class_name CandidateUpgradeData
extends Resource

const KIND_FIXED := &"fixed"
const KIND_BRANCH := &"branch"

@export var id: StringName = &""
@export var kind: StringName = KIND_FIXED
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var modifiers: Dictionary = {}

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("candidate upgrade id is empty")
	if kind not in [KIND_FIXED, KIND_BRANCH]: errors.append("candidate upgrade '%s' has unsupported kind '%s'" % [id, kind])
	if display_name.is_empty(): errors.append("candidate upgrade '%s' has no display name" % id)
	if description.is_empty(): errors.append("candidate upgrade '%s' has no description" % id)
	return errors
