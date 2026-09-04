class_name V019CharacterStyleRefreshContractTest
extends RefCounted

const MANIFEST_PATH := "res://data/art/character_style_refresh_manifest_v1.json"
const ACTIVE_CATALOG_PATH := "res://data/concepts/demon_election_assets.tres"
const M6_REVIEW_CATALOG_PATH := "res://data/art/character_style_refresh_m6_review_catalog.json"
const EXPORT_PRESET_PATH := "res://export_presets.cfg"
const M7_DEVICE_TOOL_PATH := "res://tools/android_character_m7_validation.ps1"
const EXPECTED_REFERENCE_IDS := [
	"char_001", "char_002", "char_003", "char_004", "char_005", "char_006", "char_007",
	"char_008", "char_009", "char_010", "char_011", "char_012", "char_013",
]
const EXPECTED_PILOT_KEYS := [
	"defenders/rapid",
	"defenders/knockback",
	"towers/emerald_guardian",
	"retainer_sd/given",
	"retainer_sd/jeomujeom",
]
const EXPECTED_PILOT_PATHS := {
	"defenders/rapid": "res://assets/graphics/style_refresh_v019/defenders/rapid.png",
	"defenders/knockback": "res://assets/graphics/style_refresh_v019/defenders/knockback.png",
	"towers/emerald_guardian": "res://assets/graphics/style_refresh_v019/towers/emerald_guardian.png",
	"retainer_sd/given": "res://assets/graphics/style_refresh_v019/retainer_sd/given_v2.png",
	"retainer_sd/jeomujeom": "res://assets/graphics/style_refresh_v019/retainer_sd/jeomujeom_v2.png",
}
const EXPECTED_M2_DEFENDER_REFERENCES := {
	"rapid": "char_001",
	"pierce": "char_002",
	"area": "char_003",
	"execute": "char_004",
	"knockback": "char_005",
	"mark": "char_006",
	"slow": "char_010",
}
const EXPECTED_M2_CHARACTER_PAIRS := {
	"jugdied": {
		"reference_id": "char_007",
		"portrait_path": "res://assets/graphics/style_refresh_v019/retainers/jugdied.png",
		"sd_path": "res://assets/graphics/style_refresh_v019/retainer_sd/jugdied.png",
	},
	"death_vanguard": {
		"reference_id": "char_008",
		"portrait_path": "res://assets/graphics/style_refresh_v019/retainers/death_vanguard.png",
		"sd_path": "res://assets/graphics/style_refresh_v019/retainer_sd/death_vanguard.png",
	},
	"judaginda": {
		"reference_id": "char_009",
		"portrait_path": "res://assets/graphics/style_refresh_v019/candidates/judaginda.png",
		"sd_path": "res://assets/graphics/style_refresh_v019/candidate_sd/judaginda.png",
	},
	"given": {
		"reference_id": "char_012",
		"portrait_path": "res://assets/graphics/style_refresh_v019/retainers/given.png",
		"sd_path": "res://assets/graphics/style_refresh_v019/retainer_sd/given_v2.png",
	},
	"jeomujeom": {
		"reference_id": "char_013",
		"portrait_path": "res://assets/graphics/style_refresh_v019/retainers/jeomujeom.png",
		"sd_path": "res://assets/graphics/style_refresh_v019/retainer_sd/jeomujeom_v2.png",
	},
}
const EXPECTED_M3_DEFENDER_PAIRS := {
	"chain": {
		"full_body_path": "res://assets/graphics/style_refresh_v019/defenders/chain.png",
		"icon_path": "res://assets/graphics/style_refresh_v019/defender_icons/chain.png",
	},
	"rubber_golem": {
		"full_body_path": "res://assets/graphics/style_refresh_v019/defenders/rubber_golem.png",
		"icon_path": "res://assets/graphics/style_refresh_v019/defender_icons/rubber_golem.png",
	},
}
const EXPECTED_M3_KANDA_PATHS := {
	"portrait_path": "res://assets/graphics/style_refresh_v019/retainers/kanda.png",
	"sd_path": "res://assets/graphics/style_refresh_v019/retainer_sd/kanda.png",
}
const EXPECTED_M3_CANDIDATE_PAIRS := {
	"partason": {
		"portrait_path": "res://assets/graphics/style_refresh_v019/candidates/partason.png",
		"sd_path": "res://assets/graphics/style_refresh_v019/candidate_sd/partason.png",
	},
	"jiane": {
		"portrait_path": "res://assets/graphics/style_refresh_v019/candidates/jiane.png",
		"sd_path": "res://assets/graphics/style_refresh_v019/candidate_sd/jiane.png",
	},
	"kasuha": {
		"portrait_path": "res://assets/graphics/style_refresh_v019/candidates/kasuha.png",
		"sd_path": "res://assets/graphics/style_refresh_v019/candidate_sd/kasuha.png",
	},
	"irelai": {
		"portrait_path": "res://assets/graphics/style_refresh_v019/candidates/irelai.png",
		"sd_path": "res://assets/graphics/style_refresh_v019/candidate_sd/irelai.png",
	},
}
const EXPECTED_M3_GUARDS := {
	"sapphire_lance": {
		"legacy_active_path": "res://assets/graphics/towers/jiane_fanatic_follower.png",
		"path": "res://assets/graphics/style_refresh_v019/towers/sapphire_lance.png",
	},
	"amethyst_nova": {
		"legacy_active_path": "res://assets/graphics/towers/kasuha_abyss_believer.png",
		"path": "res://assets/graphics/style_refresh_v019/towers/amethyst_nova.png",
	},
	"jade_roulette": {
		"legacy_active_path": "res://assets/graphics/towers/irelai_resurrected_guard.png",
		"path": "res://assets/graphics/style_refresh_v019/towers/jade_roulette.png",
	},
	"obsidian_inquisitor": {
		"legacy_active_path": "res://assets/graphics/towers/obsidian_inquisitor.png",
		"path": "res://assets/graphics/style_refresh_v019/towers/obsidian_inquisitor.png",
	},
	"obsidian_verdict": {
		"legacy_active_path": "res://assets/graphics/towers/obsidian_verdict.png",
		"path": "res://assets/graphics/style_refresh_v019/towers/obsidian_verdict.png",
	},
}
const EXPECTED_M4_INTRUSIONS := {
	"partason": {"ally_category": "candidate_sd", "ally_path": "res://assets/graphics/combat_sd/candidates/partason.png", "intrusion_category": "candidate_intrusion_sd", "path": "res://assets/graphics/candidate_intrusion_sd/partason.png"},
	"jiane": {"ally_category": "candidate_sd", "ally_path": "res://assets/graphics/combat_sd/candidates/jiane.png", "intrusion_category": "candidate_intrusion_sd", "path": "res://assets/graphics/candidate_intrusion_sd/jiane.png"},
	"kasuha": {"ally_category": "candidate_sd", "ally_path": "res://assets/graphics/combat_sd/candidates/kasuha.png", "intrusion_category": "candidate_intrusion_sd", "path": "res://assets/graphics/candidate_intrusion_sd/kasuha.png"},
	"irelai": {"ally_category": "candidate_sd", "ally_path": "res://assets/graphics/combat_sd/candidates/irelai.png", "intrusion_category": "candidate_intrusion_sd", "path": "res://assets/graphics/candidate_intrusion_sd/irelai.png"},
	"judaginda": {"ally_category": "candidate_sd", "ally_path": "res://assets/graphics/combat_sd/candidates/judaginda.png", "intrusion_category": "candidate_intrusion_sd", "path": "res://assets/graphics/candidate_intrusion_sd/judaginda.png"},
	"kanda": {"ally_category": "retainer_sd", "ally_path": "res://assets/graphics/combat_sd/retainers/kanda.png", "intrusion_category": "retainer_intrusion_sd", "path": "res://assets/graphics/retainer_intrusion_sd/kanda.png"},
	"given": {"ally_category": "retainer_sd", "ally_path": "res://assets/graphics/combat_sd/retainers/given.png", "intrusion_category": "retainer_intrusion_sd", "path": "res://assets/graphics/retainer_intrusion_sd/given.png"},
	"jeomujeom": {"ally_category": "retainer_sd", "ally_path": "res://assets/graphics/combat_sd/retainers/jeomujeom.png", "intrusion_category": "retainer_intrusion_sd", "path": "res://assets/graphics/retainer_intrusion_sd/jeomujeom.png"},
	"jugdied": {"ally_category": "retainer_sd", "ally_path": "res://assets/graphics/combat_sd/retainers/jugdied.png", "intrusion_category": "retainer_intrusion_sd", "path": "res://assets/graphics/retainer_intrusion_sd/jugdied.png"},
	"death_vanguard": {"ally_category": "retainer_sd", "ally_path": "res://assets/graphics/combat_sd/retainers/death_vanguard.png", "intrusion_category": "retainer_intrusion_sd", "path": "res://assets/graphics/retainer_intrusion_sd/death_vanguard.png"},
}
const EXPECTED_OFFICIAL_M2_GUARDS := {
	"partason_faction": "emerald_guardian",
	"jiane_faction": "sapphire_lance",
	"kasuha_faction": "amethyst_nova",
	"irelai_faction": "jade_roulette",
	"judaginda_faction": "obsidian_verdict",
}
const EXPECTED_FACTIONS := {
	"partason_faction": {"primary": "#252831", "secondary": "#B8B9C1", "accent": "#C9A75D", "symbol": "sword_shield", "emblem_id": "partason_sword_shield", "legacy_marker": "crown", "legacy_emblem": "partason_crown"},
	"jiane_faction": {"primary": "#D83A91", "secondary": "#6E2A64", "accent": "#F6A3D1", "symbol": "heart", "emblem_id": "jiane_heart", "legacy_marker": "star", "legacy_emblem": "jiane_star"},
	"kasuha_faction": {"primary": "#50B84A", "secondary": "#1D4338", "accent": "#B8E65C", "symbol": "tentacle_eye", "emblem_id": "kasuha_tentacle_eye", "legacy_marker": "abyss", "legacy_emblem": "kasuha_abyss"},
	"irelai_faction": {"primary": "#80D9F5", "secondary": "#EAFBFF", "accent": "#A9C7FF", "symbol": "skull_aura", "emblem_id": "irelai_skull_aura", "legacy_marker": "spirit", "legacy_emblem": "irelai_spirit"},
	"judaginda_faction": {"primary": "#D4444A", "secondary": "#24242A", "accent": "#A5A7B0", "symbol": "scythe_blood", "emblem_id": "judaginda_scythe_blood", "legacy_marker": "judgment", "legacy_emblem": "judaginda_bell"},
}
const EXPECTED_M8_ATTACK_IDS := {
	"rapid": "defender_attacks", "area": "defender_attacks", "pierce": "defender_attacks",
	"slow": "defender_attacks", "knockback": "defender_attacks", "execute": "defender_attacks",
	"mark": "defender_attacks", "chain": "defender_attacks", "rubber_golem": "defender_attacks",
	"emerald_guardian": "tower_attacks", "sapphire_lance": "tower_attacks", "amethyst_nova": "tower_attacks",
	"jade_roulette": "tower_attacks", "obsidian_verdict": "tower_attacks", "obsidian_inquisitor": "tower_attacks",
}
const EXPECTED_ENEMY_P0_IDS := {
	"wraith_raider": true,
	"steel_golem": true,
	"hound_light_infantry": true,
	"kasuha_abyss_creature": true,
	"irelai_skeleton_cavalry": true,
	"enemy_test": true,
}
const EXPECTED_ENEMY_P1_IDS := {
	"goblin_raider": true,
	"skeleton_raider": true,
	"orc_shield": true,
	"partason_standard_shield": true,
}
const EXPECTED_ENEMY_P2_IDS := {
	"civilian_slime": true,
	"jiane_succubus_bewitcher": true,
	"judaginda_cult_applicant": true,
}
const EXPECTED_ENEMY_BOSS_IDS := {
	"boss_5": true,
	"boss_10": true,
	"boss_15": true,
	"final_boss": true,
	"judgment_bell": true,
}

