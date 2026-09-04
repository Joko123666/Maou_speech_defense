class_name V019M3HubCodexContractTest
extends RefCounted

const PRODUCT_PRICES := {
	&"tower_slow": 220,
	&"tower_mark": 260,
	&"tower_execute": 320,
	&"tower_knockback": 340,
	&"tower_chain": 380,
}

static func run() -> Array[String]:
	var failures: Array[String] = []
	var save_backup := SaveManager._build_save_data()
	var bypass_backup := MetaProgressionService.testing_content_lock_bypass
	MetaProgressionService.set_testing_content_lock_bypass(false)
	SaveManager.legacy_full_unlock = false
	SaveManager.discovered_shop_product_ids.clear()
	SaveManager.purchased_shop_product_ids.clear()
	SaveManager.unlocked_tower_ids.assign(SaveManager.STARTER_TOWER_IDS)

	var products := MetaProgressionService.get_shop_products()
	_expect(products.size() == 5 and products.all(func(product: ShopProductData) -> bool: return PRODUCT_PRICES.get(product.id, -1) == product.price), "M3 shop must retain all five 220/260/320/340/380 product prices", failures)
	_expect(products.all(func(product: ShopProductData) -> bool: return MetaProgressionService.get_product_state(product) == &"DISCOVERED"), "a new account must see every follow-up tower as freely purchasable without achievement discovery", failures)

	for product in products:
		SaveManager.defense_funds = 10_000
		SaveManager.purchased_shop_product_ids.clear()
		SaveManager.unlocked_tower_ids.assign(SaveManager.STARTER_TOWER_IDS)
		var before := MetaProgressionService.filter_unlocked_formations(DataRegistry.formations)
		_expect(SaveManager._apply_product_purchase_in_memory(product), "product '%s' must purchase without discovery state" % product.id, failures)
		var after := MetaProgressionService.filter_unlocked_formations(DataRegistry.formations)
		var newly_eligible := after.filter(func(formation: TowerFormationData) -> bool: return formation not in before and product.content_id in formation.get_tower_ids())
		_expect(not newly_eligible.is_empty(), "purchasing '%s' must immediately make at least one registered related formation eligible" % product.id, failures)

	var catalog := load(CodexService.RULE_CATALOG_PATH) as CodexRuleCatalogData
	_expect(catalog != null and catalog.entries.size() == 10 and catalog.get_validation_errors().is_empty(), "M3 must provide a valid ten-entry data-typed rule catalog", failures)
	if catalog != null:
		for required_id in [&"poison", &"bleed", &"shock", &"burn", &"crowd_control", &"formation_score", &"faction_prelude", &"exit_and_return"]:
			var rule := catalog.find_entry(required_id)
			_expect(rule != null and rule.icon_key != &"", "rule '%s' must expose a name, icon key, and explanation" % required_id, failures)
	var terms := CodexService.new().get_entries(&"terms")
	_expect(CodexService.CATEGORY_ORDER.size() == 6 and terms.size() == 10 and terms.all(func(entry: Dictionary) -> bool: return entry.state == &"discovered" and not (entry.stats as Array).is_empty() and String(entry.icon_key) != ""), "terms codex entries must be visible with resolver-backed rules and code-native icons", failures)
	for status_id in CommonStatusCatalog.STATUS_IDS:
		var entry := terms.filter(func(item: Dictionary) -> bool: return item.id == status_id).front() as Dictionary
		var expected_final := CommonStatusCatalog.profile_text(status_id, CommonStatusCatalog.profile_at_level(status_id, 7))
		_expect((entry.stats as Array).any(func(line: String) -> bool: return line.contains(expected_final)), "status rule '%s' must resolve its displayed final stats from CommonStatusCatalog" % status_id, failures)

	var campaign := ConceptService.get_election_campaign()
	var candidate := campaign.candidates.front() as CandidateProfileData
	var retainer := campaign.retainer(candidate.default_retainer_id)
	SaveManager.candidate_support[String(candidate.id)] = candidate.support_required_for_election
	SaveManager.elected_candidate_ids.assign([String(candidate.id)])
	SaveManager.governance_approval[String(candidate.id)] = 73
	var codex := CodexService.new()
	var candidate_entry := (codex.get_entries(&"core") as Array).filter(func(entry: Dictionary) -> bool: return entry.id == candidate.core_id).front() as Dictionary
	var candidate_stats := candidate_entry.stats as Array
	_expect(candidate_stats.any(func(line: String) -> bool: return line.contains("팩션 · ")) and candidate_stats.any(func(line: String) -> bool: return line.contains("현재 지지도 · %d / %d" % [candidate.support_required_for_election, candidate.support_required_for_election])) and candidate_stats.any(func(line: String) -> bool: return line.contains("승격 상태 · 마왕 당선")) and candidate_stats.any(func(line: String) -> bool: return line.contains("통치 지지율 · 73")), "candidate codex details must expose faction, current support, election state, and governance approval", failures)
	_expect((candidate_entry.related as Array).any(func(line: String) -> bool: return line.contains(candidate.campaign_slogan)), "candidate codex profiles must preserve the campaign slogan as dialogue-like lore", failures)
	var retainer_entry := (codex.get_entries(&"cursor") as Array).filter(func(entry: Dictionary) -> bool: return entry.id == retainer.cursor_id).front() as Dictionary
	_expect((retainer_entry.stats as Array).any(func(line: String) -> bool: return line.contains("선호 후보 · %s" % candidate.full_name) and line.contains("보너스 없음")), "retainer codex details must expose the preferred candidate as lore without implying a stat bonus", failures)
	for tower_id in DataRegistry.NORMAL_DEFENDER_IDS:
		var tower := DataRegistry.get_tower(tower_id)
		_expect(tower != null and not tower.technology_name.is_empty(), "normal defender '%s' must own a codex technology label" % tower_id, failures)
	var abyss_entry := (codex.get_entries(&"tower") as Array).filter(func(entry: Dictionary) -> bool: return entry.id == &"slow").front() as Dictionary
	_expect((abyss_entry.stats as Array).any(func(line: String) -> bool: return line.contains("출신 · 심연 연구회") and line.contains("기술 · 심연 영역 제어")), "defender codex details must resolve authoritative origin-faction and technology data", failures)

	var migrated_v13 := SaveManager._normalize_save_data({
		"meta_progression_version": 13,
		"best_time": 200.0,
		"best_level": 4,
		"total_runs": 1,
		"unlocked_ids": ["emerald", "iron"],
		"legacy_full_unlock": false,
	})
	var expected_legacy_encounters := DataRegistry.get_all_enemy_data().filter(func(enemy: EnemyData) -> bool: return enemy.available_from_seconds <= 200.0).size()
	_expect(int(migrated_v13.meta_progression_version) == 14 and (migrated_v13.encountered_enemy_ids as Array).size() == expected_legacy_encounters, "v13 saves must conservatively migrate former time-visible enemies into the v14 encounter ledger", failures)
	var fresh_v13 := SaveManager._normalize_save_data({"meta_progression_version": 13, "total_runs": 0, "best_time": 0.0, "unlocked_ids": ["emerald", "iron"], "legacy_full_unlock": false})
	_expect((fresh_v13.encountered_enemy_ids as Array).is_empty(), "a fresh v13 save must not invent enemy encounters during migration", failures)

	SaveManager.total_runs = 99
	SaveManager.best_time = 600.0
	SaveManager.encountered_enemy_ids.clear()
	var undiscovered := CodexService.new().get_entries(&"enemy")
	_expect(undiscovered.all(func(entry: Dictionary) -> bool: return entry.state == &"locked"), "best time alone must no longer reveal enemies", failures)
	_expect(SaveManager._commit_enemy_encounters([&"goblin_raider", &"goblin_raider"], false) and SaveManager.encountered_enemy_ids == ["goblin_raider"], "a batched encounter commit must persist each enemy id exactly once", failures)
	_expect(not SaveManager._mark_enemy_encounter_in_memory(&"goblin_raider"), "the encounter ledger must reject a duplicate already present in the batch", failures)
	var discovered := CodexService.new().get_entries(&"enemy")
	_expect(discovered.filter(func(entry: Dictionary) -> bool: return entry.state == &"discovered").size() == 1, "an actual encounter ledger entry must reveal exactly its matching enemy", failures)

	var controller_source := FileAccess.get_file_as_string("res://scripts/game/game_controller.gd")
	_expect(controller_source.contains("SaveManager.queue_enemy_encounter(enemy_data.id)") and controller_source.contains("not testing_mode and not _is_tutorial()"), "standard runtime enemy finalization must queue durable encounters outside the spawn call stack while isolating tests and tutorial", failures)

	SaveManager._apply_save_data(save_backup)
	MetaProgressionService.set_testing_content_lock_bypass(bypass_backup)
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
