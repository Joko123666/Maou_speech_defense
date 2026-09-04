class_name RunResultService
extends RefCounted

func build_result(
	stage_data: StageData,
	boss_plan: StageRuntimeBossPlan,
	enemy_spawner: EnemySpawner,
	experience: ExperienceManager,
	core: DefenseCore,
	target_cursor: TargetCursor,
	loadout: LoadoutManager,
	metrics: RunMetrics,
	kill_count: int,
	boss_kill_count: int,
	top_tower: String,
	victory: bool,
	run_id: String = ""
) -> Dictionary:
	var meta_metrics := metrics.build_meta_metrics(loadout)
	meta_metrics["run.victory"] = 1.0 if victory else 0.0
	var defeated_boss_ids: Array = metrics.boss_kill_times.keys()
	var campaign := ConceptService.get_election_campaign()
	var selected_retainer := campaign.retainer_for_cursor(GameSession.selected_cursor_id) if campaign != null else null
	var spawn_snapshot := enemy_spawner.spawn_budget_snapshot()
	var result := {
		"run_id": run_id if not run_id.is_empty() else create_run_id(),
		"victory": victory,
		"stage_id": String(stage_data.id),
		"stage_name": stage_data.display_name,
		"challenge_level": ChallengeRules.clamp_level(GameSession.selected_challenge_level),
		"challenge_experience_multiplier": ChallengeRules.experience_multiplier(GameSession.selected_challenge_level),
		"elapsed": minf(enemy_spawner.elapsed, stage_data.duration_seconds),
		"stage_duration_seconds": stage_data.duration_seconds,
		"level": experience.level,
		"kills": kill_count,
		"boss_kills": boss_kill_count,
		"boss_kill_ids": defeated_boss_ids,
		"boss_plan": boss_plan.to_snapshot(),
		"boss_timeline": _build_boss_timeline(boss_plan, defeated_boss_ids),
		"meta_metrics": meta_metrics,
		"experience": experience.total_experience,
		"core_health": core.current_health,
		"core": core.data.display_name,
		"cursor": target_cursor.data.display_name,
		"retainer_growth": loadout.get_retainer_growth_snapshot(),
		"retainer_contribution": metrics.retainer_contribution_snapshot(selected_retainer.id if selected_retainer != null else &""),
		"build": loadout.get_build_summary(),
		"top_tower": top_tower,
		"formation_board": loadout.get_board_snapshot(),
		"formation_board_width": loadout.board_state.width,
		"formation_board_height": loadout.board_state.height,
		"formation_metrics": metrics.formation_metrics_snapshot(),
		"spawn_director": spawn_snapshot,
		"outcome_summary": RunOutcomeSummary.build(stage_data, metrics, loadout, spawn_snapshot),
		"candidate_growth": loadout.get_candidate_growth_snapshot(),
		"guard_growth": loadout.get_guard_growth_snapshot(),
		"overgrowth": loadout.get_overgrowth_snapshot(),
		"artifacts": loadout.get_artifact_snapshot(),
		"artifact_metrics": metrics.artifact_metrics_snapshot(loadout),
	}
	result.merge(_campaign_identity(boss_plan), true)
	return result

