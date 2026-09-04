class_name CandidateGrowthData
extends Resource

@export var candidate_id: StringName = &""
@export var first_upgrade: CandidateUpgradeData
@export var branch_upgrades: Array[CandidateUpgradeData] = []
@export var final_upgrade: CandidateUpgradeData

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if candidate_id == &"": errors.append("candidate growth has no candidate id")
	if first_upgrade == null: errors.append("candidate growth '%s' has no first fixed upgrade" % candidate_id)
	if final_upgrade == null: errors.append("candidate growth '%s' has no final fixed upgrade" % candidate_id)
	if branch_upgrades.size() != 3: errors.append("candidate growth '%s' requires exactly three branches" % candidate_id)
	var seen_ids: Dictionary = {}
	for upgrade in [first_upgrade, final_upgrade] + branch_upgrades:
		if upgrade == null:
			continue
		errors.append_array(upgrade.get_validation_errors())
		if seen_ids.has(upgrade.id): errors.append("candidate growth '%s' contains duplicate upgrade '%s'" % [candidate_id, upgrade.id])
		seen_ids[upgrade.id] = true
	if first_upgrade != null and first_upgrade.kind != CandidateUpgradeData.KIND_FIXED:
		errors.append("candidate growth '%s' first upgrade must be fixed" % candidate_id)
	if final_upgrade != null and final_upgrade.kind != CandidateUpgradeData.KIND_FIXED:
		errors.append("candidate growth '%s' final upgrade must be fixed" % candidate_id)
	for branch in branch_upgrades:
		if branch != null and branch.kind != CandidateUpgradeData.KIND_BRANCH:
			errors.append("candidate growth '%s' branch '%s' must use branch kind" % [candidate_id, branch.id])
	return errors
