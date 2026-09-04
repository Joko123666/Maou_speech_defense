class_name RunMetrics
extends Node

var elapsed: float = 0.0
var spawned_by_period: Dictionary = {}
var killed_by_period: Dictionary = {}
var reached_core_count: int = 0
var lane_spawns: Array[int] = []
var lane_reaches: Array[int] = []
var tower_damage: Dictionary = {}
var tower_kills: Dictionary = {}
var tower_attacks: Dictionary = {}
var tower_hits: Dictionary = {}
var tower_multi_hit_events: Dictionary = {}
var tower_long_range_kills: Dictionary = {}
var boss_damage: float = 0.0
var status_applications: Dictionary = {}
var status_damage: Dictionary = {}
var kills_by_enemy_id: Dictionary = {}
var kills_by_behavior: Dictionary = {}
var reaches_before_five_minutes: int = 0
var burst_ten_kill_windows: int = 0
var recent_kill_times: Array[float] = []
var cursor_damage: float = 0.0
var retainer_control_applications: int = 0
var retainer_collection_experience: float = 0.0
var cursor_lane_seconds: Array[float] = []
var selected_upgrades: Dictionary = {}
var unselected_upgrades: Dictionary = {}
## 표시명 변경과 무관하게 제안·선택률을 비교하기 위한 안정 ID 메트릭입니다.
var upgrade_offers_by_id: Dictionary = {}
var upgrade_selections_by_id: Dictionary = {}
var specialization_offers: Dictionary = {}
var specialization_selections: Dictionary = {}
var tower_slots_completed_at: float = -1.0
var first_core_damage_at: float = -1.0
var boss_kill_times: Dictionary = {}
var runtime_frame_count: int = 0
var runtime_real_seconds: float = 0.0
var runtime_game_seconds: float = 0.0
var worst_frame_ms: float = 0.0
var frames_over_16_ms: int = 0
var frames_over_33_ms: int = 0
var real_seconds_by_speed: Dictionary = {}
var peak_active_enemies: int = 0
var peak_projectiles: int = 0
var peak_effects: int = 0
var peak_summons: int = 0
var peak_summon_budget_cost: int = 0
var effect_budget_spawned: Dictionary = {}
var effect_budget_dropped: Dictionary = {}
var mechanic_events: Dictionary = {}
var mechanic_totals: Dictionary = {}
var mechanic_sample_sums: Dictionary = {}
var mechanic_sample_counts: Dictionary = {}
var mechanic_sample_peaks: Dictionary = {}
var formation_set_offers_by_size: Dictionary = {}
var formation_set_selections_by_size: Dictionary = {}
var formation_set_abandons_by_size: Dictionary = {}
var formation_offers: Dictionary = {}
var formation_selections: Dictionary = {}
var formation_abandons: Dictionary = {}
var formation_placement_seconds: Dictionary = {}
var formation_valid_position_totals: Dictionary = {}
var formation_offer_context_events: Array[Dictionary] = []
var board_occupancy_samples: Array[float] = []
var isolated_empty_cell_samples: Array[int] = []
var formation_vertical_flips: int = 0
var guard_placements: Dictionary = {}
var formation_selection_events: Array[Dictionary] = []
var formation_abandon_events: Array[Dictionary] = []
var guard_placement_events: Array[Dictionary] = []
var guard_combat: Dictionary = {}
var spawn_director_metrics: Dictionary = {}
var enemy_spawn_events: Array[Dictionary] = []
var enemy_exit_events: Array[Dictionary] = []
var enemy_acceleration_events: Array[Dictionary] = []
var defender_disable_events: Array[Dictionary] = []
var level_reach_events: Array[Dictionary] = []
var overgrowth_offer_events: Array[Dictionary] = []
var upgrade_selection_events: Array[Dictionary] = []
var enemy_control_totals: Dictionary = {}
var experience_drop_by_channel: Dictionary = {}
var experience_collected_raw_by_channel: Dictionary = {}
var experience_awarded_by_channel: Dictionary = {}
var damage_by_source_type: Dictionary = {}
var artifact_offer_counts: Dictionary = {}
var artifact_acquisition_counts: Dictionary = {}
var artifact_discard_counts: Dictionary = {}
var artifact_replacement_counts: Dictionary = {}
var artifact_target_group_offers: Dictionary = {}
var artifact_target_group_selections: Dictionary = {}
var artifact_events: Array[Dictionary] = []
var artifact_draft_events: Array[Dictionary] = []
var artifact_inventory_completed_at: float = -1.0

func _init() -> void:
	configure_lanes(Battlefield.LANE_COUNT)

func configure_lanes(lane_count: int) -> void:
	var safe_count := maxi(lane_count, 1)
	lane_spawns.resize(safe_count)
	lane_spawns.fill(0)
	lane_reaches.resize(safe_count)
	lane_reaches.fill(0)
	cursor_lane_seconds.resize(safe_count)
	cursor_lane_seconds.fill(0.0)

func update_time(value: float) -> void:
	elapsed = value

func record_runtime_frame(game_delta: float, real_delta: float, speed: float) -> void:
	var safe_real_delta := maxf(real_delta, 0.0)
	runtime_frame_count += 1
	runtime_game_seconds += maxf(game_delta, 0.0)
	runtime_real_seconds += safe_real_delta
	var frame_ms := safe_real_delta * 1000.0
	worst_frame_ms = maxf(worst_frame_ms, frame_ms)
	if frame_ms > 16.667:
		frames_over_16_ms += 1
	if frame_ms > 33.333:
		frames_over_33_ms += 1
	var speed_key := "%.0fx" % clampf(speed, 1.0, 3.0)
	real_seconds_by_speed[speed_key] = float(real_seconds_by_speed.get(speed_key, 0.0)) + safe_real_delta

func record_scene_load(active_enemies: int, projectiles: int, effects: int, summons: int = 0, summon_budget_cost: int = 0) -> void:
	peak_active_enemies = maxi(peak_active_enemies, active_enemies)
	peak_projectiles = maxi(peak_projectiles, projectiles)
	peak_effects = maxi(peak_effects, effects)
	peak_summons = maxi(peak_summons, summons)
	peak_summon_budget_cost = maxi(peak_summon_budget_cost, summon_budget_cost)

func record_effect_budget(priority: StringName, spawned: bool) -> void:
	var key := String(priority)
	var target := effect_budget_spawned if spawned else effect_budget_dropped
	target[key] = int(target.get(key, 0)) + 1

func record_mechanic_event(key: StringName, amount: float = 1.0) -> void:
	if key == &"" or amount <= 0.0:
		return
	var text_key := String(key)
	mechanic_events[text_key] = int(mechanic_events.get(text_key, 0)) + 1
	mechanic_totals[text_key] = float(mechanic_totals.get(text_key, 0.0)) + amount

func record_mechanic_sample(key: StringName, value: float) -> void:
	if key == &"":
		return
	var text_key := String(key)
	mechanic_sample_sums[text_key] = float(mechanic_sample_sums.get(text_key, 0.0)) + value
	mechanic_sample_counts[text_key] = int(mechanic_sample_counts.get(text_key, 0)) + 1
	mechanic_sample_peaks[text_key] = maxf(float(mechanic_sample_peaks.get(text_key, value)), value)

