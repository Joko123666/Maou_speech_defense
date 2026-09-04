class_name CommonStatusCatalog
extends RefCounted

const STATUS_IDS: Array[StringName] = [&"poison", &"bleed", &"shock", &"burn"]

static func profile_at_level(status_id: StringName, level: int) -> Dictionary:
	var safe_level := clampi(level, 0, 7)
	match status_id:
		&"poison":
			var damage_per_second := [6.0, 8.0, 10.0, 12.0, 16.0, 19.0, 22.0, 28.0]
			var poison_stack_limits := [3, 3, 3, 4, 5, 5, 6, 7]
			var durations := [7.0, 7.5, 8.0, 8.5, 10.0, 10.5, 11.0, 13.0]
			return {
				"level": safe_level,
				"damage_per_second": damage_per_second[safe_level],
				"max_stacks": poison_stack_limits[safe_level],
				"duration": durations[safe_level],
			}
		&"burn":
			var damage_ratios := [0.05, 0.08, 0.10, 0.12, 0.16, 0.18, 0.20, 0.26]
			var burn_stack_limits := [1, 1, 1, 2, 2, 2, 3, 4]
			var durations := [4.0, 4.0, 4.25, 4.5, 5.0, 5.0, 5.5, 6.0]
			return {
				"level": safe_level,
				"damage_ratio": damage_ratios[safe_level],
				"max_stacks": burn_stack_limits[safe_level],
				"duration": durations[safe_level],
				"minimum_decay_ratio": 0.25,
				"reset_decay_on_reapply": true,
			}
		&"bleed":
			var health_ratios := [0.0030, 0.0035, 0.0040, 0.0045, 0.0055, 0.0060, 0.0065, 0.0080]
			var bleed_stack_limits := [2, 2, 2, 3, 3, 3, 4, 5]
			var damage_caps := [72.0, 96.0, 120.0, 144.0, 200.0, 240.0, 280.0, 360.0]
			return {
				"level": safe_level,
				"health_ratio": health_ratios[safe_level],
				"max_stacks": bleed_stack_limits[safe_level],
				"damage_cap": damage_caps[safe_level],
				"duration": 4.5,
				"stack_scope": &"source_type",
			}
		&"shock":
			var damage_values := [5.0, 10.0, 13.0, 16.0, 22.0, 26.0, 30.0, 42.0]
			var shock_stack_limits := [3, 3, 3, 3, 4, 4, 4, 5]
			var transfer_counts := [1, 1, 2, 2, 3, 3, 4, 5]
			var radii := [145.0, 165.0, 175.0, 185.0, 210.0, 220.0, 235.0, 270.0]
			return {
				"level": safe_level,
				"damage": damage_values[safe_level],
				"max_stacks": shock_stack_limits[safe_level],
				"transfers": transfer_counts[safe_level],
				"radius": radii[safe_level],
				"duration": 4.0,
				"transfer_decay": 0.70,
			}
	return {}

## v0.13 밸런스 비교·세이브 감사용 읽기 전용 기준선이다. 런타임 적용에는
## profile_at_level()을 사용하며 이 프로필은 과거 수치를 재현할 때만 조회한다.
static func legacy_v010_profile_at_level(status_id: StringName, level: int) -> Dictionary:
	var safe_level := clampi(level, 0, 7)
	match status_id:
		&"burn":
			var profile := profile_at_level(status_id, safe_level)
			profile.max_stacks = [1, 2, 3, 3, 4, 5, 6, 8][safe_level]
			profile.erase("minimum_decay_ratio")
			profile.erase("reset_decay_on_reapply")
			profile.legacy_profile = &"legacy_v010"
			return profile
		&"bleed":
			var profile := profile_at_level(status_id, safe_level)
			profile.max_stacks = [3, 4, 5, 6, 8, 9, 10, 12][safe_level]
			profile.stack_scope = &"global_independent"
			profile.legacy_profile = &"legacy_v010"
			return profile
		&"shock":
			var profile := profile_at_level(status_id, safe_level)
			profile.legacy_profile = &"legacy_v010"
			return profile
	return {}

static func tower_supports(tower: TowerData, status_id: StringName) -> bool:
	return StatusSourceRegistry.tower_is_source(tower, status_id)

static func branch_supports(modifiers: Dictionary, status_id: StringName) -> bool:
	return StatusSourceRegistry.branch_is_source(modifiers, status_id)

static func tower_applies_on_hit(tower: TowerData, status_id: StringName) -> bool:
	return StatusSourceRegistry.tower_applies_on_hit(tower, status_id)

static func branch_applies_on_hit(modifiers: Dictionary, status_id: StringName) -> bool:
	return StatusSourceRegistry.branch_applies_on_hit(modifiers, status_id)

static func display_name(status_id: StringName) -> String:
	match status_id:
		&"poison": return "독"
		&"burn": return "화상"
		&"bleed": return "출혈"
		&"shock": return "감전"
	return "상태이상"

static func color(status_id: StringName) -> Color:
	match status_id:
		&"poison": return Color("72d66b")
		&"burn": return Color("ff8a4c")
		&"bleed": return Color("e84c65")
		&"shock": return Color("78d7ff")
	return Color.WHITE

static func profile_text(status_id: StringName, profile: Dictionary) -> String:
	match status_id:
		&"poison":
			return "초당 %.0f / 공용 %d중첩 / %.1f초" % [float(profile.damage_per_second), int(profile.max_stacks), float(profile.duration)]
		&"burn":
			return "초기 공격 피해 %.0f%% / 공용 %d중첩 / %.1f초 감쇠" % [float(profile.damage_ratio) * 100.0, int(profile.max_stacks), float(profile.duration)]
		&"bleed":
			return "최대 체력 %.2f%% / 소스별 %d중첩 / 상한 %.0f" % [float(profile.health_ratio) * 100.0, int(profile.max_stacks), float(profile.damage_cap)]
		&"shock":
			return "중첩 피해 %.0f / %d중첩 / %d회 전이" % [float(profile.damage), int(profile.max_stacks), int(profile.transfers)]
	return "효과 없음"
