class_name Battlefield
extends Node2D

const LANE_COUNT := 4
const COLUMN_COUNT := 6

# GDD와 전투/UI 계약은 4행 6열을 기준으로 한다. 가변 보드가 필요해지면
# 스포너, 편대 런타임 배열, 설치 UI를 함께 동적으로 전환해야 한다.
var lane_count: int = LANE_COUNT
var column_count: int = COLUMN_COUNT
@export var horizontal_margin: Vector2 = Vector2(150.0, 70.0)
@export var vertical_margin: Vector2 = Vector2(105.0, 75.0)

var warning_spawn_ratio: float = -1.0

func set_spawn_warning(spawn_y_ratio: float) -> void:
	warning_spawn_ratio = spawn_y_ratio if spawn_y_ratio >= 0.0 else -1.0
	queue_redraw()

func set_warning_lane(lane_index: int) -> void:
	set_spawn_warning((float(lane_index) + 0.5) / float(lane_count) if lane_index >= 0 else -1.0)

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	queue_redraw()

func get_battle_rect() -> Rect2:
	var viewport_size := get_viewport_rect().size
	var size := Vector2(
		maxf(viewport_size.x - horizontal_margin.x - horizontal_margin.y, 100.0),
		maxf(viewport_size.y - vertical_margin.x - vertical_margin.y, 100.0)
	)
	return Rect2(Vector2(horizontal_margin.x, vertical_margin.x), size)

func get_lane_y(lane_index: int) -> float:
	var rect := get_battle_rect()
	var safe_index := clampi(lane_index, 0, lane_count - 1)
	return rect.position.y + rect.size.y * (float(safe_index) + 0.5) / float(lane_count)

func get_column_x(column_index: int) -> float:
	var rect := get_battle_rect()
	var safe_index := clampi(column_index, 0, column_count - 1)
	return rect.position.x + rect.size.x * (float(safe_index) + 1.0) / float(column_count + 1)

func get_column_spacing() -> float:
	return get_battle_rect().size.x / float(column_count + 1)

func get_lane_spacing() -> float:
	return get_battle_rect().size.y / float(lane_count)

func world_to_lane(world_position: Vector2) -> int:
	var rect := get_battle_rect()
	var normalized_y := (world_position.y - rect.position.y) / rect.size.y
	return clampi(floori(normalized_y * lane_count), 0, lane_count - 1)

func clamp_to_battlefield(world_position: Vector2) -> Vector2:
	var rect := get_battle_rect()
	return Vector2(
		clampf(world_position.x, rect.position.x, rect.end.x),
		clampf(world_position.y, rect.position.y, rect.end.y)
	)

func get_core_position() -> Vector2:
	var rect := get_battle_rect()
	return Vector2(rect.position.x - 55.0, rect.get_center().y)

func get_core_goal_position(world_y: float) -> Vector2:
	var rect := get_battle_rect()
	return Vector2(rect.position.x, clampf(world_y, rect.position.y, rect.end.y))

func get_free_spawn_position(y_ratio: float, outside_offset: float = 30.0) -> Vector2:
	var rect := get_battle_rect()
	var safe_ratio := clampf(y_ratio, 0.05, 0.95)
	return Vector2(rect.end.x + maxf(outside_offset, 0.0), rect.position.y + rect.size.y * safe_ratio)

func get_spawn_position(lane_index: int) -> Vector2:
	var rect := get_battle_rect()
	return Vector2(rect.end.x + 30.0, get_lane_y(lane_index))

func _draw() -> void:
	var rect := get_battle_rect()
	var concept := ConceptService.active
	var background := ConceptService.texture(&"battlefield_background") if concept != null else null
	if background != null:
		draw_texture_rect(background, Rect2(Vector2.ZERO, get_viewport_rect().size), false, concept.background_tint)
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), concept.background_overlay if concept != null else Color(0.01, 0.035, 0.055, 0.28), true)

	draw_rect(rect, concept.battlefield_fill if concept != null else Color("172a3a", 0.32), true)
	if warning_spawn_ratio >= 0.0:
		var warning_y := rect.position.y + rect.size.y * warning_spawn_ratio
		var warning_height := minf(72.0, rect.size.y * 0.12)
		var danger := concept.danger_color if concept != null else Color("ff765f")
		draw_rect(Rect2(Vector2(rect.position.x, warning_y - warning_height * 0.5), Vector2(rect.size.x, warning_height)), Color(danger, 0.16), true)
		draw_line(Vector2(rect.position.x, warning_y), Vector2(rect.end.x + 24.0, warning_y), Color(danger, 0.82), 2.0, true)
		for chevron_index in 3:
			var chevron_x := rect.end.x + 8.0 + chevron_index * 9.0
			draw_polyline(PackedVector2Array([Vector2(chevron_x, warning_y - 8.0), Vector2(chevron_x - 6.0, warning_y), Vector2(chevron_x, warning_y + 8.0)]), Color("ff9a73", 0.9 - chevron_index * 0.2), 2.0, true)

	# 행 전체를 칠하지 않고 실제로 고정되는 타워 설치 지점만 표시한다.
	for column_index in column_count:
		var column_x := get_column_x(column_index)
		for row_index in lane_count:
			var socket_position := Vector2(column_x, get_lane_y(row_index))
			draw_circle(socket_position, 4.0, Color(0.34, 0.53, 0.64, 0.22))
			draw_arc(socket_position, 11.0, 0.0, TAU, 16, Color(0.34, 0.53, 0.64, 0.1), 1.0, true)

	draw_line(
		Vector2(rect.position.x, rect.position.y),
		Vector2(rect.position.x, rect.end.y),
		concept.accent_color if concept != null else Color("53d5a5"),
		4.0
	)

func _on_viewport_size_changed() -> void:
	queue_redraw()
