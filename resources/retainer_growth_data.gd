class_name RetainerGrowthData
extends Resource

@export var retainer_id: StringName = &""
@export var legacy_cursor_id: StringName = &""
@export_multiline var level_2_description: String = ""
@export_multiline var level_3_description: String = ""
@export_multiline var level_5_description: String = ""
@export_multiline var level_6_description: String = ""
@export var specialization_ids: Array[StringName] = []

func description_for_level(level: int) -> String:
	match level:
		2: return level_2_description
		3: return level_3_description
		5: return level_5_description
		6: return level_6_description
		7: return "선택한 심복 특화의 완성 효과가 적용됩니다."
	return ""

func owns_specialization(specialization_id: StringName) -> bool:
	return specialization_id in specialization_ids

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if retainer_id == &"": errors.append("retainer growth has no retainer id")
	if legacy_cursor_id == &"": errors.append("retainer growth '%s' has no legacy cursor id" % retainer_id)
	if level_2_description.is_empty(): errors.append("retainer growth '%s' has no level 2 description" % retainer_id)
	if level_3_description.is_empty(): errors.append("retainer growth '%s' has no level 3 description" % retainer_id)
	if level_5_description.is_empty(): errors.append("retainer growth '%s' has no level 5 description" % retainer_id)
	if level_6_description.is_empty(): errors.append("retainer growth '%s' has no level 6 description" % retainer_id)
	if specialization_ids.size() != 3:
		errors.append("retainer growth '%s' must expose exactly three specializations" % retainer_id)
	var unique_ids: Dictionary = {}
	for specialization_id in specialization_ids:
		if specialization_id == &"":
			errors.append("retainer growth '%s' contains an empty specialization id" % retainer_id)
		elif unique_ids.has(specialization_id):
			errors.append("retainer growth '%s' repeats specialization '%s'" % [retainer_id, specialization_id])
		unique_ids[specialization_id] = true
	return errors
