class_name ModularizationContractTest
extends RefCounted

class ContractContext:
	extends RefCounted
	var loadout: LoadoutManager
	var offer_service: UpgradeOfferService
	var burn: Dictionary = {}
	var presentation: UpgradePresentationService
	var targeting: TargetingService
	var charm_stage: CandidateCharmStageController
	var charm_profile: CharmProfileData
	var precision_enemy_data: EnemyData

const DOMAIN_ORDER: Array[StringName] = [
	&"spirit_and_candidate_policy",
	&"attack_execution",
	&"skeleton_and_branch",
	&"tactics_cursor_and_counter",
	&"core_execution_and_presentation",
	&"phase_offer_and_startup",
	&"shutdown_and_cleanup",
]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var context := _run_foundation_contracts(failures)
	for domain in DOMAIN_ORDER:
		_run_domain_contracts(domain, context, failures)
	return failures

static func run_domain(domain: StringName) -> Array[String]:
	var failures: Array[String] = []
	var context := _run_foundation_contracts(failures)
	if domain != &"foundation":
		_run_domain_contracts(domain, context, failures)
	if domain != &"shutdown_and_cleanup" and is_instance_valid(context.loadout):
		context.loadout.free()
	return failures

static func _run_domain_contracts(domain: StringName, context: ContractContext, failures: Array[String]) -> void:
	match domain:
		&"spirit_and_candidate_policy": _run_spirit_and_candidate_policy_contracts(context, failures)
		&"attack_execution": _run_attack_execution_contracts(context, failures)
		&"skeleton_and_branch": _run_skeleton_and_branch_contracts(context, failures)
		&"tactics_cursor_and_counter": _run_tactics_cursor_and_counter_contracts(context, failures)
		&"core_execution_and_presentation": _run_core_execution_and_presentation_contracts(context, failures)
		&"phase_offer_and_startup": _run_phase_offer_and_startup_contracts(context, failures)
		&"shutdown_and_cleanup": _run_shutdown_and_cleanup_contracts(context, failures)
		_: _expect(false, "unknown modularization contract domain: %s" % domain, failures)

static func _run_foundation_contracts(failures: Array[String]) -> ContractContext:
	var loadout := LoadoutManager.new()
	loadout.core_state.current_level = 3
	loadout.cursor_state.current_level = 5
	loadout.global_upgrade_level = 2
	var tower_damage := loadout.get_tower_damage_multiplier()
	var core_health := loadout.get_core_health_multiplier()
	var cursor_movement := loadout.get_cursor_movement_speed_multiplier()
	_expect(is_equal_approx(tower_damage, 1.0), "legacy global-upgrade levels must not alter the no-artifact tower baseline", failures)
	_expect(is_equal_approx(core_health, 1.45), "loadout stat facade must preserve the core durability curve", failures)
	_expect(is_equal_approx(cursor_movement, 1.50), "loadout stat facade must preserve the cursor movement curve", failures)

	var upgrade_service := LoadoutUpgradeApplicationService.new()
	var contract_tower_levels := {&"rapid": 1}
	var contract_tower_branches := {}
	var contract_core := GrowthTrackState.new(&"emerald")
	var contract_cursor := GrowthTrackState.new(&"iron")
	var contract_effects := {}
	var contract_status_levels := {&"poison": 0, &"burn": 0, &"bleed": 0, &"shock": 0}
	var upgrade_state := {
		"tower_type_levels": contract_tower_levels,
		"tower_branch_ids": contract_tower_branches,
		"core_state": contract_core,
		"cursor_state": contract_cursor,
		"guard_progression": GuardProgressionService.new(),
		"global_upgrade_level": 0,
		"selected_global_effects": contract_effects,
		"status_upgrade_levels": contract_status_levels,
	}
	var tower_growth_result := upgrade_service.apply(UpgradeData.new().configure(&"tower_type_level", "rapid 2", "", &"rapid"), upgrade_state, false)
	_expect(bool(tower_growth_result.handled) and bool(tower_growth_result.applied) and int(contract_tower_levels[&"rapid"]) == 2, "upgrade application service must own valid shared tower-level transitions", failures)
	var blocked_core_result := upgrade_service.apply(UpgradeData.new().configure(&"core_level", "blocked", "", &"emerald"), upgrade_state, true)
	_expect(bool(blocked_core_result.handled) and not bool(blocked_core_result.applied) and contract_core.current_level == 1, "candidate runs must reject the removed ordinary core-level path inside the application boundary", failures)
	var cursor_growth_result := upgrade_service.apply(UpgradeData.new().configure(&"cursor_level", "cursor 2", "", &"iron"), upgrade_state, true)
	_expect(bool(cursor_growth_result.applied) and contract_cursor.current_level == 2, "candidate runs must retain ordinary target-cursor growth", failures)
	var global_growth_result := upgrade_service.apply(UpgradeData.new().configure(&"global_upgrade", "global", "effect", &"global"), upgrade_state, false)
	_expect(not bool(global_growth_result.handled) and not bool(global_growth_result.applied) and int(global_growth_result.global_upgrade_level) == 0 and contract_effects.is_empty(), "retired global growth must be rejected while preserving the legacy read field", failures)
	var status_growth_result := upgrade_service.apply(UpgradeData.new().configure(&"status_upgrade", "burn 1", "effect", &"burn"), upgrade_state, false)
	contract_status_levels[&"burn"] = 7
	var capped_status_result := upgrade_service.apply(UpgradeData.new().configure(&"status_upgrade", "burn 8", "effect", &"burn"), upgrade_state, false)
	_expect(bool(status_growth_result.applied) and int((contract_effects[&"burn"] as Dictionary).level) == 1 and not bool(capped_status_result.applied), "status growth must update its summary and reject levels beyond the GDD cap of seven", failures)

	var offer_service := UpgradeOfferService.new()
	var signature_a: Array[UpgradeData] = [
		UpgradeData.new().configure(&"global_upgrade", "global", "", &"global"),
		UpgradeData.new().configure(&"cursor_level", "cursor", "", &"iron"),
	]
	var signature_b: Array[UpgradeData] = [signature_a[1], signature_a[0]]
	_expect(offer_service.signature(signature_a) == offer_service.signature(signature_b), "upgrade offer signatures must remain stable when card display order changes", failures)
	var diversity_offer_service := UpgradeOfferService.new(0.0, 99, 0.0, 99)
	diversity_offer_service.configure(
		func() -> UpgradeData: return UpgradeData.new().configure(&"tower_type_level", "rapid", "", &"rapid"),
		func() -> UpgradeData: return UpgradeData.new().configure(&"core_level", "core", "", &"emerald"),
		func() -> UpgradeData: return null,
		func(excluded_keys: Dictionary) -> UpgradeData:
			var repeated_core := UpgradeData.new().configure(&"core_level", "core", "", &"emerald")
			if not excluded_keys.has(UpgradeOfferService.choice_key(repeated_core)):
				return repeated_core
			return UpgradeData.new().configure(&"cursor_level", "cursor", "", &"iron"),
		func() -> Array[UpgradeData]: return [] as Array[UpgradeData],
		func() -> UpgradeData: return null
	)
	var diversity_choices := diversity_offer_service.generate(FormationBoardState.new(6, 4), [] as Array[TowerFormationData], 0)
	_expect(diversity_choices.size() == UpgradeOfferService.DISPLAY_CHOICE_COUNT and not UpgradeOfferService.has_duplicate_choices(diversity_choices) and diversity_choices.any(func(choice: UpgradeData) -> bool: return choice.category == &"cursor_level"), "level-up offers must exclude an already visible stable card ID and use another eligible reward", failures)
	var initial_formation_offer_service := UpgradeOfferService.new(0.0, 99, 0.0, 99)
	initial_formation_offer_service.configure(
		func() -> UpgradeData: return null,
		func() -> UpgradeData: return UpgradeData.new().configure(&"cursor_level", "retainer", "", &"iron"),
		func() -> UpgradeData: return null,
		func(_excluded_keys: Dictionary) -> UpgradeData: return null,
		func() -> Array[UpgradeData]: return [] as Array[UpgradeData],
		func() -> UpgradeData: return UpgradeData.new().configure(&"guard_training", "guard", "", &"emerald_guard")
	)
	var initial_formation_pool: Array[TowerFormationData] = []
	initial_formation_pool.assign(DataRegistry.formations.filter(func(formation: TowerFormationData) -> bool: return not formation.is_unique()))
	var initial_progression_state := RunRng.progression_rng.state
	RunRng.progression_rng.seed = 9042026
	var initial_formation_choices := initial_formation_offer_service.generate(FormationBoardState.new(6, 4), initial_formation_pool, 0)
	RunRng.progression_rng.state = initial_progression_state
	var initial_formation_cards := initial_formation_choices.filter(func(choice: UpgradeData) -> bool: return choice.category == &"formation_set")
	var required_initial_cards := initial_formation_cards.filter(func(choice: UpgradeData) -> bool: return bool(choice.offer_metadata.get(UpgradeOfferService.REQUIRED_INITIAL_FORMATION_META, false)))
	var optional_initial_cards := initial_formation_cards.filter(func(choice: UpgradeData) -> bool: return bool(choice.offer_metadata.get(UpgradeOfferService.OPTIONAL_INITIAL_FORMATION_META, false)))
	_expect(initial_formation_choices.size() == UpgradeOfferService.DISPLAY_CHOICE_COUNT and initial_formation_cards.size() == 2 and required_initial_cards.size() == 1 and optional_initial_cards.size() == 1 and initial_formation_cards[0].data_id != initial_formation_cards[1].data_id and not UpgradeOfferService.has_duplicate_choices(initial_formation_choices), "an initial sparse offer must keep retainer growth and fill its last slot with one different-size optional formation without exact duplicates", failures)
	var required_policy_card := UpgradeData.new().configure(&"formation_set", "required", "", &"size_2")
	required_policy_card.offer_metadata[UpgradeOfferService.REQUIRED_INITIAL_FORMATION_META] = true
	var optional_policy_card := UpgradeData.new().configure(&"formation_set", "optional", "", &"size_3")
	optional_policy_card.offer_metadata[UpgradeOfferService.OPTIONAL_INITIAL_FORMATION_META] = true
	var protected_initial_choices: Array[UpgradeData] = [
		required_policy_card,
		UpgradeData.new().configure(&"cursor_level", "retainer", "", &"iron"),
		optional_policy_card,
	]
	SpecializationOfferPolicy.new(1.0, 2).inject(protected_initial_choices, [UpgradeData.new().configure(&"guard_training", "guard", "", &"emerald_guard")] as Array[UpgradeData], true)
	_expect(protected_initial_choices[0] == required_policy_card and protected_initial_choices[1].category == &"cursor_level" and protected_initial_choices[2].category == &"guard_training", "guard injection must preserve only the marked required formation and may replace the optional initial formation", failures)
	var policy_fill_offer_service := UpgradeOfferService.new(0.0, 99, 0.0, 99)
	policy_fill_offer_service.configure(
		func() -> UpgradeData: return null,
		func() -> UpgradeData: return UpgradeData.new().configure(&"cursor_level", "cursor", "", &"iron"),
		func() -> UpgradeData: return null,
		func(_excluded_keys: Dictionary) -> UpgradeData: return null,
		func() -> Array[UpgradeData]: return [UpgradeData.new().configure(&"tower_specialization_entry", "rapid branch", "", &"rapid")] as Array[UpgradeData],
		func() -> UpgradeData: return UpgradeData.new().configure(&"guard_training", "guard", "", &"emerald_guard")
	)
	var policy_fill_choices := policy_fill_offer_service.generate(FormationBoardState.new(6, 4), [] as Array[TowerFormationData], 0)
	_expect(policy_fill_choices.size() == UpgradeOfferService.DISPLAY_CHOICE_COUNT and not UpgradeOfferService.has_duplicate_choices(policy_fill_choices) and policy_fill_choices.any(func(choice: UpgradeData) -> bool: return choice.category == &"tower_specialization_entry") and policy_fill_choices.any(func(choice: UpgradeData) -> bool: return choice.category == &"guard_training"), "eligible specialization and guard rewards must fill open level-up slots before any duplicate fallback", failures)
	var duplicate_fallback_offer_service := UpgradeOfferService.new(0.0, 99, 0.0, 99)
	duplicate_fallback_offer_service.configure(
		func() -> UpgradeData: return null,
		func() -> UpgradeData: return UpgradeData.new().configure(&"cursor_level", "cursor", "", &"iron"),
		func() -> UpgradeData: return null,
		func(_excluded_keys: Dictionary) -> UpgradeData: return null,
		func() -> Array[UpgradeData]: return [] as Array[UpgradeData],
		func() -> UpgradeData: return UpgradeData.new().configure(&"guard_training", "guard", "", &"emerald_guard")
	)
	var duplicate_fallback_choices := duplicate_fallback_offer_service.generate(FormationBoardState.new(6, 4), [] as Array[TowerFormationData], 0)
	_expect(duplicate_fallback_choices.size() == UpgradeOfferService.DISPLAY_CHOICE_COUNT and UpgradeOfferService.has_duplicate_choices(duplicate_fallback_choices) and duplicate_fallback_choices.any(func(choice: UpgradeData) -> bool: return choice.category == &"guard_training") and duplicate_fallback_choices.any(func(choice: UpgradeData) -> bool: return bool(choice.offer_metadata.get(&"duplicate_fallback", false))), "level-up offers must keep every distinct eligible reward before duplicating a marked valid card to guarantee three slots", failures)
	offer_service.specialization_policy.offer_misses = 2
	offer_service.specialization_policy.entry_waits = {&"tower_specialization_entry:rapid": 3}
	offer_service.guard_growth_policy.offer_misses = 1
	var offer_snapshot := offer_service.get_state_snapshot()
	offer_service.specialization_policy.offer_misses = 0
	offer_service.specialization_policy.entry_waits.clear()
	offer_service.guard_growth_policy.offer_misses = 0
	offer_service.restore_state(offer_snapshot)
	_expect(offer_service.specialization_policy.offer_misses == 2 and int(offer_service.specialization_policy.entry_waits.get(&"tower_specialization_entry:rapid", 0)) == 3 and offer_service.guard_growth_policy.offer_misses == 1, "reroll offer state snapshots must restore specialization and guard-growth pity atomically", failures)

	var burn := CommonStatusCatalog.profile_at_level(&"burn", 4)
	var bleed_supported := CommonStatusCatalog.tower_supports(DataRegistry.get_tower(&"knockback"), &"bleed")
	_expect(int(burn.max_stacks) == 2 and is_equal_approx(float(burn.damage_ratio), 0.16), "common status catalog must own milestone tuning data", failures)
	_expect(bleed_supported and CommonStatusCatalog.branch_supports({"lightning_damage": 0.2}, &"shock"), "common status catalog must own tower and branch eligibility rules", failures)

	var presentation := UpgradePresentationService.new()
	var category := presentation.category_presentation(&"tower_branch")
	var branch_choice := UpgradeData.new().configure(&"tower_branch", "test", "test", &"rapid_burn")
	_expect(String(category.badge).contains("Lv.4") and presentation.choice_tower_id(branch_choice) == &"rapid", "upgrade presentation service must resolve card category and tower ownership", failures)
	_expect(presentation.tower_icon_name(&"unique_random") == "★망자출격" and presentation.tower_target_rule(&"density").contains("밀집도"), "upgrade presentation service must own concise role and target labels", failures)
	var boss_presentation := BossPresentationService.new()
	var generic_boss := EnemyData.new()
	generic_boss.id = &"contract_boss"
	generic_boss.display_name = "계약 보스"
	generic_boss.body_color = Color("7a5de8")
	var generic_boss_result := boss_presentation.compose(generic_boss)
	_expect(String(generic_boss_result.name).contains(generic_boss.display_name) and generic_boss_result.candidate == generic_boss.display_name and generic_boss_result.faction == ConceptService.term(&"enemy"), "boss presentation must preserve localized generic-concept fallbacks without campaign identity", failures)
	_expect(generic_boss_result.color == generic_boss.body_color and generic_boss_result.primary_color == generic_boss.body_color and generic_boss_result.secondary_color == generic_boss.body_color.lightened(0.3) and StringName(generic_boss_result.marker_style) == &"", "generic boss presentation must derive its full palette from the enemy body color and omit faction markers", failures)
	var election_campaign := ConceptService.get_election_campaign()
	var election_faction := election_campaign.factions[0] as ElectionFactionData
	var election_boss := DataRegistry.find_enemy(election_faction.boss_ids[0])
	var election_candidate := election_campaign.candidate(election_faction.candidate_id)
	var election_boss_result := boss_presentation.compose(election_boss, election_campaign, election_faction)
	_expect(election_boss_result.candidate == election_candidate.short_name and election_boss_result.faction == election_faction.display_name and String(election_boss_result.name).contains(election_candidate.short_name) and String(election_boss_result.name).contains(election_faction.display_name), "campaign boss presentation must resolve candidate and faction identity into the localized HUD name", failures)
	_expect(election_boss_result.color == election_faction.accent_color and election_boss_result.primary_color == election_faction.primary_color and election_boss_result.secondary_color == election_faction.secondary_color and StringName(election_boss_result.marker_style) == election_faction.active_marker_style(), "campaign boss presentation must use the faction accent, semantic marker, and primary/secondary palette", failures)
	var inferred_candidate_result := boss_presentation.compose(election_boss, election_campaign)
	_expect(inferred_candidate_result.candidate == election_candidate.short_name and inferred_candidate_result.faction == ConceptService.term(&"enemy") and inferred_candidate_result.color == election_boss.body_color, "campaign candidate lookup without a resolved faction must retain generic faction colors and labels", failures)
	var election_warning := boss_presentation.warning_text(election_boss, election_boss_result, 0.23)
	_expect(election_warning.contains("Y23") and election_warning.contains(election_candidate.short_name) and election_warning.contains(election_faction.display_name), "boss warning presentation must preserve rounded two-digit position and campaign identity replacements", failures)
	_expect(boss_presentation.compose(null).is_empty() and boss_presentation.warning_text(null, {}, 0.5).is_empty(), "boss presentation must reject missing boss data without constructing partial HUD state", failures)
	var targeting := TargetingService.new()
	var chain_a := _active_enemy_at(Vector2(0.0, 0.0))
	var chain_b := _active_enemy_at(Vector2(50.0, 0.0))
	var chain_c := _active_enemy_at(Vector2(110.0, 0.0))
	var chain_far := _active_enemy_at(Vector2(400.0, 0.0))
	var chain_pool: Array[Enemy] = [chain_a, chain_b, chain_c, chain_far]
	_expect(targeting.closest_other(chain_pool, chain_a, 100.0) == chain_b, "targeting service must own nearest secondary-target selection", failures)
	_expect(targeting.build_chain(chain_pool, chain_a, 3, 80.0) == [chain_a, chain_b, chain_c], "targeting service must own bounded chain-target traversal", failures)
	chain_b.active = false
	_expect(targeting.closest_other(chain_pool, chain_a, 100.0) == null, "targeting service must exclude inactive secondary targets", failures)
	for enemy in chain_pool:
		enemy.free()

	var charm_stage := CandidateCharmStageController.new()
	var charm_profile := CharmProfileData.new()
	charm_profile.active_zone_duration = 6.0
	var base_stage_duration := charm_stage.activate(loadout, charm_profile, 1.25, false)
	_expect(is_equal_approx(base_stage_duration, 7.25) and not loadout.candidate_stage_buff_active, "candidate charm controller must own the base zone duration without leaking the branch buff", failures)
	var no_enemies: Array[Enemy] = []
	var base_stage_result := charm_stage.update(base_stage_duration, loadout, no_enemies)
	_expect(bool(base_stage_result.ended) and charm_stage.profile == null, "candidate charm controller must close and clear an expired base zone", failures)
	var branch_stage_duration := charm_stage.activate(loadout, charm_profile, 0.0, true)
	_expect(branch_stage_duration >= 6.0 and loadout.candidate_stage_buff_active, "candidate charm controller must activate the branch-only army buff with the stage", failures)
	var branch_stage_result := charm_stage.update(branch_stage_duration, loadout, no_enemies)
	_expect(bool(branch_stage_result.ended_with_stage_buff) and not loadout.candidate_stage_buff_active, "candidate charm controller must release the army buff when the stage ends", failures)
	var candidate_charm_core := CoreData.new()
	candidate_charm_core.charm_profile = CharmProfileData.new()
	candidate_charm_core.charm_profile.duration = 0.9
	candidate_charm_core.charm_profile.active_zone_duration = 5.0
	var candidate_charm_activation_events: Array[String] = []
	var candidate_charm_activation := charm_stage.activate_candidate_skill(
		candidate_charm_core,
		true,
		loadout,
		func(callback_columns: Array[TowerColumn], callback_loadout: LoadoutManager, base_duration: float) -> Dictionary:
			candidate_charm_activation_events.append("consume:%d:%s:%.1f" % [callback_columns.size(), str(callback_loadout == loadout), base_duration])
			return {"consumed_stacks": 4, "extension": 0.8, "disabled_duration": base_duration + 0.8},
		func(devotion_result: Dictionary) -> void:
			candidate_charm_activation_events.append("settle:%d:%.1f:%s" % [int(devotion_result.consumed_stacks), float(devotion_result.extension), str(loadout.candidate_stage_buff_active)])
	)
	_expect(bool(candidate_charm_activation.applied) and is_equal_approx(float(candidate_charm_activation.base_charm_duration), 6.0) and is_equal_approx(float(candidate_charm_activation.extension), 0.8) and is_equal_approx(float(candidate_charm_activation.disabled_duration), 6.8), "candidate charm skill activation must select the branch-stage duration before consuming guard devotion", failures)
	_expect(is_equal_approx(float(candidate_charm_activation.stage_duration), 5.8) and is_equal_approx(charm_stage.remaining, 5.8) and loadout.candidate_stage_buff_active and candidate_charm_activation_events == ["consume:0:true:6.0", "settle:4:0.8:false"], "candidate charm skill activation must settle devotion before activating the profile-duration stage buff with its extension", failures)
	charm_stage.update(float(candidate_charm_activation.stage_duration), loadout, no_enemies)
	var base_candidate_charm_activation := charm_stage.activate_candidate_skill(
		candidate_charm_core,
		false,
		loadout,
		func(_columns: Array[TowerColumn], _callback_loadout: LoadoutManager, base_duration: float) -> Dictionary:
			return {"consumed_stacks": 0, "extension": 0.0, "disabled_duration": base_duration}
	)
	_expect(is_equal_approx(float(base_candidate_charm_activation.base_charm_duration), 0.9) and is_equal_approx(float(base_candidate_charm_activation.stage_duration), 5.0) and not loadout.candidate_stage_buff_active, "base candidate charm activation must use hit-charm duration for devotion while retaining the profile zone duration", failures)
	charm_stage.update(float(base_candidate_charm_activation.stage_duration), loadout, no_enemies)
	var charm_echo_service := CandidateCharmEchoService.new()
	var charm_echo_normal_data := EnemyData.new()
	charm_echo_normal_data.max_health = 100.0
	var charm_echo_boss_data := EnemyData.new()
	charm_echo_boss_data.max_health = 100.0
	charm_echo_boss_data.is_boss = true
	var charm_echo_position := Vector2(100.0, 100.0)
	var charm_echo_same_position := _active_enemy_at(charm_echo_position)
	var charm_echo_inactive := _active_enemy_at(charm_echo_position + Vector2(10.0, 0.0))
	var charm_echo_boss := _active_enemy_at(charm_echo_position + Vector2(20.0, 0.0))
	var charm_echo_first := _active_enemy_at(charm_echo_position + Vector2(30.0, 0.0))
	var charm_echo_blocked := _active_enemy_at(charm_echo_position + Vector2(40.0, 0.0))
	var charm_echo_second := _active_enemy_at(charm_echo_position + Vector2(50.0, 0.0))
	var charm_echo_third := _active_enemy_at(charm_echo_position + Vector2(60.0, 0.0))
	var charm_echo_overflow := _active_enemy_at(charm_echo_position + Vector2(70.0, 0.0))
	var charm_echo_targets: Array[Enemy] = [charm_echo_same_position, charm_echo_inactive, charm_echo_boss, charm_echo_first, charm_echo_blocked, charm_echo_second, charm_echo_third, charm_echo_overflow]
	for charm_echo_target in charm_echo_targets:
		charm_echo_target.data = charm_echo_normal_data
	charm_echo_boss.data = charm_echo_boss_data
	charm_echo_inactive.active = false
	charm_echo_blocked.apply_charm(candidate_charm_core.charm_profile, 1.0, 0.0)
	var charm_echo_modifier_queries: Array[StringName] = []
	var charm_echo_radius_queries: Array[Dictionary] = []
	var charm_echo_result := charm_echo_service.execute(
		charm_echo_position,
		charm_echo_normal_data,
		candidate_charm_core,
		func(key: StringName, default_value: Variant) -> Variant:
			charm_echo_modifier_queries.append(key)
			match key:
				&"charm_echo": return true
				&"charm_echo_radius": return 160.0
				&"charm_echo_duration": return 0.55
				&"charm_vulnerability": return 0.4
			return default_value,
		func(center: Vector2, radius: float) -> Array[Enemy]:
			charm_echo_radius_queries.append({"center": center, "radius": radius})
			return charm_echo_targets
	)
	_expect(bool(charm_echo_result.eligible) and int(charm_echo_result.spread_count) == CandidateCharmEchoService.MAXIMUM_SPREAD_TARGETS and (charm_echo_result.targets as Array) == [charm_echo_first, charm_echo_second, charm_echo_third], "charm echo execution must preserve spatial order while counting only three successful normal-target applications", failures)
	_expect(charm_echo_modifier_queries == [&"charm_echo", &"charm_echo_radius", &"charm_echo_duration", &"charm_vulnerability"] and charm_echo_radius_queries.size() == 1 and charm_echo_radius_queries[0].center == charm_echo_position and is_equal_approx(float(charm_echo_radius_queries[0].radius), 160.0), "charm echo execution must resolve its profile before issuing one stable radius query", failures)
	_expect(is_equal_approx(float((charm_echo_first.statuses[&"charm"] as Dictionary).remaining), 0.495) and is_equal_approx(float((charm_echo_first.statuses[&"charm"] as Dictionary).vulnerability), 0.2) and not charm_echo_overflow.has_charm_effect(), "charm echo execution must apply configured duration and half vulnerability without touching overflow targets", failures)
	var charm_echo_query_count := charm_echo_modifier_queries.size()
	var rejected_boss_echo := charm_echo_service.execute(charm_echo_position, charm_echo_boss_data, candidate_charm_core, func(_key: StringName, _default: Variant) -> Variant: charm_echo_modifier_queries.append(&"unexpected"); return true, func(_center: Vector2, _radius: float) -> Array[Enemy]: return charm_echo_targets)
	_expect(not bool(rejected_boss_echo.eligible) and charm_echo_modifier_queries.size() == charm_echo_query_count, "boss charm defeats must be rejected before candidate modifier or spatial queries", failures)
	var disabled_echo_radius_queries := [0]
	var disabled_echo := charm_echo_service.execute(charm_echo_position, charm_echo_normal_data, candidate_charm_core, func(key: StringName, _default: Variant) -> Variant: charm_echo_modifier_queries.append(key); return false, func(_center: Vector2, _radius: float) -> Array[Enemy]: disabled_echo_radius_queries[0] += 1; return charm_echo_targets)
	_expect(not bool(disabled_echo.eligible) and disabled_echo_radius_queries[0] == 0 and charm_echo_modifier_queries.back() == &"charm_echo", "disabled charm echo growth must stop after its single eligibility lookup", failures)
	for charm_echo_target in charm_echo_targets:
		charm_echo_target.free()

	var death_wave_launch_service := CandidateDeathWaveLaunchService.new()
	var death_wave_souls := [300]
	var death_wave_modifier_queries: Array[StringName] = []
	var death_wave_launch_requests: Array[Dictionary] = []
	var death_wave_events: Array[String] = []
	var death_wave_color := Color("80d9f5")
	var death_wave_result := death_wave_launch_service.execute(
		100.0,
		death_wave_souls[0],
		360.0,
		death_wave_color,
		func(key: StringName, default_value: Variant) -> Variant:
			death_wave_modifier_queries.append(key)
			match key:
				&"soul_harvest": return true
				&"soul_wave_damage_per_effective": return 0.006
				&"soul_wave_range_per_effective": return 1.2
				&"active_generated_spirit_damage": return 1.2
				&"post_active_spirit_window": return 8.0
				&"soul_harvest_cap": return 300
			return default_value,
		func() -> int:
			var consumed: int = death_wave_souls[0]
			death_wave_events.append("consume:%d" % consumed)
			death_wave_souls[0] = 0
			return consumed,
		func(damage: float, center_y: float, half_height: float, duration: float, spirit_gain: int, spirit_damage_multiplier: float, color: Color) -> bool:
			death_wave_events.append("launch:%d" % death_wave_souls[0])
			death_wave_launch_requests.append({
				"damage": damage,
				"center_y": center_y,
				"half_height": half_height,
				"duration": duration,
				"spirit_gain": spirit_gain,
				"spirit_damage_multiplier": spirit_damage_multiplier,
				"color": color,
			})
			return true
	)
	_expect(bool(death_wave_result.launched) and StringName(death_wave_result.reason) == &"launched" and int(death_wave_result.consumed_souls) == 300 and death_wave_souls[0] == 0, "death-wave launch service must commit the entire reserved soul stack only after a successful launch", failures)
	_expect(is_equal_approx(float(death_wave_result.effective_souls), 175.0) and is_equal_approx(float(death_wave_result.damage), 205.0) and is_equal_approx(float(death_wave_result.half_height), 355.0) and int(death_wave_result.spirit_gain) == 2 and is_equal_approx(float(death_wave_result.generated_spirit_damage_multiplier), 1.2) and is_equal_approx(float(death_wave_result.post_wave_window), 8.0) and int(death_wave_result.soul_cap) == 300, "death-wave launch service must own the bounded three-band soul profile and candidate modifiers", failures)
	_expect(death_wave_modifier_queries == [&"soul_harvest", &"soul_wave_damage_per_effective", &"soul_wave_range_per_effective", &"active_generated_spirit_damage", &"post_active_spirit_window", &"soul_harvest_cap"] and death_wave_events == ["launch:300", "consume:300"], "death-wave launch service must resolve the profile, launch while souls are reserved, then consume them", failures)
	_expect(death_wave_launch_requests.size() == 1 and is_equal_approx(float(death_wave_launch_requests[0].damage), 205.0) and is_equal_approx(float(death_wave_launch_requests[0].center_y), 360.0) and is_equal_approx(float(death_wave_launch_requests[0].half_height), 355.0) and is_equal_approx(float(death_wave_launch_requests[0].duration), 2.4) and int(death_wave_launch_requests[0].spirit_gain) == 2 and is_equal_approx(float(death_wave_launch_requests[0].spirit_damage_multiplier), 1.2) and death_wave_launch_requests[0].color == death_wave_color, "death-wave launch service must issue one complete runtime request with the stable 2.4-second duration", failures)

	var rejected_death_wave_souls := [300]
	var rejected_death_wave_consumes := [0]
	var rejected_death_wave_launches := [0]
	var rejected_death_wave_result := death_wave_launch_service.execute(
		100.0,
		rejected_death_wave_souls[0],
		360.0,
		death_wave_color,
		func(key: StringName, default_value: Variant) -> Variant:
			match key:
				&"soul_harvest": return true
				&"soul_wave_damage_per_effective": return 0.006
				&"soul_wave_range_per_effective": return 1.2
			return default_value,
		func() -> int:
			rejected_death_wave_consumes[0] += 1
			var consumed: int = rejected_death_wave_souls[0]
			rejected_death_wave_souls[0] = 0
			return consumed,
		func(_damage: float, _center_y: float, _half_height: float, _duration: float, _spirit_gain: int, _spirit_damage_multiplier: float, _color: Color) -> bool:
			rejected_death_wave_launches[0] += 1
			return false
	)
	_expect(not bool(rejected_death_wave_result.launched) and StringName(rejected_death_wave_result.reason) == &"launch_rejected" and int(rejected_death_wave_result.consumed_souls) == 0 and rejected_death_wave_souls[0] == 300 and rejected_death_wave_launches[0] == 1 and rejected_death_wave_consumes[0] == 0, "rejected death-wave launches must preserve souls and skip every commit side effect", failures)

	var disabled_harvest_souls := [88]
	var disabled_harvest_consumes := [0]
	var disabled_harvest_request: Array[Dictionary] = []
	var disabled_harvest_result := death_wave_launch_service.execute(
		100.0,
		disabled_harvest_souls[0],
		300.0,
		death_wave_color,
		func(key: StringName, default_value: Variant) -> Variant:
			return false if key == &"soul_harvest" else default_value,
		func() -> int:
			disabled_harvest_consumes[0] += 1
			return 0,
		func(damage: float, _center_y: float, half_height: float, duration: float, spirit_gain: int, _spirit_damage_multiplier: float, _color: Color) -> bool:
			disabled_harvest_request.append({"damage": damage, "half_height": half_height, "duration": duration, "spirit_gain": spirit_gain})
			return true
	)
	_expect(bool(disabled_harvest_result.launched) and int(disabled_harvest_result.consumed_souls) == 0 and disabled_harvest_souls[0] == 88 and disabled_harvest_consumes[0] == 0 and disabled_harvest_request.size() == 1 and is_equal_approx(float(disabled_harvest_request[0].damage), 100.0) and is_equal_approx(float(disabled_harvest_request[0].half_height), 145.0) and int(disabled_harvest_request[0].spirit_gain) == 1, "disabled soul harvest must launch the base wave without consuming an unrelated soul snapshot", failures)

	var invalid_death_wave_modifier_queries := [0]
	var invalid_death_wave_result := death_wave_launch_service.execute(
		100.0,
		300,
		360.0,
		death_wave_color,
		func(_key: StringName, default_value: Variant) -> Variant:
			invalid_death_wave_modifier_queries[0] += 1
			return default_value,
		Callable(),
		Callable()
	)
	_expect(not bool(invalid_death_wave_result.launched) and StringName(invalid_death_wave_result.reason) == &"invalid_dependencies" and invalid_death_wave_modifier_queries[0] == 0, "death-wave launch service must reject missing collaborators before modifier lookup or soul consumption", failures)

	var death_wave_runtime_service := CandidateDeathWaveRuntimeService.new()
	var cursed_wave_target := _active_enemy_at(Vector2(240.0, 180.0))
	var cursed_wave_events: Array[String] = []
	var cursed_wave_result := death_wave_runtime_service.resolve_hit(
		false,
		cursed_wave_target,
		120.0,
		2,
		1.2,
		func(target: Enemy, requested_damage: float) -> float:
			cursed_wave_events.append("damage:%s:%.0f" % [str(death_wave_runtime_service.is_resolving_hit()), requested_damage])
			target.active = false
			cursed_wave_events.append("curse:%s" % str(death_wave_runtime_service.mark_curse_spirit_generated()))
			return 90.0,
		func(dealt: float) -> void:
			cursed_wave_events.append("settle:%.0f:%s" % [dealt, str(death_wave_runtime_service.is_resolving_hit())]),
		func(requested_gain: int, hit_position: Vector2, damage_multiplier: float) -> int:
			cursed_wave_events.append("add:%d:%.1f" % [requested_gain, damage_multiplier])
			_expect(hit_position == Vector2(240.0, 180.0), "death-wave runtime callback must receive the pre-damage hit position", failures)
			return requested_gain
	)
	_expect(bool(cursed_wave_result.resolved) and StringName(cursed_wave_result.reason) == &"target_defeated" and is_equal_approx(float(cursed_wave_result.damage), 90.0) and bool(cursed_wave_result.target_defeated) and bool(cursed_wave_result.curse_spirit_generated), "death-wave runtime service must expose a lethal hit and its synchronous curse-spirit reentry", failures)
	_expect(int(cursed_wave_result.requested_spirit_gain) == 1 and int(cursed_wave_result.generated_spirit_gain) == 1 and cursed_wave_result.hit_position == Vector2(240.0, 180.0) and cursed_wave_events == ["damage:true:120", "curse:true", "settle:90:false", "add:1:1.2"], "death-wave runtime service must settle damage after reentry and subtract exactly one curse spirit before adding wave spirits", failures)
	_expect(not death_wave_runtime_service.is_resolving_hit() and not death_wave_runtime_service.mark_curse_spirit_generated(), "death-wave runtime service must clear reentry state after every resolved hit", failures)

	var ordinary_wave_target := _active_enemy_at(Vector2(280.0, 180.0))
	var ordinary_wave_add_requests: Array[Dictionary] = []
	var ordinary_wave_result := death_wave_runtime_service.resolve_hit(
		false,
		ordinary_wave_target,
		80.0,
		2,
		1.1,
		func(target: Enemy, _requested_damage: float) -> float:
			target.active = false
			return 70.0,
		Callable(),
		func(requested_gain: int, hit_position: Vector2, damage_multiplier: float) -> int:
			ordinary_wave_add_requests.append({"gain": requested_gain, "position": hit_position, "multiplier": damage_multiplier})
			return 1
	)
	_expect(int(ordinary_wave_result.requested_spirit_gain) == 2 and int(ordinary_wave_result.generated_spirit_gain) == 1 and not bool(ordinary_wave_result.curse_spirit_generated) and ordinary_wave_add_requests.size() == 1 and int(ordinary_wave_add_requests[0].gain) == 2, "ordinary death-wave defeats must request the full spirit gain while reporting the capacity-limited actual gain", failures)

	var surviving_wave_target := _active_enemy_at(Vector2(320.0, 180.0))
	var surviving_wave_add_calls := [0]
	var surviving_wave_result := death_wave_runtime_service.resolve_hit(
		false,
		surviving_wave_target,
		35.0,
		2,
		1.0,
		func(_target: Enemy, _requested_damage: float) -> float:
			return 35.0,
		Callable(),
		func(_requested_gain: int, _hit_position: Vector2, _damage_multiplier: float) -> int:
			surviving_wave_add_calls[0] += 1
			return 0
	)
	_expect(bool(surviving_wave_result.resolved) and StringName(surviving_wave_result.reason) == &"target_survived" and not bool(surviving_wave_result.target_defeated) and surviving_wave_add_calls[0] == 0, "nonlethal death-wave hits must record damage without requesting spirits", failures)

	var blocked_wave_callbacks := [0, 0]
	var blocked_wave_result := death_wave_runtime_service.resolve_hit(
		true,
		surviving_wave_target,
		35.0,
		2,
		1.0,
		func(_target: Enemy, _requested_damage: float) -> float:
			blocked_wave_callbacks[0] += 1
			return 0.0,
		Callable(),
		func(_requested_gain: int, _hit_position: Vector2, _damage_multiplier: float) -> int:
			blocked_wave_callbacks[1] += 1
			return 0
	)
	_expect(not bool(blocked_wave_result.resolved) and blocked_wave_callbacks == [0, 0], "finished games must reject death-wave hits before damage or spirit callbacks", failures)

	var post_wave_windows: Array[float] = []
	death_wave_runtime_service.arm_post_wave_window(8.0)
	var finished_wave_result := death_wave_runtime_service.finish(func(duration: float) -> void: post_wave_windows.append(duration))
	var repeated_finish_result := death_wave_runtime_service.finish(func(duration: float) -> void: post_wave_windows.append(duration))
	_expect(is_equal_approx(float(finished_wave_result.post_wave_window), 8.0) and bool(finished_wave_result.active_window_started) and post_wave_windows == [8.0] and is_equal_approx(float(repeated_finish_result.post_wave_window), 0.0) and not bool(repeated_finish_result.active_window_started), "death-wave completion must start an armed post-wave window exactly once", failures)
	death_wave_runtime_service.arm_post_wave_window(6.0)
	var missing_window_callback_result := death_wave_runtime_service.finish(Callable())
	_expect(is_equal_approx(float(missing_window_callback_result.post_wave_window), 6.0) and not bool(missing_window_callback_result.active_window_started) and is_zero_approx(death_wave_runtime_service.pending_post_wave_window()), "death-wave completion must clear its armed window even when necromancy is unavailable", failures)
	death_wave_runtime_service.arm_post_wave_window(4.0)
	death_wave_runtime_service.reset()
	_expect(is_zero_approx(death_wave_runtime_service.pending_post_wave_window()) and not death_wave_runtime_service.is_resolving_hit(), "death-wave runtime reset must clear every transient launch and hit state", failures)
	cursed_wave_target.free()
	ordinary_wave_target.free()
	surviving_wave_target.free()
	var context := ContractContext.new()
	context.loadout = loadout
	context.offer_service = offer_service
	context.burn = burn
	context.presentation = presentation
	context.targeting = targeting
	context.charm_stage = charm_stage
	context.charm_profile = charm_profile
	context.precision_enemy_data = EnemyData.new()
	context.precision_enemy_data.max_health = 100.0
	return context

