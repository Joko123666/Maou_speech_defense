class_name CandidateProfileData
extends Resource

@export var id: StringName = &""
@export var core_id: StringName = &""
@export var faction_id: StringName = &""
@export var full_name: String = ""
@export var short_name: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var campaign_slogan: String = ""
@export var emblem_id: StringName = &""
@export var candidate_boss_id: StringName = &""
@export var default_retainer_id: StringName = &""
@export_range(1, 100000, 1) var support_required_for_election: int = 1000
@export var decree_ids: Array[StringName] = []
@export var growth_data: CandidateGrowthData
@export var guard_growth_data: GuardGrowthData

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("candidate id is empty")
	if core_id == &"": errors.append("candidate '%s' has no core id" % id)
	if faction_id == &"": errors.append("candidate '%s' has no faction id" % id)
	if full_name.is_empty(): errors.append("candidate '%s' has no full name" % id)
	if short_name.is_empty(): errors.append("candidate '%s' has no short name" % id)
	if campaign_slogan.is_empty(): errors.append("candidate '%s' has no campaign slogan" % id)
	if emblem_id == &"": errors.append("candidate '%s' has no emblem id" % id)
	if candidate_boss_id == &"": errors.append("candidate '%s' has no candidate boss id" % id)
	if default_retainer_id == &"": errors.append("candidate '%s' has no default retainer id" % id)
	if support_required_for_election <= 0: errors.append("candidate '%s' has a non-positive election support requirement" % id)
	if decree_ids.size() != 3: errors.append("candidate '%s' requires exactly three decree ids" % id)
	if growth_data != null:
		errors.append_array(growth_data.get_validation_errors())
		if growth_data.candidate_id != id: errors.append("candidate '%s' growth data belongs to '%s'" % [id, growth_data.candidate_id])
	if guard_growth_data != null:
		errors.append_array(guard_growth_data.get_validation_errors())
		if guard_growth_data.candidate_id != id: errors.append("candidate '%s' guard growth data belongs to '%s'" % [id, guard_growth_data.candidate_id])
	var unique_decrees: Dictionary = {}
	for decree_id in decree_ids:
		if decree_id == &"": errors.append("candidate '%s' contains an empty decree id" % id)
		elif unique_decrees.has(decree_id): errors.append("candidate '%s' contains duplicate decree '%s'" % [id, decree_id])
		unique_decrees[decree_id] = true
	return errors
