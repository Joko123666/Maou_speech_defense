class_name PerformanceBudgetContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	_expect(CombatEffectBudget.active_limit(1.0) == 64 and CombatEffectBudget.active_limit(2.0) == 52 and CombatEffectBudget.active_limit(3.0) == 40, "effect density limits must tighten at 2x and 3x speed", failures)
	_expect(CombatEffectBudget.can_spawn(23, 3.0, CombatEffectBudget.Priority.MINOR) and not CombatEffectBudget.can_spawn(24, 3.0, CombatEffectBudget.Priority.MINOR), "3x minor hit effects must yield at the reserved 24-effect boundary", failures)
	_expect(CombatEffectBudget.can_spawn(39, 3.0, CombatEffectBudget.Priority.IMPORTANT) and not CombatEffectBudget.can_spawn(40, 3.0, CombatEffectBudget.Priority.IMPORTANT), "important effects must retain the full 3x presentation budget", failures)
	_expect(CombatEffectBudget.can_spawn(79, 3.0, CombatEffectBudget.Priority.CRITICAL) and not CombatEffectBudget.can_spawn(80, 1.0, CombatEffectBudget.Priority.CRITICAL), "critical core casts must use a separate bounded emergency reserve", failures)
	_expect(CombatEffectBudget.priority_for_intensity(0.2) == CombatEffectBudget.Priority.MINOR and CombatEffectBudget.priority_for_intensity(0.6) == CombatEffectBudget.Priority.STANDARD and CombatEffectBudget.priority_for_intensity(1.0) == CombatEffectBudget.Priority.IMPORTANT, "effect intensity must map deterministically to visual priority", failures)
	var healthy := RuntimePerformanceBudget.assess({
		"frame_count": 1000, "average_frame_ms": 12.0, "over_33_ms_ratio": 0.001,
		"peak_active_enemies": 90, "peak_projectiles": 70, "peak_effects": 42,
		"peak_summons": 10, "peak_summon_budget_cost": 12,
	})
	_expect(bool(healthy.passed) and (healthy.violations as Array).is_empty(), "a measured run inside every provisional mobile budget must pass", failures)
	var overloaded := RuntimePerformanceBudget.assess({
		"frame_count": 1000, "average_frame_ms": 38.0, "over_33_ms_ratio": 0.04,
		"peak_active_enemies": 181, "peak_projectiles": 161, "peak_effects": 49,
		"peak_summons": 13, "peak_summon_budget_cost": 13,
	})
	_expect(not bool(overloaded.passed) and (overloaded.violations as Array).size() == 7, "performance assessment must report every exceeded frame, scene-density, and summon budget", failures)
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
