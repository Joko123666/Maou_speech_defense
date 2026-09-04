class_name V016BalanceAuditPolicyContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	_expect(BalanceAuditBuildPolicy.IDS == [&"strong_synergy", &"average_coherent", &"weak_coherent", &"tangled"], "the build-policy axis must expose the four frozen v0.16 policy ids", failures)
	_expect(BalanceAuditSkillPolicy.IDS == [&"high", &"average", &"low"], "the skill-policy axis must expose the three frozen v0.16 policy ids", failures)
	_expect(EnemySpawnDirector.BONUS_MODES == [&"normal", &"disabled", &"capped"], "the bonus axis must expose normal, disabled, and capped modes", failures)

	var formation_choice := UpgradeData.new().configure(&"formation_set", "편대", "contract", &"balanced")
	var global_choice := UpgradeData.new().configure(&"global_upgrade", "전역", "contract", &"damage")
	var context := {"valid": true, "regular_formation_count": 0, "scenario_priority": 0}
	var strong := BalanceAuditBuildPolicy.new(&"strong_synergy")
	var average := BalanceAuditBuildPolicy.new(&"average_coherent")
	var tangled := BalanceAuditBuildPolicy.new(&"tangled")
	_expect(strong.score_choice(formation_choice, context) > strong.score_choice(global_choice, context), "strong synergy must prefer early role-completing formation coverage", failures)
	_expect(tangled.score_choice(global_choice, context) > tangled.score_choice(formation_choice, context), "tangled policy must deterministically prefer low-cohesion global growth", failures)
	var guard_choice := UpgradeData.new().configure(&"guard_training", "친위대 훈련", "contract", &"obsidian_tribunal")
	var tower_choice := UpgradeData.new().configure(&"tower_type_level", "병력 훈련", "contract", &"execute")
	_expect(average.score_choice(guard_choice, context) > average.score_choice(tower_choice, context), "average coherent policy must recognize guard progression as an ordinary build track", failures)
	var branch_a := UpgradeData.new().configure(&"guard_branch", "분기 A", "contract", &"branch_a")
	var branch_b := UpgradeData.new().configure(&"guard_branch", "분기 B", "contract", &"branch_b")
	var tie_context := {"scenario": "contract", "audit_seed": 1847, "selection_index": 7}
	_expect(average.tie_break_score(branch_a, tie_context) == average.tie_break_score(branch_a, tie_context), "equal-score tie breaking must be reproducible for the same public audit inputs", failures)
	_expect(average.tie_break_score(branch_a, tie_context) != average.tie_break_score(branch_b, tie_context), "equal-score tie breaking must distinguish alternative data ids instead of preserving resource order", failures)

	var high_movement := BalanceAuditMovementPolicy.new(&"high")
	var average_movement := BalanceAuditMovementPolicy.new(&"average")
	var low_movement := BalanceAuditMovementPolicy.new(&"low")
	_expect(high_movement.command_interval() < average_movement.command_interval() and average_movement.command_interval() < low_movement.command_interval(), "skill policies must use distinct command cadences", failures)
	var high_placement := BalanceAuditPlacementPolicy.new(&"high")
	var average_placement := BalanceAuditPlacementPolicy.new(&"average")
	var low_placement := BalanceAuditPlacementPolicy.new(&"low")
	_expect(high_placement.placement_index([0, 1, 2]) == 1 and average_placement.placement_index([0, 1, 2]) == 0 and low_placement.placement_index([0, 1, 2]) == 0, "skill policies must keep placement behavior independent from build selection", failures)
	var high_active := BalanceAuditActivePolicy.new(&"high")
	var average_active := BalanceAuditActivePolicy.new(&"average")
	var low_active := BalanceAuditActivePolicy.new(&"low")
	_expect(high_active.should_cast_core_skill(true, 10.0), "high skill must cast as soon as the public charge state is ready", failures)
	_expect(not average_active.should_cast_core_skill(true, 10.0) and average_active.should_cast_core_skill(true, 11.5), "average skill must apply its visible-state reaction delay", failures)
	_expect(not low_active.should_cast_core_skill(true, 10.0) and not low_active.should_cast_core_skill(true, 18.0) and low_active.should_cast_core_skill(true, 26.0), "low skill must delay and skip alternating ready opportunities deterministically", failures)

	var stage := ConceptService.get_default_stage()
	_expect(stage != null, "the bonus-mode contract requires the active stage", failures)
	if stage != null:
		var normal := _advanced_director(stage, &"normal")
		var disabled := _advanced_director(stage, &"disabled")
		var capped := _advanced_director(stage, &"capped")
		_expect(is_equal_approx(normal.base_budget_accrued, disabled.base_budget_accrued) and is_equal_approx(normal.base_budget_accrued, capped.base_budget_accrued), "bonus modes must never alter base budget accrual", failures)
		_expect(normal.bonus_budget_accrued > 0.0 and is_zero_approx(disabled.bonus_budget_accrued), "disabled mode must remove only bonus budget accrual", failures)
		_expect(is_equal_approx(capped.bonus_budget_accrued, normal.bonus_budget_accrued * 0.5), "capped mode must apply the declared bonus-budget ratio", failures)

	var audit_source := FileAccess.get_file_as_string("res://tests/balance_audit_runner.gd")
	var movement_source := FileAccess.get_file_as_string("res://tests/audit/balance_audit_movement_policy.gd")
	var matrix_source := FileAccess.get_file_as_string("res://tests/balance_audit_matrix_runner.gd")
	_expect(audit_source.contains("BalanceAuditBuildPolicy") and audit_source.contains("BalanceAuditPlacementPolicy") and audit_source.contains("BalanceAuditMovementPolicy") and audit_source.contains("BalanceAuditActivePolicy"), "selection, placement, movement, and active use must remain separate deterministic policy objects", failures)
	_expect(audit_source.contains("policy_action_counts") and audit_source.contains("policy_action_log") and audit_source.contains("experience_attribution") and audit_source.contains("tie_break_score"), "each audit report must disclose policy actions, deterministic tie breaks, and channel-attributed experience", failures)
	_expect(movement_source.contains("experience_orbs") and movement_source.contains("visible safe Base XP recovery") and audit_source.contains("target_orb_channel"), "average/high skill policies must implement observable, threat-gated Base XP recovery and disclose it in the action ledger", failures)
	_expect(matrix_source.contains("policy_cells") and matrix_source.contains("enemy_activity") and matrix_source.contains("prelude_windows"), "matrix summaries and speed fingerprints must include policy, enemy, and Prelude evidence", failures)
	_expect(matrix_source.contains("reports_by_cell") and matrix_source.contains("formation_diagnostics") and matrix_source.contains("specialization_diagnostics") and matrix_source.contains("cell[\"balance_assessment\"]"), "each policy cell must preserve its own formation, specialization, and balance diagnostics instead of relying on a cross-policy aggregate", failures)
	_expect(matrix_source.contains("policy_warning_overlap") and matrix_source.contains("common_warning_keys") and matrix_source.contains("policy_specific_warning_keys") and matrix_source.contains("_balance_finding_key"), "multi-policy summaries must distinguish shared warnings from policy-specific warning identities", failures)
	_expect(matrix_source.contains("reusing %d compatible report(s)") and matrix_source.contains("audit_target_seconds") and matrix_source.contains("BalanceAuditBuildPolicy.REVISION") and matrix_source.contains("RunRng.REVISION"), "expanded matrices may reuse only checkpoint reports with matching axes, duration, audit schema, build policy, and RNG revisions", failures)
	_expect(matrix_source.contains("scenario_diagnostics") and FileAccess.get_file_as_string("res://scripts/game/balance_audit_summary.gd").contains("mixed_scenario_specialization_bias_deferred"), "policy diagnostics must retain scenario cells and defer cross-scenario specialization bias warnings", failures)

	var mixed_reports: Array = []
	for scenario in ["candidate_a", "candidate_b"]:
		for seed in [11, 22, 33]:
			mixed_reports.append({
				"scenario": scenario, "seed": seed, "victory": false, "game_finished": true,
				"timed_out": false, "block_board": true, "audit_target_seconds": 600.0,
				"elapsed": 600.0, "level": 25, "total_experience": 5000.0, "kills": 100,
				"core_health": 0.0, "core_max_health": 200.0, "selection_policy": "average_coherent",
				"performance_budget": {"passed": true}, "runtime_performance": {}, "formation_metrics": {},
				"upgrade_choice_metrics": {"specialization_offers": {"tower_specialization_entry:contract": 1}, "specialization_selections": {}},
				"tower_score_efficiency": {}, "guard_combat": {}, "spawn_director": {}, "artifact_metrics": {},
			})
	var mixed_summary := BalanceAuditSummary.summarize(mixed_reports, mixed_reports.size())
	_expect(_has_finding(mixed_summary.balance_assessment as Dictionary, "mixed_scenario_specialization_bias_deferred") and not _has_finding(mixed_summary.balance_assessment as Dictionary, "specialization_never_selected"), "mixed-candidate aggregate must defer specialization bias instead of producing a cross-scenario warning", failures)
	for scenario in mixed_summary.by_scenario:
		_expect(_has_finding(((mixed_summary.by_scenario as Dictionary)[scenario] as Dictionary).balance_assessment as Dictionary, "specialization_never_selected"), "each three-seed scenario cell must retain its own specialization bias warning", failures)
	return failures

static func _advanced_director(stage: StageData, mode: StringName) -> EnemySpawnDirector:
	var director := EnemySpawnDirector.new()
	director.configure(stage, 0)
	director.configure_bonus_mode(mode, 0.5)
	director.advance(1.0, 0.0, 0.0, false)
	return director

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)

static func _has_finding(assessment: Dictionary, code: String) -> bool:
	for finding_value in assessment.get("findings", []) as Array:
		if finding_value is Dictionary and String((finding_value as Dictionary).get("code", "")) == code:
			return true
	return false
