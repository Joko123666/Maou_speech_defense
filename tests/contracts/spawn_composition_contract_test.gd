class_name SpawnCompositionContractTest
extends RefCounted

const LIMITED_ROLES: Array[StringName] = [&"disable", &"heavy"]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var stage := load("res://data/stages/standard_20m.tres") as StageData
	_expect(stage != null, "the standard stage must load for spawn composition validation", failures)
	if stage == null:
		return failures
	var packet_ids := stage.spawn_packets.map(func(packet: SpawnPacketData) -> StringName: return packet.id)
	_expect(stage.spawn_packets.size() == 3 and packet_ids.has(&"breakthrough") and packet_ids.has(&"escort") and packet_ids.has(&"siege"), "the vertical slice must define breakthrough, escort, and siege packets", failures)
	var composer := SpawnPacketComposer.new()
	for packet in stage.spawn_packets:
		_expect(packet != null and packet.get_validation_errors(stage.spawn_phases.size()).is_empty(), "every spawn packet must satisfy its schema contract", failures)
		if packet == null or packet.allowed_phase_indices.is_empty():
			continue
		_expect(int(packet.role_limits.get(&"disable", -1)) == 1 and int(packet.role_limits.get(&"heavy", -1)) == 1, "packet '%s' must cap disable and heavy roles at one unit" % packet.id, failures)
		var phase_index: int = packet.allowed_phase_indices.front()
		var phase := stage.spawn_phases[phase_index]
		var at_time := (phase.start_seconds + minf(phase.end_seconds, stage.duration_seconds)) * 0.5
		var single_packet: Array[SpawnPacketData] = [packet]
		RunRng.seed_run(8100 + phase_index)
		var plan := composer.compose(single_packet, _candidates(stage, at_time), phase_index, phase.max_packet_cost)
		_expect(not plan.is_empty(), "packet '%s' must compose from its first allowed phase wave" % packet.id, failures)
		if plan.is_empty():
			continue
		_expect(float(plan.cost) <= phase.max_packet_cost + 0.0001 and float(plan.cost) <= packet.max_cost + 0.0001, "packet '%s' must never exceed the available budget or its own cost ceiling" % packet.id, failures)
		_expect(int(plan.role_counts.get(&"disable", 0)) <= 1 and int(plan.role_counts.get(&"heavy", 0)) <= 1, "packet '%s' must enforce disable and heavy density limits" % packet.id, failures)

	var phase_index := 4
	var phase := stage.spawn_phases[phase_index]
	var candidates := _candidates(stage, 480.0)
	RunRng.seed_run(9417)
	var first_plan := composer.compose(stage.spawn_packets, candidates, phase_index, phase.max_packet_cost)
	RunRng.seed_run(9417)
	var second_plan := composer.compose(stage.spawn_packets, candidates, phase_index, phase.max_packet_cost)
	_expect(_signature(first_plan) == _signature(second_plan), "the same run seed must produce the same packet composition", failures)

	var breakthrough: SpawnPacketData
	for packet in stage.spawn_packets:
		if packet.id == &"breakthrough":
			breakthrough = packet
			break
	if breakthrough != null:
		var breakthrough_only: Array[SpawnPacketData] = [breakthrough]
		_expect(composer.compose(breakthrough_only, _candidates(stage, 45.0), 0, breakthrough.min_cost - 0.01).is_empty(), "a packet must be rejected when its minimum cost exceeds the current budget", failures)
		var opening_phase := stage.spawn_phases[1]
		_expect(composer.compose(breakthrough_only, _candidates(stage, 135.0), 1, opening_phase.max_packet_cost).packet_id == &"breakthrough", "an allowed packet must compose in a declared phase", failures)
		_expect(composer.compose(breakthrough_only, candidates, 99, phase.max_packet_cost).is_empty(), "a packet must be rejected outside its declared phases", failures)

	var packet_violations := 0
	RunRng.seed_run(12037)
	for _sample in 128:
		var plan := composer.compose(stage.spawn_packets, candidates, phase_index, phase.max_packet_cost)
		if _limited_role_violation_count(plan.get("entries", [])) > 0:
			packet_violations += 1
	var unconstrained_violations := 0
	RunRng.seed_run(12037)
	for _sample in 128:
		var random_entries: Array[Dictionary] = []
		for _unit in 4:
			var candidate := RunRng.pick(candidates) as Dictionary
			random_entries.append({"enemy": candidate.get("enemy"), "count": 1})
		if _limited_role_violation_count(random_entries) > 0:
			unconstrained_violations += 1
	_expect(packet_violations == 0 and unconstrained_violations > packet_violations, "packet role caps must eliminate disable/heavy over-density found in unconstrained random groups", failures)

	var runtime_probes := [
		{"time": 45.0, "packet_id": &"breakthrough"},
		{"time": 240.0, "packet_id": &"escort"},
		{"time": 360.0, "packet_id": &"siege"},
	]
	for probe_index in runtime_probes.size():
		var probe: Dictionary = runtime_probes[probe_index]
		var spawner := EnemySpawner.new()
		spawner.stage_data = stage
		spawner.enemy_pool.assign(DataRegistry.enemies)
		spawner.elapsed = float(probe.time)
		spawner.spawn_director.configure(stage, 0)
		spawner.spawn_director.advance(10.0, spawner.elapsed, 0.0, false)
		RunRng.seed_run(15000 + probe_index)
		var spawned := spawner._spawn_from_budget(EnemySpawnDirector.BASE_CHANNEL, spawner.elapsed / stage.duration_seconds)
		var snapshot := spawner.spawn_budget_snapshot()
		_expect(spawned and int((snapshot.packet_spawn_counts as Dictionary).get(probe.packet_id, 0)) == 1 and int(snapshot.fallback_group_spawn_count) == 0, "runtime phase probe must spend its budget through the '%s' packet instead of a fallback group" % probe.packet_id, failures)
		spawner.free()
	return failures

static func _candidates(stage: StageData, at_time: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var weights := stage.spawn_wave_at(at_time).get("weights", {}) as Dictionary
	for enemy in DataRegistry.enemies:
		var weight := float(weights.get(String(enemy.id), 0.0))
		if enemy.available_from_seconds <= at_time and weight > 0.0:
			result.append({"enemy": enemy, "weight": weight})
	return result

static func _limited_role_violation_count(entries: Array) -> int:
	var counts: Dictionary = {}
	for entry_value in entries:
		var entry := entry_value as Dictionary
		var enemy := entry.get("enemy") as EnemyData
		if enemy == null:
			continue
		var count := int(entry.get("count", 0))
		for role in LIMITED_ROLES:
			if enemy.role_tags.has(role):
				counts[role] = int(counts.get(role, 0)) + count
	var violations := 0
	for role in LIMITED_ROLES:
		if int(counts.get(role, 0)) > 1:
			violations += 1
	return violations

static func _signature(plan: Dictionary) -> String:
	if plan.is_empty():
		return "empty"
	var parts: PackedStringArray = [String(plan.packet_id), "%.2f" % float(plan.cost)]
	for entry in plan.entries:
		parts.append("%s:%d" % [(entry.enemy as EnemyData).id, int(entry.count)])
	return "|".join(parts)

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
