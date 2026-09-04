class_name EnemyDeathEffectService
extends RefCounted

const AREA_DISABLE_EVENT := &"wraith_death_disable"
const KILLER_DISABLE_EVENT := &"succubus_killer_disable"

func resolve(enemy_data: EnemyData, death_position: Vector2, source_enemy: Enemy, columns: Array[TowerColumn]) -> Dictionary:
	if enemy_data == null or enemy_data.death_effect_profile == null:
		return _empty_result()
	var profile := enemy_data.death_effect_profile
	match profile.effect:
		&"disable_normal_defenders":
			return _resolve_area_disable(profile, death_position, columns)
		&"disable_killer_normal_defender":
			return _resolve_killer_disable(profile, source_enemy, columns)
	return _empty_result()

func _resolve_area_disable(profile: EnemyDeathEffectProfileData, death_position: Vector2, columns: Array[TowerColumn]) -> Dictionary:
	if profile.radius <= 0.0 or profile.duration <= 0.0:
		return _empty_result()
	var targets: Array[String] = []
	for column in columns:
		if not is_instance_valid(column):
			continue
		for row_index in Battlefield.LANE_COUNT:
			var tower := column.get_tower_data(row_index)
			if tower == null or tower.id not in DataRegistry.NORMAL_DEFENDER_IDS:
				continue
			if column.get_attack_origin(row_index).distance_to(death_position) > profile.radius:
				continue
			column.disable_row_for(row_index, profile.duration)
			targets.append(_target_id(column, row_index, tower))
	return _result(AREA_DISABLE_EVENT, profile.duration, targets, Color("9f7ce8"), profile.radius, 0.42)

func _resolve_killer_disable(profile: EnemyDeathEffectProfileData, source_enemy: Enemy, columns: Array[TowerColumn]) -> Dictionary:
	var resolution := EnemyKillerDisableResolver.resolve(source_enemy, columns, profile.duration)
	if not bool(resolution.applied):
		return _empty_result()
	var column := resolution.get("column") as TowerColumn
	var row_index := int(resolution.get("row_index", -1))
	var tower := column.get_tower_data(row_index)
	var targets: Array[String] = [_target_id(column, row_index, tower)]
	return _result(KILLER_DISABLE_EVENT, profile.duration, targets, Color("ef8bc8"), 72.0, 0.48)

func _result(mechanic_id: StringName, duration: float, targets: Array[String], burst_color: Color, burst_radius: float, burst_duration: float) -> Dictionary:
	return {
		"applied": not targets.is_empty(),
		"mechanic_id": mechanic_id,
		"duration": duration,
		"targets": targets,
		"burst_color": burst_color,
		"burst_radius": burst_radius,
		"burst_duration": burst_duration,
	}

func _empty_result() -> Dictionary:
	return {
		"applied": false,
		"mechanic_id": &"",
		"duration": 0.0,
		"targets": [] as Array[String],
		"burst_color": Color.TRANSPARENT,
		"burst_radius": 0.0,
		"burst_duration": 0.0,
	}

func _target_id(column: TowerColumn, row_index: int, tower: TowerData) -> String:
	return "%d:%d:%s" % [column.column_index, row_index, tower.id]
