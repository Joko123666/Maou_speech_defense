class_name GoblinTacticsService
extends RefCounted

const BLEED_SOURCE_ID := &"goblin_tactics_bleed"
const MARK_DURATION := 3.5

func execute(
		tower: TowerData,
		target: Enemy,
		attack_damage: float,
		attack_count: int,
		modifiers: Dictionary,
		poison_profile: Dictionary,
		bleed_profile: Dictionary,
		roll_override: float = -1.0
	) -> Dictionary:
	if tower == null or tower.behavior != &"rapid" or target == null or not target.active:
		return _empty_result()
	var tactics_cycle := int(modifiers.get("tactics_cycle", 0))
	if tactics_cycle <= 0 or attack_count < 0 or attack_count % tactics_cycle != 0:
		return _empty_result()
	var resolved_roll := roll_override if roll_override >= 0.0 else RunRng.roll()
	var poison_selected := resolved_roll < float(modifiers.get("tactics_poison_chance", 0.5))
	var selected_status := &"poison" if poison_selected else &"bleed"
	var sample_id := &"status.poison_stacks" if poison_selected else &"status.bleed_sources"
	if poison_selected:
		target.apply_common_poison(
			maxf(float(modifiers.get("tactics_poison_damage", 0.0)), float(poison_profile.get("damage_per_second", 0.0))),
			float(poison_profile.get("duration", 0.0)),
			int(poison_profile.get("max_stacks", 0))
		)
	else:
		target.apply_common_bleed(
			BLEED_SOURCE_ID,
			maxf(float(modifiers.get("tactics_bleed_ratio", 0.0)), float(bleed_profile.get("health_ratio", 0.0))),
			float(bleed_profile.get("duration", 0.0)),
			int(bleed_profile.get("max_stacks", 0)),
			maxf(attack_damage * 0.8, float(bleed_profile.get("damage_cap", 0.0)))
		)
	target.apply_status(&"mark", MARK_DURATION, float(modifiers.get("tactics_mark", 0.0)))
	var sample_value := target.get_common_ailment_stacks(&"poison") if poison_selected else target.get_common_ailment_source_count(&"bleed")
	return {
		"applied": true,
		"selected_status": selected_status,
		"status_ids": [selected_status, &"mark"],
		"sample_id": sample_id,
		"sample_value": sample_value,
	}

func _empty_result() -> Dictionary:
	return {
		"applied": false,
		"selected_status": &"",
		"status_ids": [],
		"sample_id": &"",
		"sample_value": 0,
	}
