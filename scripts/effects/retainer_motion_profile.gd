class_name RetainerMotionProfile
extends RefCounted

static func pose(cursor_id: StringName, moving: float, move_direction: Vector2, attack: float, state: StringName = &"ready", state_progress: float = 1.0, phase: float = 0.0) -> Dictionary:
	var move := clampf(moving, 0.0, 1.0)
	var strike := clampf(attack, 0.0, 1.0)
	var progress := clampf(state_progress, 0.0, 1.0)
	var direction := move_direction.normalized() if move_direction.length_squared() > 0.001 else Vector2.ZERO
	var gait := sin(phase * 2.0)
	var breathing := sin(phase) * 0.008
	var offset := Vector2(0.0, -breathing * 20.0)
	var scale := Vector2.ONE * (1.0 + breathing)
	var rotation := 0.0
	var alpha := 1.0
	match cursor_id:
		&"iron":
			offset += direction * move * 3.5
			rotation = direction.y * move * 0.055
			scale *= Vector2(1.0 + move * 0.035, 1.0 - move * 0.025)
			offset.x -= strike * 4.0
			scale *= Vector2(1.0 - strike * 0.08, 1.0 + strike * 0.09)
		&"silver":
			offset += direction * move * 2.5 + Vector2(0.0, -absf(gait) * move * 2.4)
			rotation = gait * move * 0.035
			scale *= Vector2.ONE * (1.0 + strike * 0.1)
			rotation += strike * 0.06
		&"gold":
			offset += direction * move * 2.0
			scale *= Vector2(1.0 + move * 0.055, 1.0 - move * 0.045)
			offset.x -= strike * 3.0
			scale *= Vector2(1.0 - strike * 0.13, 1.0 + strike * 0.12)
		&"platinum":
			offset += direction * move * 4.5
			rotation = direction.y * move * 0.075
			offset.x += strike * 5.0
			scale *= Vector2(1.0 + strike * 0.15, 1.0 - strike * 0.08)
		&"vanguard":
			offset += direction * move * 3.0 + Vector2(0.0, gait * move * 1.8)
			rotation = gait * move * 0.045
			offset.x += strike * 3.5
			scale *= Vector2(1.0 + strike * 0.08, 1.0 - strike * 0.11)
			rotation -= strike * 0.09
		_:
			offset += direction * move * 2.5
			offset.x -= strike * 3.0
			scale *= Vector2(1.0 - strike * 0.06, 1.0 + strike * 0.06)
	if state == &"reconstructing":
		var assemble := smoothstep(0.0, 1.0, progress)
		scale *= Vector2(0.78 + assemble * 0.22, 0.68 + assemble * 0.32)
		offset.y += (1.0 - assemble) * 7.0
		rotation += sin(progress * PI * 3.0) * (1.0 - assemble) * 0.16
		alpha = 0.34 + assemble * 0.66
	return {"offset": offset, "scale": scale, "rotation": rotation, "alpha": alpha}
