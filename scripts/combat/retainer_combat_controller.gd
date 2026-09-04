class_name RetainerCombatController
extends Node

signal resummoned(position: Vector2, damage_multiplier: float, slow_power: float)

var profile: RetainerProfileData
var source_cursor: TargetCursor
var spatial_index: EnemySpatialIndex
var modifiers: Dictionary = {}
var charm_profile := CharmProfileData.new()

func setup(retainer_profile: RetainerProfileData, cursor: TargetCursor, growth_modifiers: Dictionary = {}, enemy_index: EnemySpatialIndex = null) -> void:
	profile = retainer_profile
	source_cursor = cursor
	spatial_index = enemy_index
	charm_profile.application_chance = 1.0
	charm_profile.duration = 0.9
	charm_profile.reapplication_immunity = 1.25
	charm_profile.boss_slow_power = 0.55
	charm_profile.boss_vulnerability = 0.15
	apply_modifiers(growth_modifiers)

func apply_modifiers(growth_modifiers: Dictionary) -> void:
	modifiers = growth_modifiers.duplicate(true)
	if source_cursor != null and is_instance_valid(source_cursor) and profile != null and profile.id == &"jeomujeom":
		source_cursor.set_movement_command_interceptor(Callable(self, "_intercept_movement_command") if bool(modifiers.get("jeomujeom_teleport", false)) else Callable())

func _exit_tree() -> void:
	if source_cursor != null and is_instance_valid(source_cursor) and profile != null and profile.id == &"jeomujeom":
		source_cursor.set_movement_command_interceptor(Callable())

func uses_resummon() -> bool:
	return profile != null and profile.id == &"jeomujeom" and bool(modifiers.get("jeomujeom_teleport", false))

func _intercept_movement_command(world_position: Vector2) -> bool:
	if not uses_resummon() or source_cursor == null or not is_instance_valid(source_cursor):
		return false
	source_cursor.warp_to(world_position)
	resummoned.emit(
		world_position,
		float(modifiers.get("jeomujeom_arrival_damage", 0.0)),
		float(modifiers.get("jeomujeom_arrival_slow", 0.0))
	)
	return true

func build_attack_plan(attack_index: int) -> Dictionary:
	var plan := {
		"retainer_id": profile.id if profile != null else &"",
		"strike_count": 1,
		"strike_damage": 1.0,
		"force_area": false,
		"charm_rolls": 0,
		"charm_consumed": false,
		"fear_consumed": false,
	}
	if profile == null:
		return plan
	match profile.id:
		&"kanda":
			var cycle := int(modifiers.get("kanda_whirlwind_cycle", 0))
			plan.force_area = cycle > 0 and attack_index % cycle == 0
			plan.whirlwind_damage = float(modifiers.get("kanda_whirlwind_damage", 1.0)) if bool(plan.force_area) else 1.0
			plan.random_status = [&"poison", &"bleed", &"shock"][RunRng.randi_range(0, 2)] if bool(modifiers.get("kanda_random_status", false)) else &""
			plan.final_slash = bool(plan.force_area) and bool(modifiers.get("kanda_final_slash", false))
			plan.final_slash_damage = 0.85
		&"given":
			plan.strike_count = maxi(int(modifiers.get("given_strike_count", 1)), 1)
			plan.strike_damage = float(modifiers.get("given_strike_damage", 1.0))
			plan.bleed = not bool(modifiers.get("given_bleed_disabled", false))
			plan.charm_rolls = 1
			var chance := float(modifiers.get("given_charm_chance", 0.22))
			plan.charm_success = RunRng.roll() <= chance
			plan.edge_knockback = float(modifiers.get("given_edge_knockback", 1.0))
		&"jeomujeom":
			plan.slow_power = 0.34 * float(modifiers.get("jeomujeom_slow_power", 1.0))
			plan.center_damage = float(modifiers.get("jeomujeom_center_damage", 1.0))
			plan.fear = bool(modifiers.get("jeomujeom_erosion_fear", false)) and attack_index % 3 == 0
			plan.fear_duration = float(modifiers.get("jeomujeom_fear_duration", 1.2))
			plan.fear_spread = maxi(int(modifiers.get("jeomujeom_fear_spread", 0)), 0)
	return plan

