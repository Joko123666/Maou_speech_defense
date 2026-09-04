class_name GovernanceReactionData
extends Resource

@export var id: StringName = &""
@export_range(0, 100, 1) var minimum_approval: int = 0
@export_range(0, 100, 1) var maximum_approval: int = 19
@export var display_name: String = ""
@export var color: Color = Color.WHITE
@export_range(1, 5, 1) var audience_strength: int = 1
@export var battle_chant: String = ""
@export var victory_line: String = ""
@export var defeat_line: String = ""
@export var result_pose: String = ""

func contains(approval: int) -> bool:
	return approval >= minimum_approval and approval <= maximum_approval

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("governance reaction id is empty")
	if minimum_approval > maximum_approval: errors.append("governance reaction '%s' has an inverted range" % id)
	if display_name.is_empty(): errors.append("governance reaction '%s' has no display name" % id)
	if battle_chant.is_empty(): errors.append("governance reaction '%s' has no battle chant" % id)
	if victory_line.is_empty(): errors.append("governance reaction '%s' has no victory line" % id)
	if defeat_line.is_empty(): errors.append("governance reaction '%s' has no defeat line" % id)
	if result_pose.is_empty(): errors.append("governance reaction '%s' has no result pose" % id)
	if color.a <= 0.0: errors.append("governance reaction '%s' has an invisible color" % id)
	return errors
