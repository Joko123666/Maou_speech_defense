class_name GuardSpecializationData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var modifiers: Dictionary = {}
@export_multiline var completion_description: String = ""
@export var completion_modifiers: Dictionary = {}

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("guard specialization id is empty")
	if display_name.is_empty(): errors.append("guard specialization '%s' has no display name" % id)
	if description.is_empty(): errors.append("guard specialization '%s' has no description" % id)
	if modifiers.is_empty(): errors.append("guard specialization '%s' has no modifiers" % id)
	if completion_description.is_empty(): errors.append("guard specialization '%s' has no completion description" % id)
	if completion_modifiers.is_empty(): errors.append("guard specialization '%s' has no completion modifiers" % id)
	return errors
