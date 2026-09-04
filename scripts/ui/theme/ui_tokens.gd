class_name UiTokens
extends RefCounted

const TOUCH_TARGET_MIN := 48.0
const PRIMARY_ACTION_HEIGHT := 56.0
const TAG_HEIGHT := 32.0

const SPACE_1 := 4
const SPACE_2 := 8
const SPACE_3 := 12
const SPACE_4 := 16
const SPACE_6 := 24
const SPACE_8 := 32

const FONT_CAPTION := 13
const FONT_BODY := 16
const FONT_CARD_TITLE := 22
const FONT_PAGE_TITLE := 32

const RADIUS_SMALL := 8
const RADIUS_CARD := 14
const RADIUS_MODAL := 18

const MOTION_FAST := 0.16
const MOTION_STANDARD := 0.22
const MOTION_CARD_REVEAL := 0.28

const SURFACE_PARCHMENT := Color("f3e6cf")
const SURFACE_PARCHMENT_MUTED := Color("e4d2b5")
const INK_ROYAL := Color("39234f")
const INK_DEEP := Color("20162e")
const INK_MUTED := Color("6f6079")
const ACCENT_GOLD := Color("d8ae48")
const ACCENT_GOLD_TEXT := Color("865716")
const AXIS_POWER := Color("d95353")
const AXIS_SPEED := Color("43a867")
const AXIS_RANGE := Color("3f82c8")
const FACTION_ALLY := Color("4f8fc9")
const FACTION_RETAINER := Color("4aa66c")
const FACTION_BOSS := Color("8b59bd")
const FACTION_ENEMY := Color("c84d59")
const FOCUS_RING := Color("f4cc63")
const DISABLED_INK := Color("8f8296")
const DANGER := Color("c84655")

static func semantic_color(role: StringName, fallback: Color = INK_ROYAL) -> Color:
	match role:
		&"parchment": return SURFACE_PARCHMENT
		&"parchment_muted": return SURFACE_PARCHMENT_MUTED
		&"ink": return INK_ROYAL
		&"ink_deep": return INK_DEEP
		&"gold": return ACCENT_GOLD
		&"gold_text": return ACCENT_GOLD_TEXT
		&"power": return AXIS_POWER
		&"speed": return AXIS_SPEED
		&"range": return AXIS_RANGE
		&"ally": return FACTION_ALLY
		&"retainer": return FACTION_RETAINER
		&"boss": return FACTION_BOSS
		&"enemy": return FACTION_ENEMY
		&"danger": return DANGER
		_: return fallback

static func is_touch_target(size: Vector2) -> bool:
	return size.x >= TOUCH_TARGET_MIN and size.y >= TOUCH_TARGET_MIN

static func contrast_ratio(foreground: Color, background: Color) -> float:
	var lighter := maxf(_relative_luminance(foreground), _relative_luminance(background))
	var darker := minf(_relative_luminance(foreground), _relative_luminance(background))
	return (lighter + 0.05) / (darker + 0.05)

static func _relative_luminance(color: Color) -> float:
	return 0.2126 * _linear_channel(color.r) + 0.7152 * _linear_channel(color.g) + 0.0722 * _linear_channel(color.b)

static func _linear_channel(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)
