class_name CombatCharacterArtContractTest
extends RefCounted

const ELECTION_PROFILE_PATH := "res://data/concepts/demon_election_vertical_slice.tres"

static func run() -> Array[String]:
	var failures: Array[String] = []
	var original_profile_path := ConceptService.active_path
	if not ConceptService.load_profile(ELECTION_PROFILE_PATH):
		failures.append("the election profile must load for combat SD art validation")
	else:
		var campaign := ConceptService.get_election_campaign()
		_expect(campaign != null, "the election profile must expose its campaign for complete combat SD coverage", failures)
		var completed := {&"candidate_sd": [], &"retainer_sd": []}
		if campaign != null:
			for candidate in campaign.candidates:
				if candidate != null:
					completed[&"candidate_sd"].append(candidate.id)
			for retainer in campaign.retainers:
				if retainer != null:
					completed[&"retainer_sd"].append(retainer.id)
			_expect(completed[&"candidate_sd"].size() == campaign.expected_candidate_count and completed[&"retainer_sd"].size() == campaign.expected_candidate_count, "combat SD coverage must enumerate every campaign candidate and retainer", failures)
		for category_value in completed:
			var category := StringName(category_value)
			var intrusion_category := &"candidate_intrusion_sd" if category == &"candidate_sd" else &"retainer_intrusion_sd"
			for content_id_value in completed[category_value]:
				var content_id := StringName(content_id_value)
				var texture := ConceptService.optional_content_texture(category, content_id)
				_expect(texture != null and texture.get_size() == Vector2(512.0, 512.0), "%s/%s must own a mobile-optimized 512px combat SD cutout" % [category, content_id], failures)
				_validate_transparency(texture, String(content_id), failures)
				var intrusion_texture := ConceptService.optional_content_texture(intrusion_category, content_id)
				_expect(intrusion_texture != null and intrusion_texture.get_size() == Vector2(512.0, 512.0), "%s/%s must own a dedicated mobile-optimized 512px intrusion cutout" % [intrusion_category, content_id], failures)
				_validate_transparency(intrusion_texture, "%s intrusion" % content_id, failures)
		_expect(ConceptService.optional_content_texture(&"candidate_sd", &"unknown_character") == null and ConceptService.optional_content_texture(&"retainer_sd", &"unknown_character") == null, "combat SD categories must remain optional and never invent a fallback for unknown identities", failures)
		_expect(ConceptService.optional_content_texture(&"candidate_intrusion_sd", &"unknown_character") == null and ConceptService.optional_content_texture(&"retainer_intrusion_sd", &"unknown_character") == null and ConceptService.optional_content_texture(&"guard_intrusion_sd", &"unknown_character") == null, "intrusion SD categories must remain optional and never invent a fallback for unknown identities", failures)
		if campaign != null:
			for retainer in campaign.retainers:
				var boss_data := DataRegistry.find_enemy(retainer.retainer_boss_id)
				var faction := campaign.faction_for_boss(retainer.retainer_boss_id)
				if boss_data == null or faction == null:
					continue
				var enemy := Enemy.new()
				enemy.data = boss_data
				enemy.set_campaign_faction(faction)
				enemy.set_campaign_character_identity(retainer.id, false)
				_expect(enemy.campaign_character_art == ConceptService.optional_content_texture(&"retainer_intrusion_sd", retainer.id), "an active retainer intrusion must use its dedicated authored cutout: %s" % String(retainer.id), failures)
				_expect(enemy.campaign_character_art_source_category == &"retainer_intrusion_sd" and not enemy.campaign_character_art_flip_h, "dedicated retainer intrusion '%s' must preserve its authored left-facing orientation" % retainer.id, failures)
				enemy.free()
			for candidate in campaign.candidates:
				var enemy := Enemy.new()
				enemy.set_campaign_character_identity(candidate.id, true)
				_expect(enemy.campaign_character_art == ConceptService.optional_content_texture(&"candidate_intrusion_sd", candidate.id), "an active candidate intrusion must use its dedicated authored cutout: %s" % String(candidate.id), failures)
				_expect(enemy.campaign_character_art_source_category == &"candidate_intrusion_sd" and not enemy.campaign_character_art_flip_h, "dedicated candidate intrusion '%s' must preserve its authored left-facing orientation" % candidate.id, failures)
				enemy.free()
			_expect(GameAssetCatalogData.CONTENT_CATEGORIES.has(&"guard_intrusion_sd"), "the asset catalog must reserve an optional category for authored faction guard intrusions", failures)
			for guard_faction in campaign.factions:
				if guard_faction == null:
					continue
				var guard_candidate := campaign.candidate(guard_faction.candidate_id)
				var guard_core := DataRegistry.get_core(guard_candidate.core_id) if guard_candidate != null else null
				var guard_tower_id: StringName = guard_core.unique_tower_id if guard_core != null else &""
				var guard_texture := ConceptService.optional_content_texture(&"guard_intrusion_sd", guard_faction.id)
				_expect(guard_texture != null and guard_texture.get_size() == Vector2(512.0, 512.0), "active faction guard '%s' must own a mobile-optimized dedicated intrusion cutout" % guard_faction.id, failures)
				_validate_transparency(guard_texture, "%s guard intrusion" % guard_faction.id, failures)
				var guard_enemy := Enemy.new()
				guard_enemy.set_campaign_character_presentation(StageRuntimeBossPlan.PRESENTATION_GUARD, guard_faction.id, guard_tower_id)
				_expect(guard_enemy.campaign_character_art == guard_texture and guard_enemy.campaign_character_art_source_category == &"guard_intrusion_sd" and not guard_enemy.campaign_character_art_flip_h, "active faction guard '%s' must use its authored left-facing intrusion art" % guard_faction.id, failures)
				_expect(guard_enemy.campaign_character_presentation_kind == StageRuntimeBossPlan.PRESENTATION_GUARD and guard_enemy.campaign_character_presentation_id == guard_faction.id, "a faction guard intrusion must preserve its presentation identity independently of the mechanic boss shell", failures)
				guard_enemy.free()
			_validate_external_pack_fallback(campaign, failures)
	var restore_path := original_profile_path if not original_profile_path.is_empty() else ConceptService.DEFAULT_PROFILE_PATH
	if not ConceptService.load_profile(restore_path):
		failures.append("the original concept profile must be restored after combat SD art validation")
	return failures