static func _run_spirit_and_candidate_policy_contracts(context: ContractContext, failures: Array[String]) -> void:
	var loadout := context.loadout
	var offer_service := context.offer_service
	var burn: Dictionary = context.burn
	var presentation := context.presentation
	var targeting := context.targeting
	var charm_stage := context.charm_stage
	var charm_profile := context.charm_profile
	var spirit_attack_service := SpiritAttackExecutionService.new()
	var spirit_first := _active_enemy_at(Vector2(220.0, 180.0))
	var spirit_second := _active_enemy_at(Vector2(280.0, 180.0))
	var spirit_splash := _active_enemy_at(Vector2(310.0, 180.0))
	var spirit_pool: Array[Enemy] = [spirit_first, spirit_second, spirit_splash]
	var spirit_entries: Array[Dictionary] = [
		{"id": 11, "position": Vector2(180.0, 180.0), "damage_multiplier": 1.5, "curse_generation": 2},
		{"id": 12, "position": Vector2(240.0, 180.0), "damage_multiplier": 0.5, "curse_generation": 0},
	]
	var spirit_events: Array[String] = []
	var spirit_active_queries := [0]
	var spirit_reservations := [0]
	var spirit_result := spirit_attack_service.execute(
		Vector2(160.0, 180.0),
		100.0,
		3,
		2.0,
		90.0,
		func() -> Array[Enemy]:
			spirit_active_queries[0] += 1
			spirit_events.append("active:%d" % spirit_active_queries[0])
			var active_targets: Array[Enemy] = []
			for target in spirit_pool:
				if target.active:
					active_targets.append(target)
			return active_targets,
		func(reserved_count: int, fallback_origin: Vector2) -> Array[Dictionary]:
			spirit_reservations[0] += 1
			spirit_events.append("reserve:%d:%s" % [reserved_count, str(fallback_origin)])
			if spirit_entries.is_empty():
				return [] as Array[Dictionary]
			return [spirit_entries.pop_front()] as Array[Dictionary],
		func(targets: Array) -> Enemy:
			var target := targets[0] as Enemy
			spirit_events.append("pick:%d" % spirit_pool.find(target))
			return target,
		func(target: Enemy, generation: int) -> bool:
			spirit_events.append("curse:%d:%d" % [spirit_pool.find(target), generation])
			return generation > 0,
		func(center: Vector2, radius: float) -> Array[Enemy]:
			spirit_events.append("radius:%s:%.0f" % [str(center), radius])
			if center == spirit_first.global_position:
				return [] as Array[Enemy]
			return [spirit_second, spirit_splash] as Array[Enemy],
		func(target: Enemy, damage: float, source: StringName, is_area: bool) -> float:
			spirit_events.append("damage:%d:%.0f:%s:%s" % [spirit_pool.find(target), damage, String(source), str(is_area)])
			target.active = false
			if target == spirit_first:
				return 90.0
			return 60.0 if target == spirit_second else 40.0,
		func(origin: Vector2, target_position: Vector2, radius: float) -> void:
			spirit_events.append("present:%s:%s:%.0f" % [str(origin), str(target_position), radius]),
		func(summon_id: int, target_position: Vector2, damage: float) -> void:
			spirit_events.append("update:%d:%s:%.0f" % [summon_id, str(target_position), damage])
	)
	var spirit_releases: Array[Dictionary] = []
	spirit_releases.assign(spirit_result.releases as Array)
	_expect(bool(spirit_result.resolved) and StringName(spirit_result.reason) == &"resolved" and StringName(spirit_result.stop_reason) == &"no_targets" and int(spirit_result.requested_count) == 3 and int(spirit_result.released_count) == 2, "spirit attack execution must distinguish requested, released, and target-exhausted counts", failures)
	_expect(is_equal_approx(float(spirit_result.damage), 190.0) and int(spirit_result.hit_count) == 3 and spirit_releases.size() == 2 and bool(spirit_releases[0].used_primary_fallback) and not bool(spirit_releases[1].used_primary_fallback), "spirit attack execution must aggregate actual fallback and radius damage without inflating hit counts", failures)
	_expect(spirit_active_queries[0] == 4 and spirit_reservations[0] == 2 and is_equal_approx(float(spirit_releases[0].spirit_damage), 300.0) and is_equal_approx(float(spirit_releases[1].spirit_damage), 100.0), "spirit attack execution must requery targets per spirit and reserve exactly one charge before applying each entry multiplier", failures)
	_expect(spirit_events.find("reserve:1:(160.0, 180.0)") < spirit_events.find("pick:0") and spirit_events.find("pick:0") < spirit_events.find("curse:0:2") and spirit_events.find("curse:0:2") < spirit_events.find("radius:(220.0, 180.0):90") and spirit_events.find("radius:(220.0, 180.0):90") < spirit_events.find("damage:0:300:spirit_summon:true"), "each spirit attack must preserve reservation, RNG, curse, radius query, and damage order with the stable source", failures)
	_expect(spirit_events.find("damage:0:300:spirit_summon:true") < spirit_events.find("present:(180.0, 180.0):(220.0, 180.0):90") and spirit_events.find("present:(180.0, 180.0):(220.0, 180.0):90") < spirit_events.find("update:11:(220.0, 180.0):300") and spirit_events.find("update:11:(220.0, 180.0):300") < spirit_events.find("active:3"), "spirit presentation and active-summon state must settle after damage and before the next target requery", failures)
	var rejected_spirit_callbacks := [0]
	var rejected_spirit_result := spirit_attack_service.execute(
		Vector2.ZERO, 10.0, 1, 1.0, 50.0,
		func() -> Array[Enemy]: rejected_spirit_callbacks[0] += 1; return [] as Array[Enemy],
		func(_count: int, _origin: Vector2) -> Array[Dictionary]: return [] as Array[Dictionary],
		func(_targets: Array) -> Enemy: return spirit_first,
		func(_target: Enemy, _generation: int) -> bool: return false,
		func(_center: Vector2, _radius: float) -> Array[Enemy]: return [] as Array[Enemy],
		func(_target: Enemy, _damage: float, _source: StringName, _is_area: bool) -> float: return 0.0,
		func(_origin: Vector2, _target_position: Vector2, _radius: float) -> void: pass,
		func(_summon_id: int, _target_position: Vector2, _damage: float) -> void: pass
	)
	_expect(not bool(rejected_spirit_result.resolved) and StringName(rejected_spirit_result.reason) == &"no_targets" and rejected_spirit_callbacks[0] == 1, "spirit attack execution must stop before reserving a charge when the initial active target set is empty", failures)
	spirit_splash.active = true
	var exhausted_spirit_calls := [0, 0, 0]
	var exhausted_spirit_result := spirit_attack_service.execute(
		Vector2.ZERO, 10.0, 1, 1.0, 50.0,
		func() -> Array[Enemy]: exhausted_spirit_calls[0] += 1; return [spirit_splash] as Array[Enemy],
		func(_count: int, _origin: Vector2) -> Array[Dictionary]: exhausted_spirit_calls[1] += 1; return [] as Array[Dictionary],
		func(_targets: Array) -> Enemy: exhausted_spirit_calls[2] += 1; return spirit_splash,
		func(_target: Enemy, _generation: int) -> bool: return false,
		func(_center: Vector2, _radius: float) -> Array[Enemy]: return [] as Array[Enemy],
		func(_target: Enemy, _damage: float, _source: StringName, _is_area: bool) -> float: return 0.0,
		func(_origin: Vector2, _target_position: Vector2, _radius: float) -> void: pass,
		func(_summon_id: int, _target_position: Vector2, _damage: float) -> void: pass
	)
	_expect(not bool(exhausted_spirit_result.resolved) and StringName(exhausted_spirit_result.reason) == &"reservation_rejected" and exhausted_spirit_calls == [2, 1, 0], "spirit attack execution must reserve one charge after the per-spirit target requery and stop before RNG when reservation is rejected", failures)
	var invalid_spirit_callbacks := [0]
	var invalid_spirit_result := spirit_attack_service.execute(Vector2.ZERO, 10.0, 1, 1.0, 50.0, func() -> Array[Enemy]: invalid_spirit_callbacks[0] += 1; return spirit_pool, Callable(), Callable(), Callable(), Callable(), Callable(), Callable(), Callable())
	_expect(not bool(invalid_spirit_result.resolved) and StringName(invalid_spirit_result.reason) == &"invalid_dependencies" and invalid_spirit_callbacks[0] == 0, "spirit attack execution must reject missing collaborators before target, charge, or RNG work", failures)
	spirit_first.free()
	spirit_second.free()
	spirit_splash.free()

	var cursor_hit_service := CursorHitEffectService.new()
	var cursor_hit_target := _active_enemy_at(Vector2(520.0, 220.0))
	var cursor_spread_target := _active_enemy_at(Vector2(560.0, 220.0))
	var cursor_inactive_spread := _active_enemy_at(Vector2(590.0, 220.0))
	cursor_inactive_spread.active = false
	var cursor_hit_events: Array[String] = []
	var cursor_hit_result := cursor_hit_service.execute(
		cursor_hit_target,
		100.0,
		false,
		{"reward_mark": 1.8, "weak_mark": 0.3, "tower_pierce_mark": true, "collision_damage": 0.5, "collision_mark": 0.4, "shatter_spread": true},
		func(target: Enemy, requested_damage: float, area_hit: bool) -> float:
			cursor_hit_events.append("primary:%.1f:%.0f:%s:%s" % [target.experience_multiplier, requested_damage, str(area_hit), str(target.statuses.is_empty())])
			return 80.0,
		func(target: Enemy, requested_damage: float, source: StringName) -> float:
			cursor_hit_events.append("collision:%.0f:%s:%s:%s" % [requested_damage, String(source), str(target.statuses.has(&"mark")), str(target.statuses.has(&"pierce_mark"))])
			return 40.0,
		func(center: Vector2, radius: float) -> Array[Enemy]:
			cursor_hit_events.append("spread:%s:%.0f:%.1f" % [str(center), radius, float((cursor_hit_target.statuses.get(&"mark", {}) as Dictionary).get("power", 0.0))])
			return [cursor_hit_target, cursor_spread_target, cursor_inactive_spread]
	)
	var cursor_applied_effects: Array[StringName] = []
	cursor_applied_effects.assign(cursor_hit_result.applied_effects as Array)
	var cursor_spread_targets: Array[Enemy] = []
	cursor_spread_targets.assign(cursor_hit_result.spread_targets as Array)
	_expect(bool(cursor_hit_result.resolved) and StringName(cursor_hit_result.reason) == &"resolved" and bool(cursor_hit_result.reward_mark_reserved) and bool(cursor_hit_result.reward_mark_preserved) and is_equal_approx(cursor_hit_target.experience_multiplier, 1.8), "cursor hit effects must reserve and preserve the reward multiplier around a surviving primary hit", failures)
	_expect(is_equal_approx(float(cursor_hit_result.primary_damage), 80.0) and bool(cursor_hit_result.target_survived_primary) and bool(cursor_hit_result.collision_requested) and is_equal_approx(float(cursor_hit_result.collision_requested_damage), 50.0) and is_equal_approx(float(cursor_hit_result.collision_damage), 40.0) and bool(cursor_hit_result.target_survived_collision), "cursor hit effects must keep primary and collision actual damage separate while using the original requested damage for collision", failures)
	_expect(cursor_applied_effects == [&"weak_mark", &"tower_pierce_mark", &"collision_mark"] and bool(cursor_hit_result.spread_requested) and int(cursor_hit_result.spread_count) == 1 and cursor_spread_targets == [cursor_spread_target], "cursor hit effects must apply weak, pierce, and post-collision marks before spreading only to successful non-primary targets", failures)
	_expect(cursor_hit_events == ["primary:1.8:100:false:true", "collision:50:cursor_collision:true:true", "spread:(520.0, 220.0):120:0.4"], "cursor hit effects must preserve reward-before-primary, statuses-before-collision, and collision-mark-before-spread order", failures)
	_expect(is_equal_approx(float((cursor_hit_target.statuses[&"mark"] as Dictionary).power), 0.4) and is_equal_approx(float((cursor_spread_target.statuses[&"mark"] as Dictionary).remaining), CursorHitEffectService.SHATTER_MARK_DURATION) and is_equal_approx(float((cursor_spread_target.statuses[&"mark"] as Dictionary).power), 0.18) and not cursor_inactive_spread.statuses.has(&"mark"), "cursor shatter spread must preserve the 120px profile, 3.5-second duration, and sixty-percent weak-mark power", failures)

	var lethal_cursor_target := _active_enemy_at(Vector2(620.0, 220.0))
	var lethal_cursor_callbacks := [0, 0]
	var lethal_cursor_reward_seen := [0.0]
	var lethal_cursor_result := cursor_hit_service.execute(
		lethal_cursor_target,
		120.0,
		true,
		{"reward_mark": 2.2, "weak_mark": 0.5, "collision_damage": 0.4, "collision_mark": 0.3, "shatter_spread": true},
		func(target: Enemy, _damage: float, _is_area: bool) -> float:
			lethal_cursor_reward_seen[0] = target.experience_multiplier
			target.active = false
			return 95.0,
		func(_target: Enemy, _damage: float, _source: StringName) -> float: lethal_cursor_callbacks[0] += 1; return 0.0,
		func(_center: Vector2, _radius: float) -> Array[Enemy]: lethal_cursor_callbacks[1] += 1; return [] as Array[Enemy]
	)
	_expect(bool(lethal_cursor_result.resolved) and is_equal_approx(lethal_cursor_reward_seen[0], 2.2) and is_equal_approx(float(lethal_cursor_result.primary_damage), 95.0) and not bool(lethal_cursor_result.target_survived_primary) and bool(lethal_cursor_result.reward_mark_reserved) and not bool(lethal_cursor_result.reward_mark_preserved), "lethal cursor primary damage must observe the pre-applied reward mark and report the primary actual damage", failures)
	_expect(lethal_cursor_callbacks == [0, 0] and (lethal_cursor_result.applied_effects as Array).is_empty() and not bool(lethal_cursor_result.collision_requested) and not bool(lethal_cursor_result.spread_requested), "a lethal primary cursor hit must skip every status, collision, and spread followup", failures)

	var collision_lethal_target := _active_enemy_at(Vector2(660.0, 220.0))
	var collision_lethal_queries := [0]
	var collision_lethal_result := cursor_hit_service.execute(
		collision_lethal_target,
		90.0,
		false,
		{"weak_mark": 0.25, "collision_damage": 0.5, "collision_mark": 0.45, "shatter_spread": true},
		func(_target: Enemy, _damage: float, _is_area: bool) -> float: return 70.0,
		func(target: Enemy, requested_damage: float, source: StringName) -> float:
			_expect(is_equal_approx(requested_damage, 45.0) and source == &"cursor_collision" and target.statuses.has(&"mark"), "collision callback must receive the stable source after the weak mark", failures)
			target.active = false
			return 30.0,
		func(_center: Vector2, _radius: float) -> Array[Enemy]: collision_lethal_queries[0] += 1; return [cursor_spread_target] as Array[Enemy]
	)
	_expect(bool(collision_lethal_result.target_survived_primary) and bool(collision_lethal_result.collision_requested) and is_equal_approx(float(collision_lethal_result.collision_damage), 30.0) and not bool(collision_lethal_result.target_survived_collision), "cursor collision damage must expose its actual damage and post-collision survival state", failures)
	_expect(collision_lethal_queries[0] == 0 and (collision_lethal_result.applied_effects as Array) == [&"weak_mark"] and not bool(collision_lethal_result.spread_requested), "a lethal collision must skip collision marking and the entire spatial spread query", failures)

	var invalid_cursor_target := _active_enemy_at(Vector2(700.0, 220.0))
	var invalid_cursor_calls := [0]
	var invalid_cursor_result := cursor_hit_service.execute(invalid_cursor_target, 50.0, false, {"reward_mark": 3.0}, func(_target: Enemy, _damage: float, _is_area: bool) -> float: invalid_cursor_calls[0] += 1; return 0.0, Callable(), Callable())
	_expect(not bool(invalid_cursor_result.resolved) and StringName(invalid_cursor_result.reason) == &"invalid_dependencies" and invalid_cursor_calls[0] == 0 and is_equal_approx(invalid_cursor_target.experience_multiplier, 1.0), "cursor hit effects must reject missing collaborators before reward mutation or primary damage", failures)
	var normal_route_target := _active_enemy_at(Vector2(730.0, 220.0))
	var judgment_route_target := _active_enemy_at(Vector2(760.0, 220.0))
	var route_modifiers := {"weak_mark": 0.2, "collision_damage": 0.5, "collision_mark": 0.3}
	var normal_route_result := cursor_hit_service.execute(normal_route_target, 80.0, false, route_modifiers, func(_target: Enemy, _damage: float, _is_area: bool) -> float: return 61.0, func(_target: Enemy, _damage: float, _source: StringName) -> float: return 22.0, func(_center: Vector2, _radius: float) -> Array[Enemy]: return [] as Array[Enemy])
	var judgment_route_result := cursor_hit_service.execute(judgment_route_target, 80.0, false, route_modifiers, func(_target: Enemy, _damage: float, _is_area: bool) -> float: return 61.0, func(_target: Enemy, _damage: float, _source: StringName) -> float: return 22.0, func(_center: Vector2, _radius: float) -> Array[Enemy]: return [] as Array[Enemy])
	_expect(is_equal_approx(float(normal_route_result.primary_damage), float(judgment_route_result.primary_damage)) and is_equal_approx(float(normal_route_result.collision_damage), float(judgment_route_result.collision_damage)) and (normal_route_result.applied_effects as Array) == (judgment_route_result.applied_effects as Array) and normal_route_target.statuses == judgment_route_target.statuses, "normal and judgment primary-damage callbacks must receive identical surviving cursor followups", failures)
	cursor_hit_target.free()
	cursor_spread_target.free()
	cursor_inactive_spread.free()
	lethal_cursor_target.free()
	collision_lethal_target.free()
	invalid_cursor_target.free()
	normal_route_target.free()
	judgment_route_target.free()

	var enemy_special_service := EnemySpecialActionExecutionService.new()
	var special_source := _active_enemy_at(Vector2(300.0, 250.0))
	var special_normal_data := EnemyData.new()
	special_normal_data.id = &"contract_special_normal"
	var special_boss_data := EnemyData.new()
	special_boss_data.id = &"contract_special_boss"
	special_boss_data.is_boss = true
	special_source.data = special_normal_data
	var special_events: Array[String] = []
	var special_rolls: Array[float] = [0.2]
	var special_ranges: Array[float] = [100.0]
	var special_pool: Array[EnemyData] = []
	var special_picks: Array[EnemyData] = []
	var special_spawned: Array[Enemy] = []
	var special_area_targets: Array[Enemy] = []
	var special_battle_rect_callback: Callable = func() -> Rect2:
		special_events.append("rect")
		return Rect2(0.0, 0.0, 800.0, 500.0)
	var special_roll_callback: Callable = func() -> float:
		special_events.append("roll")
		return special_rolls.pop_front()
	var special_range_callback: Callable = func(minimum: float, maximum: float) -> float:
		special_events.append("range:%.0f:%.0f" % [minimum, maximum])
		return special_ranges.pop_front()
	var special_pick_callback: Callable = func(pool: Array) -> EnemyData:
		special_events.append("pick:%d" % pool.size())
		return special_picks.pop_front()
	var special_radius_callback: Callable = func(center: Vector2, radius: float) -> Array[Enemy]:
		special_events.append("radius:%s:%.0f" % [str(center), radius])
		return special_area_targets
	var special_lane_callback: Callable = func(position: Vector2) -> int:
		special_events.append("lane:%s" % str(position))
		return 4
	var special_move_callback: Callable = func(shifted_y: float, lane: int) -> void:
		special_events.append("move:%.0f:%d" % [shifted_y, lane])
		special_source.position.y = shifted_y
	var special_disable_callback: Callable = func(duration: float) -> void:
		special_events.append("disable:%.0f" % duration)
	var special_pool_callback: Callable = func() -> Array[EnemyData]:
		special_events.append("pool")
		return special_pool
	var special_clamp_callback: Callable = func(position: Vector2) -> Vector2:
		special_events.append("clamp:%s" % str(position))
		return position + Vector2(1.0, 2.0)
	var special_spawn_callback: Callable = func(data: EnemyData, position: Vector2, lane: int, health_multiplier: float, speed_multiplier: float) -> Enemy:
		special_events.append("spawn:%s:%s:%d:%.2f:%.2f" % [String(data.id), str(position), lane, health_multiplier, speed_multiplier])
		var spawned := Enemy.new()
		special_spawned.append(spawned)
		return spawned

	var unknown_special_result := enemy_special_service.execute(&"unknown", special_source, Callable(), Callable(), Callable(), Callable(), Callable(), Callable(), Callable(), Callable(), Callable(), Callable(), Callable())
	_expect(not bool(unknown_special_result.applied) and StringName(unknown_special_result.reason) == &"unknown_action" and special_events.is_empty(), "unknown enemy special actions must be rejected without consulting unrelated collaborators", failures)
	var invalid_shift_result := enemy_special_service.execute(&"shift_position", special_source, Callable(), Callable(), Callable(), Callable(), Callable(), Callable(), Callable(), Callable(), Callable(), Callable(), Callable())
	_expect(not bool(invalid_shift_result.applied) and StringName(invalid_shift_result.reason) == &"invalid_dependencies" and special_events.is_empty() and special_source.position == Vector2(300.0, 250.0), "enemy shift actions must reject missing collaborators before randomness or movement", failures)
	var shift_result := enemy_special_service.execute(&"shift_position", special_source, special_battle_rect_callback, special_roll_callback, special_range_callback, special_pick_callback, special_radius_callback, special_lane_callback, special_move_callback, special_disable_callback, special_pool_callback, special_clamp_callback, special_spawn_callback)
	_expect(bool(shift_result.applied) and StringName(shift_result.reason) == &"resolved" and not bool(shift_result.reversed_at_edge) and is_equal_approx(float(shift_result.direction), -1.0) and is_equal_approx(float(shift_result.first_distance), 100.0) and is_equal_approx(float(shift_result.shifted_y), 150.0) and int(shift_result.lane) == 4, "enemy shift actions must consume one direction roll and one in-bounds distance before moving", failures)
	_expect(special_events == ["rect", "roll", "range:90:175", "lane:(300.0, 150.0)", "move:150:4"], "enemy shift actions must preserve rect, direction, distance, lane, and movement order", failures)
	special_events.clear()
	special_source.position = Vector2(300.0, 50.0)
	special_rolls.append(0.2)
	special_ranges.append_array([100.0, 150.0])
	var reversed_shift_result := enemy_special_service.execute(&"shift_position", special_source, special_battle_rect_callback, special_roll_callback, special_range_callback, special_pick_callback, special_radius_callback, special_lane_callback, special_move_callback, special_disable_callback, special_pool_callback, special_clamp_callback, special_spawn_callback)
	_expect(bool(reversed_shift_result.reversed_at_edge) and is_equal_approx(float(reversed_shift_result.second_distance), 150.0) and is_equal_approx(float(reversed_shift_result.shifted_y), 200.0) and special_events.count("range:90:175") == 2, "out-of-bounds enemy shifts must consume exactly one second distance roll in the opposite direction", failures)

	var special_area_first := _active_enemy_at(Vector2(320.0, 240.0))
	var special_area_second := _active_enemy_at(Vector2(340.0, 240.0))
	special_area_first.apply_status(&"mark", 4.0, 0.3)
	special_area_second.apply_status(&"fear", 4.0, 0.3)
	special_area_targets.assign([special_area_first, special_area_second])
	special_events.clear()
	special_source.position = Vector2(300.0, 250.0)
	var cleanse_result := enemy_special_service.execute(&"cleanse_area", special_source, special_battle_rect_callback, special_roll_callback, special_range_callback, special_pick_callback, special_radius_callback, special_lane_callback, special_move_callback, special_disable_callback, special_pool_callback, special_clamp_callback, special_spawn_callback)
	_expect(bool(cleanse_result.applied) and is_equal_approx(float(cleanse_result.radius), 150.0) and int(cleanse_result.affected_count) == 2 and not special_area_first.statuses.has(&"mark") and not special_area_second.statuses.has(&"fear") and special_events == ["radius:(300.0, 250.0):150"], "enemy cleanse actions must issue one 150px query and clear every returned target", failures)
	special_events.clear()
	var support_result := enemy_special_service.execute(&"support_buff", special_source, special_battle_rect_callback, special_roll_callback, special_range_callback, special_pick_callback, special_radius_callback, special_lane_callback, special_move_callback, special_disable_callback, special_pool_callback, special_clamp_callback, special_spawn_callback)
	_expect(bool(support_result.applied) and StringName(support_result.status_id) == &"haste" and is_equal_approx(float(support_result.radius), 170.0) and is_equal_approx(float(support_result.duration), 3.5) and is_equal_approx(float(support_result.power), 0.22) and int(support_result.affected_count) == 2 and special_area_first.statuses.has(&"haste"), "enemy support actions must apply the exact 170px haste profile to successful targets", failures)
	special_events.clear()
	var fortify_result := enemy_special_service.execute(&"fortify_area", special_source, special_battle_rect_callback, special_roll_callback, special_range_callback, special_pick_callback, special_radius_callback, special_lane_callback, special_move_callback, special_disable_callback, special_pool_callback, special_clamp_callback, special_spawn_callback)
	_expect(bool(fortify_result.applied) and StringName(fortify_result.status_id) == &"fortify" and is_equal_approx(float(fortify_result.radius), 175.0) and is_equal_approx(float(fortify_result.duration), 3.5) and is_equal_approx(float(fortify_result.power), 5.0) and int(fortify_result.affected_count) == 2 and special_area_second.statuses.has(&"fortify"), "enemy fortify actions must apply the exact 175px armor profile to successful targets", failures)

	special_events.clear()
	var normal_disable_result := enemy_special_service.execute(&"disable_column", special_source, special_battle_rect_callback, special_roll_callback, special_range_callback, special_pick_callback, special_radius_callback, special_lane_callback, special_move_callback, special_disable_callback, special_pool_callback, special_clamp_callback, special_spawn_callback)
	special_source.data = special_boss_data
	var boss_disable_result := enemy_special_service.execute(&"disable_column", special_source, special_battle_rect_callback, special_roll_callback, special_range_callback, special_pick_callback, special_radius_callback, special_lane_callback, special_move_callback, special_disable_callback, special_pool_callback, special_clamp_callback, special_spawn_callback)
	_expect(is_equal_approx(float(normal_disable_result.disable_duration), 3.0) and not bool(normal_disable_result.is_boss) and is_equal_approx(float(boss_disable_result.disable_duration), 5.0) and bool(boss_disable_result.is_boss) and special_events == ["disable:3", "disable:5"], "enemy column disruption must preserve exact normal and boss disable durations", failures)

	var reinforcement_a := EnemyData.new()
	reinforcement_a.id = &"contract_reinforcement_a"
	var reinforcement_b := EnemyData.new()
	reinforcement_b.id = &"contract_reinforcement_b"
	special_pool.assign([reinforcement_a, reinforcement_b])
	special_picks.assign([reinforcement_b, reinforcement_a, reinforcement_b])
	special_events.clear()
	special_source.position = Vector2(400.0, 260.0)
	var summon_result := enemy_special_service.execute(&"summon", special_source, special_battle_rect_callback, special_roll_callback, special_range_callback, special_pick_callback, special_radius_callback, special_lane_callback, special_move_callback, special_disable_callback, special_pool_callback, special_clamp_callback, special_spawn_callback)
	var reinforcement_requests: Array[Dictionary] = []
	reinforcement_requests.assign(summon_result.reinforcements as Array)
	_expect(bool(summon_result.applied) and int(summon_result.requested_count) == 3 and int(summon_result.spawned_count) == 3 and reinforcement_requests.size() == 3 and special_events.count("pick:2") == 3, "enemy summon actions must pick with replacement exactly three times and report every successful spawn", failures)
	_expect(reinforcement_requests.map(func(request: Dictionary) -> StringName: return (request.data as EnemyData).id) == [&"contract_reinforcement_b", &"contract_reinforcement_a", &"contract_reinforcement_b"] and is_equal_approx(float(reinforcement_requests[0].angle), -0.55) and is_equal_approx(float(reinforcement_requests[1].angle), 0.0) and is_equal_approx(float(reinforcement_requests[2].angle), 0.55), "enemy summon actions must preserve pick order and the stable three-angle fan", failures)
	_expect(is_equal_approx((reinforcement_requests[0].raw_position as Vector2).distance_to(special_source.position), 48.0) and is_equal_approx((reinforcement_requests[1].raw_position as Vector2).distance_to(special_source.position), 64.0) and is_equal_approx((reinforcement_requests[2].raw_position as Vector2).distance_to(special_source.position), 80.0), "enemy summon actions must preserve the exact 48, 64, and 80px reinforcement distances", failures)
	_expect(special_events[0] == "pool" and special_events.find("pick:2") < special_events.find("clamp:%s" % str(reinforcement_requests[0].raw_position)) and special_events.all(func(event: String) -> bool: return not event.begins_with("spawn:") or event.ends_with(":4:1.40:1.15")), "enemy summon actions must resolve the pool before per-spawn pick, clamp, lane, and exact multipliers", failures)

	special_pool.clear()
	special_events.clear()
	var empty_summon_result := enemy_special_service.execute(&"summon", special_source, special_battle_rect_callback, special_roll_callback, special_range_callback, special_pick_callback, special_radius_callback, special_lane_callback, special_move_callback, special_disable_callback, special_pool_callback, special_clamp_callback, special_spawn_callback)
	_expect(not bool(empty_summon_result.applied) and StringName(empty_summon_result.reason) == &"empty_pool" and special_events == ["pool"], "enemy summon actions must reject an empty pool before pick, clamp, lane, or spawn work", failures)
	for spawned in special_spawned:
		spawned.free()
	special_source.free()
	special_area_first.free()
	special_area_second.free()

	var necromancy_effect_service := CandidateNecromancyEffectService.new()
	var fear_first := _active_enemy_at(Vector2(360.0, 180.0))
	var fear_rejected := _active_enemy_at(Vector2(380.0, 180.0))
	fear_rejected.statuses[&"fear"] = {"remaining": 1.0, "duration": 1.0, "initial_slow": 0.5}
	var fear_inactive := _active_enemy_at(Vector2(400.0, 180.0))
	fear_inactive.active = false
	var fear_second := _active_enemy_at(Vector2(420.0, 180.0))
	var fear_modifier_queries: Array[StringName] = []
	var fear_radius_queries: Array[Dictionary] = []
	var generation_fear_result := necromancy_effect_service.apply_generation_fear(
		Vector2(390.0, 180.0),
		func(key: StringName, default_value: Variant) -> Variant:
			fear_modifier_queries.append(key)
			match key:
				&"spirit_generation_fear": return true
				&"spirit_generation_fear_radius": return 140.0
				&"spirit_generation_fear_duration": return 3.5
				&"spirit_generation_fear_power": return 0.7
			return default_value,
		func(position: Vector2, radius: float) -> Array[Enemy]:
			fear_radius_queries.append({"position": position, "radius": radius})
			return [fear_first, fear_rejected, fear_inactive, fear_second]
	)
	var feared_targets: Array[Enemy] = []
	feared_targets.assign(generation_fear_result.targets as Array)
	_expect(bool(generation_fear_result.eligible) and StringName(generation_fear_result.reason) == &"resolved" and int(generation_fear_result.feared_count) == 2 and feared_targets == [fear_first, fear_second], "necromancy generation fear must count only successful active targets in spatial query order", failures)
	_expect(fear_modifier_queries == [&"spirit_generation_fear", &"spirit_generation_fear_radius", &"spirit_generation_fear_duration", &"spirit_generation_fear_power"] and fear_radius_queries.size() == 1 and fear_radius_queries[0].position == Vector2(390.0, 180.0) and is_equal_approx(float(fear_radius_queries[0].radius), 140.0), "necromancy generation fear must resolve growth values before one ordered spatial query", failures)
	_expect(fear_first.statuses.has(&"fear") and fear_second.statuses.has(&"fear") and not fear_inactive.statuses.has(&"fear"), "necromancy generation fear must apply the configured status only to eligible active enemies", failures)
	var inactive_fear_modifier_queries := [0]
	var inactive_fear_radius_queries := [0]
	var inactive_fear_result := necromancy_effect_service.apply_generation_fear(
		Vector2.ZERO,
		func(_key: StringName, _default_value: Variant) -> Variant:
			inactive_fear_modifier_queries[0] += 1
			return false,
		func(_position: Vector2, _radius: float) -> Array[Enemy]:
			inactive_fear_radius_queries[0] += 1
			return []
	)
	_expect(not bool(inactive_fear_result.eligible) and StringName(inactive_fear_result.reason) == &"inactive_growth" and inactive_fear_modifier_queries[0] == 1 and inactive_fear_radius_queries[0] == 0, "inactive generation fear must stop after its eligibility lookup and before spatial work", failures)

	var expiration_enemy_data := EnemyData.new()
	expiration_enemy_data.max_health = 100.0
	var expiration_first := _active_enemy_at(Vector2(460.0, 180.0))
	expiration_first.data = expiration_enemy_data
	expiration_first.current_health = 100.0
	var expiration_inactive := _active_enemy_at(Vector2(480.0, 180.0))
	expiration_inactive.data = expiration_enemy_data
	expiration_inactive.current_health = 100.0
	expiration_inactive.active = false
	var expiration_second := _active_enemy_at(Vector2(500.0, 180.0))
	expiration_second.data = expiration_enemy_data
	expiration_second.current_health = 100.0
	var expiration_events: Array[String] = []
	expiration_first.damage_received.connect(func(amount: float, source: StringName, _data: EnemyData) -> void: expiration_events.append("first:%.0f:%s" % [amount, source]))
	expiration_second.damage_received.connect(func(amount: float, source: StringName, _data: EnemyData) -> void: expiration_events.append("second:%.0f:%s" % [amount, source]))
	var expiration_modifier_queries: Array[StringName] = []
	var expiration_radius_queries: Array[Dictionary] = []
	var expiration_result := necromancy_effect_service.apply_expiration_blast(
		Vector2(480.0, 180.0),
		80.0,
		func(key: StringName, default_value: Variant) -> Variant:
			expiration_modifier_queries.append(key)
			match key:
				&"spirit_expiration_blast": return true
				&"spirit_expiration_radius": return 90.0
				&"spirit_expiration_damage": return 0.5
			return default_value,
		func(position: Vector2, radius: float) -> Array[Enemy]:
			expiration_radius_queries.append({"position": position, "radius": radius})
			return [expiration_first, expiration_inactive, expiration_second]
	)
	var expiration_targets: Array[Enemy] = []
	expiration_targets.assign(expiration_result.targets as Array)
	_expect(bool(expiration_result.eligible) and int(expiration_result.hit_count) == 2 and is_equal_approx(float(expiration_result.damage_per_target), 40.0) and is_equal_approx(float(expiration_result.damage), 80.0), "necromancy expiration blasts must distinguish per-target damage, actual total damage, and active hit count", failures)
	_expect(expiration_targets == [expiration_first, expiration_second] and expiration_events == ["first:40:spirit_expiration", "second:40:spirit_expiration"], "necromancy expiration blasts must preserve spatial order and the spirit_expiration damage source", failures)
	_expect(expiration_modifier_queries == [&"spirit_expiration_blast", &"spirit_expiration_radius", &"spirit_expiration_damage"] and expiration_radius_queries.size() == 1 and expiration_radius_queries[0].position == Vector2(480.0, 180.0) and is_equal_approx(float(expiration_radius_queries[0].radius), 90.0), "necromancy expiration blasts must resolve one profile and perform one spatial query", failures)
	var zero_expiration_callbacks := [0, 0]
	var zero_expiration_result := necromancy_effect_service.apply_expiration_blast(
		Vector2.ZERO,
		0.0,
		func(_key: StringName, default_value: Variant) -> Variant:
			zero_expiration_callbacks[0] += 1
			return default_value,
		func(_position: Vector2, _radius: float) -> Array[Enemy]:
			zero_expiration_callbacks[1] += 1
			return []
	)
	_expect(not bool(zero_expiration_result.eligible) and StringName(zero_expiration_result.reason) == &"invalid_damage" and zero_expiration_callbacks == [0, 0], "nonpositive summon damage must skip expiration modifier lookup and spatial work", failures)
	var inactive_expiration_callbacks := [0, 0]
	var inactive_expiration_result := necromancy_effect_service.apply_expiration_blast(
		Vector2.ZERO,
		80.0,
		func(_key: StringName, _default_value: Variant) -> Variant:
			inactive_expiration_callbacks[0] += 1
			return false,
		func(_position: Vector2, _radius: float) -> Array[Enemy]:
			inactive_expiration_callbacks[1] += 1
			return []
	)
	_expect(not bool(inactive_expiration_result.eligible) and StringName(inactive_expiration_result.reason) == &"inactive_growth" and inactive_expiration_callbacks == [1, 0], "inactive expiration blasts must stop after eligibility lookup and before spatial work", failures)
	fear_first.free()
	fear_rejected.free()
	fear_inactive.free()
	fear_second.free()
	expiration_first.free()
	expiration_inactive.free()
	expiration_second.free()

	var skill_policy := CandidateCoreSkillPolicy.new()
	var amethyst_plan := skill_policy.build_plan(DataRegistry.get_core(&"amethyst"), {"candidate_summoning": true}, true, false)
	var jade_plan := skill_policy.build_plan(DataRegistry.get_core(&"jade"), {}, true, true)
	var jade_fallback_plan := skill_policy.build_plan(DataRegistry.get_core(&"jade"), {}, true, false)
	var sapphire_plan := skill_policy.build_plan(DataRegistry.get_core(&"sapphire"), {"charm_stage": true}, true, false)
	var emerald_plan := skill_policy.build_plan(DataRegistry.get_core(&"emerald"), {}, true, false)
	var obsidian_plan := skill_policy.build_plan(DataRegistry.get_core(&"obsidian"), {}, true, false)
	_expect(bool(amethyst_plan.mass_summon) and bool(amethyst_plan.replaces_native_skill) and skill_policy.title_for(DataRegistry.get_core(&"amethyst"), amethyst_plan, "핵") == "대규모 소환술", "candidate skill policy must replace Amethyst's wall with the mass summon and its title", failures)
	_expect(bool(jade_plan.death_wave) and not bool(jade_plan.uses_native_necromancy) and skill_policy.title_for(DataRegistry.get_core(&"jade"), jade_plan, "핵") == "죽음의 파도", "candidate skill policy must replace Jade's barrage and native spirit release with the death wave", failures)
	_expect(not bool(jade_fallback_plan.death_wave) and bool(jade_fallback_plan.uses_native_necromancy), "candidate skill policy must preserve Jade's native spirit release when the death-wave controller is unavailable", failures)
	_expect(bool(sapphire_plan.charm_zone) and bool(sapphire_plan.charm_stage_buff), "candidate skill policy must distinguish Sapphire's base zone from its branch army buff", failures)
	_expect(bool(emerald_plan.guard_active), "candidate skill policy must retain Emerald's guard active linkage", failures)
	_expect(bool(obsidian_plan.reaper_summon) and skill_policy.title_for(DataRegistry.get_core(&"obsidian"), obsidian_plan, "핵") == "사신 소환", "candidate skill policy must own Obsidian's reaper cast and title", failures)
