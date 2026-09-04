class_name SpawnPhaseData
extends Resource

@export_range(0.0, 3600.0, 1.0) var start_seconds: float = 0.0
@export_range(0.1, 3600.0, 1.0) var end_seconds: float = 90.0
@export_range(0.01, 200.0, 0.01) var base_budget_rate: float = 5.5
@export_range(0.0, 100.0, 0.01) var bonus_budget_rate: float = 1.3
@export_range(1.0, 1000.0, 1.0) var target_alive_pressure: float = 42.0
@export_range(1.0, 1500.0, 1.0) var max_alive_pressure: float = 72.0
@export_range(1.0, 500.0, 1.0) var max_packet_cost: float = 18.0
@export_range(0.0, 1.0, 0.05) var boss_bonus_multiplier: float = 0.3

func contains(seconds: float, stage_duration: float) -> bool:
	var safe_end := minf(end_seconds, stage_duration + 0.11)
	return seconds >= start_seconds and seconds < safe_end

func get_validation_errors(stage_duration: float) -> PackedStringArray:
	var errors := PackedStringArray()
	if start_seconds < 0.0 or end_seconds <= start_seconds or end_seconds > stage_duration + 0.11:
		errors.append("spawn phase has an invalid time range")
	if base_budget_rate <= 0.0:
		errors.append("spawn phase base budget rate must be positive")
	if bonus_budget_rate < 0.0:
		errors.append("spawn phase bonus budget rate cannot be negative")
	if target_alive_pressure <= 0.0 or target_alive_pressure > max_alive_pressure:
		errors.append("spawn phase target pressure must be positive and no higher than maximum pressure")
	if max_packet_cost <= 0.0 or max_packet_cost > max_alive_pressure:
		errors.append("spawn phase packet cost must be positive and no higher than maximum pressure")
	return errors
