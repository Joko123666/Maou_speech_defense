class_name ArtifactOfferService
extends RefCounted

# 약 24~32회의 일반 레벨업에서 평균 1.3~1.8회 제안을 만드는 시작값이다.
const FAMILY_CHANCE := 0.055
var mode: StringName = GameSession.ARTIFACT_MODE_NORMAL

func inject(choices: Array[UpgradeData], eligible_artifacts: Array[ArtifactData], protect_required_formation: bool, fill_target_count: int = 0) -> bool:
	if mode == GameSession.ARTIFACT_MODE_DISABLED or eligible_artifacts.is_empty() or choices.any(func(choice: UpgradeData) -> bool: return choice.category == &"artifact"):
		return false
	var can_append := fill_target_count > 0 and choices.size() < fill_target_count
	if choices.is_empty() and not can_append:
		return false
	var replace_indexes := replaceable_indexes(choices, protect_required_formation)
	if not can_append and replace_indexes.is_empty():
		return false
	var occurrence_roll := 0.0 if mode == GameSession.ARTIFACT_MODE_FORCED else RunRng.progression_roll()
	if not should_offer(eligible_artifacts.size(), occurrence_roll, mode):
		return false
	# 계열 출현 판정 뒤에만 실제 아티팩트와 교체 슬롯 RNG를 소비한다.
	var artifact := RunRng.progression_pick(eligible_artifacts) as ArtifactData
	if can_append:
		choices.append(build_choice(artifact))
		return true
	var replace_index := int(RunRng.progression_pick(replace_indexes))
	choices[replace_index] = build_choice(artifact)
	return true

static func should_offer(eligible_count: int, roll: float, artifact_mode: StringName = GameSession.ARTIFACT_MODE_NORMAL) -> bool:
	if eligible_count <= 0 or artifact_mode == GameSession.ARTIFACT_MODE_DISABLED:
		return false
	return artifact_mode == GameSession.ARTIFACT_MODE_FORCED or clampf(roll, 0.0, 1.0) < FAMILY_CHANCE

static func expected_offer_count(level_up_count: int) -> float:
	return maxi(level_up_count, 0) * FAMILY_CHANCE

static func replaceable_indexes(choices: Array[UpgradeData], protect_required_formation: bool) -> Array[int]:
	var result: Array[int] = []
	for index in choices.size():
		var category := choices[index].category
		if category in [&"artifact", &"guard_training", &"guard_specialization_entry", &"guard_completion"]:
			continue
		if String(category).ends_with("_specialization_entry"):
			continue
		if category in [&"core_level", &"cursor_level"]:
			continue
		if protect_required_formation and bool(choices[index].offer_metadata.get(&"required_initial_formation", false)):
			continue
		result.append(index)
	return result

static func build_choice(artifact: ArtifactData) -> UpgradeData:
	if artifact == null:
		return null
	var choice := UpgradeData.new().configure(&"artifact", artifact.display_name, artifact.description, artifact.id)
	var target_groups: Array[String] = []
	var effects: Array[Dictionary] = []
	for effect in artifact.effects:
		if effect == null:
			continue
		var target_group := String(effect.target_group)
		if target_group not in target_groups:
			target_groups.append(target_group)
		effects.append({
			"target_group": target_group,
			"stat_key": String(effect.stat_key),
			"axis_id": String(effect.axis_id),
			"status_id": String(effect.status_id),
			"value_mode": String(effect.value_mode),
			"value": effect.value,
		})
	choice.offer_metadata = {
		"artifact": true,
		"target_groups": target_groups,
		"effects": effects,
		"trade_off": artifact.has_trade_off(),
		"icon": String(artifact.icon_key),
		"color": artifact.color.to_html(),
	}
	return choice

static func build_draft(eligible_artifacts: Array[ArtifactData], target_count: int = 3) -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	var pool: Array[ArtifactData] = []
	var seen_ids: Dictionary = {}
	for artifact in eligible_artifacts:
		if artifact == null or seen_ids.has(artifact.id):
			continue
		seen_ids[artifact.id] = true
		pool.append(artifact)
	while not pool.is_empty() and result.size() < maxi(target_count, 0):
		var artifact := RunRng.progression_pick(pool) as ArtifactData
		pool.erase(artifact)
		var choice := build_choice(artifact)
		if choice != null:
			choice.offer_metadata[&"source"] = &"artifact_elite"
			result.append(choice)
	return result
