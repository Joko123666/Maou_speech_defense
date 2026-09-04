class_name CodexService
extends RefCounted

var defense_stat_resolver := DefenseStatResolver.new()

const CATEGORY_ORDER: Array[StringName] = [&"core", &"cursor", &"tower", &"formation", &"enemy", &"terms"]
const RULE_CATALOG_PATH := "res://data/meta/codex_rules_v0_17.tres"

func get_categories() -> Array[Dictionary]:
	var enemy_label := "%s·공식 난입" % ConceptService.term(&"enemy") if ConceptService.get_election_campaign() != null else "%s·보스" % ConceptService.term(&"enemy")
	return [
		{"id": &"core", "label": ConceptService.term(&"core")},
		{"id": &"cursor", "label": ConceptService.term(&"cursor")},
		{"id": &"tower", "label": ConceptService.term(&"tower")},
		{"id": &"formation", "label": ConceptService.term(&"formation")},
		{"id": &"enemy", "label": enemy_label},
		{"id": &"terms", "label": "용어·규칙"},
	]

func get_entries(category: StringName) -> Array[Dictionary]:
	match category:
		&"core": return _core_entries()
		&"cursor": return _cursor_entries()
		&"tower": return _tower_entries()
		&"formation": return _formation_entries()
		&"enemy": return _enemy_entries()
		&"terms": return _terms_entries()
	return []

func get_discovered_count(category: StringName) -> int:
	return get_entries(category).filter(func(entry: Dictionary) -> bool: return entry.state == &"discovered").size()

func _core_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var campaign := ConceptService.get_election_campaign()
	for core in DataRegistry.cores:
		var discovered := SaveManager.legacy_full_unlock or String(core.id) in SaveManager.unlocked_ids
		var candidate := campaign.candidate_for_core(core.id) if campaign != null else null
		var faction := campaign.faction(candidate.faction_id) if campaign != null and candidate != null else null
		var related := _candidate_growth_names(candidate) if candidate != null else _specialization_names(&"core", core.id)
		var stats: Array[String] = [
			"공격 방식 · %s" % _attack_name(core.attack_type),
			"기본 피해 · %.0f   공격 간격 · %.2f초" % [core.damage, core.attack_interval],
			"내구도 · %.0f   재생 · %.2f/초" % [core.max_health, core.regeneration],
			"액티브 · %s   피해 · %.0f   시전 · %.2f초" % [_core_skill_name(core), core.skill_damage, core.skill_cast_seconds],
		]
		if candidate != null:
			stats.push_front("팩션 · %s" % (faction.display_name if faction != null else String(candidate.faction_id)))
			if faction != null:
				stats.push_front("문양 · %s" % faction.marker_display_name())
			var support := SaveManager.get_candidate_support(candidate.id)
			var elected := SaveManager.is_candidate_elected(candidate.id)
			stats.append("현재 지지도 · %d / %d" % [support, candidate.support_required_for_election])
			stats.append("승격 상태 · %s" % ("마왕 당선" if elected else "선거 진행"))
			if elected:
				var approval := SaveManager.get_governance_approval(candidate.id)
				var reaction := campaign.governance_reaction(approval)
				stats.append("통치 지지율 · %d%s" % [approval, " · %s" % reaction.display_name if reaction != null else ""])
			if not candidate.campaign_slogan.is_empty():
				related.push_front("선거 공약 · “%s”" % candidate.campaign_slogan)
		var unique_formation := DataRegistry.find_formation(core.unique_formation_id)
		var unique_tower := DataRegistry.find_tower(core.unique_tower_id)
		if unique_formation != null:
			related.push_front("전용 %s · %s" % [ConceptService.term(&"formation"), unique_formation.display_name])
		if unique_tower != null:
			related.push_front("유니크 %s · %s" % [ConceptService.term(&"tower"), unique_tower.display_name])
		var entry := _entry(
			&"core", core.id,
			candidate.full_name if candidate != null else core.display_name,
			candidate.title if candidate != null else "방어 %s" % ConceptService.term(&"core"),
			candidate.description if candidate != null else core.description,
			discovered,
			stats,
			related,
			"%s 해금 업적 또는 콘텐츠 보상으로 공개됩니다." % ConceptService.term(&"core"),
			ConceptService.content_texture(&"candidates", candidate.id) if candidate != null else core.texture,
			faction.primary_color if faction != null else core.color
		)
		if faction != null:
			entry["faction_emblem_id"] = String(faction.emblem_id)
			entry["faction_marker_style"] = String(faction.active_marker_style())
		result.append(entry)
	return result

