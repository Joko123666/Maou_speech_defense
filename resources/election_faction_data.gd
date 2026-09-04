class_name ElectionFactionData
extends Resource

const ACTIVE_MARKER_STYLES: Array[StringName] = [&"sword_shield", &"heart", &"tentacle_eye", &"skull_aura", &"scythe_blood"]
const LEGACY_MARKER_ALIASES := {
	&"crown": &"sword_shield",
	&"star": &"heart",
	&"abyss": &"tentacle_eye",
	&"spirit": &"skull_aura",
	&"judgment": &"scythe_blood",
}
const MARKER_STYLES: Array[StringName] = ACTIVE_MARKER_STYLES + [&"crown", &"star", &"abyss", &"spirit", &"judgment"]
const MARKER_LABELS := {
	&"sword_shield": "검방패",
	&"heart": "하트",
	&"tentacle_eye": "촉수눈",
	&"skull_aura": "해골오라",
	&"scythe_blood": "낫과 피",
}

@export var id: StringName = &""
@export var candidate_id: StringName = &""
@export var display_name: String = ""
@export var primary_color: Color = Color.WHITE
@export var secondary_color: Color = Color.GRAY
@export var accent_color: Color = Color.WHITE
@export var emblem_id: StringName = &""
@export var marker_style: StringName = &""
@export var supporter_enemy_ids: Array[StringName] = []
@export var elite_enemy_ids: Array[StringName] = []
@export var boss_ids: Array[StringName] = []
@export var replacement_boss_ids: Array[StringName] = []

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("faction id is empty")
	if candidate_id == &"": errors.append("faction '%s' has no candidate id" % id)
	if display_name.is_empty(): errors.append("faction '%s' has no display name" % id)
	if emblem_id == &"": errors.append("faction '%s' has no emblem id" % id)
	if marker_style not in MARKER_STYLES: errors.append("faction '%s' has unsupported marker style '%s'" % [id, marker_style])
	if supporter_enemy_ids.is_empty(): errors.append("faction '%s' has no supporter enemy ids" % id)
	if boss_ids.is_empty(): errors.append("faction '%s' has no boss ids" % id)
	return errors

func active_marker_style() -> StringName:
	return normalized_marker_style(marker_style)

func marker_display_name() -> String:
	return String(MARKER_LABELS.get(active_marker_style(), "진영 표식"))

static func normalized_marker_style(style: StringName) -> StringName:
	return LEGACY_MARKER_ALIASES.get(style, style) as StringName
