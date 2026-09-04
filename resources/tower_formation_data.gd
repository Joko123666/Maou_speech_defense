class_name TowerFormationData
extends Resource

const SHAPE_LONG: StringName = &"LONG"
const SHAPE_BEND: StringName = &"BEND"
const SHAPE_COMPACT: StringName = &"COMPACT"
const SHAPE_STEP: StringName = &"STEP"
const VALID_SHAPE_CLASSES: Array[StringName] = [SHAPE_LONG, SHAPE_BEND, SHAPE_COMPACT, SHAPE_STEP]

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var cells: Array[FormationCellData] = []
@export var role_tags: Array[StringName] = []
@export var shape_class: StringName = &""
@export_range(0, 2, 1) var placement_difficulty: int = 0
@export var rarity: int = 1
@export var base_weight: float = 1.0
@export var can_vertical_flip: bool = true
@export var formation_score: int = 0
@export var is_guard: bool = false
@export var candidate_id: StringName
@export var raw_power_score: float = 0.0
@export var output_multiplier: float = 1.0
@export var expected_power_score: float = 0.0
@export var unique_core_id: StringName

func configure_cells(
	formation_id: StringName,
	title: String,
	detail: String,
	formation_cells: Array[FormationCellData],
	tags: Array[StringName] = [],
	formation_rarity: int = 1,
	formation_shape_class: StringName = &"",
	formation_placement_difficulty: int = -1
) -> TowerFormationData:
	id = formation_id
	display_name = title
	description = detail
	cells.assign(formation_cells)
	role_tags.assign(tags)
	rarity = formation_rarity
	shape_class = formation_shape_class if formation_shape_class != &"" else infer_shape_class()
	placement_difficulty = formation_placement_difficulty if formation_placement_difficulty >= 0 else default_placement_difficulty(shape_class, cells.size())
	return self

func get_tower_count() -> int:
	return cells.size()

func get_tower_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for formation_cell in cells:
		if formation_cell != null:
			result.append(formation_cell.tower_id)
	return result

func get_distinct_tower_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for tower_id in get_tower_ids():
		if tower_id not in result:
			result.append(tower_id)
	return result

func get_distinct_tower_count() -> int:
	return get_distinct_tower_ids().size()

func get_shape_display_name() -> String:
	return shape_display_name(shape_class)

func get_placement_difficulty_display_name() -> String:
	return placement_difficulty_display_name(placement_difficulty)

func get_bounds() -> Rect2i:
	if cells.is_empty():
		return Rect2i()
	var minimum := cells[0].offset
	var maximum := cells[0].offset
	for formation_cell in cells:
		if formation_cell == null:
			continue
		minimum.x = mini(minimum.x, formation_cell.offset.x)
		minimum.y = mini(minimum.y, formation_cell.offset.y)
		maximum.x = maxi(maximum.x, formation_cell.offset.x)
		maximum.y = maxi(maximum.y, formation_cell.offset.y)
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)

func get_shape_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var maximum_cells := 6 if is_guard else 4
	if cells.size() < 2 or cells.size() > maximum_cells:
		errors.append("formation '%s' must contain 2 to %d cells" % [id, maximum_cells])
	var occupied: Dictionary = {}
	for formation_cell in cells:
		if formation_cell == null:
			errors.append("formation '%s' contains a null cell" % id)
			continue
		if formation_cell.tower_id == &"":
			errors.append("formation '%s' contains an empty tower id" % id)
		if formation_cell.offset.x < 0 or formation_cell.offset.y < 0:
			errors.append("formation '%s' contains a negative cell offset" % id)
		if occupied.has(formation_cell.offset):
			errors.append("formation '%s' contains duplicate cell coordinates" % id)
		occupied[formation_cell.offset] = true
	if not occupied.is_empty():
		var bounds := get_bounds()
		if bounds.position != Vector2i.ZERO:
			errors.append("formation '%s' cell offsets must be normalized" % id)
		var visited: Dictionary = {}
		var initial_cell: Vector2i = occupied.keys()[0] as Vector2i
		var frontier: Array[Vector2i] = [initial_cell]
		while not frontier.is_empty():
			var current: Vector2i = frontier.pop_back()
			if visited.has(current):
				continue
			visited[current] = true
			var directions: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
			for direction: Vector2i in directions:
				var neighbor: Vector2i = current + direction
				if occupied.has(neighbor) and not visited.has(neighbor):
					frontier.append(neighbor)
		if visited.size() != occupied.size() and not is_guard:
			errors.append("formation '%s' cells must be orthogonally connected" % id)
	if not is_guard:
		if shape_class not in VALID_SHAPE_CLASSES:
			errors.append("formation '%s' has invalid shape class '%s'" % [id, shape_class])
		elif not matches_shape_class(shape_class):
			errors.append("formation '%s' coordinates do not match shape class '%s'" % [id, shape_class])
		if placement_difficulty < 0 or placement_difficulty > 2:
			errors.append("formation '%s' placement difficulty must be 0 to 2" % id)
		var distinct_tower_count := get_distinct_tower_count()
		if cells.size() == 2 and (distinct_tower_count < 1 or distinct_tower_count > 2):
			errors.append("formation '%s' two-cell recipe must use one or two tower types" % id)
		elif cells.size() in [3, 4] and (distinct_tower_count < 1 or distinct_tower_count > 3):
			errors.append("formation '%s' three/four-cell recipe must use one to three tower types" % id)
	return errors

