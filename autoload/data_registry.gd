extends Node

var cores: Array[CoreData] = []
var cursors: Array[CursorData] = []
var towers: Array[TowerData] = []
var formations: Array[TowerFormationData] = []
var tower_branches: Array[TowerBranchData] = []
var specialization_branches: Array[SpecializationBranchData] = []
var enemies: Array[EnemyData] = []
var faction_enemies: Array[EnemyData] = []
var bosses: Array[EnemyData] = []
var enemy_spawn_profiles: Array[EnemySpawnProfileData] = []
var using_external_content_pack: bool = false
var combat_pace_applied: bool = false

const FORMATION_TARGET_POWER := 300.0
const UNIQUE_FORMATION_TARGET_POWER := 360.0
const TOWER_FORMATION_POWER := {
	&"rapid": 80.0,
	&"area": 120.0,
	&"pierce": 100.0,
	&"slow": 100.0,
	&"knockback": 80.0,
	&"execute": 140.0,
	&"mark": 90.0,
	&"chain": 90.0,
	&"rubber_golem": 70.0,
	&"emerald_guardian": 200.0,
	&"sapphire_lance": 220.0,
	&"amethyst_nova": 220.0,
	&"jade_roulette": 200.0,
	&"obsidian_verdict": 220.0,
	&"obsidian_inquisitor": 180.0,
}
const TOWER_PROJECTILE_TEXTURE_IDS := {
	&"rapid": &"goblin_javelin",
	&"area": &"skeleton_grenade",
	&"emerald_guardian": &"royal_slash",
	&"obsidian_verdict": &"judgment_bolt",
	&"obsidian_inquisitor": &"judgment_bolt",
}

const NORMAL_DEFENDER_IDS: Array[StringName] = [
	&"rapid", &"area", &"pierce", &"slow", &"knockback", &"execute", &"mark", &"chain", &"rubber_golem",
]

func _ready() -> void:
	var content_pack := ConceptService.get_content_pack()
	if content_pack != null:
		if content_pack.is_playable(ConceptService.get_default_stage(), ConceptService.get_stage_reward()):
			_load_content_pack(content_pack)
			using_external_content_pack = true
		else:
			push_warning("Configured concept content pack is incomplete; built-in catalog will be used: %s" % ", ".join(content_pack.get_validation_errors(ConceptService.get_default_stage(), ConceptService.get_stage_reward())))
	if not using_external_content_pack:
		_build_cores()
		_build_cursors()
		_build_towers()
		_build_formations()
		_build_tower_branches()
		_build_specialization_branches()
		_build_enemies()
		_build_enemy_spawn_profiles()
		_build_bosses()
	_apply_combat_pace()
	var campaign_errors := validate_campaign(ConceptService.get_election_campaign())
	if not campaign_errors.is_empty():
		push_warning("Configured election campaign is incompatible with the active combat catalogs: %s" % ", ".join(campaign_errors))

func _load_content_pack(pack: ContentPackData) -> void:
	# Content-pack resources are authoring sources. Runtime pace adjustment and
	# gameplay state must never mutate the loaded .tres instances in place.
	cores.assign(_runtime_resource_copies(pack.cores))
	cursors.assign(_runtime_resource_copies(pack.cursors))
	towers.assign(_runtime_resource_copies(pack.towers))
	formations.assign(_runtime_resource_copies(pack.formations))
	tower_branches.assign(_runtime_resource_copies(pack.tower_branches))
	specialization_branches.assign(_runtime_resource_copies(pack.specialization_branches))
	var loaded_enemies: Array[EnemyData] = []
	loaded_enemies.assign(_runtime_resource_copies(pack.enemies))
	enemies.clear()
	faction_enemies.clear()
	bosses.assign(_runtime_resource_copies(pack.bosses))
	if pack.enemy_spawn_profiles.is_empty():
		enemy_spawn_profiles.clear()
		for enemy in loaded_enemies:
			var profile := EnemySpawnProfileData.from_enemy_data(enemy)
			if profile != null:
				enemy_spawn_profiles.append(profile)
	else:
		enemy_spawn_profiles.assign(_runtime_resource_copies(pack.enemy_spawn_profiles))
	var profiles_by_id: Dictionary = {}
	for profile in enemy_spawn_profiles:
		if profile != null:
			profiles_by_id[profile.enemy_id] = profile
	for enemy in loaded_enemies:
		var profile := profiles_by_id.get(enemy.id) as EnemySpawnProfileData
		if profile != null and profile.is_faction_enemy:
			faction_enemies.append(enemy)
		else:
			enemies.append(enemy)

func _runtime_resource_copies(source: Array) -> Array:
	var result: Array = []
	result.resize(source.size())
	for index in source.size():
		var item := source[index] as Resource
		result[index] = item.duplicate(true) if item != null else null
	return result

func _apply_combat_pace() -> void:
	if combat_pace_applied:
		return
	for core in cores:
		core.damage = CombatPace.attack_damage(core.damage)
		core.attack_interval = CombatPace.attack_interval(core.attack_interval)
	for cursor in cursors:
		cursor.damage = CombatPace.attack_damage(cursor.damage)
		cursor.attack_interval = CombatPace.attack_interval(cursor.attack_interval)
		cursor.movement_speed = CombatPace.movement_speed(cursor.movement_speed)
	for tower in towers:
		tower.damage = CombatPace.attack_damage(tower.damage)
		tower.attack_interval = CombatPace.attack_interval(tower.attack_interval)
	for enemy in enemies + faction_enemies + bosses:
		enemy.move_speed = CombatPace.enemy_movement_speed(enemy.move_speed)
	for boss in bosses:
		boss.core_damage = CombatPace.attack_damage(boss.core_damage)
	for branch in tower_branches:
		_apply_pace_to_tower_branch_modifiers(branch.level_4_modifiers)
		_apply_pace_to_tower_branch_modifiers(branch.level_7_modifiers)
	combat_pace_applied = true

func _apply_pace_to_tower_branch_modifiers(modifiers: Dictionary) -> void:
	if modifiers.has("summon_damage"):
		modifiers.summon_damage = CombatPace.attack_damage(float(modifiers.summon_damage))
	if modifiers.has("summon_interval"):
		modifiers.summon_interval = CombatPace.attack_interval(float(modifiers.summon_interval))

func validate_campaign(campaign: ElectionCampaignData) -> PackedStringArray:
	if campaign == null:
		return PackedStringArray()
	var enemy_ids := _catalog_ids(enemies + faction_enemies)
	for profile in enemy_spawn_profiles:
		if profile != null:
			enemy_ids[profile.enemy_id] = true
	return campaign.get_validation_errors(
		_catalog_ids(cores),
		_catalog_ids(cursors),
		enemy_ids,
		_catalog_ids(bosses)
	)

func catalog_ids(items: Array) -> Dictionary:
	return _catalog_ids(items)

func _catalog_ids(items: Array) -> Dictionary:
	var result: Dictionary = {}
	for item in items:
		if item != null:
			var item_id := StringName((item as Resource).get("id"))
			if item_id != &"":
				result[item_id] = true
	return result

func get_core(id: StringName) -> CoreData:
	return find_core(id)

func get_core_or_default(id: StringName) -> CoreData:
	var found := find_core(id)
	return found if found != null else (cores[0] if not cores.is_empty() else null)

func find_core(id: StringName) -> CoreData:
	for item in cores:
		if item.id == id:
			return item
	return null

func get_cursor(id: StringName) -> CursorData:
	return find_cursor(id)

func get_cursor_or_default(id: StringName) -> CursorData:
	var found := find_cursor(id)
	return found if found != null else (cursors[0] if not cursors.is_empty() else null)

func find_cursor(id: StringName) -> CursorData:
	for item in cursors:
		if item.id == id:
			return item
	return null

func get_tower(id: StringName) -> TowerData:
	return find_tower(id)

func get_tower_or_default(id: StringName) -> TowerData:
	var found := find_tower(id)
	return found if found != null else (towers[0] if not towers.is_empty() else null)

func find_tower(id: StringName) -> TowerData:
	for item in towers:
		if item.id == id:
			return item
	return null

func get_formation(id: StringName) -> TowerFormationData:
	return find_formation(id)

func get_formation_or_default(id: StringName) -> TowerFormationData:
	var found := find_formation(id)
	return found if found != null else (formations[0] if not formations.is_empty() else null)

func find_formation(id: StringName) -> TowerFormationData:
	for item in formations:
		if item.id == id:
			return item
	return null

func get_tower_branch(id: StringName) -> TowerBranchData:
	for item in tower_branches:
		if item.id == id:
			return item
	return null

func get_tower_branches(tower_id: StringName) -> Array[TowerBranchData]:
	return tower_branches.filter(func(branch: TowerBranchData) -> bool: return branch.tower_id == tower_id)

func get_specialization_branch(id: StringName) -> SpecializationBranchData:
	for item in specialization_branches:
		if item.id == id:
			return item
	return null

func get_specialization_branches(owner_kind: StringName, owner_id: StringName) -> Array[SpecializationBranchData]:
	return specialization_branches.filter(func(branch: SpecializationBranchData) -> bool: return branch.owner_kind == owner_kind and branch.owner_id == owner_id)

func get_enemy(id: StringName) -> EnemyData:
	return find_enemy(id)

func get_enemy_or_default(id: StringName) -> EnemyData:
	var found := find_enemy(id)
	return found if found != null else (enemies[0] if not enemies.is_empty() else null)

