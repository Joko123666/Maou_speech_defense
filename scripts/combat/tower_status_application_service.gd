class_name TowerStatusApplicationService
extends RefCounted

var _loadout: LoadoutManager
var _metrics: RunMetrics
var _spatial_index: EnemySpatialIndex
var _effect_presenter: Callable

func configure(loadout: LoadoutManager, metrics: RunMetrics, spatial_index: EnemySpatialIndex, effect_presenter: Callable) -> void:
	_loadout = loadout
	_metrics = metrics
	_spatial_index = spatial_index
	_effect_presenter = effect_presenter

func apply(
	column: TowerColumn,
	row_index: int,
	tower: TowerData,
	target: Enemy,
	attack_damage: float,
	stage_progress: float,
	excluded_status: StringName = &""
) -> void:
	if target == null or not target.active or _loadout == null:
		return
	var poison := _loadout.get_common_status_profile_for_attack(column, tower, &"poison")
	if excluded_status != &"poison" and not poison.is_empty():
		target.apply_common_poison(float(poison.damage_per_second), float(poison.duration), int(poison.max_stacks))
		_record_application(&"poison")
		_record_sample(&"status.poison_stacks", target.get_common_ailment_stacks(&"poison"))
	var burn := _loadout.get_common_status_profile_for_attack(column, tower, &"burn")
	if excluded_status != &"burn" and not burn.is_empty() and attack_damage > 0.0:
		var source_key := StringName("%d:%d:%s" % [column.column_index, row_index, tower.id])
		var reignited := target.has_common_ailment(&"burn")
		target.apply_common_burn(source_key, attack_damage * float(burn.damage_ratio), float(burn.duration), int(burn.max_stacks), float(burn.minimum_decay_ratio), bool(burn.reset_decay_on_reapply))
		_record_application(&"burn")
		if reignited:
			_record_event(&"status.burn_reignition")
	var bleed := _loadout.get_common_status_profile_for_attack(column, tower, &"bleed")
	if excluded_status != &"bleed" and not bleed.is_empty():
		var modifiers := column.get_branch_modifiers(tower.id)
		var bleed_power := float(modifiers.get("bleed_power", 1.0))
		var stage_damage_cap := float(bleed.damage_cap) * bleed_power * lerpf(1.0, 3.0, clampf(stage_progress, 0.0, 1.0))
		target.apply_common_bleed(StatusSourceRegistry.bleed_source_id(tower, modifiers), float(bleed.health_ratio) * bleed_power, float(bleed.duration), int(bleed.max_stacks), stage_damage_cap)
		_record_application(&"bleed")
		_record_sample(&"status.bleed_sources", target.get_common_ailment_source_count(&"bleed"))
	var shock := _loadout.get_common_status_profile_for_attack(column, tower, &"shock")
	if excluded_status != &"shock" and not shock.is_empty():
		var shock_stacks := target.apply_common_shock(float(shock.duration), int(shock.max_stacks))
		_record_application(&"shock")
		var shock_damage := float(shock.damage) * shock_stacks
		var transferred := _resolve_shock_discharge(target, shock_damage, int(shock.transfers), float(shock.radius), float(shock.transfer_decay))
		_record_sample(&"status.shock_transfers", transferred)

func _resolve_shock_discharge(origin: Enemy, snapshot_damage: float, transfer_limit: int, radius: float, decay: float) -> int:
	if origin == null or snapshot_damage <= 0.0:
		return 0
	var visited: Dictionary = {origin.get_instance_id(): true}
	var current := origin
	var current_damage := snapshot_damage
	origin.take_damage(current_damage, &"common_shock", true)
	var transferred := 0
	while transferred < transfer_limit and _spatial_index != null:
		var next_target: Enemy
		for candidate in _spatial_index.query_radius(current.global_position, radius):
			if candidate == null or not candidate.active or visited.has(candidate.get_instance_id()) or not candidate.has_common_ailment(&"shock"):
				continue
			next_target = candidate
			break
		if next_target == null:
			break
		visited[next_target.get_instance_id()] = true
		current_damage *= clampf(decay, 0.0, 1.0)
		next_target.take_damage(current_damage, &"common_shock", true)
		if _effect_presenter.is_valid():
			_effect_presenter.call(current.global_position, next_target.global_position, Color("78d7ff"), 0.0, 0.14)
		current = next_target
		transferred += 1
	return transferred

func _record_application(status_id: StringName) -> void:
	if _metrics != null:
		_metrics.record_status_application(status_id)

func _record_sample(metric_id: StringName, value: float) -> void:
	if _metrics != null:
		_metrics.record_mechanic_sample(metric_id, value)

func _record_event(metric_id: StringName) -> void:
	if _metrics != null:
		_metrics.record_mechanic_event(metric_id)
