class_name SpecializationOfferPolicy
extends RefCounted

var entry_chance: float
var pity_misses: int
var offer_misses: int = 0
var entry_waits: Dictionary = {}

func _init(chance: float = 0.58, misses_before_pity: int = 2) -> void:
	entry_chance = clampf(chance, 0.0, 1.0)
	pity_misses = maxi(misses_before_pity, 0)

func inject(choices: Array[UpgradeData], entries: Array[UpgradeData], protect_required_formation: bool, fill_target_count: int = 0) -> void:
	_sync_entry_waits(entries)
	if entries.is_empty():
		offer_misses = 0
		return
	if fill_target_count > 0 and choices.size() < fill_target_count:
		var unique_entries := entries.filter(func(entry: UpgradeData) -> bool:
			var key := entry_key(entry)
			return key != &"" and not choices.any(func(choice: UpgradeData) -> bool: return entry_key(choice) == key)
		)
		if not unique_entries.is_empty():
			var selected_entry := _oldest_entry(unique_entries)
			choices.append(selected_entry)
			_increment_entry_waits(entries, entry_key(selected_entry))
			offer_misses = 0
			return
	if choices.is_empty():
		offer_misses = 0
		return
	var should_offer := offer_misses >= pity_misses or RunRng.progression_roll() < entry_chance
	if not should_offer:
		offer_misses += 1
		_increment_entry_waits(entries)
		return
	var replace_candidates: Array[int] = []
	for index in choices.size():
		if choices[index].category in [&"guard_training", &"guard_completion"]:
			continue
		if String(choices[index].category).ends_with("_specialization_entry"):
			continue
		if choices[index].category in [&"core_level", &"cursor_level"]:
			continue
		if protect_required_formation and bool(choices[index].offer_metadata.get(&"required_initial_formation", false)):
			continue
		replace_candidates.append(index)
	if replace_candidates.is_empty():
		offer_misses += 1
		_increment_entry_waits(entries)
		return
	var selected_entry := _oldest_entry(entries)
	choices[int(RunRng.progression_pick(replace_candidates))] = selected_entry
	_increment_entry_waits(entries, entry_key(selected_entry))
	offer_misses = 0

func entry_key(entry: UpgradeData) -> StringName:
	return StringName("%s:%s" % [entry.category, entry.data_id])

func get_state_snapshot() -> Dictionary:
	return {
		"offer_misses": offer_misses,
		"entry_waits": entry_waits.duplicate(true),
	}

func restore_state(snapshot: Dictionary) -> void:
	offer_misses = maxi(int(snapshot.get("offer_misses", 0)), 0)
	var waits: Variant = snapshot.get("entry_waits", {})
	entry_waits = (waits as Dictionary).duplicate(true) if waits is Dictionary else {}

func _sync_entry_waits(entries: Array[UpgradeData]) -> void:
	var active_keys: Dictionary = {}
	for entry in entries:
		var key := entry_key(entry)
		active_keys[key] = true
		if not entry_waits.has(key):
			entry_waits[key] = 0
	for key in entry_waits.keys():
		if not active_keys.has(key):
			entry_waits.erase(key)

func _increment_entry_waits(entries: Array[UpgradeData], offered_key: StringName = &"") -> void:
	for entry in entries:
		var key := entry_key(entry)
		entry_waits[key] = 0 if key == offered_key else int(entry_waits.get(key, 0)) + 1

func _oldest_entry(entries: Array[UpgradeData]) -> UpgradeData:
	var selected := entries[0]
	var longest_wait := int(entry_waits.get(entry_key(selected), 0))
	for entry in entries.slice(1):
		var wait := int(entry_waits.get(entry_key(entry), 0))
		if wait > longest_wait:
			selected = entry
			longest_wait = wait
	return selected
