class_name CandidateCoreAttackPolicy
extends RefCounted

func build_plan(
		requested_core: CoreData,
		active_core: CoreData,
		candidate_modifiers: Dictionary,
		candidate_growth_enabled: bool,
		abyss_presence_ready: bool
	) -> Dictionary:
	var core_id := requested_core.id if requested_core != null else &""
	return {
		"attack_range_multiplier": float(_modifier(candidate_modifiers, &"core_attack_range", 1.0)),
		"replace_with_spirit": should_replace_irelai_basic_attack(requested_core, active_core, candidate_growth_enabled),
		"trigger_abyss_presence": core_id == &"amethyst" and abyss_presence_ready,
		"abyss_presence_radius_multiplier": float(_modifier(candidate_modifiers, &"abyss_presence_radius", 1.45)),
		"abyss_presence_hits": clampi(int(_modifier(candidate_modifiers, &"abyss_presence_hits", 4)), 1, 8),
		"abyss_presence_damage_multiplier": float(_modifier(candidate_modifiers, &"abyss_presence_damage", 0.72)),
		"charm_radial": bool(_modifier(candidate_modifiers, &"charm_radial", false)),
		"charm_radial_targets": clampi(int(_modifier(candidate_modifiers, &"charm_radial_targets", 5)), 1, 8),
		"charm_radial_damage_multiplier": float(_modifier(candidate_modifiers, &"charm_radial_damage", 0.72)),
		"pierce_width_multiplier": float(_modifier(candidate_modifiers, &"core_pierce_width", 1.0)),
		"abyss_center_radius": float(_modifier(candidate_modifiers, &"abyss_center_radius", 0.0)),
		"abyss_center_damage_multiplier": float(_modifier(candidate_modifiers, &"abyss_center_damage", 0.0)),
	}

static func should_replace_irelai_basic_attack(requested_core: CoreData, active_core: CoreData, candidate_growth_enabled: bool) -> bool:
	return candidate_growth_enabled and requested_core != null and active_core != null and requested_core == active_core and active_core.id == &"jade"

func _modifier(modifiers: Dictionary, key: StringName, default_value: Variant) -> Variant:
	return modifiers.get(String(key), modifiers.get(key, default_value))
