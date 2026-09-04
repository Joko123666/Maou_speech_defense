class_name CoreCounterattackService
extends RefCounted

const SHARD_RADIUS := 180.0
const MAX_SHARD_TARGETS := 3

func execute(
		attacker: Enemy,
		core_damage: float,
		core_damage_multiplier: float,
		modifiers: Dictionary,
		target_query: Callable
	) -> Dictionary:
	if not modifiers.has("counter") or not is_instance_valid(attacker) or not attacker.active:
		return _empty_result()
	var impact_position := attacker.global_position
	var counter_damage := core_damage * core_damage_multiplier * float(modifiers.counter)
	var primary_dealt := attacker.take_damage(counter_damage, &"core_counter", true)
	var shard_damage := counter_damage * float(modifiers.get("counter_shards", 0.0))
	var shard_targets: Array[Enemy] = []
	var shard_dealt := 0.0
	if modifiers.has("counter_shards") and target_query.is_valid():
		var nearby_enemies: Array[Enemy] = []
		nearby_enemies.assign(target_query.call(impact_position, SHARD_RADIUS) as Array)
		for nearby in nearby_enemies:
			if not is_instance_valid(nearby) or not nearby.active or nearby == attacker:
				continue
			shard_dealt += nearby.take_damage(shard_damage, &"core_counter", true)
			shard_targets.append(nearby)
			if shard_targets.size() >= MAX_SHARD_TARGETS:
				break
	return {
		"applied": true,
		"impact_position": impact_position,
		"counter_damage": counter_damage,
		"primary_dealt": primary_dealt,
		"shard_damage": shard_damage,
		"shard_dealt": shard_dealt,
		"shard_targets": shard_targets,
	}

func _empty_result() -> Dictionary:
	return {
		"applied": false,
		"impact_position": Vector2.ZERO,
		"counter_damage": 0.0,
		"primary_dealt": 0.0,
		"shard_damage": 0.0,
		"shard_dealt": 0.0,
		"shard_targets": [],
	}
