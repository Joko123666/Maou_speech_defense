class_name EnemySpawner
extends Node

signal spawn_requested(spawn_y_ratio: float, enemy_data: EnemyData, health_multiplier: float, speed_multiplier: float, context: EnemySpawnContext)
signal boss_warning_started(boss_data: EnemyData, spawn_y_ratio: float, seconds_remaining: float)
signal boss_spawn_requested(spawn_y_ratio: float, boss_data: EnemyData, health_multiplier: float, speed_multiplier: float)
signal time_changed(elapsed: float, duration: float)
signal timeline_completed

var stage_data: StageData
var boss_plan: StageRuntimeBossPlan
var enemy_pool: Array[EnemyData] = []
var faction_enemy_pool: Array[EnemyData] = []
var boss_pool: Array[EnemyData] = []
var elapsed: float = 0.0
var running: bool = false
var regular_schedule_enabled: bool = true
var boss_schedule_enabled: bool = true
var warned_bosses: Dictionary = {}
var spawned_bosses: Dictionary = {}
var boss_spawn_ratios: Dictionary = {}
var artifact_elite_schedule_enabled: bool = true
var artifact_elite_pool_entry: EnemyData
var artifact_elite_times: Array[float] = []
var spawned_artifact_elites: Dictionary = {}
var timeline_completed_emitted: bool = false
var last_spawned_enemy_id: StringName = &""
var last_spawn_times_by_enemy_id: Dictionary = {}
var next_group_serial: int = 0
var challenge_level: int = 0
var spawn_director := EnemySpawnDirector.new()
var packet_composer := SpawnPacketComposer.new()
var faction_packet_composer := FactionPreludePacketComposer.new()
var faction_budget_ledger := FactionPreludeBudgetLedger.new()
var pending_faction_spawns: Array[Dictionary] = []
var canceled_faction_spawn_count: int = 0
var scheduled_delayed_faction_spawn_count: int = 0
var emitted_delayed_faction_spawn_count: int = 0
var alive_pressure_provider: Callable
var boss_active_provider: Callable

func configure_pressure_sources(alive_pressure_callback: Callable, boss_active_callback: Callable) -> void:
	alive_pressure_provider = alive_pressure_callback
	boss_active_provider = boss_active_callback

func start(
	data: StageData,
	enemies: Array[EnemyData],
	bosses: Array[EnemyData],
	_board_lane_count: int = Battlefield.LANE_COUNT,
	selected_challenge_level: int = 0,
	runtime_boss_plan: StageRuntimeBossPlan = null,
	faction_enemies: Array[EnemyData] = [],
	enable_artifact_elites: bool = true
) -> void:
	stage_data = data
	challenge_level = ChallengeRules.clamp_level(selected_challenge_level)
	enemy_pool = enemies
	faction_enemy_pool.assign(faction_enemies)
	for enemy in enemy_pool:
		var profile := _spawn_profile(enemy)
		if profile != null:
			enemy.spawn_cost = profile.spawn_cost
			enemy.role_tags.assign(profile.role_tags)
			enemy.available_from_seconds = profile.unlock_time
	boss_plan = runtime_boss_plan if runtime_boss_plan != null else CampaignStageResolver.build_fixed_plan(data, bosses)
	boss_pool = _resolve_boss_pool(bosses, boss_plan)
	elapsed = 0.0
	regular_schedule_enabled = true
	boss_schedule_enabled = true
	warned_bosses.clear()
	spawned_bosses.clear()
	boss_spawn_ratios.clear()
	artifact_elite_schedule_enabled = enable_artifact_elites
	artifact_elite_pool_entry = _enemy_by_id(enemy_pool, stage_data.artifact_elite_enemy_id) if stage_data != null else null
	artifact_elite_times.clear()
	if stage_data != null and enable_artifact_elites:
		artifact_elite_times.assign(stage_data.artifact_elite_times())
	spawned_artifact_elites.clear()
	timeline_completed_emitted = false
	last_spawned_enemy_id = &""
	last_spawn_times_by_enemy_id.clear()
	next_group_serial = 0
	pending_faction_spawns.clear()
	canceled_faction_spawn_count = 0
	scheduled_delayed_faction_spawn_count = 0
	emitted_delayed_faction_spawn_count = 0
	faction_budget_ledger.reset()
	spawn_director.configure(data, challenge_level)
	running = true
	set_physics_process(true)
	time_changed.emit(elapsed, data.duration_seconds)