static func _validate_external_pack_fallback(campaign: ElectionCampaignData, failures: Array[String]) -> void:
	if campaign.candidates.is_empty() or campaign.retainers.is_empty() or ConceptService.active == null or ConceptService.active.assets == null:
		return
	var candidate = campaign.candidates[0]
	var retainer = campaign.retainers[0]
	if candidate == null or retainer == null:
		return
	var candidate_ally := ConceptService.optional_content_texture(&"candidate_sd", candidate.id)
	var retainer_ally := ConceptService.optional_content_texture(&"retainer_sd", retainer.id)
	var guard_core := DataRegistry.get_core(candidate.core_id)
	var guard_tower_id: StringName = guard_core.unique_tower_id if guard_core != null else &""
	var guard_ally := ConceptService.optional_content_texture(&"towers", guard_tower_id)
	if candidate_ally == null or retainer_ally == null or guard_ally == null:
		return
	var original_catalog := ConceptService.active.assets
	var compatibility_catalog := original_catalog.duplicate(true) as GameAssetCatalogData
	compatibility_catalog.graphics_root = "res://assets/graphics/__external_pack_without_optional_intrusions"
	compatibility_catalog.content_texture_overrides = {
		"candidate_sd/%s" % String(candidate.id): candidate_ally,
		"retainer_sd/%s" % String(retainer.id): retainer_ally,
		"towers/%s" % String(guard_tower_id): guard_ally,
	}
	ConceptService.active.assets = compatibility_catalog
	ConceptService.clear_runtime_asset_cache()
	var candidate_enemy := Enemy.new()
	candidate_enemy.set_campaign_character_identity(candidate.id, true)
	_expect(candidate_enemy.campaign_character_art == candidate_ally and candidate_enemy.campaign_character_art_source_category == &"candidate_sd" and candidate_enemy.campaign_character_art_flip_h, "an external pack without candidate intrusion art must safely flip the allied SD", failures)
	candidate_enemy.free()
	var retainer_enemy := Enemy.new()
	retainer_enemy.set_campaign_character_identity(retainer.id, false)
	_expect(retainer_enemy.campaign_character_art == retainer_ally and retainer_enemy.campaign_character_art_source_category == &"retainer_sd" and retainer_enemy.campaign_character_art_flip_h, "an external pack without retainer intrusion art must safely flip the allied SD", failures)
	retainer_enemy.free()
	var guard_enemy := Enemy.new()
	guard_enemy.set_campaign_character_presentation(StageRuntimeBossPlan.PRESENTATION_GUARD, candidate.faction_id, guard_tower_id)
	_expect(guard_enemy.campaign_character_art == guard_ally and guard_enemy.campaign_character_art_source_category == &"towers" and guard_enemy.campaign_character_art_flip_h, "an external pack without guard intrusion art must safely flip the allied guard tower", failures)
	guard_enemy.free()
	ConceptService.active.assets = original_catalog
	ConceptService.clear_runtime_asset_cache()

static func _validate_transparency(texture: Texture2D, label: String, failures: Array[String]) -> void:
	if texture == null:
		return
	var image := texture.get_image()
	_expect(image != null and image.get_format() in [Image.FORMAT_RGBA8, Image.FORMAT_RGBAF, Image.FORMAT_RGBAH], "%s combat SD art must preserve an alpha-capable import format" % label, failures)
	if image != null:
		var last := image.get_size() - Vector2i.ONE
		_expect(image.get_pixel(0, 0).a <= 0.01 and image.get_pixel(last.x, 0).a <= 0.01 and image.get_pixel(0, last.y).a <= 0.01 and image.get_pixel(last.x, last.y).a <= 0.01, "%s combat SD art must keep all four corners transparent" % label, failures)

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
