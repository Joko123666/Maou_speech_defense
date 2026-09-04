class_name AssetCoverageContractTest
extends RefCounted

const DEFAULT_PROFILE_PATH := "res://data/concepts/formation_defense.tres"
const ELECTION_PROFILE_PATH := "res://data/concepts/demon_election_vertical_slice.tres"
const EXPECTED_ALIASES: Array[String] = []
const NORMAL_DEFENDER_IDS: Array[StringName] = [
	&"rapid", &"area", &"pierce", &"slow", &"knockback", &"execute", &"mark", &"chain", &"rubber_golem",
]
const UNIQUE_GUARD_IDS: Array[StringName] = [
	&"emerald_guardian", &"sapphire_lance", &"amethyst_nova", &"jade_roulette", &"obsidian_verdict", &"obsidian_inquisitor",
]
const CANDIDATE_EFFECT_IDS: Array[StringName] = [&"jiane_dream_barrier", &"judaginda_verdict_seal"]
const ELECTION_PROJECTILE_IDS: Array[StringName] = [&"goblin_javelin", &"skeleton_grenade", &"royal_slash", &"judgment_bolt"]
const GUARD_IDENTITY_PATHS := {
	&"emerald_guardian": "emerald_guardian.png",
	&"sapphire_lance": "sapphire_lance.png",
	&"amethyst_nova": "amethyst_nova.png",
	&"jade_roulette": "jade_roulette.png",
	&"obsidian_verdict": "obsidian_verdict.png",
	&"obsidian_inquisitor": "obsidian_inquisitor.png",
}
const TOWER_PROJECTILE_IDS := {
	&"rapid": &"goblin_javelin",
	&"area": &"skeleton_grenade",
	&"emerald_guardian": &"royal_slash",
	&"obsidian_verdict": &"judgment_bolt",
	&"obsidian_inquisitor": &"judgment_bolt",
}

static func run() -> Array[String]:
	var failures: Array[String] = []
	var original_profile_path := ConceptService.active_path
	if not ConceptService.load_profile(ELECTION_PROFILE_PATH):
		failures.append("the election profile must load for the complete content asset audit")
	else:
		var requests: Array[Dictionary] = []
		_append_resource_requests(requests, &"cores", DataRegistry.cores)
		_append_resource_requests(requests, &"cursors", DataRegistry.cursors)
		_append_resource_requests(requests, &"towers", DataRegistry.towers)
		_append_resource_requests(requests, &"enemies", DataRegistry.enemies)
		_append_resource_requests(requests, &"enemies", DataRegistry.faction_enemies)
		_append_resource_requests(requests, &"enemies", DataRegistry.bosses)
		var campaign := ConceptService.get_election_campaign()
		if campaign == null:
			failures.append("the election profile must expose campaign art requests")
		else:
			_append_resource_requests(requests, &"candidates", campaign.candidates)
			_append_resource_requests(requests, &"retainers", campaign.retainers)
			_append_resource_requests(requests, &"factions", campaign.factions)
			for candidate in campaign.candidates:
				requests.append({"category": &"emblems", "id": candidate.emblem_id})
		for effect_id in CANDIDATE_EFFECT_IDS:
			requests.append({"category": &"effects", "id": effect_id})
		for projectile_id in ELECTION_PROJECTILE_IDS:
			requests.append({"category": &"projectiles", "id": projectile_id})
		for defender_id in NORMAL_DEFENDER_IDS:
			requests.append({"category": &"defender_attacks", "id": defender_id})
		for guard_id in UNIQUE_GUARD_IDS:
			requests.append({"category": &"tower_attacks", "id": guard_id})
		var audit := ConceptService.audit_content_assets(requests)
		_expect(audit.requested_count == 83, "the asset audit must cover all 83 active runtime content identities including defender attack poses", failures)
		_expect(audit.dedicated_count == 83 and audit.alias_count == 0, "the asset audit must classify all 83 runtime resources as dedicated", failures)
		_expect(audit.missing_count == 0, "runtime content must never silently use a generic fallback: %s" % [audit.missing], failures)
		_expect(audit.aliases == PackedStringArray(EXPECTED_ALIASES), "active runtime identities must not reuse content art: %s" % [audit.aliases], failures)
		var fallback := ConceptService.fallback_texture(&"cores")
		var core_textures: Dictionary = {}
		for core in DataRegistry.cores:
			var texture := ConceptService.content_texture(&"cores", core.id)
			_expect(texture != null and texture != fallback and texture.get_size() == Vector2(128.0, 128.0), "candidate compatibility id '%s' must resolve a dedicated 128px election emblem" % core.id, failures)
			core_textures[texture] = true
		_expect(core_textures.size() == DataRegistry.cores.size(), "all five candidates must resolve visually distinct election emblems", failures)
		_validate_defender_art(failures)
		_validate_guard_art(failures)
		_validate_attack_art(failures)
		_validate_candidate_effect_art(failures)
		_validate_election_projectile_art(failures)
		_validate_faction_enemy_art(failures)
		_validate_alias_rejections(ConceptService.active.assets, failures)
	var restore_path := original_profile_path if not original_profile_path.is_empty() else DEFAULT_PROFILE_PATH
	if not ConceptService.load_profile(restore_path):
		failures.append("the original concept profile must be restored after the asset coverage audit")
	return failures

