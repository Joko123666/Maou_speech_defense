class_name UpgradePresentationService
extends RefCounted

var defense_stat_resolver := DefenseStatResolver.new()

func category_presentation(category: StringName) -> Dictionary:
	match category:
		&"formation_set": return {"badge": "[병력 세트]", "color": Color("39c9e8")}
		&"new_formation": return {"badge": "[%s 설치]" % ConceptService.term(&"formation"), "color": Color("39c9e8")}
		&"tower_type_level": return {"badge": "[%s 종류 강화]" % ConceptService.term(&"tower"), "color": Color("6f8cff")}
		&"tower_specialization_entry", &"core_specialization_entry", &"cursor_specialization_entry": return {"badge": "[특화 선택 열기]", "color": Color("c56cff")}
		&"guard_training": return {"badge": "[친위대 1단계 · 훈련]", "color": Color("f4cf62")}
		&"guard_specialization_entry": return {"badge": "[친위대 2단계 · 특화 선택]", "color": Color("c56cff")}
		&"guard_completion": return {"badge": "[친위대 3단계 · 완성]", "color": Color("ffe16b")}
		&"tower_branch", &"core_branch", &"cursor_branch": return {"badge": "[Lv.4 분기 선택]", "color": Color("df72ff")}
		&"guard_branch": return {"badge": "[친위대 특화 확정]", "color": Color("df72ff")}
		&"candidate_branch": return {"badge": "[후보 고유 특성]", "color": Color("ffe16b")}
		&"candidate_overgrowth": return {"badge": "[후보 초과성장 · 반복]", "color": Color("ffe16b")}
		&"retainer_overgrowth": return {"badge": "[심복 초과성장 · 반복]", "color": Color("8fe8ff")}
		&"core_level", &"cursor_level": return {"badge": "[%s/심복 강화]" % ConceptService.term(&"core"), "color": Color("62dc92")}
		&"status_upgrade": return {"badge": "[공통 상태이상]", "color": Color("ff8a65")}
		&"artifact": return {"badge": "[희귀 아티팩트 · 1칸]", "color": Color("ffd166")}
	return {"badge": "[공통 업그레이드]", "color": Color("62dc92")}

func tower_attack_style(behavior: StringName) -> String:
	match behavior:
		&"rapid": return "고속 단일 투사체"
		&"area": return "감쇠 폭발 포탄"
		&"pierce": return "대상 방향 관통 광선"
		&"slow": return "전 범위 냉기 오라"
		&"knockback": return "상시 회전 톱날"
		&"execute": return "저체력 단일 처형"
		&"mark": return "고체력 취약 표식"
		&"chain": return "마력 전도탑 전용 중계 빔"
		&"unique_single": return "왕실 방패검·넉백"
		&"unique_pierce": return "광신 추격창·직선 관통"
		&"unique_radial": return "심연 공명 전방위 파동"
		&"unique_random": return "망자 연속 출격"
	return str(behavior)

func tower_target_rule(rule: StringName) -> String:
	match rule:
		&"closest_core": return "%s에 가까운 난입자" % ConceptService.term(&"core")
		&"density": return "밀집도가 높은 지점"
		&"cursor_lane": return "%s 높이" % ConceptService.term(&"cursor")
		&"breach_pressure": return "돌파 압력이 높은 적"
		&"lowest_health": return "현재 체력이 낮은 적"
		&"highest_health": return "현재 체력이 높은 적"
		&"reward_value": return "보상 가치가 높은 적"
	return str(rule)

func choice_tower_id(choice: UpgradeData) -> StringName:
	if choice.category in [&"tower_type_level", &"tower_specialization_entry"]:
		return choice.data_id
	if choice.category == &"tower_branch":
		var branch := DataRegistry.get_tower_branch(choice.data_id)
		return branch.tower_id if branch != null else &""
	return &""

func is_formation_choice(choice: UpgradeData) -> bool:
	return choice != null and choice.category == &"new_formation"