func infer_shape_class() -> StringName:
	if cells.is_empty():
		return &""
	var bounds := get_bounds()
	if bounds.size.x == 1 or bounds.size.y == 1:
		return SHAPE_LONG
	if cells.size() == 4 and bounds.size == Vector2i(2, 2):
		return SHAPE_COMPACT
	if _is_step_shape():
		return SHAPE_STEP
	return SHAPE_BEND

func matches_shape_class(expected_shape: StringName) -> bool:
	match expected_shape:
		SHAPE_LONG:
			var bounds := get_bounds()
			return (bounds.size.x == 1 or bounds.size.y == 1) and bounds.size.x * bounds.size.y == cells.size()
		SHAPE_COMPACT:
			return cells.size() == 4 and get_bounds().size == Vector2i(2, 2)
		SHAPE_STEP:
			return _is_step_shape()
		SHAPE_BEND:
			if cells.size() == 3:
				return get_bounds().size == Vector2i(2, 2)
			return cells.size() == 4 and not matches_shape_class(SHAPE_LONG) and not matches_shape_class(SHAPE_COMPACT) and not matches_shape_class(SHAPE_STEP)
	return false

static func default_placement_difficulty(formation_shape_class: StringName, cell_count: int) -> int:
	if formation_shape_class == SHAPE_STEP or (formation_shape_class == SHAPE_LONG and cell_count >= 4):
		return 2
	if formation_shape_class == SHAPE_BEND or (formation_shape_class == SHAPE_LONG and cell_count >= 3):
		return 1
	return 0

static func shape_display_name(formation_shape_class: StringName) -> String:
	return {
		SHAPE_LONG: "장축",
		SHAPE_BEND: "꺾임",
		SHAPE_COMPACT: "밀집",
		SHAPE_STEP: "계단",
	}.get(formation_shape_class, "미지정")

static func placement_difficulty_display_name(difficulty: int) -> String:
	return {
		0: "쉬움",
		1: "보통",
		2: "까다로움",
	}.get(difficulty, "미지정")

func _is_step_shape() -> bool:
	if cells.size() != 4 or get_bounds().size not in [Vector2i(3, 2), Vector2i(2, 3)]:
		return false
	var occupied: Dictionary = {}
	for formation_cell in cells:
		if formation_cell != null:
			occupied[formation_cell.offset] = true
	var horizontal_shapes: Array[Array] = [
		[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)],
		[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)],
	]
	var vertical_shapes: Array[Array] = [
		[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],
		[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)],
	]
	for signature in horizontal_shapes + vertical_shapes:
		if signature.all(func(offset: Vector2i) -> bool: return occupied.has(offset)):
			return true
	return false

func configure_balance(raw_score: float, target_score: float, normalization_multiplier: float = 1.0) -> TowerFormationData:
	raw_power_score = raw_score
	formation_score = roundi(raw_score)
	var effective_normalization := maxf(normalization_multiplier, 0.01)
	output_multiplier = target_score / maxf(raw_power_score * effective_normalization, 1.0)
	expected_power_score = raw_power_score * effective_normalization * output_multiplier
	return self

func get_normalized_power(target_score: float) -> int:
	return roundi(expected_power_score / maxf(target_score, 1.0) * 100.0)

func is_unique() -> bool:
	return unique_core_id != &""
