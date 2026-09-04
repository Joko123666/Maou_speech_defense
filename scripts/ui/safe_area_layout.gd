class_name UiSafeAreaLayout
extends RefCounted

const DEFAULT_MINIMUM := Vector4(24.0, 16.0, 24.0, 16.0)

static func current_safe_rect(viewport_size: Vector2i) -> Rect2i:
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return Rect2i()
	var display_safe := DisplayServer.get_display_safe_area()
	var display_size := DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())
	if display_safe.size.x <= 0 or display_safe.size.y <= 0 or display_size.x <= 0 or display_size.y <= 0:
		return Rect2i()
	var scale := Vector2(viewport_size) / Vector2(display_size)
	return Rect2i(
		Vector2i((Vector2(display_safe.position) * scale).round()),
		Vector2i((Vector2(display_safe.size) * scale).round())
	).intersection(Rect2i(Vector2i.ZERO, viewport_size))

static func resolve_margins(viewport_size: Vector2i, safe_rect: Rect2i, minimum: Vector4 = DEFAULT_MINIMUM) -> Vector4:
	var normalized_safe := safe_rect.intersection(Rect2i(Vector2i.ZERO, viewport_size))
	if normalized_safe.size.x <= 0 or normalized_safe.size.y <= 0:
		return minimum
	return Vector4(
		maxf(minimum.x, float(normalized_safe.position.x)),
		maxf(minimum.y, float(normalized_safe.position.y)),
		maxf(minimum.z, float(viewport_size.x - normalized_safe.end.x)),
		maxf(minimum.w, float(viewport_size.y - normalized_safe.end.y))
	)

static func apply_to(container: MarginContainer, margins: Vector4) -> void:
	container.add_theme_constant_override(&"margin_left", roundi(margins.x))
	container.add_theme_constant_override(&"margin_top", roundi(margins.y))
	container.add_theme_constant_override(&"margin_right", roundi(margins.z))
	container.add_theme_constant_override(&"margin_bottom", roundi(margins.w))

static func available_size(viewport_size: Vector2i, margins: Vector4) -> Vector2:
	return Vector2(
		maxf(float(viewport_size.x) - margins.x - margins.z, 1.0),
		maxf(float(viewport_size.y) - margins.y - margins.w, 1.0)
	)