func stop() -> void:
	running = false
	pending_faction_spawns.clear()
	set_physics_process(false)

func set_boss_schedule_enabled(enabled: bool) -> void:
	boss_schedule_enabled = enabled

func set_regular_schedule_enabled(enabled: bool) -> void:
	regular_schedule_enabled = enabled
	if not enabled:
		pending_faction_spawns.clear()

func spawn_scripted_regular_wave(
	enemy: EnemyData,
	spawn_y_ratios: PackedFloat32Array,
	health_multiplier: float,
	speed_multiplier: float,
	packet_id: StringName = &"tutorial_practice"
) -> int:
	if enemy == null or enemy.is_boss or stage_data == null or spawn_y_ratios.is_empty():
		return 0
	var group_id := _next_group_id()
	for index in spawn_y_ratios.size():
		var spawn_y_ratio := clampf(spawn_y_ratios[index], 0.04, 0.96)
		var context := _build_spawn_context(enemy, spawn_y_ratio, &"base", packet_id, group_id, index)
		spawn_requested.emit(spawn_y_ratio, enemy, health_multiplier, speed_multiplier, context)
		_record_profile_spawn(enemy)
	last_spawned_enemy_id = enemy.id
	return spawn_y_ratios.size()

func warn_boss_now(index: int = 0, seconds_remaining: float = 3.0) -> bool:
	if index < 0 or index >= boss_pool.size() or spawned_bosses.has(index):
		return false
	warned_bosses[index] = true
	var spawn_y_ratio := RunRng.spawn_rangef(0.1, 0.9)
	boss_spawn_ratios[index] = spawn_y_ratio
	boss_warning_started.emit(boss_pool[index], spawn_y_ratio, maxf(seconds_remaining, 0.0))
	return true

func spawn_boss_now(index: int = 0) -> bool:
	if index < 0 or index >= boss_pool.size() or spawned_bosses.has(index):
		return false
	var progress := clampf(elapsed / maxf(stage_data.duration_seconds, 1.0), 0.0, 1.0) if stage_data != null else 0.0
	_spawn_boss(index, progress)
	return spawned_bosses.has(index)

func _physics_process(delta: float) -> void:
	if not running or stage_data == null:
		return
	elapsed += delta
	var capped_time := minf(elapsed, stage_data.duration_seconds)
	var progress := capped_time / stage_data.duration_seconds
	if boss_schedule_enabled:
		_check_boss_events()
	if artifact_elite_schedule_enabled:
		_check_artifact_elite_events()
	if regular_schedule_enabled:
		_flush_pending_faction_spawns()
	if regular_schedule_enabled and elapsed < stage_data.duration_seconds:
		var alive_pressure := _current_alive_pressure()
		spawn_director.advance(delta, elapsed, alive_pressure, _boss_active())
		_drain_spawn_budgets(progress)
	time_changed.emit(capped_time, stage_data.duration_seconds)
	if elapsed >= stage_data.duration_seconds and not timeline_completed_emitted:
		var final_boss_index := mini(boss_plan.slots.size(), boss_pool.size()) - 1
		if boss_schedule_enabled and final_boss_index >= 0 and not spawned_bosses.has(final_boss_index):
			_spawn_boss(final_boss_index, progress)
		timeline_completed_emitted = true
		timeline_completed.emit()

func _spawn_regular(progress: float) -> void:
	var candidates := get_regular_spawn_candidates(elapsed)
	if candidates.is_empty():
		return
	var selected := _weighted_enemy(candidates)
	if selected == null:
		return
	_spawn_enemy_group(selected, progress)

func _drain_spawn_budgets(progress: float) -> void:
	var safety := 0
	while safety < 12 and _spawn_from_budget(EnemySpawnDirector.BASE_CHANNEL, progress):
		safety += 1
	safety = 0
	while safety < 8 and _spawn_from_budget(EnemySpawnDirector.BONUS_CHANNEL, progress):
		safety += 1