func find_enemy(id: StringName) -> EnemyData:
	for item in enemies + faction_enemies + bosses:
		if item.id == id:
			return item
	if EnemyCatalogV015.LEGACY_REFERENCE_MIGRATION.has(id):
		var migrated_id := StringName(EnemyCatalogV015.LEGACY_REFERENCE_MIGRATION[id])
		for item in enemies + faction_enemies:
			if item.id == migrated_id:
				return item
		var runtime_fallbacks := {
			&"normal": &"civilian_slime", &"swarm": &"civilian_slime", &"splitter": &"civilian_slime",
			&"fast": &"goblin_raider", &"zigzag": &"skeleton_raider", &"shifter": &"skeleton_raider", &"ranged": &"skeleton_raider",
			&"armored": &"orc_shield", &"shielded": &"orc_shield", &"guardian": &"orc_shield",
			&"charger": &"hound_light_infantry", &"disruptor": &"wraith_raider", &"taunter": &"wraith_raider", &"phase": &"wraith_raider", &"cleanser": &"wraith_raider", &"support": &"wraith_raider",
			&"regenerator": &"steel_golem", &"sapper": &"steel_golem",
		}
		var fallback_id := StringName(runtime_fallbacks.get(id, &"civilian_slime"))
		for item in enemies:
			if item.id == fallback_id:
				return item
	return null

func get_all_enemy_data() -> Array[EnemyData]:
	var result: Array[EnemyData] = []
	result.append_array(enemies)
	result.append_array(faction_enemies)
	result.append_array(bosses)
	return result

func get_enemy_spawn_profile(enemy_id: StringName) -> EnemySpawnProfileData:
	for profile in enemy_spawn_profiles:
		if profile != null and profile.enemy_id == enemy_id:
			return profile
	return null

func get_faction_enemy_spawn_profiles(faction_id: StringName) -> Array[EnemySpawnProfileData]:
	var result: Array[EnemySpawnProfileData] = []
	for profile in enemy_spawn_profiles:
		if profile != null and profile.is_faction_enemy and profile.faction_id == faction_id:
			result.append(profile)
	return result

func _build_enemy_spawn_profiles() -> void:
	enemy_spawn_profiles = EnemyCatalogV015.build_spawn_profiles()

func _core(id: StringName, name: String, description: String, attack: StringName, skill: StringName, passive: StringName, damage: float, interval: float, health: float, regen: float, skill_damage: float, skill_cast_seconds: float, color: Color, unique_tower_id: StringName, unique_formation_id: StringName) -> CoreData:
	var item := CoreData.new()
	item.id = id
	item.display_name = name
	item.description = description
	item.attack_type = attack
	item.skill_type = skill
	item.passive_type = passive
	item.damage = damage
	item.attack_interval = interval
	item.max_health = health
	item.regeneration = regen
	item.skill_damage = skill_damage
	item.skill_cast_seconds = skill_cast_seconds
	item.unique_tower_id = unique_tower_id
	item.unique_formation_id = unique_formation_id
	item.color = color
	item.texture = ConceptService.content_texture(&"cores", id)
	return item

func _build_cores() -> void:
	cores = [
		# 보석명 ID는 세이브 호환용으로 유지하되 표시 데이터는 v0.14 후보 정체성만 사용한다.
		_core(&"emerald", "파르태손 VIII 마아앙", "정석적인 직접 공격과 왕실 친위대, 다종족 수비병력을 안정적으로 지휘하는 균형형 후보", &"single", &"beam", &"balanced", 13.0, 0.65, 170.0, 0.35, 150.0, 0.85, Color("53d5a5"), &"emerald_guardian", &"emerald_guard"),
		_core(&"sapphire", "지아느 야하니아", "관통 공격과 환혹 무대로 난입자의 진군을 뒤집고 광신 친위대의 화력을 끌어내는 제어형 후보", &"pierce", &"radial", &"piercing", 22.0, 1.05, 150.0, 0.15, 200.0, 1.15, Color("4ca6ff"), &"sapphire_lance", &"sapphire_spearhead"),
		_core(&"amethyst", "카스하 르짜르", "긴 예고 뒤 밀집 지점과 중심부를 강타하고 심연 생명체를 부리는 순간 화력형 후보", &"radial", &"wall", &"fortress", 24.0, 1.15, 225.0, 0.55, 260.0, 1.05, Color("b778ff"), &"amethyst_nova", &"amethyst_bastion"),
		_core(&"jade", "이레라이 거주서도", "퇴장한 난입자를 사령으로 재고용하고 죽음의 파도로 연쇄 전투를 만드는 누적 화력형 후보", &"random", &"barrage", &"necromancy", 16.0, 0.38, 145.0, 0.2, 165.0, 1.25, Color("9ddd55"), &"jade_roulette", &"jade_gambit"),
		_core(&"obsidian", "죽음교주 주다긴다", "짧은 사거리의 강한 판결과 처형, 사신 소환으로 정예와 보스를 마무리하는 결전형 후보", &"single", &"beam", &"judgment", 27.0, 0.88, 200.0, 0.3, 235.0, 1.05, Color("d94b56"), &"obsidian_verdict", &"obsidian_tribunal"),
	]
	cores[2].attack_range = 320.0
	cores[1].charm_profile = CharmProfileData.new()
	cores[3].necromancy_profile = NecromancyProfileData.new()
	cores[4].judgment_profile = JudgmentProfileData.new()
	cores[4].suppress_basic_attack_during_skill_cast = true

func _cursor(id: StringName, name: String, description: String, attack: StringName, damage: float, interval: float, radius: float, knockback: float, collection: float, xp: float, movement_speed: float, color: Color) -> CursorData:
	var item := CursorData.new()
	item.id = id
	item.display_name = name
	item.description = description
	item.attack_type = attack
	item.damage = damage
	item.attack_interval = interval
	item.attack_radius = radius
	item.knockback = knockback
	item.collection_radius = collection
	item.experience_multiplier = xp
	item.movement_speed = movement_speed
	item.color = color
	item.texture = ConceptService.content_texture(&"cursors", id)
	return item

func _build_cursors() -> void:
	cursors = [
		# 금속명 ID 역시 체크포인트 호환용이다. 표시명은 실제 수석 심복 프로필과 일치시킨다.
		_cursor(&"iron", "마장군 칸다 도르기어크", "균형 잡힌 기동과 검격·넉백으로 전선을 정리하는 안정적인 마장군", &"area", 21.0, 0.43, 64.0, 52.0, 120.0, 1.0, 320.0, Color("70cce8")),
		_cursor(&"silver", "고통과 쾌락의 마녀 기븐 즈타", "빠르게 전장을 오가며 채찍·출혈·환혹으로 근거리를 제압하는 제어형 마녀", &"single", 16.0, 0.17, 34.0, 22.0, 96.0, 1.0, 470.0, Color("e1ebf5")),
		_cursor(&"gold", "심연의 피조물 저므조므", "느린 기동을 넓은 지속 장판·둔화·공포와 유세 열기 회수로 보상하는 점유형 심복", &"zone", 11.0, 0.29, 96.0, 28.0, 152.0, 1.3, 260.0, Color("ffd35a")),
		_cursor(&"platinum", "사령기사 주그디에드 야그니야", "기마 참격과 후보 액티브 합동 돌격, 재구성으로 전장을 관리하는 기동형 사령기사", &"heavy", 68.0, 0.98, 56.0, 48.0, 112.0, 1.0, 220.0, Color("d8efff")),
		_cursor(&"vanguard", "죽음교 돌격부대", "인원 비례 중공격과 처형·충원·부대 희생을 사용하는 돌격형 수석 심복", &"heavy", 76.0, 1.08, 60.0, 68.0, 116.0, 1.05, 245.0, Color("e35762")),
	]

func _tower(
	id: StringName,
	name: String,
	description: String,
	behavior: StringName,
	target: StringName,
	damage: float,
	interval: float,
	area: float,
	status: float,
	color: Color,
	range_cells: float = 1.5,
	origin_faction_id: StringName = &"",
	technology_name: String = ""
) -> TowerData:
	var item := TowerData.new()
	item.id = id
	item.display_name = name
	item.description = description
	item.behavior = behavior
	item.target_rule = target
	item.damage = damage
	item.attack_interval = interval
	item.attack_range_cells = range_cells
	item.link_range_cells = 1.5 if behavior == &"chain" else 0.0
	item.area_radius = area
	item.status_power = status
	item.color = color
	item.tags = [behavior]
	item.origin_faction_id = origin_faction_id
	item.technology_name = technology_name
	item.projectile_texture_id = TOWER_PROJECTILE_TEXTURE_IDS.get(id, &"")
	item.formation_power_rating = float(TOWER_FORMATION_POWER.get(id, 100.0))
	var texture_category: StringName = &"defenders" if NORMAL_DEFENDER_IDS.has(id) else &"towers"
	var attack_texture_category: StringName = &"defender_attacks" if NORMAL_DEFENDER_IDS.has(id) else &"tower_attacks"
	item.texture = ConceptService.content_texture(texture_category, id)
	item.attack_texture = ConceptService.optional_content_texture(attack_texture_category, id)
	return item

