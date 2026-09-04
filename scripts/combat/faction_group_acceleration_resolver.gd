class_name FactionGroupAccelerationResolver
extends RefCounted

static func resolve(source_enemy: Enemy, active_enemies: Array[Enemy]) -> int:
	if not is_instance_valid(source_enemy) or source_enemy.data == null or source_enemy.data.group_acceleration_profile == null or source_enemy.spawn_context == null:
		return 0
	var group_id := source_enemy.spawn_context.group_id
	if group_id == &"":
		return 0
	var accelerated := 0
	for enemy in active_enemies:
		if not is_instance_valid(enemy) or enemy == source_enemy or not enemy.active or enemy.data == null or enemy.data.id != source_enemy.data.id or enemy.spawn_context == null or enemy.spawn_context.group_id != group_id:
			continue
		if enemy.apply_same_group_death_acceleration():
			accelerated += 1
	return accelerated
