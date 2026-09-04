class_name CoreData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var attack_type: StringName = &"single"
@export var skill_type: StringName = &"beam"
@export var passive_type: StringName = &"balanced"
@export var damage: float = 12.0
@export var attack_interval: float = 0.7
@export var attack_range: float = 900.0
@export var max_health: float = 150.0
@export var regeneration: float = 0.25
@export var skill_damage: float = 100.0
@export var skill_charge_seconds: float = 18.0
@export var skill_cast_seconds: float = 1.0
@export var suppress_basic_attack_during_skill_cast: bool = false
@export var unique_tower_id: StringName
@export var unique_formation_id: StringName
@export var charm_profile: CharmProfileData
@export var judgment_profile: JudgmentProfileData
@export var necromancy_profile: NecromancyProfileData
@export var color: Color = Color("53d5a5")
@export var texture: Texture2D
