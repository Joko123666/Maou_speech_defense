class_name SpawnPacketData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export_range(0.01, 500.0, 0.01) var min_cost: float = 1.0
@export_range(0.01, 500.0, 0.01) var max_cost: float = 20.0
@export_range(0.01, 100.0, 0.01) var weight: float = 1.0
@export var allowed_phase_indices: Array[int] = []
@export var slots: Array[Dictionary] = []
@export var role_limits: Dictionary = {&"support": 1, &"disruptor": 1}

func is_allowed_phase(phase_index: int) -> bool:
	return allowed_phase_indices.has(phase_index)

func get_validation_errors(phase_count: int) -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("spawn packet id is empty")
	if display_name.strip_edges().is_empty():
		errors.append("spawn packet display name is empty")
	if min_cost <= 0.0 or max_cost < min_cost:
		errors.append("spawn packet cost range is invalid")
	if weight <= 0.0:
		errors.append("spawn packet weight must be positive")
	if allowed_phase_indices.is_empty():
		errors.append("spawn packet has no allowed phases")
	var seen_phases: Dictionary = {}
	for phase_index in allowed_phase_indices:
		if phase_index < 0 or phase_index >= phase_count:
			errors.append("spawn packet references invalid phase %d" % phase_index)
		elif seen_phases.has(phase_index):
			errors.append("spawn packet repeats phase %d" % phase_index)
		else:
			seen_phases[phase_index] = true
	if slots.is_empty():
		errors.append("spawn packet has no composition slots")
	for slot_index in slots.size():
		var slot := slots[slot_index]
		var required_tag := StringName(slot.get("tag", &""))
		if required_tag == &"":
			errors.append("spawn packet slot %d has no required role tag" % slot_index)
		if int(slot.get("count", 0)) <= 0:
			errors.append("spawn packet slot %d has a non-positive count" % slot_index)
	for raw_role in role_limits:
		var role := StringName(raw_role)
		if role == &"" or int(role_limits[raw_role]) < 0:
			errors.append("spawn packet has an invalid role limit")
	return errors
