class_name GovernanceReactionCatalogData
extends Resource

const EXPECTED_REACTION_COUNT := 5

@export var reactions: Array[GovernanceReactionData] = []

func reaction_for(approval: int) -> GovernanceReactionData:
	var bounded := clampi(approval, 0, 100)
	for reaction in reactions:
		if reaction != null and reaction.contains(bounded):
			return reaction
	return null

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if reactions.size() != EXPECTED_REACTION_COUNT:
		errors.append("governance catalog requires exactly five reactions")
	var expected_minimum := 0
	var previous_strength := 0
	var ids: Dictionary = {}
	for index in reactions.size():
		var reaction := reactions[index]
		if reaction == null:
			errors.append("governance reaction[%d] is null" % index)
			continue
		errors.append_array(reaction.get_validation_errors())
		if ids.has(reaction.id):
			errors.append("governance reactions contain duplicate id '%s'" % reaction.id)
		ids[reaction.id] = true
		if reaction.minimum_approval != expected_minimum:
			errors.append("governance reaction '%s' must start at %d" % [reaction.id, expected_minimum])
		expected_minimum = reaction.maximum_approval + 1
		if reaction.audience_strength < previous_strength:
			errors.append("governance reaction '%s' decreases audience strength" % reaction.id)
		previous_strength = reaction.audience_strength
	if expected_minimum != 101:
		errors.append("governance reactions must cover approval 0 through 100 without gaps")
	return errors