static func run() -> Array[String]:
	var failures: Array[String] = []
	_expect(FileAccess.file_exists(MANIFEST_PATH), "the v0.19 character style refresh manifest must exist", failures)
	if not failures.is_empty():
		return failures
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	_expect(parsed is Dictionary, "the v0.19 character style refresh manifest must parse as a JSON object", failures)
	if not parsed is Dictionary:
		return failures
	var manifest := parsed as Dictionary
	_expect(int(manifest.get("schema_version", 0)) == 1, "the character style refresh manifest must use schema version 1", failures)
	_expect(String(manifest.get("status", "")) == "enemy_boss_style_refresh_active", "the art manifest must record the active enemy boss style refresh", failures)
	_expect(String(manifest.get("activation_policy", "")) == "category_batch_activated_after_m6_approval", "character refresh activation must record its approved category-batch transition", failures)
	_expect(FileAccess.file_exists(String(manifest.get("gdd", ""))), "the character style manifest must point to the authoritative v0.19 GDD", failures)
	_expect(FileAccess.file_exists(String(manifest.get("plan", ""))), "the character style manifest must point to its refresh plan", failures)
	_validate_style(manifest.get("style", {}) as Dictionary, failures)
	_validate_review(manifest.get("review", {}) as Dictionary, failures)
	_validate_factions(manifest.get("factions", []) as Array, failures)
	_validate_references(manifest.get("references", []) as Array, failures)
	_validate_pilots(manifest.get("pilots", []) as Array, failures)
	_validate_m2_defender_full_body(manifest.get("m2_defender_full_body", {}) as Dictionary, failures)
	_validate_m2_defender_icons(manifest.get("m2_defender_icons", {}) as Dictionary, failures)
	_validate_m2_character_pairs(manifest.get("m2_character_pairs", {}) as Dictionary, failures)
	_validate_m2_guard_application(manifest.get("m2_guard_application", {}) as Dictionary, failures)
	_validate_m3_missing_defenders(manifest.get("m3_missing_defenders", {}) as Dictionary, failures)
	_validate_m3_kanda_pair(manifest.get("m3_kanda_pair", {}) as Dictionary, failures)
	_validate_m3_candidate_pairs(manifest.get("m3_candidate_pairs", {}) as Dictionary, failures)
	_validate_m3_guard_full_body(manifest.get("m3_guard_full_body", {}) as Dictionary, failures)
	_validate_m4_intrusion_derivatives(manifest.get("m4_intrusion_derivatives", {}) as Dictionary, failures)
	_validate_official_intrusion_boss_m1_review(manifest.get("official_intrusion_boss_m1_review", {}) as Dictionary, failures)
	_validate_official_intrusion_boss_m2_guards(manifest.get("official_intrusion_boss_m2_guards", {}) as Dictionary, failures)
	_validate_official_intrusion_boss_m4_integration(manifest.get("official_intrusion_boss_m4_integration", {}) as Dictionary, failures)
	_validate_m5_faction_token_migration(manifest.get("m5_faction_token_migration", {}) as Dictionary, manifest.get("factions", []) as Array, failures)
	_validate_m6_catalog_activation(manifest.get("m6_catalog_activation", {}) as Dictionary, failures)
	_validate_m7_mobile_device_validation(manifest.get("m7_mobile_device_validation", {}) as Dictionary, failures)
	_validate_m8_attack_pose_activation(manifest.get("m8_attack_pose_activation", {}) as Dictionary, failures)
	_validate_enemy_p0_style_refresh(manifest.get("enemy_p0_style_refresh", {}) as Dictionary, failures)
	_validate_enemy_p1_style_refresh(manifest.get("enemy_p1_style_refresh", {}) as Dictionary, failures)
	_validate_enemy_p2_style_refresh(manifest.get("enemy_p2_style_refresh", {}) as Dictionary, failures)
	_validate_enemy_boss_style_refresh(manifest.get("enemy_boss_style_refresh", {}) as Dictionary, failures)
	var active_catalog_source := FileAccess.get_file_as_string(ACTIVE_CATALOG_PATH)
	_expect(not active_catalog_source.contains("style_refresh_v019"), "active character assets must resolve through stable canonical IDs instead of staging paths", failures)
	return failures

static func _validate_m7_mobile_device_validation(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "device_ready_waiting_for_authorized_android_target", "M7 must distinguish device-ready tooling from physical-device approval", failures)
	_expect(String(section.get("validation_tool", "")) == M7_DEVICE_TOOL_PATH and FileAccess.file_exists(M7_DEVICE_TOOL_PATH), "M7 must provide its reproducible Android device validation tool", failures)
	_expect(String(section.get("export_preset", "")) == "Android", "M7 must target the configured Android export preset", failures)
	_expect(String(section.get("build_status", "")) == "debug_build_and_v2_v3_signature_verified", "M7 must record the verified signed debug build state", failures)
	_expect(int(section.get("connected_device_count", -1)) == 0 and not String(section.get("blocker", "")).is_empty(), "M7 must keep physical-device approval blocked while no authorized target exists", failures)
	var exclusions := section.get("runtime_export_exclusions", []) as Array
	for exclusion in ["tests/*", "assets/graphics/style_refresh_v019/*", "tools/*", "reference/*", "data/art/*", "scripts/game/balance_audit_summary.gd*", "scripts/meta/first_five_run_economy_audit.gd*", "scenes/ui/components/icon_chip.tscn", "scripts/ui/components/icon_chip.gd*"]:
		_expect(exclusions.has(exclusion), "M7 Android export must exclude non-runtime path '%s'" % exclusion, failures)
	_expect(FileAccess.file_exists(EXPORT_PRESET_PATH), "the Android export preset must exist", failures)
	var export_source := FileAccess.get_file_as_string(EXPORT_PRESET_PATH)
	_expect(
		export_source.contains('exclude_filter="')
		and "tests/*" in export_source
		and "assets/graphics/style_refresh_v019/*" in export_source
		and "tools/*" in export_source
		and "reference/*" in export_source
		and "data/art/*" in export_source
		and "scripts/game/balance_audit_summary.gd*" in export_source
		and "scripts/meta/first_five_run_economy_audit.gd*" in export_source
		and "scenes/ui/components/icon_chip.tscn" in export_source
		and "scripts/ui/components/icon_chip.gd*" in export_source,
		"the Android preset must exclude tests, review sources, references, audit helpers, and test-only UI components",
		failures
	)
	var pre_bytes := int(section.get("pre_exclusion_apk_bytes", 0))
	var optimized_bytes := int(section.get("optimized_apk_bytes", 0))
	_expect(pre_bytes > optimized_bytes and optimized_bytes > 0, "M7 must record an APK reduction after excluding duplicated review masters", failures)
	_expect(int(section.get("apk_reduction_bytes", 0)) == pre_bytes - optimized_bytes and float(section.get("apk_reduction_percent", 0.0)) >= 10.0, "M7 APK reduction metrics must be internally consistent and material", failures)
	var package_audit := section.get("package_audit", {}) as Dictionary
	_expect(int(package_audit.get("active_character_import_entries", 0)) == 54, "the Android APK must retain all 54 active character imports after excluding review masters", failures)
	_expect(int(package_audit.get("style_refresh_staging_entries", -1)) == 0, "the Android APK must contain no style-refresh staging entries", failures)
	_expect(int(package_audit.get("test_entries", -1)) == 0 and int(package_audit.get("tool_entries", -1)) == 0, "the Android APK must contain no tests or developer tools", failures)
	_expect(int(package_audit.get("arm64_godot_library_count", 0)) == 1 and int(package_audit.get("other_abi_library_count", -1)) == 0, "the Android debug APK must remain arm64-only", failures)
	var required_samples := section.get("required_device_samples", []) as Array
	for sample in ["startup_and_safe_area", "combat_1x", "combat_3x", "prelude_to_boss_transition", "reduced_motion_3x"]:
		_expect(required_samples.has(sample), "M7 device plan must retain sample '%s'" % sample, failures)
	var required_metrics := section.get("required_device_metrics", []) as Array
	for metric in ["gfxinfo_framestats", "memory_start_end", "thermal_end", "battery_start_end", "logcat", "screen_start_end"]:
		_expect(required_metrics.has(metric), "M7 device tool must retain metric '%s'" % metric, failures)
	var tool_source := FileAccess.get_file_as_string(M7_DEVICE_TOOL_PATH)
	for marker in ["dumpsys\", \"gfxinfo", "dumpsys\", \"meminfo", "dumpsys\", \"thermalservice", "dumpsys\", \"battery", "screencap", "logcat"]:
		_expect(tool_source.contains(marker), "M7 device tool must collect '%s'" % marker, failures)

static func _validate_m8_attack_pose_activation(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "active", "M8 defender attack poses must be active", failures)
	_expect(String(section.get("generation_tool", "")) == "built_in_imagegen", "M8 must record the built-in ImageGen source", failures)
	_expect(is_equal_approx(float(section.get("runtime_window_seconds", 0.0)), 0.18), "M8 attack poses must record the 0.18 second runtime window", failures)
	_expect(not String(section.get("fallback_policy", "")).is_empty(), "M8 must document the idle-art fallback for external packs", failures)
	var assets := section.get("assets", []) as Array
	_expect(assets.size() == EXPECTED_M8_ATTACK_IDS.size(), "M8 must register all 15 defender attack poses", failures)
	var seen: Dictionary = {}
	for raw_asset in assets:
		var asset := raw_asset as Dictionary
		var content_id := String(asset.get("content_id", ""))
		var category := String(asset.get("category", ""))
		var path := String(asset.get("path", ""))
		_expect(EXPECTED_M8_ATTACK_IDS.has(content_id), "M8 has an unknown attack-pose id '%s'" % content_id, failures)
		_expect(category == String(EXPECTED_M8_ATTACK_IDS.get(content_id, "")), "M8 attack-pose category mismatch for '%s'" % content_id, failures)
		_expect(path == "res://assets/graphics/%s/%s.png" % [category, content_id] and FileAccess.file_exists(path), "M8 attack-pose path must exist for '%s'" % content_id, failures)
		var import_path := "%s.import" % path
		_expect(FileAccess.file_exists(import_path) and FileAccess.get_file_as_string(import_path).contains("process/size_limit=512"), "M8 attack-pose import must preserve the 512px mobile cap for '%s'" % content_id, failures)
		seen[content_id] = true
	_expect(seen.size() == EXPECTED_M8_ATTACK_IDS.size(), "M8 attack-pose manifest IDs must be unique", failures)

static func _validate_enemy_p0_style_refresh(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "active", "enemy P0 style refresh must be active", failures)
	_expect(String(section.get("generation_tool", "")) == "built_in_imagegen", "enemy P0 refresh must record the built-in ImageGen source", failures)
	_expect(int(section.get("master_size", 0)) == 1254, "enemy P0 masters must use the 1254px source contract", failures)
	_expect(int(section.get("runtime_texture_limit", 0)) == 512, "enemy P0 runtime textures must use the 512px mobile cap", failures)
	_expect(float(section.get("minimum_safe_margin_ratio", 0.0)) >= 0.07, "enemy P0 masters must require at least seven percent safe margin", failures)
	var review_sizes := section.get("review_sizes", []) as Array
	_expect(review_sizes.size() == 3 and int(review_sizes[0]) == 48 and int(review_sizes[1]) == 64 and int(review_sizes[2]) == 96, "enemy P0 review must cover 48px, 64px, and 96px", failures)
	_expect(FileAccess.file_exists(String(section.get("normalization_tool", ""))), "enemy P0 normalization tool must remain reproducible", failures)
	_expect(FileAccess.file_exists(String(section.get("review_capture", ""))), "enemy P0 small-size comparison capture must exist", failures)
	var assets := section.get("assets", []) as Array
	_expect(assets.size() == EXPECTED_ENEMY_P0_IDS.size(), "enemy P0 refresh must register exactly six active assets", failures)
	var seen: Dictionary = {}
	for value in assets:
		var asset := value as Dictionary
		var content_id := String(asset.get("content_id", ""))
		var staging_path := String(asset.get("staging_path", ""))
		var active_path := String(asset.get("active_path", ""))
		_expect(EXPECTED_ENEMY_P0_IDS.has(content_id), "enemy P0 refresh has an unknown id '%s'" % content_id, failures)
		_expect(not seen.has(content_id), "enemy P0 refresh ids must be unique: '%s'" % content_id, failures)
		seen[content_id] = true
		_expect(staging_path == "res://assets/graphics/style_refresh_v019/enemy_p0/%s.png" % content_id, "enemy P0 staging path mismatch for '%s'" % content_id, failures)
		_expect(active_path == "res://assets/graphics/enemies/%s.png" % content_id, "enemy P0 active path mismatch for '%s'" % content_id, failures)
		_expect(FileAccess.file_exists(staging_path) and FileAccess.file_exists(active_path), "enemy P0 source and active asset must exist for '%s'" % content_id, failures)
		if FileAccess.file_exists(staging_path) and FileAccess.file_exists(active_path):
			var declared_hash := String(asset.get("sha256", ""))
			_expect(declared_hash.length() == 64 and FileAccess.get_sha256(staging_path) == declared_hash, "enemy P0 declared source hash mismatch for '%s'" % content_id, failures)
			_expect(FileAccess.get_sha256(active_path) == declared_hash, "enemy P0 active file must exactly match the reviewed master for '%s'" % content_id, failures)
			var image := Image.load_from_file(ProjectSettings.globalize_path(staging_path))
			_validate_pilot_image(image, "enemy_p0/%s" % content_id, failures)
			_validate_safe_margin(image, "enemy_p0/%s" % content_id, failures)
			var texture := load(active_path) as Texture2D
			_expect(texture != null and texture.get_size() == Vector2(512, 512), "enemy P0 active texture must import at 512px for '%s'" % content_id, failures)
		var import_path := "%s.import" % active_path
		_expect(FileAccess.file_exists(import_path) and FileAccess.get_file_as_string(import_path).contains("process/size_limit=512"), "enemy P0 active import must preserve the 512px cap for '%s'" % content_id, failures)
		_expect((asset.get("identity_contract", []) as Array).size() >= 5, "enemy P0 identity contract must preserve five defining cues for '%s'" % content_id, failures)
	_expect(seen.size() == EXPECTED_ENEMY_P0_IDS.size(), "enemy P0 manifest IDs must be complete", failures)