func _build_towers() -> void:
	towers = [
		_tower(&"rapid", "고블린 창병", "한 칸 거리에서 안정적으로 단일 대상을 공격하는 기본 수비병력", &"rapid", &"closest_tower", 12.0, 0.46, 0.0, 0.0, Color("66d9ff"), 1.0, &"", "고블린 용병 창술"),
		_tower(&"area", "해골 척탄병", "느린 해골 화염탄을 밀집 지점에 던져 근·중거리 범위 피해를 가함", &"area", &"density", 30.0, 1.5, 90.0, 0.0, Color("ff9f66"), 2.0, &"", "해골 화염탄 척탄술"),
		_tower(&"pierce", "오크 궁병", "목표 방향으로 화살을 발사해 직선상의 적을 관통", &"pierce", &"closest_core", 18.0, 1.0, 0.0, 0.0, Color("83a4ff"), 4.5, &"", "오크 관통 궁술"),
		_tower(&"slow", "심연의 기둥", "범위 안의 적을 지속적으로 늦춰 특정 지점을 통제", &"slow", &"breach_pressure", 0.0, 0.72, 0.0, 0.38, Color("7fe8df"), 1.5, &"kasuha_faction", "심연 영역 제어·제물소환술"),
		_tower(&"knockback", "죽음교 자동포교기계 KI-Ⅱ", "회전 톱날 접촉으로 피해·넉백·출혈을 가하는 임대 전도 기계", &"knockback", &"closest_core", 20.0, 2.0, 0.0, 55.0, Color("f4d56b"), 1.0, &"judaginda_faction", "KI-Ⅱ 자동포교 톱날 기술"),
		_tower(&"execute", "트롤 스나이퍼", "매우 긴 사거리에서 현재 체력이 높은 정예·공식 난입을 우선 저격", &"execute", &"highest_health", 62.0, 2.4, 0.0, 0.0, Color("ff657d"), 6.0, &"", "트롤 정예 저격술"),
		_tower(&"mark", "서큐버스 약화주술사", "강한 적에게 환혹과 구분되는 취약 주술을 걸어 받는 피해를 증가", &"mark", &"highest_health", 2.0, 0.8, 0.0, 0.2, Color("d781ff"), 3.0, &"jiane_faction", "서큐버스 취약 주술"),
		_tower(&"chain", "마력 전도탑", "다른 전도탑과 감쇠 빔 망을 형성해 배치에 따라 화력이 증가", &"chain", &"closest_core", 26.0, 1.0, 0.0, 0.0, Color("fff079"), 99.0, &"", "마력 전도 회로"),
		_tower(&"rubber_golem", "고무골렘", "설치 지점 주변에서 위험한 적을 밀어내는 순수 제어 수비대", &"golem", &"breach_pressure", 0.0, 1.5, 88.0, 72.0, Color("79e59a"), 1.25, &"", "탄성 골렘 집적 제어"),
		_unique_tower(&"emerald_guardian", "왕실 정예 근위대", "검과 방패로 가장 가까운 난입자를 밀어내고 일정 주기마다 왕실 방패 충격을 사용", &"unique_single", &"closest_core", 38.0, 0.72, 0.0, 30.0, Color("53d5a5"), &"emerald"),
		_unique_tower(&"sapphire_lance", "지아느 광신 추종자", "넓은 직선을 관통하며 환혹 중인 난입자와 환혹이 변환된 공식 난입에게 75% 추가 피해", &"unique_pierce", &"closest_core", 62.0, 1.35, 0.0, 0.0, Color("4ca6ff"), &"sapphire", 5.0),
		_unique_tower(&"amethyst_nova", "심연마술 신봉자", "주변 난입자를 동시에 타격하고 둔화시키는 심연 파동을 방출", &"unique_radial", &"breach_pressure", 29.0, 1.20, 130.0, 0.22, Color("b778ff"), &"amethyst"),
		_unique_tower(&"jade_roulette", "망자 부활진", "강한 망령을 최대 네 대상에게 출격시키며 활동 체력이 소진되면 잠시 행동불능 후 완전 재가동", &"unique_random", &"reward_value", 26.0, 0.62, 0.0, 0.0, Color("9ddd55"), &"jade", 4.0),
		_unique_tower(&"obsidian_verdict", "죽음교 판결관", "전열에서 강적에게 선고를 누적해 3중첩 일반 난입자를 처형하고 공식 난입에게 최대 체력 비례 고정 피해", &"unique_single", &"highest_health", 78.0, 1.12, 0.0, 0.0, Color("d94b56"), &"obsidian", 1.75),
		_unique_tower(&"obsidian_inquisitor", "죽음교 원거리 집행관", "후열에서 심판 주술탄으로 선고를 누적하고 처형을 지원하는 원거리 친위대", &"unique_single", &"highest_health", 52.0, 1.35, 0.0, 0.0, Color("ef6b66"), &"obsidian", 4.0),
	]
	find_tower(&"jade_roulette").reactivation_profile = RetainerReactivationProfileData.new()

func _unique_tower(id: StringName, name: String, description: String, behavior: StringName, target: StringName, damage: float, interval: float, area: float, status: float, color: Color, core_id: StringName, range_cells: float = 2.5) -> TowerData:
	var item := _tower(id, name, description, behavior, target, damage, interval, area, status, color, range_cells)
	item.unique_core_id = core_id
	item.max_level = 1
	item.tags.assign([&"unique", core_id, behavior])
	item.formation_power_rating = float(TOWER_FORMATION_POWER.get(id, 200.0))
	return item

