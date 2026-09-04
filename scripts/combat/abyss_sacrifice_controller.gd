class_name AbyssSacrificeController
extends RefCounted

signal attack_requested(summon: AbyssSummon, target: Enemy, damage: float, column: TowerColumn, row_index: int, tower: TowerData)
signal summon_expired(summon: AbyssSummon, key: StringName)

var sacrifice_stacks: Dictionary = {}
var active_summons: Dictionary = {}
var spatial_index: EnemySpatialIndex
var summon_container: Node2D
var summon_service: SummonService
var summon_sources: Dictionary = {}

func configure(index: EnemySpatialIndex, container: Node2D, shared_summon_service: SummonService) -> void:
	spatial_index = index
	summon_container = container
	summon_service = shared_summon_service

func key_for(column: TowerColumn, row_index: int) -> StringName:
	return StringName("%d:%d" % [column.get_instance_id(), row_index])

func plan_sacrifice(current_stacks: int, required: int, active_count: int, summon_cap: int, budget_available: bool) -> Dictionary:
	var normalized_required := maxi(required, 1)
	var normalized_cap := maxi(summon_cap, 1)
	if active_count >= normalized_cap or not budget_available:
		return {
			"accepted": false,
			"rejected_full": true,
			"next_stacks": clampi(current_stacks, 0, normalized_required - 1),
			"should_spawn": false,
		}
	var next_stacks := mini(maxi(current_stacks, 0) + 1, normalized_required)
	return {
		"accepted": true,
		"rejected_full": false,
		"next_stacks": next_stacks - normalized_required if next_stacks >= normalized_required else next_stacks,
		"should_spawn": next_stacks >= normalized_required,
	}

func register_sacrifice(
	column: TowerColumn,
	row_index: int,
	death_position: Vector2,
	permission_callback: Callable = Callable()
) -> Dictionary:
	var result := _registration_result(&"invalid_column")
	if not is_instance_valid(column):
		return result
	var tower := column.get_tower_data(row_index)
	if tower == null or tower.behavior != &"slow":
		result.reason = &"unsupported_tower"
		return result
	if permission_callback.is_valid() and not bool(permission_callback.call(column, tower)):
		result.reason = &"permission_denied"
		return result
	var modifiers := column.get_branch_modifiers(tower.id)
	var required := int(modifiers.get("sacrifice_required", 0))
	if required <= 0:
		result.reason = &"inactive_branch"
		return result
	if death_position.distance_to(column.get_attack_origin(row_index)) > column.get_attack_range(row_index):
		result.reason = &"out_of_range"
		return result
	var key := key_for(column, row_index)
	var owner_id := StringName("kasuha_pillar:%s" % key)
	var active_count := int(active_summons.get(key, 0))
	var summon_cap := maxi(int(modifiers.get("summon_cap", 1)), 1)
	var budget_available := summon_service == null or summon_service.available_slots(owner_id, summon_cap, 1) > 0
	var plan := plan_sacrifice(int(sacrifice_stacks.get(key, 0)), required, active_count, summon_cap, budget_available)
	result.key = key
	result.rejected_full = bool(plan.rejected_full)
	if not bool(plan.accepted):
		result.reason = &"capacity_full"
		result.metric_events = [&"abyss_sacrifice_rejected_full"]
		return result
	var budget_token := 0
	if bool(plan.should_spawn) and summon_service != null:
		var tokens := summon_service.request_slots(owner_id, 1, summon_cap, 0, 0, 1, tower.id)
		if tokens.is_empty():
			result.rejected_full = true
			result.reason = &"budget_denied"
			result.metric_events = [&"abyss_sacrifice_rejected_full"]
			return result
		budget_token = tokens[0]
	sacrifice_stacks[key] = int(plan.next_stacks)
	result.accepted = true
	result.reason = &"accumulated"
	result.metric_events = [&"abyss_sacrifice_stack"]
	if not bool(plan.should_spawn):
		return result
	active_summons[key] = active_count + 1
	result.spawned = true
	result.reason = &"spawned"
	result.metric_events = [&"abyss_sacrifice_stack", &"abyss_summon_created"]
	result.summon = _spawn_summon(column, row_index, tower, death_position, key, owner_id, budget_token, modifiers)
	return result

func _registration_result(reason: StringName) -> Dictionary:
	return {
		"accepted": false,
		"rejected_full": false,
		"spawned": false,
		"reason": reason,
		"metric_events": [],
		"key": &"",
		"summon": null,
	}

func active_total() -> int:
	var total := 0
	for count in active_summons.values():
		total += int(count)
	return total

func release_active(key: StringName) -> int:
	var remaining := maxi(int(active_summons.get(key, 1)) - 1, 0)
	if remaining > 0:
		active_summons[key] = remaining
	else:
		active_summons.erase(key)
		if int(sacrifice_stacks.get(key, 0)) <= 0:
			sacrifice_stacks.erase(key)
	return remaining

func _spawn_summon(column: TowerColumn, row_index: int, tower: TowerData, spawn_position: Vector2, key: StringName, owner_id: StringName, budget_token: int, modifiers: Dictionary) -> AbyssSummon:
	var summon := summon_service.acquire_abyss_summon(summon_container) if summon_service != null else AbyssSummon.new()
	if summon.get_parent() == null:
		summon_container.add_child(summon)
	summon.setup(
		spatial_index,
		spawn_position,
		float(modifiers.get("summon_duration", 5.0)),
		float(modifiers.get("summon_interval", 0.7)),
		float(modifiers.get("summon_damage", 28.0)),
		float(modifiers.get("summon_radius", 140.0)),
		tower.color,
		owner_id,
		tower.id,
		0,
		budget_token
	)
	summon.attack_requested.connect(_on_summon_attack.bind(column, row_index, tower))
	summon.summon_expired.connect(_on_summon_expired.bind(key))
	var column_exit_callback := Callable(summon, "force_expire")
	column.tree_exiting.connect(column_exit_callback, CONNECT_ONE_SHOT)
	summon_sources[summon.get_instance_id()] = {
		"column": column,
		"column_exit_callback": column_exit_callback,
	}
	return summon

func _on_summon_attack(summon: AbyssSummon, target: Enemy, damage: float, column: TowerColumn, row_index: int, tower: TowerData) -> void:
	attack_requested.emit(summon, target, damage, column, row_index, tower)

func _on_summon_expired(summon: AbyssSummon, key: StringName) -> void:
	release_active(key)
	_disconnect_column_expiration(summon)
	summon_expired.emit(summon, key)
	if summon_service != null:
		summon_service.recycle_abyss_summon(summon)

func _disconnect_column_expiration(summon: AbyssSummon) -> void:
	if not is_instance_valid(summon):
		return
	var source: Dictionary = summon_sources.get(summon.get_instance_id(), {})
	summon_sources.erase(summon.get_instance_id())
	var column_value: Variant = source.get("column")
	if not is_instance_valid(column_value):
		return
	var column := column_value as TowerColumn
	var callback: Callable = source.get("column_exit_callback", Callable())
	if column != null and callback.is_valid() and column.tree_exiting.is_connected(callback):
		column.tree_exiting.disconnect(callback)
