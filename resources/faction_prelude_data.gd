class_name FactionPreludeData
extends Resource

@export_range(0, 3, 1) var boss_index: int = 0
@export_range(0.0, 600.0, 1.0) var duration: float = 0.0
@export_range(0, 3, 1) var tier: int = 0
@export_range(0.0, 1.0, 0.01) var faction_budget_ratio_min: float = 0.0
@export_range(0.0, 1.0, 0.01) var faction_budget_ratio_max: float = 0.0

func configure(
	prelude_boss_index: int,
	prelude_duration: float,
	prelude_tier: int,
	ratio_min: float,
	ratio_max: float
) -> FactionPreludeData:
	boss_index = prelude_boss_index
	duration = prelude_duration
	tier = prelude_tier
	faction_budget_ratio_min = ratio_min
	faction_budget_ratio_max = ratio_max
	return self

func start_seconds(boss_time: float) -> float:
	return maxf(boss_time - duration, 0.0)

func contains(seconds: float, boss_time: float) -> bool:
	return duration > 0.0 and seconds >= start_seconds(boss_time) and seconds < boss_time

func get_validation_errors(boss_times: Array[float]) -> PackedStringArray:
	var errors := PackedStringArray()
	if boss_index < 0 or boss_index >= boss_times.size():
		errors.append("faction prelude references invalid boss index %d" % boss_index)
		return errors
	if boss_index == 0:
		if not is_zero_approx(duration) or tier != 0 or not is_zero_approx(faction_budget_ratio_min) or not is_zero_approx(faction_budget_ratio_max):
			errors.append("the first boss must not have an automatic faction prelude")
		return errors
	if duration <= 0.0 or duration >= boss_times[boss_index] - boss_times[boss_index - 1]:
		errors.append("faction prelude %d has an invalid duration" % boss_index)
	if tier != boss_index:
		errors.append("faction prelude %d must use tier %d" % [boss_index, boss_index])
	if faction_budget_ratio_min <= 0.0 or faction_budget_ratio_max < faction_budget_ratio_min or faction_budget_ratio_max > 1.0:
		errors.append("faction prelude %d has an invalid budget ratio" % boss_index)
	return errors
