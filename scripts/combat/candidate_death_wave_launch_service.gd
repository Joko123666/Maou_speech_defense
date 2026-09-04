class_name CandidateDeathWaveLaunchService
extends RefCounted

const WAVE_DURATION := 2.4
const BASE_HALF_HEIGHT := 145.0

func execute(
		base_damage: float,
		current_souls: int,
		target_center_y: float,
		color: Color,
		candidate_modifier_callback: Callable,
		consume_souls_callback: Callable,
		launch_callback: Callable
	) -> Dictionary:
	var result := _empty_result()
	if not candidate_modifier_callback.is_valid() or not consume_souls_callback.is_valid() or not launch_callback.is_valid():
		return result
	var soul_harvest_enabled := bool(candidate_modifier_callback.call(&"soul_harvest", false))
	var reserved_souls := maxi(current_souls, 0) if soul_harvest_enabled else 0
	var effective_souls := effective_soul_value(reserved_souls)
	var damage_multiplier := 1.0 + effective_souls * float(candidate_modifier_callback.call(&"soul_wave_damage_per_effective", 0.0))
	result.effective_souls = effective_souls
	result.damage = base_damage * damage_multiplier
	result.half_height = BASE_HALF_HEIGHT + effective_souls * float(candidate_modifier_callback.call(&"soul_wave_range_per_effective", 0.0))
	result.spirit_gain = 1 + floori(effective_souls / 100.0)
	result.generated_spirit_damage_multiplier = float(candidate_modifier_callback.call(&"active_generated_spirit_damage", 1.0))
	result.post_wave_window = float(candidate_modifier_callback.call(&"post_active_spirit_window", 0.0))
	result.soul_cap = int(candidate_modifier_callback.call(&"soul_harvest_cap", 0))
	var launched := bool(launch_callback.call(
		float(result.damage),
		target_center_y,
		float(result.half_height),
		WAVE_DURATION,
		int(result.spirit_gain),
		float(result.generated_spirit_damage_multiplier),
		color
	))
	if not launched:
		result.reason = &"launch_rejected"
		return result
	result.launched = true
	result.reason = &"launched"
	if soul_harvest_enabled:
		result.consumed_souls = maxi(int(consume_souls_callback.call()), 0)
	return result

static func effective_soul_value(stacks: int) -> float:
	var bounded := clampi(stacks, 0, 300)
	var first_band := mini(bounded, 100)
	var second_band := mini(maxi(bounded - 100, 0), 100)
	var third_band := mini(maxi(bounded - 200, 0), 100)
	return first_band + second_band * 0.5 + third_band * 0.25

func _empty_result() -> Dictionary:
	return {
		"launched": false,
		"reason": &"invalid_dependencies",
		"consumed_souls": 0,
		"effective_souls": 0.0,
		"damage": 0.0,
		"half_height": 0.0,
		"duration": WAVE_DURATION,
		"spirit_gain": 0,
		"generated_spirit_damage_multiplier": 0.0,
		"post_wave_window": 0.0,
		"soul_cap": 0,
	}
