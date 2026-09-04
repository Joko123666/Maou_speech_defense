class_name EnemyFormationProfileData
extends Resource

@export var kind: StringName = &"single_group"
@export var tier_unit_counts: Array[int] = [1, 1, 1]
@export var tier_cohort_counts: Array[int] = [1, 1, 1]
@export var tier_stagger_seconds: Array[float] = [0.0, 0.0, 0.0]
@export_range(0.0, 0.25, 0.005) var unit_spacing_ratio: float = 0.035
@export_range(0.0, 0.5, 0.01) var cohort_axis_spacing_ratio: float = 0.14
@export var separate_group_per_cohort: bool = false

func unit_count_for_tier(tier: int) -> int:
	return tier_unit_counts[clampi(tier, 1, 3) - 1] if tier_unit_counts.size() == 3 else 0

func cohort_count_for_tier(tier: int) -> int:
	return tier_cohort_counts[clampi(tier, 1, 3) - 1] if tier_cohort_counts.size() == 3 else 0

func stagger_for_tier(tier: int) -> float:
	return tier_stagger_seconds[clampi(tier, 1, 3) - 1] if tier_stagger_seconds.size() == 3 else 0.0

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if kind not in [&"single_group", &"cavalry_formation"]:
		errors.append("enemy formation profile has unsupported kind '%s'" % kind)
	if tier_unit_counts.size() != 3 or tier_cohort_counts.size() != 3 or tier_stagger_seconds.size() != 3:
		errors.append("enemy formation profile requires exactly three tier values")
		return errors
	for tier_index in 3:
		if tier_unit_counts[tier_index] < 1 or tier_cohort_counts[tier_index] < 1 or tier_cohort_counts[tier_index] > tier_unit_counts[tier_index]:
			errors.append("enemy formation profile tier %d has invalid unit/cohort counts" % (tier_index + 1))
		if tier_stagger_seconds[tier_index] < 0.0:
			errors.append("enemy formation profile tier %d has a negative stagger" % (tier_index + 1))
	return errors
