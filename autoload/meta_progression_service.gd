extends Node

const STARTER_TOWER_IDS: Array[StringName] = [&"rapid", &"pierce", &"area", &"rubber_golem"]
const STARTER_FEATURE_IDS: Array[StringName] = [&"base_combat", &"formation_system", &"specialization_system"]
const CONFIG_PATH := "res://data/meta/meta_progression_config.tres"
const STANDARD_REWARD_PATH := "res://data/meta/stage_rewards/standard_20m.tres"

var config: MetaProgressionConfig
var stage_rewards: Dictionary = {}
var shop_products: Array[ShopProductData] = []
var achievements: Array[AchievementData] = []
var achievement_service: AchievementService
var testing_content_lock_bypass := false
var codex_service: CodexService

func _ready() -> void:
	config = load(CONFIG_PATH) as MetaProgressionConfig
	if config == null:
		config = MetaProgressionConfig.new()
	_register_stage_reward(load(STANDARD_REWARD_PATH) as StageRewardData)
	_register_stage_reward(ConceptService.get_stage_reward())
	shop_products = MetaCatalogFactory.build_products()
	achievements = MetaCatalogFactory.build_achievements()
	achievement_service = AchievementService.new(achievements)
	codex_service = CodexService.new()

func _register_stage_reward(data: StageRewardData) -> void:
	if data != null and data.stage_id != &"":
		stage_rewards[data.stage_id] = data

func is_lock_bypassed() -> bool:
	return testing_content_lock_bypass or not config.enforce_content_locks or (Engine.is_editor_hint() and config.grant_all_content_in_editor) or SaveManager.legacy_full_unlock

func set_testing_content_lock_bypass(enabled: bool) -> void:
	testing_content_lock_bypass = enabled

func is_tower_unlocked(tower_id: StringName) -> bool:
	if is_lock_bypassed() or String(tower_id) in SaveManager.unlocked_tower_ids:
		return true
	var tower := DataRegistry.get_tower(tower_id)
	return tower != null and tower.is_unique() and is_core_unlocked(tower.unique_core_id)

func is_feature_unlocked(feature_id: StringName) -> bool:
	return is_lock_bypassed() or String(feature_id) in SaveManager.unlocked_feature_ids

func is_core_unlocked(core_id: StringName) -> bool:
	return is_lock_bypassed() or String(core_id) in SaveManager.unlocked_ids

func is_cursor_unlocked(cursor_id: StringName) -> bool:
	return is_lock_bypassed() or String(cursor_id) in SaveManager.unlocked_ids

func is_formation_unlocked(formation: TowerFormationData) -> bool:
	if formation == null:
		return false
	if &"reinforcement" in formation.role_tags:
		return false
	if is_lock_bypassed():
		return true
	if formation.is_unique() and not is_core_unlocked(formation.unique_core_id):
		return false
	for tower_id in formation.get_tower_ids():
		if tower_id != &"" and not is_tower_unlocked(tower_id):
			return false
	return true

func filter_unlocked_formations(formations: Array[TowerFormationData]) -> Array[TowerFormationData]:
	var result: Array[TowerFormationData] = []
	for formation in formations:
		if is_formation_unlocked(formation):
			result.append(formation)
	return result

func get_stage_reward_data(stage_id: StringName) -> StageRewardData:
	return stage_rewards.get(stage_id) as StageRewardData

func get_shop_products() -> Array[ShopProductData]:
	return shop_products.duplicate()

func get_shop_product(product_id: StringName) -> ShopProductData:
	for product in shop_products:
		if product.id == product_id:
			return product
	return null

func get_achievements() -> Array[AchievementData]:
	return achievements.duplicate()

func get_achievement(achievement_id: StringName) -> AchievementData:
	for achievement in achievements:
		if achievement.id == achievement_id:
			return achievement
	return null

func get_achievement_state(achievement: AchievementData) -> Dictionary:
	return achievement_service.get_state(achievement)

func get_codex_categories() -> Array[Dictionary]:
	return codex_service.get_categories()

func get_codex_entries(category: StringName) -> Array[Dictionary]:
	return codex_service.get_entries(category)

func get_candidate_decree(decree_id: StringName) -> CandidateDecreeData:
	var campaign := ConceptService.get_election_campaign()
	return campaign.decree(decree_id) if campaign != null else null

func get_candidate_decrees(candidate_id: StringName) -> Array[CandidateDecreeData]:
	var campaign := ConceptService.get_election_campaign()
	return campaign.decrees_for_candidate(candidate_id) if campaign != null else []

func ensure_candidate_decree(candidate_id: StringName) -> StringName:
	var campaign := ConceptService.get_election_campaign()
	var candidate := campaign.candidate(candidate_id) if campaign != null else null
	if candidate == null or not SaveManager.is_candidate_elected(candidate_id):
		return &""
	var selected_id := SaveManager.get_candidate_decree(candidate_id)
	if selected_id in candidate.decree_ids and campaign.decree(selected_id) != null:
		return selected_id
	if candidate.decree_ids.is_empty():
		return &""
	var default_id := candidate.decree_ids[0]
	return default_id if SaveManager.select_candidate_decree(candidate_id, default_id, candidate.decree_ids) else &""

func select_candidate_decree(candidate_id: StringName, decree_id: StringName) -> bool:
	var campaign := ConceptService.get_election_campaign()
	var candidate := campaign.candidate(candidate_id) if campaign != null else null
	if candidate == null or campaign.decree(decree_id) == null:
		return false
	return SaveManager.select_candidate_decree(candidate_id, decree_id, candidate.decree_ids)

