class_name CodexRuleEntryData
extends Resource

@export var id: StringName
@export var display_name: String
@export var subtitle: String
@export_multiline var description: String
@export var icon_key: StringName = &"default"
@export var accent_color: Color = Color("65d9bd")
@export var resolver_id: StringName
@export var stat_lines: Array[String] = []
@export var related_lines: Array[String] = []

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("codex rule id is empty")
	if display_name.strip_edges().is_empty(): errors.append("codex rule '%s' has no display name" % id)
	if description.strip_edges().is_empty(): errors.append("codex rule '%s' has no description" % id)
	if icon_key == &"": errors.append("codex rule '%s' has no icon key" % id)
	if resolver_id == &"" and stat_lines.is_empty(): errors.append("codex rule '%s' has no resolver or stat lines" % id)
	return errors
