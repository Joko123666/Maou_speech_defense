class_name GuardGrowthData
extends Resource

@export var candidate_id: StringName = &""
@export var formation_id: StringName = &""
@export var training_display_name: String = "친위대 훈련"
@export_multiline var training_description: String = ""
@export var training_modifiers: Dictionary = {}
@export var specializations: Array[GuardSpecializationData] = []

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if candidate_id == &"": errors.append("guard growth candidate id is empty")
	if formation_id == &"": errors.append("guard growth for '%s' has no formation id" % candidate_id)
	if training_display_name.is_empty(): errors.append("guard growth for '%s' has no training name" % candidate_id)
	if training_description.is_empty(): errors.append("guard growth for '%s' has no training description" % candidate_id)
	if training_modifiers.is_empty(): errors.append("guard growth for '%s' has no training modifiers" % candidate_id)
	if specializations.size() != 3: errors.append("guard growth for '%s' requires exactly three specializations" % candidate_id)
	var unique_ids: Dictionary = {}
	for specialization in specializations:
		if specialization == null:
			errors.append("guard growth for '%s' contains a null specialization" % candidate_id)
			continue
		errors.append_array(specialization.get_validation_errors())
		if unique_ids.has(specialization.id):
			errors.append("guard growth for '%s' contains duplicate specialization '%s'" % [candidate_id, specialization.id])
		unique_ids[specialization.id] = true
	return errors
