class_name SummonBudget
extends RefCounted

const DEFAULT_MAXIMUM_COST := 12

var maximum_cost: int = DEFAULT_MAXIMUM_COST
var active_cost: int = 0
var next_token: int = 1
var reservations: Dictionary = {}

func configure(cost_limit: int = DEFAULT_MAXIMUM_COST) -> void:
	maximum_cost = maxi(cost_limit, 1)
	reset()

func request(
	owner_id: StringName,
	requested: int,
	local_cap: int,
	generation_depth: int = 0,
	maximum_generation: int = 0,
	cost: int = 1,
	source_id: StringName = &""
) -> Array[int]:
	var result: Array[int] = []
	var bounded_cost := maxi(cost, 1)
	var bounded_generation := maxi(generation_depth, 0)
	var bounded_maximum_generation := maxi(maximum_generation, 0)
	if owner_id == &"" or requested <= 0 or local_cap <= 0 or bounded_generation > bounded_maximum_generation:
		return result
	var local_available := maxi(local_cap - active_count(owner_id), 0)
	var global_available := maxi(floori(float(maximum_cost - active_cost) / float(bounded_cost)), 0)
	var granted := mini(maxi(requested, 0), mini(local_available, global_available))
	for _index in granted:
		var token := next_token
		next_token += 1
		reservations[token] = {
			"owner_id": owner_id,
			"source_id": source_id,
			"generation_depth": bounded_generation,
			"cost": bounded_cost,
		}
		active_cost += bounded_cost
		result.append(token)
	return result

func release(token: int) -> bool:
	if token <= 0 or not reservations.has(token):
		return false
	var reservation: Dictionary = reservations[token]
	active_cost = maxi(active_cost - int(reservation.get("cost", 1)), 0)
	reservations.erase(token)
	return true

func release_owner(owner_id: StringName) -> int:
	var released := 0
	for token_value in reservations.keys().duplicate():
		var token := int(token_value)
		var reservation: Dictionary = reservations.get(token, {})
		if StringName(reservation.get("owner_id", &"")) == owner_id and release(token):
			released += 1
	return released

func active_count(owner_id: StringName = &"") -> int:
	if owner_id == &"":
		return reservations.size()
	var result := 0
	for reservation_value in reservations.values():
		var reservation: Dictionary = reservation_value
		if StringName(reservation.get("owner_id", &"")) == owner_id:
			result += 1
	return result

func available_slots(owner_id: StringName, local_cap: int, cost: int = 1) -> int:
	var bounded_cost := maxi(cost, 1)
	return mini(
		maxi(local_cap - active_count(owner_id), 0),
		maxi(floori(float(maximum_cost - active_cost) / float(bounded_cost)), 0)
	)

func snapshot() -> Dictionary:
	var owners: Dictionary = {}
	var sources: Dictionary = {}
	for reservation_value in reservations.values():
		var reservation: Dictionary = reservation_value
		var owner_id := StringName(reservation.get("owner_id", &""))
		var owner_key := String(owner_id)
		var owner_entry: Dictionary = owners.get(owner_key, {"active": 0, "cost": 0, "maximum_generation": 0})
		owner_entry.active = int(owner_entry.active) + 1
		owner_entry.cost = int(owner_entry.cost) + int(reservation.get("cost", 1))
		owner_entry.maximum_generation = maxi(int(owner_entry.maximum_generation), int(reservation.get("generation_depth", 0)))
		owners[owner_key] = owner_entry
		var source_key := String(StringName(reservation.get("source_id", &"")))
		if not source_key.is_empty():
			sources[source_key] = int(sources.get(source_key, 0)) + 1
	return {
		"active": reservations.size(),
		"active_cost": active_cost,
		"maximum_cost": maximum_cost,
		"available_cost": maxi(maximum_cost - active_cost, 0),
		"owners": owners,
		"sources": sources,
	}

func reset() -> void:
	reservations.clear()
	active_cost = 0
	next_token = 1