static func _run_attack_execution_contracts(context: ContractContext, failures: Array[String]) -> void:
	var loadout := context.loadout
	var offer_service := context.offer_service
	var burn: Dictionary = context.burn
	var presentation := context.presentation
	var targeting := context.targeting
	var charm_profile := context.charm_profile
	var attack_policy := CandidateCoreAttackPolicy.new()
	var jade_attack_plan := attack_policy.build_plan(DataRegistry.get_core(&"jade"), DataRegistry.get_core(&"jade"), {}, true, false)
	var synthetic_jade_plan := attack_policy.build_plan(DataRegistry.get_core(&"jade"), DataRegistry.get_core(&"emerald"), {}, true, false)
	var kasuha_attack_plan := attack_policy.build_plan(DataRegistry.get_core(&"amethyst"), DataRegistry.get_core(&"amethyst"), {"core_attack_range": 1.35, "abyss_presence_radius": 1.45, "abyss_presence_hits": 4, "abyss_presence_damage": 0.72, "abyss_center_radius": 90.0, "abyss_center_damage": 1.4}, true, true)
	var jiane_attack_plan := attack_policy.build_plan(DataRegistry.get_core(&"sapphire"), DataRegistry.get_core(&"sapphire"), {"charm_radial": true, "charm_radial_targets": 5, "charm_radial_damage": 0.72, "core_pierce_width": 1.35}, true, false)
	_expect(bool(jade_attack_plan.replace_with_spirit) and not bool(synthetic_jade_plan.replace_with_spirit), "candidate attack policy must replace only Irelai's active core basic attack with a spirit request", failures)
	_expect(bool(kasuha_attack_plan.trigger_abyss_presence) and is_equal_approx(float(kasuha_attack_plan.attack_range_multiplier), 1.35) and int(kasuha_attack_plan.abyss_presence_hits) == 4 and is_equal_approx(float(kasuha_attack_plan.abyss_center_damage_multiplier), 1.4), "candidate attack policy must own Kasuha's presence, range, and center-hit tuning", failures)
	_expect(bool(jiane_attack_plan.charm_radial) and int(jiane_attack_plan.charm_radial_targets) == 5 and is_equal_approx(float(jiane_attack_plan.charm_radial_damage_multiplier), 0.72) and is_equal_approx(float(jiane_attack_plan.pierce_width_multiplier), 1.35), "candidate attack policy must own Jiane's radial charm and pierce-width tuning", failures)

	var tower_dispatch := TowerAttackDispatchPolicy.new()
	_expect(tower_dispatch.family_for(&"rapid") == &"projectile" and tower_dispatch.family_for(&"area") == &"projectile" and tower_dispatch.family_for(&"unique_single") == &"projectile", "tower dispatch policy must route all projectile behaviors through one execution family", failures)
	_expect(tower_dispatch.family_for(&"pierce") == &"pierce" and tower_dispatch.family_for(&"unique_pierce") == &"pierce", "tower dispatch policy must preserve the shared pierce family", failures)
	_expect(tower_dispatch.family_for(&"slow") == &"control" and tower_dispatch.family_for(&"chain") == &"network" and tower_dispatch.family_for(&"execute") == &"precision" and tower_dispatch.family_for(&"unique_random") == &"unique_field", "tower dispatch policy must expose stable extraction boundaries for remaining behavior families", failures)
	_expect(tower_dispatch.uses_projectile(&"rapid") and not tower_dispatch.uses_projectile(&"pierce"), "tower dispatch policy must preserve the projectile-versus-hitscan contract", failures)
	var network_service := ChainNetworkAttackExecutionService.new()
	var relay_candidates: Array[Vector2] = [Vector2(80.0, 0.0), Vector2(150.0, 0.0), Vector2(80.0, 60.0), Vector2(300.0, 0.0)]
	var planned_relay_path := network_service.build_path(Vector2.ZERO, 100.0, relay_candidates)
	_expect(planned_relay_path == [Vector2.ZERO, Vector2(80.0, 0.0), Vector2(80.0, 60.0), Vector2(150.0, 0.0)], "chain relay planning must greedily extend from the current endpoint and stop before the first disconnected remainder", failures)
	var tied_relay_candidates: Array[Vector2] = [Vector2(60.0, 0.0), Vector2(-60.0, 0.0)]
	var tied_relay_path := network_service.build_path(Vector2.ZERO, 60.0, tied_relay_candidates)
	_expect(tied_relay_path == [Vector2.ZERO, Vector2(60.0, 0.0)], "chain relay planning must preserve source collection order when candidates are equally distant", failures)
	var zero_range_relay_path := network_service.build_path(Vector2(12.0, 8.0), 0.0, relay_candidates)
	_expect(zero_range_relay_path == [Vector2(12.0, 8.0)], "chain relay planning without link range must retain only the source point", failures)
	var network_first := _active_enemy_at(Vector2(30.0, 0.0))
	var network_second := _active_enemy_at(Vector2(70.0, 0.0))
	var network_third := _active_enemy_at(Vector2(150.0, 0.0))
	var forward_segment_zero: Array[Enemy] = [network_first, network_second]
	var forward_segment_one: Array[Enemy] = [network_first, network_third]
	var return_segment_one: Array[Enemy] = [network_third, network_first]
	var return_segment_zero: Array[Enemy] = [network_second]
	var no_network_targets: Array[Enemy] = []
	var network_queries: Array[Dictionary] = []
	var network_forward_hits: Array[Dictionary] = []
	var network_return_hits: Array[Dictionary] = []
	var network_result := network_service.execute(
		[Vector2.ZERO, Vector2(100.0, 0.0), Vector2(200.0, 0.0)],
		100.0,
		1.5,
		{"relay_return": 0.5, "relay_return_falloff": 0.8},
		func(segment_start: Vector2, segment_end: Vector2, half_width: float) -> Array[Enemy]:
			network_queries.append({"start": segment_start, "end": segment_end, "half_width": half_width})
			if segment_start == Vector2.ZERO and segment_end == Vector2(100.0, 0.0):
				return forward_segment_zero
			if segment_start == Vector2(100.0, 0.0) and segment_end == Vector2(200.0, 0.0):
				return forward_segment_one
			if segment_start == Vector2(200.0, 0.0) and segment_end == Vector2(100.0, 0.0):
				return return_segment_one
			if segment_start == Vector2(100.0, 0.0) and segment_end == Vector2.ZERO:
				return return_segment_zero
			return no_network_targets,
		func(hit_target: Enemy, segment_origin: Vector2, hit_damage: float) -> float:
			network_forward_hits.append({"target": hit_target, "origin": segment_origin, "damage": hit_damage})
			return hit_damage,
		func(hit_target: Enemy, hit_damage: float) -> float:
			network_return_hits.append({"target": hit_target, "damage": hit_damage})
			return hit_damage
	)
	_expect(network_result.target == network_first and int(network_result.hit_count) == 3 and network_forward_hits.size() == 3, "chain network execution must select the first forward target and deduplicate enemies across relay segments", failures)
	_expect(is_equal_approx(float(network_forward_hits[0].damage), 150.0) and is_equal_approx(float(network_forward_hits[1].damage), 150.0) and is_equal_approx(float(network_forward_hits[2].damage), 129.0) and network_forward_hits[2].origin == Vector2(100.0, 0.0), "chain network execution must preserve forward segment origins and 0.86 damage falloff", failures)
	_expect(bool(network_result.return_triggered) and network_return_hits.size() == 3 and network_return_hits[0].target == network_third and network_return_hits[1].target == network_first and network_return_hits[2].target == network_second, "chain network return execution must traverse relay segments in reverse and preserve repeated hits", failures)
	_expect(is_equal_approx(float(network_return_hits[0].damage), 60.0) and is_equal_approx(float(network_return_hits[1].damage), 60.0) and is_equal_approx(float(network_return_hits[2].damage), 75.0) and is_equal_approx(float(network_result.dealt), 624.0), "chain network execution must preserve return falloff and aggregate forward plus return damage", failures)
	_expect(network_queries.size() == 4 and is_equal_approx(float(network_queries[0].half_width), ChainNetworkAttackExecutionService.SEGMENT_HALF_WIDTH) and network_queries[2].start == Vector2(200.0, 0.0), "chain network execution must query each forward and reverse segment with the stable corridor width", failures)
	var forward_only_state := {"queries": 0, "return_hits": 0}
	var forward_only_targets: Array[Enemy] = [network_first]
	var forward_only_result := network_service.execute(
		[Vector2.ZERO, Vector2(100.0, 0.0)],
		100.0,
		1.0,
		{},
		func(_segment_start: Vector2, _segment_end: Vector2, _half_width: float) -> Array[Enemy]:
			forward_only_state.queries = int(forward_only_state.queries) + 1
			return forward_only_targets,
		func(_hit_target: Enemy, _segment_origin: Vector2, hit_damage: float) -> float:
			return hit_damage,
		func(_hit_target: Enemy, hit_damage: float) -> float:
			forward_only_state.return_hits = int(forward_only_state.return_hits) + 1
			return hit_damage
	)
	_expect(not bool(forward_only_result.return_triggered) and int(forward_only_result.hit_count) == 1 and is_equal_approx(float(forward_only_result.dealt), 100.0) and int(forward_only_state.queries) == 1 and int(forward_only_state.return_hits) == 0, "chain network execution without relay-return modifiers must resolve only the forward path", failures)
	network_first.free()
	network_second.free()
	network_third.free()
	var precision_service := PrecisionAttackExecutionService.new()
	var precision_target := _active_enemy_at(Vector2(100.0, 0.0))
	var precision_collateral := _active_enemy_at(Vector2(50.0, 20.0))
	var precision_inactive := _active_enemy_at(Vector2(50.0, 0.0))
	precision_inactive.active = false
	var precision_outside := _active_enemy_at(Vector2(50.0, 40.0))
	var precision_enemy_data := context.precision_enemy_data
	precision_target.data = precision_enemy_data
	precision_collateral.data = precision_enemy_data
	precision_inactive.data = precision_enemy_data
	precision_outside.data = precision_enemy_data
	var precision_modifiers := {
		"armor_pierce": true,
		"execute_ratio": 0.16,
		"collateral_damage": 0.5,
		"collateral_width": 28.0,
		"execute_stun": 2.5,
		"execute_stun_radius": 120.0,
	}
	var precision_guard_overrides := {"execute_normal_multiplier": 1.2}
	var precision_profile := precision_service.build_execute_profile(precision_modifiers, precision_target, precision_guard_overrides, true)
	var default_precision_profile := precision_service.build_execute_profile({}, precision_target, {}, false)
	_expect(is_equal_approx(float(precision_profile.execute_ratio), 0.16) and precision_profile.execute_source == &"pierce" and precision_profile.guard_overrides == precision_guard_overrides and bool(precision_profile.sudden_death), "precision execution profiles must preserve armor-pierce source, threshold, guard overrides, and sudden-death state", failures)
	_expect(is_equal_approx(float(default_precision_profile.execute_ratio), PrecisionAttackExecutionService.DEFAULT_EXECUTE_RATIO) and default_precision_profile.execute_source == &"execute" and not bool(default_precision_profile.sudden_death), "precision execution profiles must preserve ordinary execute defaults", failures)
	var precision_events: Array[String] = []
	var stun_query_state := {"origin": Vector2.ZERO, "radius": 0.0}
	var precision_stun_targets: Array[Enemy] = [precision_target, precision_collateral, precision_outside]
	var precision_result := precision_service.execute_verdict(
		[precision_target, precision_collateral, precision_inactive, precision_outside],
		precision_target,
		Vector2.ZERO,
		100.0,
		precision_profile,
		{"damage": 200.0, "executed": true},
		func(hit_target: Enemy, verdict: Dictionary, profile: Dictionary) -> float:
			precision_events.append("primary")
			return float(verdict.damage) if hit_target == precision_target and profile == precision_profile else 0.0,
		func(hit_target: Enemy, hit_damage: float) -> float:
			precision_events.append("collateral")
			return hit_damage if hit_target == precision_collateral else 0.0,
		func(stun_origin: Vector2, stun_radius: float) -> Array[Enemy]:
			precision_events.append("stun_query")
			stun_query_state.origin = stun_origin
			stun_query_state.radius = stun_radius
			return precision_stun_targets
	)
	_expect(precision_result.target == precision_target and int(precision_result.hit_count) == 2 and is_equal_approx(float(precision_result.dealt), 250.0), "precision execution must aggregate one primary hit with only active in-corridor collateral targets", failures)
	_expect(precision_events == ["primary", "collateral", "stun_query"] and stun_query_state.origin == precision_target.global_position and is_equal_approx(float(stun_query_state.radius), 120.0), "precision execution must preserve primary, collateral, then post-execution stun ordering", failures)
	_expect(not precision_target.statuses.has(&"stun") and precision_collateral.statuses.has(&"stun") and precision_outside.statuses.has(&"stun") and not precision_inactive.statuses.has(&"stun"), "precision execution stun must exclude the primary target and apply to the queried neighbors", failures)
	var mark_target := _active_enemy_at(Vector2(140.0, 0.0))
	mark_target.data = precision_enemy_data
	var mark_state := {"had_mark_during_primary": false}
	var mark_result := precision_service.execute_mark(
		mark_target,
		80.0,
		{"mark_duration": 8.0, "hex_slow": 0.4},
		0.35,
		func(hit_target: Enemy, hit_damage: float) -> float:
			mark_state.had_mark_during_primary = hit_target.statuses.has(&"mark")
			return hit_damage
	)
	var applied_mark: Dictionary = mark_target.statuses.get(&"mark", {})
	var applied_slow: Dictionary = mark_target.statuses.get(&"slow", {})
	_expect(mark_result.target == mark_target and int(mark_result.hit_count) == 1 and is_equal_approx(float(mark_result.dealt), 80.0) and not bool(mark_state.had_mark_during_primary), "precision mark execution must apply the primary hit before vulnerability status", failures)
	_expect(is_equal_approx(float(applied_mark.get("remaining", 0.0)), 8.0) and is_equal_approx(float(applied_mark.get("power", 0.0)), 0.35) and is_equal_approx(float(applied_slow.get("power", 0.0)), 0.4), "precision mark execution must preserve configured duration, vulnerability power, and optional hex slow", failures)
	precision_target.free()
	precision_collateral.free()
	precision_inactive.free()
	precision_outside.free()
	mark_target.free()
	var control_service := ControlAttackExecutionService.new()
	var slow_primary := _active_enemy_at(Vector2(100.0, 0.0))
	var slow_secondary := _active_enemy_at(Vector2(120.0, 0.0))
	slow_primary.data = precision_enemy_data
	slow_secondary.data = precision_enemy_data
	slow_primary.current_health = 100.0
	slow_secondary.current_health = 100.0
	slow_primary.statuses[&"frost_stack"] = {"remaining": 4.0, "power": 1}
	var slow_modifiers := {"erosion_cycle": 2, "erosion_stun": 1.0, "frost_stack": 2, "frost_stun": 1.5}
	var slow_profile := control_service.build_slow_profile(3, slow_modifiers, 4, 0.6)
	var slow_events: Array[String] = []
	var slow_presentations: Array[Dictionary] = []
	var slow_result := control_service.execute_slow(
		[slow_primary, slow_secondary],
		slow_primary,
		Vector2.ZERO,
		&"contract_slow",
		slow_profile,
		func(status_target: Enemy) -> void:
			slow_events.append("common_primary" if status_target == slow_primary else "common_secondary"),
		func(hit_target: Enemy, hit_damage: float, strength: float) -> void:
			slow_events.append("present_primary" if hit_target == slow_primary else "present_secondary")
			slow_presentations.append({"target": hit_target, "damage": hit_damage, "strength": strength}),
		func(burst_target: Enemy) -> void:
			slow_events.append("burst_primary" if burst_target == slow_primary else "burst_secondary")
	)
	var primary_slow_status: Dictionary = slow_primary.statuses.get(&"slow", {})
	var secondary_frost_status: Dictionary = slow_secondary.statuses.get(&"frost_stack", {})
	_expect(bool(slow_profile.erosion_pulse) and is_equal_approx(float(slow_profile.slow_power), 0.6), "slow control profiles must preserve erosion-cycle timing and resolved slow power", failures)
	_expect(int(slow_result.hit_count) == 2 and is_equal_approx(float(slow_result.dealt), 36.0) and not slow_primary.statuses.has(&"frost_stack") and int(secondary_frost_status.get("power", 0)) == 1, "slow control execution must resolve completed frost damage while retaining incomplete stacks", failures)
	_expect(slow_events == ["common_primary", "burst_primary", "present_primary", "common_secondary", "present_secondary"] and slow_presentations.size() == 2 and is_equal_approx(float(slow_presentations[0].strength), 0.34) and is_equal_approx(float(slow_presentations[1].strength), 0.24), "slow control execution must preserve common-status, frost-burst, and primary-aware presentation ordering", failures)
	_expect(is_equal_approx(float(primary_slow_status.get("power", 0.0)), 0.6) and is_equal_approx(float(primary_slow_status.get("remaining", 0.0)), 2.19) and slow_primary.statuses.has(&"stun") and slow_secondary.statuses.has(&"stun"), "slow control execution must preserve level duration, power, and erosion stun application", failures)
	var knock_primary := _active_enemy_at(Vector2(50.0, 0.0))
	var knock_secondary := _active_enemy_at(Vector2(80.0, 0.0))
	for knock_target in [knock_primary, knock_secondary]:
		knock_target.data = precision_enemy_data
		knock_target.target_position = Vector2.ZERO
		knock_target.spawn_distance_limit = 200.0
	var knock_profile := control_service.build_knockback_profile(12.0, 10.0, {"overheat_cycle": 2, "overheat_duration": 1.4}, 4)
	var knock_events: Array[String] = []
	var knock_result := control_service.execute_knockback(
		[knock_primary, knock_secondary],
		knock_primary,
		Vector2.ZERO,
		knock_profile,
		func(hit_target: Enemy, hit_damage: float, show_presentation: bool, strength: float) -> float:
			knock_events.append("hit_primary" if hit_target == knock_primary else "hit_secondary")
			_expect(show_presentation and strength > 0.0, "knockback control contract fixtures must remain within the presentation budget", failures)
			return hit_damage,
		func(overheat_duration: float) -> void:
			knock_events.append("overheat:%.1f" % overheat_duration)
	)
	_expect(bool(knock_profile.overheat_triggered) and knock_events == ["hit_primary", "hit_secondary", "overheat:1.4"], "knockback control execution must resolve every contact before triggering scheduled overheat", failures)
	_expect(int(knock_result.hit_count) == 2 and is_equal_approx(float(knock_result.dealt), 24.0) and is_equal_approx(knock_primary.position.x, 60.0) and is_equal_approx(knock_secondary.position.x, 90.0), "knockback control execution must aggregate contact damage callbacks before applying configured push", failures)
	var golem_primary := _active_enemy_at(Vector2(100.0, 0.0))
	var golem_secondary := _active_enemy_at(Vector2(160.0, 0.0))
	for golem_target in [golem_primary, golem_secondary]:
		golem_target.data = precision_enemy_data
		golem_target.target_position = Vector2.ZERO
		golem_target.spawn_distance_limit = 220.0
	var golem_targets: Array[Enemy] = [golem_primary, golem_secondary]
	var golem_profile := control_service.build_golem_profile({"gather": 0.5, "self_recoil": 0.25}, Vector2.ZERO, golem_targets, 20.0)
	var golem_events: Array[String] = []
	var golem_recoil_state := {"threat_position": Vector2.ZERO, "factor": 0.0}
	var golem_result := control_service.execute_golem(
		golem_primary,
		golem_profile,
		func(control_target: Enemy, control_distance: float) -> void:
			golem_events.append("control_primary" if control_target == golem_primary else "control_secondary")
			_expect(is_equal_approx(control_distance, 10.0), "golem gather fixtures must preserve configured displacement", failures),
		func(hit_target: Enemy, _hit_damage: float, strength: float) -> void:
			golem_events.append("present_primary" if hit_target == golem_primary else "present_secondary")
			_expect(is_equal_approx(strength, 0.52 if hit_target == golem_primary else 0.32), "golem presentation strength must distinguish the primary target", failures),
		func(threat_position: Vector2, recoil_factor: float) -> float:
			golem_events.append("recoil")
			golem_recoil_state.threat_position = threat_position
			golem_recoil_state.factor = recoil_factor
			return 3.0
	)
	_expect(int(golem_result.hit_count) == 2 and golem_result.origin == Vector2.ZERO and is_equal_approx(golem_primary.position.x, 90.0) and is_equal_approx(golem_secondary.position.x, 150.0), "golem control execution must gather every target toward the impact origin", failures)
	_expect(golem_events == ["control_primary", "present_primary", "control_secondary", "present_secondary", "recoil"] and golem_recoil_state.threat_position == golem_primary.global_position and is_equal_approx(float(golem_recoil_state.factor), 0.25), "golem control execution must preserve control, presentation, then post-hit self-recoil ordering", failures)
	slow_primary.free()
	slow_secondary.free()
	knock_primary.free()
	knock_secondary.free()
	golem_primary.free()
	golem_secondary.free()
	var pierce_service := PierceAttackExecutionService.new()
	var power_shot_modifiers := {
		"power_shot_hits": 5,
		"power_shot_width": 2.0,
		"power_shot_damage": 1.5,
		"missing_health": 0.5,
	}
	var power_shot_profile := pierce_service.build_band_profile(&"pierce", power_shot_modifiers, 10)
	var ordinary_pierce_profile := pierce_service.build_band_profile(&"pierce", power_shot_modifiers, 9)
	var unique_pierce_profile := pierce_service.build_band_profile(&"unique_pierce", power_shot_modifiers, 10)
	_expect(bool(power_shot_profile.power_shot) and is_equal_approx(float(power_shot_profile.width), 48.0) and is_equal_approx(float(power_shot_profile.damage_multiplier), 1.5), "pierce profiles must preserve scheduled power-shot width and damage multipliers", failures)
	_expect(not bool(ordinary_pierce_profile.power_shot) and is_equal_approx(float(ordinary_pierce_profile.width), PierceAttackExecutionService.DEFAULT_BAND_WIDTH), "ordinary pierce profiles must retain the default corridor outside power-shot intervals", failures)
	_expect(not bool(unique_pierce_profile.power_shot) and is_equal_approx(float(unique_pierce_profile.width), PierceAttackExecutionService.UNIQUE_BAND_WIDTH), "unique pierce profiles must retain their wider corridor without inheriting Orc power shots", failures)
	var pierce_targets: Array[Enemy] = []
	for target_x in [70.0, 10.0, 20.0, 30.0, 40.0, 50.0, 60.0]:
		var pierce_target := _active_enemy_at(Vector2(target_x, 0.0))
		pierce_target.data = precision_enemy_data
		pierce_target.current_health = 50.0 if is_equal_approx(target_x, 20.0) else 100.0
		pierce_targets.append(pierce_target)
	var pierce_query_state := {"width": 0.0}
	var pierce_hits: Array[Dictionary] = []
	var pierce_result := pierce_service.execute_band(
		Vector2.ZERO,
		Vector2(100.0, 0.0),
		100.0,
		power_shot_profile,
		func(_origin: Vector2, _beam_end: Vector2, width: float) -> Array[Enemy]:
			pierce_query_state.width = width
			return pierce_targets,
		func(hit_target: Enemy, hit_damage: float, show_presentation: bool, strength: float) -> float:
			pierce_hits.append({"target": hit_target, "damage": hit_damage, "show_presentation": show_presentation, "strength": strength})
			return hit_damage
	)
	_expect(int(pierce_result.hit_count) == 7 and is_equal_approx(float(pierce_result.dealt), 1087.5) and is_equal_approx(float(pierce_query_state.width), 48.0), "pierce band execution must aggregate scheduled damage and query the resolved corridor width", failures)
	_expect(pierce_hits[0].target.global_position.x == 10.0 and pierce_hits[1].target.global_position.x == 20.0 and pierce_hits[6].target.global_position.x == 70.0 and is_equal_approx(float(pierce_hits[1].damage), 187.5), "pierce band execution must resolve targets from beam origin and preserve missing-health scaling", failures)
	_expect(bool(pierce_hits[5].show_presentation) and not bool(pierce_hits[6].show_presentation) and is_equal_approx(float(pierce_hits[0].strength), 0.86), "pierce band execution must preserve the six-hit presentation budget and power-shot strength", failures)
	var explosive_plan := pierce_service.build_explosive_plan(&"pierce", {"explosive_arrow": true, "explosion_damage": 1.4, "explosion_radius": 100.0, "explosion_delay": 0.4}, pierce_targets[0], 200.0)
	var blocked_explosive_plan := pierce_service.build_explosive_plan(&"unique_pierce", {"explosive_arrow": true}, pierce_targets[0], 200.0)
	_expect(bool(explosive_plan.deferred) and explosive_plan.position == pierce_targets[0].global_position and is_equal_approx(float(explosive_plan.damage), 280.0) and is_equal_approx(float(explosive_plan.radius), 100.0) and is_equal_approx(float(explosive_plan.delay), 0.4), "explosive-arrow plans must capture delayed impact position, scaled damage, radius, and delay", failures)
	_expect(not bool(blocked_explosive_plan.deferred), "unique pierce attacks must not inherit the Orc explosive-arrow branch", failures)
	var explosion_targets: Array[Enemy] = []
	for target_x in [0.0, 50.0, 100.0]:
		explosion_targets.append(_active_enemy_at(Vector2(target_x, 0.0)))
	var explosion_events: Array[String] = []
	var explosion_query_state := {"position": Vector2.INF, "radius": 0.0}
	var explosion_hits: Array[Dictionary] = []
	var explosion_result := pierce_service.resolve_deferred_explosion(
		{"deferred": true, "position": Vector2.ZERO, "damage": 200.0, "radius": 100.0, "delay": 0.0},
		func() -> bool:
			explosion_events.append("active")
			return true,
		func() -> Array[Enemy]:
			explosion_events.append("snapshot")
			return explosion_targets,
		func(position: Vector2, radius: float) -> Array[Enemy]:
			explosion_events.append("query")
			explosion_query_state.position = position
			explosion_query_state.radius = radius
			return explosion_targets,
		func(hit_target: Enemy, hit_damage: float, show_presentation: bool) -> float:
			explosion_events.append("hit")
			explosion_hits.append({"target": hit_target, "damage": hit_damage, "show_presentation": show_presentation})
			return hit_damage
	)
	_expect(bool(explosion_result.completed) and not bool(explosion_result.cancelled) and int(explosion_result.hit_count) == 3 and is_equal_approx(float(explosion_result.dealt), 474.0), "deferred explosive-arrow execution must aggregate radial falloff damage", failures)
	_expect(explosion_events == ["active", "snapshot", "query", "hit", "hit", "hit"] and explosion_query_state.position == Vector2.ZERO and is_equal_approx(float(explosion_query_state.radius), 100.0), "deferred explosive arrows must validate execution before snapshotting, querying, and applying hits in order", failures)
	_expect((explosion_result.tracked_targets as Array) == explosion_targets and (explosion_result.targets as Array) == explosion_targets and is_equal_approx(float(explosion_result.delay), PierceAttackExecutionService.MIN_EXPLOSION_DELAY), "deferred explosive arrows must retain the pre-hit enemy snapshot, queried targets, and minimum pause-aware delay", failures)
	_expect(is_equal_approx(float(explosion_hits[0].damage), 200.0) and is_equal_approx(float(explosion_hits[1].damage), 158.0) and is_equal_approx(float(explosion_hits[2].damage), 116.0), "explosive-arrow execution must preserve center-to-edge damage falloff", failures)
	var cancelled_explosion_events: Array[String] = []
	var cancelled_explosion_result := pierce_service.resolve_deferred_explosion(
		explosive_plan,
		func() -> bool:
			cancelled_explosion_events.append("active")
			return false,
		func() -> Array[Enemy]:
			cancelled_explosion_events.append("snapshot")
			return explosion_targets,
		func(_position: Vector2, _radius: float) -> Array[Enemy]:
			cancelled_explosion_events.append("query")
			return explosion_targets,
		func(_hit_target: Enemy, hit_damage: float, _show_presentation: bool) -> float:
			cancelled_explosion_events.append("hit")
			return hit_damage
	)
	_expect(not bool(cancelled_explosion_result.completed) and bool(cancelled_explosion_result.cancelled) and cancelled_explosion_events == ["active"], "cancelled explosive arrows must stop before enemy snapshots, spatial queries, or damage", failures)
	for pierce_target in pierce_targets:
		pierce_target.free()
	for explosion_target in explosion_targets:
		explosion_target.free()
	var projectile_service := ProjectileAttackExecutionService.new()
	var rapid_volley_profile := projectile_service.build_volley_profile(
		&"rapid",
		100.0,
		{"volley_shots": 5, "volley_damage": 0.8, "warcry_interval": 5, "warcry_damage": 1.6},
		10
	)
	var ordinary_volley_profile := projectile_service.build_volley_profile(&"area", 100.0, {"volley_shots": 3}, 10)
	_expect(int(rapid_volley_profile.count) == 3 and bool(rapid_volley_profile.warcry_triggered) and is_equal_approx(float(rapid_volley_profile.damage), 128.0), "projectile volley profiles must clamp rapid shots and compose volley plus scheduled warcry damage", failures)
	_expect(int(ordinary_volley_profile.count) == 1 and not bool(ordinary_volley_profile.warcry_triggered) and is_equal_approx(float(ordinary_volley_profile.damage), 100.0), "non-rapid projectile profiles must ignore rapid-only volley modifiers", failures)
	var rapid_motion_profile := projectile_service.build_motion_profile(&"rapid", 2, Color("804020"))
	var area_motion_profile := projectile_service.build_motion_profile(&"area", 0, Color.WHITE)
	var unique_motion_profile := projectile_service.build_motion_profile(&"unique_single", 0, Color("804020"))
	_expect(is_equal_approx(float(rapid_motion_profile.speed), 790.0) and is_equal_approx(float(rapid_motion_profile.length), 36.0), "rapid projectile motion must preserve bounded per-volley speed and length offsets", failures)
	_expect(is_equal_approx(float(area_motion_profile.speed), 320.0) and is_equal_approx(float(area_motion_profile.length), 46.0) and bool(area_motion_profile.uses_artillery_fallback), "area projectile motion must preserve artillery speed, length, and fallback identity", failures)
	_expect(is_equal_approx(float(unique_motion_profile.speed), 760.0) and is_equal_approx(float(unique_motion_profile.length), 44.0) and unique_motion_profile.tint != Color.WHITE, "unique projectile motion must preserve its fast, long, tower-tinted profile", failures)
	var area_execution_targets: Array[Enemy] = []
	for target_x in [100.0, 80.0, 60.0, 40.0, 20.0, 0.0]:
		area_execution_targets.append(_active_enemy_at(Vector2(target_x, 0.0)))
	var area_execution_events: Array[String] = []
	var area_execution_hits: Array[Dictionary] = []
	var area_query_state := {"position": Vector2.ZERO, "radius": 0.0}
	var area_execution_result := projectile_service.execute_area(
		Vector2.ZERO,
		100.0,
		200.0,
		{"edge_damage": 0.5},
		func(query_position: Vector2, query_radius: float) -> Array[Enemy]:
			area_query_state.position = query_position
			area_query_state.radius = query_radius
			return area_execution_targets,
		func(hit_target: Enemy, hit_damage: float, show_presentation: bool, strength: float) -> float:
			area_execution_events.append("hit:%d" % int(hit_target.global_position.x))
			area_execution_hits.append({"target": hit_target, "damage": hit_damage, "show_presentation": show_presentation, "strength": strength})
			return hit_damage,
		func(followup_targets: Array[Enemy]) -> float:
			area_execution_events.append("followup")
			return 25.0 if followup_targets == area_execution_targets else 0.0,
		func(closest_targets: Array[Enemy], closest_position: Vector2) -> Enemy:
			area_execution_events.append("closest")
			return area_execution_targets.back() if closest_targets == area_execution_targets and closest_position == Vector2.ZERO else null
	)
	_expect(int(area_execution_result.hit_count) == 6 and is_equal_approx(float(area_execution_result.dealt), 925.0) and area_execution_result.hit_target == area_execution_targets.back(), "area projectile execution must aggregate radial hits, post-hit followups, and closest impact target", failures)
	_expect(area_query_state.position == Vector2.ZERO and is_equal_approx(float(area_query_state.radius), 100.0) and area_execution_events == ["hit:100", "hit:80", "hit:60", "hit:40", "hit:20", "hit:0", "followup", "closest"], "area projectile execution must preserve spatial query and hit-before-followup ordering", failures)
	_expect(is_equal_approx(float(area_execution_hits[0].damage), 100.0) and is_equal_approx(float(area_execution_hits[5].damage), 200.0) and bool(area_execution_hits[4].show_presentation) and not bool(area_execution_hits[5].show_presentation), "area projectile execution must preserve edge falloff and the five-hit presentation budget", failures)
	_expect((area_execution_result.impact_points as Array).size() == 7 and is_equal_approx(float(area_execution_hits[0].strength), 0.48) and is_equal_approx(float(area_execution_hits[5].strength), 0.70), "area projectile execution must preserve bounded impact traces and distance-aware presentation strength", failures)
	var direct_execution_target := _active_enemy_at(Vector2(60.0, 0.0))
	var direct_execution_events: Array[String] = []
	var direct_execution_result := projectile_service.execute_direct(
		direct_execution_target,
		Vector2(60.0, 0.0),
		24.0,
		120.0,
		func(hit_target: Enemy, hit_damage: float) -> float:
			direct_execution_events.append("damage")
			return hit_damage if hit_target == direct_execution_target else 0.0,
		func(_hit_target: Enemy, _hit_damage: float) -> void:
			direct_execution_events.append("status"),
		func(_hit_target: Enemy, _hit_damage: float, dealt: float) -> void:
			direct_execution_events.append("behavior:%.0f" % dealt),
		func(_hit_target: Enemy, _hit_damage: float) -> void:
			direct_execution_events.append("presentation"),
		func(_hit_target: Enemy, _hit_damage: float) -> float:
			direct_execution_events.append("followup")
			return 30.0
	)
	_expect(not bool(direct_execution_result.terminal_miss) and int(direct_execution_result.hit_count) == 1 and is_equal_approx(float(direct_execution_result.dealt), 150.0), "direct projectile execution must aggregate the primary hit and post-hit followup", failures)
	_expect(direct_execution_events == ["damage", "status", "behavior:120", "presentation", "followup"] and (direct_execution_result.impact_points as Array) == [Vector2(60.0, 0.0)], "direct projectile execution must preserve damage, status, behavior, presentation, then followup ordering", failures)
	var terminal_miss_result := projectile_service.execute_direct(null, Vector2.ZERO, 0.0, 120.0, Callable(), Callable(), Callable(), Callable(), Callable())
	_expect(bool(terminal_miss_result.terminal_miss), "direct projectile execution must reject terminal impacts without an active target before invoking callbacks", failures)
	for area_execution_target in area_execution_targets:
		area_execution_target.free()
	direct_execution_target.free()
