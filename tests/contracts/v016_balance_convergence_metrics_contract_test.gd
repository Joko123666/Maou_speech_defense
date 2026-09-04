class_name V016BalanceConvergenceMetricsContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var metrics := RunMetrics.new()
	metrics.update_time(12.0)
	metrics.record_level_reached(2, 33.5)
	metrics.update_time(14.0)
	metrics.record_selection(UpgradeData.new().configure(&"cursor_level", "심복 Lv.2", "contract", &"vanguard"))
	var growth := metrics.growth_timeline_snapshot()
	_expect((growth.levels as Array).size() == 1 and is_equal_approx(float((growth.levels as Array)[0].elapsed), 12.0), "growth timeline must preserve level reach time and collected XP", failures)
	_expect(is_equal_approx(float((growth.first_upgrade_by_track as Dictionary).retainer), 14.0), "growth timeline must preserve the first candidate/retainer/guard/formation milestone by track", failures)

	var enemy := DataRegistry.get_enemy(&"steel_golem")
	metrics.update_time(20.0)
	metrics.record_enemy_spawn(1, enemy, null, 101)
	metrics.update_time(27.5)
	metrics.record_enemy_defeat(1, enemy, null, Enemy.DEATH_CAUSE_DIRECT_KILL, 101)
	var removal := metrics.enemy_removal_snapshot()
	var removal_entry := (removal.by_enemy as Array)[0] as Dictionary
	_expect(int(removal_entry.removed) == 1 and is_equal_approx(float(removal_entry.average_time_to_remove), 7.5) and is_zero_approx(float(removal_entry.breach_rate)), "enemy removal metrics must pair stable runtime instances and report time-to-remove and breach rate", failures)

	metrics.record_enemy_control(enemy, &"slow", true, 0.5, 0.275, 4.0, 2.2)
	metrics.record_enemy_control(enemy, &"slow", false, 0.5, 0.0, 4.0, 0.0)
	var control := metrics.control_effectiveness_snapshot()
	var control_entry := (control.by_enemy_control as Array)[0] as Dictionary
	_expect(int(control_entry.attempts) == 2 and int(control_entry.successes) == 1 and is_equal_approx(float(control_entry.success_rate), 0.5), "control metrics must distinguish attempts from accepted applications", failures)
	_expect(is_equal_approx(float(control_entry.effect_ratio), 0.275) and is_equal_approx(float(control_entry.duration_ratio), 0.275), "control metrics must preserve requested versus effective contribution after resistance", failures)
	_expect(int(control.warning_count) == 0, "partially effective control must not be classified as a hard counter", failures)

	metrics.record_experience_drop(&"base", 20.0)
	metrics.record_experience_collection(&"base", 15.0, 18.0)
	metrics.record_experience_drop(&"bonus", 10.0)
	metrics.record_experience_collection(&"bonus", 4.0, 4.8)
	var experience_attribution := metrics.experience_attribution_snapshot()
	_expect(is_equal_approx(float(experience_attribution.by_channel.base.collection_rate), 0.75), "Base XP metrics must distinguish defeated-enemy drops from collected raw XP", failures)
	_expect(is_equal_approx(float(experience_attribution.by_channel.bonus.collection_rate), 0.4) and is_equal_approx(float(experience_attribution.awarded_total), 22.8), "Bonus XP metrics must preserve raw collection and modifier-adjusted awards separately", failures)
	var reward_service := ExperienceRewardService.new()
	_expect(is_equal_approx(reward_service.collection_radius_for_channel(100.0, &"base"), 150.0), "Base drops must receive the single approved 1.5x collection-radius floor", failures)
	_expect(is_equal_approx(reward_service.collection_radius_for_channel(100.0, &"bonus"), 100.0), "Bonus drops must remain a positional reward when the Base collection floor changes", failures)
	reward_service.free()

	var audit_source := FileAccess.get_file_as_string("res://tests/balance_audit_runner.gd")
	_expect(audit_source.contains("AUDIT_REPORT_SCHEMA_VERSION := 20") and audit_source.contains("growth_timeline") and audit_source.contains("enemy_removal") and audit_source.contains("control_effectiveness") and audit_source.contains("base_dropped") and audit_source.contains("final_boss_challenged"), "current audit reports must preserve M3 convergence, channel-accurate XP recovery, and explicit final-boss challenge state", failures)
	RunRng.seed_run(91827)
	var expected_progression_roll := RunRng.progression_roll()
	var expected_spawn_roll := RunRng.spawn_roll()
	RunRng.seed_run(91827)
	for index in 24:
		RunRng.roll()
	_expect(is_equal_approx(RunRng.progression_roll(), expected_progression_roll), "combat RNG consumption must not redraw the progression offer stream", failures)
	_expect(is_equal_approx(RunRng.spawn_roll(), expected_spawn_roll), "combat RNG consumption must not redraw the spawn composition stream", failures)
	RunRng.seed_run(91827)
	var spawn_before_progression := RunRng.spawn_roll()
	RunRng.seed_run(91827)
	for index in 24:
		RunRng.progression_roll()
	_expect(is_equal_approx(RunRng.spawn_roll(), spawn_before_progression), "progression offer RNG consumption must not redraw spawn composition", failures)
	metrics.free()
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