func _spawn_from_budget(channel: StringName, progress: float) -> bool:
	var alive_pressure := _current_alive_pressure()
	var affordable := spawn_director.affordable_budget(channel, elapsed, alive_pressure)
	if affordable <= 0.0:
		return false
	var candidates := get_regular_spawn_candidates(elapsed)
	if candidates.is_empty():
		return false
	var phase_index := stage_data.spawn_phase_index_at(elapsed)
	var has_common_packet := packet_composer.has_phase_packet(stage_data.spawn_packets, phase_index)
	var common_plan: Dictionary = {}
	if has_common_packet:
		var minimum_packet_budget := packet_composer.minimum_budget_for_phase(stage_data.spawn_packets, phase_index)
		if affordable + 0.0001 >= minimum_packet_budget:
			common_plan = packet_composer.compose(stage_data.spawn_packets, candidates, phase_index, affordable)
	var prelude := get_faction_prelude_state(elapsed)
	var faction_plan := _compose_faction_plan(prelude, candidates, affordable, channel)
	var use_faction := not faction_plan.is_empty() and (
		common_plan.is_empty() or faction_budget_ledger.should_select_faction(float(common_plan.cost), float(faction_plan.cost), prelude, elapsed)
	)
	var selected_plan := faction_plan if use_faction else common_plan
	if not selected_plan.is_empty():
		var packet_experience := _packet_experience(selected_plan.entries as Array[Dictionary])
		if not spawn_director.spend(channel, float(selected_plan.cost), int(selected_plan.count), packet_experience):
			return false
		spawn_director.record_composition(StringName(selected_plan.packet_id))
		faction_budget_ledger.record_spend(float(selected_plan.cost), use_faction, prelude, channel)
		if use_faction:
			_spawn_faction_packet(selected_plan, progress, channel, prelude)
		else:
			_spawn_packet(selected_plan.entries as Array[Dictionary], progress, channel, StringName(selected_plan.packet_id))
		return true
	if has_common_packet:
		return false
	var affordable_groups := candidates.filter(func(candidate: Dictionary) -> bool:
		var enemy := candidate.get("enemy") as EnemyData
		return enemy != null and _group_spawn_cost(enemy) <= affordable + 0.0001
	)
	if affordable_groups.is_empty():
		return false
	var selected := _weighted_enemy(affordable_groups)
	if selected == null:
		return false
	var count := _group_count(selected)
	var cost := _spawn_cost(selected) * float(count)
	var experience_value := selected.experience_value * float(count) * ChallengeRules.experience_multiplier(challenge_level)
	if not spawn_director.spend(channel, cost, count, experience_value):
		return false
	spawn_director.record_composition(&"")
	faction_budget_ledger.record_spend(cost, false, prelude, channel)
	_spawn_enemy_group(selected, progress, count, channel)
	return true

func _packet_experience(entries: Array[Dictionary]) -> float:
	var result := 0.0
	for entry in entries:
		var enemy := entry.get("enemy") as EnemyData
		if enemy != null:
			result += enemy.experience_value * float(entry.get("count", 0))
	return result * ChallengeRules.experience_multiplier(challenge_level)

func get_faction_prelude_state(at_time: float) -> Dictionary:
	return FactionPreludeResolver.resolve(stage_data, boss_plan, at_time)

func _compose_faction_plan(prelude: Dictionary, common_candidates: Array[Dictionary], budget: float, _channel: StringName) -> Dictionary:
	if not bool(prelude.get("active", false)) or faction_enemy_pool.is_empty():
		return {}
	var plan := faction_packet_composer.compose(
		stage_data.faction_spawn_packets,
		faction_enemy_pool,
		common_candidates,
		StringName(prelude.get("faction_id", &"")),
		int(prelude.get("tier", 0)),
		budget
	)
	if plan.is_empty():
		return {}
	var faction_entry: Dictionary = (plan.entries as Array[Dictionary]).front()
	var faction_enemy := faction_entry.get("enemy") as EnemyData
	var maximum_delay := faction_enemy.formation_profile.stagger_for_tier(int(prelude.tier)) if faction_enemy != null and faction_enemy.formation_profile != null else 0.0
	if elapsed + maximum_delay >= float(prelude.get("end_seconds", elapsed)) - 0.0001:
		return {}
	return plan

