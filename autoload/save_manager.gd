extends Node

const SAVE_PATH := "user://td_survival_save.json"
const BACKUP_PATH := "user://td_survival_save.backup.json"
const TEMP_PATH := "user://td_survival_save.tmp"
const ROTATION_PATH := "user://td_survival_save.previous.tmp"
const CURRENT_META_PROGRESSION_VERSION := 14
const META_UNLOCK_SEQUENCE_REVISION := 1
const TUTORIAL_COMPLETION_REVISION := 1
const ENCOUNTER_DISCOVERY_REVISION := 1
const MAX_SETTLED_RUN_IDS := 128
const STARTER_TOWER_IDS: Array[String] = ["rapid", "pierce", "area", "rubber_golem"]
const STARTER_FEATURE_IDS: Array[String] = ["base_combat", "formation_system", "specialization_system"]

var best_time: float = 0.0
var best_level: int = 1
var total_runs: int = 0
var unlocked_ids: Array[String] = ["emerald", "iron"]
var cleared_stage_ids: Array[String] = []
var highest_challenge_by_stage: Dictionary = {}
var selected_challenge_by_stage: Dictionary = {}
var sound_enabled: bool = true
var screen_shake_enabled: bool = true
var screen_flash_enabled: bool = true
var reduced_motion_enabled: bool = false

var meta_progression_version: int = CURRENT_META_PROGRESSION_VERSION
var unlock_sequence_revision: int = META_UNLOCK_SEQUENCE_REVISION
var tutorial_completion_revision: int = TUTORIAL_COMPLETION_REVISION
var encounter_discovery_revision: int = ENCOUNTER_DISCOVERY_REVISION
var tutorial_completed: bool = false
var defense_funds: int = 0
var unlocked_tower_ids: Array[String] = STARTER_TOWER_IDS.duplicate()
var discovered_tower_use_ids: Array[String] = STARTER_TOWER_IDS.duplicate()
var unlocked_feature_ids: Array[String] = STARTER_FEATURE_IDS.duplicate()
var discovered_shop_product_ids: Array[String] = []
var purchased_shop_product_ids: Array[String] = []
var encountered_enemy_ids: Array[String] = []
var achievement_progress: Dictionary = {}
var completed_achievement_ids: Array[String] = []
var claimed_achievement_ids: Array[String] = []
var stage_first_clear_reward_ids: Array[String] = []
var challenge_first_clear_reward_ids: Array[String] = []
var settled_run_ids: Array[String] = []
var candidate_support: Dictionary = {}
var elected_candidate_ids: Array[String] = []
var candidate_decree_ids: Dictionary = {}
var governance_approval: Dictionary = {}
var candidate_clear_records: Dictionary = {}
var candidate_rival_records: Dictionary = {}
var candidate_first_clear_ids: Array[String] = []
var retainer_first_clear_ids: Array[String] = []
var legacy_full_unlock: bool = false
var pending_enemy_encounter_ids: Array[StringName] = []
var enemy_encounter_flush_scheduled: bool = false

func _ready() -> void:
	load_save()
	GameSession.screen_shake_enabled = screen_shake_enabled
	GameSession.screen_flash_enabled = screen_flash_enabled
	GameSession.reduced_motion_enabled = reduced_motion_enabled

func record_run(result: Dictionary) -> bool:
	var snapshot := _build_save_data()
	_record_run_in_memory(result)
	if save():
		return true
	_apply_save_data(snapshot)
	return false

func complete_tutorial() -> bool:
	if tutorial_completed:
		return true
	var snapshot := _build_save_data()
	_apply_tutorial_completion_in_memory()
	if save():
		return true
	_apply_save_data(snapshot)
	return false

func _apply_tutorial_completion_in_memory() -> bool:
	if tutorial_completed:
		return false
	tutorial_completed = true
	tutorial_completion_revision = TUTORIAL_COMPLETION_REVISION
	return true

func _record_run_in_memory(result: Dictionary) -> void:
	total_runs += 1
	best_time = maxf(best_time, float(result.get("elapsed", 0.0)))
	best_level = maxi(best_level, int(result.get("level", 1)))
	_apply_challenge_progress(result)

func commit_run_settlement(result: Dictionary, breakdown: Dictionary) -> bool:
	var snapshot := _build_save_data()
	if not _apply_run_settlement_in_memory(result, breakdown):
		return false
	if save():
		return true
	_apply_save_data(snapshot)
	return false

func _apply_run_settlement_in_memory(result: Dictionary, breakdown: Dictionary) -> bool:
	var run_id := String(result.get("run_id", ""))
	if run_id.is_empty() or has_settled_run(run_id):
		return false
	_record_run_in_memory(result)
	defense_funds += maxi(int(breakdown.get("total_funds", 0)), 0)
	_apply_achievement_actions(breakdown.get("achievement_actions", {}))
	_apply_candidate_progression(result, breakdown.get("candidate_progression", {}))
	_apply_governance_progression(result, breakdown.get("governance_progression", {}))
	_apply_identity_first_clear_unlocks(result)
	_append_unique(stage_first_clear_reward_ids, String(breakdown.get("stage_first_reward_id", "")))
	_append_unique(challenge_first_clear_reward_ids, String(breakdown.get("challenge_first_reward_id", "")))
	settled_run_ids.append(run_id)
	while settled_run_ids.size() > MAX_SETTLED_RUN_IDS:
		settled_run_ids.pop_front()
	return true

