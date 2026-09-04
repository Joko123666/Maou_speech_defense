class_name V013MigrationContractTest
extends RefCounted

const STARTER_IDS: Array[StringName] = [&"rapid", &"pierce", &"area", &"rubber_golem"]
const INITIAL_FORMATION_IDS: Array[StringName] = [
	&"guidance", &"barrage", &"arrow_barrage", &"duo",
	&"alternating", &"bulwark", &"mixed", &"precision",
	&"balanced", &"orc_mixed", &"standard_demon_army", &"compressed_bombardment",
]

static func run() -> Array[String]:
	var failures: Array[String] = []
	_expect(SaveManager.CURRENT_META_PROGRESSION_VERSION == 14, "the current save schema must preserve v0.13 formation discovery through version 14", failures)
	_expect(SaveManager.STARTER_TOWER_IDS == ["rapid", "pierce", "area", "rubber_golem"], "new saves must start with exactly G/O/S/R", failures)
	_expect(MetaProgressionService.STARTER_TOWER_IDS == STARTER_IDS, "runtime progression must share the exact G/O/S/R starter contract", failures)
	_expect(MetaProgressionService.config.enforce_content_locks, "release content locks must be active by default", failures)

	var repeatable := DataRegistry.formations.filter(func(formation: TowerFormationData) -> bool: return not formation.is_unique())
	_expect(DataRegistry.formations.size() == 55 and repeatable.size() == 49, "v0.13 must expose 49 repeatable recipes, five guards, and one hidden reinforcement", failures)
	var size_counts := {2: 0, 3: 0, 4: 0}
	for formation_id in INITIAL_FORMATION_IDS:
		var formation := DataRegistry.get_formation(formation_id)
		_expect(formation != null, "initial formation '%s' must exist" % formation_id, failures)
		if formation == null:
			continue
		size_counts[formation.cells.size()] = int(size_counts.get(formation.cells.size(), 0)) + 1
		_expect(formation.get_tower_ids().all(func(tower_id: StringName) -> bool: return tower_id in STARTER_IDS), "initial formation '%s' must use only G/O/S/R" % formation_id, failures)
		_expect(formation.get_shape_errors().is_empty(), "initial formation '%s' must remain normalized and connected" % formation_id, failures)
	_expect(size_counts == {2: 4, 3: 4, 4: 4}, "initial formations must provide four recipes at each 2/3/4-cell size", failures)

	var migrated_v9 := SaveManager._normalize_save_data({
		"meta_progression_version": 9,
		"unlocked_tower_ids": ["rapid", "pierce", "area", "knockback"],
		"legacy_full_unlock": false,
	})
	_expect(int(migrated_v9.meta_progression_version) == 14 and "knockback" in migrated_v9.unlocked_tower_ids and "rubber_golem" in migrated_v9.unlocked_tower_ids and "knockback" in migrated_v9.discovered_tower_use_ids, "v9 migration must preserve KI-II, add the rubber starter, and seed prior usage discovery", failures)

	var save_backup := SaveManager._build_save_data()
	var bypass_backup := MetaProgressionService.testing_content_lock_bypass
	SaveManager.legacy_full_unlock = false
	SaveManager.unlocked_tower_ids.assign(SaveManager.STARTER_TOWER_IDS)
	MetaProgressionService.set_testing_content_lock_bypass(false)
	_expect(not MetaProgressionService.is_tower_unlocked(&"knockback"), "KI-II must be locked on a new release save", failures)
	_expect(INITIAL_FORMATION_IDS.all(func(formation_id: StringName) -> bool: return MetaProgressionService.is_formation_unlocked(DataRegistry.get_formation(formation_id))), "all 12 G/O/S/R recipes must be available on a new save", failures)
	MetaProgressionService.set_testing_content_lock_bypass(true)
	_expect(MetaProgressionService.is_tower_unlocked(&"knockback"), "the explicit testing bypass must grant locked content to automated fixtures", failures)
	SaveManager._apply_save_data(save_backup)
	MetaProgressionService.set_testing_content_lock_bypass(bypass_backup)

	var knockback_product := MetaProgressionService.get_shop_product(&"tower_knockback")
	_expect(knockback_product != null and knockback_product.content_id == &"knockback" and knockback_product.discovery_achievement_id == &"discover_tower_knockback", "KI-II must have an achievement-discovered shop unlock", failures)
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