static func _validate_enemy_p1_style_refresh(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "active", "enemy P1 style refresh must be active", failures)
	_expect(String(section.get("generation_tool", "")) == "built_in_imagegen", "enemy P1 refresh must record the built-in ImageGen source", failures)
	_expect(int(section.get("master_size", 0)) == 1254, "enemy P1 masters must use the 1254px source contract", failures)
	_expect(int(section.get("runtime_texture_limit", 0)) == 512, "enemy P1 runtime textures must use the 512px mobile cap", failures)
	_expect(float(section.get("minimum_safe_margin_ratio", 0.0)) >= 0.07, "enemy P1 masters must require at least seven percent safe margin", failures)
	var review_sizes := section.get("review_sizes", []) as Array
	_expect(review_sizes.size() == 3 and int(review_sizes[0]) == 48 and int(review_sizes[1]) == 64 and int(review_sizes[2]) == 96, "enemy P1 review must cover 48px, 64px, and 96px", failures)
	_expect(FileAccess.file_exists(String(section.get("normalization_tool", ""))), "enemy P1 normalization tool must remain reproducible", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))), "enemy P1 review scene must remain reproducible", failures)
	var review_capture := String(section.get("review_capture", ""))
	_expect(FileAccess.file_exists(review_capture), "enemy P1 small-size comparison capture must exist", failures)
	if FileAccess.file_exists(review_capture):
		var capture := Image.load_from_file(ProjectSettings.globalize_path(review_capture))
		_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "enemy P1 review capture must remain 1280x720", failures)
	var assets := section.get("assets", []) as Array
	_expect(assets.size() == EXPECTED_ENEMY_P1_IDS.size(), "enemy P1 refresh must register exactly four active assets", failures)
	var seen: Dictionary = {}
	for value in assets:
		var asset := value as Dictionary
		var content_id := String(asset.get("content_id", ""))
		var staging_path := String(asset.get("staging_path", ""))
		var active_path := String(asset.get("active_path", ""))
		_expect(EXPECTED_ENEMY_P1_IDS.has(content_id), "enemy P1 refresh has an unknown id '%s'" % content_id, failures)
		_expect(not seen.has(content_id), "enemy P1 refresh ids must be unique: '%s'" % content_id, failures)
		seen[content_id] = true
		_expect(staging_path == "res://assets/graphics/style_refresh_v019/enemy_p1/%s.png" % content_id, "enemy P1 staging path mismatch for '%s'" % content_id, failures)
		_expect(active_path == "res://assets/graphics/enemies/%s.png" % content_id, "enemy P1 active path mismatch for '%s'" % content_id, failures)
		_expect(FileAccess.file_exists(staging_path) and FileAccess.file_exists(active_path), "enemy P1 source and active asset must exist for '%s'" % content_id, failures)
		if FileAccess.file_exists(staging_path) and FileAccess.file_exists(active_path):
			var declared_hash := String(asset.get("sha256", ""))
			_expect(declared_hash.length() == 64 and FileAccess.get_sha256(staging_path) == declared_hash, "enemy P1 declared source hash mismatch for '%s'" % content_id, failures)
			_expect(FileAccess.get_sha256(active_path) == declared_hash, "enemy P1 active file must exactly match the reviewed master for '%s'" % content_id, failures)
			var image := Image.load_from_file(ProjectSettings.globalize_path(staging_path))
			_validate_pilot_image(image, "enemy_p1/%s" % content_id, failures)
			_validate_safe_margin(image, "enemy_p1/%s" % content_id, failures)
			var texture := load(active_path) as Texture2D
			_expect(texture != null and texture.get_size() == Vector2(512, 512), "enemy P1 active texture must import at 512px for '%s'" % content_id, failures)
		var import_path := "%s.import" % active_path
		_expect(FileAccess.file_exists(import_path) and FileAccess.get_file_as_string(import_path).contains("process/size_limit=512"), "enemy P1 active import must preserve the 512px cap for '%s'" % content_id, failures)
		var identity_contract := asset.get("identity_contract", []) as Array
		_expect(identity_contract.size() >= 5 and "_".join(PackedStringArray(identity_contract)).contains("left_facing"), "enemy P1 identity contract must preserve role cues and left-facing direction for '%s'" % content_id, failures)
	_expect(seen.size() == EXPECTED_ENEMY_P1_IDS.size(), "enemy P1 manifest IDs must be complete", failures)

static func _validate_enemy_p2_style_refresh(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "active", "enemy P2 style refresh must be active", failures)
	_expect(String(section.get("generation_tool", "")) == "built_in_imagegen", "enemy P2 refresh must record the built-in ImageGen source", failures)
	_expect(int(section.get("master_size", 0)) == 1254, "enemy P2 masters must use the 1254px source contract", failures)
	_expect(int(section.get("runtime_texture_limit", 0)) == 512, "enemy P2 runtime textures must use the 512px mobile cap", failures)
	_expect(float(section.get("minimum_safe_margin_ratio", 0.0)) >= 0.07, "enemy P2 masters must require at least seven percent safe margin", failures)
	var review_sizes := section.get("review_sizes", []) as Array
	_expect(review_sizes.size() == 4 and int(review_sizes[0]) == 36 and int(review_sizes[1]) == 48 and int(review_sizes[2]) == 64 and int(review_sizes[3]) == 96, "enemy P2 review must cover 36px, 48px, 64px, and 96px", failures)
	_expect(int(section.get("review_density_units", 0)) == 8, "enemy P2 review must include an eight-unit density row", failures)
	_expect(FileAccess.file_exists(String(section.get("normalization_tool", ""))), "enemy P2 normalization tool must remain reproducible", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))), "enemy P2 review scene must remain reproducible", failures)
	var review_capture := String(section.get("review_capture", ""))
	_expect(FileAccess.file_exists(review_capture), "enemy P2 small-size and density comparison capture must exist", failures)
	if FileAccess.file_exists(review_capture):
		var capture := Image.load_from_file(ProjectSettings.globalize_path(review_capture))
		_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "enemy P2 review capture must remain 1280x720", failures)
	_expect(String(section.get("runtime_direction_policy", "")) == "direct_left_facing_art_no_id_scoped_correction", "enemy P2 runtime direction must use direct left-facing art", failures)
	var enemy_source := FileAccess.get_file_as_string("res://scripts/actors/enemy.gd")
	_expect(not enemy_source.contains("LEFT_FACING_ART_CORRECTION_IDS"), "enemy P2 direct art must remove the obsolete ID-scoped direction correction", failures)
	var assets := section.get("assets", []) as Array
	_expect(assets.size() == EXPECTED_ENEMY_P2_IDS.size(), "enemy P2 refresh must register exactly three active assets", failures)
	var seen: Dictionary = {}
	for value in assets:
		var asset := value as Dictionary
		var content_id := String(asset.get("content_id", ""))
		var staging_path := String(asset.get("staging_path", ""))
		var active_path := String(asset.get("active_path", ""))
		_expect(EXPECTED_ENEMY_P2_IDS.has(content_id), "enemy P2 refresh has an unknown id '%s'" % content_id, failures)
		_expect(not seen.has(content_id), "enemy P2 refresh ids must be unique: '%s'" % content_id, failures)
		seen[content_id] = true
		_expect(staging_path == "res://assets/graphics/style_refresh_v019/enemy_p2/%s.png" % content_id, "enemy P2 staging path mismatch for '%s'" % content_id, failures)
		_expect(active_path == "res://assets/graphics/enemies/%s.png" % content_id, "enemy P2 active path mismatch for '%s'" % content_id, failures)
		_expect(FileAccess.file_exists(staging_path) and FileAccess.file_exists(active_path), "enemy P2 source and active asset must exist for '%s'" % content_id, failures)
		if FileAccess.file_exists(staging_path) and FileAccess.file_exists(active_path):
			var declared_hash := String(asset.get("sha256", ""))
			_expect(declared_hash.length() == 64 and FileAccess.get_sha256(staging_path) == declared_hash, "enemy P2 declared source hash mismatch for '%s'" % content_id, failures)
			_expect(FileAccess.get_sha256(active_path) == declared_hash, "enemy P2 active file must exactly match the reviewed master for '%s'" % content_id, failures)
			var image := Image.load_from_file(ProjectSettings.globalize_path(staging_path))
			_validate_pilot_image(image, "enemy_p2/%s" % content_id, failures)
			_validate_safe_margin(image, "enemy_p2/%s" % content_id, failures)
			var texture := load(active_path) as Texture2D
			_expect(texture != null and texture.get_size() == Vector2(512, 512), "enemy P2 active texture must import at 512px for '%s'" % content_id, failures)
		var import_path := "%s.import" % active_path
		_expect(FileAccess.file_exists(import_path) and FileAccess.get_file_as_string(import_path).contains("process/size_limit=512"), "enemy P2 active import must preserve the 512px cap for '%s'" % content_id, failures)
		var identity_contract := asset.get("identity_contract", []) as Array
		_expect(identity_contract.size() >= 5 and "_".join(PackedStringArray(identity_contract)).contains("left_facing"), "enemy P2 identity contract must preserve role cues and left-facing direction for '%s'" % content_id, failures)
	_expect(seen.size() == EXPECTED_ENEMY_P2_IDS.size(), "enemy P2 manifest IDs must be complete", failures)

static func _validate_enemy_boss_style_refresh(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "active", "enemy boss style refresh must be active", failures)
	_expect(String(section.get("generation_tool", "")) == "built_in_imagegen", "enemy boss refresh must record the built-in ImageGen source", failures)
	_expect(int(section.get("master_size", 0)) == 1254, "enemy boss masters must use the 1254px source contract", failures)
	_expect(int(section.get("runtime_texture_limit", 0)) == 512, "enemy boss runtime textures must use the 512px mobile cap", failures)
	_expect(float(section.get("minimum_safe_margin_ratio", 0.0)) >= 0.07, "enemy boss masters must require at least seven percent safe margin", failures)
	var review_sizes := section.get("review_sizes", []) as Array
	_expect(review_sizes.size() == 4 and int(review_sizes[0]) == 48 and int(review_sizes[1]) == 64 and int(review_sizes[2]) == 96 and int(review_sizes[3]) == 220, "enemy boss review must cover 48px, 64px, 96px, and 220px", failures)
	_expect(FileAccess.file_exists(String(section.get("normalization_tool", ""))), "enemy boss normalization tool must remain reproducible", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))), "enemy boss review scene must remain reproducible", failures)
	var review_capture := String(section.get("review_capture", ""))
	_expect(FileAccess.file_exists(review_capture), "enemy boss small-size comparison capture must exist", failures)
	if FileAccess.file_exists(review_capture):
		var capture := Image.load_from_file(ProjectSettings.globalize_path(review_capture))
		_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "enemy boss review capture must remain 1280x720", failures)
	_expect(int(section.get("dedicated_identity_count", 0)) == EXPECTED_ENEMY_BOSS_IDS.size(), "enemy boss refresh must record five dedicated identities", failures)
	_expect(String(section.get("removed_alias", "")) == "enemies/judgment_bell -> enemies/final_boss", "enemy boss refresh must record the removed judgment bell alias", failures)
	var assets := section.get("assets", []) as Array
	_expect(assets.size() == EXPECTED_ENEMY_BOSS_IDS.size(), "enemy boss refresh must register exactly five active assets", failures)
	var seen: Dictionary = {}
	var hashes: Dictionary = {}
	for value in assets:
		var asset := value as Dictionary
		var content_id := String(asset.get("content_id", ""))
		var staging_path := String(asset.get("staging_path", ""))
		var active_path := String(asset.get("active_path", ""))
		_expect(EXPECTED_ENEMY_BOSS_IDS.has(content_id), "enemy boss refresh has an unknown id '%s'" % content_id, failures)
		_expect(not seen.has(content_id), "enemy boss refresh ids must be unique: '%s'" % content_id, failures)
		seen[content_id] = true
		_expect(staging_path == "res://assets/graphics/style_refresh_v019/enemy_bosses/%s.png" % content_id, "enemy boss staging path mismatch for '%s'" % content_id, failures)
		_expect(active_path == "res://assets/graphics/enemies/%s.png" % content_id, "enemy boss active path mismatch for '%s'" % content_id, failures)
		_expect(FileAccess.file_exists(staging_path) and FileAccess.file_exists(active_path), "enemy boss source and active asset must exist for '%s'" % content_id, failures)
		if FileAccess.file_exists(staging_path) and FileAccess.file_exists(active_path):
			var declared_hash := String(asset.get("sha256", ""))
			_expect(declared_hash.length() == 64 and FileAccess.get_sha256(staging_path) == declared_hash, "enemy boss declared source hash mismatch for '%s'" % content_id, failures)
			_expect(FileAccess.get_sha256(active_path) == declared_hash, "enemy boss active file must exactly match the reviewed master for '%s'" % content_id, failures)
			hashes[content_id] = declared_hash
			var image := Image.load_from_file(ProjectSettings.globalize_path(staging_path))
			_validate_pilot_image(image, "enemy_boss/%s" % content_id, failures)
			_validate_safe_margin(image, "enemy_boss/%s" % content_id, failures)
			var texture := load(active_path) as Texture2D
			_expect(texture != null and texture.get_size() == Vector2(512, 512), "enemy boss active texture must import at 512px for '%s'" % content_id, failures)
		var import_path := "%s.import" % active_path
		_expect(FileAccess.file_exists(import_path) and FileAccess.get_file_as_string(import_path).contains("process/size_limit=512"), "enemy boss active import must preserve the 512px cap for '%s'" % content_id, failures)
		_expect((asset.get("identity_contract", []) as Array).size() >= 5, "enemy boss identity contract must preserve five defining cues for '%s'" % content_id, failures)
	_expect(seen.size() == EXPECTED_ENEMY_BOSS_IDS.size(), "enemy boss manifest IDs must be complete", failures)
	_expect(String(hashes.get("final_boss", "")) != String(hashes.get("judgment_bell", "")), "judgment_bell must not reuse final_boss pixels", failures)
	var judgment_source := FileAccess.get_file_as_string("res://data/content/demon_election/bosses/judgment_bell.tres")
	_expect(judgment_source.contains("res://assets/graphics/enemies/judgment_bell.png") and not judgment_source.contains("res://assets/graphics/enemies/final_boss.png"), "judgment_bell data must bind its dedicated active texture", failures)
	for catalog_path in ["res://data/concepts/demon_election_assets.tres", "res://data/concepts/formation_defense_assets.tres"]:
		_expect(not FileAccess.get_file_as_string(catalog_path).contains("enemies/judgment_bell"), "active catalog must not retain the removed judgment_bell alias: '%s'" % catalog_path, failures)

