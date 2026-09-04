extends Node

const AUDIT_SCENE := "res://tests/balance_audit.tscn"
const RESULT_PREFIX := "BALANCE_AUDIT_RESULT_B64 "
const AUDIT_REPORT_SCHEMA_VERSION := 20
const DEFAULT_SCENARIOS := ["judgment_vanguard"]
const DEFAULT_SEEDS := [1847, 42731, 99881]
const DEFAULT_SPEEDS := [3]
const DEFAULT_BUILD_POLICIES := ["strong_synergy"]
const DEFAULT_SKILL_POLICIES := ["high"]
const DEFAULT_BONUS_MODES := ["normal"]

var scenarios: Array[String] = []
var seeds: Array[int] = []
var speeds: Array[int] = []
var build_policies: Array[String] = []
var skill_policies: Array[String] = []
var bonus_modes: Array[String] = []
var artifact_mode: StringName = GameSession.ARTIFACT_MODE_DISABLED
var audit_seconds := 600.0
var checkpoint_path := "user://balance_audit_matrix_checkpoint.json"
var result_path := "user://balance_audit_matrix_latest.json"
var resume_checkpoint := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_parse_arguments()
	_run_matrix.call_deferred()

func _parse_arguments() -> void:
	scenarios.assign(DEFAULT_SCENARIOS)
	seeds.assign(DEFAULT_SEEDS)
	speeds.assign(DEFAULT_SPEEDS)
	build_policies.assign(DEFAULT_BUILD_POLICIES)
	skill_policies.assign(DEFAULT_SKILL_POLICIES)
	bonus_modes.assign(DEFAULT_BONUS_MODES)
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--scenarios="):
			scenarios = _parse_string_list(argument.trim_prefix("--scenarios="))
		elif argument.begins_with("--seeds="):
			seeds = _parse_int_list(argument.trim_prefix("--seeds="))
		elif argument.begins_with("--speeds="):
			speeds = _parse_speed_list(argument.trim_prefix("--speeds="))
		elif argument.begins_with("--build-policies="):
			build_policies = _parse_allowed_string_list(argument.trim_prefix("--build-policies="), BalanceAuditBuildPolicy.IDS)
		elif argument.begins_with("--skill-policies="):
			skill_policies = _parse_allowed_string_list(argument.trim_prefix("--skill-policies="), BalanceAuditSkillPolicy.IDS)
		elif argument.begins_with("--bonus-modes="):
			bonus_modes = _parse_allowed_string_list(argument.trim_prefix("--bonus-modes="), EnemySpawnDirector.BONUS_MODES)
		elif argument.begins_with("--artifact-mode="):
			artifact_mode = StringName(argument.trim_prefix("--artifact-mode="))
		elif argument.begins_with("--audit-seconds="):
			audit_seconds = maxf(float(argument.trim_prefix("--audit-seconds=")), 30.0)
		elif argument.begins_with("--checkpoint="):
			checkpoint_path = argument.trim_prefix("--checkpoint=").strip_edges()
		elif argument.begins_with("--result="):
			result_path = argument.trim_prefix("--result=").strip_edges()
		elif argument == "--resume":
			resume_checkpoint = true