static func _run_skeleton_and_branch_contracts(context: ContractContext, failures: Array[String]) -> void:
	var loadout := context.loadout
	var offer_service := context.offer_service
	var burn: Dictionary = context.burn
	var presentation := context.presentation
	var targeting := context.targeting
	var charm_profile := context.charm_profile
	var precision_enemy_data := context.precision_enemy_data
	var skeleton_followup_service := SkeletonAreaFollowupService.new()
	var skeleton_lightning_a := _active_enemy_at(Vector2(40.0, 0.0))
	var skeleton_lightning_b := _active_enemy_at(Vector2(80.0, 0.0))
	var skeleton_inactive := _active_enemy_at(Vector2(120.0, 0.0))
	skeleton_inactive.active = false
	var skeleton_targets: Array[Enemy] = [skeleton_lightning_a, skeleton_inactive, skeleton_lightning_b]
	var skeleton_events: Array[String] = []
	var skeleton_sources: Array[StringName] = []
	var skeleton_damage_callback := func(target: Enemy, hit_damage: float, source: StringName) -> float:
		skeleton_events.append("damage:a" if target == skeleton_lightning_a else "damage:b")
		skeleton_sources.append(source)
		return hit_damage if target == skeleton_lightning_a else 40.0
	var skeleton_presentation_callback := func(target: Enemy) -> void:
		skeleton_events.append("present:a" if target == skeleton_lightning_a else "present:b")
	var skeleton_followup_result := skeleton_followup_service.execute(
		skeleton_targets,
		200.0,
		{"fire_zone_duration": 3.5, "bone_shard_count": 5, "lightning_damage": 0.25},
		func() -> void: skeleton_events.append("fire"),
		func() -> void: skeleton_events.append("shards"),
		skeleton_damage_callback,
		skeleton_presentation_callback
	)
	var skeleton_lightning_hits: Array[Enemy] = []
	skeleton_lightning_hits.assign(skeleton_followup_result.lightning_hit_targets as Array)
	_expect(bool(skeleton_followup_result.fire_zone_requested) and bool(skeleton_followup_result.bone_shards_requested) and bool(skeleton_followup_result.lightning_requested), "skeleton area followups must request fire, shards, and lightning from one ordered execution boundary", failures)
	_expect(is_equal_approx(float(skeleton_followup_result.lightning_damage), 50.0) and is_equal_approx(float(skeleton_followup_result.lightning_dealt), 90.0), "skeleton lightning must scale from attack damage and report actual applied damage rather than potential target-array damage", failures)
	_expect(skeleton_lightning_hits == [skeleton_lightning_a, skeleton_lightning_b] and skeleton_sources == [&"common_shock", &"common_shock"], "skeleton lightning must skip inactive targets and retain the fixed common-shock source", failures)
	_expect(skeleton_events == ["fire", "shards", "damage:a", "present:a", "damage:b", "present:b"], "skeleton followups must preserve fire, shard, then per-target lightning damage and presentation order", failures)
	var invalid_skeleton_result := skeleton_followup_service.execute(skeleton_targets, 200.0, {"fire_zone_duration": 3.5, "bone_shard_count": 5, "lightning_damage": 0.25}, Callable(), Callable(), Callable(), Callable())
	_expect(not bool(invalid_skeleton_result.fire_zone_requested) and not bool(invalid_skeleton_result.bone_shards_requested) and not bool(invalid_skeleton_result.lightning_requested) and skeleton_events.size() == 6, "invalid skeleton collaborators must not report or execute partial followup requests", failures)
	skeleton_lightning_a.free()
	skeleton_lightning_b.free()
	skeleton_inactive.free()

	var fire_zone_service := SkeletonFireZoneService.new()
	var fire_zone_profile := fire_zone_service.build_profile(
		42,
		7,
		200.0,
		{"fire_zone_duration": 2.1, "fire_zone_radius": 90.0, "fire_zone_burn_ratio": 0.08},
		{"damage_ratio": 0.15, "duration": 6.0, "max_stacks": 3, "minimum_decay_ratio": 0.4, "reset_decay_on_reapply": false}
	)
	_expect(is_equal_approx(float(fire_zone_profile.duration), 2.1) and is_equal_approx(float(fire_zone_profile.radius), 90.0) and fire_zone_profile.source_key == &"skeleton_fire_zone:42:7", "skeleton fire zones must build stable owner-and-serial profiles with configured duration and radius", failures)
	_expect(is_equal_approx(float(fire_zone_profile.burn_damage), 30.0) and is_equal_approx(float(fire_zone_profile.burn_duration), 6.0) and int(fire_zone_profile.burn_stacks) == 3 and is_equal_approx(float(fire_zone_profile.burn_minimum_decay), 0.4) and not bool(fire_zone_profile.burn_reset_decay), "skeleton fire zones must merge the stronger common burn profile into each zone", failures)
	_expect(int(fire_zone_profile.tick_count) == 9 and fire_zone_service.tick_count_for_duration(0.0) == 0, "skeleton fire-zone lifetimes must resolve to bounded quarter-second tick counts", failures)
	var fire_enemy_data := EnemyData.new()
	fire_enemy_data.max_health = 100.0
	var fire_new := _active_enemy_at(Vector2(20.0, 0.0))
	var fire_reignited := _active_enemy_at(Vector2(40.0, 0.0))
	var fire_inactive := _active_enemy_at(Vector2(60.0, 0.0))
	var fire_late := _active_enemy_at(Vector2(70.0, 0.0))
	for fire_enemy in [fire_new, fire_reignited, fire_inactive, fire_late]:
		fire_enemy.data = fire_enemy_data
		fire_enemy.current_health = 100.0
	fire_inactive.active = false
	fire_reignited.apply_common_burn(&"existing_burn", 5.0, 4.0, 3)
	var fire_query_targets: Array[Enemy] = [fire_new, fire_reignited, fire_inactive]
	var fire_query_state := {"calls": 0, "position": Vector2.ZERO, "radius": 0.0}
	var fire_events: Array[Dictionary] = []
	var fire_affected_ids: Dictionary = {}
	var fire_query_callback := func(position: Vector2, radius: float) -> Array[Enemy]:
		fire_query_state.calls += 1
		fire_query_state.position = position
		fire_query_state.radius = radius
		return fire_query_targets
	var first_fire_tick := fire_zone_service.apply_tick(Vector2(10.0, 5.0), fire_zone_profile, fire_affected_ids, fire_query_callback, func(event: Dictionary) -> void: fire_events.append(event))
	var second_fire_tick := fire_zone_service.apply_tick(Vector2(10.0, 5.0), fire_zone_profile, fire_affected_ids, fire_query_callback, func(event: Dictionary) -> void: fire_events.append(event))
	fire_query_targets.append(fire_late)
	var third_fire_tick := fire_zone_service.apply_tick(Vector2(10.0, 5.0), fire_zone_profile, fire_affected_ids, fire_query_callback, func(event: Dictionary) -> void: fire_events.append(event))
	_expect(int(first_fire_tick.burns) == 2 and int(second_fire_tick.burns) == 0 and int(third_fire_tick.burns) == 1 and fire_affected_ids.size() == 3, "one skeleton fire zone must burn each active enemy once while accepting enemies that enter on later ticks", failures)
	_expect(fire_events.size() == 3 and not bool(fire_events[0].reignited) and bool(fire_events[1].reignited) and not bool(fire_events[2].reignited), "skeleton fire zones must distinguish new burns from pre-existing burn reignitions", failures)
	_expect(fire_query_state.calls == 3 and fire_query_state.position == Vector2(10.0, 5.0) and is_equal_approx(float(fire_query_state.radius), 90.0), "skeleton fire-zone ticks must reuse the exact zone center and radius", failures)
	var applied_fire: Dictionary = fire_new.common_ailments.get(&"burn", {})
	_expect(applied_fire.last_source_type == &"skeleton_fire_zone:42:7" and int((applied_fire.stacks as Array).size()) == 1 and is_equal_approx(float((applied_fire.stacks as Array)[0]), 30.0) and not fire_inactive.has_common_ailment(&"burn"), "skeleton fire zones must apply their stable source and merged damage without touching inactive enemies", failures)
	for fire_enemy in [fire_new, fire_reignited, fire_inactive, fire_late]:
		fire_enemy.free()

	var bone_shard_service := SkeletonBoneShardService.new()
	var bone_shard_column := TowerColumn.new()
	var bone_shard_tower := TowerData.new()
	bone_shard_tower.color = Color(0.2, 0.4, 0.6)
	var bone_shard_spatial_index := EnemySpatialIndex.new()
	var bone_shard_random_values: Array[float] = [0.5, -0.18, 0.0, 0.18]
	var bone_shard_random_calls: Array[Vector2] = []
	var bone_shard_plan := bone_shard_service.build_spawn_plan(
		bone_shard_column,
		3,
		bone_shard_tower,
		Vector2(10.0, 20.0),
		120.0,
		{"bone_shard_count": 3, "bone_shard_range": 180.0, "bone_shard_damage": 0.25},
		bone_shard_spatial_index,
		func(minimum: float, maximum: float) -> float:
			bone_shard_random_calls.append(Vector2(minimum, maximum))
			return bone_shard_random_values.pop_front()
	)
	var bone_shards: Array = bone_shard_plan.shards
	_expect(bool(bone_shard_plan.applied) and int(bone_shard_plan.count) == 3 and bone_shards.size() == 3, "skeleton bone shards must build one projectile request per configured shard", failures)
	_expect(bone_shard_random_calls == [Vector2(0.0, TAU), Vector2(-0.18, 0.18), Vector2(-0.18, 0.18), Vector2(-0.18, 0.18)], "skeleton bone shards must consume one starting angle before one jitter roll per shard", failures)
	var expected_bone_shard_angles: Array[float] = [0.32, 0.5 + TAU / 3.0, 0.5 + TAU * 2.0 / 3.0 + 0.18]
	var bone_shard_geometry_valid := true
	for bone_shard_index in bone_shards.size():
		var bone_shard_request: Dictionary = bone_shards[bone_shard_index]
		var expected_target := Vector2(10.0, 20.0) + Vector2.from_angle(expected_bone_shard_angles[bone_shard_index]) * 180.0
		bone_shard_geometry_valid = bone_shard_geometry_valid and (bone_shard_request.origin as Vector2).is_equal_approx(Vector2(10.0, 20.0)) and (bone_shard_request.target as Vector2).is_equal_approx(expected_target) and is_equal_approx(float(bone_shard_request.max_distance), 180.0)
	_expect(bone_shard_geometry_valid, "skeleton bone shards must preserve evenly spaced angles, per-shard jitter, range, and origin", failures)
	var first_bone_shard: Dictionary = bone_shards[0]
	var first_bone_shard_payload: Dictionary = first_bone_shard.payload
	_expect(is_equal_approx(float(first_bone_shard.speed), 520.0) and is_equal_approx(float(first_bone_shard.length), 22.0) and first_bone_shard.color == bone_shard_tower.color.lightened(0.22), "skeleton bone shards must preserve projectile presentation and movement settings", failures)
	_expect(first_bone_shard_payload.column == bone_shard_column and first_bone_shard_payload.tower == bone_shard_tower and int(first_bone_shard_payload.row_index) == 3 and first_bone_shard_payload.spatial_index == bone_shard_spatial_index, "skeleton bone-shard payloads must retain their tower execution collaborators", failures)
	_expect(first_bone_shard_payload.behavior == &"area_shard" and is_equal_approx(float(first_bone_shard_payload.damage), 30.0) and int(first_bone_shard_payload.max_hits) == 1 and first_bone_shard_payload.collision_mode == &"path" and first_bone_shard_payload.origin == Vector2(10.0, 20.0), "skeleton bone-shard payloads must preserve path collision, single-hit damage, and impact origin", failures)
	var invalid_bone_shard_plan := bone_shard_service.build_spawn_plan(bone_shard_column, 3, bone_shard_tower, Vector2.ZERO, 120.0, {}, bone_shard_spatial_index, Callable())
	_expect(not bool(invalid_bone_shard_plan.applied) and int(invalid_bone_shard_plan.count) == 0 and (invalid_bone_shard_plan.shards as Array).is_empty(), "skeleton bone shards must reject missing randomness collaborators before building a partial spawn plan", failures)
	bone_shard_column.free()

	var abyss_summon_attack_service := AbyssSummonAttackService.new()
	var abyss_attack_column := TowerColumn.new()
	abyss_attack_column.is_guard_formation = true
	abyss_attack_column.formation_data = TowerFormationData.new()
	abyss_attack_column.formation_data.id = &"amethyst_nova_guard"
	var abyss_attack_tower := TowerData.new()
	abyss_attack_tower.id = &"slow"
	abyss_attack_tower.color = Color("7fe8df")
	var abyss_attack_summon := AbyssSummon.new()
	abyss_attack_summon.position = Vector2(24.0, 12.0)
	var abyss_attack_enemy_data := EnemyData.new()
	abyss_attack_enemy_data.max_health = 50.0
	var abyss_attack_target := _active_enemy_at(Vector2(30.0, 12.0))
	abyss_attack_target.data = abyss_attack_enemy_data
	abyss_attack_target.current_health = 50.0
	var abyss_attack_events: Array[String] = []
	abyss_attack_target.damage_received.connect(func(amount: float, source: StringName, _data: EnemyData) -> void: abyss_attack_events.append("damage:%.0f:%s" % [amount, source]))
	var abyss_attack_result := abyss_summon_attack_service.execute(
		true,
		abyss_attack_summon,
		abyss_attack_target,
		60.0,
		abyss_attack_column,
		abyss_attack_tower,
		func(tower_id: StringName, formation_id: StringName) -> void: abyss_attack_events.append("attack:%s:%s" % [tower_id, formation_id])
	)
	_expect(bool(abyss_attack_result.applied) and is_equal_approx(float(abyss_attack_result.dealt), 50.0) and int(abyss_attack_result.kills) == 1 and int(abyss_attack_result.hit_count) == 1, "abyss summon attacks must report actual contact damage and direct kills", failures)
	_expect(abyss_attack_result.tower_id == &"slow" and abyss_attack_result.formation_id == &"amethyst_nova_guard", "abyss summon attacks must attribute results to the source tower and guard formation", failures)
	_expect(abyss_attack_events == ["attack:slow:amethyst_nova_guard", "damage:50:abyss_summon"], "abyss summon attacks must record the source attack before applying fixed-source contact damage", failures)
	var rejected_abyss_attack := abyss_summon_attack_service.execute(true, abyss_attack_summon, abyss_attack_target, 60.0, abyss_attack_column, abyss_attack_tower, func(_tower_id: StringName, _formation_id: StringName) -> void: abyss_attack_events.append("rejected"))
	_expect(not bool(rejected_abyss_attack.applied) and abyss_attack_events.size() == 2, "abyss summon attacks must reject inactive targets without recording attack attempts", failures)
	var candidate_abyss_target := _active_enemy_at(Vector2(36.0, 12.0))
	candidate_abyss_target.data = abyss_attack_enemy_data
	candidate_abyss_target.current_health = 50.0
	var candidate_abyss_events: Array[String] = []
	candidate_abyss_target.damage_received.connect(func(amount: float, source: StringName, _data: EnemyData) -> void: candidate_abyss_events.append("damage:%.0f:%s" % [amount, source]))
	var candidate_abyss_result := abyss_summon_attack_service.execute_candidate(true, abyss_attack_summon, candidate_abyss_target, 30.0)
	_expect(bool(candidate_abyss_result.applied) and is_equal_approx(float(candidate_abyss_result.dealt), 30.0) and int(candidate_abyss_result.kills) == 0 and int(candidate_abyss_result.hit_count) == 1, "candidate abyss summons must report actual nonlethal contact damage", failures)
	_expect(candidate_abyss_result.source == &"core_abyss_summon" and bool(candidate_abyss_result.is_area) and candidate_abyss_events == ["damage:30:core_abyss_summon"], "candidate abyss summons must preserve their area-tagged core damage source", failures)
	var blocked_candidate_abyss_result := abyss_summon_attack_service.execute_candidate(false, abyss_attack_summon, candidate_abyss_target, 30.0)
	_expect(not bool(blocked_candidate_abyss_result.applied) and is_equal_approx(candidate_abyss_target.current_health, 20.0) and candidate_abyss_events.size() == 1, "candidate abyss summons must reject attacks after the game becomes inactive", failures)
	var candidate_swarm_service := CandidateAbyssSwarmService.new()
	var candidate_swarm_modifiers := {
		&"candidate_summon_count": 10,
		&"candidate_summon_cap": 8,
		&"candidate_summon_duration": 9.0,
		&"candidate_summon_interval": 0.8,
		&"candidate_summon_damage": 40.0,
		&"candidate_summon_radius": 1000.0,
		&"core_skill_range": 1.5,
	}
	var candidate_swarm_profile := candidate_swarm_service.build_profile(
		func(key: StringName, default_value: Variant) -> Variant: return candidate_swarm_modifiers.get(key, default_value),
		{"completed_slots": {&"first": true, &"branch": true, &"final": true}},
		1.2
	)
	_expect(bool(candidate_swarm_profile.valid) and int(candidate_swarm_profile.requested) == 10 and int(candidate_swarm_profile.cap) == 8, "candidate abyss swarm profiles must preserve requested summons and the shared active cap", failures)
	_expect(is_equal_approx(float(candidate_swarm_profile.duration), 9.0) and is_equal_approx(float(candidate_swarm_profile.interval), 0.8), "candidate abyss swarm profiles must preserve summon lifetime and attack cadence", failures)
	_expect(is_equal_approx(float(candidate_swarm_profile.damage), 69.6) and is_equal_approx(float(candidate_swarm_profile.radius), 1500.0), "candidate abyss swarm profiles must compose completed growth slots with core-skill damage and range multipliers", failures)
	var candidate_swarm_requests: Array[Dictionary] = []
	var candidate_swarm_targets: Array[Enemy] = [candidate_abyss_target]
	var candidate_swarm_color := Color("55c86b")
	var candidate_swarm_spawn_result := candidate_swarm_service.execute(
		candidate_swarm_profile,
		candidate_swarm_color,
		candidate_swarm_targets,
		func(requested: int, cap: int, duration: float, interval: float, damage: float, radius: float, color: Color, targets: Array[Enemy]) -> int:
			candidate_swarm_requests.append({
				"requested": requested,
				"cap": cap,
				"duration": duration,
				"interval": interval,
				"damage": damage,
				"radius": radius,
				"color": color,
				"targets": targets,
			})
			return 6
	)
	var candidate_swarm_request: Dictionary = candidate_swarm_requests[0]
	_expect(int(candidate_swarm_spawn_result.spawn_count) == 6 and candidate_swarm_spawn_result.metric_id == &"kasuha_mass_summon" and is_equal_approx(float(candidate_swarm_spawn_result.metric_value), 6.0), "successful candidate abyss swarms must report their actual spawn count to the mass-summon metric", failures)
	_expect(String(candidate_swarm_spawn_result.notice) == "대규모 소환술 · 심연 생명체 6기" and is_equal_approx(float(candidate_swarm_spawn_result.notice_duration), 2.2), "successful candidate abyss swarms must preserve their bounded HUD notice", failures)
	_expect(int(candidate_swarm_request.requested) == 10 and int(candidate_swarm_request.cap) == 8 and is_equal_approx(float(candidate_swarm_request.damage), 69.6) and is_equal_approx(float(candidate_swarm_request.radius), 1500.0), "candidate abyss swarm execution must forward the composed combat profile without recomputing it", failures)
	_expect(candidate_swarm_request.color == candidate_swarm_color and candidate_swarm_request.targets == candidate_swarm_targets, "candidate abyss swarm execution must forward the active core color and enemy snapshot to the spawn owner", failures)
	var capped_candidate_swarm_result := candidate_swarm_service.execute(candidate_swarm_profile, candidate_swarm_color, candidate_swarm_targets, func(_requested: int, _cap: int, _duration: float, _interval: float, _damage: float, _radius: float, _color: Color, _targets: Array[Enemy]) -> int: return 0)
	_expect(bool(capped_candidate_swarm_result.attempted) and int(capped_candidate_swarm_result.spawn_count) == 0 and capped_candidate_swarm_result.metric_id == &"kasuha_summon_cap_reached" and String(capped_candidate_swarm_result.notice).is_empty(), "candidate abyss swarm execution must distinguish exhausted summon capacity without presenting a false spawn notice", failures)
	var invalid_candidate_swarm_profile := candidate_swarm_service.build_profile(Callable(), {}, 1.0)
	var invalid_candidate_swarm_result := candidate_swarm_service.execute(invalid_candidate_swarm_profile, candidate_swarm_color, candidate_swarm_targets, Callable())
	_expect(not bool(invalid_candidate_swarm_profile.valid) and not bool(invalid_candidate_swarm_result.attempted), "candidate abyss swarm orchestration must reject missing modifier and spawn collaborators before side effects", failures)
	abyss_attack_summon.free()
	abyss_attack_column.free()
	if is_instance_valid(abyss_attack_target):
		abyss_attack_target.free()
	candidate_abyss_target.free()

	var branch_service := TowerBranchHitExecutionService.new()
	var branch_tower := TowerData.new()
	branch_tower.behavior = &"area"
	branch_tower.area_radius = 100.0
	branch_tower.status_power = 15.0
	var branch_enemy_data := EnemyData.new()
	branch_enemy_data.max_health = 100.0
	var branch_target := _active_enemy_at(Vector2.ZERO)
	var branch_near := _active_enemy_at(Vector2(50.0, 0.0))
	var branch_middle := _active_enemy_at(Vector2(100.0, 0.0))
	var branch_wave_only := _active_enemy_at(Vector2(140.0, 0.0))
	var branch_far := _active_enemy_at(Vector2(230.0, 0.0))
	var branch_inactive := _active_enemy_at(Vector2(40.0, 0.0))
	branch_inactive.active = false
	var branch_enemies: Array[Enemy] = [branch_target, branch_near, branch_middle, branch_wave_only, branch_far, branch_inactive]
	for branch_enemy in branch_enemies:
		branch_enemy.data = branch_enemy_data
		branch_enemy.current_health = 100.0
	branch_target.current_health = 30.0
	var branch_damage_events: Array[Dictionary] = []
	var branch_presentations: Array[Dictionary] = []
	var branch_damage_callback := func(hit_target: Enemy, hit_damage: float, source: StringName, is_area: bool) -> float:
		branch_damage_events.append({"target": hit_target, "damage": hit_damage, "source": source, "is_area": is_area})
		if source == &"branch_execute":
			hit_target.active = false
		return hit_damage
	var branch_result := branch_service.execute(
		branch_tower,
		branch_target,
		branch_enemies,
		100.0,
		{
			"burn": 0.2,
			"mark": 0.3,
			"stun": 0.5,
			"execute": 2.0,
			"execute_ratio": 0.35,
			"ricochet": 0.5,
			"ricochet_count": 2,
			"ricochet_falloff": 0.5,
			"shrapnel": 0.25,
			"wave": 2.0,
			"spread_status": &"burn",
			"center_damage": 0.4,
			"experience_bonus": 1.8,
			"explosion": true,
		},
		120.0,
		30.0,
		branch_damage_callback,
		func(event: Dictionary) -> void: branch_presentations.append(event)
	)
	var branch_knocked_targets: Array[Enemy] = []
	branch_knocked_targets.assign(branch_result.knocked_targets as Array)
	_expect(bool(branch_result.applied) and is_equal_approx(float(branch_result.dealt), 255.0), "tower branch execution must aggregate execute, ricochet, shrapnel, and post-wave explosion damage in stable order", failures)
	_expect(is_equal_approx(float(branch_result.execute_damage), 100.0) and is_equal_approx(float(branch_result.ricochet_damage), 75.0) and is_equal_approx(float(branch_result.shrapnel_damage), 50.0) and is_zero_approx(float(branch_result.center_damage)) and is_equal_approx(float(branch_result.explosion_damage), 30.0), "tower branch execution must expose stage-level actual damage totals", failures)
	_expect(branch_target.statuses.has_all([&"burn", &"mark", &"stun"]) and branch_near.statuses.has(&"stun") and branch_middle.statuses.has(&"stun") and not branch_wave_only.statuses.has(&"stun"), "tower branch statuses must apply burn, mark, and bounded area stun before damage followups", failures)
	_expect(branch_knocked_targets == [branch_near, branch_middle, branch_wave_only] and branch_knocked_targets.all(func(enemy: Enemy) -> bool: return enemy.last_knockback_displacement > 0.0), "tower branch wave must move only active secondary targets inside 150 pixels", failures)
	_expect(branch_result.spread_target == branch_near and branch_near.statuses.has(&"burn") and is_equal_approx(float(branch_near.statuses[&"burn"].power), 12.0) and is_equal_approx(branch_target.experience_multiplier, 1.0), "a branch execution kill must spread burn to the nearest survivor and skip living-target experience changes", failures)
	_expect(branch_damage_events.map(func(event: Dictionary) -> StringName: return StringName(event.source)) == [&"branch_execute", &"ricochet", &"ricochet", &"shrapnel", &"shrapnel", &"branch_explosion"], "tower branch damage callbacks must preserve execute, chain, radial, transition, then explosion ordering", failures)
	_expect(branch_presentations.map(func(event: Dictionary) -> StringName: return StringName(event.source)) == [&"ricochet", &"ricochet", &"shrapnel", &"shrapnel", &"branch_explosion"] and branch_presentations.all(func(event: Dictionary) -> bool: return event.target != branch_inactive), "tower branch presentation requests must match active damage targets and stage budgets", failures)

	var living_branch_target := _active_enemy_at(Vector2.ZERO)
	living_branch_target.data = branch_enemy_data
	living_branch_target.current_health = 80.0
	var living_branch_result := branch_service.execute(branch_tower, living_branch_target, [living_branch_target], 100.0, {"execute": 2.0, "execute_ratio": 0.35, "center_damage": 0.4, "experience_bonus": 1.8}, 120.0, 0.0, branch_damage_callback, Callable())
	_expect(is_zero_approx(float(living_branch_result.execute_damage)) and is_equal_approx(float(living_branch_result.center_damage), 40.0) and is_equal_approx(living_branch_target.experience_multiplier, 1.8), "a living branch target above the execution line must receive center damage and the configured experience multiplier", failures)
	var empty_branch_result := branch_service.execute(branch_tower, living_branch_target, [living_branch_target], 100.0, {}, 120.0, 0.0, branch_damage_callback, Callable())
	_expect(not bool(empty_branch_result.applied) and is_zero_approx(float(empty_branch_result.dealt)), "empty tower branch modifiers must exit without damage or mutation", failures)
	for branch_enemy in branch_enemies:
		branch_enemy.free()
	living_branch_target.free()
