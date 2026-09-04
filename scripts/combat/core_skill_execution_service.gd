class_name CoreSkillExecutionService
extends RefCounted

const BEAM_BASE_HALF_WIDTH := 110.0
const BEAM_DAMAGE_MULTIPLIER := 1.15
const BEAM_KNOCKBACK := 165.0
const BEAM_STUN_DURATION := 0.35
const RADIAL_DAMAGE_MULTIPLIER := 0.78
const RADIAL_MARK_DURATION := 6.0
const RADIAL_KNOCKBACK := 72.0
const WALL_BASE_HALF_WIDTH := 140.0
const WALL_DAMAGE_MULTIPLIER := 0.95
const WALL_SLOW_DURATION := 7.5
const WALL_SLOW_POWER := 0.76
const WALL_STUN_DURATION := 0.6
const WALL_KNOCKBACK := 120.0
const BARRAGE_HIT_LIMIT := 28
const BARRAGE_POSITION_LIMIT := 12
const BARRAGE_MIN_DAMAGE_MULTIPLIER := 0.20
const BARRAGE_MAX_DAMAGE_MULTIPLIER := 0.38
const BARRAGE_HIGHROLL_INTERVAL := 7
const BARRAGE_HIGHROLL_DAMAGE_MULTIPLIER := 0.16

func execute_candidate_extensions(
		core_data: CoreData,
		candidate_plan: Dictionary,
		damage: float,
		charm_zone_callback: Callable,
		mass_summon_callback: Callable,
		guard_active_callback: Callable,
		death_wave_callback: Callable
	) -> Dictionary:
	var result := {
		"applied": false,
		"guard_charm_extension": 0.0,
		"stage_ids": [] as Array[StringName],
	}
	if bool(candidate_plan.get("charm_zone", false)) and charm_zone_callback.is_valid():
		result.guard_charm_extension = float(charm_zone_callback.call(core_data, bool(candidate_plan.get("charm_stage_buff", false))))
		(result.stage_ids as Array[StringName]).append(&"charm_zone")
	if bool(candidate_plan.get("mass_summon", false)) and mass_summon_callback.is_valid():
		mass_summon_callback.call()
		(result.stage_ids as Array[StringName]).append(&"mass_summon")
	if bool(candidate_plan.get("guard_active", false)) and guard_active_callback.is_valid():
		guard_active_callback.call()
		(result.stage_ids as Array[StringName]).append(&"guard_active")
	if bool(candidate_plan.get("death_wave", false)) and death_wave_callback.is_valid():
		death_wave_callback.call(damage)
		(result.stage_ids as Array[StringName]).append(&"death_wave")
	result.applied = not (result.stage_ids as Array[StringName]).is_empty()
	return result

func execute(
		skill_type: StringName,
		enemies: Array[Enemy],
		cursor_position: Vector2,
		damage: float,
		modifiers: Dictionary,
		candidate_skill_range: float,
		guard_charm_extension: float,
		candidate_summon_active: bool,
		irelai_death_wave: bool,
		beam_sentence_stacks: int,
		core_hit_callback: Callable,
		wall_bonus_callback: Callable,
		barrage_hit_callback: Callable,
		barrage_highroll_callback: Callable
	) -> Dictionary:
	match skill_type:
		&"beam":
			return _execute_beam(enemies, cursor_position, damage, modifiers, candidate_skill_range, beam_sentence_stacks, core_hit_callback)
		&"radial":
			return _execute_radial(enemies, damage, guard_charm_extension, core_hit_callback)
		&"wall":
			return _execute_wall(enemies, cursor_position, damage, modifiers, candidate_skill_range, candidate_summon_active, core_hit_callback, wall_bonus_callback)
		&"barrage":
			return _execute_barrage(enemies, damage, irelai_death_wave, barrage_hit_callback, barrage_highroll_callback)
	return _empty_result()

func _execute_beam(
		enemies: Array[Enemy],
		cursor_position: Vector2,
		damage: float,
		modifiers: Dictionary,
		candidate_skill_range: float,
		sentence_stacks: int,
		core_hit_callback: Callable
	) -> Dictionary:
	var half_width := BEAM_BASE_HALF_WIDTH * float(modifiers.get("beam_width", 1.0)) * candidate_skill_range
	var hit_targets := _targets_in_cursor_band(enemies, cursor_position.y, half_width)
	for target in hit_targets:
		core_hit_callback.call(target, damage * BEAM_DAMAGE_MULTIPLIER, &"pierce", false, sentence_stacks, 0.0)
		target.apply_knockback(BEAM_KNOCKBACK)
		target.apply_status(&"stun", BEAM_STUN_DURATION, 1.0)
	return {"hit_targets": hit_targets, "barrage_positions": [] as Array[Vector2]}

