class_name TowerColumn
extends Node2D

const DAMAGE_LEVEL_CURVE: Array[float] = [0.0, 1.0, 1.45, 1.45, 1.45, 2.05, 2.05, 2.05]
const SPEED_LEVEL_CURVE: Array[float] = [0.0, 1.0, 1.0, 1.35, 1.35, 1.35, 1.75, 1.75]
const RANGE_LEVEL_CURVE: Array[float] = [0.0, 1.0, 1.0, 1.12, 1.12, 1.12, 1.30, 1.30]
const MAX_ATTACKS_PER_FRAME := 8

signal attack_requested(column: TowerColumn, row_index: int)
signal state_changed

var column_index: int
var formation_data: TowerFormationData
var vertical_flipped: bool = false
var row_towers: Array[TowerData] = []
var tower_levels: Dictionary = {}
var tower_branch_ids: Dictionary = {}
var disabled_remaining: float = 0.0
var attack_accumulators: Array[float] = []
var attack_counts: Array[int] = []
var attack_flashes: Array[float] = []
var attack_pose_remaining: Array[float] = []
var row_disabled_remaining: Array[float] = []
var row_runtime_speed_multipliers: Array[float] = []
var mobile_tower_offsets: Array[Vector2] = []
var global_speed_multiplier: float = 1.0
var guard_range_multiplier: float = 1.0
var general_range_multiplier: float = 1.0
var defense_stat_resolver: DefenseStatResolver
var defense_axis_bonuses: Dictionary = {&"power": 0.0, &"speed": 0.0, &"range": 0.0}
var battlefield: Battlefield
var placement_id: StringName = &""
var is_guard_formation: bool = false
## 현재 블록 보드의 셀 슬라이스인지 구분합니다.
var uses_block_cells: bool = false

func setup(index: int, world_x: float, target_battlefield: Battlefield) -> void:
	column_index = index
	battlefield = target_battlefield
	position = Vector2(world_x, 0.0)
	attack_accumulators.resize(battlefield.lane_count)
	attack_accumulators.fill(0.0)
	attack_counts.resize(battlefield.lane_count)
	attack_counts.fill(0)
	attack_flashes.resize(battlefield.lane_count)
	attack_flashes.fill(0.0)
	attack_pose_remaining.resize(battlefield.lane_count)
	attack_pose_remaining.fill(0.0)
	row_disabled_remaining.resize(battlefield.lane_count)
	row_disabled_remaining.fill(0.0)
	row_runtime_speed_multipliers.resize(battlefield.lane_count)
	row_runtime_speed_multipliers.fill(1.0)
	mobile_tower_offsets.resize(battlefield.lane_count)
	mobile_tower_offsets.fill(Vector2.ZERO)
	queue_redraw()

func is_occupied() -> bool:
	return formation_data != null

func equip_formation_cells(data: TowerFormationData, board_entries: Array[Dictionary], owner_placement_id: StringName, guard: bool = false) -> bool:
	if is_occupied() or data == null or board_entries.is_empty():
		return false
	formation_data = data
	uses_block_cells = true
	placement_id = owner_placement_id
	is_guard_formation = guard
	vertical_flipped = false
	row_towers.clear()
	row_towers.resize(battlefield.lane_count)
	row_towers.fill(null)
	for entry in board_entries:
		var board_cell := entry.get("cell", Vector2i(-1, -1)) as Vector2i
		var tower_id := entry.get("tower_id", &"") as StringName
		if board_cell.x != column_index or board_cell.y < 0 or board_cell.y >= battlefield.lane_count or tower_id == &"" or row_towers[board_cell.y] != null:
			formation_data = null
			uses_block_cells = false
			placement_id = &""
			is_guard_formation = false
			row_towers.clear()
			return false
		row_towers[board_cell.y] = DataRegistry.get_tower(tower_id)
	attack_accumulators.fill(0.0)
	attack_counts.fill(0)
	attack_flashes.fill(0.0)
	attack_pose_remaining.fill(0.0)
	row_disabled_remaining.fill(0.0)
	row_runtime_speed_multipliers.fill(1.0)
	mobile_tower_offsets.fill(Vector2.ZERO)
	state_changed.emit()
	queue_redraw()
	return true

func get_occupied_board_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for row_index in row_towers.size():
		if row_towers[row_index] != null:
			result.append(Vector2i(column_index, row_index))
	return result