func _cursor_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var campaign := ConceptService.get_election_campaign()
	for cursor in DataRegistry.cursors:
		var discovered := SaveManager.legacy_full_unlock or String(cursor.id) in SaveManager.unlocked_ids
		var retainer := campaign.retainer_for_cursor(cursor.id) if campaign != null else null
		var stats: Array[String] = [
			"공격 방식 · %s" % _attack_name(cursor.attack_type),
			"기본 피해 · %.0f   공격 간격 · %.2f초" % [cursor.damage, cursor.attack_interval],
			"공격 반경 · %.0f   넉백 · %.0f" % [cursor.attack_radius, cursor.knockback],
			"이동속도 · %.0f   수집 반경 · %.0f" % [cursor.movement_speed, cursor.collection_radius],
			"경험치 배율 · ×%.2f" % cursor.experience_multiplier,
		]
		if retainer != null:
			var preferred := campaign.candidate(retainer.preferred_candidate_id)
			stats.append("선호 후보 · %s · 조합 보너스 없음" % (preferred.full_name if preferred != null else String(retainer.preferred_candidate_id)))
		result.append(_entry(
			&"cursor", cursor.id,
			retainer.full_name if retainer != null else cursor.display_name,
			retainer.title if retainer != null else "전장 %s" % ConceptService.term(&"cursor"),
			retainer.description if retainer != null else cursor.description,
			discovered,
			stats,
			_specialization_names(&"cursor", cursor.id),
			"%s 해금 업적 또는 콘텐츠 보상으로 공개됩니다." % ConceptService.term(&"cursor"),
			ConceptService.content_texture(&"retainers", retainer.id) if retainer != null else cursor.texture,
			cursor.color
		))
	return result

func _tower_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var campaign := ConceptService.get_election_campaign()
	for tower in DataRegistry.towers:
		var discovered := SaveManager.legacy_full_unlock or String(tower.id) in SaveManager.unlocked_tower_ids or (tower.is_unique() and String(tower.unique_core_id) in SaveManager.unlocked_ids)
		var stats: Array[String] = [
			"공격 역할 · %s   대상 규칙 · %s" % [_behavior_name(tower.behavior), _target_name(tower.target_rule)],
			"기본 피해 · %.0f   공격 간격 · %.2f초" % [tower.damage, tower.attack_interval],
			"사거리 · %.1f칸   편대 기대값 · %.0f" % [tower.attack_range_cells, tower.formation_power_rating],
		]
		var origin_name := _tower_origin_name(tower, campaign)
		var technology_name := tower.technology_name
		if technology_name.is_empty():
			technology_name = "후보 전속 친위대 전술" if tower.is_unique() else "공용 전투 기술"
		stats.append("출신 · %s   기술 · %s" % [origin_name, technology_name])
		if tower.area_radius > 0.0:
			stats.append("효과 반경 · %.0f" % tower.area_radius)
		if tower.status_power > 0.0:
			stats.append("제어 위력 · %.0f" % tower.status_power)
		var related := _tower_formations(tower.id)
		related.append_array(_tower_branch_names(tower.id))
		var tower_faction: ElectionFactionData
		if tower.is_unique() and campaign != null:
			var tower_candidate := campaign.candidate_for_core(tower.unique_core_id)
			tower_faction = campaign.faction(tower_candidate.faction_id) if tower_candidate != null else null
		var entry := _entry(
			&"tower", tower.id, tower.display_name, "%s 전용 유니크 %s" % [DataRegistry.get_core(tower.unique_core_id).display_name, ConceptService.term(&"tower")] if tower.is_unique() else "전투 %s" % ConceptService.term(&"tower"), tower.description, discovered,
			stats, related, _tower_unlock_hint(tower), tower.texture, tower_faction.primary_color if tower_faction != null else tower.color
		)
		if tower_faction != null:
			entry["faction_emblem_id"] = String(tower_faction.emblem_id)
			entry["faction_marker_style"] = String(tower_faction.active_marker_style())
		entry["stat_axes"] = defense_stat_resolver.tower_axis_presentations(tower.id)
		result.append(entry)
	return result