func choice_impacts(choice: UpgradeData) -> Array[Dictionary]:
	match choice.category:
		&"artifact":
			var result: Array[Dictionary] = []
			for effect_value in choice.offer_metadata.get("effects", []) as Array:
				var effect := effect_value as Dictionary
				var target_group := StringName(effect.get("target_group", ""))
				var stat_key := StringName(effect.get("stat_key", ""))
				var axis_id := StringName(effect.get("axis_id", ""))
				var status_id := StringName(effect.get("status_id", ""))
				if target_group == &"status":
					result.append(_impact(CommonStatusCatalog.display_name(status_id), status_id, CommonStatusCatalog.color(status_id)))
				elif axis_id != &"":
					var axis := defense_stat_resolver.catalog.find_axis(axis_id) if defense_stat_resolver.catalog != null else null
					result.append(_impact(axis.display_name if axis != null else String(axis_id), axis.icon_key if axis != null else axis_id, axis.color if axis != null else Color("ffd166")))
				else:
					result.append(_artifact_target_impact(target_group, stat_key))
				if result.size() >= 3:
					break
			return result if not result.is_empty() else [_impact("아티팩트", &"global", Color("ffd166"))]
		&"candidate_overgrowth", &"retainer_overgrowth":
			var target_group := StringName(choice.offer_metadata.get("target_group", ""))
			var stat_key := StringName(choice.offer_metadata.get("stat_key", ""))
			var target_impact := _impact("후보" if target_group == &"candidate" else "심복", &"core" if target_group == &"candidate" else &"cursor", Color("ffe16b") if target_group == &"candidate" else Color("8fe8ff"))
			match stat_key:
				&"damage": return [target_impact, _impact("직접 피해", &"damage", Color("ff807d")), _impact("반복 수치", &"global", Color("62dc92"))]
				&"skill": return [target_impact, _impact("고유 기술", &"area", Color("d781ff")), _impact("반복 수치", &"global", Color("62dc92"))]
				&"action_speed": return [target_impact, _impact("행동속도", &"speed", Color("fff079")), _impact("반복 수치", &"global", Color("62dc92"))]
				&"movement": return [target_impact, _impact("이동속도", &"speed", Color("8fe8ff")), _impact("반복 수치", &"global", Color("62dc92"))]
				&"collection": return [target_impact, _impact("수집 범위", &"area", Color("7fe8df")), _impact("반복 수치", &"global", Color("62dc92"))]
		&"guard_training":
			return [_impact("친위대", &"tower", Color("f4cf62")), _impact("기초 능력", &"damage", Color("ff807d")), _impact("공속·사거리", &"speed", Color("fff079"))]
		&"guard_specialization_entry":
			return [_impact("친위대", &"tower", Color("f4cf62")), _impact("고유 특화", &"global", Color("df72ff")), _impact("3개 중 1개", &"mark", Color("c56cff"))]
		&"guard_branch", &"guard_completion":
			match choice.data_id:
				&"kasuha_guard_research":
					return [_impact("친위대", &"tower", Color("f4cf62")), _impact("공격·사거리", &"damage", Color("ff807d")), _impact("교체 첫타", &"speed", Color("fff079"))]
				&"kasuha_guard_erosion":
					return [_impact("친위대", &"tower", Color("f4cf62")), _impact("둔화 장판", &"area", Color("7fe8df")), _impact("지속 제어", &"control", Color("8fe8ff"))]
				&"kasuha_guard_obsession":
					return [_impact("친위대", &"tower", Color("f4cf62")), _impact("단일 고화력", &"damage", Color("ff807d")), _impact("범위 감소", &"mark", Color("c56cff"))]
				&"irelai_guard_fast_soul":
					return [_impact("친위대", &"tower", Color("f4cf62")), _impact("재가동 가속", &"speed", Color("fff079")), _impact("복귀 직후 속사", &"damage", Color("ff807d"))]
				&"irelai_guard_explosive_death":
					return [_impact("친위대", &"tower", Color("f4cf62")), _impact("비활성 폭발", &"area", Color("7fe8df")), _impact("재가동 지연", &"mark", Color("c56cff"))]
				&"irelai_guard_death_curse":
					return [_impact("친위대", &"tower", Color("f4cf62")), _impact("저주 I→III", &"mark", Color("c56cff")), _impact("사령 보장", &"global", Color("8df0ad"))]
				&"judaginda_guard_martyrdom":
					return [_impact("친위대", &"tower", Color("f4cf62")), _impact("순교 30스택", &"speed", Color("fff079")), _impact("처형 뒤 비활성", &"mark", Color("c56cff"))]
				&"judaginda_guard_sudden_death":
					return [_impact("친위대", &"tower", Color("f4cf62")), _impact("확률 즉사", &"damage", Color("ff807d")), _impact("공식 난입 제외", &"mark", Color("c56cff"))]
				&"judaginda_guard_reaper_ritual":
					return [_impact("친위대", &"tower", Color("f4cf62")), _impact("액티브 충전", &"global", Color("8df0ad")), _impact("내부 대기", &"speed", Color("fff079"))]
			return [_impact("친위대", &"tower", Color("f4cf62")), _impact("특화 기술", &"area", Color("7fe8df")), _impact("피해·제어", &"control", Color("f4d56b"))]
		&"core_specialization_entry":
			return [_impact(ConceptService.term(&"core"), &"core", Color("65e09e")), _impact("고유 특화", &"global", Color("df72ff")), _impact("하위 선택", &"mark", Color("c56cff"))]
		&"cursor_specialization_entry":
			return [_impact("심복", &"cursor", Color("8fe8ff")), _impact("고유 특화", &"global", Color("df72ff")), _impact("하위 선택", &"mark", Color("c56cff"))]
		&"core_branch", &"cursor_branch":
			var specialization := DataRegistry.get_specialization_branch(choice.data_id)
			if specialization != null:
				var specialization_impacts: Array[Dictionary] = []
				for impact_key in specialization.impact_keys:
					specialization_impacts.append(_specialization_impact(impact_key))
				return specialization_impacts
		&"core_level":
			if choice.description.contains("방호") or choice.description.contains("격벽"):
				return [_impact(ConceptService.term(&"core"), &"core", Color("65e09e")), _impact("내구", &"health", Color("65e09e")), _impact("돌파 방어", &"control", Color("8fe8ff"))]
			if choice.description.contains("동기화") or choice.description.contains("탄도"):
				return [_impact(ConceptService.term(&"core"), &"core", Color("65e09e")), _impact("전체 %s" % ConceptService.term(&"tower"), &"global", Color("6f8cff")), _impact("공속", &"speed", Color("8fe8ff"))]
			return [_impact(ConceptService.term(&"core"), &"core", Color("65e09e")), _impact("피해", &"damage", Color("ff807d")), _impact("스킬", &"area", Color("d781ff"))]
		&"cursor_level":
			var result := [_impact("심복", &"cursor", Color("8fe8ff"))]
			if choice.description.contains("이동속도"):
				result.append(_impact("이동속도", &"speed", Color("fff079")))
				result.append(_impact("전장 기동", &"control", Color("8fe8ff")))
			elif choice.description.contains("범위") or choice.description.contains("와류"):
				result.append(_impact("범위", &"area", Color("7fe8df")))
				result.append(_impact("넉백", &"control", Color("f4d56b")))
			elif choice.description.contains("주기") or choice.description.contains("연속"):
				result.append(_impact("공속", &"speed", Color("fff079")))
				result.append(_impact("넉백", &"control", Color("f4d56b")))
			else:
				result.append(_impact("피해", &"damage", Color("ff807d")))
			return result
		&"tower_branch":
			var branch := DataRegistry.get_tower_branch(choice.data_id)
			if branch != null:
				return _tower_branch_impacts(branch)
		&"tower_type_level":
			var axis_impacts: Array[Dictionary] = []
			for presentation in defense_stat_resolver.tower_axis_presentations(choice.data_id):
				axis_impacts.append(_impact(String(presentation.display_name), presentation.icon_key, presentation.color))
			return axis_impacts if not axis_impacts.is_empty() else [_impact("해당 %s" % ConceptService.term(&"tower"), &"tower", Color("6f8cff"))]
		&"tower_specialization_entry":
			return [_impact("해당 %s" % ConceptService.term(&"tower"), &"tower", Color("6f8cff")), _impact("Lv.4 특화", &"global", Color("df72ff")), _impact("하위 선택", &"mark", Color("c56cff"))]
		&"global_upgrade":
			return [_impact("전체 %s" % ConceptService.term(&"tower"), &"global", Color("62dc92")), _impact("피해", &"damage", Color("ff807d")), _impact("공속", &"speed", Color("8fe8ff"))]
		&"status_upgrade":
			match choice.data_id:
				&"poison": return [_impact("적용 공격", &"tower", Color("f2a84a")), _impact("독", &"poison", Color("72d66b")), _impact("공용 누적 지속 피해", &"damage", Color("72d66b"))]
				&"burn": return [_impact("적용 공격", &"tower", Color("f2a84a")), _impact("화상", &"burn", Color("ff8a4c")), _impact("공격 기반 지속 피해", &"damage", Color("ff807d"))]
				&"bleed": return [_impact("적용 공격", &"tower", Color("f2a84a")), _impact("출혈", &"bleed", Color("e84c65")), _impact("체력 기반 지속 피해", &"health", Color("e84c65"))]
				&"shock": return [_impact("적용 공격", &"tower", Color("f2a84a")), _impact("감전", &"shock", Color("78d7ff")), _impact("주변 전이", &"area", Color("78d7ff"))]
	return [_impact("강화", &"global", Color("62dc92"))]

