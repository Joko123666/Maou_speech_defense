class_name GameAssetCatalogData
extends Resource

const REQUIRED_CONTENT_CATEGORIES = [&"cores", &"cursors", &"towers", &"enemies"]
const CONTENT_CATEGORIES = REQUIRED_CONTENT_CATEGORIES + [&"defenders", &"defender_attacks", &"defender_icons", &"tower_attacks", &"candidates", &"retainers", &"candidate_sd", &"retainer_sd", &"candidate_intrusion_sd", &"retainer_intrusion_sd", &"guard_intrusion_sd", &"factions", &"emblems", &"effects", &"projectiles"]
const TEXTURE_ROLES = [
	&"menu_background", &"title_background", &"main_hub_background", &"battlefield_background",
	&"core_fallback", &"cursor_fallback", &"tower_fallback", &"enemy_fallback",
	&"projectile_plasma", &"projectile_artillery",
]
const AUDIO_ROLES = [
	&"ui_click", &"level_up", &"boss_warning", &"boss_spawn", &"core_skill",
	&"hit_light", &"hit_heavy", &"core_hit", &"victory", &"defeat",
]
const REQUIRED_AUDIO_VARIANTS = [
	&"core_skill_emerald", &"core_skill_sapphire", &"core_skill_amethyst", &"core_skill_jade", &"core_skill_obsidian",
	&"tower_rapid", &"tower_blast", &"tower_energy", &"tower_saw", &"tower_arcane",
]

@export_group("Identity")
@export var id: StringName = &""

@export_group("Content graphics")
@export_dir var graphics_root: String = "res://assets/graphics"
@export var content_texture_overrides: Dictionary = {}
@export var approved_content_aliases: Dictionary = {}

@export_group("Required textures")
@export var menu_background: Texture2D
@export var title_background: Texture2D
@export var main_hub_background: Texture2D
@export var battlefield_background: Texture2D
@export var core_fallback: Texture2D
@export var cursor_fallback: Texture2D
@export var tower_fallback: Texture2D
@export var enemy_fallback: Texture2D
@export var projectile_plasma: Texture2D
@export var projectile_artillery: Texture2D

@export_group("Required audio")
@export var audio_ui_click: AudioStream
@export var audio_level_up: AudioStream
@export var audio_boss_warning: AudioStream
@export var audio_boss_spawn: AudioStream
@export var audio_core_skill: AudioStream
@export var audio_hit_light: AudioStream
@export var audio_hit_heavy: AudioStream
@export var audio_core_hit: AudioStream
@export var audio_victory: AudioStream
@export var audio_defeat: AudioStream

@export_group("Optional named audio")
@export var audio_overrides: Dictionary = {}

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("asset catalog id is empty")
	if not _is_safe_resource_root(graphics_root):
		errors.append("asset catalog graphics root must be a safe res:// path without parent traversal")
	for role in TEXTURE_ROLES:
		if texture(role) == null:
			errors.append("asset catalog is missing required texture role '%s'" % role)
	for role in AUDIO_ROLES:
		if audio(role) == null:
			errors.append("asset catalog is missing required audio role '%s'" % role)
	for role in REQUIRED_AUDIO_VARIANTS:
		if audio(role) == null:
			errors.append("asset catalog is missing required audio variant '%s'" % role)
	for raw_key in content_texture_overrides:
		var key := String(raw_key)
		if not _is_valid_content_key(key):
			errors.append("asset catalog has invalid content texture override key '%s'" % key)
		elif content_texture_overrides[raw_key] is not Texture2D:
			errors.append("asset catalog override '%s' is not a Texture2D" % key)
	for raw_source in approved_content_aliases:
		var source := String(raw_source)
		var target := String(approved_content_aliases[raw_source])
		if not _is_valid_content_key(source):
			errors.append("asset catalog has invalid content alias source '%s'" % source)
			continue
		if not _is_valid_content_key(target):
			errors.append("asset catalog has invalid content alias target '%s'" % target)
			continue
		var source_parts := source.split("/", false, 1)
		var target_parts := target.split("/", false, 1)
		if source_parts[0] != target_parts[0]:
			errors.append("asset catalog content alias must stay in one category: '%s' -> '%s'" % [source, target])
		elif source == target:
			errors.append("asset catalog content alias cannot target itself: '%s'" % source)
		elif _alias_value(target) != "":
			errors.append("asset catalog content alias target cannot be another alias: '%s' -> '%s'" % [source, target])
		elif not _content_key_has_texture(target):
			errors.append("asset catalog content alias target is missing: '%s' -> '%s'" % [source, target])
	for raw_key in audio_overrides:
		var key := StringName(raw_key)
		if not is_safe_content_id(key):
			errors.append("asset catalog has invalid audio override key '%s'" % String(raw_key))
		elif audio_overrides[raw_key] is not AudioStream:
			errors.append("asset catalog audio override '%s' is not an AudioStream" % String(raw_key))
	return errors

func is_valid() -> bool:
	return get_validation_errors().is_empty()

