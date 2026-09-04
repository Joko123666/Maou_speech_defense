class_name V019M8ArtifactMetricsAuditContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalog := load(ArtifactEffectResolver.CATALOG_PATH) as ArtifactCatalogData
	var loadout := LoadoutManager.new()
	var metrics := RunMetrics.new()
	var acquisition_ids: Array[StringName] = [&"war_banner", &"green_gear", &"blue_lens", &"crown_shard", &"silver_spur", &"toxin_ampoule"]
	for index in acquisition_ids.size():
		var artifact_id := acquisition_ids[index]
		var artifact := catalog.find_artifact(artifact_id)
		var choice := ArtifactOfferService.build_choice(artifact)
		var offered_choices: Array[UpgradeData] = [choice]
		metrics.update_time(float(index + 1) * 10.0)
		metrics.record_choices(offered_choices)
		_expect(loadout.artifact_inventory.equip(artifact_id), "M8 metric fixture artifacts must occupy distinct inventory slots", failures)
		metrics.record_artifact_decision(artifact, &"acquired", loadout.get_artifact_snapshot())
		metrics.record_selection(choice)
	var discarded := catalog.find_artifact(&"blood_prism")
	metrics.update_time(90.0)
	var discarded_choices: Array[UpgradeData] = [ArtifactOfferService.build_choice(discarded)]
	metrics.record_choices(discarded_choices)
	metrics.record_artifact_decision(discarded, &"discarded", loadout.get_artifact_snapshot())
	metrics.update_time(120.0)
	metrics.record_choices(discarded_choices)
	var replaced_id := loadout.artifact_inventory.artifact_ids[0]
	_expect(loadout.artifact_inventory.replace(0, discarded.id), "M8 metric fixture must replace exactly one full-inventory artifact", failures)
	metrics.record_artifact_decision(discarded, &"replaced", loadout.get_artifact_snapshot(), replaced_id)
	metrics.record_selection(ArtifactOfferService.build_choice(discarded))
	metrics.update_time(600.0)
	metrics.tower_damage = {"rapid": 1200.0}
	metrics.cursor_damage = 500.0
	metrics.damage_by_source_type = {"core": 900.0}
	metrics.status_damage = {"poison": 140.0}
	var artifact_metrics := metrics.artifact_metrics_snapshot(loadout)
	_expect(int(artifact_metrics.offers) == 8 and int(artifact_metrics.acquisitions) == 7 and int(artifact_metrics.discards) == 1 and int(artifact_metrics.replacements) == 1, "artifact metrics must preserve offer, acquisition, discard, and replacement counts independently", failures)
	_expect(is_equal_approx(float(artifact_metrics.inventory_completed_at), 60.0) and int(artifact_metrics.final_inventory.count) == 6, "artifact metrics must preserve the first six-slot completion time and final inventory", failures)
	_expect((artifact_metrics.events as Array).size() == 16 and int((artifact_metrics.by_artifact as Dictionary).blood_prism.offers) == 2 and is_equal_approx(float((artifact_metrics.by_artifact as Dictionary).blood_prism.selection_rate), 0.5), "artifact event ledger must retain stable per-artifact offer, selection, and discard rates", failures)
	_expect(int((artifact_metrics.target_group_selections as Dictionary).get("normal_defender", 0)) >= 3 and float((artifact_metrics.effect_contribution as Dictionary).estimated_output_delta) > 0.0, "artifact metrics must preserve target-group decisions and an explicitly labeled observed-output contribution estimate", failures)

	var stage := load("res://data/stages/standard_20m.tres") as StageData
	var outcome := RunOutcomeSummary.build_from_snapshots(stage, {}, [], {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, loadout.get_artifact_snapshot(), artifact_metrics)
	_expect(int(outcome.growth.artifact_count) == 6 and int(outcome.artifacts.offers) == 8 and int(outcome.artifacts.final_inventory.count) == 6, "outcome summary must preserve final artifact inventory together with the full event metric snapshot", failures)
	var hud := GameHUD.new()
	var outcome_text := hud._outcome_summary_text(outcome)
	var growth_text := hud._result_growth_summary(outcome, "fallback")
	_expect(outcome_text.contains("아티팩트 · 보유 6/6") and outcome_text.contains("제안 8 / 획득 7 / 포기 1 / 교체 1"), "result presentation must explain artifact ownership and every player decision", failures)
	_expect(growth_text.contains("아티팩트 6/6"), "compact result growth must include final artifact capacity", failures)
	hud.free()

	_expect(not ArtifactOfferService.should_offer(1, 0.0, GameSession.ARTIFACT_MODE_DISABLED) and ArtifactOfferService.should_offer(1, 0.99, GameSession.ARTIFACT_MODE_FORCED), "audit artifact modes must provide an isolated disabled control and deterministic forced contract mode", failures)
	var policy_choice := ArtifactOfferService.build_choice(catalog.find_artifact(&"war_banner"))
	var policy := BalanceAuditBuildPolicy.new(&"average_coherent")
	var policy_context := {"valid": true, "scenario_priority": 0, "regular_formation_count": 4, "artifact_inventory_count": 0}
	_expect(policy.score_choice(policy_choice, policy_context) > 108 and policy.selection_reason(policy_choice, policy_context).contains("public artifact effects"), "audit selection must evaluate only disclosed artifact effects, trade-offs, and current inventory", failures)

	var reports: Array = []
	for seed in [11, 22, 33]:
		reports.append({
			"scenario": "artifact_contract", "seed": seed, "artifact_mode": "normal", "victory": seed == 11,
			"game_finished": true, "timed_out": false, "block_board": true, "audit_target_seconds": 600.0,
			"elapsed": 600.0, "level": 25, "total_experience": 5000.0, "kills": 100, "core_health": 100.0, "core_max_health": 200.0,
			"final_boss_challenged": true, "performance_budget": {"passed": true}, "runtime_performance": {},
			"selection_policy": "average_coherent", "formation_metrics": {}, "upgrade_choice_metrics": {}, "tower_score_efficiency": {}, "guard_combat": {}, "spawn_director": {},
			"artifact_metrics": {"offers": 1, "acquisitions": 1, "discards": 0, "replacements": 0, "inventory_completed_at": -1.0, "final_inventory": {"count": 1, "artifact_ids": ["war_banner"]}, "by_artifact": {"war_banner": {"offers": 1, "acquisitions": 1, "discards": 0, "replacements": 0}}, "target_group_offers": {"normal_defender": 1}, "target_group_selections": {"normal_defender": 1}, "effect_contribution": {"estimated_output_delta": 10.0}},
			"artifacts": {"count": 1, "artifact_ids": ["war_banner"]},
		})
	var audit_summary := BalanceAuditSummary.summarize(reports, 3)
	_expect(is_equal_approx(float(audit_summary.artifact_metrics.average_offers), 1.0) and is_equal_approx(float(audit_summary.artifact_metrics.average_full_length_offers), 1.0) and int(audit_summary.artifact_metrics.max_inventory_count) == 1, "matrix summary must separate full-length offer frequency while preserving per-run inventory bounds", failures)
	_expect((audit_summary.artifact_metrics.inventory_outcomes as Dictionary).has("1") and (audit_summary.artifact_metrics.combination_outcomes as Dictionary).has("war_banner") and (audit_summary.artifact_metrics.target_group_outcomes as Dictionary).has("normal_defender"), "matrix summary must correlate target groups, inventory count, and stable artifact combinations with outcomes", failures)

	var result_source := FileAccess.get_file_as_string("res://scripts/game/run_result_service.gd")
	var audit_source := FileAccess.get_file_as_string("res://tests/balance_audit_runner.gd")
	var matrix_source := FileAccess.get_file_as_string("res://tests/balance_audit_matrix_runner.gd")
	_expect(result_source.count("\"artifact_metrics\": metrics.artifact_metrics_snapshot(loadout)") == 2, "normal results and settlement checkpoints must serialize the same artifact metric snapshot", failures)
	_expect(audit_source.contains("AUDIT_REPORT_SCHEMA_VERSION := 20") and audit_source.contains("--artifact-mode=") and audit_source.contains("artifact_metrics"), "schema v20 audit reports must expose disabled, normal, and forced artifact experiment modes with metrics", failures)
	_expect(matrix_source.contains("AUDIT_REPORT_SCHEMA_VERSION := 20") and matrix_source.contains("--artifact-mode=%s") and matrix_source.contains("artifact_events"), "matrix checkpoints and speed fingerprints must preserve the artifact mode and stable decision ledger", failures)
	_expect(matrix_source.contains("summary[\"audit_schema_version\"] = AUDIT_REPORT_SCHEMA_VERSION") and matrix_source.contains("summary[\"build_policy_revision\"]") and matrix_source.contains("summary[\"rng_revision\"]"), "saved matrix summaries must identify the audit, policy, and RNG revisions without requiring the checkpoint signature", failures)

	metrics.free()
	loadout.free()
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