static func _validate_style(style: Dictionary, failures: Array[String]) -> void:
	_expect(String(style.get("canvas", "")) == "square", "character refresh masters must use square canvases", failures)
	_expect(String(style.get("player_facing", "")) == "right" and String(style.get("enemy_facing", "")) == "left", "character refresh direction must keep players right-facing and enemies left-facing", failures)
	_expect(float(style.get("target_safe_margin_ratio", 0.0)) >= 0.07, "character refresh masters must target at least seven percent safety margin", failures)
	var review_sizes := style.get("review_sizes", []) as Array
	_expect(review_sizes.size() == 3 and int(review_sizes[0]) == 48 and int(review_sizes[1]) == 64 and int(review_sizes[2]) == 96, "character refresh pilots must be reviewed at 48px, 64px, and 96px", failures)
	var transparent_categories := style.get("transparent_categories", []) as Array
	for category in ["defenders", "defender_attacks", "defender_icons", "towers", "tower_attacks", "candidates", "candidate_sd", "candidate_intrusion_sd", "retainers", "retainer_sd", "retainer_intrusion_sd", "guard_intrusion_sd", "enemies"]:
		_expect(transparent_categories.has(category), "character refresh alpha contract must cover '%s'" % category, failures)

static func _validate_review(review: Dictionary, failures: Array[String]) -> void:
	_expect(String(review.get("result", "")) == "approved_for_m2_derivation", "the M1 visual review must preserve its derivation approval verdict", failures)
	_expect(FileAccess.file_exists(String(review.get("scene", ""))), "the character pilot review scene must exist", failures)
	_expect(FileAccess.file_exists(String(review.get("capture", ""))), "the rendered character pilot comparison must exist", failures)
	_expect((review.get("findings", []) as Array).size() >= 3, "the character pilot review must record its small-size findings", failures)

static func _validate_factions(factions: Array, failures: Array[String]) -> void:
	_expect(factions.size() == EXPECTED_FACTIONS.size(), "the character style manifest must define all five faction token sets", failures)
	var seen: Dictionary = {}
	for value in factions:
		var faction := value as Dictionary
		var faction_id := String(faction.get("id", ""))
		_expect(EXPECTED_FACTIONS.has(faction_id), "unexpected character style faction '%s'" % faction_id, failures)
		_expect(not seen.has(faction_id), "character style faction ids must be unique: '%s'" % faction_id, failures)
		seen[faction_id] = true
		if not EXPECTED_FACTIONS.has(faction_id):
			continue
		var expected := EXPECTED_FACTIONS[faction_id] as Dictionary
		for field in ["primary", "secondary", "accent", "symbol", "legacy_marker"]:
			_expect(String(faction.get(field, "")) == String(expected[field]), "faction '%s' must preserve the approved %s token" % [faction_id, field], failures)
		for color_field in ["primary", "secondary", "accent"]:
			var color_value := String(faction.get(color_field, ""))
			_expect(color_value.length() == 7 and color_value.begins_with("#") and Color.from_string(color_value, Color.TRANSPARENT) != Color.TRANSPARENT, "faction '%s' must define a valid opaque %s color" % [faction_id, color_field], failures)

static func _validate_references(references: Array, failures: Array[String]) -> void:
	_expect(references.size() == EXPECTED_REFERENCE_IDS.size(), "the character style manifest must map all 13 reference images", failures)
	var seen: Dictionary = {}
	for value in references:
		var mapping := value as Dictionary
		var reference_id := String(mapping.get("reference_id", ""))
		_expect(EXPECTED_REFERENCE_IDS.has(reference_id), "unexpected character reference mapping '%s'" % reference_id, failures)
		_expect(not seen.has(reference_id), "character reference ids must be unique: '%s'" % reference_id, failures)
		seen[reference_id] = true
		var source := String(mapping.get("source", ""))
		_expect(source == "res://reference/%s.png" % reference_id, "reference '%s' must keep its stable source path" % reference_id, failures)
		_expect(FileAccess.file_exists(source), "reference source must exist: '%s'" % source, failures)
		var targets := mapping.get("targets", []) as Array
		_expect(not targets.is_empty(), "reference '%s' must map to at least one stable content target" % reference_id, failures)
		_expect(not String(mapping.get("decision", "")).is_empty() and not String(mapping.get("adaptation", "")).is_empty(), "reference '%s' must record an approved adaptation decision" % reference_id, failures)
		if FileAccess.file_exists(source):
			var image := Image.load_from_file(ProjectSettings.globalize_path(source))
			_expect(image != null and image.get_size() == Vector2i(1254, 1254), "reference '%s' must remain the audited 1254px square source" % reference_id, failures)
	for reference_id in EXPECTED_REFERENCE_IDS:
		_expect(seen.has(reference_id), "missing character reference mapping '%s'" % reference_id, failures)
	var conditional_decisions := {
		"char_006": "approved_with_motif_change",
		"char_009": "approved_with_identity_split",
		"char_012": "approved_costume_accessory",
	}
	for reference_id in conditional_decisions:
		var mapping := _find_by_id(references, reference_id)
		_expect(String(mapping.get("decision", "")) == conditional_decisions[reference_id], "reference '%s' must preserve its resolved conditional decision" % reference_id, failures)

static func _validate_pilots(pilots: Array, failures: Array[String]) -> void:
	_expect(pilots.size() == EXPECTED_PILOT_KEYS.size(), "the M1 character refresh must stage exactly five representative pilots", failures)
	var seen: Dictionary = {}
	for value in pilots:
		var pilot := value as Dictionary
		var key := "%s/%s" % [pilot.get("category", ""), pilot.get("content_id", "")]
		_expect(EXPECTED_PILOT_KEYS.has(key), "unexpected character refresh pilot '%s'" % key, failures)
		_expect(not seen.has(key), "character refresh pilot keys must be unique: '%s'" % key, failures)
		seen[key] = true
		_expect(String(pilot.get("status", "")) == "approved_for_derivation", "pilot '%s' must remain approved for M2 derivatives" % key, failures)
		var path := String(pilot.get("path", ""))
		_expect(path == String(EXPECTED_PILOT_PATHS.get(key, "")), "pilot '%s' must preserve its selected reviewed source" % key, failures)
		_expect(path.begins_with("res://assets/graphics/style_refresh_v019/"), "pilot '%s' must remain under the isolated staging root" % key, failures)
		_expect(FileAccess.file_exists(path), "pilot image must exist: '%s'" % path, failures)
		if FileAccess.file_exists(path):
			_validate_pilot_image(Image.load_from_file(ProjectSettings.globalize_path(path)), key, failures)
	for key in EXPECTED_PILOT_KEYS:
		_expect(seen.has(key), "missing representative character refresh pilot '%s'" % key, failures)

static func _validate_m2_defender_full_body(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "approved_for_icon_derivation", "the M2-A defender full-body set must remain approved for icon derivation", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))), "the M2-A defender review scene must exist", failures)
	var captures := section.get("captures", []) as Array
	_expect(captures.size() == 2, "the M2-A defender review must preserve both comparison pages", failures)
	for capture_value in captures:
		var capture_path := String(capture_value)
		_expect(FileAccess.file_exists(capture_path), "the M2-A defender review capture must exist: '%s'" % capture_path, failures)
		if FileAccess.file_exists(capture_path):
			var capture := Image.load_from_file(ProjectSettings.globalize_path(capture_path))
			_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "the M2-A defender review capture must remain 1280x720: '%s'" % capture_path, failures)
	_expect((section.get("findings", []) as Array).size() >= 4, "the M2-A defender review must record its mobile-size and activation findings", failures)

	var assets := section.get("assets", []) as Array
	_expect(assets.size() == EXPECTED_M2_DEFENDER_REFERENCES.size(), "the M2-A defender set must stage all seven normal-defender full-body masters", failures)
	var seen: Dictionary = {}
	for value in assets:
		var asset := value as Dictionary
		var content_id := String(asset.get("content_id", ""))
		_expect(EXPECTED_M2_DEFENDER_REFERENCES.has(content_id), "unexpected M2-A defender full-body asset '%s'" % content_id, failures)
		_expect(not seen.has(content_id), "M2-A defender content ids must be unique: '%s'" % content_id, failures)
		seen[content_id] = true
		if not EXPECTED_M2_DEFENDER_REFERENCES.has(content_id):
			continue
		_expect(String(asset.get("reference_id", "")) == String(EXPECTED_M2_DEFENDER_REFERENCES[content_id]), "M2-A defender '%s' must preserve its approved reference mapping" % content_id, failures)
		_expect(String(asset.get("status", "")) == "approved_for_icon_derivation", "M2-A defender '%s' must remain approved for icon derivation" % content_id, failures)
		_expect(not String(asset.get("generation_method", "")).is_empty(), "M2-A defender '%s' must record its production method" % content_id, failures)
		var path := String(asset.get("path", ""))
		_expect(path == "res://assets/graphics/style_refresh_v019/defenders/%s.png" % content_id, "M2-A defender '%s' must keep its stable staging path" % content_id, failures)
		_expect(FileAccess.file_exists(path), "M2-A defender master must exist: '%s'" % path, failures)
		if FileAccess.file_exists(path):
			_validate_pilot_image(Image.load_from_file(ProjectSettings.globalize_path(path)), "defenders/%s" % content_id, failures)
	for content_id in EXPECTED_M2_DEFENDER_REFERENCES:
		_expect(seen.has(content_id), "missing M2-A defender full-body master '%s'" % content_id, failures)

static func _validate_m2_defender_icons(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "approved_identity_pairs_staging_only", "the M2-B defender icon pairs must remain approved only inside staging", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))), "the M2-B defender icon review scene must exist", failures)
	var captures := section.get("captures", []) as Array
	_expect(captures.size() == 2, "the M2-B defender icon review must preserve both comparison pages", failures)
	for capture_value in captures:
		var capture_path := String(capture_value)
		_expect(FileAccess.file_exists(capture_path), "the M2-B defender icon review capture must exist: '%s'" % capture_path, failures)
		if FileAccess.file_exists(capture_path):
			var capture := Image.load_from_file(ProjectSettings.globalize_path(capture_path))
			_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "the M2-B defender icon review capture must remain 1280x720: '%s'" % capture_path, failures)
	_expect((section.get("findings", []) as Array).size() >= 5, "the M2-B defender icon review must record identity, mobile-size, motif, and activation findings", failures)

	var assets := section.get("assets", []) as Array
	_expect(assets.size() == EXPECTED_M2_DEFENDER_REFERENCES.size(), "the M2-B defender icon set must stage all seven approved identity pairs", failures)
	var seen: Dictionary = {}
	for value in assets:
		var asset := value as Dictionary
		var content_id := String(asset.get("content_id", ""))
		_expect(EXPECTED_M2_DEFENDER_REFERENCES.has(content_id), "unexpected M2-B defender icon asset '%s'" % content_id, failures)
		_expect(not seen.has(content_id), "M2-B defender icon ids must be unique: '%s'" % content_id, failures)
		seen[content_id] = true
		if not EXPECTED_M2_DEFENDER_REFERENCES.has(content_id):
			continue
		_expect(String(asset.get("reference_id", "")) == String(EXPECTED_M2_DEFENDER_REFERENCES[content_id]), "M2-B defender icon '%s' must preserve its approved reference mapping" % content_id, failures)
		_expect(String(asset.get("status", "")) == "approved_identity_pair", "M2-B defender icon '%s' must remain approved as an identity pair" % content_id, failures)
		_expect(not String(asset.get("generation_method", "")).is_empty(), "M2-B defender icon '%s' must record its production method" % content_id, failures)
		var full_body_path := String(asset.get("source_full_body", ""))
		_expect(full_body_path == "res://assets/graphics/style_refresh_v019/defenders/%s.png" % content_id, "M2-B defender icon '%s' must point to its approved full-body source" % content_id, failures)
		_expect(FileAccess.file_exists(full_body_path), "M2-B defender icon source must exist: '%s'" % full_body_path, failures)
		var path := String(asset.get("path", ""))
		_expect(path == "res://assets/graphics/style_refresh_v019/defender_icons/%s.png" % content_id, "M2-B defender icon '%s' must keep its stable staging path" % content_id, failures)
		_expect(FileAccess.file_exists(path), "M2-B defender icon master must exist: '%s'" % path, failures)
		if FileAccess.file_exists(path):
			_validate_pilot_image(Image.load_from_file(ProjectSettings.globalize_path(path)), "defender_icons/%s" % content_id, failures)
	for content_id in EXPECTED_M2_DEFENDER_REFERENCES:
		_expect(seen.has(content_id), "missing M2-B defender icon master '%s'" % content_id, failures)

