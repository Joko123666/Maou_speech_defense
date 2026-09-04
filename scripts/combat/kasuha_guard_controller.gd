class_name KasuhaGuardController
extends RefCounted

const FORMATION_ID: StringName = &"amethyst_bastion"

var replacement_states: Dictionary = {}
var erosion_zones: Array[Dictionary] = []
var erosion_zone_serial: int = 0

func prepare_attack(column: TowerColumn, row_index: int, tower: TowerData, loadout: LoadoutManager) -> Dictionary:
	var result := {"damage_multiplier": 1.0, "status_multiplier": 1.0, "replacement_boosted": false}
	if not _is_kasuha_guard(column, tower) or not bool(loadout.get_guard_modifier(&"guard_research_replacement", false)):
		return result
	var key := _source_key(column, row_index)
	var state: Dictionary = replacement_states.get(key, {})
	if bool(state.get("boost_pending", false)):
		state.boost_pending = false
		result.damage_multiplier = maxf(float(loadout.get_guard_modifier(&"guard_replacement_first_attack_damage", 1.8)), 1.0)
		result.status_multiplier = result.damage_multiplier
		result.replacement_boosted = true
	replacement_states[key] = state
	return result

func resolve_confirmed_attack(column: TowerColumn, row_index: int, tower: TowerData, impact_position: Vector2, loadout: LoadoutManager) -> Dictionary:
	var result := {"mode": &"", "position": impact_position, "radius": 0.0, "replacement_triggered": false}
	if not _is_kasuha_guard(column, tower):
		return result
	if bool(loadout.get_guard_modifier(&"guard_research_replacement", false)):
		var chance := clampf(float(loadout.get_guard_modifier(&"guard_replacement_chance", 0.08)), 0.0, 1.0)
		if replacement_triggered(RunRng.roll(), chance):
			var key := _source_key(column, row_index)
			var state: Dictionary = replacement_states.get(key, {})
			state.boost_pending = true
			replacement_states[key] = state
			column.disable_row_for(row_index, maxf(float(loadout.get_guard_modifier(&"guard_replacement_downtime", 1.2)), 0.1))
			result.mode = &"replacement"
			result.replacement_triggered = true
	if bool(loadout.get_guard_modifier(&"guard_erosion_zone", false)):
		erosion_zone_serial += 1
		var radius := maxf(float(loadout.get_guard_modifier(&"guard_erosion_radius", 86.0)), 12.0)
		var source_key := _source_key(column, row_index)
		var zone_cap := maxi(int(loadout.get_guard_modifier(&"guard_erosion_zone_cap", 3)), 1)
		var matching_zone_indices: Array[int] = []
		for zone_index in erosion_zones.size():
			if String(erosion_zones[zone_index].get("source_key", "")) == source_key:
				matching_zone_indices.append(zone_index)
		if matching_zone_indices.size() >= zone_cap:
			erosion_zones.remove_at(matching_zone_indices[0])
		erosion_zones.append({
			"id": erosion_zone_serial,
			"source_key": source_key,
			"column": column,
			"tower": tower,
			"position": impact_position,
			"radius": radius,
			"remaining": maxf(float(loadout.get_guard_modifier(&"guard_erosion_duration", 2.6)), 0.2),
			"tick": 0.0,
			"tick_interval": maxf(float(loadout.get_guard_modifier(&"guard_erosion_tick", 0.25)), 0.1),
			"slow": clampf(float(loadout.get_guard_modifier(&"guard_erosion_slow", 0.34)), 0.0, 0.8),
		})
		result.mode = &"erosion_zone"
		result.radius = radius
	return result

