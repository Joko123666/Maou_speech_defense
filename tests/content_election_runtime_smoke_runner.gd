extends Node

const DEFAULT_CONCEPT_PATH := "res://data/concepts/demon_election_vertical_slice.tres"

var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _run() -> void:
	await get_tree().process_frame
	AudioManager.muted = true
	var original_concept_path := ConceptService.active_path
	var testing_bypass_backup := MetaProgressionService.testing_content_lock_bypass
	var selected_core_backup := GameSession.selected_core_id
	var selected_cursor_backup := GameSession.selected_cursor_id
	var election_progress_backup := {
		"support": SaveManager.candidate_support.duplicate(true),
		"elected": SaveManager.elected_candidate_ids.duplicate(),
		"decrees": SaveManager.candidate_decree_ids.duplicate(true),
	}
	MetaProgressionService.set_testing_content_lock_bypass(true)
	_check(ConceptService.active != null and ConceptService.active.id == &"demon_election_vertical_slice" and ConceptService.get_election_campaign() != null, "the configured GDD v0.10 election profile and campaign must load before gameplay services")
	var default_stage := ConceptService.get_default_stage()
	var default_reward := ConceptService.get_stage_reward()
	_check(default_stage != null and default_reward != null, "the concept profile must own its default stage and reward table")
	if default_stage == null or default_reward == null:
		await _restore_and_finish(original_concept_path, testing_bypass_backup, selected_core_backup, selected_cursor_backup, election_progress_backup)
		return
	_check(ConceptService.active.assets != null and ConceptService.active.assets.get_validation_errors().is_empty(), "the active concept must own a valid standalone asset catalog")
	_check(ConceptService.term(&"core") == "마왕 후보" and ConceptService.term(&"currency") == "선거 자금", "the default election concept must expose campaign terminology")
	var sound_assets: Array[AudioStream] = [
		ConceptService.audio(&"ui_click"),
		ConceptService.audio(&"level_up"),
		ConceptService.audio(&"boss_warning"),
		ConceptService.audio(&"boss_spawn"),
		ConceptService.audio(&"core_skill"),
		ConceptService.audio(&"hit_light"),
		ConceptService.audio(&"hit_heavy"),
		ConceptService.audio(&"core_hit"),
		ConceptService.audio(&"victory"),
		ConceptService.audio(&"defeat"),
	]
	_check(sound_assets.size() == 10 and sound_assets.all(func(stream: AudioStream) -> bool: return stream != null and stream.get_length() > 0.05), "all generated sound resources must load as non-empty audio streams")
	var emerald_texture := ConceptService.content_texture(&"cores", &"emerald")
	_check(emerald_texture != null and emerald_texture == ConceptService.content_texture(&"cores", &"emerald") and ConceptService.fallback_texture(&"projectile_plasma") != null, "concept graphics lookup must cache catalog textures and resolve required fallbacks")
	_check(ConceptService.texture(&"menu_background") != null and ConceptService.texture(&"battlefield_background") != null, "named presentation textures must resolve through the asset service boundary")
	var invalid_content_texture := ConceptService.content_texture(&"cores", &"../escape")
	_check(invalid_content_texture == ConceptService.fallback_texture(&"cores") and not ConceptService.get_missing_content_assets().is_empty(), "unsafe content ids must never form resource paths and must resolve to a tracked fallback")
	ConceptService.clear_runtime_asset_cache()
	var invalid_asset_catalog := ConceptService.active.assets.duplicate(true) as GameAssetCatalogData
	invalid_asset_catalog.graphics_root = "res://assets/../outside"
	invalid_asset_catalog.audio_ui_click = null
	invalid_asset_catalog.content_texture_overrides = {"cores/../../escape": ConceptService.fallback_texture(&"cores")}
	var invalid_asset_errors := "\n".join(invalid_asset_catalog.get_validation_errors())
	_check(invalid_asset_errors.contains("without parent traversal") and invalid_asset_errors.contains("ui_click") and invalid_asset_errors.contains("override key"), "asset catalog validation must reject unsafe roots, missing required roles, and malformed overrides before activation")
	var invalid_pack := ContentPackData.new()
	_check(not invalid_pack.is_playable() and invalid_pack.get_validation_errors().size() == 9, "an empty external content pack must report its id and all eight required catalogs")
	var valid_pack := ContentPackData.new()
	valid_pack.id = &"smoke_valid_pack"
	valid_pack.cores.assign(DataRegistry.cores)
	valid_pack.cursors.assign(DataRegistry.cursors)
	valid_pack.towers.assign(DataRegistry.towers)
	valid_pack.formations.assign(DataRegistry.formations)
	valid_pack.tower_branches.assign(DataRegistry.tower_branches)
	valid_pack.specialization_branches.assign(DataRegistry.specialization_branches)
	valid_pack.enemies.assign(DataRegistry.enemies + DataRegistry.faction_enemies)
	valid_pack.bosses.assign(DataRegistry.bosses)
	valid_pack.enemy_spawn_profiles.assign(DataRegistry.enemy_spawn_profiles)
	_check(valid_pack.is_playable(default_stage, default_reward), "the built-in catalogs must satisfy the complete stage, reward, and content-pack contract")
	_check(
		DataRegistry.get_core(&"missing_core") == null
		and DataRegistry.get_cursor(&"missing_cursor") == null
		and DataRegistry.get_tower(&"missing_tower") == null
		and DataRegistry.get_formation(&"missing_formation") == null
		and DataRegistry.get_enemy(&"missing_enemy") == null,
		"catalog lookups must expose unknown stable ids instead of silently substituting the first entry"
	)
	_check(
		DataRegistry.get_core_or_default(&"missing_core") == DataRegistry.cores[0]
		and DataRegistry.get_cursor_or_default(&"missing_cursor") == DataRegistry.cursors[0]
		and DataRegistry.get_tower_or_default(&"missing_tower") == DataRegistry.towers[0]
		and DataRegistry.get_formation_or_default(&"missing_formation") == DataRegistry.formations[0]
		and DataRegistry.get_enemy_or_default(&"missing_enemy") == DataRegistry.enemies[0],
		"catalog defaults must remain available only through explicitly named fallback APIs"
	)
	var expanded_boss_pack := valid_pack.duplicate(true) as ContentPackData
	var reserve_catalog_boss := expanded_boss_pack.bosses[0].duplicate(true) as EnemyData
	reserve_catalog_boss.id = &"reserve_catalog_boss"
	expanded_boss_pack.bosses.append(reserve_catalog_boss)
	var expanded_boss_reward := default_reward.duplicate(true) as StageRewardData
	expanded_boss_reward.boss_funds_by_id[reserve_catalog_boss.id] = 20
	_check(expanded_boss_pack.is_playable(default_stage, expanded_boss_reward), "a content pack may expose more bosses than the stage's four explicit default slots")
	var malformed_formation_pack := valid_pack.duplicate(true) as ContentPackData
	malformed_formation_pack.formations[0].cells[1].offset = malformed_formation_pack.formations[0].cells[0].offset
	_check("\n".join(malformed_formation_pack.get_validation_errors(default_stage, default_reward)).contains("duplicate cell coordinates"), "content validation must reject malformed block formation shapes")
	var missing_final_stage := default_stage.duplicate(true) as StageData
	missing_final_stage.final_boss_id = &"missing_final_boss"
	_check("\n".join(valid_pack.get_validation_errors(missing_final_stage, default_reward)).contains("missing final boss"), "content validation must reject a stage whose declared final boss is absent from the boss catalog")
	var custom_final_pack := valid_pack.duplicate(true) as ContentPackData
	var custom_final_boss := custom_final_pack.bosses.filter(func(boss: EnemyData) -> bool: return boss.id == &"final_boss")[0] as EnemyData
	custom_final_boss.id = &"omega_boss"
	var custom_final_stage := default_stage.duplicate(true) as StageData
	custom_final_stage.final_boss_id = &"omega_boss"
	custom_final_stage.default_boss_ids[custom_final_stage.default_boss_ids.size() - 1] = &"omega_boss"
	var custom_final_reward := default_reward.duplicate(true) as StageRewardData
	custom_final_reward.boss_funds_by_id.erase(&"final_boss")
	custom_final_reward.boss_funds_by_id[&"omega_boss"] = 50
	var final_boss_probe := GameController.new()
	final_boss_probe.stage_data = custom_final_stage
	final_boss_probe.boss_plan = CampaignStageResolver.build_fixed_plan(custom_final_stage, custom_final_pack.bosses)
	_check(custom_final_pack.is_playable(custom_final_stage, custom_final_reward) and final_boss_probe._is_final_boss(custom_final_boss), "a content pack must remain playable and finishable when its declared final boss uses a custom id")
	final_boss_probe.free()
	var mismatched_spawn_stage := default_stage.duplicate(true) as StageData
	mismatched_spawn_stage.spawn_table = [{"start": 0.0, "end": mismatched_spawn_stage.duration_seconds, "weights": {"missing_enemy": 1.0}, "groups": {}}]
	_check("\n".join(valid_pack.get_validation_errors(mismatched_spawn_stage, default_reward)).contains("missing enemy"), "content validation must reject spawn tables that reference enemies outside the active catalog")
	var invalid_concept := GameConceptData.new()
	invalid_concept.id = &"invalid_smoke_concept"
	_check(invalid_concept.get_validation_errors().size() == 4, "a concept profile without text, assets, default stage, and reward data must be rejected before activation")
	_check(ConceptService.active.get_validation_errors().is_empty(), "the active concept profile must satisfy its integrated playability contract")
	_check(ConceptService.load_profile("res://data/concepts/formation_defense.tres"), "the campaign-free formation-defense profile must remain available as an explicit alternate concept")
	_check(ConceptService.active.id == &"formation_defense" and ConceptService.get_election_campaign() == null and ConceptService.term(&"core") == "핵", "the explicit generic profile must remain independent from election presentation data")
	_check(ConceptService.load_profile("res://data/concepts/example_arcane_reskin.tres"), "an alternate concept profile must be loadable at runtime")
	_check(ConceptService.term(&"core") == "마력석" and ConceptService.term(&"tower") == "수호탑" and ConceptService.active.accent_color != Color("59dbae"), "switching concept profiles must replace terminology and palette without code changes")
	_check(ConceptService.load_profile(DEFAULT_CONCEPT_PATH), "the election vertical-slice profile must be loadable for setup UI verification")
	SaveManager.candidate_support["partason"] = 1000
	if "partason" not in SaveManager.elected_candidate_ids:
		SaveManager.elected_candidate_ids.append("partason")
	SaveManager.candidate_decree_ids["partason"] = "royal_barrier"
	var election_menu := (load("res://scenes/main/main_menu.tscn") as PackedScene).instantiate()
	add_child(election_menu)
	await get_tree().process_frame
	var election_core_option := election_menu.get_node("%CoreOption") as OptionButton
	var election_cursor_option := election_menu.get_node("%CursorOption") as OptionButton
	var election_candidate_choices := election_menu.get_node("%CandidateChoiceList") as HBoxContainer
	var election_retainer_choices := election_menu.get_node("%RetainerChoiceList") as HBoxContainer
	_check(
		(election_menu.get_node("%CampaignProfileSection") as Control).visible
		and (election_menu.get_node("%CampaignChoiceSection") as Control).visible
		and not (election_menu.get_node("%DescriptionLabel") as Control).visible
		and not election_core_option.visible
		and not election_cursor_option.visible
		and election_candidate_choices.get_child_count() == 5
		and election_retainer_choices.get_child_count() == 5
		and election_core_option.get_item_text(0).contains("파르태손")
		and election_cursor_option.get_item_text(0).contains("칸다")
		and (election_menu.get_node("%CandidatePortrait") as TextureRect).texture == ConceptService.content_texture(&"candidates", &"partason")
		and (election_menu.get_node("%RetainerPortrait") as TextureRect).texture == ConceptService.content_texture(&"retainers", &"kanda")
		and (election_menu.get_node("%CandidateEmblem") as TextureRect).texture == ConceptService.content_texture(&"emblems", &"partason_sword_shield"),
		"the election setup must replace generic loadout copy with candidate and retainer profile choices"
	)
	var decree_selector := election_menu.get_node("%DecreeOption") as OptionButton
	_check(not decree_selector.disabled and decree_selector.item_count == 3 and decree_selector.get_item_text(decree_selector.selected).contains("왕실 호위") and (election_menu.get_node("%CandidateStats") as Label).text.contains("통치"), "an elected candidate setup card must expose its three decrees, governance tier, and persisted selection")
	(election_candidate_choices.get_child(1) as Button).pressed.emit()
	(election_retainer_choices.get_child(1) as Button).pressed.emit()
	_check(
		(election_menu.get_node("%CandidateName") as Label).text.contains("지아느")
		and (election_menu.get_node("%RetainerName") as Label).text.contains("기븐")
		and (election_menu.get_node("%CandidateStats") as Label).text.contains("기본 조합")
		and (election_menu.get_node("%CandidateStats") as Label).text.contains("지지")
		and (election_menu.get_node("%CampaignRivalPreview") as Label).text.contains("출격 시 난입 순서 확정")
		and (election_menu.get_node("%CandidatePortrait") as TextureRect).texture == ConceptService.content_texture(&"candidates", &"jiane")
		and (election_menu.get_node("%RetainerPortrait") as TextureRect).texture == ConceptService.content_texture(&"retainers", &"given")
		and (election_menu.get_node("%CandidateEmblem") as TextureRect).texture == ConceptService.content_texture(&"emblems", &"jiane_heart"),
		"scrollable candidate and retainer cards, preferred pairing, and rival preview must react to setup selection"
	)
	GameSession.selected_core_id = &"emerald"
	GameSession.selected_cursor_id = &"iron"
	var election_plan := CampaignStageResolver.resolve(default_stage, DataRegistry.bosses, ConceptService.get_election_campaign(), &"emerald", &"iron", 8307)
	var election_identity := RunResultService.new()._campaign_identity(election_plan)
	_check(String(election_identity.get("candidate_id", "")) == "partason" and String(election_identity.get("retainer_id", "")) == "kanda" and (election_identity.get("rival_candidate_ids", []) as Array).size() == 4, "campaign results must carry stable candidate, retainer, and four rival ids into settlement and checkpoints")
	var election_level_panel := (load("res://scenes/ui/level_up_panel.tscn") as PackedScene).instantiate() as LevelUpPanel
	add_child(election_level_panel)
	var election_level_choices: Array[UpgradeData] = [
		UpgradeData.new().configure(&"global_upgrade", "왕가의 호령", "유세 지원대 전체 강화", &"global"),
		UpgradeData.new().configure(&"core_level", "연설 지속력", "후보 방어력 강화", &"emerald"),
		UpgradeData.new().configure(&"cursor_level", "심복 기동", "심복 이동속도 강화", &"iron"),
	]
	election_level_panel.show_choices(election_level_choices, 4, 2, 3)
	_check(
		election_level_panel.cards_revealing
		and LevelUpPanel.CARD_REVEAL_STAGGER > 0.0
		and election_level_panel.buttons.all(func(button: Button) -> bool: return button.disabled)
		and election_level_panel.buttons.all(func(button: Button) -> bool: return is_zero_approx(button.modulate.a)),
		"level-up cards must begin a staggered reveal with every card input locked"
	)
	election_level_panel.complete_card_reveal()
	_check(
		(election_level_panel.get_node("%Title") as Label).text.contains("파르태손 8세 공약 선택")
		and (election_level_panel.get_node("%Hint") as Label).text.contains("유세 공약")
		and (election_level_panel.get_node("%RerollButton") as Button).text.contains("공약 교체")
		and not election_level_panel.cards_revealing
		and election_level_panel.buttons.all(func(button: Button) -> bool: return not button.disabled),
		"the election level-up panel must use candidate-aware campaign title, guidance, and reroll copy"
	)
	var election_boss_probe := GameController.new()
	var election_boss_presentation: Dictionary = election_boss_probe._boss_presentation(DataRegistry.bosses[0])
	_check(
		String(election_boss_presentation.name).contains("파르태손 8세")
		and String(election_boss_presentation.name).contains("마왕 정통파"),
		"the election boss HUD presentation must resolve the candidate and faction instead of the generic boss name"
	)
	election_boss_probe.free()
	election_level_panel.queue_free()
	election_menu.queue_free()
	_check(ConceptService.load_profile(original_concept_path), "the default concept profile must be restorable after a runtime swap")
	_check(AudioManager.voices.size() == AudioManager.VOICE_COUNT, "the audio manager must initialize its bounded playback pool")
	RunRng.seed_run(1847)
	var expected_gameplay_roll := RunRng.roll()
	RunRng.seed_run(1847)
	AudioManager.play_ui()
	var cosmetic_rng_sample := CombatEffect.new()
	cosmetic_rng_sample._prepare_sparks(8)
	cosmetic_rng_sample.free()
	var gameplay_roll_after_audio := RunRng.roll()
	_check(is_equal_approx(gameplay_roll_after_audio, expected_gameplay_roll), "cosmetic audio and combat effects must not consume the gameplay random stream")
	_check(AudioManager.voices.all(func(player: AudioStreamPlayer) -> bool: return not player.playing), "muting sound must suppress and stop active playback voices")
	await _restore_and_finish(original_concept_path, testing_bypass_backup, selected_core_backup, selected_cursor_backup, election_progress_backup)

func _restore_and_finish(
	original_concept_path: String,
	testing_bypass_backup: bool,
	selected_core_backup: StringName,
	selected_cursor_backup: StringName,
	election_progress_backup: Dictionary
) -> void:
	SaveManager.candidate_support = election_progress_backup.support
	SaveManager.elected_candidate_ids.assign(election_progress_backup.elected)
	SaveManager.candidate_decree_ids = election_progress_backup.decrees
	GameSession.selected_core_id = selected_core_backup
	GameSession.selected_cursor_id = selected_cursor_backup
	MetaProgressionService.set_testing_content_lock_bypass(testing_bypass_backup)
	if ConceptService.active_path != original_concept_path and not ConceptService.load_profile(original_concept_path):
		failures.append("the original concept profile must be restored during isolated smoke cleanup")
	await get_tree().process_frame
	AudioManager.release_voice_pool()
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("CONTENT ELECTION SMOKE PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
