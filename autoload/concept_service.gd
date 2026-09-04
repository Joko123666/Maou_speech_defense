extends Node

signal concept_changed(profile: GameConceptData)

const DEFAULT_PROFILE_PATH := "res://data/concepts/demon_election_vertical_slice.tres"

var active: GameConceptData
var active_path: String = ""
var last_load_errors: PackedStringArray = PackedStringArray()
var _content_texture_cache: Dictionary = {}
var _missing_content_assets: Dictionary = {}
var _used_content_aliases: Dictionary = {}

func _enter_tree() -> void:
	var configured_path := String(ProjectSettings.get_setting("game/concept_profile", DEFAULT_PROFILE_PATH))
	if not load_profile(configured_path):
		if configured_path != DEFAULT_PROFILE_PATH:
			load_profile(DEFAULT_PROFILE_PATH)

func load_profile(path: String) -> bool:
	last_load_errors.clear()
	if path.is_empty() or not ResourceLoader.exists(path):
		_record_load_error("Concept profile does not exist: %s" % path)
		return false
	var loaded := load(path) as GameConceptData
	if loaded == null:
		_record_load_error("Concept profile has the wrong resource type: %s" % path)
		return false
	var validation_errors := loaded.get_validation_errors()
	var registry := get_node_or_null("/root/DataRegistry")
	if registry != null and registry.has_method("validate_campaign") and loaded.campaign() != null:
		validation_errors.append_array(registry.validate_campaign(loaded.campaign()))
	if not validation_errors.is_empty():
		for validation_error in validation_errors:
			last_load_errors.append(String(validation_error))
		push_warning("Concept profile is not playable: %s" % ", ".join(validation_errors))
		return false
	active = loaded
	active_path = path
	_clear_asset_cache()
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title(active.project_title)
	concept_changed.emit(active)
	return true

func get_load_error_summary() -> String:
	return ", ".join(last_load_errors)

func _record_load_error(message: String) -> void:
	last_load_errors.append(message)
	push_warning(message)

func term(key: StringName) -> String:
	return active.term(key) if active != null else String(key)

func ui_text(key: StringName, replacements: Dictionary = {}, fallback: String = "") -> String:
	if active != null and active.text_catalog != null:
		return active.text_catalog.resolve(key, replacements, fallback)
	return fallback if not fallback.is_empty() else String(key)

func format_currency(amount: int) -> String:
	return "%d  %s" % [amount, term(&"currency")]

func texture(role: StringName) -> Texture2D:
	return active.assets.texture(role) if active != null and active.assets != null else null

func content_texture(category: StringName, id: StringName) -> Texture2D:
	if active == null or active.assets == null:
		return null
	var cache_key := "%s/%s" % [String(category), String(id)]
	if _content_texture_cache.has(cache_key):
		return _content_texture_cache[cache_key] as Texture2D
	var resolved := _load_content_texture(category, id)
	var requested_path := active.assets.content_texture_path(category, id)
	var alias_id := active.assets.content_alias_target(category, id)
	if resolved == null and alias_id != &"":
		resolved = _load_content_texture(category, alias_id)
		if resolved != null:
			_used_content_aliases[cache_key] = "%s/%s" % [String(category), String(alias_id)]
	if resolved == null:
		resolved = fallback_texture(category)
		_missing_content_assets[cache_key] = requested_path if not requested_path.is_empty() else "invalid category or content id"
	_content_texture_cache[cache_key] = resolved
	if resolved != null:
		return resolved
	return fallback_texture(category)

func optional_content_texture(category: StringName, id: StringName) -> Texture2D:
	if active == null or active.assets == null:
		return null
	return _load_content_texture(category, id)

func fallback_texture(category: StringName) -> Texture2D:
	return active.assets.fallback_texture(category) if active != null and active.assets != null else null

func audio(role: StringName) -> AudioStream:
	return active.assets.audio(role) if active != null and active.assets != null else null

func get_missing_content_assets() -> PackedStringArray:
	var missing := PackedStringArray()
	for key in _missing_content_assets:
		missing.append("%s -> %s" % [key, _missing_content_assets[key]])
	missing.sort()
	return missing

func get_used_content_aliases() -> Dictionary:
	return _used_content_aliases.duplicate()

func audit_content_assets(requests: Array[Dictionary]) -> Dictionary:
	_clear_asset_cache()
	var requested_keys: Dictionary = {}
	for request in requests:
		var category := StringName(request.get("category", &""))
		var content_id := StringName(request.get("id", &""))
		var key := "%s/%s" % [String(category), String(content_id)]
		requested_keys[key] = true
		content_texture(category, content_id)
	var dedicated := PackedStringArray()
	var aliases := PackedStringArray()
	var missing := PackedStringArray()
	for key_variant in requested_keys:
		var key := String(key_variant)
		if _missing_content_assets.has(key):
			missing.append(key)
		elif _used_content_aliases.has(key):
			aliases.append("%s -> %s" % [key, _used_content_aliases[key]])
		else:
			dedicated.append(key)
	dedicated.sort()
	aliases.sort()
	missing.sort()
	return {
		"requested_count": requested_keys.size(),
		"dedicated_count": dedicated.size(),
		"alias_count": aliases.size(),
		"missing_count": missing.size(),
		"dedicated": dedicated,
		"aliases": aliases,
		"missing": missing,
	}

func clear_runtime_asset_cache() -> void:
	_clear_asset_cache()

func _clear_asset_cache() -> void:
	_content_texture_cache.clear()
	_missing_content_assets.clear()
	_used_content_aliases.clear()

func _load_content_texture(category: StringName, content_id: StringName) -> Texture2D:
	var resolved := active.assets.content_texture_override(category, content_id)
	var path := active.assets.content_texture_path(category, content_id)
	if resolved == null and not path.is_empty() and ResourceLoader.exists(path, "Texture2D"):
		resolved = ResourceLoader.load(path, "Texture2D") as Texture2D
	return resolved

func get_content_pack() -> ContentPackData:
	return active.content_pack if active != null else null

func get_election_campaign() -> ElectionCampaignData:
	return active.campaign() if active != null else null

func get_default_stage() -> StageData:
	return active.default_stage if active != null else null

func get_stage_reward() -> StageRewardData:
	return active.stage_reward if active != null else null
