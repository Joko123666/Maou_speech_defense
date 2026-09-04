class_name CoreHitExecutionService
extends RefCounted

var judgment_service := JudgmentService.new()

func execute(
		enemy: Enemy,
		damage: float,
		source_type: StringName,
		core_data: CoreData,
		modifiers: Dictionary,
		guaranteed_charm: bool = false,
		sentence_stacks: int = 1,
		charm_duration_bonus_seconds: float = 0.0,
		execution_overrides: Dictionary = {},
		candidate_modifier_callback: Callable = Callable(),
		charm_roll_callback: Callable = Callable()
	) -> Dictionary:
	var result := {
		"applied": false,
		"route": &"",
		"damage": 0.0,
		"effective_damage": 0.0,
		"boss_target": false,
		"judgment": {},
		"execution_position": Vector2.ZERO,
		"charm_attempted": false,
		"charm_applied": false,
		"charm_duration_multiplier": 0.0,
		"charm_vulnerability": 0.0,
	}
	if not is_instance_valid(enemy) or not enemy.active or enemy.data == null or core_data == null:
		return result
	result.applied = true
	result.boss_target = enemy.data.is_boss
	result.effective_damage = damage * (float(modifiers.get("boss_damage", 1.0)) if enemy.data.is_boss else 1.0)
	if core_data.judgment_profile != null:
		_execute_judgment(enemy, source_type, core_data, modifiers, sentence_stacks, execution_overrides, result)
	else:
		_execute_standard(enemy, source_type, core_data, guaranteed_charm, charm_duration_bonus_seconds, candidate_modifier_callback, charm_roll_callback, result)
	return result

func _execute_judgment(
		enemy: Enemy,
		source_type: StringName,
		core_data: CoreData,
		modifiers: Dictionary,
		sentence_stacks: int,
		execution_overrides: Dictionary,
		result: Dictionary
	) -> void:
	result.route = &"judgment"
	result.execution_position = enemy.global_position
	var execute_ratio := maxf(core_data.judgment_profile.execute_health_ratio, float(modifiers.get("execute_ratio", 0.0)))
	var judgment := judgment_service.resolve(
		enemy,
		float(result.effective_damage),
		source_type,
		execute_ratio,
		core_data.judgment_profile,
		sentence_stacks,
		execution_overrides
	)
	result.judgment = judgment
	result.damage = float(judgment.damage)

func _execute_standard(
		enemy: Enemy,
		source_type: StringName,
		core_data: CoreData,
		guaranteed_charm: bool,
		charm_duration_bonus_seconds: float,
		candidate_modifier_callback: Callable,
		charm_roll_callback: Callable,
		result: Dictionary
	) -> void:
	result.route = &"standard"
	result.damage = enemy.take_damage(float(result.effective_damage), source_type)
	if core_data.charm_profile == null or not enemy.active:
		return
	result.charm_attempted = true
	var should_charm := guaranteed_charm
	if not should_charm:
		var roll := float(charm_roll_callback.call()) if charm_roll_callback.is_valid() else RunRng.roll()
		should_charm = roll <= core_data.charm_profile.application_chance
	var duration_multiplier := float(candidate_modifier_callback.call(&"charm_duration", 1.0)) if candidate_modifier_callback.is_valid() else 1.0
	duration_multiplier += maxf(charm_duration_bonus_seconds, 0.0) / maxf(core_data.charm_profile.duration, 0.1)
	var charm_vulnerability := float(candidate_modifier_callback.call(&"charm_vulnerability", 0.0)) if candidate_modifier_callback.is_valid() else 0.0
	result.charm_duration_multiplier = duration_multiplier
	result.charm_vulnerability = charm_vulnerability
	if should_charm:
		result.charm_applied = enemy.apply_charm(core_data.charm_profile, duration_multiplier, charm_vulnerability)
