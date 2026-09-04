class_name AchievementService
extends RefCounted

var achievements: Array[AchievementData] = []

func _init(catalog: Array[AchievementData] = []) -> void:
	achievements = catalog

func evaluate(metrics: Dictionary) -> Dictionary:
	var progress_updates: Dictionary = {}
	var completed_ids: Array[String] = []
	var discovered_product_ids: Array[String] = []
	var unlocked_feature_ids: Array[String] = []
	var unlocked_content_ids: Array[String] = []
	var reward_funds := 0
	for achievement in achievements:
		var id := String(achievement.id)
		if id in SaveManager.completed_achievement_ids or not requirements_met(achievement):
			continue
		var run_value := float(metrics.get(String(achievement.metric_id), 0.0))
		var previous := float(SaveManager.achievement_progress.get(id, 0.0))
		var progress := _next_progress(previous, run_value, achievement.progress_mode)
		progress_updates[id] = progress
		if not _is_complete(progress, achievement.target_value, achievement.comparison):
			continue
		completed_ids.append(id)
		reward_funds += maxi(achievement.reward_funds, 0)
		_append_unique_names(discovered_product_ids, achievement.discover_product_ids)
		_append_unique_names(unlocked_feature_ids, achievement.unlock_feature_ids)
		_append_unique_names(unlocked_content_ids, achievement.unlock_content_ids)
	return {
		"progress_updates": progress_updates,
		"completed_ids": completed_ids,
		"claimed_ids": completed_ids.duplicate(),
		"discovered_product_ids": discovered_product_ids,
		"unlocked_feature_ids": unlocked_feature_ids,
		"unlocked_content_ids": unlocked_content_ids,
		"reward_funds": reward_funds,
	}

func get_progress(achievement: AchievementData) -> float:
	return float(SaveManager.achievement_progress.get(String(achievement.id), 0.0))

func get_state(achievement: AchievementData) -> Dictionary:
	if achievement == null:
		return {}
	var id := String(achievement.id)
	var completed := id in SaveManager.completed_achievement_ids
	var progress := achievement.target_value if completed else get_progress(achievement)
	return {
		"completed": completed,
		"available": requirements_met(achievement),
		"progress": progress,
		"target": achievement.target_value,
		"ratio": clampf(progress / maxf(achievement.target_value, 0.001), 0.0, 1.0),
		"claimed": id in SaveManager.claimed_achievement_ids,
	}

func requirements_met(achievement: AchievementData) -> bool:
	for product_id in achievement.required_product_ids:
		if String(product_id) not in SaveManager.purchased_shop_product_ids:
			return false
	if not achievement.required_any_product_ids.is_empty():
		var any_met := false
		for product_id in achievement.required_any_product_ids:
			if String(product_id) in SaveManager.purchased_shop_product_ids:
				any_met = true
				break
		if not any_met:
			return false
	for feature_id in achievement.required_feature_ids:
		if String(feature_id) not in SaveManager.unlocked_feature_ids:
			return false
	return true

func _next_progress(previous: float, run_value: float, mode: StringName) -> float:
	match mode:
		&"maximum", &"single_run": return maxf(previous, run_value)
		&"replace": return run_value
	return previous + run_value

func _is_complete(progress: float, target: float, comparison: StringName) -> bool:
	match comparison:
		&"less_or_equal": return progress <= target
		&"equal": return is_equal_approx(progress, target)
	return progress >= target

func _append_unique_names(target: Array[String], values: Array[StringName]) -> void:
	for value in values:
		var id := String(value)
		if not id.is_empty() and id not in target:
			target.append(id)
