class_name ElectionCampaignData
extends Resource

@export var id: StringName = &""
@export_range(1, 20, 1) var expected_candidate_count: int = 5
@export_range(1, 20, 1) var expected_boss_slot_count: int = 4
@export var candidates: Array[CandidateProfileData] = []
@export var retainers: Array[RetainerProfileData] = []
@export var factions: Array[ElectionFactionData] = []
@export var decree_catalog: CandidateDecreeCatalogData
@export var governance_reactions: GovernanceReactionCatalogData

func get_validation_errors(
	core_ids: Dictionary = {},
	cursor_ids: Dictionary = {},
	enemy_ids: Dictionary = {},
	boss_ids: Dictionary = {}
) -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("election campaign id is empty")
	_validate_count(errors, "candidate", candidates.size(), expected_candidate_count)
	_validate_count(errors, "retainer", retainers.size(), expected_candidate_count)
	_validate_count(errors, "faction", factions.size(), expected_candidate_count)
	var candidate_by_id := _catalog(errors, "candidate", candidates)
	var retainer_by_id := _catalog(errors, "retainer", retainers)
	var faction_by_id := _catalog(errors, "faction", factions)
	if decree_catalog == null:
		errors.append("election campaign has no candidate decree catalog")
	else:
		errors.append_array(decree_catalog.get_validation_errors(candidate_by_id))
	if governance_reactions == null:
		errors.append("election campaign has no governance reaction catalog")
	else:
		errors.append_array(governance_reactions.get_validation_errors())
	var short_names: Dictionary = {}
	var enemy_faction_owners: Dictionary = {}
	var marker_style_owners: Dictionary = {}
	for candidate in candidates:
		if candidate == null: continue
		errors.append_array(candidate.get_validation_errors())
		_validate_reference(errors, "candidate '%s' core" % candidate.id, candidate.core_id, core_ids)
		_validate_reference(errors, "candidate '%s' faction" % candidate.id, candidate.faction_id, faction_by_id)
		_validate_reference(errors, "candidate '%s' boss" % candidate.id, candidate.candidate_boss_id, boss_ids)
		_validate_reference(errors, "candidate '%s' default retainer" % candidate.id, candidate.default_retainer_id, retainer_by_id)
		if decree_catalog != null:
			for decree_id in candidate.decree_ids:
				var decree := decree_catalog.decree(decree_id)
				if decree == null:
					errors.append("candidate '%s' references missing decree '%s'" % [candidate.id, decree_id])
				elif decree.candidate_id != candidate.id:
					errors.append("candidate '%s' decree '%s' belongs to '%s'" % [candidate.id, decree_id, decree.candidate_id])
		if short_names.has(candidate.short_name):
			errors.append("candidates contain duplicate short name '%s'" % candidate.short_name)
		else:
			short_names[candidate.short_name] = true
		var faction := faction_by_id.get(candidate.faction_id) as ElectionFactionData
		if faction != null and faction.candidate_id != candidate.id:
			errors.append("candidate '%s' faction '%s' points to candidate '%s'" % [candidate.id, faction.id, faction.candidate_id])
	for retainer in retainers:
		if retainer == null: continue
		errors.append_array(retainer.get_validation_errors())
		_validate_reference(errors, "retainer '%s' cursor" % retainer.id, retainer.cursor_id, cursor_ids)
		_validate_reference(errors, "retainer '%s' preferred candidate" % retainer.id, retainer.preferred_candidate_id, candidate_by_id)
		_validate_reference(errors, "retainer '%s' boss" % retainer.id, retainer.retainer_boss_id, boss_ids)
	for faction in factions:
		if faction == null: continue
		errors.append_array(faction.get_validation_errors())
		if faction.marker_style != &"":
			if marker_style_owners.has(faction.marker_style):
				errors.append("factions '%s' and '%s' share marker style '%s'" % [marker_style_owners[faction.marker_style], faction.id, faction.marker_style])
			else:
				marker_style_owners[faction.marker_style] = faction.id
		_validate_reference(errors, "faction '%s' candidate" % faction.id, faction.candidate_id, candidate_by_id)
		_validate_references(errors, "faction '%s' supporter" % faction.id, faction.supporter_enemy_ids, enemy_ids)
		_validate_references(errors, "faction '%s' elite" % faction.id, faction.elite_enemy_ids, enemy_ids)
		_validate_references(errors, "faction '%s' boss" % faction.id, faction.boss_ids, boss_ids)
		_validate_references(errors, "faction '%s' replacement boss" % faction.id, faction.replacement_boss_ids, boss_ids)
		for supporter_id in faction.supporter_enemy_ids:
			if enemy_faction_owners.has(supporter_id):
				errors.append("enemy '%s' belongs to multiple election factions '%s' and '%s'" % [supporter_id, enemy_faction_owners[supporter_id], faction.id])
			else:
				enemy_faction_owners[supporter_id] = faction.id
	return errors

