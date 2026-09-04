class_name ElectionCampaignContractTest
extends RefCounted

const DEFAULT_PROFILE_PATH := "res://data/concepts/formation_defense.tres"
const ELECTION_PROFILE_PATH := "res://data/concepts/demon_election_vertical_slice.tres"

static func run() -> Array[String]:
	var failures: Array[String] = []
	var original_profile_path := ConceptService.active_path
	_expect(
		ConceptService.active != null
		and ConceptService.active.text_catalog != null
		and ConceptService.active.text_catalog.get_validation_errors().is_empty(),
		"the default profile must expose a complete validated UI text catalog",
		failures
	)
	_expect(
		ConceptService.active != null
		and ConceptService.active.content_pack != null
		and ConceptService.active.content_pack.id == &"demon_election_builtin_v019"
		and ConceptService.active.content_pack.is_playable(ConceptService.get_default_stage(), ConceptService.get_stage_reward())
		and DataRegistry.using_external_content_pack,
		"the active election profile must load its editable validated content pack instead of rebuilding the default combat catalog in code",
		failures
	)
	var source_pack := ConceptService.active.content_pack
	_expect(
		source_pack != null
		and source_pack.cores[0] != DataRegistry.cores[0]
		and source_pack.formations[0] != DataRegistry.formations[0]
		and source_pack.formations[0].cells[0] != DataRegistry.formations[0].cells[0],
		"the registry must deep-copy authoring resources before runtime pace or gameplay mutation",
		failures
	)
	var generic_text_catalog := load("res://data/concepts/formation_defense_texts.tres") as GameTextCatalogData
	_expect(
		generic_text_catalog != null
		and generic_text_catalog.resolve(&"menu.game_subtitle", {&"core": "핵", &"cursor": "목표지점"}).contains("핵 / 목표지점"),
		"text catalog token replacement must resolve role terminology",
		failures
	)
	if not ConceptService.load_profile(ELECTION_PROFILE_PATH):
		failures.append("the demon election vertical-slice profile must load at runtime")
	else:
		var campaign := ConceptService.get_election_campaign()
		_expect(campaign != null, "the election profile must expose a campaign contract", failures)
		if campaign != null:
			_expect(campaign.expected_candidate_count == 5 and campaign.expected_boss_slot_count == 4, "the election campaign must declare five selectable candidates and four rival boss slots", failures)
			var faction_marker_styles: Dictionary = {}
			for faction in campaign.factions:
				faction_marker_styles[faction.marker_style] = true
			_expect(faction_marker_styles.size() == 5 and campaign.factions.all(func(faction: ElectionFactionData) -> bool: return faction.marker_style in ElectionFactionData.ACTIVE_MARKER_STYLES), "all five factions must own distinct active v0.19 color-independent battlefield marker styles", failures)
			_expect(ElectionFactionData.normalized_marker_style(&"crown") == &"sword_shield" and ElectionFactionData.normalized_marker_style(&"judgment") == &"scythe_blood", "legacy battlefield marker names must normalize to the active semantic silhouettes", failures)
			_expect(campaign.decree_catalog != null and campaign.decree_catalog.decrees.size() == 15 and campaign.candidates.all(func(candidate: CandidateProfileData) -> bool: return campaign.decrees_for_candidate(candidate.id).size() == 3), "each of the five candidates must own exactly three data-driven decrees", failures)
			_expect(campaign.governance_reactions != null and campaign.governance_reactions.get_validation_errors().is_empty(), "the election campaign must define five continuous governance reaction tiers", failures)
			_expect(campaign.governance_reaction(0).id == &"cold" and campaign.governance_reaction(50).id == &"neutral" and campaign.governance_reaction(100).id == &"fervent", "governance approval boundaries must resolve to cold, neutral, and fervent reactions", failures)
			_expect(campaign.get_validation_errors().is_empty(), "the election campaign must satisfy its internal candidate-retainer-faction links", failures)
			_expect(DataRegistry.validate_campaign(campaign).is_empty(), "the election campaign must reference every active core, cursor, enemy, and boss by a valid stable id", failures)
			var partason := campaign.candidate_for_core(&"emerald")
			var kanda := campaign.retainer_for_cursor(&"iron")
			var judaginda := campaign.candidate_for_core(&"obsidian")
			var death_vanguard := campaign.retainer_for_cursor(&"vanguard")
			_expect(partason != null and partason.id == &"partason" and partason.default_retainer_id == &"kanda", "emerald must map to candidate Partason and default retainer Kanda", failures)
			_expect(kanda != null and kanda.id == &"kanda" and kanda.preferred_candidate_id == &"partason", "iron must map back to retainer Kanda and candidate Partason", failures)
			_expect(judaginda != null and judaginda.id == &"judaginda" and judaginda.default_retainer_id == &"death_vanguard", "obsidian must map to candidate Judaginda and the Death Cult Vanguard", failures)
			_expect(death_vanguard != null and death_vanguard.preferred_candidate_id == &"judaginda", "vanguard must map back to Judaginda", failures)
			_expect(judaginda != null and judaginda.full_name == "죽음교주 주다긴다" and judaginda.title == "죽음교주", "Judaginda presentation must match the v0.14 candidate concept", failures)
			var retired_display_terms := ["에메랄드", "사파이어", "아메지스트", "옵시디언", "제이드"]
			for core in DataRegistry.cores:
				for retired_term in retired_display_terms:
					_expect(not core.display_name.contains(retired_term) and not core.description.contains(retired_term), "candidate presentation for stable core '%s' must not expose retired gemstone term '%s'" % [core.id, retired_term], failures)
			for guard_id in [&"emerald_guardian", &"sapphire_lance", &"amethyst_nova", &"jade_roulette", &"obsidian_verdict", &"obsidian_inquisitor"]:
				var guard := DataRegistry.get_tower(guard_id)
				for retired_term in retired_display_terms:
					_expect(guard != null and not guard.display_name.contains(retired_term) and not guard.description.contains(retired_term), "guard presentation '%s' must not expose retired gemstone term '%s'" % [guard_id, retired_term], failures)
			_expect(campaign.candidate_for_boss(&"boss_5") == partason and campaign.faction_for_boss(&"boss_5").id == &"partason_faction", "boss presentation lookup must resolve Partason and the orthodox faction from boss_5", failures)
			_expect(campaign.faction_for_enemy(&"partason_standard_shield").id == &"partason_faction", "Partason's faction enemy must resolve the orthodox faction palette", failures)
			_expect(campaign.faction_for_enemy(&"jiane_succubus_bewitcher").id == &"jiane_faction", "Jiane's faction enemy must resolve the dream alliance palette", failures)
			_expect(campaign.faction_for_enemy(&"kasuha_abyss_creature").id == &"kasuha_faction", "Kasuha's faction enemy must resolve the abyss research palette", failures)
			_expect(campaign.faction_for_enemy(&"irelai_skeleton_cavalry").id == &"irelai_faction", "Irelai's faction enemy must resolve the necromancy union palette", failures)
			_expect(campaign.faction_for_enemy(&"judaginda_cult_applicant").id == &"judaginda_faction", "Judaginda's faction enemy must resolve the death-cult palette", failures)
			_expect(campaign.faction_for_enemy(&"civilian_slime") == null, "common v0.15 enemies must not inherit a candidate faction palette", failures)
			var invalid_reference := campaign.duplicate(true) as ElectionCampaignData
			invalid_reference.candidates[0].core_id = &"missing_core"
			_expect("\n".join(DataRegistry.validate_campaign(invalid_reference)).contains("missing_core"), "campaign validation must reject a candidate whose combat core id is absent", failures)
			var duplicate_candidate := campaign.duplicate(true) as ElectionCampaignData
			duplicate_candidate.candidates[1].id = duplicate_candidate.candidates[0].id
			_expect("\n".join(duplicate_candidate.get_validation_errors()).contains("duplicate id"), "campaign validation must reject duplicate stable candidate ids", failures)
			var duplicate_supporter := campaign.duplicate(true) as ElectionCampaignData
			duplicate_supporter.factions[1].supporter_enemy_ids.append(duplicate_supporter.factions[0].supporter_enemy_ids[0])
			_expect("\n".join(duplicate_supporter.get_validation_errors()).contains("multiple election factions"), "campaign validation must reject ambiguous enemy palette ownership", failures)
			var duplicate_marker := campaign.duplicate(true) as ElectionCampaignData
			duplicate_marker.factions[1].marker_style = duplicate_marker.factions[0].marker_style
			_expect("\n".join(duplicate_marker.get_validation_errors()).contains("share marker style"), "campaign validation must reject duplicate faction marker silhouettes", failures)
			for candidate in campaign.candidates:
				var portrait := ConceptService.content_texture(&"candidates", candidate.id)
				var emblem := ConceptService.content_texture(&"emblems", candidate.emblem_id)
				var legacy_core := DataRegistry.get_core(candidate.core_id)
				_expect(portrait != null and portrait.get_size() == Vector2(512.0, 512.0), "each election candidate must resolve a dedicated optimized 512px portrait", failures)
				_expect(emblem != null, "each election candidate must resolve a dedicated faction emblem", failures)
				_expect(legacy_core != null and legacy_core.texture == emblem, "each compatibility core must present the candidate emblem instead of retired gemstone art", failures)
			for retainer in campaign.retainers:
				var portrait := ConceptService.content_texture(&"retainers", retainer.id)
				_expect(portrait != null and portrait.get_size() == Vector2(512.0, 512.0), "each election retainer must resolve a dedicated optimized 512px portrait", failures)
			var palette_enemy := Enemy.new()
			palette_enemy.setup(DataRegistry.get_enemy(&"civilian_slime"), Vector2(640.0, 360.0), 0, Vector2(120.0, 360.0), 1.0, 1.0)
			palette_enemy.set_campaign_faction(campaign.faction_for_enemy(&"partason_standard_shield"))
			_expect(palette_enemy.campaign_faction_id == &"partason_faction" and palette_enemy.campaign_marker_style == &"sword_shield" and palette_enemy.campaign_emblem != null, "campaign enemies must receive the active v0.19 palette, color-independent marker, and emblem through the runtime presentation layer", failures)
			palette_enemy.free()
			var legacy_partason_emblem := ConceptService.content_texture(&"emblems", &"partason_crown")
			_expect(legacy_partason_emblem == ConceptService.content_texture(&"emblems", &"partason_sword_shield"), "legacy emblem ids must resolve through one-way aliases to the active v0.19 emblems", failures)
			_expect(ConceptService.active.assets.id == &"demon_election_assets", "the election profile must own a dedicated asset catalog instead of mutating the default catalog", failures)
		_expect(ConceptService.term(&"core") == "마왕 후보" and ConceptService.term(&"cursor") == "수석 심복" and ConceptService.term(&"boss") == "공식 난입", "the election profile must replace player-facing role terminology", failures)
		var campaign_copy := FileAccess.get_file_as_string("res://data/concepts/demon_election_campaign_v0_8.tres")
		var decree_copy := FileAccess.get_file_as_string("res://data/concepts/demon_election_decrees_v0_8.tres")
		for retired_copy in ["후보 스킬", "핵 돌파", "보스"]:
			_expect(not campaign_copy.contains(retired_copy), "active campaign copy must not expose retired term '%s'" % retired_copy, failures)
		_expect(not decree_copy.contains("타워 피해"), "active decree summaries must use election support-force terminology", failures)
		_expect(ConceptService.ui_text(&"hud.skill") == "필살 공약" and ConceptService.ui_text(&"result.victory") == "연설 완주", "the election profile must replace key HUD and result copy through the text catalog", failures)
		_expect(
			ConceptService.ui_text(&"hud.boss_warning", {&"position": "23", &"candidate": "파르태손 8세", &"faction": "마왕 정통파"}).contains("공식 난입")
			and ConceptService.ui_text(&"level_up.title", {&"level": 4, &"candidate": "파르태손 8세"}).contains("공약 선택"),
			"the election catalog must own boss warning and level-up campaign copy",
			failures
		)
	var invalid_text := load("res://data/concepts/formation_defense_texts.tres").duplicate(true) as GameTextCatalogData
	invalid_text.entries.erase(&"hud.skill")
	_expect("\n".join(invalid_text.get_validation_errors()).contains("hud.skill"), "text catalog validation must reject a missing required UI key", failures)
	var invalid_placeholders := load("res://data/concepts/formation_defense_texts.tres").duplicate(true) as GameTextCatalogData
	invalid_placeholders.placeholder_contracts[&"hud.boss_warning"] = PackedStringArray(["position"])
	_expect("\n".join(invalid_placeholders.get_validation_errors()).contains("do not match declared contract"), "text catalog validation must reject placeholder contract drift", failures)
	_expect(
		generic_text_catalog.missing_replacements(&"hud.boss_warning", {&"position": "23"}) == PackedStringArray(["boss"])
		and generic_text_catalog.resolve(&"hud.boss_warning", {&"position": "23"}, "보스 정보를 불러오지 못했습니다") == "보스 정보를 불러오지 못했습니다",
		"text resolution must expose missing replacements and fall back without leaking template tokens",
		failures
	)
	var restore_path := original_profile_path if not original_profile_path.is_empty() else DEFAULT_PROFILE_PATH
	if not ConceptService.load_profile(restore_path):
		failures.append("the original concept profile must be restored after election contract tests")
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
