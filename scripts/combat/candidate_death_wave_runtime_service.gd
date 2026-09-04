class_name CandidateDeathWaveRuntimeService
extends RefCounted

var _resolving_hit: bool = false
var _curse_spirit_generated: bool = false
var _pending_post_wave_window: float = 0.0

func arm_post_wave_window(duration: float) -> void:
	_pending_post_wave_window = maxf(duration, 0.0)

func resolve_hit(
		game_finished: bool,
		enemy: Enemy,
		damage: float,
		spirit_gain: int,
		spirit_damage_multiplier: float,
		damage_callback: Callable,
		damage_settled_callback: Callable,
		add_charges_callback: Callable
	) -> Dictionary:
	var result := _empty_hit_result()
	if game_finished or not is_instance_valid(enemy) or not enemy.active or not damage_callback.is_valid() or not add_charges_callback.is_valid():
		return result
	var hit_position := enemy.global_position
	_curse_spirit_generated = false
	_resolving_hit = true
	var dealt := float(damage_callback.call(enemy, damage))
	_resolving_hit = false
	result.resolved = true
	result.damage = dealt
	result.hit_position = hit_position
	result.target_defeated = not enemy.active
	result.curse_spirit_generated = _curse_spirit_generated
	if damage_settled_callback.is_valid():
		damage_settled_callback.call(dealt)
	if bool(result.target_defeated):
		result.reason = &"target_defeated"
		result.requested_spirit_gain = maxi(spirit_gain - (1 if _curse_spirit_generated else 0), 0)
		result.generated_spirit_gain = maxi(int(add_charges_callback.call(
			int(result.requested_spirit_gain),
			hit_position,
			spirit_damage_multiplier
		)), 0)
	else:
		result.reason = &"target_survived"
	_clear_hit_state()
	return result

func mark_curse_spirit_generated() -> bool:
	if not _resolving_hit:
		return false
	_curse_spirit_generated = true
	return true

func is_resolving_hit() -> bool:
	return _resolving_hit

func finish(begin_active_window_callback: Callable) -> Dictionary:
	var post_wave_window := _pending_post_wave_window
	_pending_post_wave_window = 0.0
	var active_window_started := false
	if post_wave_window > 0.0 and begin_active_window_callback.is_valid():
		begin_active_window_callback.call(post_wave_window)
		active_window_started = true
	return {
		"post_wave_window": post_wave_window,
		"active_window_started": active_window_started,
	}

func reset() -> void:
	_clear_hit_state()
	_pending_post_wave_window = 0.0

func pending_post_wave_window() -> float:
	return _pending_post_wave_window

func _clear_hit_state() -> void:
	_resolving_hit = false
	_curse_spirit_generated = false

func _empty_hit_result() -> Dictionary:
	return {
		"resolved": false,
		"reason": &"invalid_request",
		"damage": 0.0,
		"hit_position": Vector2.ZERO,
		"target_defeated": false,
		"curse_spirit_generated": false,
		"requested_spirit_gain": 0,
		"generated_spirit_gain": 0,
	}