func _tower_origin_name(tower: TowerData, campaign: ElectionCampaignData) -> String:
	var faction_id := tower.origin_faction_id
	if faction_id == &"" and tower.is_unique() and campaign != null:
		var candidate := campaign.candidate_for_core(tower.unique_core_id)
		if candidate != null:
			faction_id = candidate.faction_id
	if faction_id != &"" and campaign != null:
		var faction := campaign.faction(faction_id)
		if faction != null:
			return faction.display_name
		return String(faction_id)
	return "선거관리위원회 등록 용병·임대 장비" if campaign != null else "공용 계약 병력·장비"

func _formation_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for formation in DataRegistry.formations:
		if &"reinforcement" in formation.role_tags:
			continue
		var discovered := SaveManager.legacy_full_unlock or _formation_owned(formation)
		var recipe: Array[String] = []
		var color := Color("65d9bd")
		for formation_cell in formation.cells:
			if formation_cell == null:
				continue
			var tower := DataRegistry.get_tower(formation_cell.tower_id)
			recipe.append("(%d,%d) %s" % [formation_cell.offset.x + 1, formation_cell.offset.y + 1, tower.display_name])
			if recipe.size() == 1:
				color = tower.color
		result.append(_entry(
			&"formation", formation.id, formation.display_name, "%s %s" % [ConceptService.term(&"tower"), ConceptService.term(&"formation")], formation.description, discovered,
			[
				"배치 · %s" % " / ".join(recipe),
				"형태 · %s   병종 · %d종   배치 난도 · %s" % [formation.get_shape_display_name(), formation.get_distinct_tower_count(), formation.get_placement_difficulty_display_name()],
				"블록 %d칸   희귀도 %d   상하 반전 %s" % [formation.cells.size(), formation.rarity, "가능" if formation.can_vertical_flip else "불가"],
				"기초 편성점수 · %d" % formation.formation_score,
			],
			_role_names(formation.role_tags), _formation_unlock_hint(formation), null, color
		))
	return result

func _enemy_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var campaign := ConceptService.get_election_campaign()
	var election_campaign_active := campaign != null
	for enemy in DataRegistry.get_all_enemy_data():
		var discovered := SaveManager.legacy_full_unlock or String(enemy.id) in SaveManager.encountered_enemy_ids
		var faction_profile := DataRegistry.get_enemy_spawn_profile(enemy.id)
		var faction_enemy := faction_profile != null and faction_profile.is_faction_enemy
		var subtitle := ("공식 난입 · 단계 %d" if election_campaign_active else "보스 · Tier %d") % enemy.boss_tier if enemy.is_boss else (("팩션 예고 난입자" if faction_enemy else "일반 난입자") if election_campaign_active else ("팩션 적" if faction_enemy else "일반 적"))
		var stats: Array[String] = [
			"행동 · %s" % _behavior_name(enemy.behavior),
			"체력 · %.0f   이동속도 · %.0f" % [enemy.max_health, enemy.move_speed],
			"%s 피해 · %.0f   방어 · %.0f   경험치 · %.0f" % [ConceptService.term(&"core"), enemy.core_damage, enemy.armor, enemy.experience_value],
		]
		if faction_profile != null:
			stats.append("스폰 비용 · %.0f   편성 · %d~%d기" % [faction_profile.spawn_cost, faction_profile.group_min, faction_profile.group_max])
		if enemy.knockback_resistance > 0.0 or enemy.status_resistance > 0.0:
			stats.append("넉백 저항 · %d%%   상태 저항 · %d%%" % [roundi(enemy.knockback_resistance * 100.0), roundi(enemy.status_resistance * 100.0)])
		var encounter := "해당 진영 Faction Prelude에서만 조우" if faction_enemy else ("스테이지 시작 직후 조우" if enemy.available_from_seconds <= 0.0 else "%d:%02d 이후 조우" % [floori(enemy.available_from_seconds) / 60, floori(enemy.available_from_seconds) % 60])
		var related: Array[String] = [encounter, "특수행동 · %s" % _enemy_special_action(enemy.behavior), "정상 대응 · %s" % _enemy_response(enemy.behavior)]
		if faction_profile != null:
			for role in faction_profile.role_tags:
				related.append("역할 · %s" % _enemy_role_name(role))
		var faction := campaign.faction_for_boss(enemy.id) if campaign != null and enemy.is_boss else (campaign.faction(faction_profile.faction_id) if campaign != null and faction_enemy else null)
		if faction_enemy:
			if faction != null:
				related.push_front("소속 · %s" % faction.display_name)
		var entry := _entry(
			&"enemy", enemy.id, enemy.display_name, subtitle, "%s을 향해 진입하는 %s 유형입니다." % [ConceptService.term(&"core"), _behavior_name(enemy.behavior)], discovered,
			stats, related, "%s하면 상세 정보가 공개됩니다." % encounter, enemy.texture, faction.primary_color if faction != null else enemy.body_color
		)
		if faction != null:
			entry["faction_emblem_id"] = String(faction.emblem_id)
			entry["faction_marker_style"] = String(faction.active_marker_style())
			entry.related.push_front("문양 · %s" % faction.marker_display_name())
		result.append(entry)
	return result