func _build_formations() -> void:
	formations = [
		_formation_cells(&"balanced", "표준 사격진", "2×2 밀집 사각에서 네 고블린 창병이 안정적인 탄막을 형성", [&"rapid", &"rapid", &"rapid", &"rapid"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], [&"basic", &"single"], 1, TowerFormationData.SHAPE_COMPACT, 0),
		_formation_cells(&"orc_mixed", "오크 혼성 장사진", "가로 4칸에서 고블린 둘이 오크 궁병 둘의 관통선을 엄호", [&"rapid", &"pierce", &"rapid", &"pierce"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], [&"pierce", &"basic"], 1, TowerFormationData.SHAPE_LONG, 2),
		_formation_cells(&"standard_demon_army", "표준 마군단", "고블린·오크·고무골렘 세 병종이 계단형 전선을 구성", [&"rapid", &"pierce", &"rubber_golem", &"rubber_golem"], [Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)], [&"basic", &"pierce", &"knockback"], 1, TowerFormationData.SHAPE_STEP, 2),
		_formation_cells(&"compressed_bombardment", "압축 포격진", "해골 척탄병 둘을 고무골렘 둘이 받치는 굴곡형 압축 포격진", [&"area", &"rubber_golem", &"area", &"rubber_golem"], [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)], [&"aoe", &"knockback"], 1, TowerFormationData.SHAPE_BEND, 1),
		_formation_cells(&"guidance", "창병 전열", "두 고블린 창병이 가로 전열에서 안정적인 단일 화력을 집중", [&"rapid", &"rapid"], [Vector2i(0, 0), Vector2i(1, 0)], [&"basic", &"single"], 1, TowerFormationData.SHAPE_LONG, 0),
		_formation_cells(&"barrage", "척탄 종대", "두 해골 척탄병이 세로 종대에서 같은 밀집 지점을 연속 폭격", [&"area", &"area"], [Vector2i(0, 0), Vector2i(0, 1)], [&"aoe"], 1, TowerFormationData.SHAPE_LONG, 0),
		_formation_cells(&"arrow_barrage", "오크 장궁대", "두 오크 궁병이 가로 사격선에서 관통 화살을 연계", [&"pierce", &"pierce"], [Vector2i(0, 0), Vector2i(1, 0)], [&"pierce"], 1, TowerFormationData.SHAPE_LONG, 0),
		_formation_cells(&"duo", "고무 방벽진", "두 고무골렘이 세로 2칸 방벽에서 적을 밀어냄", [&"rubber_golem", &"rubber_golem"], [Vector2i(0, 0), Vector2i(0, 1)], [&"knockback", &"control"], 2, TowerFormationData.SHAPE_LONG, 0),
		_formation_cells(&"alternating", "창병 굴곡진", "세 고블린 창병이 ㄱ자 전선을 구성해 근거리 빈틈을 줄임", [&"rapid", &"rapid", &"rapid"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)], [&"basic", &"single"], 1, TowerFormationData.SHAPE_BEND, 1),
		_formation_cells(&"bulwark", "골렘 포격 방벽", "고무골렘 둘이 해골 척탄병의 포격 위치를 굴곡형으로 보호", [&"rubber_golem", &"area", &"rubber_golem"], [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)], [&"aoe", &"knockback"], 1, TowerFormationData.SHAPE_BEND, 1),
		_formation_cells(&"mixed", "삼종 사격선", "오크·고무골렘·해골이 가로 3칸 혼성 화망을 구성", [&"pierce", &"rubber_golem", &"area"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], [&"aoe", &"pierce", &"knockback"], 2, TowerFormationData.SHAPE_LONG, 1),
		_formation_cells(&"precision", "기초 정밀진", "고블린 창병이 세로로 배치된 오크 궁병 둘의 사격선을 엄호", [&"rapid", &"pierce", &"pierce"], [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)], [&"pierce", &"basic"], 1, TowerFormationData.SHAPE_LONG, 1),
		_weighted_formation_cells(&"cryo_net", "심연 압축조", "심연의 기둥이 고무골렘의 집적 지점을 둔화", [&"slow", &"rubber_golem"], [Vector2i(0, 0), Vector2i(1, 0)], [&"control", &"knockback"], 1.15, TowerFormationData.SHAPE_LONG, 0),
		_weighted_formation_cells(&"abyss_shooting", "심연 혼성 사격진", "세로 4칸 둔화 지대에서 심연의 기둥과 오크 궁병이 관통 사격을 집중", [&"slow", &"pierce", &"slow", &"pierce"], [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)], [&"control", &"pierce"], 0.90, TowerFormationData.SHAPE_LONG, 2),
		_weighted_formation_cells(&"abyss_firepower", "심연 화력조", "심연의 기둥이 둔화한 밀집 적을 해골 척탄병이 마무리", [&"slow", &"area"], [Vector2i(0, 0), Vector2i(0, 1)], [&"control", &"aoe"], 1.05, TowerFormationData.SHAPE_LONG, 0),
		_weighted_formation_cells(&"abyss_vanguard", "심연 전열대", "심연의 기둥 뒤에서 두 고블린 창병이 굴곡형 사격선을 형성", [&"slow", &"rapid", &"rapid"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)], [&"control", &"basic"], 1.00, TowerFormationData.SHAPE_BEND, 1),
		_weighted_formation_cells(&"abyss_compressed_bombardment", "심연 압축포격", "둔화와 집적으로 모은 적을 척탄으로 폭격", [&"slow", &"rubber_golem", &"area"], [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)], [&"control", &"aoe", &"knockback"], 1.10, TowerFormationData.SHAPE_BEND, 1),
		_weighted_formation_cells(&"abyss_standard", "심연 밀집진", "심연의 기둥 둘이 두 고블린 창병의 2×2 화망을 안정화", [&"slow", &"rapid", &"slow", &"rapid"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], [&"control", &"basic"], 0.95, TowerFormationData.SHAPE_COMPACT, 0),
		_weighted_formation_cells(&"spear_observer", "창병 관측조", "고블린 전열이 트롤의 저격 각을 확보", [&"execute", &"rapid"], [Vector2i(0, 0), Vector2i(1, 0)], [&"elite", &"single"], 1.05, TowerFormationData.SHAPE_LONG, 0),
		_weighted_formation_cells(&"long_range_fireteam", "중장거리 혼성진", "트롤의 저격선을 세 고블린 창병이 가로 4칸에서 엄호", [&"execute", &"rapid", &"rapid", &"rapid"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], [&"elite", &"single"], 0.85, TowerFormationData.SHAPE_LONG, 2),
		_weighted_formation_cells(&"recoil_hunt", "반동 사냥조", "고무골렘이 강적을 트롤의 조준선으로 밀어냄", [&"execute", &"rubber_golem"], [Vector2i(0, 0), Vector2i(0, 1)], [&"elite", &"knockback"], 1.05, TowerFormationData.SHAPE_LONG, 0),
		_weighted_formation_cells(&"slowed_snipers", "전열 저격대", "두 고블린 창병이 트롤의 조준선 앞에서 진군을 늦추는 가로 장사진", [&"execute", &"rapid", &"rapid"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], [&"elite", &"single"], 1.10, TowerFormationData.SHAPE_LONG, 1),
		_weighted_formation_cells(&"grenadier_snipers", "척탄 저격대", "트롤이 강적을 맡고 척탄과 집적으로 물량을 정리", [&"execute", &"area", &"rubber_golem"], [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)], [&"elite", &"aoe", &"knockback"], 1.00, TowerFormationData.SHAPE_BEND, 1),
		_weighted_formation_cells(&"rear_fireline", "후방 화력진", "트롤·오크·고블린이 긴 ㄴ자 후방 화력선을 구성", [&"execute", &"pierce", &"rapid", &"rapid"], [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2)], [&"elite", &"pierce", &"basic"], 0.90, TowerFormationData.SHAPE_BEND, 1),
		_weighted_formation_cells(&"execution", "약점 사냥조", "주술사가 만든 약점을 트롤이 마무리", [&"execute", &"mark"], [Vector2i(0, 0), Vector2i(1, 0)], [&"amplify", &"elite"], 1.15, TowerFormationData.SHAPE_LONG, 0),
		_weighted_formation_cells(&"vulnerable_breakthrough", "취약 혼성 돌파진", "서큐버스 둘과 오크 궁병 둘이 2×2에서 취약·관통을 연계", [&"mark", &"pierce", &"mark", &"pierce"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], [&"amplify", &"pierce"], 0.90, TowerFormationData.SHAPE_COMPACT, 0),
		_weighted_formation_cells(&"vulnerable_bombardment", "취약 포격조", "취약 표식 위에 척탄 범위 피해를 집중", [&"mark", &"area"], [Vector2i(0, 0), Vector2i(0, 1)], [&"amplify", &"aoe"], 1.10, TowerFormationData.SHAPE_LONG, 0),
		_weighted_formation_cells(&"elite_hunt", "정예 사냥조", "서큐버스 둘이 세로 후열의 트롤 저격을 연속 증폭", [&"mark", &"mark", &"execute"], [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)], [&"elite", &"amplify"], 1.05, TowerFormationData.SHAPE_LONG, 1),
		_weighted_formation_cells(&"charm_compression", "매혹 압축조", "피해 증폭과 집적 뒤 범위 포격을 연계", [&"mark", &"rubber_golem", &"area"], [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)], [&"amplify", &"aoe", &"knockback"], 1.05, TowerFormationData.SHAPE_BEND, 1),
		_weighted_formation_cells(&"weakpoint_blockade", "약점 봉쇄진", "서큐버스가 오크 궁병 둘의 관통 사격에 취약 표식을 제공", [&"mark", &"pierce", &"pierce"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], [&"amplify", &"pierce"], 1.00, TowerFormationData.SHAPE_BEND, 1),
		_weighted_formation_cells(&"elite_execution", "정예 처단진", "취약 표식과 트롤 저격을 고블린 창병 둘의 전열이 보조", [&"mark", &"execute", &"rapid", &"rapid"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1)], [&"elite", &"amplify", &"single"], 0.85, TowerFormationData.SHAPE_BEND, 1),
		_weighted_formation_cells(&"vulnerable_bombardment_line", "취약 포격 종대", "두 서큐버스의 취약과 심연 둔화 위에 해골 척탄병이 세로 화력을 투입", [&"mark", &"slow", &"mark", &"area"], [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)], [&"amplify", &"control", &"aoe"], 0.90, TowerFormationData.SHAPE_LONG, 2),
		_weighted_formation_cells(&"ki2_field_team", "전도 현장조", "KI-Ⅱ 톱날이 고무골렘의 집적 지점을 밀어냄", [&"knockback", &"rubber_golem"], [Vector2i(0, 0), Vector2i(1, 0)], [&"contact", &"knockback"], 1.15, TowerFormationData.SHAPE_LONG, 0),
		_weighted_formation_cells(&"bleeding_defense", "출혈 포격 방어진", "KI-Ⅱ 둘과 해골 척탄병 둘이 2×2 접촉·포격 지대를 형성", [&"knockback", &"area", &"knockback", &"area"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)], [&"contact", &"status", &"aoe"], 0.90, TowerFormationData.SHAPE_COMPACT, 0),
		_weighted_formation_cells(&"violent_mission", "과격 포교조", "톱날 출혈과 취약 표식을 한 지점에 집중", [&"knockback", &"mark"], [Vector2i(0, 0), Vector2i(0, 1)], [&"contact", &"amplify", &"status"], 1.05, TowerFormationData.SHAPE_LONG, 0),
		_weighted_formation_cells(&"saw_compression", "톱날 굴곡진", "세 KI-Ⅱ가 ㄱ자 접촉 영역을 만들어 출혈 압박을 유지", [&"knockback", &"knockback", &"knockback"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)], [&"contact", &"status"], 1.05, TowerFormationData.SHAPE_BEND, 1),
		_weighted_formation_cells(&"forced_labor", "강제 노동진", "KI-Ⅱ와 고무골렘이 해골 척탄병의 가로 폭발선으로 적을 운반", [&"knockback", &"rubber_golem", &"area"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], [&"contact", &"aoe", &"knockback"], 1.00, TowerFormationData.SHAPE_LONG, 1),
		_weighted_formation_cells(&"violent_conversion", "과격 포교대", "출혈 접촉과 취약 표식을 고블린이 지원", [&"knockback", &"mark", &"rapid"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], [&"contact", &"status", &"amplify"], 1.00, TowerFormationData.SHAPE_BEND, 1),
		_weighted_formation_cells(&"death_rotation", "죽음의 회전진", "네 KI-Ⅱ가 계단형 접촉선을 이어 출혈 압박을 유지", [&"knockback", &"knockback", &"knockback", &"knockback"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(2, 1)], [&"contact", &"status"], 0.85, TowerFormationData.SHAPE_STEP, 2),
		_weighted_formation_cells(&"compressed_mission", "압축 포교진", "KI-Ⅱ 둘과 서큐버스가 해골 척탄병의 ㄴ자 포격선을 지원", [&"knockback", &"mark", &"knockback", &"area"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, 2)], [&"contact", &"amplify", &"aoe"], 0.90, TowerFormationData.SHAPE_BEND, 1),
		_weighted_formation_cells(&"cascade", "최소 전도망", "두 전도탑이 최소 연결망을 형성", [&"chain", &"chain"], [Vector2i(0, 0), Vector2i(1, 0)], [&"network", &"status"], 1.20, TowerFormationData.SHAPE_LONG, 0),
		_weighted_formation_cells(&"conduction_sniper", "전도 저격조", "전도망 보조 타격과 트롤의 강적 저격을 결합", [&"chain", &"execute"], [Vector2i(0, 0), Vector2i(0, 1)], [&"network", &"elite"], 1.00, TowerFormationData.SHAPE_LONG, 0),
		_weighted_formation_cells(&"conduction_compression", "전도 압축조", "고무골렘이 적을 전도선 안으로 집적", [&"chain", &"rubber_golem"], [Vector2i(0, 0), Vector2i(1, 0)], [&"network", &"knockback"], 1.05, TowerFormationData.SHAPE_LONG, 0),
		_weighted_formation_cells(&"conduction_blockade", "전도 종대", "세 전도탑이 세로 연결망으로 좁은 전선을 봉쇄", [&"chain", &"chain", &"chain"], [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2)], [&"network", &"status"], 1.10, TowerFormationData.SHAPE_LONG, 1),
		_weighted_formation_cells(&"conduction_amplification", "전도 증폭진", "전도탑 둘과 서큐버스가 가로 3칸에서 연결망 피해를 증폭", [&"chain", &"chain", &"mark"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], [&"network", &"amplify"], 1.10, TowerFormationData.SHAPE_LONG, 1),
		_weighted_formation_cells(&"conduction_concentration", "전도 압축진", "두 전도탑 사이로 고무골렘이 적을 모으는 굴곡형 연결망", [&"chain", &"chain", &"rubber_golem"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1)], [&"network", &"knockback"], 1.05, TowerFormationData.SHAPE_BEND, 1),
		_weighted_formation_cells(&"abyss_power_grid", "심연 전력망", "네 전도탑이 세로 계단형 연결망을 구축", [&"chain", &"chain", &"chain", &"chain"], [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)], [&"network", &"status"], 0.90, TowerFormationData.SHAPE_STEP, 2),
		_weighted_formation_cells(&"conduction_fire_grid", "전도 화력망", "전도탑 둘을 오크·고블린 사격선과 가로로 연결", [&"chain", &"chain", &"pierce", &"rapid"], [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)], [&"network", &"pierce", &"basic"], 0.90, TowerFormationData.SHAPE_LONG, 2),
		_weighted_formation_cells(&"overload_mission_grid", "과부하 포교망", "전도탑 둘과 KI-Ⅱ 둘이 세로 계단형 기계 제어망을 형성", [&"chain", &"knockback", &"chain", &"knockback"], [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)], [&"network", &"contact", &"knockback"], 0.85, TowerFormationData.SHAPE_STEP, 2),
		_unique_formation(&"emerald_guard", "파르태손 왕실 친위대", "세로 4칸을 지키는 왕실 정예 친위대", [&"emerald_guardian", &"emerald_guardian", &"emerald_guardian", &"emerald_guardian"], [&"unique", &"emerald", &"royal_guard"], &"emerald"),
		_unique_formation(&"sapphire_spearhead", "지아느 광신 추종자", "엇갈린 4칸에서 환혹 대상을 추격하는 고화력 광신 친위대", [&"sapphire_lance", &"sapphire_lance", &"sapphire_lance", &"sapphire_lance"], [&"unique", &"sapphire", &"charm_guard"], &"sapphire"),
		_unique_formation(&"amethyst_bastion", "심연마술 신봉자", "전방 심연의 기둥 둘이 적을 묶고 후방 신봉자 둘이 범위 파동으로 마무리", [&"amethyst_nova", &"slow", &"amethyst_nova", &"slow"], [&"unique", &"amethyst", &"control"], &"amethyst"),
		_unique_formation(&"jade_gambit", "부활 시체 친위대", "여섯 부활 친위대가 높은 초기 전력을 제공하지만 두 공란과 넓은 점유로 후반 배치를 압박", [&"jade_roulette", &"jade_roulette", &"jade_roulette", &"jade_roulette", &"jade_roulette", &"jade_roulette"], [&"unique", &"jade", &"necromancy"], &"jade"),
		_unique_formation(&"obsidian_tribunal", "죽음교도 집행대", "전열 판결관 둘과 후열 원거리 집행관 둘이 선고와 처형을 이어가는 2×2 죽음교 친위대", [&"obsidian_inquisitor", &"obsidian_verdict", &"obsidian_inquisitor", &"obsidian_verdict"], [&"unique", &"obsidian", &"execution"], &"obsidian"),
		_guard_reinforcement(&"emerald_guard_reinforcement", "왕실 친위대 증원", "엘리트주의 특성으로 합류하는 세로 2칸 친위대", &"emerald_guardian", &"emerald"),
	]