func set_shared_progress(levels: Dictionary, branch_ids: Dictionary) -> void:
	tower_levels = levels
	tower_branch_ids = branch_ids
	state_changed.emit()
	queue_redraw()

func set_defense_stat_context(resolver: DefenseStatResolver, axis_bonuses: Dictionary) -> void:
	defense_stat_resolver = resolver
	defense_axis_bonuses = axis_bonuses.duplicate()
	queue_redraw()

func resolve_defense_stat(row_index: int, axis_id: StringName, modifier_key: StringName, base_value: float) -> float:
	var tower := get_tower_data(row_index)
	if tower == null or defense_stat_resolver == null:
		return base_value
	return defense_stat_resolver.resolve_value(
		tower.id,
		axis_id,
		modifier_key,
		base_value,
		float(defense_axis_bonuses.get(axis_id, 0.0)),
		&"normal_defender",
		is_guard_formation
	)

func contains_tower_type(tower_id: StringName) -> bool:
	return row_towers.any(func(tower: TowerData) -> bool: return tower != null and tower.id == tower_id)

func get_tower_data(row_index: int) -> TowerData:
	if row_index < 0 or row_index >= row_towers.size():
		return null
	return row_towers[row_index]

func get_tower_level(tower_id: StringName) -> int:
	return int(tower_levels.get(tower_id, 1))

func get_tower_branch_id(tower_id: StringName) -> StringName:
	return tower_branch_ids.get(tower_id, &"") as StringName

func get_tower_branch(tower_id: StringName) -> TowerBranchData:
	return DataRegistry.get_tower_branch(get_tower_branch_id(tower_id))

func is_tower_evolved(tower_id: StringName) -> bool:
	return get_tower_branch_id(tower_id) != &""

func is_tower_final(tower_id: StringName) -> bool:
	return get_tower_level(tower_id) >= 7 and is_tower_evolved(tower_id)

func get_branch_modifiers(tower_id: StringName) -> Dictionary:
	var branch := get_tower_branch(tower_id)
	if branch == null:
		return {}
	var result := branch.level_4_modifiers.duplicate(true)
	if is_tower_final(tower_id):
		result.merge(branch.level_7_modifiers, true)
	return result

func get_attack_origin(row_index: int) -> Vector2:
	return get_base_attack_origin(row_index) + (mobile_tower_offsets[row_index] if row_index >= 0 and row_index < mobile_tower_offsets.size() else Vector2.ZERO)

func get_mobile_tower_offset(row_index: int) -> Vector2:
	return mobile_tower_offsets[row_index] if row_index >= 0 and row_index < mobile_tower_offsets.size() else Vector2.ZERO

func set_mobile_tower_offset(row_index: int, offset: Vector2) -> void:
	if row_index < 0 or row_index >= mobile_tower_offsets.size():
		return
	mobile_tower_offsets[row_index] = offset
	queue_redraw()

func get_base_attack_origin(row_index: int) -> Vector2:
	return Vector2(global_position.x, battlefield.get_lane_y(row_index))

func get_golem_activity_radius(row_index: int) -> float:
	var tower := get_tower_data(row_index)
	if tower == null or tower.behavior != &"golem":
		return 0.0
	return get_attack_range(row_index) * 0.52 * float(get_branch_modifiers(tower.id).get("activity_range", 1.0))

func get_golem_control_radius(row_index: int) -> float:
	var tower := get_tower_data(row_index)
	if tower == null or tower.behavior != &"golem":
		return 0.0
	return maxf(tower.area_radius, 24.0) * float(get_branch_modifiers(tower.id).get("control_radius", 1.0))

func advance_golem_toward(row_index: int, target_position: Vector2) -> Vector2:
	var tower := get_tower_data(row_index)
	if tower == null or tower.behavior != &"golem" or row_index < 0 or row_index >= mobile_tower_offsets.size():
		return get_attack_origin(row_index)
	var base_origin := get_base_attack_origin(row_index)
	var current_origin := base_origin + mobile_tower_offsets[row_index]
	var movement_multiplier := float(get_branch_modifiers(tower.id).get("movement", 1.0))
	var candidate := current_origin.move_toward(target_position, 46.0 * movement_multiplier)
	var candidate_offset := candidate - base_origin
	var activity_radius := get_golem_activity_radius(row_index)
	if candidate_offset.length() > activity_radius:
		candidate_offset = candidate_offset.normalized() * activity_radius
	mobile_tower_offsets[row_index] = candidate_offset
	queue_redraw()
	return base_origin + candidate_offset

