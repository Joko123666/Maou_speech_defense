class_name CampaignStageResolver
extends RefCounted

static func resolve(
	stage: StageData,
	boss_catalog: Array[EnemyData],
	campaign: ElectionCampaignData,
	selected_core_id: StringName,
	selected_cursor_id: StringName,
	seed_value: int
) -> StageRuntimeBossPlan:
	var fixed_plan := build_fixed_plan(stage, boss_catalog, seed_value)
	if campaign == null:
		return fixed_plan
	var selected_candidate := campaign.candidate_for_core(selected_core_id)
	if selected_candidate == null:
		fixed_plan.fallback_reason = "selected core has no candidate profile"
		return fixed_plan
	var required_rival_count := stage.boss_times.size()
	var rivals: Array[CandidateProfileData] = []
	for candidate in campaign.candidates:
		if candidate != null and candidate.id != selected_candidate.id:
			rivals.append(candidate)
	if rivals.size() != required_rival_count:
		fixed_plan.selected_candidate_id = selected_candidate.id
		fixed_plan.fallback_reason = "campaign requires exactly %d rival candidates but contains %d" % [required_rival_count, rivals.size()]
		return fixed_plan
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value ^ String("%s/%s/%s" % [stage.id, selected_core_id, selected_cursor_id]).hash()
	_shuffle(rivals, rng)
	var selected_retainer := campaign.retainer_for_cursor(selected_cursor_id)
	var selected_retainer_id := selected_retainer.id if selected_retainer != null else &""
	var reserved_final_boss_id: StringName = rivals.back().candidate_boss_id
	var blocked_bosses: Dictionary = {}
	blocked_bosses[reserved_final_boss_id] = true
	var used_bosses: Dictionary = {}
	var slots: Array[Dictionary] = []
	for index in rivals.size():
		var rival := rivals[index]
		var faction := campaign.faction(rival.faction_id)
		var presentation := {
			"boss_id": reserved_final_boss_id,
			"presentation_kind": StageRuntimeBossPlan.PRESENTATION_CANDIDATE,
			"presentation_id": rival.id,
		} if index == rivals.size() - 1 else _opening_boss_presentation(campaign, rival, faction, selected_retainer_id, blocked_bosses)
		var boss_id := StringName(presentation.get("boss_id", ""))
		if boss_id == &"" or used_bosses.has(boss_id):
			fixed_plan.selected_candidate_id = selected_candidate.id
			fixed_plan.fallback_reason = "campaign could not resolve four unique rival bosses"
			return fixed_plan
		used_bosses[boss_id] = true
		blocked_bosses[boss_id] = true
		slots.append({
			"boss_id": boss_id,
			"faction_id": rival.faction_id,
			"presentation_kind": StringName(presentation.get("presentation_kind", "")),
			"presentation_id": StringName(presentation.get("presentation_id", "")),
			"time": stage.boss_times[index],
		})
	var plan := StageRuntimeBossPlan.new()
	plan.id = StringName("%s-campaign-%d" % [stage.id, seed_value])
	plan.source = StageRuntimeBossPlan.SOURCE_CAMPAIGN
	plan.seed = seed_value
	plan.selected_candidate_id = selected_candidate.id
	plan.final_boss_id = StringName(slots.back().boss_id)
	plan.slots = slots
	var boss_ids := _catalog_ids(boss_catalog)
	var faction_ids: Dictionary = {}
	for faction in campaign.factions:
		if faction != null:
			faction_ids[faction.id] = true
	var validation_errors := plan.get_validation_errors(stage, boss_ids, faction_ids, selected_candidate.faction_id)
	if not validation_errors.is_empty():
		fixed_plan.selected_candidate_id = selected_candidate.id
		fixed_plan.fallback_reason = ", ".join(validation_errors)
		return fixed_plan
	return plan

static func build_fixed_plan(stage: StageData, boss_catalog: Array[EnemyData], seed_value: int = 0) -> StageRuntimeBossPlan:
	var plan := StageRuntimeBossPlan.new()
	plan.id = StringName("%s-fixed" % stage.id) if stage != null else &"invalid-fixed"
	plan.source = StageRuntimeBossPlan.SOURCE_FIXED
	plan.seed = seed_value
	if stage == null:
		plan.fallback_reason = "stage is missing"
		return plan
	var boss_ids := stage.default_boss_ids.duplicate()
	if boss_ids.is_empty():
		for index in mini(stage.boss_times.size(), boss_catalog.size()):
			boss_ids.append(boss_catalog[index].id)
		plan.fallback_reason = "legacy stage used catalog order because default_boss_ids is empty"
	for index in mini(stage.boss_times.size(), boss_ids.size()):
		plan.slots.append({"boss_id": boss_ids[index], "faction_id": &"", "time": stage.boss_times[index]})
	plan.final_boss_id = StringName(plan.slots.back().boss_id) if not plan.slots.is_empty() else stage.final_boss_id
	return plan

static func _opening_boss_presentation(
	campaign: ElectionCampaignData,
	rival: CandidateProfileData,
	faction: ElectionFactionData,
	selected_retainer_id: StringName,
	blocked_bosses: Dictionary
) -> Dictionary:
	var default_retainer := campaign.retainer(rival.default_retainer_id)
	if default_retainer != null and default_retainer.id != selected_retainer_id and not blocked_bosses.has(default_retainer.retainer_boss_id):
		return {
			"boss_id": default_retainer.retainer_boss_id,
			"presentation_kind": StageRuntimeBossPlan.PRESENTATION_RETAINER,
			"presentation_id": default_retainer.id,
		}
	if faction != null:
		for replacement_id in faction.replacement_boss_ids:
			if not blocked_bosses.has(replacement_id):
				return {
					"boss_id": replacement_id,
					"presentation_kind": StageRuntimeBossPlan.PRESENTATION_GUARD,
					"presentation_id": faction.id,
				}
	return {}

static func _shuffle(values: Array[CandidateProfileData], rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var temporary := values[index]
		values[index] = values[swap_index]
		values[swap_index] = temporary

static func _catalog_ids(items: Array[EnemyData]) -> Dictionary:
	var result: Dictionary = {}
	for item in items:
		if item != null:
			result[item.id] = true
	return result
