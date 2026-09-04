class_name CandidateAbyssSwarmService
extends RefCounted

const MASS_SUMMON_METRIC := &"kasuha_mass_summon"
const CAP_REACHED_METRIC := &"kasuha_summon_cap_reached"
const NOTICE_DURATION := 2.2

func build_profile(
		modifier_resolver: Callable,
		growth_snapshot: Dictionary,
		core_skill_damage_multiplier: float
	) -> Dictionary:
	if not modifier_resolver.is_valid():
		return _empty_profile()
	var completed_slots_value: Variant = growth_snapshot.get("completed_slots", {})
	var growth_level := (completed_slots_value as Dictionary).size() if completed_slots_value is Dictionary else 0
	var summon_damage := float(modifier_resolver.call(&"candidate_summon_damage", 36.0))
	summon_damage *= 1.0 + growth_level * 0.15
	summon_damage *= core_skill_damage_multiplier
	var summon_radius := float(modifier_resolver.call(&"candidate_summon_radius", 1600.0))
	summon_radius *= float(modifier_resolver.call(&"core_skill_range", 1.0))
	return {
		"valid": true,
		"requested": maxi(int(modifier_resolver.call(&"candidate_summon_count", 8)), 0),
		"cap": maxi(int(modifier_resolver.call(&"candidate_summon_cap", 8)), 1),
		"duration": float(modifier_resolver.call(&"candidate_summon_duration", 8.0)),
		"interval": float(modifier_resolver.call(&"candidate_summon_interval", 1.0)),
		"damage": summon_damage,
		"radius": summon_radius,
	}

func execute(
		profile: Dictionary,
		color: Color,
		targets: Array[Enemy],
		spawn_callback: Callable
	) -> Dictionary:
	if not bool(profile.get("valid", false)) or not spawn_callback.is_valid():
		return _empty_result()
	var spawn_count := maxi(int(spawn_callback.call(
		int(profile.requested),
		int(profile.cap),
		float(profile.duration),
		float(profile.interval),
		float(profile.damage),
		float(profile.radius),
		color,
		targets
	)), 0)
	if spawn_count <= 0:
		return {
			"attempted": true,
			"spawn_count": 0,
			"metric_id": CAP_REACHED_METRIC,
			"metric_value": 1.0,
			"notice": "",
			"notice_duration": 0.0,
		}
	return {
		"attempted": true,
		"spawn_count": spawn_count,
		"metric_id": MASS_SUMMON_METRIC,
		"metric_value": float(spawn_count),
		"notice": "대규모 소환술 · 심연 생명체 %d기" % spawn_count,
		"notice_duration": NOTICE_DURATION,
	}

func _empty_profile() -> Dictionary:
	return {
		"valid": false,
		"requested": 0,
		"cap": 1,
		"duration": 0.0,
		"interval": 0.0,
		"damage": 0.0,
		"radius": 0.0,
	}

func _empty_result() -> Dictionary:
	return {
		"attempted": false,
		"spawn_count": 0,
		"metric_id": &"",
		"metric_value": 0.0,
		"notice": "",
		"notice_duration": 0.0,
	}