func apply_golem_recoil(row_index: int, threat_position: Vector2, distance: float) -> float:
	var tower := get_tower_data(row_index)
	if tower == null or tower.behavior != &"golem" or distance <= 0.0 or row_index < 0 or row_index >= mobile_tower_offsets.size():
		return 0.0
	var base_origin := get_base_attack_origin(row_index)
	var current_origin := base_origin + mobile_tower_offsets[row_index]
	var direction := threat_position.direction_to(current_origin)
	if direction.is_zero_approx():
		direction = Vector2.LEFT
	var previous_offset := mobile_tower_offsets[row_index]
	var next_offset := previous_offset + direction * distance
	var activity_radius := get_golem_activity_radius(row_index)
	if next_offset.length() > activity_radius:
		next_offset = next_offset.normalized() * activity_radius
	mobile_tower_offsets[row_index] = next_offset
	queue_redraw()
	return next_offset.distance_to(previous_offset)

func disable_for(duration: float) -> void:
	disabled_remaining = maxf(disabled_remaining, duration)
	state_changed.emit()
	queue_redraw()

func disable_row_for(row_index: int, duration: float) -> void:
	if row_index < 0 or row_index >= row_disabled_remaining.size():
		return
	row_disabled_remaining[row_index] = maxf(row_disabled_remaining[row_index], duration)
	state_changed.emit()
	queue_redraw()

func is_row_disabled(row_index: int) -> bool:
	return disabled_remaining > 0.0 or (row_index >= 0 and row_index < row_disabled_remaining.size() and row_disabled_remaining[row_index] > 0.0)

func clear_disable() -> void:
	disabled_remaining = 0.0
	row_disabled_remaining.fill(0.0)
	state_changed.emit()
	queue_redraw()

func set_row_runtime_speed_multiplier(row_index: int, multiplier: float) -> void:
	if row_index < 0 or row_index >= row_runtime_speed_multipliers.size():
		return
	row_runtime_speed_multipliers[row_index] = maxf(multiplier, 0.01)
	queue_redraw()

func get_row_runtime_speed_multiplier(row_index: int) -> float:
	if row_index < 0 or row_index >= row_runtime_speed_multipliers.size():
		return 1.0
	return maxf(row_runtime_speed_multipliers[row_index], 0.01)

func get_damage(row_index: int) -> float:
	var tower := get_tower_data(row_index)
	if tower == null:
		return 0.0
	var level := get_tower_level(tower.id)
	var level_multiplier := DAMAGE_LEVEL_CURVE[clampi(level, 1, DAMAGE_LEVEL_CURVE.size() - 1)]
	var branch_multiplier := float(get_branch_modifiers(tower.id).get("damage", 1.0))
	var position_ratio := float(column_index) / maxf(battlefield.column_count - 1, 1)
	var position_multiplier := 1.0
	if tower.behavior in [&"mark", &"area", &"unique_random"]:
		position_multiplier += position_ratio * 0.18
	elif tower.behavior in [&"knockback", &"execute", &"rapid", &"unique_single", &"unique_radial"]:
		position_multiplier += (1.0 - position_ratio) * 0.18
	var base_damage := tower.damage * level_multiplier * branch_multiplier * position_multiplier * get_formation_output_multiplier()
	return resolve_defense_stat(row_index, &"power", &"damage", base_damage)

func get_attack_interval(row_index: int) -> float:
	var tower := get_tower_data(row_index)
	if tower == null:
		return 999.0
	var level := get_tower_level(tower.id)
	var speed_sources: Array = [
		SPEED_LEVEL_CURVE[clampi(level, 1, SPEED_LEVEL_CURVE.size() - 1)],
		float(get_branch_modifiers(tower.id).get("speed", 1.0)),
		global_speed_multiplier,
		get_row_runtime_speed_multiplier(row_index),
	]
	if tower.behavior == &"knockback":
		speed_sources.append(1.35)
	var base_interval := tower.attack_interval / CombatModifierResolver.resolve_attack_speed(speed_sources)
	if defense_stat_resolver == null:
		return base_interval
	return defense_stat_resolver.resolve_interval(
		tower.id,
		base_interval,
		float(defense_axis_bonuses.get(&"speed", 0.0)),
		&"normal_defender",
		is_guard_formation
	)

