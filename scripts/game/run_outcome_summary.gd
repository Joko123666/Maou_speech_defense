class_name RunOutcomeSummary
extends RefCounted

static func build(stage: StageData, metrics: RunMetrics, loadout: LoadoutManager, spawn_snapshot: Dictionary) -> Dictionary:
	if metrics == null or loadout == null:
		return {}
	return build_from_snapshots(
		stage,
		metrics.status_contribution_snapshot(),
		loadout.get_board_snapshot(),
		metrics.formation_metrics_snapshot(),
		loadout.get_candidate_growth_snapshot(),
		loadout.get_guard_growth_snapshot(),
		loadout.get_retainer_growth_snapshot(),
		spawn_snapshot,
		metrics.enemy_activity_snapshot(),
		metrics.growth_timeline_snapshot(),
		metrics.enemy_removal_snapshot(),
		metrics.control_effectiveness_snapshot(),
		loadout.get_overgrowth_snapshot(),
		loadout.get_artifact_snapshot(),
		metrics.artifact_metrics_snapshot(loadout)
	)

static func build_from_snapshots(
	stage: StageData,
	status_summary: Dictionary,
	formation_board: Array,
	formation_metrics: Dictionary,
	candidate_growth: Dictionary,
	guard_growth: Dictionary,
	retainer_growth: Dictionary,
	spawn_snapshot: Dictionary,
	enemy_activity: Dictionary = {},
	growth_timeline: Dictionary = {},
	enemy_removal: Dictionary = {},
	control_effectiveness: Dictionary = {},
	overgrowth: Dictionary = {},
	artifacts: Dictionary = {},
	artifact_metrics: Dictionary = {}
) -> Dictionary:
	var regular_formations := 0
	var regular_units := 0
	var guard_formations := 0
	var guard_units := 0
	for placement_value in formation_board:
		var placement := placement_value as Dictionary
		var cells := placement.get("cells", []) as Array
		if bool(placement.get("is_guard", false)):
			guard_formations += 1
			guard_units += cells.size()
		else:
			regular_formations += 1
			regular_units += cells.size()
	var guard_damage := 0.0
	var guard_kills := 0
	var guard_control := 0
	var guard_combat := formation_metrics.get("guard_combat", {}) as Dictionary
	for guard_value in guard_combat.values():
		var guard := guard_value as Dictionary
		guard_damage += maxf(float(guard.get("damage", 0.0)), 0.0)
		guard_kills += maxi(int(guard.get("kills", 0)), 0)
		guard_control += maxi(int(guard.get("control_applications", 0)), 0)
	var packet_counts := spawn_snapshot.get("packet_spawn_counts", {}) as Dictionary
	var packet_entries: Array[Dictionary] = []
	var consumed_packet_ids: Dictionary = {}
	if stage != null:
		for packet in stage.spawn_packets:
			if packet == null:
				continue
			var count := maxi(int(packet_counts.get(packet.id, packet_counts.get(String(packet.id), 0))), 0)
			if count > 0:
				packet_entries.append({"packet_id": String(packet.id), "display_name": packet.display_name, "count": count})
			consumed_packet_ids[String(packet.id)] = true
	var extra_packet_ids: Array[String] = []
	for raw_packet_id in packet_counts:
		var packet_id := String(raw_packet_id)
		if not consumed_packet_ids.has(packet_id):
			extra_packet_ids.append(packet_id)
	extra_packet_ids.sort()
	for packet_id in extra_packet_ids:
		var count := maxi(int(packet_counts.get(packet_id, 0)), 0)
		if count > 0:
			packet_entries.append({"packet_id": packet_id, "display_name": packet_id, "count": count})
	return {
		"growth": {
			"candidate_slots": (candidate_growth.get("completed_slots", {}) as Dictionary).size(),
			"candidate_branch_id": String(candidate_growth.get("selected_branch_id", "")),
			"guard_stage": maxi(int(guard_growth.get("stage", 0)), 0),
			"guard_specialization_id": String(guard_growth.get("selected_specialization_id", "")),
			"retainer_level": maxi(int(retainer_growth.get("current_level", 1)), 1),
			"retainer_specialization_id": String(retainer_growth.get("selected_specialization_id", "")),
			"candidate_overgrowth_stacks": maxi(int(overgrowth.get("candidate_total", 0)), 0),
			"retainer_overgrowth_stacks": maxi(int(overgrowth.get("retainer_total", 0)), 0),
			"artifact_count": maxi(int(artifacts.get("count", 0)), 0),
			"artifact_ids": (artifacts.get("artifact_ids", []) as Array).duplicate(),
			"timeline": growth_timeline.duplicate(true),
		},
		"formation": {
			"regular_formations": regular_formations,
			"regular_units": regular_units,
			"guard_formations": guard_formations,
			"guard_units": guard_units,
			"guard_damage": guard_damage,
			"guard_kills": guard_kills,
			"guard_control_applications": guard_control,
		},
		"status": status_summary.duplicate(true),
		"enemy": enemy_activity.duplicate(true),
		"enemy_removal": enemy_removal.duplicate(true),
		"control_effectiveness": control_effectiveness.duplicate(true),
		"artifacts": artifact_metrics.duplicate(true),
		"spawn": {
			"base_count": maxi(int(spawn_snapshot.get("base_spawn_count", 0)), 0),
			"bonus_count": maxi(int(spawn_snapshot.get("bonus_spawn_count", 0)), 0),
			"bonus_experience_ratio": clampf(float(spawn_snapshot.get("bonus_experience_ratio", 0.0)), 0.0, 1.0),
			"fallback_group_count": maxi(int(spawn_snapshot.get("fallback_group_spawn_count", 0)), 0),
			"packets": packet_entries,
		},
	}
