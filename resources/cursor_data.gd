class_name CursorData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var attack_type: StringName = &"area"
@export var damage: float = 18.0
@export var attack_interval: float = 0.45
@export var attack_radius: float = 75.0
@export var knockback: float = 25.0
@export var collection_radius: float = 110.0
@export var experience_multiplier: float = 1.0
@export var movement_speed: float = 300.0
@export var color: Color = Color("59d1ff")
@export var texture: Texture2D