func _apply_identity_first_clear_unlocks(result: Dictionary) -> void:
	if not bool(result.get("victory", false)):
		return
	var campaign := ConceptService.get_election_campaign()
	if campaign == null:
		return
	var candidate_id := String(result.get("candidate_id", ""))
	if not candidate_id.is_empty() and candidate_id not in candidate_first_clear_ids:
		for index in campaign.candidates.size():
			var candidate := campaign.candidates[index]
			if candidate == null or String(candidate.id) != candidate_id:
				continue
			candidate_first_clear_ids.append(candidate_id)
			if index + 1 < campaign.candidates.size() and campaign.candidates[index + 1] != null:
				_append_unique(unlocked_ids, String(campaign.candidates[index + 1].core_id))
			break
	var retainer_id := String(result.get("retainer_id", ""))
	if not retainer_id.is_empty() and retainer_id not in retainer_first_clear_ids:
		for index in campaign.retainers.size():
			var retainer := campaign.retainers[index]
			if retainer == null or String(retainer.id) != retainer_id:
				continue
			retainer_first_clear_ids.append(retainer_id)
			if index + 1 < campaign.retainers.size() and campaign.retainers[index + 1] != null:
				_append_unique(unlocked_ids, String(campaign.retainers[index + 1].cursor_id))
			break

func _apply_candidate_progression(result: Dictionary, value: Variant) -> void:
	if value is not Dictionary:
		return
	var progression := value as Dictionary
	var candidate_id := String(progression.get("candidate_id", result.get("candidate_id", "")))
	if candidate_id.is_empty():
		return
	var support_required := maxi(int(progression.get("support_required", 0)), 0)
	var support_earned := maxi(int(progression.get("total_support", 0)), 0)
	var current_support := maxi(int(candidate_support.get(candidate_id, 0)), 0)
	var support_after := current_support + support_earned
	if support_required > 0:
		support_after = mini(support_after, support_required)
	candidate_support[candidate_id] = support_after
	if support_required > 0 and support_after >= support_required:
		_append_unique(elected_candidate_ids, candidate_id)
		if not governance_approval.has(candidate_id):
			governance_approval[candidate_id] = 50
		var default_decree_id := String(progression.get("default_decree_id", ""))
		if not default_decree_id.is_empty() and String(candidate_decree_ids.get(candidate_id, "")).is_empty():
			candidate_decree_ids[candidate_id] = default_decree_id
	_update_candidate_clear_record(candidate_id, result)
	_update_candidate_rival_records(candidate_id, progression.get("defeated_rival_candidate_ids", []))

func _update_candidate_clear_record(candidate_id: String, result: Dictionary) -> void:
	var record_value: Variant = candidate_clear_records.get(candidate_id, {})
	var record: Dictionary = record_value.duplicate(true) if record_value is Dictionary else {}
	record["runs"] = maxi(int(record.get("runs", 0)), 0) + 1
	if bool(result.get("victory", false)):
		record["victories"] = maxi(int(record.get("victories", 0)), 0) + 1
	record["best_progress_ratio"] = maxf(float(record.get("best_progress_ratio", 0.0)), clampf(float(result.get("elapsed", 0.0)) / maxf(float(result.get("stage_duration_seconds", 600.0)), 1.0), 0.0, 1.0))
	record["highest_challenge"] = maxi(int(record.get("highest_challenge", -1)), ChallengeRules.clamp_level(int(result.get("challenge_level", 0))))
	record["last_stage_id"] = String(result.get("stage_id", ""))
	candidate_clear_records[candidate_id] = record

func _apply_governance_progression(result: Dictionary, value: Variant) -> void:
	if value is not Dictionary:
		return
	var progression := value as Dictionary
	if not bool(progression.get("eligible", false)):
		return
	var candidate_id := String(progression.get("candidate_id", result.get("candidate_id", "")))
	if candidate_id.is_empty() or not is_candidate_elected(StringName(candidate_id)):
		return
	var before := get_governance_approval(StringName(candidate_id))
	var delta := int(progression.get("approval_delta", 0))
	governance_approval[candidate_id] = clampi(before + delta, 0, 100)

func _update_candidate_rival_records(candidate_id: String, value: Variant) -> void:
	if value is not Array:
		return
	var rival_value: Variant = candidate_rival_records.get(candidate_id, {})
	var rival_records: Dictionary = rival_value.duplicate(true) if rival_value is Dictionary else {}
	for rival_id_value in value:
		var rival_id := String(rival_id_value)
		if rival_id.is_empty() or rival_id == candidate_id:
			continue
		rival_records[rival_id] = maxi(int(rival_records.get(rival_id, 0)), 0) + 1
	candidate_rival_records[candidate_id] = rival_records

func _apply_achievement_actions(value: Variant) -> void:
	if value is not Dictionary:
		return
	var actions := value as Dictionary
	var progress_updates: Variant = actions.get("progress_updates", {})
	if progress_updates is Dictionary:
		for achievement_id in progress_updates:
			achievement_progress[String(achievement_id)] = maxf(float(achievement_progress.get(String(achievement_id), 0.0)), float(progress_updates[achievement_id]))
	_append_unique_values(completed_achievement_ids, actions.get("completed_ids", []))
	_append_unique_values(claimed_achievement_ids, actions.get("claimed_ids", []))
	_append_unique_values(discovered_shop_product_ids, actions.get("discovered_product_ids", []))
	_append_unique_values(unlocked_feature_ids, actions.get("unlocked_feature_ids", []))
	_append_unique_values(unlocked_ids, actions.get("unlocked_content_ids", []))

