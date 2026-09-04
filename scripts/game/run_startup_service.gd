class_name RunStartupService
extends RefCounted

func build_plan(
	configured_stage: StageData,
	enemy_scene: PackedScene,
	testing_mode: bool,
	random_seed: int,
	result_service: RunResultService
) -> Dictionary:
	var tutorial_scenario: TutorialScenarioData
	if GameSession.is_tutorial_run():
		tutorial_scenario = load("res://data/tutorial/tutorial_v0_17.tres") as TutorialScenarioData
		if tutorial_scenario == null or not tutorial_scenario.get_validation_errors().is_empty():
			return _failure("GameController could not load a valid tutorial scenario.")
	var resolved_stage := tutorial_scenario.stage_data if tutorial_scenario != null else ConceptService.get_default_stage()
	if resolved_stage == null:
		resolved_stage = configured_stage
	if resolved_stage == null or enemy_scene == null:
		return _failure("GameController is missing required data or scenes.")
	var core_id := tutorial_scenario.core_id if tutorial_scenario != null else GameSession.selected_core_id
	var cursor_id := tutorial_scenario.cursor_id if tutorial_scenario != null else GameSession.selected_cursor_id
	var core_data := DataRegistry.get_core(core_id)
	var cursor_data := DataRegistry.get_cursor(cursor_id)
	if core_data == null or cursor_data == null:
		return _failure("GameController could not resolve the selected core or cursor.")
	RunRng.begin_run(testing_mode, random_seed)
	var campaign := ConceptService.get_election_campaign()
	var boss_plan := (
		CampaignStageResolver.build_fixed_plan(resolved_stage, DataRegistry.bosses, RunRng.current_seed)
		if tutorial_scenario != null else
		CampaignStageResolver.resolve(
			resolved_stage,
			DataRegistry.bosses,
			campaign,
			GameSession.selected_core_id,
			GameSession.selected_cursor_id,
			RunRng.current_seed
		)
	)
	var boss_plan_errors := boss_plan.get_validation_errors(resolved_stage, DataRegistry.catalog_ids(DataRegistry.bosses))
	if not boss_plan_errors.is_empty():
		return _failure("GameController could not create a valid runtime boss plan: %s" % ", ".join(boss_plan_errors))
	var candidate := campaign.candidate_for_core(core_data.id) if campaign != null else null
	var governance_reaction: GovernanceReactionData
	var governance_approval: int = 0
	if candidate != null and SaveManager.is_candidate_elected(candidate.id):
		governance_approval = SaveManager.get_governance_approval(candidate.id)
		governance_reaction = campaign.governance_reaction(governance_approval)
	var selected_decree := MetaProgressionService.get_candidate_decree(GameSession.selected_decree_id)
	return {
		"success": true,
		"error_message": "",
		"warning_message": "Runtime boss plan used the fixed fallback: %s" % boss_plan.fallback_reason if not boss_plan.fallback_reason.is_empty() else "",
		"stage_data": resolved_stage,
		"boss_plan": boss_plan,
		"run_id": result_service.create_run_id(),
		"core_data": core_data,
		"cursor_data": cursor_data,
		"candidate": candidate,
		"decree_name": selected_decree.display_name if selected_decree != null else "",
		"governance_reaction": governance_reaction,
		"governance_approval": governance_approval,
		"tutorial_scenario": tutorial_scenario,
	}

func begin_checkpoint(checkpoint_result: Dictionary, testing_mode: bool) -> bool:
	return testing_mode or GameSession.is_tutorial_run() or RunCheckpointService.begin_run(checkpoint_result)

func _failure(message: String) -> Dictionary:
	return {
		"success": false,
		"error_message": message,
	}
