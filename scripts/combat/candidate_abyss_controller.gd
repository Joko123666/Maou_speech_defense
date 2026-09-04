class_name CandidateAbyssController
extends Node

signal attack_requested(summon: AbyssSummon, target: Enemy, damage: float)
signal summon_expired(summon: AbyssSummon)

var spatial_index: EnemySpatialIndex
var summon_container: Node2D
var battlefield: Battlefield
var summon_service: SummonService
var active_summons: Array[AbyssSummon] = []

func setup(index: EnemySpatialIndex, container: Node2D, target_battlefield: Battlefield, shared_summon_service: SummonService = null) -> void:
	spatial_index = index
	summon_container = container
	battlefield = target_battlefield
	summon_service = shared_summon_service

func active_count() -> int:
	_prune_invalid_summons()
	return active_summons.size()

static func bounded_spawn_count(requested: int, summon_cap: int, current_active: int) -> int:
	return mini(maxi(requested, 0), maxi(maxi(summon_cap, 1) - maxi(current_active, 0), 0))

func spawn_swarm(
	requested: int,
	summon_cap: int,
	duration: float,
	interval: float,
	damage: float,
	search_radius: float,
	color: Color,
	targets: Array[Enemy]
) -> int:
	_prune_invalid_summons()
	if spatial_index == null or summon_container == null or battlefield == null:
		return 0
	var budget_tokens: Array[int] = []
	if summon_service != null:
		budget_tokens = summon_service.request_slots(&"kasuha_candidate", requested, summon_cap, 0, 0, 1, &"candidate_mass_summoning")
	else:
		budget_tokens.resize(bounded_spawn_count(requested, summon_cap, active_summons.size()))
		budget_tokens.fill(0)
	var spawn_count := budget_tokens.size()
	if spawn_count <= 0:
		return 0
	var battle_rect := battlefield.get_battle_rect()
	for summon_index in spawn_count:
		var spawn_position := _spawn_position(summon_index, spawn_count, targets, battle_rect)
		var summon := summon_service.acquire_abyss_summon(summon_container) if summon_service != null else AbyssSummon.new()
		if summon.get_parent() == null:
			summon_container.add_child(summon)
		summon.setup(spatial_index, spawn_position, duration, interval, damage, search_radius, color, &"kasuha_candidate", &"candidate_mass_summoning", 0, budget_tokens[summon_index])
		summon.attack_requested.connect(_on_summon_attack_requested)
		summon.summon_expired.connect(_on_summon_expired)
		active_summons.append(summon)
	return spawn_count

func expire_all() -> void:
	for summon in active_summons.duplicate():
		if is_instance_valid(summon):
			summon.force_expire()
	active_summons.clear()

func _exit_tree() -> void:
	expire_all()

func _spawn_position(summon_index: int, spawn_count: int, targets: Array[Enemy], battle_rect: Rect2) -> Vector2:
	if not targets.is_empty():
		var target := targets[summon_index % targets.size()]
		var angle := TAU * float(summon_index) / maxf(spawn_count, 1)
		return battlefield.clamp_to_battlefield(target.global_position + Vector2.from_angle(angle) * (34.0 + (summon_index % 3) * 12.0))
	var x_ratio := float((summon_index % 4) + 1) / 5.0
	var y_ratio := float(floori(float(summon_index) / 4.0) + 1) / 3.0
	return battlefield.clamp_to_battlefield(battle_rect.position + Vector2(battle_rect.size.x * x_ratio, battle_rect.size.y * y_ratio))

func _prune_invalid_summons() -> void:
	for summon_index in range(active_summons.size() - 1, -1, -1):
		var summon := active_summons[summon_index]
		if not is_instance_valid(summon) or summon.expiring:
			active_summons.remove_at(summon_index)

func _on_summon_attack_requested(summon: AbyssSummon, target: Enemy, damage: float) -> void:
	attack_requested.emit(summon, target, damage)

func _on_summon_expired(summon: AbyssSummon) -> void:
	active_summons.erase(summon)
	summon_expired.emit(summon)
	if summon_service != null:
		summon_service.recycle_abyss_summon(summon)