func commit_product_purchase(product: ShopProductData) -> bool:
	if product == null:
		return false
	var snapshot := _build_save_data()
	if not _apply_product_purchase_in_memory(product):
		return false
	if save():
		return true
	_apply_save_data(snapshot)
	return false

func _apply_product_purchase_in_memory(product: ShopProductData) -> bool:
	var product_id := String(product.id)
	if product_id.is_empty() or product_id in purchased_shop_product_ids or defense_funds < product.price:
		return false
	defense_funds -= product.price
	purchased_shop_product_ids.append(product_id)
	match product.product_type:
		&"tower": _append_unique(unlocked_tower_ids, String(product.content_id))
		_: _append_unique(unlocked_ids, String(product.content_id))
	for content_id in product.granted_content_ids:
		match product.product_type:
			&"tower": _append_unique(unlocked_tower_ids, String(content_id))
			_: _append_unique(unlocked_ids, String(content_id))
	for feature_id in product.granted_feature_ids:
		_append_unique(unlocked_feature_ids, String(feature_id))
	_append_unique(unlocked_feature_ids, "codex_system")
	return true

func record_enemy_encounter(enemy_id: StringName) -> bool:
	return _commit_enemy_encounters([enemy_id])

func queue_enemy_encounter(enemy_id: StringName) -> bool:
	var key := String(enemy_id)
	if key.is_empty():
		return false
	if key in encountered_enemy_ids or enemy_id in pending_enemy_encounter_ids:
		return true
	pending_enemy_encounter_ids.append(enemy_id)
	if not enemy_encounter_flush_scheduled:
		enemy_encounter_flush_scheduled = true
		_flush_pending_enemy_encounters.call_deferred()
	return true

func flush_pending_enemy_encounters() -> bool:
	enemy_encounter_flush_scheduled = false
	if pending_enemy_encounter_ids.is_empty():
		return true
	var pending := pending_enemy_encounter_ids.duplicate()
	pending_enemy_encounter_ids.clear()
	var committed := _commit_enemy_encounters(pending)
	if not committed:
		push_warning("Enemy encounter discovery could not be saved; it will be retried on a later encounter.")
	return committed

func _flush_pending_enemy_encounters() -> void:
	flush_pending_enemy_encounters()

func _commit_enemy_encounters(enemy_ids: Array[StringName], persist_to_disk: bool = true) -> bool:
	var snapshot := _build_save_data()
	var changed := false
	for enemy_id in enemy_ids:
		var key := String(enemy_id)
		if key.is_empty() or key in encountered_enemy_ids:
			continue
		encountered_enemy_ids.append(key)
		changed = true
	if not changed or not persist_to_disk or save():
		return true
	_apply_save_data(snapshot)
	return false

func _mark_enemy_encounter_in_memory(enemy_id: StringName) -> bool:
	var key := String(enemy_id)
	if key.is_empty() or key in encountered_enemy_ids:
		return false
	encountered_enemy_ids.append(key)
	return true

func has_settled_run(run_id: String) -> bool:
	return not run_id.is_empty() and run_id in settled_run_ids

func mark_tower_use_discovered(tower_ids: Array[StringName], persist_to_disk: bool = true) -> bool:
	var snapshot := _build_save_data()
	var changed := false
	for tower_id in tower_ids:
		var key := String(tower_id)
		if key.is_empty() or key in discovered_tower_use_ids:
			continue
		discovered_tower_use_ids.append(key)
		changed = true
	if not changed:
		return false
	if not persist_to_disk or save():
		return true
	_apply_save_data(snapshot)
	push_warning("Tower-use discovery could not be saved; the placement remains active and discovery will retry on a later placement.")
	return false

func get_candidate_support(candidate_id: StringName) -> int:
	return maxi(int(candidate_support.get(String(candidate_id), 0)), 0)

func is_candidate_elected(candidate_id: StringName) -> bool:
	return String(candidate_id) in elected_candidate_ids

func get_candidate_decree(candidate_id: StringName) -> StringName:
	return StringName(candidate_decree_ids.get(String(candidate_id), ""))

func get_governance_approval(candidate_id: StringName) -> int:
	var candidate_key := String(candidate_id)
	if governance_approval.has(candidate_key):
		return clampi(int(governance_approval[candidate_key]), 0, 100)
	return 50 if is_candidate_elected(candidate_id) else 0

func select_candidate_decree(candidate_id: StringName, decree_id: StringName, allowed_decree_ids: Array[StringName]) -> bool:
	var snapshot := _build_save_data()
	if not _apply_candidate_decree_selection_in_memory(candidate_id, decree_id, allowed_decree_ids):
		return false
	if save():
		return true
	_apply_save_data(snapshot)
	return false

func _apply_candidate_decree_selection_in_memory(candidate_id: StringName, decree_id: StringName, allowed_decree_ids: Array[StringName]) -> bool:
	var candidate_key := String(candidate_id)
	if candidate_key.is_empty() or not is_candidate_elected(candidate_id) or decree_id not in allowed_decree_ids:
		return false
	candidate_decree_ids[candidate_key] = String(decree_id)
	return true

func _append_unique(target: Array[String], value: String) -> void:
	if not value.is_empty() and value not in target:
		target.append(value)

func _append_unique_values(target: Array[String], values: Variant) -> void:
	if values is not Array:
		return
	for value in values:
		_append_unique(target, String(value))

