extends Node

var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	AudioManager.muted = true
	GameSession.configure_tutorial()
	var wrapper: Node = (load("res://scenes/tutorial/tutorial_game.tscn") as PackedScene).instantiate()
	var game := wrapper.get_node("Game") as GameController
	game.testing_mode = true
	add_child(wrapper)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(game.stage_data != null and game.stage_data.id == &"tutorial_60s", "tutorial scene must start its dedicated stage")
	_check(game.tutorial_director != null and game.tutorial_director.is_step(TutorialDirector.Step.MOVE_RETAINER), "tutorial scene must start at the movement lesson")
	_check(not game.hud.speed_button.visible and not game.hud.range_button.visible, "tutorial scene must hide unrelated combat controls")
	_check(game.tutorial_action_guide != null and game.tutorial_action_guide.visible and game.tutorial_action_guide.world_target == game.target_cursor and game.tutorial_action_guide.action_label.contains("드래그"), "the movement lesson must visibly emphasize Kanda and its drag action")

	game.tutorial_director.record_movement(TutorialDirector.MOVE_DISTANCE_REQUIRED)
	_check(game.get_tree().paused and game.preparation_panel.visible, "movement completion must pause combat for designated placement")
	_check(game.preparation_panel.selected_anchor == game.tutorial_scenario.required_formation_anchor, "tutorial placement must select the required anchor")
	_check(game.tutorial_action_guide.control_targets.size() == 2 and game.preparation_panel.confirm_button in game.tutorial_action_guide.control_targets, "the placement lesson must emphasize both the designated cell and confirmation action")
	game._on_block_formation_confirmed(DataRegistry.get_formation(game.tutorial_scenario.formation_id), game.tutorial_scenario.required_formation_anchor, false)
	_check(not game.get_tree().paused and game.tutorial_director.is_step(TutorialDirector.Step.OBSERVE_DEFENSE), "fixed formation placement must resume the observation lesson")
	_check(not game.tutorial_action_guide.visible, "observation-only steps must remove action emphasis instead of implying input")

	game.tutorial_director.advance(game.tutorial_scenario.observation_seconds)
	_check(game.get_tree().paused and game.level_up_panel.visible and game.level_up_panel.choices.size() == 1, "observation must open exactly one fixed growth card")
	_check(game.tutorial_action_guide.visible and game.tutorial_action_guide.control_targets == game.level_up_panel.tutorial_action_controls(), "fixed growth must emphasize its only selectable card")
	game._on_upgrade_selected(game.level_up_panel.choices[0])
	_check(not game.get_tree().paused and game.tutorial_director.is_step(TutorialDirector.Step.TUTORIAL_BOSS), "fixed growth must resume a bounded practical drill")
	_check(game.tutorial_action_guide.world_target == game.target_cursor and game.tutorial_action_guide.action_label.contains("위험한 행"), "the practical drill must return emphasis to Kanda's lane movement")
	_check(game.enemy_spawner.running and not game.enemy_spawner.regular_schedule_enabled and not game.enemy_spawner.boss_schedule_enabled, "the practical drill must keep its clock running while suppressing random spawns and the old absolute boss schedule")
	game.set_physics_process(false)
	game.tutorial_director.advance(game.tutorial_scenario.practice_first_wave_delay_seconds)
	var practice_spawn_count := 0
	for child in game.enemy_container.get_children():
		var practice_enemy := child as Enemy
		if practice_enemy != null and practice_enemy.spawn_context != null and practice_enemy.spawn_context.packet_id == &"tutorial_practice":
			practice_spawn_count += 1
	_check(practice_spawn_count == game.tutorial_scenario.practice_units_per_wave, "the first drill beat must spawn its designated regular enemies immediately")
	_check(game.hud.warning_label.text.contains("실전 1/3"), "each drill wave must replace passive waiting with visible contextual guidance")
	var drill_clock_before := game.enemy_spawner.elapsed
	await get_tree().physics_frame
	await get_tree().physics_frame
	_check(game.enemy_spawner.elapsed > drill_clock_before, "the stage clock must keep moving during the scripted drill")
	game.tutorial_director.advance(game.tutorial_scenario.boss_lead_in_seconds)
	var scripted_practice_total := 0
	var tutorial_boss: Enemy
	for child in game.enemy_container.get_children():
		var spawned_enemy := child as Enemy
		if spawned_enemy == null:
			continue
		if spawned_enemy.spawn_context != null and spawned_enemy.spawn_context.packet_id == &"tutorial_practice":
			scripted_practice_total += 1
		if spawned_enemy.data != null and spawned_enemy.data.id == game.tutorial_scenario.tutorial_boss_id:
			tutorial_boss = spawned_enemy
	_check(scripted_practice_total == game.tutorial_scenario.practice_wave_count * game.tutorial_scenario.practice_units_per_wave, "the bounded drill must spawn all three regular-enemy waves")
	_check(game.enemy_spawner.spawned_bosses.size() == 1 and tutorial_boss != null, "the bounded drill must spawn exactly one tutorial boss")
	if tutorial_boss != null:
		tutorial_boss.set_process(false)
		tutorial_boss.set_physics_process(false)
	_check(game.tutorial_director.is_step(TutorialDirector.Step.CANDIDATE_SKILL) and is_equal_approx(game.core.skill_charge, game.core.data.skill_charge_seconds), "tutorial boss arrival must fully charge the candidate skill")
	_check(game.tutorial_action_guide.control_targets.size() == 1 and game.tutorial_action_guide.control_targets[0] == game.hud.skill_button and game.tutorial_action_guide.action_label.contains("필살 공약"), "the final lesson must emphasize the charged skill button")
	_check(not game.enemy_spawner.spawn_boss_now(0), "the scripted boss request must remain idempotent after arrival")

	get_tree().paused = false
	GameSession.end_tutorial_run()
	wrapper.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("TUTORIAL RUNTIME SMOKE PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