func _build_boss_timeline(boss_plan: StageRuntimeBossPlan, defeated_boss_ids: Array) -> Array[Dictionary]:
	var timeline: Array[Dictionary] = []
	if boss_plan == null:
		return timeline
	var campaign := ConceptService.get_election_campaign()
	var is_election_campaign := campaign != null and boss_plan.source == StageRuntimeBossPlan.SOURCE_CAMPAIGN
	for index in boss_plan.slots.size():
		var boss := DataRegistry.find_enemy(boss_plan.boss_id_at(index))
		if boss == null:
			continue
		var display_name := boss.display_name
		var texture := boss.texture
		var color := boss.body_color
		var emblem_id: StringName = &""
		var marker_style: StringName = &""
		var presentation_kind := boss_plan.presentation_kind_at(index)
		var presentation_id := boss_plan.presentation_id_at(index)
		if is_election_campaign:
			var faction := campaign.faction(boss_plan.faction_id_at(index))
			var identity := _campaign_timeline_identity(campaign, faction, presentation_kind, presentation_id)
			if identity.is_empty():
				var rival_candidate := campaign.candidate(faction.candidate_id) if faction != null else campaign.candidate_for_boss(boss.id)
				if rival_candidate != null:
					display_name = rival_candidate.full_name
					var portrait := ConceptService.optional_content_texture(&"candidates", rival_candidate.id)
					if portrait != null:
						texture = portrait
			else:
				display_name = String(identity.get("display_name", display_name))
				var identity_texture := identity.get("texture") as Texture2D
				if identity_texture != null:
					texture = identity_texture
			if faction != null:
				color = faction.primary_color
				emblem_id = faction.emblem_id
				marker_style = faction.active_marker_style()
		timeline.append({
			"id": String(boss.id),
			"faction_id": String(boss_plan.faction_id_at(index)),
			"presentation_kind": String(presentation_kind),
			"presentation_id": String(presentation_id),
			"display_name": display_name,
			"time": boss_plan.time_at(index),
			"texture": texture,
			"color": color,
			"emblem_id": String(emblem_id),
			"marker_style": String(marker_style),
			"defeated": String(boss.id) in defeated_boss_ids or boss.id in defeated_boss_ids,
		})
	return timeline

func _campaign_timeline_identity(
	campaign: ElectionCampaignData,
	faction: ElectionFactionData,
	presentation_kind: StringName,
	presentation_id: StringName
) -> Dictionary:
	match presentation_kind:
		StageRuntimeBossPlan.PRESENTATION_CANDIDATE:
			var candidate := campaign.candidate(presentation_id)
			if candidate != null:
				return {"display_name": candidate.full_name, "texture": ConceptService.optional_content_texture(&"candidates", candidate.id)}
		StageRuntimeBossPlan.PRESENTATION_RETAINER:
			var retainer := campaign.retainer(presentation_id)
			if retainer != null:
				return {"display_name": retainer.full_name, "texture": ConceptService.optional_content_texture(&"retainers", retainer.id)}
		StageRuntimeBossPlan.PRESENTATION_GUARD:
			var tower := _campaign_guard_tower(campaign, faction)
			if tower != null:
				var guard_texture := ConceptService.optional_content_texture(&"guard_intrusion_sd", presentation_id)
				return {"display_name": tower.display_name, "texture": guard_texture if guard_texture != null else tower.texture}
	return {}

func _campaign_guard_tower(campaign: ElectionCampaignData, faction: ElectionFactionData) -> TowerData:
	if campaign == null or faction == null:
		return null
	var candidate := campaign.candidate(faction.candidate_id)
	var core := DataRegistry.get_core(candidate.core_id) if candidate != null else null
	return DataRegistry.get_tower(core.unique_tower_id) if core != null else null