func record_spawn(lane_index: int) -> void:
	var period := _period_key()
	spawned_by_period[period] = int(spawned_by_period.get(period, 0)) + 1
	if lane_index >= 0 and lane_index < lane_spawns.size():
		lane_spawns[lane_index] += 1

func record_enemy_spawn(lane_index: int, enemy_data: EnemyData, context: EnemySpawnContext = null, enemy_instance_id: int = 0) -> void:
	record_spawn(lane_index)
	if enemy_data == null:
		return
	var event := _enemy_event_base(enemy_data, lane_index, context)
	event["event"] = "spawn"
	event["enemy_instance_id"] = enemy_instance_id
	enemy_spawn_events.append(event)

func record_enemy_defeat(lane_index: int, enemy_data: EnemyData, context: EnemySpawnContext = null, death_cause: StringName = &"direct_kill", enemy_instance_id: int = 0) -> void:
	if enemy_data == null:
		return
	var event := _enemy_event_base(enemy_data, lane_index, context)
	event["event"] = "death"
	event["death_cause"] = String(death_cause)
	event["enemy_instance_id"] = enemy_instance_id
	enemy_exit_events.append(event)

func record_enemy_breach(lane_index: int, enemy_data: EnemyData, context: EnemySpawnContext = null, enemy_instance_id: int = 0) -> void:
	record_reach(lane_index)
	if enemy_data == null:
		return
	var event := _enemy_event_base(enemy_data, lane_index, context)
	event["event"] = "breach"
	event["death_cause"] = "none"
	event["enemy_instance_id"] = enemy_instance_id
	enemy_exit_events.append(event)

func record_enemy_acceleration(enemy_data: EnemyData, context: EnemySpawnContext, acceleration_kind: StringName, stacks: int, speed_bonus: float, duration: float) -> void:
	if enemy_data == null or acceleration_kind == &"" or stacks <= 0:
		return
	var event := _enemy_event_base(enemy_data, -1, context)
	event.merge({
		"event": "acceleration",
		"kind": String(acceleration_kind),
		"stacks": stacks,
		"speed_bonus": maxf(speed_bonus, 0.0),
		"duration": maxf(duration, 0.0),
	}, true)
	enemy_acceleration_events.append(event)

func record_defender_disable(source_enemy: EnemyData, context: EnemySpawnContext, effect: StringName, duration: float, targets: Array[String]) -> void:
	if source_enemy == null or effect == &"" or targets.is_empty():
		return
	var event := _enemy_event_base(source_enemy, -1, context)
	event.merge({
		"event": "defender_disable",
		"effect": String(effect),
		"duration": maxf(duration, 0.0),
		"target_count": targets.size(),
		"targets": targets.duplicate(),
		"effective_seconds": maxf(duration, 0.0) * float(targets.size()),
	}, true)
	defender_disable_events.append(event)

func enemy_activity_snapshot() -> Dictionary:
	return {
		"spawns": enemy_spawn_events.duplicate(true),
		"exits": enemy_exit_events.duplicate(true),
		"accelerations": enemy_acceleration_events.duplicate(true),
		"defender_disables": defender_disable_events.duplicate(true),
		"spawn_count": enemy_spawn_events.size(),
		"death_count": enemy_exit_events.filter(func(event: Dictionary) -> bool: return event.get("event", "") == "death").size(),
		"breach_count": enemy_exit_events.filter(func(event: Dictionary) -> bool: return event.get("event", "") == "breach").size(),
	}

func record_level_reached(level: int, total_experience: float) -> void:
	level_reach_events.append({"level": maxi(level, 1), "elapsed": elapsed, "total_experience": maxf(total_experience, 0.0)})

func growth_timeline_snapshot() -> Dictionary:
	var first_by_track := {}
	for event in upgrade_selection_events:
		var track := String(event.get("track", "other"))
		if not first_by_track.has(track):
			first_by_track[track] = float(event.get("elapsed", 0.0))
	var first_offer_by_track := {}
	for event in overgrowth_offer_events:
		var track := String(event.get("track", "other"))
		if not first_offer_by_track.has(track):
			first_offer_by_track[track] = float(event.get("elapsed", 0.0))
	return {
		"levels": level_reach_events.duplicate(true),
		"offers": overgrowth_offer_events.duplicate(true),
		"upgrades": upgrade_selection_events.duplicate(true),
		"first_offer_by_track": first_offer_by_track,
		"first_upgrade_by_track": first_by_track,
	}

func record_enemy_control(enemy_data: EnemyData, control_type: StringName, accepted: bool, requested_effect: float, effective_effect: float, requested_duration: float, effective_duration: float) -> void:
	if enemy_data == null or control_type == &"":
		return
	var key := "%s:%s:%s" % [enemy_data.id, control_type, "boss" if enemy_data.is_boss else "normal"]
	var entry := enemy_control_totals.get(key, {
		"enemy_id": String(enemy_data.id), "control_type": String(control_type), "is_boss": enemy_data.is_boss,
		"attempts": 0, "successes": 0, "requested_effect_total": 0.0, "effective_effect_total": 0.0,
		"requested_duration_total": 0.0, "effective_duration_total": 0.0,
	}) as Dictionary
	entry.attempts = int(entry.attempts) + 1
	entry.successes = int(entry.successes) + (1 if accepted else 0)
	entry.requested_effect_total = float(entry.requested_effect_total) + maxf(requested_effect, 0.0)
	entry.effective_effect_total = float(entry.effective_effect_total) + maxf(effective_effect, 0.0)
	entry.requested_duration_total = float(entry.requested_duration_total) + maxf(requested_duration, 0.0)
	entry.effective_duration_total = float(entry.effective_duration_total) + maxf(effective_duration, 0.0)
	enemy_control_totals[key] = entry

func control_effectiveness_snapshot() -> Dictionary:
	var entries: Array[Dictionary] = []
	var hard_counter_warnings: Array[String] = []
	var keys := enemy_control_totals.keys()
	keys.sort()
	for key in keys:
		var entry := (enemy_control_totals[key] as Dictionary).duplicate(true)
		var attempts := maxi(int(entry.attempts), 1)
		var requested_effect := float(entry.requested_effect_total)
		var requested_duration := float(entry.requested_duration_total)
		entry["success_rate"] = float(entry.successes) / attempts
		entry["effect_ratio"] = float(entry.effective_effect_total) / requested_effect if requested_effect > 0.0 else 0.0
		entry["duration_ratio"] = float(entry.effective_duration_total) / requested_duration if requested_duration > 0.0 else 0.0
		if int(entry.successes) == 0:
			hard_counter_warnings.append("%s:%s" % [entry.enemy_id, entry.control_type])
		entries.append(entry)
	return {"by_enemy_control": entries, "hard_counter_warnings": hard_counter_warnings, "warning_count": hard_counter_warnings.size()}

func record_experience_drop(channel: StringName, raw_value: float) -> void:
	var key := String(channel)
	experience_drop_by_channel[key] = float(experience_drop_by_channel.get(key, 0.0)) + maxf(raw_value, 0.0)

