class_name V014FormationCatalogContractTest
extends RefCounted

const EXPECTED_REGULAR_IDS: Array[StringName] = [
	&"balanced", &"orc_mixed", &"standard_demon_army", &"compressed_bombardment",
	&"guidance", &"barrage", &"arrow_barrage", &"duo",
	&"alternating", &"bulwark", &"mixed", &"precision",
	&"cryo_net", &"abyss_shooting", &"abyss_firepower", &"abyss_vanguard",
	&"abyss_compressed_bombardment", &"abyss_standard", &"spear_observer",
	&"long_range_fireteam", &"recoil_hunt", &"slowed_snipers", &"grenadier_snipers",
	&"rear_fireline", &"execution", &"vulnerable_breakthrough",
	&"vulnerable_bombardment", &"elite_hunt", &"charm_compression",
	&"weakpoint_blockade", &"elite_execution", &"vulnerable_bombardment_line",
	&"ki2_field_team", &"bleeding_defense", &"violent_mission", &"saw_compression",
	&"forced_labor", &"violent_conversion", &"death_rotation", &"compressed_mission",
	&"cascade", &"conduction_sniper", &"conduction_compression", &"conduction_blockade",
	&"conduction_amplification", &"conduction_concentration", &"abyss_power_grid",
	&"conduction_fire_grid", &"overload_mission_grid",
]

