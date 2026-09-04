class_name RewardSelectionCoordinator
extends RefCounted

var reward_queue: RunRewardQueue
var phase_coordinator: GamePhaseCoordinator
var scene_tree: SceneTree
var level_up_panel: LevelUpPanel
var artifact_resolution_panel: ArtifactResolutionPanel

func configure(
	target_queue: RunRewardQueue,
	target_phase: GamePhaseCoordinator,
	target_tree: SceneTree,
	target_level_up_panel: LevelUpPanel,
	target_artifact_panel: ArtifactResolutionPanel
) -> void:
	reward_queue = target_queue
	phase_coordinator = target_phase
	scene_tree = target_tree
	level_up_panel = target_level_up_panel
	artifact_resolution_panel = target_artifact_panel

func is_configured() -> bool:
	return reward_queue != null and phase_coordinator != null and is_instance_valid(scene_tree) and is_instance_valid(level_up_panel) and is_instance_valid(artifact_resolution_panel)

func begin_level_up(before_pause: Callable = Callable()) -> bool:
	if not is_configured() or not reward_queue.begin_level_up():
		return false
	return enter_selection(before_pause)

func begin_candidate_branch(before_pause: Callable = Callable()) -> bool:
	if not is_configured() or not reward_queue.begin_candidate_branch():
		return false
	return enter_selection(before_pause)

func begin_artifact_draft(before_pause: Callable = Callable()) -> bool:
	if not is_configured() or not reward_queue.begin_artifact_draft():
		return false
	return enter_selection(before_pause)

func enter_selection(before_pause: Callable = Callable()) -> bool:
	if not is_configured():
		return false
	if before_pause.is_valid():
		before_pause.call()
	phase_coordinator.enter_level_up()
	scene_tree.paused = true
	return true

func show_level_up_choices(choices: Array[UpgradeData], level: int, remaining_rerolls: int, maximum_rerolls: int) -> void:
	if is_instance_valid(level_up_panel):
		level_up_panel.show_choices(choices, level, remaining_rerolls, maximum_rerolls)

func show_event_choices(choices: Array[UpgradeData], title: String, hint: String) -> void:
	if is_instance_valid(level_up_panel):
		level_up_panel.show_event_choices(choices, title, hint)

func show_subchoices(choices: Array[UpgradeData], parent_title: String, level: int, allow_return: bool = true) -> void:
	if is_instance_valid(level_up_panel):
		level_up_panel.show_subchoices(choices, parent_title, level, allow_return)

func current_choices() -> Array[UpgradeData]:
	return level_up_panel.choices.duplicate() if is_instance_valid(level_up_panel) else []

func show_artifact_resolution(artifact: ArtifactData, equipped: Array[ArtifactData]) -> void:
	if not is_configured():
		return
	level_up_panel.hide_panel()
	artifact_resolution_panel.show_resolution(artifact, equipped)

func hide_level_up() -> void:
	if is_instance_valid(level_up_panel):
		level_up_panel.hide_panel()

func hide_artifact_resolution() -> void:
	if is_instance_valid(artifact_resolution_panel):
		artifact_resolution_panel.hide_panel()

func hide_all() -> void:
	hide_artifact_resolution()
	hide_level_up()

func continue_flow(next_reward_kind: int, open_artifact: Callable, open_candidate: Callable, show_level_up: Callable, resume_combat: Callable) -> void:
	hide_artifact_resolution()
	match next_reward_kind:
		RunRewardQueue.RewardKind.ARTIFACT_DRAFT:
			_call_if_valid(open_artifact)
		RunRewardQueue.RewardKind.CANDIDATE_BRANCH:
			_call_if_valid(open_candidate)
		RunRewardQueue.RewardKind.LEVEL_UP:
			_call_if_valid(show_level_up)
		_:
			_call_if_valid(resume_combat)
			hide_level_up()
			if is_instance_valid(scene_tree):
				scene_tree.paused = false

func _call_if_valid(callback: Callable) -> void:
	if callback.is_valid():
		callback.call()