func record_experience_collection(channel: StringName, raw_value: float, awarded_value: float) -> void:
	var key := String(channel)
	experience_collected_raw_by_channel[key] = float(experience_collected_raw_by_channel.get(key, 0.0)) + maxf(raw_value, 0.0)
	experience_awarded_by_channel[key] = float(experience_awarded_by_channel.get(key, 0.0)) + maxf(awarded_value, 0.0)

func experience_attribution_snapshot() -> Dictionary:
	var channels: Array[String] = []
	for source in [experience_drop_by_channel, experience_collected_raw_by_channel, experience_awarded_by_channel]:
		for raw_channel in source:
			var channel := String(raw_channel)
			if channel not in channels:
				channels.append(channel)
	channels.sort()
	var by_channel := {}
	var dropped_total := 0.0
	var collected_raw_total := 0.0
	var awarded_total := 0.0
	for channel in channels:
		var dropped := maxf(float(experience_drop_by_channel.get(channel, 0.0)), 0.0)
		var collected_raw := maxf(float(experience_collected_raw_by_channel.get(channel, 0.0)), 0.0)
		var awarded := maxf(float(experience_awarded_by_channel.get(channel, 0.0)), 0.0)
		by_channel[channel] = {
			"dropped": dropped,
			"collected_raw": collected_raw,
			"awarded": awarded,
			"collection_rate": collected_raw / dropped if dropped > 0.0 else 0.0,
		}
		dropped_total += dropped
		collected_raw_total += collected_raw
		awarded_total += awarded
	return {
		"by_channel": by_channel,
		"dropped_total": dropped_total,
		"collected_raw_total": collected_raw_total,
		"awarded_total": awarded_total,
		"collection_rate": collected_raw_total / dropped_total if dropped_total > 0.0 else 0.0,
	}

func enemy_removal_snapshot() -> Dictionary:
	var spawned_at := {}
	for event in enemy_spawn_events:
		var instance_id := int(event.get("enemy_instance_id", 0))
		if instance_id > 0:
			spawned_at[instance_id] = float(event.get("elapsed", 0.0))
	var totals := {}
	for event in enemy_exit_events:
		var instance_id := int(event.get("enemy_instance_id", 0))
		if instance_id <= 0 or not spawned_at.has(instance_id):
			continue
		var enemy_id := String(event.get("enemy_id", ""))
		var entry := totals.get(enemy_id, {"enemy_id": enemy_id, "removed": 0, "deaths": 0, "breaches": 0, "lifetime_total": 0.0, "lifetime_peak": 0.0}) as Dictionary
		var lifetime := maxf(float(event.get("elapsed", 0.0)) - float(spawned_at[instance_id]), 0.0)
		entry.removed = int(entry.removed) + 1
		entry.deaths = int(entry.deaths) + (1 if event.get("event", "") == "death" else 0)
		entry.breaches = int(entry.breaches) + (1 if event.get("event", "") == "breach" else 0)
		entry.lifetime_total = float(entry.lifetime_total) + lifetime
		entry.lifetime_peak = maxf(float(entry.lifetime_peak), lifetime)
		totals[enemy_id] = entry
	var result: Array[Dictionary] = []
	var enemy_ids := totals.keys()
	enemy_ids.sort()
	for enemy_id in enemy_ids:
		var entry := totals[enemy_id] as Dictionary
		entry["average_time_to_remove"] = float(entry.lifetime_total) / maxi(int(entry.removed), 1)
		entry["breach_rate"] = float(entry.breaches) / maxi(int(entry.removed), 1)
		entry.erase("lifetime_total")
		result.append(entry)
	return {"by_enemy": result}

func _enemy_event_base(enemy_data: EnemyData, lane_index: int, context: EnemySpawnContext) -> Dictionary:
	var event := {
		"elapsed": elapsed,
		"enemy_id": String(enemy_data.id),
		"behavior": String(enemy_data.behavior),
		"is_boss": enemy_data.is_boss,
		"lane_index": lane_index,
	}
	if context != null:
		event.merge(context.to_snapshot(), true)
	return event

func record_kill(lane_index: int, enemy_data: EnemyData = null) -> void:
	var period := _period_key()
	killed_by_period[period] = int(killed_by_period.get(period, 0)) + 1
	if enemy_data != null:
		var enemy_id := String(enemy_data.id)
		var behavior := String(enemy_data.behavior)
		kills_by_enemy_id[enemy_id] = int(kills_by_enemy_id.get(enemy_id, 0)) + 1
		kills_by_behavior[behavior] = int(kills_by_behavior.get(behavior, 0)) + 1
	recent_kill_times.append(elapsed)
	while not recent_kill_times.is_empty() and elapsed - recent_kill_times[0] > 2.0:
		recent_kill_times.pop_front()
	if recent_kill_times.size() >= 10:
		burst_ten_kill_windows += 1
		recent_kill_times.clear()

func record_reach(lane_index: int) -> void:
	reached_core_count += 1
	if elapsed <= 300.0:
		reaches_before_five_minutes += 1
	if lane_index >= 0 and lane_index < lane_reaches.size():
		lane_reaches[lane_index] += 1
	if first_core_damage_at < 0.0:
		first_core_damage_at = elapsed

func record_tower_attack(tower_id: StringName, guard_formation_id: StringName = &"") -> void:
	var key := String(tower_id)
	tower_attacks[key] = int(tower_attacks.get(key, 0)) + 1
	if guard_formation_id != &"":
		var guard := _guard_combat_entry(guard_formation_id)
		guard.attacks = int(guard.attacks) + 1
		var guard_tower := _guard_tower_combat_entry(guard, key)
		guard_tower.attacks = int(guard_tower.attacks) + 1

func record_tower_hit(
	tower_id: StringName,
	damage: float,
	kills: int,
	hit_count: int = 1,
	long_range_kills: int = 0,
	guard_formation_id: StringName = &"",
	guard_control_applications: int = 0
) -> void:
	var key := String(tower_id)
	tower_damage[key] = float(tower_damage.get(key, 0.0)) + damage
	tower_hits[key] = int(tower_hits.get(key, 0)) + maxi(hit_count, 0)
	if hit_count >= 2:
		tower_multi_hit_events[key] = int(tower_multi_hit_events.get(key, 0)) + 1
	if kills > 0:
		tower_kills[key] = int(tower_kills.get(key, 0)) + kills
	if long_range_kills > 0:
		tower_long_range_kills[key] = int(tower_long_range_kills.get(key, 0)) + long_range_kills
	if guard_formation_id != &"":
		var guard := _guard_combat_entry(guard_formation_id)
		guard.hits = int(guard.hits) + maxi(hit_count, 0)
		guard.damage = float(guard.damage) + maxf(damage, 0.0)
		guard.kills = int(guard.kills) + maxi(kills, 0)
		guard.control_applications = int(guard.control_applications) + maxi(guard_control_applications, 0)
		var guard_tower := _guard_tower_combat_entry(guard, key)
		guard_tower.hits = int(guard_tower.hits) + maxi(hit_count, 0)
		guard_tower.damage = float(guard_tower.damage) + maxf(damage, 0.0)
		guard_tower.kills = int(guard_tower.kills) + maxi(kills, 0)
		guard_tower.control_applications = int(guard_tower.control_applications) + maxi(guard_control_applications, 0)

