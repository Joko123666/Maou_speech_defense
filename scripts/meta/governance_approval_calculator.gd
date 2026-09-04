class_name GovernanceApprovalCalculator
extends RefCounted

const VICTORY_APPROVAL := 8
const CHALLENGE_LEVELS_PER_BONUS := 2
const MAX_CHALLENGE_BONUS := 5
const MIN_DEFEAT_LOSS := 2
const MAX_DEFEAT_LOSS := 10

static func calculate(result: Dictionary, approval_before: int) -> Dictionary:
	var candidate_id := String(result.get("candidate_id", ""))
	var before := clampi(approval_before, 0, 100)
	var eligible := (
		not candidate_id.is_empty()
		and bool(result.get("candidate_elected", false))
		and bool(result.get("eligible_for_meta_rewards", true))
	)
	if not eligible:
		return empty_breakdown(candidate_id, before)
	var duration := maxf(float(result.get("stage_duration_seconds", 600.0)), 1.0)
	var elapsed := clampf(float(result.get("elapsed", 0.0)), 0.0, duration)
	var progress_ratio := elapsed / duration
	var boss_kills := _unique_boss_kill_count(result)
	var challenge_bonus := 0
	var defeat_loss := 0
	var boss_mitigation := 0
	var calculated_delta := 0
	if bool(result.get("victory", false)):
		challenge_bonus = mini(
			ChallengeRules.clamp_level(int(result.get("challenge_level", 0))) / CHALLENGE_LEVELS_PER_BONUS,
			MAX_CHALLENGE_BONUS
		)
		calculated_delta = VICTORY_APPROVAL + challenge_bonus
	else:
		defeat_loss = maxi(MIN_DEFEAT_LOSS, ceili((1.0 - progress_ratio) * float(MAX_DEFEAT_LOSS)))
		boss_mitigation = mini(boss_kills, maxi(defeat_loss - 1, 0))
		calculated_delta = -(defeat_loss - boss_mitigation)
	var after := clampi(before + calculated_delta, 0, 100)
	return {
		"candidate_id": candidate_id,
		"eligible": true,
		"approval_before": before,
		"approval_delta": after - before,
		"calculated_delta": calculated_delta,
		"approval_after": after,
		"progress_ratio": progress_ratio,
		"boss_kills": boss_kills,
		"victory_approval": VICTORY_APPROVAL if bool(result.get("victory", false)) else 0,
		"challenge_bonus": challenge_bonus,
		"defeat_loss": defeat_loss,
		"boss_mitigation": boss_mitigation,
	}

static func empty_breakdown(candidate_id: String = "", approval: int = 0) -> Dictionary:
	var safe_approval := clampi(approval, 0, 100)
	return {
		"candidate_id": candidate_id,
		"eligible": false,
		"approval_before": safe_approval,
		"approval_delta": 0,
		"calculated_delta": 0,
		"approval_after": safe_approval,
		"progress_ratio": 0.0,
		"boss_kills": 0,
		"victory_approval": 0,
		"challenge_bonus": 0,
		"defeat_loss": 0,
		"boss_mitigation": 0,
	}

static func _unique_boss_kill_count(result: Dictionary) -> int:
	var ids_value: Variant = result.get("boss_kill_ids", [])
	if ids_value is not Array:
		return maxi(int(result.get("boss_kills", 0)), 0)
	var unique_ids: Dictionary = {}
	for value in ids_value:
		var boss_id := String(value)
		if not boss_id.is_empty():
			unique_ids[boss_id] = true
	return unique_ids.size()