func _apply_challenge_progress(result: Dictionary) -> void:
	if not bool(result.get("victory", false)):
		return
	var stage_id := String(result.get("stage_id", "standard_20m"))
	if stage_id.is_empty():
		return
	var selectable_before_clear := get_max_selectable_challenge(StringName(stage_id))
	var challenge_level := clampi(ChallengeRules.clamp_level(int(result.get("challenge_level", 0))), 0, selectable_before_clear)
	if stage_id not in cleared_stage_ids:
		cleared_stage_ids.append(stage_id)
	highest_challenge_by_stage[stage_id] = maxi(int(highest_challenge_by_stage.get(stage_id, -1)), challenge_level)
	selected_challenge_by_stage[stage_id] = mini(int(selected_challenge_by_stage.get(stage_id, 0)), get_max_selectable_challenge(StringName(stage_id)))

func is_challenge_unlocked(stage_id: StringName) -> bool:
	return String(stage_id) in cleared_stage_ids

func get_highest_challenge(stage_id: StringName) -> int:
	return int(highest_challenge_by_stage.get(String(stage_id), -1))

func get_max_selectable_challenge(stage_id: StringName) -> int:
	if not is_challenge_unlocked(stage_id):
		return 0
	return mini(maxi(get_highest_challenge(stage_id), -1) + 1, ChallengeRules.MAX_LEVEL)

func get_selected_challenge(stage_id: StringName) -> int:
	if not is_challenge_unlocked(stage_id):
		return 0
	return clampi(ChallengeRules.clamp_level(int(selected_challenge_by_stage.get(String(stage_id), 0))), 0, get_max_selectable_challenge(stage_id))

func set_selected_challenge(stage_id: StringName, level: int) -> void:
	var key := String(stage_id)
	selected_challenge_by_stage[key] = clampi(ChallengeRules.clamp_level(level), 0, get_max_selectable_challenge(stage_id)) if is_challenge_unlocked(stage_id) else 0
	save()

func save() -> bool:
	var file := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(_build_save_data()))
	file.flush()
	file.close()
	return _replace_save_with_temp()

func _replace_save_with_temp() -> bool:
	var result := _replace_file_with_temp_result(SAVE_PATH, BACKUP_PATH, TEMP_PATH, ROTATION_PATH)
	if bool(result.get("primary_committed", false)) and bool(result.get("previous_primary_valid", false)) and not bool(result.get("backup_promoted", false)):
		push_warning("Save committed, but the previous save could not be promoted to the backup slot; recovery remains at %s (%s)." % [String(result.get("recovery_path", ROTATION_PATH)), String(result.get("error", "backup promotion failed"))])
	return bool(result.get("primary_committed", false))

func _replace_file_with_temp(save_path: String, backup_path: String, temp_path: String, rotation_path: String) -> bool:
	return bool(_replace_file_with_temp_result(save_path, backup_path, temp_path, rotation_path).get("primary_committed", false))

func _replace_file_with_temp_result(save_path: String, backup_path: String, temp_path: String, rotation_path: String) -> Dictionary:
	var result := {
		"primary_committed": false,
		"previous_primary_valid": false,
		"backup_promoted": true,
		"previous_version_durable": true,
		"recovery_path": "",
		"error": "",
	}
	if not FileAccess.file_exists(temp_path):
		result.error = "temporary save is missing"
		return result
	var save_absolute := ProjectSettings.globalize_path(save_path)
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	var temp_absolute := ProjectSettings.globalize_path(temp_path)
	var rotation_absolute := ProjectSettings.globalize_path(rotation_path)
	var existing_primary_valid := not _validate_save_dictionary(_read_save_dictionary(save_path)).is_empty()
	result.previous_primary_valid = existing_primary_valid
	if FileAccess.file_exists(rotation_path):
		if DirAccess.remove_absolute(rotation_absolute) != OK:
			DirAccess.remove_absolute(temp_absolute)
			result.error = "stale rotation could not be removed"
			return result
	var moved_existing := false
	if FileAccess.file_exists(save_path):
		if DirAccess.rename_absolute(save_absolute, rotation_absolute) != OK:
			DirAccess.remove_absolute(temp_absolute)
			result.error = "primary save could not enter rotation"
			return result
		moved_existing = true
	if DirAccess.rename_absolute(temp_absolute, save_absolute) == OK:
		result.primary_committed = true
		if moved_existing:
			if existing_primary_valid:
				var backup_ready := true
				if FileAccess.file_exists(backup_path) and DirAccess.remove_absolute(backup_absolute) != OK:
					backup_ready = false
					result.error = "existing backup could not be removed"
				if backup_ready and DirAccess.rename_absolute(rotation_absolute, backup_absolute) == OK:
					result.backup_promoted = true
					result.recovery_path = backup_path
				else:
					result.backup_promoted = false
					result.previous_version_durable = FileAccess.file_exists(rotation_path) or FileAccess.file_exists(backup_path)
					result.recovery_path = rotation_path if FileAccess.file_exists(rotation_path) else backup_path
					if String(result.error).is_empty():
						result.error = "rotation could not be promoted to backup"
			else:
				DirAccess.remove_absolute(rotation_absolute)
		return result
	if moved_existing:
		if DirAccess.rename_absolute(rotation_absolute, save_absolute) != OK:
			result.previous_version_durable = FileAccess.file_exists(rotation_path)
			result.recovery_path = rotation_path if FileAccess.file_exists(rotation_path) else ""
			result.error = "new primary commit and previous primary restoration both failed"
		else:
			result.error = "new primary could not be committed; previous primary was restored"
	else:
		result.error = "new primary could not be committed"
	DirAccess.remove_absolute(temp_absolute)
	return result