func _guard_combat_entry(formation_id: StringName) -> Dictionary:
	var key := String(formation_id)
	if not guard_combat.has(key):
		guard_combat[key] = {"attacks": 0, "hits": 0, "damage": 0.0, "kills": 0, "control_applications": 0, "by_tower": {}}
	return guard_combat[key] as Dictionary

func _guard_tower_combat_entry(guard: Dictionary, tower_id: String) -> Dictionary:
	var by_tower := guard.get("by_tower", {}) as Dictionary
	if not by_tower.has(tower_id):
		by_tower[tower_id] = {"attacks": 0, "hits": 0, "damage": 0.0, "kills": 0, "control_applications": 0}
	guard["by_tower"] = by_tower
	return by_tower[tower_id] as Dictionary

func record_damage_received(amount: float, source_type: StringName, enemy_data: EnemyData) -> void:
	if amount <= 0.0 or enemy_data == null:
		return
	var source_key := String(source_type)
	damage_by_source_type[source_key] = float(damage_by_source_type.get(source_key, 0.0)) + amount
	if enemy_data.is_boss:
		boss_damage += amount
	var status_id := _status_id_from_damage_source(source_type)
	if status_id != &"":
		var key := String(status_id)
		status_damage[key] = float(status_damage.get(key, 0.0)) + amount

func record_status_application(status_id: StringName, count: int = 1) -> void:
	if status_id == &"" or count <= 0:
		return
	var key := String(status_id)
	status_applications[key] = int(status_applications.get(key, 0)) + count

func status_contribution_snapshot() -> Dictionary:
	var remaining_ids: Array[String] = []
	for raw_status_id in status_applications:
		var status_id := String(raw_status_id)
		if status_id not in remaining_ids:
			remaining_ids.append(status_id)
	for raw_status_id in status_damage:
		var status_id := String(raw_status_id)
		if status_id not in remaining_ids:
			remaining_ids.append(status_id)
	remaining_ids.sort()
	var ordered_ids: Array[String] = []
	for common_status_id in CommonStatusCatalog.STATUS_IDS:
		var status_id := String(common_status_id)
		if status_id in remaining_ids:
			ordered_ids.append(status_id)
			remaining_ids.erase(status_id)
	ordered_ids.append_array(remaining_ids)
	var entries: Array[Dictionary] = []
	var total_applications := 0
	var total_damage := 0.0
	var top_status_id := ""
	var top_damage := -1.0
	var top_applications := -1
	for status_id in ordered_ids:
		var applications := maxi(int(status_applications.get(status_id, 0)), 0)
		var damage := maxf(float(status_damage.get(status_id, 0.0)), 0.0)
		entries.append({"status_id": status_id, "applications": applications, "damage": damage})
		total_applications += applications
		total_damage += damage
		if damage > top_damage or (is_equal_approx(damage, top_damage) and applications > top_applications):
			top_status_id = status_id
			top_damage = damage
			top_applications = applications
	return {
		"active_status_count": entries.size(),
		"total_applications": total_applications,
		"total_damage": total_damage,
		"top_status_id": top_status_id,
		"top_applications": maxi(top_applications, 0),
		"top_damage": maxf(top_damage, 0.0),
		"by_status": entries,
	}

func record_cursor_damage(damage: float) -> void:
	cursor_damage += damage

func record_retainer_control(count: int = 1) -> void:
	retainer_control_applications += maxi(count, 0)

func record_retainer_collection(experience_value: float) -> void:
	retainer_collection_experience += maxf(experience_value, 0.0)

func record_spawn_director_snapshot(snapshot: Dictionary) -> void:
	spawn_director_metrics = snapshot.duplicate(true)

func retainer_contribution_snapshot(retainer_id: StringName) -> Dictionary:
	var role := "전투 지원"
	var unique_uses := 0
	var executions := int(mechanic_events.get("vanguard_execution", 0))
	match retainer_id:
		&"kanda":
			role = "근접·상태"
			unique_uses = int(mechanic_events.get("kanda_final_slash", 0)) + int(mechanic_events.get("retainer_poison_applied", 0)) + int(mechanic_events.get("retainer_bleed_applied", 0)) + int(mechanic_events.get("retainer_shock_applied", 0))
		&"given":
			role = "출혈·환혹"
			unique_uses = int(mechanic_events.get("given_charm_roll", 0)) + int(mechanic_events.get("given_edge_knockback", 0))
		&"jeomujeom":
			role = "영역·공포"
			unique_uses = int(mechanic_events.get("jeomujeom_resummon", 0)) + int(mechanic_events.get("jeomujeom_fear_spread", 0))
		&"jugdied":
			role = "합동 돌격"
			unique_uses = int(mechanic_events.get("combo_cast", 0))
		&"death_vanguard":
			role = "부대·처형"
			unique_uses = int(mechanic_events.get("vanguard_timed_sacrifice", 0)) + int(mechanic_events.get("vanguard_reaper_snapshot", 0))
	return {
		"retainer_id": String(retainer_id),
		"role": role,
		"damage": cursor_damage,
		"control_applications": retainer_control_applications,
		"collection_experience": retainer_collection_experience,
		"executions": executions,
		"unique_uses": unique_uses,
	}

func record_cursor_lane(lane_index: int, delta: float) -> void:
	if lane_index >= 0 and lane_index < cursor_lane_seconds.size():
		cursor_lane_seconds[lane_index] += delta

func record_choices(choices: Array[UpgradeData]) -> void:
	for choice in choices:
		var key := choice.display_name
		unselected_upgrades[key] = int(unselected_upgrades.get(key, 0)) + 1
		var stable_key := _upgrade_metric_key(choice)
		upgrade_offers_by_id[stable_key] = int(upgrade_offers_by_id.get(stable_key, 0)) + 1
		if choice.category in [&"candidate_overgrowth", &"retainer_overgrowth"]:
			overgrowth_offer_events.append({"elapsed": elapsed, "category": String(choice.category), "data_id": String(choice.data_id), "track": _growth_track(choice.category)})
		if _is_specialization_choice(choice):
			specialization_offers[stable_key] = int(specialization_offers.get(stable_key, 0)) + 1
		if choice.category == &"artifact":
			_record_artifact_offer(choice)

func record_selection(choice: UpgradeData) -> void:
	var key := choice.display_name
	selected_upgrades[key] = int(selected_upgrades.get(key, 0)) + 1
	unselected_upgrades[key] = maxi(int(unselected_upgrades.get(key, 1)) - 1, 0)
	var stable_key := _upgrade_metric_key(choice)
	upgrade_selections_by_id[stable_key] = int(upgrade_selections_by_id.get(stable_key, 0)) + 1
	if _is_specialization_choice(choice):
		specialization_selections[stable_key] = int(specialization_selections.get(stable_key, 0)) + 1
	upgrade_selection_events.append({"elapsed": elapsed, "category": String(choice.category), "data_id": String(choice.data_id), "track": _growth_track(choice.category)})