func get_saw_blade_count(row_index: int) -> int:
	var tower := get_tower_data(row_index)
	if tower == null or tower.behavior != &"knockback":
		return 0
	var blade_count := 2
	var level := get_tower_level(tower.id)
	if level >= 3:
		blade_count += 1
	if level >= 6:
		blade_count += 1
	var modifiers := get_branch_modifiers(tower.id)
	if modifiers.has("saw_fixed"):
		return maxi(1, int(modifiers.saw_fixed))
	return blade_count * maxi(1, int(modifiers.get("saw_multiplier", 1)))

func get_saw_rotation_speed(row_index: int) -> float:
	var tower := get_tower_data(row_index)
	if tower == null or tower.behavior != &"knockback":
		return 0.0
	return TAU / maxf(get_attack_interval(row_index) * 3.0, 0.72)

func get_saw_orbit_radius(row_index: int) -> float:
	var tower := get_tower_data(row_index)
	if tower == null or tower.behavior != &"knockback":
		return 0.0
	return maxf(get_attack_range(row_index) - 17.0, 42.0)

func get_saw_contact_damage(row_index: int) -> float:
	var blade_count := get_saw_blade_count(row_index)
	if blade_count <= 0:
		return 0.0
	return get_damage(row_index) * (0.42 + blade_count * 0.08)

func get_saw_blade_radius(row_index: int) -> float:
	var tower := get_tower_data(row_index)
	if tower == null or tower.behavior != &"knockback":
		return 0.0
	return (10.0 + get_tower_level(tower.id) * 0.45) * float(get_branch_modifiers(tower.id).get("saw_size", 1.0))

func get_range_multiplier(row_index: int) -> float:
	var tower := get_tower_data(row_index)
	if tower == null:
		return 1.0
	var level := get_tower_level(tower.id)
	var value := RANGE_LEVEL_CURVE[clampi(level, 1, RANGE_LEVEL_CURVE.size() - 1)]
	value *= float(get_branch_modifiers(tower.id).get("range", 1.0))
	if is_guard_formation:
		value *= guard_range_multiplier
	else:
		value *= general_range_multiplier
	return value

func get_attack_range(row_index: int) -> float:
	var tower := get_tower_data(row_index)
	if tower == null or battlefield == null:
		return 0.0
	# 전도탑의 공통 RANGE는 첫 표적 탐색 사거리가 아니라 중계점 연결 거리에 적용합니다.
	if tower.behavior == &"chain":
		return battlefield.get_column_spacing() * tower.attack_range_cells
	var base_range := battlefield.get_column_spacing() * tower.attack_range_cells * get_range_multiplier(row_index)
	if defense_stat_resolver == null:
		return base_range
	return defense_stat_resolver.resolve_primary(
		tower.id,
		&"range",
		base_range,
		float(defense_axis_bonuses.get(&"range", 0.0)),
		&"normal_defender",
		is_guard_formation
	)

func get_chain_link_range(row_index: int) -> float:
	var tower := get_tower_data(row_index)
	if tower == null or tower.behavior != &"chain" or battlefield == null or tower.link_range_cells <= 0.0:
		return 0.0
	var cell_spacing := maxf(battlefield.get_column_spacing(), battlefield.get_lane_spacing())
	var base_range := cell_spacing * tower.link_range_cells * get_range_multiplier(row_index)
	if defense_stat_resolver == null:
		return base_range
	return maxf(defense_stat_resolver.resolve_value(
		tower.id,
		&"range",
		&"link_range",
		base_range,
		float(defense_axis_bonuses.get(&"range", 0.0)),
		&"normal_defender",
		is_guard_formation
	), 0.0)

func get_damage_per_second(row_index: int) -> float:
	var tower := get_tower_data(row_index)
	if tower == null:
		return 0.0
	var cycle_damage_multiplier := 1.0
	var modifiers := get_branch_modifiers(tower.id)
	if tower.behavior == &"rapid" and modifiers.has("volley_shots"):
		cycle_damage_multiplier = float(modifiers.volley_shots) * float(modifiers.get("volley_damage", 1.0))
	return get_damage(row_index) * cycle_damage_multiplier / maxf(get_attack_interval(row_index), 0.01)