static func _run_tactics_cursor_and_counter_contracts(context: ContractContext, failures: Array[String]) -> void:
	var loadout := context.loadout
	var offer_service := context.offer_service
	var presentation := context.presentation
	var targeting := context.targeting
	var charm_profile := context.charm_profile
	var precision_enemy_data := context.precision_enemy_data
	var tactics_service := GoblinTacticsService.new()
	var tactics_tower := DataRegistry.get_tower(&"rapid")
	var tactics_modifiers := {
		"tactics_cycle": 3,
		"tactics_poison_chance": 0.5,
		"tactics_poison_damage": 6.0,
		"tactics_bleed_ratio": 0.02,
		"tactics_mark": 0.35,
	}
	var tactics_poison_profile := {"damage_per_second": 10.0, "duration": 7.0, "max_stacks": 3}
	var tactics_bleed_profile := {"health_ratio": 0.03, "duration": 4.5, "max_stacks": 2, "damage_cap": 65.0}
	var tactics_poison_target := _active_enemy_at(Vector2.ZERO)
	var tactics_poison_result := tactics_service.execute(tactics_tower, tactics_poison_target, 100.0, 3, tactics_modifiers, tactics_poison_profile, tactics_bleed_profile, 0.2)
	var applied_poison: Dictionary = tactics_poison_target.common_ailments.get(&"poison", {})
	_expect(bool(tactics_poison_result.applied) and tactics_poison_result.selected_status == &"poison" and tactics_poison_result.status_ids == [&"poison", &"mark"] and tactics_poison_result.sample_id == &"status.poison_stacks" and int(tactics_poison_result.sample_value) == 1, "goblin tactics must expose one poison-plus-mark metric result for a low scheduled roll", failures)
	_expect(is_equal_approx(float(applied_poison.damage_per_second), 10.0) and is_equal_approx(float(applied_poison.remaining), 7.0) and int(applied_poison.max_stacks) == 3 and is_equal_approx(float(tactics_poison_target.statuses[&"mark"].power), 0.35), "goblin poison tactics must merge the stronger common profile and apply the fixed-duration vulnerability mark", failures)
	var tactics_bleed_target := _active_enemy_at(Vector2.ZERO)
	var tactics_bleed_result := tactics_service.execute(tactics_tower, tactics_bleed_target, 100.0, 6, tactics_modifiers, tactics_poison_profile, tactics_bleed_profile, 0.8)
	var bleed_sources: Dictionary = (tactics_bleed_target.common_ailments.get(&"bleed", {}) as Dictionary).get("sources", {})
	var tactics_bleed_source: Dictionary = bleed_sources.get(GoblinTacticsService.BLEED_SOURCE_ID, {})
	var tactics_bleed_stack: Dictionary = (tactics_bleed_source.get("stacks", []) as Array)[0]
	_expect(bool(tactics_bleed_result.applied) and tactics_bleed_result.selected_status == &"bleed" and tactics_bleed_result.status_ids == [&"bleed", &"mark"] and tactics_bleed_result.sample_id == &"status.bleed_sources" and int(tactics_bleed_result.sample_value) == 1, "goblin tactics must expose one bleed-plus-mark metric result for a high scheduled roll", failures)
	_expect(is_equal_approx(float(tactics_bleed_stack.health_ratio), 0.03) and is_equal_approx(float(tactics_bleed_stack.remaining), 4.5) and is_equal_approx(float(tactics_bleed_stack.damage_cap), 80.0), "goblin bleed tactics must merge the stronger common ratio and retain the attack-damage cap floor", failures)
	var tactics_rng_state := RunRng.rng.state
	var tactics_skipped_target := _active_enemy_at(Vector2.ZERO)
	var tactics_skipped_result := tactics_service.execute(tactics_tower, tactics_skipped_target, 100.0, 2, tactics_modifiers, tactics_poison_profile, tactics_bleed_profile)
	var non_rapid_tower := TowerData.new()
	non_rapid_tower.behavior = &"area"
	var non_rapid_result := tactics_service.execute(non_rapid_tower, tactics_skipped_target, 100.0, 3, tactics_modifiers, tactics_poison_profile, tactics_bleed_profile)
	_expect(not bool(tactics_skipped_result.applied) and not bool(non_rapid_result.applied) and tactics_skipped_target.common_ailments.is_empty() and tactics_skipped_target.statuses.is_empty() and RunRng.rng.state == tactics_rng_state, "off-cycle and non-rapid hits must not apply goblin tactics or consume combat RNG", failures)
	tactics_poison_target.free()
	tactics_bleed_target.free()
	tactics_skipped_target.free()
	var cursor_attack_service := CursorAttackExecutionService.new()
	var cursor_area_near := _active_enemy_at(Vector2(20.0, 0.0))
	var cursor_area_edge := _active_enemy_at(Vector2(80.0, 0.0))
	var cursor_area_outside := _active_enemy_at(Vector2(120.0, 0.0))
	var cursor_area_candidates: Array[Enemy] = [cursor_area_near, cursor_area_edge, cursor_area_outside]
	for cursor_area_enemy in cursor_area_candidates:
		cursor_area_enemy.data = EnemyData.new()
		cursor_area_enemy.spawn_distance_limit = 400.0
	var cursor_area_hits: Array[Dictionary] = []
	var cursor_area_boosted_knockbacks: Array[bool] = []
	var cursor_area_unlock_targets: Array[Enemy] = []
	var cursor_area_result := cursor_attack_service.execute_primary(
		&"area",
		cursor_area_candidates,
		Vector2.ZERO,
		100.0,
		100.0,
		18.0,
		{},
		{},
		func(_targets: Array[Enemy], _position: Vector2, _prefer_boss: bool) -> Enemy: return null,
		func(hit_target: Enemy, _position: Vector2, _radius: float, _plan: Dictionary) -> float: return 1.5 if hit_target == cursor_area_edge else 1.0,
		func(hit_target: Enemy, hit_damage: float, is_area: bool, _modifiers: Dictionary, _plan: Dictionary) -> float:
			cursor_area_hits.append({"target": hit_target, "damage": hit_damage, "is_area": is_area})
			return hit_damage,
		func(hit_target: Enemy, _plan: Dictionary) -> float: return 2.0 if hit_target == cursor_area_edge else 1.0,
		func() -> void: cursor_area_boosted_knockbacks.append(true),
		func(hit_target: Enemy) -> void: cursor_area_unlock_targets.append(hit_target)
	)
	_expect(is_equal_approx(float(cursor_area_result.dealt), 250.0) and cursor_area_result.target == null and is_equal_approx(float(cursor_area_result.damage), 100.0), "cursor area execution must filter the exact attack radius and aggregate retainer-scaled damage", failures)
	_expect(cursor_area_hits.map(func(hit: Dictionary) -> Enemy: return hit.target as Enemy) == [cursor_area_near, cursor_area_edge] and cursor_area_hits.all(func(hit: Dictionary) -> bool: return bool(hit.is_area)), "cursor area execution must preserve candidate order and area-hit arguments", failures)
	_expect(is_equal_approx(cursor_area_near.last_knockback_displacement, 18.0) and is_equal_approx(cursor_area_edge.last_knockback_displacement, 36.0) and cursor_area_boosted_knockbacks.size() == 1 and cursor_area_unlock_targets == [cursor_area_near, cursor_area_edge], "cursor area execution must apply retainer-scaled knockback before requesting boss-lock release", failures)
	var cursor_single_closest_preferences: Array[bool] = []
	var cursor_single_hits: Array[float] = []
	var cursor_single_unlock_targets: Array[Enemy] = []
	var cursor_single_result := cursor_attack_service.execute_primary(
		&"heavy",
		cursor_area_candidates,
		Vector2.ZERO,
		100.0,
		140.0,
		12.0,
		{"tracking": true, "repeat_damage_step": 0.2, "repeat_damage_cap": 0.5},
		{"strike_count": 2, "strike_damage": 0.5},
		func(_targets: Array[Enemy], _position: Vector2, prefer_boss: bool) -> Enemy:
			cursor_single_closest_preferences.append(prefer_boss)
			return cursor_area_edge if prefer_boss else cursor_area_near,
		func(_target: Enemy, _position: Vector2, _radius: float, _plan: Dictionary) -> float: return 1.0,
		func(_target: Enemy, hit_damage: float, is_area: bool, _modifiers: Dictionary, _plan: Dictionary) -> float:
			cursor_single_hits.append(hit_damage)
			return hit_damage if not is_area else 0.0,
		func(_target: Enemy, _plan: Dictionary) -> float: return 1.0,
		func() -> void: cursor_area_boosted_knockbacks.append(false),
		func(hit_target: Enemy) -> void: cursor_single_unlock_targets.append(hit_target)
	)
	var cursor_repeat_result := cursor_attack_service.execute_primary(
		&"single",
		cursor_area_candidates,
		Vector2.ZERO,
		100.0,
		140.0,
		12.0,
		{"tracking": true, "repeat_damage_step": 0.2, "repeat_damage_cap": 0.5},
		{},
		func(_targets: Array[Enemy], _position: Vector2, _prefer_boss: bool) -> Enemy:
			cursor_single_closest_preferences.append(false)
			return cursor_area_near,
		func(_target: Enemy, _position: Vector2, _radius: float, _plan: Dictionary) -> float: return 1.0,
		func(_target: Enemy, hit_damage: float, _is_area: bool, _modifiers: Dictionary, _plan: Dictionary) -> float:
			cursor_single_hits.append(hit_damage)
			return hit_damage,
		func(_target: Enemy, _plan: Dictionary) -> float: return 1.0,
		func() -> void: cursor_area_boosted_knockbacks.append(false),
		func(hit_target: Enemy) -> void: cursor_single_unlock_targets.append(hit_target)
	)
	_expect(cursor_single_result.target == cursor_area_edge and is_equal_approx(float(cursor_single_result.dealt), 100.0) and cursor_single_hits.slice(0, 2) == [50.0, 50.0], "cursor single execution must preserve heavy targeting and retainer multi-strike damage", failures)
	_expect(cursor_repeat_result.target == cursor_area_edge and cursor_single_closest_preferences == [true] and is_equal_approx(float(cursor_repeat_result.damage), 120.0) and is_equal_approx(float(cursor_repeat_result.dealt), 120.0), "cursor tracking must retain the prior target and apply capped repeat-hit growth before striking", failures)
	_expect(cursor_single_unlock_targets == [cursor_area_edge, cursor_area_edge, cursor_area_edge] and is_equal_approx(cursor_area_edge.last_knockback_displacement, 12.0), "cursor multi-strikes and repeated tracking hits must each apply knockback and request boss-lock release", failures)
	var cursor_slash_near := _active_enemy_at(Vector2(60.0, 30.0))
	var cursor_slash_outside := _active_enemy_at(Vector2(60.0, 60.0))
	var cursor_followup_target := _active_enemy_at(Vector2.ZERO)
	for cursor_followup_enemy in [cursor_slash_near, cursor_slash_outside, cursor_followup_target]:
		var cursor_followup_data := EnemyData.new()
		cursor_followup_data.radius = 5.0
		cursor_followup_enemy.data = cursor_followup_data
	var cursor_followup_sources: Array[StringName] = []
	var cursor_followup_damages: Array[float] = []
	var cursor_followup_queries: Array[Dictionary] = []
	var cursor_followup_presentations: Array[Dictionary] = []
	var cursor_segment_targets: Array[Enemy] = [cursor_slash_near, cursor_slash_outside]
	var cursor_radius_targets: Array[Enemy] = [cursor_followup_target]
	var cursor_followup_dealt := cursor_attack_service.execute_damage_followups(
		Vector2.ZERO,
		100.0,
		100.0,
		1.0,
		{"split_zone": true, "charged_explosion": 0.4, "jugdied_horse_area": 0.3, "jugdied_horse_radius": 1.25},
		{"final_slash": true, "final_slash_damage": 0.85},
		func(start: Vector2, finish: Vector2, half_width: float) -> Array[Enemy]:
			cursor_followup_queries.append({"type": &"segment", "start": start, "finish": finish, "radius": half_width})
			return cursor_segment_targets,
		func(position: Vector2, query_radius: float) -> Array[Enemy]:
			cursor_followup_queries.append({"type": &"radius", "position": position, "radius": query_radius})
			return cursor_radius_targets,
		func(_target: Enemy, hit_damage: float, source: StringName) -> float:
			cursor_followup_sources.append(source)
			cursor_followup_damages.append(hit_damage)
			return hit_damage,
		func(event: Dictionary) -> void: cursor_followup_presentations.append(event)
	)
	_expect(is_equal_approx(cursor_followup_dealt, 265.0) and cursor_followup_sources == [&"kanda_final_slash", &"cursor_split_zone", &"cursor_split_zone", &"cursor_charge", &"jugdied_horse"], "cursor followup execution must aggregate final slash, split zones, charged explosion, and horse area in stable order", failures)
	_expect(cursor_followup_damages.size() == 5 and is_equal_approx(cursor_followup_damages[0], 85.0) and is_equal_approx(cursor_followup_damages[1], 55.0) and is_equal_approx(cursor_followup_damages[2], 55.0) and is_equal_approx(cursor_followup_damages[3], 40.0) and is_equal_approx(cursor_followup_damages[4], 30.0) and int(cursor_followup_presentations[0].target_count) == 1, "cursor followups must preserve branch damage ratios and exact final-slash corridor filtering", failures)
	_expect((cursor_followup_presentations as Array).map(func(event: Dictionary) -> StringName: return StringName(event.type)) == [&"final_slash", &"split_zone", &"split_zone", &"charged_explosion", &"horse_area"], "cursor followup presentation requests must follow their corresponding damage groups", failures)
	_expect(cursor_followup_queries.size() == 5 and cursor_followup_queries[0].finish == Vector2(155.0, 0.0) and is_equal_approx(float(cursor_followup_queries[0].radius), 34.0) and is_equal_approx(float(cursor_followup_queries[4].radius), 90.0), "cursor followup queries must preserve slash geometry and branch radius multipliers", failures)
	for cursor_contract_enemy in cursor_area_candidates + [cursor_slash_near, cursor_slash_outside, cursor_followup_target]:
		cursor_contract_enemy.free()
	var counterattack_service := CoreCounterattackService.new()
	var counter_enemy_data := EnemyData.new()
	counter_enemy_data.max_health = 1000.0
	counter_enemy_data.armor = 0.0
	counter_enemy_data.behavior = &"normal"
	var counter_attacker := _active_enemy_at(Vector2(20.0, 30.0))
	var counter_shard_one := _active_enemy_at(Vector2(40.0, 30.0))
	var counter_shard_two := _active_enemy_at(Vector2(60.0, 30.0))
	var counter_shard_three := _active_enemy_at(Vector2(80.0, 30.0))
	var counter_shard_overflow := _active_enemy_at(Vector2(100.0, 30.0))
	var counter_targets: Array[Enemy] = [counter_attacker, counter_shard_one, counter_shard_two, counter_shard_three, counter_shard_overflow]
	for counter_target in counter_targets:
		counter_target.data = counter_enemy_data
		counter_target.current_health = counter_enemy_data.max_health
	var counter_query := {"calls": 0, "center": Vector2.ZERO, "radius": 0.0}
	var counter_result := counterattack_service.execute(
		counter_attacker, 100.0, 1.5, {"counter": 1.2, "counter_shards": 0.45},
		func(center: Vector2, radius: float) -> Array[Enemy]:
			counter_query.calls += 1
			counter_query.center = center
			counter_query.radius = radius
			return counter_targets
	)
	_expect(bool(counter_result.applied) and is_equal_approx(float(counter_result.counter_damage), 180.0) and is_equal_approx(float(counter_result.primary_dealt), 180.0) and is_equal_approx(counter_attacker.current_health, 820.0), "core counterattack service must compose core damage, runtime multiplier, and branch ratio into the primary retaliation", failures)
	_expect(counter_query.calls == 1 and counter_query.center == counter_attacker.global_position and is_equal_approx(float(counter_query.radius), CoreCounterattackService.SHARD_RADIUS), "counter shards must request one radius query centered on the breaching attacker", failures)
	_expect((counter_result.shard_targets as Array) == [counter_shard_one, counter_shard_two, counter_shard_three] and is_equal_approx(float(counter_result.shard_damage), 81.0) and is_equal_approx(float(counter_result.shard_dealt), 243.0), "counter shards must exclude the attacker and damage at most the first three valid nearby enemies", failures)
	_expect(is_equal_approx(counter_shard_one.current_health, 919.0) and is_equal_approx(counter_shard_two.current_health, 919.0) and is_equal_approx(counter_shard_three.current_health, 919.0) and is_equal_approx(counter_shard_overflow.current_health, 1000.0), "counter shard execution must preserve the three-target cap without touching overflow targets", failures)
	var primary_only_attacker := _active_enemy_at(Vector2.ZERO)
	primary_only_attacker.data = counter_enemy_data
	primary_only_attacker.current_health = counter_enemy_data.max_health
	var primary_only_queries := [0]
	var primary_only_result := counterattack_service.execute(
		primary_only_attacker, 50.0, 1.5, {"counter": 1.0},
		func(_center: Vector2, _radius: float) -> Array[Enemy]:
			primary_only_queries[0] += 1
			return counter_targets
	)
	var missing_counter_result := counterattack_service.execute(primary_only_attacker, 50.0, 1.5, {}, Callable())
	_expect(bool(primary_only_result.applied) and is_equal_approx(primary_only_attacker.current_health, 925.0) and int(primary_only_queries[0]) == 0 and (primary_only_result.shard_targets as Array).is_empty(), "a counter without shards must damage only the attacker and skip the spatial query", failures)
	_expect(not bool(missing_counter_result.applied) and is_equal_approx(primary_only_attacker.current_health, 925.0), "missing counter modifiers must reject retaliation without additional damage", failures)
	for counter_target in counter_targets:
		counter_target.free()
	primary_only_attacker.free()