func record_artifact_decision(artifact: ArtifactData, action: StringName, inventory_snapshot: Dictionary, replaced_artifact_id: StringName = &"") -> void:
	if artifact == null or action not in [&"acquired", &"replaced", &"discarded"]:
		return
	var artifact_id := String(artifact.id)
	match action:
		&"acquired": artifact_acquisition_counts[artifact_id] = int(artifact_acquisition_counts.get(artifact_id, 0)) + 1
		&"replaced":
			artifact_acquisition_counts[artifact_id] = int(artifact_acquisition_counts.get(artifact_id, 0)) + 1
			artifact_replacement_counts[artifact_id] = int(artifact_replacement_counts.get(artifact_id, 0)) + 1
		&"discarded": artifact_discard_counts[artifact_id] = int(artifact_discard_counts.get(artifact_id, 0)) + 1
	if action != &"discarded":
		for target_group in _artifact_target_groups(artifact):
			artifact_target_group_selections[target_group] = int(artifact_target_group_selections.get(target_group, 0)) + 1
	var inventory_ids := (inventory_snapshot.get("artifact_ids", []) as Array).duplicate()
	if action != &"discarded" and artifact_inventory_completed_at < 0.0 and inventory_ids.size() >= ArtifactInventoryState.DEFAULT_CAPACITY:
		artifact_inventory_completed_at = elapsed
	artifact_events.append({
		"elapsed": elapsed,
		"event": String(action),
		"artifact_id": artifact_id,
		"replaced_artifact_id": String(replaced_artifact_id),
		"target_groups": _artifact_target_groups(artifact),
		"effects": _artifact_effect_snapshot(artifact),
		"trade_off": artifact.has_trade_off(),
		"inventory_count": inventory_ids.size(),
		"inventory_ids": inventory_ids,
	})

func record_artifact_draft(tier: int, choices: Array[UpgradeData]) -> void:
	var choice_ids: Array[String] = []
	for choice in choices:
		if choice != null and choice.category == &"artifact":
			choice_ids.append(String(choice.data_id))
	artifact_draft_events.append({
		"elapsed": elapsed,
		"tier": maxi(tier, 1),
		"choice_ids": choice_ids,
	})

func artifact_metrics_snapshot(loadout: LoadoutManager = null) -> Dictionary:
	var final_inventory := loadout.get_artifact_snapshot() if loadout != null else _artifact_final_inventory_from_events()
	var offers := _sum_int_dictionary(artifact_offer_counts)
	var acquisitions := _sum_int_dictionary(artifact_acquisition_counts)
	var discards := _sum_int_dictionary(artifact_discard_counts)
	var replacements := _sum_int_dictionary(artifact_replacement_counts)
	var by_artifact: Dictionary = {}
	var artifact_ids: Array[String] = []
	for source in [artifact_offer_counts, artifact_acquisition_counts, artifact_discard_counts, artifact_replacement_counts]:
		for raw_id in source:
			var artifact_id := String(raw_id)
			if artifact_id not in artifact_ids:
				artifact_ids.append(artifact_id)
	artifact_ids.sort()
	for artifact_id in artifact_ids:
		var artifact_offers := int(artifact_offer_counts.get(artifact_id, 0))
		var artifact_acquisitions := int(artifact_acquisition_counts.get(artifact_id, 0))
		var artifact_discards := int(artifact_discard_counts.get(artifact_id, 0))
		by_artifact[artifact_id] = {
			"offers": artifact_offers,
			"acquisitions": artifact_acquisitions,
			"discards": artifact_discards,
			"replacements": int(artifact_replacement_counts.get(artifact_id, 0)),
			"selection_rate": float(artifact_acquisitions) / float(artifact_offers) if artifact_offers > 0 else 0.0,
			"discard_rate": float(artifact_discards) / float(artifact_offers) if artifact_offers > 0 else 0.0,
		}
	return {
		"offers": offers,
		"acquisitions": acquisitions,
		"discards": discards,
		"replacements": replacements,
		"selection_rate": float(acquisitions) / float(offers) if offers > 0 else 0.0,
		"discard_rate": float(discards) / float(offers) if offers > 0 else 0.0,
		"inventory_completed_at": artifact_inventory_completed_at,
		"final_inventory": final_inventory.duplicate(true),
		"by_artifact": by_artifact,
		"target_group_offers": artifact_target_group_offers.duplicate(true),
		"target_group_selections": artifact_target_group_selections.duplicate(true),
		"events": artifact_events.duplicate(true),
		"elite_draft_count": artifact_draft_events.size(),
		"elite_drafts": artifact_draft_events.duplicate(true),
		"effect_contribution": _artifact_effect_contribution(loadout, final_inventory),
	}

func _record_artifact_offer(choice: UpgradeData) -> void:
	var artifact_id := String(choice.data_id)
	artifact_offer_counts[artifact_id] = int(artifact_offer_counts.get(artifact_id, 0)) + 1
	var target_groups: Array = (choice.offer_metadata.get("target_groups", []) as Array).duplicate()
	for target_group_value in target_groups:
		var target_group := String(target_group_value)
		artifact_target_group_offers[target_group] = int(artifact_target_group_offers.get(target_group, 0)) + 1
	artifact_events.append({
		"elapsed": elapsed,
		"event": "offered",
		"artifact_id": artifact_id,
		"target_groups": target_groups,
		"effects": (choice.offer_metadata.get("effects", []) as Array).duplicate(true),
		"trade_off": bool(choice.offer_metadata.get("trade_off", false)),
		"source": String(choice.offer_metadata.get("source", &"level_up")),
	})

func _artifact_target_groups(artifact: ArtifactData) -> Array[String]:
	var result: Array[String] = []
	for effect in artifact.effects:
		if effect != null and String(effect.target_group) not in result:
			result.append(String(effect.target_group))
	return result

func _artifact_effect_snapshot(artifact: ArtifactData) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for effect in artifact.effects:
		if effect == null:
			continue
		result.append({
			"target_group": String(effect.target_group),
			"stat_key": String(effect.stat_key),
			"axis_id": String(effect.axis_id),
			"status_id": String(effect.status_id),
			"value_mode": String(effect.value_mode),
			"value": effect.value,
		})
	return result

func _artifact_final_inventory_from_events() -> Dictionary:
	for index in range(artifact_events.size() - 1, -1, -1):
		var event := artifact_events[index]
		if event.has("inventory_ids"):
			var ids := (event.get("inventory_ids", []) as Array).duplicate()
			return {"capacity": ArtifactInventoryState.DEFAULT_CAPACITY, "count": ids.size(), "artifact_ids": ids}
	return {"capacity": ArtifactInventoryState.DEFAULT_CAPACITY, "count": 0, "artifact_ids": []}