func _spawn_faction_packet(plan: Dictionary, progress: float, channel: StringName, prelude: Dictionary) -> void:
	var entries := plan.entries as Array[Dictionary]
	if entries.is_empty():
		return
	var packet_id := StringName(plan.packet_id)
	var faction_entry: Dictionary = entries.front()
	var faction_enemy := faction_entry.get("enemy") as EnemyData
	if faction_enemy == null:
		return
	last_spawned_enemy_id = faction_enemy.id
	var center_y := RunRng.spawn_rangef(0.14, 0.86)
	var serial := _next_group_serial_value()
	var contexts := _faction_contexts(faction_enemy, int(faction_entry.get("count", 0)), int(prelude.tier), serial, center_y, packet_id, channel)
	var health_multiplier := stage_data.health_multiplier_at(progress)
	var speed_multiplier := stage_data.speed_multiplier_at(progress)
	for context in contexts:
		_dispatch_faction_spawn(faction_enemy, health_multiplier, speed_multiplier, context, float(prelude.end_seconds))
	var common_entries: Array[Dictionary] = []
	for entry_index in range(1, entries.size()):
		common_entries.append(entries[entry_index])
	var common_total := 0
	for entry in common_entries:
		common_total += int(entry.get("count", 0))
	var common_index := 0
	var common_group_id := StringName("prelude-%d-common" % serial)
	for entry in common_entries:
		var enemy := entry.get("enemy") as EnemyData
		if enemy == null:
			continue
		for local_index in int(entry.get("count", 0)):
			var centered := float(common_index) - float(common_total - 1) * 0.5
			var spawn_y_ratio := clampf(center_y + centered * 0.045 + RunRng.spawn_rangef(-0.012, 0.012), 0.04, 0.96)
			var context := _build_spawn_context(enemy, spawn_y_ratio, channel, packet_id, common_group_id, local_index)
			_emit_regular_spawn(enemy, health_multiplier, speed_multiplier, context)
			common_index += 1

func _faction_contexts(enemy: EnemyData, count: int, tier: int, serial: int, center_y: float, packet_id: StringName, channel: StringName) -> Array[EnemySpawnContext]:
	var spawn_profile := _spawn_profile(enemy)
	if spawn_profile == null:
		return []
	if enemy.formation_profile != null:
		var planned := FactionEnemyFormationPlanner.build_contexts(enemy, spawn_profile, tier, serial, center_y, elapsed, packet_id, channel)
		return planned if planned.size() == count else []
	var result: Array[EnemySpawnContext] = []
	var group_id := StringName("%s:g0:t%d:s%d" % [enemy.id, tier, serial])
	for index in count:
		var centered := float(index) - float(count - 1) * 0.5
		var context := EnemySpawnContext.new()
		context.enemy_id = enemy.id
		context.packet_id = packet_id
		context.channel = channel
		context.spawn_time = elapsed
		context.faction_id = spawn_profile.faction_id
		context.prelude_tier = tier
		context.group_id = group_id
		context.cohort_id = StringName("%s:c0:t%d:s%d" % [enemy.id, tier, serial])
		context.formation_index = index
		context.spawn_y_ratio = clampf(center_y + centered * 0.035, 0.04, 0.96)
		result.append(context)
	return result

func _dispatch_faction_spawn(enemy: EnemyData, health_multiplier: float, speed_multiplier: float, context: EnemySpawnContext, prelude_end: float) -> void:
	if context.spawn_delay <= 0.0:
		_emit_regular_spawn(enemy, health_multiplier, speed_multiplier, context)
		return
	pending_faction_spawns.append({
		"enemy": enemy,
		"health_multiplier": health_multiplier,
		"speed_multiplier": speed_multiplier,
		"context": context,
		"prelude_end": prelude_end,
	})
	scheduled_delayed_faction_spawn_count += 1

func _flush_pending_faction_spawns() -> void:
	var remaining: Array[Dictionary] = []
	for pending in pending_faction_spawns:
		var context := pending.get("context") as EnemySpawnContext
		if context == null:
			continue
		if elapsed >= float(pending.get("prelude_end", elapsed)):
			canceled_faction_spawn_count += 1
			continue
		if elapsed + 0.0001 < context.spawn_time:
			remaining.append(pending)
			continue
		var prelude := get_faction_prelude_state(elapsed)
		if not bool(prelude.get("active", false)) or StringName(prelude.get("faction_id", &"")) != context.faction_id or int(prelude.get("tier", 0)) != context.prelude_tier:
			canceled_faction_spawn_count += 1
			continue
		_emit_regular_spawn(
			pending.get("enemy") as EnemyData,
			float(pending.get("health_multiplier", 1.0)),
			float(pending.get("speed_multiplier", 1.0)),
			context
		)
		emitted_delayed_faction_spawn_count += 1
	pending_faction_spawns = remaining

