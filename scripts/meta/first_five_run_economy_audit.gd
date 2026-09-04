class_name FirstFiveRunEconomyAudit
extends RefCounted

const SCHEMA_VERSION := 2
const STANDARD_REWARD_PATH := "res://data/meta/stage_rewards/standard_20m.tres"
const STARTER_TOWER_IDS: Array[String] = ["rapid", "pierce", "area", "rubber_golem"]
const TARGET_FIRST_PURCHASE_RUN := 3
const TARGET_FULL_UNLOCK_RUN := 8
const PROJECTION_LIMIT := 12

static func run_default() -> Dictionary:
	return simulate(
		_default_run_profiles(),
		load(STANDARD_REWARD_PATH) as StageRewardData,
		MetaCatalogFactory.build_products(),
		MetaCatalogFactory.build_achievements()
	)

static func simulate(
	profiles: Array[Dictionary],
	reward_data: StageRewardData,
	products: Array[ShopProductData],
	achievements: Array[AchievementData]
) -> Dictionary:
	if reward_data == null or profiles.is_empty():
		return _empty_report()

	var funds := 0
	var achievement_progress: Dictionary = {}
	var completed_achievement_ids: Array[String] = []
	var discovered_product_ids: Array[String] = []
	for product in products:
		discovered_product_ids.append(String(product.id))
	var purchased_product_ids: Array[String] = []
	var unlocked_tower_ids := STARTER_TOWER_IDS.duplicate()
	var unlocked_feature_ids: Array[String] = ["base_combat", "formation_system", "specialization_system"]
	var stage_first_clear_claimed := false
	var challenge_first_clear_claimed: Dictionary = {}
	var run_rows: Array[Dictionary] = []
	var projection_rows: Array[Dictionary] = []
	var first_defeat_reward := 0
	var first_discovery_run := 0
	var first_purchase_run := 0

	for profile in profiles:
		var run_number := run_rows.size() + 1
		var settlement := _settle_run(
			profile,
			run_number,
			reward_data,
			products,
			achievements,
			funds,
			stage_first_clear_claimed,
			challenge_first_clear_claimed,
			achievement_progress,
			completed_achievement_ids,
			discovered_product_ids,
			purchased_product_ids,
			unlocked_tower_ids,
			unlocked_feature_ids
		)
		funds = int(settlement.funds_after)
		stage_first_clear_claimed = bool(settlement.stage_first_clear_claimed)
		challenge_first_clear_claimed = settlement.challenge_first_clear_claimed
		run_rows.append(settlement.row)
		if first_defeat_reward == 0 and not bool(profile.get("victory", false)):
			first_defeat_reward = int(settlement.row.reward_funds)
		if first_discovery_run == 0 and not (settlement.row.newly_discovered as Array).is_empty():
			first_discovery_run = run_number
		if first_purchase_run == 0 and not (settlement.row.purchased as Array).is_empty():
			first_purchase_run = run_number

	var discovered_after_five := discovered_product_ids.size()
	var purchased_after_five := purchased_product_ids.size()
	var unlocked_after_five := unlocked_tower_ids.size()
	var projected_full_unlock_run := profiles.size() if purchased_product_ids.size() == products.size() else 0
	var repeat_profile: Dictionary = profiles.back().duplicate(true)
	repeat_profile["victory"] = true
	repeat_profile["elapsed"] = reward_data.stage_duration_seconds
	repeat_profile["stage_duration_seconds"] = reward_data.stage_duration_seconds

	while projected_full_unlock_run == 0 and run_rows.size() + projection_rows.size() < PROJECTION_LIMIT:
		var run_number := run_rows.size() + projection_rows.size() + 1
		var settlement := _settle_run(
			repeat_profile,
			run_number,
			reward_data,
			products,
			achievements,
			funds,
			stage_first_clear_claimed,
			challenge_first_clear_claimed,
			achievement_progress,
			completed_achievement_ids,
			discovered_product_ids,
			purchased_product_ids,
			unlocked_tower_ids,
			unlocked_feature_ids
		)
		funds = int(settlement.funds_after)
		stage_first_clear_claimed = bool(settlement.stage_first_clear_claimed)
		challenge_first_clear_claimed = settlement.challenge_first_clear_claimed
		projection_rows.append(settlement.row)
		if purchased_product_ids.size() == products.size():
			projected_full_unlock_run = run_number

	var all_products_available := discovered_after_five == products.size()
	var quality_gate_passed := (
		first_defeat_reward > 0
		and first_purchase_run > 0
		and first_purchase_run <= TARGET_FIRST_PURCHASE_RUN
		and all_products_available
		and projected_full_unlock_run > 0
		and projected_full_unlock_run <= TARGET_FULL_UNLOCK_RUN
	)
	return {
		"schema_version": SCHEMA_VERSION,
		"quality_gate_passed": quality_gate_passed,
		"profile_name": "representative_new_account_v019",
		"purchase_policy": "all_products_available_lowest_price_first_after_each_run",
		"starter_tower_count": STARTER_TOWER_IDS.size(),
		"shop_product_count": products.size(),
		"total_tower_count": STARTER_TOWER_IDS.size() + products.size(),
		"total_shop_price": products.reduce(func(total: int, product: ShopProductData) -> int: return total + product.price, 0),
		"first_defeat_reward": first_defeat_reward,
		"first_discovery_run": first_discovery_run,
		"first_purchase_run": first_purchase_run,
		"discovered_after_five": discovered_after_five,
		"purchased_after_five": purchased_after_five,
		"unlocked_towers_after_five": unlocked_after_five,
		"projected_full_unlock_run": projected_full_unlock_run,
		"ending_funds": funds,
		"targets": {
			"first_purchase_by_run": TARGET_FIRST_PURCHASE_RUN,
			"all_products_available_from_run": 0,
			"full_unlock_by_run": TARGET_FULL_UNLOCK_RUN,
		},
		"runs": run_rows,
		"projection": projection_rows,
	}

