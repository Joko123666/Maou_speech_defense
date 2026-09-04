class_name SummonService
extends Node

const TOTAL_BUDGET_COST := 12
const ABYSS_POOL_LIMIT := 12

var budget := SummonBudget.new()
var pooled_abyss_summons: Array[AbyssSummon] = []

func _init() -> void:
	budget.configure(TOTAL_BUDGET_COST)

func request_slots(
	owner_id: StringName,
	requested: int,
	local_cap: int,
	generation_depth: int = 0,
	maximum_generation: int = 0,
	cost: int = 1,
	source_id: StringName = &""
) -> Array[int]:
	return budget.request(owner_id, requested, local_cap, generation_depth, maximum_generation, cost, source_id)

func release_slot(token: int) -> bool:
	return budget.release(token)

func release_owner(owner_id: StringName) -> int:
	return budget.release_owner(owner_id)

func available_slots(owner_id: StringName, local_cap: int, cost: int = 1) -> int:
	return budget.available_slots(owner_id, local_cap, cost)

func active_count(owner_id: StringName = &"") -> int:
	return budget.active_count(owner_id)

func budget_snapshot() -> Dictionary:
	return budget.snapshot()

func acquire_abyss_summon(container: Node2D) -> AbyssSummon:
	_prune_pool()
	var summon: AbyssSummon
	if pooled_abyss_summons.is_empty():
		summon = AbyssSummon.new()
		container.add_child(summon)
	else:
		summon = pooled_abyss_summons.pop_back()
		if summon.get_parent() != container:
			summon.reparent(container)
	summon.reset_for_reuse()
	summon.managed_by_pool = true
	return summon

func recycle_abyss_summon(summon: AbyssSummon) -> void:
	if not is_instance_valid(summon):
		return
	if summon.summon_budget_token > 0:
		release_slot(summon.summon_budget_token)
		summon.summon_budget_token = 0
	call_deferred("_store_recycled_abyss_summon", summon)

func reset_budget() -> void:
	budget.reset()

func _store_recycled_abyss_summon(summon: AbyssSummon) -> void:
	if not is_instance_valid(summon):
		return
	summon.prepare_for_pool()
	_prune_pool()
	if pooled_abyss_summons.size() >= ABYSS_POOL_LIMIT:
		summon.queue_free()
		return
	if summon.get_parent() != self:
		summon.reparent(self)
	pooled_abyss_summons.append(summon)

func _prune_pool() -> void:
	for index in range(pooled_abyss_summons.size() - 1, -1, -1):
		if not is_instance_valid(pooled_abyss_summons[index]):
			pooled_abyss_summons.remove_at(index)