func get_chain_network_damage_multiplier(row_index: int, relay_count: int) -> float:
	var tower := get_tower_data(row_index)
	if tower == null or tower.behavior != &"chain" or relay_count < 2:
		return 0.0
	var extra_relays := clampi(relay_count - 2, 0, 4)
	var per_relay := float(get_branch_modifiers(tower.id).get("network_damage_per_relay", 0.08))
	return 1.0 + extra_relays * per_relay

func get_formation_output_multiplier() -> float:
	# 기초 편성점수는 레시피 구성 지표이며 실제 피해를 강제 정규화하지 않습니다.
	return 1.0

func _physics_process(delta: float) -> void:
	var redraw_feedback := false
	var has_persistent_saw := false
	var mobile_tower_moved := false
	for row_index in attack_flashes.size():
		if attack_flashes[row_index] > 0.0:
			attack_flashes[row_index] = maxf(attack_flashes[row_index] - delta * 7.5, 0.0)
			redraw_feedback = true
		if row_index < attack_pose_remaining.size() and attack_pose_remaining[row_index] > 0.0:
			attack_pose_remaining[row_index] = maxf(attack_pose_remaining[row_index] - delta, 0.0)
			redraw_feedback = true
		var row_tower := get_tower_data(row_index)
		if row_tower != null and row_tower.behavior == &"knockback":
			has_persistent_saw = true
		if row_tower != null and row_tower.behavior == &"golem" and not mobile_tower_offsets[row_index].is_zero_approx():
			var return_speed := CombatPace.movement_speed(16.0) * float(get_branch_modifiers(row_tower.id).get("movement", 1.0))
			mobile_tower_offsets[row_index] = mobile_tower_offsets[row_index].move_toward(Vector2.ZERO, return_speed * delta)
			mobile_tower_moved = true
	if redraw_feedback or has_persistent_saw or mobile_tower_moved:
		queue_redraw()
	if disabled_remaining > 0.0:
		disabled_remaining = maxf(disabled_remaining - delta, 0.0)
		if is_zero_approx(disabled_remaining):
			state_changed.emit()
			queue_redraw()
		return
	if not is_occupied():
		return
	for row_index in row_towers.size():
		if row_index < row_disabled_remaining.size() and row_disabled_remaining[row_index] > 0.0:
			row_disabled_remaining[row_index] = maxf(row_disabled_remaining[row_index] - delta, 0.0)
			redraw_feedback = true
			if row_disabled_remaining[row_index] > 0.0:
				continue
		attack_accumulators[row_index] += delta
		var attack_interval := get_attack_interval(row_index)
		var attacks_this_frame := 0
		while attack_accumulators[row_index] >= attack_interval and attacks_this_frame < MAX_ATTACKS_PER_FRAME:
			attack_accumulators[row_index] -= attack_interval
			attack_requested.emit(self, row_index)
			attacks_this_frame += 1
			attack_interval = get_attack_interval(row_index)
		if attacks_this_frame >= MAX_ATTACKS_PER_FRAME:
			attack_accumulators[row_index] = minf(attack_accumulators[row_index], attack_interval)

func confirm_attack(row_index: int) -> void:
	if row_index < 0 or row_index >= attack_flashes.size():
		return
	attack_counts[row_index] += 1
	var tower := get_tower_data(row_index)
	attack_flashes[row_index] = 0.42 if tower != null and tower.behavior == &"knockback" else 1.0
	attack_pose_remaining[row_index] = 0.18
	queue_redraw()

func get_tower_art_texture(row_index: int) -> Texture2D:
	var tower := get_tower_data(row_index)
	if tower == null:
		return ConceptService.fallback_texture(&"towers")
	var attack_pose_active := row_index >= 0 and row_index < attack_pose_remaining.size() and attack_pose_remaining[row_index] > 0.0
	if attack_pose_active and tower.attack_texture != null:
		return tower.attack_texture
	return tower.texture if tower.texture != null else ConceptService.fallback_texture(&"towers")