func build_checkpoint_result(
	stage_data: StageData,
	boss_plan: StageRuntimeBossPlan,
	enemy_spawner: EnemySpawner,
	experience: ExperienceManager,
	loadout: LoadoutManager,
	metrics: RunMetrics,
	kill_count: int,
	boss_kill_count: int,
	victory: bool,
	run_id: String
) -> Dictionary:
	var meta_metrics := metrics.build_meta_metrics(loadout)
	meta_metrics["run.victory"] = 1.0 if victory else 0.0
	var spawn_snapshot := enemy_spawner.spawn_budget_snapshot()
	var result := {
		"run_id": run_id,
		"victory": victory,
		"stage_id": String(stage_data.id),
		"stage_name": stage_data.display_name,
		"challenge_level": ChallengeRules.clamp_level(GameSession.selected_challenge_level),
		"challenge_experience_multiplier": ChallengeRules.experience_multiplier(GameSession.selected_challenge_level),
		"elapsed": minf(enemy_spawner.elapsed, stage_data.duration_seconds),
		"stage_duration_seconds": stage_data.duration_seconds,
		"level": experience.level,
		"kills": kill_count,
		"boss_kills": boss_kill_count,
		"boss_kill_ids": metrics.boss_kill_times.keys(),
		"boss_plan": boss_plan.to_snapshot(),
		"meta_metrics": meta_metrics,
		"experience": experience.total_experience,
		"eligible_for_meta_rewards": true,
		"formation_board": loadout.get_board_snapshot(),
		"formation_board_width": loadout.board_state.width,
		"formation_board_height": loadout.board_state.height,
		"formation_metrics": metrics.formation_metrics_snapshot(),
		"spawn_director": spawn_snapshot,
		"outcome_summary": RunOutcomeSummary.build(stage_data, metrics, loadout, spawn_snapshot),
		"candidate_growth": loadout.get_candidate_growth_snapshot(),
		"guard_growth": loadout.get_guard_growth_snapshot(),
		"retainer_growth": loadout.get_retainer_growth_snapshot(),
		"overgrowth": loadout.get_overgrowth_snapshot(),
		"artifacts": loadout.get_artifact_snapshot(),
		"artifact_metrics": metrics.artifact_metrics_snapshot(loadout),
		"retainer_contribution": metrics.retainer_contribution_snapshot(StringName(loadout.get_retainer_growth_snapshot().get("retainer_id", ""))),
	}
	result.merge(_campaign_identity(boss_plan), true)
	return result

func _campaign_identity(boss_plan: StageRuntimeBossPlan) -> Dictionary:
	var campaign := ConceptService.get_election_campaign()
	if campaign == null or boss_plan == null or boss_plan.source != StageRuntimeBossPlan.SOURCE_CAMPAIGN:
		return {}
	var candidate := campaign.candidate(boss_plan.selected_candidate_id)
	var retainer := campaign.retainer_for_cursor(GameSession.selected_cursor_id)
	if candidate == null:
		return {}
	var rival_candidate_ids: Array[String] = []
	for index in boss_plan.slots.size():
		var faction := campaign.faction(boss_plan.faction_id_at(index))
		rival_candidate_ids.append(String(faction.candidate_id) if faction != null else "")
	var decree_ids: Array[String] = []
	for decree_id in candidate.decree_ids:
		decree_ids.append(String(decree_id))
	var selected_decree := campaign.decree(GameSession.selected_decree_id)
	var elected := SaveManager.is_candidate_elected(candidate.id)
	return {
		"candidate_id": String(candidate.id),
		"candidate_name": candidate.short_name,
		"retainer_id": String(retainer.id) if retainer != null else "",
		"retainer_name": retainer.short_name if retainer != null else "",
		"rival_candidate_ids": rival_candidate_ids,
		"support_required_for_election": candidate.support_required_for_election,
		"candidate_decree_ids_available": decree_ids,
		"decree_id": String(GameSession.selected_decree_id),
		"decree_name": selected_decree.display_name if selected_decree != null else "",
		"candidate_elected": elected,
		"governance_approval": SaveManager.get_governance_approval(candidate.id) if elected else 0,
	}

func create_run_id() -> String:
	return "%d-%d-%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec(), OS.get_process_id()]

