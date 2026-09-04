class_name UpgradeData
extends Resource

@export var category: StringName
@export var display_name: String
@export_multiline var description: String
@export var data_id: StringName
@export var requires_placement: bool = false
var placement_confirmed: bool = false
var vertical_flip: bool = false
var board_anchor: Vector2i = Vector2i(-1, -1)
var placement_id: StringName = &""
var offer_metadata: Dictionary = {}

func configure(upgrade_category: StringName, title: String, detail: String, target_id: StringName) -> UpgradeData:
	category = upgrade_category
	display_name = title
	description = detail
	data_id = target_id
	requires_placement = category == &"new_formation"
	return self