func get_product_state(product: ShopProductData) -> StringName:
	if product == null:
		return &"HIDDEN"
	var product_id := String(product.id)
	if product_id in SaveManager.purchased_shop_product_ids:
		return &"PURCHASED"
	return &"DISCOVERED"

func purchase_product(product_id: StringName) -> Dictionary:
	var product := get_shop_product(product_id)
	if product == null:
		return {"purchased": false, "reason": "존재하지 않는 상품입니다."}
	var id := String(product.id)
	if id in SaveManager.purchased_shop_product_ids:
		return {"purchased": false, "reason": "이미 구매한 상품입니다."}
	if SaveManager.defense_funds < product.price:
		return {"purchased": false, "reason": "%s이 %d 부족합니다." % [ConceptService.term(&"currency"), product.price - SaveManager.defense_funds]}
	var committed := SaveManager.commit_product_purchase(product)
	return {
		"purchased": committed,
		"reason": "구매했습니다." if committed else "저장에 실패해 구매를 취소했습니다.",
		"balance": SaveManager.defense_funds,
		"product_id": id,
	}

func calculate_run_rewards(result: Dictionary) -> Dictionary:
	var stage_id := StringName(result.get("stage_id", ""))
	var reward_data := get_stage_reward_data(stage_id)
	if reward_data == null:
		return StageRewardCalculator.calculate(result, null)
	var stage_reward_id := "stage:%s" % String(stage_id)
	var challenge_reward_id := "challenge:%s:%d" % [String(stage_id), ChallengeRules.clamp_level(int(result.get("challenge_level", 0)))]
	return StageRewardCalculator.calculate(
		result,
		reward_data,
		stage_reward_id in SaveManager.stage_first_clear_reward_ids,
		challenge_reward_id in SaveManager.challenge_first_clear_reward_ids
	)

func calculate_candidate_progression(result: Dictionary) -> Dictionary:
	var progression := CandidateSupportCalculator.calculate(result)
	var candidate_id := String(progression.get("candidate_id", ""))
	if candidate_id.is_empty():
		return progression
	var required := int(progression.get("support_required", 0))
	if required <= 0:
		var campaign := ConceptService.get_election_campaign()
		var candidate := campaign.candidate(StringName(candidate_id)) if campaign != null else null
		required = candidate.support_required_for_election if candidate != null else 0
	progression["support_required"] = required
	var before := SaveManager.get_candidate_support(StringName(candidate_id))
	var already_elected := SaveManager.is_candidate_elected(StringName(candidate_id))
	var calculated := maxi(int(progression.get("total_support", 0)), 0)
	var awarded := 0 if already_elected else calculated
	if required > 0:
		awarded = mini(awarded, maxi(required - before, 0))
	var after := before + awarded
	progression["calculated_support"] = calculated
	progression["total_support"] = awarded
	progression["support_before"] = before
	progression["support_after"] = after
	progression["already_elected"] = already_elected
	progression["newly_elected"] = not already_elected and required > 0 and after >= required
	var available_decrees_value: Variant = result.get("candidate_decree_ids_available", [])
	if available_decrees_value is Array and not available_decrees_value.is_empty():
		progression["default_decree_id"] = String(available_decrees_value[0])
	return progression

func calculate_governance_progression(result: Dictionary) -> Dictionary:
	var candidate_id := StringName(result.get("candidate_id", ""))
	if candidate_id == &"":
		return GovernanceApprovalCalculator.empty_breakdown()
	var approval_before := SaveManager.get_governance_approval(candidate_id)
	# 이번 정산에서 처음 당선되는 런은 50으로 초기화만 하고 다음 출격부터
	# 통치 성과를 계산한다. 결과가 기록한 출격 시작 시점의 당선 상태가 권위다.
	if not SaveManager.is_candidate_elected(candidate_id) or not bool(result.get("candidate_elected", false)):
		return GovernanceApprovalCalculator.empty_breakdown(String(candidate_id), approval_before)
	return GovernanceApprovalCalculator.calculate(result, approval_before)

func settle_run(result: Dictionary) -> Dictionary:
	var run_id := String(result.get("run_id", ""))
	if run_id.is_empty() or SaveManager.has_settled_run(run_id):
		return {
			"awarded": false,
			"duplicate": not run_id.is_empty(),
			"breakdown": StageRewardCalculator._empty_breakdown(),
			"balance": SaveManager.defense_funds,
		}
	var breakdown := calculate_run_rewards(result)
	breakdown["candidate_progression"] = calculate_candidate_progression(result)
	breakdown["governance_progression"] = calculate_governance_progression(result)
	var achievement_actions := achievement_service.evaluate(result.get("meta_metrics", {}))
	breakdown["achievement_actions"] = achievement_actions
	breakdown["achievement_funds"] = int(achievement_actions.get("reward_funds", 0))
	breakdown["total_funds"] = int(breakdown.get("total_funds", 0)) + int(breakdown.achievement_funds)
	var committed := SaveManager.commit_run_settlement(result, breakdown)
	return {
		"awarded": committed,
		"duplicate": false,
		"breakdown": breakdown if committed else StageRewardCalculator._empty_breakdown(),
		"achievement_actions": achievement_actions if committed else {},
		"balance": SaveManager.defense_funds,
	}
