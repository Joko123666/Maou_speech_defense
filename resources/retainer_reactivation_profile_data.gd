class_name RetainerReactivationProfileData
extends Resource

@export_range(1.0, 1000.0, 1.0) var maximum_health: float = 100.0
@export_range(0.0, 100.0, 0.1) var passive_health_drain_per_second: float = 1.2
@export_range(0.0, 100.0, 0.1) var attack_health_cost: float = 2.5
@export_range(0.1, 60.0, 0.1) var reactivation_seconds: float = 6.0

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if maximum_health <= 0.0: errors.append("retainer maximum health must be positive")
	if passive_health_drain_per_second <= 0.0: errors.append("retainer passive health drain must be positive")
	if attack_health_cost <= 0.0: errors.append("retainer attack health cost must be positive")
	if reactivation_seconds <= 0.0: errors.append("retainer reactivation time must be positive")
	return errors
