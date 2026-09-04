class_name SpawnPacketComposer
extends RefCounted

func compose(
	packets: Array[SpawnPacketData],
	candidates: Array[Dictionary],
	phase_index: int,
	budget: float
) -> Dictionary:
	if budget <= 0.0 or candidates.is_empty():
		return {}
	var remaining: Array[SpawnPacketData] = []
	for packet in packets:
		if packet != null and packet.is_allowed_phase(phase_index) and packet.min_cost <= budget + 0.0001:
			remaining.append(packet)
	while not remaining.is_empty():
		var packet_index := _weighted_packet_index(remaining)
		var packet := remaining[packet_index]
		var plan := _build_plan(packet, candidates, budget)
		if not plan.is_empty():
			return plan
		remaining.remove_at(packet_index)
	return {}

func has_phase_packet(packets: Array[SpawnPacketData], phase_index: int) -> bool:
	return packets.any(func(packet: SpawnPacketData) -> bool:
		return packet != null and packet.is_allowed_phase(phase_index)
	)

func minimum_budget_for_phase(packets: Array[SpawnPacketData], phase_index: int) -> float:
	var minimum := INF
	for packet in packets:
		if packet != null and packet.is_allowed_phase(phase_index):
			minimum = minf(minimum, packet.min_cost)
	return minimum if is_finite(minimum) else 0.0

func _build_plan(packet: SpawnPacketData, candidates: Array[Dictionary], budget: float) -> Dictionary:
	var spending_limit := minf(budget, packet.max_cost)
	return _fill_slots(packet, candidates, 0, spending_limit, 0.0, 0, {}, [])

func _fill_slots(
	packet: SpawnPacketData,
	candidates: Array[Dictionary],
	slot_index: int,
	spending_limit: float,
	total_cost: float,
	total_count: int,
	role_counts: Dictionary,
	entries: Array[Dictionary]
) -> Dictionary:
	if slot_index >= packet.slots.size():
		if total_count <= 0 or total_cost + 0.0001 < packet.min_cost:
			return {}
		return {
			"packet_id": packet.id,
			"entries": entries,
			"cost": total_cost,
			"count": total_count,
			"role_counts": role_counts,
		}
	var slot := packet.slots[slot_index]
	var required_tag := StringName(slot.get("tag", &""))
	var count := int(slot.get("count", 1))
	var matching: Array[Dictionary] = []
	for candidate in candidates:
		var enemy := candidate.get("enemy") as EnemyData
		if enemy == null or not enemy.role_tags.has(required_tag):
			continue
		var slot_cost := enemy.spawn_cost * float(count)
		if total_cost + slot_cost > spending_limit + 0.0001:
			continue
		if _respects_role_limits(enemy, count, role_counts, packet.role_limits):
			matching.append(candidate)
	while not matching.is_empty():
		var selected_index := _weighted_candidate_index(matching)
		var selected := matching[selected_index].get("enemy") as EnemyData
		matching.remove_at(selected_index)
		if selected == null:
			continue
		var next_entries: Array[Dictionary] = entries.duplicate(true)
		var next_roles := role_counts.duplicate()
		_add_entry(next_entries, selected, count)
		_add_limited_roles(next_roles, selected, count, packet.role_limits)
		var plan := _fill_slots(
			packet,
			candidates,
			slot_index + 1,
			spending_limit,
			total_cost + selected.spawn_cost * float(count),
			total_count + count,
			next_roles,
			next_entries
		)
		if not plan.is_empty():
			return plan
	if bool(slot.get("optional", false)):
		return _fill_slots(packet, candidates, slot_index + 1, spending_limit, total_cost, total_count, role_counts, entries)
	return {}

func _weighted_packet_index(packets: Array[SpawnPacketData]) -> int:
	var total_weight := 0.0
	for packet in packets:
		total_weight += packet.weight
	if total_weight <= 0.0:
		return 0
	var roll := RunRng.spawn_roll() * total_weight
	for index in packets.size():
		roll -= packets[index].weight
		if roll <= 0.0:
			return index
	return packets.size() - 1

func _weighted_candidate_index(candidates: Array[Dictionary]) -> int:
	var total_weight := 0.0
	for candidate in candidates:
		total_weight += maxf(float(candidate.get("weight", 0.0)), 0.0)
	if total_weight <= 0.0:
		return 0
	var roll := RunRng.spawn_roll() * total_weight
	for index in candidates.size():
		roll -= maxf(float(candidates[index].get("weight", 0.0)), 0.0)
		if roll <= 0.0:
			return index
	return candidates.size() - 1

func _respects_role_limits(enemy: EnemyData, count: int, current: Dictionary, limits: Dictionary) -> bool:
	for raw_role in limits:
		var role := StringName(raw_role)
		if enemy.role_tags.has(role) and int(current.get(role, 0)) + count > int(limits[raw_role]):
			return false
	return true

func _add_limited_roles(current: Dictionary, enemy: EnemyData, count: int, limits: Dictionary) -> void:
	for raw_role in limits:
		var role := StringName(raw_role)
		if enemy.role_tags.has(role):
			current[role] = int(current.get(role, 0)) + count

func _add_entry(entries: Array[Dictionary], enemy: EnemyData, count: int) -> void:
	for entry in entries:
		if (entry.get("enemy") as EnemyData).id == enemy.id:
			entry["count"] = int(entry.get("count", 0)) + count
			return
	entries.append({"enemy": enemy, "count": count})
