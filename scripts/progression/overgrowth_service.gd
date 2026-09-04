class_name OvergrowthService
extends RefCounted

const CATALOG_PATH := "res://data/meta/overgrowth_catalog_v0_19.tres"

var catalog: OvergrowthCatalogData
var stack_counts: Dictionary = {}

func _init(source_catalog: OvergrowthCatalogData = null) -> void:
	catalog = source_catalog if source_catalog != null else load(CATALOG_PATH) as OvergrowthCatalogData

func reset() -> void:
	stack_counts.clear()

func eligible_options(candidate_growth_complete: bool, retainer_growth_complete: bool) -> Array[OvergrowthOptionData]:
	var result: Array[OvergrowthOptionData] = []
	if catalog == null:
		return result
	for option in catalog.options:
		if option == null:
			continue
		if option.target_group == &"candidate" and candidate_growth_complete:
			result.append(option)
		elif option.target_group == &"retainer" and retainer_growth_complete:
			result.append(option)
	return result

func pick_eligible(candidate_growth_complete: bool, retainer_growth_complete: bool) -> OvergrowthOptionData:
	var options := eligible_options(candidate_growth_complete, retainer_growth_complete)
	if options.is_empty():
		return null
	var total_weight := 0.0
	for option in options:
		total_weight += maxf(option.offer_weight, 0.0)
	if total_weight <= 0.0:
		return null
	var cursor := RunRng.progression_roll() * total_weight
	for option in options:
		cursor -= maxf(option.offer_weight, 0.0)
		if cursor <= 0.0:
			return option
	return options.back()

func apply(option_id: StringName, candidate_growth_complete: bool, retainer_growth_complete: bool) -> bool:
	var option := catalog.find_option(option_id) if catalog != null else null
	if option == null:
		return false
	if option.target_group == &"candidate" and not candidate_growth_complete:
		return false
	if option.target_group == &"retainer" and not retainer_growth_complete:
		return false
	stack_counts[option.id] = get_stack_count(option.id) + 1
	return true

func get_stack_count(option_id: StringName) -> int:
	return maxi(int(stack_counts.get(option_id, stack_counts.get(String(option_id), 0))), 0)

func get_multiplier(target_group: StringName, stat_key: StringName) -> float:
	if catalog == null:
		return 1.0
	var bonus := 0.0
	for option in catalog.options:
		if option != null and option.target_group == target_group and option.stat_key == stat_key:
			bonus += get_stack_count(option.id) * option.bonus_per_stack
	return 1.0 + bonus

func snapshot() -> Dictionary:
	var counts: Dictionary = {}
	var candidate_total := 0
	var retainer_total := 0
	if catalog != null:
		for option in catalog.options:
			if option == null:
				continue
			var count := get_stack_count(option.id)
			if count <= 0:
				continue
			counts[String(option.id)] = count
			if option.target_group == &"candidate": candidate_total += count
			if option.target_group == &"retainer": retainer_total += count
	return {
		"stack_counts": counts,
		"candidate_total": candidate_total,
		"retainer_total": retainer_total,
		"total": candidate_total + retainer_total,
	}

func restore(snapshot: Dictionary) -> void:
	stack_counts.clear()
	var raw_counts: Variant = snapshot.get("stack_counts", {})
	if not raw_counts is Dictionary or catalog == null:
		return
	for raw_id in (raw_counts as Dictionary):
		var option_id := StringName(raw_id)
		if catalog.find_option(option_id) != null:
			stack_counts[option_id] = maxi(int((raw_counts as Dictionary)[raw_id]), 0)
