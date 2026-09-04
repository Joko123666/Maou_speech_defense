class_name CombatModifierResolverContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var additive_forward := CombatModifierResolver.additive_multiplier([1.20, 1.15, 0.90])
	var additive_reverse := CombatModifierResolver.additive_multiplier([0.90, 1.15, 1.20])
	_expect(is_equal_approx(additive_forward, 1.25) and is_equal_approx(additive_forward, additive_reverse), "attack-speed sources must combine additively and independently of application order", failures)

	var below_soft_cap := CombatModifierResolver.resolve_attack_speed([1.35, 1.25])
	var above_soft_cap := CombatModifierResolver.resolve_attack_speed([1.60, 1.50])
	_expect(is_equal_approx(below_soft_cap, 1.60), "attack speed below the soft cap must preserve its additive value", failures)
	_expect(is_equal_approx(above_soft_cap, 1.8375) and above_soft_cap > CombatModifierResolver.ATTACK_SPEED_SOFT_CAP and above_soft_cap < 2.10, "attack speed above x1.75 must retain only one quarter of overflow", failures)

	var global_permanent_cap := CombatModifierResolver.resolve_permanent_attack_speed_bonus(0.80, 0.50)
	var local_permanent_cap := CombatModifierResolver.resolve_permanent_attack_speed_bonus(0.80, 0.15)
	_expect(is_equal_approx(global_permanent_cap, 0.30) and is_equal_approx(local_permanent_cap, 0.15), "run-permanent attack speed must honor both the shared +30% cap and stricter local caps", failures)

	var normal_amplification := CombatModifierResolver.resolve_damage_amplification([0.35, 0.45, 0.50], false)
	var normal_reverse := CombatModifierResolver.resolve_damage_amplification([0.50, 0.45, 0.35], false)
	var boss_amplification := CombatModifierResolver.resolve_damage_amplification([0.35, 0.45, 0.50], true)
	_expect(is_equal_approx(normal_amplification, 1.0) and is_equal_approx(normal_amplification, normal_reverse), "normal-enemy damage amplification must add by source and cap at +100% regardless of order", failures)
	_expect(is_equal_approx(boss_amplification, 0.60), "boss damage amplification must use its separate +60% cap", failures)
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
