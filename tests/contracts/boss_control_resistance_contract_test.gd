class_name BossControlResistanceContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var boss_data := EnemyData.new()
	boss_data.id = &"control_contract_boss"
	boss_data.is_boss = true
	boss_data.max_health = 100.0
	boss_data.move_speed = 0.0
	boss_data.status_resistance = 0.5
	boss_data.knockback_resistance = 0.6
	boss_data.control_resistance_profile = ControlResistanceProfileData.new()
	var boss := Enemy.new()
	boss.setup(boss_data, Vector2(200.0, 100.0), 0, Vector2.ZERO, 1.0, 1.0)
	_expect(boss.apply_status(&"stun", 2.0, 1.0), "a boss must receive a reduced first stun", failures)
	_expect(float(boss.statuses.get(&"stun", {}).get("remaining", 0.0)) < 2.0, "boss control duration must be reduced", failures)
	_expect(not boss.apply_status(&"stun", 2.0, 1.0), "same-family stun must be resisted while the first effect is active", failures)
	boss._update_control_recovery(2.0)
	_expect(not boss.apply_status(&"stun", 2.0, 1.0), "advancing recovery alone must not bypass an active stun", failures)
	boss._update_statuses(1.0)
	_expect(float(boss.control_recovery_remaining.get(&"stun", 0.0)) > 0.0, "stun recovery must begin after the effect expires", failures)
	_expect(not boss.apply_status(&"stun", 2.0, 1.0), "same-family stun must be resisted during post-effect recovery", failures)
	boss._update_control_recovery(1.4)
	_expect(boss.apply_status(&"stun", 2.0, 1.0), "stun must become applicable after post-effect recovery", failures)
	var first_displacement := boss.apply_knockback(100.0)
	var second_displacement := boss.apply_forced_movement(Vector2.ZERO, 100.0, &"gather")
	_expect(first_displacement > 0.0 and first_displacement < 100.0, "boss knockback must contribute partially", failures)
	_expect(is_zero_approx(second_displacement), "knockback and gather must share displacement recovery", failures)
	boss._update_control_recovery(2.0)
	_expect(boss.apply_forced_movement(Vector2.ZERO, 100.0, &"gather") > 0.0, "forced movement must return after displacement recovery", failures)
	boss.free()
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
