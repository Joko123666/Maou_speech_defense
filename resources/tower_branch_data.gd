class_name TowerBranchData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var tower_id: StringName
@export var branch_type: StringName
@export var weight: float = 1.0
@export var level_4_modifiers: Dictionary = {}
@export var level_7_modifiers: Dictionary = {}
@export var required_tags: Array[StringName] = []
@export var forbidden_tags: Array[StringName] = []

func configure(branch_id: StringName, title: String, detail: String, target_tower: StringName, role: StringName, level_4: Dictionary, level_7: Dictionary) -> TowerBranchData:
	id = branch_id
	display_name = title
	description = detail
	tower_id = target_tower
	branch_type = role
	level_4_modifiers = level_4
	level_7_modifiers = level_7
	return self
