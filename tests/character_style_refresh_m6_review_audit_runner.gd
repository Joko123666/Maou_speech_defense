extends Node

const CAPTURES := [
	"res://tests/visual_reviews/character_style_refresh_m6_catalog_defenders.png",
	"res://tests/visual_reviews/character_style_refresh_m6_catalog_candidates.png",
	"res://tests/visual_reviews/character_style_refresh_m6_catalog_retainers.png",
	"res://tests/visual_reviews/character_style_refresh_m6_catalog_guards.png",
]

func _ready() -> void:
	var failures: Array[String] = []
	var config := CharacterStyleRefreshM6ReviewCatalog.load_config()
	var catalog := CharacterStyleRefreshM6ReviewCatalog.build()
	_expect(not config.is_empty(), "M6 review catalog config must parse", failures)
	_expect(catalog != null and catalog.get_validation_errors().is_empty(), "M6 review catalog clone must be valid", failures)
	if catalog != null:
		_validate_overrides(config, catalog, failures)
	for path in CAPTURES:
		_expect(FileAccess.file_exists(path), "M6 review capture must exist: %s" % path, failures)
		if FileAccess.file_exists(path):
			var capture := Image.load_from_file(ProjectSettings.globalize_path(path))
			_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "M6 review capture must remain 1280x720: %s" % path, failures)
	if failures.is_empty():
		print("CHARACTER M6 REVIEW CATALOG AUDIT PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)

func _validate_overrides(config: Dictionary, catalog: GameAssetCatalogData, failures: Array[String]) -> void:
	var overrides := config.get("overrides", {}) as Dictionary
	var expected_counts := config.get("expected_category_counts", {}) as Dictionary
	_expect(overrides.size() == int(config.get("expected_override_count", 0)) and overrides.size() == 54, "M6 review catalog must contain exactly 54 approved character overrides", failures)
	var actual_counts: Dictionary = {}
	var paths: Dictionary = {}
	var hashes: Dictionary = {}
	for key_value in overrides:
		var key := String(key_value)
		var path := String(overrides[key_value])
		var category := key.get_slice("/", 0)
		var content_id := key.get_slice("/", 1)
		actual_counts[category] = int(actual_counts.get(category, 0)) + 1
		_expect(key.count("/") == 1 and GameAssetCatalogData.CONTENT_CATEGORIES.has(StringName(category)) and GameAssetCatalogData.is_safe_content_id(StringName(content_id)), "M6 review key must be a safe catalog identity: %s" % key, failures)
		_expect(path.begins_with("res://assets/graphics/style_refresh_v019/") and FileAccess.file_exists(path), "M6 review source must be an existing staged master: %s" % path, failures)
		_expect(not paths.has(path), "M6 review source paths must not be reused: %s" % path, failures)
		paths[path] = true
		var texture := catalog.content_texture_override(StringName(category), StringName(content_id))
		_expect(texture != null and texture.get_size() == Vector2(512, 512), "M6 review runtime texture must import at exactly 512px: %s" % key, failures)
		if FileAccess.file_exists(path):
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			_validate_master(image, key, failures)
			var digest := FileAccess.get_sha256(path)
			_expect(not digest.is_empty() and not hashes.has(digest), "M6 approved character masters must not contain an unapproved exact duplicate: %s" % key, failures)
			hashes[digest] = key
	for category_value in expected_counts:
		var category := String(category_value)
		_expect(int(actual_counts.get(category, 0)) == int(expected_counts[category_value]), "M6 review category '%s' must contain exactly %d overrides" % [category, int(expected_counts[category_value])], failures)
	_expect(actual_counts.size() == expected_counts.size(), "M6 review catalog must not introduce undeclared character categories", failures)
	for content_id in [&"partason", &"jiane", &"kasuha", &"irelai", &"judaginda"]:
		_expect(String(overrides["candidate_sd/%s" % content_id]) != String(overrides["candidate_intrusion_sd/%s" % content_id]), "candidate ally and intrusion art must remain separate: %s" % content_id, failures)
	for content_id in [&"kanda", &"given", &"jeomujeom", &"jugdied", &"death_vanguard"]:
		_expect(String(overrides["retainer_sd/%s" % content_id]) != String(overrides["retainer_intrusion_sd/%s" % content_id]), "retainer ally and intrusion art must remain separate: %s" % content_id, failures)

func _validate_master(image: Image, label: String, failures: Array[String]) -> void:
	_expect(image != null and image.get_size() == Vector2i(1254, 1254), "M6 approved master must remain a 1254px square: %s" % label, failures)
	if image == null:
		return
	_expect(image.get_format() in [Image.FORMAT_RGBA8, Image.FORMAT_RGBAF, Image.FORMAT_RGBAH], "M6 approved master must preserve RGBA: %s" % label, failures)
	var last := image.get_size() - Vector2i.ONE
	_expect(image.get_pixel(0, 0).a <= 0.01 and image.get_pixel(last.x, 0).a <= 0.01 and image.get_pixel(0, last.y).a <= 0.01 and image.get_pixel(last.x, last.y).a <= 0.01, "M6 approved master must keep transparent corners: %s" % label, failures)
	var margins := _alpha_margin_ratios(image)
	var minimum_margin := minf(minf(float(margins.left), float(margins.right)), minf(float(margins.top), float(margins.bottom)))
	_expect(minimum_margin >= 0.07, "M6 approved master must keep seven percent alpha-safe margin: %s (%s)" % [label, margins], failures)

func _alpha_margin_ratios(source: Image) -> Dictionary:
	var image := source.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	var width: int = image.get_width()
	var height: int = image.get_height()
	var data: PackedByteArray = image.get_data()
	var left: int = width
	var right: int = width
	var top: int = height
	var bottom: int = height
	for x_value in range(width):
		var x := int(x_value)
		if _column_has_visible_alpha(data, width, height, x):
			left = x
			break
	for offset_value in range(width):
		var offset := int(offset_value)
		var x := width - 1 - offset
		if _column_has_visible_alpha(data, width, height, x):
			right = offset
			break
	for y_value in range(height):
		var y := int(y_value)
		if _row_has_visible_alpha(data, width, y):
			top = y
			break
	for offset_value in range(height):
		var offset := int(offset_value)
		var y := height - 1 - offset
		if _row_has_visible_alpha(data, width, y):
			bottom = offset
			break
	return {"left": float(left) / width, "right": float(right) / width, "top": float(top) / height, "bottom": float(bottom) / height}

func _column_has_visible_alpha(data: PackedByteArray, width: int, height: int, x: int) -> bool:
	for y in range(height):
		if data[(y * width + x) * 4 + 3] > 2:
			return true
	return false

func _row_has_visible_alpha(data: PackedByteArray, width: int, y: int) -> bool:
	var start := (y * width) * 4 + 3
	for x in range(width):
		if data[start + x * 4] > 2:
			return true
	return false

func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
