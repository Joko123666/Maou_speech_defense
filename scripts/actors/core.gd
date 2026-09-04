class_name DefenseCore
extends Node2D

const MAX_ATTACKS_PER_FRAME := 8

signal health_changed(current: float, maximum: float)
signal destroyed
signal attack_requested(core_data: CoreData)
signal skill_charge_changed(current: float, maximum: float)
signal skill_cast_started(core_data: CoreData, duration: float)
signal skill_cast_changed(remaining: float, total: float)
signal skill_requested(core_data: CoreData)

var data: CoreData
var max_health: float = 100.0
var current_health: float = 100.0
var attack_accumulator: float = 0.0
var skill_charge: float = 0.0
var skill_cast_remaining: float = 0.0
var skill_cast_total: float = 0.0
var damage_multiplier: float = 1.0
var regeneration_multiplier: float = 1.0
var skill_charge_multiplier: float = 1.0
var attack_speed_multiplier: float = 1.0
var active: bool = false
var damage_flash: float = 0.0
var action_pulse: float = 0.0
var release_pulse: float = 0.0
var combat_character_texture: Texture2D
var presentation_color: Color = Color("53d5a5")

func configure(core_data: CoreData, health_multiplier: float = 1.0) -> void:
	data = core_data
	max_health = data.max_health * health_multiplier
	current_health = max_health
	attack_accumulator = data.attack_interval
	skill_charge = 0.0
	skill_cast_remaining = 0.0
	skill_cast_total = 0.0
	release_pulse = 0.0
	combat_character_texture = null
	presentation_color = data.color
	var campaign := ConceptService.get_election_campaign()
	if campaign != null:
		var candidate := campaign.candidate_for_core(data.id)
		if candidate != null:
			combat_character_texture = ConceptService.optional_content_texture(&"candidate_sd", candidate.id)
			var faction := campaign.faction(candidate.faction_id)
			if faction != null:
				presentation_color = faction.primary_color
				var runtime_data := core_data.duplicate(false) as CoreData
				if runtime_data != null:
					runtime_data.color = presentation_color
					data = runtime_data
	active = true
	health_changed.emit(current_health, max_health)
	skill_charge_changed.emit(skill_charge, data.skill_charge_seconds)
	queue_redraw()

func take_damage(amount: float) -> void:
	if current_health <= 0.0:
		return
	current_health = maxf(current_health - maxf(amount, 0.0), 0.0)
	damage_flash = 1.0
	action_pulse = maxf(action_pulse, 0.72)
	health_changed.emit(current_health, max_health)
	queue_redraw()
	if is_zero_approx(current_health):
		active = false
		destroyed.emit()

func heal(amount: float) -> void:
	if not active or current_health >= max_health:
		return
	current_health = minf(current_health + maxf(amount, 0.0), max_health)
	health_changed.emit(current_health, max_health)
	queue_redraw()

func apply_runtime(damage_value: float, health_value: float, regeneration_value: float, charge_value: float, attack_speed_value: float = 1.0) -> void:
	var ratio := current_health / max_health
	max_health = data.max_health * health_value
	current_health = max_health * ratio
	damage_multiplier = damage_value
	regeneration_multiplier = regeneration_value
	skill_charge_multiplier = charge_value
	attack_speed_multiplier = CombatModifierResolver.resolve_attack_speed([attack_speed_value])
	health_changed.emit(current_health, max_health)

func activate_skill() -> bool:
	if data == null or skill_charge < data.skill_charge_seconds or not active or is_skill_casting():
		return false
	skill_charge = 0.0
	skill_cast_total = maxf(data.skill_cast_seconds, 0.05)
	skill_cast_remaining = skill_cast_total
	action_pulse = 1.0
	skill_charge_changed.emit(skill_charge, data.skill_charge_seconds)
	skill_cast_started.emit(data, skill_cast_total)
	skill_cast_changed.emit(skill_cast_remaining, skill_cast_total)
	queue_redraw()
	return true

func is_skill_casting() -> bool:
	return skill_cast_remaining > 0.0

func add_skill_charge(seconds: float) -> void:
	if not active or data == null or is_skill_casting():
		return
	skill_charge = minf(skill_charge + maxf(seconds, 0.0), data.skill_charge_seconds)
	skill_charge_changed.emit(skill_charge, data.skill_charge_seconds)

func stop() -> void:
	active = false
	skill_cast_remaining = 0.0