func _build_save_data() -> Dictionary:
	return {
		"best_time": best_time,
		"best_level": best_level,
		"total_runs": total_runs,
		"unlocked_ids": unlocked_ids,
		"cleared_stage_ids": cleared_stage_ids,
		"highest_challenge_by_stage": highest_challenge_by_stage,
		"selected_challenge_by_stage": selected_challenge_by_stage,
		"sound_enabled": sound_enabled,
		"screen_shake_enabled": screen_shake_enabled,
		"screen_flash_enabled": screen_flash_enabled,
		"reduced_motion_enabled": reduced_motion_enabled,
		"meta_progression_version": meta_progression_version,
		"unlock_sequence_revision": unlock_sequence_revision,
		"tutorial_completion_revision": tutorial_completion_revision,
		"encounter_discovery_revision": encounter_discovery_revision,
		"tutorial_completed": tutorial_completed,
		"defense_funds": defense_funds,
		"unlocked_tower_ids": unlocked_tower_ids,
		"discovered_tower_use_ids": discovered_tower_use_ids,
		"unlocked_feature_ids": unlocked_feature_ids,
		"discovered_shop_product_ids": discovered_shop_product_ids,
		"purchased_shop_product_ids": purchased_shop_product_ids,
		"encountered_enemy_ids": encountered_enemy_ids,
		"achievement_progress": achievement_progress,
		"completed_achievement_ids": completed_achievement_ids,
		"claimed_achievement_ids": claimed_achievement_ids,
		"stage_first_clear_reward_ids": stage_first_clear_reward_ids,
		"challenge_first_clear_reward_ids": challenge_first_clear_reward_ids,
		"settled_run_ids": settled_run_ids,
		"candidate_support": candidate_support,
		"elected_candidate_ids": elected_candidate_ids,
		"candidate_decree_ids": candidate_decree_ids,
		"governance_approval": governance_approval,
		"candidate_clear_records": candidate_clear_records,
		"candidate_rival_records": candidate_rival_records,
		"candidate_first_clear_ids": candidate_first_clear_ids,
		"retainer_first_clear_ids": retainer_first_clear_ids,
		"legacy_full_unlock": legacy_full_unlock,
	}

func load_save() -> void:
	var recovery := _resolve_save_recovery(SAVE_PATH, BACKUP_PATH, ROTATION_PATH)
	var parsed := recovery.get("data", {}) as Dictionary
	if parsed.is_empty():
		return
	var recovery_source := recovery.get("source", &"") as StringName
	var recovered_from_backup := recovery_source == &"backup"
	var recovered_from_rotation := recovery_source == &"rotation"
	var was_legacy := int(parsed.get("meta_progression_version", 0)) < CURRENT_META_PROGRESSION_VERSION
	_apply_save_data(_normalize_save_data(parsed))
	if recovered_from_rotation and not _preserve_recovery_copy(ROTATION_PATH, BACKUP_PATH):
		return
	if was_legacy or recovered_from_backup or recovered_from_rotation:
		save()

func _resolve_save_recovery(save_path: String, backup_path: String, rotation_path: String) -> Dictionary:
	var primary := _validate_save_dictionary(_read_save_dictionary(save_path))
	if not primary.is_empty():
		return {"data": primary, "source": &"primary"}
	# rotation은 commit 직전까지의 primary이며 backup보다 항상 최신 세대입니다.
	var rotation := _validate_save_dictionary(_read_save_dictionary(rotation_path))
	if not rotation.is_empty():
		return {"data": rotation, "source": &"rotation"}
	var backup := _validate_save_dictionary(_read_save_dictionary(backup_path))
	if not backup.is_empty():
		return {"data": backup, "source": &"backup"}
	return {"data": {}, "source": &""}

func _preserve_recovery_copy(source_path: String, backup_path: String) -> bool:
	if _validate_save_dictionary(_read_save_dictionary(source_path)).is_empty():
		return false
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(backup_path) and DirAccess.remove_absolute(backup_absolute) != OK:
		return false
	return DirAccess.copy_absolute(ProjectSettings.globalize_path(source_path), backup_absolute) == OK

func _read_save_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed.duplicate(true) if parsed is Dictionary else {}

func _read_save_dictionary_from_paths(save_path: String, backup_path: String) -> Dictionary:
	var primary := _validate_save_dictionary(_read_save_dictionary(save_path))
	if not primary.is_empty():
		return primary
	return _validate_save_dictionary(_read_save_dictionary(backup_path))

