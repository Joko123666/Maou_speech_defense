class_name EnemyDamageContext
extends RefCounted

const SOURCE_UNKNOWN := &"unknown"
const SOURCE_NORMAL_DEFENDER := &"normal_defender"
const SOURCE_CANDIDATE := &"candidate"
const SOURCE_RETAINER := &"retainer"
const SOURCE_GUARD := &"guard"
const SOURCE_STATUS := &"status"
const SOURCE_SUMMON := &"summon"

var source_kind: StringName = SOURCE_UNKNOWN
var source_id: StringName = &""
var source_column_instance_id: int = 0
var source_row: int = -1

static func normal_defender(column: TowerColumn, row_index: int, tower_id: StringName) -> EnemyDamageContext:
	var context := EnemyDamageContext.new()
	context.source_kind = SOURCE_NORMAL_DEFENDER
	context.source_id = tower_id
	context.source_column_instance_id = column.get_instance_id() if is_instance_valid(column) else 0
	context.source_row = row_index
	return context

func resolve_normal_defender_column(columns: Array[TowerColumn]) -> TowerColumn:
	if source_kind != SOURCE_NORMAL_DEFENDER or source_column_instance_id <= 0 or source_row < 0:
		return null
	for column in columns:
		if is_instance_valid(column) and column.get_instance_id() == source_column_instance_id:
			return column
	return null

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if source_kind not in [SOURCE_UNKNOWN, SOURCE_NORMAL_DEFENDER, SOURCE_CANDIDATE, SOURCE_RETAINER, SOURCE_GUARD, SOURCE_STATUS, SOURCE_SUMMON]:
		errors.append("enemy damage context has unsupported source kind '%s'" % source_kind)
	if source_kind == SOURCE_NORMAL_DEFENDER and (source_id == &"" or source_column_instance_id <= 0 or source_row < 0):
		errors.append("normal defender damage context requires a tower, column, and row")
	return errors
