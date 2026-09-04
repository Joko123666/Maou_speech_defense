class_name BalanceAuditSummary
extends RefCounted

const MIN_RELIABLE_RUNS := 3
const MIN_CHOICE_OFFERS := 3
const LEVEL_TARGET := 25.0
const LEVEL_TOLERANCE := 5.0
const LOW_SELECTION_RATE := 0.15
const HIGH_ABANDON_RATE := 0.25
const TOWER_EFFICIENCY_REVIEW_RATIO := 2.0
const FULL_RUN_MINIMUM_SECONDS := 570.0
const MIN_FULL_LENGTH_LEVEL_SAMPLES := 2
const RUN_COMPLETION_WARNING_RATIO := 0.85
const NETWORK_DEPENDENT_TOWER_IDS: Array[String] = ["chain"]

static func summarize(reports: Array, expected_runs: int = -1) -> Dictionary:
	var grouped: Dictionary = {}
	for report_value in reports:
		if not report_value is Dictionary:
			continue
		var report := report_value as Dictionary
		var scenario := String(report.get("scenario", "unknown"))
		if not grouped.has(scenario):
			grouped[scenario] = []
		(grouped[scenario] as Array).append(report)
	var by_scenario: Dictionary = {}
	for scenario in grouped:
		by_scenario[scenario] = _summarize_group(grouped[scenario] as Array, true)
	var summary := _summarize_group(reports, grouped.size() <= 1)
	summary["expected_runs"] = reports.size() if expected_runs < 0 else expected_runs
	summary["complete"] = reports.size() == int(summary.expected_runs)
	summary["by_scenario"] = by_scenario
	summary["quality_gate_passed"] = (
		bool(summary.complete)
		and int(summary.invalid_block_board_runs) == 0
		and int(summary.timed_out_runs) == 0
		and int(summary.performance_budget_failures) == 0
	)
	return summary

static func _summarize_group(reports: Array, assess_specialization_bias: bool = true) -> Dictionary:
	var valid_reports: Array[Dictionary] = []
	for report_value in reports:
		if report_value is Dictionary:
			valid_reports.append(report_value as Dictionary)
	var run_count := valid_reports.size()
	var victories := 0
	var finished_runs := 0
	var timed_out_runs := 0
	var invalid_block_board_runs := 0
	var performance_budget_failures := 0
	var elapsed_total := 0.0
	var audit_target_total := 0.0
	var completion_ratio_total := 0.0
	var level_total := 0.0
	var full_length_runs := 0
	var full_length_level_total := 0.0
	var full_length_experience_total := 0.0
	var kills_total := 0.0
	var core_health_ratio_total := 0.0
	var average_frame_ms_total := 0.0
	var max_worst_frame_ms := 0.0
	var max_over_33_ms_ratio := 0.0
	var formation_totals := _new_choice_totals()
	var specialization_totals := _new_choice_totals()
	var tower_totals: Dictionary = {}
	var guard_layout_totals: Dictionary = {}
	var guard_combat_totals: Dictionary = {}
	var spawn_director_totals := {
		"base_spawn_count": 0.0, "bonus_spawn_count": 0.0,
		"base_spawn_experience": 0.0, "bonus_spawn_experience": 0.0,
		"average_alive_pressure": 0.0, "peak_alive_pressure": 0.0,
	}
	var selection_policies: Dictionary = {}
	var artifact_totals := _new_artifact_totals()
	var overgrowth_totals := _new_overgrowth_totals()
	var abandonment_outcome_totals := {
		"with_abandon": {"runs": 0, "victories": 0, "elapsed": 0.0, "completion": 0.0},
		"without_abandon": {"runs": 0, "victories": 0, "elapsed": 0.0, "completion": 0.0},
	}
	var seeds: Array[int] = []
	for report in valid_reports:
		victories += 1 if bool(report.get("victory", false)) else 0
		finished_runs += 1 if bool(report.get("game_finished", false)) else 0
		timed_out_runs += 1 if bool(report.get("timed_out", false)) else 0
		invalid_block_board_runs += 0 if bool(report.get("block_board", false)) else 1
		var budget := report.get("performance_budget", {}) as Dictionary
		performance_budget_failures += 0 if bool(budget.get("passed", false)) else 1
		var elapsed := float(report.get("elapsed", 0.0))
		var target := maxf(float(report.get("audit_target_seconds", 0.0)), 0.001)
		audit_target_total += target
		elapsed_total += elapsed
		var completion_ratio := clampf(elapsed / target, 0.0, 1.0)
		completion_ratio_total += completion_ratio
		var report_level := float(report.get("level", 0))
		level_total += report_level
		if bool(report.get("victory", false)) or completion_ratio >= 0.95:
			full_length_runs += 1
			full_length_level_total += report_level
			full_length_experience_total += float(report.get("total_experience", 0.0))
		kills_total += float(report.get("kills", 0))
		var selection_policy := String(report.get("selection_policy", "unknown"))
		selection_policies[selection_policy] = int(selection_policies.get(selection_policy, 0)) + 1
		var core_max_health := float(report.get("core_max_health", 0.0))
		if core_max_health > 0.0:
			core_health_ratio_total += clampf(float(report.get("core_health", 0.0)) / core_max_health, 0.0, 1.0)
		var performance := report.get("runtime_performance", {}) as Dictionary
		average_frame_ms_total += float(performance.get("average_frame_ms", 0.0))
		max_worst_frame_ms = maxf(max_worst_frame_ms, float(performance.get("worst_frame_ms", 0.0)))
		max_over_33_ms_ratio = maxf(max_over_33_ms_ratio, float(performance.get("over_33_ms_ratio", 0.0)))
		seeds.append(int(report.get("seed", 0)))
		var formation_metrics := report.get("formation_metrics", {}) as Dictionary
		_accumulate_formation_metrics(formation_totals, formation_metrics)
		_accumulate_specialization_metrics(specialization_totals, report.get("upgrade_choice_metrics", {}) as Dictionary)
		_accumulate_tower_efficiency(tower_totals, report.get("tower_score_efficiency", {}) as Dictionary, elapsed)
		_accumulate_guard_layout(guard_layout_totals, report)
		_accumulate_guard_combat(guard_combat_totals, report.get("guard_combat", {}) as Dictionary, elapsed)
		_accumulate_spawn_director(spawn_director_totals, report.get("spawn_director", {}) as Dictionary)
		_accumulate_artifact_metrics(artifact_totals, report)
		_accumulate_overgrowth_metrics(overgrowth_totals, report.get("growth_timeline", {}) as Dictionary)
		var outcome_key := "with_abandon" if _has_formation_abandon(formation_metrics) else "without_abandon"
		var outcome := abandonment_outcome_totals[outcome_key] as Dictionary
		outcome.runs = int(outcome.runs) + 1
		outcome.victories = int(outcome.victories) + (1 if bool(report.get("victory", false)) else 0)
		outcome.elapsed = float(outcome.elapsed) + elapsed
		outcome.completion = float(outcome.completion) + clampf(elapsed / target, 0.0, 1.0)
	var formation_summary := _finalize_choice_totals(formation_totals)
	var specialization_summary := _finalize_choice_totals(specialization_totals)
	var tower_efficiency_summary := _finalize_tower_efficiency(tower_totals)
	var result := {
		"run_count": run_count,
		"seeds": seeds,
		"victories": victories,
		"victory_rate": _ratio(victories, run_count),
		"finished_runs": finished_runs,
		"timed_out_runs": timed_out_runs,
		"invalid_block_board_runs": invalid_block_board_runs,
		"performance_budget_failures": performance_budget_failures,
		"performance_budget_pass_rate": _ratio(run_count - performance_budget_failures, run_count),
		"average_elapsed": _average(elapsed_total, run_count),
		"average_audit_target_seconds": _average(audit_target_total, run_count),
		"average_completion_ratio": _average(completion_ratio_total, run_count),
		"average_level": _average(level_total, run_count),
		"full_length_runs": full_length_runs,
		"average_full_length_level": _average(full_length_level_total, full_length_runs),
		"average_full_length_experience": _average(full_length_experience_total, full_length_runs),
		"average_kills": _average(kills_total, run_count),
		"selection_policies": selection_policies,
		"average_core_health_ratio": _average(core_health_ratio_total, run_count),
		"average_frame_ms": _average(average_frame_ms_total, run_count),
		"max_worst_frame_ms": max_worst_frame_ms,
		"max_over_33_ms_ratio": max_over_33_ms_ratio,
		"formation_metrics": formation_summary,
		"specialization_metrics": specialization_summary,
		"tower_score_efficiency": tower_efficiency_summary,
		"abandonment_outcomes": _finalize_outcomes(abandonment_outcome_totals),
		"guard_layouts": _finalize_guard_layouts(guard_layout_totals),
		"guard_combat": _finalize_guard_combat(guard_combat_totals),
		"spawn_director": _finalize_spawn_director(spawn_director_totals, run_count),
		"artifact_metrics": _finalize_artifact_metrics(artifact_totals, run_count),
		"overgrowth_metrics": _finalize_overgrowth_metrics(overgrowth_totals, run_count),
	}
	result["balance_assessment"] = _assess_balance(result, assess_specialization_bias)
	var formation_diagnostics := (formation_summary.get("offer_diagnostics", {}) as Dictionary)
	result["balance_gate_passed"] = (
		float(result.average_completion_ratio) >= RUN_COMPLETION_WARNING_RATIO
		and (int(result.full_length_runs) == 0 or float(result.average_full_length_level) <= LEVEL_TARGET + LEVEL_TOLERANCE)
		and (int(formation_diagnostics.get("rounds", 0)) == 0 or is_equal_approx(float(formation_diagnostics.get("multi_role_round_rate", 0.0)), 1.0))
	)
	return result

