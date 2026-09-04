class_name DefenseStatResolver
extends RefCounted

const CATALOG_PATH := "res://data/meta/defense_stat_catalog_v0_19.tres"

var catalog: DefenseStatCatalogData

func _init(source_catalog: DefenseStatCatalogData = null) -> void:
	catalog = source_catalog if source_catalog != null else load(CATALOG_PATH) as DefenseStatCatalogData

func resolve_value(tower_id: StringName, axis_id: StringName, modifier_key: StringName, base_value: float, bonus: float, target_kind: StringName = &"normal_defender", is_guard: bool = false) -> float:
	var mapping := get_mapping(tower_id, axis_id)
	if mapping == null or not mapping.supports(modifier_key, target_kind, is_guard) or is_zero_approx(bonus):
		return base_value
	if mapping.value_mode == DefenseStatMappingData.FIXED_MODE:
		return base_value + clampf(bonus, -mapping.cap, mapping.cap)
	var multiplier := clampf(1.0 + bonus, 0.01, mapping.cap)
	return base_value * multiplier

func resolve_primary(tower_id: StringName, axis_id: StringName, base_value: float, bonus: float, target_kind: StringName = &"normal_defender", is_guard: bool = false) -> float:
	var mapping := get_mapping(tower_id, axis_id)
	if mapping == null:
		return base_value
	return resolve_value(tower_id, axis_id, mapping.primary_modifier_key(), base_value, bonus, target_kind, is_guard)

func resolve_interval(tower_id: StringName, base_interval: float, speed_bonus: float, target_kind: StringName = &"normal_defender", is_guard: bool = false) -> float:
	var rate := resolve_primary(tower_id, &"speed", 1.0, speed_bonus, target_kind, is_guard)
	return base_interval / maxf(rate, 0.01)

func get_mapping(tower_id: StringName, axis_id: StringName) -> DefenseStatMappingData:
	return catalog.find_mapping(tower_id, axis_id) if catalog != null else null

func get_axis(axis_id: StringName) -> DefenseStatAxisData:
	return catalog.find_axis(axis_id) if catalog != null else null

func tower_axis_presentations(tower_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if catalog == null:
		return result
	for mapping in catalog.get_tower_mappings(tower_id):
		var axis := catalog.find_axis(mapping.axis_id)
		if axis != null:
			result.append({"axis_id": axis.id, "display_name": axis.display_name, "icon_key": axis.icon_key, "color": axis.color, "mapping_name": mapping.display_name, "value_mode": mapping.value_mode, "cap": mapping.cap})
	return result
