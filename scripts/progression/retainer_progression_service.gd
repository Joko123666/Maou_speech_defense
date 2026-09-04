class_name RetainerProgressionService
extends RefCounted

var growth_data: RetainerGrowthData
var state := RetainerGrowthState.new()

func configure(data: RetainerGrowthData, legacy_state: GrowthTrackState = null) -> void:
	growth_data = data
	if data == null:
		var cursor_id := legacy_state.id if legacy_state != null else &""
		state = RetainerGrowthState.new(&"", cursor_id)
	else:
		state = RetainerGrowthState.new(data.retainer_id, data.legacy_cursor_id)
	state.import_legacy_state(legacy_state)

func is_enabled() -> bool:
	return growth_data != null and state.retainer_id != &""

func is_growth_complete() -> bool:
	return is_enabled() and state.current_level >= 7 and state.selected_branch_id != &""

func owns_specialization(specialization_id: StringName) -> bool:
	return growth_data != null and growth_data.owns_specialization(specialization_id)

func get_selected_specialization() -> SpecializationBranchData:
	if state.selected_branch_id == &"" or not owns_specialization(state.selected_branch_id):
		return null
	return DataRegistry.get_specialization_branch(state.selected_branch_id)

func get_modifiers() -> Dictionary:
	var specialization := get_selected_specialization()
	return specialization.get_modifiers(state.current_level >= 7) if specialization != null else {}

func get_snapshot() -> Dictionary:
	return state.to_retainer_snapshot()