static func _append_resource_requests(requests: Array[Dictionary], category: StringName, resources: Array) -> void:
	for resource in resources:
		requests.append({"category": category, "id": resource.id})

static func _validate_defender_art(failures: Array[String]) -> void:
	var full_textures: Dictionary = {}
	var icon_textures: Dictionary = {}
	for defender_id in NORMAL_DEFENDER_IDS:
		var full_texture := ConceptService.optional_content_texture(&"defenders", defender_id)
		var face_icon := ConceptService.optional_content_texture(&"defender_icons", defender_id)
		_expect(full_texture != null and full_texture.get_size() == Vector2(512, 512), "defender '%s' must resolve its mobile-capped 512px casual character art" % defender_id, failures)
		_expect(face_icon != null and face_icon.get_size() == Vector2(512, 512), "defender '%s' must resolve its mobile-capped 512px level-up face icon" % defender_id, failures)
		var tower := DataRegistry.get_tower(defender_id)
		_expect(tower != null and tower.texture == full_texture, "defender '%s' must use its casual character art in the runtime tower catalog" % defender_id, failures)
		if full_texture != null:
			full_textures[full_texture] = true
		if face_icon != null:
			icon_textures[face_icon] = true
	_expect(full_textures.size() == NORMAL_DEFENDER_IDS.size(), "all normal defenders must use visually distinct character art", failures)
	_expect(icon_textures.size() == NORMAL_DEFENDER_IDS.size(), "all normal defenders must use visually distinct face icons", failures)

static func _validate_guard_art(failures: Array[String]) -> void:
	var guard_textures: Dictionary = {}
	for guard_id in UNIQUE_GUARD_IDS:
		var guard_texture := ConceptService.optional_content_texture(&"towers", guard_id)
		var guard := DataRegistry.get_tower(guard_id)
		_expect(guard_texture != null and guard_texture.get_size() == Vector2(512, 512), "guard '%s' must resolve its mobile-capped 512px character art" % guard_id, failures)
		_expect(guard != null and guard.is_unique() and guard.texture == guard_texture, "guard '%s' must use its dedicated character art in the runtime tower catalog" % guard_id, failures)
		_expect(guard_texture != null and guard_texture.resource_path == "res://assets/graphics/towers/%s" % String(GUARD_IDENTITY_PATHS[guard_id]), "guard '%s' must resolve its stable-ID v0.19 art instead of a legacy named sprite: %s" % [guard_id, guard_texture.resource_path if guard_texture != null else "missing"], failures)
		if guard_texture != null:
			var image := guard_texture.get_image()
			if image != null:
				var maximum := image.get_size() - Vector2i.ONE
				var transparent_corners := [Vector2i.ZERO, Vector2i(maximum.x, 0), Vector2i(0, maximum.y), maximum]
				_expect(transparent_corners.all(func(point: Vector2i) -> bool: return image.get_pixelv(point).a <= 0.01), "guard '%s' must preserve a transparent cutout background" % guard_id, failures)
			guard_textures[guard_texture] = true
	_expect(guard_textures.size() == UNIQUE_GUARD_IDS.size(), "all six candidate-exclusive guard unit types must use visually distinct character art", failures)

static func _validate_attack_art(failures: Array[String]) -> void:
	var attack_textures: Dictionary = {}
	for defender_id in NORMAL_DEFENDER_IDS:
		_validate_tower_attack_texture(defender_id, &"defender_attacks", attack_textures, failures)
	for guard_id in UNIQUE_GUARD_IDS:
		_validate_tower_attack_texture(guard_id, &"tower_attacks", attack_textures, failures)
	_expect(attack_textures.size() == NORMAL_DEFENDER_IDS.size() + UNIQUE_GUARD_IDS.size(), "all 15 defender types must use visually distinct attack poses", failures)

