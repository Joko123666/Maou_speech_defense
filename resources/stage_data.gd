class_name StageData
extends Resource

@export var id: StringName = &"standard_20m"
@export var display_name: String = "10분 표준 스테이지"
@export_range(1.0, 3600.0, 1.0) var duration_seconds: float = 600.0
@export_range(0.1, 30.0, 0.05) var initial_spawn_interval: float = 1.8
@export_range(0.1, 30.0, 0.05) var minimum_spawn_interval: float = 0.55
@export_range(1.0, 3.0, 0.05) var initial_health_multiplier: float = 1.0
@export_range(1.0, 10.0, 0.05) var final_health_multiplier: float = 3.2
@export_range(1.0, 10.0, 0.05) var final_speed_multiplier: float = 1.45
@export var enemy: EnemyData
@export var boss_times: Array[float] = [150.0, 300.0, 450.0, 600.0]
@export var default_boss_ids: Array[StringName] = [&"boss_5", &"boss_10", &"boss_15", &"final_boss"]
@export var final_boss_id: StringName = &"final_boss"
@export var artifact_elite_interval_seconds: float = 0.0
@export var artifact_elite_enemy_id: StringName = &""
@export var artifact_elite_health_multipliers: Array[float] = []
@export var spawn_table: Array[Dictionary] = []
@export var spawn_phases: Array[SpawnPhaseData] = []
@export var spawn_packets: Array[SpawnPacketData] = []
@export var faction_preludes: Array[FactionPreludeData] = []
@export var faction_spawn_packets: Array[FactionSpawnPacketData] = []

func spawn_interval_at(progress: float) -> float:
	return lerpf(initial_spawn_interval, minimum_spawn_interval, clampf(progress, 0.0, 1.0))

func health_multiplier_at(progress: float) -> float:
	return lerpf(initial_health_multiplier, final_health_multiplier, clampf(progress, 0.0, 1.0))

func boss_health_multiplier_at(progress: float) -> float:
	var normalized_progress := clampf(progress, 0.0, 1.0)
	return lerpf(1.0, final_health_multiplier, normalized_progress * normalized_progress)

func speed_multiplier_at(progress: float) -> float:
	return lerpf(1.0, final_speed_multiplier, clampf(progress, 0.0, 1.0))

func has_artifact_elite_schedule() -> bool:
	return artifact_elite_interval_seconds > 0.0 and artifact_elite_enemy_id != &"" and not artifact_elite_health_multipliers.is_empty()

func artifact_elite_times() -> Array[float]:
	var result: Array[float] = []
	if not has_artifact_elite_schedule():
		return result
	var at_time := artifact_elite_interval_seconds
	# 최종 보스와 같은 시각의 정예는 만들지 않는다.
	while at_time < duration_seconds - 0.0001:
		result.append(at_time)
		at_time += artifact_elite_interval_seconds
	return result

func artifact_elite_health_multiplier(tier: int) -> float:
	if artifact_elite_health_multipliers.is_empty():
		return 1.0
	return maxf(artifact_elite_health_multipliers[clampi(tier - 1, 0, artifact_elite_health_multipliers.size() - 1)], 0.1)

func spawn_wave_at(seconds: float) -> Dictionary:
	for wave in spawn_table:
		var start_time := float(wave.get("start", 0.0))
		var end_time := float(wave.get("end", duration_seconds))
		if seconds >= start_time and seconds < end_time:
			return wave
	return spawn_table.back() if not spawn_table.is_empty() else {}

func spawn_phase_at(seconds: float) -> SpawnPhaseData:
	for phase in spawn_phases:
		if phase != null and phase.contains(seconds, duration_seconds):
			return phase
	return spawn_phases.back() if not spawn_phases.is_empty() else null

func spawn_phase_index_at(seconds: float) -> int:
	for phase_index in spawn_phases.size():
		var phase := spawn_phases[phase_index]
		if phase != null and phase.contains(seconds, duration_seconds):
			return phase_index
	return spawn_phases.size() - 1 if not spawn_phases.is_empty() else -1

func faction_prelude_for_boss_index(boss_index: int) -> FactionPreludeData:
	for prelude in faction_preludes:
		if prelude != null and prelude.boss_index == boss_index:
			return prelude
	return null

func get_faction_prelude_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if faction_preludes.is_empty():
		return errors
	if faction_preludes.size() != boss_times.size():
		errors.append("faction prelude count must match boss time count")
	var seen_indices: Dictionary = {}
	for prelude in faction_preludes:
		if prelude == null:
			errors.append("faction prelude entry is null")
			continue
		if seen_indices.has(prelude.boss_index):
			errors.append("faction prelude repeats boss index %d" % prelude.boss_index)
		else:
			seen_indices[prelude.boss_index] = true
		errors.append_array(prelude.get_validation_errors(boss_times))
	for boss_index in boss_times.size():
		if not seen_indices.has(boss_index):
			errors.append("faction prelude is missing boss index %d" % boss_index)
	return errors

func get_faction_spawn_packet_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if faction_preludes.any(func(prelude: FactionPreludeData) -> bool: return prelude != null and prelude.tier > 0) and faction_spawn_packets.is_empty():
		errors.append("faction preludes require faction spawn packet data")
	var seen_ids: Dictionary = {}
	var seen_factions: Dictionary = {}
	for packet_index in faction_spawn_packets.size():
		var packet := faction_spawn_packets[packet_index]
		if packet == null:
			errors.append("faction spawn packet %d is null" % packet_index)
			continue
		for packet_error in packet.get_validation_errors():
			errors.append("faction spawn packet %d: %s" % [packet_index, packet_error])
		if seen_ids.has(packet.id):
			errors.append("faction spawn packet id '%s' is duplicated" % packet.id)
		else:
			seen_ids[packet.id] = true
		if seen_factions.has(packet.faction_id):
			errors.append("faction '%s' has multiple spawn packet records" % packet.faction_id)
		else:
			seen_factions[packet.faction_id] = true
	return errors