func persist_result(result: Dictionary, metrics: RunMetrics, testing_mode: bool) -> Dictionary:
	var new_unlocks: Array[String] = []
	if not testing_mode:
		var unlocks_before := SaveManager.unlocked_ids.duplicate()
		var stage_id := StringName(result.get("stage_id", "standard_20m"))
		var challenge_was_unlocked := SaveManager.is_challenge_unlocked(stage_id)
		var settlement := MetaProgressionService.settle_run(result)
		result["settlement_awarded"] = bool(settlement.get("awarded", false))
		result["settlement_duplicate"] = bool(settlement.get("duplicate", false))
		var breakdown: Dictionary = settlement.get("breakdown", {})
		result["funds_earned"] = int(breakdown.get("total_funds", 0))
		result["funds_breakdown"] = breakdown
		result["defense_funds_total"] = int(settlement.get("balance", SaveManager.defense_funds))
		var candidate_progression: Dictionary = breakdown.get("candidate_progression", {})
		result["candidate_support_earned"] = int(candidate_progression.get("total_support", 0))
		result["candidate_support_total"] = int(candidate_progression.get("support_after", SaveManager.get_candidate_support(StringName(result.get("candidate_id", "")))))
		result["candidate_support_required"] = int(candidate_progression.get("support_required", result.get("support_required_for_election", 0)))
		result["candidate_newly_elected"] = bool(candidate_progression.get("newly_elected", false))
		var governance_progression: Dictionary = breakdown.get("governance_progression", {})
		result["governance_approval_before"] = int(governance_progression.get("approval_before", result.get("governance_approval", 0)))
		result["governance_approval_delta"] = int(governance_progression.get("approval_delta", 0))
		var achievement_actions: Dictionary = settlement.get("achievement_actions", {})
		result["completed_achievement_ids"] = achievement_actions.get("completed_ids", [])
		result["discovered_product_ids"] = achievement_actions.get("discovered_product_ids", [])
		result["unlocked_feature_ids"] = achievement_actions.get("unlocked_feature_ids", [])
		for achievement_id in result.completed_achievement_ids:
			var achievement := MetaProgressionService.get_achievement(StringName(achievement_id))
			if achievement != null:
				new_unlocks.append("업적 · %s" % achievement.display_name)
		for product_id in result.discovered_product_ids:
			var product := MetaProgressionService.get_shop_product(StringName(product_id))
			if product != null:
				new_unlocks.append("상품 · %s" % product.display_name)
		metrics.save_run(int(result.get("level", 1)), bool(result.get("victory", false)), int(result.get("challenge_level", 0)))
		for unlock_id in SaveManager.unlocked_ids:
			if unlock_id not in unlocks_before:
				new_unlocks.append(unlock_id)
		if not challenge_was_unlocked and SaveManager.is_challenge_unlocked(stage_id):
			new_unlocks.append("도전 단계 1")
	else:
		result["settlement_awarded"] = true
		result["settlement_duplicate"] = false
		result["funds_earned"] = 0
		result["funds_breakdown"] = StageRewardCalculator._empty_breakdown()
		result["defense_funds_total"] = SaveManager.defense_funds
		result["completed_achievement_ids"] = []
		result["discovered_product_ids"] = []
		result["unlocked_feature_ids"] = []
		result["candidate_support_earned"] = 0
		result["candidate_support_total"] = SaveManager.get_candidate_support(StringName(result.get("candidate_id", "")))
		result["candidate_support_required"] = int(result.get("support_required_for_election", 0))
		result["candidate_newly_elected"] = false
		result["governance_approval_before"] = int(result.get("governance_approval", 0))
		result["governance_approval_delta"] = 0
	var result_candidate_id := StringName(result.get("candidate_id", ""))
	if result_candidate_id != &"":
		result["candidate_elected"] = SaveManager.is_candidate_elected(result_candidate_id)
		result["governance_approval"] = SaveManager.get_governance_approval(result_candidate_id) if bool(result.candidate_elected) else 0
	result["unlocked"] = _unlock_summary(new_unlocks)
	GameSession.last_result = result
	return result

func _unlock_summary(items: Array[String]) -> String:
	if items.is_empty():
		return "없음"
	if items.size() <= 3:
		return " · ".join(items)
	return "%s · 외 %d개" % [" · ".join(items.slice(0, 3)), items.size() - 3]
