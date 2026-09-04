class_name DefenseStatCatalogData
extends Resource

const REQUIRED_AXIS_IDS: Array[StringName] = [&"power", &"speed", &"range"]
const REQUIRED_TOWER_IDS: Array[StringName] = [&"rapid", &"pierce", &"execute", &"slow", &"area", &"knockback", &"chain", &"rubber_golem", &"mark"]

@export var axes: Array[DefenseStatAxisData] = []
@export var mappings: Array[DefenseStatMappingData] = []

func find_axis(axis_id: StringName) -> DefenseStatAxisData:
	for axis in axes:
		if axis != null and axis.id == axis_id:
			return axis
	return null

func find_mapping(tower_id: StringName, axis_id: StringName) -> DefenseStatMappingData:
	for mapping in mappings:
		if mapping != null and mapping.tower_id == tower_id and mapping.axis_id == axis_id:
			return mapping
	return null

func get_tower_mappings(tower_id: StringName) -> Array[DefenseStatMappingData]:
	var result: Array[DefenseStatMappingData] = []
	for axis_id in REQUIRED_AXIS_IDS:
		var mapping := find_mapping(tower_id, axis_id)
		if mapping != null:
			result.append(mapping)
	return result

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var axis_ids: Dictionary = {}
	for axis in axes:
		if axis == null:
			errors.append("defense stat catalog contains a null axis")
			continue
		if axis_ids.has(axis.id): errors.append("duplicate defense stat axis '%s'" % axis.id)
		axis_ids[axis.id] = true
		errors.append_array(axis.get_validation_errors())
	for required_axis_id in REQUIRED_AXIS_IDS:
		if not axis_ids.has(required_axis_id): errors.append("missing defense stat axis '%s'" % required_axis_id)
	var mapping_keys: Dictionary = {}
	for mapping in mappings:
		if mapping == null:
			errors.append("defense stat catalog contains a null mapping")
			continue
		var key := "%s:%s" % [mapping.tower_id, mapping.axis_id]
		if mapping_keys.has(key): errors.append("duplicate defense stat mapping '%s'" % key)
		mapping_keys[key] = true
		errors.append_array(mapping.get_validation_errors())
	for tower_id in REQUIRED_TOWER_IDS:
		for axis_id in REQUIRED_AXIS_IDS:
			if not mapping_keys.has("%s:%s" % [tower_id, axis_id]):
				errors.append("missing defense stat mapping '%s:%s'" % [tower_id, axis_id])
	return errors
