class_name RuntimePerformanceBudget
extends RefCounted

const TARGET_FRAME_MS: float = 33.333
const MAX_OVER_33_MS_RATIO: float = 0.01
const MAX_ACTIVE_ENEMIES: int = 180
const MAX_PROJECTILES: int = 160
const MAX_EFFECTS: int = 48
const MAX_ACTIVE_SUMMONS: int = SummonService.TOTAL_BUDGET_COST
const MAX_SUMMON_BUDGET_COST: int = SummonService.TOTAL_BUDGET_COST

static func assess(snapshot: Dictionary) -> Dictionary:
	var frame_count := maxi(int(snapshot.get("frame_count", 0)), 0)
	var violations: Array[String] = []
	if frame_count <= 0:
		violations.append("no runtime frames measured")
	if float(snapshot.get("average_frame_ms", 0.0)) > TARGET_FRAME_MS:
		violations.append("average frame time exceeds %.3fms" % TARGET_FRAME_MS)
	if float(snapshot.get("over_33_ms_ratio", 0.0)) > MAX_OVER_33_MS_RATIO:
		violations.append("slow-frame ratio exceeds %.1f%%" % (MAX_OVER_33_MS_RATIO * 100.0))
	if int(snapshot.get("peak_active_enemies", 0)) > MAX_ACTIVE_ENEMIES:
		violations.append("active enemy peak exceeds %d" % MAX_ACTIVE_ENEMIES)
	if int(snapshot.get("peak_projectiles", 0)) > MAX_PROJECTILES:
		violations.append("projectile peak exceeds %d" % MAX_PROJECTILES)
	if int(snapshot.get("peak_effects", 0)) > MAX_EFFECTS:
		violations.append("effect peak exceeds %d" % MAX_EFFECTS)
	if int(snapshot.get("peak_summons", 0)) > MAX_ACTIVE_SUMMONS:
		violations.append("summon peak exceeds %d" % MAX_ACTIVE_SUMMONS)
	if int(snapshot.get("peak_summon_budget_cost", 0)) > MAX_SUMMON_BUDGET_COST:
		violations.append("summon budget cost exceeds %d" % MAX_SUMMON_BUDGET_COST)
	return {
		"measured": frame_count > 0,
		"passed": violations.is_empty(),
		"violations": violations,
		"limits": {
			"target_frame_ms": TARGET_FRAME_MS,
			"max_over_33_ms_ratio": MAX_OVER_33_MS_RATIO,
			"max_active_enemies": MAX_ACTIVE_ENEMIES,
			"max_projectiles": MAX_PROJECTILES,
			"max_effects": MAX_EFFECTS,
			"max_active_summons": MAX_ACTIVE_SUMMONS,
			"max_summon_budget_cost": MAX_SUMMON_BUDGET_COST,
		},
	}
