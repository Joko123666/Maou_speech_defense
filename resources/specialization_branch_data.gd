class_name SpecializationBranchData
extends Resource

@export var id: StringName
@export var owner_kind: StringName
@export var owner_id: StringName
@export var display_name: String
@export_multiline var level_4_description: String
@export_multiline var level_7_description: String
@export var level_4_modifiers: Dictionary = {}
@export var level_7_modifiers: Dictionary = {}
@export var impact_keys: Array[StringName] = []

func configure(
	branch_id: StringName,
	kind: StringName,
	target_id: StringName,
	title: String,
	level_4_text: String,
	level_7_text: String,
	level_4: Dictionary,
	level_7: Dictionary,
	impacts: Array[StringName]
) -> SpecializationBranchData:
	id = branch_id
	owner_kind = kind
	owner_id = target_id
	display_name = title
	level_4_description = level_4_text
	level_7_description = level_7_text
	level_4_modifiers = level_4
	level_7_modifiers = level_7
	impact_keys = impacts
	return self

func get_modifiers(finalized: bool) -> Dictionary:
	var result := level_4_modifiers.duplicate(true)
	if finalized:
		result.merge(level_7_modifiers, true)
	return result
