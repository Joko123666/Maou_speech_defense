class_name OvergrowthOptionData
extends Resource

const TARGET_GROUPS: Array[StringName] = [&"candidate", &"retainer"]

@export var id: StringName
@export var target_group: StringName
@export var display_name: String
@export_multiline var description: String
@export var stat_key: StringName
@export_range(0.001, 0.10, 0.001) var bonus_per_stack: float = 0.03
@export_range(0.01, 10.0, 0.01) var offer_weight: float = 1.0
@export var icon_key: StringName = &"global"
@export var color: Color = Color("ffe16b")

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("overgrowth option id is empty")
	if target_group not in TARGET_GROUPS: errors.append("overgrowth option '%s' has invalid target group '%s'" % [id, target_group])
	if display_name.strip_edges().is_empty(): errors.append("overgrowth option '%s' has no display name" % id)
	if description.strip_edges().is_empty(): errors.append("overgrowth option '%s' has no description" % id)
	if stat_key == &"": errors.append("overgrowth option '%s' has no stat key" % id)
	if bonus_per_stack <= 0.0: errors.append("overgrowth option '%s' has a non-positive bonus" % id)
	if offer_weight <= 0.0: errors.append("overgrowth option '%s' has a non-positive offer weight" % id)
	return errors
