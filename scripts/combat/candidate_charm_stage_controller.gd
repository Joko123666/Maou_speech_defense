class_name CandidateCharmStageController
extends RefCounted

const TICK_INTERVAL_SECONDS := 0.25

var remaining: float = 0.0
var tick_remaining: float = 0.0
var profile: CharmProfileData
var grants_stage_buff: bool = false

func activate_candidate_skill(
		core_data: CoreData,
		grants_buff: bool,
		loadout: LoadoutManager,
		devotion_consumer_callback: Callable,
		devotion_result_callback: Callable = Callable()
	) -> Dictionary:
	var result := {
		"applied": false,
		"base_charm_duration": 0.0,
		"extension": 0.0,
		"consumed_stacks": 0,
		"disabled_duration": 0.0,
		"stage_duration": 0.0,
		"grants_stage_buff": grants_buff,
	}
	if core_data == null or loadout == null:
		return result
	var base_charm_duration := 0.9
	if core_data.charm_profile != null:
		base_charm_duration = core_data.charm_profile.duration * float(loadout.get_candidate_modifier(&"charm_duration", 1.0))
	if grants_buff:
		base_charm_duration = float(loadout.get_candidate_modifier(&"charm_stage_duration", 6.0))
	result.base_charm_duration = base_charm_duration
	var devotion_result := {"consumed_stacks": 0, "extension": 0.0, "disabled_duration": 0.0}
	if devotion_consumer_callback.is_valid():
		var callback_result: Variant = devotion_consumer_callback.call(loadout.columns, loadout, base_charm_duration)
		if callback_result is Dictionary:
			devotion_result = callback_result
	result.extension = float(devotion_result.get("extension", 0.0))
	result.consumed_stacks = int(devotion_result.get("consumed_stacks", 0))
	result.disabled_duration = float(devotion_result.get("disabled_duration", 0.0))
	if devotion_result_callback.is_valid():
		devotion_result_callback.call(devotion_result)
	result.stage_duration = activate(loadout, core_data.charm_profile, float(result.extension), grants_buff)
	result.applied = true
	return result

func activate(
		loadout: LoadoutManager,
		active_profile: CharmProfileData,
		duration_extension: float = 0.0,
		grants_buff: bool = true
	) -> float:
	profile = active_profile
	var base_duration := profile.active_zone_duration if profile != null else 6.0
	if grants_buff:
		base_duration = float(loadout.get_candidate_modifier(&"charm_stage_duration", base_duration))
	remaining = base_duration + maxf(duration_extension, 0.0)
	tick_remaining = 0.0
	grants_stage_buff = grants_buff
	loadout.set_candidate_stage_buff_active(grants_buff)
	return remaining

func update(delta: float, loadout: LoadoutManager, enemies: Array[Enemy]) -> Dictionary:
	var result := {
		"pulse": false,
		"charm_applied": false,
		"stage_tick": false,
		"ended": false,
		"ended_with_stage_buff": false,
	}
	if remaining <= 0.0:
		return result
	remaining = maxf(remaining - delta, 0.0)
	tick_remaining -= delta
	if tick_remaining <= 0.0:
		tick_remaining = TICK_INTERVAL_SECONDS
		result.pulse = true
		if profile != null:
			var duration_multiplier := float(loadout.get_candidate_modifier(&"charm_duration", 1.0))
			var vulnerability := float(loadout.get_candidate_modifier(&"charm_vulnerability", 0.0))
			for enemy in enemies:
				if not is_instance_valid(enemy) or not enemy.active:
					continue
				if not enemy.refresh_charm(profile.duration * duration_multiplier):
					enemy.apply_charm(profile, duration_multiplier, vulnerability)
			result.charm_applied = true
			result.stage_tick = grants_stage_buff
	if is_zero_approx(remaining):
		result.ended = true
		result.ended_with_stage_buff = grants_stage_buff
		if grants_stage_buff:
			loadout.set_candidate_stage_buff_active(false)
		grants_stage_buff = false
		profile = null
	return result
