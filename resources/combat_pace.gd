class_name CombatPace
extends RefCounted

## 전투 판독성을 위한 전역 템포 계약입니다. 공격 횟수는 절반으로 낮추고
## 한 번의 타격은 두 배로 보정해 방어력이 없는 대상 기준 DPS를 유지합니다.
const ATTACK_SPEED_SCALE: float = 0.5
const ATTACK_DAMAGE_SCALE: float = 2.0
const MOVEMENT_SPEED_SCALE: float = 0.5
const ENEMY_MOVEMENT_SPEED_SCALE: float = 1.0

static func attack_interval(value: float) -> float:
	return value / ATTACK_SPEED_SCALE

static func attack_damage(value: float) -> float:
	return value * ATTACK_DAMAGE_SCALE

static func movement_speed(value: float) -> float:
	return value * MOVEMENT_SPEED_SCALE


static func enemy_movement_speed(value: float) -> float:
	return value * ENEMY_MOVEMENT_SPEED_SCALE
