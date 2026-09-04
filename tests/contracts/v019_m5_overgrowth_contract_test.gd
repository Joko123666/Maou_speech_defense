class_name V019M5OvergrowthContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalog := load(OvergrowthService.CATALOG_PATH) as OvergrowthCatalogData
	_expect(catalog != null and catalog.options.size() == 6, "M5 must define the initial two candidate and four retainer overgrowth options", failures)
	if catalog == null:
		return failures
	_expect(catalog.get_validation_errors().is_empty(), "M5 overgrowth catalog must pass schema validation: %s" % ", ".join(catalog.get_validation_errors()), failures)
	for option in catalog.options:
		_expect(option.bonus_per_stack >= 0.02 and option.bonus_per_stack <= 0.05, "overgrowth '%s' must remain a small numeric 2–5%% repeatable bonus" % option.id, failures)

	var campaign := ConceptService.get_election_campaign()
	var candidate := campaign.candidates.front() as CandidateProfileData
	var candidate_progression := CandidateProgressionService.new()
	candidate_progression.configure(candidate.growth_data)
	var retainer := campaign.retainers.front() as RetainerProfileData
	var retainer_progression := RetainerProgressionService.new()
	retainer_progression.configure(retainer.growth_data)
	var service := OvergrowthService.new(catalog)
	_expect(service.eligible_options(candidate_progression.is_growth_complete(), retainer_progression.is_growth_complete()).is_empty(), "overgrowth cards must never appear before their owning growth track is complete", failures)
	_expect(not service.apply(&"candidate_damage", false, false), "an early or forged overgrowth selection must be rejected by the application boundary", failures)

	candidate_progression.claim_fixed_slot(0)
	var branches := candidate_progression.get_branch_upgrades()
	candidate_progression.select_branch((branches.front() as CandidateUpgradeData).id)
	candidate_progression.claim_fixed_slot(2)
	_expect(candidate_progression.is_growth_complete(), "candidate_growth_complete must require all three timed candidate upgrades and its branch", failures)
	var candidate_options := service.eligible_options(true, false)
	_expect(candidate_options.size() == 2 and candidate_options.all(func(option: OvergrowthOptionData) -> bool: return option.target_group == &"candidate"), "candidate completion must unlock only the candidate overgrowth family", failures)

	retainer_progression.state.current_level = 7
	retainer_progression.state.selected_branch_id = retainer.growth_data.specialization_ids.front()
	_expect(retainer_progression.is_growth_complete(), "retainer completion must require Lv.7 and a selected specialization", failures)
	_expect(service.eligible_options(true, true).size() == 6, "both completed tracks must expose the full overgrowth catalog", failures)

	_expect(service.apply(&"candidate_damage", true, true) and service.apply(&"candidate_damage", true, true), "completed overgrowth must be repeatable", failures)
	_expect(service.apply(&"retainer_action_speed", true, true) and service.apply(&"retainer_collection", true, true), "retainer overgrowth must accept only completed-track selections", failures)
	_expect(is_equal_approx(service.get_multiplier(&"candidate", &"damage"), 1.08) and is_equal_approx(service.get_multiplier(&"retainer", &"action_speed"), 1.025), "repeated stacks must resolve into their declared simple numeric combat multipliers", failures)
	var snapshot := service.snapshot()
	var restored := OvergrowthService.new(catalog)
	restored.restore(snapshot)
	_expect(int(snapshot.total) == 4 and int(snapshot.candidate_total) == 2 and int(snapshot.retainer_total) == 2 and restored.get_stack_count(&"candidate_damage") == 2, "overgrowth repetitions must persist in stable run/result snapshots", failures)

	var regular := UpgradeData.new().configure(&"cursor_level", "심복 Lv.7", "regular", &"cursor")
	var overgrowth := UpgradeData.new().configure(&"retainer_overgrowth", "심복 초과성장", "repeatable", &"retainer_damage")
	_expect(UpgradeOfferService.OVERGROWTH_FAMILY_CHANCE < 0.25, "the entire overgrowth family must keep a low card-pool weight", failures)
	_expect(UpgradeOfferService.choose_growth_slot(regular, overgrowth, 0.0) == overgrowth and UpgradeOfferService.choose_growth_slot(regular, overgrowth, 0.99) == regular, "overgrowth must compete only in the growth slot without replacing normal growth on most offers", failures)
	_expect(UpgradeOfferService.choose_growth_slot(null, overgrowth, 0.99) == null, "a completed track must not force overgrowth into every late-game offer", failures)

	var loadout := LoadoutManager.new()
	var base_candidate_damage := loadout.get_core_damage_multiplier()
	var base_candidate_skill := loadout.get_core_skill_damage_multiplier()
	var base_retainer_damage := loadout.get_cursor_damage_multiplier()
	var base_retainer_speed := loadout.get_cursor_attack_speed_multiplier()
	var base_retainer_movement := loadout.get_cursor_movement_speed_multiplier()
	var base_retainer_area := loadout.get_cursor_area_multiplier()
	loadout.overgrowth_service.apply(&"candidate_damage", true, true)
	loadout.overgrowth_service.apply(&"candidate_skill", true, true)
	loadout.overgrowth_service.apply(&"retainer_damage", true, true)
	loadout.overgrowth_service.apply(&"retainer_action_speed", true, true)
	loadout.overgrowth_service.apply(&"retainer_movement", true, true)
	loadout.overgrowth_service.apply(&"retainer_collection", true, true)
	_expect(is_equal_approx(loadout.get_core_damage_multiplier(), base_candidate_damage * 1.04) and is_equal_approx(loadout.get_core_skill_damage_multiplier(), base_candidate_skill * 1.025), "candidate overgrowth must affect direct damage and unique-skill damage only after selection", failures)
	_expect(is_equal_approx(loadout.get_cursor_damage_multiplier(), base_retainer_damage * 1.045) and loadout.get_cursor_attack_speed_multiplier() > base_retainer_speed and is_equal_approx(loadout.get_cursor_movement_speed_multiplier(), base_retainer_movement * 1.03) and is_equal_approx(loadout.get_cursor_area_multiplier(), base_retainer_area * 1.025), "retainer overgrowth must reach damage, action speed, movement, and collection-area runtime getters", failures)

	var choice := UpgradeData.new().configure(&"retainer_overgrowth", "심복 초과성장 · 행동속도", "반복", &"retainer_action_speed")
	choice.offer_metadata = {"target_group": "retainer", "stat_key": "action_speed"}
	var presentation := UpgradePresentationService.new()
	_expect(String(presentation.category_presentation(choice.category).badge).contains("반복") and presentation.choice_impacts(choice).size() == 3, "overgrowth cards must clearly disclose their repeatable family and affected stat", failures)

	var metrics := RunMetrics.new()
	var candidate_choice := UpgradeData.new().configure(&"candidate_overgrowth", "후보 초과성장 · 직접 피해", "반복", &"candidate_damage")
	metrics.update_time(12.0)
	var candidate_offers: Array[UpgradeData] = [candidate_choice]
	metrics.record_choices(candidate_offers)
	metrics.update_time(14.0)
	var retainer_offers: Array[UpgradeData] = [choice]
	metrics.record_choices(retainer_offers)
	metrics.record_selection(choice)
	var timeline := metrics.growth_timeline_snapshot()
	_expect((timeline.offers as Array).size() == 2 and is_equal_approx(float((timeline.first_offer_by_track as Dictionary).candidate), 12.0) and is_equal_approx(float((timeline.first_offer_by_track as Dictionary).retainer), 14.0), "overgrowth metrics must preserve the first offered time for both completed growth tracks even before selection", failures)
	_expect(String((timeline.upgrades as Array).front().track) == "retainer", "overgrowth repetitions must be attributable to their owner in run metrics", failures)
	var summary := BalanceAuditSummary.summarize([{
		"scenario": "overgrowth_contract", "growth_timeline": timeline, "performance_budget": {"passed": true},
		"audit_target_seconds": 600.0, "elapsed": 600.0, "level": 25, "block_board": true,
	}], 1)
	_expect(is_equal_approx(float(summary.overgrowth_metrics.candidate.average_first_offer_elapsed), 12.0) and is_equal_approx(float(summary.overgrowth_metrics.retainer.average_first_offer_elapsed), 14.0) and is_equal_approx(float(summary.overgrowth_metrics.retainer.average_selections_per_run), 1.0), "audit summaries must expose first-offer timing and average overgrowth selections by owner", failures)
	metrics.free()
	loadout.free()
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
