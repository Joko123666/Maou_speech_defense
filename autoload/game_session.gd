extends Node

const RUN_MODE_STANDARD: StringName = &"standard"
const RUN_MODE_TUTORIAL: StringName = &"tutorial"
const ARTIFACT_MODE_DISABLED: StringName = &"disabled"
const ARTIFACT_MODE_NORMAL: StringName = &"normal"
const ARTIFACT_MODE_FORCED: StringName = &"forced"
const ARTIFACT_MODES: Array[StringName] = [ARTIFACT_MODE_DISABLED, ARTIFACT_MODE_NORMAL, ARTIFACT_MODE_FORCED]

var selected_core_id: StringName = &"emerald"
var selected_cursor_id: StringName = &"iron"
var selected_challenge_level: int = 0
var selected_decree_id: StringName = &""
var last_result: Dictionary = {}
var meta_notice: String = ""
var screen_shake_enabled: bool = true
var screen_flash_enabled: bool = true
var reduced_motion_enabled: bool = false
var run_mode: StringName = RUN_MODE_STANDARD
var artifact_mode: StringName = ARTIFACT_MODE_NORMAL

func configure(core_id: StringName, cursor_id: StringName, challenge_level: int = 0) -> void:
	run_mode = RUN_MODE_STANDARD
	artifact_mode = ARTIFACT_MODE_NORMAL
	selected_core_id = core_id
	selected_cursor_id = cursor_id
	selected_challenge_level = ChallengeRules.clamp_level(challenge_level)
	selected_decree_id = &""
	var campaign := ConceptService.get_election_campaign()
	var candidate := campaign.candidate_for_core(core_id) if campaign != null else null
	if candidate != null and SaveManager.is_candidate_elected(candidate.id):
		selected_decree_id = MetaProgressionService.ensure_candidate_decree(candidate.id)
	last_result.clear()

func configure_tutorial() -> void:
	run_mode = RUN_MODE_TUTORIAL
	artifact_mode = ARTIFACT_MODE_DISABLED
	selected_core_id = &"emerald"
	selected_cursor_id = &"iron"
	selected_challenge_level = 0
	selected_decree_id = &""
	last_result.clear()

func is_tutorial_run() -> bool:
	return run_mode == RUN_MODE_TUTORIAL

func end_tutorial_run() -> void:
	run_mode = RUN_MODE_STANDARD
	artifact_mode = ARTIFACT_MODE_NORMAL
