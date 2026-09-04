class_name GrowthTrackState
extends RefCounted

var id: StringName
var current_level: int = 1
var max_level: int = 7
var selected_branch_id: StringName = &""

func _init(track_id: StringName = &"") -> void:
	id = track_id

func can_level_up() -> bool:
	return current_level < max_level

func requires_branch_choice() -> bool:
	return current_level == 3 and selected_branch_id == &""

func reaches_final_upgrade() -> bool:
	return current_level == 6
