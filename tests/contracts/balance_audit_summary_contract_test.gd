class_name BalanceAuditSummaryContractTest
extends RefCounted

var failures: Array[String] = []

static func run() -> Array[String]:
	var contract := BalanceAuditSummaryContractTest.new()
	contract._run()
	return contract.failures

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	var audit_board_sample := [
		{"placement_id": "formation_1", "formation_id": "cascade", "anchor_x": 2, "anchor_y": 0, "vertical_flipped": false, "is_guard": false, "cells": [{"x": 2, "y": 0, "tower_id": "chain"}]},
		{"placement_id": "guard_obsidian", "formation_id": "obsidian_tribunal", "anchor_x": 0, "anchor_y": 0, "vertical_flipped": false, "is_guard": true, "cells": [{"x": 0, "y": 0, "tower_id": "obsidian_inquisitor"}, {"x": 1, "y": 0, "tower_id": "obsidian_verdict"}]},
	]
	var audit_summary := BalanceAuditSummary.summarize([
		{
			"scenario": "judgment_vanguard",
			"seed": 1847,
			"selection_policy": "scripted_scenario_priority",
			"block_board": true,
			"audit_target_seconds": 600.0,
			"elapsed": 600.0,
			"victory": true,
			"game_finished": true,
			"timed_out": false,
			"level": 25,
			"total_experience": 4200.0,
			"kills": 600,
			"core_health": 50.0,
			"core_max_health": 100.0,
			"performance_budget": {"passed": true},
			"runtime_performance": {"average_frame_ms": 7.0, "worst_frame_ms": 20.0, "over_33_ms_ratio": 0.0},
			"formation_metrics": {
				"set_offers_by_size": {"2": 2, "4": 1}, "set_selections_by_size": {"2": 1}, "set_abandons_by_size": {},
				"formation_offers": {"cascade": 2}, "formation_selections": {"cascade": 1}, "formation_abandons": {},
				"placement_seconds_total": {"cascade": 4.0}, "valid_position_totals": {"cascade": 8},
				"board_occupancy_samples": [0.5, 0.75], "isolated_empty_cell_samples": [0, 1],
				"guard_placements": {"obsidian": 1},
				"offer_context_events": [
					{"elapsed": 10.0, "formation_id": "cascade", "slot_type": "build", "primary_role": "network", "eligible_pool_size": 6, "discovery_bonus": true, "shape_class": "STEP", "distinct_tower_count": 1, "valid_position_count": 7},
					{"elapsed": 10.0, "formation_id": "elite_hunt", "slot_type": "expansion", "primary_role": "elite", "eligible_pool_size": 6, "shape_class": "LONG", "distinct_tower_count": 3, "valid_position_count": 5},
					{"elapsed": 10.0, "formation_id": "cryo_net", "slot_type": "wildcard", "primary_role": "control", "eligible_pool_size": 6, "shape_class": "BEND", "distinct_tower_count": 2, "valid_position_count": 6},
				],
				"selection_events": [{"elapsed": 10.1, "formation_id": "cascade", "shape_class": "STEP", "distinct_tower_count": 1, "valid_position_count": 7, "empty_cells": 12, "isolated_empty_cells": 0, "occupancy_ratio": 0.5, "vertical_flipped": false}],
				"abandon_events": [], "guard_placement_events": [{"vertical_flipped": false}],
			},
			"formation_board": audit_board_sample,
			"spawn_director": {"base_spawn_count": 100, "bonus_spawn_count": 10, "base_spawn_experience": 1000.0, "bonus_spawn_experience": 100.0, "average_alive_pressure": 40.0, "peak_alive_pressure": 90.0},
			"guard_combat": {"obsidian_tribunal": {"attacks": 20, "hits": 10, "damage": 1000.0, "kills": 5, "control_applications": 2, "by_tower": {"obsidian_verdict": {"attacks": 20, "hits": 10, "damage": 1000.0, "kills": 5, "control_applications": 2}}}},
			"upgrade_choice_metrics": {"specialization_offers": {"core_branch:obsidian_sentence": 1}, "specialization_selections": {"core_branch:obsidian_sentence": 1}},
			"tower_score_efficiency": {"rapid": {"installed": 2, "formation_score_budget": 160.0, "formation_score_minutes": 800.0, "damage": 1600.0, "efficiency_role": "damage", "efficiency_cohort": "sustained_damage"}},
		},
		{
			"scenario": "judgment_vanguard",
			"seed": 42731,
			"selection_policy": "scripted_scenario_priority",
			"block_board": true,
			"audit_target_seconds": 600.0,
			"elapsed": 300.0,
			"victory": false,
			"game_finished": true,
			"timed_out": false,
			"level": 23,
			"total_experience": 3100.0,
			"kills": 400,
			"core_health": 0.0,
			"core_max_health": 100.0,
			"performance_budget": {"passed": true},
			"runtime_performance": {"average_frame_ms": 9.0, "worst_frame_ms": 35.0, "over_33_ms_ratio": 0.001},
			"formation_metrics": {
				"set_offers_by_size": {"2": 1, "4": 2}, "set_selections_by_size": {"2": 1, "4": 1}, "set_abandons_by_size": {"4": 1},
				"formation_offers": {"cascade": 1}, "formation_selections": {"cascade": 1}, "formation_abandons": {"cascade": 1},
				"placement_seconds_total": {"cascade": 2.0}, "valid_position_totals": {"cascade": 4},
				"board_occupancy_samples": [0.25], "isolated_empty_cell_samples": [2],
				"guard_placements": {"obsidian": 1},
				"offer_context_events": [
					{"elapsed": 20.0, "formation_id": "elite_hunt", "slot_type": "build", "primary_role": "elite", "eligible_pool_size": 8, "role_duplicate": true, "shape_class": "LONG", "distinct_tower_count": 3, "valid_position_count": 4},
					{"elapsed": 20.0, "formation_id": "cryo_net", "slot_type": "expansion", "primary_role": "control", "eligible_pool_size": 8, "recent_penalty": true, "shape_class": "BEND", "distinct_tower_count": 2, "valid_position_count": 5},
					{"elapsed": 20.0, "formation_id": "cascade", "slot_type": "wildcard", "primary_role": "elite", "eligible_pool_size": 8, "role_duplicate": true, "shape_class": "STEP", "distinct_tower_count": 1, "valid_position_count": 3},
				],
				"selection_events": [{"elapsed": 20.1, "formation_id": "cascade", "shape_class": "STEP", "distinct_tower_count": 1, "valid_position_count": 3, "empty_cells": 8, "isolated_empty_cells": 2, "occupancy_ratio": 0.67, "vertical_flipped": true}],
				"abandon_events": [{"elapsed": 200.0, "formation_id": "cascade", "shape_class": "STEP", "distinct_tower_count": 1, "valid_position_count": 3, "refund_experience": 40.0, "empty_cells": 5, "isolated_empty_cells": 1}],
				"guard_placement_events": [{"vertical_flipped": true}],
			},
			"formation_board": audit_board_sample,
			"spawn_director": {"base_spawn_count": 50, "bonus_spawn_count": 10, "base_spawn_experience": 500.0, "bonus_spawn_experience": 100.0, "average_alive_pressure": 60.0, "peak_alive_pressure": 120.0},
			"guard_combat": {"obsidian_tribunal": {"attacks": 10, "hits": 5, "damage": 500.0, "kills": 2, "control_applications": 1, "by_tower": {"obsidian_verdict": {"attacks": 10, "hits": 5, "damage": 500.0, "kills": 2, "control_applications": 1}}}},
			"upgrade_choice_metrics": {"specialization_offers": {"core_branch:obsidian_sentence": 1}, "specialization_selections": {}},
			"tower_score_efficiency": {"rapid": {"installed": 1, "formation_score_budget": 80.0, "formation_score_minutes": 400.0, "damage": 400.0, "efficiency_role": "damage", "efficiency_cohort": "sustained_damage"}},
		},
	], 2)
	_check(bool(audit_summary.complete) and bool(audit_summary.quality_gate_passed) and int(audit_summary.run_count) == 2 and is_equal_approx(float(audit_summary.victory_rate), 0.5), "multi-seed audit summaries must expose completion, quality gates, and victory rate")
	_check(is_equal_approx(float(audit_summary.average_level), 24.0) and is_equal_approx(float(audit_summary.average_completion_ratio), 0.75) and is_equal_approx(float(audit_summary.max_over_33_ms_ratio), 0.001), "multi-seed audit summaries must aggregate progression and worst performance observations")
	_check(int(audit_summary.full_length_runs) == 1 and is_equal_approx(float(audit_summary.average_full_length_level), 25.0) and is_equal_approx(float(audit_summary.average_full_length_experience), 4200.0) and int(audit_summary.selection_policies.scripted_scenario_priority) == 2, "multi-seed audit summaries must isolate full-length progression and preserve the automated selection policy")
	_check(is_equal_approx(float(audit_summary.formation_metrics.selection_rates.cascade), 2.0 / 3.0) and is_equal_approx(float(audit_summary.formation_metrics.abandon_rates.cascade), 1.0 / 3.0) and is_equal_approx(float(audit_summary.formation_metrics.average_placement_seconds.cascade), 3.0), "multi-seed audit summaries must weight formation choices by total offers and placements")
	_check(is_equal_approx(float(audit_summary.formation_metrics.set_selection_rates_by_size["2"]), 2.0 / 3.0) and is_equal_approx(float(audit_summary.formation_metrics.set_selection_rates_by_size["4"]), 1.0 / 3.0) and is_equal_approx(float(audit_summary.formation_metrics.set_abandon_rates_by_size["4"]), 1.0), "multi-seed audit summaries must aggregate size selection and abandonment rates")
	_check(is_equal_approx(float(audit_summary.formation_metrics.average_valid_positions.cascade), 4.0) and is_equal_approx(float(audit_summary.formation_metrics.board_context.average_occupancy), 0.5) and is_equal_approx(float(audit_summary.formation_metrics.board_context.average_isolated_empty_cells), 1.0), "multi-seed audit summaries must aggregate placement freedom and board fragmentation")
	_check(is_equal_approx(float(audit_summary.formation_metrics.final_board_context.average_occupancy), 0.5) and is_equal_approx(float(audit_summary.formation_metrics.final_board_context.average_isolated_empty_cells), 1.5), "multi-seed audit summaries must separate each run's final occupancy and isolated cells from all intermediate board samples")
	_check(int(audit_summary.formation_metrics.by_shape.STEP.offers) == 2 and int(audit_summary.formation_metrics.by_shape.STEP.selections) == 2 and int(audit_summary.formation_metrics.by_shape.STEP.abandons) == 1 and is_equal_approx(float(audit_summary.formation_metrics.by_shape.STEP.average_valid_positions), 5.0), "multi-seed audit summaries must aggregate offers, selections, abandons, and placement freedom by v0.14 shape")
	_check(int(audit_summary.formation_metrics.by_distinct_tower_count["1"].offers) == 2 and int(audit_summary.formation_metrics.by_distinct_tower_count["1"].selections) == 2 and int(audit_summary.formation_metrics.by_distinct_tower_count["1"].abandons) == 1, "multi-seed audit summaries must aggregate formation decisions by distinct tower count")
	_check(is_equal_approx(float(audit_summary.spawn_director.bonus_experience_ratio), 200.0 / 1700.0) and is_equal_approx(float(audit_summary.spawn_director.average_alive_pressure), 50.0) and is_equal_approx(float(audit_summary.spawn_director.peak_alive_pressure), 120.0), "multi-seed audit summaries must aggregate bonus Spawn XP and alive pressure")
	_check(not bool(audit_summary.balance_gate_passed), "long-run balance gates must remain separate from technical quality and fail below eighty-five percent average completion")
	_check(is_equal_approx(float(audit_summary.formation_metrics.flip_usage.regular_vertical_flip_rate), 0.5) and is_equal_approx(float(audit_summary.formation_metrics.flip_usage.guard_vertical_flip_rate), 0.5) and int(audit_summary.formation_metrics.guard_placements.obsidian) == 2, "multi-seed audit summaries must separate regular and guard flip usage")
	_check(is_equal_approx(float(audit_summary.specialization_metrics.selection_rates["core_branch:obsidian_sentence"]), 0.5) and is_equal_approx(float(audit_summary.tower_score_efficiency.rapid.damage_per_score_minute), 5.0 / 3.0) and is_equal_approx(float(audit_summary.tower_score_efficiency.rapid.formation_score_minutes_total), 1200.0) and String(audit_summary.tower_score_efficiency.rapid.efficiency_cohort) == "sustained_damage", "multi-seed audit summaries must aggregate stable specialization ids and placement-uptime-weighted tower contribution")
	_check(int(audit_summary.formation_metrics.decision_context.selection_events) == 2 and is_equal_approx(float(audit_summary.formation_metrics.decision_context.average_empty_cells_at_selection), 10.0) and is_equal_approx(float(audit_summary.formation_metrics.decision_context.refunded_experience_total), 40.0), "multi-seed audit summaries must preserve board context and refund totals for formation decisions")
	var offer_diagnostics := audit_summary.formation_metrics.offer_diagnostics as Dictionary
	_check(int(offer_diagnostics.rounds) == 2 and int(offer_diagnostics.slot_offers.build) == 2 and int(offer_diagnostics.slot_selections.build) == 1 and int(offer_diagnostics.slot_selections.wildcard) == 1, "multi-seed summaries must aggregate A/B/C offer exposure and selected slot purpose")
	_check(is_equal_approx(float(offer_diagnostics.multi_role_round_rate), 1.0) and is_equal_approx(float(offer_diagnostics.all_unique_role_round_rate), 0.5) and is_equal_approx(float(offer_diagnostics.average_eligible_pool_size), 7.0), "offer diagnostics must retain desired-role access, strict role diversity, and eligible pool breadth")
	_check(is_equal_approx(float(audit_summary.abandonment_outcomes.with_abandon.victory_rate), 0.0) and is_equal_approx(float(audit_summary.abandonment_outcomes.without_abandon.victory_rate), 1.0), "multi-seed audit summaries must correlate placement abandonment with run outcomes")
	var guard_layout := (audit_summary.guard_layouts as Dictionary).values()[0] as Dictionary
	_check((audit_summary.guard_layouts as Dictionary).size() == 1 and int(guard_layout.runs) == 2 and is_equal_approx(float(guard_layout.victory_rate), 0.5) and is_equal_approx(float(guard_layout.average_first_regular_distance), 1.0), "multi-seed audit summaries must aggregate guard-position outcomes and distance to the first regular formation")
	var guard_combat_summary := audit_summary.guard_combat.obsidian_tribunal as Dictionary
	_check(int(guard_combat_summary.sampled_runs) == 2 and is_equal_approx(float(guard_combat_summary.damage_total), 1500.0) and int(guard_combat_summary.kills_total) == 7 and int(guard_combat_summary.control_applications_total) == 3 and is_equal_approx(float(guard_combat_summary.damage_per_minute), 100.0) and is_equal_approx(float((guard_combat_summary.by_tower.obsidian_verdict as Dictionary).damage), 1500.0), "multi-seed audit summaries must aggregate guard combat contribution by formation and tower id")
	_check(not bool(audit_summary.balance_assessment.sample_sufficient) and String(((audit_summary.balance_assessment.findings as Array)[0] as Dictionary).code) == "sample_too_small", "balance findings must label undersized samples instead of over-interpreting them")
	var short_audit_assessment := BalanceAuditSummary._assess_balance({"run_count": 3, "average_audit_target_seconds": 30.0})
	_check(bool(short_audit_assessment.sample_sufficient) and not bool(short_audit_assessment.assessment_ready) and int(short_audit_assessment.warning_count) == 0 and String(((short_audit_assessment.findings as Array)[0] as Dictionary).code) == "full_run_required", "short technical audits must not emit long-run balance warnings")
	var dimension_assessment := BalanceAuditSummary._assess_balance({
		"run_count": 3, "average_audit_target_seconds": 600.0, "average_completion_ratio": 1.0,
		"full_length_runs": 3, "average_full_length_level": 25.0,
		"formation_metrics": {
			"set_offers_by_size": {}, "set_selections_by_size": {}, "set_selection_rates_by_size": {}, "set_abandon_rates_by_size": {},
			"selections": {}, "abandons": {}, "abandon_rates": {},
			"by_shape": {"STEP": {"offers": 10, "selections": 1, "selection_rate": 0.1, "abandons": 0, "abandon_rate": 0.0}},
			"by_distinct_tower_count": {"1": {"offers": 10, "selections": 1, "selection_rate": 0.1, "abandons": 0, "abandon_rate": 0.0}},
		},
		"selection_policies": {"scripted_scenario_priority": 3},
	})
	_check((dimension_assessment.findings as Array).any(func(finding: Dictionary) -> bool: return finding.code == "formation_shape_underselected") and (dimension_assessment.findings as Array).any(func(finding: Dictionary) -> bool: return finding.code == "formation_species_underselected"), "long-run assessment must flag sufficiently sampled v0.14 shape and species under-selection")
	var diagnostic_assessment := BalanceAuditSummary._assess_balance({
		"run_count": 3, "average_audit_target_seconds": 600.0, "average_completion_ratio": 0.75, "average_level": 15.0,
		"full_length_runs": 3, "average_full_length_level": 15.0,
		"formation_metrics": {
			"set_offers_by_size": {"2": 3, "4": 3}, "set_selections_by_size": {"2": 3, "4": 0},
			"set_selection_rates_by_size": {"2": 1.0, "4": 0.0}, "set_abandon_rates_by_size": {"2": 0.0, "4": 0.0},
			"selections": {"cascade": 2}, "abandons": {"cascade": 1}, "abandon_rates": {"cascade": 1.0 / 3.0},
		},
		"specialization_metrics": {"offers": {"never": 3, "always": 3}, "selection_rates": {"never": 0.0, "always": 1.0}},
		"tower_score_efficiency": {
			"rapid": {"sampled_runs": 3, "installed_total": 3, "damage_per_score_minute": 1.0},
			"area": {"sampled_runs": 3, "installed_total": 3, "damage_per_score_minute": 2.0},
			"execute": {"sampled_runs": 3, "installed_total": 3, "damage_per_score_minute": 3.0},
		},
	})
	var diagnostic_codes: Array[String] = []
	for finding_value in (diagnostic_assessment.findings as Array):
		diagnostic_codes.append(String((finding_value as Dictionary).code))
	_check(bool(diagnostic_assessment.sample_sufficient) and "run_completion_low" in diagnostic_codes and "level_progression_low" in diagnostic_codes and "large_formation_avoidance" in diagnostic_codes and "formation_abandonment_high" in diagnostic_codes and "specialization_never_selected" in diagnostic_codes and "specialization_overselected" in diagnostic_codes and "tower_efficiency_spread" in diagnostic_codes, "balance assessment must surface actionable survival, progression, and content-bias findings once sample size is sufficient")
	var scripted_assessment := BalanceAuditSummary._assess_balance({
		"run_count": 3, "average_audit_target_seconds": 600.0, "full_length_runs": 3, "average_full_length_level": 25.0,
		"selection_policies": {"scripted_scenario_priority": 3},
		"formation_metrics": {},
		"specialization_metrics": {"offers": {"forced": 3, "ignored": 3}, "selection_rates": {"forced": 1.0, "ignored": 0.0}},
		"tower_score_efficiency": {
			"rapid": {"sampled_runs": 3, "installed_total": 3, "damage_per_score_minute": 1.0, "efficiency_role": "damage", "efficiency_cohort": "sustained_damage"},
			"area": {"sampled_runs": 3, "installed_total": 3, "damage_per_score_minute": 1.1, "efficiency_role": "damage", "efficiency_cohort": "sustained_damage"},
			"chain": {"sampled_runs": 3, "installed_total": 6, "damage_per_score_minute": 0.1, "efficiency_role": "damage", "efficiency_cohort": "sustained_damage"},
			"pierce": {"sampled_runs": 3, "installed_total": 3, "damage_per_score_minute": 8.0, "efficiency_role": "damage", "efficiency_cohort": "precision_damage"},
			"execute": {"sampled_runs": 3, "installed_total": 3, "damage_per_score_minute": 10.0, "efficiency_role": "damage", "efficiency_cohort": "precision_damage"},
			"mark": {"sampled_runs": 3, "installed_total": 3, "damage_per_score_minute": 0.01, "efficiency_role": "support", "efficiency_cohort": "support"},
			"knockback": {"sampled_runs": 3, "installed_total": 3, "damage_per_score_minute": 0.1, "efficiency_role": "hybrid_control", "efficiency_cohort": "hybrid_control"},
		},
	})
	var scripted_codes: Array[String] = []
	for finding_value in (scripted_assessment.findings as Array):
		scripted_codes.append(String((finding_value as Dictionary).code))
	_check("scripted_specialization_policy" in scripted_codes and "specialization_never_selected" not in scripted_codes and "specialization_overselected" not in scripted_codes and "tower_efficiency_spread" not in scripted_codes, "scripted choices, non-damage roles, and network-dependent damage cohorts must not be misreported as comparable player preference or efficiency imbalance")
	var under_sampled_efficiency_assessment := BalanceAuditSummary._assess_balance({
		"run_count": 3, "average_audit_target_seconds": 600.0, "full_length_runs": 3, "average_full_length_level": 25.0,
		"selection_policies": {"scripted_scenario_priority": 3}, "formation_metrics": {},
		"tower_score_efficiency": {
			"rapid": {"sampled_runs": 3, "installed_total": 12, "damage_per_score_minute": 8.0, "efficiency_role": "damage", "efficiency_cohort": "sustained_damage"},
			"area": {"sampled_runs": 1, "installed_total": 4, "damage_per_score_minute": 0.8, "efficiency_role": "damage", "efficiency_cohort": "sustained_damage"},
		},
	})
	var under_sampled_efficiency_codes: Array[String] = []
	for finding_value in (under_sampled_efficiency_assessment.findings as Array):
		under_sampled_efficiency_codes.append(String((finding_value as Dictionary).code))
	_check("tower_efficiency_spread" not in under_sampled_efficiency_codes, "tower efficiency comparison must require independent run samples instead of treating several towers installed in one run as sufficient evidence")
