class_name V019M2TutorialContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var scenario := load("res://data/tutorial/tutorial_v0_17.tres") as TutorialScenarioData
	_expect(scenario != null, "M2 must provide a loadable tutorial scenario resource", failures)
	if scenario == null:
		return failures
	_expect(scenario.get_validation_errors().is_empty(), "the tutorial scenario must satisfy its fixed-content and duration contract", failures)
	_expect(TutorialDirector.LEARNING_STEP_COUNT == 6 and TutorialDirector.STEP_IDS.size() == 6, "the tutorial must expose exactly six learning steps", failures)
	_expect(TutorialDirector.INSTRUCTIONS[0].contains("연설 종료까지 지키") and TutorialDirector.INSTRUCTIONS[0].contains("직접 움직여 싸우") and TutorialDirector.INSTRUCTIONS[0].contains("회수"), "the opening lesson must explain the candidate protection goal and the retainer's direct-combat/collection role before movement", failures)
	_expect(scenario.stage_data.duration_seconds >= 45.0 and scenario.stage_data.duration_seconds <= 75.0, "the tutorial stage must target the 45-75 second onboarding window", failures)
	_expect(scenario.core_id == &"emerald" and scenario.cursor_id == &"iron", "the tutorial must fix Partason and Kanda", failures)
	_expect(scenario.formation_id == &"guidance" and scenario.fixed_upgrade_category == &"tower_type_level" and scenario.fixed_upgrade_id == &"rapid", "the tutorial must fix the goblin formation and its one growth card", failures)
	_expect(scenario.tutorial_enemy_id == &"goblin_raider" and scenario.tutorial_boss_id == &"boss_5", "the tutorial must fix its regular enemy and boss", failures)
	_expect(scenario.practice_wave_count == 3 and scenario.practice_units_per_wave == 2, "the boss lead-in must contain three two-unit regular-enemy practice waves", failures)
	_expect(scenario.practice_wave_interval_seconds <= 3.0 and scenario.boss_lead_in_seconds <= 10.0, "the practical drill must not leave more than a short gap before its scripted boss", failures)
	_expect(ResourceLoader.exists("res://scenes/tutorial/tutorial_game.tscn"), "M2 must provide a dedicated tutorial scene entry", failures)
	_expect(ResourceLoader.exists("res://scripts/ui/tutorial_action_guide.gd"), "M2 must provide a reusable action-emphasis layer", failures)

	var director := TutorialDirector.new()
	var requested_waves: Array[int] = []
	var guidance_updates: Array[String] = []
	var warning_requests: Array[float] = []
	var boss_requests: Array[bool] = []
	director.practice_wave_requested.connect(func(wave_index: int) -> void: requested_waves.append(wave_index))
	director.guidance_changed.connect(func(_step_index: int, instruction: String) -> void: guidance_updates.append(instruction))
	director.boss_warning_requested.connect(func(seconds_remaining: float) -> void: warning_requests.append(seconds_remaining))
	director.boss_requested.connect(func() -> void: boss_requests.append(true))
	_expect(director.begin(scenario), "the director must accept the authoritative tutorial scenario", failures)
	_expect(not director.record_growth(&"tower_type_level", &"rapid") and director.is_step(TutorialDirector.Step.MOVE_RETAINER), "out-of-order tutorial actions must not skip learning steps", failures)
	_expect(director.record_movement(TutorialDirector.MOVE_DISTANCE_REQUIRED), "the movement lesson must advance after the required distance", failures)
	_expect(director.record_formation(scenario.formation_id, scenario.required_formation_anchor), "the designated goblin placement must advance the tutorial", failures)
	director.advance(scenario.observation_seconds)
	_expect(director.is_step(TutorialDirector.Step.FIXED_GROWTH), "the observation lesson must advance only after its timer", failures)
	_expect(director.record_growth(scenario.fixed_upgrade_category, scenario.fixed_upgrade_id), "the one fixed growth card must advance the tutorial", failures)
	director.advance(scenario.boss_lead_in_seconds)
	_expect(requested_waves == [0, 1, 2] and guidance_updates.size() == 3, "the boss wait must become three explained regular-enemy practice waves", failures)
	_expect(warning_requests.size() == 1 and boss_requests.size() == 1, "the practical drill must request one warning and one boss within ten seconds", failures)
	director.advance(scenario.boss_lead_in_seconds)
	_expect(requested_waves.size() == 3 and warning_requests.size() == 1 and boss_requests.size() == 1, "scripted tutorial events must be idempotent", failures)
	_expect(director.record_boss(scenario.tutorial_boss_id), "the designated tutorial boss must unlock the candidate skill lesson", failures)
	_expect(director.record_skill_cast() and bool(director.snapshot().completed), "candidate skill use must complete the six-step director", failures)

	var save_backup := SaveManager._build_save_data()
	var fresh_v12 := SaveManager._normalize_save_data({"meta_progression_version": 12, "total_runs": 0, "unlocked_ids": ["emerald", "iron"], "legacy_full_unlock": false})
	var established_v12 := SaveManager._normalize_save_data({"meta_progression_version": 12, "total_runs": 1, "unlocked_ids": ["emerald", "iron"], "legacy_full_unlock": false})
	_expect(int(fresh_v12.meta_progression_version) == 14 and not bool(fresh_v12.tutorial_completed), "a fresh v12 save must migrate to v14 with tutorial incomplete", failures)
	_expect(bool(established_v12.tutorial_completed), "an established pre-v13 player must not be forced back through onboarding", failures)
	SaveManager._apply_save_data(fresh_v12)
	var runs_before := SaveManager.total_runs
	var funds_before := SaveManager.defense_funds
	var first_completion := SaveManager._apply_tutorial_completion_in_memory()
	var duplicate_completion := SaveManager._apply_tutorial_completion_in_memory()
	_expect(first_completion and not duplicate_completion, "tutorial completion must be idempotent in memory", failures)
	_expect(SaveManager.total_runs == runs_before and SaveManager.defense_funds == funds_before and SaveManager.settled_run_ids.is_empty(), "tutorial completion must not award run settlement or meta currency", failures)
	SaveManager._apply_save_data(save_backup)

	var controller_source := FileAccess.get_file_as_string("res://scripts/game/game_controller.gd")
	var menu_source := FileAccess.get_file_as_string("res://scripts/ui/main_menu.gd")
	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud.gd")
	var action_guide_source := FileAccess.get_file_as_string("res://scripts/ui/tutorial_action_guide.gd")
	_expect(controller_source.contains("GameSession.is_tutorial_run()") and controller_source.contains("SaveManager.complete_tutorial()") and controller_source.contains("or _is_tutorial()"), "tutorial runtime must isolate checkpoint settlement and persist only completion", failures)
	_expect(controller_source.contains("_update_tutorial_action_guide") and controller_source.contains("focus_world(target_cursor") and controller_source.contains("focus_controls([hud.skill_button]"), "tutorial steps must route movement and final skill actions to visible emphasis targets", failures)
	_expect(action_guide_source.contains("MOUSE_FILTER_IGNORE") and action_guide_source.contains("UiMotion.is_reduced()"), "tutorial action emphasis must not intercept input and must honor reduced motion", failures)
	_expect(menu_source.contains("not SaveManager.tutorial_completed") and menu_source.contains("configure_tutorial()"), "fresh menu routing must enter the tutorial before setup", failures)
	_expect(hud_source.contains("speed_button.visible = not enabled") and hud_source.contains("range_button.visible = not enabled"), "tutorial HUD must hide speed and unrelated range controls", failures)
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