static func _run_core_execution_and_presentation_contracts(context: ContractContext, failures: Array[String]) -> void:
	var loadout := context.loadout
	var offer_service := context.offer_service
	var presentation := context.presentation
	var charm_profile := context.charm_profile
	var precision_enemy_data := context.precision_enemy_data
	var core_attack_service := CoreAttackExecutionService.new()
	_expect(is_equal_approx(core_attack_service.resolve_attack_damage(100.0, {"overheat_round": 1.6}, 5), 160.0) and is_equal_approx(core_attack_service.resolve_attack_damage(100.0, {"overheat_round": 1.6}, 4), 100.0), "core attack execution must apply overheat rounds only on the stable fifth-attack cadence", failures)
	var core_band_far := _active_enemy_at(Vector2(200.0, 55.0))
	var core_band_near := _active_enemy_at(Vector2(50.0, 45.0))
	var core_band_outside := _active_enemy_at(Vector2(100.0, 120.0))
	var core_band_enemies: Array[Enemy] = [core_band_far, core_band_outside, core_band_near]
	var base_core_attack_plan := {
		"attack_range_multiplier": 1.0,
		"charm_radial": false,
		"charm_radial_targets": 2,
		"charm_radial_damage_multiplier": 0.72,
		"pierce_width_multiplier": 1.0,
		"abyss_center_radius": 0.0,
		"abyss_center_damage_multiplier": 0.0,
		"abyss_presence_radius_multiplier": 1.0,
		"abyss_presence_hits": 3,
		"abyss_presence_damage_multiplier": 0.5,
	}
	var core_band_hits: Array[Dictionary] = []
	var core_band_result := core_attack_service.execute(
		&"pierce",
		core_band_enemies,
		Vector2.ZERO,
		Vector2(100.0, 50.0),
		300.0,
		300.0,
		base_core_attack_plan,
		{},
		100.0,
		1,
		func(_targets: Array[Enemy]) -> Enemy: return core_band_near,
		func(hit_target: Enemy, hit_damage: float, source: StringName) -> void:
			core_band_hits.append({"target": hit_target, "damage": hit_damage, "source": source})
	)
	_expect((core_band_result.hit_targets as Array) == [core_band_near, core_band_far] and core_band_hits.map(func(hit: Dictionary) -> Enemy: return hit.target as Enemy) == [core_band_near, core_band_far], "core pierce execution must filter the cursor band and resolve targets from the core-facing beam origin", failures)
	_expect(core_band_hits.all(func(hit: Dictionary) -> bool: return hit.source == &"pierce" and is_equal_approx(float(hit.damage), 100.0)), "core pierce execution must preserve its damage and armor-piercing source", failures)
	var charm_plan := base_core_attack_plan.duplicate()
	charm_plan.charm_radial = true
	var charm_hits: Array[Dictionary] = []
	var charm_result := core_attack_service.execute(
		&"pierce", core_band_enemies, Vector2.ZERO, Vector2(100.0, 50.0), 300.0, 300.0,
		charm_plan, {}, 100.0, 1,
		func(_targets: Array[Enemy]) -> Enemy: return null,
		func(hit_target: Enemy, hit_damage: float, source: StringName) -> void:
			charm_hits.append({"target": hit_target, "damage": hit_damage, "source": source})
	)
	_expect((charm_result.hit_targets as Array) == [core_band_near, core_band_outside] and charm_hits.all(func(hit: Dictionary) -> bool: return is_equal_approx(float(hit.damage), 72.0)), "charm-radial core execution must select the nearest bounded cursor targets and apply its candidate damage multiplier", failures)
	var rail_far := _active_enemy_at(Vector2(80.0, 5.0))
	var rail_near := _active_enemy_at(Vector2(20.0, -5.0))
	var rail_outside := _active_enemy_at(Vector2(50.0, 30.0))
	var rail_enemies: Array[Enemy] = [rail_far, rail_outside, rail_near]
	var rail_hits: Array[Enemy] = []
	var rail_result := core_attack_service.execute(
		&"pierce", rail_enemies, Vector2.ZERO, Vector2(100.0, 0.0), 300.0, 300.0,
		base_core_attack_plan, {"coordinate_rail": true, "rail_width": 10.0}, 100.0, 1,
		func(_targets: Array[Enemy]) -> Enemy: return null,
		func(hit_target: Enemy, _hit_damage: float, _source: StringName) -> void: rail_hits.append(hit_target)
	)
	_expect((rail_result.hit_targets as Array) == [rail_near, rail_far] and rail_hits == [rail_near, rail_far], "coordinate-rail core execution must filter its segment corridor and preserve origin-to-cursor hit order", failures)
	var radial_near := _active_enemy_at(Vector2(30.0, 0.0))
	var radial_far := _active_enemy_at(Vector2(80.0, 0.0))
	var radial_outside := _active_enemy_at(Vector2(120.0, 0.0))
	var radial_enemies: Array[Enemy] = [radial_near, radial_far, radial_outside]
	var radial_plan := base_core_attack_plan.duplicate()
	radial_plan.abyss_center_radius = 50.0
	radial_plan.abyss_center_damage_multiplier = 1.5
	var core_radial_hits: Array[String] = []
	var core_radial_result := core_attack_service.execute(
		&"radial", radial_enemies, Vector2.ZERO, Vector2.ZERO, 300.0, 100.0,
		radial_plan, {}, 100.0, 1,
		func(_targets: Array[Enemy]) -> Enemy: return null,
		func(hit_target: Enemy, hit_damage: float, source: StringName) -> void:
			core_radial_hits.append("%d:%s:%.0f" % [int(hit_target.global_position.x), String(source), hit_damage])
	)
	_expect((core_radial_result.hit_targets as Array) == [radial_near, radial_far] and core_radial_hits == ["30:core:100", "30:core_abyss_center:150", "80:core:100"], "radial core execution must apply a second center hit after the primary while excluding out-of-range targets", failures)
	var core_rng_state := RunRng.rng.state
	RunRng.rng.seed = 9357
	RunRng.rangef(0.5, 1.5)
	var expected_random_core_target := RunRng.pick(core_band_enemies) as Enemy
	RunRng.rng.seed = 9357
	var random_core_hits: Array[Dictionary] = []
	var random_core_result := core_attack_service.execute(
		&"random", core_band_enemies, Vector2.ZERO, Vector2.ZERO, 300.0, 300.0,
		base_core_attack_plan, {"lucky_min": 0.5, "lucky_max": 1.5, "stable_critical": 5}, 100.0, 5,
		func(_targets: Array[Enemy]) -> Enemy: return null,
		func(hit_target: Enemy, hit_damage: float, source: StringName) -> void:
			random_core_hits.append({"target": hit_target, "damage": hit_damage, "source": source})
	)
	RunRng.rng.state = core_rng_state
	_expect(is_equal_approx(float(random_core_result.lucky_roll), CoreAttackExecutionService.STABLE_CRITICAL_MULTIPLIER) and random_core_hits[0].target == expected_random_core_target and is_equal_approx(float(random_core_hits[0].damage), 180.0), "random core execution must consume the lucky roll before target selection and then apply stable-critical override damage", failures)
	var specialization_enemy_data := EnemyData.new()
	specialization_enemy_data.max_health = 1000.0
	var specialization_primary := _active_enemy_at(Vector2.ZERO)
	var specialization_prism_target := _active_enemy_at(Vector2(20.0, 0.0))
	var specialization_blast_target := _active_enemy_at(Vector2(60.0, 0.0))
	var specialization_highroll_target := _active_enemy_at(Vector2(100.0, 0.0))
	var specialization_enemies: Array[Enemy] = [specialization_primary, specialization_prism_target, specialization_blast_target, specialization_highroll_target]
	for specialization_enemy in specialization_enemies:
		specialization_enemy.data = specialization_enemy_data
		specialization_enemy.current_health = specialization_enemy_data.max_health
	specialization_prism_target.current_health = 40.0
	var specialization_events: Array[String] = []
	var specialization_active_queries := [0]
	var specialization_radius_queries: Array[Dictionary] = []
	var specialization_targeting := TargetingService.new()
	var specialization_result := core_attack_service.execute_specializations(
		specialization_primary,
		100.0,
		2.5,
		{
			"prism_refract": 0.5,
			"pierce_explosion": 0.4,
			"pierce_explosion_chain": 0.3,
			"highroll_explosion": 0.2,
			"lucky_chain_threshold": 2.0,
			"lucky_chain_count": 2,
			"lucky_chain_damage": 0.25,
		},
		func() -> Array[Enemy]:
			specialization_active_queries[0] += 1
			return specialization_enemies.filter(func(enemy: Enemy) -> bool: return enemy.active),
		func(center: Vector2, radius: float) -> Array[Enemy]:
			specialization_radius_queries.append({"center": center, "radius": radius})
			return specialization_enemies.filter(func(enemy: Enemy) -> bool: return enemy.active and enemy.global_position.distance_to(center) <= radius),
		Callable(specialization_targeting, "closest_other"),
		func(hit_target: Enemy, hit_damage: float, source: StringName) -> float:
			specialization_events.append("hit:%s:%d" % [String(source), int(hit_target.global_position.x)])
			return hit_target.take_damage(hit_damage, source, true),
		func(event: Dictionary) -> void:
			specialization_events.append("present:%s:%s" % [String(event.type), String(event.source)])
	)
	var expected_specialization_events: Array[String] = [
		"hit:core_prism:20",
		"present:link:core_prism",
		"hit:core_pierce_blast:60",
		"hit:core_pierce_blast:100",
		"present:burst:core_pierce_blast",
		"hit:core_pierce_chain:60",
		"hit:core_highroll:60",
		"hit:core_highroll:100",
		"present:burst:core_highroll",
		"hit:core_lucky_chain:60",
		"present:link:core_lucky_chain",
		"hit:core_lucky_chain:100",
		"present:link:core_lucky_chain",
	]
	_expect(bool(specialization_result.applied) and int(specialization_result.hit_count) == 8 and is_equal_approx(float(specialization_result.dealt), 300.0), "core attack specializations must aggregate actual prism, blast, chain, highroll, and lucky-chain damage", failures)
	_expect((specialization_result.stage_ids as Array) == [&"core_prism", &"core_pierce_blast", &"core_pierce_chain", &"core_highroll", &"core_lucky_chain"] and specialization_events == expected_specialization_events, "core attack specializations must preserve prism, pierce blast and chain, highroll, then lucky-chain execution and presentation order", failures)
	_expect(not specialization_prism_target.active and is_equal_approx(specialization_blast_target.current_health, 855.0) and is_equal_approx(specialization_highroll_target.current_health, 885.0), "later core specialization stages must exclude a prism defeat while retaining cumulative damage on surviving targets", failures)
	_expect(specialization_active_queries[0] == 4 and specialization_radius_queries.size() == 2 and is_equal_approx(float(specialization_radius_queries[0].radius), CoreAttackExecutionService.PIERCE_EXPLOSION_RADIUS) and is_equal_approx(float(specialization_radius_queries[1].radius), CoreAttackExecutionService.HIGHROLL_EXPLOSION_RADIUS), "core specialization chains must refresh active targets per hop and issue one stable query per explosion radius", failures)
	var suppressed_specialization_event_count := specialization_events.size()
	var suppressed_specialization_result := core_attack_service.execute_specializations(
		specialization_primary, 100.0, 1.9,
		{"highroll_explosion": 0.2, "lucky_chain_threshold": 2.0, "lucky_chain_damage": 0.25},
		func() -> Array[Enemy]: return specialization_enemies,
		func(_center: Vector2, _radius: float) -> Array[Enemy]: return specialization_enemies,
		Callable(specialization_targeting, "closest_other"),
		func(_target: Enemy, hit_damage: float, _source: StringName) -> float: return hit_damage,
		func(_event: Dictionary) -> void: specialization_events.append("unexpected")
	)
	_expect(not bool(suppressed_specialization_result.applied) and specialization_events.size() == suppressed_specialization_event_count, "core highroll and lucky-chain specializations must remain side-effect free below their configured thresholds", failures)
	for specialization_enemy in specialization_enemies:
		if is_instance_valid(specialization_enemy):
			specialization_enemy.free()
	var core_hit_service := CoreHitExecutionService.new()
	var core_hit_boss_data := EnemyData.new()
	core_hit_boss_data.max_health = 1000.0
	core_hit_boss_data.armor = 0.0
	core_hit_boss_data.is_boss = true
	var core_hit_boss := _active_enemy_at(Vector2(15.0, 25.0))
	core_hit_boss.data = core_hit_boss_data
	core_hit_boss.current_health = core_hit_boss_data.max_health
	var plain_core_data := CoreData.new()
	var boss_hit_result := core_hit_service.execute(core_hit_boss, 100.0, &"core", plain_core_data, {"boss_damage": 1.5})
	_expect(bool(boss_hit_result.applied) and boss_hit_result.route == &"standard" and bool(boss_hit_result.boss_target) and is_equal_approx(float(boss_hit_result.effective_damage), 150.0) and is_equal_approx(float(boss_hit_result.damage), 150.0), "core hit execution must apply the branch boss multiplier before routing a standard hit", failures)
	var core_hit_charm_data := EnemyData.new()
	core_hit_charm_data.max_health = 1000.0
	core_hit_charm_data.armor = 0.0
	var core_hit_charm_target := _active_enemy_at(Vector2(30.0, 40.0))
	core_hit_charm_target.data = core_hit_charm_data
	core_hit_charm_target.current_health = core_hit_charm_data.max_health
	var charm_core_data := CoreData.new()
	charm_core_data.charm_profile = CharmProfileData.new()
	charm_core_data.charm_profile.duration = 0.9
	var guaranteed_charm_rolls := [0]
	var core_hit_charm_modifier_queries: Array[StringName] = []
	var guaranteed_charm_result := core_hit_service.execute(
		core_hit_charm_target, 100.0, &"core", charm_core_data, {}, true, 1, 0.45, {},
		func(key: StringName, default_value: Variant) -> Variant:
			core_hit_charm_modifier_queries.append(key)
			return 1.25 if key == &"charm_duration" else (0.2 if key == &"charm_vulnerability" else default_value),
		func() -> float:
			guaranteed_charm_rolls[0] += 1
			return 1.0
	)
	_expect(bool(guaranteed_charm_result.charm_attempted) and bool(guaranteed_charm_result.charm_applied) and guaranteed_charm_rolls[0] == 0 and core_hit_charm_modifier_queries == [&"charm_duration", &"charm_vulnerability"], "guaranteed core charm must apply without consuming RNG and query candidate modifiers only after reaching the charm path", failures)
	_expect(is_equal_approx(float(guaranteed_charm_result.charm_duration_multiplier), 1.75) and is_equal_approx(float((core_hit_charm_target.statuses[&"charm"] as Dictionary).remaining), 1.575) and is_equal_approx(float((core_hit_charm_target.statuses[&"charm"] as Dictionary).vulnerability), 0.2), "core hit execution must combine charm duration bonuses and vulnerability before applying the status", failures)
	var core_hit_judgment_data := EnemyData.new()
	core_hit_judgment_data.max_health = 1000.0
	core_hit_judgment_data.armor = 0.0
	var core_hit_judgment_target := _active_enemy_at(Vector2(45.0, 55.0))
	core_hit_judgment_target.data = core_hit_judgment_data
	core_hit_judgment_target.current_health = 100.0
	var judgment_core_data := CoreData.new()
	judgment_core_data.judgment_profile = JudgmentProfileData.new()
	var judgment_hit_result := core_hit_service.execute(core_hit_judgment_target, 40.0, &"core", judgment_core_data, {"execute_ratio": 0.12}, false, 1)
	_expect(judgment_hit_result.route == &"judgment" and is_equal_approx(float(judgment_hit_result.damage), 100.0) and bool((judgment_hit_result.judgment as Dictionary).executed) and not core_hit_judgment_target.active, "core judgment routing must preserve sentence evaluation and fixed-health execution damage", failures)
	_expect(judgment_hit_result.execution_position == Vector2(45.0, 55.0) and not bool(judgment_hit_result.charm_attempted), "core judgment routing must snapshot the execution position and skip the standard charm path", failures)
	var invalid_core_hit_rolls := [0]
	var invalid_core_hit_result := core_hit_service.execute(null, 100.0, &"core", charm_core_data, {}, false, 1, 0.0, {}, Callable(), func() -> float: invalid_core_hit_rolls[0] += 1; return 0.0)
	_expect(not bool(invalid_core_hit_result.applied) and invalid_core_hit_rolls[0] == 0, "invalid core hit targets must be rejected before damage, judgment, or charm RNG work", failures)
	core_hit_boss.free()
	core_hit_charm_target.free()
	core_hit_judgment_target.free()
	var presence_primary := _active_enemy_at(Vector2(20.0, 0.0))
	var presence_fragile := _active_enemy_at(Vector2(40.0, 0.0))
	var presence_outside := _active_enemy_at(Vector2(150.0, 0.0))
	var presence_enemies: Array[Enemy] = [presence_primary, presence_fragile, presence_outside]
	var presence_state := {"consume_count": 0}
	var presence_hits: Array[Enemy] = []
	var presence_result := core_attack_service.execute_abyss_presence(
		presence_enemies, Vector2.ZERO, 100.0, 200.0, base_core_attack_plan,
		func() -> bool:
			presence_state.consume_count = int(presence_state.consume_count) + 1
			return true,
		func(hit_target: Enemy, hit_damage: float, source: StringName) -> void:
			presence_hits.append(hit_target)
			_expect(is_equal_approx(hit_damage, 100.0) and source == &"core_abyss_presence", "abyss-presence hits must preserve configured damage and source", failures)
			if hit_target == presence_fragile:
				hit_target.active = false
	)
	var empty_presence_result := core_attack_service.execute_abyss_presence(
		[presence_outside], Vector2.ZERO, 100.0, 200.0, base_core_attack_plan,
		func() -> bool:
			presence_state.consume_count = int(presence_state.consume_count) + 1
			return true,
		func(_hit_target: Enemy, _hit_damage: float, _source: StringName) -> void: pass
	)
	_expect(bool(presence_result.triggered) and int(presence_result.hit_count) == 4 and presence_hits == [presence_primary, presence_fragile, presence_primary, presence_primary] and int(presence_state.consume_count) == 1, "abyss-presence execution must consume readiness once and skip targets defeated during repeated waves", failures)
	_expect(not bool(empty_presence_result.triggered), "abyss-presence execution must not consume readiness when no target is inside its radius", failures)
	for core_attack_target in core_band_enemies + rail_enemies + radial_enemies + presence_enemies:
		core_attack_target.free()
	var core_skill_service := CoreSkillExecutionService.new()
	var candidate_extension_events: Array[String] = []
	var extension_core_data := CoreData.new()
	extension_core_data.id = &"contract_extension"
	var candidate_extension_result := core_skill_service.execute_candidate_extensions(
		extension_core_data,
		{"charm_zone": true, "charm_stage_buff": true, "mass_summon": true, "guard_active": true, "death_wave": true},
		120.0,
		func(callback_core_data: CoreData, grants_stage_buff: bool) -> float:
			candidate_extension_events.append("charm:%s:%s" % [String(callback_core_data.id), str(grants_stage_buff)])
			return 1.75,
		func() -> void: candidate_extension_events.append("mass"),
		func() -> void: candidate_extension_events.append("guard"),
		func(callback_damage: float) -> void: candidate_extension_events.append("death:%.0f" % callback_damage)
	)
	_expect(bool(candidate_extension_result.applied) and is_equal_approx(float(candidate_extension_result.guard_charm_extension), 1.75), "candidate core-skill extensions must retain the charm-stage extension returned by Jiane execution", failures)
	_expect((candidate_extension_result.stage_ids as Array) == [&"charm_zone", &"mass_summon", &"guard_active", &"death_wave"] and candidate_extension_events == ["charm:contract_extension:true", "mass", "guard", "death:120"], "candidate core-skill extensions must execute charm, summon, guard active, then death wave in stable order", failures)
	var inactive_extension_result := core_skill_service.execute_candidate_extensions(
		extension_core_data, {}, 120.0,
		func(_core_data: CoreData, _stage_buff: bool) -> float: candidate_extension_events.append("unexpected"); return 9.0,
		func() -> void: candidate_extension_events.append("unexpected"),
		func() -> void: candidate_extension_events.append("unexpected"),
		func(_damage: float) -> void: candidate_extension_events.append("unexpected")
	)
	_expect(not bool(inactive_extension_result.applied) and (inactive_extension_result.stage_ids as Array).is_empty() and candidate_extension_events.size() == 4, "inactive candidate extension plans must remain side-effect free", failures)
	var beam_primary := _active_enemy_at(Vector2(100.0, 0.0))
	var beam_secondary := _active_enemy_at(Vector2(120.0, 100.0))
	var beam_outside := _active_enemy_at(Vector2(140.0, 130.0))
	var beam_enemies: Array[Enemy] = [beam_primary, beam_secondary, beam_outside]
	for beam_target in beam_enemies:
		beam_target.data = precision_enemy_data
		beam_target.target_position = Vector2.ZERO
		beam_target.spawn_distance_limit = 500.0
	var beam_skill_hits: Array[Dictionary] = []
	var beam_skill_result := core_skill_service.execute(
		&"beam", beam_enemies, Vector2.ZERO, 100.0, {}, 1.0, 0.0, false, false, 3,
		func(hit_target: Enemy, hit_damage: float, source: StringName, guaranteed_charm: bool, sentence_stacks: int, charm_extension: float) -> void:
			beam_skill_hits.append({"target": hit_target, "damage": hit_damage, "source": source, "guaranteed_charm": guaranteed_charm, "sentence_stacks": sentence_stacks, "charm_extension": charm_extension}),
		func(_hit_target: Enemy, _hit_damage: float) -> void: pass,
		func(_hit_target: Enemy, _hit_damage: float) -> void: pass,
		func(_hit_target: Enemy, _hit_damage: float) -> void: pass
	)
	_expect((beam_skill_result.hit_targets as Array) == [beam_primary, beam_secondary] and beam_skill_hits.size() == 2 and beam_skill_hits.all(func(hit: Dictionary) -> bool: return is_equal_approx(float(hit.damage), 115.0) and hit.source == &"pierce" and int(hit.sentence_stacks) == 3), "beam core-skill execution must filter its widened cursor band and preserve damage, source, and judgment sentence stacks", failures)
	_expect(beam_primary.statuses.has(&"stun") and beam_secondary.statuses.has(&"stun") and not beam_outside.statuses.has(&"stun") and beam_primary.global_position.x > 100.0, "beam core-skill execution must apply heavy knockback and stun only to band targets", failures)
	var radial_skill_a := _active_enemy_at(Vector2(80.0, 0.0))
	var radial_skill_b := _active_enemy_at(Vector2(120.0, 40.0))
	var radial_skill_enemies: Array[Enemy] = [radial_skill_a, radial_skill_b]
	for radial_skill_target in radial_skill_enemies:
		radial_skill_target.data = precision_enemy_data
		radial_skill_target.target_position = Vector2.ZERO
		radial_skill_target.spawn_distance_limit = 500.0
	var radial_skill_hits: Array[Dictionary] = []
	var radial_skill_result := core_skill_service.execute(
		&"radial", radial_skill_enemies, Vector2.ZERO, 200.0, {}, 1.0, 1.25, false, false, 1,
		func(hit_target: Enemy, hit_damage: float, source: StringName, guaranteed_charm: bool, sentence_stacks: int, charm_extension: float) -> void:
			radial_skill_hits.append({"target": hit_target, "damage": hit_damage, "source": source, "guaranteed_charm": guaranteed_charm, "sentence_stacks": sentence_stacks, "charm_extension": charm_extension}),
		func(_hit_target: Enemy, _hit_damage: float) -> void: pass,
		func(_hit_target: Enemy, _hit_damage: float) -> void: pass,
		func(_hit_target: Enemy, _hit_damage: float) -> void: pass
	)
	_expect((radial_skill_result.hit_targets as Array) == radial_skill_enemies and radial_skill_hits.all(func(hit: Dictionary) -> bool: return is_equal_approx(float(hit.damage), 156.0) and bool(hit.guaranteed_charm) and is_equal_approx(float(hit.charm_extension), 1.25)), "radial core-skill execution must hit every target with guaranteed charm and devotion extension", failures)
	_expect(radial_skill_enemies.all(func(target: Enemy) -> bool: return target.statuses.has(&"pierce_mark")), "radial core-skill execution must expose and displace every target", failures)
	var wall_primary := _active_enemy_at(Vector2(100.0, 0.0))
	var wall_secondary := _active_enemy_at(Vector2(120.0, 100.0))
	var wall_outside := _active_enemy_at(Vector2(140.0, 160.0))
	var wall_enemies: Array[Enemy] = [wall_primary, wall_secondary, wall_outside]
	for wall_target in wall_enemies:
		wall_target.data = precision_enemy_data
		wall_target.target_position = Vector2.ZERO
		wall_target.spawn_distance_limit = 600.0
	var wall_skill_events: Array[String] = []
	var wall_skill_result := core_skill_service.execute(
		&"wall", wall_enemies, Vector2.ZERO, 200.0, {"wall_damage": 0.25, "wall_push": 20.0}, 1.0, 0.0, false, false, 1,
		func(hit_target: Enemy, hit_damage: float, source: StringName, _guaranteed_charm: bool, _sentence_stacks: int, _charm_extension: float) -> void:
			wall_skill_events.append("base:%d:%s:%.0f" % [int(hit_target.position.y), String(source), hit_damage]),
		func(hit_target: Enemy, hit_damage: float) -> void:
			wall_skill_events.append("bonus:%d:%.0f" % [int(hit_target.position.y), hit_damage])
			_expect(hit_target.statuses.has(&"slow") and hit_target.statuses.has(&"stun"), "wall bonus damage must execute after base control application", failures),
		func(_hit_target: Enemy, _hit_damage: float) -> void: pass,
		func(_hit_target: Enemy, _hit_damage: float) -> void: pass
	)
	_expect((wall_skill_result.hit_targets as Array) == [wall_primary, wall_secondary] and wall_skill_events.size() == 4 and not wall_outside.statuses.has(&"slow"), "wall core-skill execution must constrain damage and control to its cursor band", failures)
	var suppressed_wall_state := {"hits": 0}
	var suppressed_wall_result := core_skill_service.execute(
		&"wall", wall_enemies, Vector2.ZERO, 200.0, {"wall_damage": 0.25}, 1.0, 0.0, true, false, 1,
		func(_hit_target: Enemy, _hit_damage: float, _source: StringName, _guaranteed_charm: bool, _sentence_stacks: int, _charm_extension: float) -> void: suppressed_wall_state.hits = int(suppressed_wall_state.hits) + 1,
		func(_hit_target: Enemy, _hit_damage: float) -> void: suppressed_wall_state.hits = int(suppressed_wall_state.hits) + 1,
		func(_hit_target: Enemy, _hit_damage: float) -> void: pass,
		func(_hit_target: Enemy, _hit_damage: float) -> void: pass
	)
	_expect((suppressed_wall_result.hit_targets as Array).is_empty() and int(suppressed_wall_state.hits) == 0, "candidate mass summoning must suppress the native wall execution without invoking damage callbacks", failures)
	var barrage_skill_enemies: Array[Enemy] = [
		_active_enemy_at(Vector2(20.0, 0.0)),
		_active_enemy_at(Vector2(40.0, 0.0)),
		_active_enemy_at(Vector2(60.0, 0.0)),
	]
	var barrage_rng_state := RunRng.rng.state
	RunRng.rng.seed = 7419
	var expected_barrage_pool := barrage_skill_enemies.duplicate()
	var expected_first_barrage_target := RunRng.pick(expected_barrage_pool) as Enemy
	var expected_first_barrage_damage := 100.0 * RunRng.rangef(CoreSkillExecutionService.BARRAGE_MIN_DAMAGE_MULTIPLIER, CoreSkillExecutionService.BARRAGE_MAX_DAMAGE_MULTIPLIER)
	RunRng.rng.seed = 7419
	var barrage_skill_hits: Array[Dictionary] = []
	var barrage_highroll_hits: Array[Dictionary] = []
	var barrage_skill_result := core_skill_service.execute(
		&"barrage", barrage_skill_enemies, Vector2.ZERO, 100.0, {}, 1.0, 0.0, false, false, 1,
		func(_hit_target: Enemy, _hit_damage: float, _source: StringName, _guaranteed_charm: bool, _sentence_stacks: int, _charm_extension: float) -> void: pass,
		func(_hit_target: Enemy, _hit_damage: float) -> void: pass,
		func(hit_target: Enemy, hit_damage: float) -> void: barrage_skill_hits.append({"target": hit_target, "damage": hit_damage}),
		func(hit_target: Enemy, hit_damage: float) -> void: barrage_highroll_hits.append({"target": hit_target, "damage": hit_damage})
	)
	var barrage_state_after_execution := RunRng.rng.state
	var suppressed_barrage_result := core_skill_service.execute(
		&"barrage", barrage_skill_enemies, Vector2.ZERO, 100.0, {}, 1.0, 0.0, false, true, 1,
		func(_hit_target: Enemy, _hit_damage: float, _source: StringName, _guaranteed_charm: bool, _sentence_stacks: int, _charm_extension: float) -> void: pass,
		func(_hit_target: Enemy, _hit_damage: float) -> void: pass,
		func(_hit_target: Enemy, _hit_damage: float) -> void: pass,
		func(_hit_target: Enemy, _hit_damage: float) -> void: pass
	)
	var barrage_first_cycle: Array = barrage_skill_hits.slice(0, 3).map(func(hit: Dictionary) -> Enemy: return hit.target as Enemy)
	_expect(barrage_skill_hits.size() == CoreSkillExecutionService.BARRAGE_HIT_LIMIT and (barrage_skill_result.hit_targets as Array).size() == 3 and (barrage_skill_result.barrage_positions as Array).size() == CoreSkillExecutionService.BARRAGE_POSITION_LIMIT, "barrage core-skill execution must cover every target before repeating across 28 hits and retain twelve presentation positions", failures)
	_expect(barrage_first_cycle.all(func(target: Enemy) -> bool: return target in barrage_skill_enemies) and barrage_first_cycle[0] != barrage_first_cycle[1] and barrage_first_cycle[0] != barrage_first_cycle[2] and barrage_first_cycle[1] != barrage_first_cycle[2], "barrage core-skill execution must use a non-replacement first target cycle", failures)
	_expect(barrage_skill_hits[0].target == expected_first_barrage_target and is_equal_approx(float(barrage_skill_hits[0].damage), expected_first_barrage_damage) and barrage_highroll_hits.size() == 4 and barrage_highroll_hits.all(func(hit: Dictionary) -> bool: return is_equal_approx(float(hit.damage), 16.0)), "barrage core-skill execution must preserve target-then-damage RNG order and seventh-hit splash cadence", failures)
	_expect((suppressed_barrage_result.hit_targets as Array).is_empty() and RunRng.rng.state == barrage_state_after_execution, "Irelai death wave must suppress native barrage execution without consuming barrage RNG", failures)
	RunRng.rng.state = barrage_rng_state
	for core_skill_target in beam_enemies + radial_skill_enemies + wall_enemies + barrage_skill_enemies:
		core_skill_target.free()
	var unique_field_service := UniqueFieldAttackExecutionService.new()
	var unique_field_enemies: Array[Enemy] = []
	for enemy_index in 7:
		unique_field_enemies.append(_active_enemy_at(Vector2(float(enemy_index) * 20.0, 0.0)))
	var radial_hits: Array[Dictionary] = []
	var radial_result := unique_field_service.execute_radial(
		unique_field_enemies,
		Vector2.ZERO,
		100.0,
		100.0,
		func(hit_target: Enemy, hit_damage: float, show_presentation: bool) -> float:
			radial_hits.append({"target": hit_target, "damage": hit_damage, "show_presentation": show_presentation})
			return hit_damage
	)
	_expect(int(radial_result.hit_count) == 7 and radial_hits.size() == 7 and is_equal_approx(float(radial_result.dealt), 572.0), "unique radial execution must visit every target and preserve distance-falloff damage", failures)
	_expect(is_equal_approx(float(radial_hits[0].damage), 100.0) and is_equal_approx(float(radial_hits[5].damage), 68.0) and is_equal_approx(float(radial_hits[6].damage), 68.0), "unique radial execution must clamp falloff at the configured minimum multiplier", failures)
	_expect(bool(radial_hits[5].show_presentation) and not bool(radial_hits[6].show_presentation), "unique radial execution must preserve the six-hit presentation budget", failures)
	var combat_rng_state := RunRng.rng.state
	RunRng.rng.seed = 8128
	var first_target_state := {"target": null, "roll": -1.0}
	var random_hits: Array[Dictionary] = []
	var random_result := unique_field_service.execute_random(
		unique_field_enemies,
		100.0,
		func(first_target: Enemy) -> void:
			first_target_state.target = first_target
			first_target_state.roll = RunRng.roll(),
		func(hit_target: Enemy, hit_damage: float) -> float:
			random_hits.append({"target": hit_target, "damage": hit_damage})
			return hit_damage
	)
	RunRng.rng.seed = 8128
	var expected_random_pool: Array[Enemy] = unique_field_enemies.duplicate()
	var expected_first_target := RunRng.pick(expected_random_pool) as Enemy
	expected_random_pool.erase(expected_first_target)
	var expected_first_callback_roll := RunRng.roll()
	var expected_first_damage := 100.0 * RunRng.rangef(0.72, 1.48)
	RunRng.rng.state = combat_rng_state
	var random_target_ids := {}
	var random_damage_in_range := true
	var random_dealt_sum := 0.0
	for random_hit in random_hits:
		random_target_ids[(random_hit.target as Enemy).get_instance_id()] = true
		var random_hit_damage := float(random_hit.damage)
		random_damage_in_range = random_damage_in_range and random_hit_damage >= 72.0 and random_hit_damage <= 148.0
		random_dealt_sum += random_hit_damage
	_expect(int(random_result.hit_count) == 4 and random_hits.size() == 4 and random_target_ids.size() == 4, "unique random execution must select up to four targets without replacement", failures)
	_expect(random_result.target == expected_first_target and first_target_state.target == expected_first_target and is_equal_approx(float(first_target_state.roll), expected_first_callback_roll) and is_equal_approx(float(random_hits[0].damage), expected_first_damage), "unique random execution must preserve first-target callback and RNG sequencing before damage resolution", failures)
	_expect(random_damage_in_range and is_equal_approx(float(random_result.dealt), random_dealt_sum), "unique random execution must preserve lucky-damage bounds and aggregate callback damage", failures)
	for unique_field_enemy in unique_field_enemies:
		unique_field_enemy.free()
	var rapid_hit_profile := TowerHitPresentationProfile.build(DataRegistry.get_tower(&"rapid"), 100.0, 14.0, 1.0)
	var execute_hit_profile := TowerHitPresentationProfile.build(DataRegistry.get_tower(&"execute"), 100.0, 140.0, 2.0)
	var fallback_tower := TowerData.new()
	fallback_tower.behavior = &"contract_unknown"
	var fallback_hit_profile := TowerHitPresentationProfile.build(fallback_tower, 0.0, 0.0, 0.0)
	_expect(is_equal_approx(float(rapid_hit_profile.radius), 20.0) and is_equal_approx(float(execute_hit_profile.radius), 44.0) and is_equal_approx(float(fallback_hit_profile.radius), TowerHitPresentationProfile.DEFAULT_RADIUS), "tower-hit presentation profiles must own behavior-specific and fallback radii", failures)
	_expect(is_equal_approx(float(rapid_hit_profile.strength), 0.74) and is_equal_approx(float(execute_hit_profile.strength), 0.9) and is_equal_approx(float(fallback_hit_profile.strength), 0.14), "tower-hit presentation profiles must preserve damage-relative strength and both clamps", failures)
	var presentation_effects := Node2D.new()
	var presentation_metrics := RunMetrics.new()
	var presentation_service := CombatPresentationService.new()
	presentation_service.configure(presentation_effects, presentation_metrics)
	presentation_service.show_impact(Vector2(24.0, 40.0), Color.CORNFLOWER_BLUE, 18.0, 0.5)
	var impact_effect := presentation_effects.get_child(0) as CombatEffect
	_expect(presentation_service.is_configured() and impact_effect != null and impact_effect.effect_style == &"impact" and impact_effect.start_position == Vector2(24.0, 40.0), "combat presentation service must create configured impact effects in the injected container", failures)
	var presentation_target := _active_enemy_at(Vector2(90.0, 20.0))
	var presentation_enemy_data := EnemyData.new()
	presentation_enemy_data.max_health = 100.0
	presentation_target.data = presentation_enemy_data
	var presented_profile := presentation_service.present_tower_hit(DataRegistry.get_tower(&"rapid"), presentation_target, Vector2(10.0, 20.0), 14.0)
	var tower_hit_effect := presentation_effects.get_child(1) as CombatEffect
	_expect(tower_hit_effect != null and tower_hit_effect.effect_style == &"hit_rapid" and presentation_target.hit_feedback_profile == &"rapid" and not presentation_target.hit_visual_velocity.is_zero_approx(), "combat presentation service must keep tower-hit visuals and target recoil feedback in one presentation boundary", failures)
	_expect(is_equal_approx(float(presented_profile.strength), 0.74) and int(presentation_metrics.effect_budget_spawned.get("standard", 0)) == 1 and int(presentation_metrics.effect_budget_spawned.get("minor", 0)) == 1, "combat presentation service must preserve tower-hit profiles and record effect-budget outcomes", failures)
	presentation_target.free()
	presentation_effects.free()
	presentation_metrics.free()
