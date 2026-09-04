class_name RunOutcomeSummaryContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var metrics := RunMetrics.new()
	metrics.record_status_application(&"poison", 3)
	metrics.record_status_application(&"shock", 5)
	metrics.record_status_application(&"slow", 2)
	metrics.status_damage = {"poison": 120.0, "shock": 80.0}
	var status_summary := metrics.status_contribution_snapshot()
	_expect(int(status_summary.active_status_count) == 3 and int(status_summary.total_applications) == 10 and is_equal_approx(float(status_summary.total_damage), 200.0), "status outcome summary must preserve distinct sources, applications, and damage", failures)
	_expect(String(status_summary.top_status_id) == "poison" and int(status_summary.top_applications) == 3 and is_equal_approx(float(status_summary.top_damage), 120.0), "top status must prioritize measured status damage before application count", failures)

	var stage := load("res://data/stages/standard_20m.tres") as StageData
	var board := [
		{"is_guard": true, "cells": [{}, {}, {}, {}]},
		{"is_guard": false, "cells": [{}, {}, {}]},
		{"is_guard": false, "cells": [{}, {}]},
	]
	var formation_metrics := {"guard_combat": {
		"guard_a": {"damage": 410.0, "kills": 5, "control_applications": 2},
		"guard_b": {"damage": 90.0, "kills": 1, "control_applications": 0},
	}}
	var spawn_snapshot := {
		"base_spawn_count": 100,
		"bonus_spawn_count": 20,
		"bonus_experience_ratio": 0.15,
		"fallback_group_spawn_count": 3,
		"packet_spawn_counts": {"breakthrough": 7, "escort": 4, "siege": 2},
	}
	var summary := RunOutcomeSummary.build_from_snapshots(
		stage,
		status_summary,
		board,
		formation_metrics,
		{"completed_slots": {"0": "first", "1": "branch"}, "selected_branch_id": "branch"},
		{"stage": 2, "selected_specialization_id": "guard_branch"},
		{"current_level": 6, "selected_specialization_id": "retainer_branch"},
		spawn_snapshot
	)
	_expect(int(summary.growth.candidate_slots) == 2 and int(summary.growth.guard_stage) == 2 and int(summary.growth.retainer_level) == 6, "outcome summary must preserve candidate, guard, and retainer growth state for matrix audits", failures)
	_expect(int(summary.formation.regular_formations) == 2 and int(summary.formation.regular_units) == 5 and int(summary.formation.guard_units) == 4, "outcome summary must distinguish regular formations from guard units", failures)
	_expect(is_equal_approx(float(summary.formation.guard_damage), 500.0) and int(summary.formation.guard_kills) == 6 and int(summary.formation.guard_control_applications) == 2, "outcome summary must aggregate guard combat without duplicating per-tower rows", failures)
	_expect(int(summary.spawn.base_count) == 100 and int(summary.spawn.bonus_count) == 20 and is_equal_approx(float(summary.spawn.bonus_experience_ratio), 0.15), "outcome summary must preserve base and bonus Spawn throughput", failures)
	var packets := summary.spawn.packets as Array
	_expect(packets.size() == 3 and String((packets[0] as Dictionary).display_name) == "돌파대" and int((packets[2] as Dictionary).count) == 2, "outcome summary must expose stage-owned packet names in phase order", failures)

	var hud := GameHUD.new()
	var presentation := hud._outcome_summary_text(summary)
	var growth_presentation := hud._result_growth_summary(summary, "fallback")
	_expect(presentation.contains("편대 기여") and presentation.contains("상태 기여") and presentation.contains("Spawn 처리"), "result presentation must explain formation, status, and Spawn contribution as separate short lines", failures)
	_expect(presentation.contains("독 3회") and presentation.contains("추가 20 (XP 15%)") and presentation.contains("공성대 2"), "result presentation must use readable status, bonus XP, and packet values", failures)
	_expect(growth_presentation == "후보 2/3 · 친위대 2/3 · 심복 Lv.6 · 일반 편대 2세트 · 아티팩트 0/6", "result growth summary must replace the duplicate full build with a compact role hierarchy including artifact capacity", failures)
	hud.free()
	metrics.free()
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
