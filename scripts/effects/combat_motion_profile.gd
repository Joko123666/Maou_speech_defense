class_name CombatMotionProfile
extends RefCounted

static func tower_pose(behavior: StringName, intensity: float, phase: float = 0.0) -> Dictionary:
	var amount := clampf(intensity, 0.0, 1.0)
	var idle := sin(phase) * 0.012
	var offset := Vector2(0.0, -idle * 22.0)
	var scale := Vector2.ONE * (1.0 + idle)
	var rotation := 0.0
	match behavior:
		&"rapid", &"unique_single":
			offset.x -= amount * 6.0
			scale *= Vector2(1.0 - amount * 0.09, 1.0 + amount * 0.08)
		&"area":
			offset.x -= amount * 4.0
			scale *= Vector2(1.0 - amount * 0.14, 1.0 + amount * 0.13)
			rotation = -amount * 0.045
		&"pierce", &"unique_pierce":
			offset.x -= amount * 7.0
			scale *= Vector2(1.0 - amount * 0.17, 1.0 + amount * 0.09)
		&"slow", &"unique_radial":
			scale *= Vector2.ONE * (1.0 + amount * 0.12)
			rotation = amount * 0.05
		&"knockback":
			scale *= Vector2(1.0 + amount * 0.08, 1.0 - amount * 0.06)
			rotation = amount * 0.16
		&"execute":
			offset.x -= amount * 5.0
			scale *= Vector2(1.0 - amount * 0.12, 1.0 + amount * 0.16)
			rotation = -amount * 0.08
		&"mark", &"chain", &"unique_random":
			offset.y -= amount * 3.0
			scale *= Vector2.ONE * (1.0 + amount * 0.09)
			rotation = sin(phase * 1.7) * amount * 0.07
	return {"offset": offset, "scale": scale, "rotation": rotation}

static func core_pose(motion_id: StringName, cast_progress: float, action_pulse: float, release_pulse: float, phase: float = 0.0) -> Dictionary:
	var cast := clampf(cast_progress, 0.0, 1.0)
	var action := clampf(action_pulse, 0.0, 1.0)
	var release := clampf(release_pulse, 0.0, 1.0)
	var breathing := sin(phase) * 0.009
	var offset := Vector2(0.0, -breathing * 26.0)
	var scale := Vector2.ONE * (1.0 + breathing)
	var rotation := 0.0
	if cast > 0.0:
		var anticipation := sin(cast * PI)
		match motion_id:
			&"beam":
				scale *= Vector2(0.94 + cast * 0.18, 1.08 - cast * 0.04)
				offset.x += cast * 4.0
			&"radial":
				scale *= Vector2.ONE * (1.0 + anticipation * 0.08 + cast * 0.05)
				rotation = cast * 0.08
			&"wall":
				scale *= Vector2(1.08 - cast * 0.03, 0.92 + cast * 0.2)
				offset.y -= anticipation * 4.0
			&"barrage":
				scale *= Vector2(1.0 + anticipation * 0.07, 1.0 - anticipation * 0.04)
				rotation = sin(cast * TAU * 2.0) * 0.035
			_:
				scale *= Vector2.ONE * (1.0 + anticipation * 0.05)
	elif action > 0.0:
		offset.x -= action * 4.0
		scale *= Vector2(1.0 - action * 0.06, 1.0 + action * 0.05)
	if release > 0.0:
		scale *= Vector2.ONE * (1.0 + release * 0.15)
		rotation += release * 0.055
	return {"offset": offset, "scale": scale, "rotation": rotation}
