class_name AbyssSummonAttackService
extends RefCounted

const PILLAR_DAMAGE_SOURCE := &"abyss_summon"
const CANDIDATE_DAMAGE_SOURCE := &"core_abyss_summon"

func execute(
		game_active: bool,
		summon: AbyssSummon,
		target: Enemy,
		damage: float,
		column: TowerColumn,
		tower: TowerData,
		attack_record_callback: Callable
	) -> Dictionary:
	var result := _empty_result()
	if not _can_attack(game_active, summon, target) or not is_instance_valid(column) or tower == null or not attack_record_callback.is_valid():
		return result
	var formation_id := _formation_metric_id(column)
	attack_record_callback.call(tower.id, formation_id)
	var target_was_active := target.active
	var dealt := target.take_damage(damage, PILLAR_DAMAGE_SOURCE)
	result.applied = true
	result.source = PILLAR_DAMAGE_SOURCE
	result.tower_id = tower.id
	result.formation_id = formation_id
	result.dealt = dealt
	result.kills = 1 if target_was_active and not target.active else 0
	result.hit_count = 1
	return result

func execute_candidate(game_active: bool, summon: AbyssSummon, target: Enemy, damage: float) -> Dictionary:
	var result := _empty_result()
	if not _can_attack(game_active, summon, target):
		return result
	var target_was_active := target.active
	var dealt := target.take_damage(damage, CANDIDATE_DAMAGE_SOURCE, true)
	result.applied = true
	result.source = CANDIDATE_DAMAGE_SOURCE
	result.is_area = true
	result.dealt = dealt
	result.kills = 1 if target_was_active and not target.active else 0
	result.hit_count = 1
	return result

func _can_attack(game_active: bool, summon: AbyssSummon, target: Enemy) -> bool:
	return game_active and is_instance_valid(summon) and is_instance_valid(target) and target.active

func _empty_result() -> Dictionary:
	return {
		"applied": false,
		"source": &"",
		"is_area": false,
		"tower_id": &"",
		"formation_id": &"",
		"dealt": 0.0,
		"kills": 0,
		"hit_count": 0,
	}

func _formation_metric_id(column: TowerColumn) -> StringName:
	if not column.is_guard_formation or column.formation_data == null:
		return &""
	return column.formation_data.id
