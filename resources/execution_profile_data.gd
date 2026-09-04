class_name ExecutionProfileData
extends Resource

## 일반·정예·보스가 공유하는 처형 판정 계약입니다.
@export_range(0.0, 0.95, 0.01) var execute_threshold_normal: float = 0.12
@export_range(0.0, 0.95, 0.01) var execute_threshold_elite: float = 0.07
@export_range(0.0, 0.95, 0.01) var execute_threshold_boss: float = 0.12
@export_range(0.0, 0.5, 0.005) var execute_boss_damage: float = 0.045

func threshold_for(enemy_data: EnemyData, requested_normal: float = 0.0, overrides: Dictionary = {}) -> float:
	var normal_threshold := maxf(execute_threshold_normal, requested_normal)
	var threshold := normal_threshold
	var multiplier_key := &"execute_threshold_normal_multiplier"
	if enemy_data != null and enemy_data.is_boss:
		threshold = execute_threshold_boss
		multiplier_key = &"execute_threshold_boss_multiplier"
	elif enemy_data != null and enemy_data.is_elite:
		threshold = execute_threshold_elite
		multiplier_key = &"execute_threshold_elite_multiplier"
	threshold *= float(overrides.get(&"execute_threshold_multiplier", overrides.get("execute_threshold_multiplier", 1.0)))
	threshold *= float(overrides.get(multiplier_key, overrides.get(String(multiplier_key), 1.0)))
	return clampf(threshold, 0.0, 0.95)

func boss_damage_ratio(overrides: Dictionary = {}) -> float:
	var multiplier := float(overrides.get(&"execute_boss_damage_multiplier", overrides.get("execute_boss_damage_multiplier", 1.0)))
	return clampf(execute_boss_damage * multiplier, 0.0, 0.5)

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if execute_threshold_normal <= 0.0:
		errors.append("normal execution threshold must be positive")
	if execute_threshold_elite <= 0.0 or execute_threshold_elite > execute_threshold_normal:
		errors.append("elite execution threshold must be positive and no higher than normal")
	if execute_threshold_boss <= 0.0:
		errors.append("boss execution threshold must be positive")
	if execute_boss_damage <= 0.0:
		errors.append("boss execution damage must be positive")
	return errors