func resolve_single_target_attack(column: TowerColumn, row_index: int, tower: TowerData, loadout: LoadoutManager, spatial_index: EnemySpatialIndex, select_target: Callable, tower_damage_multiplier: float, column_damage_multiplier: float) -> Dictionary:
	var result := {"handled": false, "damage": 0.0, "attack_damage": 0.0, "hit_count": 0, "target": null, "tracked_enemies": [], "position": Vector2.ZERO}
	if not uses_single_target_conversion(column, tower, loadout):
		return result
	result.handled = true
	var origin := column.get_attack_origin(row_index)
	var candidates := spatial_index.query_radius(origin, column.get_attack_range(row_index))
	var target := select_target.call(candidates, column, tower) as Enemy
	if target == null:
		return result
	var splash_radius := maxf(float(loadout.get_guard_modifier(&"guard_single_target_splash_radius", 58.0)), 0.0)
	var splash_ratio := clampf(float(loadout.get_guard_modifier(&"guard_single_target_splash_ratio", 0.22)), 0.0, 0.5)
	var splash_targets: Array[Enemy] = []
	if splash_radius > 0.0 and splash_ratio > 0.0:
		splash_targets.assign(spatial_index.query_radius(target.global_position, splash_radius).filter(func(enemy: Enemy) -> bool: return enemy != target))
	var tracked_enemies: Array[Enemy] = [target]
	tracked_enemies.append_array(splash_targets)
	var damage_floor := maxf(float(loadout.get_guard_modifier(&"guard_single_target_damage_floor", 42.0)), 0.0)
	var attack_damage := maxf(column.get_damage(row_index), damage_floor) * tower_damage_multiplier * column_damage_multiplier
	var dealt := target.take_damage(attack_damage, &"guard_abyss_entity")
	for splash_target in splash_targets:
		dealt += splash_target.take_damage(attack_damage * splash_ratio, &"guard_abyss_entity_splash", true)
	if target.active and tower.status_power > 0.0:
		target.apply_slow(&"kasuha_guard_single", float(loadout.get_guard_modifier(&"guard_single_target_slow_duration", 1.6)), tower.status_power)
	result.damage = dealt
	result.attack_damage = attack_damage
	result.hit_count = tracked_enemies.size()
	result.target = target
	result.tracked_enemies = tracked_enemies
	result.position = target.global_position
	return result

func update_erosion_zones(delta: float, spatial_index: EnemySpatialIndex) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for index in range(erosion_zones.size() - 1, -1, -1):
		var zone: Dictionary = erosion_zones[index]
		var column := zone.get("column") as TowerColumn
		if not is_instance_valid(column):
			erosion_zones.remove_at(index)
			continue
		zone.remaining = float(zone.get("remaining", 0.0)) - delta
		zone.tick = float(zone.get("tick", 0.0)) - delta
		if float(zone.tick) <= 0.0:
			zone.tick = float(zone.get("tick_interval", 0.25))
			var applied := 0
			for enemy in spatial_index.query_radius(zone.get("position", Vector2.ZERO) as Vector2, float(zone.get("radius", 0.0))):
				if enemy.apply_slow(&"kasuha_guard_erosion", float(zone.get("tick_interval", 0.25)) + 0.18, float(zone.get("slow", 0.0))):
					applied += 1
			if applied > 0:
				events.append({"type": &"erosion_tick", "column": column, "tower": zone.get("tower"), "count": applied})
		if float(zone.remaining) <= 0.0:
			events.append({"type": &"erosion_ended", "column": column, "tower": zone.get("tower"), "position": zone.get("position", Vector2.ZERO)})
			erosion_zones.remove_at(index)
		else:
			erosion_zones[index] = zone
	return events

func uses_single_target_conversion(column: TowerColumn, tower: TowerData, loadout: LoadoutManager) -> bool:
	return _is_kasuha_guard(column, tower) and bool(loadout.get_guard_modifier(&"guard_single_target_conversion", false))

func allows_pillar_sacrifice(column: TowerColumn, tower: TowerData, loadout: LoadoutManager) -> bool:
	return not uses_single_target_conversion(column, tower, loadout)

func active_erosion_zone_count() -> int:
	return erosion_zones.size()

static func replacement_triggered(roll: float, chance: float) -> bool:
	return clampf(roll, 0.0, 1.0) < clampf(chance, 0.0, 1.0)

func _is_kasuha_guard(column: TowerColumn, tower: TowerData) -> bool:
	return column != null and tower != null and column.is_guard_formation and column.formation_data != null and column.formation_data.id == FORMATION_ID

func _source_key(column: TowerColumn, row_index: int) -> String:
	return "%d:%d" % [column.get_instance_id(), row_index]
