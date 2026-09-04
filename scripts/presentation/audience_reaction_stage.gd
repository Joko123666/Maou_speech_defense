class_name AudienceReactionStage
extends Node2D

const THREAT_CLEAR := 0
const THREAT_WARNING := 1
const THREAT_DANGER := 2
const GALLERY_HORIZONTAL_MARGIN := Vector2(150.0, 70.0)
const GALLERY_HEIGHT := 75.0
const CROWD_HEIGHT := 69.0
const REACTION_COLORS := {
	&"skill_cast": Color("f2c85b"),
	&"skill_release": Color("fff0a8"),
	&"boss_warning": Color("d86cff"),
	&"breach": Color("ff5366"),
	&"boss_defeated": Color("ffd76a"),
	&"victory": Color("ffe39a"),
	&"defeat": Color("8d789c"),
}

@export var crowd_texture: Texture2D

var faction_color := Color("d8ae48")
var threat_level: int = THREAT_CLEAR
var reduced_motion_enabled: bool = false
var reaction_kind: StringName = &""
var reaction_color := Color.WHITE
var reaction_strength: float = 0.0
var reaction_remaining: float = 0.0
var reaction_duration: float = 0.0
var animation_time: float = 0.0

func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	queue_redraw()

func configure(primary_color: Color, reduced_motion: bool = false) -> void:
	faction_color = primary_color
	set_reduced_motion_enabled(reduced_motion)
	queue_redraw()

func set_reduced_motion_enabled(enabled: bool) -> void:
	reduced_motion_enabled = enabled
	if enabled:
		animation_time = 0.0
	queue_redraw()

func set_threat_level(level: int) -> void:
	var safe_level := clampi(level, THREAT_CLEAR, THREAT_DANGER)
	if safe_level == threat_level:
		return
	threat_level = safe_level
	queue_redraw()

func react(kind: StringName, color: Color = Color.WHITE, strength: float = 1.0, duration: float = 1.2) -> void:
	reaction_kind = kind
	reaction_color = color if color != Color.WHITE else REACTION_COLORS.get(kind, faction_color)
	reaction_strength = clampf(strength, 0.0, 1.0)
	reaction_duration = maxf(duration, 0.05)
	reaction_remaining = reaction_duration
	queue_redraw()

func clear_reaction() -> void:
	reaction_kind = &""
	reaction_strength = 0.0
	reaction_remaining = 0.0
	reaction_duration = 0.0
	queue_redraw()

func get_presentation_state() -> Dictionary:
	return {
		"reaction": reaction_kind,
		"threat_level": threat_level,
		"reduced_motion": reduced_motion_enabled,
		"gallery_rect": _gallery_rect(),
		"has_crowd_texture": crowd_texture != null,
	}

func _process(delta: float) -> void:
	animation_time += delta
	if reaction_remaining > 0.0:
		reaction_remaining = maxf(reaction_remaining - delta, 0.0)
		if is_zero_approx(reaction_remaining):
			reaction_kind = &""
			reaction_strength = 0.0
	queue_redraw()

func _draw() -> void:
	var gallery := _gallery_rect()
	if gallery.size.x <= 0.0 or gallery.size.y <= 0.0:
		return
	var visual_kind := _visual_kind()
	var visual_color := _visual_color(visual_kind)
	var energy := _visual_energy(visual_kind)
	_draw_gallery_glow(gallery, visual_color, energy)
	_draw_crowd(gallery, visual_kind, visual_color, energy)
	_draw_foreground_railing(gallery, visual_color, energy)
	_draw_reaction_marks(gallery, visual_kind, visual_color, energy)

func _gallery_rect() -> Rect2:
	var viewport_size := get_viewport_rect().size
	return Rect2(
		Vector2(GALLERY_HORIZONTAL_MARGIN.x, maxf(viewport_size.y - GALLERY_HEIGHT, 0.0)),
		Vector2(maxf(viewport_size.x - GALLERY_HORIZONTAL_MARGIN.x - GALLERY_HORIZONTAL_MARGIN.y, 0.0), minf(GALLERY_HEIGHT, viewport_size.y))
	)

func _visual_kind() -> StringName:
	if reaction_remaining > 0.0 and reaction_kind != &"":
		return reaction_kind
	if threat_level >= THREAT_DANGER:
		return &"danger"
	if threat_level >= THREAT_WARNING:
		return &"warning"
	return &"idle"

func _visual_color(kind: StringName) -> Color:
	match kind:
		&"danger", &"breach", &"defeat":
			return Color("ff5366") if kind != &"defeat" else Color("8d789c")
		&"warning":
			return Color("f39b54")
		&"boss_warning":
			return Color("d86cff")
		&"skill_cast", &"skill_release", &"boss_defeated", &"victory":
			return reaction_color
		_:
			return faction_color

func _visual_energy(kind: StringName) -> float:
	match kind:
		&"idle":
			return 0.16
		&"warning":
			return 0.48
		&"danger":
			return 0.82
		_:
			return maxf(reaction_strength, 0.62)