func _formation_cells(id: StringName, title: String, description: String, tower_ids: Array[StringName], offsets: Array, tags: Array[StringName], rarity: int = 1, shape_class: StringName = &"", placement_difficulty: int = -1) -> TowerFormationData:
	if tower_ids.size() != offsets.size():
		push_error("Formation '%s' has %d towers but %d cell offsets." % [id, tower_ids.size(), offsets.size()])
	var cells: Array[FormationCellData] = []
	for index in mini(tower_ids.size(), offsets.size()):
		cells.append(FormationCellData.new().configure(offsets[index] as Vector2i, tower_ids[index]))
	var formation := TowerFormationData.new().configure_cells(id, title, description, cells, tags, rarity, shape_class, placement_difficulty)
	var raw_power := 0.0
	for tower_id in tower_ids:
		raw_power += get_tower(tower_id).formation_power_rating
	return formation.configure_balance(raw_power, FORMATION_TARGET_POWER)

func _weighted_formation_cells(id: StringName, title: String, description: String, tower_ids: Array[StringName], offsets: Array, tags: Array[StringName], weight: float, shape_class: StringName = &"", placement_difficulty: int = -1) -> TowerFormationData:
	var formation := _formation_cells(id, title, description, tower_ids, offsets, tags, 1, shape_class, placement_difficulty)
	formation.base_weight = maxf(weight, 0.05)
	return formation

func _unique_formation(id: StringName, title: String, description: String, recipe: Array[StringName], tags: Array[StringName], core_id: StringName) -> TowerFormationData:
	var compact_towers: Array[StringName] = []
	for tower_id in recipe:
		if tower_id != &"":
			compact_towers.append(tower_id)
	assert(compact_towers.size() in [3, 4, 6], "guard formations must explicitly define three, four, or six occupied cells")
	var guard_cells: Array[FormationCellData] = []
	if compact_towers.size() == 6:
		var offsets: Array[Vector2i] = [
			Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1),
			Vector2i(0, 2), Vector2i(0, 3), Vector2i(1, 3),
		]
		for index in compact_towers.size():
			guard_cells.append(FormationCellData.new().configure(offsets[index], compact_towers[index]))
	elif compact_towers.size() == 4:
		var offsets: Array[Vector2i] = []
		if core_id == &"sapphire":
			offsets.assign([Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(0, 3)])
		elif core_id in [&"amethyst", &"obsidian"]:
			offsets.assign([Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)])
		else:
			offsets.assign([Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)])
		for index in compact_towers.size():
			guard_cells.append(FormationCellData.new().configure(offsets[index], compact_towers[index]))
	else:
		guard_cells.assign([
			FormationCellData.new().configure(Vector2i(0, 0), compact_towers[0]),
			FormationCellData.new().configure(Vector2i(1, 0), compact_towers[1]),
			FormationCellData.new().configure(Vector2i(0, 1), compact_towers[2]),
		])
	var formation := TowerFormationData.new().configure_cells(id, title, description, guard_cells, tags, 3)
	formation.unique_core_id = core_id
	formation.is_guard = true
	formation.candidate_id = core_id
	formation.can_vertical_flip = true
	var raw_power := 0.0
	for tower_id in formation.get_tower_ids():
		raw_power += get_tower(tower_id).formation_power_rating
	return formation.configure_balance(raw_power, UNIQUE_FORMATION_TARGET_POWER)

func _guard_reinforcement(id: StringName, title: String, description: String, tower_id: StringName, core_id: StringName) -> TowerFormationData:
	var cells: Array[FormationCellData] = [
		FormationCellData.new().configure(Vector2i(0, 0), tower_id),
		FormationCellData.new().configure(Vector2i(0, 1), tower_id),
	]
	var formation := TowerFormationData.new().configure_cells(id, title, description, cells, [&"unique", core_id, &"reinforcement"], 3)
	formation.unique_core_id = core_id
	formation.is_guard = true
	formation.candidate_id = core_id
	formation.can_vertical_flip = false
	return formation.configure_balance(get_tower(tower_id).formation_power_rating * 2.0, UNIQUE_FORMATION_TARGET_POWER * 0.5)

