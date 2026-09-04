class_name Enemy
extends Node2D

const BURN_TICK_SECONDS := 0.5
const MAX_BURN_TICKS_PER_FRAME := 8
const MAX_KNOCKBACK_SPAWN_OVERSHOOT := 180.0
const BENEFICIAL_STATUS_TYPES: Array[StringName] = [&"haste", &"fortify"]
const DEFAULT_CONTROL_RECOVERY := {&"fear": 0.45, &"stun": 0.35}
const DEATH_CAUSE_DIRECT_KILL := &"direct_kill"
const DEATH_CAUSE_DAMAGE_OVER_TIME := &"damage_over_time"
const DEATH_CAUSE_SELF_DECAY := &"self_decay"
const DEATH_CAUSE_NONE := &"none"
const DAMAGE_OVER_TIME_SOURCES: Array[StringName] = [&"burn", &"common_poison", &"common_burn", &"common_bleed", &"common_shock"]

signal reached_core(damage: float)
signal died(experience_value: float, death_position: Vector2, enemy_data: EnemyData, lane_index: int)
signal charmed_defeated(death_position: Vector2, enemy_data: EnemyData)
signal damage_received(amount: float, source_type: StringName, enemy_data: EnemyData)
signal boss_health_changed(current: float, maximum: float, display_name: String)
signal special_action(action: StringName, source: Enemy)
signal moved(enemy: Enemy)
signal acceleration_changed(enemy: Enemy, acceleration_kind: StringName, stacks: int, speed_bonus: float, duration: float)
signal control_resolved(enemy: Enemy, control_type: StringName, accepted: bool, requested_effect: float, effective_effect: float, requested_duration: float, effective_duration: float)

var data: EnemyData
# 전투 위치를 고정하지 않는 통계/호환용 세로 구역 인덱스다.
var lane_index: int
var current_health: float
var target_position: Vector2
var spawn_distance_limit: float
var health_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var active: bool = false
var statuses: Dictionary = {}
var common_ailments: Dictionary = {}
var common_ailment_accumulator: float = 0.0
var behavior_accumulator: float = 0.0
var burn_accumulator: float = 0.0
var experience_multiplier: float = 1.0
var challenge_experience_multiplier: float = 1.0
var final_phase: int = 1
var runtime_status_resistance: float = 0.0
var hit_flash: float = 0.0
var hit_pulse: float = 0.0
var barrier_health: float = 0.0
var barrier_max: float = 0.0
var charge_remaining: float = 0.0
var phase_active: bool = false
var core_breach_cooldown: float = 0.0
var zigzag_phase: float = 0.0
var taunt_pulse: float = 0.0
var hit_visual_offset := Vector2.ZERO
var hit_visual_velocity := Vector2.ZERO
var hit_feedback_color := Color.WHITE
var hit_feedback_profile: StringName = &"generic"
var knockback_flash: float = 0.0
var knockback_visual_distance: float = 0.0
var knockback_visual_direction := Vector2.RIGHT
var status_visual_flashes: Dictionary = {}
var execute_threshold_ratio: float = 0.0
var last_knockback_displacement: float = 0.0
var charm_immunity_remaining: float = 0.0
var control_recovery_remaining: Dictionary = {}
var campaign_faction_id: StringName = &""
var campaign_primary_color: Color = Color.WHITE
var campaign_secondary_color: Color = Color.WHITE
var campaign_emblem: Texture2D
var campaign_character_art: Texture2D
var campaign_character_art_source_category: StringName = &""
var campaign_character_art_flip_h: bool = false
var campaign_character_presentation_kind: StringName = &""
var campaign_character_presentation_id: StringName = &""
var campaign_marker_style: StringName = &""
var campaign_elite: bool = false
var spawn_context: EnemySpawnContext
var fixed_movement_direction := Vector2.ZERO
var acceleration_stacks: int = 0
var acceleration_remaining: float = 0.0
var acceleration_internal_cooldown: float = 0.0
var group_acceleration_stacks: int = 0
var group_acceleration_remaining: float = 0.0
var group_acceleration_internal_cooldown: float = 0.0
var last_damage_context: EnemyDamageContext
var last_death_cause: StringName = DEATH_CAUSE_NONE

func _ready() -> void:
	set_notify_transform(true)
	set_notify_local_transform(true)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_TRANSFORM_CHANGED, NOTIFICATION_LOCAL_TRANSFORM_CHANGED] and active:
		moved.emit(self)

func setup(enemy_data: EnemyData, spawn_position: Vector2, sector: int, core_target_position: Vector2, spawn_health_multiplier: float, spawn_speed_multiplier: float) -> void:
	data = enemy_data
	lane_index = sector
	position = spawn_position
	target_position = core_target_position
	spawn_distance_limit = spawn_position.distance_to(core_target_position)
	health_multiplier = spawn_health_multiplier
	speed_multiplier = spawn_speed_multiplier
	current_health = data.max_health * health_multiplier
	statuses.clear()
	common_ailments.clear()
	status_visual_flashes.clear()
	common_ailment_accumulator = 0.0
	burn_accumulator = 0.0
	charm_immunity_remaining = 0.0
	control_recovery_remaining.clear()
	spawn_context = null
	fixed_movement_direction = Vector2.ZERO
	acceleration_stacks = 0
	acceleration_remaining = 0.0
	acceleration_internal_cooldown = 0.0
	group_acceleration_stacks = 0
	group_acceleration_remaining = 0.0
	group_acceleration_internal_cooldown = 0.0
	last_damage_context = null
	last_death_cause = DEATH_CAUSE_NONE
	campaign_character_art = null
	campaign_character_art_source_category = &""
	campaign_character_art_flip_h = false
	campaign_character_presentation_kind = &""
	campaign_character_presentation_id = &""
	if data.behavior == &"shielded":
		barrier_max = current_health * 0.42
		barrier_health = barrier_max
	runtime_status_resistance = data.status_resistance
	zigzag_phase = RunRng.spawn_rangef(0.0, TAU)
	active = true
	add_to_group(&"enemies")
	if data.is_boss:
		add_to_group(&"bosses")
		boss_health_changed.emit(current_health, get_max_health(), data.display_name)
	queue_redraw()

func get_max_health() -> float:
	return data.max_health * health_multiplier

func set_challenge_modifiers(experience_bonus: float, status_resistance_bonus: float) -> void:
	challenge_experience_multiplier = maxf(experience_bonus, 1.0)
	runtime_status_resistance = clampf(runtime_status_resistance + maxf(status_resistance_bonus, 0.0), 0.0, 0.95)

func set_campaign_faction(faction: ElectionFactionData) -> void:
	if faction == null or data == null:
		return
	campaign_faction_id = faction.id
	campaign_primary_color = faction.primary_color
	campaign_secondary_color = faction.secondary_color
	campaign_emblem = ConceptService.content_texture(&"emblems", faction.emblem_id)
	campaign_marker_style = faction.marker_style
	campaign_elite = data.is_boss or data.id in faction.elite_enemy_ids
	queue_redraw()

func set_campaign_character_identity(identity_id: StringName, candidate_identity: bool) -> void:
	set_campaign_character_presentation(
		StageRuntimeBossPlan.PRESENTATION_CANDIDATE if candidate_identity else StageRuntimeBossPlan.PRESENTATION_RETAINER,
		identity_id
	)

