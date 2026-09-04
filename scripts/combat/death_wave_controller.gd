class_name DeathWaveController
extends Node2D

const SUMMON_OWNER_ID: StringName = &"irelai_death_wave"
const SUMMON_BUDGET_COST := 2

signal hit_requested(enemy: Enemy, damage: float, spirit_gain: int, spirit_damage_multiplier: float)
signal wave_finished

var battlefield: Battlefield
var spatial_index: EnemySpatialIndex
var summon_service: SummonService
var summon_budget_token: int = 0
var active: bool = false
var elapsed: float = 0.0
var duration: float = 2.4
var start_x: float = 0.0
var end_x: float = 0.0
var previous_x: float = 0.0
var current_x: float = 0.0
var center_y: float = 0.0
var half_height: float = 160.0
var wave_damage: float = 0.0
var spirit_gain_per_defeat: int = 1
var generated_spirit_damage_multiplier: float = 1.0
var wave_color := Color("78dba6")
var hit_instance_ids: Dictionary = {}

func setup(target_battlefield: Battlefield, index: EnemySpatialIndex, shared_summon_service: SummonService = null) -> void:
	battlefield = target_battlefield
	spatial_index = index
	summon_service = shared_summon_service
	z_index = 6
	set_physics_process(false)

func launch(
	damage: float,
	target_center_y: float,
	target_half_height: float,
	wave_duration: float,
	spirit_gain: int,
	spirit_damage_multiplier: float,
	color: Color
) -> bool:
	if battlefield == null or spatial_index == null:
		return false
	if active:
		cancel()
	if summon_service != null:
		var tokens := summon_service.request_slots(SUMMON_OWNER_ID, 1, 1, 0, 0, SUMMON_BUDGET_COST, &"candidate_active")
		if tokens.is_empty():
			return false
		summon_budget_token = tokens[0]
	var battle_rect := battlefield.get_battle_rect()
	active = true
	elapsed = 0.0
	duration = maxf(wave_duration, 0.2)
	start_x = battle_rect.position.x - 48.0
	end_x = battle_rect.end.x + 48.0
	previous_x = start_x
	current_x = start_x
	center_y = clampf(target_center_y, battle_rect.position.y, battle_rect.end.y)
	half_height = clampf(target_half_height, 48.0, battle_rect.size.y * 0.5)
	wave_damage = maxf(damage, 0.0)
	spirit_gain_per_defeat = maxi(spirit_gain, 1)
	generated_spirit_damage_multiplier = maxf(spirit_damage_multiplier, 0.0)
	wave_color = color
	hit_instance_ids.clear()
	set_physics_process(true)
	queue_redraw()
	return true

func cancel() -> void:
	active = false
	set_physics_process(false)
	hit_instance_ids.clear()
	_release_budget_slot()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if not active:
		return
	elapsed = minf(elapsed + maxf(delta, 0.0), duration)
	previous_x = current_x
	current_x = lerpf(start_x, end_x, elapsed / duration)
	for enemy in spatial_index.get_active_enemies():
		if enemy == null or not enemy.active or hit_instance_ids.has(enemy.get_instance_id()):
			continue
		if absf(enemy.global_position.y - center_y) > half_height + enemy.data.radius:
			continue
		if enemy.global_position.x + enemy.data.radius < previous_x or enemy.global_position.x - enemy.data.radius > current_x:
			continue
		hit_instance_ids[enemy.get_instance_id()] = true
		hit_requested.emit(enemy, wave_damage, spirit_gain_per_defeat, generated_spirit_damage_multiplier)
	queue_redraw()
	if elapsed >= duration:
		active = false
		set_physics_process(false)
		_release_budget_slot()
		wave_finished.emit()
		queue_redraw()

func _release_budget_slot() -> void:
	if summon_service != null and summon_budget_token > 0:
		summon_service.release_slot(summon_budget_token)
	summon_budget_token = 0

func _exit_tree() -> void:
	_release_budget_slot()

func _draw() -> void:
	if not active:
		return
	var wave_rect := Rect2(Vector2(current_x - 34.0, center_y - half_height), Vector2(68.0, half_height * 2.0))
	draw_rect(wave_rect, Color(wave_color, 0.18), true)
	draw_line(Vector2(current_x, center_y - half_height), Vector2(current_x, center_y + half_height), Color(wave_color.lightened(0.35), 0.92), 5.0, true)
	for offset in [-22.0, 22.0]:
		draw_line(Vector2(current_x + offset, center_y - half_height), Vector2(current_x + offset, center_y + half_height), Color(wave_color, 0.38), 2.0, true)
