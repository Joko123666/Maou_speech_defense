class_name ContentPackData
extends Resource

@export var id: StringName = &""
@export_multiline var description: String = ""
@export var cores: Array[CoreData] = []
@export var cursors: Array[CursorData] = []
@export var towers: Array[TowerData] = []
@export var formations: Array[TowerFormationData] = []
@export var tower_branches: Array[TowerBranchData] = []
@export var specialization_branches: Array[SpecializationBranchData] = []
@export var enemies: Array[EnemyData] = []
@export var bosses: Array[EnemyData] = []
@export var enemy_spawn_profiles: Array[EnemySpawnProfileData] = []
@export var election_campaign: ElectionCampaignData

func is_playable(stage: StageData = null, reward: StageRewardData = null) -> bool:
	return get_validation_errors(stage, reward).is_empty()

func get_validation_errors(stage: StageData = null, reward: StageRewardData = null) -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("content pack id is empty")
	var catalogs: Dictionary = {
		"cores": cores, "cursors": cursors, "towers": towers,
		"formations": formations, "tower_branches": tower_branches,
		"specialization_branches": specialization_branches, "enemies": enemies, "bosses": bosses,
	}
	for catalog_name in catalogs:
		_validate_catalog(errors, catalog_name, catalogs[catalog_name] as Array)
	for enemy in enemies:
		if enemy == null:
			continue
		if enemy.spawn_cost <= 0.0:
			errors.append("enemy '%s' has a non-positive spawn cost" % enemy.id)
		if enemy.role_tags.is_empty():
			errors.append("enemy '%s' has no spawn role tags" % enemy.id)
	var enemy_ids := _catalog_ids(enemies)
	var faction_ids: Dictionary = {}
	if election_campaign != null:
		for faction in election_campaign.factions:
			if faction != null:
				faction_ids[faction.id] = true
	var seen_spawn_profile_ids: Dictionary = {}
	for profile in enemy_spawn_profiles:
		if profile == null:
			errors.append("enemy spawn profile is null")
			continue
		if seen_spawn_profile_ids.has(profile.enemy_id):
			errors.append("enemy spawn profile id '%s' is duplicated" % profile.enemy_id)
		else:
			seen_spawn_profile_ids[profile.enemy_id] = true
		if not enemy_ids.has(profile.enemy_id):
			errors.append("enemy spawn profile references missing enemy '%s'" % profile.enemy_id)
		for profile_error in profile.get_validation_errors(faction_ids):
			errors.append(profile_error)
	if not enemy_spawn_profiles.is_empty():
		for enemy_id in enemy_ids:
			if not seen_spawn_profile_ids.has(enemy_id):
				errors.append("enemy '%s' is missing its explicit spawn profile" % enemy_id)
	for boss in bosses:
		if boss != null and boss.control_resistance_profile == null:
			errors.append("boss '%s' is missing the common control resistance profile" % boss.id)
	var tower_ids := _catalog_ids(towers)
	var has_regular_formation := false
	for formation in formations:
		if formation != null:
			for shape_error in formation.get_shape_errors():
				errors.append(shape_error)
			if not formation.is_unique():
				has_regular_formation = true
			var calculated_score := 0
			for tower_id in formation.get_tower_ids():
				if not tower_ids.has(tower_id):
					errors.append("formation '%s' references missing tower '%s'" % [formation.id, tower_id])
				else:
					for tower in towers:
						if tower != null and tower.id == tower_id:
							calculated_score += roundi(tower.formation_power_rating)
							break
			if formation.formation_score != calculated_score:
				errors.append("formation '%s' score %d does not match tower score sum %d" % [formation.id, formation.formation_score, calculated_score])
	if not formations.is_empty() and not has_regular_formation:
		errors.append("content pack has no regular formation")
	for core in cores:
		if core == null:
			continue
		if core.unique_tower_id != &"" and not tower_ids.has(core.unique_tower_id):
			errors.append("core '%s' references missing unique tower '%s'" % [core.id, core.unique_tower_id])
	var formation_ids := _catalog_ids(formations)
	for core in cores:
		if core != null and core.unique_formation_id != &"" and not formation_ids.has(core.unique_formation_id):
			errors.append("core '%s' references missing unique formation '%s'" % [core.id, core.unique_formation_id])
	for branch in tower_branches:
		if branch != null and not tower_ids.has(branch.tower_id):
			errors.append("tower branch '%s' references missing tower '%s'" % [branch.id, branch.tower_id])
	var core_ids := _catalog_ids(cores)
	var cursor_ids := _catalog_ids(cursors)
	for formation in formations:
		if formation != null and formation.unique_core_id != &"" and not core_ids.has(formation.unique_core_id):
			errors.append("formation '%s' references missing unique core '%s'" % [formation.id, formation.unique_core_id])
	for branch in specialization_branches:
		if branch == null:
			continue
		var owner_ids: Dictionary = core_ids if branch.owner_kind == &"core" else cursor_ids if branch.owner_kind == &"cursor" else {}
		if owner_ids.is_empty() or not owner_ids.has(branch.owner_id):
			errors.append("specialization '%s' has invalid %s owner '%s'" % [branch.id, branch.owner_kind, branch.owner_id])
	if election_campaign != null:
		enemy_ids = _catalog_ids(enemies)
		var boss_ids := _catalog_ids(bosses)
		for campaign_error in election_campaign.get_validation_errors(core_ids, cursor_ids, enemy_ids, boss_ids):
			errors.append("campaign: %s" % campaign_error)
	if stage != null:
		_validate_stage_contract(errors, stage, reward)
	return errors