func _emit_regular_spawn(enemy: EnemyData, health_multiplier: float, speed_multiplier: float, context: EnemySpawnContext) -> void:
	if enemy == null or context == null:
		return
	spawn_requested.emit(context.spawn_y_ratio, enemy, health_multiplier, speed_multiplier, context)
	_record_profile_spawn(enemy)

func _spawn_packet(entries: Array[Dictionary], progress: float, channel: StringName = &"base", packet_id: StringName = &"") -> void:
	var total_count := 0
	for entry in entries:
		total_count += int(entry.get("count", 0))
	if total_count <= 0:
		return
	last_spawned_enemy_id = ((entries.front().get("enemy") as EnemyData).id if entries.front().get("enemy") != null else &"")
	var group_center := RunRng.spawn_rangef(0.08, 0.92)
	var spacing := minf(0.035 + float(total_count) * 0.008, 0.075)
	var unit_index := 0
	var group_id := _next_group_id()
	for entry in entries:
		var enemy := entry.get("enemy") as EnemyData
		if enemy == null:
			continue
		for spawn_index in int(entry.get("count", 0)):
			var centered_index := float(unit_index) - float(total_count - 1) * 0.5
			var spawn_y_ratio := clampf(group_center + centered_index * spacing + RunRng.spawn_rangef(-0.018, 0.018), 0.04, 0.96)
			spawn_requested.emit(
				spawn_y_ratio,
				enemy,
				stage_data.health_multiplier_at(progress),
				stage_data.speed_multiplier_at(progress),
				_build_spawn_context(enemy, spawn_y_ratio, channel, packet_id, group_id, spawn_index)
			)
			_record_profile_spawn(enemy)
			unit_index += 1

func _spawn_enemy_group(selected: EnemyData, progress: float, requested_count: int = -1, channel: StringName = &"base") -> void:
	var count := _group_count(selected) if requested_count < 0 else requested_count
	last_spawned_enemy_id = selected.id
	var group_center := RunRng.spawn_rangef(0.08, 0.92)
	var spacing := minf(0.035 + float(count) * 0.008, 0.075)
	var group_id := _next_group_id()
	for index in count:
		var centered_index := float(index) - float(count - 1) * 0.5
		var spawn_y_ratio := clampf(group_center + centered_index * spacing + RunRng.spawn_rangef(-0.018, 0.018), 0.04, 0.96)
		spawn_requested.emit(
			spawn_y_ratio,
			selected,
			stage_data.health_multiplier_at(progress),
			stage_data.speed_multiplier_at(progress),
			_build_spawn_context(selected, spawn_y_ratio, channel, &"", group_id, index)
		)
		_record_profile_spawn(selected)

func _group_count(enemy: EnemyData) -> int:
	if enemy == null or stage_data == null:
		return 0
	var wave := stage_data.spawn_wave_at(elapsed)
	var groups: Dictionary = wave.get("groups", {})
	var profile := _spawn_profile(enemy)
	var default_count := profile.group_min if profile != null else (3 if enemy.behavior == &"swarm" else 1)
	return clampi(int(groups.get(String(enemy.id), default_count)), 1, 8)

func _group_spawn_cost(enemy: EnemyData) -> float:
	return _spawn_cost(enemy) * float(_group_count(enemy)) if enemy != null else 0.0

func _spawn_cost(enemy: EnemyData) -> float:
	var profile := _spawn_profile(enemy)
	return profile.spawn_cost if profile != null else (enemy.spawn_cost if enemy != null else 0.0)

func _spawn_profile(enemy: EnemyData) -> EnemySpawnProfileData:
	return DataRegistry.get_enemy_spawn_profile(enemy.id) if enemy != null else null

func _current_alive_pressure() -> float:
	if alive_pressure_provider.is_valid():
		return maxf(float(alive_pressure_provider.call()), 0.0)
	return 0.0

func _boss_active() -> bool:
	return bool(boss_active_provider.call()) if boss_active_provider.is_valid() else false

