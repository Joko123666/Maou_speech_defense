class_name JudgmentService
extends RefCounted

var shared_execution_profile := ExecutionProfileData.new()

func resolve(
	enemy: Enemy,
	attack_damage: float,
	source_type: StringName,
	execute_ratio: float,
	profile: JudgmentProfileData = null,
	sentence_stacks: int = 0,
	execution_overrides: Dictionary = {},
	damage_context: EnemyDamageContext = null
) -> Dictionary:
	var result := {
		"damage": 0.0,
		"executed": false,
		"verdict_triggered": false,
		"sentence_stacks": 0,
		"execute_threshold": 0.0,
		"boss_execution_damage": 0.0,
	}
	if enemy == null or not enemy.active:
		return result

	var stack_triggered := false
	if profile != null and sentence_stacks > 0:
		var stack_count := enemy.add_sentence_stacks(sentence_stacks, profile.sentence_duration)
		result.sentence_stacks = stack_count
		stack_triggered = stack_count >= profile.required_sentence_stacks
	var execution_profile := profile.execution_profile if profile != null and profile.execution_profile != null else shared_execution_profile
	var threshold := execution_profile.threshold_for(enemy.data, execute_ratio, execution_overrides)
	result.execute_threshold = threshold
	var health_triggered := threshold > 0.0 and enemy.get_health_ratio() <= threshold
	var verdict_triggered := stack_triggered or health_triggered
	result.verdict_triggered = verdict_triggered

	if enemy.data.is_boss:
		result.damage = enemy.take_damage(attack_damage, source_type, false, damage_context)
		if verdict_triggered and enemy.active:
			var boss_ratio := execution_profile.boss_damage_ratio(execution_overrides)
			# 레거시 판결 프로필의 직접 수치도 더 큰 쪽으로 보존한다.
			if profile != null:
				boss_ratio = maxf(boss_ratio, profile.boss_fixed_health_ratio * float(execution_overrides.get(&"execute_boss_damage_multiplier", 1.0)))
			var boss_execution_damage := enemy.take_fixed_damage(enemy.get_max_health() * boss_ratio, &"judgment_fixed")
			result.damage += boss_execution_damage
			result.boss_execution_damage = boss_execution_damage
			enemy.consume_sentence_stacks()
		return result

	if verdict_triggered:
		result.damage = enemy.take_fixed_damage(enemy.current_health + enemy.barrier_health, &"judgment_execute", damage_context)
		result.executed = true
		return result

	result.damage = enemy.take_damage(attack_damage, source_type, false, damage_context)
	return result

func threshold_for(enemy: Enemy, execute_ratio: float, profile: JudgmentProfileData = null, execution_overrides: Dictionary = {}) -> float:
	if enemy == null or enemy.data == null:
		return 0.0
	var execution_profile := profile.execution_profile if profile != null and profile.execution_profile != null else shared_execution_profile
	return execution_profile.threshold_for(enemy.data, execute_ratio, execution_overrides)

func resolve_forced_non_boss_execution(enemy: Enemy, source_type: StringName = &"judgment_execute") -> Dictionary:
	var result := {
		"damage": 0.0,
		"executed": false,
		"verdict_triggered": false,
		"sentence_stacks": 0,
		"execute_threshold": 0.0,
		"boss_execution_damage": 0.0,
	}
	if enemy == null or not enemy.active or enemy.data == null or enemy.data.is_boss:
		return result
	result.damage = enemy.take_fixed_damage(enemy.current_health + enemy.barrier_health, source_type)
	result.executed = true
	result.verdict_triggered = true
	result.execute_threshold = 1.0
	return result