static func _run_phase_offer_and_startup_contracts(context: ContractContext, failures: Array[String]) -> void:
	var loadout := context.loadout
	var offer_service := context.offer_service
	var phase_coordinator := GamePhaseCoordinator.new()
	phase_coordinator.enter_running()
	_expect(phase_coordinator.open_pause() and phase_coordinator.current_phase == GameTypes.GamePhase.PAUSED, "game phase coordinator must enter pause from the active combat phase", failures)
	_expect(not phase_coordinator.open_pause(), "game phase coordinator must reject a nested pause transition", failures)
	_expect(phase_coordinator.close_pause() and phase_coordinator.current_phase == GameTypes.GamePhase.RUNNING, "game phase coordinator must restore the phase captured before pause", failures)
	_expect(phase_coordinator.resume_combat(true, true) == GameTypes.GamePhase.BOSS_BATTLE, "active bosses must take priority when the combat phase resumes", failures)
	_expect(phase_coordinator.resume_combat(false, true) == GameTypes.GamePhase.BOSS_WARNING, "a pending warning must resume before ordinary combat", failures)
	_expect(phase_coordinator.resume_combat(false, false) == GameTypes.GamePhase.RUNNING, "combat must resume to the running phase without boss state", failures)
	phase_coordinator.finish(true)
	_expect(phase_coordinator.current_phase == GameTypes.GamePhase.VICTORY and not phase_coordinator.pause_open, "finishing a run must own the terminal phase and clear pause state", failures)

	var reward_queue := RunRewardQueue.new()
	_expect(reward_queue.enqueue_level_up(2), "the first queued level-up must request opening the reward UI", failures)
	_expect(reward_queue.begin_level_up() and reward_queue.current_reward_level(99) == 2, "the reward queue must expose the active level for placement refunds", failures)
	_expect(not reward_queue.enqueue_level_up(3), "additional level-ups must stay queued while a reward is active", failures)
	_expect(not reward_queue.enqueue_candidate_branch(), "candidate rewards must stay queued while a level-up is active", failures)
	_expect(reward_queue.complete_level_up() == RunRewardQueue.RewardKind.CANDIDATE_BRANCH, "candidate branch rewards must take priority after the current level-up", failures)
	_expect(reward_queue.begin_candidate_branch() and reward_queue.candidate_branch_active, "the candidate reward must consume one pending branch when it opens", failures)
	_expect(reward_queue.complete_candidate_branch() == RunRewardQueue.RewardKind.LEVEL_UP, "remaining level-ups must continue after the candidate branch", failures)
	_expect(reward_queue.selection_active and reward_queue.current_reward_level(99) == 3, "queued level-up levels must preserve FIFO order and remain active across reward transitions", failures)
	_expect(reward_queue.complete_level_up() == RunRewardQueue.RewardKind.NONE and not reward_queue.selection_active, "the final reward must close selection state", failures)
	reward_queue.enqueue_level_up(4)
	reward_queue.begin_level_up()
	reward_queue.enqueue_candidate_branch()
	_expect(reward_queue.discard_candidate_branches() == RunRewardQueue.RewardKind.LEVEL_UP, "an unavailable candidate branch must fall back to the pending level-up instead of stalling", failures)
	reward_queue.reset()
	_expect(reward_queue.pending_level_ups == 0 and reward_queue.reward_levels.is_empty() and reward_queue.pending_candidate_branches == 0 and not reward_queue.selection_active, "finishing a run must clear every queued reward state", failures)

	var selection_router := UpgradeSelectionRouter.new()
	var default_game_controller := GameController.new()
	_expect(default_game_controller.block_board_active, "every game controller must default to the current block-board runtime", failures)
	default_game_controller.free()
	var ui_snapshot_source := FileAccess.get_file_as_string("res://tests/ui_snapshot_runner.gd")
	var smoke_source := FileAccess.get_file_as_string("res://tests/smoke_test_runner.gd")
	var loadout_source := FileAccess.get_file_as_string("res://scripts/progression/loadout_manager.gd")
	var placement_source := FileAccess.get_file_as_string("res://scripts/progression/formation_placement_service.gd")
	var offer_source := FileAccess.get_file_as_string("res://scripts/progression/upgrade_offer_service.gd")
	_expect(not ui_snapshot_source.contains("use_legacy_column_fixture_for_testing = true") and ui_snapshot_source.contains("place_formation_block"), "UI snapshot fixtures must exercise current block-board placement instead of the retired column runtime", failures)
	_expect(not smoke_source.contains("use_legacy_column_fixture_for_testing") and smoke_source.contains("placed_formation_slices"), "the gameplay smoke fixture must exercise current block ownership instead of a retired column opt-in", failures)
	_expect(not loadout_source.contains("LegacyColumn") and not loadout_source.contains("_equip_formation") and not FileAccess.file_exists("res://scripts/progression/legacy_column_fixture_catalog.gd") and not FileAccess.file_exists("res://scripts/progression/legacy_column_snapshot_adapter.gd"), "retired column recipes, snapshots, and equip paths must be absent from the runtime", failures)
	_expect(loadout_source.contains("placement_service.place(") and not loadout_source.contains("board_state.place(") and not loadout_source.contains("TowerColumn.new()") and placement_source.contains("board_state.place(") and placement_source.contains("_rollback("), "formation placement must delegate board commits, combat-slice creation, and rollback to its dedicated service", failures)
	_expect(loadout_source.contains("offer_service.generate(") and not loadout_source.contains("_generate_block_upgrade_choices") and not loadout_source.contains("_random_formation_set_choice") and offer_source.contains("specialization_policy.inject(") and offer_source.contains("guard_growth_policy.inject(") and offer_source.contains("generate_rerolled("), "upgrade offers must delegate three-card composition, formation weighting, both pity injections, and reroll restoration to their dedicated service", failures)
	var formation_set_choice := UpgradeData.new().configure(&"formation_set", "set", "test", &"size_3")
	var specialization_choice := UpgradeData.new().configure(&"tower_specialization_entry", "specialize", "test", &"rapid")
	var placement_choice := UpgradeData.new().configure(&"new_formation", "formation", "test", &"rapid_pair")
	var direct_choice := UpgradeData.new().configure(&"global_upgrade", "direct", "test", &"global")
	var artifact_choice := UpgradeData.new().configure(&"artifact", "artifact", "test", &"contract_artifact")
	var tutorial_choice := UpgradeData.new().configure(&"cursor_level", "tutorial", "test", &"iron")
	_expect(selection_router.route_for(direct_choice, true) == UpgradeSelectionRouter.Route.CANDIDATE_BRANCH and selection_router.route_for(artifact_choice, true) == UpgradeSelectionRouter.Route.CANDIDATE_BRANCH, "candidate reward mode must take priority over every ordinary upgrade route, including artifact cards", failures)
	_expect(selection_router.route_for(artifact_choice, false) == UpgradeSelectionRouter.Route.ARTIFACT, "ordinary artifact cards must route through artifact acquisition before direct application", failures)
	_expect(selection_router.route_for(tutorial_choice, true, true, &"cursor_level", &"iron") == UpgradeSelectionRouter.Route.TUTORIAL_FIXED, "the exact tutorial growth card must take priority over candidate and ordinary reward routes", failures)
	_expect(selection_router.route_for(direct_choice, false, true, &"cursor_level", &"iron") == UpgradeSelectionRouter.Route.IGNORE and selection_router.route_for(null, false, true, &"cursor_level", &"iron") == UpgradeSelectionRouter.Route.IGNORE and selection_router.route_for(tutorial_choice, false, true) == UpgradeSelectionRouter.Route.IGNORE, "fixed-growth tutorial steps must ignore mismatched, empty, and unconfigured selections without applying another route", failures)
	_expect(selection_router.route_for(formation_set_choice, false) == UpgradeSelectionRouter.Route.FORMATION_SET, "block-board formation sets must open their frozen subchoice flow", failures)
	_expect(selection_router.route_for(specialization_choice, false) == UpgradeSelectionRouter.Route.SPECIALIZATION, "the selection router must identify specialization-entry categories without controller-side classification", failures)
	_expect(selection_router.route_for(placement_choice, false) == UpgradeSelectionRouter.Route.BLOCK_FORMATION_PLACEMENT, "new block formations must use the board placement flow", failures)
	placement_choice.placement_confirmed = true
	_expect(selection_router.route_for(placement_choice, false) == UpgradeSelectionRouter.Route.APPLY and selection_router.route_for(direct_choice, false) == UpgradeSelectionRouter.Route.APPLY, "confirmed placements and direct cards must advance to upgrade application", failures)
	_expect(selection_router.failure_route_for(placement_choice) == UpgradeSelectionRouter.FailureRoute.BLOCK_FORMATION_RETRY and selection_router.failure_route_for(direct_choice) == UpgradeSelectionRouter.FailureRoute.REFRESH_MAIN_CHOICES, "failed block placements must retry the board while other failures refresh the main cards", failures)
