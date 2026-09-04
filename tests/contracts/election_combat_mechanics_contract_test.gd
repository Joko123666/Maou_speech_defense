class_name ElectionCombatMechanicsContractTest
extends RefCounted

static func run(host: Node) -> Array[String]:
	var failures: Array[String] = []
	var sapphire := DataRegistry.get_core(&"sapphire")
	var obsidian := DataRegistry.get_core(&"obsidian")
	_expect(sapphire.charm_profile != null and sapphire.charm_profile.get_validation_errors().is_empty(), "Sapphire must expose a valid data-driven charm profile", failures)
	_expect(obsidian.judgment_profile != null and obsidian.judgment_profile.get_validation_errors().is_empty(), "Obsidian must expose a valid data-driven judgment profile", failures)
	_expect(obsidian.judgment_profile.execution_profile.execute_threshold_elite < obsidian.judgment_profile.execution_profile.execute_threshold_normal and obsidian.judgment_profile.execution_profile.execute_boss_damage > 0.0, "the shared execution contract must separate normal, elite, and non-lethal boss values", failures)
	var title_probe := GameController.new()
	_expect(title_probe._core_skill_title(obsidian) == "사신 소환", "Obsidian must expose Judaginda's Reaper active instead of inheriting Emerald's beam display title", failures)
	title_probe.free()

	var charm_enemy := Enemy.new()
	host.add_child(charm_enemy)
	charm_enemy.set_process(false)
	charm_enemy.set_physics_process(false)
	charm_enemy.setup(DataRegistry.get_enemy(&"normal"), Vector2(500.0, 300.0), 0, Vector2(100.0, 300.0), 10.0, 1.0)
	var charm_start_x := charm_enemy.position.x
	_expect(charm_enemy.apply_charm(sapphire.charm_profile) and charm_enemy.is_charmed(), "charm must activate on a normal enemy", failures)
	var unamplified_health := charm_enemy.current_health
	charm_enemy.take_damage(10.0, &"core")
	var unamplified_damage := unamplified_health - charm_enemy.current_health
	charm_enemy.statuses.erase(&"charm")
	charm_enemy.charm_immunity_remaining = 0.0
	_expect(charm_enemy.apply_charm(sapphire.charm_profile, 1.35, 0.35), "candidate growth must be able to apply extended vulnerable charm", failures)
	var amplified_health := charm_enemy.current_health
	charm_enemy.take_damage(10.0, &"core")
	_expect(amplified_health - charm_enemy.current_health > unamplified_damage * 1.3, "vulnerable charm must amplify normal-enemy damage independently from boss conversion", failures)
	charm_enemy.statuses[&"mark"] = {"remaining": 5.0, "power": 0.80}
	_expect(is_equal_approx(charm_enemy.get_damage_amplification(), 1.0), "mark and charm vulnerability must add into the shared +100% normal-enemy amplification cap", failures)
	var capped_health := charm_enemy.current_health
	charm_enemy.take_damage(10.0, &"core")
	_expect(is_equal_approx(capped_health - charm_enemy.current_health, 20.0), "the normal-enemy amplification cap must be applied once at the final damage boundary", failures)
	var fixed_health := charm_enemy.current_health
	charm_enemy.take_fixed_damage(10.0)
	_expect(is_equal_approx(fixed_health - charm_enemy.current_health, 10.0), "fixed damage must continue to bypass damage amplification", failures)
	charm_enemy.statuses.erase(&"mark")
	charm_enemy._physics_process(0.2)
	_expect(charm_enemy.position.x > charm_start_x, "normal charm must reverse only the enemy movement direction", failures)
	var before_knockback := charm_enemy.position.x
	var knockback_distance := charm_enemy.apply_knockback(30.0)
	_expect(knockback_distance > 0.0 and charm_enemy.position.x > before_knockback and charm_enemy.is_charmed(), "knockback displacement must remain independent while charm is active", failures)
	_expect(not charm_enemy.apply_charm(sapphire.charm_profile), "active charm must reject continuous reapplication", failures)
	charm_enemy._update_statuses(sapphire.charm_profile.duration * 1.35 + 0.2)
	_expect(not charm_enemy.is_charmed() and charm_enemy.is_charm_immune() and not charm_enemy.apply_charm(sapphire.charm_profile), "expired charm must grant its data-driven reapplication immunity", failures)
	charm_enemy.charm_immunity_remaining = 0.0
	_expect(charm_enemy.apply_charm(sapphire.charm_profile), "charm must become applicable again after immunity ends", failures)
	charm_enemy.active = false
	charm_enemy.queue_free()

	var charm_boss := Enemy.new()
	host.add_child(charm_boss)
	charm_boss.set_process(false)
	charm_boss.set_physics_process(false)
	charm_boss.setup(DataRegistry.bosses[0], Vector2(600.0, 300.0), 0, Vector2(100.0, 300.0), 1.0, 1.0)
	var boss_start_x := charm_boss.position.x
	_expect(charm_boss.apply_charm(sapphire.charm_profile) and charm_boss.has_charm_effect() and not charm_boss.is_charmed(), "boss charm must convert instead of reversing movement", failures)
	var converted_charm: Dictionary = charm_boss.statuses.get(&"charm", {})
	_expect(float(converted_charm.get("slow_power", 0.0)) > 0.0 and float(converted_charm.get("vulnerability", 0.0)) > 0.0, "boss charm must expose resistance-scaled slow and vulnerability values", failures)
	charm_boss.statuses[&"mark"] = {"remaining": 5.0, "power": 1.0}
	_expect(is_equal_approx(charm_boss.get_damage_amplification(), 0.60), "boss mark and converted charm must share the separate +60% amplification cap", failures)
	charm_boss._physics_process(0.2)
	_expect(charm_boss.position.x < boss_start_x, "a charmed boss must continue toward the core under converted slow", failures)
	charm_boss.active = false
	charm_boss.queue_free()

	var charm_exit_probe := Enemy.new()
	host.add_child(charm_exit_probe)
	charm_exit_probe.set_process(false)
	charm_exit_probe.set_physics_process(false)
	charm_exit_probe.setup(DataRegistry.get_enemy(&"normal"), Vector2(420.0, 280.0), 0, Vector2(100.0, 280.0), 1.0, 1.0)
	var charmed_exit_emitted := [false]
	charm_exit_probe.charmed_defeated.connect(func(_position: Vector2, _data: EnemyData) -> void: charmed_exit_emitted[0] = true)
	charm_exit_probe.apply_charm(sapphire.charm_profile)
	charm_exit_probe.take_damage(charm_exit_probe.current_health + 1.0, &"core")
	_expect(bool(charmed_exit_emitted[0]), "a charmed enemy defeat must emit the dedicated non-boss echo source signal before removal", failures)

	var judgment := JudgmentService.new()
	var judgment_enemy := Enemy.new()
	host.add_child(judgment_enemy)
	judgment_enemy.set_process(false)
	judgment_enemy.set_physics_process(false)
	judgment_enemy.setup(DataRegistry.get_enemy(&"armored"), Vector2(500.0, 340.0), 0, Vector2(100.0, 340.0), 20.0, 1.0)
	var normal_first := judgment.resolve(judgment_enemy, 1.0, &"judgment_test", obsidian.judgment_profile.execute_health_ratio, obsidian.judgment_profile, 1)
	var normal_second := judgment.resolve(judgment_enemy, 1.0, &"judgment_test", obsidian.judgment_profile.execute_health_ratio, obsidian.judgment_profile, 1)
	var normal_third := judgment.resolve(judgment_enemy, 1.0, &"judgment_test", obsidian.judgment_profile.execute_health_ratio, obsidian.judgment_profile, 1)
	_expect(not bool(normal_first.verdict_triggered) and not bool(normal_second.verdict_triggered) and bool(normal_third.executed) and not judgment_enemy.active, "three sentence stacks must execute a normal enemy through the shared judgment service", failures)

	var threshold_enemy := Enemy.new()
	host.add_child(threshold_enemy)
	threshold_enemy.set_process(false)
	threshold_enemy.set_physics_process(false)
	threshold_enemy.setup(DataRegistry.get_enemy(&"armored"), Vector2(500.0, 380.0), 0, Vector2(100.0, 380.0), 20.0, 1.0)
	threshold_enemy.current_health = threshold_enemy.get_max_health() * 0.05
	var threshold_result := judgment.resolve(threshold_enemy, 1.0, &"execute", 0.10)
	_expect(bool(threshold_result.executed) and not threshold_enemy.active, "the ordinary execute tower threshold must use the same judgment service", failures)

	var elite_threshold_enemy := Enemy.new()
	host.add_child(elite_threshold_enemy)
	elite_threshold_enemy.set_process(false)
	elite_threshold_enemy.set_physics_process(false)
	elite_threshold_enemy.setup(DataRegistry.get_enemy(&"steel_golem"), Vector2(500.0, 395.0), 0, Vector2(100.0, 395.0), 20.0, 1.0)
	elite_threshold_enemy.current_health = elite_threshold_enemy.get_max_health() * 0.09
	var elite_threshold_result := judgment.resolve(elite_threshold_enemy, 1.0, &"execute", 0.12)
	_expect(not bool(elite_threshold_result.executed) and elite_threshold_enemy.active and float(elite_threshold_result.execute_threshold) < 0.09, "elite execution must use its lower shared threshold instead of the normal-enemy threshold", failures)
	elite_threshold_enemy.active = false
	elite_threshold_enemy.queue_free()
	var sudden_death_enemy := Enemy.new()
	host.add_child(sudden_death_enemy)
	sudden_death_enemy.set_process(false)
	sudden_death_enemy.set_physics_process(false)
	sudden_death_enemy.setup(DataRegistry.get_enemy(&"normal"), Vector2(520.0, 395.0), 0, Vector2(100.0, 395.0), 20.0, 1.0)
	var forced_execution := judgment.resolve_forced_non_boss_execution(sudden_death_enemy, &"guard_sudden_death")
	_expect(bool(forced_execution.executed) and bool(forced_execution.verdict_triggered) and not sudden_death_enemy.active, "a successful sudden-death roll must route through the shared forced non-boss execution contract", failures)

	var fear_enemy := Enemy.new()
	host.add_child(fear_enemy)
	fear_enemy.set_process(false)
	fear_enemy.set_physics_process(false)
	fear_enemy.setup(DataRegistry.get_enemy(&"normal"), Vector2(520.0, 405.0), 0, Vector2(100.0, 405.0), 10.0, 1.0)
	_expect(fear_enemy.apply_fear(4.0, 0.7), "fear must apply through its shared control-resistance path", failures)
	var initial_fear_slow := fear_enemy.get_fear_slow_power()
	_expect(not fear_enemy.apply_fear(2.0, 0.5) and not fear_enemy.apply_fear(4.0, 0.8), "active fear must reject every reapplication regardless of strength", failures)
	fear_enemy._update_statuses(2.0)
	_expect(initial_fear_slow > fear_enemy.get_fear_slow_power() and fear_enemy.get_fear_slow_power() > 0.0, "fear slow must decay continuously while its duration remains", failures)
	fear_enemy._update_statuses(2.0)
	_expect(float(fear_enemy.control_recovery_remaining.get(&"fear", 0.0)) > 0.0 and not fear_enemy.apply_fear(1.0, 0.8), "fear must resist reapplication during post-effect recovery", failures)
	fear_enemy._update_control_recovery(0.45)
	_expect(fear_enemy.apply_fear(1.0, 0.8), "fear must become applicable after post-effect recovery", failures)
	fear_enemy.active = false
	fear_enemy.queue_free()

	var judgment_boss := Enemy.new()
	host.add_child(judgment_boss)
	judgment_boss.set_process(false)
	judgment_boss.set_physics_process(false)
	judgment_boss.setup(DataRegistry.bosses[0], Vector2(600.0, 420.0), 0, Vector2(100.0, 420.0), 1.0, 1.0)
	var boss_health_before_forced_execution := judgment_boss.current_health
	var rejected_boss_execution := judgment.resolve_forced_non_boss_execution(judgment_boss, &"guard_sudden_death")
	_expect(not bool(rejected_boss_execution.executed) and judgment_boss.active and is_equal_approx(judgment_boss.current_health, boss_health_before_forced_execution), "forced guard execution must reject bosses without damage", failures)
	judgment.resolve(judgment_boss, 1.0, &"judgment_test", obsidian.judgment_profile.execute_health_ratio, obsidian.judgment_profile, 1)
	judgment.resolve(judgment_boss, 1.0, &"judgment_test", obsidian.judgment_profile.execute_health_ratio, obsidian.judgment_profile, 1)
	var boss_health_before_verdict := judgment_boss.current_health
	var boss_verdict := judgment.resolve(judgment_boss, 1.0, &"judgment_test", obsidian.judgment_profile.execute_health_ratio, obsidian.judgment_profile, 1)
	_expect(bool(boss_verdict.verdict_triggered) and not bool(boss_verdict.executed) and judgment_boss.active, "a boss verdict must never execute the boss", failures)
	_expect(boss_health_before_verdict - judgment_boss.current_health >= judgment_boss.get_max_health() * obsidian.judgment_profile.boss_fixed_health_ratio, "a boss verdict must convert to maximum-health fixed damage", failures)
	_expect(judgment_boss.get_sentence_stacks() == 0, "a completed boss verdict must consume its sentence stacks", failures)
	judgment_boss.current_health = judgment_boss.get_max_health() * 0.05
	var boss_threshold_verdict := judgment.resolve(judgment_boss, 1.0, &"execute", 0.12)
	_expect(bool(boss_threshold_verdict.verdict_triggered) and not bool(boss_threshold_verdict.executed) and float(boss_threshold_verdict.boss_execution_damage) > 0.0 and judgment_boss.active, "boss execution threshold must convert into fixed damage and never instant death", failures)
	judgment_boss.active = false
	judgment_boss.queue_free()
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