func _artifact_effect_contribution(loadout: LoadoutManager, final_inventory: Dictionary) -> Dictionary:
	if loadout == null or loadout.artifact_catalog == null:
		return {"method": "proportional_observed_output_v1", "estimated_output_delta": 0.0, "by_artifact": {}}
	var uptime := _artifact_uptime_snapshot(final_inventory)
	var regular_tower_damage := 0.0
	for value in tower_damage.values():
		regular_tower_damage += maxf(float(value), 0.0)
	var guard_damage := 0.0
	for guard_value in guard_combat.values():
		guard_damage += maxf(float((guard_value as Dictionary).get("damage", 0.0)), 0.0)
	regular_tower_damage = maxf(regular_tower_damage - guard_damage, 0.0)
	var candidate_damage := 0.0
	for raw_source in damage_by_source_type:
		var source := String(raw_source)
		if source.begins_with("core") or source.begins_with("irelai_") or source.begins_with("kasuha_") or source == "tutorial_candidate_skill":
			candidate_damage += maxf(float(damage_by_source_type[raw_source]), 0.0)
	var by_artifact: Dictionary = {}
	var total_estimate := 0.0
	for raw_artifact_id in uptime:
		var artifact_id := StringName(raw_artifact_id)
		var artifact := loadout.artifact_catalog.find_artifact(artifact_id)
		if artifact == null:
			continue
		var duration := maxf(float(uptime[raw_artifact_id]), 0.0)
		var uptime_ratio := clampf(duration / maxf(elapsed, 0.001), 0.0, 1.0)
		var effects: Array[Dictionary] = []
		var artifact_estimate := 0.0
		for effect in artifact.effects:
			if effect == null:
				continue
			var observed := _artifact_observed_output(effect, regular_tower_damage, candidate_damage, guard_damage)
			var estimate := 0.0
			if effect.value_mode == ArtifactEffectData.MULTIPLIER_BONUS and observed > 0.0:
				estimate = observed * uptime_ratio * effect.value / maxf(1.0 + effect.value, 0.01)
			artifact_estimate += estimate
			effects.append({"target_group": String(effect.target_group), "stat_key": String(effect.stat_key), "status_id": String(effect.status_id), "value": effect.value, "observed_output": observed, "estimated_output_delta": estimate})
		total_estimate += artifact_estimate
		by_artifact[String(artifact_id)] = {"active_seconds": duration, "uptime_ratio": uptime_ratio, "estimated_output_delta": artifact_estimate, "effects": effects}
	return {"method": "proportional_observed_output_v1", "estimated_output_delta": total_estimate, "by_artifact": by_artifact}

func _artifact_observed_output(effect: ArtifactEffectData, regular_tower_damage: float, candidate_damage: float, guard_damage: float) -> float:
	match effect.target_group:
		&"normal_defender": return regular_tower_damage if effect.stat_key in [&"power", &"speed"] else 0.0
		&"candidate": return candidate_damage if effect.stat_key in [&"damage", &"skill"] else 0.0
		&"retainer": return cursor_damage if effect.stat_key in [&"damage", &"action_speed"] else 0.0
		&"guard": return guard_damage if effect.stat_key in [&"damage", &"action_speed"] else 0.0
		&"status": return maxf(float(status_damage.get(String(effect.status_id), 0.0)), 0.0) if effect.stat_key == &"damage" else 0.0
	return 0.0

func _artifact_uptime_snapshot(final_inventory: Dictionary) -> Dictionary:
	var active_since: Dictionary = {}
	var duration_by_id: Dictionary = {}
	var current_ids: Array[String] = []
	for event in artifact_events:
		if not event.has("inventory_ids"):
			continue
		var next_ids: Array[String] = []
		for raw_id in event.get("inventory_ids", []) as Array:
			next_ids.append(String(raw_id))
		var at := clampf(float(event.get("elapsed", 0.0)), 0.0, elapsed)
		for artifact_id in current_ids:
			if artifact_id not in next_ids:
				duration_by_id[artifact_id] = float(duration_by_id.get(artifact_id, 0.0)) + maxf(at - float(active_since.get(artifact_id, at)), 0.0)
				active_since.erase(artifact_id)
		for artifact_id in next_ids:
			if artifact_id not in current_ids:
				active_since[artifact_id] = at
		current_ids = next_ids
	if artifact_events.is_empty():
		for raw_id in final_inventory.get("artifact_ids", []) as Array:
			active_since[String(raw_id)] = 0.0
	for artifact_id in active_since:
		duration_by_id[artifact_id] = float(duration_by_id.get(artifact_id, 0.0)) + maxf(elapsed - float(active_since[artifact_id]), 0.0)
	return duration_by_id

func _sum_int_dictionary(values: Dictionary) -> int:
	var result := 0
	for value in values.values():
		result += maxi(int(value), 0)
	return result

func _growth_track(category: StringName) -> String:
	if category == &"artifact":
		return "artifact"
	if category in [&"candidate_branch", &"candidate_overgrowth"]:
		return "candidate"
	if category in [&"cursor_level", &"cursor_specialization_entry", &"cursor_branch", &"retainer_overgrowth"]:
		return "retainer"
	if category in [&"guard_training", &"guard_specialization_entry", &"guard_branch", &"guard_completion"]:
		return "guard"
	if category in [&"formation_set", &"new_formation"]:
		return "formation"
	if category in [&"tower_type_level", &"tower_specialization_entry", &"tower_branch"]:
		return "defender"
	return "other"

func upgrade_choice_metrics_snapshot() -> Dictionary:
	return {
		"offers_by_id": upgrade_offers_by_id,
		"selections_by_id": upgrade_selections_by_id,
		"specialization_offers": specialization_offers,
		"specialization_selections": specialization_selections,
		"specialization_selection_rates": _selection_rate_snapshot(specialization_offers, specialization_selections),
	}

func _upgrade_metric_key(choice: UpgradeData) -> String:
	return "%s:%s" % [choice.category, choice.data_id]

func _is_specialization_choice(choice: UpgradeData) -> bool:
	return choice.category in [
		&"tower_specialization_entry", &"core_specialization_entry", &"cursor_specialization_entry",
		&"tower_branch", &"core_branch", &"cursor_branch",
		&"guard_training", &"guard_specialization_entry", &"guard_branch", &"guard_completion",
	]

func record_formation_set_offer(size: int) -> void:
	var key := str(clampi(size, 2, 4))
	formation_set_offers_by_size[key] = int(formation_set_offers_by_size.get(key, 0)) + 1

func record_formation_set_selection(size: int) -> void:
	var key := str(clampi(size, 2, 4))
	formation_set_selections_by_size[key] = int(formation_set_selections_by_size.get(key, 0)) + 1

func record_formation_offer(formation_id: StringName, valid_position_count: int, metadata: Dictionary = {}) -> void:
	var key := String(formation_id)
	var safe_valid_position_count := maxi(int(metadata.get("valid_position_count", valid_position_count)), 0)
	formation_offers[key] = int(formation_offers.get(key, 0)) + 1
	formation_valid_position_totals[key] = int(formation_valid_position_totals.get(key, 0)) + safe_valid_position_count
	formation_offer_context_events.append({
		"elapsed": elapsed,
		"formation_id": key,
		"slot_type": String(metadata.get("slot_type", "legacy")),
		"discovery_bonus": bool(metadata.get("discovery_bonus", false)),
		"recent_penalty": bool(metadata.get("recent_penalty", false)),
		"primary_role": String(metadata.get("primary_role", "basic")),
		"role_duplicate": bool(metadata.get("role_duplicate", false)),
		"eligible_pool_size": maxi(int(metadata.get("eligible_pool_size", 0)), 0),
		"shape_class": String(metadata.get("shape_class", "")),
		"distinct_tower_count": maxi(int(metadata.get("distinct_tower_count", 0)), 0),
		"valid_position_count": safe_valid_position_count,
	})