func _terms_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var catalog := load(RULE_CATALOG_PATH) as CodexRuleCatalogData
	if catalog == null:
		return result
	for rule in catalog.entries:
		if rule == null:
			continue
		result.append(_entry(
			&"terms", rule.id, rule.display_name, rule.subtitle, rule.description, true,
			_rule_stats(rule), rule.related_lines.duplicate(), "도감 기본 규칙 항목입니다.", null, rule.accent_color, rule.icon_key
		))
	return result

func _rule_stats(rule: CodexRuleEntryData) -> Array[String]:
	var stats: Array[String] = rule.stat_lines.duplicate()
	var resolver_text := String(rule.resolver_id)
	if resolver_text.begins_with("status:"):
		var status_id := StringName(resolver_text.trim_prefix("status:"))
		stats.append("기본 · %s" % CommonStatusCatalog.profile_text(status_id, CommonStatusCatalog.profile_at_level(status_id, 0)))
		stats.append("최종 성장 · %s" % CommonStatusCatalog.profile_text(status_id, CommonStatusCatalog.profile_at_level(status_id, 7)))
	elif rule.resolver_id == &"control_resistance":
		var profile := ControlResistanceProfileData.new()
		stats.append("재적용 회복 · 넉백 %.2f초 / 둔화 %.2f초 / 공포 %.2f초 / 기절 %.2f초 / 환혹 %.2f초" % [profile.recovery_for(&"knockback"), profile.recovery_for(&"slow"), profile.recovery_for(&"fear"), profile.recovery_for(&"stun"), profile.recovery_for(&"charm")])
		stats.append("효과 최소 비율 · 강도 %d%% / 지속시간 %d%%" % [roundi(profile.minimum_effect_ratio * 100.0), roundi(profile.minimum_duration_ratio * 100.0)])
	elif rule.resolver_id == &"formation_score":
		var scores: Array[int] = []
		for formation in DataRegistry.formations:
			if formation != null and &"reinforcement" not in formation.role_tags:
				scores.append(formation.formation_score)
		if not scores.is_empty():
			stats.append("등록 편대 범위 · %d~%d점" % [scores.min(), scores.max()])
			stats.append("계산 · 포함 병력 formation_power_rating의 합")
	elif rule.resolver_id == &"faction_prelude":
		var stage := ConceptService.get_default_stage()
		if stage != null:
			var active: Array[FactionPreludeData] = []
			for prelude in stage.faction_preludes:
				if prelude != null and prelude.duration > 0.0:
					active.append(prelude)
			if not active.is_empty():
				stats.append("표준 스테이지 · %d개 구간 / 각 %d초" % [active.size(), roundi(active[0].duration)])
				stats.append("공격대 예산 대체 · %d~%d%%" % [roundi(active[0].faction_budget_ratio_min * 100.0), roundi(active.back().faction_budget_ratio_max * 100.0)])
	return stats

func _entry(category: StringName, id: StringName, title: String, subtitle: String, description: String, discovered: bool, stats: Array[String], related: Array[String], hint: String, texture: Texture2D, color: Color, icon_key: StringName = &"") -> Dictionary:
	var state: StringName = &"discovered" if discovered else (&"dev" if MetaProgressionService.is_lock_bypassed() else &"locked")
	return {
		"key": "%s:%s" % [String(category), String(id)],
		"category": category,
		"id": id,
		"title": title,
		"subtitle": subtitle,
		"description": description,
		"state": state,
		"revealed": state != &"locked",
		"stats": stats,
		"related": related,
		"unlock_hint": hint,
		"texture": texture,
		"icon_key": icon_key,
		"color": color,
		"stat_axes": [],
	}

func _formation_owned(formation: TowerFormationData) -> bool:
	if formation.is_unique():
		return String(formation.unique_core_id) in SaveManager.unlocked_ids
	for tower_id in formation.get_tower_ids():
		if tower_id != &"" and String(tower_id) not in SaveManager.unlocked_tower_ids:
			return false
	return true

