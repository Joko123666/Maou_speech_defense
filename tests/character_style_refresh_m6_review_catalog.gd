class_name CharacterStyleRefreshM6ReviewCatalog
extends RefCounted

const CONFIG_PATH := "res://data/art/character_style_refresh_m6_review_catalog.json"

static func load_config() -> Dictionary:
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed as Dictionary if parsed is Dictionary else {}

static func build() -> GameAssetCatalogData:
	var config := load_config()
	var base_path := String(config.get("base_catalog_path", ""))
	var base_catalog := load(base_path) as GameAssetCatalogData
	if base_catalog == null:
		return null
	var review_catalog := base_catalog.duplicate(true) as GameAssetCatalogData
	review_catalog.id = StringName(config.get("id", "demon_election_assets_v019_review"))
	var merged_overrides := review_catalog.content_texture_overrides.duplicate()
	for key_value in (config.get("overrides", {}) as Dictionary):
		var key := String(key_value)
		var path := String((config.get("overrides", {}) as Dictionary).get(key_value, ""))
		var texture := load(path) as Texture2D
		if texture != null:
			merged_overrides[key] = texture
	review_catalog.content_texture_overrides = merged_overrides
	return review_catalog