func record_formation_selection(formation: TowerFormationData, placement_seconds: float, anchor: Vector2i, vertical_flipped: bool, board_state: FormationBoardState, metadata: Dictionary = {}) -> void:
	if formation == null:
		return
	var key := String(formation.id)
	formation_selections[key] = int(formation_selections.get(key, 0)) + 1
	formation_placement_seconds[key] = float(formation_placement_seconds.get(key, 0.0)) + maxf(placement_seconds, 0.0)
	formation_selection_events.append(_formation_decision_event(formation, anchor, vertical_flipped, board_state, {
		"placement_seconds": maxf(placement_seconds, 0.0),
		"valid_position_count": maxi(int(metadata.get("valid_position_count", 0)), 0),
	}))
	if vertical_flipped:
		formation_vertical_flips += 1
	record_board_state(board_state)

func record_formation_abandon(formation: TowerFormationData, refund: float, board_state: FormationBoardState, metadata: Dictionary = {}) -> void:
	if formation == null:
		return
	var key := String(formation.id)
	var size_key := str(clampi(formation.cells.size(), 2, 4))
	formation_abandons[key] = int(formation_abandons.get(key, 0)) + 1
	formation_set_abandons_by_size[size_key] = int(formation_set_abandons_by_size.get(size_key, 0)) + 1
	formation_abandon_events.append(_formation_decision_event(formation, Vector2i(-1, -1), false, board_state, {
		"refund_experience": maxf(refund, 0.0),
		"valid_position_count": maxi(int(metadata.get("valid_position_count", 0)), 0),
	}))
	record_mechanic_event(&"formation_xp_refunded", refund)
	record_board_state(board_state)

func record_guard_placement(candidate_id: StringName, anchor: Vector2i, vertical_flipped: bool, board_state: FormationBoardState) -> void:
	var key := String(candidate_id)
	guard_placements[key] = int(guard_placements.get(key, 0)) + 1
	guard_placement_events.append({
		"elapsed": elapsed,
		"candidate_id": key,
		"anchor_x": anchor.x,
		"anchor_y": anchor.y,
		"vertical_flipped": vertical_flipped,
		"occupancy_ratio": board_state.get_occupancy_ratio() if board_state != null else 0.0,
		"empty_cells": board_state.get_empty_count() if board_state != null else 0,
	})
	if vertical_flipped:
		formation_vertical_flips += 1
	record_board_state(board_state)

func _formation_decision_event(formation: TowerFormationData, anchor: Vector2i, vertical_flipped: bool, board_state: FormationBoardState, extra: Dictionary = {}) -> Dictionary:
	var event := {
		"elapsed": elapsed,
		"formation_id": String(formation.id),
		"shape_class": String(formation.shape_class),
		"distinct_tower_count": formation.get_distinct_tower_count(),
		"anchor_x": anchor.x,
		"anchor_y": anchor.y,
		"vertical_flipped": vertical_flipped,
		"occupancy_ratio": board_state.get_occupancy_ratio() if board_state != null else 0.0,
		"empty_cells": board_state.get_empty_count() if board_state != null else 0,
		"isolated_empty_cells": board_state.get_isolated_empty_cell_count() if board_state != null else 0,
	}
	event.merge(extra, true)
	return event

func record_board_state(board_state: FormationBoardState) -> void:
	if board_state == null:
		return
	board_occupancy_samples.append(board_state.get_occupancy_ratio())
	isolated_empty_cell_samples.append(board_state.get_isolated_empty_cell_count())

func formation_metrics_snapshot() -> Dictionary:
	return {
		"set_offers_by_size": formation_set_offers_by_size,
		"set_selections_by_size": formation_set_selections_by_size,
		"set_selection_rates_by_size": _selection_rate_snapshot(formation_set_offers_by_size, formation_set_selections_by_size),
		"set_abandons_by_size": formation_set_abandons_by_size,
		"set_abandon_rates_by_size": _selection_rate_snapshot(formation_set_selections_by_size, formation_set_abandons_by_size),
		"formation_offers": formation_offers,
		"formation_selections": formation_selections,
		"formation_selection_rates": _selection_rate_snapshot(formation_offers, formation_selections),
		"formation_abandons": formation_abandons,
		"formation_abandon_rates": _formation_abandon_rate_snapshot(),
		"placement_seconds_total": formation_placement_seconds,
		"valid_position_totals": formation_valid_position_totals,
		"offer_context_events": formation_offer_context_events,
		"board_occupancy_samples": board_occupancy_samples,
		"isolated_empty_cell_samples": isolated_empty_cell_samples,
		"vertical_flips": formation_vertical_flips,
		"guard_placements": guard_placements,
		"selection_events": formation_selection_events,
		"abandon_events": formation_abandon_events,
		"guard_placement_events": guard_placement_events,
		"guard_combat": guard_combat,
	}

