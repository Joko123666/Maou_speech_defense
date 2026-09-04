class_name TowerHitPresentationProfile
extends RefCounted

const DEFAULT_RADIUS := 24.0
const BEHAVIOR_RADII := {
	&"rapid": 20.0,
	&"area": 36.0,
	&"pierce": 30.0,
	&"slow": 32.0,
	&"knockback": 38.0,
	&"execute": 44.0,
	&"mark": 31.0,
	&"chain": 27.0,
	&"unique_single": 30.0,
	&"unique_pierce": 34.0,
	&"unique_radial": 40.0,
	&"unique_random": 32.0,
}

static func build(tower: TowerData, target_maximum_health: float, damage: float, strength_scale: float = 1.0) -> Dictionary:
	if tower == null:
		return {}
	var target_health := maxf(target_maximum_health, 1.0)
	var damage_ratio := clampf(damage / maxf(target_health * 0.14, 1.0), 0.0, 1.0)
	return {
		"behavior": tower.behavior,
		"color": tower.color,
		"strength": clampf((0.24 + damage_ratio * 0.5) * strength_scale, 0.14, 0.9),
		"radius": float(BEHAVIOR_RADII.get(tower.behavior, DEFAULT_RADIUS)),
	}
