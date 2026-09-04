class_name SpawnDirectorContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var stage := load("res://data/stages/standard_20m.tres") as StageData
	_expect(stage != null and stage.spawn_phases.size() == 6 and stage.spawn_table.size() == 6, "the standard stage must retain six weighted waves with six matching spawn phases", failures)
	if stage == null:
		return failures

	_expect(DataRegistry.enemies.all(func(enemy: EnemyData) -> bool: return enemy.spawn_cost > 0.0 and not enemy.role_tags.is_empty()), "every regular enemy must expose positive spawn cost and at least one role tag", failures)
	var previous_end := 0.0
	for phase_index in stage.spawn_phases.size():
		var phase := stage.spawn_phases[phase_index]
		_expect(phase != null and is_equal_approx(phase.start_seconds, previous_end), "spawn phases must be contiguous without gaps or overlaps", failures)
		if phase == null:
			continue
		_expect(phase.get_validation_errors(stage.duration_seconds).is_empty(), "spawn phase %d must satisfy its budget and pressure contract" % phase_index, failures)
		_expect(phase.target_alive_pressure <= phase.max_alive_pressure and phase.bonus_budget_rate <= phase.base_budget_rate * 0.25 + 0.0001, "spawn phases must cap pressure and bonus growth at one quarter of base growth", failures)
		var wave: Dictionary = stage.spawn_table[phase_index]
		var groups := wave.get("groups", {}) as Dictionary
		for raw_enemy_id in (wave.get("weights", {}) as Dictionary):
			var enemy := DataRegistry.get_enemy(StringName(raw_enemy_id))
			if enemy == null:
				continue
			var count := int(groups.get(String(enemy.id), 3 if enemy.behavior == &"swarm" else 1))
			_expect(enemy.spawn_cost * float(count) <= phase.max_packet_cost, "phase %d must afford every weighted enemy group" % phase_index, failures)
		previous_end = phase.end_seconds
	_expect(previous_end >= stage.duration_seconds, "spawn phases must cover the full stage duration", failures)

	var strong := _simulate(stage, 1.0 / 60.0, 0.0)
	var weak := _simulate(stage, 1.0 / 60.0, stage.spawn_phases[0].max_alive_pressure)
	_expect(int(strong.base_spawn_count) == int(weak.base_spawn_count) and int(weak.base_spawn_count) > 0, "high pressure must not remove the mandatory base spawn supply", failures)
	_expect(int(strong.bonus_spawn_count) > 0 and int(weak.bonus_spawn_count) == 0 and int(strong.base_spawn_count) + int(strong.bonus_spawn_count) > int(weak.base_spawn_count), "a low-pressure probe must gain bounded extra enemies while a saturated probe gains none", failures)
	_expect(float(strong.bonus_experience_ratio) > 0.0 and float(strong.bonus_experience_ratio) <= 0.25, "bonus spawn experience must stay within the 20-25 percent growth ceiling", failures)

	var speed_2x := _simulate(stage, 1.0 / 30.0, 0.0)
	var speed_3x := _simulate(stage, 1.0 / 20.0, 0.0)
	_expect(int(strong.base_spawn_count) == int(speed_2x.base_spawn_count) and int(strong.bonus_spawn_count) == int(speed_2x.bonus_spawn_count) and int(strong.base_spawn_count) == int(speed_3x.base_spawn_count) and int(strong.bonus_spawn_count) == int(speed_3x.bonus_spawn_count), "equivalent game time at 1x/2x/3x frame steps must produce identical budget decisions", failures)

	var boss_free := EnemySpawnDirector.new()
	boss_free.configure(stage, 0)
	boss_free.advance(10.0, 30.0, 0.0, false)
	var boss_active := EnemySpawnDirector.new()
	boss_active.configure(stage, 0)
	boss_active.advance(10.0, 30.0, 0.0, true)
	_expect(is_equal_approx(boss_free.base_budget_accrued, boss_active.base_budget_accrued) and boss_active.bonus_budget_accrued < boss_free.bonus_budget_accrued, "boss presence must reduce only bonus budget while preserving base budget", failures)
	_expect(is_zero_approx(boss_free.affordable_budget(EnemySpawnDirector.BONUS_CHANNEL, 30.0, stage.spawn_phases[0].max_alive_pressure)), "bonus spending must stop at maximum alive pressure", failures)
	var challenge_director := EnemySpawnDirector.new()
	challenge_director.configure(stage, 10)
	challenge_director.advance(10.0, 30.0, 0.0, false)
	var base_limits := boss_free.phase_limits(30.0)
	var challenge_limits := challenge_director.phase_limits(30.0)
	_expect(challenge_director.base_budget_accrued > boss_free.base_budget_accrued and float(challenge_limits.max_packet_cost) > float(base_limits.max_packet_cost) and float(challenge_limits.target_alive_pressure) > float(base_limits.target_alive_pressure), "challenge spawn acceleration must migrate to budget rate, packet cap, and target pressure", failures)
	return failures

static func _simulate(stage: StageData, step: float, alive_pressure: float) -> Dictionary:
	var director := EnemySpawnDirector.new()
	director.configure(stage, 0)
	var elapsed := 0.0
	while elapsed < 60.0 - 0.0001:
		var delta := minf(step, 60.0 - elapsed)
		elapsed += delta
		director.advance(delta, elapsed, alive_pressure, false)
		while director.affordable_budget(EnemySpawnDirector.BASE_CHANNEL, elapsed, alive_pressure) + 0.0001 >= 3.0:
			director.spend(EnemySpawnDirector.BASE_CHANNEL, 3.0, 1, 1.0)
		while director.affordable_budget(EnemySpawnDirector.BONUS_CHANNEL, elapsed, alive_pressure) + 0.0001 >= 3.0:
			director.spend(EnemySpawnDirector.BONUS_CHANNEL, 3.0, 1, 1.0)
	return director.snapshot()

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
