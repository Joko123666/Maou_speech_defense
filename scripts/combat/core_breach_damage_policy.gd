class_name CoreBreachDamagePolicy
extends RefCounted

## SpawnDirector는 강한 빌드의 추가 전투와 경험치 획득을 위해 일반 적
## 처리량을 늘린다. 적 수와 성장량은 보존하되, 여러 일반 적이 같은 순간
## 도달했을 때 기존 개별 핵 피해가 그대로 중첩되는 부분만 보정한다.
const REGULAR_DAMAGE_MULTIPLIER := 0.30
## 한 SpawnDirector 패킷은 같은 group_id를 공유한다. 여러 구성원이 함께
## 전선을 넘더라도 한 패킷이 주는 일반 돌파 피해는 마왕 후보 최대 체력의
## 4%를 기본 상한으로 삼되, 단일 개체의 온전한 피해보다 낮아지지는 않는다.
const GROUP_DAMAGE_CAP_RATIO := 0.04
const PRE_FINAL_CORE_RESERVE_RATIO := 0.40

static func regular_damage(raw_damage: float, challenge_damage_multiplier: float = 1.0, core_breach_damage_multiplier: float = 1.0) -> float:
	return maxf(raw_damage, 0.0) * maxf(challenge_damage_multiplier, 0.0) * REGULAR_DAMAGE_MULTIPLIER * maxf(core_breach_damage_multiplier, 0.0)

static func group_limited_damage(
	resolved_damage: float,
	core_max_health: float,
	accumulated_group_damage: float,
	challenge_damage_multiplier: float = 1.0,
	core_breach_damage_multiplier: float = 1.0
) -> float:
	var safe_damage := maxf(resolved_damage, 0.0)
	var scaled_ratio_cap := (
		maxf(core_max_health, 0.0)
		* GROUP_DAMAGE_CAP_RATIO
		* maxf(challenge_damage_multiplier, 0.0)
		* maxf(core_breach_damage_multiplier, 0.0)
	)
	var group_cap := maxf(safe_damage, scaled_ratio_cap)
	return minf(safe_damage, maxf(group_cap - maxf(accumulated_group_damage, 0.0), 0.0))

static func pre_final_reserve_limited_damage(resolved_damage: float, core_health: float, core_max_health: float) -> float:
	var reserve_health := maxf(core_max_health, 0.0) * PRE_FINAL_CORE_RESERVE_RATIO
	return minf(maxf(resolved_damage, 0.0), maxf(core_health - reserve_health, 0.0))
