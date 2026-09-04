extends Node

const CHECKPOINT_PATH := "user://td_survival_run_checkpoint.json"
const BACKUP_PATH := "user://td_survival_run_checkpoint.backup.json"
const TEMP_PATH := "user://td_survival_run_checkpoint.tmp"
const CHECKPOINT_VERSION := 3

var checkpoint: Dictionary = {}

func _ready() -> void:
	checkpoint = _read_checkpoint()

func begin_run(result: Dictionary, persist_to_disk: bool = true) -> bool:
	var run_id := String(result.get("run_id", ""))
	if run_id.is_empty():
		return false
	if has_confirmed_checkpoint() and String(checkpoint.get("run_id", "")) != run_id:
		return false
	var candidate := {
		"version": CHECKPOINT_VERSION,
		"run_id": run_id,
		"confirmed": false,
		"result": _normalize_result(result),
		"updated_unix": Time.get_unix_time_from_system(),
	}
	return _commit_checkpoint(candidate, persist_to_disk)

func confirm_checkpoint(result: Dictionary, persist_to_disk: bool = true) -> bool:
	var run_id := String(result.get("run_id", ""))
	if run_id.is_empty():
		return false
	var active_run_id := String(checkpoint.get("run_id", ""))
	if not active_run_id.is_empty() and active_run_id != run_id:
		return false
	var candidate := {
		"version": CHECKPOINT_VERSION,
		"run_id": run_id,
		"confirmed": true,
		"result": _normalize_result(result),
		"updated_unix": Time.get_unix_time_from_system(),
	}
	return _commit_checkpoint(candidate, persist_to_disk)

func has_confirmed_checkpoint() -> bool:
	return bool(checkpoint.get("confirmed", false)) and not String(checkpoint.get("run_id", "")).is_empty()

func get_pending_result(outcome: String = "recovered") -> Dictionary:
	if not has_confirmed_checkpoint():
		return {}
	var result_value: Variant = checkpoint.get("result", {})
	if result_value is not Dictionary:
		return {}
	var result: Dictionary = result_value.duplicate(true)
	result["run_id"] = String(checkpoint.get("run_id", ""))
	result["outcome"] = outcome
	result["checkpoint_recovery"] = outcome == "recovered"
	return result

func settle_pending(outcome: String = "recovered", expected_run_id: String = "") -> Dictionary:
	if not expected_run_id.is_empty() and String(checkpoint.get("run_id", "")) != expected_run_id:
		return {"completed": false, "settled": false, "duplicate": false, "funds": 0, "reason": "run_id_mismatch"}
	var result := get_pending_result(outcome)
	if result.is_empty():
		clear_checkpoint()
		return {"completed": true, "settled": false, "duplicate": false, "funds": 0, "reason": "no_confirmed_checkpoint"}
	var settlement := MetaProgressionService.settle_run(result)
	var awarded := bool(settlement.get("awarded", false))
	var duplicate := bool(settlement.get("duplicate", false))
	var breakdown: Dictionary = settlement.get("breakdown", {})
	var funds := int(breakdown.get("total_funds", 0))
	if awarded or duplicate:
		clear_checkpoint()
	if awarded:
		var boss_count := (result.get("boss_kill_ids", []) as Array).size()
		var label := "비정상 종료 복구" if outcome == "recovered" else "출격 포기 정산"
		GameSession.meta_notice = "%s · %s %d기 체크포인트 · %s +%d" % [label, ConceptService.term(&"boss"), boss_count, ConceptService.term(&"currency"), funds]
	return {
		"completed": awarded or duplicate,
		"settled": awarded,
		"duplicate": duplicate,
		"funds": funds,
		"reason": "" if awarded or duplicate else "save_failed",
		"result": result,
		"settlement": settlement,
	}

func recover_pending() -> Dictionary:
	return settle_pending("recovered")

func clear_run(run_id: String) -> void:
	if not run_id.is_empty() and String(checkpoint.get("run_id", "")) == run_id:
		clear_checkpoint()

func clear_checkpoint(remove_from_disk: bool = true) -> void:
	checkpoint.clear()
	if remove_from_disk:
		_clear_checkpoint_files(CHECKPOINT_PATH, BACKUP_PATH, TEMP_PATH)

func _normalize_result(result: Dictionary) -> Dictionary:
	var normalized := result.duplicate(true)
	normalized["run_id"] = String(result.get("run_id", ""))
	normalized["stage_id"] = String(result.get("stage_id", ""))
	normalized["elapsed"] = maxf(float(result.get("elapsed", 0.0)), 0.0)
	normalized["level"] = maxi(int(result.get("level", 1)), 1)
	normalized["challenge_level"] = ChallengeRules.clamp_level(int(result.get("challenge_level", 0)))
	normalized["victory"] = bool(result.get("victory", false))
	normalized["eligible_for_meta_rewards"] = true
	normalized["candidate_id"] = String(result.get("candidate_id", ""))
	normalized["retainer_id"] = String(result.get("retainer_id", ""))
	normalized["decree_id"] = String(result.get("decree_id", ""))
	normalized["decree_name"] = String(result.get("decree_name", ""))
	normalized["candidate_elected"] = bool(result.get("candidate_elected", false))
	normalized["governance_approval"] = clampi(int(result.get("governance_approval", 0)), 0, 100)
	return normalized