func _validate_save_dictionary(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}
	var version_value: Variant = data.get("meta_progression_version", 0)
	if not _is_numeric(version_value):
		return {}
	var source_version := int(version_value)
	if source_version < 0 or source_version > CURRENT_META_PROGRESSION_VERSION:
		return {}
	var numeric_fields := ["best_time", "best_level", "total_runs", "defense_funds", "unlock_sequence_revision", "tutorial_completion_revision", "encounter_discovery_revision"]
	var boolean_fields := ["sound_enabled", "screen_shake_enabled", "screen_flash_enabled", "legacy_full_unlock", "tutorial_completed"]
	var array_fields := [
		"unlocked_ids", "cleared_stage_ids", "unlocked_tower_ids",
		"discovered_tower_use_ids",
		"unlocked_feature_ids", "discovered_shop_product_ids", "purchased_shop_product_ids", "encountered_enemy_ids",
		"completed_achievement_ids", "claimed_achievement_ids", "stage_first_clear_reward_ids",
		"challenge_first_clear_reward_ids", "settled_run_ids",
		"elected_candidate_ids", "candidate_first_clear_ids", "retainer_first_clear_ids",
	]
	var dictionary_fields := [
		"highest_challenge_by_stage", "selected_challenge_by_stage", "achievement_progress",
		"candidate_support", "candidate_decree_ids", "governance_approval",
		"candidate_clear_records", "candidate_rival_records",
	]
	for field in numeric_fields:
		if data.has(field) and not _is_numeric(data[field]):
			return {}
	for field in boolean_fields:
		if data.has(field) and data[field] is not bool:
			return {}
	if data.has("reduced_motion_enabled") and data.reduced_motion_enabled is not bool:
		return {}
	for field in array_fields:
		if data.has(field) and data[field] is not Array:
			return {}
	# v8 이하 저장 파일의 폐기된 모듈 목록은 형식만 확인한 뒤 마이그레이션에서 버린다.
	if data.has("unlocked_module_ids") and data.unlocked_module_ids is not Array:
		return {}
	for field in dictionary_fields:
		if data.has(field) and data[field] is not Dictionary:
			return {}
	if data.has("candidate_support") and not _is_numeric_dictionary(data.candidate_support, 0.0):
		return {}
	if data.has("governance_approval") and not _is_numeric_dictionary(data.governance_approval, 0.0, 100.0):
		return {}
	if data.has("candidate_decree_ids") and not _is_string_dictionary(data.candidate_decree_ids):
		return {}
	if data.has("candidate_clear_records") and not _is_record_dictionary(data.candidate_clear_records):
		return {}
	if data.has("candidate_rival_records") and not _is_nested_numeric_dictionary(data.candidate_rival_records):
		return {}
	if data.has("highest_challenge_by_stage") and not _is_numeric_dictionary(data.highest_challenge_by_stage, -1.0, float(ChallengeRules.MAX_LEVEL)):
		return {}
	if data.has("selected_challenge_by_stage") and not _is_numeric_dictionary(data.selected_challenge_by_stage, 0.0, float(ChallengeRules.MAX_LEVEL)):
		return {}
	if source_version == CURRENT_META_PROGRESSION_VERSION:
		var required_fields := ["meta_progression_version"] + numeric_fields + boolean_fields + array_fields + dictionary_fields
		for field in required_fields:
			if not data.has(field):
				return {}
	else:
		var has_legacy_identity := false
		for field in ["best_time", "best_level", "total_runs", "unlocked_ids"]:
			if data.has(field):
				has_legacy_identity = true
				break
		if not has_legacy_identity:
			return {}
	return data.duplicate(true)

func _is_numeric(value: Variant) -> bool:
	return value is int or value is float

func _is_numeric_dictionary(value: Dictionary, minimum: float, maximum: float = INF) -> bool:
	for key in value:
		if not _is_numeric(value[key]):
			return false
		var number := float(value[key])
		if number < minimum or number > maximum:
			return false
	return true

func _is_string_dictionary(value: Dictionary) -> bool:
	for key in value:
		if value[key] is not String:
			return false
	return true

func _is_nested_numeric_dictionary(value: Dictionary) -> bool:
	for key in value:
		if value[key] is not Dictionary or not _is_numeric_dictionary(value[key], 0.0):
			return false
	return true

func _is_record_dictionary(value: Dictionary) -> bool:
	for key in value:
		if value[key] is not Dictionary:
			return false
		for field in (value[key] as Dictionary):
			var field_value: Variant = value[key][field]
			if field_value is not String and not _is_numeric(field_value) and field_value is not bool:
				return false
	return true

