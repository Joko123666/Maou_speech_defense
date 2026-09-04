class_name VanguardReaperExecutionService
extends RefCounted

const DEFAULT_DAMAGE_MULTIPLIER := 2.2
const DEFAULT_KNOCKBACK := 95.0
const RADIUS_MULTIPLIER := 1.8

func execute(
		squad: VanguardSquadComponent,
		cursor_damage: float,
		cursor_stat_multiplier: float,
		center: Vector2,
		base_radius: float,
		modifiers: Dictionary,
		target_query: Callable,
		judgment_callback: Callable
	) -> Dictionary:
	if not is_instance_valid(squad) or not target_query.is_valid() or not judgment_callback.is_valid():
		return _empty_result()
	var snapshot := squad.consume_for_reaper()
	if snapshot <= 0:
		return _empty_result()
	var radius := base_radius * RADIUS_MULTIPLIER
	var damage := cursor_damage * cursor_stat_multiplier * float(modifiers.get("vanguard_reaper_damage", DEFAULT_DAMAGE_MULTIPLIER)) * float(snapshot)
	var knockback := float(modifiers.get("vanguard_reaper_knockback", DEFAULT_KNOCKBACK))
	var targets: Array[Enemy] = []
	targets.assign(target_query.call(center, radius) as Array)
	var hit_targets: Array[Enemy] = []
	var knocked_targets: Array[Enemy] = []
	var dealt := 0.0
	var execution_count := 0
	for enemy in targets:
		if not is_instance_valid(enemy) or not enemy.active:
			continue
		var execution := judgment_callback.call(enemy, damage, &"vanguard_reaper", squad.execution_health_ratio) as Dictionary
		dealt += float(execution.get("damage", 0.0))
		hit_targets.append(enemy)
		if bool(execution.get("executed", false)):
			execution_count += 1
		if enemy.active:
			enemy.apply_knockback(knockback)
			knocked_targets.append(enemy)
	return {
		"applied": true,
		"snapshot": snapshot,
		"damage": damage,
		"knockback": knockback,
		"radius": radius,
		"dealt": dealt,
		"hit_targets": hit_targets,
		"knocked_targets": knocked_targets,
		"execution_count": execution_count,
	}

func _empty_result() -> Dictionary:
	return {
		"applied": false,
		"snapshot": 0,
		"damage": 0.0,
		"knockback": 0.0,
		"radius": 0.0,
		"dealt": 0.0,
		"hit_targets": [],
		"knocked_targets": [],
		"execution_count": 0,
	}
