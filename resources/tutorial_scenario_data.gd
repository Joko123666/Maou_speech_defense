class_name TutorialScenarioData
extends Resource

@export var id: StringName = &"tutorial_v0_17"
@export var stage_data: StageData
@export var core_id: StringName = &"emerald"
@export var cursor_id: StringName = &"iron"
@export var formation_id: StringName = &"guidance"
@export var required_formation_anchor: Vector2i = Vector2i(4, 1)
@export var fixed_upgrade_category: StringName = &"tower_type_level"
@export var fixed_upgrade_id: StringName = &"rapid"
@export var tutorial_enemy_id: StringName = &"goblin_raider"
@export var tutorial_boss_id: StringName = &"boss_5"
@export_range(0.5, 10.0, 0.1) var observation_seconds: float = 3.0
@export_range(0.1, 3.0, 0.05) var practice_first_wave_delay_seconds: float = 0.35
@export_range(0.5, 8.0, 0.1) var practice_wave_interval_seconds: float = 2.6
@export_range(2, 5, 1) var practice_wave_count: int = 3
@export_range(1, 4, 1) var practice_units_per_wave: int = 2
@export_range(0.1, 1.0, 0.05) var practice_enemy_health_multiplier: float = 0.55
@export_range(0.5, 1.5, 0.05) var practice_enemy_speed_multiplier: float = 0.9
@export_range(4.0, 20.0, 0.1) var boss_lead_in_seconds: float = 9.0
@export_range(1.0, 8.0, 0.1) var boss_warning_seconds: float = 2.4
@export_range(1.0, 600.0, 1.0) var expected_min_seconds: float = 45.0
@export_range(1.0, 600.0, 1.0) var expected_max_seconds: float = 75.0

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("tutorial scenario id is empty")
	if stage_data == null:
		errors.append("tutorial scenario has no stage")
		return errors
	if stage_data.duration_seconds < expected_min_seconds or stage_data.duration_seconds > expected_max_seconds:
		errors.append("tutorial stage duration must stay inside its expected completion window")
	if stage_data.boss_times.size() != 1 or stage_data.default_boss_ids.size() != 1:
		errors.append("tutorial stage must contain exactly one boss slot")
	elif stage_data.default_boss_ids[0] != tutorial_boss_id or stage_data.final_boss_id != tutorial_boss_id:
		errors.append("tutorial boss ids do not match the stage")
	if stage_data.spawn_table.is_empty():
		errors.append("tutorial stage has no spawn table")
	for wave in stage_data.spawn_table:
		var weights := wave.get("weights", {}) as Dictionary
		if weights.size() != 1 or not weights.has(tutorial_enemy_id):
			errors.append("tutorial spawn table must contain only the designated enemy")
	if stage_data.spawn_packets.size() > 0 or stage_data.faction_preludes.size() > 0 or stage_data.faction_spawn_packets.size() > 0:
		errors.append("tutorial stage must not include packets or faction preludes")
	if core_id == &"" or cursor_id == &"" or formation_id == &"" or fixed_upgrade_id == &"":
		errors.append("tutorial scenario contains an empty fixed content id")
	var last_practice_wave_time := practice_first_wave_delay_seconds + practice_wave_interval_seconds * float(practice_wave_count - 1)
	if last_practice_wave_time >= boss_lead_in_seconds - boss_warning_seconds:
		errors.append("tutorial practice waves must finish before the boss warning")
	if boss_warning_seconds >= boss_lead_in_seconds:
		errors.append("tutorial boss warning must be shorter than its lead-in")
	return errors
