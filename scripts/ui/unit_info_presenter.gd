class_name UnitInfoPresenter
extends RefCounted

const SCHEMA_VERSION := 1

func present(
	selection: Dictionary,
	core: DefenseCore,
	loadout: LoadoutManager,
	battlefield: Battlefield,
	tower_damage_resolver: Callable = Callable()
) -> Dictionary:
	if int(selection.get("schema_version", 0)) != SCHEMA_VERSION:
		return {}
	match selection.get("kind", &"") as StringName:
		&"core":
			return _present_core(selection, core, loadout, battlefield)
		&"tower":
			return _present_tower(selection, loadout, battlefield, tower_damage_resolver)
	return {}

func _present_core(selection: Dictionary, core: DefenseCore, loadout: LoadoutManager, battlefield: Battlefield) -> Dictionary:
	if not is_instance_valid(core) or core.data == null or not core.active or core.data.id != (selection.get("stable_id", &"") as StringName):
		return {}
	var campaign := ConceptService.get_election_campaign()
	var candidate := campaign.candidate_for_core(core.data.id) if campaign != null else null
	var faction := campaign.faction(candidate.faction_id) if campaign != null and candidate != null else null
	var attack_range := float(selection.get("range_pixels", core.data.attack_range))
	var range_cells := attack_range / maxf(battlefield.get_column_spacing(), 1.0) if battlefield != null else 0.0
	var attack_interval := core.data.attack_interval / maxf(core.attack_speed_multiplier, 0.01)
	var status_text := "시전 중 · %.1f초" % core.skill_cast_remaining if core.is_skill_casting() else "전투 가능"
	var texture := ConceptService.optional_content_texture(&"candidates", candidate.id) if candidate != null else null
	if texture == null:
		texture = core.data.texture if core.data.texture != null else ConceptService.fallback_texture(&"cores")
	var faction_name := faction.display_name if faction != null else (String(candidate.faction_id) if candidate != null else "독립 후보")
	var title := candidate.full_name if candidate != null else core.data.display_name
	var subtitle := candidate.title if candidate != null else "방어 후보"
	var detail_lines: Array[String] = []
	if candidate != null and not candidate.campaign_slogan.is_empty():
		detail_lines.append("공약 · %s" % candidate.campaign_slogan)
	if not core.data.description.is_empty():
		detail_lines.append(core.data.description)
	return {
		"schema_version": SCHEMA_VERSION,
		"kind": &"core",
		"stable_id": core.data.id,
		"title": title,
		"subtitle": subtitle,
		"faction_label": "팩션 · %s" % faction_name,
		"role_tags": ["후보", "핵 방어"],
		"status_label": status_text,
		"status_role": &"danger" if core.current_health / maxf(core.max_health, 1.0) < 0.3 else &"ally",
		"health_current": core.current_health,
		"health_maximum": core.max_health,
		"stats": [
			{"label": "현재 체력", "value": "%.0f / %.0f" % [core.current_health, core.max_health], "role": &"ally"},
			{"label": "공격 피해", "value": "%.1f" % (core.data.damage * core.damage_multiplier), "role": &"power"},
			{"label": "공격 간격", "value": "%.2f초" % attack_interval, "role": &"speed"},
			{"label": "공격 범위", "value": "%.2f칸" % range_cells, "role": &"range"},
			{"label": "액티브 충전", "value": "%.1f / %.1f초" % [core.skill_charge, core.data.skill_charge_seconds], "role": &"gold"},
		],
		"detail_lines": detail_lines,
		"texture": texture,
		"accent": faction.primary_color if faction != null else core.data.color,
		"world_position": selection.get("world_position", core.global_position) as Vector2,
		"range_pixels": attack_range,
		"pinned": bool(selection.get("pinned", false)),
	}

