class_name BossBreachPolicy
extends RefCounted

const BASE_DAMAGE_RATIO := 0.15
const TIER_DAMAGE_RATIO_STEP := 0.025
const FINAL_BOSS_DAMAGE_CAP_RATIO := 0.22
const FINAL_BOSS_RETREAT_COLUMNS := 3.60
const FINAL_BOSS_RECOVERY_SECONDS := 2.40
const NONFINAL_RETREAT_SPEED_COMPENSATION := 2.5
const NONFINAL_REPEAT_DAMAGE_MULTIPLIER := 0.10

static func breach_damage(raw_damage: float, core_max_health: float, boss_tier: int, is_final_boss: bool) -> float:
	var tier_ratio := BASE_DAMAGE_RATIO + maxf(boss_tier - 1, 0) * TIER_DAMAGE_RATIO_STEP
	var resolved := maxf(raw_damage, core_max_health * tier_ratio)
	if is_final_boss:
		resolved = minf(resolved, core_max_health * FINAL_BOSS_DAMAGE_CAP_RATIO)
	else:
		# 동적 보스의 원천 피해가 후보별 내구도 차이를 압도하지 않도록 한 번의
		# 돌파를 단계별 체력 비율로 정규화한다. 보스는 후퇴 후 재돌파할 수
		# 있으므로 반복 돌파의 위협과 단계별 15/17.5/20% 압박은 유지된다.
		resolved = minf(resolved, core_max_health * tier_ratio)
	return maxf(resolved, 0.0)

static func retreat_columns(boss_tier: int, is_final_boss: bool) -> float:
	if is_final_boss:
		return FINAL_BOSS_RETREAT_COLUMNS
	# 출현 적 이동속도를 원천 속도로 복원해도 반복 돌파 주기는 전역 전투
	# 템포 계약을 유지해야 한다. 이동 구간을 같은 비율로 늘려 첫 돌파의
	# 압박은 보존하면서 연속 돌파가 두 배 빨라지는 것을 막는다.
	return (1.8 + maxf(boss_tier, 0) * 0.2) * NONFINAL_RETREAT_SPEED_COMPENSATION

static func repeat_damage_multiplier(previous_breaches: int, is_final_boss: bool) -> float:
	if is_final_boss or previous_breaches <= 0:
		return 1.0
	return NONFINAL_REPEAT_DAMAGE_MULTIPLIER

static func recovery_seconds(boss_tier: int, is_final_boss: bool) -> float:
	return FINAL_BOSS_RECOVERY_SECONDS if is_final_boss else 1.35 + maxf(boss_tier, 0) * 0.15
