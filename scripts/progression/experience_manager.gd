class_name ExperienceManager
extends Node

signal experience_changed(current: float, required: float, level: int)
signal leveled_up(new_level: int)

const LATE_CURVE_START_LEVEL := 25
# 승인 장기 감사의 완주 표본은 최대 12,742 XP까지 획득했다. Lv.24까지의
# 초중반 템포는 유지하면서 이 실제 상단 표본이 목표 범위의 Lv.30에
# 머물도록 후반 요구량만 더 빠르게 증가시킨다.
const LATE_CURVE_GROWTH_MULTIPLIER := 1.7

var level: int = 1
var current_experience: float = 0.0
var total_experience: float = 0.0
var required_experience: float = 24.0
var experience_multiplier: float = 1.0

func reset() -> void:
	level = 1
	current_experience = 0.0
	total_experience = 0.0
	required_experience = _required_for(level)
	experience_changed.emit(current_experience, required_experience, level)

func add_experience(amount: float) -> void:
	var gained := maxf(amount, 0.0) * experience_multiplier
	total_experience += gained
	current_experience += gained
	while current_experience >= required_experience:
		current_experience -= required_experience
		level += 1
		required_experience = _required_for(level)
		leveled_up.emit(level)
	experience_changed.emit(current_experience, required_experience, level)

func get_requirement_for_reward_level(reward_level: int) -> float:
	return _required_for(maxi(reward_level - 1, 1))

func refund_abandoned_reward(reward_level: int, ratio: float = 0.4) -> float:
	var refund := get_requirement_for_reward_level(reward_level) * clampf(ratio, 0.0, 1.0)
	current_experience += refund
	while current_experience >= required_experience:
		current_experience -= required_experience
		level += 1
		required_experience = _required_for(level)
		leveled_up.emit(level)
	experience_changed.emit(current_experience, required_experience, level)
	return refund

func _required_for(target_level: int) -> float:
	var base_requirement := 28.0 + target_level * 5.5
	var late_curve_steps := maxi(target_level - LATE_CURVE_START_LEVEL + 1, 0)
	return base_requirement * pow(LATE_CURVE_GROWTH_MULTIPLIER, late_curve_steps)
