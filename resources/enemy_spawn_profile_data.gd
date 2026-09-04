class_name EnemySpawnProfileData
extends Resource

@export var enemy_id: StringName = &""
@export_range(0.01, 500.0, 0.01) var spawn_cost: float = 1.0
@export var role_tags: Array[StringName] = []
@export_range(0.0, 3600.0, 1.0) var unlock_time: float = 0.0
@export var is_faction_enemy: bool = false
@export var faction_id: StringName = &""
@export_range(1, 32, 1) var group_min: int = 1
@export_range(1, 32, 1) var group_max: int = 1
@export_range(0.0, 600.0, 0.1) var rare_spawn_cooldown: float = 0.0

func configure(
	profile_enemy_id: StringName,
	profile_spawn_cost: float,
	profile_role_tags: Array[StringName],
	profile_unlock_time: float = 0.0,
	profile_faction_id: StringName = &"",
	profile_group_min: int = 1,
	profile_group_max: int = 1,
	profile_rare_spawn_cooldown: float = 0.0
) -> EnemySpawnProfileData:
	enemy_id = profile_enemy_id
	spawn_cost = profile_spawn_cost
	role_tags.assign(profile_role_tags)
	unlock_time = profile_unlock_time
	faction_id = profile_faction_id
	is_faction_enemy = faction_id != &""
	group_min = profile_group_min
	group_max = profile_group_max
	rare_spawn_cooldown = profile_rare_spawn_cooldown
	return self

func get_validation_errors(faction_catalog_ids: Dictionary = {}) -> PackedStringArray:
	var errors := PackedStringArray()
	if enemy_id == &"":
		errors.append("enemy spawn profile id is empty")
	if spawn_cost <= 0.0:
		errors.append("enemy spawn profile '%s' has a non-positive cost" % enemy_id)
	if role_tags.is_empty() or role_tags.any(func(role: StringName) -> bool: return role == &""):
		errors.append("enemy spawn profile '%s' must have non-empty role tags" % enemy_id)
	if unlock_time < 0.0:
		errors.append("enemy spawn profile '%s' has a negative unlock time" % enemy_id)
	if is_faction_enemy != (faction_id != &""):
		errors.append("enemy spawn profile '%s' has inconsistent faction flags" % enemy_id)
	if is_faction_enemy and not faction_catalog_ids.is_empty() and not faction_catalog_ids.has(faction_id):
		errors.append("enemy spawn profile '%s' references missing faction '%s'" % [enemy_id, faction_id])
	if group_min < 1 or group_max < group_min:
		errors.append("enemy spawn profile '%s' has an invalid group range" % enemy_id)
	if rare_spawn_cooldown < 0.0:
		errors.append("enemy spawn profile '%s' has a negative rare cooldown" % enemy_id)
	return errors

static func from_enemy_data(enemy: EnemyData) -> EnemySpawnProfileData:
	if enemy == null:
		return null
	var profile := EnemySpawnProfileData.new()
	profile.configure(
		enemy.id,
		enemy.spawn_cost,
		enemy.role_tags,
		enemy.available_from_seconds,
		&"",
		3 if enemy.behavior == &"swarm" else 1,
		3 if enemy.behavior == &"swarm" else 1
	)
	return profile
