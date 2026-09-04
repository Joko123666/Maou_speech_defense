class_name GameTextCatalogData
extends Resource

const REQUIRED_KEYS = [
	&"menu.game_title", &"menu.game_subtitle",
	&"menu.shop_title", &"menu.shop_subtitle",
	&"menu.achievements_title", &"menu.achievements_subtitle",
	&"menu.codex_title", &"menu.codex_subtitle",
	&"setup.page_title", &"setup.page_subtitle", &"setup.shop_hint",
	&"hud.input_touch", &"hud.input_desktop", &"hud.skill", &"hud.boss_warning", &"hud.boss_name",
	&"level_up.title", &"level_up.hint", &"level_up.reroll", &"level_up.reroll_tooltip",
	&"level_up.subchoice_title", &"level_up.subchoice_hint",
	&"result.victory", &"result.defeat",
]

@export var id: StringName = &""
@export var entries: Dictionary = {}
@export var placeholder_contracts: Dictionary = {}

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("text catalog id is empty")
	for key in REQUIRED_KEYS:
		var value := _entry(key)
		if value.is_empty():
			errors.append("text catalog is missing required key '%s'" % key)
	for raw_key in entries:
		var key := String(raw_key)
		if key.is_empty():
			errors.append("text catalog contains an empty key")
		elif entries[raw_key] is not String:
			errors.append("text catalog entry '%s' is not a String" % key)
		elif String(entries[raw_key]).is_empty():
			errors.append("text catalog entry '%s' is empty" % key)
		else:
			_validate_placeholder_contract(errors, StringName(key), String(entries[raw_key]))
	for raw_key in placeholder_contracts:
		var key := StringName(raw_key)
		if _entry(key).is_empty():
			errors.append("text catalog placeholder contract references missing key '%s'" % key)
	return errors

func resolve(key: StringName, replacements: Dictionary = {}, fallback: String = "") -> String:
	var value := _entry(key)
	if value.is_empty():
		value = fallback if not fallback.is_empty() else String(key)
	var missing := _missing_placeholders(value, replacements)
	if not missing.is_empty():
		if fallback.is_empty():
			push_warning("Text catalog entry '%s' is missing replacements: %s" % [key, ", ".join(missing)])
			return String(key)
		value = fallback
	for replacement_key in replacements:
		value = value.replace("{%s}" % str(replacement_key), str(replacements[replacement_key]))
	var unresolved := _placeholder_names(value)
	if not unresolved.is_empty():
		push_warning("Text catalog entry '%s' has unresolved placeholders: %s" % [key, ", ".join(unresolved)])
		return String(key)
	return value

func required_placeholders(key: StringName) -> PackedStringArray:
	return _placeholder_names(_entry(key))

func missing_replacements(key: StringName, replacements: Dictionary = {}) -> PackedStringArray:
	return _missing_placeholders(_entry(key), replacements)

func _entry(key: StringName) -> String:
	var value: Variant = entries.get(key)
	if value == null:
		value = entries.get(String(key))
	return String(value) if value is String else ""

func _validate_placeholder_contract(errors: PackedStringArray, key: StringName, value: String) -> void:
	var placeholder_pattern := _placeholder_pattern()
	var remainder := placeholder_pattern.sub(value, "", true)
	if remainder.contains("{") or remainder.contains("}"):
		errors.append("text catalog entry '%s' contains malformed placeholder braces" % key)
	var actual := _placeholder_names(value)
	var raw_contract: Variant = placeholder_contracts.get(key)
	if raw_contract == null:
		raw_contract = placeholder_contracts.get(String(key))
	if raw_contract == null:
		if not actual.is_empty():
			errors.append("text catalog entry '%s' is missing its placeholder contract" % key)
		return
	if raw_contract is not Array and raw_contract is not PackedStringArray:
		errors.append("text catalog placeholder contract '%s' must be an Array or PackedStringArray" % key)
		return
	var declared := PackedStringArray()
	for raw_name in raw_contract:
		var name := String(raw_name)
		if name.is_empty() or not name.is_valid_identifier():
			errors.append("text catalog placeholder contract '%s' contains invalid name '%s'" % [key, name])
		elif name in declared:
			errors.append("text catalog placeholder contract '%s' duplicates '%s'" % [key, name])
		else:
			declared.append(name)
	actual.sort()
	declared.sort()
	if actual != declared:
		errors.append("text catalog entry '%s' placeholders %s do not match declared contract %s" % [key, actual, declared])

func _missing_placeholders(value: String, replacements: Dictionary) -> PackedStringArray:
	var missing := PackedStringArray()
	for name in _placeholder_names(value):
		if not replacements.has(name) and not replacements.has(StringName(name)):
			missing.append(name)
	return missing

func _placeholder_names(value: String) -> PackedStringArray:
	var result := PackedStringArray()
	for match_result in _placeholder_pattern().search_all(value):
		var name := match_result.get_string(1)
		if name not in result:
			result.append(name)
	return result

func _placeholder_pattern() -> RegEx:
	var pattern := RegEx.new()
	pattern.compile("\\{([A-Za-z_][A-Za-z0-9_]*)\\}")
	return pattern
