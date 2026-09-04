class_name IrelaiGuardController
extends RefCounted

const FORMATION_ID: StringName = &"jade_gambit"

var first_curse_ready: Dictionary = {}
var cursed_enemies: Dictionary = {}

func resolve_deactivation(column: TowerColumn, row_index: int, tower: TowerData, loadout: LoadoutManager, spatial_index: EnemySpatialIndex, tower_damage_multiplier: float, column_damage_multiplier: float) -> Dictionary:
	var origin := column.get_attack_origin(row_index) if is_instance_valid(column) else Vector2.ZERO
	var result := {"damage": 0.0, "hit_count": 0, "position": origin, "radius": 0.0, "tracked_enemies": [] as Array[Enemy]}
	first_curse_ready.erase(_source_key(column, row_index))
	if not _is_irelai_guard(column, tower) or not bool(loadout.get_guard_modifier(&"guard_inactive_explosion", false)):
		return result
	var radius := maxf(float(loadout.get_guard_modifier(&"guard_inactive_explosion_radius", 112.0)), 16.0)
	var damage := column.get_damage(row_index) * tower_damage_multiplier * column_damage_multiplier
	damage *= maxf(float(loadout.get_guard_modifier(&"guard_inactive_explosion_damage", 1.25)), 0.0)
	var targets := spatial_index.query_radius(origin, radius)
	var tracked_enemies: Array[Enemy] = targets.duplicate()
	for enemy in targets:
		result["damage"] = float(result.damage) + enemy.take_damage(damage, &"guard_inactive_explosion", true)
	result.hit_count = targets.size()
	result.radius = radius
	result.tracked_enemies = tracked_enemies
	return result

func register_reactivation(column: TowerColumn, row_index: int, tower: TowerData, loadout: LoadoutManager) -> Dictionary:
	var result := {"curse_ready": false, "fast_soul": false}
	if not _is_irelai_guard(column, tower):
		return result
	var source_key := _source_key(column, row_index)
	if bool(loadout.get_guard_modifier(&"guard_death_curse", false)):
		first_curse_ready[source_key] = true
		result.curse_ready = true
	else:
		first_curse_ready.erase(source_key)
	result.fast_soul = float(loadout.get_guard_modifier(&"post_reactivation_speed", 1.0)) > 1.0
	return result

func apply_first_attack_curse(column: TowerColumn, row_index: int, tower: TowerData, enemy: Enemy, loadout: LoadoutManager) -> int:
	if not _is_irelai_guard(column, tower) or not bool(loadout.get_guard_modifier(&"guard_death_curse", false)):
		return 0
	var source_key := _source_key(column, row_index)
	if not bool(first_curse_ready.get(source_key, false)):
		return 0
	first_curse_ready.erase(source_key)
	return 1 if apply_curse(enemy, 1) else 0

func apply_curse(enemy: Enemy, generation: int) -> bool:
	if not is_instance_valid(enemy) or not enemy.active or generation <= 0:
		return false
	_prune_invalid_curses()
	var enemy_id := enemy.get_instance_id()
	var previous: Dictionary = cursed_enemies.get(enemy_id, {})
	var previous_generation := int(previous.get("generation", 0))
	if previous_generation > 0 and previous_generation <= generation:
		return false
	cursed_enemies[enemy_id] = {"enemy": weakref(enemy), "generation": generation}
	return true

func consume_curse_on_defeat(enemy: Enemy) -> int:
	if not is_instance_valid(enemy):
		return 0
	var enemy_id := enemy.get_instance_id()
	var entry: Dictionary = cursed_enemies.get(enemy_id, {})
	cursed_enemies.erase(enemy_id)
	return maxi(int(entry.get("generation", 0)), 0)

func clear_enemy(enemy: Enemy) -> void:
	if is_instance_valid(enemy):
		cursed_enemies.erase(enemy.get_instance_id())

func clear_source(column: TowerColumn, row_index: int) -> void:
	first_curse_ready.erase(_source_key(column, row_index))

static func next_curse_generation(current_generation: int, maximum_generation: int = 3) -> int:
	var bounded_maximum := maxi(maximum_generation, 1)
	return current_generation + 1 if current_generation > 0 and current_generation < bounded_maximum else 0

func _prune_invalid_curses() -> void:
	for enemy_id in cursed_enemies.keys():
		var entry: Dictionary = cursed_enemies[enemy_id]
		var enemy_ref := entry.get("enemy") as WeakRef
		if enemy_ref == null or not is_instance_valid(enemy_ref.get_ref()):
			cursed_enemies.erase(enemy_id)

func _is_irelai_guard(column: TowerColumn, tower: TowerData) -> bool:
	return column != null and tower != null and column.is_guard_formation and column.formation_data != null and column.formation_data.id == FORMATION_ID and tower.id == &"jade_roulette"

func _source_key(column: TowerColumn, row_index: int) -> String:
	return "%d:%d" % [column.get_instance_id() if is_instance_valid(column) else 0, row_index]
