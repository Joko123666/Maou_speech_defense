class_name CodexRuleCatalogData
extends Resource

@export var entries: Array[CodexRuleEntryData] = []

func find_entry(entry_id: StringName) -> CodexRuleEntryData:
	for entry in entries:
		if entry != null and entry.id == entry_id:
			return entry
	return null

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	var ids: Dictionary = {}
	for entry in entries:
		if entry == null:
			errors.append("codex rule catalog contains a null entry")
			continue
		if ids.has(entry.id):
			errors.append("duplicate codex rule id '%s'" % entry.id)
		ids[entry.id] = true
		errors.append_array(entry.get_validation_errors())
	return errors