func _normalize_save_data(parsed: Dictionary) -> Dictionary:
	var source_version := int(parsed.get("meta_progression_version", 0))
	var is_pre_meta_legacy := source_version < 6
	var normalized_tower_ids := _string_array(parsed.get("unlocked_tower_ids", STARTER_TOWER_IDS), STARTER_TOWER_IDS)
	# v10 makes the rubber golem a starter while moving KI-II behind meta progression.
	# Existing unlocks are deliberately preserved; migration never removes KI-II.
	if source_version < 10 and "rubber_golem" not in normalized_tower_ids:
		normalized_tower_ids.append("rubber_golem")
	if is_pre_meta_legacy and "knockback" not in normalized_tower_ids:
		normalized_tower_ids.append("knockback")
	var discovered_default := normalized_tower_ids if source_version < 11 else STARTER_TOWER_IDS
	var normalized_discovered_tower_use_ids := _string_array(parsed.get("discovered_tower_use_ids", discovered_default), discovered_default)
	var normalized_features := _without_legacy_module_ids(_string_array(parsed.get("unlocked_feature_ids", STARTER_FEATURE_IDS), STARTER_FEATURE_IDS))
	var normalized_discovered_products := _without_legacy_module_ids(_string_array(parsed.get("discovered_shop_product_ids", [])))
	var normalized_purchased_products := _without_legacy_module_ids(_string_array(parsed.get("purchased_shop_product_ids", [])))
	var normalized_completed_achievements := _without_legacy_module_ids(_string_array(parsed.get("completed_achievement_ids", [])))
	var normalized_claimed_achievements := _without_legacy_module_ids(_string_array(parsed.get("claimed_achievement_ids", [])))
	var normalized_unlocked_ids := _string_array(parsed.get("unlocked_ids", ["emerald", "iron"]), ["emerald", "iron"])
	var normalized_candidate_first_clears := _string_array(parsed.get("candidate_first_clear_ids", []))
	var normalized_retainer_first_clears := _string_array(parsed.get("retainer_first_clear_ids", []))
	var normalized_enemy_encounters := _string_array(parsed.get("encountered_enemy_ids", []))
	if source_version < 12:
		_migrate_identity_unlock_progress(
			normalized_unlocked_ids,
			normalized_candidate_first_clears,
			normalized_retainer_first_clears,
			_dictionary(parsed.get("candidate_clear_records", {}))
		)
	if source_version < 14:
		normalized_enemy_encounters = _migrate_legacy_enemy_encounters(
			int(parsed.get("total_runs", 0)),
			float(parsed.get("best_time", 0.0))
		)
	return {
		"best_time": float(parsed.get("best_time", 0.0)),
		"best_level": int(parsed.get("best_level", 1)),
		"total_runs": int(parsed.get("total_runs", 0)),
		"unlocked_ids": normalized_unlocked_ids,
		"cleared_stage_ids": _string_array(parsed.get("cleared_stage_ids", [])),
		"highest_challenge_by_stage": _dictionary(parsed.get("highest_challenge_by_stage", {})),
		"selected_challenge_by_stage": _dictionary(parsed.get("selected_challenge_by_stage", {})),
		"sound_enabled": bool(parsed.get("sound_enabled", true)),
		"screen_shake_enabled": bool(parsed.get("screen_shake_enabled", true)),
		"screen_flash_enabled": bool(parsed.get("screen_flash_enabled", true)),
		"reduced_motion_enabled": bool(parsed.get("reduced_motion_enabled", false)),
		"meta_progression_version": CURRENT_META_PROGRESSION_VERSION,
		"unlock_sequence_revision": META_UNLOCK_SEQUENCE_REVISION,
		"tutorial_completion_revision": TUTORIAL_COMPLETION_REVISION,
		"encounter_discovery_revision": ENCOUNTER_DISCOVERY_REVISION,
		"tutorial_completed": bool(parsed.get("tutorial_completed", false)) if source_version >= 13 else int(parsed.get("total_runs", 0)) > 0,
		"defense_funds": maxi(int(parsed.get("defense_funds", 0)), 0),
		"unlocked_tower_ids": normalized_tower_ids,
		"discovered_tower_use_ids": normalized_discovered_tower_use_ids,
		"unlocked_feature_ids": normalized_features,
		"discovered_shop_product_ids": normalized_discovered_products,
		"purchased_shop_product_ids": normalized_purchased_products,
		"encountered_enemy_ids": normalized_enemy_encounters,
		"achievement_progress": _without_legacy_module_progress(_dictionary(parsed.get("achievement_progress", {}))),
		"completed_achievement_ids": normalized_completed_achievements,
		"claimed_achievement_ids": normalized_claimed_achievements,
		"stage_first_clear_reward_ids": _string_array(parsed.get("stage_first_clear_reward_ids", [])),
		"challenge_first_clear_reward_ids": _string_array(parsed.get("challenge_first_clear_reward_ids", [])),
		"settled_run_ids": _string_array(parsed.get("settled_run_ids", [])),
		"candidate_support": _nonnegative_numeric_dictionary(parsed.get("candidate_support", {})),
		"elected_candidate_ids": _string_array(parsed.get("elected_candidate_ids", [])),
		"candidate_decree_ids": _dictionary(parsed.get("candidate_decree_ids", {})),
		"governance_approval": _bounded_numeric_dictionary(parsed.get("governance_approval", {}), 0.0, 100.0),
		"candidate_clear_records": _dictionary(parsed.get("candidate_clear_records", {})),
		"candidate_rival_records": _dictionary(parsed.get("candidate_rival_records", {})),
		"candidate_first_clear_ids": normalized_candidate_first_clears,
		"retainer_first_clear_ids": normalized_retainer_first_clears,
		"legacy_full_unlock": true if is_pre_meta_legacy else bool(parsed.get("legacy_full_unlock", false)),
	}

func _migrate_legacy_enemy_encounters(legacy_total_runs: int, legacy_best_time: float) -> Array[String]:
	var result: Array[String] = []
	if legacy_total_runs <= 0:
		return result
	for enemy in DataRegistry.get_all_enemy_data():
		if enemy != null and legacy_best_time >= enemy.available_from_seconds:
			result.append(String(enemy.id))
	return result

func _migrate_identity_unlock_progress(
	normalized_unlocked_ids: Array[String],
	normalized_candidate_first_clears: Array[String],
	normalized_retainer_first_clears: Array[String],
	existing_candidate_records: Dictionary
) -> void:
	var campaign := ConceptService.get_election_campaign()
	if campaign == null:
		return
	for index in campaign.candidates.size():
		var candidate := campaign.candidates[index]
		if candidate == null:
			continue
		var record_value: Variant = existing_candidate_records.get(String(candidate.id), {})
		var has_recorded_victory := record_value is Dictionary and int((record_value as Dictionary).get("victories", 0)) > 0
		var successor_is_unlocked := index + 1 < campaign.candidates.size() and campaign.candidates[index + 1] != null and String(campaign.candidates[index + 1].core_id) in normalized_unlocked_ids
		if has_recorded_victory or successor_is_unlocked:
			_append_unique(normalized_candidate_first_clears, String(candidate.id))
		if has_recorded_victory and index + 1 < campaign.candidates.size() and campaign.candidates[index + 1] != null:
			_append_unique(normalized_unlocked_ids, String(campaign.candidates[index + 1].core_id))
	for index in campaign.retainers.size():
		var retainer := campaign.retainers[index]
		if retainer == null:
			continue
		var successor_is_unlocked := index + 1 < campaign.retainers.size() and campaign.retainers[index + 1] != null and String(campaign.retainers[index + 1].cursor_id) in normalized_unlocked_ids
		if successor_is_unlocked:
			_append_unique(normalized_retainer_first_clears, String(retainer.id))