static func _settle_run(
	profile: Dictionary,
	run_number: int,
	reward_data: StageRewardData,
	products: Array[ShopProductData],
	achievements: Array[AchievementData],
	funds_before: int,
	stage_first_clear_claimed: bool,
	challenge_first_clear_claimed: Dictionary,
	achievement_progress: Dictionary,
	completed_achievement_ids: Array[String],
	discovered_product_ids: Array[String],
	purchased_product_ids: Array[String],
	unlocked_tower_ids: Array[String],
	unlocked_feature_ids: Array[String]
) -> Dictionary:
	var challenge_level := ChallengeRules.clamp_level(int(profile.get("challenge_level", 0)))
	var challenge_claimed := bool(challenge_first_clear_claimed.get(challenge_level, false))
	var reward := StageRewardCalculator.calculate(profile, reward_data, stage_first_clear_claimed, challenge_claimed)
	var achievement_actions := _evaluate_achievements(
		profile.get("meta_metrics", {}),
		achievements,
		achievement_progress,
		completed_achievement_ids,
		purchased_product_ids,
		unlocked_feature_ids
	)
	var achievement_funds := int(achievement_actions.reward_funds)
	var reward_funds := maxi(int(reward.get("total_funds", 0)), 0) + achievement_funds
	var funds_available := funds_before + reward_funds
	var achievement_discoveries := achievement_actions.discovered_product_ids as Array[String]
	var newly_discovered: Array[String] = []
	for product_id in achievement_discoveries:
		if product_id not in discovered_product_ids:
			newly_discovered.append(product_id)
	_append_unique_values(discovered_product_ids, newly_discovered)
	var purchases := _purchase_affordable(products, discovered_product_ids, purchased_product_ids, unlocked_tower_ids, unlocked_feature_ids, funds_available)
	var spent := int(purchases.spent)
	var funds_after := funds_available - spent
	var stage_claimed_after := stage_first_clear_claimed or not String(reward.get("stage_first_reward_id", "")).is_empty()
	var challenge_claimed_after := challenge_first_clear_claimed.duplicate(true)
	if not String(reward.get("challenge_first_reward_id", "")).is_empty():
		challenge_claimed_after[challenge_level] = true
	return {
		"funds_after": funds_after,
		"stage_first_clear_claimed": stage_claimed_after,
		"challenge_first_clear_claimed": challenge_claimed_after,
		"row": {
			"run": run_number,
			"victory": bool(profile.get("victory", false)),
			"elapsed": float(profile.get("elapsed", 0.0)),
			"reward_funds": reward_funds,
			"achievement_funds": achievement_funds,
			"funds_before": funds_before,
			"funds_available": funds_available,
			"newly_discovered": newly_discovered,
			"purchased": purchases.product_ids,
			"spent": spent,
			"funds_after": funds_after,
			"discovered_count": discovered_product_ids.size(),
			"purchased_count": purchased_product_ids.size(),
			"unlocked_tower_count": unlocked_tower_ids.size(),
		},
	}

