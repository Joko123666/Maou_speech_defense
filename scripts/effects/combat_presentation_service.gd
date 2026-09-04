class_name CombatPresentationService
extends RefCounted

var effect_container: Node2D
var metrics: RunMetrics

func configure(container: Node2D, run_metrics: RunMetrics = null) -> void:
	effect_container = container
	metrics = run_metrics

func is_configured() -> bool:
	return is_instance_valid(effect_container)

func create_effect(priority: int) -> CombatEffect:
	if not is_configured():
		return null
	var speed := maxf(Engine.time_scale, 1.0)
	# 1×는 기존 연출 밀도를 유지하고, 생성 빈도가 급증하는 2×/3×에서만 예약 예산을 적용한다.
	var allowed := speed < 1.5 or CombatEffectBudget.can_spawn(CombatEffect.active_effects, speed, priority)
	if is_instance_valid(metrics):
		metrics.record_effect_budget(CombatEffectBudget.priority_name(priority), allowed)
	if not allowed:
		return null
	var effect := CombatEffect.new()
	effect_container.add_child(effect)
	return effect

func show_trace(from: Vector2, to: Vector2, color: Color, radius: float = 0.0, intensity: float = 0.2, priority: int = -1) -> void:
	var effect := create_effect(_resolved_priority(intensity, priority))
	if effect != null:
		effect.setup(from, to, color, radius, intensity)

func show_impact(at: Vector2, color: Color, radius: float = 0.0, intensity: float = 0.25, priority: int = -1) -> void:
	var effect := create_effect(_resolved_priority(intensity, priority))
	if effect != null:
		effect.setup_impact(at, color, radius, intensity)

func present_tower_hit(tower: TowerData, target: Enemy, source_position: Vector2, damage: float, strength_scale: float = 1.0) -> Dictionary:
	if tower == null or not is_instance_valid(target):
		return {}
	var profile := TowerHitPresentationProfile.build(tower, target.get_max_health(), damage, strength_scale)
	var hit_position := target.global_position
	if CombatEffect.active_tower_hits < CombatEffect.MAX_ACTIVE_TOWER_HITS:
		var effect := create_effect(CombatEffectBudget.Priority.MINOR)
		if effect != null:
			effect.setup_tower_hit(hit_position, profile.color, profile.behavior, source_position.direction_to(hit_position), profile.strength, profile.radius)
	target.register_hit_feedback(source_position, profile.strength, profile.behavior, profile.color)
	return profile

func show_burst(at: Vector2, color: Color, radius: float = 110.0, intensity: float = 0.8, priority: int = -1) -> void:
	var effect := create_effect(_resolved_priority(intensity, priority))
	if effect != null:
		effect.setup_burst(at, color, radius, intensity)

func show_pattern(at: Vector2, color: Color, radius: float, style: StringName, intensity: float = 0.6, duration: float = 0.55, priority: int = -1) -> void:
	var effect := create_effect(_resolved_priority(intensity, priority))
	if effect != null:
		effect.setup_pattern(at, color, radius, style, intensity, duration)

func show_candidate_stamp(at: Vector2, effect_id: StringName, color: Color, radius: float, style: StringName, intensity: float = 0.8, duration: float = 0.6) -> void:
	var texture := ConceptService.optional_content_texture(&"effects", effect_id)
	if texture == null:
		return
	var effect := create_effect(CombatEffectBudget.Priority.IMPORTANT)
	if effect != null:
		effect.setup_candidate_stamp(at, texture, color, radius, style, intensity, duration)

func show_chain(points: Array[Vector2], color: Color, intensity: float = 0.65, priority: int = -1) -> void:
	if points.size() < 2:
		return
	var effect := create_effect(_resolved_priority(intensity, priority))
	if effect != null:
		effect.setup_chain(points, color, intensity)

func show_target_impacts(targets: Array[Enemy], color: Color, intensity: float, limit: int = 8) -> void:
	for index in mini(targets.size(), limit):
		var target := targets[index]
		if is_instance_valid(target):
			show_impact(target.global_position, color, 0.0, intensity)

func _resolved_priority(intensity: float, priority: int) -> int:
	return CombatEffectBudget.priority_for_intensity(intensity) if priority < 0 else priority