static func _validate_m2_character_pairs(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "approved_identity_pairs_staging_only", "the M2-C portrait and SD pairs must remain approved only inside staging", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))), "the M2-C character pair review scene must exist", failures)
	var captures := section.get("captures", []) as Array
	_expect(captures.size() == 2, "the M2-C character pair review must preserve both comparison pages", failures)
	for capture_value in captures:
		var capture_path := String(capture_value)
		_expect(FileAccess.file_exists(capture_path), "the M2-C character pair review capture must exist: '%s'" % capture_path, failures)
		if FileAccess.file_exists(capture_path):
			var capture := Image.load_from_file(ProjectSettings.globalize_path(capture_path))
			_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "the M2-C character pair review capture must remain 1280x720: '%s'" % capture_path, failures)
	_expect((section.get("findings", []) as Array).size() >= 7, "the M2-C review must record all five identity findings, mobile readability, and activation isolation", failures)

	var assets := section.get("assets", []) as Array
	_expect(assets.size() == EXPECTED_M2_CHARACTER_PAIRS.size(), "the M2-C set must stage all five approved portrait and SD pairs", failures)
	var seen: Dictionary = {}
	for value in assets:
		var asset := value as Dictionary
		var content_id := String(asset.get("content_id", ""))
		_expect(EXPECTED_M2_CHARACTER_PAIRS.has(content_id), "unexpected M2-C character pair '%s'" % content_id, failures)
		_expect(not seen.has(content_id), "M2-C character pair ids must be unique: '%s'" % content_id, failures)
		seen[content_id] = true
		if not EXPECTED_M2_CHARACTER_PAIRS.has(content_id):
			continue
		var expected := EXPECTED_M2_CHARACTER_PAIRS[content_id] as Dictionary
		_expect(String(asset.get("reference_id", "")) == String(expected.get("reference_id", "")), "M2-C pair '%s' must preserve its approved reference mapping" % content_id, failures)
		_expect(String(asset.get("status", "")) == "approved_identity_pair", "M2-C pair '%s' must remain approved as a portrait and SD identity pair" % content_id, failures)
		_expect(not String(asset.get("generation_method", "")).is_empty(), "M2-C pair '%s' must record its production method" % content_id, failures)
		_expect((asset.get("identity_contract", []) as Array).size() >= 3, "M2-C pair '%s' must record its stable identity cues" % content_id, failures)
		for field in ["portrait_path", "sd_path"]:
			var path := String(asset.get(field, ""))
			_expect(path == String(expected.get(field, "")), "M2-C pair '%s' must keep its stable %s" % [content_id, field], failures)
			_expect(path.begins_with("res://assets/graphics/style_refresh_v019/"), "M2-C pair '%s' %s must remain under the isolated staging root" % [content_id, field], failures)
			_expect(FileAccess.file_exists(path), "M2-C pair image must exist: '%s'" % path, failures)
			if FileAccess.file_exists(path):
				_validate_pilot_image(Image.load_from_file(ProjectSettings.globalize_path(path)), "%s/%s" % [content_id, field], failures)
	for content_id in EXPECTED_M2_CHARACTER_PAIRS:
		_expect(seen.has(content_id), "missing M2-C character pair '%s'" % content_id, failures)

static func _validate_m2_guard_application(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "approved_application_example_staging_only", "the M2-C royal guard application must remain approved only inside staging", failures)
	_expect(String(section.get("reference_id", "")) == "char_011" and String(section.get("content_id", "")) == "emerald_guardian", "the M2-C guard example must preserve the approved char_011 mapping", failures)
	_expect(String(section.get("emblem", "")) == "sword_shield", "the M2-C royal guard must use the approved sword-and-shield emblem", failures)
	_expect(String(section.get("floor_border", "")) == "partason_metal_ring", "the M2-C royal guard must use the approved floor border example", failures)
	var palette := section.get("palette", []) as Array
	_expect(palette == ["#252831", "#B8B9C1", "#C9A75D"], "the M2-C guard example must preserve the charcoal, steel, and limited metal palette", failures)
	_expect(not String(section.get("finding", "")).is_empty(), "the M2-C guard example must record its visual finding", failures)
	var source_path := String(section.get("source_full_body", ""))
	_expect(source_path == "res://assets/graphics/style_refresh_v019/towers/emerald_guardian.png", "the M2-C guard application must use the approved staged full body", failures)
	_expect(FileAccess.file_exists(source_path), "the M2-C guard full-body source must exist", failures)
	if FileAccess.file_exists(source_path):
		_validate_pilot_image(Image.load_from_file(ProjectSettings.globalize_path(source_path)), "guard_application/emerald_guardian", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))), "the M2-C guard application review scene must exist", failures)
	var capture_path := String(section.get("capture", ""))
	_expect(FileAccess.file_exists(capture_path), "the M2-C guard application capture must exist", failures)
	if FileAccess.file_exists(capture_path):
		var capture := Image.load_from_file(ProjectSettings.globalize_path(capture_path))
		_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "the M2-C guard application capture must remain 1280x720", failures)

static func _validate_m3_missing_defenders(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "approved_identity_pairs_staging_only", "the M3-A missing defender pairs must remain approved only inside staging", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))), "the M3-A defender pair review scene must exist", failures)
	var capture_path := String(section.get("capture", ""))
	_expect(FileAccess.file_exists(capture_path), "the M3-A defender pair review capture must exist", failures)
	if FileAccess.file_exists(capture_path):
		var capture := Image.load_from_file(ProjectSettings.globalize_path(capture_path))
		_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "the M3-A defender pair review capture must remain 1280x720", failures)
	_expect((section.get("findings", []) as Array).size() >= 4, "the M3-A review must record role identity, mobile readability, and activation isolation", failures)

	var assets := section.get("assets", []) as Array
	_expect(assets.size() == EXPECTED_M3_DEFENDER_PAIRS.size(), "the M3-A set must stage both missing normal-defender identity pairs", failures)
	var seen: Dictionary = {}
	for value in assets:
		var asset := value as Dictionary
		var content_id := String(asset.get("content_id", ""))
		_expect(EXPECTED_M3_DEFENDER_PAIRS.has(content_id), "unexpected M3-A defender pair '%s'" % content_id, failures)
		_expect(not seen.has(content_id), "M3-A defender pair ids must be unique: '%s'" % content_id, failures)
		seen[content_id] = true
		if not EXPECTED_M3_DEFENDER_PAIRS.has(content_id):
			continue
		var expected := EXPECTED_M3_DEFENDER_PAIRS[content_id] as Dictionary
		_expect(String(asset.get("status", "")) == "approved_identity_pair", "M3-A defender '%s' must remain approved as a full-body and icon identity pair" % content_id, failures)
		_expect(not String(asset.get("generation_method", "")).is_empty(), "M3-A defender '%s' must record its production method" % content_id, failures)
		_expect((asset.get("identity_contract", []) as Array).size() >= 4, "M3-A defender '%s' must record its role and silhouette identity cues" % content_id, failures)
		for field in ["full_body_path", "icon_path"]:
			var path := String(asset.get(field, ""))
			_expect(path == String(expected.get(field, "")), "M3-A defender '%s' must keep its stable %s" % [content_id, field], failures)
			_expect(path.begins_with("res://assets/graphics/style_refresh_v019/"), "M3-A defender '%s' %s must remain under the isolated staging root" % [content_id, field], failures)
			_expect(FileAccess.file_exists(path), "M3-A defender pair image must exist: '%s'" % path, failures)
			if FileAccess.file_exists(path):
				_validate_pilot_image(Image.load_from_file(ProjectSettings.globalize_path(path)), "%s/%s" % [content_id, field], failures)
	for content_id in EXPECTED_M3_DEFENDER_PAIRS:
		_expect(seen.has(content_id), "missing M3-A defender pair '%s'" % content_id, failures)

static func _validate_m3_kanda_pair(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "approved_identity_pair_staging_only", "the M3-B Kanda pair must remain approved only inside staging", failures)
	_expect(String(section.get("content_id", "")) == "kanda", "the M3-B retainer pair must preserve Kanda's stable content id", failures)
	_expect(not String(section.get("generation_method", "")).is_empty(), "the M3-B Kanda pair must record its production method", failures)
	_expect((section.get("identity_contract", []) as Array).size() >= 5, "the M3-B Kanda pair must record horns, scar, armor, palette, and sword identity cues", failures)
	_expect((section.get("findings", []) as Array).size() >= 4, "the M3-B Kanda review must record identity, role, mobile readability, and activation isolation", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))), "the M3-B Kanda pair review scene must exist", failures)
	var capture_path := String(section.get("capture", ""))
	_expect(FileAccess.file_exists(capture_path), "the M3-B Kanda pair review capture must exist", failures)
	if FileAccess.file_exists(capture_path):
		var capture := Image.load_from_file(ProjectSettings.globalize_path(capture_path))
		_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "the M3-B Kanda pair review capture must remain 1280x720", failures)
	for field in EXPECTED_M3_KANDA_PATHS:
		var path := String(section.get(field, ""))
		_expect(path == String(EXPECTED_M3_KANDA_PATHS[field]), "the M3-B Kanda pair must keep its stable %s" % field, failures)
		_expect(path.begins_with("res://assets/graphics/style_refresh_v019/"), "the M3-B Kanda %s must remain under the isolated staging root" % field, failures)
		_expect(FileAccess.file_exists(path), "the M3-B Kanda pair image must exist: '%s'" % path, failures)
		if FileAccess.file_exists(path):
			_validate_pilot_image(Image.load_from_file(ProjectSettings.globalize_path(path)), "kanda/%s" % field, failures)

static func _validate_m3_candidate_pairs(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "approved_identity_pairs_staging_only", "the M3-C candidate pairs must remain approved only inside staging", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))), "the M3-C candidate pair review scene must exist", failures)
	var captures := section.get("captures", []) as Array
	_expect(captures.size() == 2, "the M3-C candidate review must keep both mobile comparison pages", failures)
	for capture_value in captures:
		var capture_path := String(capture_value)
		_expect(FileAccess.file_exists(capture_path), "the M3-C candidate review capture must exist: '%s'" % capture_path, failures)
		if FileAccess.file_exists(capture_path):
			var capture := Image.load_from_file(ProjectSettings.globalize_path(capture_path))
			_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "the M3-C candidate review capture must remain 1280x720: '%s'" % capture_path, failures)
	_expect((section.get("findings", []) as Array).size() >= 6, "the M3-C review must record all four identities, mobile readability, alpha margins, and activation isolation", failures)

	var assets := section.get("assets", []) as Array
	_expect(assets.size() == EXPECTED_M3_CANDIDATE_PAIRS.size(), "the M3-C set must stage all four missing candidate identity pairs", failures)
	var seen: Dictionary = {}
	for value in assets:
		var asset := value as Dictionary
		var content_id := String(asset.get("content_id", ""))
		_expect(EXPECTED_M3_CANDIDATE_PAIRS.has(content_id), "unexpected M3-C candidate pair '%s'" % content_id, failures)
		_expect(not seen.has(content_id), "M3-C candidate pair ids must be unique: '%s'" % content_id, failures)
		seen[content_id] = true
		if not EXPECTED_M3_CANDIDATE_PAIRS.has(content_id):
			continue
		var expected := EXPECTED_M3_CANDIDATE_PAIRS[content_id] as Dictionary
		_expect(String(asset.get("status", "")) == "approved_identity_pair", "M3-C candidate '%s' must remain approved as a portrait and combat SD identity pair" % content_id, failures)
		_expect(not String(asset.get("generation_method", "")).is_empty(), "M3-C candidate '%s' must record its production method" % content_id, failures)
		_expect((asset.get("identity_contract", []) as Array).size() >= 5, "M3-C candidate '%s' must record face, horn, faction, and combat-role identity cues" % content_id, failures)
		for field in ["portrait_path", "sd_path"]:
			var path := String(asset.get(field, ""))
			_expect(path == String(expected.get(field, "")), "M3-C candidate '%s' must keep its stable %s" % [content_id, field], failures)
			_expect(path.begins_with("res://assets/graphics/style_refresh_v019/"), "M3-C candidate '%s' %s must remain under the isolated staging root" % [content_id, field], failures)
			_expect(FileAccess.file_exists(path), "M3-C candidate pair image must exist: '%s'" % path, failures)
			if FileAccess.file_exists(path):
				var image := Image.load_from_file(ProjectSettings.globalize_path(path))
				_validate_pilot_image(image, "%s/%s" % [content_id, field], failures)
				_validate_safe_margin(image, "%s/%s" % [content_id, field], failures)
	for content_id in EXPECTED_M3_CANDIDATE_PAIRS:
		_expect(seen.has(content_id), "missing M3-C candidate pair '%s'" % content_id, failures)

