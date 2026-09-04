class_name AchievementData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var category: StringName
@export var hidden: bool = false
@export var metric_id: StringName
@export var target_value: float = 1.0
@export var comparison: StringName = &"greater_or_equal"
@export var progress_mode: StringName = &"cumulative"
@export var required_product_ids: Array[StringName] = []
@export var required_any_product_ids: Array[StringName] = []
@export var required_feature_ids: Array[StringName] = []
@export var reward_funds: int = 0
@export var discover_product_ids: Array[StringName] = []
@export var unlock_feature_ids: Array[StringName] = []
@export var unlock_content_ids: Array[StringName] = []

func configure(
	achievement_id: StringName,
	title: String,
	detail: String,
	group: StringName,
	metric: StringName,
	target: float,
	mode: StringName = &"cumulative"
) -> AchievementData:
	id = achievement_id
	display_name = title
	description = detail
	category = group
	metric_id = metric
	target_value = target
	progress_mode = mode
	return self
