class_name TowerBranchHitExecutionService
extends RefCounted

const RICOCHET_RANGE := 180.0
const SHRAPNEL_RADIUS := 130.0
const WAVE_RADIUS := 150.0
const SPREAD_RADIUS := 210.0
const EXPLOSION_RADIUS := 90.0

var targeting_service := TargetingService.new()

func execute(
		tower: TowerData,
		target: Enemy,
		enemies: Array[Enemy],
		damage: float,
		modifiers: Dictionary,
		area_stun_radius: float,
		wave_knockback: float,
		damage_callback: Callable,
		presentation_callback: Callable
	) -> Dictionary:
	var result := _empty_result()
	if tower == null or not is_instance_valid(target) or modifiers.is_empty():
		return result
	result.applied = true
	_apply_initial_statuses(tower, target, enemies, damage, modifiers, area_stun_radius)
	result.execute_damage = _apply_execute_damage(target, damage, modifiers, damage_callback)
	result.ricochet_damage = _apply_ricochet(target, enemies, damage, modifiers, damage_callback, presentation_callback)
	result.shrapnel_damage = _apply_shrapnel(target, enemies, damage, modifiers, damage_callback, presentation_callback)
	result.knocked_targets = _apply_wave(target, enemies, modifiers, wave_knockback)
	var transition := _apply_target_transition(target, enemies, damage, modifiers, damage_callback)
	result.spread_target = transition.spread_target
	result.center_damage = transition.center_damage
	result.explosion_damage = _apply_explosion(target, enemies, damage, modifiers, damage_callback, presentation_callback)
	result.dealt = float(result.execute_damage) + float(result.ricochet_damage) + float(result.shrapnel_damage) + float(result.center_damage) + float(result.explosion_damage)
	return result

func _apply_initial_statuses(tower: TowerData, target: Enemy, enemies: Array[Enemy], damage: float, modifiers: Dictionary, area_stun_radius: float) -> void:
	if modifiers.has("burn"):
		target.apply_status(&"burn", 4.0, damage * float(modifiers.burn))
	if modifiers.has("mark") and tower.behavior != &"mark":
		target.apply_status(&"mark", 4.0, float(modifiers.mark))
	if not modifiers.has("stun"):
		return
	var stun_duration := float(modifiers.stun)
	target.apply_status(&"stun", stun_duration, 1.0)
	if tower.behavior != &"area":
		return
	for enemy in enemies:
		if _is_active_other(enemy, target) and enemy.global_position.distance_to(target.global_position) <= area_stun_radius:
			enemy.apply_status(&"stun", stun_duration, 1.0)

func _apply_execute_damage(target: Enemy, damage: float, modifiers: Dictionary, damage_callback: Callable) -> float:
	if not modifiers.has("execute") or not damage_callback.is_valid() or target.get_health_ratio() > float(modifiers.get("execute_ratio", 0.35)):
		return 0.0
	return float(damage_callback.call(target, damage * (float(modifiers.execute) - 1.0), &"branch_execute", true))

func _apply_ricochet(target: Enemy, enemies: Array[Enemy], damage: float, modifiers: Dictionary, damage_callback: Callable, presentation_callback: Callable) -> float:
	if not modifiers.has("ricochet") or not damage_callback.is_valid():
		return 0.0
	var dealt := 0.0
	var ricochet_count := maxi(int(modifiers.get("ricochet_count", 1)), 1)
	var ricochet_targets := targeting_service.build_chain(enemies, target, ricochet_count + 1, RICOCHET_RANGE)
	for ricochet_index in range(1, ricochet_targets.size()):
		var secondary := ricochet_targets[ricochet_index]
		var ricochet_damage := damage * float(modifiers.ricochet) * pow(float(modifiers.get("ricochet_falloff", 1.0)), ricochet_index - 1)
		dealt += float(damage_callback.call(secondary, ricochet_damage, &"ricochet", true))
		_present(presentation_callback, secondary, ricochet_targets[ricochet_index - 1].global_position, ricochet_damage, 0.42, &"ricochet")
	return dealt