func _draw_gallery_glow(gallery: Rect2, color: Color, energy: float) -> void:
	var pulse := 0.5 if reduced_motion_enabled else 0.5 + sin(animation_time * 4.0) * 0.5
	var glow_alpha := 0.025 + energy * (0.035 + pulse * 0.035)
	draw_rect(gallery, Color(color, glow_alpha), true)
	draw_line(gallery.position, Vector2(gallery.end.x, gallery.position.y), Color(color, 0.16 + energy * 0.22), 2.0, true)

func _draw_crowd(gallery: Rect2, kind: StringName, color: Color, energy: float) -> void:
	if crowd_texture == null:
		return
	var texture_size := crowd_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var base_scale := minf(gallery.size.x * 0.92 / texture_size.x, CROWD_HEIGHT / texture_size.y)
	var reaction_scale := 1.0
	var motion_offset := Vector2.ZERO
	if not reduced_motion_enabled:
		match kind:
			&"idle":
				motion_offset.y = sin(animation_time * 2.2) * 1.1
			&"warning":
				motion_offset.y = sin(animation_time * 5.0) * 1.8
			&"danger", &"breach":
				motion_offset = Vector2(sin(animation_time * 17.0), sin(animation_time * 12.0)) * (1.5 + energy * 1.8)
			&"skill_cast":
				motion_offset.y = -absf(sin(animation_time * 7.0)) * 3.0
			&"skill_release", &"boss_defeated", &"victory":
				var progress := 1.0 - reaction_remaining / maxf(reaction_duration, 0.05)
				motion_offset.y = -absf(sin(progress * PI * 3.0)) * (4.0 + energy * 5.0)
				reaction_scale = 1.0 + absf(sin(progress * PI * 2.0)) * 0.035
			&"boss_warning":
				motion_offset.x = sin(animation_time * 8.0) * 2.2
	var size := texture_size * base_scale * reaction_scale
	var position := Vector2(gallery.get_center().x - size.x * 0.5, gallery.end.y - size.y - 4.0) + motion_offset
	var tint := Color.WHITE.lerp(color, 0.10 + energy * 0.16)
	if kind == &"defeat":
		tint = Color("a99caf")
	draw_texture_rect(crowd_texture, Rect2(position, size), false, Color(tint, 0.86 + energy * 0.14))

func _draw_foreground_railing(gallery: Rect2, color: Color, energy: float) -> void:
	var rail_y := gallery.end.y - 10.0
	draw_rect(Rect2(Vector2(gallery.position.x, rail_y), Vector2(gallery.size.x, 10.0)), Color("170f20", 0.94), true)
	draw_line(Vector2(gallery.position.x, rail_y), Vector2(gallery.end.x, rail_y), Color("d8ae48").lerp(color, energy * 0.24), 3.0, true)
	for post_index in 13:
		var x := gallery.position.x + gallery.size.x * float(post_index) / 12.0
		draw_rect(Rect2(Vector2(x - 2.0, rail_y - 6.0), Vector2(4.0, 16.0)), Color("2a1a35", 0.96), true)
		draw_circle(Vector2(x, rail_y - 6.0), 3.0, Color("d8ae48", 0.9))

func _draw_reaction_marks(gallery: Rect2, kind: StringName, color: Color, energy: float) -> void:
	if reduced_motion_enabled:
		return
	if kind in [&"skill_release", &"boss_defeated", &"victory"]:
		for beam_index in 6:
			var beam_x := gallery.position.x + gallery.size.x * (float(beam_index) + 0.5) / 6.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(beam_x - 28.0, gallery.end.y - 8.0),
				Vector2(beam_x - 3.0, gallery.position.y + 4.0),
				Vector2(beam_x + 3.0, gallery.position.y + 4.0),
				Vector2(beam_x + 28.0, gallery.end.y - 8.0),
			]), Color(color, 0.045 + energy * 0.055))
		for mark_index in 12:
			var phase := fmod(animation_time * (0.7 + float(mark_index % 3) * 0.15) + float(mark_index) * 0.113, 1.0)
			var x := gallery.position.x + 36.0 + fmod(float(mark_index) * 83.0, maxf(gallery.size.x - 72.0, 1.0))
			var y := gallery.end.y - 18.0 - phase * 48.0
			var radius := 3.0 + float(mark_index % 2)
			var mark_color := color.lerp(Color("fff0a8"), float(mark_index % 3) * 0.22)
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, y - radius), Vector2(x + radius, y),
				Vector2(x, y + radius), Vector2(x - radius, y)
			]), Color(mark_color, (1.0 - phase) * energy))
	elif kind in [&"danger", &"breach", &"boss_warning"]:
		for mark_index in 5:
			var x := gallery.position.x + gallery.size.x * (float(mark_index) + 0.5) / 5.0
			var bob := sin(animation_time * 8.0 + float(mark_index)) * 2.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(x, gallery.position.y + 7.0 + bob),
				Vector2(x - 6.0, gallery.position.y + 18.0 + bob),
				Vector2(x + 6.0, gallery.position.y + 18.0 + bob)
			]), Color(color, 0.28 + energy * 0.34))

func _on_viewport_size_changed() -> void:
	queue_redraw()