func _run_matrix() -> void:
	if scenarios.is_empty() or seeds.is_empty() or speeds.is_empty() or build_policies.is_empty() or skill_policies.is_empty() or bonus_modes.is_empty() or artifact_mode not in GameSession.ARTIFACT_MODES:
		push_error("BALANCE AUDIT MATRIX requires every scenario, seed, speed, build, skill, and bonus axis")
		get_tree().quit(2)
		return
	AudioManager.muted = true
	var signature := _configuration_signature()
	var reports: Array = _load_checkpoint_reports(signature) if resume_checkpoint else []
	var child_failures: Array[String] = []
	var io_failures: Array[String] = []
	var resumed_runs := 0
	var executed_runs := 0
	if not resume_checkpoint and not _write_json(checkpoint_path, {"signature": signature, "reports": reports}):
		io_failures.append("checkpoint initialization failed: %s" % checkpoint_path)
	var project_path := ProjectSettings.globalize_path("res://")
	for scenario in scenarios:
		for seed in seeds:
			for speed in speeds:
				for build_policy in build_policies:
					for skill_policy in skill_policies:
						for bonus_mode in bonus_modes:
							var report_index := _report_index(reports, scenario, seed, speed, build_policy, skill_policy, bonus_mode)
							var run_label := "%s:%d:%dx:%s/%s/%s:artifact=%s" % [scenario, seed, speed, build_policy, skill_policy, bonus_mode, artifact_mode]
							if report_index >= 0:
								var checkpoint_report := reports[report_index] as Dictionary
								if _report_quality_valid(checkpoint_report):
									print("BALANCE AUDIT MATRIX RESUME %s" % run_label)
									resumed_runs += 1
									continue
								reports.remove_at(report_index)
							print("BALANCE AUDIT MATRIX RUN %s" % run_label)
							executed_runs += 1
							var output: Array = []
							var arguments := [
								"--headless",
								"--path", project_path,
								AUDIT_SCENE,
								"--",
								"--scenario=%s" % scenario,
								"--audit-seconds=%s" % audit_seconds,
								"--seed=%d" % seed,
								"--speed=%d" % speed,
								"--build-policy=%s" % build_policy,
								"--skill-policy=%s" % skill_policy,
								"--bonus-mode=%s" % bonus_mode,
								"--artifact-mode=%s" % artifact_mode,
							]
							var exit_code := OS.execute(OS.get_executable_path(), arguments, output, true, false)
							var report := _extract_report(output)
							if exit_code != 0 or report.is_empty():
								child_failures.append("%s exit=%d result=%s" % [run_label, exit_code, not report.is_empty()])
								continue
							reports.append(report)
							if not _write_json(checkpoint_path, {"signature": signature, "reports": reports}):
								io_failures.append("checkpoint update failed: %s" % run_label)
	var expected_runs := scenarios.size() * seeds.size() * speeds.size() * build_policies.size() * skill_policies.size() * bonus_modes.size()
	var summary := BalanceAuditSummary.summarize(reports, expected_runs)
	summary["audit_schema_version"] = AUDIT_REPORT_SCHEMA_VERSION
	summary["build_policy_revision"] = BalanceAuditBuildPolicy.REVISION
	summary["rng_revision"] = RunRng.REVISION
	summary["scenarios"] = scenarios
	summary["requested_seeds"] = seeds
	summary["requested_speeds"] = speeds
	summary["requested_build_policies"] = build_policies
	summary["requested_skill_policies"] = skill_policies
	summary["requested_bonus_modes"] = bonus_modes
	summary["artifact_mode"] = String(artifact_mode)
	var policy_cells := _policy_cell_summary(reports)
	summary["policy_cells"] = policy_cells
	summary["policy_warning_overlap"] = _policy_warning_overlap(policy_cells)
	summary["audit_seconds"] = audit_seconds
	summary["child_failures"] = child_failures
	summary["io_failures"] = io_failures
	summary["checkpoint_path"] = checkpoint_path
	summary["result_path"] = result_path
	summary["executed_runs"] = executed_runs
	summary["resumed_runs"] = resumed_runs
	var speed_equivalence := _evaluate_speed_equivalence(reports)
	summary["speed_equivalence"] = speed_equivalence
	if bool(speed_equivalence.checked) and not bool(speed_equivalence.passed):
		summary["quality_gate_passed"] = false
	if not child_failures.is_empty() or not io_failures.is_empty():
		summary["quality_gate_passed"] = false
	if not _write_json(result_path, summary):
		io_failures.append("result write failed: %s" % result_path)
		summary["io_failures"] = io_failures
		summary["quality_gate_passed"] = false
	print("BALANCE_AUDIT_MATRIX_RESULT %s" % JSON.stringify(summary))
	AudioManager.release_voice_pool()
	get_tree().quit(0 if bool(summary.quality_gate_passed) else 1)

