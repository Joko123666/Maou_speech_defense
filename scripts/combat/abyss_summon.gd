class_name AbyssSummon
extends Node2D

signal attack_requested(summon: AbyssSummon, target: Enemy, damage: float)
signal summon_expired(summon: AbyssSummon)

const ATTACK_RANGE: float = 44.0
const MOVE_SPEED: float = 220.0
const RETARGET_INTERVAL: float = 0.12

var spatial_index: EnemySpatialIndex
var maximum_health: float = 1.0
var current_health: float = 1.0
var attack_interval: float = 0.7
var attack_damage: float = 1.0
var pursuit_radius: float = 140.0
var source_color: Color = Color("7fe8df")
var current_target: Enemy
var attack_cooldown: float = 0.0
var retarget_cooldown: float = 0.0
var life_elapsed: float = 0.0
var configured: bool = false
var expiring: bool = false
var managed_by_pool: bool = false
var summon_budget_token: int = 0
var summon_owner_id: StringName = &""
var summon_source_id: StringName = &""
var generation_depth: int = 0

func setup(
	index: EnemySpatialIndex,
	spawn_position: Vector2,
	duration: float,
	interval: float,
	damage: float,
	search_radius: float,
	color: Color,
	owner_id: StringName = &"",
	source_id: StringName = &"",
	generation: int = 0,
	budget_token: int = 0
) -> void:
	spatial_index = index
	global_position = spawn_position
	maximum_health = maxf(duration, 0.1)
	current_health = maximum_health
	attack_interval = maxf(interval, 0.1)
	attack_damage = maxf(damage, 0.0)
	pursuit_radius = maxf(search_radius, ATTACK_RANGE)
	source_color = color
	summon_owner_id = owner_id
	summon_source_id = source_id
	generation_depth = maxi(generation, 0)
	summon_budget_token = maxi(budget_token, 0)
	z_index = 4
	configured = true
	expiring = false
	visible = true
	set_physics_process(true)
	add_to_group(&"abyss_summons")
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not configured or expiring:
		return
	var step := maxf(delta, 0.0)
	life_elapsed += step
	current_health = maxf(current_health - step, 0.0)
	attack_cooldown = maxf(attack_cooldown - step, 0.0)
	retarget_cooldown = maxf(retarget_cooldown - step, 0.0)
	if current_health <= 0.0:
		force_expire()
		return
	if not _is_valid_target(current_target) or retarget_cooldown <= 0.0:
		current_target = _nearest_target()
		retarget_cooldown = RETARGET_INTERVAL
	if _is_valid_target(current_target):
		var target_position := current_target.global_position
		if global_position.distance_to(target_position) > ATTACK_RANGE:
			global_position = global_position.move_toward(target_position, MOVE_SPEED * CombatPace.MOVEMENT_SPEED_SCALE * step)
		if global_position.distance_to(target_position) <= ATTACK_RANGE and attack_cooldown <= 0.0:
			attack_cooldown = attack_interval
			attack_requested.emit(self, current_target, attack_damage)
	queue_redraw()

func force_expire() -> void:
	if expiring:
		return
	expiring = true
	current_health = 0.0
	set_physics_process(false)
	summon_expired.emit(self)
	if not managed_by_pool:
		queue_free()

func reset_for_reuse() -> void:
	configured = false
	expiring = false
	visible = true
	current_target = null
	attack_cooldown = 0.0
	retarget_cooldown = 0.0
	life_elapsed = 0.0
	set_physics_process(false)

func prepare_for_pool() -> void:
	configured = false
	expiring = false
	visible = false
	current_target = null
	set_physics_process(false)
	remove_from_group(&"abyss_summons")
	_clear_signal_connections(attack_requested)
	_clear_signal_connections(summon_expired)

func _clear_signal_connections(target_signal: Signal) -> void:
	for connection_value in target_signal.get_connections():
		var connection: Dictionary = connection_value
		var callback: Callable = connection.get("callable", Callable())
		if callback.is_valid() and target_signal.is_connected(callback):
			target_signal.disconnect(callback)

func get_health_ratio() -> float:
	return clampf(current_health / maxf(maximum_health, 0.001), 0.0, 1.0)

func _nearest_target() -> Enemy:
	if spatial_index == null:
		return null
	var nearest: Enemy
	var nearest_distance_squared := INF
	for candidate in spatial_index.query_radius(global_position, pursuit_radius):
		if not _is_valid_target(candidate):
			continue
		var distance_squared := global_position.distance_squared_to(candidate.global_position)
		if distance_squared < nearest_distance_squared:
			nearest = candidate
			nearest_distance_squared = distance_squared
	return nearest

func _is_valid_target(target: Variant) -> bool:
	return is_instance_valid(target) and target is Enemy and (target as Enemy).active

func _draw() -> void:
	if not configured:
		return
	var health_ratio := get_health_ratio()
	var pulse := 1.0 + sin(life_elapsed * 8.0) * 0.08
	var body_color := Color(source_color, 0.88)
	var dark_color := source_color.darkened(0.72)
	draw_circle(Vector2(0.0, 7.0), 17.0 * pulse, Color(0.01, 0.02, 0.04, 0.58))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-13.0, -8.0), Vector2(-21.0, -20.0), Vector2(-5.0, -14.0),
	]), dark_color)
	draw_colored_polygon(PackedVector2Array([
		Vector2(13.0, -8.0), Vector2(21.0, -20.0), Vector2(5.0, -14.0),
	]), dark_color)
	draw_circle(Vector2.ZERO, 14.0 * pulse, body_color)
	draw_arc(Vector2.ZERO, 18.0 * pulse, 0.0, TAU, 24, Color(source_color.lightened(0.28), 0.82), 2.0, true)
	draw_circle(Vector2(-4.5, -2.0), 2.0, Color("102b35"))
	draw_circle(Vector2(4.5, -2.0), 2.0, Color("102b35"))
	draw_line(Vector2(-8.0, 17.0), Vector2(8.0, 17.0), Color(0.01, 0.02, 0.04, 0.9), 4.0, true)
	draw_line(Vector2(-8.0, 17.0), Vector2(-8.0 + 16.0 * health_ratio, 17.0), source_color.lightened(0.35), 2.0, true)
