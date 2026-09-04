class_name FactionPreludeBudgetLedger
extends RefCounted

var active_key: String = ""
var active_faction_id: StringName = &""
var active_tier: int = 0
var active_common_spent: float = 0.0
var active_faction_spent: float = 0.0
var lifetime_common_spent: float = 0.0
var lifetime_faction_spent: float = 0.0
var faction_spent_by_id: Dictionary = {}
var total_spent_by_tier: Dictionary = {}
var cost_by_channel: Dictionary = {}
var prelude_windows: Dictionary = {}

func reset() -> void:
	active_key = ""
	active_faction_id = &""
	active_tier = 0
	active_common_spent = 0.0
	active_faction_spent = 0.0
	lifetime_common_spent = 0.0
	lifetime_faction_spent = 0.0
	faction_spent_by_id.clear()
	total_spent_by_tier.clear()
	cost_by_channel.clear()
	prelude_windows.clear()

func sync(prelude: Dictionary) -> void:
	if not bool(prelude.get("active", false)):
		return
	var next_key := "%d:%s" % [int(prelude.get("boss_index", -1)), String(prelude.get("faction_id", &""))]
	if next_key == active_key:
		return
	active_key = next_key
	active_faction_id = StringName(prelude.get("faction_id", &""))
	active_tier = int(prelude.get("tier", 0))
	active_common_spent = 0.0
	active_faction_spent = 0.0
	if not prelude_windows.has(active_key):
		prelude_windows[active_key] = {
			"boss_index": int(prelude.get("boss_index", -1)),
			"faction_id": String(active_faction_id),
			"tier": active_tier,
			"start_seconds": float(prelude.get("start_seconds", 0.0)),
			"end_seconds": float(prelude.get("end_seconds", 0.0)),
			"ratio_min": float(prelude.get("ratio_min", 0.0)),
			"ratio_max": float(prelude.get("ratio_max", 0.0)),
			"common_cost": 0.0,
			"faction_cost": 0.0,
			"cost_by_channel": {},
		}

func target_ratio(prelude: Dictionary, at_time: float) -> float:
	if not bool(prelude.get("active", false)):
		return 0.0
	var start_seconds := float(prelude.get("start_seconds", at_time))
	var end_seconds := float(prelude.get("end_seconds", at_time))
	var progress := clampf((at_time - start_seconds) / maxf(end_seconds - start_seconds, 0.001), 0.0, 1.0)
	return lerpf(float(prelude.get("ratio_min", 0.0)), float(prelude.get("ratio_max", 0.0)), progress)

func should_select_faction(common_cost: float, faction_cost: float, prelude: Dictionary, at_time: float) -> bool:
	if faction_cost <= 0.0 or not bool(prelude.get("active", false)):
		return false
	sync(prelude)
	if common_cost <= 0.0:
		return true
	var ratio := target_ratio(prelude, at_time)
	var spent := active_common_spent + active_faction_spent
	var common_total := spent + common_cost
	var faction_total := spent + faction_cost
	var common_error := absf(active_faction_spent - common_total * ratio)
	var faction_error := absf(active_faction_spent + faction_cost - faction_total * ratio)
	return faction_error <= common_error

func record_spend(cost: float, is_faction: bool, prelude: Dictionary, channel: StringName = &"base") -> void:
	if cost <= 0.0 or not bool(prelude.get("active", false)):
		return
	sync(prelude)
	var safe_cost := maxf(cost, 0.0)
	if is_faction:
		active_faction_spent += safe_cost
		lifetime_faction_spent += safe_cost
		faction_spent_by_id[active_faction_id] = float(faction_spent_by_id.get(active_faction_id, 0.0)) + safe_cost
	else:
		active_common_spent += safe_cost
		lifetime_common_spent += safe_cost
	total_spent_by_tier[active_tier] = float(total_spent_by_tier.get(active_tier, 0.0)) + safe_cost
	var channel_key := String(channel)
	var channel_entry: Dictionary = cost_by_channel.get(channel_key, {"common_cost": 0.0, "faction_cost": 0.0})
	var cost_key := "faction_cost" if is_faction else "common_cost"
	channel_entry[cost_key] = float(channel_entry.get(cost_key, 0.0)) + safe_cost
	cost_by_channel[channel_key] = channel_entry
	var window := prelude_windows.get(active_key, {}) as Dictionary
	window[cost_key] = float(window.get(cost_key, 0.0)) + safe_cost
	var window_channels := window.get("cost_by_channel", {}) as Dictionary
	var window_channel := window_channels.get(channel_key, {"common_cost": 0.0, "faction_cost": 0.0}) as Dictionary
	window_channel[cost_key] = float(window_channel.get(cost_key, 0.0)) + safe_cost
	window_channels[channel_key] = window_channel
	window["cost_by_channel"] = window_channels
	prelude_windows[active_key] = window

func snapshot(prelude: Dictionary, at_time: float) -> Dictionary:
	var current_key := "%d:%s" % [int(prelude.get("boss_index", -1)), String(prelude.get("faction_id", &""))]
	var matches_active_prelude := (
		bool(prelude.get("active", false))
		and active_key == current_key
	)
	var current_common_spent := active_common_spent if matches_active_prelude else 0.0
	var current_faction_spent := active_faction_spent if matches_active_prelude else 0.0
	var active_total := current_common_spent + current_faction_spent
	var lifetime_total := lifetime_common_spent + lifetime_faction_spent
	var window_entries: Array[Dictionary] = []
	for window_value in prelude_windows.values():
		var window := (window_value as Dictionary).duplicate(true)
		var window_total := float(window.get("common_cost", 0.0)) + float(window.get("faction_cost", 0.0))
		window["total_cost"] = window_total
		window["actual_ratio"] = float(window.get("faction_cost", 0.0)) / window_total if window_total > 0.0 else 0.0
		window_entries.append(window)
	window_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.get("boss_index", -1)) < int(b.get("boss_index", -1)))
	return {
		"prelude_active": bool(prelude.get("active", false)),
		"prelude_faction_id": String(prelude.get("faction_id", &"")),
		"prelude_tier": int(prelude.get("tier", 0)),
		"prelude_target_ratio": target_ratio(prelude, at_time),
		"prelude_actual_ratio": current_faction_spent / active_total if active_total > 0.0 else 0.0,
		"prelude_common_cost": current_common_spent,
		"prelude_faction_cost": current_faction_spent,
		"prelude_total_cost": active_total,
		"lifetime_common_cost": lifetime_common_spent,
		"lifetime_faction_cost": lifetime_faction_spent,
		"lifetime_faction_ratio": lifetime_faction_spent / lifetime_total if lifetime_total > 0.0 else 0.0,
		"faction_cost_by_id": faction_spent_by_id.duplicate(),
		"prelude_cost_by_tier": total_spent_by_tier.duplicate(),
		"prelude_cost_by_channel": cost_by_channel.duplicate(true),
		"prelude_windows": window_entries,
	}
