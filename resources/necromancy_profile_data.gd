class_name NecromancyProfileData
extends Resource

@export_range(1, 12, 1) var maximum_charges: int = 4
@export_range(0.0, 1.0, 0.01) var normal_defeat_chance: float = 0.15
@export var elite_enemy_ids: Array[StringName] = [&"orc_shield", &"wraith_raider", &"steel_golem"]
@export_range(1, 5, 1) var elite_charge_gain: int = 1
@export_range(1, 8, 1) var boss_charge_gain_minimum: int = 2
@export_range(1, 8, 1) var boss_charge_gain_maximum: int = 3
@export_range(0.0, 5.0, 0.05) var spirit_damage_multiplier: float = 0.72
@export_range(8.0, 240.0, 1.0) var spirit_blast_radius: float = 72.0
@export_range(1, 12, 1) var maximum_simultaneous_summons: int = 4
@export_range(0.05, 3.0, 0.05) var summon_visual_duration: float = 0.6

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if maximum_charges <= 0: errors.append("necromancy maximum charges must be positive")
	if normal_defeat_chance <= 0.0: errors.append("necromancy normal defeat chance must be positive")
	if elite_charge_gain <= 0: errors.append("necromancy elite charge gain must be positive")
	if boss_charge_gain_minimum <= 0 or boss_charge_gain_maximum < boss_charge_gain_minimum: errors.append("necromancy boss charge range is invalid")
	if spirit_damage_multiplier <= 0.0: errors.append("necromancy spirit damage multiplier must be positive")
	if spirit_blast_radius <= 0.0: errors.append("necromancy spirit blast radius must be positive")
	if maximum_simultaneous_summons <= 0: errors.append("necromancy simultaneous summon cap must be positive")
	return errors