static func _validate_m3_guard_full_body(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "approved_guard_set_staging_only", "the M3-D guard set must remain approved only inside staging", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))), "the M3-D guard review scene must exist", failures)
	var captures := section.get("captures", []) as Array
	_expect(captures.size() == 2, "the M3-D guard review must keep both mobile comparison pages", failures)
	for capture_value in captures:
		var capture_path := String(capture_value)
		_expect(FileAccess.file_exists(capture_path), "the M3-D guard review capture must exist: '%s'" % capture_path, failures)
		if FileAccess.file_exists(capture_path):
			var capture := Image.load_from_file(ProjectSettings.globalize_path(capture_path))
			_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "the M3-D guard review capture must remain 1280x720: '%s'" % capture_path, failures)
	_expect((section.get("findings", []) as Array).size() >= 6, "the M3-D review must record five guard roles, alpha margins, and activation isolation", failures)
	_expect(String(section.get("prompt_palette_status", "")) == "updated_to_v019_faction_tokens", "the M3-D prompt cleanup must use the v0.19 faction tokens", failures)
	var prompt_path := String(section.get("prompt_document", ""))
	_expect(prompt_path == "res://docs/DEMON_ELECTION_PORTRAIT_PROMPTS.md" and FileAccess.file_exists(prompt_path), "the M3-D guard set must reference the maintained character prompt document", failures)
	if FileAccess.file_exists(prompt_path):
		var prompt_source := FileAccess.get_file_as_string(prompt_path)
		for token in ["#252831", "#D83A91", "#50B84A", "#80D9F5", "#D4444A", "검과 방패", "하트", "촉수와 눈", "해골과 일렁이는 오라", "낫과 피"]:
			_expect(prompt_source.contains(token), "the v0.19 prompt document must preserve faction token '%s'" % token, failures)

	var assets := section.get("assets", []) as Array
	_expect(assets.size() == EXPECTED_M3_GUARDS.size(), "the M3-D set must stage all five missing guard full-body masters", failures)
	var seen: Dictionary = {}
	for value in assets:
		var asset := value as Dictionary
		var content_id := String(asset.get("content_id", ""))
		_expect(EXPECTED_M3_GUARDS.has(content_id), "unexpected M3-D guard '%s'" % content_id, failures)
		_expect(not seen.has(content_id), "M3-D guard ids must be unique: '%s'" % content_id, failures)
		seen[content_id] = true
		if not EXPECTED_M3_GUARDS.has(content_id):
			continue
		var expected := EXPECTED_M3_GUARDS[content_id] as Dictionary
		_expect(String(asset.get("status", "")) == "approved_guard_full_body", "M3-D guard '%s' must remain approved as a staged full-body master" % content_id, failures)
		_expect(not String(asset.get("generation_method", "")).is_empty(), "M3-D guard '%s' must record its production method" % content_id, failures)
		_expect((asset.get("identity_contract", []) as Array).size() >= 5, "M3-D guard '%s' must record faction, role, weapon, direction, and silhouette cues" % content_id, failures)
		_expect(String(asset.get("legacy_active_path", "")) == String(expected.get("legacy_active_path", "")), "M3-D guard '%s' must preserve its explicit active-asset comparison source" % content_id, failures)
		var path := String(asset.get("path", ""))
		_expect(path == String(expected.get("path", "")), "M3-D guard '%s' must keep its stable staging path" % content_id, failures)
		_expect(path.begins_with("res://assets/graphics/style_refresh_v019/towers/"), "M3-D guard '%s' must remain under the isolated tower staging root" % content_id, failures)
		_expect(FileAccess.file_exists(path), "M3-D guard image must exist: '%s'" % path, failures)
		if FileAccess.file_exists(path):
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			_validate_pilot_image(image, "guard/%s" % content_id, failures)
			_validate_safe_margin(image, "guard/%s" % content_id, failures)
	for content_id in EXPECTED_M3_GUARDS:
		_expect(seen.has(content_id), "missing M3-D guard '%s'" % content_id, failures)

static func _validate_m4_intrusion_derivatives(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "approved_intrusion_set_active", "the M4 intrusion set must record its active-catalog status", failures)
	_expect(String(section.get("runtime_policy", "")) == "dedicated_intrusion_then_ally_sd_horizontal_flip", "M4 must preserve the dedicated-art-first and ally-flip compatibility policy", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))), "the M4 intrusion review scene must exist", failures)
	var captures := section.get("captures", []) as Array
	_expect(captures.size() == 4, "the M4 intrusion review must keep all four comparison pages", failures)
	for capture_value in captures:
		var capture_path := String(capture_value)
		_expect(FileAccess.file_exists(capture_path), "the M4 intrusion review capture must exist: '%s'" % capture_path, failures)
		if FileAccess.file_exists(capture_path):
			var capture := Image.load_from_file(ProjectSettings.globalize_path(capture_path))
			_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "the M4 intrusion review capture must remain 1280x720: '%s'" % capture_path, failures)
	_expect((section.get("findings", []) as Array).size() >= 6, "the M4 review must record candidate, retainer, identity-count, mobile, alpha, and fallback findings", failures)
	var active_enemy_audit := section.get("active_enemy_audit", {}) as Dictionary
	_expect((active_enemy_audit.get("audited_ids", []) as Array).size() == 17, "M4 must audit all seven common enemies, five faction enemies, and five boss identities", failures)
	_expect((active_enemy_audit.get("corrected_ids", []) as Array).is_empty(), "P2 direct enemy art must supersede the former active direction correction", failures)
	_expect((active_enemy_audit.get("approved_frontal_exceptions", []) as Array).size() >= 6, "M4 must explicitly record symmetric machine, creature, and boss frontal exceptions while judgment_bell uses direct left-facing art", failures)
	_expect(String(active_enemy_audit.get("outline_result", "")) == "medium_or_internal_dark_contour_no_player_thick_outline_violations", "M4 must preserve the active enemy outline audit verdict", failures)
	var enemy_source := FileAccess.get_file_as_string("res://scripts/actors/enemy.gd")
	_expect(not enemy_source.contains("LEFT_FACING_ART_CORRECTION_IDS"), "direct P2 enemy art must eliminate the obsolete ID-scoped runtime correction", failures)
	_expect(GameAssetCatalogData.CONTENT_CATEGORIES.has(&"candidate_intrusion_sd") and GameAssetCatalogData.CONTENT_CATEGORIES.has(&"retainer_intrusion_sd") and GameAssetCatalogData.CONTENT_CATEGORIES.has(&"guard_intrusion_sd"), "the asset catalog must accept candidate, retainer, and faction guard intrusion SD categories", failures)

	var assets := section.get("assets", []) as Array
	_expect(assets.size() == EXPECTED_M4_INTRUSIONS.size(), "the M4 set must register all ten active official intrusion derivatives", failures)
	var seen: Dictionary = {}
	for value in assets:
		var asset := value as Dictionary
		var content_id := String(asset.get("content_id", ""))
		_expect(EXPECTED_M4_INTRUSIONS.has(content_id), "unexpected M4 intrusion derivative '%s'" % content_id, failures)
		_expect(not seen.has(content_id), "M4 intrusion ids must be unique: '%s'" % content_id, failures)
		seen[content_id] = true
		if not EXPECTED_M4_INTRUSIONS.has(content_id):
			continue
		var expected := EXPECTED_M4_INTRUSIONS[content_id] as Dictionary
		_expect(String(asset.get("status", "")) == "approved_intrusion_derivative", "M4 intrusion '%s' must remain an approved active derivative" % content_id, failures)
		_expect(not String(asset.get("generation_method", "")).is_empty(), "M4 intrusion '%s' must record its production method" % content_id, failures)
		for field in ["ally_category", "ally_path", "intrusion_category", "path"]:
			_expect(String(asset.get(field, "")) == String(expected.get(field, "")), "M4 intrusion '%s' must preserve its explicit source/derivative %s" % [content_id, field], failures)
		var changed_elements := asset.get("changed_elements", []) as Array
		var changed_summary := " ".join(PackedStringArray(changed_elements))
		_expect(changed_elements.size() >= 4, "M4 intrusion '%s' must record at least direction, expression, outline, and faction-effect changes" % content_id, failures)
		_expect(changed_summary.contains("left_facing") and changed_summary.contains("hostile") and changed_summary.contains("medium_outline"), "M4 intrusion '%s' must explicitly record left-facing, hostile, and medium-outline differences" % content_id, failures)
		var ally_path := String(asset.get("ally_path", ""))
		var path := String(asset.get("path", ""))
		_expect(FileAccess.file_exists(ally_path), "M4 intrusion source must exist: '%s'" % ally_path, failures)
		_expect(path.begins_with("res://assets/graphics/%s/" % String(asset.get("intrusion_category", ""))), "M4 intrusion '%s' must resolve from its active category path" % content_id, failures)
		_expect(FileAccess.file_exists(path), "M4 intrusion image must exist: '%s'" % path, failures)
		if FileAccess.file_exists(path):
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			_validate_pilot_image(image, "intrusion/%s" % content_id, failures)
			_validate_safe_margin(image, "intrusion/%s" % content_id, failures)
	for content_id in EXPECTED_M4_INTRUSIONS:
		_expect(seen.has(content_id), "missing M4 intrusion derivative '%s'" % content_id, failures)

static func _validate_official_intrusion_boss_m1_review(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "approved_active_set_no_regeneration_required", "the M1 actual-boss review must record its selective-regeneration verdict", failures)
	_expect(String(section.get("source_policy", "")) == "active_catalog_paths_only", "the M1 review must inspect active catalog pixels instead of staging-only sources", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))), "the M1 actual-boss review scene must exist", failures)
	_expect(int(section.get("candidate_display_size_px", 0)) == 224, "the M1 candidate review must use the actual 224px final-boss envelope", failures)
	var retainer_sizes := section.get("retainer_display_sizes_px", []) as Array
	_expect(retainer_sizes.size() == 3 and int(retainer_sizes[0]) == 158 and int(retainer_sizes[1]) == 190 and int(retainer_sizes[2]) == 210, "the M1 retainer review must cover the actual Tier 1/2/3 body envelopes", failures)
	_expect(int(section.get("monochrome_display_size_px", 0)) == 128, "the M1 monochrome identity row must use the declared 128px review envelope", failures)
	var reviewed_ids := section.get("reviewed_ids", []) as Array
	var unique_ids: Dictionary = {}
	for content_id in reviewed_ids:
		unique_ids[String(content_id)] = true
	_expect(reviewed_ids.size() == 10 and unique_ids.size() == 10, "the M1 review must cover five candidates and five retainers exactly once", failures)
	_expect((section.get("failed_ids", []) as Array).is_empty() and (section.get("regeneration_ids", []) as Array).is_empty(), "the approved M1 active set must not invent selective regeneration work", failures)
	_expect((section.get("density_fixture", []) as Array).size() == 4 and (section.get("findings", []) as Array).size() >= 5, "the M1 review must preserve a four-slot density fixture and its decision findings", failures)
	var captures := section.get("captures", []) as Array
	_expect(captures.size() == 4, "the M1 actual-boss review must keep candidate, retainer, monochrome, and density captures", failures)
	for capture_value in captures:
		var capture_path := String(capture_value)
		_expect(FileAccess.file_exists(capture_path), "the M1 actual-boss capture must exist: '%s'" % capture_path, failures)
		if FileAccess.file_exists(capture_path):
			var capture := Image.load_from_file(ProjectSettings.globalize_path(capture_path))
			_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "the M1 actual-boss capture must remain 1280x720: '%s'" % capture_path, failures)
	var review_source := FileAccess.get_file_as_string("res://tests/official_intrusion_boss_m1_review_runner.gd")
	_expect(review_source.contains("assets/graphics/candidate_intrusion_sd") and review_source.contains("assets/graphics/retainer_intrusion_sd") and not review_source.contains("style_refresh_v019"), "the M1 review runner must load only active intrusion paths", failures)

