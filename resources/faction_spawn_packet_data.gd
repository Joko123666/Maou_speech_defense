class_name FactionSpawnPacketData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var faction_id: StringName = &""
@export var faction_enemy_id: StringName = &""
@export var tier_faction_counts: Array[int] = [1, 1, 1]
@export var tier_common_entries: Array[Dictionary] = [{}, {}, {}]

func faction_count_for_tier(tier: int) -> int:
	return tier_faction_counts[clampi(tier, 1, 3) - 1] if tier_faction_counts.size() == 3 else 0

func common_entries_for_tier(tier: int) -> Dictionary:
	return tier_common_entries[clampi(tier, 1, 3) - 1].duplicate() if tier_common_entries.size() == 3 else {}

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("faction spawn packet id is empty")
	if display_name.strip_edges().is_empty():
		errors.append("faction spawn packet display name is empty")
	if faction_id == &"":
		errors.append("faction spawn packet has no faction id")
	if faction_enemy_id == &"":
		errors.append("faction spawn packet has no faction enemy id")
	if tier_faction_counts.size() != 3 or tier_common_entries.size() != 3:
		errors.append("faction spawn packet requires exactly three tier definitions")
		return errors
	for tier_index in 3:
		if tier_faction_counts[tier_index] <= 0:
			errors.append("faction spawn packet tier %d has no faction units" % (tier_index + 1))
		for raw_enemy_id in tier_common_entries[tier_index]:
			if StringName(raw_enemy_id) == &"" or int(tier_common_entries[tier_index][raw_enemy_id]) <= 0:
				errors.append("faction spawn packet tier %d has an invalid common entry" % (tier_index + 1))
	return errors
