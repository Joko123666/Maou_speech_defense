extends Node

const TARGET_MARGIN_RATIO := 0.07
const NORMALIZED_CONTENT_RATIO := 0.84

func _ready() -> void:
	var config := CharacterStyleRefreshM6ReviewCatalog.load_config()
	var overrides := config.get("overrides", {}) as Dictionary
	var normalized := 0
	var failures: Array[String] = []
	var handled_paths: Dictionary = {}
	for key_value in overrides:
		var path := String(overrides[key_value])
		if handled_paths.has(path):
			continue
		handled_paths[path] = true
		var image := Image.load_from_file(ProjectSettings.globalize_path(path))
		if image == null or image.get_size() != Vector2i(1254, 1254):
			failures.append("normalization source must be a 1254px image: %s" % path)
			continue
		if _minimum_alpha_margin_ratio(image) >= TARGET_MARGIN_RATIO:
			continue
		var scaled := image.duplicate() as Image
		scaled.convert(Image.FORMAT_RGBA8)
		var target_size := int(floor(float(image.get_width()) * NORMALIZED_CONTENT_RATIO))
		scaled.resize(target_size, target_size, Image.INTERPOLATE_LANCZOS)
		var canvas := Image.create(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8)
		canvas.fill(Color.TRANSPARENT)
		var offset := Vector2i((image.get_width() - target_size) / 2, (image.get_height() - target_size) / 2)
		canvas.blend_rect(scaled, Rect2i(Vector2i.ZERO, scaled.get_size()), offset)
		var error := canvas.save_png(ProjectSettings.globalize_path(path))
		if error != OK:
			failures.append("failed to save normalized master '%s': %d" % [path, error])
		else:
			normalized += 1
	if failures.is_empty():
		print("CHARACTER M6 SAFE-MARGIN NORMALIZATION PASS: %d of %d masters updated" % [normalized, handled_paths.size()])
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)

func _minimum_alpha_margin_ratio(source: Image) -> float:
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
	return minf(minf(float(left) / width, float(right) / width), minf(float(top) / height, float(bottom) / height))

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