func _execute_radial(enemies: Array[Enemy], damage: float, guard_charm_extension: float, core_hit_callback: Callable) -> Dictionary:
	var hit_targets: Array[Enemy] = enemies.duplicate()
	for target in hit_targets:
		core_hit_callback.call(target, damage * RADIAL_DAMAGE_MULTIPLIER, &"core", true, 1, guard_charm_extension)
		target.apply_status(&"pierce_mark", RADIAL_MARK_DURATION, 1.0)
		target.apply_knockback(RADIAL_KNOCKBACK)
	return {"hit_targets": hit_targets, "barrage_positions": [] as Array[Vector2]}

func _execute_wall(
		enemies: Array[Enemy],
		cursor_position: Vector2,
		damage: float,
		modifiers: Dictionary,
		candidate_skill_range: float,
		candidate_summon_active: bool,
		core_hit_callback: Callable,
		wall_bonus_callback: Callable
	) -> Dictionary:
	if candidate_summon_active:
		return _empty_result()
	var half_width := WALL_BASE_HALF_WIDTH * float(modifiers.get("wall_width", 1.0)) * candidate_skill_range
	var hit_targets := _targets_in_cursor_band(enemies, cursor_position.y, half_width)
	for target in hit_targets:
		core_hit_callback.call(target, damage * WALL_DAMAGE_MULTIPLIER, &"core_skill", false, 1, 0.0)
		target.apply_slow(&"core_skill_amethyst", WALL_SLOW_DURATION, WALL_SLOW_POWER)
		target.apply_status(&"stun", WALL_STUN_DURATION, 1.0)
		target.apply_knockback(WALL_KNOCKBACK)
		if modifiers.has("wall_damage"):
			wall_bonus_callback.call(target, damage * float(modifiers.wall_damage))
			target.apply_knockback(float(modifiers.get("wall_push", 0.0)))
	return {"hit_targets": hit_targets, "barrage_positions": [] as Array[Vector2]}

func _execute_barrage(
		enemies: Array[Enemy],
		damage: float,
		irelai_death_wave: bool,
		barrage_hit_callback: Callable,
		barrage_highroll_callback: Callable
	) -> Dictionary:
	if irelai_death_wave:
		return _empty_result()
	var hit_targets: Array[Enemy] = []
	var barrage_positions: Array[Vector2] = []
	var unique_targets := enemies.duplicate()
	for hit_index in BARRAGE_HIT_LIMIT:
		var live_targets: Array[Enemy] = enemies.filter(func(enemy: Enemy) -> bool: return is_instance_valid(enemy) and enemy.active)
		if live_targets.is_empty():
			break
		unique_targets.assign(unique_targets.filter(func(enemy: Enemy) -> bool: return is_instance_valid(enemy) and enemy.active))
		var target := RunRng.pick(unique_targets if not unique_targets.is_empty() else live_targets) as Enemy
		unique_targets.erase(target)
		if target not in hit_targets:
			hit_targets.append(target)
		if barrage_positions.size() < BARRAGE_POSITION_LIMIT:
			barrage_positions.append(target.global_position)
		var damage_multiplier := RunRng.rangef(BARRAGE_MIN_DAMAGE_MULTIPLIER, BARRAGE_MAX_DAMAGE_MULTIPLIER)
		barrage_hit_callback.call(target, damage * damage_multiplier)
		if hit_index % BARRAGE_HIGHROLL_INTERVAL == BARRAGE_HIGHROLL_INTERVAL - 1 and target.active:
			barrage_highroll_callback.call(target, damage * BARRAGE_HIGHROLL_DAMAGE_MULTIPLIER)
	return {"hit_targets": hit_targets, "barrage_positions": barrage_positions}

func _targets_in_cursor_band(enemies: Array[Enemy], cursor_y: float, half_width: float) -> Array[Enemy]:
	return enemies.filter(func(enemy: Enemy) -> bool:
		return is_instance_valid(enemy) and enemy.active and absf(enemy.global_position.y - cursor_y) <= half_width
	)

func _empty_result() -> Dictionary:
	return {"hit_targets": [] as Array[Enemy], "barrage_positions": [] as Array[Vector2]}