static func _validate_official_intrusion_boss_m2_guards(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "approved_active_guard_intrusion_set", "the M2 guard set must record active approval", failures)
	_expect(String(section.get("source_policy", "")) == "active_guard_idle_and_attack_identity_pair", "the M2 guards must derive from both active idle and attack identities", failures)
	_expect(int(section.get("master_size_px", 0)) == 1254 and is_equal_approx(float(section.get("maximum_fill_ratio", 0.0)), 0.84), "the M2 guards must preserve the 1254px master and 84-percent normalization contract", failures)
	_expect(int(section.get("runtime_texture_limit", 0)) == 512, "the M2 guard runtime imports must retain the 512px cap", failures)
	_expect(FileAccess.file_exists(String(section.get("preparation_tool", ""))), "the M2 guard alpha-normalization tool must exist", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))), "the M2 guard review scene must exist", failures)
	var captures := section.get("captures", []) as Array
	_expect(captures.size() == 2, "the M2 guard review must preserve identity-pair and size captures", failures)
	for capture_value in captures:
		var capture_path := String(capture_value)
		_expect(FileAccess.file_exists(capture_path), "the M2 guard capture must exist: '%s'" % capture_path, failures)
		if FileAccess.file_exists(capture_path):
			var capture := Image.load_from_file(ProjectSettings.globalize_path(capture_path))
			_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "the M2 guard capture must remain 1280x720: '%s'" % capture_path, failures)
	var assets := section.get("assets", []) as Array
	_expect(assets.size() == EXPECTED_OFFICIAL_M2_GUARDS.size(), "the M2 guard set must activate exactly five faction identities", failures)
	var seen: Dictionary = {}
	var hashes: Dictionary = {}
	for asset_value in assets:
		var asset := asset_value as Dictionary
		var faction_id := String(asset.get("faction_id", ""))
		var guard_id := String(asset.get("guard_id", ""))
		_expect(EXPECTED_OFFICIAL_M2_GUARDS.has(faction_id), "unexpected M2 guard faction '%s'" % faction_id, failures)
		if not EXPECTED_OFFICIAL_M2_GUARDS.has(faction_id):
			continue
		_expect(not seen.has(faction_id), "M2 guard faction '%s' must appear exactly once" % faction_id, failures)
		seen[faction_id] = true
		_expect(guard_id == String(EXPECTED_OFFICIAL_M2_GUARDS[faction_id]), "M2 faction '%s' must derive from its planned guard identity" % faction_id, failures)
		_expect(String(asset.get("source_idle_path", "")) == "res://assets/graphics/towers/%s.png" % guard_id, "M2 faction '%s' must preserve the active guard idle source" % faction_id, failures)
		_expect(String(asset.get("source_attack_path", "")) == "res://assets/graphics/tower_attacks/%s.png" % guard_id, "M2 faction '%s' must preserve the active guard attack source" % faction_id, failures)
		var staged_path := String(asset.get("staged_path", ""))
		var active_path := String(asset.get("active_path", ""))
		_expect(staged_path == "res://assets/graphics/style_refresh_v019/guard_intrusion_sd/%s.png" % faction_id, "M2 faction '%s' must retain its derivation master" % faction_id, failures)
		_expect(active_path == "res://assets/graphics/guard_intrusion_sd/%s.png" % faction_id, "M2 faction '%s' must use the stable active category path" % faction_id, failures)
		_expect(FileAccess.file_exists(staged_path) and FileAccess.file_exists(active_path), "M2 faction '%s' staged and active images must both exist" % faction_id, failures)
		if FileAccess.file_exists(staged_path) and FileAccess.file_exists(active_path):
			var actual_hash := FileAccess.get_sha256(active_path).to_lower()
			_expect(actual_hash == FileAccess.get_sha256(staged_path).to_lower() and actual_hash == String(asset.get("sha256", "")).to_lower(), "M2 faction '%s' staged, active, and manifest hashes must match" % faction_id, failures)
			_expect(not hashes.has(actual_hash), "M2 faction '%s' must own a unique guard image" % faction_id, failures)
			hashes[actual_hash] = faction_id
			var image := Image.load_from_file(ProjectSettings.globalize_path(active_path))
			_validate_pilot_image(image, "official M2 guard/%s" % faction_id, failures)
			_validate_safe_margin(image, "official M2 guard/%s" % faction_id, failures)
		var margins := asset.get("alpha_margins_px", []) as Array
		_expect(margins.size() == 4 and margins.all(func(value: Variant) -> bool: return int(value) >= 87), "M2 faction '%s' must record at least seven-percent alpha margins" % faction_id, failures)
		_expect((asset.get("identity_contract", []) as Array).size() >= 4 and String(asset.get("status", "")) == "active_guard_intrusion", "M2 faction '%s' must preserve identity cues and active status" % faction_id, failures)
		var texture := load(active_path) as Texture2D
		_expect(texture != null and texture.get_size() == Vector2(512, 512), "M2 faction '%s' must import as a 512px runtime texture" % faction_id, failures)
		var import_path := "%s.import" % active_path
		_expect(FileAccess.file_exists(import_path) and FileAccess.get_file_as_string(import_path).contains("process/size_limit=512"), "M2 faction '%s' must preserve its 512px import setting" % faction_id, failures)
	for faction_id in EXPECTED_OFFICIAL_M2_GUARDS:
		_expect(seen.has(faction_id), "missing M2 guard intrusion for '%s'" % faction_id, failures)
	_expect((section.get("findings", []) as Array).size() >= 5, "the M2 guard activation must record identity, alpha, import, readability, and fallback findings", failures)
	var review_source := FileAccess.get_file_as_string("res://tests/official_intrusion_boss_m2_guard_review_runner.gd")
	_expect(review_source.contains("assets/graphics/guard_intrusion_sd") and not review_source.contains("style_refresh_v019") and review_source.contains("220") and review_source.contains("96") and review_source.contains("64") and review_source.contains("48"), "the M2 review runner must inspect active guards at every required size", failures)
	var preparation_source := FileAccess.get_file_as_string(String(section.get("preparation_tool", "")))
	_expect(preparation_source.contains("RemoveConnectedBackdrop") and preparation_source.contains("NormalizeContentToCanvas") and preparation_source.contains("0.84"), "the M2 preparation tool must preserve deterministic background cleanup and 84-percent normalization", failures)

static func _validate_official_intrusion_boss_m4_integration(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "approved_integrated_runtime_and_android_package", "the official intrusion M4 integration must record runtime and Android approval", failures)
	var matrix := section.get("matrix", {}) as Dictionary
	var seeds := matrix.get("seeds", []) as Array
	_expect(int(matrix.get("candidate_count", 0)) == 5 and int(matrix.get("retainer_count", 0)) == 5 and seeds.size() == 3 and int(seeds[0]) == 17 and int(seeds[1]) == 42731 and int(seeds[2]) == 99881, "the M4 integration must preserve its five-by-five and three-seed matrix", failures)
	_expect(int(matrix.get("plan_count", 0)) == 75 and int(matrix.get("slot_count", 0)) == 300 and int(matrix.get("guard_faction_count", 0)) == 5, "the M4 integration must record all 75 plans, 300 slots, and five guard factions", failures)
	_expect(String(section.get("runtime_contract", "")).contains("opening_retainer_or_same_faction_guard") and String(section.get("runtime_contract", "")).contains("no_ally_duplicate"), "the M4 runtime contract must preserve opening roles, final candidate, and ally exclusion", failures)
	_expect(String(section.get("result_surface_policy", "")) == "same_presentation_identity_candidate_and_retainer_portraits_guard_intrusion_sd", "the M4 result surface must preserve identity while using approved portraits and guard SD", failures)

	var expected_assets: Dictionary = {}
	for content_id_value in EXPECTED_M4_INTRUSIONS:
		var content_id := String(content_id_value)
		var expected := EXPECTED_M4_INTRUSIONS[content_id] as Dictionary
		var prefix := "candidate" if String(expected.ally_category) == "candidate_sd" else "retainer"
		expected_assets["%s/%s" % [prefix, content_id]] = String(expected.path)
	for faction_id_value in EXPECTED_OFFICIAL_M2_GUARDS:
		var faction_id := String(faction_id_value)
		expected_assets["guard/%s" % faction_id] = "res://assets/graphics/guard_intrusion_sd/%s.png" % faction_id
	var active_assets := section.get("active_asset_paths", []) as Array
	_expect(active_assets.size() == 15 and expected_assets.size() == 15, "the M4 integration must enumerate exactly fifteen active official intrusion assets", failures)
	var seen_keys: Dictionary = {}
	var seen_hashes: Dictionary = {}
	for asset_value in active_assets:
		var asset := asset_value as Dictionary
		var key := String(asset.get("key", ""))
		var path := String(asset.get("path", ""))
		var recorded_hash := String(asset.get("sha256", "")).to_lower()
		_expect(expected_assets.has(key), "unexpected M4 active intrusion key '%s'" % key, failures)
		_expect(not seen_keys.has(key), "M4 active intrusion key '%s' must be unique" % key, failures)
		seen_keys[key] = true
		if expected_assets.has(key):
			_expect(path == String(expected_assets[key]), "M4 active intrusion '%s' must preserve its stable category path" % key, failures)
		_expect(FileAccess.file_exists(path), "M4 active intrusion file must exist: '%s'" % path, failures)
		if FileAccess.file_exists(path):
			var actual_hash := FileAccess.get_sha256(path).to_lower()
			_expect(actual_hash == recorded_hash and not seen_hashes.has(actual_hash), "M4 active intrusion '%s' must preserve its unique recorded SHA-256" % key, failures)
			seen_hashes[actual_hash] = key
			var image := Image.load_from_file(ProjectSettings.globalize_path(path))
			_validate_pilot_image(image, "official M4/%s" % key, failures)
			_validate_safe_margin(image, "official M4/%s" % key, failures)
			var texture := load(path) as Texture2D
			_expect(texture != null and texture.get_size() == Vector2(512, 512), "M4 active intrusion '%s' must import at 512px" % key, failures)
			var import_path := "%s.import" % path
			_expect(FileAccess.file_exists(import_path) and FileAccess.get_file_as_string(import_path).contains("process/size_limit=512"), "M4 active intrusion '%s' must preserve its 512px import cap" % key, failures)
	for expected_key in expected_assets:
		_expect(seen_keys.has(expected_key), "missing M4 active intrusion '%s'" % expected_key, failures)
	_expect(seen_hashes.size() == 15, "the fifteen M4 active intrusion assets must have unique SHA-256 values", failures)
	_expect(int(section.get("runtime_texture_limit", 0)) == 512, "the M4 integration must retain the 512px runtime texture limit", failures)

	var review_scene := String(section.get("review_scene", ""))
	_expect(FileAccess.file_exists(review_scene), "the M4 integration review scene must exist", failures)
	var expected_capture_sizes := [Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(1920, 1080)]
	var captures := section.get("captures", []) as Array
	_expect(captures.size() == expected_capture_sizes.size(), "the M4 integration must preserve three responsive Forward Mobile captures", failures)
	for index in mini(captures.size(), expected_capture_sizes.size()):
		var capture_entry := captures[index] as Dictionary
		var capture_path := String(capture_entry.get("path", ""))
		var declared_size := capture_entry.get("size", []) as Array
		_expect(declared_size.size() == 2 and Vector2i(int(declared_size[0]), int(declared_size[1])) == expected_capture_sizes[index], "the M4 capture must declare its required responsive size", failures)
		_expect(FileAccess.file_exists(capture_path), "the M4 responsive capture must exist: '%s'" % capture_path, failures)
		if FileAccess.file_exists(capture_path):
			var capture := Image.load_from_file(ProjectSettings.globalize_path(capture_path))
			_expect(capture != null and capture.get_size() == expected_capture_sizes[index], "the M4 responsive capture must match its declared size: '%s'" % capture_path, failures)
			if capture != null and expected_capture_sizes[index] == Vector2i(1600, 720):
				_expect(capture.get_pixel(0, 360).is_equal_approx(Color.BLACK) and capture.get_pixel(800, 360) != Color.BLACK, "the 1600x720 M4 capture must preserve explicit side letterboxing around the 1280x720 composition", failures)
	var review_source := FileAccess.get_file_as_string("res://tests/official_intrusion_boss_m4_integration_review_runner.gd")
	_expect(review_source.contains("CampaignStageResolver.resolve") and review_source.contains("candidate_intrusion_sd") and review_source.contains("retainer_intrusion_sd") and review_source.contains("guard_intrusion_sd"), "the M4 review must render real resolved plans from all three active intrusion categories", failures)

	var android := section.get("android", {}) as Dictionary
	var audit_tool := String(android.get("audit_tool", ""))
	_expect(FileAccess.file_exists(audit_tool), "the M4 Android package audit tool must exist", failures)
	_expect(String(android.get("apk", "")) == "TD_survival_v019_official_intrusion_m4_debug.apk" and String(android.get("apk_sha256", "")).length() == 64 and int(android.get("apk_bytes", 0)) > 0, "the M4 Android build must record its named APK, size, and SHA-256", failures)
	_expect(String(android.get("package_id", "")) == "com.example.td_survival" and String(android.get("version_name", "")) == "0.03" and int(android.get("min_sdk", 0)) == 24 and int(android.get("target_sdk", 0)) == 36, "the M4 Android package metadata must match the current debug baseline", failures)
	_expect(String(android.get("abi", "")) == "arm64-v8a" and String(android.get("signature", "")) == "v2_v3_verified" and String(android.get("zipalign", "")).begins_with("verified") and int(android.get("permission_count", -1)) == 0, "the M4 APK must remain arm64-only, aligned, v2/v3 signed, and permission-free", failures)
	_expect(int(android.get("import_entries", 0)) == 15 and int(android.get("ctex_entries", 0)) == 15, "the M4 APK must contain all fifteen official intrusion import and CTEX entries", failures)
	var exclusions := android.get("excluded_entries", {}) as Dictionary
	_expect(exclusions.size() == 5 and exclusions.values().all(func(value: Variant) -> bool: return int(value) == 0), "the M4 APK must exclude staging, tests, tools, references, and art manifests", failures)
	_expect(String(android.get("device_status", "")) == "not_run_no_authorized_device", "the M4 manifest must not claim physical-device approval without an authorized target", failures)
	var audit_source := FileAccess.get_file_as_string(audit_tool)
	_expect(audit_source.contains("candidate_intrusion_sd") and audit_source.contains("retainer_intrusion_sd") and audit_source.contains("guard_intrusion_sd") and audit_source.contains("apksigner") and audit_source.contains("zipalign"), "the M4 APK audit must inspect all intrusion categories, signatures, and alignment", failures)
	var validation := section.get("validation", {}) as Dictionary
	var gate_stages := String(validation.get("quality_gate_stages", ""))
	_expect(gate_stages in ["pending", "7/7"], "the M4 validation must be pending only during execution or record a 7/7 quality gate", failures)
	if gate_stages == "7/7":
		_expect(not String(validation.get("quality_gate_report", "")).is_empty(), "the completed M4 validation must record its quality-gate report", failures)
	_expect((section.get("findings", []) as Array).size() >= 5, "the M4 integration must record matrix, identity, responsive, and Android package findings", failures)

