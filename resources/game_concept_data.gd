class_name GameConceptData
extends Resource

@export_group("Identity")
@export var id: StringName = &"formation_defense"
@export var project_title: String = "FORMATION DEFENSE"
@export var project_eyebrow: String = "CORE NETWORK / FORMATION COMMAND"
@export var chapter_title: String = "SECTOR 01 · DEFENSE PROTOCOL"
@export_multiline var hero_title: String = "핵을 지키고\n편대를 완성하라"
@export_multiline var hero_description: String = "네 개의 전선을 감시하고 여섯 개의 열을 설계하세요.\n레벨업마다 편대와 강화를 선택해 10분을 방어합니다."
@export var ready_status: String = "●  방어 프로토콜 대기 중"

@export_group("Terminology")
@export var core_term: String = "핵"
@export var cursor_term: String = "목표지점"
@export var tower_term: String = "타워"
@export var formation_term: String = "편대"
@export var enemy_term: String = "적"
@export var boss_term: String = "보스"
@export var currency_term: String = "방위 자금"
@export var stage_term: String = "스테이지"

@export_group("Palette")
@export var accent_color: Color = Color("59dbae")
@export var secondary_color: Color = Color("69bce8")
@export var danger_color: Color = Color("ff6575")
@export var background_tint: Color = Color(0.72, 0.82, 0.90, 1.0)
@export var background_overlay: Color = Color(0.01, 0.035, 0.055, 0.28)
@export var battlefield_fill: Color = Color("172a3a", 0.32)

@export_group("Assets")
@export var assets: GameAssetCatalogData

@export_group("Text")
@export var text_catalog: GameTextCatalogData

@export_group("Stage")
@export var default_stage: StageData
@export var stage_reward: StageRewardData

@export_group("Optional content replacement")
@export var content_pack: ContentPackData

@export_group("Optional campaign overlay")
@export var election_campaign: ElectionCampaignData

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("concept profile id is empty")
	if assets == null:
		errors.append("concept profile has no asset catalog")
	else:
		for asset_error in assets.get_validation_errors():
			errors.append("assets: %s" % asset_error)
	if text_catalog == null:
		errors.append("concept profile has no text catalog")
	else:
		for text_error in text_catalog.get_validation_errors():
			errors.append("text: %s" % text_error)
	if default_stage == null:
		errors.append("concept profile has no default stage")
	if stage_reward == null:
		errors.append("concept profile has no stage reward table")
	if default_stage != null and stage_reward != null:
		if default_stage.id != stage_reward.stage_id:
			errors.append("stage reward id '%s' does not match default stage '%s'" % [stage_reward.stage_id, default_stage.id])
		if not is_equal_approx(default_stage.duration_seconds, stage_reward.stage_duration_seconds):
			errors.append("stage reward duration %.2f does not match default stage duration %.2f" % [stage_reward.stage_duration_seconds, default_stage.duration_seconds])
	if content_pack != null:
		errors.append_array(content_pack.get_validation_errors(default_stage, stage_reward))
	if content_pack != null and content_pack.election_campaign != null and election_campaign != null:
		errors.append("concept profile defines an election campaign both directly and through its content pack")
	elif election_campaign != null:
		for campaign_error in election_campaign.get_validation_errors():
			errors.append("campaign: %s" % campaign_error)
	return errors

func is_playable() -> bool:
	return get_validation_errors().is_empty()

func term(key: StringName) -> String:
	return {
		&"core": core_term,
		&"cursor": cursor_term,
		&"tower": tower_term,
		&"formation": formation_term,
		&"enemy": enemy_term,
		&"boss": boss_term,
		&"currency": currency_term,
		&"stage": stage_term,
	}.get(key, String(key))

func campaign() -> ElectionCampaignData:
	if content_pack != null and content_pack.election_campaign != null:
		return content_pack.election_campaign
	return election_campaign
