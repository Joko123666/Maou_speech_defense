class_name EnemyLifecycleController
extends RefCounted

signal enemy_reached_core(damage: float, enemy: Enemy)
signal enemy_died(value: float, death_position: Vector2, enemy_data: EnemyData, lane_index: int, enemy: Enemy)
signal charmed_enemy_defeated(death_position: Vector2, enemy_data: EnemyData)
signal enemy_damage_received(amount: float, source_type: StringName, enemy_data: EnemyData)
signal enemy_special_action(action: StringName, enemy: Enemy)
signal enemy_acceleration_changed(enemy: Enemy, acceleration_kind: StringName, stacks: int, speed_bonus: float, duration: float)
signal enemy_control_resolved(enemy: Enemy, control_type: StringName, accepted: bool, requested_effect: float, effective_effect: float, requested_duration: float, effective_duration: float)
signal boss_health_changed(current: float, maximum: float, display_name: String, enemy: Enemy)
signal boss_tree_exiting(enemy: Enemy)

var spatial_index: EnemySpatialIndex
var clear_enemy_callback: Callable
var active_bosses: Array[Enemy] = []
var current_boss: Enemy

func configure(index: EnemySpatialIndex, enemy_clear_callback: Callable = Callable()) -> void:
	spatial_index = index
	clear_enemy_callback = enemy_clear_callback

func spawn_enemy(
	enemy_scene: PackedScene,
	container: Node2D,
	enemy_data: EnemyData,
	spawn_position: Vector2,
	lane_index: int,
	core_goal_position: Vector2,
	health_multiplier: float,
	speed_multiplier: float,
	challenge_level: int,
	campaign_faction: ElectionFactionData,
	execute_threshold_resolver: Callable,
	spawn_context: EnemySpawnContext = null,
	destination_world_y: float = NAN
) -> Enemy:
	if enemy_scene == null or not is_instance_valid(container) or enemy_data == null:
		return null
	var enemy := enemy_scene.instantiate() as Enemy
	if enemy == null:
		return null
	container.add_child(enemy)
	enemy.setup(
		enemy_data,
		spawn_position,
		lane_index,
		core_goal_position,
		health_multiplier * ChallengeRules.enemy_health_multiplier(challenge_level),
		speed_multiplier * ChallengeRules.enemy_speed_multiplier(challenge_level)
	)
	if spawn_context != null:
		enemy.set_spawn_context(spawn_context, destination_world_y)
	enemy.set_challenge_modifiers(
		ChallengeRules.experience_multiplier(challenge_level),
		ChallengeRules.status_resistance_bonus(challenge_level)
	)
	if campaign_faction != null:
		enemy.set_campaign_faction(campaign_faction)
	var execute_threshold := 0.0
	if not enemy_data.is_boss and execute_threshold_resolver.is_valid():
		execute_threshold = maxf(float(execute_threshold_resolver.call(enemy)), 0.0)
	enemy.set_execute_threshold(execute_threshold)
	_register_enemy(enemy)
	return enemy

func register_boss(enemy: Enemy) -> bool:
	if not is_instance_valid(enemy) or enemy.data == null or not enemy.data.is_boss:
		return false
	if enemy not in active_bosses:
		active_bosses.append(enemy)
	current_boss = enemy
	return true

func unregister_boss(enemy: Enemy) -> bool:
	var removed := enemy in active_bosses
	active_bosses.erase(enemy)
	if current_boss == enemy:
		current_boss = null
	refresh_bosses()
	return removed

func unregister_boss_by_data(enemy_data: EnemyData) -> Enemy:
	for boss in active_bosses:
		if is_instance_valid(boss) and boss.data == enemy_data:
			unregister_boss(boss)
			return boss
	refresh_bosses()
	return null

func refresh_bosses() -> Enemy:
	for index in range(active_bosses.size() - 1, -1, -1):
		var boss := active_bosses[index]
		if not is_instance_valid(boss) or not boss.active:
			active_bosses.remove_at(index)
	if not is_instance_valid(current_boss) or current_boss not in active_bosses:
		current_boss = active_bosses.back() if not active_bosses.is_empty() else null
	return current_boss

func active_boss_count() -> int:
	refresh_bosses()
	return active_bosses.size()

func _register_enemy(enemy: Enemy) -> void:
	if spatial_index != null:
		spatial_index.register_enemy(enemy)
	enemy.moved.connect(_on_enemy_moved)
	enemy.tree_exiting.connect(_on_enemy_tree_exiting.bind(enemy), CONNECT_ONE_SHOT)
	enemy.reached_core.connect(_on_enemy_reached_core.bind(enemy))
	enemy.died.connect(_on_enemy_died.bind(enemy))
	enemy.charmed_defeated.connect(_on_charmed_enemy_defeated)
	enemy.damage_received.connect(_on_enemy_damage_received)
	enemy.special_action.connect(_on_enemy_special_action)
	enemy.acceleration_changed.connect(_on_enemy_acceleration_changed)
	enemy.control_resolved.connect(_on_enemy_control_resolved)
	if enemy.data != null and enemy.data.is_boss:
		register_boss(enemy)
		enemy.boss_health_changed.connect(_on_boss_health_changed.bind(enemy))

func _on_enemy_moved(enemy: Enemy) -> void:
	if spatial_index != null:
		spatial_index.update_enemy(enemy)

func _on_enemy_tree_exiting(enemy: Enemy) -> void:
	if spatial_index != null:
		spatial_index.unregister_enemy(enemy)
	if clear_enemy_callback.is_valid():
		clear_enemy_callback.call(enemy)
	if enemy.data != null and enemy.data.is_boss:
		unregister_boss(enemy)
		boss_tree_exiting.emit(enemy)

func _on_enemy_reached_core(damage: float, enemy: Enemy) -> void:
	enemy_reached_core.emit(damage, enemy)

func _on_enemy_died(value: float, death_position: Vector2, enemy_data: EnemyData, lane_index: int, enemy: Enemy) -> void:
	enemy_died.emit(value, death_position, enemy_data, lane_index, enemy)

func _on_charmed_enemy_defeated(death_position: Vector2, enemy_data: EnemyData) -> void:
	charmed_enemy_defeated.emit(death_position, enemy_data)

func _on_enemy_damage_received(amount: float, source_type: StringName, enemy_data: EnemyData) -> void:
	enemy_damage_received.emit(amount, source_type, enemy_data)

func _on_enemy_special_action(action: StringName, enemy: Enemy) -> void:
	enemy_special_action.emit(action, enemy)

func _on_enemy_acceleration_changed(enemy: Enemy, acceleration_kind: StringName, stacks: int, speed_bonus: float, duration: float) -> void:
	enemy_acceleration_changed.emit(enemy, acceleration_kind, stacks, speed_bonus, duration)

func _on_enemy_control_resolved(enemy: Enemy, control_type: StringName, accepted: bool, requested_effect: float, effective_effect: float, requested_duration: float, effective_duration: float) -> void:
	enemy_control_resolved.emit(enemy, control_type, accepted, requested_effect, effective_effect, requested_duration, effective_duration)

func _on_boss_health_changed(current: float, maximum: float, display_name: String, enemy: Enemy) -> void:
	boss_health_changed.emit(current, maximum, display_name, enemy)
