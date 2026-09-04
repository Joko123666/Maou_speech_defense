class_name FactionPreludePacketComposer
extends RefCounted

const SUCCUBUS_CAPS: Array[int] = [1, 2, 3]

func compose(
	packets: Array[FactionSpawnPacketData],
	faction_enemies: Array[EnemyData],
	common_candidates: Array[Dictionary],
	faction_id: StringName,
	tier: int,
	budget: float
) -> Dictionary:
	if faction_id == &"" or tier < 1 or tier > 3 or budget <= 0.0:
		return {}
	var packet := _packet_for_faction(packets, faction_id)
	if packet == null or not packet.get_validation_errors().is_empty():
		return {}
	var faction_enemy := _enemy_by_id(faction_enemies, packet.faction_enemy_id)
	if faction_enemy == null:
		return {}
	var entries: Array[Dictionary] = []
	var faction_count := packet.faction_count_for_tier(tier)
	entries.append({"enemy": faction_enemy, "count": faction_count, "faction": true})
	var common_by_id: Dictionary = {}
	for candidate in common_candidates:
		var enemy := candidate.get("enemy") as EnemyData
		if enemy != null:
			common_by_id[enemy.id] = enemy
	var common_entries := packet.common_entries_for_tier(tier)
	for raw_enemy_id in common_entries:
		var enemy_id := StringName(raw_enemy_id)
		var common_enemy := common_by_id.get(enemy_id) as EnemyData
		if common_enemy == null:
			return {}
		entries.append({"enemy": common_enemy, "count": int(common_entries[raw_enemy_id]), "faction": false})
	var cost := 0.0
	var count := 0
	var role_counts: Dictionary = {}
	for entry in entries:
		var enemy := entry.enemy as EnemyData
		var entry_count := int(entry.count)
		cost += enemy.spawn_cost * float(entry_count)
		count += entry_count
		for role in enemy.role_tags:
			role_counts[role] = int(role_counts.get(role, 0)) + entry_count
	if cost > budget + 0.0001 or not _respects_density_limits(entries, role_counts, tier):
		return {}
	return {
		"packet_id": StringName("prelude_%s_t%d" % [packet.id, tier]),
		"display_name": "%s Tier %d" % [packet.display_name, tier],
		"faction_id": faction_id,
		"tier": tier,
		"entries": entries,
		"cost": cost,
		"count": count,
		"role_counts": role_counts,
	}

func _packet_for_faction(packets: Array[FactionSpawnPacketData], faction_id: StringName) -> FactionSpawnPacketData:
	for packet in packets:
		if packet != null and packet.faction_id == faction_id:
			return packet
	return null

func _enemy_by_id(enemies: Array[EnemyData], enemy_id: StringName) -> EnemyData:
	for enemy in enemies:
		if enemy != null and enemy.id == enemy_id:
			return enemy
	return null

func _respects_density_limits(entries: Array[Dictionary], role_counts: Dictionary, tier: int) -> bool:
	var ids: Dictionary = {}
	for entry in entries:
		var enemy := entry.enemy as EnemyData
		ids[enemy.id] = int(ids.get(enemy.id, 0)) + int(entry.count)
	if int(ids.get(&"steel_golem", 0)) > 1:
		return false
	if ids.has(&"steel_golem") and (ids.has(&"kasuha_abyss_creature") or ids.has(&"partason_standard_shield")):
		return false
	var heavy_limit := 2 if tier >= 3 else 1
	if int(role_counts.get(&"heavy", 0)) > heavy_limit:
		return false
	if int(role_counts.get(&"disable", 0)) > tier:
		return false
	if int(ids.get(&"jiane_succubus_bewitcher", 0)) > SUCCUBUS_CAPS[tier - 1]:
		return false
	if tier < 3 and ids.has(&"hound_light_infantry") and int(ids.get(&"judaginda_cult_applicant", 0)) >= 4:
		return false
	return true
