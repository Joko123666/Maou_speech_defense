class_name EnemySpawnDirector
extends RefCounted

const BASE_CHANNEL: StringName = &"base"
const BONUS_CHANNEL: StringName = &"bonus"
const BONUS_MODES: Array[StringName] = [&"normal", &"disabled", &"capped"]

var stage_data: StageData
var challenge_level: int = 0
var base_budget: float = 0.0
var bonus_budget: float = 0.0
var base_budget_accrued: float = 0.0
var bonus_budget_accrued: float = 0.0
var base_budget_spent: float = 0.0
var bonus_budget_spent: float = 0.0
var base_spawn_count: int = 0
var bonus_spawn_count: int = 0
var base_spawn_experience: float = 0.0
var bonus_spawn_experience: float = 0.0
var pressure_integral: float = 0.0
var pressure_seconds: float = 0.0
var peak_alive_pressure: float = 0.0
var current_alive_pressure: float = 0.0
var packet_spawn_counts: Dictionary = {}
var fallback_group_spawn_count: int = 0
var bonus_mode: StringName = &"normal"
var capped_bonus_rate_ratio: float = 0.5

func configure_bonus_mode(mode: StringName, capped_rate_ratio: float = 0.5) -> void:
	bonus_mode = mode if mode in BONUS_MODES else &"normal"
	capped_bonus_rate_ratio = clampf(capped_rate_ratio, 0.0, 1.0)
	if bonus_mode == &"disabled":
		bonus_budget = 0.0

func configure(data: StageData, selected_challenge_level: int) -> void:
	stage_data = data
	challenge_level = ChallengeRules.clamp_level(selected_challenge_level)
	base_budget = 0.0
	bonus_budget = 0.0
	base_budget_accrued = 0.0
	bonus_budget_accrued = 0.0
	base_budget_spent = 0.0
	bonus_budget_spent = 0.0
	base_spawn_count = 0
	bonus_spawn_count = 0
	base_spawn_experience = 0.0
	bonus_spawn_experience = 0.0
	pressure_integral = 0.0
	pressure_seconds = 0.0
	peak_alive_pressure = 0.0
	current_alive_pressure = 0.0
	packet_spawn_counts.clear()
	fallback_group_spawn_count = 0

func advance(delta: float, at_time: float, alive_pressure: float, boss_active: bool) -> void:
	if stage_data == null or delta <= 0.0:
		return
	var phase := stage_data.spawn_phase_at(at_time)
	if phase == null:
		return
	var limits := phase_limits(at_time)
	current_alive_pressure = maxf(alive_pressure, 0.0)
	pressure_integral += current_alive_pressure * delta
	pressure_seconds += delta
	peak_alive_pressure = maxf(peak_alive_pressure, current_alive_pressure)
	var challenge_rate := ChallengeRules.spawn_rate_multiplier(challenge_level)
	var base_gain := phase.base_budget_rate * challenge_rate * delta
	base_budget += base_gain
	base_budget_accrued += base_gain
	var effective_target := float(limits.target_alive_pressure)
	var pressure_gap_ratio := clampf((effective_target - current_alive_pressure) / maxf(effective_target, 1.0), 0.0, 1.0)
	var boss_multiplier := phase.boss_bonus_multiplier if boss_active else 1.0
	var bonus_rate_ratio := 0.0 if bonus_mode == &"disabled" else (capped_bonus_rate_ratio if bonus_mode == &"capped" else 1.0)
	var bonus_gain := phase.bonus_budget_rate * challenge_rate * pressure_gap_ratio * boss_multiplier * bonus_rate_ratio * delta
	bonus_budget += bonus_gain
	bonus_budget_accrued += bonus_gain
	# 후보 비용보다 예산이 오래 쌓여 한 프레임에 폭발하지 않도록 채널별 저수지를 제한한다.
	base_budget = minf(base_budget, float(limits.max_packet_cost) * 3.0)
	bonus_budget = minf(bonus_budget, float(limits.max_packet_cost))

func affordable_budget(channel: StringName, at_time: float, alive_pressure: float) -> float:
	if stage_data == null:
		return 0.0
	var phase := stage_data.spawn_phase_at(at_time)
	if phase == null:
		return 0.0
	var limits := phase_limits(at_time)
	if channel == BONUS_CHANNEL:
		if alive_pressure >= float(limits.target_alive_pressure):
			return 0.0
		return minf(minf(bonus_budget, float(limits.max_packet_cost)), maxf(float(limits.max_alive_pressure) - alive_pressure, 0.0))
	return minf(base_budget, float(limits.max_packet_cost))

func phase_limits(at_time: float) -> Dictionary:
	if stage_data == null:
		return {"target_alive_pressure": 0.0, "max_alive_pressure": 0.0, "max_packet_cost": 0.0}
	var phase := stage_data.spawn_phase_at(at_time)
	if phase == null:
		return {"target_alive_pressure": 0.0, "max_alive_pressure": 0.0, "max_packet_cost": 0.0}
	var density := ChallengeRules.spawn_rate_multiplier(challenge_level)
	return {
		"bonus_mode": String(bonus_mode),
		"capped_bonus_rate_ratio": capped_bonus_rate_ratio,
		"target_alive_pressure": phase.target_alive_pressure * density,
		"max_alive_pressure": phase.max_alive_pressure * density,
		"max_packet_cost": phase.max_packet_cost * density,
	}

func spend(channel: StringName, cost: float, count: int, experience_value: float) -> bool:
	var safe_cost := maxf(cost, 0.0)
	if safe_cost <= 0.0 or count <= 0:
		return false
	if channel == BONUS_CHANNEL:
		if bonus_budget + 0.0001 < safe_cost:
			return false
		bonus_budget = maxf(bonus_budget - safe_cost, 0.0)
		bonus_budget_spent += safe_cost
		bonus_spawn_count += count
		bonus_spawn_experience += maxf(experience_value, 0.0)
		return true
	if base_budget + 0.0001 < safe_cost:
		return false
	base_budget = maxf(base_budget - safe_cost, 0.0)
	base_budget_spent += safe_cost
	base_spawn_count += count
	base_spawn_experience += maxf(experience_value, 0.0)
	return true

func record_composition(packet_id: StringName) -> void:
	if packet_id == &"":
		fallback_group_spawn_count += 1
		return
	packet_spawn_counts[packet_id] = int(packet_spawn_counts.get(packet_id, 0)) + 1

func snapshot() -> Dictionary:
	var total_xp := base_spawn_experience + bonus_spawn_experience
	return {
		"bonus_mode": String(bonus_mode),
		"capped_bonus_rate_ratio": capped_bonus_rate_ratio,
		"base_budget": base_budget,
		"bonus_budget": bonus_budget,
		"base_budget_accrued": base_budget_accrued,
		"bonus_budget_accrued": bonus_budget_accrued,
		"base_budget_spent": base_budget_spent,
		"bonus_budget_spent": bonus_budget_spent,
		"base_spawn_count": base_spawn_count,
		"bonus_spawn_count": bonus_spawn_count,
		"base_spawn_experience": base_spawn_experience,
		"bonus_spawn_experience": bonus_spawn_experience,
		"bonus_experience_ratio": bonus_spawn_experience / total_xp if total_xp > 0.0 else 0.0,
		"average_alive_pressure": pressure_integral / pressure_seconds if pressure_seconds > 0.0 else 0.0,
		"peak_alive_pressure": peak_alive_pressure,
		"current_alive_pressure": current_alive_pressure,
		"packet_spawn_counts": packet_spawn_counts.duplicate(),
		"fallback_group_spawn_count": fallback_group_spawn_count,
	}
