class_name CombatModifierResolver
extends RefCounted

const ATTACK_SPEED_SOFT_CAP := 1.75
const ATTACK_SPEED_OVERFLOW_EFFICIENCY := 0.25
const PERMANENT_ATTACK_SPEED_BONUS_CAP := 0.30
const NORMAL_DAMAGE_AMPLIFICATION_CAP := 1.00
const BOSS_DAMAGE_AMPLIFICATION_CAP := 0.60

static func additive_multiplier(sources: Array) -> float:
	var total_bonus := 0.0
	for source in sources:
		total_bonus += float(source) - 1.0
	return maxf(1.0 + total_bonus, 0.01)

static func resolve_attack_speed(sources: Array) -> float:
	var raw_multiplier := additive_multiplier(sources)
	if raw_multiplier <= ATTACK_SPEED_SOFT_CAP:
		return raw_multiplier
	return ATTACK_SPEED_SOFT_CAP + (raw_multiplier - ATTACK_SPEED_SOFT_CAP) * ATTACK_SPEED_OVERFLOW_EFFICIENCY

static func resolve_permanent_attack_speed_bonus(raw_bonus: float, local_cap: float = PERMANENT_ATTACK_SPEED_BONUS_CAP) -> float:
	return clampf(raw_bonus, 0.0, minf(maxf(local_cap, 0.0), PERMANENT_ATTACK_SPEED_BONUS_CAP))

static func resolve_damage_amplification(sources: Array, is_boss: bool = false) -> float:
	var total_amplification := 0.0
	for source in sources:
		total_amplification += maxf(float(source), 0.0)
	var cap := BOSS_DAMAGE_AMPLIFICATION_CAP if is_boss else NORMAL_DAMAGE_AMPLIFICATION_CAP
	return minf(total_amplification, cap)
