class_name CandidateCharmEchoService
extends RefCounted

const MAXIMUM_SPREAD_TARGETS := 3
const MINIMUM_SOURCE_DISTANCE := 1.0

func execute(
		death_position: Vector2,
		defeated_enemy_data: EnemyData,
		core_data: CoreData,
		candidate_modifier_callback: Callable,
		radius_query_callback: Callable
	) -> Dictionary:
	var result := {
		"eligible": false,
		"spread_count": 0,
		"radius": 0.0,
		"duration_multiplier": 0.0,
		"vulnerability": 0.0,
		"targets": [] as Array[Enemy],
	}
	if defeated_enemy_data == null or defeated_enemy_data.is_boss or not candidate_modifier_callback.is_valid() or not radius_query_callback.is_valid():
		return result
	if not bool(candidate_modifier_callback.call(&"charm_echo", false)):
		return result
	var charm_profile := core_data.charm_profile if core_data != null else null
	if charm_profile == null:
		return result
	result.eligible = true
	result.radius = float(candidate_modifier_callback.call(&"charm_echo_radius", 140.0))
	result.duration_multiplier = float(candidate_modifier_callback.call(&"charm_echo_duration", 0.55))
	result.vulnerability = float(candidate_modifier_callback.call(&"charm_vulnerability", 0.0)) * 0.5
	var queried_targets: Array = radius_query_callback.call(death_position, float(result.radius))
	for value in queried_targets:
		var nearby := value as Enemy
		if not is_instance_valid(nearby) or not nearby.active or nearby.data == null or nearby.data.is_boss or nearby.global_position.distance_to(death_position) < MINIMUM_SOURCE_DISTANCE:
			continue
		if not nearby.apply_charm(charm_profile, float(result.duration_multiplier), float(result.vulnerability)):
			continue
		(result.targets as Array[Enemy]).append(nearby)
		result.spread_count = int(result.spread_count) + 1
		if int(result.spread_count) >= MAXIMUM_SPREAD_TARGETS:
			break
	return result