func set_campaign_character_presentation(presentation_kind: StringName, identity_id: StringName, fallback_id: StringName = &"") -> void:
	var intrusion_category: StringName = &""
	var fallback_category: StringName = &""
	var resolved_fallback_id := identity_id
	match presentation_kind:
		StageRuntimeBossPlan.PRESENTATION_CANDIDATE:
			intrusion_category = &"candidate_intrusion_sd"
			fallback_category = &"candidate_sd"
		StageRuntimeBossPlan.PRESENTATION_RETAINER:
			intrusion_category = &"retainer_intrusion_sd"
			fallback_category = &"retainer_sd"
		StageRuntimeBossPlan.PRESENTATION_GUARD:
			intrusion_category = &"guard_intrusion_sd"
			fallback_category = &"towers"
			resolved_fallback_id = fallback_id
	campaign_character_presentation_kind = presentation_kind
	campaign_character_presentation_id = identity_id
	campaign_character_art = ConceptService.optional_content_texture(intrusion_category, identity_id) if intrusion_category != &"" and identity_id != &"" else null
	campaign_character_art_source_category = intrusion_category if campaign_character_art != null else fallback_category
	campaign_character_art_flip_h = campaign_character_art == null and fallback_category != &"" and resolved_fallback_id != &""
	if campaign_character_art == null and fallback_category != &"" and resolved_fallback_id != &"":
		campaign_character_art = ConceptService.optional_content_texture(fallback_category, resolved_fallback_id)
	if campaign_character_art == null:
		campaign_character_art_source_category = &""
		campaign_character_art_flip_h = false
	queue_redraw()

func get_health_ratio() -> float:
	return current_health / get_max_health() if get_max_health() > 0.0 else 0.0

func get_distance_to_core_face() -> float:
	return maxf(global_position.x - target_position.x, 0.0)

func set_core_goal_position(core_goal_position: Vector2) -> void:
	target_position = core_goal_position
	spawn_distance_limit = maxf(spawn_distance_limit, global_position.distance_to(target_position))

func set_spawn_context(context: EnemySpawnContext, destination_world_y: float = NAN) -> void:
	spawn_context = context
	queue_redraw()
	if data == null or data.movement_profile == null or data.movement_profile.kind != &"fixed_diagonal" or is_nan(destination_world_y):
		return
	fixed_movement_direction = position.direction_to(Vector2(target_position.x, destination_world_y))
	if fixed_movement_direction.is_zero_approx():
		fixed_movement_direction = Vector2.LEFT

func get_acceleration_stack_count() -> int:
	return acceleration_stacks

func get_acceleration_speed_bonus() -> float:
	return float(acceleration_stacks) * data.acceleration_profile.speed_per_hit if data != null and data.acceleration_profile != null else 0.0

func get_group_acceleration_stack_count() -> int:
	return group_acceleration_stacks

func get_group_acceleration_speed_bonus() -> float:
	return float(group_acceleration_stacks) * data.group_acceleration_profile.speed_per_ally_death if data != null and data.group_acceleration_profile != null else 0.0

func apply_same_group_death_acceleration() -> bool:
	if not active or data == null or data.group_acceleration_profile == null or spawn_context == null or spawn_context.group_id == &"" or group_acceleration_internal_cooldown > 0.0:
		return false
	var profile := data.group_acceleration_profile
	group_acceleration_stacks = mini(group_acceleration_stacks + 1, profile.maximum_stacks)
	group_acceleration_remaining = profile.duration
	group_acceleration_internal_cooldown = profile.internal_cooldown
	acceleration_changed.emit(self, &"group_death", group_acceleration_stacks, get_group_acceleration_speed_bonus(), group_acceleration_remaining)
	return true

func set_execute_threshold(ratio: float) -> void:
	execute_threshold_ratio = clampf(ratio, 0.0, 0.95)
	queue_redraw()

func needs_continuous_redraw() -> bool:
	return (execute_threshold_ratio > 0.0 and get_health_ratio() <= execute_threshold_ratio) or statuses.has(&"mark") or not status_visual_flashes.is_empty()

func trigger_status_visual(status_id: StringName) -> void:
	if not EnemyStatusEffectRenderer.supports(status_id):
		return
	status_visual_flashes[status_id] = 1.0
	queue_redraw()

func get_active_status_visual_ids() -> Array[StringName]:
	return EnemyStatusEffectRenderer.active_visual_ids(statuses, common_ailments)

func _update_status_visual_flashes(delta: float) -> bool:
	if status_visual_flashes.is_empty():
		return false
	var expired: Array[StringName] = []
	for status_id in status_visual_flashes:
		status_visual_flashes[status_id] = maxf(float(status_visual_flashes[status_id]) - delta * 4.8, 0.0)
		if is_zero_approx(float(status_visual_flashes[status_id])):
			expired.append(status_id)
	for status_id in expired:
		status_visual_flashes.erase(status_id)
	return true

func take_damage(amount: float, source_type: StringName = &"generic", is_area: bool = false, damage_context: EnemyDamageContext = null) -> float:
	if not active or amount <= 0.0:
		return 0.0
	var fixed_damage := source_type in [&"common_poison", &"common_burn", &"common_bleed", &"common_shock", &"judgment_fixed", &"judgment_execute"]
	var damage_amplification := 0.0 if fixed_damage else get_damage_amplification()
	var fortify_armor := float(statuses.get(&"fortify", {}).get("power", 0.0))
	var tower_pierce_marked := statuses.has(&"pierce_mark") and source_type in [&"rapid", &"area", &"slow", &"execute", &"knockback", &"mark", &"chain", &"pierce", &"unique_single", &"unique_pierce", &"unique_radial", &"unique_random"]
	var armor_value := 0.0 if fixed_damage else (data.armor + fortify_armor) * (0.6 if source_type == &"pierce" or tower_pierce_marked else 1.0)
	var phase_multiplier := 1.0 if fixed_damage else (0.42 if data.behavior == &"phase" and phase_active else 1.0)
	var applied := maxf(amount * (1.0 + damage_amplification) * phase_multiplier - armor_value, 1.0)
	var barrier_absorbed := minf(barrier_health, applied)
	barrier_health -= barrier_absorbed
	var health_damage := minf(current_health, applied - barrier_absorbed)
	current_health -= health_damage
	var total_damage := barrier_absorbed + health_damage
	if total_damage > 0.0:
		last_damage_context = damage_context
		_register_acceleration_hit()
		damage_received.emit(total_damage, source_type, data)
	hit_flash = 1.0
	hit_pulse = 1.0
	if data.is_boss:
		boss_health_changed.emit(current_health, get_max_health(), data.display_name)
	_update_boss_phase()
	queue_redraw()
	if is_zero_approx(current_health):
		_die(DEATH_CAUSE_DAMAGE_OVER_TIME if source_type in DAMAGE_OVER_TIME_SOURCES else DEATH_CAUSE_DIRECT_KILL)
	return total_damage

func get_damage_amplification() -> float:
	if data == null:
		return 0.0
	return CombatModifierResolver.resolve_damage_amplification([
		float(statuses.get(&"mark", {}).get("power", 0.0)),
		float(statuses.get(&"charm", {}).get("vulnerability", 0.0)),
	], data.is_boss)

func take_fixed_damage(amount: float, source_type: StringName = &"judgment_fixed", damage_context: EnemyDamageContext = null) -> float:
	return take_damage(amount, source_type, true, damage_context)

func _register_acceleration_hit() -> void:
	if data == null or data.acceleration_profile == null or acceleration_internal_cooldown > 0.0:
		return
	var profile := data.acceleration_profile
	acceleration_stacks = mini(acceleration_stacks + 1, profile.maximum_stacks)
	acceleration_remaining = profile.duration
	acceleration_internal_cooldown = profile.internal_cooldown
	acceleration_changed.emit(self, &"on_hit", acceleration_stacks, get_acceleration_speed_bonus(), acceleration_remaining)

func apply_charm(profile: CharmProfileData, duration_multiplier: float = 1.0, vulnerability_bonus: float = 0.0) -> bool:
	if not active or profile == null:
		return false
	var requested_duration := profile.duration * maxf(duration_multiplier, 0.05)
	if charm_immunity_remaining > 0.0 or statuses.has(&"charm") or _is_control_resisted(&"charm"):
		_emit_control_result(&"charm", false, 1.0, 0.0, requested_duration, 0.0)
		return false
	var effective_duration := requested_duration * _control_duration_ratio(&"charm")
	if effective_duration <= 0.05:
		_emit_control_result(&"charm", false, 1.0, 0.0, requested_duration, 0.0)
		return false
	var vulnerability := vulnerability_bonus
	if data.is_boss:
		vulnerability = profile.boss_vulnerability * _control_effect_ratio(&"charm") + vulnerability_bonus * _control_effect_ratio(&"charm")
	vulnerability = minf(vulnerability, 0.30 if data.is_boss else 0.50)
	statuses[&"charm"] = {
		"remaining": effective_duration,
		"power": 1.0,
		"immunity_duration": profile.reapplication_immunity,
		"boss_converted": data.is_boss,
		"slow_power": profile.boss_slow_power * _control_effect_ratio(&"charm") if data.is_boss else 0.0,
		"vulnerability": vulnerability,
	}
	trigger_status_visual(&"charm")
	_emit_control_result(&"charm", true, 1.0, _control_effect_ratio(&"charm"), requested_duration, effective_duration)
	queue_redraw()
	return true