func tower_icon_name(behavior: StringName) -> String:
	match behavior:
		&"rapid": return "속사"
		&"area": return "포격"
		&"pierce": return "관통"
		&"slow": return "둔화"
		&"knockback": return "톱날"
		&"execute": return "처형"
		&"mark": return "표식"
		&"chain": return "연쇄"
		&"unique_single": return "★공명탄"
		&"unique_pierce": return "★공명창"
		&"unique_radial": return "★공명파"
		&"unique_random": return "★망자출격"
	return str(behavior)

func _specialization_impact(key: StringName) -> Dictionary:
	match key:
		&"core": return _impact(ConceptService.term(&"core"), &"core", Color("65e09e"))
		&"cursor": return _impact(ConceptService.term(&"cursor"), &"cursor", Color("8fe8ff"))
		&"damage": return _impact("피해", &"damage", Color("ff807d"))
		&"speed": return _impact("공격속도", &"speed", Color("fff079"))
		&"area": return _impact("범위", &"area", Color("7fe8df"))
		&"control": return _impact("제어", &"control", Color("f4d56b"))
		&"health": return _impact("내구·재생", &"health", Color("65e09e"))
		&"mark": return _impact("취약 표식", &"mark", Color("d781ff"))
		&"experience": return _impact("경험치", &"experience", Color("ffd35a"))
		&"global": return _impact("%s %s" % [ConceptService.term(&"tower"), ConceptService.term(&"formation")], &"global", Color("6f8cff"))
	return _impact("특화", &"global", Color("df72ff"))

