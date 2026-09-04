class_name NecromancyController
extends Node2D

const SUMMON_OWNER_ID: StringName = &"irelai_spirit"
const MAXIMUM_CURSE_GENERATION := 3

signal charges_changed(current: int, maximum: int)
signal spirits_generated(position: Vector2, count: int)
signal summon_expired(position: Vector2, damage: float)

var source_node: Node2D
var profile: NecromancyProfileData
var summon_service: SummonService
var charges: int = 0
var maximum_charges: int = 0
var normal_defeat_chance: float = 0.0
var spirit_damage_multiplier: float = 1.0
var maximum_simultaneous_summons: int = 0
var charge_origins: Array[Vector2] = []
var charge_damage_multipliers: Array[float] = []
var charge_curse_generations: Array[int] = []
var active_summons: Array[Dictionary] = []
var next_summon_id: int = 1
var summon_duration_multiplier: float = 1.0
var post_active_chance_bonus: float = 0.0
var post_active_bonus_remaining: float = 0.0
var soul_stacks: int = 0
var maximum_soul_stacks: int = 0
var active_summon_lifetimes: Array[float]:
	get:
		var result: Array[float] = []
		for summon in active_summons:
			result.append(float(summon.get("remaining", 0.0)))
		return result

func setup(source: Node2D, data: NecromancyProfileData, shared_summon_service: SummonService = null) -> void:
	source_node = source
	profile = data
	summon_service = shared_summon_service
	z_index = 7
	apply_modifiers({})
	queue_redraw()

func apply_modifiers(modifiers: Dictionary) -> void:
	if profile == null:
		return
	maximum_charges = maxi(1, profile.maximum_charges + int(modifiers.get("spirit_capacity_bonus", 0)))
	normal_defeat_chance = clampf(profile.normal_defeat_chance + float(modifiers.get("spirit_gain_chance_bonus", 0.0)), 0.0, 1.0)
	spirit_damage_multiplier = profile.spirit_damage_multiplier * float(modifiers.get("spirit_damage", 1.0))
	maximum_simultaneous_summons = maxi(1, profile.maximum_simultaneous_summons + int(modifiers.get("spirit_simultaneous_bonus", 0)))
	summon_duration_multiplier = maxf(float(modifiers.get("spirit_duration", 1.0)), 0.1)
	post_active_chance_bonus = maxf(float(modifiers.get("post_active_spirit_chance_bonus", 0.0)), 0.0)
	charges = mini(charges, maximum_charges)
	while charge_origins.size() > charges:
		charge_origins.pop_front()
	while charge_damage_multipliers.size() > charges:
		charge_damage_multipliers.pop_front()
	while charge_curse_generations.size() > charges:
		charge_curse_generations.pop_front()
	charges_changed.emit(charges, maximum_charges)
	queue_redraw()

func record_defeat(enemy_data: EnemyData, defeat_position: Vector2 = Vector2.INF, roll_override: float = -1.0, boss_gain_override: int = -1) -> int:
	if profile == null or enemy_data == null or charges >= maximum_charges:
		return 0
	var gain := 0
	if enemy_data.is_boss:
		if boss_gain_override >= 0:
			gain = boss_gain_override
		else:
			var boss_roll := roll_override if roll_override >= 0.0 else RunRng.roll()
			gain = profile.boss_charge_gain_minimum if boss_roll < 0.5 else profile.boss_charge_gain_maximum
	elif enemy_data.id in profile.elite_enemy_ids:
		gain = profile.elite_charge_gain
	else:
		var roll := roll_override if roll_override >= 0.0 else RunRng.roll()
		if roll <= clampf(normal_defeat_chance + (post_active_chance_bonus if post_active_bonus_remaining > 0.0 else 0.0), 0.0, 1.0):
			gain = 1
	return add_charges(gain, defeat_position)

func add_charges(amount: int, origin: Vector2 = Vector2.INF, damage_multiplier: float = 1.0, curse_generation: int = 0) -> int:
	if amount <= 0 or maximum_charges <= 0:
		return 0
	var before := charges
	charges = mini(maximum_charges, charges + amount)
	var gained := charges - before
	if gained > 0:
		for _index in gained:
			charge_origins.append(origin)
			charge_damage_multipliers.append(maxf(damage_multiplier, 0.0))
			charge_curse_generations.append(clampi(curse_generation, 0, MAXIMUM_CURSE_GENERATION))
		charges_changed.emit(charges, maximum_charges)
		if origin.is_finite():
			spirits_generated.emit(origin, gained)
		queue_redraw()
	return gained

func add_guaranteed_charge(origin: Vector2 = Vector2.INF, damage_multiplier: float = 1.0, curse_generation: int = 0) -> bool:
	if maximum_charges <= 0:
		return false
	if charges < maximum_charges:
		return add_charges(1, origin, damage_multiplier, curse_generation) == 1
	while charge_origins.size() < charges:
		charge_origins.append(Vector2.INF)
	while charge_damage_multipliers.size() < charges:
		charge_damage_multipliers.append(1.0)
	while charge_curse_generations.size() < charges:
		charge_curse_generations.append(0)
	var replace_index := maxi(charges - 1, 0)
	charge_origins[replace_index] = origin
	charge_damage_multipliers[replace_index] = maxf(damage_multiplier, 0.0)
	charge_curse_generations[replace_index] = clampi(curse_generation, 0, MAXIMUM_CURSE_GENERATION)
	if origin.is_finite():
		spirits_generated.emit(origin, 1)
	queue_redraw()
	return true