func _extract_report(output: Array) -> Dictionary:
	for chunk_value in output:
		for line in String(chunk_value).split("\n"):
			var clean_line := line.strip_edges()
			var prefix_index := clean_line.find(RESULT_PREFIX)
			if prefix_index < 0:
				continue
			var encoded_result := clean_line.substr(prefix_index + RESULT_PREFIX.length())
			var json_text := Marshalls.base64_to_utf8(encoded_result)
			var parser := JSON.new()
			if parser.parse(json_text) == OK and parser.data is Dictionary:
				return parser.data as Dictionary
			var suspicious := ""
			for index in json_text.length():
				var codepoint := json_text.unicode_at(index)
				if codepoint < 32:
					suspicious = "control U+%04X at %d" % [codepoint, index]
					break
			if suspicious.is_empty():
				for token in [":nan", ":inf", ":-inf"]:
					var token_index := json_text.find(token)
					if token_index >= 0:
						suspicious = "%s at %d" % [token, token_index]
						break
			push_warning("BALANCE AUDIT MATRIX JSON parse failed: %s · %s · head=%s · tail=%s" % [parser.get_error_message(), suspicious, JSON.stringify(json_text.left(120)), JSON.stringify(json_text.right(120))])
	return {}

func _configuration_signature() -> String:
	return JSON.stringify({"schema_version": AUDIT_REPORT_SCHEMA_VERSION, "build_policy_revision": BalanceAuditBuildPolicy.REVISION, "rng_revision": RunRng.REVISION, "artifact_mode": String(artifact_mode), "scenarios": scenarios, "seeds": seeds, "speeds": speeds, "build_policies": build_policies, "skill_policies": skill_policies, "bonus_modes": bonus_modes, "audit_seconds": audit_seconds})

func _report_index(reports: Array, scenario: String, seed: int, speed: int, build_policy: String, skill_policy: String, bonus_mode: String) -> int:
	for index in reports.size():
		var report_value = reports[index]
		if report_value is Dictionary:
			var report := report_value as Dictionary
			if String(report.get("scenario", "")) == scenario and int(report.get("seed", 0)) == seed and int(report.get("game_speed", 0)) == speed and String(report.get("build_policy", "")) == build_policy and String(report.get("skill_policy", "")) == skill_policy and String(report.get("bonus_mode", "")) == bonus_mode:
				return index
	return -1

func _evaluate_speed_equivalence(reports: Array) -> Dictionary:
	if speeds.size() <= 1:
		return {"checked": false, "passed": true, "mismatches": []}
	var mismatches: Array[String] = []
	for scenario in scenarios:
		for seed in seeds:
			for build_policy in build_policies:
				for skill_policy in skill_policies:
					for bonus_mode in bonus_modes:
						var cell := "%s:%d:%s/%s/%s" % [scenario, seed, build_policy, skill_policy, bonus_mode]
						var reference := _find_report(reports, scenario, seed, speeds[0], build_policy, skill_policy, bonus_mode)
						if reference.is_empty():
							mismatches.append("%s missing %dx reference" % [cell, speeds[0]])
							continue
						var reference_fingerprint := _simulation_fingerprint(reference)
						for speed in speeds.slice(1):
							var candidate := _find_report(reports, scenario, seed, speed, build_policy, skill_policy, bonus_mode)
							if candidate.is_empty():
								mismatches.append("%s missing %dx" % [cell, speed])
							elif _simulation_fingerprint(candidate) != reference_fingerprint:
								mismatches.append("%s %dx differs from %dx" % [cell, speed, speeds[0]])
	return {"checked": true, "passed": mismatches.is_empty(), "mismatches": mismatches}

func _find_report(reports: Array, scenario: String, seed: int, speed: int, build_policy: String, skill_policy: String, bonus_mode: String) -> Dictionary:
	var index := _report_index(reports, scenario, seed, speed, build_policy, skill_policy, bonus_mode)
	return reports[index] as Dictionary if index >= 0 else {}

