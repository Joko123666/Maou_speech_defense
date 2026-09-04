class_name CandidateCoreSkillPolicy
extends RefCounted

func build_plan(
		core_data: CoreData,
		candidate_modifiers: Dictionary,
		candidate_growth_enabled: bool,
		death_wave_available: bool
	) -> Dictionary:
	var core_id := core_data.id if core_data != null else &""
	var mass_summon := core_id == &"amethyst" and bool(_modifier(candidate_modifiers, &"candidate_summoning", false))
	var death_wave := core_id == &"jade" and candidate_growth_enabled and death_wave_available
	return {
		"mass_summon": mass_summon,
		"death_wave": death_wave,
		"display_death_wave": core_id == &"jade" and candidate_growth_enabled,
		"charm_zone": core_id == &"sapphire",
		"charm_stage_buff": core_id == &"sapphire" and bool(_modifier(candidate_modifiers, &"charm_stage", false)),
		"guard_active": core_id == &"emerald",
		"reaper_summon": core_id == &"obsidian",
		"replaces_native_skill": mass_summon or death_wave,
		"uses_native_necromancy": core_data != null and core_data.necromancy_profile != null and not death_wave,
	}

func title_for(core_data: CoreData, plan: Dictionary, core_term: String) -> String:
	if core_data == null:
		return "%s 액티브" % core_term
	if bool(plan.get("reaper_summon", false)):
		return "사신 소환"
	if core_data.id == &"jade":
		return "죽음의 파도" if bool(plan.get("display_death_wave", false)) else "사령 군단"
	if bool(plan.get("mass_summon", false)):
		return "대규모 소환술"
	# 보석 기반 skill_type은 안정 전투 계약으로만 유지하고 화면에는 후보 액티브명을 노출한다.
	return {
		&"emerald": "왕권 선포",
		&"sapphire": "광역 환혹 무대",
		&"amethyst": "심연 붕괴술",
		&"jade": "죽음의 파도",
		&"obsidian": "사신 소환",
	}.get(core_data.id, "%s 액티브" % core_term)

func _modifier(modifiers: Dictionary, key: StringName, default_value: Variant) -> Variant:
	return modifiers.get(String(key), modifiers.get(key, default_value))
