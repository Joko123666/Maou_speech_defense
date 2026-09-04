class_name RetainerReactivationRegistry
extends RefCounted

var components: Dictionary = {}

func key_for(column: TowerColumn, row_index: int) -> String:
	return "%d:%d" % [column.get_instance_id(), row_index]

func get_or_create(
	column: TowerColumn,
	row_index: int,
	tower: TowerData,
	effect_container: Node2D,
	modifiers: Dictionary,
	callbacks: Dictionary = {}
) -> RetainerReactivationComponent:
	if column == null or tower == null or tower.reactivation_profile == null or effect_container == null:
		return null
	var key := key_for(column, row_index)
	var existing_value: Variant = components.get(key)
	var existing: RetainerReactivationComponent
	if is_instance_valid(existing_value):
		existing = existing_value as RetainerReactivationComponent
	var can_reuse := (
		existing != null
		and is_instance_valid(existing)
		and not existing.is_queued_for_deletion()
		and existing.source_column == column
		and existing.row_index == row_index
		and existing.profile == tower.reactivation_profile
	)
	if can_reuse:
		existing.apply_modifiers(modifiers)
		return existing
	if existing != null and is_instance_valid(existing) and not existing.is_queued_for_deletion():
		var removed_callback: Callable = callbacks.get(&"removed", Callable())
		if removed_callback.is_valid():
			removed_callback.call(existing.source_column, existing.row_index)
		existing.queue_free()
	components.erase(key)
	var component := RetainerReactivationComponent.new()
	effect_container.add_child(component)
	component.setup(column, row_index, tower.reactivation_profile, tower.color, modifiers)
	_connect_bound(component.deactivated, callbacks.get(&"deactivated", Callable()), column, row_index, tower)
	_connect_bound(component.reactivated, callbacks.get(&"reactivated", Callable()), column, row_index, tower)
	components[key] = component
	return component

func synchronize(
	columns: Array[TowerColumn],
	effect_container: Node2D,
	modifier_provider: Callable,
	callbacks: Dictionary = {},
	removed_callback: Callable = Callable()
) -> Dictionary:
	var valid_keys: Dictionary = {}
	var created_count := 0
	for column in columns:
		if column == null or not is_instance_valid(column):
			continue
		for row_index in column.row_towers.size():
			var tower := column.get_tower_data(row_index)
			if tower == null or tower.reactivation_profile == null:
				continue
			var key := key_for(column, row_index)
			valid_keys[key] = true
			var previous_value: Variant = components.get(key)
			var previous: RetainerReactivationComponent
			if is_instance_valid(previous_value):
				previous = previous_value as RetainerReactivationComponent
			var existed := previous != null and is_instance_valid(previous) and not previous.is_queued_for_deletion()
			var modifiers: Dictionary = {}
			if modifier_provider.is_valid():
				modifiers = modifier_provider.call(column)
			if get_or_create(column, row_index, tower, effect_container, modifiers, callbacks) != null and not existed:
				created_count += 1
	var removed_count := 0
	for key in components.keys():
		if valid_keys.has(key):
			continue
		var stale_value: Variant = components.get(key)
		if not is_instance_valid(stale_value):
			components.erase(key)
			removed_count += 1
			continue
		var stale := stale_value as RetainerReactivationComponent
		if stale != null:
			if removed_callback.is_valid():
				removed_callback.call(stale.source_column, stale.row_index)
			stale.queue_free()
		components.erase(key)
		removed_count += 1
	return {
		"active": component_count(),
		"created": created_count,
		"removed": removed_count,
	}

func component_count() -> int:
	_prune_invalid_entries()
	return components.size()

func inactive_count() -> int:
	_prune_invalid_entries()
	var result := 0
	for value in components.values():
		if not is_instance_valid(value):
			continue
		var component := value as RetainerReactivationComponent
		if component != null and not component.can_attack():
			result += 1
	return result

func _connect_bound(signal_value: Signal, callback: Callable, column: TowerColumn, row_index: int, tower: TowerData) -> void:
	if not callback.is_valid():
		return
	var bound_callback := callback.bind(column, row_index, tower)
	if not signal_value.is_connected(bound_callback):
		signal_value.connect(bound_callback)

func _prune_invalid_entries() -> void:
	for key in components.keys():
		var component_value: Variant = components.get(key)
		if not is_instance_valid(component_value):
			components.erase(key)
			continue
		var component := component_value as RetainerReactivationComponent
		if component == null or component.is_queued_for_deletion():
			components.erase(key)
