class_name EnemyData
extends Resource

@export var id: StringName = &"basic"
@export var display_name: String = "기본 적"
@export var max_health: float = 36.0
@export var move_speed: float = 72.0
@export var core_damage: float = 10.0
@export var experience_value: float = 1.0
@export_range(0.1, 100.0, 0.1) var spawn_cost: float = 1.0
@export var role_tags: Array[StringName] = [&"frontline"]
@export var armor: float = 0.0
@export_range(0.0, 1.0, 0.05) var knockback_resistance: float = 0.0
@export_range(0.0, 1.0, 0.05) var status_resistance: float = 0.0
@export var control_resistance_profile: ControlResistanceProfileData
@export var movement_profile: EnemyMovementProfileData
@export var acceleration_profile: EnemyAccelerationProfileData
@export var group_acceleration_profile: EnemyGroupAccelerationProfileData
@export var decay_profile: EnemyDecayProfileData
@export var formation_profile: EnemyFormationProfileData
@export var death_effect_profile: EnemyDeathEffectProfileData
@export var available_from_seconds: float = 0.0
@export var behavior: StringName = &"normal"
@export var is_boss: bool = false
@export var is_elite: bool = false
@export var boss_tier: int = 0
@export var target_priority: float = 0.0
@export var body_color: Color = Color("e65f5c")
@export var radius: float = 18.0
@export var texture: Texture2D