func _build_tower_branches() -> void:
	tower_branches = [
		TowerBranchData.new().configure(&"rapid_burn", "고블린 수 증가", "한 공격 주기에 여러 창병이 차례로 공격해 상태 적용 기회를 늘림", &"rapid", &"role", {"volley_shots": 2, "volley_damage": 0.7}, {"volley_shots": 3, "volley_damage": 0.72}),
		TowerBranchData.new().configure(&"rapid_ricochet", "고블린 정예화", "피해·사거리·공격속도를 높이고 주기적으로 워크라이 강화 공격", &"rapid", &"synergy", {"damage": 1.25, "range": 1.18, "speed": 1.15, "warcry_interval": 8, "warcry_damage": 1.4}, {"damage": 1.55, "range": 1.32, "speed": 1.3, "warcry_interval": 6, "warcry_damage": 1.6}),
		TowerBranchData.new().configure(&"rapid_mark", "고블린 병법", "주기적으로 독 또는 출혈과 취약을 함께 부여해 평범한 창병을 상태 보조원으로 전환", &"rapid", &"playstyle", {"tactics_cycle": 3, "tactics_mark": 0.1, "tactics_bleed_ratio": 0.006, "tactics_poison_damage": 6.0, "tactics_poison_chance": 0.5}, {"tactics_cycle": 2, "tactics_mark": 0.16, "tactics_bleed_ratio": 0.009, "tactics_poison_damage": 9.0, "tactics_poison_chance": 0.5}),
		TowerBranchData.new().configure(&"area_power", "화염병 배치", "착탄 지점에 화상 장판을 남기고 같은 장판은 각 적에게 한 번만 화상을 부여", &"area", &"role", {"fire_zone_duration": 3.5, "fire_zone_radius": 72.0, "fire_zone_burn_ratio": 0.12}, {"fire_zone_duration": 5.0, "fire_zone_radius": 92.0, "fire_zone_burn_ratio": 0.18}),
		TowerBranchData.new().configure(&"area_shrapnel", "뼈뭉치 폭탄 개발", "착탄 뒤 무작위 방향으로 적중 상한이 있는 일반 뼈 투사체를 확산", &"area", &"synergy", {"bone_shard_count": 5, "bone_shard_damage": 0.30, "bone_shard_range": 150.0}, {"bone_shard_count": 8, "bone_shard_damage": 0.38, "bone_shard_range": 190.0}),
		TowerBranchData.new().configure(&"area_stun", "번개정령과의 협업", "폭탄 착탄 지점에 추가 번개 피해와 감전을 부여", &"area", &"playstyle", {"lightning_damage": 0.42, "shock": true}, {"lightning_damage": 0.72, "shock": true}),
		TowerBranchData.new().configure(&"pierce_power", "장궁부대", "사거리와 피해를 크게 높이는 대신 공격속도가 느려지는 장거리 관통 분기", &"pierce", &"role", {"damage": 1.55, "range": 1.6, "speed": 0.82}, {"damage": 2.0, "range": 1.9, "speed": 0.72}),
		TowerBranchData.new().configure(&"pierce_execute", "하이오크 부대", "주요 능력치를 높이고 5회 공격마다 폭이 넓은 파워샷을 발사", &"pierce", &"synergy", {"damage": 1.3, "range": 1.15, "power_shot_hits": 5, "power_shot_width": 1.7, "power_shot_damage": 1.65}, {"damage": 1.55, "range": 1.3, "power_shot_hits": 5, "power_shot_width": 2.3, "power_shot_damage": 2.2}),
		TowerBranchData.new().configure(&"pierce_rail", "폭파각인 화살", "관통을 포기하고 첫 대상 위치에 부착한 뒤 짧은 지연 후 범위 폭발", &"pierce", &"playstyle", {"explosive_arrow": true, "explosion_delay": 0.32, "explosion_radius": 92.0, "explosion_damage": 1.45}, {"explosive_arrow": true, "explosion_delay": 0.24, "explosion_radius": 126.0, "explosion_damage": 1.9}),
		TowerBranchData.new().configure(&"push_force", "터보엔진 DEATH-3000 장착", "톱 회전속도를 대폭 높이되 일정 공격마다 과열되어 잠시 자동 정지", &"knockback", &"role", {"speed": 2.35, "overheat_cycle": 7, "overheat_duration": 1.1}, {"speed": 3.20, "overheat_cycle": 6, "overheat_duration": 0.9}),
		TowerBranchData.new().configure(&"push_mark", "크고 아름다운 전도수단", "톱날을 하나로 고정하고 크기·피해·회전속도·넉백을 대폭 강화", &"knockback", &"synergy", {"saw_fixed": 1, "saw_size": 1.65, "damage": 2.35, "speed": 1.35, "push": 1.85}, {"saw_fixed": 1, "saw_size": 2.05, "damage": 3.20, "speed": 1.60, "push": 2.40}),
		TowerBranchData.new().configure(&"push_wave", "피로서 이루리라", "톱날을 8개로 고정해 더 많은 각도를 덮는 대신 개별 피해와 넉백을 낮춤", &"knockback", &"playstyle", {"saw_fixed": 8, "damage": 0.55, "push": 0.55}, {"saw_fixed": 8, "damage": 0.68, "push": 0.68, "bleed_power": 1.6}),
		TowerBranchData.new().configure(&"slow_power", "제물소환의식", "영향권에서 적이 쓰러지면 제물을 쌓고 빈 소환 슬롯에 체력이 소진되는 추적 피조물을 생성", &"slow", &"role", {"sacrifice_required": 5, "summon_cap": 1, "summon_duration": 5.0, "summon_interval": 0.72, "summon_damage": 28.0, "summon_radius": 140.0}, {"sacrifice_required": 4, "summon_cap": 2, "summon_duration": 7.0, "summon_interval": 0.55, "summon_damage": 42.0, "summon_radius": 170.0}),
		TowerBranchData.new().configure(&"slow_lock", "침식하는 기둥", "영향권을 주기적으로 침식해 짧은 기절을 부여하고 공식 난입 공통 제어 저항을 따름", &"slow", &"synergy", {"erosion_cycle": 5, "erosion_stun": 0.32}, {"erosion_cycle": 4, "erosion_stun": 0.58}),
		TowerBranchData.new().configure(&"slow_range", "거대기둥", "영향 범위와 둔화율을 함께 높여 특정 지점 통제에 집중", &"slow", &"playstyle", {"range": 1.35, "slow_multiplier": 1.3}, {"range": 1.6, "slow_multiplier": 1.55}),
		TowerBranchData.new().configure(&"execute_power", "장전수 배치", "단일 저격 패턴을 유지하면서 재장전 시간을 대폭 단축", &"execute", &"role", {"speed": 1.7}, {"speed": 2.45}),
		TowerBranchData.new().configure(&"execute_threshold", "철갑탄 배치", "주 대상의 방어를 관통하고 발사 경로의 적에게 부수 피해", &"execute", &"synergy", {"damage": 1.3, "armor_pierce": true, "collateral_damage": 0.4, "collateral_width": 28.0}, {"damage": 1.65, "armor_pierce": true, "collateral_damage": 0.68, "collateral_width": 42.0}),
		TowerBranchData.new().configure(&"execute_cycle", "도탄 전문가", "주 대상 적중 후 주변의 서로 다른 적에게 감쇠 도탄", &"execute", &"playstyle", {"ricochet_count": 2, "ricochet": 0.62, "ricochet_falloff": 0.72}, {"ricochet_count": 3, "ricochet": 0.72, "ricochet_falloff": 0.78}),
		TowerBranchData.new().configure(&"mark_amp", "충격과 공포", "취약 주술에 약한 둔화를 더하고 지속시간을 늘려 제어를 겸함", &"mark", &"role", {"mark": 0.26, "mark_duration": 6.0, "hex_slow": 0.12}, {"mark": 0.34, "mark_duration": 8.0, "hex_slow": 0.18}),
		TowerBranchData.new().configure(&"mark_power", "약점노출", "지속시간을 줄이는 대신 받는 피해 증가율을 크게 높여 강적에 집중", &"mark", &"synergy", {"mark": 0.45, "mark_duration": 2.8}, {"mark": 0.62, "mark_duration": 2.2}),
		TowerBranchData.new().configure(&"mark_spread", "교대근무", "주술 시전속도와 지속시간을 높여 여러 적에게 빠르게 취약을 순환", &"mark", &"playstyle", {"speed": 1.8, "mark": 0.22, "mark_duration": 6.0}, {"speed": 2.5, "mark": 0.25, "mark_duration": 7.5}),
		TowerBranchData.new().configure(&"chain_power", "고전압 방전", "기본 빔 피해와 추가 중계기당 네트워크 증폭을 함께 강화", &"chain", &"role", {"damage": 1.35, "network_damage_per_relay": 0.12}, {"damage": 1.65, "network_damage_per_relay": 0.16}),
		TowerBranchData.new().configure(&"chain_cycle", "공진 회로", "마지막 중계점에서 시작점으로 감쇠가 적은 역방향 빔을 추가 방출", &"chain", &"synergy", {"relay_return": 0.34, "relay_return_falloff": 0.86}, {"relay_return": 0.52, "relay_return_falloff": 0.94}),
		TowerBranchData.new().configure(&"chain_mark", "초전도 코어", "네트워크 형태는 유지하면서 연쇄 빔 공격속도를 집중 강화", &"chain", &"playstyle", {"speed": 1.50}, {"speed": 2.00}),
		TowerBranchData.new().configure(&"golem_elastic", "고탄성 소재", "넉백이 강해지고 공격 반동으로 활동 위치가 흔들림", &"rubber_golem", &"role", {"push": 1.7, "speed": 1.15, "self_recoil": 32.0}, {"push": 2.3, "speed": 1.3, "self_recoil": 48.0}),
		TowerBranchData.new().configure(&"golem_wing", "학익진", "넉백 방향을 중심 집적으로 바꿔 범위 공격을 지원", &"rubber_golem", &"synergy", {"gather": 0.55, "area": 1.15}, {"gather": 0.8, "area": 1.35}),
		TowerBranchData.new().configure(&"golem_heavy", "육중함", "이동과 활동 범위를 줄이는 대신 넉백 범위를 넓힘", &"rubber_golem", &"playstyle", {"speed": 0.86, "movement": 0.68, "activity_range": 0.72, "control_radius": 1.3}, {"speed": 0.78, "movement": 0.52, "activity_range": 0.6, "control_radius": 1.6, "push": 1.4}),
	]

func _specialization(id: StringName, kind: StringName, owner: StringName, title: String, level_4_text: String, level_7_text: String, level_4: Dictionary, level_7: Dictionary, impacts: Array[StringName]) -> SpecializationBranchData:
	return SpecializationBranchData.new().configure(id, kind, owner, title, level_4_text, level_7_text, level_4, level_7, impacts)