func candidate(id_value: StringName) -> CandidateProfileData:
	for item in candidates:
		if item != null and item.id == id_value: return item
	return null

func candidate_for_core(core_id: StringName) -> CandidateProfileData:
	for item in candidates:
		if item != null and item.core_id == core_id: return item
	return null

func candidate_for_boss(boss_id: StringName) -> CandidateProfileData:
	for item in candidates:
		if item != null and item.candidate_boss_id == boss_id:
			return item
	var boss_faction := faction_for_boss(boss_id)
	return candidate(boss_faction.candidate_id) if boss_faction != null else null

func decree(id_value: StringName) -> CandidateDecreeData:
	return decree_catalog.decree(id_value) if decree_catalog != null else null

func decrees_for_candidate(candidate_id: StringName) -> Array[CandidateDecreeData]:
	return decree_catalog.decrees_for_candidate(candidate_id) if decree_catalog != null else []

func governance_reaction(approval: int) -> GovernanceReactionData:
	return governance_reactions.reaction_for(approval) if governance_reactions != null else null

func retainer(id_value: StringName) -> RetainerProfileData:
	for item in retainers:
		if item != null and item.id == id_value: return item
	return null

func retainer_for_cursor(cursor_id: StringName) -> RetainerProfileData:
	for item in retainers:
		if item != null and item.cursor_id == cursor_id: return item
	return null

func retainer_for_boss(boss_id: StringName) -> RetainerProfileData:
	for item in retainers:
		if item != null and item.retainer_boss_id == boss_id: return item
	return null

func faction(id_value: StringName) -> ElectionFactionData:
	for item in factions:
		if item != null and item.id == id_value: return item
	return null

func faction_for_boss(boss_id: StringName) -> ElectionFactionData:
	for item in factions:
		if item != null and boss_id in item.boss_ids:
			return item
	for item in factions:
		if item != null and boss_id in item.replacement_boss_ids:
			return item
	return null

func faction_for_enemy(enemy_id: StringName) -> ElectionFactionData:
	for item in factions:
		if item != null and enemy_id in item.supporter_enemy_ids:
			return item
	return null

func _validate_count(errors: PackedStringArray, label: String, actual: int, expected: int) -> void:
	if actual != expected:
		errors.append("election campaign requires %d %ss but contains %d" % [expected, label, actual])

func _catalog(errors: PackedStringArray, label: String, items: Array) -> Dictionary:
	var result: Dictionary = {}
	for index in items.size():
		var item := items[index] as Resource
		if item == null:
			errors.append("%s[%d] is null" % [label, index])
			continue
		var item_id := StringName(item.get("id"))
		if item_id == &"":
			continue
		if result.has(item_id):
			errors.append("%ss contain duplicate id '%s'" % [label, item_id])
		else:
			result[item_id] = item
	return result

func _validate_reference(errors: PackedStringArray, label: String, id_value: StringName, catalog: Dictionary) -> void:
	if id_value == &"" or catalog.is_empty(): return
	if not catalog.has(id_value): errors.append("%s references missing id '%s'" % [label, id_value])

func _validate_references(errors: PackedStringArray, label: String, ids: Array[StringName], catalog: Dictionary) -> void:
	if catalog.is_empty(): return
	for id_value in ids:
		_validate_reference(errors, label, id_value, catalog)
