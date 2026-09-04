class_name StageRewardData
extends Resource

@export var stage_id: StringName = &"standard_20m"
@export var stage_duration_seconds: float = 600.0
@export var base_progress_funds: int = 180
@export var progress_curve_power: float = 1.70
@export var boss_funds_by_id: Dictionary = {
	&"boss_5": 15,
	&"boss_10": 25,
	&"boss_15": 35,
	&"final_boss": 50,
	&"judgment_bell": 42,
}
@export var victory_bonus: int = 75
@export var challenge_funds_per_level: float = 0.06
@export var stage_first_clear_bonus: int = 150
@export var challenge_first_clear_funds: Dictionary = {
	3: 100,
	5: 150,
	7: 200,
	10: 300,
}
@export var abandon_minimum_seconds: float = 30.0