func _simulation_fingerprint(report: Dictionary) -> String:
	var spawn := report.get("spawn_director", {}) as Dictionary
	return JSON.stringify({
		"victory": bool(report.get("victory", false)),
		"game_finished": bool(report.get("game_finished", false)),
		"level": int(report.get("level", 0)),
		"total_experience": snappedf(float(report.get("total_experience", 0.0)), 0.001),
		"kills": int(report.get("kills", 0)),
		"boss_kills": int(report.get("boss_kills", 0)),
		"core_health": snappedf(float(report.get("core_health", 0.0)), 0.001),
		"base_spawn_count": int(spawn.get("base_spawn_count", 0)),
		"bonus_spawn_count": int(spawn.get("bonus_spawn_count", 0)),
		"prelude_windows": _stable_event_fingerprint(spawn.get("prelude_windows", []), []),
		"enemy_activity": _enemy_activity_fingerprint((report.get("outcome_summary", {}) as Dictionary).get("enemy", {})),
		"policy_actions": report.get("policy_actions", {}),
		"policy_action_log": _stable_event_fingerprint(report.get("policy_action_log", []), ["elapsed", "destination_x", "destination_y"]),
		"growth_timeline": _growth_timeline_fingerprint(report.get("growth_timeline", {})),
		"artifact_events": _stable_event_fingerprint((report.get("artifact_metrics", {}) as Dictionary).get("events", []), ["elapsed"]),
		"artifacts": report.get("artifacts", {}),
		"selected_upgrades": report.get("selected_upgrades", {}),
		"formation_board": report.get("formation_board", []),
	})

func _enemy_activity_fingerprint(activity_value: Variant) -> Dictionary:
	var activity := activity_value as Dictionary
	return {
		"spawns": _stable_event_fingerprint(activity.get("spawns", []), ["elapsed", "spawn_time", "enemy_instance_id"]),
		"exits": _stable_event_fingerprint(activity.get("exits", []), ["elapsed", "spawn_time", "enemy_instance_id"]),
		"accelerations": _stable_event_fingerprint(activity.get("accelerations", []), ["elapsed", "spawn_time"]),
		"defender_disables": _stable_event_fingerprint(activity.get("defender_disables", []), ["elapsed", "spawn_time"]),
		"spawn_count": int(activity.get("spawn_count", 0)),
		"death_count": int(activity.get("death_count", 0)),
		"breach_count": int(activity.get("breach_count", 0)),
	}