func get_authoring_validation_errors() -> PackedStringArray:
	var errors := get_validation_errors()
	if not _is_safe_resource_root(graphics_root):
		return errors
	for category in REQUIRED_CONTENT_CATEGORIES:
		var category_path := "%s/%s" % [graphics_root.trim_suffix("/"), String(category)]
		if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(category_path)):
			errors.append("asset catalog graphics category directory is missing: %s" % category_path)
	return errors

func texture(role: StringName) -> Texture2D:
	return {
		&"menu_background": menu_background,
		&"title_background": title_background if title_background != null else menu_background,
		&"main_hub_background": main_hub_background if main_hub_background != null else menu_background,
		&"battlefield_background": battlefield_background,
		&"core_fallback": core_fallback,
		&"cursor_fallback": cursor_fallback,
		&"tower_fallback": tower_fallback,
		&"enemy_fallback": enemy_fallback,
		&"projectile_plasma": projectile_plasma,
		&"projectile_artillery": projectile_artillery,
	}.get(role) as Texture2D

func fallback_texture(category: StringName) -> Texture2D:
	return {
		&"backgrounds": battlefield_background,
		&"cores": core_fallback,
		&"cursors": cursor_fallback,
		&"towers": tower_fallback,
		&"defenders": tower_fallback,
		&"defender_attacks": tower_fallback,
		&"defender_icons": tower_fallback,
		&"tower_attacks": tower_fallback,
		&"enemies": enemy_fallback,
		&"candidates": core_fallback,
		&"retainers": cursor_fallback,
		&"candidate_sd": core_fallback,
		&"retainer_sd": cursor_fallback,
		&"candidate_intrusion_sd": core_fallback,
		&"retainer_intrusion_sd": cursor_fallback,
		&"guard_intrusion_sd": tower_fallback,
		&"factions": enemy_fallback,
		&"emblems": enemy_fallback,
		&"effects": core_fallback,
		&"projectiles": projectile_plasma,
		&"projectile_plasma": projectile_plasma,
		&"projectile_artillery": projectile_artillery,
	}.get(category) as Texture2D

func audio(role: StringName) -> AudioStream:
	var override: Variant = audio_overrides.get(role)
	if override == null:
		override = audio_overrides.get(String(role))
	if override is AudioStream:
		return override as AudioStream
	return {
		&"ui_click": audio_ui_click,
		&"level_up": audio_level_up,
		&"boss_warning": audio_boss_warning,
		&"boss_spawn": audio_boss_spawn,
		&"core_skill": audio_core_skill,
		&"hit_light": audio_hit_light,
		&"hit_heavy": audio_hit_heavy,
		&"core_hit": audio_core_hit,
		&"victory": audio_victory,
		&"defeat": audio_defeat,
	}.get(role) as AudioStream

func content_texture_override(category: StringName, content_id: StringName) -> Texture2D:
	var key := "%s/%s" % [String(category), String(content_id)]
	var value: Variant = content_texture_overrides.get(key)
	if value == null:
		value = content_texture_overrides.get(StringName(key))
	return value as Texture2D

func content_alias_target(category: StringName, content_id: StringName) -> StringName:
	var key := "%s/%s" % [String(category), String(content_id)]
	var value := _alias_value(key)
	if value.is_empty() or not _is_valid_content_key(value):
		return &""
	return StringName(value.get_slice("/", 1))

func content_texture_path(category: StringName, content_id: StringName) -> String:
	if not CONTENT_CATEGORIES.has(category) or not is_safe_content_id(content_id):
		return ""
	return "%s/%s/%s.png" % [graphics_root.trim_suffix("/"), String(category), String(content_id)]

static func is_safe_content_id(content_id: StringName) -> bool:
	var value := String(content_id)
	if value.is_empty():
		return false
	for character in value:
		var code := character.unicode_at(0)
		var is_lowercase_letter := code >= 97 and code <= 122
		var is_digit := code >= 48 and code <= 57
		if not is_lowercase_letter and not is_digit and character != "_" and character != "-":
			return false
	return true

func _alias_value(key: String) -> String:
	var value: Variant = approved_content_aliases.get(key)
	if value == null:
		value = approved_content_aliases.get(StringName(key))
	return String(value) if value is String or value is StringName else ""

func _content_key_has_texture(key: String) -> bool:
	var parts := key.split("/", false, 1)
	var category := StringName(parts[0])
	var content_id := StringName(parts[1])
	if content_texture_override(category, content_id) != null:
		return true
	var path := content_texture_path(category, content_id)
	return not path.is_empty() and ResourceLoader.exists(path, "Texture2D")

static func _is_valid_content_key(key: String) -> bool:
	var parts := key.split("/", false, 1)
	return parts.size() == 2 and CONTENT_CATEGORIES.has(StringName(parts[0])) and is_safe_content_id(StringName(parts[1]))

static func _is_safe_resource_root(path: String) -> bool:
	return not path.is_empty() and path.begins_with("res://") and not path.contains("..")