func refresh_charm(duration: float) -> bool:
	if not active or not statuses.has(&"charm") or duration <= 0.0:
		return false
	var charm: Dictionary = statuses[&"charm"]
	charm.remaining = maxf(float(charm.get("remaining", 0.0)), duration * _control_duration_ratio(&"charm"))
	statuses[&"charm"] = charm
	return true

func apply_fear(duration: float, initial_slow: float = 0.8) -> bool:
	if not active or duration <= 0.05 or initial_slow <= 0.0:
		return false
	if statuses.has(&"fear") or _is_control_resisted(&"fear"):
		_emit_control_result(&"fear", false, initial_slow, 0.0, duration, 0.0)
		return false
	var effective_duration := duration * _control_duration_ratio(&"fear")
	var effective_slow := clampf(initial_slow * _control_effect_ratio(&"fear"), 0.0, 0.8)
	if effective_duration <= 0.05 or effective_slow <= 0.0:
		_emit_control_result(&"fear", false, initial_slow, 0.0, duration, 0.0)
		return false
	var candidate := {
		"remaining": effective_duration,
		"total_duration": effective_duration,
		"power": effective_slow,
	}
	statuses[&"fear"] = candidate
	trigger_status_visual(&"fear")
	_emit_control_result(&"fear", true, initial_slow, effective_slow, duration, effective_duration)
	queue_redraw()
	return true

func get_fear_slow_power() -> float:
	return _fear_slow_power(statuses.get(&"fear", {}))

func _fear_slow_power(fear: Dictionary) -> float:
	if fear.is_empty():
		return 0.0
	var total_duration := maxf(float(fear.get("total_duration", 0.0)), 0.001)
	var remaining_ratio := clampf(float(fear.get("remaining", 0.0)) / total_duration, 0.0, 1.0)
	return clampf(float(fear.get("power", 0.0)) * remaining_ratio, 0.0, 0.8)

func is_charmed() -> bool:
	return statuses.has(&"charm") and not bool(statuses[&"charm"].get("boss_converted", false))

func has_charm_effect() -> bool:
	return statuses.has(&"charm")

func is_charm_immune() -> bool:
	return charm_immunity_remaining > 0.0

func add_sentence_stacks(amount: int, duration: float) -> int:
	if not active or amount <= 0:
		return get_sentence_stacks()
	var sentence: Dictionary = statuses.get(&"sentence", {"remaining": duration, "power": 0})
	sentence.remaining = maxf(float(sentence.get("remaining", 0.0)), duration)
	sentence.power = int(sentence.get("power", 0)) + amount
	statuses[&"sentence"] = sentence
	trigger_status_visual(&"sentence")
	queue_redraw()
	return int(sentence.power)

func get_sentence_stacks() -> int:
	return int(statuses.get(&"sentence", {}).get("power", 0))

func consume_sentence_stacks() -> void:
	statuses.erase(&"sentence")
	queue_redraw()

func apply_status(type: StringName, duration: float, power: float) -> bool:
	if not active:
		return false
	if type == &"slow":
		return apply_slow(&"legacy_slow", duration, power)
	var control_type := _control_type_for_status(type)
	if control_type != &"" and _is_control_resisted(control_type):
		_emit_control_result(control_type, false, power, 0.0, duration, 0.0)
		return false
	var resistance_ratio := 1.0 if _is_beneficial_status(type) else (1.0 - runtime_status_resistance)
	var effective_duration := duration * (_control_duration_ratio(control_type) if control_type != &"" else resistance_ratio)
	if effective_duration <= 0.05:
		if control_type != &"":
			_emit_control_result(control_type, false, power, 0.0, duration, 0.0)
		return false
	var effect_ratio := _control_effect_ratio(control_type) if control_type != &"" else resistance_ratio
	var candidate := {"remaining": effective_duration, "power": power * effect_ratio}
	if statuses.has(type) and not _should_replace_status(statuses[type], candidate):
		if control_type != &"":
			_emit_control_result(control_type, false, power, 0.0, duration, 0.0)
		return false
	if type == &"burn" and not statuses.has(type):
		burn_accumulator = 0.0
	statuses[type] = candidate
	trigger_status_visual(type)
	if control_type != &"":
		_emit_control_result(control_type, true, power, power * effect_ratio, duration, effective_duration)
	queue_redraw()
	return true

func apply_slow(source_id: StringName, duration: float, power: float) -> bool:
	if not active or source_id == &"" or duration <= 0.05 or power <= 0.0:
		return false
	var effective_duration := duration * _control_duration_ratio(&"slow")
	var effective_power := power * _control_effect_ratio(&"slow")
	if effective_duration <= 0.05 or effective_power <= 0.0:
		_emit_control_result(&"slow", false, power, 0.0, duration, 0.0)
		return false
	var slow: Dictionary = statuses.get(&"slow", {"sources": {}})
	var sources: Dictionary = slow.get("sources", {})
	var current: Dictionary = sources.get(source_id, {})
	if not current.is_empty() and float(current.get("power", 0.0)) > effective_power + 0.0001:
		_emit_control_result(&"slow", false, power, 0.0, duration, 0.0)
		return false
	sources[source_id] = {
		"remaining": maxf(float(current.get("remaining", 0.0)), effective_duration) if is_equal_approx(float(current.get("power", 0.0)), effective_power) else effective_duration,
		"power": effective_power,
	}
	slow.sources = sources
	statuses[&"slow"] = slow
	_refresh_slow_status()
	trigger_status_visual(&"slow")
	_emit_control_result(&"slow", true, power, effective_power, duration, effective_duration)
	queue_redraw()
	return true

func _refresh_slow_status() -> void:
	if not statuses.has(&"slow"):
		return
	var slow: Dictionary = statuses[&"slow"]
	var sources: Dictionary = slow.get("sources", {})
	if sources.is_empty():
		statuses.erase(&"slow")
		return
	var strongest_power := 0.0
	var strongest_remaining := 0.0
	for source_id in sources:
		var source: Dictionary = sources[source_id]
		var source_power := float(source.get("power", 0.0))
		if source_power > strongest_power + 0.0001 or (is_equal_approx(source_power, strongest_power) and float(source.get("remaining", 0.0)) > strongest_remaining):
			strongest_power = source_power
			strongest_remaining = float(source.get("remaining", 0.0))
	slow.sources = sources
	slow.power = strongest_power
	slow.remaining = strongest_remaining
	statuses[&"slow"] = slow

func _should_replace_status(current: Dictionary, candidate: Dictionary) -> bool:
	var current_power := float(current.get("power", 0.0))
	var candidate_power := float(candidate.get("power", 0.0))
	if candidate_power > current_power + 0.0001:
		return true
	if is_equal_approx(candidate_power, current_power):
		candidate.remaining = maxf(float(current.get("remaining", 0.0)), float(candidate.remaining))
		return float(candidate.remaining) > float(current.get("remaining", 0.0)) + 0.0001
	return false

func _is_beneficial_status(type: StringName) -> bool:
	return type in BENEFICIAL_STATUS_TYPES

func has_negative_status_effect() -> bool:
	if not common_ailments.is_empty():
		return true
	for type in statuses:
		if not _is_beneficial_status(type):
			return true
	return false