func _growth_timeline_fingerprint(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return {}
	var timeline := value as Dictionary
	return {
		"levels": _stable_event_fingerprint(timeline.get("levels", []), ["elapsed"]),
		"offers": _stable_event_fingerprint(timeline.get("offers", []), ["elapsed"]),
		"upgrades": _stable_event_fingerprint(timeline.get("upgrades", []), ["elapsed"]),
	}

func _stable_event_fingerprint(events_value: Variant, volatile_fields: Array[String]) -> Array[String]:
	var result: Array[String] = []
	if not events_value is Array:
		return result
	for event_value in events_value as Array:
		if event_value is Dictionary:
			var event := (event_value as Dictionary).duplicate(true)
			for field in volatile_fields:
				event.erase(field)
			result.append(JSON.stringify(event))
	result.sort()
	return result

func _report_quality_valid(report: Dictionary) -> bool:
	return (
		int(report.get("audit_schema_version", 0)) == AUDIT_REPORT_SCHEMA_VERSION
		and int(report.get("build_policy_revision", 0)) == BalanceAuditBuildPolicy.REVISION
		and int(report.get("rng_revision", 0)) == RunRng.REVISION
		and is_equal_approx(float(report.get("audit_target_seconds", 0.0)), audit_seconds)
		and bool(report.get("block_board", false))
		and not bool(report.get("timed_out", false))
		and bool((report.get("performance_budget", {}) as Dictionary).get("passed", false))
		and String(report.get("scenario", "")) in scenarios
		and int(report.get("seed", 0)) in seeds
		and int(report.get("game_speed", 0)) in speeds
		and String(report.get("build_policy", "")) in build_policies
		and String(report.get("skill_policy", "")) in skill_policies
		and String(report.get("bonus_mode", "")) in bonus_modes
		and StringName(report.get("artifact_mode", "")) == artifact_mode
		and report.get("policy_actions", null) is Dictionary
	)

func _policy_cell_summary(reports: Array) -> Dictionary:
	var cells := {}
	var reports_by_cell := {}
	for report_value in reports:
		if not report_value is Dictionary:
			continue
		var report := report_value as Dictionary
		var key := "%s/%s/%s/artifact=%s" % [report.get("build_policy", ""), report.get("skill_policy", ""), report.get("bonus_mode", ""), report.get("artifact_mode", "")]
		var cell_reports := reports_by_cell.get(key, []) as Array
		cell_reports.append(report)
		reports_by_cell[key] = cell_reports
		var cell := cells.get(key, {"runs": 0, "victories": 0, "final_boss_challenges": 0, "elapsed_total": 0.0, "level_total": 0.0, "core_health_ratio_total": 0.0}) as Dictionary
		cell.runs = int(cell.runs) + 1
		cell.victories = int(cell.victories) + (1 if bool(report.get("victory", false)) else 0)
		cell.final_boss_challenges = int(cell.final_boss_challenges) + (1 if bool(report.get("final_boss_challenged", false)) else 0)
		cell.elapsed_total = float(cell.elapsed_total) + float(report.get("elapsed", 0.0))
		cell.level_total = float(cell.level_total) + float(report.get("level", 0))
		cell.core_health_ratio_total = float(cell.core_health_ratio_total) + float(report.get("core_health", 0.0)) / maxf(float(report.get("core_max_health", 1.0)), 1.0)
		cells[key] = cell
	for key in cells:
		var cell := cells[key] as Dictionary
		var runs := maxi(int(cell.runs), 1)
		cell["victory_rate"] = float(cell.victories) / runs
		cell["final_boss_challenge_rate"] = float(cell.final_boss_challenges) / runs
		cell["average_elapsed"] = float(cell.elapsed_total) / runs
		cell["average_level"] = float(cell.level_total) / runs
		cell["average_core_health_ratio"] = float(cell.core_health_ratio_total) / runs
		cell.erase("elapsed_total")
		cell.erase("level_total")
		cell.erase("core_health_ratio_total")
		var cell_reports := reports_by_cell.get(key, []) as Array
		var diagnostics := BalanceAuditSummary.summarize(cell_reports, cell_reports.size())
		var formation_metrics := diagnostics.get("formation_metrics", {}) as Dictionary
		var specialization_metrics := diagnostics.get("specialization_metrics", {}) as Dictionary
		cell["balance_assessment"] = diagnostics.get("balance_assessment", {})
		cell["scenario_diagnostics"] = diagnostics.get("by_scenario", {})
		cell["formation_diagnostics"] = {
			"by_shape": formation_metrics.get("by_shape", {}),
			"by_distinct_tower_count": formation_metrics.get("by_distinct_tower_count", {}),
			"set_offers_by_size": formation_metrics.get("set_offers_by_size", {}),
			"set_selections_by_size": formation_metrics.get("set_selections_by_size", {}),
			"set_selection_rates_by_size": formation_metrics.get("set_selection_rates_by_size", {}),
		}
		cell["specialization_diagnostics"] = {
			"offers": specialization_metrics.get("offers", {}),
			"selections": specialization_metrics.get("selections", {}),
			"selection_rates": specialization_metrics.get("selection_rates", {}),
		}
	return cells

func _policy_warning_overlap(cells: Dictionary) -> Dictionary:
	var warning_keys_by_cell := {}
	var common_warning_keys: Array[String] = []
	var initialized := false
	for cell_key in cells:
		var cell := cells[cell_key] as Dictionary
		var assessment := cell.get("balance_assessment", {}) as Dictionary
		var warning_keys: Array[String] = []
		for finding_value in assessment.get("findings", []) as Array:
			if not finding_value is Dictionary:
				continue
			var finding := finding_value as Dictionary
			if String(finding.get("severity", "")) != "warning":
				continue
			var warning_key := _balance_finding_key(finding)
			if not warning_key.is_empty() and warning_key not in warning_keys:
				warning_keys.append(warning_key)
		warning_keys.sort()
		warning_keys_by_cell[cell_key] = warning_keys
		if not initialized:
			common_warning_keys.assign(warning_keys)
			initialized = true
		else:
			for existing_key in common_warning_keys.duplicate():
				if existing_key not in warning_keys:
					common_warning_keys.erase(existing_key)
	var policy_specific_warning_keys := {}
	for cell_key in warning_keys_by_cell:
		var specific_keys: Array[String] = []
		for warning_key in warning_keys_by_cell[cell_key] as Array:
			if warning_key not in common_warning_keys:
				specific_keys.append(String(warning_key))
		policy_specific_warning_keys[cell_key] = specific_keys
	return {
		"checked": cells.size() > 1,
		"compared_cells": cells.size(),
		"common_warning_keys": common_warning_keys if cells.size() > 1 else [],
		"warning_keys_by_cell": warning_keys_by_cell,
		"policy_specific_warning_keys": policy_specific_warning_keys,
	}

func _balance_finding_key(finding: Dictionary) -> String:
	var code := String(finding.get("code", ""))
	if code.is_empty():
		return ""
	var parts: Array[String] = [code]
	var evidence := finding.get("evidence", {}) as Dictionary
	for field in ["specialization_id", "formation_id", "size", "value", "efficiency_cohort", "artifact_id", "target_group"]:
		if evidence.has(field):
			parts.append("%s=%s" % [field, evidence[field]])
	return "|".join(parts)

func _load_checkpoint_reports(signature: String) -> Array:
	if checkpoint_path.is_empty() or not FileAccess.file_exists(checkpoint_path):
		return []
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(checkpoint_path))
	if not parsed is Dictionary:
		push_warning("BALANCE AUDIT MATRIX checkpoint is not valid JSON: %s" % checkpoint_path)
		return []
	var checkpoint := parsed as Dictionary
	var compatible_reports: Array = []
	for report_value in checkpoint.get("reports", []) as Array:
		if report_value is Dictionary and _report_quality_valid(report_value as Dictionary):
			compatible_reports.append((report_value as Dictionary).duplicate(true))
	if String(checkpoint.get("signature", "")) != signature:
		push_warning("BALANCE AUDIT MATRIX checkpoint configuration changed; reusing %d compatible report(s)" % compatible_reports.size())
	return compatible_reports