func _read_checkpoint() -> Dictionary:
	return _read_checkpoint_from_paths(CHECKPOINT_PATH, BACKUP_PATH)

func _read_checkpoint_from_paths(checkpoint_path: String, backup_path: String) -> Dictionary:
	var primary := _validate_checkpoint(_read_checkpoint_file(checkpoint_path))
	if not primary.is_empty():
		return primary
	return _validate_checkpoint(_read_checkpoint_file(backup_path))

func _validate_checkpoint(data: Dictionary) -> Dictionary:
	if data.is_empty() or not _is_numeric(data.get("version", null)):
		return {}
	var version := int(data.get("version", 0))
	if version not in [1, 2, CHECKPOINT_VERSION]:
		return {}
	if data.get("run_id", null) is not String or String(data.get("run_id", "")).is_empty():
		return {}
	if data.get("confirmed", null) is not bool or not _is_numeric(data.get("updated_unix", null)):
		return {}
	var result_value: Variant = data.get("result", null)
	if result_value is not Dictionary:
		return {}
	var result: Dictionary = result_value
	if result.get("run_id", null) is not String or String(result.get("run_id", "")) != String(data.get("run_id", "")):
		return {}
	if result.get("stage_id", null) is not String or String(result.get("stage_id", "")).is_empty():
		return {}
	for field in ["stage_duration_seconds", "elapsed", "level", "challenge_level"]:
		if not _is_numeric(result.get(field, null)):
			return {}
	if float(result.get("stage_duration_seconds", 0.0)) <= 0.0 or float(result.get("elapsed", -1.0)) < 0.0 or int(result.get("level", 0)) < 1:
		return {}
	if result.get("victory", null) is not bool or result.get("eligible_for_meta_rewards", null) is not bool:
		return {}
	if result.get("boss_kill_ids", null) is not Array or result.get("meta_metrics", null) is not Dictionary:
		return {}
	if version >= 2 and not StageRuntimeBossPlan.is_valid_snapshot(result.get("boss_plan", null)):
		return {}
	if version >= 3:
		var plan: Dictionary = result.get("boss_plan", {})
		if StringName(plan.get("source", "")) == StageRuntimeBossPlan.SOURCE_CAMPAIGN:
			if result.get("candidate_id", null) is not String or String(result.get("candidate_id", "")).is_empty():
				return {}
			if result.get("retainer_id", null) is not String or String(result.get("retainer_id", "")).is_empty():
				return {}
			if result.get("rival_candidate_ids", null) is not Array or (result.get("rival_candidate_ids", []) as Array).size() != (plan.get("slots", []) as Array).size():
				return {}
			if not _is_numeric(result.get("support_required_for_election", null)) or int(result.get("support_required_for_election", 0)) <= 0:
				return {}
			if result.get("candidate_decree_ids_available", null) is not Array or (result.get("candidate_decree_ids_available", []) as Array).size() != 3:
				return {}
			if result.get("decree_id", null) is not String or result.get("decree_name", null) is not String:
				return {}
			if result.has("candidate_elected") and result.candidate_elected is not bool:
				return {}
			if result.has("governance_approval") and (not _is_numeric(result.governance_approval) or int(result.governance_approval) < 0 or int(result.governance_approval) > 100):
				return {}
	return data.duplicate(true)

func _is_numeric(value: Variant) -> bool:
	return value is int or value is float

func _read_checkpoint_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is not Dictionary:
		return {}
	return (parsed as Dictionary).duplicate(true)

func _write_checkpoint() -> bool:
	return _write_checkpoint_to_paths(checkpoint, CHECKPOINT_PATH, BACKUP_PATH, TEMP_PATH)

func _commit_checkpoint(candidate: Dictionary, persist_to_disk: bool = true, writer: Callable = Callable()) -> bool:
	var validated := _validate_checkpoint(candidate)
	if validated.is_empty():
		return false
	if persist_to_disk:
		var write_succeeded := bool(writer.call(validated)) if writer.is_valid() else _write_checkpoint_to_paths(validated, CHECKPOINT_PATH, BACKUP_PATH, TEMP_PATH)
		if not write_succeeded:
			return false
	checkpoint = validated
	return true

func _write_checkpoint_to_paths(data: Dictionary, checkpoint_path: String, backup_path: String, temp_path: String) -> bool:
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()
	var checkpoint_absolute := ProjectSettings.globalize_path(checkpoint_path)
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	var temp_absolute := ProjectSettings.globalize_path(temp_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_absolute)
	var moved_existing := false
	if FileAccess.file_exists(checkpoint_path):
		if DirAccess.rename_absolute(checkpoint_absolute, backup_absolute) != OK:
			DirAccess.remove_absolute(temp_absolute)
			return false
		moved_existing = true
	if DirAccess.rename_absolute(temp_absolute, checkpoint_absolute) == OK:
		return true
	if moved_existing:
		DirAccess.rename_absolute(backup_absolute, checkpoint_absolute)
	DirAccess.remove_absolute(temp_absolute)
	return false

func _clear_checkpoint_files(checkpoint_path: String, backup_path: String, temp_path: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(checkpoint_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp_path))