func apply_common_poison(damage_per_second: float, duration: float, max_stacks: int) -> bool:
	if not active or damage_per_second <= 0.0 or duration <= 0.0 or max_stacks <= 0:
		return false
	var poison: Dictionary = common_ailments.get(&"poison", {"remaining": 0.0, "stacks": 0, "damage_per_second": damage_per_second})
	poison.stacks = mini(max_stacks, int(poison.get("stacks", 0)) + 1)
	poison.remaining = maxf(float(poison.get("remaining", 0.0)), duration)
	poison.damage_per_second = maxf(float(poison.get("damage_per_second", 0.0)), damage_per_second)
	poison.max_stacks = max_stacks
	common_ailments[&"poison"] = poison
	trigger_status_visual(&"poison")
	queue_redraw()
	return true

func apply_common_burn(source_key: StringName, damage_per_tick: float, duration: float, max_stacks: int, minimum_decay_ratio: float = 0.25, reset_decay_on_reapply: bool = true) -> bool:
	if not active or damage_per_tick <= 0.0 or max_stacks <= 0:
		return false
	var burn: Dictionary = common_ailments.get(&"burn", {"stacks": [], "remaining": 0.0, "duration": duration, "elapsed": 0.0})
	var stacks: Array = burn.get("stacks", [])
	if stacks.size() < max_stacks:
		stacks.append(damage_per_tick)
	else:
		var weakest_index := 0
		for index in range(1, stacks.size()):
			if float(stacks[index]) < float(stacks[weakest_index]):
				weakest_index = index
		if damage_per_tick > float(stacks[weakest_index]):
			stacks[weakest_index] = damage_per_tick
	burn.stacks = stacks
	burn.remaining = maxf(float(burn.get("remaining", 0.0)), duration)
	burn.duration = maxf(float(burn.get("duration", 0.0)), duration)
	if reset_decay_on_reapply:
		burn.elapsed = 0.0
	burn.max_stacks = max_stacks
	burn.minimum_decay_ratio = clampf(minimum_decay_ratio, 0.0, 1.0)
	burn.last_source_type = source_key
	common_ailments[&"burn"] = burn
	trigger_status_visual(&"burn")
	queue_redraw()
	return true

func apply_common_bleed(source_id: StringName, health_ratio: float, duration: float, max_stacks: int, damage_cap: float) -> bool:
	if not active or source_id == &"" or health_ratio <= 0.0 or max_stacks <= 0:
		return false
	var bleed: Dictionary = common_ailments.get(&"bleed", {"sources": {}})
	var sources: Dictionary = bleed.get("sources", {})
	var source: Dictionary = sources.get(source_id, {"stacks": []})
	var stacks: Array = source.get("stacks", [])
	var new_stack := {"remaining": duration, "health_ratio": health_ratio, "damage_cap": damage_cap}
	if stacks.size() < max_stacks:
		stacks.append(new_stack)
	else:
		var oldest_index := 0
		for index in range(1, stacks.size()):
			if float(stacks[index].remaining) < float(stacks[oldest_index].remaining):
				oldest_index = index
		stacks[oldest_index] = new_stack
	source.stacks = stacks
	sources[source_id] = source
	bleed.sources = sources
	common_ailments[&"bleed"] = bleed
	trigger_status_visual(&"bleed")
	queue_redraw()
	return true

func apply_common_shock(duration: float, max_stacks: int) -> int:
	if not active or max_stacks <= 0:
		return 0
	var shock: Dictionary = common_ailments.get(&"shock", {"remaining": 0.0, "stacks": 0})
	shock.remaining = duration
	shock.stacks = mini(max_stacks, int(shock.get("stacks", 0)) + 1)
	common_ailments[&"shock"] = shock
	trigger_status_visual(&"shock")
	queue_redraw()
	return int(shock.stacks)

func has_common_ailment(status_id: StringName) -> bool:
	return common_ailments.has(status_id)

func get_common_ailment_stacks(status_id: StringName) -> int:
	if not common_ailments.has(status_id):
		return 0
	if status_id == &"burn":
		return (common_ailments[status_id].stacks as Array).size()
	if status_id == &"bleed":
		var total := 0
		for source in (common_ailments[status_id].sources as Dictionary).values():
			total += (source.stacks as Array).size()
		return total
	return int(common_ailments[status_id].get("stacks", 0))

func get_common_ailment_source_count(status_id: StringName) -> int:
	if status_id == &"bleed" and common_ailments.has(status_id):
		return (common_ailments[status_id].sources as Dictionary).size()
	return 0

func apply_knockback(distance: float) -> float:
	if not active:
		return 0.0
	if _is_control_resisted(&"knockback"):
		_emit_control_result(&"knockback", false, distance, 0.0, 0.0, 0.0)
		return 0.0
	var outward_direction := target_position.direction_to(position)
	if outward_direction.is_zero_approx():
		outward_direction = Vector2.RIGHT
	var previous_position := position
	var effective_distance := distance * _control_effect_ratio(&"knockback")
	var candidate_position := position + outward_direction * effective_distance
	var candidate_distance := candidate_position.distance_to(target_position)
	var maximum_distance := spawn_distance_limit + MAX_KNOCKBACK_SPAWN_OVERSHOOT
	if candidate_distance > maximum_distance:
		candidate_position = target_position + target_position.direction_to(candidate_position) * maximum_distance
	position = candidate_position
	var displacement_vector := position - previous_position
	var displacement := displacement_vector.length()
	last_knockback_displacement = displacement
	if displacement > 0.0:
		_start_control_recovery(&"knockback")
		knockback_visual_direction = displacement_vector / displacement
		knockback_flash = 1.0
		knockback_visual_distance = maxf(knockback_visual_distance, displacement)
		hit_visual_offset += knockback_visual_direction * minf(displacement * 0.1, 10.0)
		hit_visual_velocity += knockback_visual_direction * minf(90.0 + displacement * 1.2, 240.0)
		queue_redraw()
	_emit_control_result(&"knockback", displacement > 0.0, distance, displacement, 0.0, 0.0)
	return displacement

func apply_forced_movement(destination: Vector2, distance: float, control_type: StringName = &"forced_movement") -> float:
	if not active or distance <= 0.0:
		return 0.0
	if _is_control_resisted(control_type):
		_emit_control_result(control_type, false, distance, 0.0, 0.0, 0.0)
		return 0.0
	var previous_position := global_position
	var effective_distance := distance * _control_effect_ratio(control_type)
	global_position = global_position.move_toward(destination, effective_distance)
	var displacement := global_position.distance_to(previous_position)
	last_knockback_displacement = displacement
	if displacement > 0.0:
		_start_control_recovery(control_type)
		knockback_visual_direction = previous_position.direction_to(global_position)
		knockback_flash = 1.0
		knockback_visual_distance = maxf(knockback_visual_distance, displacement)
		queue_redraw()
	_emit_control_result(control_type, displacement > 0.0, distance, displacement, 0.0, 0.0)
	return displacement

func _emit_control_result(control_type: StringName, accepted: bool, requested_effect: float, effective_effect: float, requested_duration: float, effective_duration: float) -> void:
	control_resolved.emit(self, control_type, accepted, maxf(requested_effect, 0.0), maxf(effective_effect, 0.0), maxf(requested_duration, 0.0), maxf(effective_duration, 0.0))

func _control_profile() -> ControlResistanceProfileData:
	return data.control_resistance_profile if data != null and data.is_boss else null

func _control_effect_ratio(control_type: StringName) -> float:
	var profile := _control_profile()
	if profile == null:
		return 1.0 - runtime_status_resistance if control_type not in [&"knockback", &"gather", &"forced_movement"] else 1.0 - data.knockback_resistance
	return profile.effect_ratio(control_type, runtime_status_resistance, data.knockback_resistance)

func _control_duration_ratio(control_type: StringName) -> float:
	var profile := _control_profile()
	return profile.duration_ratio(control_type, runtime_status_resistance) if profile != null else 1.0 - runtime_status_resistance

func _control_type_for_status(type: StringName) -> StringName:
	if type == &"freeze":
		return &"stun"
	return type if type in [&"slow", &"fear", &"stun"] else &""

