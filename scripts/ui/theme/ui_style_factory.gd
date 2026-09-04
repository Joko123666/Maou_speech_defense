class_name UiStyleFactory
extends RefCounted

static func panel(
	background: Color = UiTokens.SURFACE_PARCHMENT,
	border: Color = UiTokens.INK_ROYAL,
	radius: int = UiTokens.RADIUS_CARD,
	border_width: int = 2,
	content_margin: float = float(UiTokens.SPACE_4)
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(content_margin)
	return style

static func button(accent: Color = UiTokens.INK_ROYAL, selected: bool = false, destructive: bool = false) -> Dictionary:
	var semantic_accent := UiTokens.DANGER if destructive else accent
	var normal_background := UiTokens.SURFACE_PARCHMENT_MUTED.lerp(semantic_accent, 0.08)
	var normal := panel(normal_background, Color(semantic_accent, 0.78), UiTokens.RADIUS_SMALL, 2, float(UiTokens.SPACE_3))
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = UiTokens.SURFACE_PARCHMENT.lerp(semantic_accent, 0.16)
	hover.border_color = semantic_accent
	hover.set_border_width_all(3)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = UiTokens.SURFACE_PARCHMENT_MUTED.lerp(semantic_accent, 0.28)
	pressed.border_color = semantic_accent.darkened(0.12)
	pressed.set_border_width_all(3)
	var focus := hover.duplicate() as StyleBoxFlat
	focus.border_color = UiTokens.FOCUS_RING
	focus.set_border_width_all(3)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = UiTokens.SURFACE_PARCHMENT_MUTED.darkened(0.08)
	disabled.border_color = Color(UiTokens.DISABLED_INK, 0.66)
	if selected:
		normal.bg_color = UiTokens.SURFACE_PARCHMENT.lerp(semantic_accent, 0.2)
		normal.border_color = semantic_accent
		normal.set_border_width_all(3)
	return {
		"normal": normal,
		"hover": hover,
		"pressed": pressed,
		"focus": focus,
		"disabled": disabled,
		"font_color": UiTokens.INK_ROYAL,
		"font_disabled_color": UiTokens.DISABLED_INK,
	}

static func card(accent: Color, selected: bool = false) -> Dictionary:
	var styles := button(accent, selected)
	for key in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		var style := styles[key] as StyleBoxFlat
		style.set_corner_radius_all(UiTokens.RADIUS_CARD)
		style.set_content_margin_all(float(UiTokens.SPACE_4))
	return styles

static func tag(accent: Color = UiTokens.INK_ROYAL) -> StyleBoxFlat:
	return panel(UiTokens.SURFACE_PARCHMENT_MUTED.lerp(accent, 0.12), Color(accent, 0.82), UiTokens.RADIUS_SMALL, 1, float(UiTokens.SPACE_2))

static func apply_button(target: Button, accent: Color = UiTokens.INK_ROYAL, selected: bool = false, destructive: bool = false) -> void:
	var styles := button(accent, selected, destructive)
	target.custom_minimum_size.y = maxf(target.custom_minimum_size.y, UiTokens.TOUCH_TARGET_MIN)
	target.focus_mode = Control.FOCUS_ALL
	for key in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		target.add_theme_stylebox_override(StringName(key), styles[key] as StyleBox)
	target.add_theme_color_override(&"font_color", styles.font_color)
	target.add_theme_color_override(&"font_hover_color", UiTokens.INK_DEEP)
	target.add_theme_color_override(&"font_pressed_color", UiTokens.INK_DEEP)
	target.add_theme_color_override(&"font_focus_color", UiTokens.INK_DEEP)
	target.add_theme_color_override(&"font_disabled_color", styles.font_disabled_color)
	target.add_theme_font_size_override(&"font_size", UiTokens.FONT_BODY)

static func hud_button(accent: Color = UiTokens.ACCENT_GOLD, selected: bool = false) -> Dictionary:
	var normal := panel(Color(UiTokens.INK_DEEP, 0.92), Color(accent, 0.82), UiTokens.RADIUS_SMALL, 2, float(UiTokens.SPACE_3))
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = UiTokens.INK_ROYAL.lightened(0.08)
	hover.border_color = accent
	hover.set_border_width_all(3)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = UiTokens.INK_ROYAL.lightened(0.16)
	pressed.border_color = accent.darkened(0.1)
	pressed.set_border_width_all(3)
	var focus := hover.duplicate() as StyleBoxFlat
	focus.border_color = UiTokens.FOCUS_RING
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color = Color(UiTokens.INK_DEEP, 0.72)
	disabled.border_color = Color(UiTokens.DISABLED_INK, 0.58)
	if selected:
		normal.bg_color = UiTokens.INK_ROYAL.lightened(0.12)
		normal.border_color = accent
		normal.set_border_width_all(3)
	return {
		"normal": normal,
		"hover": hover,
		"pressed": pressed,
		"focus": focus,
		"disabled": disabled,
		"font_color": UiTokens.SURFACE_PARCHMENT,
		"font_disabled_color": UiTokens.DISABLED_INK,
	}

static func apply_hud_button(target: Button, accent: Color = UiTokens.ACCENT_GOLD, selected: bool = false) -> void:
	var styles := hud_button(accent, selected)
	target.custom_minimum_size.y = maxf(target.custom_minimum_size.y, UiTokens.TOUCH_TARGET_MIN)
	target.focus_mode = Control.FOCUS_ALL
	for key in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		target.add_theme_stylebox_override(StringName(key), styles[key] as StyleBox)
	target.add_theme_color_override(&"font_color", styles.font_color)
	target.add_theme_color_override(&"font_hover_color", Color.WHITE)
	target.add_theme_color_override(&"font_pressed_color", Color.WHITE)
	target.add_theme_color_override(&"font_focus_color", Color.WHITE)
	target.add_theme_color_override(&"font_disabled_color", styles.font_disabled_color)
	target.add_theme_font_size_override(&"font_size", UiTokens.FONT_BODY)
