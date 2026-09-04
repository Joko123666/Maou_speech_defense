class_name RunSignalBindingService
extends RefCounted

func bind_runtime(
	core: DefenseCore,
	target_cursor: TargetCursor,
	experience_rewards: ExperienceRewardService,
	enemy_spawner: EnemySpawner,
	loadout: LoadoutManager,
	experience: ExperienceManager,
	level_up_panel: LevelUpPanel,
	artifact_resolution_panel: ArtifactResolutionPanel,
	pause_menu: PauseMenu,
	hud: GameHUD,
	viewport: Viewport,
	callbacks: Dictionary
) -> Dictionary:
	var summary := {
		"combat": 0,
		"progression": 0,
		"ui": 0,
	}
	summary.combat += connect_once(core.health_changed, hud.update_health)
	summary.combat += connect_once(core.health_changed, callbacks.get(&"core_health_relay", Callable()))
	summary.combat += connect_once(core.destroyed, callbacks.get(&"core_destroyed", Callable()))
	summary.combat += connect_once(core.attack_requested, callbacks.get(&"core_attack", Callable()))
	summary.combat += connect_once(core.skill_cast_started, callbacks.get(&"core_skill_cast_started", Callable()))
	summary.combat += connect_once(core.skill_cast_changed, hud.update_skill_cast)
	summary.combat += connect_once(core.skill_requested, callbacks.get(&"core_skill", Callable()))
	summary.combat += connect_once(core.skill_charge_changed, hud.update_skill_charge)
	summary.combat += connect_once(target_cursor.attack_requested, callbacks.get(&"cursor_attack", Callable()))
	summary.combat += connect_once(target_cursor.collection_requested, callbacks.get(&"collection", Callable()))
	summary.combat += connect_once(experience_rewards.boss_reward_completed, callbacks.get(&"boss_reward_completed", Callable()))
	summary.combat += connect_once(experience_rewards.retainer_experience_collected, callbacks.get(&"retainer_experience_collected", Callable()))
	summary.combat += connect_once(experience_rewards.experience_orb_spawned, callbacks.get(&"experience_orb_spawned", Callable()))
	summary.combat += connect_once(experience_rewards.experience_orb_collected, callbacks.get(&"experience_orb_collected", Callable()))
	summary.combat += connect_once(target_cursor.position_changed, callbacks.get(&"cursor_moved", Callable()))
	summary.combat += connect_once(enemy_spawner.spawn_requested, callbacks.get(&"spawn", Callable()))
	summary.combat += connect_once(enemy_spawner.boss_spawn_requested, callbacks.get(&"spawn", Callable()))
	summary.combat += connect_once(enemy_spawner.boss_warning_started, callbacks.get(&"boss_warning", Callable()))
	summary.combat += connect_once(enemy_spawner.time_changed, hud.update_time)
	summary.combat += connect_once(loadout.tower_attack_requested, callbacks.get(&"tower_attack", Callable()))
	summary.progression += connect_once(loadout.loadout_changed, hud.update_build)
	summary.progression += connect_once(loadout.loadout_changed, callbacks.get(&"range_refresh", Callable()))
	summary.progression += connect_once(loadout.loadout_changed, callbacks.get(&"execute_threshold_refresh", Callable()))
	summary.progression += connect_once(loadout.loadout_changed, callbacks.get(&"candidate_loadout_changed", Callable()))
	summary.progression += connect_once(loadout.effects_changed, hud.update_effects)
	summary.progression += connect_once(loadout.artifacts_changed, hud.update_artifacts)
	summary.progression += connect_once(loadout.upgrade_applied, hud.show_notice)
	summary.progression += connect_once(experience.experience_changed, hud.update_experience)
	summary.progression += connect_once(experience.leveled_up, callbacks.get(&"leveled_up", Callable()))
	summary.ui += connect_once(level_up_panel.choice_selected, callbacks.get(&"upgrade_selected", Callable()))
	summary.ui += connect_once(level_up_panel.reroll_requested, callbacks.get(&"level_up_reroll", Callable()))
	summary.ui += connect_once(artifact_resolution_panel.replacement_requested, callbacks.get(&"artifact_replace", Callable()))
	summary.ui += connect_once(artifact_resolution_panel.discard_requested, callbacks.get(&"artifact_discard", Callable()))
	summary.ui += connect_once(pause_menu.resume_requested, callbacks.get(&"pause_resume", Callable()))
	summary.ui += connect_once(pause_menu.quit_requested, callbacks.get(&"return_to_menu", Callable()))
	summary.ui += connect_once(pause_menu.shake_toggled, callbacks.get(&"screen_shake", Callable()))
	summary.ui += connect_once(pause_menu.flash_toggled, callbacks.get(&"screen_flash", Callable()))
	summary.ui += connect_once(pause_menu.reduced_motion_toggled, callbacks.get(&"reduced_motion", Callable()))
	summary.ui += connect_once(hud.restart_requested, callbacks.get(&"restart", Callable()))
	summary.ui += connect_once(hud.menu_requested, callbacks.get(&"return_to_menu", Callable()))
	summary.ui += connect_once(hud.skill_requested, callbacks.get(&"request_core_skill", Callable()))
	summary.ui += connect_once(hud.speed_requested, callbacks.get(&"cycle_speed", Callable()))
	summary.ui += connect_once(hud.range_overlay_requested, callbacks.get(&"set_range_overlay", Callable()))
	summary.ui += connect_once(hud.pause_requested, callbacks.get(&"open_pause", Callable()))
	summary.ui += connect_once(viewport.size_changed, callbacks.get(&"viewport_size_changed", Callable()))
	summary["total"] = int(summary.combat) + int(summary.progression) + int(summary.ui)
	return summary

func connect_once(signal_value: Signal, callback: Callable) -> int:
	if not callback.is_valid() or signal_value.is_connected(callback):
		return 0
	signal_value.connect(callback)
	return 1