func _validate_stage_contract(errors: PackedStringArray, stage: StageData, reward: StageRewardData) -> void:
	var enemy_ids := _catalog_ids(enemies)
	var enemy_by_id: Dictionary = {}
	for enemy in enemies:
		if enemy != null:
			enemy_by_id[enemy.id] = enemy
	var boss_ids := _catalog_ids(bosses)
	if stage.final_boss_id == &"":
		errors.append("stage final boss id is empty")
	elif not boss_ids.has(stage.final_boss_id):
		errors.append("stage references missing final boss '%s'" % stage.final_boss_id)
	if stage.default_boss_ids.size() != stage.boss_times.size():
		errors.append("stage default boss id count %d does not match boss time count %d" % [stage.default_boss_ids.size(), stage.boss_times.size()])
	var seen_default_bosses: Dictionary = {}
	for default_boss_id in stage.default_boss_ids:
		if not boss_ids.has(default_boss_id):
			errors.append("stage default plan references missing boss '%s'" % default_boss_id)
		elif seen_default_bosses.has(default_boss_id):
			errors.append("stage default plan contains duplicate boss '%s'" % default_boss_id)
		else:
			seen_default_bosses[default_boss_id] = true
	if not stage.default_boss_ids.is_empty() and stage.default_boss_ids.back() != stage.final_boss_id:
		errors.append("stage final boss '%s' must match the last default boss slot" % stage.final_boss_id)
	var previous_boss_time := -1.0
	for boss_time in stage.boss_times:
		if boss_time <= previous_boss_time or boss_time <= 0.0 or boss_time > stage.duration_seconds:
			errors.append("stage boss times must be strictly increasing within the stage duration")
			break
		previous_boss_time = boss_time
	if stage.artifact_elite_interval_seconds < 0.0:
		errors.append("stage artifact elite interval cannot be negative")
	elif stage.artifact_elite_interval_seconds > 0.0:
		if stage.artifact_elite_enemy_id == &"" or not enemy_ids.has(stage.artifact_elite_enemy_id):
			errors.append("stage references missing artifact elite '%s'" % stage.artifact_elite_enemy_id)
		else:
			var artifact_elite := enemy_by_id.get(stage.artifact_elite_enemy_id) as EnemyData
			if artifact_elite == null or artifact_elite.is_boss or not artifact_elite.is_elite:
				errors.append("stage artifact elite must reference a non-boss elite enemy")
		var artifact_elite_times := stage.artifact_elite_times()
		if artifact_elite_times.is_empty():
			errors.append("stage artifact elite schedule must contain at least one pre-final encounter")
		if stage.artifact_elite_health_multipliers.size() < artifact_elite_times.size():
			errors.append("stage artifact elite health curve does not cover every encounter")
		if stage.artifact_elite_health_multipliers.any(func(value: float) -> bool: return value <= 0.0):
			errors.append("stage artifact elite health multipliers must be positive")
	elif stage.artifact_elite_enemy_id != &"" or not stage.artifact_elite_health_multipliers.is_empty():
		errors.append("disabled artifact elite schedule must not retain enemy or health data")
	for prelude_error in stage.get_faction_prelude_validation_errors():
		errors.append("stage: %s" % prelude_error)
	for packet_error in stage.get_faction_spawn_packet_validation_errors():
		errors.append("stage: %s" % packet_error)
	if stage.spawn_phases.size() != stage.spawn_table.size():
		errors.append("stage spawn phase count must match the weighted wave count")
	var previous_phase_end := 0.0
	for phase_index in stage.spawn_phases.size():
		var phase := stage.spawn_phases[phase_index]
		if phase == null:
			errors.append("spawn phase %d is null" % phase_index)
			continue
		for phase_error in phase.get_validation_errors(stage.duration_seconds):
			errors.append("spawn phase %d: %s" % [phase_index, phase_error])
		if not is_equal_approx(phase.start_seconds, previous_phase_end):
			errors.append("spawn phase %d leaves a gap or overlaps the previous phase" % phase_index)
		previous_phase_end = phase.end_seconds
	if not stage.spawn_phases.is_empty() and previous_phase_end < stage.duration_seconds:
		errors.append("spawn phases do not cover the full stage duration")
	if stage.spawn_packets.size() < 3:
		errors.append("stage must define at least three spawn composition packets")
	var seen_packet_ids: Dictionary = {}
	for packet_index in stage.spawn_packets.size():
		var packet := stage.spawn_packets[packet_index]
		if packet == null:
			errors.append("spawn packet %d is null" % packet_index)
			continue
		for packet_error in packet.get_validation_errors(stage.spawn_phases.size()):
			errors.append("spawn packet %d: %s" % [packet_index, packet_error])
		if seen_packet_ids.has(packet.id):
			errors.append("spawn packet id '%s' is duplicated" % packet.id)
		else:
			seen_packet_ids[packet.id] = true
		for phase_index in packet.allowed_phase_indices:
			if phase_index >= 0 and phase_index < stage.spawn_phases.size():
				var phase := stage.spawn_phases[phase_index]
				if phase != null and packet.min_cost > phase.max_packet_cost + 0.0001:
					errors.append("spawn packet '%s' minimum cost exceeds phase %d packet budget" % [packet.id, phase_index])
	var profile_by_enemy_id: Dictionary = {}
	for profile in enemy_spawn_profiles:
		if profile != null:
			profile_by_enemy_id[profile.enemy_id] = profile
	for faction_packet in stage.faction_spawn_packets:
		if faction_packet == null:
			continue
		if not enemy_by_id.has(faction_packet.faction_enemy_id):
			errors.append("faction spawn packet '%s' references missing faction enemy '%s'" % [faction_packet.id, faction_packet.faction_enemy_id])
		var faction_profile := profile_by_enemy_id.get(faction_packet.faction_enemy_id) as EnemySpawnProfileData
		if faction_profile == null or not faction_profile.is_faction_enemy or faction_profile.faction_id != faction_packet.faction_id:
			errors.append("faction spawn packet '%s' requires a matching explicit faction spawn profile" % faction_packet.id)
		if faction_packet.tier_common_entries.size() != 3:
			continue
		for tier in 3:
			for raw_enemy_id in faction_packet.tier_common_entries[tier]:
				var common_id := StringName(raw_enemy_id)
				if not enemy_by_id.has(common_id):
					errors.append("faction spawn packet '%s' references missing common enemy '%s'" % [faction_packet.id, common_id])
				var common_profile := profile_by_enemy_id.get(common_id) as EnemySpawnProfileData
				if common_profile == null or common_profile.is_faction_enemy:
					errors.append("faction spawn packet '%s' common entry '%s' requires an explicit common spawn profile" % [faction_packet.id, common_id])
	for wave_index in stage.spawn_table.size():
		var wave: Dictionary = stage.spawn_table[wave_index]
		var start_time := float(wave.get("start", 0.0))
		var end_time := float(wave.get("end", stage.duration_seconds))
		if start_time < 0.0 or end_time <= start_time or end_time > stage.duration_seconds + 0.11:
			errors.append("spawn wave %d has an invalid time range" % wave_index)
		var weights_value: Variant = wave.get("weights", {})
		if weights_value is not Dictionary:
			errors.append("spawn wave %d weights must be a dictionary" % wave_index)
			continue
		var weights := weights_value as Dictionary
		var has_eligible_enemy := weights.is_empty()
		for raw_enemy_id in weights:
			var enemy_id := StringName(raw_enemy_id)
			if not enemy_ids.has(enemy_id):
				errors.append("spawn wave %d references missing enemy '%s'" % [wave_index, enemy_id])
				continue
			if float(weights[raw_enemy_id]) <= 0.0:
				errors.append("spawn wave %d has a non-positive weight for enemy '%s'" % [wave_index, enemy_id])
			elif (enemy_by_id[enemy_id] as EnemyData).available_from_seconds <= start_time:
				has_eligible_enemy = true
		if not has_eligible_enemy:
			errors.append("spawn wave %d has no positively weighted enemy available at its start" % wave_index)
		var groups_value: Variant = wave.get("groups", {})
		if groups_value is not Dictionary:
			errors.append("spawn wave %d groups must be a dictionary" % wave_index)
			continue
		for raw_enemy_id in groups_value:
			var enemy_id := StringName(raw_enemy_id)
			if not enemy_ids.has(enemy_id):
				errors.append("spawn wave %d group references missing enemy '%s'" % [wave_index, enemy_id])
			elif int((groups_value as Dictionary)[raw_enemy_id]) <= 0:
				errors.append("spawn wave %d has a non-positive group size for enemy '%s'" % [wave_index, enemy_id])
	if reward == null:
		return
	for raw_boss_id in reward.boss_funds_by_id:
		var boss_id := StringName(raw_boss_id)
		if not boss_ids.has(boss_id):
			errors.append("stage reward references missing boss '%s'" % boss_id)
	for boss in bosses:
		if boss != null and not reward.boss_funds_by_id.has(boss.id) and not reward.boss_funds_by_id.has(String(boss.id)):
			errors.append("stage reward has no entry for boss '%s'" % boss.id)

func _validate_catalog(errors: PackedStringArray, catalog_name: String, items: Array) -> void:
	if items.is_empty():
		errors.append("%s catalog is empty" % catalog_name)
		return
	var seen: Dictionary = {}
	for index in items.size():
		var item := items[index] as Resource
		if item == null:
			errors.append("%s[%d] is null" % [catalog_name, index])
			continue
		var item_id := StringName(item.get("id"))
		if item_id == &"":
			errors.append("%s[%d] has an empty id" % [catalog_name, index])
		elif seen.has(item_id):
			errors.append("%s contains duplicate id '%s'" % [catalog_name, item_id])
		else:
			seen[item_id] = true

func _catalog_ids(items: Array) -> Dictionary:
	var result: Dictionary = {}
	for item in items:
		if item != null:
			var item_id := StringName((item as Resource).get("id"))
			if item_id != &"":
				result[item_id] = true
	return result
