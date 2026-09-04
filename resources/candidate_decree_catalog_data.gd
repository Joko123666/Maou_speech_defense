class_name CandidateDecreeCatalogData
extends Resource

@export_range(1, 10, 1) var expected_decrees_per_candidate: int = 3
@export var decrees: Array[CandidateDecreeData] = []

func decree(id_value: StringName) -> CandidateDecreeData:
	for item in decrees:
		if item != null and item.id == id_value:
			return item
	return null

func decrees_for_candidate(candidate_id: StringName) -> Array[CandidateDecreeData]:
	var result: Array[CandidateDecreeData] = []
	for item in decrees:
		if item != null and item.candidate_id == candidate_id:
			result.append(item)
	return result

func get_validation_errors(candidate_ids: Dictionary = {}) -> PackedStringArray:
	var errors := PackedStringArray()
	var seen_ids: Dictionary = {}
	var counts: Dictionary = {}
	for index in decrees.size():
		var item := decrees[index]
		if item == null:
			errors.append("candidate decree[%d] is null" % index)
			continue
		errors.append_array(item.get_validation_errors())
		if seen_ids.has(item.id):
			errors.append("candidate decrees contain duplicate id '%s'" % item.id)
		seen_ids[item.id] = true
		counts[item.candidate_id] = int(counts.get(item.candidate_id, 0)) + 1
		if not candidate_ids.is_empty() and not candidate_ids.has(item.candidate_id):
			errors.append("candidate decree '%s' references missing candidate '%s'" % [item.id, item.candidate_id])
	if not candidate_ids.is_empty():
		for candidate_id in candidate_ids:
			if int(counts.get(candidate_id, 0)) != expected_decrees_per_candidate:
				errors.append("candidate '%s' requires %d decrees but has %d" % [candidate_id, expected_decrees_per_candidate, int(counts.get(candidate_id, 0))])
	return errors