static func _validate_tower_attack_texture(tower_id: StringName, category: StringName, attack_textures: Dictionary, failures: Array[String]) -> void:
	var attack_texture := ConceptService.optional_content_texture(category, tower_id)
	var tower := DataRegistry.get_tower(tower_id)
	_expect(attack_texture != null and attack_texture.get_size() == Vector2(512, 512), "defender '%s' must resolve a mobile-capped 512px attack pose" % tower_id, failures)
	_expect(tower != null and tower.attack_texture == attack_texture, "defender '%s' must bind its dedicated attack pose in the runtime tower catalog" % tower_id, failures)
	_expect(tower != null and attack_texture != tower.texture, "defender '%s' attack pose must remain distinct from its idle art" % tower_id, failures)
	_expect(attack_texture != null and attack_texture.resource_path == "res://assets/graphics/%s/%s.png" % [String(category), String(tower_id)], "defender '%s' must resolve its stable-ID attack pose path" % tower_id, failures)
	if attack_texture == null:
		return
	var image := attack_texture.get_image()
	if image != null:
		var maximum := image.get_size() - Vector2i.ONE
		var corners := [Vector2i.ZERO, Vector2i(maximum.x, 0), Vector2i(0, maximum.y), maximum]
		_expect(corners.all(func(point: Vector2i) -> bool: return image.get_pixelv(point).a <= 0.01), "defender '%s' attack pose must preserve transparent corners" % tower_id, failures)
	attack_textures[attack_texture] = true

static func _validate_candidate_effect_art(failures: Array[String]) -> void:
	var effect_textures: Dictionary = {}
	for effect_id in CANDIDATE_EFFECT_IDS:
		var texture := ConceptService.optional_content_texture(&"effects", effect_id)
		_expect(texture != null and texture.get_width() >= 1024 and texture.get_height() >= 1024, "candidate effect '%s' must resolve a dedicated high-resolution transparent texture" % effect_id, failures)
		if texture != null:
			effect_textures[texture] = true
	_expect(effect_textures.size() == CANDIDATE_EFFECT_IDS.size(), "Jiane and Judaginda must use visually distinct candidate effect textures", failures)

static func _validate_election_projectile_art(failures: Array[String]) -> void:
	var projectile_textures: Dictionary = {}
	for projectile_id in ELECTION_PROJECTILE_IDS:
		var texture := ConceptService.optional_content_texture(&"projectiles", projectile_id)
		_expect(texture != null and texture.resource_path.contains("/projectiles/election/"), "election projectile '%s' must resolve a concept-specific texture" % projectile_id, failures)
		if texture != null:
			projectile_textures[texture] = true
	_expect(projectile_textures.size() == ELECTION_PROJECTILE_IDS.size(), "all four election projectile silhouettes must be visually distinct", failures)
	for tower_id in TOWER_PROJECTILE_IDS:
		var tower := DataRegistry.get_tower(tower_id)
		_expect(tower != null and tower.projectile_texture_id == TOWER_PROJECTILE_IDS[tower_id], "tower '%s' must use its identity-specific election projectile" % tower_id, failures)

static func _validate_faction_enemy_art(failures: Array[String]) -> void:
	var textures: Dictionary = {}
	for enemy in DataRegistry.faction_enemies:
		var texture := ConceptService.optional_content_texture(&"enemies", enemy.id)
		_expect(texture != null and texture.get_size() == Vector2(512.0, 512.0), "faction enemy '%s' must resolve a dedicated mobile-optimized 512px texture" % enemy.id, failures)
		if texture == null:
			continue
		var image := texture.get_image()
		if image != null:
			var maximum := image.get_size() - Vector2i.ONE
			var corners := [Vector2i.ZERO, Vector2i(maximum.x, 0), Vector2i(0, maximum.y), maximum]
			_expect(corners.all(func(point: Vector2i) -> bool: return image.get_pixelv(point).a <= 0.01), "faction enemy '%s' must preserve transparent corners" % enemy.id, failures)
		textures[texture] = true
	_expect(textures.size() == EnemyCatalogV015.FACTION_IDS.size(), "all five faction representatives must use distinct dedicated art", failures)

static func _validate_alias_rejections(valid_catalog: GameAssetCatalogData, failures: Array[String]) -> void:
	var invalid_source := valid_catalog.duplicate(true) as GameAssetCatalogData
	invalid_source.approved_content_aliases = {"cores/../escape": "cores/emerald"}
	_expect("\n".join(invalid_source.get_validation_errors()).contains("invalid content alias source"), "asset validation must reject unsafe alias source ids", failures)
	var cross_category := valid_catalog.duplicate(true) as GameAssetCatalogData
	cross_category.approved_content_aliases = {"cores/copy": "towers/rapid"}
	_expect("\n".join(cross_category.get_validation_errors()).contains("must stay in one category"), "asset validation must reject cross-category aliases", failures)
	var self_alias := valid_catalog.duplicate(true) as GameAssetCatalogData
	self_alias.approved_content_aliases = {"cores/emerald": "cores/emerald"}
	_expect("\n".join(self_alias.get_validation_errors()).contains("cannot target itself"), "asset validation must reject self-referential aliases", failures)
	var missing_target := valid_catalog.duplicate(true) as GameAssetCatalogData
	missing_target.approved_content_aliases = {"cores/copy": "cores/not_present"}
	_expect("\n".join(missing_target.get_validation_errors()).contains("target is missing"), "asset validation must reject aliases whose target resource is missing", failures)

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
