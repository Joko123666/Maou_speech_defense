class_name SummonServiceContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var service := SummonService.new()
	var candidate_tokens := service.request_slots(&"kasuha_candidate", 8, 8, 0, 0, 1, &"candidate_mass_summoning")
	var pillar_tokens := service.request_slots(&"kasuha_pillar:test", 6, 4, 0, 0, 1)
	_expect(candidate_tokens.size() == 8 and pillar_tokens.size() == 4 and service.active_count() == 12, "candidate and pillar summons must share the twelve-cost global budget while preserving their local caps", failures)
	_expect(service.request_slots(&"irelai_spirit", 1, 6, 0, 3, 1).is_empty(), "a full summon budget must reject immediately without creating a hidden request queue", failures)

	_expect(service.release_slot(candidate_tokens[0]), "releasing a summon must return its exact budget token", failures)
	var curse_tokens := service.request_slots(&"irelai_spirit", 1, 6, 2, 3, 1)
	var rejected_generation := service.request_slots(&"irelai_spirit", 1, 6, 4, 3, 1)
	_expect(curse_tokens.size() == 1 and rejected_generation.is_empty(), "death-curse summons must retain allowed generation metadata and reject generation four", failures)
	var full_snapshot := service.budget_snapshot()
	var owner_snapshot: Dictionary = (full_snapshot.get("owners", {}) as Dictionary).get("irelai_spirit", {})
	var source_snapshot: Dictionary = full_snapshot.get("sources", {})
	_expect(int(full_snapshot.get("active_cost", 0)) == 12 and int(owner_snapshot.get("maximum_generation", 0)) == 2 and int(source_snapshot.get("candidate_mass_summoning", 0)) == 7, "summon snapshots must expose total budget cost, original source, and the owning lineage", failures)

	service.release_owner(&"kasuha_candidate")
	var wave_tokens := service.request_slots(&"irelai_death_wave", 1, 1, 0, 0, 2)
	_expect(wave_tokens.size() == 1 and service.active_count(&"irelai_death_wave") == 1, "the death wave must reserve one bounded owner slot with its two-cost budget weight", failures)
	service.reset_budget()
	_expect(service.active_count() == 0 and int(service.budget_snapshot().get("active_cost", -1)) == 0, "run cleanup must return every summon reservation in one reset boundary", failures)

	var pool_container := Node2D.new()
	service.add_child(pool_container)
	var first_summon := service.acquire_abyss_summon(pool_container)
	var first_instance_id := first_summon.get_instance_id()
	first_summon.prepare_for_pool()
	first_summon.reparent(service)
	service.pooled_abyss_summons.append(first_summon)
	var reused_summon := service.acquire_abyss_summon(pool_container)
	_expect(reused_summon.get_instance_id() == first_instance_id and service.pooled_abyss_summons.is_empty(), "the bounded abyss pool must reuse an expired node instead of allocating a new combat object", failures)
	service.free()
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