func _is_control_resisted(control_type: StringName) -> bool:
	var profile := _control_profile()
	var family := profile.control_family(control_type) if profile != null else (&"displacement" if control_type in [&"knockback", &"gather", &"forced_movement"] else control_type)
	if float(control_recovery_remaining.get(family, 0.0)) > 0.0:
		return true
	if family == &"stun":
		return statuses.has(&"stun") or statuses.has(&"freeze")
	return statuses.has(family) if family in [&"fear", &"charm"] else false

func _start_control_recovery(control_type: StringName) -> void:
	var profile := _control_profile()
	var family := profile.control_family(control_type) if profile != null else (&"displacement" if control_type in [&"knockback", &"gather", &"forced_movement"] else control_type)
	var recovery := profile.recovery_for(control_type) if profile != null else float(DEFAULT_CONTROL_RECOVERY.get(family, 0.0))
	if recovery > 0.0:
		control_recovery_remaining[family] = maxf(float(control_recovery_remaining.get(family, 0.0)), recovery)

func _update_control_recovery(delta: float) -> void:
	var expired: Array[StringName] = []
	for family in control_recovery_remaining:
		control_recovery_remaining[family] = maxf(float(control_recovery_remaining[family]) - delta, 0.0)
		if is_zero_approx(float(control_recovery_remaining[family])):
			expired.append(family)
	for family in expired:
		control_recovery_remaining.erase(family)

func register_hit_feedback(source_position: Vector2, strength: float, profile: StringName, color: Color) -> void:
	var recoil_direction := source_position.direction_to(global_position)
	if recoil_direction.is_zero_approx():
		recoil_direction = Vector2.RIGHT
	hit_feedback_profile = profile
	hit_feedback_color = color
	var feedback_strength := clampf(strength, 0.1, 1.0)
	hit_visual_offset += recoil_direction * (2.0 + feedback_strength * 4.0)
	hit_visual_velocity += recoil_direction * (45.0 + feedback_strength * 95.0)
	hit_flash = maxf(hit_flash, 0.72 + feedback_strength * 0.28)
	hit_pulse = maxf(hit_pulse, 0.62 + feedback_strength * 0.3)
	queue_redraw()

func clear_statuses() -> void:
	if statuses.has(&"charm"):
		charm_immunity_remaining = maxf(charm_immunity_remaining, float(statuses[&"charm"].get("immunity_duration", 0.0)))
	var removed_statuses: Array[StringName] = []
	for type in statuses:
		if not _is_beneficial_status(type):
			removed_statuses.append(type)
	for type in removed_statuses:
		var control_type := &"charm" if type == &"charm" else _control_type_for_status(type)
		if control_type != &"":
			_start_control_recovery(control_type)
		statuses.erase(type)
		status_visual_flashes.erase(type)
	common_ailments.clear()
	for ailment_id in EnemyStatusEffectRenderer.COMMON_AILMENT_IDS:
		status_visual_flashes.erase(ailment_id)
	common_ailment_accumulator = 0.0
	if &"burn" in removed_statuses:
		burn_accumulator = 0.0
	queue_redraw()

func change_vertical_position(new_y: float, new_sector: int) -> void:
	lane_index = new_sector
	position.y = new_y
	target_position.y = new_y
	spawn_distance_limit = maxf(spawn_distance_limit, position.distance_to(target_position))

func stop() -> void:
	active = false

func _physics_process(delta: float) -> void:
	if not active or data == null:
		return
	var status_visuals_changed := _update_status_visual_flashes(delta)
	if not hit_visual_offset.is_zero_approx() or not hit_visual_velocity.is_zero_approx():
		hit_visual_velocity += -hit_visual_offset * 92.0 * delta
		hit_visual_velocity *= exp(-13.0 * delta)
		hit_visual_offset += hit_visual_velocity * delta
		if hit_visual_offset.length_squared() < 0.02 and hit_visual_velocity.length_squared() < 0.2:
			hit_visual_offset = Vector2.ZERO
			hit_visual_velocity = Vector2.ZERO
	if knockback_flash > 0.0:
		knockback_flash = maxf(knockback_flash - delta * 4.2, 0.0)
		knockback_visual_distance = lerpf(knockback_visual_distance, 0.0, clampf(delta * 9.0, 0.0, 1.0))
	if hit_flash > 0.0 or hit_pulse > 0.0 or knockback_flash > 0.0 or not hit_visual_offset.is_zero_approx():
		hit_flash = maxf(hit_flash - delta * 8.5, 0.0)
		hit_pulse = maxf(hit_pulse - delta * 5.5, 0.0)
		queue_redraw()
	if needs_continuous_redraw() or status_visuals_changed:
		queue_redraw()
	if data.behavior in [&"zigzag", &"taunter"]:
		taunt_pulse = fmod(taunt_pulse + delta * (4.8 if data.behavior == &"taunter" else 3.0), TAU)
		queue_redraw()
	charm_immunity_remaining = maxf(charm_immunity_remaining - delta, 0.0)
	acceleration_internal_cooldown = maxf(acceleration_internal_cooldown - delta, 0.0)
	if acceleration_remaining > 0.0:
		acceleration_remaining = maxf(acceleration_remaining - delta, 0.0)
		if acceleration_remaining <= 0.0:
			acceleration_stacks = 0
	group_acceleration_internal_cooldown = maxf(group_acceleration_internal_cooldown - delta, 0.0)
	if group_acceleration_remaining > 0.0:
		group_acceleration_remaining = maxf(group_acceleration_remaining - delta, 0.0)
		if group_acceleration_remaining <= 0.0:
			group_acceleration_stacks = 0
	_update_control_recovery(delta)
	_update_statuses(delta)
	_update_common_ailments(delta)
	_update_self_decay(delta)
	# 지속 피해로 사망한 경우 같은 프레임의 행동과 코어 도달을 중단한다.
	if not active:
		return
	var frozen := statuses.has(&"freeze") or statuses.has(&"stun")
	if not frozen:
		behavior_accumulator += delta
		_handle_behavior()
		charge_remaining = maxf(charge_remaining - delta, 0.0)
	core_breach_cooldown = maxf(core_breach_cooldown - delta, 0.0)
	var slow_power := float(statuses.get(&"slow", {}).get("power", 0.0))
	slow_power = maxf(slow_power, get_fear_slow_power())
	if statuses.has(&"charm") and bool(statuses[&"charm"].get("boss_converted", false)):
		slow_power = maxf(slow_power, float(statuses[&"charm"].get("slow_power", 0.0)))
	var haste_power := float(statuses.get(&"haste", {}).get("power", 0.0))
	var current_speed := data.move_speed * speed_multiplier * (1.0 + haste_power + get_acceleration_speed_bonus() + get_group_acceleration_speed_bonus()) * (1.0 - clampf(slow_power, 0.0, 0.8))
	if data.behavior == &"boss_enrage" and get_health_ratio() < 0.5:
		current_speed *= 1.65
	if data.behavior == &"charger" and charge_remaining > 0.0:
		current_speed *= 2.35
	if data.behavior == &"boss_final" and final_phase == 3:
		current_speed *= 1.75
	if not frozen:
		if data.behavior == &"zigzag":
			zigzag_phase = fmod(zigzag_phase + delta * 4.6, TAU)
			var approach_direction := Vector2.RIGHT if is_charmed() else Vector2.LEFT
			var approach_scale := clampf((get_distance_to_core_face() - 20.0) / 160.0, 0.0, 1.0)
			var weave_strength := sin(zigzag_phase) * 0.62 * approach_scale
			var weave_direction := (approach_direction + approach_direction.orthogonal() * weave_strength).normalized()
			position += weave_direction * current_speed * delta
		else:
			var movement_direction := fixed_movement_direction if not fixed_movement_direction.is_zero_approx() else position.direction_to(target_position)
			if is_charmed():
				movement_direction *= -1.0
			position += movement_direction * current_speed * delta
	var reach_distance := 280.0 if data.behavior == &"ranged" else maxf(data.radius, 18.0)
	if not frozen and not is_charmed() and get_distance_to_core_face() <= reach_distance and core_breach_cooldown <= 0.0:
		if data.is_boss:
			core_breach_cooldown = CombatPace.attack_interval(1.2)
			reached_core.emit(data.core_damage)
		else:
			active = false
			reached_core.emit(data.core_damage)
			queue_free()