func _draw() -> void:
	var rect := battlefield.get_battle_rect() if battlefield != null else Rect2(Vector2.ZERO, Vector2(1.0, 720.0))
	draw_line(Vector2(0.0, rect.position.y), Vector2(0.0, rect.end.y), Color(0.34, 0.53, 0.64, 0.14), 2.0)
	for row_index in battlefield.lane_count:
		var local_position := Vector2(0.0, battlefield.get_lane_y(row_index))
		var tower := get_tower_data(row_index)
		if tower == null:
			draw_circle(local_position, 12.0, Color("345064", 0.5))
			continue
		if row_index < mobile_tower_offsets.size() and not mobile_tower_offsets[row_index].is_zero_approx():
			local_position += mobile_tower_offsets[row_index]
		if tower.behavior == &"golem" and row_index < mobile_tower_offsets.size():
			var activity_radius := get_golem_activity_radius(row_index)
			draw_arc(Vector2(0.0, battlefield.get_lane_y(row_index)), activity_radius, 0.0, TAU, 40, Color(tower.color, 0.12), 1.2, true)
		var row_disabled := is_row_disabled(row_index)
		var base_color := Color("5c4350") if row_disabled else tower.color
		if tower.behavior == &"knockback":
			_draw_persistent_saws(local_position, row_index, base_color)
		var attack_flash := attack_flashes[row_index] if row_index < attack_flashes.size() else 0.0
		var tint := Color.WHITE.lerp(base_color, 0.04).lerp(Color.WHITE, attack_flash * 0.65)
		var tower_size := Vector2.ONE * 60.0
		draw_circle(local_position, 23.0 + attack_flash * 7.0, Color(base_color, 0.2 + attack_flash * 0.2))
		if tower.is_unique():
			draw_arc(local_position, 31.0 + sin(Time.get_ticks_msec() * 0.004) * 2.0, 0.0, TAU, 36, Color(base_color.lightened(0.35), 0.82), 2.4, true)
			var diamond := PackedVector2Array([local_position + Vector2(0.0, -36.0), local_position + Vector2(6.0, -30.0), local_position + Vector2(0.0, -24.0), local_position + Vector2(-6.0, -30.0)])
			draw_colored_polygon(diamond, Color("ffe16b", 0.92))
		var art_texture := get_tower_art_texture(row_index)
		if art_texture != null:
			var motion_phase := Time.get_ticks_msec() * 0.0028 + column_index * 0.63 + row_index * 0.81
			var pose := CombatMotionProfile.tower_pose(tower.behavior, attack_flash, motion_phase)
			draw_set_transform(local_position + pose.offset, float(pose.rotation), pose.scale)
			draw_texture_rect(art_texture, Rect2(-tower_size * 0.5, tower_size), false, tint)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if attack_flash > 0.0:
			_draw_attack_feedback(local_position, tower.behavior, base_color, attack_flash)
		var level := get_tower_level(tower.id)
		draw_circle(local_position + Vector2(-20.0, 19.0), 9.0, base_color)
		draw_string(ThemeDB.fallback_font, local_position + Vector2(-26.0, 23.0), "U" if tower.is_unique() else str(level), HORIZONTAL_ALIGNMENT_CENTER, 13.0, 12, Color("081116"))
		if is_tower_evolved(tower.id):
			draw_arc(local_position, 25.0, 0.0, TAU, 24, Color("ffe16b") if is_tower_final(tower.id) else Color("d781ff"), 2.0)
		if not row_disabled:
			var cooldown_ratio := clampf(attack_accumulators[row_index] / maxf(get_attack_interval(row_index), 0.01), 0.0, 1.0)
			draw_arc(local_position, 27.0, -PI * 0.5, -PI * 0.5 + TAU * cooldown_ratio, 24, Color(base_color, 0.42), 1.4)
		if row_disabled:
			draw_line(local_position + Vector2(-14.0, -14.0), local_position + Vector2(14.0, 14.0), Color("ff6577"), 3.0)