func _write_json(path: String, data: Dictionary) -> bool:
	if path.is_empty():
		return true
	var absolute_path := ProjectSettings.globalize_path(path)
	var directory_path := absolute_path.get_base_dir()
	if not directory_path.is_empty() and DirAccess.make_dir_recursive_absolute(directory_path) != OK:
		return false
	var file := FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()
	return true

func _parse_string_list(value: String) -> Array[String]:
	var result: Array[String] = []
	for item in value.split(",", false):
		var cleaned := item.strip_edges()
		if not cleaned.is_empty() and cleaned not in result:
			result.append(cleaned)
	return result

func _parse_int_list(value: String) -> Array[int]:
	var result: Array[int] = []
	for item in value.split(",", false):
		var cleaned := item.strip_edges()
		if cleaned.is_valid_int():
			var parsed := int(cleaned)
			if parsed not in result:
				result.append(parsed)
	return result

func _parse_speed_list(value: String) -> Array[int]:
	var result: Array[int] = []
	for parsed in _parse_int_list(value):
		var speed := clampi(parsed, 1, 3)
		if speed not in result:
			result.append(speed)
	return result

func _parse_allowed_string_list(value: String, allowed: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for item in _parse_string_list(value):
		if StringName(item) in allowed and item not in result:
			result.append(item)
	return result