func retreat_from_core(distance: float, recovery_time: float = 1.0) -> void:
	if not active:
		return
	var outward_direction := target_position.direction_to(position)
	if outward_direction.is_zero_approx():
		outward_direction = Vector2.RIGHT
	var retreat_position := position + outward_direction * maxf(distance, 0.0)
	var retreat_distance := minf(retreat_position.distance_to(target_position), spawn_distance_limit)
	position = target_position + target_position.direction_to(retreat_position) * retreat_distance
	core_breach_cooldown = maxf(core_breach_cooldown, recovery_time)
	apply_status(&"stun", recovery_time, 1.0)
	queue_redraw()

func _update_statuses(delta: float) -> void:
	var expired: Array[StringName] = []
	var burn_delta := 0.0
	var burn_power := 0.0
	for key in statuses:
		if key == &"slow" and statuses[key].has("sources"):
			var slow_sources: Dictionary = statuses[key].sources
			var expired_slow_sources: Array = []
			for source_id in slow_sources:
				slow_sources[source_id].remaining = float(slow_sources[source_id].remaining) - delta
				if float(slow_sources[source_id].remaining) <= 0.0:
					expired_slow_sources.append(source_id)
			for source_id in expired_slow_sources:
				slow_sources.erase(source_id)
			if slow_sources.is_empty():
				expired.append(key)
			else:
				statuses[key].sources = slow_sources
				_refresh_slow_status()
			continue
		var remaining_before := float(statuses[key].remaining)
		if key == &"burn":
			burn_delta = minf(delta, maxf(remaining_before, 0.0))
			burn_power = float(statuses[key].power)
		statuses[key].remaining -= delta
		if statuses[key].remaining <= 0.0:
			if key == &"charm":
				charm_immunity_remaining = maxf(charm_immunity_remaining, float(statuses[key].get("immunity_duration", 0.0)))
			expired.append(key)
	if burn_delta > 0.0:
		burn_accumulator += burn_delta
		var ticks_this_frame := 0
		while burn_accumulator >= BURN_TICK_SECONDS and ticks_this_frame < MAX_BURN_TICKS_PER_FRAME and active:
			burn_accumulator -= BURN_TICK_SECONDS
			take_damage(burn_power * 3.0, &"burn", true)
			ticks_this_frame += 1
		if ticks_this_frame >= MAX_BURN_TICKS_PER_FRAME:
			burn_accumulator = minf(burn_accumulator, BURN_TICK_SECONDS)
	for key in expired:
		var control_type := &"charm" if key == &"charm" else _control_type_for_status(key)
		if control_type != &"":
			_start_control_recovery(control_type)
		statuses.erase(key)
		if key == &"burn":
			burn_accumulator = 0.0
	if not expired.is_empty():
		queue_redraw()

func _update_common_ailments(delta: float) -> void:
	if common_ailments.is_empty():
		common_ailment_accumulator = 0.0
		return
	var accumulator_before := common_ailment_accumulator
	common_ailment_accumulator += delta
	var tick_time := BURN_TICK_SECONDS - accumulator_before
	var ticks_this_frame := 0
	while common_ailment_accumulator >= BURN_TICK_SECONDS and ticks_this_frame < MAX_BURN_TICKS_PER_FRAME and active:
		common_ailment_accumulator -= BURN_TICK_SECONDS
		if common_ailments.has(&"poison"):
			var poison: Dictionary = common_ailments[&"poison"]
			if float(poison.remaining) + 0.0001 >= tick_time:
				var poison_damage := float(poison.damage_per_second) * int(poison.stacks) * BURN_TICK_SECONDS
				if poison_damage > 0.0:
					take_damage(poison_damage, &"common_poison", true)
		if active and common_ailments.has(&"burn"):
			var burn: Dictionary = common_ailments[&"burn"]
			var burn_damage := 0.0
			if float(burn.remaining) + 0.0001 >= tick_time:
				var elapsed_at_tick := maxf(float(burn.elapsed) + tick_time - BURN_TICK_SECONDS, 0.0)
				var decay_progress := clampf(elapsed_at_tick / maxf(float(burn.duration), BURN_TICK_SECONDS), 0.0, 1.0)
				var decay_ratio := lerpf(1.0, float(burn.minimum_decay_ratio), decay_progress)
				for stack_damage in burn.stacks as Array:
					burn_damage += float(stack_damage) * decay_ratio
			if burn_damage > 0.0:
				take_damage(burn_damage, &"common_burn", true)
		if active and common_ailments.has(&"bleed"):
			var bleed_data: Dictionary = common_ailments[&"bleed"]
			var bleed_damage := 0.0
			for source in (bleed_data.sources as Dictionary).values():
				var source_damage := 0.0
				var source_cap := 0.0
				for stack_data in source.stacks as Array:
					if float(stack_data.remaining) + 0.0001 >= tick_time:
						source_damage += get_max_health() * float(stack_data.health_ratio)
						source_cap = maxf(source_cap, float(stack_data.damage_cap))
				bleed_damage += minf(source_damage, source_cap) if source_cap > 0.0 else source_damage
			if bleed_damage > 0.0:
				take_damage(bleed_damage, &"common_bleed", true)
		ticks_this_frame += 1
		tick_time += BURN_TICK_SECONDS
	if ticks_this_frame >= MAX_BURN_TICKS_PER_FRAME:
		common_ailment_accumulator = minf(common_ailment_accumulator, BURN_TICK_SECONDS)
	if common_ailments.has(&"poison"):
		var poison: Dictionary = common_ailments[&"poison"]
		poison.remaining = float(poison.remaining) - delta
		if float(poison.remaining) <= 0.0:
			common_ailments.erase(&"poison")
		else:
			common_ailments[&"poison"] = poison
	if common_ailments.has(&"burn"):
		var burn: Dictionary = common_ailments[&"burn"]
		burn.remaining = float(burn.remaining) - delta
		burn.elapsed = float(burn.elapsed) + delta
		if float(burn.remaining) <= 0.0:
			common_ailments.erase(&"burn")
		else:
			common_ailments[&"burn"] = burn
	if common_ailments.has(&"bleed"):
		var bleed: Dictionary = common_ailments[&"bleed"]
		var sources: Dictionary = bleed.sources
		var expired_sources: Array = []
		for source_id in sources:
			var source: Dictionary = sources[source_id]
			var stacks: Array = source.stacks
			for index in range(stacks.size() - 1, -1, -1):
				stacks[index].remaining = float(stacks[index].remaining) - delta
				if float(stacks[index].remaining) <= 0.0:
					stacks.remove_at(index)
			if stacks.is_empty():
				expired_sources.append(source_id)
			else:
				source.stacks = stacks
				sources[source_id] = source
		for source_id in expired_sources:
			sources.erase(source_id)
		if sources.is_empty():
			common_ailments.erase(&"bleed")
		else:
			bleed.sources = sources
			common_ailments[&"bleed"] = bleed
	if common_ailments.has(&"shock"):
		var shock: Dictionary = common_ailments[&"shock"]
		shock.remaining = float(shock.remaining) - delta
		if float(shock.remaining) <= 0.0:
			common_ailments.erase(&"shock")
		else:
			common_ailments[&"shock"] = shock
	if common_ailments.is_empty():
		common_ailment_accumulator = 0.0
	queue_redraw()