func knockback_multiplier_for(enemy: Enemy, attack_position: Vector2, radius: float, plan: Dictionary) -> float:
	if profile == null or profile.id != &"given" or enemy == null or radius <= 0.0:
		return 1.0
	return float(plan.get("edge_knockback", 1.0)) if enemy.global_position.distance_to(attack_position) >= radius * 0.72 else 1.0

func damage_multiplier_for(enemy: Enemy, attack_position: Vector2, radius: float, plan: Dictionary) -> float:
	if profile == null or enemy == null:
		return 1.0
	if profile.id == &"jeomujeom" and enemy.global_position.distance_to(attack_position) <= radius * 0.42:
		return float(plan.get("center_damage", 1.0))
	if profile.id == &"kanda" and bool(plan.get("force_area", false)):
		return float(plan.get("whirlwind_damage", 1.0))
	return 1.0

func apply_on_hit(enemy: Enemy, plan: Dictionary) -> Dictionary:
	var result := {"statuses": [] as Array[StringName], "charm_rolls": 0, "fear_spread": 0}
	if profile == null or enemy == null or not is_instance_valid(enemy):
		return result
	match profile.id:
		&"kanda":
			var status_id := StringName(plan.get("random_status", &""))
			if status_id != &"" and _apply_kanda_common_status(enemy, status_id):
				(result.statuses as Array[StringName]).append(status_id)
		&"given":
			if bool(plan.get("bleed", false)) and enemy.apply_common_bleed(&"retainer_given", 0.0018, 3.0, 3, 24.0):
				(result.statuses as Array[StringName]).append(&"bleed")
			if not bool(plan.get("charm_consumed", false)):
				plan.charm_consumed = true
				result.charm_rolls = 1
				if bool(plan.get("charm_success", false)) and enemy.apply_charm(charm_profile, float(modifiers.get("given_charm_duration", 1.0))):
					(result.statuses as Array[StringName]).append(&"charm")
		&"jeomujeom":
			if enemy.apply_slow(&"retainer_jeomujeom", 2.2, float(plan.get("slow_power", 0.34))):
				(result.statuses as Array[StringName]).append(&"slow")
			if bool(plan.get("fear", false)) and not bool(plan.get("fear_consumed", false)):
				plan.fear_consumed = true
				if enemy.apply_fear(float(plan.get("fear_duration", 1.2)), 0.65):
					(result.statuses as Array[StringName]).append(&"fear")
					var spread_limit := int(plan.get("fear_spread", 0))
					if spread_limit > 0 and spatial_index != null:
						for nearby in spatial_index.query_radius(enemy.global_position, 150.0):
							if nearby == enemy:
								continue
							if nearby.apply_fear(float(plan.get("fear_duration", 1.2)) * 0.65, 0.45):
								(result.statuses as Array[StringName]).append(&"fear")
								result.fear_spread = int(result.fear_spread) + 1
								if int(result.fear_spread) >= spread_limit:
									break
	return result

func _apply_kanda_common_status(enemy: Enemy, status_id: StringName) -> bool:
	var power := float(modifiers.get("retainer_status_power", 1.0))
	var duration := float(modifiers.get("retainer_status_duration", 1.0))
	match status_id:
		&"poison": return enemy.apply_common_poison(4.0 * power, 3.2 * duration, 3)
		&"bleed": return enemy.apply_common_bleed(&"retainer_kanda", 0.0016 * power, 3.0 * duration, 3, 22.0 * power)
		&"shock": return enemy.apply_common_shock(3.0 * duration, 3) > 0
	return false