static func _evaluate_achievements(
	metrics_value: Variant,
	achievements: Array[AchievementData],
	progress: Dictionary,
	completed_ids: Array[String],
	purchased_product_ids: Array[String],
	unlocked_feature_ids: Array[String]
) -> Dictionary:
	var discovered: Array[String] = []
	var reward_funds := 0
	var metrics: Dictionary = metrics_value if metrics_value is Dictionary else {}
	for achievement in achievements:
		var id := String(achievement.id)
		if id in completed_ids or not _requirements_met(achievement, purchased_product_ids, unlocked_feature_ids):
			continue
		var run_value := float(metrics.get(String(achievement.metric_id), 0.0))
		var previous := float(progress.get(id, 0.0))
		var next := run_value
		match achievement.progress_mode:
			&"maximum", &"single_run": next = maxf(previous, run_value)
			&"replace": next = run_value
			_: next = previous + run_value
		progress[id] = next
		if not _comparison_met(next, achievement.target_value, achievement.comparison):
			continue
		completed_ids.append(id)
		reward_funds += maxi(achievement.reward_funds, 0)
		for feature_id in achievement.unlock_feature_ids:
			var feature_name := String(feature_id)
			if not feature_name.is_empty() and feature_name not in unlocked_feature_ids:
				unlocked_feature_ids.append(feature_name)
		for product_id in achievement.discover_product_ids:
			var product_name := String(product_id)
			if not product_name.is_empty() and product_name not in discovered:
				discovered.append(product_name)
	return {"discovered_product_ids": discovered, "reward_funds": reward_funds}

static func _requirements_met(achievement: AchievementData, purchased_product_ids: Array[String], unlocked_feature_ids: Array[String]) -> bool:
	for product_id in achievement.required_product_ids:
		if String(product_id) not in purchased_product_ids:
			return false
	if not achievement.required_any_product_ids.is_empty():
		var any_met := achievement.required_any_product_ids.any(
			func(product_id: StringName) -> bool: return String(product_id) in purchased_product_ids
		)
		if not any_met:
			return false
	for feature_id in achievement.required_feature_ids:
		if String(feature_id) not in unlocked_feature_ids:
			return false
	return true

static func _comparison_met(progress: float, target: float, comparison: StringName) -> bool:
	match comparison:
		&"less_or_equal": return progress <= target
		&"equal": return is_equal_approx(progress, target)
	return progress >= target

static func _purchase_affordable(
	products: Array[ShopProductData],
	discovered_product_ids: Array[String],
	purchased_product_ids: Array[String],
	unlocked_tower_ids: Array[String],
	unlocked_feature_ids: Array[String],
	funds_available: int
) -> Dictionary:
	var ordered := products.duplicate()
	ordered.sort_custom(func(a: ShopProductData, b: ShopProductData) -> bool:
		return a.price < b.price if a.price != b.price else String(a.id) < String(b.id)
	)
	var spent := 0
	var purchased: Array[String] = []
	for product in ordered:
		var product_id := String(product.id)
		if product_id in purchased_product_ids:
			continue
		if funds_available - spent < product.price:
			continue
		spent += product.price
		purchased_product_ids.append(product_id)
		purchased.append(product_id)
		if product.product_type == &"tower":
			var tower_id := String(product.content_id)
			if not tower_id.is_empty() and tower_id not in unlocked_tower_ids:
				unlocked_tower_ids.append(tower_id)
		for feature_id in product.granted_feature_ids:
			var feature_name := String(feature_id)
			if not feature_name.is_empty() and feature_name not in unlocked_feature_ids:
				unlocked_feature_ids.append(feature_name)
		if "codex_system" not in unlocked_feature_ids:
			unlocked_feature_ids.append("codex_system")
	return {"spent": spent, "product_ids": purchased}

static func _append_unique_values(target: Array[String], values: Array[String]) -> void:
	for value in values:
		if not value.is_empty() and value not in target:
			target.append(value)

static func _default_run_profiles() -> Array[Dictionary]:
	return [
		_profile(180.0, false, [&"boss_5"], 2500.0, 15.0, 0.0, 0.0),
		_profile(300.0, false, [&"boss_5", &"boss_10"], 3500.0, 20.0, 1.0, 1.0),
		_profile(420.0, false, [&"boss_5", &"boss_10"], 4500.0, 25.0, 1.0, 1.0),
		_profile(510.0, false, [&"boss_5", &"boss_10", &"boss_15"], 6000.0, 30.0, 1.0, 1.0),
		_profile(600.0, true, [&"boss_5", &"boss_10", &"boss_15", &"final_boss"], 8000.0, 30.0, 2.0, 1.0),
	]

static func _profile(
	elapsed: float,
	victory: bool,
	boss_ids: Array[StringName],
	boss_damage: float,
	elite_kills: float,
	burst_windows: float,
	slow_discovery: float
) -> Dictionary:
	return {
		"stage_id": "standard_20m",
		"stage_duration_seconds": 600.0,
		"elapsed": elapsed,
		"victory": victory,
		"challenge_level": 0,
		"eligible_for_meta_rewards": true,
		"boss_kill_ids": boss_ids,
		"meta_metrics": {
			"runs": 1.0,
			"run.victory": 1.0 if victory else 0.0,
			"run.starter_tower_types": 4.0,
			"run.slow_discovery": slow_discovery,
			"boss_damage": boss_damage,
			"elite_kills": elite_kills,
			"burst_10_kill_windows": burst_windows,
		},
	}

static func _empty_report() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"quality_gate_passed": false,
		"error": "reward data and at least one run profile are required",
		"runs": [],
		"projection": [],
	}