func _handle_behavior() -> void:
	if data.behavior == &"shifter" and behavior_accumulator >= 5.0:
		behavior_accumulator = 0.0
		special_action.emit(&"shift_position", self)
	elif data.behavior == &"cleanser" and behavior_accumulator >= 4.0:
		behavior_accumulator = 0.0
		clear_statuses()
		special_action.emit(&"cleanse_area", self)
	elif data.behavior == &"support" and behavior_accumulator >= 3.0:
		behavior_accumulator = 0.0
		special_action.emit(&"support_buff", self)
	elif data.behavior == &"regenerator" and behavior_accumulator >= 2.5:
		behavior_accumulator = 0.0
		current_health = minf(current_health + get_max_health() * 0.08, get_max_health())
		queue_redraw()
	elif data.behavior == &"charger" and behavior_accumulator >= 4.2:
		behavior_accumulator = 0.0
		charge_remaining = 0.9
		queue_redraw()
	elif data.behavior == &"phase" and behavior_accumulator >= 2.4:
		behavior_accumulator = 0.0
		phase_active = not phase_active
		queue_redraw()
	elif data.behavior == &"guardian" and behavior_accumulator >= 4.0:
		behavior_accumulator = 0.0
		special_action.emit(&"fortify_area", self)
	elif data.behavior in [&"disruptor", &"sapper", &"boss_disrupt", &"boss_summon", &"boss_final"] and behavior_accumulator >= (9.0 if data.behavior == &"boss_final" else (7.0 if data.is_boss else (6.0 if data.behavior == &"sapper" else 9.0))):
		behavior_accumulator = 0.0
		special_action.emit(&"disable_column", self)
		if data.behavior in [&"boss_summon", &"boss_final"]:
			special_action.emit(&"summon", self)

func _update_boss_phase() -> void:
	if data == null or data.behavior != &"boss_final":
		return
	var next_phase := 3 if get_health_ratio() <= 0.33 else (2 if get_health_ratio() <= 0.66 else 1)
	if next_phase != final_phase:
		final_phase = next_phase
		if final_phase == 2:
			special_action.emit(&"disable_column", self)
		elif final_phase == 3:
			runtime_status_resistance = minf(runtime_status_resistance + 0.2, 0.9)

func _update_self_decay(delta: float) -> void:
	if not active or data == null or data.decay_profile == null:
		return
	var health_loss := data.decay_profile.get_health_loss_per_second(get_max_health()) * maxf(delta, 0.0)
	if health_loss <= 0.0:
		return
	current_health = maxf(current_health - health_loss, 0.0)
	last_damage_context = null
	queue_redraw()
	if is_zero_approx(current_health):
		_die(DEATH_CAUSE_SELF_DECAY)

func _die(death_cause: StringName = DEATH_CAUSE_DIRECT_KILL) -> void:
	if not active:
		return
	last_death_cause = death_cause
	var defeated_while_charmed := has_charm_effect()
	active = false
	if defeated_while_charmed:
		charmed_defeated.emit(global_position, data)
	died.emit(data.experience_value * experience_multiplier * challenge_experience_multiplier, global_position, data, lane_index)
	queue_free()

func _draw_campaign_faction_marker(radius: float) -> void:
	var dark := Color(0.015, 0.025, 0.045, 0.9)
	var primary := Color(campaign_primary_color, 0.96)
	var secondary := Color(campaign_secondary_color, 0.96)
	var active_style := ElectionFactionData.normalized_marker_style(campaign_marker_style)
	match active_style:
		&"sword_shield":
			var shield := PackedVector2Array([
				Vector2(-radius * 0.82, -radius * 0.7), Vector2(radius * 0.82, -radius * 0.7),
				Vector2(radius * 0.7, radius * 0.25), Vector2(0.0, radius + 6.0),
				Vector2(-radius * 0.7, radius * 0.25), Vector2(-radius * 0.82, -radius * 0.7),
			])
			draw_polyline(shield, dark, 5.4, true)
			draw_polyline(shield, primary, 2.3, true)
			draw_line(Vector2(-radius * 0.78, radius * 0.76), Vector2(radius * 0.82, -radius * 0.82), dark, 5.2, true)
			draw_line(Vector2(-radius * 0.78, radius * 0.76), Vector2(radius * 0.82, -radius * 0.82), secondary, 2.2, true)
		&"heart":
			var heart := PackedVector2Array([
				Vector2(0.0, radius + 6.0), Vector2(-radius - 4.0, radius * 0.08),
				Vector2(-radius * 0.78, -radius * 0.72), Vector2(-radius * 0.24, -radius * 0.9),
				Vector2.ZERO, Vector2(radius * 0.24, -radius * 0.9),
				Vector2(radius * 0.78, -radius * 0.72), Vector2(radius + 4.0, radius * 0.08),
				Vector2(0.0, radius + 6.0),
			])
			draw_polyline(heart, dark, 5.4, true)
			draw_polyline(heart, primary, 2.3, true)
			draw_line(Vector2(-radius * 0.52, radius * 0.22), Vector2(radius * 0.52, radius * 0.22), secondary, 2.2, true)
		&"tentacle_eye":
			draw_arc(Vector2.ZERO, radius + 4.0, -2.68, -0.46, 18, dark, 5.2, true)
			draw_arc(Vector2.ZERO, radius + 4.0, 0.46, 2.68, 18, dark, 5.2, true)
			draw_arc(Vector2.ZERO, radius + 4.0, -2.68, -0.46, 18, primary, 2.2, true)
			draw_arc(Vector2.ZERO, radius + 4.0, 0.46, 2.68, 18, primary, 2.2, true)
			draw_circle(Vector2.ZERO, 4.8, dark)
			draw_circle(Vector2.ZERO, 2.6, secondary)
			for offset in [-0.55, 0.0, 0.55]:
				var start := Vector2(radius * float(offset), radius * 0.82)
				var finish := Vector2(radius * float(offset + 0.14), radius + 8.0)
				draw_line(start, finish, dark, 5.0, true)
				draw_line(start, finish, secondary, 2.0, true)
		&"skull_aura":
			draw_arc(Vector2(0.0, -radius * 0.1), radius + 2.0, PI, TAU, 20, dark, 5.2, true)
			draw_arc(Vector2(0.0, -radius * 0.1), radius + 2.0, PI, TAU, 20, primary, 2.2, true)
			for x in [-0.46, 0.0, 0.46]:
				var start := Vector2(radius * float(x), radius * 0.62)
				var finish := Vector2(radius * float(x), radius + 6.0)
				draw_line(start, finish, dark, 5.0, true)
				draw_line(start, finish, secondary, 2.0, true)
			for angle in [-2.7, -1.9, -1.25, -0.44]:
				var center := Vector2.from_angle(float(angle)) * (radius + 5.0)
				draw_circle(center, 3.3, dark)
				draw_circle(center, 1.7, secondary)
		&"scythe_blood":
			draw_arc(Vector2(radius * 0.08, -radius * 0.05), radius + 3.0, -2.72, 0.48, 24, dark, 5.4, true)
			draw_arc(Vector2(radius * 0.08, -radius * 0.05), radius + 3.0, -2.72, 0.48, 24, primary, 2.3, true)
			draw_line(Vector2(radius * 0.7, -radius * 0.82), Vector2(-radius * 0.6, radius + 5.0), dark, 5.2, true)
			draw_line(Vector2(radius * 0.7, -radius * 0.82), Vector2(-radius * 0.6, radius + 5.0), secondary, 2.2, true)
			for point in [Vector2(radius * 0.72, radius * 0.55), Vector2(radius + 5.0, radius * 0.22)]:
				draw_circle(point, 3.4, dark)
				draw_circle(point, 1.8, primary)
		_:
			draw_arc(Vector2.ZERO, radius, -2.75, -1.25, 18, primary, 2.4, true)
			draw_arc(Vector2.ZERO, radius, 0.38, 1.88, 18, secondary, 2.4, true)

