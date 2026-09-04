class_name OvergrowthCatalogData
extends Resource

const REQUIRED_OPTION_IDS: Array[StringName] = [
	&"candidate_damage", &"candidate_skill",
	&"retainer_damage", &"retainer_action_speed", &"retainer_movement", &"retainer_collection",
]

@export var options: Array[OvergrowthOptionData] = []

func find_option(option_id: StringName) -> OvergrowthOptionData:
	for option in options:
		if option != null and option.id == option_id:
			return option
	return null

func options_for_group(target_group: StringName) -> Array[OvergrowthOptionData]:
	var result: Array[OvergrowthOptionData] = []
	for option in options:
		if option != null and option.target_group == target_group:
			result.append(option)
	return result

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids: Dictionary = {}
	for option in options:
		if option == null:
			errors.append("overgrowth catalog contains a null option")
			continue
		if ids.has(option.id): errors.append("duplicate overgrowth option '%s'" % option.id)
		ids[option.id] = true
		errors.append_array(option.get_validation_errors())
	for required_id in REQUIRED_OPTION_IDS:
		if not ids.has(required_id): errors.append("missing overgrowth option '%s'" % required_id)
	return errors