func _build_specialization_branches() -> void:
	specialization_branches = [
		# 심복: 칸다 (기존 ID는 저장 호환을 위해 유지)
		_specialization(&"iron_impact", &"cursor", &"iron", "정예 검술 훈련", "검격 피해 +22% · 넉백 +18%", "검격 피해 +45% · 넉백 +65% · 충돌 취약", {"damage": 1.22, "knockback": 1.18}, {"damage": 1.45, "knockback": 1.65, "collision_damage": 0.32, "collision_mark": 0.18}, [&"retainer", &"damage", &"control"]),
		_specialization(&"iron_focus", &"cursor", &"iron", "삼중 저주 검술", "검격마다 독·출혈·감전 중 하나를 부여", "상태 위력과 지속시간 +40%", {"kanda_random_status": true}, {"kanda_random_status": true, "retainer_status_power": 1.4, "retainer_status_duration": 1.4}, [&"retainer", &"status", &"damage"]),
		_specialization(&"iron_relay", &"cursor", &"iron", "회오리 검무", "4번째 검격마다 주변을 휩쓰는 회오리 참격", "회오리 뒤 전방 마무리 참격 추가", {"kanda_whirlwind_cycle": 4, "kanda_whirlwind_damage": 0.7}, {"kanda_whirlwind_cycle": 4, "kanda_whirlwind_damage": 1.0, "kanda_final_slash": true}, [&"retainer", &"area", &"damage"]),
		# 심복: 기븐
		_specialization(&"silver_tracking", &"cursor", &"silver", "쾌락의 삼연타", "채찍을 3회 연속 휘두르되 환혹 판정은 연격당 1회", "연격 피해 +35% · 환혹 지속시간 +30%", {"given_strike_count": 3, "given_sequence_charm_rolls": 1, "given_strike_damage": 0.48}, {"given_strike_count": 3, "given_sequence_charm_rolls": 1, "given_strike_damage": 0.65, "given_charm_duration": 1.3}, [&"retainer", &"charm", &"damage"]),
		_specialization(&"silver_weakness", &"cursor", &"silver", "긴 채찍", "채찍 사거리 +40% · 가장자리 적 넉백 +55%", "사거리 +65% · 가장자리 넉백 +90%", {"area": 1.4, "given_edge_knockback": 1.55}, {"area": 1.65, "given_edge_knockback": 1.9}, [&"retainer", &"area", &"control"]),
		_specialization(&"silver_switch", &"cursor", &"silver", "매혹의 채찍", "출혈을 제거하고 환혹 확률을 크게 증가", "환혹 확률과 지속시간 추가 증가", {"given_bleed_disabled": true, "given_charm_chance": 0.48}, {"given_bleed_disabled": true, "given_charm_chance": 0.72, "given_charm_duration": 1.45}, [&"retainer", &"charm", &"control"]),
		# 심복: 저므조므
		_specialization(&"gold_experience", &"cursor", &"gold", "심연의 힘", "장판 중심부 피해 +55% · 범위 +20%", "중심부 피해 +95% · 둔화 강화", {"area": 1.2, "jeomujeom_center_damage": 1.55}, {"area": 1.35, "jeomujeom_center_damage": 1.95, "jeomujeom_slow_power": 1.35}, [&"retainer", &"area", &"damage"]),
		_specialization(&"gold_zone", &"cursor", &"gold", "심연 침식", "장판 누적 침식이 공포를 부여하며 제어 저항 적용", "공포가 인접 적 2명에게 약화 전파", {"jeomujeom_erosion_fear": true, "jeomujeom_fear_duration": 1.2}, {"jeomujeom_erosion_fear": true, "jeomujeom_fear_duration": 1.7, "jeomujeom_fear_spread": 2}, [&"retainer", &"fear", &"control"]),
		_specialization(&"gold_chain", &"cursor", &"gold", "심연 재소환", "직접 이동을 제거하고 지정 위치로 재소환", "도착 지점에 피해와 둔화 충격", {"jeomujeom_teleport": true, "movement": 0.01}, {"jeomujeom_teleport": true, "movement": 0.01, "jeomujeom_arrival_damage": 1.2, "jeomujeom_arrival_slow": 0.5}, [&"retainer", &"movement", &"area"]),
		# 심복: 주그디에드
		_specialization(&"platinum_charge", &"cursor", &"platinum", "영속 계약", "재구성 없이 행동하지만 합동 돌격 피해·넉백 -35%", "합동 돌격 페널티가 -15%로 완화", {"persistent_contract": true, "combo_damage": 0.65, "combo_knockback": 0.65}, {"persistent_contract": true, "combo_damage": 0.85, "combo_knockback": 0.85}, [&"retainer", &"combo", &"uptime"]),
		_specialization(&"platinum_shatter", &"cursor", &"platinum", "파멸 돌격", "합동 돌격 피해 +65% · 재구성 시간 +50%", "피해 +110% · 경로 폭 +30% · 재구성 시간 +80%", {"combo_damage": 1.65, "reconstruction_duration": 1.5}, {"combo_damage": 2.1, "combo_path_width": 1.3, "reconstruction_duration": 1.8}, [&"retainer", &"combo", &"risk"]),
		_specialization(&"platinum_boss", &"cursor", &"platinum", "망령마 돌진", "일반 공격에 망령마 범위 충격 추가", "망령마 충격 피해·범위 +50%", {"jugdied_horse_area": 0.55}, {"jugdied_horse_area": 0.85, "jugdied_horse_radius": 1.5}, [&"retainer", &"area", &"damage"]),
		# 심복: 죽음교 돌격부대
		_specialization(&"vanguard_impact", &"cursor", &"vanguard", "대부대 편성", "최대 인원 +2 · 인원 손실당 화력 감소 완화", "최대 인원 +3 · 손실 페널티 추가 완화", {"vanguard_member_bonus": 2, "vanguard_loss_penalty": 0.72}, {"vanguard_member_bonus": 3, "vanguard_loss_penalty": 0.52}, [&"retainer", &"squad", &"sustain"]),
		_specialization(&"vanguard_hunt", &"cursor", &"vanguard", "정기 희생", "9초마다 1명을 희생해 넓은 충격파", "희생 주기 단축 · 피해와 처형선 증가", {"vanguard_sacrifice_interval": 9.0, "vanguard_sacrifice_damage": 1.6}, {"vanguard_sacrifice_interval": 6.5, "vanguard_sacrifice_damage": 2.2, "vanguard_execute_bonus": 0.04}, [&"retainer", &"squad", &"damage"]),
		_specialization(&"vanguard_march", &"cursor", &"vanguard", "사신 소환진", "후보 액티브 시 현재 인원을 스냅샷하고 전원 희생해 사신 소환", "사신 피해·넉백·처형선 증가", {"vanguard_reaper_circle": true, "vanguard_reaper_damage": 2.2, "vanguard_reaper_knockback": 95.0}, {"vanguard_reaper_circle": true, "vanguard_reaper_damage": 3.2, "vanguard_reaper_knockback": 140.0, "vanguard_execute_bonus": 0.06}, [&"retainer", &"squad", &"active"]),
		# 핵: 베이직 에메랄드
		_specialization(&"emerald_prism", &"core", &"emerald", "프리즘 광선", "핵 공격·광선 피해 +30%, 광선 폭 증가", "목표지점에서 가장 가까운 적에게 55% 굴절", {"damage": 1.30, "beam_width": 1.35}, {"damage": 1.55, "beam_width": 1.65, "prism_refract": 0.55}, [&"core", &"damage", &"area"]),
		_specialization(&"emerald_resonance", &"core", &"emerald", "방어 공명", "핵 재생 +60% · 후방 타워 피해 +12%", "핵 피격 후 3초간 후방 타워 공속 +45%", {"regeneration": 1.60, "rear_tower_damage": 1.12}, {"regeneration": 2.20, "rear_tower_damage": 1.22, "rear_overcharge": true}, [&"core", &"health", &"global"]),
		_specialization(&"emerald_ballistics", &"core", &"emerald", "탄도 동기화", "목표지점 반경 적을 공격하는 타워 피해 +16%", "목표지점 공격 시 핵이 45% 피해로 추가 사격", {"cursor_tower_damage": 1.16}, {"cursor_tower_damage": 1.30, "core_follow_shot": 0.45}, [&"core", &"cursor", &"global"]),
		# 핵: 스피어 사파이어
		_specialization(&"sapphire_blast", &"core", &"sapphire", "관통 폭발", "마지막 관통 대상 주변에 45% 폭발", "폭발이 인접 적에게 55% 피해로 연쇄", {"pierce_explosion": 0.45}, {"pierce_explosion": 0.70, "pierce_explosion_chain": 0.55}, [&"core", &"area", &"damage"]),
		_specialization(&"sapphire_overheat", &"core", &"sapphire", "과열 속사", "연속 공격마다 공속 증가", "다섯 번째 공격이 220% 강화탄으로 발사", {"overheat_speed": 1.22}, {"overheat_speed": 1.38, "overheat_round": 2.20}, [&"core", &"speed", &"damage"]),
		_specialization(&"sapphire_rail", &"core", &"sapphire", "좌표 레일", "핵과 목표지점을 잇는 대역의 적 공격", "좌표 레일 폭 증가 · 전체 다중 관통", {"coordinate_rail": true}, {"coordinate_rail": true, "rail_width": 96.0}, [&"core", &"cursor", &"area"]),
		# 핵: 샤드 아메지스트
		_specialization(&"amethyst_fortress", &"core", &"amethyst", "근접 요새", "핵 내구도 +35% · 방사 공격 피해 +25%", "핵 주변 타워와 핵이 서로 피해를 강화", {"health": 1.35, "damage": 1.25}, {"health": 1.65, "damage": 1.45, "fortress_aura": 1.22}, [&"core", &"health", &"global"]),
		_specialization(&"amethyst_barrier", &"core", &"amethyst", "충격 장벽", "둔화벽 지속시간과 폭 증가", "장벽이 지속 피해와 넉백을 추가", {"wall_width": 1.35}, {"wall_width": 1.65, "wall_damage": 0.25, "wall_push": 70.0}, [&"core", &"control", &"area"]),
		_specialization(&"amethyst_counter", &"core", &"amethyst", "반격 결정", "핵 피격 시 공격자에게 핵 피해 80% 반격", "반격이 주변 적 3명에게 45% 파편으로 분열", {"counter": 0.80}, {"counter": 1.20, "counter_shards": 0.45}, [&"core", &"damage", &"health"]),
		# 핵: 네크로 제이드 / 이레라이
		_specialization(&"jade_highroll", &"core", &"jade", "즉시 재고용", "일반 적 사령 획득 확률 +15% · 친위대 재가동 속도 +35%", "획득 확률 총 40% · 재가동 속도 +75%", {"spirit_gain_chance_bonus": 0.15, "reactivation_speed": 1.35}, {"spirit_gain_chance_bonus": 0.25, "reactivation_speed": 1.75}, [&"core", &"necromancy", &"speed"]),
		_specialization(&"jade_stable", &"core", &"jade", "집단 부활", "사령 상한 +2 · 사령 피해 +25%", "사령 상한 +4 · 피해 +55% · 동시 사령 +2", {"spirit_capacity_bonus": 2, "spirit_damage": 1.25}, {"spirit_capacity_bonus": 4, "spirit_damage": 1.55, "spirit_simultaneous_bonus": 2}, [&"core", &"necromancy", &"area"]),
		_specialization(&"jade_chain", &"core", &"jade", "사후 복지", "친위대 체력 +45% · 지속 소모 -28% · 공격 소모 -20%", "체력 +80% · 지속 소모 -50% · 공격 소모 -40%", {"retainer_health": 1.45, "retainer_passive_drain": 0.72, "retainer_attack_cost": 0.80}, {"retainer_health": 1.80, "retainer_passive_drain": 0.50, "retainer_attack_cost": 0.60}, [&"core", &"necromancy", &"health"]),
		# 핵: 저지먼트 옵시디언
		_specialization(&"obsidian_sentence", &"core", &"obsidian", "최종 선고", "핵 공격 피해 +45% · 보스 피해 +25%", "체력 20% 이하 일반 적을 즉시 처형하고 보스에게 추가 피해", {"damage": 1.45, "boss_damage": 1.25}, {"damage": 1.70, "boss_damage": 1.50, "execute_ratio": 0.20}, [&"core", &"damage", &"boss"]),
		_specialization(&"obsidian_bell", &"core", &"obsidian", "심판의 종", "공격 5회마다 80% 범위 충격파", "충격파가 취약 표식과 강한 넉백을 함께 부여", {"ritual_hits": 5, "ritual_damage": 0.80}, {"ritual_hits": 4, "ritual_damage": 1.15, "collision_mark": 0.22}, [&"core", &"area", &"control"]),
		_specialization(&"obsidian_covenant", &"core", &"obsidian", "피의 계약", "핵 내구도 +30% · 재생 +45%", "핵 피격 후 3초간 핵과 전용 친위대 피해 +55%", {"health": 1.30, "regeneration": 1.45}, {"health": 1.55, "regeneration": 1.85, "rear_overcharge": true}, [&"core", &"health", &"global"]),
	]