static func _new_overgrowth_totals() -> Dictionary:
	return {
		"candidate": {"offers": 0, "selections": 0, "first_offer_total": 0.0, "runs_with_offer": 0},
		"retainer": {"offers": 0, "selections": 0, "first_offer_total": 0.0, "runs_with_offer": 0},
	}

static func _accumulate_overgrowth_metrics(totals: Dictionary, timeline: Dictionary) -> void:
	for event_value in timeline.get("offers", []) as Array:
		if not event_value is Dictionary:
			continue
		var event := event_value as Dictionary
		var track := String(event.get("track", ""))
		if totals.has(track):
			var total := totals[track] as Dictionary
			total.offers = int(total.offers) + 1
	for event_value in timeline.get("upgrades", []) as Array:
		if not event_value is Dictionary:
			continue
		var event := event_value as Dictionary
		var category := String(event.get("category", ""))
		if category not in ["candidate_overgrowth", "retainer_overgrowth"]:
			continue
		var track := String(event.get("track", ""))
		if totals.has(track):
			var total := totals[track] as Dictionary
			total.selections = int(total.selections) + 1
	var first_by_track := timeline.get("first_offer_by_track", {}) as Dictionary
	for track in totals:
		if not first_by_track.has(track):
			continue
		var total := totals[track] as Dictionary
		total.first_offer_total = float(total.first_offer_total) + maxf(float(first_by_track[track]), 0.0)
		total.runs_with_offer = int(total.runs_with_offer) + 1

static func _finalize_overgrowth_metrics(totals: Dictionary, run_count: int) -> Dictionary:
	var result: Dictionary = {}
	for track in totals:
		var total := totals[track] as Dictionary
		result[track] = {
			"offers": int(total.offers),
			"average_offers_per_run": _average(float(total.offers), run_count),
			"selections": int(total.selections),
			"average_selections_per_run": _average(float(total.selections), run_count),
			"runs_with_offer": int(total.runs_with_offer),
			"average_first_offer_elapsed": _average(float(total.first_offer_total), int(total.runs_with_offer)),
		}
	return result

static func _new_choice_totals() -> Dictionary:
	return {
		"offers": {}, "selections": {}, "abandons": {}, "placement_seconds": {}, "placement_counts": {},
		"set_offers": {}, "set_selections": {}, "set_abandons": {}, "valid_positions": {},
		"board_sample_count": 0, "board_isolated_sample_count": 0, "board_occupancy": 0.0, "board_isolated_cells": 0.0,
		"selection_event_count": 0, "selection_empty_cells": 0.0, "selection_isolated_cells": 0.0, "selection_occupancy": 0.0,
		"abandon_event_count": 0, "abandon_elapsed": 0.0, "abandon_refund": 0.0, "abandon_empty_cells": 0.0, "abandon_isolated_cells": 0.0,
		"regular_flip_samples": 0, "regular_vertical_flips": 0,
		"guard_flip_samples": 0, "guard_vertical_flips": 0, "guard_placements": {},
		"offer_slot_counts": {}, "offer_slot_selections": {},
		"offer_primary_roles": {}, "selected_primary_roles": {},
		"offer_rounds": 0, "multi_role_rounds": 0, "all_unique_role_rounds": 0,
		"duplicate_role_offers": 0, "discovery_bonus_offers": 0, "recent_penalty_offers": 0,
		"eligible_pool_total": 0.0, "eligible_pool_samples": 0,
		"shape_offers": {}, "shape_selections": {}, "shape_abandons": {}, "shape_valid_positions": {},
		"species_offers": {}, "species_selections": {}, "species_abandons": {}, "species_valid_positions": {},
		"final_board_samples": 0, "final_board_occupancy": 0.0, "final_board_isolated_cells": 0.0,
	}

