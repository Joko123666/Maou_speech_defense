class_name BalanceAuditBuildPolicy
extends RefCounted

const IDS: Array[StringName] = [&"strong_synergy", &"average_coherent", &"weak_coherent", &"tangled"]
const REVISION := 3

var id: StringName = &"strong_synergy"

func _init(policy_id: StringName = &"strong_synergy") -> void:
	id = policy_id if policy_id in IDS else &"strong_synergy"

func score_choice(choice: UpgradeData, context: Dictionary) -> int:
	if choice == null or not bool(context.get("valid", true)):
		return -1000
	var base_score := _base_score(choice, context)
	var scenario_priority := int(context.get("scenario_priority", 0))
	match id:
		&"strong_synergy":
			return maxi(base_score, scenario_priority)
		&"average_coherent":
			return base_score + mini(scenario_priority / 12, 8)
		&"weak_coherent":
			return _weak_score(choice, context)
		&"tangled":
			return _tangled_score(choice, context)
	return base_score

func selection_reason(choice: UpgradeData, context: Dictionary) -> String:
	if choice != null and choice.category == &"artifact":
		return "public artifact effects, trade-off, and current inventory"
	match id:
		&"strong_synergy": return "scenario synergy and role completion"
		&"average_coherent": return "current role coverage and ordinary growth"
		&"weak_coherent": return "low synergy with minimum placement viability"
		&"tangled": return "role duplication and low build cohesion"
	return "deterministic policy score"

func tie_break_score(choice: UpgradeData, context: Dictionary) -> int:
	if choice == null:
		return -1
	# Equal category scores used to select the first card every time. That made
	# multi-seed audits repeat the resource order instead of sampling coherent
	# alternatives. Keep the primary policy score authoritative and vary only
	# exact ties with public, reproducible audit inputs.
	var signature := "%s|%s|%s|%d|%d" % [
		String(id),
		String(context.get("scenario", "")),
		String(choice.data_id),
		int(context.get("audit_seed", 0)),
		int(context.get("selection_index", 0)),
	]
	return int(signature.hash()) & 0x7fffffff

func _base_score(choice: UpgradeData, context: Dictionary) -> int:
	var regular_formations := int(context.get("regular_formation_count", 0))
	match choice.category:
		&"artifact": return 108 + roundi(_artifact_public_utility(choice, context) * 30.0)
		&"formation_set": return 130 if regular_formations < 4 else 90
		&"tower_specialization_entry", &"core_specialization_entry", &"cursor_specialization_entry": return 115
		&"guard_specialization_entry": return 109
		&"tower_branch", &"core_branch", &"cursor_branch": return 112
		&"guard_branch": return 108
		&"guard_training": return 110
		&"guard_completion": return 106
		&"candidate_branch": return 114
		&"tower_type_level": return 108
		&"core_level": return 116 if int(context.get("core_level", 1)) < 4 else 100
		&"cursor_level": return 116 if int(context.get("cursor_level", 1)) < 4 else 100
		&"new_formation":
			return 120 + roundi(float(context.get("formation_score", 0)) / 20.0) + mini(int(context.get("valid_position_count", 0)), 12)
		&"status_upgrade": return 88
		&"global_upgrade": return 84
	return 60

func _weak_score(choice: UpgradeData, context: Dictionary) -> int:
	var regular_formations := int(context.get("regular_formation_count", 0))
	match choice.category:
		&"artifact": return 96 + roundi(_artifact_public_utility(choice, context) * 20.0)
		&"formation_set": return 128 if regular_formations < 2 else 82
		&"new_formation": return 118 + mini(int(context.get("valid_position_count", 0)), 8) - roundi(float(context.get("formation_score", 0)) / 30.0)
		&"status_upgrade": return 116
		&"global_upgrade": return 112
		&"tower_type_level": return 108
		&"core_level", &"cursor_level": return 104
		&"candidate_branch", &"tower_branch", &"core_branch", &"cursor_branch", &"guard_branch": return 100
		&"guard_training", &"guard_completion": return 104
		&"tower_specialization_entry", &"core_specialization_entry", &"cursor_specialization_entry", &"guard_specialization_entry": return 98
	return 70

func _tangled_score(choice: UpgradeData, context: Dictionary) -> int:
	var regular_formations := int(context.get("regular_formation_count", 0))
	match choice.category:
		&"artifact": return 118 + roundi(_artifact_public_utility(choice, context) * 18.0)
		&"global_upgrade": return 126
		&"status_upgrade": return 122
		&"tower_type_level": return 120
		&"core_level", &"cursor_level": return 114
		&"formation_set": return 110 if regular_formations < 1 else 78
		&"new_formation": return 102 + mini(int(context.get("valid_position_count", 0)), 4)
		&"candidate_branch", &"tower_branch", &"core_branch", &"cursor_branch", &"guard_branch": return 92
		&"guard_training", &"guard_completion": return 88
		&"tower_specialization_entry", &"core_specialization_entry", &"cursor_specialization_entry", &"guard_specialization_entry": return 90
	return 80

func _artifact_public_utility(choice: UpgradeData, context: Dictionary) -> float:
	var utility := 0.0
	for effect_value in choice.offer_metadata.get("effects", []) as Array:
		if not effect_value is Dictionary:
			continue
		var effect := effect_value as Dictionary
		var value := float(effect.get("value", 0.0))
		if StringName(effect.get("value_mode", "")) == ArtifactEffectData.FIXED_BONUS:
			value /= 100.0
		utility += value
	if bool(choice.offer_metadata.get("trade_off", false)):
		utility -= 0.08
	if int(context.get("artifact_inventory_count", 0)) >= ArtifactInventoryState.DEFAULT_CAPACITY:
		utility -= 0.05
	return utility
