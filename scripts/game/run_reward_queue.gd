class_name RunRewardQueue
extends RefCounted

enum RewardKind {
	NONE,
	ARTIFACT_DRAFT,
	LEVEL_UP,
	CANDIDATE_BRANCH,
}

var selection_active: bool = false
var pending_level_ups: int = 0
var reward_levels: Array[int] = []
var pending_candidate_branches: int = 0
var candidate_branch_active: bool = false
var pending_artifact_draft_tiers: Array[int] = []
var artifact_draft_active: bool = false

func enqueue_level_up(level: int) -> bool:
	var should_open := not selection_active
	pending_level_ups += 1
	reward_levels.append(level)
	return should_open

func begin_level_up() -> bool:
	if pending_level_ups <= 0 or candidate_branch_active or artifact_draft_active or selection_active:
		return false
	selection_active = true
	return true

func enqueue_candidate_branch() -> bool:
	var should_open := not selection_active
	pending_candidate_branches += 1
	return should_open

func begin_candidate_branch() -> bool:
	if pending_candidate_branches <= 0 or candidate_branch_active or artifact_draft_active:
		return false
	pending_candidate_branches -= 1
	candidate_branch_active = true
	selection_active = true
	return true

func enqueue_artifact_draft(tier: int) -> bool:
	if tier <= 0:
		return false
	var should_open := not selection_active
	pending_artifact_draft_tiers.append(tier)
	return should_open

func begin_artifact_draft() -> bool:
	if pending_artifact_draft_tiers.is_empty() or artifact_draft_active or candidate_branch_active:
		return false
	artifact_draft_active = true
	selection_active = true
	return true

func current_artifact_draft_tier() -> int:
	return pending_artifact_draft_tiers[0] if not pending_artifact_draft_tiers.is_empty() else 0

func complete_artifact_draft() -> int:
	artifact_draft_active = false
	if not pending_artifact_draft_tiers.is_empty():
		pending_artifact_draft_tiers.pop_front()
	return _settle_next_reward()

func complete_level_up() -> int:
	pending_level_ups = maxi(pending_level_ups - 1, 0)
	if not reward_levels.is_empty():
		reward_levels.pop_front()
	return _settle_next_reward()

func complete_candidate_branch() -> int:
	candidate_branch_active = false
	return _settle_next_reward()

func discard_candidate_branches() -> int:
	pending_candidate_branches = 0
	candidate_branch_active = false
	return _settle_next_reward()

func current_reward_level(fallback_level: int) -> int:
	return reward_levels[0] if not reward_levels.is_empty() else fallback_level

func next_reward_kind() -> int:
	if not pending_artifact_draft_tiers.is_empty():
		return RewardKind.ARTIFACT_DRAFT
	if pending_candidate_branches > 0:
		return RewardKind.CANDIDATE_BRANCH
	if pending_level_ups > 0:
		return RewardKind.LEVEL_UP
	return RewardKind.NONE

func reset() -> void:
	selection_active = false
	pending_level_ups = 0
	reward_levels.clear()
	pending_candidate_branches = 0
	candidate_branch_active = false
	pending_artifact_draft_tiers.clear()
	artifact_draft_active = false

func _settle_next_reward() -> int:
	var next_kind := next_reward_kind()
	selection_active = next_kind != RewardKind.NONE
	return next_kind
