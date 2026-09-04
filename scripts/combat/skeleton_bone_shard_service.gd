class_name SkeletonBoneShardService
extends RefCounted

const DEFAULT_SHARD_COUNT := 5
const MAX_SHARD_COUNT := 8
const DEFAULT_SHARD_RANGE := 150.0
const DEFAULT_DAMAGE_RATIO := 0.3
const ANGLE_JITTER := 0.18
const PROJECTILE_SPEED := 520.0
const PROJECTILE_LENGTH := 22.0

func build_spawn_plan(
		column: TowerColumn,
		row_index: int,
		tower: TowerData,
		origin: Vector2,
		attack_damage: float,
		modifiers: Dictionary,
		spatial_index: EnemySpatialIndex,
		random_range_callback: Callable
	) -> Dictionary:
	var result := {"applied": false, "count": 0, "shards": []}
	if not is_instance_valid(column) or tower == null or spatial_index == null or not random_range_callback.is_valid():
		return result
	var shard_count := clampi(int(modifiers.get("bone_shard_count", DEFAULT_SHARD_COUNT)), 1, MAX_SHARD_COUNT)
	var shard_range := float(modifiers.get("bone_shard_range", DEFAULT_SHARD_RANGE))
	var shard_damage := attack_damage * float(modifiers.get("bone_shard_damage", DEFAULT_DAMAGE_RATIO))
	var starting_angle := float(random_range_callback.call(0.0, TAU))
	var shards: Array[Dictionary] = []
	for shard_index in shard_count:
		var jitter := float(random_range_callback.call(-ANGLE_JITTER, ANGLE_JITTER))
		var angle := starting_angle + TAU * float(shard_index) / float(shard_count) + jitter
		shards.append({
			"origin": origin,
			"target": origin + Vector2.from_angle(angle) * shard_range,
			"speed": PROJECTILE_SPEED,
			"color": tower.color.lightened(0.22),
			"length": PROJECTILE_LENGTH,
			"max_distance": shard_range,
			"payload": {
				"column": column,
				"tower": tower,
				"row_index": row_index,
				"behavior": &"area_shard",
				"damage": shard_damage,
				"max_hits": 1,
				"collision_mode": &"path",
				"spatial_index": spatial_index,
				"origin": origin,
			},
		})
	result.applied = true
	result.count = shard_count
	result.shards = shards
	return result
