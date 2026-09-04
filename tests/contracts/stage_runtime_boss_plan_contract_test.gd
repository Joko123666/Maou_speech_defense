class_name StageRuntimeBossPlanContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var stage := ConceptService.get_default_stage()
	var fixed_plan := CampaignStageResolver.build_fixed_plan(stage, DataRegistry.bosses, 1847)
	_expect(fixed_plan.get_validation_errors(stage, DataRegistry.catalog_ids(DataRegistry.bosses)).is_empty(), "the standard stage must produce a valid explicit fixed runtime boss plan", failures)
	_expect(fixed_plan.slots.size() == 4 and fixed_plan.final_boss_id == &"final_boss", "the fixed plan must preserve four milestones and its declared final boss", failures)
	_expect(fixed_plan.to_snapshot().get("slots", []).size() == 4 and StageRuntimeBossPlan.is_valid_snapshot(fixed_plan.to_snapshot()), "runtime boss plans must serialize into a valid checkpoint-safe snapshot", failures)

	var expanded_catalog: Array[EnemyData] = []
	expanded_catalog.assign(DataRegistry.bosses)
	var reserve_boss := DataRegistry.bosses[0].duplicate(true) as EnemyData
	reserve_boss.id = &"reserve_boss"
	reserve_boss.display_name = "예비 보스"
	expanded_catalog.append(reserve_boss)
	var expanded_spawner := EnemySpawner.new()
	expanded_spawner.start(stage, DataRegistry.enemies, expanded_catalog, Battlefield.LANE_COUNT, 0, fixed_plan)
	_expect(expanded_spawner.boss_pool.size() == 4 and expanded_spawner.boss_pool.all(func(boss: EnemyData) -> bool: return boss.id != &"reserve_boss"), "a boss catalog larger than four entries must still spawn only the four bosses in the runtime plan", failures)
	expanded_spawner.stop()
	expanded_spawner.free()

	var five_candidate_campaign := load("res://data/concepts/demon_election_campaign_v0_8.tres") as ElectionCampaignData
	RunRng.seed_run(7319)
	var expected_gameplay_roll := RunRng.roll()
	RunRng.seed_run(7319)
	var dynamic_a := CampaignStageResolver.resolve(stage, DataRegistry.bosses, five_candidate_campaign, &"obsidian", &"vanguard", 42731)
	var gameplay_roll_after_resolve := RunRng.roll()
	var dynamic_b := CampaignStageResolver.resolve(stage, DataRegistry.bosses, five_candidate_campaign, &"obsidian", &"vanguard", 42731)
	_expect(dynamic_a.source == StageRuntimeBossPlan.SOURCE_CAMPAIGN and dynamic_a.fallback_reason.is_empty(), "a complete five-candidate campaign must produce a dynamic rival plan", failures)
	_expect(dynamic_a.to_snapshot() == dynamic_b.to_snapshot(), "the same stage, selection, and isolated seed must produce the same boss plan", failures)
	_expect(int(dynamic_a.to_snapshot().get("presentation_revision", 0)) == StageRuntimeBossPlan.PRESENTATION_REVISION and StageRuntimeBossPlan.is_valid_snapshot(dynamic_a.to_snapshot()), "campaign boss plans must serialize their presentation identity revision", failures)
	_expect(is_equal_approx(gameplay_roll_after_resolve, expected_gameplay_roll), "campaign plan resolution must not consume the gameplay random stream", failures)
	_expect(dynamic_a.slots.size() == 4 and dynamic_a.slots.all(func(slot: Dictionary) -> bool: return StringName(slot.faction_id) != &"judaginda_faction"), "a dynamic plan must contain four unique rival factions and exclude the selected faction", failures)
	var dynamic_spawner := EnemySpawner.new()
	dynamic_spawner.start(stage, DataRegistry.enemies, DataRegistry.bosses, Battlefield.LANE_COUNT, 0, dynamic_a)
	var slot_pressure_normalized := true
	for index in dynamic_spawner.boss_pool.size():
		var runtime_boss := dynamic_spawner.boss_pool[index]
		var slot_reference := DataRegistry.find_enemy(stage.default_boss_ids[index])
		slot_pressure_normalized = slot_pressure_normalized and runtime_boss.id == dynamic_a.boss_id_at(index) and is_equal_approx(runtime_boss.max_health, slot_reference.max_health) and is_equal_approx(runtime_boss.core_damage, slot_reference.core_damage) and runtime_boss.boss_tier == index + 1
	_expect(slot_pressure_normalized, "dynamic rival bosses must retain identity while health, core damage, and breach tier follow their runtime time slot", failures)
	dynamic_spawner.stop()
	dynamic_spawner.free()
	var guard_replacement_count := 0
	var resolved_plan_count := 0
	var resolved_slot_count := 0
	var selected_pair_keys: Dictionary = {}
	var guard_replacement_factions: Dictionary = {}
	var candidate_presentations: Dictionary = {}
	var retainer_presentations: Dictionary = {}
	for candidate in five_candidate_campaign.candidates:
		for retainer in five_candidate_campaign.retainers:
			selected_pair_keys["%s/%s" % [candidate.id, retainer.id]] = true
			for plan_seed in [17, 42731, 99881]:
				var combination_plan := CampaignStageResolver.resolve(stage, DataRegistry.bosses, five_candidate_campaign, candidate.core_id, retainer.cursor_id, plan_seed)
				resolved_plan_count += 1
				var combination_timeline := RunResultService.new()._build_boss_timeline(combination_plan, [])
				var presentation_probe := GameController.new()
				presentation_probe.boss_plan = combination_plan
				var unique_bosses: Dictionary = {}
				var unique_factions: Dictionary = {}
				var unique_presentations: Dictionary = {}
				for slot_index in combination_plan.slots.size():
					resolved_slot_count += 1
					var slot := combination_plan.slots[slot_index]
					unique_bosses[StringName(slot.boss_id)] = true
					unique_factions[StringName(slot.faction_id)] = true
					var presentation_kind := combination_plan.presentation_kind_at(slot_index)
					var presentation_id := combination_plan.presentation_id_at(slot_index)
					unique_presentations["%s/%s" % [presentation_kind, presentation_id]] = true
					var slot_faction := five_candidate_campaign.faction(StringName(slot.faction_id))
					var faction_candidate := five_candidate_campaign.candidate(slot_faction.candidate_id) if slot_faction != null else null
					if slot_index == combination_plan.slots.size() - 1:
						_expect(presentation_kind == StageRuntimeBossPlan.PRESENTATION_CANDIDATE and faction_candidate != null and presentation_id == faction_candidate.id, "the final campaign slot must present its unselected rival candidate", failures)
						candidate_presentations[presentation_id] = true
					else:
						_expect(presentation_kind in [StageRuntimeBossPlan.PRESENTATION_RETAINER, StageRuntimeBossPlan.PRESENTATION_GUARD], "opening campaign slots must present a retainer or faction guard", failures)
						if presentation_kind == StageRuntimeBossPlan.PRESENTATION_RETAINER:
							var default_retainer := five_candidate_campaign.retainer(faction_candidate.default_retainer_id) if faction_candidate != null else null
							_expect(default_retainer != null and presentation_id == default_retainer.id and presentation_id != retainer.id, "an opening retainer presentation must belong to the rival faction and never duplicate the selected ally", failures)
							retainer_presentations[presentation_id] = true
						else:
							guard_replacement_count += 1
							guard_replacement_factions[presentation_id] = true
							_expect(slot_faction != null and presentation_id == slot_faction.id, "a replacement mechanic shell must present the same rival faction's guard identity", failures)
					var expected_category: StringName = {
						StageRuntimeBossPlan.PRESENTATION_CANDIDATE: &"candidate_intrusion_sd",
						StageRuntimeBossPlan.PRESENTATION_RETAINER: &"retainer_intrusion_sd",
						StageRuntimeBossPlan.PRESENTATION_GUARD: &"guard_intrusion_sd",
					}.get(presentation_kind, &"") as StringName
					var expected_texture := ConceptService.optional_content_texture(expected_category, presentation_id)
					var mechanic_boss := DataRegistry.find_enemy(combination_plan.boss_id_at(slot_index))
					var enemy_probe := Enemy.new()
					enemy_probe.data = mechanic_boss
					presentation_probe._apply_campaign_boss_character_art(enemy_probe, mechanic_boss)
					_expect(expected_category != &"" and expected_texture != null, "every campaign presentation must resolve a dedicated active intrusion texture", failures)
					_expect(enemy_probe.campaign_character_presentation_kind == presentation_kind and enemy_probe.campaign_character_presentation_id == presentation_id, "combat art must preserve every planned presentation identity across the full candidate-retainer matrix", failures)
					_expect(enemy_probe.campaign_character_art == expected_texture and enemy_probe.campaign_character_art_source_category == expected_category and not enemy_probe.campaign_character_art_flip_h, "every built-in campaign presentation must use direct left-facing candidate, retainer, or guard intrusion art", failures)
					var timeline_category: StringName = {
						StageRuntimeBossPlan.PRESENTATION_CANDIDATE: &"candidates",
						StageRuntimeBossPlan.PRESENTATION_RETAINER: &"retainers",
						StageRuntimeBossPlan.PRESENTATION_GUARD: &"guard_intrusion_sd",
					}.get(presentation_kind, &"") as StringName
					var expected_timeline_texture := ConceptService.optional_content_texture(timeline_category, presentation_id)
					var timeline_entry := combination_timeline[slot_index] if slot_index < combination_timeline.size() else {}
					_expect(StringName(timeline_entry.get("presentation_kind", "")) == presentation_kind and StringName(timeline_entry.get("presentation_id", "")) == presentation_id and expected_timeline_texture != null and timeline_entry.get("texture") == expected_timeline_texture, "the result timeline must preserve every presentation identity with its approved portrait or guard texture across the full candidate-retainer matrix", failures)
					enemy_probe.free()
				_expect(combination_plan.source == StageRuntimeBossPlan.SOURCE_CAMPAIGN and combination_plan.fallback_reason.is_empty(), "every candidate-retainer combination must resolve a campaign plan", failures)
				_expect(combination_timeline.size() == 4, "every resolved campaign plan must produce four result timeline entries", failures)
				_expect(combination_plan.slots.size() == 4 and unique_bosses.size() == 4 and unique_factions.size() == 4, "every campaign plan must contain four unique rival bosses and factions", failures)
				_expect(unique_presentations.size() == 4, "every campaign plan must keep four distinct visual presentation identities", failures)
				_expect(not unique_factions.has(candidate.faction_id), "a campaign plan must exclude its selected candidate faction", failures)
				presentation_probe.free()
	_expect(guard_replacement_count > 0, "the candidate-retainer matrix must exercise faction guard replacement presentations", failures)
	_expect(selected_pair_keys.size() == 25 and resolved_plan_count == 75 and resolved_slot_count == 300, "the integration matrix must cover 5 candidates by 5 retainers by 3 seeds and all 300 resulting slots", failures)
	_expect(guard_replacement_factions.size() == 5, "the integration matrix must exercise the dedicated guard intrusion for every faction", failures)
	_expect(candidate_presentations.size() == 5 and retainer_presentations.size() == 5, "the integration matrix must exercise all five candidate and all five retainer intrusion identities", failures)
	var partason_guard_plan: StageRuntimeBossPlan
	for collision_seed in range(1, 65):
		var collision_plan := CampaignStageResolver.resolve(stage, DataRegistry.bosses, five_candidate_campaign, &"obsidian", &"iron", collision_seed)
		for slot_index in collision_plan.slots.size() - 1:
			if collision_plan.faction_id_at(slot_index) == &"partason_faction":
				partason_guard_plan = collision_plan
				break
		if partason_guard_plan != null:
			break
	_expect(partason_guard_plan != null, "the collision regression fixture must place the Partason faction in an opening slot", failures)
	if partason_guard_plan != null:
		for slot_index in partason_guard_plan.slots.size() - 1:
			if partason_guard_plan.faction_id_at(slot_index) == &"partason_faction":
				_expect(partason_guard_plan.presentation_kind_at(slot_index) == StageRuntimeBossPlan.PRESENTATION_GUARD and partason_guard_plan.presentation_id_at(slot_index) == &"partason_faction", "selecting Kanda must show a Partason guard replacement instead of recoloring another faction's retainer", failures)
				var presentation_probe := GameController.new()
				presentation_probe.boss_plan = partason_guard_plan
				var presentation_enemy := Enemy.new()
				var mechanic_boss := DataRegistry.find_enemy(partason_guard_plan.boss_id_at(slot_index))
				presentation_enemy.data = mechanic_boss
				presentation_probe._apply_campaign_boss_character_art(presentation_enemy, mechanic_boss)
				_expect(presentation_enemy.campaign_character_presentation_kind == StageRuntimeBossPlan.PRESENTATION_GUARD and presentation_enemy.campaign_character_presentation_id == &"partason_faction" and presentation_enemy.campaign_character_art_source_category == &"guard_intrusion_sd" and not presentation_enemy.campaign_character_art_flip_h, "the game controller must apply the planned dedicated guard identity instead of inferring a retainer from the mechanic boss id", failures)
				var collision_timeline := RunResultService.new()._build_boss_timeline(partason_guard_plan, [])
				var timeline_entry := collision_timeline[slot_index] if slot_index < collision_timeline.size() else {}
				var partason_guard := DataRegistry.get_tower(&"emerald_guardian")
				var partason_guard_intrusion := ConceptService.optional_content_texture(&"guard_intrusion_sd", &"partason_faction")
				_expect(StringName(timeline_entry.get("presentation_kind", "")) == StageRuntimeBossPlan.PRESENTATION_GUARD and StringName(timeline_entry.get("presentation_id", "")) == &"partason_faction" and partason_guard != null and String(timeline_entry.get("display_name", "")) == partason_guard.display_name and timeline_entry.get("texture") == partason_guard_intrusion, "the result timeline must preserve the same dedicated faction guard identity shown in combat", failures)
				presentation_enemy.free()
				presentation_probe.free()
	var legacy_snapshot := dynamic_a.to_snapshot().duplicate(true) as Dictionary
	legacy_snapshot.erase("presentation_revision")
	for legacy_slot_value in legacy_snapshot.get("slots", []):
		var legacy_slot := legacy_slot_value as Dictionary
		legacy_slot.erase("presentation_kind")
		legacy_slot.erase("presentation_id")
	_expect(StageRuntimeBossPlan.is_valid_snapshot(legacy_snapshot), "revision-0 checkpoints must remain readable after the presentation identity split", failures)
	var corrupt_presentation_snapshot := dynamic_a.to_snapshot().duplicate(true) as Dictionary
	(corrupt_presentation_snapshot.slots[0] as Dictionary).erase("presentation_id")
	_expect(not StageRuntimeBossPlan.is_valid_snapshot(corrupt_presentation_snapshot), "revision-1 checkpoints must reject campaign slots with an incomplete presentation identity", failures)
	_expect(dynamic_a.final_boss_id == dynamic_a.boss_id_at(3), "only the last dynamic slot may define the final boss", failures)
	var ordinary_breach := BossBreachPolicy.breach_damage(140.0, 200.0, 4, false)
	var final_breach := BossBreachPolicy.breach_damage(140.0, 200.0, 4, true)
	_expect(is_equal_approx(ordinary_breach, 45.0) and is_equal_approx(final_breach, 44.0), "ordinary rivals must use the low-floor tier envelope while the final rival caps one breach at 22% core health", failures)
	_expect(is_equal_approx(CoreBreachDamagePolicy.regular_damage(20.0, 1.5), 9.0), "regular breaches must preserve challenge scaling after the Base-only low-floor adjustment", failures)
	_expect(is_equal_approx(CoreBreachDamagePolicy.regular_damage(20.0, 1.5, 0.7), 6.3), "candidate core-breach protection must scale regular leaks through the same explicit policy", failures)
	var first_group_breach := CoreBreachDamagePolicy.group_limited_damage(5.4, 170.0, 0.0)
	var second_group_breach := CoreBreachDamagePolicy.group_limited_damage(5.4, 170.0, first_group_breach)
	var exhausted_group_breach := CoreBreachDamagePolicy.group_limited_damage(5.4, 170.0, first_group_breach + second_group_breach)
	_expect(is_equal_approx(first_group_breach, 5.4) and is_equal_approx(second_group_breach, 1.4) and is_zero_approx(exhausted_group_breach), "one regular spawn group must retain its first full leak but cap overlapping packet damage at 4% core health", failures)
	_expect(is_equal_approx(CoreBreachDamagePolicy.group_limited_damage(13.2, 170.0, 0.0), 13.2), "the regular group cap must never reduce a single heavy enemy's full breach damage", failures)
	_expect(is_equal_approx(CoreBreachDamagePolicy.pre_final_reserve_limited_damage(20.0, 75.0, 170.0), 7.0) and is_zero_approx(CoreBreachDamagePolicy.pre_final_reserve_limited_damage(20.0, 68.0, 170.0)), "regular enemies must not lower the core below its 40% pre-final reserve", failures)
	var regular_breach_service := RegularCoreBreachService.new()
	var first_group_result := regular_breach_service.resolve(18.0, 1.0, 1.0, 170.0, 170.0, &"contract_group", false)
	var second_group_result := regular_breach_service.resolve(18.0, 1.0, 1.0, 164.6, 170.0, &"contract_group", false)
	var exhausted_group_result := regular_breach_service.resolve(18.0, 1.0, 1.0, 163.2, 170.0, &"contract_group", false)
	_expect(is_equal_approx(float(first_group_result.damage), 5.4) and is_zero_approx(float(first_group_result.group_prevented_damage)) and is_equal_approx(float(first_group_result.group_accumulated_damage), 5.4), "regular breach service must preserve the first full packet member and start one group accumulator", failures)
	_expect(is_equal_approx(float(second_group_result.damage), 1.4) and is_equal_approx(float(second_group_result.group_prevented_damage), 4.0) and is_equal_approx(float(second_group_result.group_accumulated_damage), 6.8), "regular breach service must expose the second packet member's group-limited damage and prevented amount", failures)
	_expect(is_zero_approx(float(exhausted_group_result.damage)) and is_equal_approx(float(exhausted_group_result.group_prevented_damage), 5.4) and is_equal_approx(float(exhausted_group_result.group_accumulated_damage), 6.8), "an exhausted packet group must report its entire resolved damage as prevented without increasing the accumulator", failures)
	var reserve_result := regular_breach_service.resolve(20.0, 1.5, 1.0, 75.0, 170.0, &"", false)
	var final_contest_result := regular_breach_service.resolve(20.0, 1.5, 1.0, 75.0, 170.0, &"", true)
	_expect(is_equal_approx(float(reserve_result.resolved_damage), 9.0) and is_equal_approx(float(reserve_result.damage), 7.0) and is_equal_approx(float(reserve_result.reserve_prevented_damage), 2.0), "pre-final regular breaches must expose damage stopped by the forty-percent core reserve", failures)
	_expect(is_equal_approx(float(final_contest_result.damage), 9.0) and is_zero_approx(float(final_contest_result.reserve_prevented_damage)), "the final contest must bypass only the pre-final reserve while preserving regular damage scaling", failures)
	regular_breach_service.reset()
	var reserve_blocked_first := regular_breach_service.resolve(18.0, 1.0, 1.0, 68.0, 170.0, &"reserve_group", false)
	var reserve_blocked_second := regular_breach_service.resolve(18.0, 1.0, 1.0, 68.0, 170.0, &"reserve_group", false)
	_expect(is_zero_approx(float(reserve_blocked_first.damage)) and is_equal_approx(float(reserve_blocked_first.reserve_prevented_damage), 5.4) and is_equal_approx(float(reserve_blocked_first.group_accumulated_damage), 5.4), "the pre-final reserve must block applied damage only after the packet accumulator consumes the first member", failures)
	_expect(is_zero_approx(float(reserve_blocked_second.damage)) and is_equal_approx(float(reserve_blocked_second.group_limited_damage), 1.4) and is_equal_approx(float(reserve_blocked_second.group_accumulated_damage), 6.8), "reserve-blocked packet members must still exhaust the shared group cap in the original ordering", failures)
	regular_breach_service.reset()
	_expect(regular_breach_service.accumulated_damage_by_group.is_empty(), "regular breach service reset must clear run-local packet accumulation", failures)
	var first_three_minimum_breaches := (
		BossBreachPolicy.breach_damage(0.0, 200.0, 1, false)
		+ BossBreachPolicy.breach_damage(0.0, 200.0, 2, false)
		+ BossBreachPolicy.breach_damage(0.0, 200.0, 3, false)
	)
	_expect(is_equal_approx(first_three_minimum_breaches, 105.0), "one breach from each midboss must stay within the 52.5% low-floor envelope before the final contest", failures)
	var first_three_high_raw_breaches := (
		BossBreachPolicy.breach_damage(999.0, 200.0, 1, false)
		+ BossBreachPolicy.breach_damage(999.0, 200.0, 2, false)
		+ BossBreachPolicy.breach_damage(999.0, 200.0, 3, false)
	)
	_expect(is_equal_approx(first_three_high_raw_breaches, 105.0), "raw boss damage must not bypass the combined 52.5% tier envelope for the first three rivals", failures)
	_expect(is_equal_approx(BossBreachPolicy.repeat_damage_multiplier(0, false), 1.0) and is_equal_approx(BossBreachPolicy.repeat_damage_multiplier(1, false), 0.1) and is_equal_approx(BossBreachPolicy.repeat_damage_multiplier(3, true), 1.0), "only repeated midboss breaches must fall to ten percent while first and final-boss breaches remain intact", failures)
	_expect(is_equal_approx(BossBreachPolicy.retreat_columns(1, false), 5.0) and is_equal_approx(BossBreachPolicy.retreat_columns(4, false), 6.5), "ordinary boss retreat distance must compensate for restored enemy movement speed and preserve a readable repeat-breach cadence", failures)
	_expect(is_equal_approx(BossBreachPolicy.retreat_columns(4, true), 3.6) and BossBreachPolicy.recovery_seconds(4, true) > BossBreachPolicy.recovery_seconds(4, false), "the final rival must keep its separately tuned retreat and longer recovery contract", failures)
	var final_boss_probe := GameController.new()
	final_boss_probe.boss_plan = dynamic_a
	_expect(final_boss_probe._is_final_boss(DataRegistry.find_enemy(dynamic_a.final_boss_id)) and not final_boss_probe._is_final_boss(DataRegistry.find_enemy(dynamic_a.boss_id_at(0))), "victory authority must follow the runtime plan's last boss rather than catalog order", failures)
	final_boss_probe.free()
	var checkpoint_candidate := {
		"version": 2,
		"run_id": "dynamic-plan-contract",
		"confirmed": true,
		"updated_unix": 1,
		"result": {
			"run_id": "dynamic-plan-contract", "stage_id": String(stage.id),
			"stage_duration_seconds": stage.duration_seconds, "elapsed": stage.boss_times[0],
			"level": 5, "challenge_level": 0, "victory": false,
			"eligible_for_meta_rewards": true, "boss_kill_ids": [String(dynamic_a.boss_id_at(0))],
			"boss_plan": dynamic_a.to_snapshot(), "meta_metrics": {},
		},
	}
	var validated_checkpoint := RunCheckpointService._validate_checkpoint(checkpoint_candidate)
	_expect(not validated_checkpoint.is_empty() and String(validated_checkpoint.result.boss_plan.selected_candidate_id) == "judaginda", "version-2 checkpoints must preserve the original boss plan and selected candidate id", failures)
	var duplicate_plan := dynamic_a.duplicate(true) as StageRuntimeBossPlan
	duplicate_plan.slots[1].boss_id = duplicate_plan.slots[0].boss_id
	_expect("\n".join(duplicate_plan.get_validation_errors(stage, DataRegistry.catalog_ids(DataRegistry.bosses))).contains("duplicate boss"), "runtime boss plan validation must reject duplicate boss slots", failures)
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