func _selection_rate_snapshot(offers: Dictionary, selections: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in offers:
		var offer_count := maxi(int(offers[key]), 0)
		result[key] = float(selections.get(key, 0)) / float(offer_count) if offer_count > 0 else 0.0
	return result

func _formation_abandon_rate_snapshot() -> Dictionary:
	var result: Dictionary = {}
	var formation_ids: Dictionary = {}
	for key in formation_selections:
		formation_ids[key] = true
	for key in formation_abandons:
		formation_ids[key] = true
	for key in formation_ids:
		var selections := maxi(int(formation_selections.get(key, 0)), 0)
		var abandons := maxi(int(formation_abandons.get(key, 0)), 0)
		var placement_attempts := selections + abandons
		result[key] = float(abandons) / float(placement_attempts) if placement_attempts > 0 else 0.0
	return result

func update_slot_completion(loadout: LoadoutManager) -> void:
	if tower_slots_completed_at < 0.0 and loadout.columns.all(func(column: TowerColumn) -> bool: return column.is_occupied()):
		tower_slots_completed_at = elapsed

func record_boss_kill(boss_id: StringName) -> void:
	boss_kill_times[String(boss_id)] = elapsed

func build_meta_metrics(loadout: LoadoutManager) -> Dictionary:
	var result := {
		"runs": 1.0,
		"run.elapsed": elapsed,
		"run.reached_five_minutes": 1.0 if elapsed >= 300.0 else 0.0,
		"run.core_reaches_first_300": float(reaches_before_five_minutes),
		"run.slow_discovery": 1.0 if elapsed >= 300.0 and reaches_before_five_minutes <= 3 else 0.0,
		"run.victory": 0.0,
		"boss_kills": float(boss_kill_times.size()),
		"boss_damage": boss_damage,
		"burst_10_kill_windows": float(burst_ten_kill_windows),
	}
	var elite_kills := 0
	for behavior in ["armored", "shielded", "regenerator"]:
		elite_kills += int(kills_by_behavior.get(behavior, 0))
	result["elite_kills"] = float(elite_kills)
	for key in tower_attacks:
		result["tower_attacks.%s" % key] = float(tower_attacks[key])
	for key in tower_damage:
		result["tower_damage.%s" % key] = float(tower_damage[key])
	for key in tower_kills:
		result["tower_kills.%s" % key] = float(tower_kills[key])
	for key in tower_hits:
		result["tower_hits.%s" % key] = float(tower_hits[key])
	for key in tower_multi_hit_events:
		result["tower_multi_hit_events.%s" % key] = float(tower_multi_hit_events[key])
	for key in tower_long_range_kills:
		result["tower_long_range_kills.%s" % key] = float(tower_long_range_kills[key])
	for key in status_applications:
		result["status_applications.%s" % key] = float(status_applications[key])
	for key in status_damage:
		result["status_damage.%s" % key] = float(status_damage[key])
	for key in kills_by_enemy_id:
		result["kills.%s" % key] = float(kills_by_enemy_id[key])
	var installed_ids: Array[StringName] = []
	if loadout != null:
		installed_ids = loadout.get_installed_tower_ids()
	var starter_types := 0
	for tower_id in [&"rapid", &"pierce", &"area", &"rubber_golem"]:
		if tower_id in installed_ids:
			starter_types += 1
	result["run.starter_tower_types"] = float(starter_types)
	var max_tower_level := 0
	if loadout != null:
		for tower_id in loadout.tower_type_levels:
			max_tower_level = maxi(max_tower_level, int(loadout.tower_type_levels[tower_id]))
	result["run.max_tower_level"] = float(max_tower_level)
	result["starter_fire_kills"] = float(tower_kills.get("rapid", 0)) + float(tower_kills.get("area", 0))
	for key in mechanic_events:
		result["mechanic_events.%s" % key] = float(mechanic_events[key])
	for key in mechanic_totals:
		result["mechanic_totals.%s" % key] = float(mechanic_totals[key])
	for key in formation_set_offers_by_size:
		result["formation.set_offers.%s" % key] = float(formation_set_offers_by_size[key])
	for key in formation_set_selections_by_size:
		result["formation.set_selections.%s" % key] = float(formation_set_selections_by_size[key])
	for key in formation_abandons:
		result["formation.abandons.%s" % key] = float(formation_abandons[key])
	result["formation.vertical_flips"] = float(formation_vertical_flips)
	return result

func _status_id_from_damage_source(source_type: StringName) -> StringName:
	match source_type:
		&"common_poison": return &"poison"
		&"burn", &"common_burn": return &"burn"
		&"common_bleed": return &"bleed"
		&"common_shock": return &"shock"
	return &""

func save_run(level: int, victory: bool, challenge_level: int = 0) -> void:
	var file := FileAccess.open("user://last_run_metrics.json", FileAccess.WRITE)
	if file == null:
		return
	var runtime_performance := _runtime_performance_snapshot()
	file.store_string(JSON.stringify({
		"elapsed": elapsed,
		"victory": victory,
		"challenge_level": ChallengeRules.clamp_level(challenge_level),
		"final_level": level,
		"spawned_by_period": spawned_by_period,
		"killed_by_period": killed_by_period,
		"reached_core_count": reached_core_count,
		"lane_spawns": lane_spawns,
		"lane_reaches": lane_reaches,
		"lane_pass_rates": _lane_pass_rates(),
		"tower_damage": tower_damage,
		"tower_kills": tower_kills,
		"tower_attacks": tower_attacks,
		"tower_hits": tower_hits,
		"tower_multi_hit_events": tower_multi_hit_events,
		"tower_long_range_kills": tower_long_range_kills,
		"boss_damage": boss_damage,
		"status_applications": status_applications,
		"status_damage": status_damage,
		"kills_by_enemy_id": kills_by_enemy_id,
		"kills_by_behavior": kills_by_behavior,
		"reaches_before_five_minutes": reaches_before_five_minutes,
		"burst_ten_kill_windows": burst_ten_kill_windows,
		"cursor_damage": cursor_damage,
		"retainer_control_applications": retainer_control_applications,
		"retainer_collection_experience": retainer_collection_experience,
		"cursor_lane_seconds": cursor_lane_seconds,
		"selected_upgrades": selected_upgrades,
		"unselected_upgrades": unselected_upgrades,
		"upgrade_choice_metrics": upgrade_choice_metrics_snapshot(),
		"tower_slots_completed_at": tower_slots_completed_at,
		"first_core_damage_at": first_core_damage_at,
		"boss_kill_times": boss_kill_times,
		"runtime_performance": runtime_performance,
		"performance_budget": RuntimePerformanceBudget.assess(runtime_performance),
		"mechanic_events": mechanic_events,
		"mechanic_totals": mechanic_totals,
		"mechanic_sample_averages": _mechanic_sample_averages(),
		"mechanic_sample_peaks": mechanic_sample_peaks,
		"formation_metrics": formation_metrics_snapshot(),
		"spawn_director": spawn_director_metrics,
		"enemy_activity": enemy_activity_snapshot(),
		"enemy_removal": enemy_removal_snapshot(),
		"control_effectiveness": control_effectiveness_snapshot(),
		"growth_timeline": growth_timeline_snapshot(),
	}, "  "))

func _runtime_performance_snapshot() -> Dictionary:
	var average_frame_ms := runtime_real_seconds * 1000.0 / float(runtime_frame_count) if runtime_frame_count > 0 else 0.0
	return {
		"frame_count": runtime_frame_count,
		"real_seconds": runtime_real_seconds,
		"game_seconds": runtime_game_seconds,
		"average_frame_ms": average_frame_ms,
		"worst_frame_ms": worst_frame_ms,
		"frames_over_16_ms": frames_over_16_ms,
		"frames_over_33_ms": frames_over_33_ms,
		"over_33_ms_ratio": float(frames_over_33_ms) / float(runtime_frame_count) if runtime_frame_count > 0 else 0.0,
		"real_seconds_by_speed": real_seconds_by_speed,
		"peak_active_enemies": peak_active_enemies,
		"peak_projectiles": peak_projectiles,
		"peak_effects": peak_effects,
		"peak_summons": peak_summons,
		"peak_summon_budget_cost": peak_summon_budget_cost,
		"effect_budget_spawned": effect_budget_spawned,
		"effect_budget_dropped": effect_budget_dropped,
		"effect_budget_drop_total": effect_budget_dropped.values().reduce(func(total: int, value: Variant) -> int: return total + int(value), 0),
	}

func _mechanic_sample_averages() -> Dictionary:
	var averages: Dictionary = {}
	for key in mechanic_sample_sums:
		var count := maxi(int(mechanic_sample_counts.get(key, 0)), 1)
		averages[key] = float(mechanic_sample_sums[key]) / float(count)
	return averages

func _period_key() -> String:
	var start_minute := floori(elapsed / 300.0) * 5
	return "%02d-%02d" % [start_minute, start_minute + 5]

func _lane_pass_rates() -> Array[float]:
	var result: Array[float] = []
	for index in lane_spawns.size():
		result.append(float(lane_reaches[index]) / float(lane_spawns[index]) if lane_spawns[index] > 0 else 0.0)
	return result