static func _accumulate_formation_metrics(totals: Dictionary, metrics: Dictionary) -> void:
	_merge_numeric_dictionary(totals.set_offers, metrics.get("set_offers_by_size", {}) as Dictionary)
	_merge_numeric_dictionary(totals.set_selections, metrics.get("set_selections_by_size", {}) as Dictionary)
	_merge_numeric_dictionary(totals.set_abandons, metrics.get("set_abandons_by_size", {}) as Dictionary)
	_merge_numeric_dictionary(totals.offers, metrics.get("formation_offers", {}) as Dictionary)
	_merge_numeric_dictionary(totals.selections, metrics.get("formation_selections", {}) as Dictionary)
	_merge_numeric_dictionary(totals.abandons, metrics.get("formation_abandons", {}) as Dictionary)
	_merge_numeric_dictionary(totals.valid_positions, metrics.get("valid_position_totals", {}) as Dictionary)
	_merge_numeric_dictionary(totals.guard_placements, metrics.get("guard_placements", {}) as Dictionary)
	var offer_events := metrics.get("offer_context_events", []) as Array
	var offer_rounds: Dictionary = {}
	for event_value in offer_events:
		if not event_value is Dictionary:
			continue
		var event := event_value as Dictionary
		var slot_type := String(event.get("slot_type", "legacy"))
		var primary_role := String(event.get("primary_role", "basic"))
		var shape_class := String(event.get("shape_class", ""))
		var species_key := str(maxi(int(event.get("distinct_tower_count", 0)), 0))
		var valid_position_count := maxf(float(event.get("valid_position_count", 0)), 0.0)
		totals.offer_slot_counts[slot_type] = int(totals.offer_slot_counts.get(slot_type, 0)) + 1
		totals.offer_primary_roles[primary_role] = int(totals.offer_primary_roles.get(primary_role, 0)) + 1
		totals.duplicate_role_offers = int(totals.duplicate_role_offers) + (1 if bool(event.get("role_duplicate", false)) else 0)
		totals.discovery_bonus_offers = int(totals.discovery_bonus_offers) + (1 if bool(event.get("discovery_bonus", false)) else 0)
		totals.recent_penalty_offers = int(totals.recent_penalty_offers) + (1 if bool(event.get("recent_penalty", false)) else 0)
		totals.eligible_pool_total = float(totals.eligible_pool_total) + maxf(float(event.get("eligible_pool_size", 0)), 0.0)
		totals.eligible_pool_samples = int(totals.eligible_pool_samples) + 1
		if not shape_class.is_empty():
			totals.shape_offers[shape_class] = int(totals.shape_offers.get(shape_class, 0)) + 1
			totals.shape_valid_positions[shape_class] = float(totals.shape_valid_positions.get(shape_class, 0.0)) + valid_position_count
		if species_key != "0":
			totals.species_offers[species_key] = int(totals.species_offers.get(species_key, 0)) + 1
			totals.species_valid_positions[species_key] = float(totals.species_valid_positions.get(species_key, 0.0)) + valid_position_count
		var round_key := String.num(float(event.get("elapsed", 0.0)), 6)
		if not offer_rounds.has(round_key):
			offer_rounds[round_key] = {"count": 0, "roles": {}}
		var round_data := offer_rounds[round_key] as Dictionary
		round_data.count = int(round_data.count) + 1
		(round_data.roles as Dictionary)[primary_role] = true
	for round_value in offer_rounds.values():
		var round_data := round_value as Dictionary
		var role_count := (round_data.roles as Dictionary).size()
		totals.offer_rounds = int(totals.offer_rounds) + 1
		totals.multi_role_rounds = int(totals.multi_role_rounds) + (1 if role_count > 1 else 0)
		totals.all_unique_role_rounds = int(totals.all_unique_role_rounds) + (1 if role_count == int(round_data.count) else 0)
	for occupancy_value in metrics.get("board_occupancy_samples", []) as Array:
		totals.board_sample_count = int(totals.board_sample_count) + 1
		totals.board_occupancy = float(totals.board_occupancy) + float(occupancy_value)
	var isolated_samples := metrics.get("isolated_empty_cell_samples", []) as Array
	for isolated_value in isolated_samples:
		totals.board_isolated_sample_count = int(totals.board_isolated_sample_count) + 1
		totals.board_isolated_cells = float(totals.board_isolated_cells) + float(isolated_value)
	var occupancy_samples := metrics.get("board_occupancy_samples", []) as Array
	if not occupancy_samples.is_empty():
		totals.final_board_samples = int(totals.final_board_samples) + 1
		totals.final_board_occupancy = float(totals.final_board_occupancy) + float(occupancy_samples.back())
		totals.final_board_isolated_cells = float(totals.final_board_isolated_cells) + (float(isolated_samples.back()) if not isolated_samples.is_empty() else 0.0)
	var seconds := metrics.get("placement_seconds_total", {}) as Dictionary
	_merge_numeric_dictionary(totals.placement_seconds, seconds)
	for formation_id in seconds:
		var selection_count := int((metrics.get("formation_selections", {}) as Dictionary).get(formation_id, 0))
		totals.placement_counts[formation_id] = int(totals.placement_counts.get(formation_id, 0)) + selection_count
	for event_value in metrics.get("selection_events", []) as Array:
		if not event_value is Dictionary:
			continue
		var event := event_value as Dictionary
		totals.selection_event_count = int(totals.selection_event_count) + 1
		totals.regular_flip_samples = int(totals.regular_flip_samples) + 1
		totals.regular_vertical_flips = int(totals.regular_vertical_flips) + (1 if bool(event.get("vertical_flipped", false)) else 0)
		totals.selection_empty_cells = float(totals.selection_empty_cells) + float(event.get("empty_cells", 0))
		totals.selection_isolated_cells = float(totals.selection_isolated_cells) + float(event.get("isolated_empty_cells", 0))
		totals.selection_occupancy = float(totals.selection_occupancy) + float(event.get("occupancy_ratio", 0.0))
		_accumulate_dimension_decision(totals.shape_selections, String(event.get("shape_class", "")))
		_accumulate_dimension_decision(totals.species_selections, str(maxi(int(event.get("distinct_tower_count", 0)), 0)))
		var selected_offer := _matching_offer_context(event, offer_events)
		if not selected_offer.is_empty():
			var selected_slot := String(selected_offer.get("slot_type", "legacy"))
			var selected_role := String(selected_offer.get("primary_role", "basic"))
			totals.offer_slot_selections[selected_slot] = int(totals.offer_slot_selections.get(selected_slot, 0)) + 1
			totals.selected_primary_roles[selected_role] = int(totals.selected_primary_roles.get(selected_role, 0)) + 1
	for event_value in metrics.get("abandon_events", []) as Array:
		if not event_value is Dictionary:
			continue
		var event := event_value as Dictionary
		totals.abandon_event_count = int(totals.abandon_event_count) + 1
		totals.abandon_elapsed = float(totals.abandon_elapsed) + float(event.get("elapsed", 0.0))
		totals.abandon_refund = float(totals.abandon_refund) + float(event.get("refund_experience", 0.0))
		totals.abandon_empty_cells = float(totals.abandon_empty_cells) + float(event.get("empty_cells", 0))
		totals.abandon_isolated_cells = float(totals.abandon_isolated_cells) + float(event.get("isolated_empty_cells", 0))
		_accumulate_dimension_decision(totals.shape_abandons, String(event.get("shape_class", "")))
		_accumulate_dimension_decision(totals.species_abandons, str(maxi(int(event.get("distinct_tower_count", 0)), 0)))
	for event_value in metrics.get("guard_placement_events", []) as Array:
		if not event_value is Dictionary:
			continue
		var event := event_value as Dictionary
		totals.guard_flip_samples = int(totals.guard_flip_samples) + 1
		totals.guard_vertical_flips = int(totals.guard_vertical_flips) + (1 if bool(event.get("vertical_flipped", false)) else 0)

static func _accumulate_specialization_metrics(totals: Dictionary, metrics: Dictionary) -> void:
	_merge_numeric_dictionary(totals.offers, metrics.get("specialization_offers", {}) as Dictionary)
	_merge_numeric_dictionary(totals.selections, metrics.get("specialization_selections", {}) as Dictionary)

static func _accumulate_spawn_director(totals: Dictionary, snapshot: Dictionary) -> void:
	for key in ["base_spawn_count", "bonus_spawn_count", "base_spawn_experience", "bonus_spawn_experience", "average_alive_pressure"]:
		totals[key] = float(totals.get(key, 0.0)) + maxf(float(snapshot.get(key, 0.0)), 0.0)
	totals.peak_alive_pressure = maxf(float(totals.peak_alive_pressure), maxf(float(snapshot.get("peak_alive_pressure", 0.0)), 0.0))

static func _finalize_spawn_director(totals: Dictionary, run_count: int) -> Dictionary:
	var base_experience := float(totals.base_spawn_experience)
	var bonus_experience := float(totals.bonus_spawn_experience)
	return {
		"base_spawn_count_total": float(totals.base_spawn_count),
		"bonus_spawn_count_total": float(totals.bonus_spawn_count),
		"base_spawn_experience_total": base_experience,
		"bonus_spawn_experience_total": bonus_experience,
		"bonus_experience_ratio": bonus_experience / maxf(base_experience + bonus_experience, 1.0),
		"average_alive_pressure": _average(float(totals.average_alive_pressure), run_count),
		"peak_alive_pressure": float(totals.peak_alive_pressure),
	}

static func _matching_offer_context(selection: Dictionary, offer_events: Array) -> Dictionary:
	var formation_id := String(selection.get("formation_id", ""))
	var selected_at := float(selection.get("elapsed", INF))
	var best: Dictionary = {}
	var best_gap := INF
	for event_value in offer_events:
		if not event_value is Dictionary:
			continue
		var event := event_value as Dictionary
		if String(event.get("formation_id", "")) != formation_id:
			continue
		var offered_at := float(event.get("elapsed", 0.0))
		var gap := selected_at - offered_at
		if gap >= -0.001 and gap < best_gap:
			best = event
			best_gap = gap
	return best