func _product_unlock_hint(product_type: StringName, content_id: StringName) -> String:
	for product in MetaProgressionService.get_shop_products():
		if product.product_type == product_type and product.content_id == content_id:
			var achievement := MetaProgressionService.get_achievement(product.discovery_achievement_id)
			if achievement != null:
				return "상점에서 구매하면 공개됩니다. 연관 업적 · %s" % achievement.display_name
	return "기본 보유 콘텐츠입니다."

func _formation_unlock_hint(formation: TowerFormationData) -> String:
	if formation.is_unique():
		return "%s 선택 시 전투 중 한 번 설치할 수 있습니다." % DataRegistry.get_core(formation.unique_core_id).display_name
	var missing: Array[String] = []
	for tower_id in formation.get_tower_ids():
		if tower_id != &"" and String(tower_id) not in SaveManager.unlocked_tower_ids:
			var name := DataRegistry.get_tower(tower_id).display_name
			if name not in missing:
				missing.append(name)
	return "필요 수비병력 확보 · %s" % ", ".join(missing) if not missing.is_empty() else "포함 수비병력을 모두 보유하면 공개됩니다."

func _tower_unlock_hint(tower: TowerData) -> String:
	if tower.is_unique():
		return "%s의 런당 1회 전용 편대에 포함됩니다." % DataRegistry.get_core(tower.unique_core_id).display_name
	return _product_unlock_hint(&"tower", tower.id)

func _tower_formations(tower_id: StringName) -> Array[String]:
	var result: Array[String] = []
	for formation in DataRegistry.formations:
		if &"reinforcement" in formation.role_tags:
			continue
		if tower_id in formation.get_tower_ids():
			result.append("편대 · %s" % formation.display_name)
	return result

func _tower_branch_names(tower_id: StringName) -> Array[String]:
	var result: Array[String] = []
	for branch in DataRegistry.get_tower_branches(tower_id):
		result.append("Lv.4 특화 · %s" % branch.display_name)
	return result

func _candidate_growth_names(candidate: CandidateProfileData) -> Array[String]:
	var result: Array[String] = []
	if candidate == null or candidate.growth_data == null:
		return result
	if candidate.growth_data.first_upgrade != null:
		result.append("2:30 강화 · %s" % candidate.growth_data.first_upgrade.display_name)
	for branch in candidate.growth_data.branch_upgrades:
		if branch != null:
			result.append("5:00 후보 특화 · %s" % branch.display_name)
	if candidate.growth_data.final_upgrade != null:
		result.append("7:30 강화 · %s" % candidate.growth_data.final_upgrade.display_name)
	if candidate.guard_growth_data != null:
		for specialization in candidate.guard_growth_data.specializations:
			if specialization != null:
				result.append("친위대 특화 · %s" % specialization.display_name)
	return result

func _specialization_names(kind: StringName, owner_id: StringName) -> Array[String]:
	var result: Array[String] = []
	for branch in DataRegistry.get_specialization_branches(kind, owner_id):
		result.append("Lv.4 특화 · %s" % branch.display_name)
	return result

func _role_names(tags: Array[StringName]) -> Array[String]:
	var result: Array[String] = []
	for tag in tags:
		result.append("역할 · %s" % String(tag))
	return result

func _attack_name(id: StringName) -> String:
	return {&"single": "단일", &"pierce": "관통", &"radial": "방사", &"random": "무작위", &"area": "범위", &"zone": "장판", &"heavy": "중공격"}.get(id, String(id))

func _skill_name(id: StringName) -> String:
	return {&"beam": "전방 공약포", &"radial": "광역 유세파", &"wall": "진군 저지선", &"barrage": "사령 군단"}.get(id, String(id))

func _core_skill_name(core: CoreData) -> String:
	if core == null:
		return ""
	return CandidateCoreSkillPolicy.new().title_for(
		core,
		CandidateCoreSkillPolicy.new().build_plan(core, {}, ConceptService.get_election_campaign() != null, true),
		ConceptService.term(&"core")
	)

