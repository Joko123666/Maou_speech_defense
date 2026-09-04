class_name EnemyKillerDisableResolver
extends RefCounted

static func resolve(source_enemy: Enemy, columns: Array[TowerColumn], duration: float) -> Dictionary:
	var result := {"applied": false, "column": null, "row_index": -1}
	if not is_instance_valid(source_enemy) or source_enemy.last_damage_context == null or duration <= 0.0:
		return result
	var damage_context := source_enemy.last_damage_context
	var column := damage_context.resolve_normal_defender_column(columns)
	if not is_instance_valid(column) or column.is_guard_formation:
		return result
	var tower := column.get_tower_data(damage_context.source_row)
	if tower == null or tower.id != damage_context.source_id or tower.id not in DataRegistry.NORMAL_DEFENDER_IDS:
		return result
	column.disable_row_for(damage_context.source_row, duration)
	result.applied = true
	result.column = column
	result.row_index = damage_context.source_row
	return result