static func _accumulate_tower_efficiency(totals: Dictionary, efficiency: Dictionary, elapsed_seconds: float) -> void:
	var measured_minutes := maxf(elapsed_seconds / 60.0, 1.0 / 60.0)
	for tower_id in efficiency:
		var sample := efficiency[tower_id] as Dictionary
		if not totals.has(tower_id):
			totals[tower_id] = {
				"runs": 0, "installed": 0, "damage": 0.0, "score_minutes": 0.0,
				"efficiency_role": String(sample.get("efficiency_role", "unknown")),
				"efficiency_cohort": _normalized_efficiency_cohort(String(tower_id), sample),
			}
		var total := totals[tower_id] as Dictionary
		total.runs = int(total.runs) + 1
		total.installed = int(total.installed) + int(sample.get("installed", 0))
		total.damage = float(total.damage) + float(sample.get("damage", 0.0))
		total.score_minutes = float(total.score_minutes) + float(sample.get("formation_score_minutes", float(sample.get("formation_score_budget", 0.0)) * measured_minutes))

static func _finalize_choice_totals(totals: Dictionary) -> Dictionary:
	var set_selection_rates: Dictionary = {}
	var set_abandon_rates: Dictionary = {}
	var selection_rates: Dictionary = {}
	var abandon_rates: Dictionary = {}
	var average_placement_seconds: Dictionary = {}
	var average_valid_positions: Dictionary = {}
	var slot_selection_rates: Dictionary = {}
	for size_key in totals.set_offers:
		set_selection_rates[size_key] = _ratio(int(totals.set_selections.get(size_key, 0)), int(totals.set_offers[size_key]))
		set_abandon_rates[size_key] = _ratio(int(totals.set_abandons.get(size_key, 0)), int(totals.set_selections.get(size_key, 0)))
	for item_id in totals.offers:
		selection_rates[item_id] = _ratio(int(totals.selections.get(item_id, 0)), int(totals.offers[item_id]))
		var decisions := int(totals.selections.get(item_id, 0)) + int(totals.abandons.get(item_id, 0))
		abandon_rates[item_id] = _ratio(int(totals.abandons.get(item_id, 0)), decisions)
		average_valid_positions[item_id] = float(totals.valid_positions.get(item_id, 0.0)) / maxf(float(totals.offers[item_id]), 1.0)
	for item_id in totals.placement_seconds:
		average_placement_seconds[item_id] = float(totals.placement_seconds[item_id]) / maxf(float(totals.placement_counts.get(item_id, 0)), 1.0)
	for slot_type in totals.offer_slot_counts:
		slot_selection_rates[slot_type] = _ratio(int(totals.offer_slot_selections.get(slot_type, 0)), int(totals.offer_slot_counts[slot_type]))
	return {
		"set_offers_by_size": totals.set_offers,
		"set_selections_by_size": totals.set_selections,
		"set_selection_rates_by_size": set_selection_rates,
		"set_abandons_by_size": totals.set_abandons,
		"set_abandon_rates_by_size": set_abandon_rates,
		"offers": totals.offers,
		"selections": totals.selections,
		"selection_rates": selection_rates,
		"abandons": totals.abandons,
		"abandon_rates": abandon_rates,
		"average_placement_seconds": average_placement_seconds,
		"average_valid_positions": average_valid_positions,
		"board_context": {
			"samples": int(totals.board_sample_count),
			"average_occupancy": _average(float(totals.board_occupancy), int(totals.board_sample_count)),
			"average_isolated_empty_cells": _average(float(totals.board_isolated_cells), int(totals.board_isolated_sample_count)),
		},
		"final_board_context": {
			"runs": int(totals.final_board_samples),
			"average_occupancy": _average(float(totals.final_board_occupancy), int(totals.final_board_samples)),
			"average_isolated_empty_cells": _average(float(totals.final_board_isolated_cells), int(totals.final_board_samples)),
		},
		"by_shape": _finalize_dimension_breakdown(totals.shape_offers, totals.shape_selections, totals.shape_abandons, totals.shape_valid_positions),
		"by_distinct_tower_count": _finalize_dimension_breakdown(totals.species_offers, totals.species_selections, totals.species_abandons, totals.species_valid_positions),
		"flip_usage": {
			"regular_placements": int(totals.regular_flip_samples),
			"regular_vertical_flips": int(totals.regular_vertical_flips),
			"regular_vertical_flip_rate": _ratio(int(totals.regular_vertical_flips), int(totals.regular_flip_samples)),
			"guard_placements": int(totals.guard_flip_samples),
			"guard_vertical_flips": int(totals.guard_vertical_flips),
			"guard_vertical_flip_rate": _ratio(int(totals.guard_vertical_flips), int(totals.guard_flip_samples)),
		},
		"guard_placements": totals.guard_placements,
		"offer_diagnostics": {
			"rounds": int(totals.offer_rounds),
			"slot_offers": totals.offer_slot_counts,
			"slot_selections": totals.offer_slot_selections,
			"slot_selection_rates": slot_selection_rates,
			"primary_role_offers": totals.offer_primary_roles,
			"primary_role_selections": totals.selected_primary_roles,
			"multi_role_rounds": int(totals.multi_role_rounds),
			"multi_role_round_rate": _ratio(int(totals.multi_role_rounds), int(totals.offer_rounds)),
			"all_unique_role_rounds": int(totals.all_unique_role_rounds),
			"all_unique_role_round_rate": _ratio(int(totals.all_unique_role_rounds), int(totals.offer_rounds)),
			"duplicate_role_offers": int(totals.duplicate_role_offers),
			"discovery_bonus_offers": int(totals.discovery_bonus_offers),
			"discovery_bonus_offer_rate": _ratio(int(totals.discovery_bonus_offers), int(totals.eligible_pool_samples)),
			"recent_penalty_offers": int(totals.recent_penalty_offers),
			"average_eligible_pool_size": _average(float(totals.eligible_pool_total), int(totals.eligible_pool_samples)),
		},
		"decision_context": {
			"selection_events": int(totals.selection_event_count),
			"average_empty_cells_at_selection": _average(float(totals.selection_empty_cells), int(totals.selection_event_count)),
			"average_isolated_cells_at_selection": _average(float(totals.selection_isolated_cells), int(totals.selection_event_count)),
			"average_occupancy_at_selection": _average(float(totals.selection_occupancy), int(totals.selection_event_count)),
			"abandon_events": int(totals.abandon_event_count),
			"average_abandon_elapsed": _average(float(totals.abandon_elapsed), int(totals.abandon_event_count)),
			"refunded_experience_total": float(totals.abandon_refund),
			"average_empty_cells_at_abandon": _average(float(totals.abandon_empty_cells), int(totals.abandon_event_count)),
			"average_isolated_cells_at_abandon": _average(float(totals.abandon_isolated_cells), int(totals.abandon_event_count)),
		},
	}

static func _accumulate_dimension_decision(target: Dictionary, key: String) -> void:
	if key.is_empty() or key == "0":
		return
	target[key] = int(target.get(key, 0)) + 1