func _draw_persistent_saws(origin: Vector2, row_index: int, color: Color) -> void:
	var blade_count := get_saw_blade_count(row_index)
	if blade_count <= 0:
		return
	var orbit_radius := get_saw_orbit_radius(row_index)
	var phase := Time.get_ticks_msec() * 0.001 * get_saw_rotation_speed(row_index)
	var disabled_alpha := 0.28 if is_row_disabled(row_index) else 1.0
	draw_arc(origin, orbit_radius, 0.0, TAU, 72, Color(color, 0.1 * disabled_alpha), 1.2, true)
	for blade_index in blade_count:
		var angle := phase + TAU * float(blade_index) / float(blade_count)
		var blade_position := origin + Vector2.from_angle(angle) * orbit_radius
		var blade_radius := get_saw_blade_radius(row_index)
		draw_line(origin + Vector2.from_angle(angle) * 30.0, blade_position, Color(color, 0.08 * disabled_alpha), 1.0, true)
		draw_circle(blade_position, blade_radius + 3.0, Color(0.02, 0.04, 0.05, 0.58 * disabled_alpha))
		var teeth := PackedVector2Array()
		for tooth_index in 16:
			var tooth_angle := angle * 2.4 + TAU * float(tooth_index) / 16.0
			var tooth_radius := blade_radius + (3.6 if tooth_index % 2 == 0 else 0.0)
			teeth.append(blade_position + Vector2.from_angle(tooth_angle) * tooth_radius)
		draw_colored_polygon(teeth, Color(color, 0.88 * disabled_alpha))
		draw_circle(blade_position, blade_radius * 0.38, Color("17242b", 0.95 * disabled_alpha))
		draw_arc(blade_position, blade_radius * 0.72, angle, angle + PI * 1.15, 12, Color(1.0, 1.0, 0.86, 0.82 * disabled_alpha), 1.4, true)

func _draw_attack_feedback(origin: Vector2, behavior: StringName, color: Color, flash: float) -> void:
	var bright := color.lightened(0.48)
	var muzzle := origin + Vector2(29.0, 0.0)
	match behavior:
		&"rapid", &"unique_single":
			draw_line(muzzle, muzzle + Vector2(20.0 + flash * 14.0, 0.0), Color(bright, flash), 2.0 + flash)
			draw_circle(muzzle, 3.0 + flash * 3.0, Color(color, flash * 0.55))
		&"area":
			draw_arc(muzzle, 8.0 + flash * 11.0, -0.8, 0.8, 16, Color(bright, flash), 3.0)
			draw_circle(muzzle, 5.0 + flash * 4.0, Color(color, flash * 0.42))
		&"pierce", &"unique_pierce":
			draw_line(muzzle, muzzle + Vector2(42.0 + flash * 22.0, 0.0), Color(bright, flash), 4.0)
			draw_line(muzzle + Vector2(0.0, -7.0), muzzle + Vector2(25.0, -2.0), Color(color, flash * 0.7), 1.5)
			draw_line(muzzle + Vector2(0.0, 7.0), muzzle + Vector2(25.0, 2.0), Color(color, flash * 0.7), 1.5)
		&"slow":
			for index in 6:
				var direction := Vector2.from_angle(TAU * index / 6.0)
				draw_line(muzzle + direction * 3.0, muzzle + direction * (9.0 + flash * 8.0), Color(bright, flash), 1.7)
		&"knockback":
			for radius in [12.0, 20.0, 28.0]:
				draw_arc(muzzle, radius * flash, -0.85, 0.85, 18, Color(color, flash * 0.78), 2.2)
		&"execute":
			for angle in [-0.72, 0.72]:
				var direction := Vector2.from_angle(angle)
				draw_line(origin - direction * 22.0 * flash, origin + direction * 22.0 * flash, Color(bright, flash), 2.8)
		&"mark":
			var phase := Time.get_ticks_msec() * 0.012
			for index in 3:
				var node := origin + Vector2.from_angle(phase + TAU * index / 3.0) * (25.0 + flash * 5.0)
				draw_circle(node, 3.0 + flash * 2.0, Color(bright, flash))
		&"chain":
			var points := PackedVector2Array([muzzle, muzzle + Vector2(10.0, -8.0), muzzle + Vector2(20.0, 7.0), muzzle + Vector2(32.0, -4.0)])
			draw_polyline(points, Color(bright, flash), 2.5)
		&"unique_radial":
			for ring in [10.0, 19.0, 28.0]:
				draw_arc(origin, ring + flash * 9.0, 0.0, TAU, 28, Color(bright, flash * 0.72), 2.0)
		&"unique_random":
			for index in 4:
				var direction := Vector2.from_angle(Time.get_ticks_msec() * 0.01 + TAU * index / 4.0)
				draw_circle(origin + direction * (18.0 + flash * 9.0), 3.0 + flash * 2.0, Color(bright, flash))
		_:
			draw_circle(muzzle, 4.0 + flash * 5.0, Color(bright, flash))
