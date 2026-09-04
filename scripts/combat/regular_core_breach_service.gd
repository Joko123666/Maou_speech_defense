class_name RegularCoreBreachService
extends RefCounted

var accumulated_damage_by_group: Dictionary = {}

func resolve(
		raw_damage: float,
		challenge_damage_multiplier: float,
		core_breach_damage_multiplier: float,
		core_health: float,
		core_max_health: float,
		group_id: StringName,
		final_boss_contest_started: bool
	) -> Dictionary:
	var resolved_damage := CoreBreachDamagePolicy.regular_damage(raw_damage, challenge_damage_multiplier, core_breach_damage_multiplier)
	var group_limited_damage := resolved_damage
	if group_id != &"":
		var accumulated := float(accumulated_damage_by_group.get(group_id, 0.0))
		group_limited_damage = CoreBreachDamagePolicy.group_limited_damage(
			resolved_damage,
			core_max_health,
			accumulated,
			challenge_damage_multiplier,
			core_breach_damage_multiplier
		)
		accumulated_damage_by_group[group_id] = accumulated + group_limited_damage
	var breach_damage := group_limited_damage
	if not final_boss_contest_started:
		breach_damage = CoreBreachDamagePolicy.pre_final_reserve_limited_damage(group_limited_damage, core_health, core_max_health)
	return {
		"damage": breach_damage,
		"resolved_damage": resolved_damage,
		"group_limited_damage": group_limited_damage,
		"group_prevented_damage": maxf(resolved_damage - group_limited_damage, 0.0),
		"reserve_prevented_damage": maxf(group_limited_damage - breach_damage, 0.0),
		"group_accumulated_damage": float(accumulated_damage_by_group.get(group_id, 0.0)) if group_id != &"" else 0.0,
	}

func reset() -> void:
	accumulated_damage_by_group.clear()