static func _finalize_dimension_breakdown(offers: Dictionary, selections: Dictionary, abandons: Dictionary, valid_positions: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var keys: Array = offers.keys()
	for key in selections:
		if key not in keys:
			keys.append(key)
	for key in abandons:
		if key not in keys:
			keys.append(key)
	keys.sort()
	for key_value in keys:
		var key := String(key_value)
		var offer_count := int(offers.get(key, 0))
		var selection_count := int(selections.get(key, 0))
		var abandon_count := int(abandons.get(key, 0))
		result[key] = {
			"offers": offer_count,
			"selections": selection_count,
			"selection_rate": _ratio(selection_count, offer_count),
			"abandons": abandon_count,
			"abandon_rate": _ratio(abandon_count, selection_count + abandon_count),
			"average_valid_positions": float(valid_positions.get(key, 0.0)) / maxf(float(offer_count), 1.0),
		}
	return result

static func _assess_balance(summary: Dictionary, assess_specialization_bias: bool = true) -> Dictionary:
	var findings: Array[Dictionary] = []
	var run_count := int(summary.get("run_count", 0))
	if run_count < MIN_RELIABLE_RUNS:
		findings.append(_finding("info", "sample_too_small", "표본이 적어 편향 판정을 보류합니다.", {
			"runs": run_count, "minimum_recommended_runs": MIN_RELIABLE_RUNS,
		}))
	elif float(summary.get("average_audit_target_seconds", 0.0)) < FULL_RUN_MINIMUM_SECONDS:
		findings.append(_finding("info", "full_run_required", "짧은 기술 감사에서는 장기 밸런스 판정을 보류합니다.", {
			"average_audit_target_seconds": float(summary.get("average_audit_target_seconds", 0.0)),
			"minimum_seconds": FULL_RUN_MINIMUM_SECONDS,
		}))
	else:
		_assess_run_completion(findings, summary)
		_assess_level_progression(findings, summary)
		_assess_formation_choices(findings, summary.get("formation_metrics", {}) as Dictionary)
		if not assess_specialization_bias:
			findings.append(_finding("info", "mixed_scenario_specialization_bias_deferred", "서로 다른 후보 시나리오를 합친 표본에서는 특화 선택 편향 판정을 시나리오별 진단으로 이관합니다.", {}))
		elif _has_only_scripted_selection(summary.get("selection_policies", {}) as Dictionary):
			findings.append(_finding("info", "scripted_specialization_policy", "고정 시나리오 우선 선택 표본에서는 특화 선택 편향 판정을 보류합니다.", {
				"selection_policies": summary.get("selection_policies", {}),
			}))
		else:
			_assess_specialization_choices(findings, summary.get("specialization_metrics", {}) as Dictionary)
		_assess_tower_efficiency(findings, summary.get("tower_score_efficiency", {}) as Dictionary)
		_assess_artifacts(findings, summary.get("artifact_metrics", {}) as Dictionary, float(summary.get("average_audit_target_seconds", 0.0)))
	var warning_count := 0
	for finding in findings:
		warning_count += 1 if String(finding.get("severity", "")) == "warning" else 0
	return {
		"sample_runs": run_count,
		"minimum_recommended_runs": MIN_RELIABLE_RUNS,
		"sample_sufficient": run_count >= MIN_RELIABLE_RUNS,
		"full_run_sample": float(summary.get("average_audit_target_seconds", 0.0)) >= FULL_RUN_MINIMUM_SECONDS,
		"assessment_ready": run_count >= MIN_RELIABLE_RUNS and float(summary.get("average_audit_target_seconds", 0.0)) >= FULL_RUN_MINIMUM_SECONDS,
		"level_target": LEVEL_TARGET,
		"full_run_minimum_seconds": FULL_RUN_MINIMUM_SECONDS,
		"finding_count": findings.size(),
		"warning_count": warning_count,
		"findings": findings,
	}

static func _assess_run_completion(findings: Array[Dictionary], summary: Dictionary) -> void:
	var completion_ratio := float(summary.get("average_completion_ratio", 0.0))
	if completion_ratio < RUN_COMPLETION_WARNING_RATIO:
		findings.append(_finding("warning", "run_completion_low", "평균 생존 시간이 장기 밸런스 감사 기준보다 짧습니다.", {
			"average_completion_ratio": completion_ratio,
			"minimum_ratio": RUN_COMPLETION_WARNING_RATIO,
		}))

static func _assess_artifacts(findings: Array[Dictionary], metrics: Dictionary, average_target_seconds: float) -> void:
	if metrics.is_empty():
		return
	var mode := String(metrics.get("mode", "disabled"))
	var offers := int(metrics.get("offers", 0))
	var acquisitions := int(metrics.get("acquisitions", 0))
	if int(metrics.get("max_inventory_count", 0)) > ArtifactInventoryState.DEFAULT_CAPACITY:
		findings.append(_finding("warning", "artifact_inventory_overflow", "아티팩트 인벤토리가 6칸 상한을 넘었습니다.", {"max_inventory_count": int(metrics.get("max_inventory_count", 0))}))
	if mode == String(GameSession.ARTIFACT_MODE_DISABLED) and (offers > 0 or acquisitions > 0):
		findings.append(_finding("warning", "artifact_disabled_leak", "아티팩트 비활성 대조군에 제안 또는 획득이 기록됐습니다.", {"offers": offers, "acquisitions": acquisitions}))
	if mode != String(GameSession.ARTIFACT_MODE_NORMAL) or average_target_seconds < FULL_RUN_MINIMUM_SECONDS:
		return
	var full_length_runs := int(metrics.get("full_length_runs", 0))
	if int(metrics.get("elite_drafts", 0)) > 0:
		if full_length_runs >= MIN_FULL_LENGTH_LEVEL_SAMPLES:
			var average_drafts := float(metrics.get("average_full_length_elite_drafts", 0.0))
			var average_acquisitions := float(metrics.get("average_full_length_acquisitions", 0.0))
			if average_drafts < 3.0 or average_drafts > 4.0:
				findings.append(_finding("warning", "artifact_elite_draft_frequency", "완주 런당 정예 아티팩트 드래프트가 목표 3~4회를 벗어났습니다.", {"average_drafts": average_drafts, "target_min": 3.0, "target_max": 4.0, "full_length_runs": full_length_runs}))
			if average_acquisitions < 2.5 or average_acquisitions > 4.5:
				findings.append(_finding("warning", "artifact_acquisition_frequency", "완주 런당 아티팩트 획득량이 정예 드롭 목표 범위를 벗어났습니다.", {"average_acquisitions": average_acquisitions, "target_min": 2.5, "target_max": 4.5, "full_length_runs": full_length_runs}))
		return
	if full_length_runs >= MIN_FULL_LENGTH_LEVEL_SAMPLES:
		var average_offers := float(metrics.get("average_full_length_offers", 0.0))
		if average_offers < 1.0 or average_offers > 2.0:
			findings.append(_finding("warning", "artifact_offer_frequency", "완주 런당 아티팩트 제안 횟수가 시작 목표 1~2회를 벗어났습니다.", {"average_offers": average_offers, "target_min": 1.0, "target_max": 2.0, "full_length_runs": full_length_runs}))
	if offers >= 6 and float(metrics.get("selection_rate", 0.0)) >= 0.98:
		findings.append(_finding("warning", "artifact_selection_forced", "아티팩트 선택률이 사실상 100%여서 일반 성장 선택을 압도할 수 있습니다.", {"offers": offers, "selection_rate": float(metrics.get("selection_rate", 0.0))}))

static func _new_artifact_totals() -> Dictionary:
	return {
		"runs": 0, "offers": 0, "acquisitions": 0, "discards": 0, "replacements": 0,
		"full_length_runs": 0, "full_length_offers": 0, "full_length_acquisitions": 0,
		"elite_drafts": 0, "full_length_elite_drafts": 0,
		"inventory_count": 0.0, "max_inventory_count": 0, "completed_inventories": 0,
		"contribution": 0.0, "modes": {}, "by_artifact": {}, "target_group_offers": {},
		"target_group_selections": {}, "target_group_outcomes": {}, "inventory_outcomes": {}, "combination_outcomes": {},
	}

static func _accumulate_artifact_metrics(totals: Dictionary, report: Dictionary) -> void:
	var metrics := report.get("artifact_metrics", {}) as Dictionary
	var inventory := report.get("artifacts", metrics.get("final_inventory", {})) as Dictionary
	var inventory_ids: Array[String] = []
	for raw_id in inventory.get("artifact_ids", []) as Array:
		inventory_ids.append(String(raw_id))
	inventory_ids.sort()
	var inventory_count := clampi(int(inventory.get("count", inventory_ids.size())), 0, ArtifactInventoryState.DEFAULT_CAPACITY)
	var mode := String(report.get("artifact_mode", GameSession.ARTIFACT_MODE_DISABLED))
	totals.runs = int(totals.runs) + 1
	totals.offers = int(totals.offers) + maxi(int(metrics.get("offers", 0)), 0)
	totals.acquisitions = int(totals.acquisitions) + maxi(int(metrics.get("acquisitions", 0)), 0)
	totals.discards = int(totals.discards) + maxi(int(metrics.get("discards", 0)), 0)
	totals.replacements = int(totals.replacements) + maxi(int(metrics.get("replacements", 0)), 0)
	totals.elite_drafts = int(totals.elite_drafts) + maxi(int(metrics.get("elite_draft_count", 0)), 0)
	var target_seconds := maxf(float(report.get("audit_target_seconds", 0.0)), 0.001)
	var full_length := bool(report.get("victory", false)) or float(report.get("elapsed", 0.0)) / target_seconds >= 0.95
	if full_length:
		totals.full_length_runs = int(totals.full_length_runs) + 1
		totals.full_length_offers = int(totals.full_length_offers) + maxi(int(metrics.get("offers", 0)), 0)
		totals.full_length_acquisitions = int(totals.full_length_acquisitions) + maxi(int(metrics.get("acquisitions", 0)), 0)
		totals.full_length_elite_drafts = int(totals.full_length_elite_drafts) + maxi(int(metrics.get("elite_draft_count", 0)), 0)
	totals.inventory_count = float(totals.inventory_count) + inventory_count
	totals.max_inventory_count = maxi(int(totals.max_inventory_count), inventory_count)
	totals.completed_inventories = int(totals.completed_inventories) + (1 if float(metrics.get("inventory_completed_at", -1.0)) >= 0.0 else 0)
	totals.contribution = float(totals.contribution) + float((metrics.get("effect_contribution", {}) as Dictionary).get("estimated_output_delta", 0.0))
	totals.modes[mode] = int(totals.modes.get(mode, 0)) + 1
	_merge_numeric_dictionary(totals.target_group_offers, metrics.get("target_group_offers", {}) as Dictionary)
	_merge_numeric_dictionary(totals.target_group_selections, metrics.get("target_group_selections", {}) as Dictionary)
	for target_group in (metrics.get("target_group_selections", {}) as Dictionary):
		if int((metrics.get("target_group_selections", {}) as Dictionary).get(target_group, 0)) > 0:
			_accumulate_artifact_outcome(totals.target_group_outcomes, String(target_group), report)
	for artifact_id in (metrics.get("by_artifact", {}) as Dictionary):
		if not totals.by_artifact.has(artifact_id):
			totals.by_artifact[artifact_id] = {"offers": 0, "acquisitions": 0, "discards": 0, "replacements": 0, "held_runs": 0, "victories_held": 0, "elapsed_held": 0.0}
		var total := totals.by_artifact[artifact_id] as Dictionary
		var sample := (metrics.by_artifact as Dictionary)[artifact_id] as Dictionary
		for key in ["offers", "acquisitions", "discards", "replacements"]:
			total[key] = int(total[key]) + maxi(int(sample.get(key, 0)), 0)
	for artifact_id in inventory_ids:
		if not totals.by_artifact.has(artifact_id):
			totals.by_artifact[artifact_id] = {"offers": 0, "acquisitions": 0, "discards": 0, "replacements": 0, "held_runs": 0, "victories_held": 0, "elapsed_held": 0.0}
		var held := totals.by_artifact[artifact_id] as Dictionary
		held.held_runs = int(held.held_runs) + 1
		held.victories_held = int(held.victories_held) + (1 if bool(report.get("victory", false)) else 0)
		held.elapsed_held = float(held.elapsed_held) + float(report.get("elapsed", 0.0))
	_accumulate_artifact_outcome(totals.inventory_outcomes, str(inventory_count), report)
	_accumulate_artifact_outcome(totals.combination_outcomes, "+".join(inventory_ids) if not inventory_ids.is_empty() else "none", report)

static func _accumulate_artifact_outcome(target: Dictionary, key: String, report: Dictionary) -> void:
	if not target.has(key):
		target[key] = {"runs": 0, "victories": 0, "final_boss_challenges": 0, "elapsed": 0.0}
	var entry := target[key] as Dictionary
	entry.runs = int(entry.runs) + 1
	entry.victories = int(entry.victories) + (1 if bool(report.get("victory", false)) else 0)
	entry.final_boss_challenges = int(entry.final_boss_challenges) + (1 if bool(report.get("final_boss_challenged", false)) else 0)
	entry.elapsed = float(entry.elapsed) + float(report.get("elapsed", 0.0))

static func _finalize_artifact_metrics(totals: Dictionary, run_count: int) -> Dictionary:
	var by_artifact := (totals.by_artifact as Dictionary).duplicate(true)
	for artifact_id in by_artifact:
		var entry := by_artifact[artifact_id] as Dictionary
		entry["selection_rate"] = _ratio(int(entry.acquisitions), int(entry.offers))
		entry["discard_rate"] = _ratio(int(entry.discards), int(entry.offers))
		entry["held_victory_rate"] = _ratio(int(entry.victories_held), int(entry.held_runs))
		entry["held_average_elapsed"] = _average(float(entry.elapsed_held), int(entry.held_runs))
		entry.erase("elapsed_held")
	var mode := "mixed"
	if (totals.modes as Dictionary).size() == 1:
		mode = String((totals.modes as Dictionary).keys().front())
	return {
		"mode": mode,
		"runs": run_count,
		"offers": int(totals.offers),
		"average_offers": _average(float(totals.offers), run_count),
		"acquisitions": int(totals.acquisitions),
		"average_acquisitions": _average(float(totals.acquisitions), run_count),
		"full_length_runs": int(totals.full_length_runs),
		"average_full_length_offers": _average(float(totals.full_length_offers), int(totals.full_length_runs)),
		"average_full_length_acquisitions": _average(float(totals.full_length_acquisitions), int(totals.full_length_runs)),
		"elite_drafts": int(totals.elite_drafts),
		"average_elite_drafts": _average(float(totals.elite_drafts), run_count),
		"average_full_length_elite_drafts": _average(float(totals.full_length_elite_drafts), int(totals.full_length_runs)),
		"discards": int(totals.discards),
		"replacements": int(totals.replacements),
		"selection_rate": _ratio(int(totals.acquisitions), int(totals.offers)),
		"discard_rate": _ratio(int(totals.discards), int(totals.offers)),
		"average_inventory_count": _average(float(totals.inventory_count), run_count),
		"max_inventory_count": int(totals.max_inventory_count),
		"completed_inventory_runs": int(totals.completed_inventories),
		"average_estimated_output_delta": _average(float(totals.contribution), run_count),
		"by_artifact": by_artifact,
		"target_group_offers": (totals.target_group_offers as Dictionary).duplicate(true),
		"target_group_selections": (totals.target_group_selections as Dictionary).duplicate(true),
		"target_group_outcomes": _finalize_artifact_outcomes(totals.target_group_outcomes),
		"inventory_outcomes": _finalize_artifact_outcomes(totals.inventory_outcomes),
		"combination_outcomes": _finalize_artifact_outcomes(totals.combination_outcomes),
	}

static func _finalize_artifact_outcomes(totals: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in totals:
		var total := totals[key] as Dictionary
		var runs := int(total.runs)
		result[key] = {"runs": runs, "victory_rate": _ratio(int(total.victories), runs), "final_boss_challenge_rate": _ratio(int(total.final_boss_challenges), runs), "average_elapsed": _average(float(total.elapsed), runs)}
	return result

static func _assess_level_progression(findings: Array[Dictionary], summary: Dictionary) -> void:
	var average_level := float(summary.get("average_level", 0.0))
	if summary.has("full_length_runs"):
		var full_length_runs := int(summary.get("full_length_runs", 0))
		if full_length_runs < MIN_FULL_LENGTH_LEVEL_SAMPLES:
			findings.append(_finding("info", "full_length_level_sample_too_small", "완주 레벨 표본이 적어 성장 속도 판정을 보류합니다.", {
				"runs": full_length_runs, "minimum_recommended_runs": MIN_FULL_LENGTH_LEVEL_SAMPLES,
			}))
			return
		average_level = float(summary.get("average_full_length_level", 0.0))
	elif float(summary.get("average_completion_ratio", 0.0)) < 0.95:
		return
	if average_level < LEVEL_TARGET - LEVEL_TOLERANCE:
		findings.append(_finding("warning", "level_progression_low", "완주 표본의 평균 레벨이 목표 범위보다 낮습니다.", {
			"average_level": average_level, "target": LEVEL_TARGET, "lower_bound": LEVEL_TARGET - LEVEL_TOLERANCE,
		}))
	elif average_level > LEVEL_TARGET + LEVEL_TOLERANCE:
		findings.append(_finding("warning", "level_progression_high", "완주 표본의 평균 레벨이 목표 범위보다 높습니다.", {
			"average_level": average_level, "target": LEVEL_TARGET, "upper_bound": LEVEL_TARGET + LEVEL_TOLERANCE,
		}))

static func _assess_formation_choices(findings: Array[Dictionary], metrics: Dictionary) -> void:
	var size_offers := metrics.get("set_offers_by_size", {}) as Dictionary
	var size_selections := metrics.get("set_selections_by_size", {}) as Dictionary
	var size_rates := metrics.get("set_selection_rates_by_size", {}) as Dictionary
	var size_abandon_rates := metrics.get("set_abandon_rates_by_size", {}) as Dictionary
	var size_keys := size_offers.keys()
	size_keys.sort()
	for size_key in size_keys:
		var offers := int(size_offers[size_key])
		var rate := float(size_rates.get(size_key, 0.0))
		if offers >= MIN_CHOICE_OFFERS and rate < LOW_SELECTION_RATE:
			findings.append(_finding("warning", "formation_size_underselected", "%s칸 병력 세트 선택률이 낮습니다." % size_key, {
				"size": String(size_key), "offers": offers, "selection_rate": rate,
			}))
		var selections_for_size := int(size_selections.get(size_key, 0))
		var abandon_rate_for_size := float(size_abandon_rates.get(size_key, 0.0))
		if selections_for_size >= MIN_CHOICE_OFFERS and abandon_rate_for_size >= HIGH_ABANDON_RATE:
			findings.append(_finding("warning", "formation_size_abandonment_high", "%s칸 병력 세트 배치 포기율이 높습니다." % size_key, {
				"size": String(size_key), "decisions": selections_for_size, "abandon_rate": abandon_rate_for_size,
			}))
	if int(size_offers.get("2", 0)) >= MIN_CHOICE_OFFERS and int(size_offers.get("4", 0)) >= MIN_CHOICE_OFFERS:
		var two_rate := float(size_rates.get("2", 0.0))
		var four_rate := float(size_rates.get("4", 0.0))
		if four_rate + LOW_SELECTION_RATE < two_rate:
			findings.append(_finding("warning", "large_formation_avoidance", "4칸 병력 세트가 2칸보다 뚜렷하게 기피됩니다.", {
				"two_cell_selection_rate": two_rate, "four_cell_selection_rate": four_rate,
			}))
	var selections := metrics.get("selections", {}) as Dictionary
	var abandons := metrics.get("abandons", {}) as Dictionary
	var abandon_rates := metrics.get("abandon_rates", {}) as Dictionary
	var formation_ids := abandon_rates.keys()
	formation_ids.sort()
	for formation_id in formation_ids:
		var decisions := int(selections.get(formation_id, 0)) + int(abandons.get(formation_id, 0))
		var abandon_rate := float(abandon_rates[formation_id])
		if decisions >= MIN_CHOICE_OFFERS and abandon_rate >= HIGH_ABANDON_RATE:
			findings.append(_finding("warning", "formation_abandonment_high", "편대 배치 포기율이 높습니다.", {
				"formation_id": String(formation_id), "decisions": decisions, "abandon_rate": abandon_rate,
			}))
	_assess_formation_dimension(findings, metrics.get("by_shape", {}) as Dictionary, "shape", "편대 형태")
	_assess_formation_dimension(findings, metrics.get("by_distinct_tower_count", {}) as Dictionary, "species", "병종 수")

static func _assess_formation_dimension(findings: Array[Dictionary], breakdown: Dictionary, code_prefix: String, label: String) -> void:
	var keys := breakdown.keys()
	keys.sort()
	for key_value in keys:
		var key := String(key_value)
		var sample := breakdown[key] as Dictionary
		var offers := int(sample.get("offers", 0))
		var selections := int(sample.get("selections", 0))
		var abandons := int(sample.get("abandons", 0))
		var selection_rate := float(sample.get("selection_rate", 0.0))
		var abandon_rate := float(sample.get("abandon_rate", 0.0))
		if offers >= MIN_CHOICE_OFFERS and selection_rate < LOW_SELECTION_RATE:
			findings.append(_finding("warning", "formation_%s_underselected" % code_prefix, "%s 선택률이 낮습니다." % label, {
				"value": key, "offers": offers, "selections": selections, "selection_rate": selection_rate,
			}))
		if selections + abandons >= MIN_CHOICE_OFFERS and abandon_rate >= HIGH_ABANDON_RATE:
			findings.append(_finding("warning", "formation_%s_abandonment_high" % code_prefix, "%s 배치 포기율이 높습니다." % label, {
				"value": key, "decisions": selections + abandons, "abandons": abandons, "abandon_rate": abandon_rate,
			}))

static func _assess_specialization_choices(findings: Array[Dictionary], metrics: Dictionary) -> void:
	var offers_by_id := metrics.get("offers", {}) as Dictionary
	var rates_by_id := metrics.get("selection_rates", {}) as Dictionary
	var specialization_ids := offers_by_id.keys()
	specialization_ids.sort()
	for specialization_id in specialization_ids:
		var offers := int(offers_by_id[specialization_id])
		var rate := float(rates_by_id.get(specialization_id, 0.0))
		if offers < MIN_CHOICE_OFFERS:
			continue
		if rate <= 0.0:
			findings.append(_finding("warning", "specialization_never_selected", "충분히 제시된 특화가 한 번도 선택되지 않았습니다.", {
				"specialization_id": String(specialization_id), "offers": offers,
			}))
		elif rate >= 0.8:
			findings.append(_finding("warning", "specialization_overselected", "특화 선택률이 과도하게 높습니다.", {
				"specialization_id": String(specialization_id), "offers": offers, "selection_rate": rate,
			}))

static func _has_only_scripted_selection(selection_policies: Dictionary) -> bool:
	return selection_policies.size() == 1 and int(selection_policies.get("scripted_scenario_priority", 0)) > 0

static func _assess_tower_efficiency(findings: Array[Dictionary], efficiency: Dictionary) -> void:
	var eligible_by_cohort: Dictionary = {}
	for tower_id in efficiency:
		var sample := efficiency[tower_id] as Dictionary
		var efficiency_role := String(sample.get("efficiency_role", "unknown"))
		if efficiency_role in ["damage", "unknown"] and int(sample.get("sampled_runs", 0)) >= MIN_RELIABLE_RUNS and int(sample.get("installed_total", 0)) >= MIN_CHOICE_OFFERS and float(sample.get("damage_per_score_minute", 0.0)) > 0.0:
			var cohort := _normalized_efficiency_cohort(String(tower_id), sample)
			if not eligible_by_cohort.has(cohort):
				eligible_by_cohort[cohort] = []
			(eligible_by_cohort[cohort] as Array).append(String(tower_id))
	for cohort in eligible_by_cohort:
		var eligible_ids := eligible_by_cohort[cohort] as Array
		if eligible_ids.size() < 2:
			continue
		eligible_ids.sort()
		var weakest_id := String(eligible_ids[0])
		var strongest_id := String(eligible_ids[0])
		for tower_id_value in eligible_ids:
			var tower_id := String(tower_id_value)
			var value := float((efficiency[tower_id] as Dictionary).get("damage_per_score_minute", 0.0))
			if value < float((efficiency[weakest_id] as Dictionary).get("damage_per_score_minute", 0.0)):
				weakest_id = tower_id
			if value > float((efficiency[strongest_id] as Dictionary).get("damage_per_score_minute", 0.0)):
				strongest_id = tower_id
		var weakest_value := float((efficiency[weakest_id] as Dictionary).get("damage_per_score_minute", 0.0))
		var strongest_value := float((efficiency[strongest_id] as Dictionary).get("damage_per_score_minute", 0.0))
		var ratio := strongest_value / maxf(weakest_value, 0.0001)
		if ratio >= TOWER_EFFICIENCY_REVIEW_RATIO:
			findings.append(_finding("warning", "tower_efficiency_spread", "같은 화력 역할군의 편성점수 대비 병력 피해 효율 격차가 큽니다.", {
				"efficiency_cohort": String(cohort),
				"strongest_tower_id": strongest_id, "weakest_tower_id": weakest_id, "ratio": ratio,
				"strongest_efficiency": strongest_value, "weakest_efficiency": weakest_value,
			}))

static func _finding(severity: String, code: String, message: String, evidence: Dictionary) -> Dictionary:
	return {"severity": severity, "code": code, "message": message, "evidence": evidence}

static func _normalized_efficiency_cohort(tower_id: String, sample: Dictionary) -> String:
	if tower_id in NETWORK_DEPENDENT_TOWER_IDS:
		return "network_damage"
	return String(sample.get("efficiency_cohort", "unknown"))

static func _has_formation_abandon(metrics: Dictionary) -> bool:
	if not (metrics.get("abandon_events", []) as Array).is_empty():
		return true
	for count in (metrics.get("formation_abandons", {}) as Dictionary).values():
		if int(count) > 0:
			return true
	return false

static func _accumulate_guard_layout(totals: Dictionary, report: Dictionary) -> void:
	var board := report.get("formation_board", []) as Array
	var guard: Dictionary = {}
	var first_regular: Dictionary = {}
	for placement_value in board:
		if not placement_value is Dictionary:
			continue
		var placement := placement_value as Dictionary
		if bool(placement.get("is_guard", false)):
			guard = placement
		elif first_regular.is_empty():
			first_regular = placement
	if guard.is_empty():
		return
	var layout_key := "%s@%d,%d:%s" % [
		String(guard.get("formation_id", "guard")),
		int(guard.get("anchor_x", -1)),
		int(guard.get("anchor_y", -1)),
		"flip" if bool(guard.get("vertical_flipped", false)) else "normal",
	]
	if not totals.has(layout_key):
		totals[layout_key] = {"runs": 0, "victories": 0, "completion": 0.0, "first_regular_distance": 0.0, "distance_samples": 0}
	var total := totals[layout_key] as Dictionary
	total.runs = int(total.runs) + 1
	total.victories = int(total.victories) + (1 if bool(report.get("victory", false)) else 0)
	var target := maxf(float(report.get("audit_target_seconds", 0.0)), 0.001)
	total.completion = float(total.completion) + clampf(float(report.get("elapsed", 0.0)) / target, 0.0, 1.0)
	if not first_regular.is_empty():
		total.first_regular_distance = float(total.first_regular_distance) + _minimum_cell_distance(guard, first_regular)
		total.distance_samples = int(total.distance_samples) + 1

static func _minimum_cell_distance(left: Dictionary, right: Dictionary) -> float:
	var minimum := INF
	for left_cell_value in left.get("cells", []) as Array:
		if not left_cell_value is Dictionary:
			continue
		var left_cell := left_cell_value as Dictionary
		for right_cell_value in right.get("cells", []) as Array:
			if not right_cell_value is Dictionary:
				continue
			var right_cell := right_cell_value as Dictionary
			var distance := absi(int(left_cell.get("x", 0)) - int(right_cell.get("x", 0))) + absi(int(left_cell.get("y", 0)) - int(right_cell.get("y", 0)))
			minimum = minf(minimum, float(distance))
	return minimum if is_finite(minimum) else 0.0

static func _finalize_guard_layouts(totals: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for layout_key in totals:
		var total := totals[layout_key] as Dictionary
		var runs := int(total.runs)
		result[layout_key] = {
			"runs": runs,
			"victories": int(total.victories),
			"victory_rate": _ratio(int(total.victories), runs),
			"average_completion_ratio": _average(float(total.completion), runs),
			"average_first_regular_distance": _average(float(total.first_regular_distance), int(total.distance_samples)),
		}
	return result

static func _accumulate_guard_combat(totals: Dictionary, combat: Dictionary, elapsed_seconds: float) -> void:
	for formation_id in combat:
		var sample := combat[formation_id] as Dictionary
		if not totals.has(formation_id):
			totals[formation_id] = {
				"runs": 0, "seconds": 0.0, "attacks": 0, "hits": 0,
				"damage": 0.0, "kills": 0, "control_applications": 0, "by_tower": {},
			}
		var total := totals[formation_id] as Dictionary
		total.runs = int(total.runs) + 1
		total.seconds = float(total.seconds) + maxf(elapsed_seconds, 0.0)
		total.attacks = int(total.attacks) + int(sample.get("attacks", 0))
		total.hits = int(total.hits) + int(sample.get("hits", 0))
		total.damage = float(total.damage) + float(sample.get("damage", 0.0))
		total.kills = int(total.kills) + int(sample.get("kills", 0))
		total.control_applications = int(total.control_applications) + int(sample.get("control_applications", 0))
		var total_by_tower := total.by_tower as Dictionary
		for tower_id in (sample.get("by_tower", {}) as Dictionary):
			var tower_sample := (sample.by_tower as Dictionary)[tower_id] as Dictionary
			if not total_by_tower.has(tower_id):
				total_by_tower[tower_id] = {"attacks": 0, "hits": 0, "damage": 0.0, "kills": 0, "control_applications": 0}
			var tower_total := total_by_tower[tower_id] as Dictionary
			for metric_key in ["attacks", "hits", "kills", "control_applications"]:
				tower_total[metric_key] = int(tower_total[metric_key]) + int(tower_sample.get(metric_key, 0))
			tower_total.damage = float(tower_total.damage) + float(tower_sample.get("damage", 0.0))

static func _finalize_guard_combat(totals: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for formation_id in totals:
		var total := totals[formation_id] as Dictionary
		var runs := int(total.runs)
		var measured_minutes := maxf(float(total.seconds) / 60.0, 1.0 / 60.0)
		result[formation_id] = {
			"sampled_runs": runs,
			"attacks_total": int(total.attacks),
			"hits_total": int(total.hits),
			"damage_total": float(total.damage),
			"kills_total": int(total.kills),
			"control_applications_total": int(total.control_applications),
			"average_damage_per_run": _average(float(total.damage), runs),
			"damage_per_minute": float(total.damage) / measured_minutes,
			"by_tower": total.by_tower,
		}
	return result

static func _finalize_outcomes(totals: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for outcome_key in totals:
		var total := totals[outcome_key] as Dictionary
		var runs := int(total.runs)
		result[outcome_key] = {
			"runs": runs,
			"victories": int(total.victories),
			"victory_rate": _ratio(int(total.victories), runs),
			"average_elapsed": _average(float(total.elapsed), runs),
			"average_completion_ratio": _average(float(total.completion), runs),
		}
	return result

static func _finalize_tower_efficiency(totals: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for tower_id in totals:
		var total := totals[tower_id] as Dictionary
		result[tower_id] = {
			"sampled_runs": int(total.runs),
			"installed_total": int(total.installed),
			"damage_total": float(total.damage),
			"formation_score_minutes_total": float(total.score_minutes),
			"damage_per_score_minute": float(total.damage) / maxf(float(total.score_minutes), 1.0),
			"efficiency_role": String(total.get("efficiency_role", "unknown")),
			"efficiency_cohort": String(total.get("efficiency_cohort", "unknown")),
		}
	return result

static func _merge_numeric_dictionary(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		target[key] = float(target.get(key, 0.0)) + float(source[key])

static func _ratio(numerator: int, denominator: int) -> float:
	return float(numerator) / float(denominator) if denominator > 0 else 0.0

static func _average(total: float, count: int) -> float:
	return total / float(count) if count > 0 else 0.0