func _behavior_name(id: StringName) -> String:
	return {
		&"rapid": "속사", &"area": "범위 포격", &"pierce": "직선 관통", &"slow": "둔화 오라", &"knockback": "회전 톱날",
		&"execute": "처형", &"mark": "취약 표식", &"chain": "연쇄 빔", &"normal": "직진", &"fast": "고속",
		&"unique_single": "왕실 방패검", &"unique_pierce": "광신 추격창", &"unique_radial": "심연 공명파", &"unique_random": "망자 연속 출격",
		&"swarm": "물량", &"armored": "중장갑", &"splitter": "분열", &"support": "지원", &"shifter": "행 이동",
		&"cleanser": "상태 해제", &"disruptor": "교란", &"ranged": "원거리", &"shielded": "방패", &"regenerator": "재생",
		&"charger": "돌진", &"phase": "위상", &"sapper": "공병", &"guardian": "수호", &"zigzag": "지그재그 도약",
		&"taunter": "수비병력 유인", &"fixed_diagonal": "고정 사선", &"on_hit_speed": "피격 가속", &"death_disable": "사망 마비", &"heavy_resist": "부분 제어 저항", &"boss_enrage": "격노", &"boss_disrupt": "전선 교란", &"boss_summon": "군단 소환", &"boss_final": "최종 압박",
		&"faction_frontline": "강화 전열", &"killer_disable": "결정타 마비", &"self_decay": "자가 체력 감소", &"formation_charge": "대열 돌격", &"group_death_speed": "동료 사망 가속",
	}.get(id, String(id))

func _enemy_special_action(behavior: StringName) -> String:
	return {
		&"normal": "다수 편성으로 직진",
		&"fast": "빠른 속도로 빈틈 압박",
		&"fixed_diagonal": "생성 시 정한 사선 경로 유지",
		&"armored": "높은 방어와 전열 유지",
		&"on_hit_speed": "피격 때마다 일시 가속, 최대 5중첩",
		&"death_disable": "퇴장 시 주변 일반 수비병력 일시 마비",
		&"heavy_resist": "둔화·공포·기절에 부분 저항",
		&"faction_frontline": "대열 선두에서 후속 병력 보호",
		&"killer_disable": "결정타를 가한 일반 수비병력 마비",
		&"self_decay": "높은 체력을 지녔지만 스스로 체력 감소",
		&"formation_charge": "여러 대열이 시간차 돌격",
		&"group_death_speed": "같은 무리의 동료 퇴장 시 일시 가속",
	}.get(behavior, _behavior_name(behavior))

func _enemy_response(behavior: StringName) -> String:
	return {
		&"normal": "범위 화력 또는 빠른 전열 정리",
		&"fast": "전방 집중 화력 또는 둔화",
		&"fixed_diagonal": "예고된 경로에 병력 배치 또는 심복 재배치",
		&"armored": "고화력 단일 공격 또는 지속 피해",
		&"on_hit_speed": "큰 단발 피해 또는 제어로 교전 시간 단축",
		&"death_disable": "수비병력을 분산하고 안전 거리에서 마무리",
		&"heavy_resist": "직접 화력과 여러 약한 제어를 병행",
		&"faction_frontline": "관통·범위 화력으로 후열과 함께 압박",
		&"killer_disable": "친위대·심복 마무리 또는 핵심 병력 외 공격원 분산",
		&"self_decay": "제어로 지연하거나 집중 화력으로 조기 제거",
		&"formation_charge": "대열 경로를 읽고 범위 제어·심복 이동",
		&"group_death_speed": "무리를 동시에 정리하거나 가속 대상을 우선 제어",
	}.get(behavior, "직접 화력, 제어, 심복 재배치 중 둘 이상을 조합")

func _enemy_role_name(role: StringName) -> String:
	return {
		&"basic": "기본", &"swarm": "물량", &"fast": "고속", &"diagonal": "사선",
		&"frontline": "전열", &"on_hit_speed": "피격 가속", &"disable": "비활성화",
		&"heavy": "중장", &"cc_resist": "제어 저항", &"faction": "팩션 전용",
		&"decay": "자가 감소", &"pack": "무리", &"death_buff": "동료 퇴장 강화",
	}.get(role, String(role))

func _target_name(id: StringName) -> String:
	return {&"closest_tower": "수비병력 근접", &"density": "밀집 지점", &"closest_core": "후보 근접", &"breach_pressure": "연설대 돌파 압력", &"lowest_health": "최저 체력", &"highest_health": "최고 체력", &"reward_value": "보상 가치"}.get(id, String(id))

func _status_name(id: StringName) -> String:
	return {&"poison": "독", &"burn": "화상", &"bleed": "출혈", &"shock": "감전"}.get(id, String(id))