func _draw_campaign_character_texture(texture: Texture2D, rect: Rect2, modulate: Color) -> void:
	var should_flip_h := campaign_character_art != null and campaign_character_art_flip_h
	if not should_flip_h:
		draw_texture_rect(texture, rect, false, modulate)
		return
	var mirrored_rect := Rect2(Vector2(-rect.position.x - rect.size.x, rect.position.y), rect.size)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))
	draw_texture_rect(texture, mirrored_rect, false, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw() -> void:
	if data == null:
		return
	var health_ratio := get_health_ratio()
	draw_set_transform(Vector2(0.0, data.radius * 0.72), 0.0, Vector2(1.25, 0.34))
	draw_circle(Vector2.ZERO, data.radius * 0.9, Color(0.0, 0.0, 0.0, 0.38))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var pulse_scale := 1.0 + hit_pulse * 0.08
	var affiliation_color := campaign_primary_color if campaign_faction_id != &"" else data.body_color
	draw_circle(Vector2.ZERO, (data.radius + 5.0) * pulse_scale, Color(affiliation_color, 0.2 + hit_flash * 0.18))
	if campaign_faction_id != &"":
		_draw_campaign_faction_marker(data.radius + 5.0)
	var impact_scale := Vector2.ONE
	match hit_feedback_profile:
		&"rapid": impact_scale = Vector2(1.0 + hit_pulse * 0.08, 1.0 - hit_pulse * 0.05)
		&"area": impact_scale = Vector2.ONE * (1.0 + hit_pulse * 0.09)
		&"pierce": impact_scale = Vector2(1.0 - hit_pulse * 0.04, 1.0 + hit_pulse * 0.1)
		&"slow": impact_scale = Vector2.ONE * (1.0 - hit_pulse * 0.035)
		&"knockback": impact_scale = Vector2(1.0 + hit_pulse * 0.13, 1.0 - hit_pulse * 0.09)
		&"execute": impact_scale = Vector2(1.0 - hit_pulse * 0.08, 1.0 + hit_pulse * 0.13)
		&"chain": impact_scale = Vector2(1.0 + hit_pulse * 0.04, 1.0 - hit_pulse * 0.04)
	var texture_size := Vector2.ONE * data.radius * (4.15 if data.is_boss else 3.75) * pulse_scale * impact_scale
	var base_tint := Color.WHITE.lerp(campaign_primary_color, 0.16) if campaign_faction_id != &"" else Color.WHITE.lerp(data.body_color, 0.04)
	var tint := base_tint.lerp(hit_feedback_color.lightened(0.35), hit_flash * 0.72)
	if data.behavior == &"phase" and phase_active:
		tint.a = 0.58 + hit_flash * 0.42
	var art_texture := campaign_character_art if campaign_character_art != null else (data.texture if data.texture != null else ConceptService.fallback_texture(&"enemies"))
	var hop_offset := Vector2(0.0, -absf(sin(zigzag_phase)) * 7.0) if data.behavior == &"zigzag" else Vector2.ZERO
	if knockback_flash > 0.0:
		var trail_offset := -knockback_visual_direction * clampf(8.0 + knockback_visual_distance * 0.16, 8.0, 28.0)
		var ghost_tint := Color(hit_feedback_color, knockback_flash * 0.17)
		_draw_campaign_character_texture(art_texture, Rect2(-texture_size * 0.5 + hop_offset + trail_offset, texture_size), ghost_tint)
	if art_texture != null:
		_draw_campaign_character_texture(art_texture, Rect2(-texture_size * 0.5 + hop_offset + hit_visual_offset, texture_size), tint)
	EnemyStatusEffectRenderer.draw_knockback(self, data.radius, knockback_visual_direction, knockback_flash, knockback_visual_distance)
	if campaign_elite and campaign_emblem != null:
		var emblem_size := clampf(data.radius * 0.72, 14.0, 28.0)
		var emblem_center := Vector2(data.radius * 0.72, data.radius * 0.72)
		draw_circle(emblem_center, emblem_size * 0.56, Color(0.02, 0.04, 0.07, 0.82))
		draw_texture_rect(campaign_emblem, Rect2(emblem_center - Vector2.ONE * emblem_size * 0.5, Vector2.ONE * emblem_size), false, Color.WHITE)
	if spawn_context != null and spawn_context.is_artifact_elite():
		var artifact_pulse := sin(Time.get_ticks_msec() * 0.006) * 0.5 + 0.5
		var artifact_radius := data.radius + 10.0 + artifact_pulse * 3.0
		draw_arc(Vector2.ZERO, artifact_radius, 0.0, TAU, 32, Color("ffd86a", 0.82), 3.5, true)
		draw_arc(Vector2.ZERO, artifact_radius + 5.0, -1.1, 0.15, 12, Color("fff4bd", 0.9), 2.0, true)
		draw_string(ThemeDB.fallback_font, Vector2(-12.0, -data.radius - 22.0), "◆%d" % spawn_context.artifact_reward_tier, HORIZONTAL_ALIGNMENT_CENTER, 24.0, 12, Color("fff0a6"))
	if data.behavior == &"zigzag":
		var trail_color := Color(data.body_color, 0.78)
		for trail_index in 3:
			var trail_x := data.radius + 9.0 + trail_index * 9.0
			var trail_y := sin(zigzag_phase - trail_index * 0.72) * 8.0
			draw_polyline(PackedVector2Array([Vector2(trail_x, trail_y - 6.0), Vector2(trail_x - 7.0, trail_y), Vector2(trail_x, trail_y + 6.0)]), Color(trail_color, 0.78 - trail_index * 0.18), 2.0)
	elif data.behavior == &"taunter":
		var pulse_radius := data.radius + 8.0 + (sin(taunt_pulse) * 0.5 + 0.5) * 9.0
		draw_arc(Vector2.ZERO, pulse_radius, 0.0, TAU, 32, Color(data.body_color, 0.72), 2.5)
		draw_arc(Vector2.ZERO, data.radius + 5.0, -taunt_pulse, -taunt_pulse + PI * 0.72, 16, Color.WHITE, 2.0)
	EnemyStatusEffectRenderer.draw_persistent(
		self,
		data.radius,
		statuses,
		common_ailments,
		status_visual_flashes,
		Time.get_ticks_msec() * 0.001
	)
	var bar_width := data.radius * 2.4
	var health_color := Color("ff5f70").lerp(Color("65e09e"), health_ratio)
	var bar_position := Vector2(-bar_width * 0.5, -data.radius - 12.0)
	draw_rect(Rect2(bar_position, Vector2(bar_width, 6.0)), Color("331c25"), true)
	if execute_threshold_ratio > 0.0:
		draw_rect(Rect2(bar_position, Vector2(bar_width * execute_threshold_ratio, 6.0)), Color("7f1d35", 0.9), true)
	draw_rect(Rect2(bar_position, Vector2(bar_width * health_ratio, 6.0)), health_color, true)
	if execute_threshold_ratio > 0.0:
		var threshold_x := bar_position.x + bar_width * execute_threshold_ratio
		draw_line(Vector2(threshold_x, bar_position.y - 2.0), Vector2(threshold_x, bar_position.y + 8.0), Color("ffe3ea"), 1.8, true)
		if health_ratio <= execute_threshold_ratio:
			var execute_pulse := sin(Time.get_ticks_msec() * 0.012) * 0.5 + 0.5
			draw_arc(Vector2.ZERO, data.radius + 7.0 + execute_pulse * 3.0, -0.55, 0.55, 12, Color("ff5f70", 0.72 + execute_pulse * 0.28), 3.0, true)
			draw_string(ThemeDB.fallback_font, Vector2(-18.0, -data.radius - 17.0), "처형", HORIZONTAL_ALIGNMENT_CENTER, 36.0, 11, Color("ffdce4"))
	if hit_flash > 0.0:
		draw_arc(Vector2.ZERO, data.radius + 8.0 + hit_pulse * 8.0, 0.0, TAU, 28, Color.WHITE, 1.0 + hit_flash * 2.0)
	if barrier_health > 0.0:
		var barrier_ratio := barrier_health / maxf(barrier_max, 1.0)
		draw_arc(Vector2.ZERO, data.radius + 8.0, -PI * 0.75, -PI * 0.75 + TAU * barrier_ratio, 32, Color("65eaff"), 3.5)
	if charge_remaining > 0.0:
		draw_arc(Vector2.ZERO, data.radius + 7.0, -0.8, 0.8, 12, Color("ff725a"), 4.0)
	if data.is_boss:
		draw_arc(Vector2.ZERO, data.radius + 10.0, 0.0, TAU, 32, Color("ffcf58"), 3.0)
