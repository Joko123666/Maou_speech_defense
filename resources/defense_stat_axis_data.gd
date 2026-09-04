class_name DefenseStatAxisData
extends Resource

@export var id: StringName
@export var display_name: String
@export var icon_key: StringName
@export var color: Color = Color.WHITE

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id not in [&"power", &"speed", &"range"]:
		errors.append("unknown defense stat axis '%s'" % id)
	if display_name.strip_edges().is_empty():
		errors.append("defense stat axis '%s' has no display name" % id)
	if icon_key == &"":
		errors.append("defense stat axis '%s' has no icon key" % id)
	return errors
