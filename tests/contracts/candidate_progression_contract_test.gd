class_name CandidateProgressionContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var save_backup := SaveManager._build_save_data()
	var campaign := load("res://data/concepts/demon_election_campaign_v0_8.tres") as ElectionCampaignData
	_expect(campaign.decree_catalog != null and campaign.decree_catalog.get_validation_errors(_candidate_ids(campaign)).is_empty(), "all candidate decrees must validate as bounded sidegrades with one benefit and one tradeoff", failures)
	var partason := campaign.candidate(&"partason")
	_expect(partason != null and partason.growth_data != null and partason.growth_data.get_validation_errors().is_empty(), "Partason must expose a valid first-fixed, three-branch, final-fixed candidate growth contract", failures)
	_expect(partason != null and partason.guard_growth_data != null and partason.guard_growth_data.get_validation_errors().is_empty(), "Partason must expose a valid training, three-specialization, completion guard growth contract", failures)
	var guard_growth := GuardProgressionService.new()
	guard_growth.configure(partason.guard_growth_data)
	_expect(guard_growth.get_stage() == 0 and guard_growth.get_specializations().is_empty() and guard_growth.select_specialization(&"partason_guard_shield") == null, "guard specialization must not skip the mandatory training stage", failures)
	var guard_trained := guard_growth.train()
	var guard_specializations := guard_growth.get_specializations()
	var guard_selected := guard_growth.select_specialization(&"partason_guard_shield")
	var guard_modifiers := guard_growth.merged_modifiers()
	_expect(guard_trained and guard_growth.get_stage() == 2 and guard_specializations.size() == 3 and guard_selected != null and is_equal_approx(float(guard_modifiers.get("guard_damage", 1.0)), 1.1 * 1.05), "guard training must unlock exactly three branches and compose training with the selected specialization", failures)
	_expect(guard_growth.select_specialization(&"partason_guard_sword") == null and not guard_growth.complete_specialization(&"partason_guard_sword"), "a selected guard specialization must be immutable and only its matching completion may apply", failures)
	_expect(guard_growth.complete_specialization(&"partason_guard_shield") and guard_growth.get_stage() == 3 and guard_growth.completed and float(guard_growth.merged_modifiers().get("guard_knockback", 1.0)) > 1.6, "guard completion must strengthen only the selected specialization and cap growth at stage three", failures)
	var guard_loadout := LoadoutManager.new()
	guard_loadout.guard_progression.configure(partason.guard_growth_data)
	var guard_training_choice := guard_loadout.get_guard_growth_choice()
	var guard_training_applied := guard_loadout.apply_upgrade(guard_training_choice)
	var guard_entry := guard_loadout.get_guard_growth_choice()
	var guard_branch_choices := guard_loadout.get_specialization_subchoices(guard_entry)
	var guard_branch_applied := guard_loadout.apply_upgrade(guard_branch_choices[1])
	var guard_completion_choice := guard_loadout.get_guard_growth_choice()
	var guard_completion_applied := guard_loadout.apply_upgrade(guard_completion_choice)
	_expect(guard_training_choice.category == &"guard_training" and guard_training_applied and guard_entry.category == &"guard_specialization_entry" and guard_branch_choices.size() == 3 and guard_branch_applied and guard_completion_choice.category == &"guard_completion" and guard_completion_applied and guard_loadout.get_guard_growth_choice() == null, "ordinary level-up guard cards must advance training, one three-choice branch, and its completion without offering a fourth stage", failures)
	_expect(String(guard_loadout.get_guard_growth_snapshot().selected_specialization_id) == "partason_guard_sword" and guard_loadout.get_build_summary().contains("친위대 3/3"), "guard growth must persist stable branch state and expose its completed stage in the build summary", failures)
	guard_loadout.free()
	var guard_policy := SpecializationOfferPolicy.new(0.0, 2)
	var guard_policy_entry := UpgradeData.new().configure(&"guard_training", "친위대 훈련", "", &"emerald_guard")
	var guard_policy_entries: Array[UpgradeData] = [guard_policy_entry]
	var guard_policy_offered := false
	for offer_index in 3:
		var policy_choices: Array[UpgradeData] = [UpgradeData.new().configure(&"global_upgrade", "공통", "", &"global")]
		guard_policy.inject(policy_choices, guard_policy_entries, false)
		if offer_index == 2:
			guard_policy_offered = policy_choices[0].category == &"guard_training"
	_expect(guard_policy_offered, "an eligible guard growth card must be guaranteed after two consecutive misses", failures)
	var guard_range_column := TowerColumn.new()
	guard_range_column.row_towers.append(DataRegistry.get_tower(&"emerald_guardian"))
	guard_range_column.tower_levels[&"emerald_guardian"] = 1
	guard_range_column.guard_range_multiplier = 1.5
	guard_range_column.general_range_multiplier = 1.1
	guard_range_column.is_guard_formation = false
	var regular_range := guard_range_column.get_range_multiplier(0)
	guard_range_column.is_guard_formation = true
	_expect(is_equal_approx(regular_range, 1.1) and is_equal_approx(guard_range_column.get_range_multiplier(0), 1.5), "general and guard range modifiers must remain isolated even when formations share a tower id", failures)
	guard_range_column.free()
	var runtime_growth := CandidateProgressionService.new()
	runtime_growth.configure(partason.growth_data)
	var first_growth := runtime_growth.claim_fixed_slot(0)
	var candidate_branches := runtime_growth.get_branch_upgrades(1)
	var selected_growth := runtime_growth.select_branch(&"partason_armament")
	var final_growth := runtime_growth.claim_fixed_slot(2)
	var growth_modifiers := runtime_growth.merged_modifiers()
	_expect(first_growth != null and first_growth.id == &"partason_royal_dignity" and candidate_branches.size() == 3 and selected_growth != null and final_growth != null, "candidate boss slots 0, 1, and 2 must resolve fixed, three-choice, and fixed rewards exactly once", failures)
	_expect(is_equal_approx(float(growth_modifiers.get("core_damage", 1.0)), 1.08 * 1.15) and is_equal_approx(float(growth_modifiers.get("tower_damage", 1.0)), 1.1 * 1.08), "candidate growth modifiers from completed slots must compose multiplicatively", failures)
	_expect(runtime_growth.claim_fixed_slot(0) == null and runtime_growth.select_branch(&"partason_union") == null, "candidate milestone rewards and branch selection must be idempotent", failures)
	var union_loadout := LoadoutManager.new()
	union_loadout.candidate_progression.configure(partason.growth_data)
	union_loadout.candidate_progression.select_branch(&"partason_union")
	for tower_id: StringName in [&"rapid", &"area", &"pierce"]:
		var union_column := TowerColumn.new()
		union_column.row_towers.append(DataRegistry.get_tower(tower_id))
		union_loadout.columns.append(union_column)
	_expect(is_equal_approx(union_loadout.get_tower_damage_multiplier(), 1.0) and is_equal_approx(union_loadout.get_tower_speed_multiplier(), 1.05) and is_equal_approx(union_loadout.get_tower_range_multiplier(), 1.05), "three distinct regular defenders must grant speed and range/area, never the obsolete diversity damage bonus", failures)
	for union_column in union_loadout.columns:
		union_column.free()
	union_loadout.columns.clear()
	union_loadout.free()
	var command_loadout := LoadoutManager.new()
	command_loadout.candidate_progression.configure(partason.growth_data)
	command_loadout.candidate_progression.claim_fixed_slot(0)
	command_loadout.candidate_progression.select_branch(&"partason_armament")
	command_loadout.candidate_progression.claim_fixed_slot(2)
	var base_guard_loadout := LoadoutManager.new()
	var base_guard_skill := GuardAbilityController.new().get_partason_auto_skill_profile(base_guard_loadout)
	var commanded_guard_skill := GuardAbilityController.new().get_partason_auto_skill_profile(command_loadout)
	_expect(base_guard_skill.mode == &"royal" and int(base_guard_skill.cycle) == 6 and float(base_guard_skill.damage) > 0.0 and float(commanded_guard_skill.damage) > float(base_guard_skill.damage), "Partason's guard must own a baseline periodic area skill and Mobilization must strengthen it", failures)
	base_guard_loadout.free()
	command_loadout.free()
	var partason_guard := DataRegistry.get_formation(&"emerald_guard")
	_expect(partason_guard != null and partason_guard.cells.size() == 4 and partason_guard.get_bounds().size == Vector2i(1, 4), "Partason's royal guard must occupy one vertical four-cell column", failures)
	var jiane := campaign.candidate(&"jiane")
	_expect(jiane != null and jiane.growth_data != null and jiane.growth_data.get_validation_errors().is_empty(), "Jiane must expose two fixed milestones and exactly three charm-specialization branches", failures)
	_expect(DataRegistry.get_core(&"sapphire").charm_profile.active_zone_duration >= 6.0, "Jiane's base active must own a persistent map-wide charm-zone duration before any branch is selected", failures)
	var jiane_growth := CandidateProgressionService.new()
	jiane_growth.configure(jiane.growth_data)
	_expect(jiane_growth.claim_fixed_slot(0).id == &"jiane_dream_authority" and jiane_growth.get_branch_upgrades().size() == 3 and jiane_growth.select_branch(&"jiane_betraying_love") != null and jiane_growth.claim_fixed_slot(2).id == &"jiane_fanatic_supporters", "Jiane boss milestones must resolve dream authority, one love branch, and fanatic supporters in slot order", failures)
	var jiane_modifiers := jiane_growth.merged_modifiers()
	_expect(is_equal_approx(float(jiane_modifiers.get("charm_duration", 1.0)), 1.35) and is_equal_approx(float(jiane_modifiers.get("core_breach_damage", 1.0)), 0.5) and is_equal_approx(float(jiane_modifiers.get("charm_vulnerability", 0.0)), 0.35) and bool(jiane_modifiers.get("charm_echo", false)), "Jiane growth must compose duration, core-breach protection, vulnerability, and non-boss charm echo behavior", failures)
	var jiane_breach_loadout := LoadoutManager.new()
	jiane_breach_loadout.candidate_progression.configure(jiane.growth_data)
	_expect(is_equal_approx(jiane_breach_loadout.get_core_breach_damage_multiplier(), 1.0), "Jiane must not receive core-breach protection before the first candidate milestone", failures)
	jiane_breach_loadout.candidate_progression.claim_fixed_slot(0)
	_expect(is_equal_approx(jiane_breach_loadout.get_core_breach_damage_multiplier(), 0.5), "Dream Authority must route its core-breach protection through the runtime loadout multiplier", failures)
	jiane_breach_loadout.free()
	_expect(jiane.guard_growth_data != null and jiane.guard_growth_data.get_validation_errors().is_empty() and jiane.guard_growth_data.specializations.map(func(branch: GuardSpecializationData) -> StringName: return branch.id) == [&"jiane_guard_pure", &"jiane_guard_chaste", &"jiane_guard_devotion"], "Jiane guard growth must expose training followed by the documented pure, chaste, and devotion specializations", failures)
	var jiane_pure_guard := GuardProgressionService.new()
	jiane_pure_guard.configure(jiane.guard_growth_data)
	jiane_pure_guard.train()
	jiane_pure_guard.select_specialization(&"jiane_guard_pure")
	var pure_guard_modifiers := jiane_pure_guard.merged_modifiers()
	_expect(float(pure_guard_modifiers.get("guard_range", 1.0)) < 1.0 and float(pure_guard_modifiers.get("guard_damage", 1.0)) > 1.5 and bool(pure_guard_modifiers.get("guard_hit_shockwave", false)) and jiane_pure_guard.complete_specialization(&"jiane_guard_pure") and float(jiane_pure_guard.merged_modifiers().get("guard_hit_shockwave_radius", 1.0)) > 1.0, "Jiane's pure guard must exchange range for damage and a completion-scaled hit shockwave", failures)
	var jiane_chaste_guard := GuardProgressionService.new()
	jiane_chaste_guard.configure(jiane.guard_growth_data)
	jiane_chaste_guard.train()
	jiane_chaste_guard.select_specialization(&"jiane_guard_chaste")
	jiane_chaste_guard.complete_specialization(&"jiane_guard_chaste")
	var chaste_guard_modifiers := jiane_chaste_guard.merged_modifiers()
	_expect(bool(chaste_guard_modifiers.get("guard_frenzy", false)) and float(chaste_guard_modifiers.get("guard_frenzy_duration", 0.0)) > 3.0 and float(chaste_guard_modifiers.get("guard_frenzy_interval", 10.0)) < 10.0 and float(chaste_guard_modifiers.get("guard_frenzy_movement_speed", 0.0)) > 170.0, "Jiane's chaste guard must periodically enter a faster roaming narrow-area frenzy before returning", failures)
	var jiane_devotion_loadout := LoadoutManager.new()
	jiane_devotion_loadout.guard_progression.configure(jiane.guard_growth_data)
	jiane_devotion_loadout.guard_progression.train()
	jiane_devotion_loadout.guard_progression.select_specialization(&"jiane_guard_devotion")
	jiane_devotion_loadout.add_guard_runtime_value(&"devotion", 40.0, int(jiane_devotion_loadout.get_guard_modifier(&"guard_devotion_max_stacks", 30)))
	var devotion_snapshot := jiane_devotion_loadout.get_guard_growth_snapshot()
	var devotion_runtime_values := devotion_snapshot.runtime_values as Dictionary
	var snapshotted_devotion := float(devotion_runtime_values.get(&"devotion", devotion_runtime_values.get("devotion", 0.0)))
	_expect(is_equal_approx(jiane_devotion_loadout.get_guard_runtime_value(&"devotion"), 30.0) and is_equal_approx(snapshotted_devotion, 30.0) and is_equal_approx(GuardAbilityController.devotion_extension(30, 0.1, 3.0), 3.0) and jiane_devotion_loadout.get_build_summary().contains("헌신 30/30"), "Jiane devotion must persist in the run snapshot, display in the HUD summary, cap at thirty, and extend the active by at most three seconds", failures)
	_expect(is_equal_approx(jiane_devotion_loadout.consume_guard_runtime_value(&"devotion"), 30.0) and is_zero_approx(jiane_devotion_loadout.get_guard_runtime_value(&"devotion")), "Jiane's active must consume the entire bounded devotion reserve exactly once", failures)
	jiane_devotion_loadout.free()
	var jiane_guard := DataRegistry.get_formation(&"sapphire_spearhead")
	var expected_jiane_offsets := [Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 3)]
	_expect(jiane_guard != null and jiane_guard.cells.size() == 4 and jiane_guard.get_shape_errors().is_empty() and jiane_guard.cells.all(func(cell: FormationCellData) -> bool: return cell.offset in expected_jiane_offsets and cell.tower_id == &"sapphire_lance"), "Jiane's fanatic guard must allow the documented sparse four-cell shape while regular formations remain connected", failures)
	var mobile_guard_column := TowerColumn.new()
	mobile_guard_column.row_towers.append(DataRegistry.get_tower(&"sapphire_lance"))
	mobile_guard_column.mobile_tower_offsets.resize(1)
	mobile_guard_column.mobile_tower_offsets[0] = Vector2.ZERO
	var occupied_tower := mobile_guard_column.row_towers[0]
	mobile_guard_column.set_mobile_tower_offset(0, Vector2(48.0, -24.0))
	_expect(mobile_guard_column.row_towers[0] == occupied_tower and mobile_guard_column.get_mobile_tower_offset(0) == Vector2(48.0, -24.0), "roaming guards must retain their original occupied board cell while only their combat and draw offset moves", failures)
	mobile_guard_column.free()
	var candidate_loadout := LoadoutManager.new()
	candidate_loadout.core_state = GrowthTrackState.new(&"emerald")
	candidate_loadout.cursor_state = GrowthTrackState.new(&"iron")
	candidate_loadout.candidate_progression.configure(partason.growth_data)
	candidate_loadout.core_state.current_level = 3
	var normal_growth_choice := candidate_loadout._growth_track_choice()
	_expect(normal_growth_choice.category == &"cursor_level" and not candidate_loadout.get_specialization_entry_choices().any(func(choice: UpgradeData) -> bool: return choice.category == &"core_specialization_entry"), "an election candidate growth profile must remove core/candidate levels and branches from the ordinary level-up pool", failures)
	var branch_choice := candidate_loadout.get_candidate_branch_choices()[0]
	_expect(candidate_loadout.apply_candidate_branch(branch_choice) and candidate_loadout.get_candidate_growth_snapshot().selected_branch_id == "partason_armament", "candidate branch choices must apply through their dedicated runtime path and persist in the run snapshot", failures)
	candidate_loadout.free()
	var stage_loadout := LoadoutManager.new()
	stage_loadout.candidate_progression.configure(jiane.growth_data)
	stage_loadout.candidate_progression.select_branch(&"jiane_stage_of_love")
	var stage_damage_before := stage_loadout.get_tower_damage_multiplier()
	stage_loadout.set_candidate_stage_buff_active(true)
	_expect(stage_loadout.get_tower_damage_multiplier() > stage_damage_before and stage_loadout.get_tower_speed_multiplier() > 1.0 and stage_loadout.get_cursor_damage_multiplier() > 1.0, "Jiane's love stage must buff all tower and retainer damage channels only while active", failures)
	stage_loadout.set_candidate_stage_buff_active(false)
	_expect(is_equal_approx(stage_loadout.get_tower_damage_multiplier(), stage_damage_before), "Jiane's love-stage buff must end without permanently changing loadout multipliers", failures)
	stage_loadout.free()
	var kasuha := campaign.candidate(&"kasuha")
	_expect(kasuha != null and kasuha.growth_data != null and kasuha.growth_data.get_validation_errors().is_empty(), "Kasuha must expose two fixed milestones and exactly three abyss-specialization branches", failures)
	var amethyst_core := DataRegistry.get_core(&"amethyst")
	var sapphire_core := DataRegistry.get_core(&"sapphire")
	_expect(amethyst_core != null and sapphire_core != null and amethyst_core.damage > sapphire_core.damage and amethyst_core.skill_damage > sapphire_core.skill_damage, "Kasuha's base radial attack and active must preserve the GDD's high-power direct-attack identity before the first boss milestone", failures)
	var kasuha_growth := CandidateProgressionService.new()
	kasuha_growth.configure(kasuha.growth_data)
	_expect(kasuha_growth.claim_fixed_slot(0).id == &"kasuha_amplification" and kasuha_growth.get_branch_upgrades().size() == 3 and kasuha_growth.select_branch(&"kasuha_abyss_power") != null and kasuha_growth.claim_fixed_slot(2).id == &"kasuha_overdrive", "Kasuha boss milestones must resolve amplification, one abyss branch, and overdrive in slot order", failures)
	var kasuha_power_modifiers := kasuha_growth.merged_modifiers()
	_expect(float(kasuha_power_modifiers.get("core_attack_range", 1.0)) > 1.5 and float(kasuha_power_modifiers.get("core_attack_speed", 1.0)) < 1.0 and float(kasuha_power_modifiers.get("abyss_center_damage", 0.0)) > 1.0, "abyss power must exchange attack speed for multiplicative range and center damage", failures)
	var kasuha_range_loadout := LoadoutManager.new()
	kasuha_range_loadout.candidate_progression.configure(kasuha.growth_data)
	kasuha_range_loadout.candidate_progression.claim_fixed_slot(0)
	kasuha_range_loadout.candidate_progression.select_branch(&"kasuha_abyss_power")
	var kasuha_range_core := DefenseCore.new()
	kasuha_range_core.data = DataRegistry.get_core(&"amethyst")
	var kasuha_range_overlay := CombatRangeOverlay.new()
	kasuha_range_overlay.core = kasuha_range_core
	kasuha_range_overlay.loadout = kasuha_range_loadout
	kasuha_range_overlay.inspected_kind = &"core"
	_expect(is_equal_approx(kasuha_range_overlay.get_inspected_range(), kasuha_range_core.data.attack_range * float(kasuha_range_loadout.get_candidate_modifier(&"core_attack_range", 1.0))) and kasuha_range_loadout.get_core_attack_speed_multiplier() < 1.0, "Kasuha's runtime range overlay and core cadence must use the same candidate modifiers as combat", failures)
	kasuha_range_overlay.free()
	kasuha_range_core.free()
	kasuha_range_loadout.free()
	var kasuha_guard := DataRegistry.get_formation(&"amethyst_bastion")
	var kasuha_guard_ids: Array[StringName] = kasuha_guard.get_tower_ids() if kasuha_guard != null else []
	_expect(kasuha_guard != null and kasuha_guard.cells.size() == 4 and kasuha_guard.get_bounds().size == Vector2i(2, 2) and kasuha_guard_ids.count(&"slow") == 2 and kasuha_guard_ids.count(&"amethyst_nova") == 2 and kasuha_guard.cells.all(func(cell: FormationCellData) -> bool: return cell.tower_id == (&"amethyst_nova" if cell.offset.x == 0 else &"slow")), "Kasuha's abyss guard must occupy a two-by-two block with two front pillars and two rear followers", failures)
	_expect(kasuha.guard_growth_data != null and kasuha.guard_growth_data.get_validation_errors().is_empty() and kasuha.guard_growth_data.specializations.map(func(branch: GuardSpecializationData) -> StringName: return branch.id) == [&"kasuha_guard_research", &"kasuha_guard_erosion", &"kasuha_guard_obsession"], "Kasuha guard growth must expose the documented abyss research, erosion, and obsession specializations", failures)
	var kasuha_research_guard := GuardProgressionService.new()
	kasuha_research_guard.configure(kasuha.guard_growth_data)
	kasuha_research_guard.train()
	kasuha_research_guard.select_specialization(&"kasuha_guard_research")
	var research_modifiers := kasuha_research_guard.merged_modifiers()
	_expect(float(research_modifiers.get("guard_damage", 1.0)) > 1.2 and float(research_modifiers.get("guard_range", 1.0)) > 1.2 and float(research_modifiers.get("guard_speed", 1.0)) < 1.0 and bool(research_modifiers.get("guard_research_replacement", false)) and KasuhaGuardController.replacement_triggered(0.079, 0.08) and not KasuhaGuardController.replacement_triggered(0.08, 0.08), "abyss research must exchange cadence for damage and range while using a deterministic bounded replacement probability", failures)
	_expect(kasuha_research_guard.complete_specialization(&"kasuha_guard_research") and float(kasuha_research_guard.merged_modifiers().get("guard_replacement_first_attack_damage", 1.0)) > 2.0 and float(kasuha_research_guard.merged_modifiers().get("guard_replacement_downtime", 2.0)) < 1.2, "completed abyss research must shorten replacement downtime and strengthen the replacement's first action", failures)
	var kasuha_erosion_guard := GuardProgressionService.new()
	kasuha_erosion_guard.configure(kasuha.guard_growth_data)
	kasuha_erosion_guard.train()
	kasuha_erosion_guard.select_specialization(&"kasuha_guard_erosion")
	kasuha_erosion_guard.complete_specialization(&"kasuha_guard_erosion")
	var erosion_modifiers := kasuha_erosion_guard.merged_modifiers()
	_expect(bool(erosion_modifiers.get("guard_erosion_zone", false)) and int(erosion_modifiers.get("guard_erosion_zone_cap", 0)) == 3 and float(erosion_modifiers.get("guard_erosion_duration", 0.0)) > 3.0 and float(erosion_modifiers.get("guard_erosion_radius", 0.0)) > 100.0, "abyss erosion must create short-lived slowing impact zones with a bounded per-source active cap", failures)
	var kasuha_obsession_loadout := LoadoutManager.new()
	kasuha_obsession_loadout.guard_progression.configure(kasuha.guard_growth_data)
	kasuha_obsession_loadout.guard_progression.train()
	kasuha_obsession_loadout.guard_progression.select_specialization(&"kasuha_guard_obsession")
	var kasuha_guard_column := TowerColumn.new()
	kasuha_guard_column.is_guard_formation = true
	kasuha_guard_column.formation_data = kasuha_guard
	kasuha_guard_column.row_towers.append(DataRegistry.get_tower(&"slow"))
	var kasuha_guard_controller := KasuhaGuardController.new()
	_expect(kasuha_guard_controller.uses_single_target_conversion(kasuha_guard_column, DataRegistry.get_tower(&"slow"), kasuha_obsession_loadout) and not kasuha_guard_controller.allows_pillar_sacrifice(kasuha_guard_column, DataRegistry.get_tower(&"slow"), kasuha_obsession_loadout) and float(kasuha_obsession_loadout.get_guard_modifier(&"guard_range", 1.0)) < 1.0 and float(kasuha_obsession_loadout.get_guard_modifier(&"guard_single_target_damage_floor", 0.0)) >= 42.0 and float(kasuha_obsession_loadout.get_guard_modifier(&"guard_single_target_splash_ratio", 1.0)) < 0.3, "obsession must replace the mixed guard with a short-range high-damage primary hit, heavily reduced splash, and no obsolete pillar sacrifice ritual", failures)
	var kasuha_research_loadout := LoadoutManager.new()
	kasuha_research_loadout.guard_progression.configure(kasuha.guard_growth_data)
	kasuha_research_loadout.guard_progression.train()
	kasuha_research_loadout.guard_progression.select_specialization(&"kasuha_guard_research")
	_expect(kasuha_guard_controller.allows_pillar_sacrifice(kasuha_guard_column, DataRegistry.get_tower(&"slow"), kasuha_research_loadout), "research and erosion guards must preserve the ordinary abyss pillar's independently capped sacrifice summon contract", failures)
	var kasuha_guard_impacts := UpgradePresentationService.new().choice_impacts(UpgradeData.new().configure(&"guard_branch", "심연 침식", "", &"kasuha_guard_erosion"))
	_expect(kasuha_guard_impacts.any(func(impact: Dictionary) -> bool: return String(impact.get("label", "")).contains("둔화 장판")), "Kasuha guard cards must expose their actual erosion-zone role instead of a generic guard impact summary", failures)
	kasuha_guard_column.free()
	kasuha_obsession_loadout.free()
	kasuha_research_loadout.free()
	var presence_loadout := LoadoutManager.new()
	presence_loadout.candidate_progression.configure(kasuha.growth_data)
	var presence_choice := presence_loadout.get_candidate_branch_choices().filter(func(choice: UpgradeData) -> bool: return choice.data_id == &"kasuha_abyss_presence")[0] as UpgradeData
	_expect(presence_loadout.apply_candidate_branch(presence_choice), "Kasuha's abyss-presence branch must apply through the candidate path", failures)
	presence_loadout.record_candidate_abyss_defeat(DataRegistry.get_enemy(&"civilian_slime"))
	presence_loadout.record_candidate_abyss_defeat(DataRegistry.get_enemy(&"steel_golem"))
	presence_loadout.record_candidate_abyss_boss_damage(0.16)
	presence_loadout.record_candidate_abyss_defeat(DataRegistry.get_enemy(&"steel_golem"))
	presence_loadout.record_candidate_abyss_defeat(DataRegistry.get_enemy(&"civilian_slime"))
	_expect(presence_loadout.candidate_abyss_stacks == 12 and presence_loadout.is_candidate_abyss_presence_ready(), "abyss presence must gain one normal stack, four elite stacks, and one stack per eight percent boss damage without exceeding twelve", failures)
	presence_loadout.record_candidate_abyss_boss_damage(0.5)
	_expect(is_zero_approx(presence_loadout.candidate_abyss_boss_damage_progress), "abyss presence must not bank hidden boss-damage progress while its twelve-stack bundle is ready", failures)
	_expect(presence_loadout.consume_candidate_abyss_presence() and presence_loadout.candidate_abyss_stacks == 0 and int(presence_loadout.get_candidate_growth_snapshot().abyss_presence_stacks) == 0, "the next abyss-presence attack must consume exactly one capped stack bundle and persist the result snapshot", failures)
	presence_loadout.free()
	var summoning_growth := CandidateProgressionService.new()
	summoning_growth.configure(kasuha.growth_data)
	summoning_growth.select_branch(&"kasuha_mass_summoning")
	var summoning_modifiers := summoning_growth.merged_modifiers()
	_expect(bool(summoning_modifiers.get("candidate_summoning", false)) and int(summoning_modifiers.get("candidate_summon_count", 0)) == 8 and int(summoning_modifiers.get("candidate_summon_cap", 0)) == 8, "mass summoning must expose an explicit eight-creature request and simultaneous cap", failures)
	summoning_growth.claim_fixed_slot(2)
	var completed_summoning_modifiers := summoning_growth.merged_modifiers()
	_expect(float(completed_summoning_modifiers.get("core_skill_damage", 1.0)) > 1.0 and float(completed_summoning_modifiers.get("core_skill_range", 1.0)) > 1.0, "overdrive must strengthen both damage and search range after the active is replaced by mass summoning", failures)
	_expect(CandidateAbyssController.bounded_spawn_count(8, 8, 0) == 8 and CandidateAbyssController.bounded_spawn_count(8, 8, 6) == 2 and CandidateAbyssController.bounded_spawn_count(8, 8, 8) == 0, "the candidate summon controller must enforce its simultaneous cap for empty, partial, and full pools", failures)
	var irelai := campaign.candidate(&"irelai")
	_expect(irelai != null and irelai.growth_data != null and irelai.growth_data.get_validation_errors().is_empty(), "Irelai must expose two fixed milestones and exactly three necromancy-specialization branches", failures)
	var irelai_growth := CandidateProgressionService.new()
	irelai_growth.configure(irelai.growth_data)
	_expect(irelai_growth.claim_fixed_slot(0).id == &"irelai_employment_expansion" and irelai_growth.get_branch_upgrades().size() == 3 and irelai_growth.select_branch(&"irelai_soul_harvest") != null and irelai_growth.claim_fixed_slot(2).id == &"irelai_mass_reemployment", "Irelai boss milestones must resolve employment expansion, one necromancy branch, and mass reemployment in slot order", failures)
	var irelai_modifiers := irelai_growth.merged_modifiers()
	_expect(float(irelai_modifiers.get("spirit_duration", 1.0)) > 1.0 and int(irelai_modifiers.get("spirit_simultaneous_bonus", 0)) == 2 and float(irelai_modifiers.get("post_active_spirit_window", 0.0)) > 0.0 and float(irelai_modifiers.get("active_generated_spirit_damage", 1.0)) > 1.0, "Irelai fixed growth must extend spirit duration and capacity, then strengthen post-wave hiring and wave-generated spirits", failures)
	_expect(GameController.should_replace_irelai_basic_attack(DataRegistry.get_core(&"jade"), DataRegistry.get_core(&"jade"), true) and not GameController.should_replace_irelai_basic_attack(DataRegistry.get_core(&"jade"), DataRegistry.get_core(&"emerald"), true), "Irelai's active candidate core must replace every basic attack with a spirit request without affecting synthetic or other-core attacks", failures)
	var irelai_guard := DataRegistry.get_formation(&"jade_gambit")
	var expected_irelai_offsets := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(1, 3)]
	_expect(irelai_guard != null and irelai_guard.cells.size() == 6 and irelai_guard.get_bounds().size == Vector2i(2, 4) and irelai_guard.get_shape_errors().is_empty() and irelai_guard.cells.all(func(cell: FormationCellData) -> bool: return cell.offset in expected_irelai_offsets and cell.tower_id == &"jade_roulette"), "Irelai's resurrected guard must occupy the documented six cells while leaving both zero cells free", failures)
	_expect(irelai.guard_growth_data != null and irelai.guard_growth_data.get_validation_errors().is_empty() and irelai.guard_growth_data.specializations.map(func(entry: GuardSpecializationData) -> StringName: return entry.id) == [&"irelai_guard_fast_soul", &"irelai_guard_explosive_death", &"irelai_guard_death_curse"], "Irelai must expose Fast Soul, explosive inactivity, and three-generation death curse as exactly three valid guard branches", failures)
	var irelai_guard_growth := GuardProgressionService.new()
	irelai_guard_growth.configure(irelai.guard_growth_data)
	irelai_guard_growth.train()
	irelai_guard_growth.select_specialization(&"irelai_guard_death_curse")
	var irelai_guard_modifiers := irelai_guard_growth.merged_modifiers()
	_expect(bool(irelai_guard_modifiers.get("guard_death_curse", false)) and int(irelai_guard_modifiers.get("guard_death_curse_max_generation", 0)) == 3, "Irelai's death-curse branch must preserve the explicit I-to-II-to-III generation cap", failures)
	var irelai_guard_impacts := UpgradePresentationService.new().choice_impacts(UpgradeData.new().configure(&"guard_branch", "죽음의 저주", "", &"irelai_guard_death_curse"))
	_expect(irelai_guard_impacts.any(func(impact: Dictionary) -> bool: return impact.label == "저주 I→III") and irelai_guard_impacts.any(func(impact: Dictionary) -> bool: return impact.label == "사령 보장"), "Irelai guard cards must communicate the bounded curse lineage and guaranteed spirit outcome", failures)
	var soul_loadout := LoadoutManager.new()
	soul_loadout.candidate_progression.configure(irelai.growth_data)
	var soul_choice := soul_loadout.get_candidate_branch_choices().filter(func(choice: UpgradeData) -> bool: return choice.data_id == &"irelai_soul_harvest")[0] as UpgradeData
	_expect(soul_loadout.apply_candidate_branch(soul_choice), "Irelai's soul-harvest branch must apply through the candidate path", failures)
	for _soul_index in 350:
		soul_loadout.record_candidate_souls()
	_expect(soul_loadout.candidate_soul_stacks == 300 and int(soul_loadout.get_candidate_growth_snapshot().soul_stacks) == 300 and is_equal_approx(LoadoutManager.candidate_soul_effective_value(100), 100.0) and is_equal_approx(LoadoutManager.candidate_soul_effective_value(200), 150.0) and is_equal_approx(LoadoutManager.candidate_soul_effective_value(300), 175.0), "soul harvest must cap at 300 and apply high, medium, then low marginal efficiency across its three bands", failures)
	_expect(soul_loadout.consume_candidate_souls() == 300 and soul_loadout.candidate_soul_stacks == 0, "death wave must consume the entire bounded soul reserve exactly once", failures)
	soul_loadout.free()
	var irelai_death_growth := CandidateProgressionService.new()
	irelai_death_growth.configure(irelai.growth_data)
	irelai_death_growth.select_branch(&"irelai_death_dies")
	_expect(bool(irelai_death_growth.merged_modifiers().get("spirit_expiration_blast", false)) and float(irelai_death_growth.merged_modifiers().get("spirit_expiration_radius", 0.0)) > 0.0, "death itself must convert every completed spirit lifetime into a bounded area blast", failures)
	var irelai_fear_growth := CandidateProgressionService.new()
	irelai_fear_growth.configure(irelai.growth_data)
	irelai_fear_growth.select_branch(&"irelai_necrophobia")
	_expect(float(irelai_fear_growth.merged_modifiers().get("spirit_gain_chance_bonus", 0.0)) > 0.0 and bool(irelai_fear_growth.merged_modifiers().get("spirit_generation_fear", false)), "necrophobia must increase hiring chance and route generated spirits into the common fear contract", failures)
	var judaginda := campaign.candidate(&"judaginda")
	_expect(judaginda != null and judaginda.growth_data != null and judaginda.growth_data.get_validation_errors().is_empty(), "Judaginda must expose two fixed milestones and exactly three execution-specialization branches", failures)
	_expect(DataRegistry.get_core(&"obsidian").suppress_basic_attack_during_skill_cast, "Judaginda must become unable to perform basic attacks while summoning the Reaper", failures)
	var reaper_probe := ReaperSummon.new()
	reaper_probe.setup(Vector2.ZERO, Vector2(100.0, 80.0), Rect2(Vector2.ZERO, Vector2(500.0, 300.0)), Color("d94b56"), 1.0)
	var reaper_manifested := reaper_probe.is_casting()
	reaper_probe.strike(Vector2(120.0, 90.0))
	_expect(reaper_manifested and not reaper_probe.is_casting() and reaper_probe.strike_remaining > 0.0, "Judaginda's active must manifest a bounded Reaper node and transition it into one strike presentation", failures)
	reaper_probe.free()
	var judaginda_growth := CandidateProgressionService.new()
	judaginda_growth.configure(judaginda.growth_data)
	_expect(judaginda_growth.claim_fixed_slot(0).id == &"judaginda_doctrine" and judaginda_growth.get_branch_upgrades().size() == 3 and judaginda_growth.select_branch(&"judaginda_death_affinity") != null and judaginda_growth.claim_fixed_slot(2).id == &"judaginda_authority", "Judaginda boss milestones must resolve doctrine, one execution branch, and authority in slot order", failures)
	var judaginda_modifiers := judaginda_growth.merged_modifiers()
	_expect(float(judaginda_modifiers.get("execute_threshold_normal_multiplier", 1.0)) > float(judaginda_modifiers.get("execute_threshold_elite_multiplier", 1.0)) and float(judaginda_modifiers.get("execute_boss_damage_multiplier", 1.0)) > 1.0, "death-affinity growth must raise the normal threshold more than the elite threshold and strengthen boss execution damage", failures)
	var judaginda_guard := DataRegistry.get_formation(&"obsidian_tribunal")
	var guard_tower_ids: Array[StringName] = judaginda_guard.get_tower_ids() if judaginda_guard != null else []
	var guard_by_offset: Dictionary = {}
	if judaginda_guard != null:
		for guard_cell in judaginda_guard.cells:
			guard_by_offset[guard_cell.offset] = guard_cell.tower_id
	var all_judaginda_guard_units := guard_tower_ids.all(func(tower_id: StringName) -> bool:
		var tower := DataRegistry.get_tower(tower_id)
		return tower != null and tower.is_unique() and tower.unique_core_id == &"obsidian"
	)
	_expect(judaginda_guard != null and judaginda_guard.cells.size() == 4 and judaginda_guard.get_bounds().size == Vector2i(2, 2) and guard_tower_ids.count(&"obsidian_verdict") == 2 and guard_tower_ids.count(&"obsidian_inquisitor") == 2 and not &"execute" in guard_tower_ids, "Judaginda's execution guard must contain only two melee and two ranged Death Church guards", failures)
	_expect(guard_by_offset.get(Vector2i(0, 0)) == &"obsidian_inquisitor" and guard_by_offset.get(Vector2i(0, 1)) == &"obsidian_inquisitor" and guard_by_offset.get(Vector2i(1, 0)) == &"obsidian_verdict" and guard_by_offset.get(Vector2i(1, 1)) == &"obsidian_verdict", "Judaginda's ranged guards must occupy the rear column and melee judges the front column", failures)
	_expect(all_judaginda_guard_units, "every Judaginda formation cell must be an obsidian-exclusive Death Church guard", failures)
	_expect(judaginda.guard_growth_data != null and judaginda.guard_growth_data.get_validation_errors().is_empty() and judaginda.guard_growth_data.specializations.map(func(branch: GuardSpecializationData) -> StringName: return branch.id) == [&"judaginda_guard_martyrdom", &"judaginda_guard_sudden_death", &"judaginda_guard_reaper_ritual"], "Judaginda guard growth must expose martyrdom, sudden death, and reaper ritual as exactly three valid branches", failures)
	var martyr_loadout := LoadoutManager.new()
	martyr_loadout.guard_progression.configure(judaginda.guard_growth_data)
	martyr_loadout.guard_progression.train()
	martyr_loadout.guard_progression.select_specialization(&"judaginda_guard_martyrdom")
	var martyr_column := TowerColumn.new()
	martyr_column.formation_data = judaginda_guard
	martyr_column.is_guard_formation = true
	martyr_column.row_towers.append(DataRegistry.get_tower(&"obsidian_inquisitor"))
	martyr_column.row_disabled_remaining.append(0.0)
	var martyr_controller := JudagindaGuardController.new()
	var normal_execution_data := EnemyData.new()
	for _martyr_index in 35:
		martyr_controller.resolve_execution(martyr_column, 0, martyr_column.row_towers[0], normal_execution_data, martyr_loadout)
	_expect(is_equal_approx(martyr_loadout.get_guard_runtime_value(&"martyr"), 30.0) and is_equal_approx(martyr_loadout.get_guard_martyr_speed_multiplier(), 1.15) and is_equal_approx(martyr_loadout.get_core_attack_speed_multiplier(), 1.15) and martyr_column.is_row_disabled(0), "martyr executions must temporarily disable their source, share a candidate-and-guard speed bonus, and hard-cap at thirty stacks", failures)
	var martyr_snapshot_values := martyr_loadout.get_guard_growth_snapshot().runtime_values as Dictionary
	_expect(is_equal_approx(float(martyr_snapshot_values.get(&"martyr", martyr_snapshot_values.get("martyr", 0.0))), 30.0) and martyr_loadout.get_build_summary().contains("순교 30/30"), "martyr stacks must persist in the guard snapshot and remain visible in the build summary", failures)
	martyr_column.free()
	martyr_loadout.free()
	var elite_execution_data := EnemyData.new()
	elite_execution_data.is_elite = true
	var boss_execution_data := EnemyData.new()
	boss_execution_data.is_boss = true
	_expect(is_equal_approx(JudagindaGuardController.sudden_death_chance(normal_execution_data, 0.04, 0.25), 0.04) and is_equal_approx(JudagindaGuardController.sudden_death_chance(elite_execution_data, 0.04, 0.25), 0.01) and is_zero_approx(JudagindaGuardController.sudden_death_chance(boss_execution_data, 0.04, 0.25)), "sudden death must keep separate four-percent normal, one-percent elite, and zero-percent boss probabilities", failures)
	_expect(JudagindaGuardController.sudden_death_triggered(0.039, normal_execution_data, 0.04, 0.25) and not JudagindaGuardController.sudden_death_triggered(0.04, normal_execution_data, 0.04, 0.25), "sudden-death probability boundaries must be deterministic and half-open", failures)
	var ritual_loadout := LoadoutManager.new()
	ritual_loadout.guard_progression.configure(judaginda.guard_growth_data)
	ritual_loadout.guard_progression.train()
	ritual_loadout.guard_progression.select_specialization(&"judaginda_guard_reaper_ritual")
	var ritual_column := TowerColumn.new()
	ritual_column.formation_data = judaginda_guard
	ritual_column.is_guard_formation = true
	ritual_column.row_towers.append(DataRegistry.get_tower(&"obsidian_inquisitor"))
	var ritual_controller := JudagindaGuardController.new()
	var first_ritual := ritual_controller.resolve_execution(ritual_column, 0, ritual_column.row_towers[0], normal_execution_data, ritual_loadout)
	var blocked_ritual := ritual_controller.resolve_execution(ritual_column, 0, ritual_column.row_towers[0], elite_execution_data, ritual_loadout)
	ritual_controller.update(0.61)
	var elite_ritual := ritual_controller.resolve_execution(ritual_column, 0, ritual_column.row_towers[0], elite_execution_data, ritual_loadout)
	_expect(is_equal_approx(float(first_ritual.skill_charge), 1.0) and is_zero_approx(float(blocked_ritual.skill_charge)) and is_equal_approx(float(elite_ritual.skill_charge), 2.5), "reaper ritual must grant tiered active charge and enforce its short internal cooldown across mass executions", failures)
	var judaginda_guard_impacts := UpgradePresentationService.new().choice_impacts(UpgradeData.new().configure(&"guard_branch", "갑작스런 죽음", "", &"judaginda_guard_sudden_death"))
	_expect(judaginda_guard_impacts.any(func(impact: Dictionary) -> bool: return impact.label == "확률 즉사") and judaginda_guard_impacts.any(func(impact: Dictionary) -> bool: return impact.label == "공식 난입 제외"), "Judaginda guard cards must explicitly communicate probabilistic execution and official-intrusion exclusion", failures)
	ritual_column.free()
	ritual_loadout.free()
	var execution_growth_loadout := LoadoutManager.new()
	execution_growth_loadout.core_state = GrowthTrackState.new(&"obsidian")
	execution_growth_loadout.cursor_state = GrowthTrackState.new(&"vanguard")
	execution_growth_loadout.candidate_progression.configure(judaginda.growth_data)
	var advance_choice := execution_growth_loadout.get_candidate_branch_choices().filter(func(choice: UpgradeData) -> bool: return choice.data_id == &"judaginda_advance")[0] as UpgradeData
	_expect(execution_growth_loadout.apply_candidate_branch(advance_choice), "Judaginda's execution-growth branch must apply through the candidate path", failures)
	var penalized_damage := execution_growth_loadout.get_core_damage_multiplier()
	for _execution_index in 45:
		execution_growth_loadout.record_candidate_execution()
	_expect(execution_growth_loadout.candidate_execution_stacks == 40 and is_equal_approx(execution_growth_loadout.get_candidate_execution_damage_multiplier(), 1.4) and execution_growth_loadout.get_core_damage_multiplier() > penalized_damage, "execution growth must add one percent per success, stop at forty stacks, and persist in the candidate snapshot", failures)
	_expect(int(execution_growth_loadout.get_candidate_growth_snapshot().execution_stacks) == 40, "run result snapshots must retain Judaginda's runtime execution stacks", failures)
	execution_growth_loadout.free()
	var stage := ConceptService.get_default_stage()
	var plan := CampaignStageResolver.resolve(stage, DataRegistry.bosses, campaign, &"emerald", &"iron", 8307)
	var rival_ids: Array[String] = []
	for index in plan.slots.size():
		var faction := campaign.faction(plan.faction_id_at(index))
		rival_ids.append(String(faction.candidate_id))

	var full_result := {
		"run_id": "candidate-support-full", "candidate_id": "partason", "retainer_id": "kanda",
		"support_required_for_election": 1000, "rival_candidate_ids": rival_ids,
		"candidate_decree_ids_available": ["royal_barrier", "orthodox_army", "royal_command"],
		"decree_id": "", "decree_name": "",
		"stage_id": String(stage.id), "stage_duration_seconds": 600.0, "elapsed": 600.0,
		"victory": true, "challenge_level": 0, "level": 18,
		"boss_kill_ids": plan.slots.map(func(slot: Dictionary) -> String: return String(slot.boss_id)),
		"boss_plan": plan.to_snapshot(), "meta_metrics": {}, "eligible_for_meta_rewards": true,
	}
	var full_support := CandidateSupportCalculator.calculate(full_result)
	_expect(int(full_support.total_support) == 95 and int(full_support.progress_support) == 60 and int(full_support.boss_support) == 20, "a complete campaign must grant the documented 60 progress, 20 rival, and 15 victory support", failures)
	var early_result := full_result.duplicate(true)
	early_result.elapsed = 120.0
	early_result.victory = false
	early_result.boss_kill_ids = []
	var late_result := full_result.duplicate(true)
	late_result.elapsed = 600.0
	late_result.victory = false
	late_result.boss_kill_ids = (full_result.boss_kill_ids as Array).slice(0, 3)
	var early_support := CandidateSupportCalculator.calculate(early_result)
	var late_support := CandidateSupportCalculator.calculate(late_result)
	_expect(float(early_support.total_support) / 2.0 < float(late_support.total_support) / 10.0 and int(late_support.total_support) == 75, "early failure loops must earn less support per minute than reaching the final rival", failures)
	var elected_victory := full_result.duplicate(true)
	elected_victory.candidate_elected = true
	elected_victory.challenge_level = 4
	var victory_governance := GovernanceApprovalCalculator.calculate(elected_victory, 50)
	var early_governance := GovernanceApprovalCalculator.calculate(early_result.merged({"candidate_elected": true}, true), 50)
	var late_governance := GovernanceApprovalCalculator.calculate(late_result.merged({"candidate_elected": true}, true), 50)
	var unelected_governance := GovernanceApprovalCalculator.calculate(full_result, 0)
	_expect(int(victory_governance.approval_delta) == 10 and int(victory_governance.approval_after) == 60, "an elected candidate victory must grant eight approval plus one per two challenge levels", failures)
	_expect(int(early_governance.approval_delta) == -8 and int(late_governance.approval_delta) == -1, "defeat approval loss must scale with missing progress while defeated bosses mitigate but never erase the loss", failures)
	_expect(not bool(unelected_governance.eligible) and int(unelected_governance.approval_delta) == 0, "campaign runs before election must not change governance approval", failures)

	SaveManager.candidate_support = {"partason": 930, "kasuha": 25}
	SaveManager.elected_candidate_ids.clear()
	SaveManager.candidate_decree_ids.clear()
	SaveManager.governance_approval.clear()
	SaveManager.candidate_clear_records.clear()
	SaveManager.candidate_rival_records.clear()
	SaveManager.settled_run_ids.clear()
	var progression := MetaProgressionService.calculate_candidate_progression(full_result)
	var settlement_breakdown := {
		"total_funds": 0, "stage_first_reward_id": "", "challenge_first_reward_id": "",
		"achievement_actions": {}, "candidate_progression": progression,
	}
	var settled := SaveManager._apply_run_settlement_in_memory(full_result, settlement_breakdown)
	var duplicate := SaveManager._apply_run_settlement_in_memory(full_result, settlement_breakdown)
	_expect(settled and not duplicate and SaveManager.get_candidate_support(&"partason") == 1000 and SaveManager.is_candidate_elected(&"partason"), "support settlement must cap at the threshold and elect a candidate exactly once under the run id transaction", failures)
	_expect(SaveManager.get_candidate_decree(&"partason") == &"royal_barrier", "first election must grant the candidate's default decree inside the same settlement transaction", failures)
	_expect(SaveManager.get_governance_approval(&"partason") == 50 and campaign.governance_reaction(SaveManager.get_governance_approval(&"partason")).id == &"neutral", "first election must initialize the candidate at the neutral governance tier", failures)
	_expect(SaveManager._apply_candidate_decree_selection_in_memory(&"partason", &"orthodox_army", campaign.candidate(&"partason").decree_ids) and SaveManager.get_candidate_decree(&"partason") == &"orthodox_army", "an elected candidate must be able to switch among only its own three decrees", failures)
	_expect(not SaveManager._apply_candidate_decree_selection_in_memory(&"partason", &"charmed_march", campaign.candidate(&"partason").decree_ids), "a candidate must reject another candidate's decree", failures)
	var decree_loadout := LoadoutManager.new()
	decree_loadout.active_decree = campaign.decree(&"orthodox_army")
	_expect(is_equal_approx(decree_loadout.get_tower_damage_multiplier(), 1.15) and is_equal_approx(decree_loadout.get_core_skill_damage_multiplier(), 0.85), "decree runtime multipliers must apply both their declared benefit and tradeoff", failures)
	decree_loadout.free()
	_expect(SaveManager.get_candidate_support(&"kasuha") == 25 and int((SaveManager.candidate_clear_records.partason as Dictionary).runs) == 1, "candidate support and run records must remain isolated per candidate", failures)
	var rival_record: Dictionary = SaveManager.candidate_rival_records.get("partason", {})
	_expect(rival_ids.all(func(id: String) -> bool: return int(rival_record.get(id, 0)) == 1), "defeated rival records must be credited to the selected candidate once", failures)
	var governance_result := elected_victory.duplicate(true)
	governance_result.run_id = "candidate-governance-victory"
	var governance_breakdown := {
		"total_funds": 0, "stage_first_reward_id": "", "challenge_first_reward_id": "",
		"achievement_actions": {}, "candidate_progression": MetaProgressionService.calculate_candidate_progression(governance_result),
		"governance_progression": MetaProgressionService.calculate_governance_progression(governance_result),
	}
	var governance_settled := SaveManager._apply_run_settlement_in_memory(governance_result, governance_breakdown)
	var governance_duplicate := SaveManager._apply_run_settlement_in_memory(governance_result, governance_breakdown)
	_expect(governance_settled and not governance_duplicate and SaveManager.get_governance_approval(&"partason") == 60, "governance approval must settle once inside the same idempotent run transaction", failures)

	var migrated_v6 := SaveManager._normalize_save_data({"meta_progression_version": 6, "total_runs": 4, "unlocked_ids": ["emerald", "iron"], "legacy_full_unlock": false})
	_expect(int(migrated_v6.meta_progression_version) == 14 and not bool(migrated_v6.legacy_full_unlock) and "rubber_golem" in migrated_v6.unlocked_tower_ids and (migrated_v6.candidate_support as Dictionary).is_empty(), "v6 saves must migrate to v14 defaults without being mistaken for pre-meta full-unlock saves", failures)
	var valid_v14 := SaveManager._build_save_data()
	_expect(not SaveManager._validate_save_dictionary(valid_v14).is_empty(), "a complete v14 save with candidate progression, tutorial, and encounter fields must validate", failures)
	var invalid_support := valid_v14.duplicate(true)
	invalid_support.candidate_support = {"partason": "corrupt"}
	var invalid_decree := valid_v14.duplicate(true)
	invalid_decree.candidate_decree_ids = {"partason": 7}
	var invalid_approval := valid_v14.duplicate(true)
	invalid_approval.governance_approval = {"partason": 101}
	_expect(SaveManager._validate_save_dictionary(invalid_support).is_empty() and SaveManager._validate_save_dictionary(invalid_decree).is_empty() and SaveManager._validate_save_dictionary(invalid_approval).is_empty(), "v14 validation must reject damaged support, decree, and governance field types or ranges", failures)

	var checkpoint_result := full_result.duplicate(true)
	checkpoint_result.run_id = "candidate-v3-checkpoint"
	checkpoint_result.candidate_elected = true
	checkpoint_result.governance_approval = 50
	var checkpoint := {"version": 3, "run_id": "candidate-v3-checkpoint", "confirmed": true, "updated_unix": 1, "result": checkpoint_result}
	_expect(not RunCheckpointService._validate_checkpoint(checkpoint).is_empty(), "v3 checkpoints must preserve candidate, retainer, rival, and boss plan identity for recovery settlement", failures)
	var missing_identity := checkpoint.duplicate(true)
	missing_identity.result.erase("candidate_id")
	_expect(RunCheckpointService._validate_checkpoint(missing_identity).is_empty(), "v3 campaign checkpoints must reject missing candidate identity", failures)
	var damaged_governance := checkpoint.duplicate(true)
	damaged_governance.result.governance_approval = 140
	_expect(RunCheckpointService._validate_checkpoint(damaged_governance).is_empty(), "v3 campaign checkpoints must reject an out-of-range governance snapshot", failures)

	SaveManager._apply_save_data(save_backup)
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)

static func _candidate_ids(campaign: ElectionCampaignData) -> Dictionary:
	var result: Dictionary = {}
	for candidate in campaign.candidates:
		if candidate != null:
			result[candidate.id] = true
	return result