static func _validate_m5_faction_token_migration(section: Dictionary, faction_tokens: Array, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "approved_active_token_migration_character_art_staging_only", "M5 must activate the faction token migration without activating staged character bitmaps", failures)
	_expect(String(section.get("emblem_root", "")) == "res://assets/graphics/emblems/v019", "M5 emblems must live under the active v0.19 emblem root", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))), "the M5 faction token review scene must exist", failures)
	_expect(FileAccess.file_exists(String(section.get("capture", ""))), "the rendered M5 faction token review must exist", failures)
	var ui_surfaces := section.get("ui_surfaces", []) as Array
	for surface in ["candidate_selection", "candidate_profile", "faction_prelude_hud", "boss_warning", "boss_health", "codex", "result_timeline", "guard_cell_frame"]:
		_expect(ui_surfaces.has(surface), "M5 must record the '%s' faction-token UI surface" % surface, failures)
	var emblem_aliases := section.get("legacy_emblem_aliases", {}) as Dictionary
	var marker_aliases := section.get("legacy_marker_aliases", {}) as Dictionary
	_expect(emblem_aliases.size() == 5 and marker_aliases.size() == 5, "M5 must preserve five one-way emblem aliases and five marker aliases", failures)
	var assets := section.get("assets", []) as Array
	_expect(assets.size() == 5, "M5 must activate exactly five semantic faction emblems", failures)
	var campaign := load("res://data/concepts/demon_election_campaign_v0_8.tres") as ElectionCampaignData
	var catalog := load(ACTIVE_CATALOG_PATH) as GameAssetCatalogData
	_expect(campaign != null and catalog != null, "M5 campaign and asset catalog resources must load", failures)
	var faction_by_id: Dictionary = {}
	for faction_value in faction_tokens:
		var faction_token := faction_value as Dictionary
		faction_by_id[String(faction_token.get("id", ""))] = faction_token
	for asset_value in assets:
		var asset := asset_value as Dictionary
		var faction_id := String(asset.get("faction_id", ""))
		_expect(EXPECTED_FACTIONS.has(faction_id), "unexpected M5 faction asset '%s'" % faction_id, failures)
		if not EXPECTED_FACTIONS.has(faction_id):
			continue
		var expected := EXPECTED_FACTIONS[faction_id] as Dictionary
		var emblem_id := String(asset.get("emblem_id", ""))
		var marker_style := String(asset.get("marker_style", ""))
		var path := String(asset.get("path", ""))
		_expect(emblem_id == String(expected.emblem_id) and marker_style == String(expected.symbol), "M5 faction '%s' must bind its approved emblem and marker IDs" % faction_id, failures)
		_expect(path == "res://assets/graphics/emblems/v019/%s.svg" % emblem_id and FileAccess.file_exists(path), "M5 faction '%s' must resolve its active semantic SVG" % faction_id, failures)
		var texture := load(path) as Texture2D
		_expect(texture != null and texture.get_size() == Vector2(128.0, 128.0), "M5 emblem '%s' must import as a dedicated 128px texture" % emblem_id, failures)
		if campaign != null:
			var faction := campaign.faction(StringName(faction_id))
			_expect(faction != null and String(faction.emblem_id) == emblem_id and String(faction.active_marker_style()) == marker_style, "active campaign faction '%s' must use the M5 semantic emblem and marker" % faction_id, failures)
			if faction != null:
				_expect(faction.primary_color.is_equal_approx(Color.from_string(String(expected.primary), Color.TRANSPARENT)), "active faction '%s' primary color must match the manifest" % faction_id, failures)
				_expect(faction.secondary_color.is_equal_approx(Color.from_string(String(expected.secondary), Color.TRANSPARENT)), "active faction '%s' secondary color must match the manifest" % faction_id, failures)
				_expect(faction.accent_color.is_equal_approx(Color.from_string(String(expected.accent), Color.TRANSPARENT)), "active faction '%s' accent color must match the manifest" % faction_id, failures)
		if catalog != null:
			_expect(catalog.content_alias_target(&"emblems", StringName(expected.legacy_emblem)) == StringName(emblem_id), "legacy emblem '%s' must alias to '%s'" % [expected.legacy_emblem, emblem_id], failures)
		_expect(String(marker_aliases.get(String(expected.legacy_marker), "")) == marker_style, "legacy marker '%s' must normalize to '%s'" % [expected.legacy_marker, marker_style], failures)
	var marker_source := FileAccess.get_file_as_string("res://scripts/ui/faction_marker_icon.gd")
	var enemy_source := FileAccess.get_file_as_string("res://scripts/actors/enemy.gd")
	for expected_value in EXPECTED_FACTIONS.values():
		var expected := expected_value as Dictionary
		_expect(marker_source.contains(String(expected.symbol)) and enemy_source.contains(String(expected.symbol)), "M5 marker '%s' must be rendered in both UI and battlefield contexts" % expected.symbol, failures)
	var hud_scene := FileAccess.get_file_as_string("res://scenes/ui/hud.tscn")
	var codex_source := FileAccess.get_file_as_string("res://scripts/ui/codex_browser.gd")
	var result_source := FileAccess.get_file_as_string("res://scripts/ui/result_progress_timeline.gd")
	var preparation_source := FileAccess.get_file_as_string("res://scripts/ui/preparation_panel.gd")
	_expect(hud_scene.contains("PreludeMarker") and hud_scene.contains("WarningMarker") and hud_scene.contains("BossMarker"), "M5 HUD must expose faction markers for Prelude, boss warning, and boss health", failures)
	_expect(codex_source.contains("detail_faction_emblem") and result_source.contains("emblem_id") and preparation_source.contains("guard_primary_color"), "M5 codex, result timeline, and guard cells must consume faction tokens", failures)

static func _validate_m6_catalog_activation(section: Dictionary, failures: Array[String]) -> void:
	_expect(String(section.get("status", "")) == "approved_active_character_catalog", "M6 must record the active character catalog approval", failures)
	_expect(String(section.get("review_catalog", "")) == M6_REVIEW_CATALOG_PATH and FileAccess.file_exists(M6_REVIEW_CATALOG_PATH), "M6 must preserve its explicit review-catalog recipe", failures)
	_expect(FileAccess.file_exists(String(section.get("review_scene", ""))) and FileAccess.file_exists(String(section.get("review_audit_scene", ""))), "M6 review and automated audit scenes must exist", failures)
	var captures := section.get("captures", []) as Array
	_expect(captures.size() == 4, "M6 must preserve four complete catalog review pages", failures)
	for capture_value in captures:
		var capture_path := String(capture_value)
		_expect(FileAccess.file_exists(capture_path), "M6 review capture must exist: %s" % capture_path, failures)
		if FileAccess.file_exists(capture_path):
			var capture := Image.load_from_file(ProjectSettings.globalize_path(capture_path))
			_expect(capture != null and capture.get_size() == Vector2i(1280, 720), "M6 review capture must remain 1280x720: %s" % capture_path, failures)
	_expect(int(section.get("approved_override_count", 0)) == 54 and int(section.get("normalized_master_count", 0)) == 30 and int(section.get("runtime_texture_limit", 0)) == 512, "M6 must record 54 active assets, 30 safe-margin normalizations, and a 512px runtime cap", failures)
	_expect(String(section.get("activation_method", "")) == "recoverable_canonical_batch_copy_with_stable_ids", "M6 activation must remain recoverable and preserve stable content IDs", failures)
	_expect((section.get("findings", []) as Array).size() >= 5, "M6 must record alpha, runtime size, coverage, intrusion fallback, and 68-content audit findings", failures)
	var config_value: Variant = JSON.parse_string(FileAccess.get_file_as_string(M6_REVIEW_CATALOG_PATH))
	_expect(config_value is Dictionary, "M6 review catalog must parse as JSON", failures)
	if not config_value is Dictionary:
		return
	var config := config_value as Dictionary
	var overrides := config.get("overrides", {}) as Dictionary
	var expected_counts := section.get("active_category_counts", {}) as Dictionary
	_expect(overrides.size() == 54 and int(config.get("expected_override_count", 0)) == 54, "M6 review catalog must enumerate exactly 54 approved identities", failures)
	_expect(int(config.get("runtime_texture_limit", 0)) == 512 and String(config.get("base_catalog_path", "")) == ACTIVE_CATALOG_PATH, "M6 review catalog must clone the active catalog with the 512px import policy", failures)
	var actual_counts: Dictionary = {}
	var source_hashes: Dictionary = {}
	for key_value in overrides:
		var key := String(key_value)
		var category := key.get_slice("/", 0)
		var content_id := key.get_slice("/", 1)
		actual_counts[category] = int(actual_counts.get(category, 0)) + 1
		var source_path := String(overrides[key_value])
		var active_path := _m6_active_path(category, content_id)
		_expect(FileAccess.file_exists(source_path) and FileAccess.file_exists(active_path), "M6 source and active asset must both exist: %s" % key, failures)
		if FileAccess.file_exists(source_path) and FileAccess.file_exists(active_path):
			var source_hash := FileAccess.get_sha256(source_path)
			_expect(source_hash == FileAccess.get_sha256(active_path), "M6 active stable-ID file must exactly match its approved master: %s" % key, failures)
			_expect(not source_hashes.has(source_hash), "M6 approved active assets must not contain an exact duplicate: %s" % key, failures)
			source_hashes[source_hash] = key
			var source_image := Image.load_from_file(ProjectSettings.globalize_path(source_path))
			_validate_pilot_image(source_image, "M6/%s" % key, failures)
			_validate_safe_margin(source_image, "M6/%s" % key, failures)
		var texture := load(active_path) as Texture2D
		_expect(texture != null and texture.get_size() == Vector2(512, 512), "M6 active texture must import at exactly 512px: %s" % key, failures)
		var import_path := "%s.import" % active_path
		_expect(FileAccess.file_exists(import_path) and FileAccess.get_file_as_string(import_path).contains("process/size_limit=512"), "M6 active texture must preserve the 512px import cap: %s" % key, failures)
	for category_value in expected_counts:
		var category := String(category_value)
		_expect(int(actual_counts.get(category, 0)) == int(expected_counts[category_value]), "M6 active category '%s' must preserve its approved count" % category, failures)
	_expect(actual_counts.size() == expected_counts.size(), "M6 active catalog must not add undeclared character categories", failures)
	var catalog_source := FileAccess.get_file_as_string(ACTIVE_CATALOG_PATH)
	for guard_id in ["emerald_guardian", "sapphire_lance", "amethyst_nova", "jade_roulette"]:
		_expect(catalog_source.contains("res://assets/graphics/towers/%s.png" % guard_id), "M6 active catalog must use the stable guard path '%s'" % guard_id, failures)
	_expect(not catalog_source.contains("partason_royal_guard.png") and not catalog_source.contains("jiane_fanatic_follower.png") and not catalog_source.contains("kasuha_abyss_believer.png") and not catalog_source.contains("irelai_resurrected_guard.png"), "M6 active guard overrides must not retain legacy character-named paths", failures)

static func _m6_active_path(category: String, content_id: String) -> String:
	if category == "candidate_sd":
		return "res://assets/graphics/combat_sd/candidates/%s.png" % content_id
	if category == "retainer_sd":
		return "res://assets/graphics/combat_sd/retainers/%s.png" % content_id
	return "res://assets/graphics/%s/%s.png" % [category, content_id]

static func _validate_safe_margin(image: Image, label: String, failures: Array[String]) -> void:
	if image == null:
		return
	var margins := _alpha_margin_ratios(image)
	var minimum_margin := minf(minf(float(margins.left), float(margins.right)), minf(float(margins.top), float(margins.bottom)))
	_expect(minimum_margin >= 0.07, "staged character '%s' must keep at least seven percent alpha-safe margin on every side: %s" % [label, margins], failures)

static func _alpha_margin_ratios(source: Image) -> Dictionary:
	var image := source.duplicate() as Image
	image.convert(Image.FORMAT_RGBA8)
	var width: int = image.get_width()
	var height: int = image.get_height()
	var data: PackedByteArray = image.get_data()
	var left: int = width
	var right: int = width
	var top: int = height
	var bottom: int = height
	for x_value in range(width):
		var x := int(x_value)
		if _column_has_visible_alpha(data, width, height, x):
			left = x
			break
	for offset_value in range(width):
		var offset := int(offset_value)
		var x := width - 1 - offset
		if _column_has_visible_alpha(data, width, height, x):
			right = offset
			break
	for y_value in range(height):
		var y := int(y_value)
		if _row_has_visible_alpha(data, width, y):
			top = y
			break
	for offset_value in range(height):
		var offset := int(offset_value)
		var y := height - 1 - offset
		if _row_has_visible_alpha(data, width, y):
			bottom = offset
			break
	return {"left": float(left) / width, "right": float(right) / width, "top": float(top) / height, "bottom": float(bottom) / height}

static func _column_has_visible_alpha(data: PackedByteArray, width: int, height: int, x: int) -> bool:
	for y in range(height):
		if data[(y * width + x) * 4 + 3] > 2:
			return true
	return false

static func _row_has_visible_alpha(data: PackedByteArray, width: int, y: int) -> bool:
	var start := (y * width) * 4 + 3
	for x in range(width):
		if data[start + x * 4] > 2:
			return true
	return false

static func _validate_pilot_image(image: Image, label: String, failures: Array[String]) -> void:
	_expect(image != null, "pilot '%s' must load as an image" % label, failures)
	if image == null:
		return
	var size := image.get_size()
	_expect(size.x == size.y and size.x >= 1024, "pilot '%s' must keep a high-resolution square master" % label, failures)
	_expect(image.get_format() in [Image.FORMAT_RGBA8, Image.FORMAT_RGBAF, Image.FORMAT_RGBAH], "pilot '%s' must preserve an alpha-capable image format" % label, failures)
	var last := size - Vector2i.ONE
	_expect(image.get_pixel(0, 0).a <= 0.01 and image.get_pixel(last.x, 0).a <= 0.01 and image.get_pixel(0, last.y).a <= 0.01 and image.get_pixel(last.x, last.y).a <= 0.01, "pilot '%s' must keep all four corners transparent" % label, failures)

static func _find_by_id(entries: Array, reference_id: String) -> Dictionary:
	for value in entries:
		var entry := value as Dictionary
		if String(entry.get("reference_id", "")) == reference_id:
			return entry
	return {}

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