func _present_tower(selection: Dictionary, loadout: LoadoutManager, battlefield: Battlefield, tower_damage_resolver: Callable) -> Dictionary:
	if loadout == null:
		return {}
	var column := _find_column(loadout, int(selection.get("column_index", -1)))
	var row_index := int(selection.get("row_index", -1))
	if not is_instance_valid(column) or row_index < 0 or row_index >= column.row_towers.size():
		return {}
	var tower := column.get_tower_data(row_index)
	if tower == null or tower.id != (selection.get("stable_id", &"") as StringName):
		return {}
	var damage := column.get_damage(row_index) * loadout.get_axis_independent_tower_damage_multiplier()
	if tower_damage_resolver.is_valid():
		damage = float(tower_damage_resolver.call(column, row_index))
	var attack_range := column.get_attack_range(row_index)
	var range_cells := attack_range / maxf(battlefield.get_column_spacing(), 1.0) if battlefield != null else tower.attack_range_cells
	var level := column.get_tower_level(tower.id)
	var branch := column.get_tower_branch(tower.id)
	var status_text := "행동 불능" if column.is_row_disabled(row_index) else "정상 작동"
	var campaign := ConceptService.get_election_campaign()
	var origin_name := _tower_origin_name(tower, campaign)
	var role_tags: Array[String] = ["친위대" if column.is_guard_formation else "일반 수비", _behavior_name(tower.behavior)]
	var detail_lines: Array[String] = [
		"출신 · %s" % origin_name,
		"기술 · %s" % (tower.technology_name if not tower.technology_name.is_empty() else ("후보 전속 전술" if tower.is_unique() else "공용 전투 기술")),
	]
	if branch != null:
		detail_lines.append("특화 · %s%s" % [branch.display_name, " · 완성" if column.is_tower_final(tower.id) else ""])
	if not tower.description.is_empty():
		detail_lines.append(tower.description)
	var texture := tower.texture if tower.texture != null else ConceptService.fallback_texture(&"towers")
	return {
		"schema_version": SCHEMA_VERSION,
		"kind": &"tower",
		"stable_id": tower.id,
		"title": tower.display_name,
		"subtitle": "%s · Lv.%d" % ["친위대" if column.is_guard_formation else "배치 병력", level],
		"faction_label": "소속 · %s" % origin_name,
		"role_tags": role_tags,
		"status_label": status_text,
		"status_role": &"danger" if column.is_row_disabled(row_index) else &"ally",
		"stats": [
			{"label": "공격 피해", "value": "%.1f" % damage, "role": &"power"},
			{"label": "공격 간격", "value": "%.2f초" % column.get_attack_interval(row_index), "role": &"speed"},
			{"label": "공격 범위", "value": "%.2f칸" % range_cells, "role": &"range"},
			{"label": "배치 위치", "value": "%d열 · %d행" % [column.column_index + 1, row_index + 1], "role": &"gold"},
		],
		"detail_lines": detail_lines,
		"texture": texture,
		"accent": tower.color,
		"world_position": selection.get("world_position", column.get_attack_origin(row_index)) as Vector2,
		"range_pixels": attack_range,
		"pinned": bool(selection.get("pinned", false)),
	}

func _find_column(loadout: LoadoutManager, column_index: int) -> TowerColumn:
	for column in loadout.columns:
		if is_instance_valid(column) and column.column_index == column_index:
			return column
	return null

func _tower_origin_name(tower: TowerData, campaign: ElectionCampaignData) -> String:
	var faction_id := tower.origin_faction_id
	if faction_id == &"" and tower.is_unique() and campaign != null:
		var candidate := campaign.candidate_for_core(tower.unique_core_id)
		if candidate != null:
			faction_id = candidate.faction_id
	if faction_id != &"" and campaign != null:
		var faction := campaign.faction(faction_id)
		return faction.display_name if faction != null else String(faction_id)
	return "선거관리위원회 등록 병력" if campaign != null else "공용 계약 병력"

func _behavior_name(behavior: StringName) -> String:
	return {
		&"rapid": "속사",
		&"area": "광역",
		&"pierce": "관통",
		&"slow": "감속",
		&"knockback": "밀쳐내기",
		&"execute": "처형",
		&"mark": "표식",
		&"chain": "전도",
		&"golem": "기동 제어",
		&"unique_single": "후보 전속",
		&"unique_pierce": "후보 관통",
		&"unique_radial": "후보 광역",
		&"unique_random": "후보 변칙",
	}.get(behavior, "전투 지원")