func _enemy(id: StringName, name: String, behavior: StringName, health: float, speed: float, damage: float, xp: float, armor: float, available: float, color: Color, radius: float = 18.0, target_priority: float = 0.0) -> EnemyData:
	var item := EnemyData.new()
	item.id = id
	item.display_name = name
	item.behavior = behavior
	item.max_health = health
	item.move_speed = speed
	item.core_damage = damage
	item.experience_value = xp
	item.armor = armor
	item.available_from_seconds = available
	item.target_priority = target_priority
	item.body_color = color
	item.radius = radius
	item.texture = ConceptService.content_texture(&"enemies", id)
	return item

func _build_enemies() -> void:
	enemies = [
		_enemy(&"civilian_slime", "민간 슬라임", &"normal", 22.0, 58.0, 5.0, 2.0, 0.0, 0.0, Color("75d59b"), 14.0),
		_enemy(&"goblin_raider", "고블린 약탈병", &"fast", 30.0, 92.0, 7.0, 3.0, 0.0, 0.0, Color("b9c857"), 15.0),
		_enemy(&"skeleton_raider", "해골 습격병", &"fixed_diagonal", 55.0, 74.0, 9.0, 5.0, 0.0, 150.0, Color("d8d4c5"), 17.0),
		_enemy(&"orc_shield", "오크 방패병", &"armored", 135.0, 45.0, 15.0, 8.0, 4.0, 150.0, Color("668855"), 22.0),
		_enemy(&"hound_light_infantry", "마견 경보병", &"on_hit_speed", 72.0, 78.0, 11.0, 7.0, 1.0, 300.0, Color("b77b5c"), 18.0),
		_enemy(&"wraith_raider", "망령 습격자", &"death_disable", 82.0, 60.0, 10.0, 9.0, 1.0, 300.0, Color("9077c9"), 19.0),
		_enemy(&"steel_golem", "강철 골렘", &"heavy_resist", 260.0, 34.0, 22.0, 18.0, 7.0, 450.0, Color("6f8295"), 27.0),
	]
	_build_faction_enemies()
	var profiles_by_id: Dictionary = {}
	for profile in EnemyCatalogV015.build_spawn_profiles():
		profiles_by_id[profile.enemy_id] = profile
	for enemy in enemies + faction_enemies:
		var spawn_profile := profiles_by_id.get(enemy.id) as EnemySpawnProfileData
		if spawn_profile != null:
			enemy.spawn_cost = spawn_profile.spawn_cost
			enemy.role_tags.assign(spawn_profile.role_tags)
			enemy.available_from_seconds = spawn_profile.unlock_time
	_configure_v015_enemy_profiles()
	_configure_v015_faction_enemy_profiles()

func _build_faction_enemies() -> void:
	faction_enemies = [
		_enemy(&"partason_standard_shield", "마왕군 표준 방패병", &"faction_frontline", 155.0, 49.0, 17.0, 10.0, 5.0, 240.0, Color("5fcf8a"), 23.0),
		_enemy(&"jiane_succubus_bewitcher", "서큐버스 현혹대", &"killer_disable", 92.0, 66.0, 11.0, 10.0, 1.0, 240.0, Color("e785bd"), 19.0),
		_enemy(&"kasuha_abyss_creature", "심연의 피조물", &"self_decay", 380.0, 44.0, 20.0, 18.0, 3.0, 240.0, Color("9c72d8"), 28.0),
		_enemy(&"irelai_skeleton_cavalry", "해골 기병", &"formation_charge", 46.0, 96.0, 8.0, 4.0, 0.0, 240.0, Color("70c9c3"), 17.0),
		_enemy(&"judaginda_cult_applicant", "죽음교 입교 희망자", &"group_death_speed", 34.0, 70.0, 6.0, 3.0, 0.0, 240.0, Color("d95668"), 15.0),
	]

func _configure_v015_enemy_profiles() -> void:
	var skeleton := get_enemy(&"skeleton_raider")
	if skeleton != null:
		skeleton.movement_profile = EnemyMovementProfileData.new()
		skeleton.movement_profile.kind = &"fixed_diagonal"
	var hound := get_enemy(&"hound_light_infantry")
	if hound != null:
		hound.acceleration_profile = EnemyAccelerationProfileData.new()
	var wraith := get_enemy(&"wraith_raider")
	if wraith != null:
		wraith.death_effect_profile = EnemyDeathEffectProfileData.new()
		wraith.death_effect_profile.effect = &"disable_normal_defenders"
		wraith.death_effect_profile.radius = 170.0
		wraith.death_effect_profile.duration = 2.5
	var golem := get_enemy(&"steel_golem")
	if golem != null:
		golem.is_elite = true
		golem.knockback_resistance = 0.55
		golem.status_resistance = 0.45

func _configure_v015_faction_enemy_profiles() -> void:
	var partason := get_enemy(&"partason_standard_shield")
	if partason != null:
		partason.knockback_resistance = 0.20
	var succubus := get_enemy(&"jiane_succubus_bewitcher")
	if succubus != null:
		succubus.death_effect_profile = EnemyDeathEffectProfileData.new()
		succubus.death_effect_profile.effect = &"disable_killer_normal_defender"
		succubus.death_effect_profile.duration = 2.5
	var abyss := get_enemy(&"kasuha_abyss_creature")
	if abyss != null:
		abyss.decay_profile = EnemyDecayProfileData.new()
	var cavalry := get_enemy(&"irelai_skeleton_cavalry")
	if cavalry != null:
		cavalry.formation_profile = EnemyFormationProfileData.new()
		cavalry.formation_profile.kind = &"cavalry_formation"
		cavalry.formation_profile.tier_unit_counts = [3, 4, 6]
		cavalry.formation_profile.tier_cohort_counts = [1, 2, 2]
		cavalry.formation_profile.tier_stagger_seconds = [0.0, 0.0, 0.9]
		cavalry.formation_profile.unit_spacing_ratio = 0.035
		cavalry.formation_profile.cohort_axis_spacing_ratio = 0.16
		cavalry.formation_profile.separate_group_per_cohort = true
	var applicant := get_enemy(&"judaginda_cult_applicant")
	if applicant != null:
		applicant.group_acceleration_profile = EnemyGroupAccelerationProfileData.new()
		applicant.formation_profile = EnemyFormationProfileData.new()
		applicant.formation_profile.kind = &"single_group"
		applicant.formation_profile.tier_unit_counts = [4, 5, 8]
		applicant.formation_profile.tier_cohort_counts = [1, 1, 2]
		applicant.formation_profile.tier_stagger_seconds = [0.0, 0.0, 1.5]
		applicant.formation_profile.unit_spacing_ratio = 0.028
		applicant.formation_profile.cohort_axis_spacing_ratio = 0.12
		applicant.formation_profile.separate_group_per_cohort = true

func _build_bosses() -> void:
	var shared_control_profile := ControlResistanceProfileData.new()
	bosses = [
		_enemy(&"boss_5", "공식 난입 선봉장", &"boss_enrage", 1900.0, 30.0, 28.0, 100.0, 7.0, 150.0, Color("b86b55"), 38.0),
		_enemy(&"boss_10", "유세 방해 책임자", &"boss_disrupt", 3600.0, 35.0, 35.0, 180.0, 9.0, 300.0, Color("b45fbb"), 42.0),
		_enemy(&"boss_15", "경쟁 진영 근위대장", &"boss_summon", 6200.0, 38.0, 45.0, 280.0, 12.0, 450.0, Color("d19b4e"), 46.0),
		_enemy(&"final_boss", "최종 경쟁 후보", &"boss_final", 9000.0, 31.0, 70.0, 600.0, 12.0, 600.0, Color("e34f67"), 54.0),
		_enemy(&"judgment_bell", "심판의 종지기", &"boss_enrage", 5200.0, 36.0, 48.0, 320.0, 10.0, 450.0, Color("bd3546"), 47.0),
	]
	for index in bosses.size():
		bosses[index].is_boss = true
		bosses[index].boss_tier = index + 1
		bosses[index].control_resistance_profile = shared_control_profile
		bosses[index].knockback_resistance = 0.85 if bosses[index].id == &"judgment_bell" else (0.87 if bosses[index].id == &"final_boss" else 0.75 + index * 0.06)
		bosses[index].status_resistance = 0.52 if bosses[index].id == &"judgment_bell" else (0.56 if bosses[index].id == &"final_boss" else 0.35 + index * 0.1)
