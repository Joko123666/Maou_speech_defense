class_name FormationOfferBuilderContractTest
extends RefCounted

const STANDARD_ROLES: Array[StringName] = [
	&"basic", &"single", &"aoe", &"pierce", &"control", &"knockback",
	&"elite", &"status", &"amplify", &"contact", &"network",
]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var regular := DataRegistry.formations.filter(func(formation: TowerFormationData) -> bool: return not formation.is_unique())
	var size_counts := {2: 0, 3: 0, 4: 0}
	for formation in regular:
		size_counts[formation.cells.size()] = int(size_counts.get(formation.cells.size(), 0)) + 1
		_expect(formation.base_weight > 0.0, "formation '%s' must declare a positive offer weight" % formation.id, failures)
		_expect(not formation.role_tags.is_empty() and formation.role_tags.all(func(role: StringName) -> bool: return role in STANDARD_ROLES), "formation '%s' must use only v0.13 standard role tags" % formation.id, failures)
		_expect(formation.get_shape_errors().is_empty(), "formation '%s' must remain normalized and connected" % formation.id, failures)
	_expect(regular.size() == 49 and size_counts == {2: 15, 3: 17, 4: 17}, "the reviewed v0.13 catalog must contain 49 recipes in the 15/17/17 size distribution", failures)

	var unlock_stages: Array[Array] = [
		[&"rapid", &"pierce", &"area", &"rubber_golem"],
		[&"rapid", &"pierce", &"area", &"rubber_golem", &"slow"],
		[&"rapid", &"pierce", &"area", &"rubber_golem", &"slow", &"execute"],
		[&"rapid", &"pierce", &"area", &"rubber_golem", &"slow", &"execute", &"mark"],
		[&"rapid", &"pierce", &"area", &"rubber_golem", &"slow", &"execute", &"mark", &"knockback"],
		[&"rapid", &"pierce", &"area", &"rubber_golem", &"slow", &"execute", &"mark", &"knockback", &"chain"],
	]
	for stage_index in unlock_stages.size():
		var allowed := unlock_stages[stage_index]
		var stage_pool := regular.filter(func(formation: TowerFormationData) -> bool: return formation.get_tower_ids().all(func(tower_id: StringName) -> bool: return tower_id in allowed))
		for size in [2, 3, 4]:
			_expect(stage_pool.filter(func(formation: TowerFormationData) -> bool: return formation.cells.size() == size).size() >= 3, "unlock stage %d must keep at least three eligible %d-cell recipes" % [stage_index, size], failures)

	var board := FormationBoardState.new(6, 4)
	var builder := FormationOfferBuilder.new()
	var context := {
		"installed_tower_ids": [&"execute"],
		"tower_levels": {&"execute": 4},
		"tower_branches": {&"execute": &"execute_armor"},
		"current_role_tags": [&"elite"],
		"discovered_tower_use_ids": [&"rapid", &"pierce", &"area", &"rubber_golem", &"execute"],
	}
	RunRng.seed_run(13049)
	var offers := builder.build(board, regular, 3, 3, context)
	var offered_ids: Dictionary = {}
	var primary_roles: Dictionary = {}
	for offer in offers:
		var formation := offer.formation as TowerFormationData
		offered_ids[formation.id] = true
		primary_roles[offer.primary_role] = true
	_expect(offers.size() == 3 and offers.map(func(offer: Dictionary) -> StringName: return offer.slot_type) == [&"build", &"expansion", &"wildcard"], "formation offers must expose ordered A/B/C purposes", failures)
	_expect(offered_ids.size() == offers.size(), "A/B/C slots must never duplicate a formation", failures)
	_expect(offers.all(func(offer: Dictionary) -> bool:
		var formation := offer.formation as TowerFormationData
		return (offer.shape_class == formation.shape_class
			and int(offer.distinct_tower_count) == formation.get_distinct_tower_count()
			and int(offer.valid_position_count) == board.valid_placements(formation).size())
	), "A/B/C metadata must carry shape, distinct-tower count, and current valid placement count", failures)
	_expect((offers[0].formation as TowerFormationData).get_tower_ids().has(&"execute"), "slot A must link to an installed and leveled tower when possible", failures)
	_expect(primary_roles.size() > 1 and offers.any(func(offer: Dictionary) -> bool: return bool(offer.discovery_bonus)), "three offers must diversify primary roles and surface discovery weighting when eligible", failures)
	var metric_probe := RunMetrics.new()
	metric_probe.record_formation_offer((offers[0].formation as TowerFormationData).id, 7, offers[0])
	var probe_formation := offers[0].formation as TowerFormationData
	metric_probe.record_formation_selection(probe_formation, 1.25, Vector2i.ZERO, false, board, offers[0])
	metric_probe.record_formation_abandon(probe_formation, 4.0, board, offers[0])
	var metric_snapshot := metric_probe.formation_metrics_snapshot()
	var metric_events: Array = metric_snapshot.get("offer_context_events", [])
	var selection_events: Array = metric_snapshot.get("selection_events", [])
	var abandon_events: Array = metric_snapshot.get("abandon_events", [])
	_expect(metric_events.size() == 1 and metric_events[0].get("slot_type", &"") == &"build" and metric_events[0].shape_class == String(probe_formation.shape_class) and int(metric_events[0].distinct_tower_count) == probe_formation.get_distinct_tower_count() and int(metric_events[0].valid_position_count) == int(offers[0].valid_position_count), "formation offer metrics must retain slot, shape, species, and eligibility diagnostics", failures)
	_expect(selection_events.size() == 1 and abandon_events.size() == 1 and selection_events[0].shape_class == String(probe_formation.shape_class) and int(selection_events[0].distinct_tower_count) == probe_formation.get_distinct_tower_count() and int(abandon_events[0].valid_position_count) == int(offers[0].valid_position_count), "formation selection and abandonment metrics must preserve the same v0.14 decision context", failures)
	metric_probe.free()

	var fully_discovered := context.duplicate(true)
	fully_discovered.discovered_tower_use_ids = DataRegistry.NORMAL_DEFENDER_IDS.duplicate()
	var clean_builder := FormationOfferBuilder.new()
	RunRng.seed_run(13049)
	var fully_discovered_offers := clean_builder.build(board, regular, 3, 3, fully_discovered)
	_expect(fully_discovered_offers.all(func(offer: Dictionary) -> bool: return not bool(offer.discovery_bonus)), "discovery weighting must end after every included tower has been installed", failures)

	var small_pool: Array[TowerFormationData] = [DataRegistry.get_formation(&"alternating"), DataRegistry.get_formation(&"bulwark"), DataRegistry.get_formation(&"mixed")]
	var history_builder := FormationOfferBuilder.new()
	RunRng.seed_run(7781)
	history_builder.build(board, small_pool, 3, 3, fully_discovered)
	var history_snapshot := history_builder.get_state_snapshot()
	RunRng.seed_run(7781)
	var repeated := history_builder.build(board, small_pool, 3, 3, fully_discovered)
	_expect(repeated.all(func(offer: Dictionary) -> bool: return bool(offer.recent_penalty)), "recently offered formations must receive a penalty on the next draw", failures)
	history_builder.reset_run_state()
	history_builder.restore_state(history_snapshot)
	_expect(history_builder.get_state_snapshot() == history_snapshot, "formation recent-offer history must round-trip through reroll state snapshots", failures)

	var discovered_backup := SaveManager.discovered_tower_use_ids.duplicate()
	SaveManager.discovered_tower_use_ids.assign(SaveManager.STARTER_TOWER_IDS)
	_expect(SaveManager.mark_tower_use_discovered([&"slow", &"rapid"], false) and "slow" in SaveManager.discovered_tower_use_ids, "the first installed advanced tower must enter persistent discovery state", failures)
	_expect(not SaveManager.mark_tower_use_discovered([&"slow"], false), "reinstalling a discovered tower must not create duplicate progress", failures)
	SaveManager.discovered_tower_use_ids.assign(discovered_backup)
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