func _apply_save_data(data: Dictionary) -> void:
	pending_enemy_encounter_ids.clear()
	enemy_encounter_flush_scheduled = false
	best_time = float(data.get("best_time", 0.0))
	best_level = int(data.get("best_level", 1))
	total_runs = int(data.get("total_runs", 0))
	unlocked_ids = _string_array(data.get("unlocked_ids", ["emerald", "iron"]), ["emerald", "iron"])
	cleared_stage_ids = _string_array(data.get("cleared_stage_ids", []))
	highest_challenge_by_stage = _dictionary(data.get("highest_challenge_by_stage", {}))
	selected_challenge_by_stage = _dictionary(data.get("selected_challenge_by_stage", {}))
	sound_enabled = bool(data.get("sound_enabled", true))
	screen_shake_enabled = bool(data.get("screen_shake_enabled", true))
	screen_flash_enabled = bool(data.get("screen_flash_enabled", true))
	reduced_motion_enabled = bool(data.get("reduced_motion_enabled", false))
	meta_progression_version = int(data.get("meta_progression_version", CURRENT_META_PROGRESSION_VERSION))
	unlock_sequence_revision = int(data.get("unlock_sequence_revision", META_UNLOCK_SEQUENCE_REVISION))
	tutorial_completion_revision = int(data.get("tutorial_completion_revision", TUTORIAL_COMPLETION_REVISION))
	encounter_discovery_revision = int(data.get("encounter_discovery_revision", ENCOUNTER_DISCOVERY_REVISION))
	tutorial_completed = bool(data.get("tutorial_completed", false))
	defense_funds = maxi(int(data.get("defense_funds", 0)), 0)
	unlocked_tower_ids = _string_array(data.get("unlocked_tower_ids", STARTER_TOWER_IDS), STARTER_TOWER_IDS)
	discovered_tower_use_ids = _string_array(data.get("discovered_tower_use_ids", STARTER_TOWER_IDS), STARTER_TOWER_IDS)
	unlocked_feature_ids = _string_array(data.get("unlocked_feature_ids", STARTER_FEATURE_IDS), STARTER_FEATURE_IDS)
	discovered_shop_product_ids = _string_array(data.get("discovered_shop_product_ids", []))
	purchased_shop_product_ids = _string_array(data.get("purchased_shop_product_ids", []))
	encountered_enemy_ids = _string_array(data.get("encountered_enemy_ids", []))
	achievement_progress = _dictionary(data.get("achievement_progress", {}))
	completed_achievement_ids = _string_array(data.get("completed_achievement_ids", []))
	claimed_achievement_ids = _string_array(data.get("claimed_achievement_ids", []))
	stage_first_clear_reward_ids = _string_array(data.get("stage_first_clear_reward_ids", []))
	challenge_first_clear_reward_ids = _string_array(data.get("challenge_first_clear_reward_ids", []))
	settled_run_ids = _string_array(data.get("settled_run_ids", []))
	candidate_support = _nonnegative_numeric_dictionary(data.get("candidate_support", {}))
	elected_candidate_ids = _string_array(data.get("elected_candidate_ids", []))
	candidate_decree_ids = _dictionary(data.get("candidate_decree_ids", {}))
	governance_approval = _bounded_numeric_dictionary(data.get("governance_approval", {}), 0.0, 100.0)
	candidate_clear_records = _dictionary(data.get("candidate_clear_records", {}))
	candidate_rival_records = _dictionary(data.get("candidate_rival_records", {}))
	candidate_first_clear_ids = _string_array(data.get("candidate_first_clear_ids", []))
	retainer_first_clear_ids = _string_array(data.get("retainer_first_clear_ids", []))
	legacy_full_unlock = bool(data.get("legacy_full_unlock", false))

func _string_array(value: Variant, fallback: Array[String] = []) -> Array[String]:
	var result: Array[String] = []
	var source: Variant = value if value is Array else fallback
	for item in source:
		var text := String(item)
		if not text.is_empty() and text not in result:
			result.append(text)
	return result

func _without_legacy_module_ids(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		if value == "module_system" or value == "unlock_module_system" or value.begins_with("module_") or value.begins_with("discover_module_"):
			continue
		result.append(value)
	return result

func _without_legacy_module_progress(values: Dictionary) -> Dictionary:
	var result := values.duplicate(true)
	for key in values:
		var text := String(key)
		if text == "unlock_module_system" or text.begins_with("discover_module_"):
			result.erase(key)
	return result

func _dictionary(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}

func _nonnegative_numeric_dictionary(value: Variant) -> Dictionary:
	return _bounded_numeric_dictionary(value, 0.0, INF)

func _bounded_numeric_dictionary(value: Variant, minimum: float, maximum: float) -> Dictionary:
	var result: Dictionary = {}
	if value is not Dictionary:
		return result
	for key in value:
		var item: Variant = value[key]
		if not _is_numeric(item):
			continue
		var number := clampf(float(item), minimum, maximum)
		result[String(key)] = roundi(number) if item is int else number
	return result

func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	save()

func set_screen_shake_enabled(enabled: bool) -> void:
	screen_shake_enabled = enabled
	save()

func set_screen_flash_enabled(enabled: bool) -> void:
	screen_flash_enabled = enabled
	save()

func set_reduced_motion_enabled(enabled: bool) -> void:
	reduced_motion_enabled = enabled
	save()