func spawn_budget_snapshot() -> Dictionary:
	var result := spawn_director.snapshot()
	result.merge(faction_budget_ledger.snapshot(get_faction_prelude_state(elapsed), elapsed), true)
	result["pending_faction_spawn_count"] = pending_faction_spawns.size()
	result["canceled_faction_spawn_count"] = canceled_faction_spawn_count
	result["scheduled_delayed_faction_spawn_count"] = scheduled_delayed_faction_spawn_count
	result["emitted_delayed_faction_spawn_count"] = emitted_delayed_faction_spawn_count
	return result

func get_regular_spawn_candidates(at_time: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if stage_data == null:
		return result
	var wave := stage_data.spawn_wave_at(at_time)
	var weights: Dictionary = wave.get("weights", {})
	for enemy in enemy_pool:
		var profile := _spawn_profile(enemy)
		if profile != null and profile.is_faction_enemy:
			continue
		var unlock_time := profile.unlock_time if profile != null else enemy.available_from_seconds
		if unlock_time > at_time or not _rare_cooldown_ready(profile, at_time):
			continue
		var weight := float(weights.get(String(enemy.id), 0.0))
		if weight <= 0.0:
			continue
		if enemy.id == last_spawned_enemy_id:
			weight *= 0.45
		result.append({"enemy": enemy, "weight": weight})
	# 구형/사용자 스테이지에 테이블이 없으면 기존 해금 시간 기반 풀을 유지한다.
	if result.is_empty() and weights.is_empty():
		for enemy in enemy_pool:
			var profile := _spawn_profile(enemy)
			if profile != null and profile.is_faction_enemy:
				continue
			var unlock_time := profile.unlock_time if profile != null else enemy.available_from_seconds
			if unlock_time <= at_time and _rare_cooldown_ready(profile, at_time):
				result.append({"enemy": enemy, "weight": 1.0})
	return result

func _rare_cooldown_ready(profile: EnemySpawnProfileData, at_time: float) -> bool:
	if profile == null or profile.rare_spawn_cooldown <= 0.0 or not last_spawn_times_by_enemy_id.has(profile.enemy_id):
		return true
	return at_time - float(last_spawn_times_by_enemy_id[profile.enemy_id]) >= profile.rare_spawn_cooldown

func _record_profile_spawn(enemy: EnemyData) -> void:
	if enemy != null:
		last_spawn_times_by_enemy_id[enemy.id] = elapsed

func _next_group_id() -> StringName:
	return StringName("spawn-%d" % _next_group_serial_value())

func _next_group_serial_value() -> int:
	next_group_serial += 1
	return next_group_serial

func _build_spawn_context(enemy: EnemyData, spawn_y_ratio: float, channel: StringName, packet_id: StringName, group_id: StringName, cohort_index: int) -> EnemySpawnContext:
	var context := EnemySpawnContext.new()
	context.enemy_id = enemy.id
	context.packet_id = packet_id
	context.channel = channel
	context.spawn_time = elapsed
	context.group_id = group_id
	context.cohort_id = StringName("%s-%d" % [group_id, cohort_index])
	context.wave_index = stage_data.spawn_phase_index_at(elapsed) if stage_data != null else 0
	context.spawn_y_ratio = spawn_y_ratio
	if enemy.movement_profile != null and enemy.movement_profile.kind == &"fixed_diagonal":
		var profile := enemy.movement_profile
		var offset := RunRng.spawn_rangef(profile.destination_offset_min, profile.destination_offset_max)
		var direction := -1.0 if spawn_y_ratio >= 0.5 else 1.0
		if spawn_y_ratio > 0.28 and spawn_y_ratio < 0.72 and RunRng.spawn_roll() < 0.5:
			direction *= -1.0
		context.destination_y_ratio = clampf(spawn_y_ratio + offset * direction, 0.08, 0.92)
	return context

func _weighted_enemy(candidates: Array[Dictionary]) -> EnemyData:
	var total_weight := 0.0
	for candidate in candidates:
		total_weight += float(candidate.get("weight", 0.0))
	if total_weight <= 0.0:
		return null
	var roll := RunRng.spawn_roll() * total_weight
	for candidate in candidates:
		roll -= float(candidate.get("weight", 0.0))
		if roll <= 0.0:
			return candidate.get("enemy") as EnemyData
	return candidates.back().get("enemy") as EnemyData

func _check_boss_events() -> void:
	for index in mini(boss_plan.slots.size(), boss_pool.size()):
		var boss_time := boss_plan.time_at(index)
		if elapsed >= boss_time - 30.0 and not warned_bosses.has(index):
			warned_bosses[index] = true
			boss_spawn_ratios[index] = RunRng.spawn_rangef(0.1, 0.9)
			boss_warning_started.emit(boss_pool[index], boss_spawn_ratios[index], 30.0)
		if elapsed >= boss_time and not spawned_bosses.has(index):
			_spawn_boss(index, minf(elapsed / stage_data.duration_seconds, 1.0))

func _check_artifact_elite_events() -> void:
	if stage_data == null or artifact_elite_pool_entry == null:
		return
	for tier_index in artifact_elite_times.size():
		if spawned_artifact_elites.has(tier_index):
			continue
		var scheduled_time := artifact_elite_times[tier_index]
		if elapsed + 0.0001 < scheduled_time:
			break
		_spawn_artifact_elite(tier_index + 1, scheduled_time)

func _spawn_artifact_elite(tier: int, scheduled_time: float) -> void:
	var tier_index := tier - 1
	if tier_index < 0 or tier_index >= artifact_elite_times.size() or spawned_artifact_elites.has(tier_index) or artifact_elite_pool_entry == null:
		return
	spawned_artifact_elites[tier_index] = true
	var elite := artifact_elite_pool_entry.duplicate(true) as EnemyData
	elite.display_name = "아티팩트 운반 정예 · %d단계" % tier
	elite.is_boss = false
	elite.is_elite = true
	elite.body_color = Color("f0bb4f").lerp(Color("e75c66"), float(tier - 1) / 5.0)
	elite.radius = artifact_elite_pool_entry.radius + 2.0 + float(tier)
	var spawn_y_ratio := RunRng.spawn_rangef(0.12, 0.88)
	var context := _build_spawn_context(elite, spawn_y_ratio, &"base", StringName("artifact_elite_%d" % tier), _next_group_id(), 0)
	context.spawn_time = scheduled_time
	context.encounter_kind = &"artifact_elite"
	context.artifact_reward_tier = tier
	var progress := clampf(scheduled_time / maxf(stage_data.duration_seconds, 1.0), 0.0, 1.0)
	spawn_requested.emit(
		spawn_y_ratio,
		elite,
		stage_data.health_multiplier_at(progress) * stage_data.artifact_elite_health_multiplier(tier),
		stage_data.speed_multiplier_at(progress),
		context
	)

func _enemy_by_id(pool: Array[EnemyData], enemy_id: StringName) -> EnemyData:
	for enemy in pool:
		if enemy != null and enemy.id == enemy_id:
			return enemy
	return null

func _spawn_boss(index: int, progress: float) -> void:
	if index < 0 or index >= boss_pool.size() or spawned_bosses.has(index):
		return
	spawned_bosses[index] = true
	var spawn_y_ratio := float(boss_spawn_ratios.get(index, RunRng.spawn_rangef(0.1, 0.9)))
	boss_spawn_requested.emit(
		spawn_y_ratio,
		boss_pool[index],
		stage_data.boss_health_multiplier_at(progress),
		stage_data.speed_multiplier_at(progress)
	)

func _resolve_boss_pool(catalog: Array[EnemyData], plan: StageRuntimeBossPlan) -> Array[EnemyData]:
	var by_id: Dictionary = {}
	for boss in catalog:
		if boss != null:
			by_id[boss.id] = boss
	var resolved: Array[EnemyData] = []
	for index in plan.slots.size():
		var boss := by_id.get(plan.boss_id_at(index)) as EnemyData
		if boss == null:
			push_error("Runtime boss plan references missing boss '%s'." % plan.boss_id_at(index))
			continue
		if plan.source == StageRuntimeBossPlan.SOURCE_CAMPAIGN and stage_data != null and index < stage_data.default_boss_ids.size():
			var slot_reference := by_id.get(stage_data.default_boss_ids[index]) as EnemyData
			if slot_reference != null:
				var normalized_boss := boss.duplicate(true) as EnemyData
				normalized_boss.max_health = slot_reference.max_health
				normalized_boss.core_damage = slot_reference.core_damage
				normalized_boss.experience_value = slot_reference.experience_value
				normalized_boss.armor = slot_reference.armor
				normalized_boss.boss_tier = index + 1
				resolved.append(normalized_boss)
				continue
		resolved.append(boss)
	return resolved
