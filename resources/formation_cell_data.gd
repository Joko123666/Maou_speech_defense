class_name FormationCellData
extends Resource

@export var offset: Vector2i = Vector2i.ZERO
@export var tower_id: StringName = &""

func configure(cell_offset: Vector2i, cell_tower_id: StringName) -> FormationCellData:
	offset = cell_offset
	tower_id = cell_tower_id
	return self

