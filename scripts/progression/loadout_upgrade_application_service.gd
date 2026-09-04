class_name LoadoutUpgradeApplicationService
extends RefCounted

const SUPPORTED_CATEGORIES: Array[StringName] = [
	&"tower_type_level", &"tower_branch",
	&"core_level", &"core_branch", &"cursor_level", &"cursor_branch",
	&"guard_training", &"guard_branch", &"guard_completion",
	&"status_upgrade",
]

func apply(choice: UpgradeData, state: Dictionary, candidate_growth_enabled: bool) -> Dictionary:
	var result := {
		"handled": choice != null and choice.category in SUPPORTED_CATEGORIES,
		"applied": false,
		"global_upgrade_level": int(state.get("global_upgrade_level", 0)),
	}
	if not bool(result.handled):
		return result
	match choice.category:
		&"tower_type_level":
			result.applied = _level_tower(choice.data_id, state)
		&"tower_branch":
			result.applied = _select_tower_branch(choice.data_id, state)
		&"core_level":
			result.applied = false if candidate_growth_enabled else _level_track(state.get("core_state") as GrowthTrackState, false)
		&"core_branch":
			result.applied = false if candidate_growth_enabled else _select_track_branch(state.get("core_state") as GrowthTrackState, choice.data_id, false)
		&"cursor_level":
			result.applied = _level_track(state.get("cursor_state") as GrowthTrackState, true)
		&"cursor_branch":
			result.applied = _select_track_branch(state.get("cursor_state") as GrowthTrackState, choice.data_id, true)
		&"guard_training", &"guard_branch", &"guard_completion":
			result.applied = _apply_guard_growth(choice, state.get("guard_progression") as GuardProgressionService)
		&"status_upgrade":
			result.applied = _apply_status_upgrade(choice, state)
	return result

func _level_tower(tower_id: StringName, state: Dictionary) -> bool:
	var levels := state.get("tower_type_levels", {}) as Dictionary
	var branches := state.get("tower_branch_ids", {}) as Dictionary
	var current := int(levels.get(tower_id, 0))
	var tower := DataRegistry.find_tower(tower_id)
	if tower == null or current <= 0 or current >= tower.max_level or (current == 3 and StringName(branches.get(tower_id, &"")) == &""):
		return false
	levels[tower_id] = current + 1
	SignalBus.tower_type_upgraded.emit(tower_id, current + 1)
	if current + 1 == 7:
		SignalBus.tower_final_upgrade_reached.emit(tower_id, StringName(branches.get(tower_id, &"")))
	return true

func _select_tower_branch(branch_id: StringName, state: Dictionary) -> bool:
	var levels := state.get("tower_type_levels", {}) as Dictionary
	var branches := state.get("tower_branch_ids", {}) as Dictionary
	var branch := DataRegistry.get_tower_branch(branch_id)
	if branch == null or int(levels.get(branch.tower_id, 0)) != 3:
		return false
	branches[branch.tower_id] = branch.id
	levels[branch.tower_id] = 4
	SignalBus.tower_branch_selected.emit(branch.tower_id, branch.id)
	SignalBus.tower_type_upgraded.emit(branch.tower_id, 4)
	return true

func _level_track(track: GrowthTrackState, cursor: bool) -> bool:
	if track == null or not track.can_level_up() or track.requires_branch_choice():
		return false
	track.current_level += 1
	if cursor:
		SignalBus.cursor_level_changed.emit(track.current_level)
	else:
		SignalBus.core_level_changed.emit(track.current_level)
	return true

func _select_track_branch(track: GrowthTrackState, branch_id: StringName, cursor: bool) -> bool:
	if track == null or not track.requires_branch_choice():
		return false
	var branch := DataRegistry.get_specialization_branch(branch_id)
	var expected_kind: StringName = &"cursor" if cursor else &"core"
	if branch == null or branch.owner_kind != expected_kind or branch.owner_id != track.id:
		return false
	track.selected_branch_id = branch_id
	track.current_level = 4
	if cursor:
		SignalBus.cursor_branch_selected.emit(branch_id)
		SignalBus.cursor_level_changed.emit(4)
	else:
		SignalBus.core_branch_selected.emit(branch_id)
		SignalBus.core_level_changed.emit(4)
	return true

func _apply_guard_growth(choice: UpgradeData, guard: GuardProgressionService) -> bool:
	if guard == null or not guard.is_enabled():
		return false
	match choice.category:
		&"guard_training":
			return choice.data_id == guard.growth_data.formation_id and guard.train()
		&"guard_branch":
			return guard.select_specialization(choice.data_id) != null
		&"guard_completion":
			return guard.complete_specialization(choice.data_id)
	return false

func _apply_status_upgrade(choice: UpgradeData, state: Dictionary) -> bool:
	var levels := state.get("status_upgrade_levels", {}) as Dictionary
	var status_id := choice.data_id
	if not levels.has(status_id) or int(levels[status_id]) >= 7:
		return false
	var next_level := int(levels[status_id]) + 1
	levels[status_id] = next_level
	var effects := state.get("selected_global_effects", {}) as Dictionary
	effects[status_id] = {
		"name": choice.display_name,
		"description": choice.description,
		"level": next_level,
		"status": true,
	}
	return true