func _physics_process(delta: float) -> void:
	if damage_flash > 0.0 or action_pulse > 0.0 or release_pulse > 0.0:
		damage_flash = maxf(damage_flash - delta * 4.8, 0.0)
		action_pulse = maxf(action_pulse - delta * 2.7, 0.0)
		release_pulse = maxf(release_pulse - delta * 3.6, 0.0)
		queue_redraw()
	if not active or data == null:
		return
	var attack_interval := data.attack_interval / maxf(attack_speed_multiplier, 0.01)
	var attacks_this_frame := 0
	var attack_suppressed := data.suppress_basic_attack_during_skill_cast and is_skill_casting()
	if not attack_suppressed:
		attack_accumulator += delta
		while attack_accumulator >= attack_interval and attacks_this_frame < MAX_ATTACKS_PER_FRAME:
			attack_accumulator -= attack_interval
			action_pulse = maxf(action_pulse, 0.38)
			attack_requested.emit(data)
			attacks_this_frame += 1
		if attacks_this_frame >= MAX_ATTACKS_PER_FRAME:
			attack_accumulator = minf(attack_accumulator, attack_interval)
	if data.regeneration > 0.0:
		heal(data.regeneration * regeneration_multiplier * delta)
	if skill_cast_remaining > 0.0:
		skill_cast_remaining = maxf(skill_cast_remaining - delta, 0.0)
		action_pulse = maxf(action_pulse, 0.82)
		skill_cast_changed.emit(skill_cast_remaining, skill_cast_total)
		queue_redraw()
		if is_zero_approx(skill_cast_remaining):
			release_pulse = 1.0
			skill_requested.emit(data)
		return
	skill_charge = minf(skill_charge + delta * skill_charge_multiplier, data.skill_charge_seconds)
	skill_charge_changed.emit(skill_charge, data.skill_charge_seconds)

func _draw() -> void:
	var health_ratio := current_health / max_health if max_health > 0.0 else 0.0
	var core_color := presentation_color if data != null else Color("53d5a5")
	var glow_color := core_color.lerp(Color("ef5a68"), 1.0 - health_ratio)
	draw_set_transform(Vector2(0.0, 42.0), 0.0, Vector2(1.35, 0.34))
	draw_circle(Vector2.ZERO, 48.0, Color(0.0, 0.0, 0.0, 0.42))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var pulse_radius := 52.0 + action_pulse * 15.0
	draw_circle(Vector2.ZERO, pulse_radius, Color(glow_color, 0.22 + action_pulse * 0.08))
	if action_pulse > 0.0:
		draw_arc(Vector2.ZERO, 60.0 + (1.0 - action_pulse) * 24.0, 0.0, TAU, 40, Color(core_color, action_pulse * 0.72), 2.5)
	var cast_progress := 0.0
	if skill_cast_remaining > 0.0:
		cast_progress = 1.0 - skill_cast_remaining / maxf(skill_cast_total, 0.01)
		var cast_rotation := Time.get_ticks_msec() * 0.004
		for ring_index in 3:
			var ring_radius := 72.0 + ring_index * 10.0 - cast_progress * (12.0 + ring_index * 2.0)
			var arc_start := cast_rotation * (1.0 if ring_index % 2 == 0 else -1.0) + ring_index * 0.7
			draw_arc(Vector2.ZERO, ring_radius, arc_start, arc_start + PI * (1.05 + cast_progress * 0.72), 32, Color(core_color.lightened(0.18 * ring_index), 0.34 + cast_progress * 0.56), 2.0 + cast_progress * 2.0, true)
		draw_circle(Vector2.ZERO, 18.0 + cast_progress * 22.0, Color(core_color.lightened(0.55), 0.08 + cast_progress * 0.24))
	var texture_tint := Color.WHITE.lerp(Color("ff7c86"), damage_flash * 0.72)
	var texture_scale := 1.0 + damage_flash * 0.07
	var texture_size := Vector2(146.0, 146.0) * texture_scale
	var art_texture := data.texture if data != null and data.texture != null else ConceptService.fallback_texture(&"cores")
	if art_texture != null:
		var motion_id := data.skill_type if data != null and (cast_progress > 0.0 or release_pulse > 0.0) else (data.attack_type if data != null else &"")
		var pose := CombatMotionProfile.core_pose(motion_id, cast_progress, action_pulse if cast_progress <= 0.0 else 0.0, release_pulse, Time.get_ticks_msec() * 0.0024)
		draw_set_transform(pose.offset, float(pose.rotation), pose.scale)
		if combat_character_texture != null:
			var foundation_tint := Color(texture_tint, 0.3)
			draw_texture_rect(art_texture, Rect2(-texture_size * 0.5, texture_size), false, foundation_tint)
			var character_size := Vector2(132.0, 132.0)
			draw_texture_rect(combat_character_texture, Rect2(Vector2(-58.0, -68.0), character_size), false, texture_tint)
		else:
			draw_texture_rect(art_texture, Rect2(-texture_size * 0.5, texture_size), false, texture_tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_arc(Vector2.ZERO, 55.0, -PI / 2.0, -PI / 2.0 + TAU * health_ratio, 48, glow_color, 6.0)
	if health_ratio < 0.3:
		var warning_alpha := 0.45 + sin(Time.get_ticks_msec() * 0.012) * 0.25
		draw_arc(Vector2.ZERO, 63.0, 0.0, TAU, 40, Color("ff5366", warning_alpha), 3.0)