func _apply_shrapnel(target: Enemy, enemies: Array[Enemy], damage: float, modifiers: Dictionary, damage_callback: Callable, presentation_callback: Callable) -> float:
	if not modifiers.has("shrapnel") or not damage_callback.is_valid():
		return 0.0
	var dealt := 0.0
	var hit_index := 0
	for enemy in enemies:
		if not _is_active_other(enemy, target) or enemy.global_position.distance_to(target.global_position) > SHRAPNEL_RADIUS:
			continue
		var shrapnel_damage := damage * float(modifiers.shrapnel)
		dealt += float(damage_callback.call(enemy, shrapnel_damage, &"shrapnel", true))
		if hit_index < 4:
			_present(presentation_callback, enemy, target.global_position, shrapnel_damage, 0.34, &"shrapnel")
		hit_index += 1
	return dealt

func _apply_wave(target: Enemy, enemies: Array[Enemy], modifiers: Dictionary, wave_knockback: float) -> Array[Enemy]:
	var knocked_targets: Array[Enemy] = []
	if not modifiers.has("wave"):
		return knocked_targets
	for enemy in enemies:
		if not _is_active_other(enemy, target) or enemy.global_position.distance_to(target.global_position) > WAVE_RADIUS:
			continue
		enemy.apply_knockback(wave_knockback)
		knocked_targets.append(enemy)
	return knocked_targets

func _apply_target_transition(target: Enemy, enemies: Array[Enemy], damage: float, modifiers: Dictionary, damage_callback: Callable) -> Dictionary:
	var spread_target: Enemy
	if modifiers.has("spread_status") and not target.active:
		spread_target = targeting_service.closest_other(enemies, target, SPREAD_RADIUS)
		if spread_target != null:
			var spread_status: StringName = modifiers.spread_status
			var spread_power := damage * 0.12 if spread_status == &"burn" else float(modifiers.get("mark", 0.2))
			spread_target.apply_status(spread_status, 3.0, spread_power)
	var center_damage := 0.0
	if modifiers.has("center_damage") and target.active and damage_callback.is_valid():
		center_damage = float(damage_callback.call(target, damage * float(modifiers.center_damage), &"branch_center", true))
	if modifiers.has("experience_bonus") and target.active:
		target.experience_multiplier = maxf(target.experience_multiplier, float(modifiers.experience_bonus))
	return {"spread_target": spread_target, "center_damage": center_damage}

func _apply_explosion(target: Enemy, enemies: Array[Enemy], damage: float, modifiers: Dictionary, damage_callback: Callable, presentation_callback: Callable) -> float:
	if not bool(modifiers.get("explosion", false)) or not damage_callback.is_valid():
		return 0.0
	var dealt := 0.0
	var hit_index := 0
	for enemy in enemies:
		if not _is_active_other(enemy, target) or enemy.global_position.distance_to(target.global_position) > EXPLOSION_RADIUS:
			continue
		var explosion_damage := damage * 0.3
		dealt += float(damage_callback.call(enemy, explosion_damage, &"branch_explosion", true))
		if hit_index < 4:
			_present(presentation_callback, enemy, target.global_position, explosion_damage, 0.32, &"branch_explosion")
		hit_index += 1
	return dealt

func _present(callback: Callable, target: Enemy, origin: Vector2, damage: float, strength: float, source: StringName) -> void:
	if callback.is_valid():
		callback.call({"target": target, "origin": origin, "damage": damage, "strength": strength, "source": source})

func _is_active_other(enemy: Enemy, target: Enemy) -> bool:
	return is_instance_valid(enemy) and enemy != target and enemy.active

func _empty_result() -> Dictionary:
	return {
		"applied": false,
		"dealt": 0.0,
		"execute_damage": 0.0,
		"ricochet_damage": 0.0,
		"shrapnel_damage": 0.0,
		"center_damage": 0.0,
		"explosion_damage": 0.0,
		"knocked_targets": [],
		"spread_target": null,
	}
