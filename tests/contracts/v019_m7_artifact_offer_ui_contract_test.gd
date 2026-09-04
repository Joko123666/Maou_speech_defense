class_name V019M7ArtifactOfferUiContractTest
extends RefCounted

static func run(root: Node) -> Array[String]:
	var failures: Array[String] = []
	var catalog := load(ArtifactEffectResolver.CATALOG_PATH) as ArtifactCatalogData
	_expect(catalog != null, "M7 requires the validated M6 artifact catalog", failures)
	if catalog == null:
		return failures

	_expect(ArtifactOfferService.FAMILY_CHANCE < 0.10 and ArtifactOfferService.expected_offer_count(24) >= 1.0 and ArtifactOfferService.expected_offer_count(32) <= 2.0, "artifact family chance must target roughly one to two offers across a normal run", failures)
	_expect(ArtifactOfferService.should_offer(1, 0.0) and not ArtifactOfferService.should_offer(1, 0.99) and not ArtifactOfferService.should_offer(0, 0.0), "artifact occurrence must be a low-probability family roll made only when an eligible artifact exists", failures)
	var protected_choices: Array[UpgradeData] = [
		UpgradeData.new().configure(&"formation_set", "첫 편대", "required", &"size_2"),
		UpgradeData.new().configure(&"cursor_level", "심복", "protected", &"cursor"),
		UpgradeData.new().configure(&"status_upgrade", "독", "replaceable", &"poison"),
	]
	protected_choices[0].offer_metadata[UpgradeOfferService.REQUIRED_INITIAL_FORMATION_META] = true
	_expect(ArtifactOfferService.replaceable_indexes(protected_choices, true) == [2], "artifact injection must preserve the first required formation and protected growth cards", failures)
	var optional_formation := UpgradeData.new().configure(&"formation_set", "선택 편대", "replaceable", &"size_3")
	optional_formation.offer_metadata[UpgradeOfferService.OPTIONAL_INITIAL_FORMATION_META] = true
	var two_formation_choices: Array[UpgradeData] = [protected_choices[0], protected_choices[1], optional_formation]
	_expect(ArtifactOfferService.replaceable_indexes(two_formation_choices, true) == [2], "artifact injection must protect only the required initial formation and may replace the optional different-size formation", failures)
	var artifact_choice := ArtifactOfferService.build_choice(catalog.find_artifact(&"blood_prism"))
	_expect(artifact_choice != null and artifact_choice.category == &"artifact" and artifact_choice.data_id == &"blood_prism" and artifact_choice.description.contains("위력 +35%") and artifact_choice.description.contains("범위 -20") and bool(artifact_choice.offer_metadata.trade_off), "artifact cards must lock one stable id and disclose exact benefit and trade-off values", failures)
	var draft_state := RunRng.progression_rng.state
	RunRng.progression_rng.seed = 91827
	var artifact_draft := ArtifactOfferService.build_draft(catalog.artifacts, 3)
	RunRng.progression_rng.state = draft_state
	var draft_ids := artifact_draft.map(func(choice: UpgradeData) -> StringName: return choice.data_id)
	_expect(artifact_draft.size() == 3 and draft_ids[0] != draft_ids[1] and draft_ids[0] != draft_ids[2] and draft_ids[1] != draft_ids[2] and artifact_draft.all(func(choice: UpgradeData) -> bool: return choice.category == &"artifact" and choice.offer_metadata.get(&"source", &"") == &"artifact_elite"), "artifact elite drafts must contain three distinct fully disclosed artifact choices", failures)
	var choices_with_artifact: Array[UpgradeData] = [artifact_choice, protected_choices[1], protected_choices[2]]
	var before_signature := UpgradeOfferService.new().signature(choices_with_artifact)
	_expect(not ArtifactOfferService.new().inject(choices_with_artifact, [catalog.find_artifact(&"war_banner")], false) and UpgradeOfferService.new().signature(choices_with_artifact) == before_signature, "one offer screen must contain at most one artifact and must not rerandomize an already confirmed card", failures)
	var progression_state := RunRng.progression_rng.state
	var offering_seed := 0
	for seed_value in 10000:
		RunRng.progression_rng.seed = seed_value
		if RunRng.progression_rng.randf() < ArtifactOfferService.FAMILY_CHANCE:
			offering_seed = seed_value
			break
	RunRng.progression_rng.seed = offering_seed
	var injectable_choices: Array[UpgradeData] = [
		UpgradeData.new().configure(&"tower_type_level", "병력 A", "", &"rapid"),
		UpgradeData.new().configure(&"status_upgrade", "상태 B", "", &"poison"),
		UpgradeData.new().configure(&"tower_type_level", "병력 C", "", &"pierce"),
	]
	var injected := ArtifactOfferService.new().inject(injectable_choices, [catalog.find_artifact(&"war_banner"), catalog.find_artifact(&"green_gear")], false)
	RunRng.progression_rng.state = progression_state
	_expect(injected and injectable_choices.filter(func(choice: UpgradeData) -> bool: return choice.category == &"artifact").size() == 1, "a successful family roll must inject exactly one stable artifact card", failures)
	var sparse_artifact_service := ArtifactOfferService.new()
	sparse_artifact_service.mode = GameSession.ARTIFACT_MODE_FORCED
	var sparse_choices: Array[UpgradeData] = []
	_expect(sparse_artifact_service.inject(sparse_choices, [catalog.find_artifact(&"war_banner")], true, UpgradeOfferService.DISPLAY_CHOICE_COUNT) and sparse_choices.size() == 1 and sparse_choices[0].category == &"artifact", "an artifact that passes its family roll must fill an open main-offer slot before duplicate fallback", failures)

	var presentation := UpgradePresentationService.new()
	var artifact_presentation := presentation.category_presentation(&"artifact")
	var impacts := presentation.choice_impacts(artifact_choice)
	_expect(String(artifact_presentation.badge).contains("아티팩트") and impacts.size() == 2 and String(impacts[0].label) == "위력" and String(impacts[1].label) == "범위", "artifact cards must show their target axes with dedicated presentation metadata", failures)

	var reward_queue := RunRewardQueue.new()
	_expect(reward_queue.enqueue_level_up(5) and reward_queue.begin_level_up(), "the first level reward must enter the selection state", failures)
	reward_queue.enqueue_level_up(6)
	_expect(reward_queue.selection_active and reward_queue.pending_level_ups == 2, "an unresolved artifact replacement must leave the current and queued rewards intact", failures)
	_expect(reward_queue.complete_level_up() == RunRewardQueue.RewardKind.LEVEL_UP and reward_queue.pending_level_ups == 1 and reward_queue.selection_active, "resolving the artifact must advance to exactly the next queued reward", failures)
	var elite_reward_queue := RunRewardQueue.new()
	_expect(elite_reward_queue.enqueue_level_up(5) and elite_reward_queue.begin_level_up(), "artifact queue ordering fixture must begin with its active level reward", failures)
	_expect(not elite_reward_queue.enqueue_artifact_draft(2) and elite_reward_queue.current_artifact_draft_tier() == 2, "an elite artifact reward earned during another selection must remain queued without interrupting it", failures)
	_expect(elite_reward_queue.complete_level_up() == RunRewardQueue.RewardKind.ARTIFACT_DRAFT and elite_reward_queue.begin_artifact_draft(), "elite artifact drafts must take priority immediately after the current reward resolves", failures)
	elite_reward_queue.enqueue_level_up(6)
	_expect(elite_reward_queue.complete_artifact_draft() == RunRewardQueue.RewardKind.LEVEL_UP and not elite_reward_queue.artifact_draft_active and elite_reward_queue.pending_artifact_draft_tiers.is_empty(), "completing an elite artifact draft must consume it exactly once and preserve later level rewards", failures)
	var selection_panel := (load("res://scenes/ui/level_up_panel.tscn") as PackedScene).instantiate() as LevelUpPanel
	var selection_artifact_panel := (load("res://scenes/ui/artifact_resolution_panel.tscn") as PackedScene).instantiate() as ArtifactResolutionPanel
	root.add_child(selection_panel)
	root.add_child(selection_artifact_panel)
	var selection_queue := RunRewardQueue.new()
	var selection_phase := GamePhaseCoordinator.new()
	selection_phase.enter_running()
	var selection_coordinator := RewardSelectionCoordinator.new()
	selection_coordinator.configure(selection_queue, selection_phase, root.get_tree(), selection_panel, selection_artifact_panel)
	selection_queue.enqueue_level_up(5)
	var before_pause := {"count": 0}
	var selection_choice := UpgradeData.new().configure(&"tower_type_level", "계약 카드", "reward presentation", &"rapid")
	_expect(selection_coordinator.begin_level_up(func() -> void: before_pause.count += 1), "reward presentation must accept the first queued level-up", failures)
	selection_coordinator.show_level_up_choices([selection_choice], 5, 2, 3)
	selection_panel.complete_card_reveal()
	_expect(int(before_pause.count) == 1 and root.get_tree().paused and selection_phase.current_phase == GameTypes.GamePhase.LEVEL_UP and selection_panel.visible and selection_coordinator.current_choices() == [selection_choice], "reward presentation must run pre-pause cleanup once, enter the level-up phase, pause combat, and expose the offered cards", failures)
	var flow_calls := {"artifact": 0, "candidate": 0, "level": 0, "resume": 0}
	selection_coordinator.continue_flow(RunRewardQueue.RewardKind.ARTIFACT_DRAFT, func() -> void: flow_calls.artifact += 1, func() -> void: flow_calls.candidate += 1, func() -> void: flow_calls.level += 1, func() -> void: flow_calls.resume += 1)
	selection_coordinator.continue_flow(RunRewardQueue.RewardKind.CANDIDATE_BRANCH, func() -> void: flow_calls.artifact += 1, func() -> void: flow_calls.candidate += 1, func() -> void: flow_calls.level += 1, func() -> void: flow_calls.resume += 1)
	selection_coordinator.continue_flow(RunRewardQueue.RewardKind.LEVEL_UP, func() -> void: flow_calls.artifact += 1, func() -> void: flow_calls.candidate += 1, func() -> void: flow_calls.level += 1, func() -> void: flow_calls.resume += 1)
	_expect(int(flow_calls.artifact) == 1 and int(flow_calls.candidate) == 1 and int(flow_calls.level) == 1 and int(flow_calls.resume) == 0 and root.get_tree().paused, "queued artifact, candidate, and level rewards must route to exactly one matching presentation without resuming combat", failures)
	selection_coordinator.continue_flow(RunRewardQueue.RewardKind.NONE, Callable(), Callable(), Callable(), func() -> void: flow_calls.resume += 1)
	_expect(int(flow_calls.resume) == 1 and not root.get_tree().paused and not selection_panel.visible, "the final reward transition must resume the combat callback, hide cards, and unpause the scene tree", failures)
	selection_panel.queue_free()
	selection_artifact_panel.queue_free()
	var resolution_loadout := LoadoutManager.new()
	var resolution_metrics := RunMetrics.new()
	var resolution_service := ArtifactRewardResolutionService.new()
	var campaign := ConceptService.get_election_campaign()
	resolution_loadout.candidate_progression.configure(campaign.candidate(&"partason").growth_data)
	resolution_service.configure(resolution_loadout, resolution_metrics)
	var crown_choice := ArtifactOfferService.build_choice(catalog.find_artifact(&"crown_shard"))
	var acquired_result := resolution_service.begin(crown_choice)
	_expect(int(acquired_result.status) == ArtifactRewardResolutionService.Status.ACQUIRED and resolution_loadout.artifact_inventory.artifact_ids == [&"crown_shard"] and int(resolution_metrics.artifact_acquisition_counts.get("crown_shard", 0)) == 1, "artifact reward resolution must atomically equip and record an eligible artifact when inventory has room", failures)
	resolution_loadout.artifact_inventory.reset()
	for fixture_id in [&"war_banner", &"blood_prism", &"green_gear", &"overclock_coil", &"blue_lens", &"horizon_map"]:
		resolution_loadout.artifact_inventory.equip(fixture_id)
	var decree_choice := ArtifactOfferService.build_choice(catalog.find_artifact(&"decree_tablet"))
	var replacement_required := resolution_service.begin(decree_choice)
	var replaced_id := resolution_loadout.artifact_inventory.artifact_ids[2]
	var replaced_result := resolution_service.replace(2)
	_expect(int(replacement_required.status) == ArtifactRewardResolutionService.Status.REPLACEMENT_REQUIRED and int(replaced_result.status) == ArtifactRewardResolutionService.Status.REPLACED and resolution_loadout.artifact_inventory.artifact_ids[2] == &"decree_tablet" and replaced_id not in resolution_loadout.artifact_inventory.artifact_ids and resolution_service.pending_choice == null, "a full artifact reward must remain pending until one valid occupied slot is atomically replaced", failures)
	var discard_required := resolution_service.begin(crown_choice)
	var discarded_result := resolution_service.discard()
	_expect(int(discard_required.status) == ArtifactRewardResolutionService.Status.REPLACEMENT_REQUIRED and int(discarded_result.status) == ArtifactRewardResolutionService.Status.DISCARDED and &"crown_shard" not in resolution_loadout.artifact_inventory.artifact_ids and int(resolution_metrics.artifact_discard_counts.get("crown_shard", 0)) == 1, "discarding a pending artifact reward must preserve the full inventory and record exactly one discard", failures)
	resolution_loadout.free()
	resolution_metrics.free()

	var equipped: Array[ArtifactData] = []
	for artifact in catalog.artifacts.slice(0, 6):
		equipped.append(artifact)
	var resolution_scene := load("res://scenes/ui/artifact_resolution_panel.tscn") as PackedScene
	var resolution_panel := resolution_scene.instantiate() as ArtifactResolutionPanel
	root.add_child(resolution_panel)
	resolution_panel.show_resolution(catalog.artifacts[6], equipped)
	var replacement_signal := {"slot": -1}
	resolution_panel.replacement_requested.connect(func(slot_index: int) -> void: replacement_signal.slot = slot_index)
	resolution_panel._request_replacement(4)
	_expect(resolution_panel.visible and resolution_panel.slot_buttons.size() == 6 and resolution_panel.incoming_effect.text == catalog.artifacts[6].description and replacement_signal.slot == 4, "the full-inventory modal must expose six replacement slots and the exact incoming effect", failures)
	resolution_panel.queue_free()

	var hud_scene := load("res://scenes/ui/hud.tscn") as PackedScene
	var hud := hud_scene.instantiate() as GameHUD
	root.add_child(hud)
	hud.update_artifacts([{
		"id": "blood_prism", "name": "응축 혈정", "description": "위력 +35% / 범위 -20",
		"icon": &"damage", "color": Color("ed2e45"), "trade_off": true,
	}])
	hud._toggle_artifact_details()
	_expect(hud.artifact_count.text == "1/6" and hud.artifact_list.get_child_count() == 6 and hud.artifact_detail_panel.visible and hud.artifact_detail_label.text.contains("범위 -20"), "the HUD must retain six visible slots and a toggleable exact-effect detail view", failures)
	_expect(hud.artifact_detail_button.custom_minimum_size.y >= 48.0, "the artifact detail control must retain a touch-sized 48px target", failures)
	hud.queue_free()

	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
