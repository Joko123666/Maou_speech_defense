class_name ExperienceRewardService
extends Node

const BASE_ORB_COLLECTION_RADIUS_MULTIPLIER := 1.5

signal boss_reward_completed(enemy_data: EnemyData)
signal retainer_experience_collected(value: float)
signal experience_orb_spawned(channel: StringName, raw_value: float)
signal experience_orb_collected(channel: StringName, raw_value: float, awarded_value: float)

@export var experience_orb_scene: PackedScene

var battlefield: Battlefield
var experience: ExperienceManager
var target_cursor: TargetCursor
var loadout: LoadoutManager
var spatial_index: EnemySpatialIndex
var next_orb_sequence := 1

func setup(
	target_battlefield: Battlefield,
	experience_manager: ExperienceManager,
	cursor: TargetCursor,
	loadout_manager: LoadoutManager,
	enemy_index: EnemySpatialIndex
) -> void:
	battlefield = target_battlefield
	experience = experience_manager
	target_cursor = cursor
	loadout = loadout_manager
	spatial_index = enemy_index

func is_configured() -> bool:
	return experience_orb_scene != null and battlefield != null and experience != null and target_cursor != null and loadout != null and spatial_index != null

func spawn_orb(spawn_position: Vector2, value: float, initial_velocity: Vector2 = Vector2.ZERO, launch_duration: float = 0.0, source_channel: StringName = &"base") -> ExperienceOrb:
	if experience_orb_scene == null or get_parent() == null:
		return null
	var orb := experience_orb_scene.instantiate() as ExperienceOrb
	if orb == null:
		return null
	get_parent().add_child(orb)
	orb.setup(spawn_position, value, initial_velocity, launch_duration, battlefield.get_battle_rect().grow(-12.0), source_channel, next_orb_sequence)
	next_orb_sequence += 1
	experience_orb_spawned.emit(source_channel, maxf(value, 0.0))
	return orb

func calculate_boss_orb_count(total_value: float, boss_tier: int) -> int:
	var minimum_spectacle_count := 18 + maxi(boss_tier, 1) * 4
	var value_preserving_count := ceili(maxf(total_value, 1.0) / 14.0)
	return clampi(maxi(minimum_spectacle_count, value_preserving_count), 18, 48)

func emit_boss_reward(spawn_position: Vector2, total_value: float, enemy_data: EnemyData) -> void:
	var orb_count := calculate_boss_orb_count(total_value, enemy_data.boss_tier)
	var emission_duration := 0.75 + enemy_data.boss_tier * 0.14
	var launch_duration := emission_duration + 0.42
	var emitted_orbs: Array[ExperienceOrb] = []
	var remaining_value := maxf(total_value, 0.0)
	for orb_index in orb_count:
		var remaining_count := orb_count - orb_index
		var orb_value := remaining_value / float(remaining_count)
		remaining_value -= orb_value
		var angle := fmod(float(orb_index) * 2.399963 + enemy_data.boss_tier * 0.37, TAU)
		var launch_speed := 145.0 + enemy_data.boss_tier * 18.0 + float(orb_index % 5) * 13.0
		var orb := spawn_orb(spawn_position, orb_value, Vector2.from_angle(angle) * launch_speed, launch_duration, &"boss")
		if orb != null:
			emitted_orbs.append(orb)
		await get_tree().create_timer(emission_duration / float(orb_count), true, false, true).timeout
	await get_tree().create_timer(0.52, true, false, true).timeout
	for orb in emitted_orbs:
		if is_instance_valid(orb):
			award_orb(orb, orb.global_position, 1.0, true)
	boss_reward_completed.emit(enemy_data)

func collect_at(target_position: Vector2, radius: float) -> void:
	for node in get_tree().get_nodes_in_group(&"experience_orbs"):
		var orb := node as ExperienceOrb
		var channel_radius := collection_radius_for_channel(radius, orb.source_channel) if orb != null else radius
		if orb != null and orb.attract_and_collect(target_position, channel_radius, 0.1):
			award_orb(orb, target_position, 1.0, true)

func collection_radius_for_channel(radius: float, channel: StringName) -> float:
	return maxf(radius, 0.0) * (BASE_ORB_COLLECTION_RADIUS_MULTIPLIER if channel == &"base" else 1.0)

func award_orb(orb: ExperienceOrb, collection_position: Vector2, additional_multiplier: float = 1.0, record_retainer_contribution: bool = false) -> void:
	if orb == null or not is_instance_valid(orb):
		return
	var modifiers := loadout.get_cursor_branch_modifiers()
	var cursor_multiplier := target_cursor.data.experience_multiplier if target_cursor.data != null else 1.0
	var awarded_value := orb.value * cursor_multiplier * float(modifiers.get("experience", 1.0)) * additional_multiplier
	experience.add_experience(awarded_value)
	var raw_total := maxf(orb.value, 0.0)
	for channel in orb.source_values:
		var raw_channel_value := maxf(float(orb.source_values[channel]), 0.0)
		var channel_awarded := awarded_value * raw_channel_value / raw_total if raw_total > 0.0 else 0.0
		experience_orb_collected.emit(StringName(channel), raw_channel_value, channel_awarded)
	if record_retainer_contribution:
		retainer_experience_collected.emit(awarded_value)
	if modifiers.has("experience_burst"):
		for enemy in spatial_index.query_radius(collection_position, 105.0):
			enemy.take_damage(orb.value * float(modifiers.experience_burst), &"cursor_experience", true)
	orb.queue_free()

func collect_all(multiplier: float = 1.0) -> void:
	for node in get_tree().get_nodes_in_group(&"experience_orbs"):
		var orb := node as ExperienceOrb
		if orb != null:
			award_orb(orb, orb.global_position, multiplier)
