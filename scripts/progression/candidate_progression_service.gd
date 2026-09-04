class_name CandidateProgressionService
extends RefCounted

var growth_data: CandidateGrowthData
var completed_slots: Dictionary = {}
var selected_branch_id: StringName = &""

func configure(data: CandidateGrowthData) -> void:
	growth_data = data
	completed_slots.clear()
	selected_branch_id = &""

func is_enabled() -> bool:
	return growth_data != null and growth_data.get_validation_errors().is_empty()

func is_growth_complete() -> bool:
	return is_enabled() and completed_slots.has(0) and completed_slots.has(1) and completed_slots.has(2) and selected_branch_id != &""

func claim_fixed_slot(slot_index: int) -> CandidateUpgradeData:
	if not is_enabled() or completed_slots.has(slot_index):
		return null
	var upgrade: CandidateUpgradeData
	if slot_index == 0:
		upgrade = growth_data.first_upgrade
	elif slot_index == 2:
		upgrade = growth_data.final_upgrade
	else:
		return null
	completed_slots[slot_index] = String(upgrade.id)
	return upgrade

func get_branch_upgrades(slot_index: int = 1) -> Array[CandidateUpgradeData]:
	if not is_enabled() or slot_index != 1 or completed_slots.has(slot_index):
		return []
	return growth_data.branch_upgrades.duplicate()

func select_branch(branch_id: StringName, slot_index: int = 1) -> CandidateUpgradeData:
	if not is_enabled() or slot_index != 1 or completed_slots.has(slot_index):
		return null
	for branch in growth_data.branch_upgrades:
		if branch != null and branch.id == branch_id:
			selected_branch_id = branch_id
			completed_slots[slot_index] = String(branch_id)
			return branch
	return null

func merged_modifiers() -> Dictionary:
	var result: Dictionary = {}
	if not is_enabled():
		return result
	for slot_index in completed_slots:
		var upgrade := _upgrade_for_id(StringName(completed_slots[slot_index]))
		if upgrade == null:
			continue
		for key in upgrade.modifiers:
			var value: Variant = upgrade.modifiers[key]
			if value is float or value is int:
				result[key] = float(result.get(key, 1.0)) * float(value)
			else:
				result[key] = value
	return result

func snapshot() -> Dictionary:
	var slot_snapshot: Dictionary = {}
	for slot_index in completed_slots:
		slot_snapshot[str(slot_index)] = String(completed_slots[slot_index])
	return {
		"candidate_id": String(growth_data.candidate_id) if growth_data != null else "",
		"completed_slots": slot_snapshot,
		"selected_branch_id": String(selected_branch_id),
	}

func _upgrade_for_id(upgrade_id: StringName) -> CandidateUpgradeData:
	if growth_data == null:
		return null
	for upgrade in [growth_data.first_upgrade, growth_data.final_upgrade] + growth_data.branch_upgrades:
		if upgrade != null and upgrade.id == upgrade_id:
			return upgrade
	return null
