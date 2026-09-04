class_name FactionEnemyFormationPlanner
extends RefCounted

static func build_contexts(
	enemy_data: EnemyData,
	spawn_profile: EnemySpawnProfileData,
	tier: int,
	serial: int,
	center_y_ratio: float = 0.5,
	spawn_time: float = 0.0,
	packet_id: StringName = &"faction_preview",
	channel: StringName = &"base"
) -> Array[EnemySpawnContext]:
	var result: Array[EnemySpawnContext] = []
	if enemy_data == null or spawn_profile == null or enemy_data.formation_profile == null or not spawn_profile.is_faction_enemy or tier < 1 or tier > 3:
		return result
	var formation := enemy_data.formation_profile
	if not formation.get_validation_errors().is_empty():
		return result
	var unit_count := formation.unit_count_for_tier(tier)
	var cohort_count := formation.cohort_count_for_tier(tier)
	var cohort_sizes := _split_count(unit_count, cohort_count)
	var global_index := 0
	for cohort_index in cohort_count:
		var cohort_size := cohort_sizes[cohort_index]
		var cohort_axis := clampf(center_y_ratio + (float(cohort_index) - float(cohort_count - 1) * 0.5) * formation.cohort_axis_spacing_ratio, 0.06, 0.94)
		var cohort_id := StringName("%s:c%d:t%d:s%d" % [spawn_profile.enemy_id, cohort_index, tier, serial])
		var group_cohort := cohort_index if formation.separate_group_per_cohort else 0
		var group_id := StringName("%s:g%d:t%d:s%d" % [spawn_profile.enemy_id, group_cohort, tier, serial])
		for member_index in cohort_size:
			var centered_member := float(member_index) - float(cohort_size - 1) * 0.5
			var spawn_ratio := clampf(cohort_axis + centered_member * formation.unit_spacing_ratio, 0.04, 0.96)
			var context := EnemySpawnContext.new()
			context.enemy_id = enemy_data.id
			context.packet_id = packet_id
			context.channel = channel
			context.spawn_time = spawn_time + formation.stagger_for_tier(tier) * float(cohort_index)
			context.spawn_delay = formation.stagger_for_tier(tier) * float(cohort_index)
			context.faction_id = spawn_profile.faction_id
			context.prelude_tier = tier
			context.group_id = group_id
			context.cohort_id = cohort_id
			context.wave_index = cohort_index
			context.formation_index = global_index
			context.spawn_y_ratio = spawn_ratio
			context.destination_y_ratio = spawn_ratio
			result.append(context)
			global_index += 1
	return result

static func _split_count(total: int, groups: int) -> Array[int]:
	var result: Array[int] = []
	for group_index in groups:
		result.append(total / groups + (1 if group_index < total % groups else 0))
	return result
