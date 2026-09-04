class_name RetainerGrowthState
extends GrowthTrackState

var retainer_id: StringName = &""
var legacy_cursor_id: StringName = &""

func _init(profile_id: StringName = &"", cursor_id: StringName = &"") -> void:
	retainer_id = profile_id
	legacy_cursor_id = cursor_id
	id = cursor_id

func import_legacy_state(legacy_state: GrowthTrackState) -> void:
	if legacy_state == null:
		return
	if legacy_cursor_id == &"":
		legacy_cursor_id = legacy_state.id
	id = legacy_cursor_id
	current_level = clampi(legacy_state.current_level, 1, max_level)
	selected_branch_id = legacy_state.selected_branch_id

func to_retainer_snapshot() -> Dictionary:
	return {
		"retainer_id": String(retainer_id),
		"legacy_cursor_id": String(legacy_cursor_id),
		"current_level": current_level,
		"selected_specialization_id": String(selected_branch_id),
	}