const INITIAL_IDS: Array[StringName] = [
	&"guidance", &"barrage", &"arrow_barrage", &"duo",
	&"alternating", &"bulwark", &"mixed", &"precision",
	&"balanced", &"orc_mixed", &"standard_demon_army", &"compressed_bombardment",
]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var regular := DataRegistry.formations.filter(func(formation: TowerFormationData) -> bool: return not formation.is_unique())
	var actual_ids: Array[StringName] = []
	actual_ids.assign(regular.map(func(formation: TowerFormationData) -> StringName: return formation.id))
	actual_ids.sort()
	var expected_ids := EXPECTED_REGULAR_IDS.duplicate()
	expected_ids.sort()
	_expect(actual_ids == expected_ids, "v0.14 must preserve all 49 stable regular formation IDs", failures)

	var size_counts := {2: 0, 3: 0, 4: 0}
	var species_counts := {1: 0, 2: 0, 3: 0, 4: 0}
	var shape_counts := {
		TowerFormationData.SHAPE_LONG: 0,
		TowerFormationData.SHAPE_BEND: 0,
		TowerFormationData.SHAPE_COMPACT: 0,
		TowerFormationData.SHAPE_STEP: 0,
	}
	var size_shape_counts := {
		2: {TowerFormationData.SHAPE_LONG: 0},
		3: {TowerFormationData.SHAPE_LONG: 0, TowerFormationData.SHAPE_BEND: 0},
		4: {
			TowerFormationData.SHAPE_LONG: 0,
			TowerFormationData.SHAPE_BEND: 0,
			TowerFormationData.SHAPE_COMPACT: 0,
			TowerFormationData.SHAPE_STEP: 0,
		},
	}
	for formation in regular:
		var cell_count: int = formation.cells.size()
		var species_count: int = formation.get_distinct_tower_count()
		size_counts[cell_count] = int(size_counts.get(cell_count, 0)) + 1
		species_counts[species_count] = int(species_counts.get(species_count, 0)) + 1
		shape_counts[formation.shape_class] = int(shape_counts.get(formation.shape_class, 0)) + 1
		var by_size := size_shape_counts.get(cell_count, {}) as Dictionary
		by_size[formation.shape_class] = int(by_size.get(formation.shape_class, 0)) + 1
		size_shape_counts[cell_count] = by_size
		_expect(formation.get_shape_errors().is_empty(), "formation '%s' must satisfy its declared v0.14 layout contract" % formation.id, failures)
		_expect(formation.placement_difficulty in [0, 1, 2], "formation '%s' must declare placement difficulty 0 to 2" % formation.id, failures)
		_expect(formation.get_shape_display_name() != "미지정" and formation.get_placement_difficulty_display_name() != "미지정", "formation '%s' must expose concise localized shape and difficulty labels" % formation.id, failures)
		_expect(formation.can_vertical_flip, "regular formation '%s' must retain vertical flip support" % formation.id, failures)
	_expect(size_counts == {2: 15, 3: 17, 4: 17}, "v0.14 must preserve the reviewed 15/17/17 size distribution", failures)
	_expect(species_counts == {1: 11, 2: 26, 3: 12, 4: 0}, "v0.14 distinct-tower distribution must be exactly 11/26/12/0", failures)
	_expect(shape_counts == {
		TowerFormationData.SHAPE_LONG: 27,
		TowerFormationData.SHAPE_BEND: 14,
		TowerFormationData.SHAPE_COMPACT: 4,
		TowerFormationData.SHAPE_STEP: 4,
	}, "v0.14 shape distribution must be exactly LONG/BEND/COMPACT/STEP 27/14/4/4", failures)
	_expect(size_shape_counts == {
		2: {TowerFormationData.SHAPE_LONG: 15},
		3: {TowerFormationData.SHAPE_LONG: 7, TowerFormationData.SHAPE_BEND: 10},
		4: {
			TowerFormationData.SHAPE_LONG: 5,
			TowerFormationData.SHAPE_BEND: 4,
			TowerFormationData.SHAPE_COMPACT: 4,
			TowerFormationData.SHAPE_STEP: 4,
		},
	}, "v0.14 shapes must meet the executable size-by-shape distribution", failures)

	var starter_ids: Array[StringName] = [&"rapid", &"pierce", &"area", &"rubber_golem"]
	var initial_shape_counts := {
		2: {TowerFormationData.SHAPE_LONG: 0},
		3: {TowerFormationData.SHAPE_LONG: 0, TowerFormationData.SHAPE_BEND: 0},
		4: {
			TowerFormationData.SHAPE_LONG: 0,
			TowerFormationData.SHAPE_BEND: 0,
			TowerFormationData.SHAPE_COMPACT: 0,
			TowerFormationData.SHAPE_STEP: 0,
		},
	}
	var initial_species: Dictionary = {}
	for formation_id in INITIAL_IDS:
		var formation := DataRegistry.get_formation(formation_id)
		_expect(formation != null, "initial formation '%s' must exist" % formation_id, failures)
		if formation == null:
			continue
		_expect(formation.get_tower_ids().all(func(tower_id: StringName) -> bool: return tower_id in starter_ids), "initial formation '%s' must use only G/O/S/R" % formation.id, failures)
		var by_size := initial_shape_counts[formation.cells.size()] as Dictionary
		by_size[formation.shape_class] = int(by_size.get(formation.shape_class, 0)) + 1
		initial_shape_counts[formation.cells.size()] = by_size
		initial_species[formation.get_distinct_tower_count()] = true
	_expect(initial_shape_counts == {
		2: {TowerFormationData.SHAPE_LONG: 4},
		3: {TowerFormationData.SHAPE_LONG: 2, TowerFormationData.SHAPE_BEND: 2},
		4: {
			TowerFormationData.SHAPE_LONG: 1,
			TowerFormationData.SHAPE_BEND: 1,
			TowerFormationData.SHAPE_COMPACT: 1,
			TowerFormationData.SHAPE_STEP: 1,
		},
	}, "the initial 12 formations must teach every executable size and shape family", failures)
	_expect(initial_species.has(1) and initial_species.has(2) and initial_species.has(3) and not initial_species.has(4), "the initial 12 formations must teach one-, two-, and three-species recipes without four-species mixing", failures)

	var inferred_line := TowerFormationData.new().configure_cells(
		&"inferred_line", "inferred", "", [
			FormationCellData.new().configure(Vector2i(0, 0), &"rapid"),
			FormationCellData.new().configure(Vector2i(1, 0), &"rapid"),
		]
	)
	_expect(inferred_line.shape_class == TowerFormationData.SHAPE_LONG and inferred_line.placement_difficulty == 0, "programmatic formations must infer safe v0.14 metadata when omitted", failures)
	inferred_line.shape_class = TowerFormationData.SHAPE_STEP
	_expect("\n".join(inferred_line.get_shape_errors()).contains("do not match shape class"), "formation validation must reject metadata that contradicts occupied coordinates", failures)
	_expect(not TowerFormationData.new().get_property_list().any(func(property: Dictionary) -> bool: return String(property.name).contains("rotate")), "v0.14 must not introduce a 90-degree rotation field", failures)
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
