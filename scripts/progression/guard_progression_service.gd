class_name GuardProgressionService
extends RefCounted

var growth_data: GuardGrowthData
var trained: bool = false
var selected_specialization_id: StringName = &""
var completed: bool = false
var runtime_values: Dictionary = {}

func configure(data: GuardGrowthData) -> void:
	growth_data = data
	trained = false
	selected_specialization_id = &""
	completed = false
	runtime_values.clear()

func is_enabled() -> bool:
	return growth_data != null and growth_data.get_validation_errors().is_empty()

func get_stage() -> int:
	if not trained:
		return 0
	if selected_specialization_id == &"":
		return 1
	return 3 if completed else 2

func train() -> bool:
	if not is_enabled() or trained:
		return false
	trained = true
	return true

func get_specializations() -> Array[GuardSpecializationData]:
	if not is_enabled() or not trained or selected_specialization_id != &"":
		return []
	return growth_data.specializations.duplicate()

func select_specialization(specialization_id: StringName) -> GuardSpecializationData:
	if not is_enabled() or not trained or selected_specialization_id != &"":
		return null
	for specialization in growth_data.specializations:
		if specialization != null and specialization.id == specialization_id:
			selected_specialization_id = specialization_id
			return specialization
	return null

func complete_specialization(specialization_id: StringName) -> bool:
	if not is_enabled() or not trained or completed or specialization_id != selected_specialization_id:
		return false
	completed = true
	return true

func get_selected_specialization() -> GuardSpecializationData:
	if growth_data == null or selected_specialization_id == &"":
		return null
	for specialization in growth_data.specializations:
		if specialization != null and specialization.id == selected_specialization_id:
			return specialization
	return null

func add_runtime_value(key: StringName, amount: float, maximum: float) -> float:
	if not is_enabled() or amount <= 0.0 or maximum <= 0.0:
		return get_runtime_value(key)
	var next_value := minf(get_runtime_value(key) + amount, maximum)
	runtime_values[key] = next_value
	return next_value

func consume_runtime_value(key: StringName) -> float:
	var consumed := get_runtime_value(key)
	runtime_values.erase(key)
	return consumed

func get_runtime_value(key: StringName) -> float:
	return maxf(float(runtime_values.get(key, runtime_values.get(String(key), 0.0))), 0.0)

func merged_modifiers() -> Dictionary:
	var result: Dictionary = {}
	if not is_enabled():
		return result
	if trained:
		_merge_modifiers(result, growth_data.training_modifiers)
	var specialization := get_selected_specialization()
	if specialization != null:
		_merge_modifiers(result, specialization.modifiers)
		if completed:
			_merge_modifiers(result, specialization.completion_modifiers)
	return result

func snapshot() -> Dictionary:
	return {
		"candidate_id": String(growth_data.candidate_id) if growth_data != null else "",
		"formation_id": String(growth_data.formation_id) if growth_data != null else "",
		"stage": get_stage(),
		"trained": trained,
		"selected_specialization_id": String(selected_specialization_id),
		"completed": completed,
		"runtime_values": runtime_values.duplicate(true),
	}

func _merge_modifiers(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		var value: Variant = source[key]
		if value is float or value is int:
			target[key] = float(target.get(key, 1.0)) * float(value)
		else:
			target[key] = value
