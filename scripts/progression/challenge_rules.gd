class_name ChallengeRules
extends RefCounted

const MIN_LEVEL := 0
const MAX_LEVEL := 10

static func clamp_level(level: int) -> int:
	return clampi(level, MIN_LEVEL, MAX_LEVEL)

static func enemy_health_multiplier(level: int) -> float:
	return 1.0 + float(clamp_level(level)) * 0.12

static func enemy_damage_multiplier(level: int) -> float:
	return 1.0 + float(clamp_level(level)) * 0.08

static func enemy_speed_multiplier(level: int) -> float:
	return 1.0 + float(clamp_level(level)) * 0.015

static func spawn_interval_multiplier(level: int) -> float:
	return 1.0 - float(clamp_level(level)) * 0.025

static func spawn_rate_multiplier(level: int) -> float:
	return 1.0 / spawn_interval_multiplier(level)

static func status_resistance_bonus(level: int) -> float:
	return float(clamp_level(level)) * 0.015

static func experience_multiplier(level: int) -> float:
	return 1.0 + float(clamp_level(level)) * 0.02

static func summary(level: int) -> String:
	var safe_level := clamp_level(level)
	if safe_level == 0:
		return "기본 난도 · 적과 보상에 추가 보정 없음"
	return "난입자 체력 +%d%% · 연설 지속력 피해 +%d%% · 이동 +%d%% · 난입 +%d%% · 상태 저항 +%d%%p · 경험치 +%d%%" % [
		roundi((enemy_health_multiplier(safe_level) - 1.0) * 100.0),
		roundi((enemy_damage_multiplier(safe_level) - 1.0) * 100.0),
		roundi((enemy_speed_multiplier(safe_level) - 1.0) * 100.0),
		roundi((spawn_rate_multiplier(safe_level) - 1.0) * 100.0),
		roundi(status_resistance_bonus(safe_level) * 100.0),
		roundi((experience_multiplier(safe_level) - 1.0) * 100.0),
	]