func request_summon_entries(requested: int, fallback_origin: Vector2 = Vector2.ZERO) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if profile == null or requested <= 0 or charges <= 0:
		return result
	var release_attempts := mini(requested, charges)
	for _index in release_attempts:
		if active_summons.size() >= maximum_simultaneous_summons:
			break
		var curse_generation := int(charge_curse_generations.front()) if not charge_curse_generations.is_empty() else 0
		var budget_token := 0
		if summon_service != null:
			var tokens := summon_service.request_slots(SUMMON_OWNER_ID, 1, maximum_simultaneous_summons, curse_generation, MAXIMUM_CURSE_GENERATION, 1, &"necromancy_charge")
			if tokens.is_empty():
				break
			budget_token = tokens[0]
		charges -= 1
		var stored_origin: Vector2 = charge_origins.pop_front() if not charge_origins.is_empty() else Vector2.INF
		var release_origin: Vector2 = fallback_origin if not stored_origin.is_finite() else stored_origin
		var damage_multiplier: float = charge_damage_multipliers.pop_front() if not charge_damage_multipliers.is_empty() else 1.0
		if not charge_curse_generations.is_empty():
			charge_curse_generations.pop_front()
		var summon := {
			"id": next_summon_id,
			"remaining": profile.summon_visual_duration * summon_duration_multiplier,
			"position": release_origin,
			"damage": 0.0,
			"damage_multiplier": damage_multiplier,
			"curse_generation": curse_generation,
			"owner_id": SUMMON_OWNER_ID,
			"source_id": &"necromancy_charge",
			"budget_token": budget_token,
		}
		next_summon_id += 1
		active_summons.append(summon)
		result.append(summon.duplicate(true))
	charges_changed.emit(charges, maximum_charges)
	queue_redraw()
	return result

func clear_active_summons(emit_expiration: bool = false) -> void:
	for summon_value in active_summons.duplicate():
		var summon: Dictionary = summon_value
		if summon_service != null:
			summon_service.release_slot(int(summon.get("budget_token", 0)))
		if emit_expiration:
			var expire_position: Vector2 = summon.get("position", Vector2.INF)
			if expire_position.is_finite():
				summon_expired.emit(expire_position, float(summon.get("damage", 0.0)))
	active_summons.clear()
	queue_redraw()

func request_summons(requested: int, fallback_origin: Vector2 = Vector2.ZERO) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for entry in request_summon_entries(requested, fallback_origin):
		var release_position: Vector2 = entry.get("position", fallback_origin)
		result.append(release_position)
	return result

func update_active_summon(summon_id: int, position: Vector2, damage: float) -> void:
	for summon in active_summons:
		if int(summon.get("id", -1)) == summon_id:
			summon["position"] = position
			summon["damage"] = maxf(damage, 0.0)
			return

func begin_active_window(duration: float) -> void:
	post_active_bonus_remaining = maxf(duration, 0.0)

func set_soul_display(current: int, maximum: int) -> void:
	soul_stacks = maxi(current, 0)
	maximum_soul_stacks = maxi(maximum, 0)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if source_node != null and is_instance_valid(source_node):
		global_position = source_node.global_position
	post_active_bonus_remaining = maxf(post_active_bonus_remaining - delta, 0.0)
	for index in range(active_summons.size() - 1, -1, -1):
		var summon := active_summons[index]
		summon["remaining"] = float(summon.get("remaining", 0.0)) - delta
		if float(summon.remaining) <= 0.0:
			var expire_position: Vector2 = summon.get("position", Vector2.INF)
			var expire_damage := float(summon.get("damage", 0.0))
			if summon_service != null:
				summon_service.release_slot(int(summon.get("budget_token", 0)))
			active_summons.remove_at(index)
			if expire_position.is_finite():
				summon_expired.emit(expire_position, expire_damage)
	if charges > 0 or not active_summons.is_empty() or soul_stacks > 0:
		queue_redraw()

func _exit_tree() -> void:
	clear_active_summons(false)

func _draw() -> void:
	if profile == null or maximum_charges <= 0:
		return
	var phase := Time.get_ticks_msec() * 0.0022
	var orbit_radius := 62.0
	for index in maximum_charges:
		var angle := phase + TAU * float(index) / float(maximum_charges)
		var spirit_position := Vector2.from_angle(angle) * orbit_radius
		var filled := index < charges
		var spirit_color := Color("a8ffcf", 0.92 if filled else 0.16)
		draw_circle(spirit_position, 5.5 if filled else 3.5, spirit_color)
		draw_arc(spirit_position, 8.0, -2.7, -0.45, 10, Color(spirit_color, spirit_color.a * 0.82), 2.0, true)
		if filled:
			draw_circle(spirit_position + Vector2(-2.0, -1.0), 1.0, Color("153b35"))
			draw_circle(spirit_position + Vector2(2.0, -1.0), 1.0, Color("153b35"))
	if charges > 0:
		draw_string(ThemeDB.fallback_font, Vector2(-28.0, -72.0), "사령 %d/%d" % [charges, maximum_charges], HORIZONTAL_ALIGNMENT_CENTER, 56.0, 11, Color("caffdf"))
	if maximum_soul_stacks > 0:
		draw_string(ThemeDB.fallback_font, Vector2(-38.0, -88.0), "영혼 %d/%d" % [soul_stacks, maximum_soul_stacks], HORIZONTAL_ALIGNMENT_CENTER, 76.0, 11, Color("e7d7ff"))
