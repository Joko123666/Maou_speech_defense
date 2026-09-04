class_name V019M4DefenseStatContractTest
extends RefCounted

static func run(root: Node) -> Array[String]:
	var failures: Array[String] = []
	var catalog := load(DefenseStatResolver.CATALOG_PATH) as DefenseStatCatalogData
	_expect(catalog != null and catalog.axes.size() == 3 and catalog.mappings.size() == 27, "M4 must define exactly three axes and all 9×3 normal-defender mappings", failures)
	if catalog == null:
		return failures
	_expect(catalog.get_validation_errors().is_empty(), "M4 defense stat catalog must pass schema validation: %s" % ", ".join(catalog.get_validation_errors()), failures)
	for tower_id in DefenseStatCatalogData.REQUIRED_TOWER_IDS:
		for axis_id in DefenseStatCatalogData.REQUIRED_AXIS_IDS:
			var mapping := catalog.find_mapping(tower_id, axis_id)
			_expect(mapping != null and not mapping.display_name.is_empty() and not mapping.modifier_keys.is_empty() and mapping.cap > 0.0, "mapping '%s:%s' must expose a display name, actual modifier keys, mode, and cap" % [tower_id, axis_id], failures)
			if mapping != null:
				_expect(mapping.applies_to_guard and mapping.allowed_target_kinds == [&"normal_defender"], "mapping '%s:%s' must share with guards while excluding candidates, retainers, and summons" % [tower_id, axis_id], failures)

	var resolver := DefenseStatResolver.new(catalog)
	_expect(is_equal_approx(resolver.resolve_value(&"rapid", &"power", &"damage", 100.0, 0.2), 120.0), "POWER must multiply a declared direct-damage value", failures)
	_expect(is_equal_approx(resolver.resolve_value(&"slow", &"power", &"slow_strength", 0.3, 0.2), 0.36), "POWER must relatively multiply slow strength instead of adding percentage points", failures)
	for status_key in [&"poison_damage", &"bleed_damage", &"shock_damage", &"burn_damage"]:
		_expect(is_equal_approx(resolver.resolve_value(&"rapid", &"power", status_key, 100.0, 0.5), 100.0), "POWER must not directly amplify common status key '%s'" % status_key, failures)
	_expect(is_equal_approx(resolver.resolve_interval(&"execute", 2.0, 0.25), 1.6), "SPEED must shorten a declared action/reload interval", failures)
	_expect(is_equal_approx(resolver.resolve_value(&"rubber_golem", &"speed", &"movement_speed", 100.0, 0.5), 100.0), "SPEED must never resolve into defender movement speed", failures)
	_expect(is_equal_approx(resolver.resolve_primary(&"rapid", &"range", 120.0, 24.0), 144.0), "RANGE must add a fixed spatial value", failures)
	_expect(is_equal_approx(resolver.resolve_primary(&"rapid", &"range", 120.0, 999.0), 216.0), "RANGE fixed bonuses must obey the mapping cap", failures)
	for excluded_kind in [&"candidate", &"retainer", &"summon"]:
		_expect(is_equal_approx(resolver.resolve_value(&"rapid", &"power", &"damage", 100.0, 0.5, excluded_kind), 100.0), "normal-defender axes must not leak into '%s'" % excluded_kind, failures)
	_expect(is_equal_approx(resolver.resolve_value(&"rapid", &"power", &"damage", 100.0, 0.2, &"normal_defender", true), 120.0), "normal defender mappings must remain active when the same unit is used as a guard", failures)

	var battlefield := Battlefield.new()
	root.add_child(battlefield)
	battlefield.set_process(false)
	var column := TowerColumn.new()
	root.add_child(column)
	column.set_process(false)
	column.set_physics_process(false)
	column.setup(0, 0.0, battlefield)
	column.row_towers.clear()
	column.row_towers.append(DataRegistry.get_tower(&"rapid"))
	column.row_towers.resize(battlefield.lane_count)
	column.set_defense_stat_context(resolver, {&"power": 0.0, &"speed": 0.0, &"range": 0.0})
	var base_damage := column.get_damage(0)
	var base_interval := column.get_attack_interval(0)
	var base_range := column.get_attack_range(0)
	column.set_defense_stat_context(resolver, {&"power": 0.2, &"speed": 0.25, &"range": 24.0})
	_expect(is_equal_approx(column.get_damage(0), base_damage * 1.2), "TowerColumn combat damage must use the POWER resolver", failures)
	_expect(is_equal_approx(column.get_attack_interval(0), base_interval / 1.25), "TowerColumn action cadence must use the SPEED resolver", failures)
	_expect(is_equal_approx(column.get_attack_range(0), base_range + 24.0), "TowerColumn spatial reach must use the fixed RANGE resolver", failures)

	column.row_towers.clear()
	column.row_towers.append(DataRegistry.get_tower(&"chain"))
	column.row_towers.resize(battlefield.lane_count)
	column.set_shared_progress({&"chain": 1}, {})
	column.set_defense_stat_context(resolver, {&"power": 0.0, &"speed": 0.0, &"range": 0.0})
	var base_chain_attack_range := column.get_attack_range(0)
	var base_chain_link_range := column.get_chain_link_range(0)
	column.set_defense_stat_context(resolver, {&"power": 0.0, &"speed": 0.0, &"range": 24.0})
	_expect(is_equal_approx(column.get_attack_range(0), base_chain_attack_range), "chain RANGE must not leak into its battlefield-wide first-target acquisition range", failures)
	_expect(is_equal_approx(column.get_chain_link_range(0), base_chain_link_range + 24.0), "chain RANGE must increase the declared link_range spatial contract", failures)

	column.row_towers.clear()
	column.row_towers.append(DataRegistry.get_tower(&"rubber_golem"))
	column.row_towers.resize(battlefield.lane_count)
	column.set_defense_stat_context(resolver, {&"power": 0.0, &"speed": 0.5, &"range": 0.0})
	column.set_mobile_tower_offset(0, Vector2.ZERO)
	var first_step := column.advance_golem_toward(0, column.get_base_attack_origin(0) + Vector2.RIGHT * 300.0)
	column.set_mobile_tower_offset(0, Vector2.ZERO)
	column.set_defense_stat_context(resolver, {&"power": 0.0, &"speed": 0.0, &"range": 0.0})
	var control_step := column.advance_golem_toward(0, column.get_base_attack_origin(0) + Vector2.RIGHT * 300.0)
	_expect(first_step.distance_to(control_step) <= 0.001, "SPEED must not change rubber golem battlefield movement distance", failures)

	var tower_entry := (CodexService.new().get_entries(&"tower") as Array).filter(func(entry: Dictionary) -> bool: return entry.id == &"rapid").front() as Dictionary
	_expect((tower_entry.stat_axes as Array).size() == 3, "tower codex details must expose the red/green/blue axis presentations", failures)
	var level_choice := UpgradeData.new().configure(&"tower_type_level", "고블린 창병 전체 Lv.2", "병종 능력축", &"rapid")
	var card_impacts := UpgradePresentationService.new().choice_impacts(level_choice)
	_expect(card_impacts.size() == 3 and card_impacts.map(func(impact: Dictionary) -> String: return String(impact.label)) == ["위력", "속도", "범위"], "tower upgrade cards must show three named, uniquely colored/iconized axes", failures)
	var description_loadout := LoadoutManager.new()
	var description := description_loadout._tower_level_description(&"rapid", 2)
	description_loadout.free()
	_expect(description.contains("🔴 위력·기본 공격 피해") and description.contains("🟢 속도·공격속도") and description.contains("🔵 범위·공격 사거리"), "tower upgrade details must state each axis and its unit-specific mapping", failures)

	column.free()
	battlefield.free()
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