static func _run_shutdown_and_cleanup_contracts(context: ContractContext, failures: Array[String]) -> void:
	var loadout := context.loadout
	var shutdown_service := RunShutdownService.new()
	var shutdown_spawner := EnemySpawner.new()
	shutdown_spawner.running = true
	var shutdown_cursor := TargetCursor.new()
	shutdown_cursor.active = true
	shutdown_cursor.dragging = true
	var shutdown_core := DefenseCore.new()
	shutdown_core.active = true
	var shutdown_enemy := _active_enemy_at(Vector2.ZERO)
	var shutdown_enemies: Array[Enemy] = [shutdown_enemy]
	var shutdown_death_wave := DeathWaveController.new()
	shutdown_death_wave.active = true
	shutdown_death_wave.hit_instance_ids[1] = true
	var shutdown_necromancy := NecromancyController.new()
	shutdown_necromancy.active_summons.append({"id": 1})
	var shutdown_summon_service := SummonService.new()
	shutdown_summon_service.request_slots(&"shutdown_probe", 1, 1)
	var shutdown_abyss := AbyssSummon.new()
	shutdown_abyss.managed_by_pool = true
	var shutdown_summons: Array[Node] = [shutdown_abyss]
	var no_projectiles: Array[Node] = []
	var freed_reaper := Node.new()
	freed_reaper.free()
	var shutdown_summary := shutdown_service.cleanup_combat_runtime(shutdown_spawner, shutdown_cursor, shutdown_core, shutdown_enemies, freed_reaper, shutdown_death_wave, shutdown_necromancy, no_projectiles, shutdown_summons, shutdown_summon_service)
	_expect(not shutdown_spawner.running and not shutdown_cursor.active and not shutdown_cursor.dragging and not shutdown_core.active and not shutdown_enemy.active, "run shutdown must stop the spawner and every primary combat actor", failures)
	_expect(not shutdown_death_wave.active and shutdown_death_wave.hit_instance_ids.is_empty() and shutdown_necromancy.active_summons.is_empty(), "run shutdown must cancel candidate transient combat systems", failures)
	_expect(shutdown_abyss.expiring and shutdown_summon_service.active_count() == 0, "run shutdown must expire abyss summons and reset the shared summon budget", failures)
	_expect(int(shutdown_summary.primary_actors_stopped) == 3 and int(shutdown_summary.enemies_stopped) == 1 and int(shutdown_summary.abyss_summons_expired) == 1 and bool(shutdown_summary.death_wave_cancelled) and bool(shutdown_summary.necromancy_cleared) and bool(shutdown_summary.summon_budget_reset), "run shutdown must report every completed cleanup boundary", failures)

	var startup_service := RunStartupService.new()
	var startup_plan := startup_service.build_plan(ConceptService.get_default_stage(), PackedScene.new(), true, 9182, RunResultService.new())
	_expect(bool(startup_plan.success) and startup_plan.stage_data != null and startup_plan.boss_plan != null, "run startup must resolve stage content and a validated runtime boss plan", failures)
	_expect(startup_plan.core_data != null and startup_plan.cursor_data != null and not String(startup_plan.run_id).is_empty(), "run startup must resolve the selected combat identities and issue one run identifier", failures)
	_expect(startup_service.begin_checkpoint({}, true), "test runs must bypass durable checkpoint writes through the startup boundary", failures)
	var invalid_startup_plan := startup_service.build_plan(null, null, true, 9182, RunResultService.new())
	_expect(not bool(invalid_startup_plan.success) and not String(invalid_startup_plan.error_message).is_empty(), "run startup must reject missing scene dependencies before mutating runtime nodes", failures)

	var signal_binding_service := RunSignalBindingService.new()
	var stop_callback := Callable(shutdown_core, "stop")
	_expect(signal_binding_service.connect_once(shutdown_core.destroyed, stop_callback) == 1 and signal_binding_service.connect_once(shutdown_core.destroyed, stop_callback) == 0, "run signal binding must connect each callback exactly once", failures)
	shutdown_core.destroyed.disconnect(stop_callback)
	var mechanics_factory := CandidateMechanicsFactory.new()
	var amethyst_mechanics_plan := mechanics_factory.component_plan(DataRegistry.get_core(&"amethyst"), null)
	var jade_mechanics_plan := mechanics_factory.component_plan(DataRegistry.get_core(&"jade"), null)
	_expect(&"summon_service" in amethyst_mechanics_plan and &"candidate_abyss" in amethyst_mechanics_plan and &"necromancy" not in amethyst_mechanics_plan, "candidate mechanics factory must plan Kasuha's shared budget and abyss controller only", failures)
	_expect(&"summon_service" in jade_mechanics_plan and &"necromancy" in jade_mechanics_plan and &"death_wave" in jade_mechanics_plan, "candidate mechanics factory must plan Irelai's shared budget, necromancy, and death wave together", failures)
	var campaign := ConceptService.get_election_campaign()
	var combo_retainer: RetainerProfileData
	var vanguard_retainer: RetainerProfileData
	if campaign != null:
		for retainer in campaign.retainers:
			if combo_retainer == null and retainer != null and retainer.combo_profile != null:
				combo_retainer = retainer
			if vanguard_retainer == null and retainer != null and retainer.vanguard_stack_profile != null:
				vanguard_retainer = retainer
	_expect(combo_retainer != null and &"retainer_reconstruction" in mechanics_factory.component_plan(null, combo_retainer), "candidate mechanics factory must plan reconstruction from the retainer profile", failures)
	_expect(vanguard_retainer != null and &"vanguard_squad" in mechanics_factory.component_plan(null, vanguard_retainer), "candidate mechanics factory must plan vanguard stacks from the retainer profile", failures)
	var reactivation_registry := RetainerReactivationRegistry.new()
	var reactivation_effects := Node2D.new()
	var reactivation_column := TowerColumn.new()
	var reactivation_tower := DataRegistry.get_tower(&"jade_roulette")
	var first_reactivation := reactivation_registry.get_or_create(reactivation_column, 2, reactivation_tower, reactivation_effects, {"retainer_health": 1.0})
	var reused_reactivation := reactivation_registry.get_or_create(reactivation_column, 2, reactivation_tower, reactivation_effects, {"retainer_health": 1.4})
	_expect(first_reactivation != null and reused_reactivation == first_reactivation and reactivation_registry.component_count() == 1, "retainer reactivation registry must reuse one lifecycle component per column row", failures)
	_expect(is_equal_approx(reused_reactivation.maximum_health, reactivation_tower.reactivation_profile.maximum_health * 1.4), "retainer reactivation registry must refresh modifiers when reusing a lifecycle component", failures)
	var no_reactivation_columns: Array[TowerColumn] = []
	var reactivation_sync := reactivation_registry.synchronize(no_reactivation_columns, reactivation_effects, Callable())
	_expect(int(reactivation_sync.removed) == 1 and reactivation_registry.component_count() == 0 and first_reactivation.is_queued_for_deletion(), "retainer reactivation registry must remove stale lifecycle components when their tower leaves the loadout", failures)
	reactivation_effects.free()
	reactivation_column.free()
	var sacrifice_controller := AbyssSacrificeController.new()
	var first_sacrifice_plan := sacrifice_controller.plan_sacrifice(0, 4, 0, 2, true)
	var spawn_sacrifice_plan := sacrifice_controller.plan_sacrifice(3, 4, 1, 2, true)
	var capped_sacrifice_plan := sacrifice_controller.plan_sacrifice(2, 4, 2, 2, true)
	_expect(bool(first_sacrifice_plan.accepted) and int(first_sacrifice_plan.next_stacks) == 1 and not bool(first_sacrifice_plan.should_spawn), "abyss sacrifice controller must accumulate one bounded stack per eligible defeat", failures)
	_expect(bool(spawn_sacrifice_plan.accepted) and int(spawn_sacrifice_plan.next_stacks) == 0 and bool(spawn_sacrifice_plan.should_spawn), "the fourth abyss sacrifice must consume its stack bundle and request one summon", failures)
	_expect(not bool(capped_sacrifice_plan.accepted) and bool(capped_sacrifice_plan.rejected_full) and int(capped_sacrifice_plan.next_stacks) == 2, "a full abyss summon row must reject sacrifices without banking hidden stacks", failures)
	var sacrifice_permission_calls: Array[Dictionary] = []
	var invalid_sacrifice_result := sacrifice_controller.register_sacrifice(null, 0, Vector2.ZERO, func(_column: TowerColumn, _tower: TowerData) -> bool:
		sacrifice_permission_calls.append({})
		return true
	)
	_expect(invalid_sacrifice_result.reason == &"invalid_column" and sacrifice_permission_calls.is_empty() and (invalid_sacrifice_result.metric_events as Array).is_empty(), "abyss sacrifice registration must reject invalid columns before consulting guard permissions or emitting metrics", failures)
	var sacrifice_contract_column := TowerColumn.new()
	sacrifice_contract_column.row_towers.append(DataRegistry.get_tower(&"rapid"))
	var unsupported_sacrifice_result := sacrifice_controller.register_sacrifice(sacrifice_contract_column, 0, Vector2.ZERO, func(_column: TowerColumn, _tower: TowerData) -> bool:
		sacrifice_permission_calls.append({})
		return true
	)
	_expect(unsupported_sacrifice_result.reason == &"unsupported_tower" and sacrifice_permission_calls.is_empty(), "abyss sacrifice registration must own slow-tower qualification and skip permissions for unrelated defenders", failures)
	sacrifice_contract_column.row_towers[0] = DataRegistry.get_tower(&"slow")
	var denied_sacrifice_result := sacrifice_controller.register_sacrifice(sacrifice_contract_column, 0, Vector2.ZERO, func(permission_column: TowerColumn, permission_tower: TowerData) -> bool:
		sacrifice_permission_calls.append({"column": permission_column, "tower": permission_tower})
		return false
	)
	_expect(denied_sacrifice_result.reason == &"permission_denied" and sacrifice_permission_calls.size() == 1 and sacrifice_permission_calls[0].column == sacrifice_contract_column and sacrifice_permission_calls[0].tower.id == &"slow", "abyss sacrifice registration must consult the guard permission exactly once after base tower qualification", failures)
	var inactive_sacrifice_result := sacrifice_controller.register_sacrifice(sacrifice_contract_column, 0, Vector2.ZERO)
	_expect(inactive_sacrifice_result.reason == &"inactive_branch" and not bool(inactive_sacrifice_result.accepted) and (inactive_sacrifice_result.metric_events as Array).is_empty(), "abyss sacrifice registration must reject slow towers without the sacrifice branch before range or budget work", failures)
	sacrifice_contract_column.free()
	var sacrifice_key := &"contract_pillar"
	sacrifice_controller.active_summons[sacrifice_key] = 2
	_expect(sacrifice_controller.release_active(sacrifice_key) == 1 and int(sacrifice_controller.active_summons.get(sacrifice_key, 0)) == 1, "abyss sacrifice controller must return exactly one row-local slot per expired summon", failures)
	var enemy_lifecycle := EnemyLifecycleController.new()
	var earlier_boss := _active_enemy_at(Vector2.ZERO)
	var latest_boss := _active_enemy_at(Vector2.ONE)
	earlier_boss.data = DataRegistry.bosses[0]
	latest_boss.data = DataRegistry.bosses[1]
	_expect(enemy_lifecycle.register_boss(earlier_boss) and enemy_lifecycle.register_boss(latest_boss) and enemy_lifecycle.current_boss == latest_boss, "enemy lifecycle must track the most recently registered active boss", failures)
	_expect(enemy_lifecycle.unregister_boss(earlier_boss) and enemy_lifecycle.current_boss == latest_boss and enemy_lifecycle.active_bosses.size() == 1, "removing an older boss must preserve the latest active boss", failures)
	latest_boss.active = false
	_expect(enemy_lifecycle.refresh_bosses() == null and enemy_lifecycle.active_bosses.is_empty(), "enemy lifecycle refresh must prune inactive bosses and clear the current boss", failures)
	var defeat_policy := EnemyDefeatPolicy.new()
	var splitter_data := EnemyData.new()
	splitter_data.id = &"contract_splitter"
	splitter_data.behavior = &"splitter"
	splitter_data.experience_value = 10.0
	var splitter_plan := defeat_policy.build_plan(splitter_data, 15.0, false, true, true, true, true)
	_expect(bool(splitter_plan.record_candidate_soul) and not bool(splitter_plan.allow_random_necromancy), "enemy defeat policy must preserve soul harvest while suppressing random necromancy during a death wave", failures)
	_expect(StringName(splitter_plan.reward_kind) == &"orb" and bool(splitter_plan.trigger_reward_chain) and int(splitter_plan.splitter_child_count) == 2, "an enriched splitter defeat must grant one orb, trigger the reward chain, and request two children", failures)
	var final_boss_plan := defeat_policy.build_plan(DataRegistry.bosses.back(), 1.0, true, false, false, false, false)
	_expect(bool(final_boss_plan.is_boss) and bool(final_boss_plan.is_final_boss) and bool(final_boss_plan.stop_timeline) and StringName(final_boss_plan.reward_kind) == &"boss_burst", "a final boss defeat must stop the timeline and route through the boss reward settlement", failures)
	earlier_boss.free()
	latest_boss.free()
	shutdown_spawner.free()
	shutdown_cursor.free()
	shutdown_core.free()
	shutdown_enemy.free()
	shutdown_death_wave.free()
	shutdown_necromancy.free()
	shutdown_summon_service.free()
	shutdown_abyss.free()
	loadout.free()

static func _active_enemy_at(spawn_position: Vector2) -> Enemy:
	var enemy := Enemy.new()
	enemy.position = spawn_position
	enemy.active = true
	return enemy

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