func _artifact_target_impact(target_group: StringName, stat_key: StringName) -> Dictionary:
	var target_label := {
		&"candidate": "후보",
		&"retainer": "심복",
		&"guard": "친위대",
		&"normal_defender": "일반 병력",
	}.get(target_group, "아티팩트") as String
	var icon := {
		&"damage": &"damage",
		&"skill": &"area",
		&"action_speed": &"speed",
		&"movement": &"speed",
		&"range": &"area",
	}.get(stat_key, &"global") as StringName
	var color := Color("ff807d") if stat_key == &"damage" else Color("ffd166")
	return _impact(target_label, icon, color)

func _tower_branch_impacts(branch: TowerBranchData) -> Array[Dictionary]:
	var keys: Array = branch.level_4_modifiers.keys()
	for key in branch.level_7_modifiers:
		if key not in keys:
			keys.append(key)
	var result: Array[Dictionary] = []
	for key in keys:
		var impact_key: StringName = StringName(key)
		match impact_key:
			&"damage", &"center_damage", &"ritual_hits", &"ritual_damage", &"missing_health", &"explosion", &"shrapnel", &"volley_shots", &"volley_damage", &"warcry_damage", &"power_shot_damage", &"explosion_damage", &"collateral_damage", &"summon_damage", &"fire_zone_burn_ratio", &"bone_shard_damage", &"lightning_damage": result.append(_specialization_impact(&"damage"))
			&"speed", &"warcry_interval", &"tactics_cycle", &"power_shot_hits", &"overheat_cycle": result.append(_specialization_impact(&"speed"))
			&"range", &"edge_damage", &"saw_fixed", &"saw_multiplier", &"saw_size", &"relay_return", &"relay_return_falloff", &"network_damage_per_relay", &"power_shot_width", &"explosion_radius", &"collateral_width", &"ricochet_count", &"summon_radius", &"summon_cap", &"fire_zone_duration", &"fire_zone_radius", &"bone_shard_count", &"bone_shard_range": result.append(_specialization_impact(&"area"))
			&"mark", &"spread_status", &"tactics_mark", &"mark_duration": result.append(_specialization_impact(&"mark"))
			&"push", &"stun", &"frost_stack", &"frost_stun", &"slow_multiplier", &"execute_stun", &"execute_stun_radius", &"execute_ratio", &"erosion_cycle", &"erosion_stun", &"hex_slow", &"overheat_duration": result.append(_specialization_impact(&"control"))
			&"bleed_power", &"tactics_bleed_ratio": result.append(_impact("출혈", &"bleed", Color("e84c65")))
			&"shock": result.append(_impact("감전", &"shock", Color("78d7ff")))
			&"experience_bonus": result.append(_specialization_impact(&"experience"))
			&"ricochet", &"ricochet_falloff": result.append(_specialization_impact(&"area"))
		if result.size() >= 3:
			break
	if result.is_empty():
		result.append(_specialization_impact(&"damage"))
	return result

func _impact(label: String, icon: StringName, color: Color) -> Dictionary:
	return {"label": label, "icon": icon, "color": color}
