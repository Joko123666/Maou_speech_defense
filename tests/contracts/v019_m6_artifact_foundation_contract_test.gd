class_name V019M6ArtifactFoundationContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var catalog := load(ArtifactEffectResolver.CATALOG_PATH) as ArtifactCatalogData
	_expect(catalog != null and catalog.artifacts.size() == ArtifactCatalogData.INITIAL_CATALOG_SIZE, "M6 must define exactly 18 initial artifacts", failures)
	if catalog == null:
		return failures
	_expect(catalog.get_validation_errors().is_empty(), "M6 artifact catalog must pass schema validation: %s" % ", ".join(catalog.get_validation_errors()), failures)
	var artifact_ids: Array[StringName] = []
	var unique_ids: Dictionary = {}
	var target_groups: Dictionary = {}
	var trade_off_count := 0
	for artifact in catalog.artifacts:
		artifact_ids.append(artifact.id)
		unique_ids[artifact.id] = true
		if artifact.has_trade_off():
			trade_off_count += 1
		for effect in artifact.effects:
			target_groups[effect.target_group] = int(target_groups.get(effect.target_group, 0)) + 1
	_expect(artifact_ids.size() == 18 and unique_ids.size() == 18, "artifact ids must be stable and unique", failures)
	_expect([&"normal_defender", &"candidate", &"retainer", &"guard", &"status"].all(func(group: StringName) -> bool: return target_groups.has(group)), "the initial catalog must cover normal defenders, candidate, retainer, guard, and statuses", failures)
	_expect(trade_off_count >= 3, "the initial catalog must include several small explicit trade-off artifacts", failures)

	var invalid_effect := ArtifactEffectData.new()
	invalid_effect.target_group = &"candidate"
	invalid_effect.stat_key = &"range"
	invalid_effect.value = 0.2
	var invalid_artifact := ArtifactData.new()
	invalid_artifact.id = &"invalid_contract_artifact"
	invalid_artifact.display_name = "invalid"
	invalid_artifact.description = "invalid"
	invalid_artifact.effects = [invalid_effect]
	var eligibility := ArtifactEligibilityService.new()
	var broad_context := _context([&"rapid"], [&"control"], [&"poison", &"burn", &"bleed", &"shock"], true, true, true)
	_expect(not invalid_effect.get_validation_errors(invalid_artifact.id).is_empty() and not eligibility.is_eligible(invalid_artifact, broad_context), "invalid artifact effects must be excluded at the eligibility boundary", failures)

	var inventory := ArtifactInventoryState.new()
	for artifact_id in artifact_ids.slice(0, 6):
		_expect(inventory.equip(artifact_id), "the first six unique artifacts must occupy the six run slots", failures)
	var full_snapshot := inventory.snapshot()
	_expect(inventory.capacity == 6 and inventory.is_full() and not inventory.equip(artifact_ids[6]) and inventory.snapshot() == full_snapshot, "a seventh equip must fail without partially mutating the six-slot inventory", failures)
	_expect(not inventory.replace(-1, artifact_ids[6]) and not inventory.replace(0, artifact_ids[1]) and inventory.snapshot() == full_snapshot, "invalid or duplicate replacements must be atomic", failures)
	_expect(inventory.replace(0, artifact_ids[6]) and inventory.artifact_ids.size() == 6 and inventory.artifact_ids[0] == artifact_ids[6] and artifact_ids[0] not in inventory.artifact_ids, "a valid replacement must swap exactly one occupied slot", failures)
	_expect(inventory.remove_at(5) and inventory.artifact_ids.size() == 5, "removal must free exactly one artifact slot", failures)
	var restored := ArtifactInventoryState.new()
	restored.restore({"capacity": 99, "artifact_ids": artifact_ids + [&"unknown_artifact"]}, catalog)
	_expect(restored.capacity == 6 and restored.artifact_ids.size() == 6 and &"unknown_artifact" not in restored.artifact_ids, "snapshot restore must preserve the fixed six-slot cap and discard unknown ids", failures)
	restored.reset()
	_expect(restored.artifact_ids.is_empty(), "artifact inventory must reset completely between runs", failures)

	var effect_inventory := ArtifactInventoryState.new()
	var resolver := ArtifactEffectResolver.new(catalog, effect_inventory)
	var poison_profile := {"damage_per_second": 10.0, "max_stacks": 3}
	_expect(resolver.defense_axis_bonuses() == {&"power": 0.0, &"speed": 0.0, &"range": 0.0} and is_equal_approx(resolver.multiplier(&"candidate", &"damage"), 1.0) and resolver.apply_status_profile(&"poison", poison_profile) == poison_profile, "an empty artifact inventory must preserve the no-artifact combat baseline", failures)
	for artifact_id in [&"war_banner", &"green_gear", &"blue_lens", &"crown_shard", &"silver_spur", &"toxin_ampoule"]:
		_expect(effect_inventory.equip(artifact_id), "contract artifacts must equip into distinct slots", failures)
	var axes := resolver.defense_axis_bonuses()
	_expect(is_equal_approx(float(axes.power), 0.25) and is_equal_approx(float(axes.speed), 0.25) and is_equal_approx(float(axes.range), 24.0), "normal-defender artifacts must resolve through POWER, SPEED, and RANGE axes", failures)
	_expect(is_equal_approx(resolver.multiplier(&"candidate", &"damage"), 1.25) and is_equal_approx(resolver.multiplier(&"retainer", &"damage"), 1.25), "candidate and retainer artifacts must affect only their declared target groups", failures)
	var boosted_poison := resolver.apply_status_profile(&"poison", poison_profile)
	_expect(is_equal_approx(float(boosted_poison.damage_per_second), 14.0) and is_equal_approx(resolver.status_damage_multiplier(&"burn"), 1.0), "status artifacts must amplify their own status damage without inheriting normal POWER", failures)
	_expect(effect_inventory.replace(0, &"blood_prism"), "an equipped artifact must support atomic replacement", failures)
	axes = resolver.defense_axis_bonuses()
	_expect(is_equal_approx(float(axes.power), 0.35) and is_equal_approx(float(axes.range), 4.0), "replacement must immediately remove the old effect and apply the new trade-off", failures)

	var no_status := _context([&"rapid"], [], [], true, true, true)
	_expect(not eligibility.is_eligible(catalog.find_artifact(&"toxin_ampoule"), no_status), "a poison artifact must be excluded when the run has no poison application source", failures)
	var poison_context := no_status.duplicate(true)
	poison_context.status_source_ids = [&"poison"]
	_expect(eligibility.is_eligible(catalog.find_artifact(&"toxin_ampoule"), poison_context), "a status artifact must become eligible when its exact application source exists", failures)
	_expect(not eligibility.is_eligible(catalog.find_artifact(&"control_compass"), no_status), "a role artifact must be excluded without its required role", failures)
	var control_context := no_status.duplicate(true)
	control_context.role_tags = [&"control"]
	_expect(eligibility.is_eligible(catalog.find_artifact(&"control_compass"), control_context), "a role artifact must become eligible with its required role", failures)
	var missing_retainer := no_status.duplicate(true)
	missing_retainer.retainer_available = false
	_expect(not eligibility.is_eligible(catalog.find_artifact(&"twin_mandate"), missing_retainer) and eligibility.is_eligible(catalog.find_artifact(&"war_banner"), no_status), "cross-target artifacts must require every target while inefficient but valid general artifacts remain eligible", failures)
	var duplicate_context := no_status.duplicate(true)
	duplicate_context.equipped_artifact_ids = [&"war_banner"]
	_expect(not eligibility.is_eligible(catalog.find_artifact(&"war_banner"), duplicate_context), "already equipped artifacts must not be eligible twice", failures)

	var loadout := LoadoutManager.new()
	loadout.global_upgrade_level = 99
	_expect(is_equal_approx(loadout.get_tower_damage_multiplier(), 1.0) and is_equal_approx(float(loadout.get_defense_axis_bonuses().power), 0.0), "legacy global-upgrade result fields must not change the no-artifact runtime baseline", failures)
	_expect(not loadout.apply_upgrade(UpgradeData.new().configure(&"global_upgrade", "legacy", "legacy", &"global")), "forged legacy global-upgrade choices must be rejected", failures)
	loadout.artifact_inventory.equip(&"royal_whetstone")
	loadout.artifact_inventory.equip(&"watchtower_sigil")
	_expect(is_equal_approx(loadout.get_guard_damage_multiplier(), 1.30) and is_equal_approx(loadout.get_guard_range_multiplier(), 1.20), "guard artifacts must reach the existing guard combat resolver boundary", failures)
	var battlefield := Battlefield.new()
	var container := Node2D.new()
	loadout.setup(battlefield, container)
	_expect(loadout.get_artifact_snapshot().artifact_ids.is_empty() and loadout.global_upgrade_level == 0, "starting a new run must clear artifacts and legacy global levels", failures)
	loadout.free()
	battlefield.free()
	container.free()

	var offer_source := FileAccess.get_file_as_string("res://scripts/progression/upgrade_offer_service.gd")
	var application_source := FileAccess.get_file_as_string("res://scripts/progression/loadout_upgrade_application_service.gd")
	_expect(not offer_source.contains("func _global_choice") and not offer_source.contains("global_choice_provider") and not application_source.contains("&\"global_upgrade\","), "runtime offer and application services must no longer create or support global-upgrade cards", failures)
	return failures

static func _context(
	installed_tower_ids: Array[StringName],
	role_tags: Array[StringName],
	status_source_ids: Array[StringName],
	candidate_available: bool,
	retainer_available: bool,
	guard_available: bool
) -> Dictionary:
	return {
		"installed_tower_ids": installed_tower_ids,
		"role_tags": role_tags,
		"status_source_ids": status_source_ids,
		"candidate_available": candidate_available,
		"retainer_available": retainer_available,
		"guard_available": guard_available,
		"equipped_artifact_ids": [],
	}

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
