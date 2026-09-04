class_name RunShutdownService
extends RefCounted

func cleanup_combat_runtime(
	enemy_spawner: EnemySpawner,
	target_cursor: TargetCursor,
	core: DefenseCore,
	enemies: Array[Enemy],
	reaper_summon: Variant,
	death_wave_controller: DeathWaveController,
	necromancy_controller: NecromancyController,
	projectiles: Array[Node],
	summons: Array[Node],
	summon_service: SummonService
) -> Dictionary:
	var summary := {
		"primary_actors_stopped": 0,
		"enemies_stopped": 0,
		"projectiles_queued": 0,
		"abyss_summons_expired": 0,
		"reaper_queued": false,
		"death_wave_cancelled": false,
		"necromancy_cleared": false,
		"summon_budget_reset": false,
	}
	if enemy_spawner != null and is_instance_valid(enemy_spawner):
		enemy_spawner.stop()
		summary.primary_actors_stopped += 1
	if target_cursor != null and is_instance_valid(target_cursor):
		target_cursor.stop()
		summary.primary_actors_stopped += 1
	if core != null and is_instance_valid(core):
		core.stop()
		summary.primary_actors_stopped += 1
	if is_instance_valid(reaper_summon) and reaper_summon is Node:
		(reaper_summon as Node).queue_free()
		summary.reaper_queued = true
	if death_wave_controller != null and is_instance_valid(death_wave_controller):
		death_wave_controller.cancel()
		summary.death_wave_cancelled = true
	if necromancy_controller != null and is_instance_valid(necromancy_controller):
		necromancy_controller.clear_active_summons(false)
		summary.necromancy_cleared = true
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy):
			continue
		enemy.stop()
		summary.enemies_stopped += 1
	for projectile in projectiles:
		if projectile == null or not is_instance_valid(projectile):
			continue
		projectile.queue_free()
		summary.projectiles_queued += 1
	for summon in summons:
		if summon is AbyssSummon and is_instance_valid(summon):
			(summon as AbyssSummon).force_expire()
			summary.abyss_summons_expired += 1
	if summon_service != null and is_instance_valid(summon_service):
		summon_service.reset_budget()
		summary.summon_budget_reset = true
	return summary
