class_name EnemyCatalogV015
extends RefCounted

const COMMON_IDS: Array[StringName] = [
	&"civilian_slime", &"goblin_raider", &"skeleton_raider", &"orc_shield",
	&"hound_light_infantry", &"wraith_raider", &"steel_golem",
]

const FACTION_IDS: Array[StringName] = [
	&"partason_standard_shield", &"jiane_succubus_bewitcher", &"kasuha_abyss_creature",
	&"irelai_skeleton_cavalry", &"judaginda_cult_applicant",
]

const FACTION_BY_ENEMY_ID := {
	&"partason_standard_shield": &"partason_faction",
	&"jiane_succubus_bewitcher": &"jiane_faction",
	&"kasuha_abyss_creature": &"kasuha_faction",
	&"irelai_skeleton_cavalry": &"irelai_faction",
	&"judaginda_cult_applicant": &"judaginda_faction",
}

const LEGACY_IDS: Array[StringName] = [
	&"normal", &"fast", &"swarm", &"armored", &"splitter", &"support", &"shifter", &"cleanser",
	&"disruptor", &"ranged", &"shielded", &"regenerator", &"charger", &"phase", &"sapper",
	&"guardian", &"zigzag", &"taunter",
]

# 저장 마이그레이션이 아니라 코드·스테이지 참조를 역할상 가장 가까운 v0.15 ID로 옮길 때 쓰는 검수표다.
const LEGACY_REFERENCE_MIGRATION := {
	&"normal": &"civilian_slime",
	&"fast": &"goblin_raider",
	&"swarm": &"civilian_slime",
	&"armored": &"orc_shield",
	&"splitter": &"civilian_slime",
	&"support": &"partason_standard_shield",
	&"shifter": &"skeleton_raider",
	&"cleanser": &"jiane_succubus_bewitcher",
	&"disruptor": &"wraith_raider",
	&"ranged": &"skeleton_raider",
	&"shielded": &"orc_shield",
	&"regenerator": &"kasuha_abyss_creature",
	&"charger": &"irelai_skeleton_cavalry",
	&"phase": &"jiane_succubus_bewitcher",
	&"sapper": &"judaginda_cult_applicant",
	&"guardian": &"partason_standard_shield",
	&"zigzag": &"skeleton_raider",
	&"taunter": &"wraith_raider",
}

static func all_ids() -> Array[StringName]:
	var result := COMMON_IDS.duplicate()
	result.append_array(FACTION_IDS)
	return result

static func build_spawn_profiles() -> Array[EnemySpawnProfileData]:
	return [
		_profile(&"civilian_slime", 3.0, _roles([&"basic", &"swarm"]), 0.0, &"", 3, 5),
		_profile(&"goblin_raider", 5.0, _roles([&"basic", &"fast"]), 0.0, &"", 2, 3),
		_profile(&"skeleton_raider", 8.0, _roles([&"fast", &"diagonal"]), 150.0, &"", 2, 2, 6.0),
		_profile(&"orc_shield", 12.0, _roles([&"frontline"]), 150.0),
		_profile(&"hound_light_infantry", 11.0, _roles([&"fast", &"on_hit_speed"]), 300.0, &"", 1, 2),
		_profile(&"wraith_raider", 14.0, _roles([&"disable"]), 300.0),
		_profile(&"steel_golem", 26.0, _roles([&"heavy", &"cc_resist"]), 450.0, &"", 1, 1, 30.0),
		_profile(&"partason_standard_shield", 15.0, _roles([&"faction", &"frontline"]), 240.0, &"partason_faction"),
		_profile(&"jiane_succubus_bewitcher", 16.0, _roles([&"faction", &"disable"]), 240.0, &"jiane_faction"),
		_profile(&"kasuha_abyss_creature", 22.0, _roles([&"faction", &"heavy", &"decay"]), 240.0, &"kasuha_faction"),
		_profile(&"irelai_skeleton_cavalry", 6.0, _roles([&"faction", &"fast", &"pack"]), 240.0, &"irelai_faction", 3, 5),
		_profile(&"judaginda_cult_applicant", 4.0, _roles([&"faction", &"pack", &"death_buff"]), 240.0, &"judaginda_faction", 4, 6),
	]

static func _roles(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	result.assign(values)
	return result

static func _profile(
	enemy_id: StringName,
	cost: float,
	roles: Array[StringName],
	unlock_time: float,
	faction_id: StringName = &"",
	group_min: int = 1,
	group_max: int = 1,
	rare_cooldown: float = 0.0
) -> EnemySpawnProfileData:
	return EnemySpawnProfileData.new().configure(enemy_id, cost, roles, unlock_time, faction_id, group_min, group_max, rare_cooldown)
