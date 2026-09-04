class_name ImplementationFreezeContractTest
extends RefCounted

const REQUIRED_PATHS: Array[String] = [
	"res://godot_formation_defense_gdd_v0_10.md",
	"res://godot_formation_defense_gdd_v0_13.md",
	"res://godot_formation_defense_gdd_v0_14.md",
	"res://godot_formation_defense_gdd_v0_15.md",
	"res://IMPLEMENTATION_STATUS.md",
	"res://docs/GDD_V0_10_MODIFICATION_PLAN.md",
	"res://docs/GDD_V0_13_IMPROVEMENT_PLAN.md",
	"res://docs/GDD_V0_14_IMPROVEMENT_PLAN.md",
	"res://docs/GDD_V0_15_IMPROVEMENT_PLAN.md",
	"res://docs/RESOURCE_LIST.md",
	"res://docs/STATUS_EFFECT_VISUAL_REFRESH_2026-08-31.md",
	"res://data/concepts/demon_election_vertical_slice.tres",
	"res://data/concepts/demon_election_campaign_v0_8.tres",
	"res://data/concepts/demon_election_assets.tres",
	"res://scripts/progression/loadout_upgrade_application_service.gd",
	"res://scripts/progression/status_source_registry.gd",
	"res://scripts/progression/formation_placement_service.gd",
	"res://scripts/progression/formation_offer_builder.gd",
	"res://scripts/progression/upgrade_offer_service.gd",
	"res://scripts/effects/enemy_status_effect_renderer.gd",
	"res://scripts/battlefield/enemy_spawn_director.gd",
	"res://scripts/battlefield/spawn_packet_composer.gd",
	"res://scripts/game/run_outcome_summary.gd",
	"res://scripts/meta/first_five_run_economy_audit.gd",
	"res://resources/spawn_phase_data.gd",
	"res://resources/spawn_packet_data.gd",
	"res://resources/enemy_spawn_profile_data.gd",
	"res://resources/faction_prelude_data.gd",
	"res://resources/faction_spawn_packet_data.gd",
	"res://resources/enemy_catalog_v015.gd",
	"res://scripts/battlefield/enemy_spawn_context.gd",
	"res://scripts/battlefield/faction_prelude_resolver.gd",
	"res://scripts/battlefield/faction_prelude_budget_ledger.gd",
	"res://scripts/battlefield/faction_prelude_packet_composer.gd",
	"res://tests/contracts/spawn_composition_contract_test.gd",
	"res://tests/contracts/run_outcome_summary_contract_test.gd",
	"res://tests/contracts/first_five_run_economy_contract_test.gd",
	"res://tests/contracts/balance_audit_summary_contract_test.gd",
	"res://tests/contracts/enemy_status_visual_contract_test.gd",
	"res://tests/contracts/enemy_runtime_state_contract_test.gd",
	"res://tests/contracts/catalog_growth_runtime_contract_test.gd",
	"res://tests/contracts/v014_formation_catalog_contract_test.gd",
	"res://tests/contracts/v015_enemy_spawn_foundation_contract_test.gd",
	"res://tests/contracts/v015_faction_enemy_contract_test.gd",
	"res://tests/contracts/v015_faction_prelude_composition_contract_test.gd",
	"res://tests/contracts/v016_enemy_observability_contract_test.gd",
	"res://tests/contracts/v016_balance_audit_policy_contract_test.gd",
	"res://tests/contracts/v016_balance_convergence_metrics_contract_test.gd",
	"res://tests/contracts/v019_m0_baseline_contract_test.gd",
	"res://tests/contracts/v019_m1_meta_unlock_contract_test.gd",
	"res://tests/contracts/v019_m2_tutorial_contract_test.gd",
	"res://tests/contracts/v019_m3_hub_codex_contract_test.gd",
	"res://tests/contracts/v019_m4_defense_stat_contract_test.gd",
	"res://tests/contracts/v019_m5_overgrowth_contract_test.gd",
	"res://tests/contracts/v019_m6_artifact_foundation_contract_test.gd",
	"res://tests/contracts/v019_m7_artifact_offer_ui_contract_test.gd",
	"res://tests/contracts/v019_m8_artifact_metrics_audit_contract_test.gd",
	"res://tests/contracts/v019_character_style_refresh_contract_test.gd",
	"res://data/art/character_style_refresh_manifest_v1.json",
	"res://tests/character_style_refresh_review.tscn",
	"res://tests/character_style_refresh_review_runner.gd",
	"res://tests/visual_reviews/character_style_refresh_pilots.png",
	"res://tests/character_style_refresh_defender_review.tscn",
	"res://tests/character_style_refresh_defender_review_runner.gd",
	"res://tests/visual_reviews/character_style_refresh_defenders_a.png",
	"res://tests/visual_reviews/character_style_refresh_defenders_b.png",
	"res://tests/character_style_refresh_defender_icon_review.tscn",
	"res://tests/character_style_refresh_defender_icon_review_runner.gd",
	"res://tests/visual_reviews/character_style_refresh_defender_icons_a.png",
	"res://tests/visual_reviews/character_style_refresh_defender_icons_b.png",
	"res://tests/status_effect_visual_review.tscn",
	"res://tests/status_effect_visual_review_runner.gd",
	"res://tests/visual_reviews/status_effect_visual_review.png",
	"res://tests/visual_reviews/status_effect_density_review.png",
	"res://tests/character_style_refresh_character_pair_review.tscn",
	"res://tests/character_style_refresh_character_pair_review_runner.gd",
	"res://tests/visual_reviews/character_style_refresh_character_pairs_a.png",
	"res://tests/visual_reviews/character_style_refresh_character_pairs_b.png",
	"res://tests/character_style_refresh_m3_defender_review.tscn",
	"res://tests/character_style_refresh_m3_defender_review_runner.gd",
	"res://tests/visual_reviews/character_style_refresh_m3_defenders.png",
	"res://tests/character_style_refresh_m3_kanda_review.tscn",
	"res://tests/character_style_refresh_m3_kanda_review_runner.gd",
	"res://tests/visual_reviews/character_style_refresh_m3_kanda.png",
	"res://tests/character_style_refresh_m3_candidate_review.tscn",
	"res://tests/character_style_refresh_m3_candidate_review_runner.gd",
	"res://tests/visual_reviews/character_style_refresh_m3_candidates_a.png",
	"res://tests/visual_reviews/character_style_refresh_m3_candidates_b.png",
	"res://tests/character_style_refresh_m3_guard_review.tscn",
	"res://tests/character_style_refresh_m3_guard_review_runner.gd",
	"res://tests/visual_reviews/character_style_refresh_m3_guards_a.png",
	"res://tests/visual_reviews/character_style_refresh_m3_guards_b.png",
	"res://tests/character_style_refresh_m4_intrusion_review.tscn",
	"res://tests/character_style_refresh_m4_intrusion_review_runner.gd",
	"res://tests/visual_reviews/character_style_refresh_m4_intrusions_a.png",
	"res://tests/visual_reviews/character_style_refresh_m4_intrusions_b.png",
	"res://tests/visual_reviews/character_style_refresh_m4_intrusions_c.png",
	"res://tests/visual_reviews/character_style_refresh_m4_intrusions_d.png",
	"res://assets/graphics/emblems/v019/partason_sword_shield.svg",
	"res://assets/graphics/emblems/v019/jiane_heart.svg",
	"res://assets/graphics/emblems/v019/kasuha_tentacle_eye.svg",
	"res://assets/graphics/emblems/v019/irelai_skull_aura.svg",
	"res://assets/graphics/emblems/v019/judaginda_scythe_blood.svg",
	"res://scripts/ui/faction_marker_icon.gd",
	"res://tests/character_style_refresh_m5_faction_review.tscn",
	"res://tests/character_style_refresh_m5_faction_review_runner.gd",
	"res://tests/visual_reviews/character_style_refresh_m5_faction_tokens.png",
	"res://data/art/character_style_refresh_m6_review_catalog.json",
	"res://tests/character_style_refresh_m6_review_catalog.gd",
	"res://tests/character_style_refresh_m6_catalog_review.tscn",
	"res://tests/character_style_refresh_m6_catalog_review_runner.gd",
	"res://tests/character_style_refresh_m6_review_audit.tscn",
	"res://tests/character_style_refresh_m6_review_audit_runner.gd",
	"res://tests/character_style_refresh_m6_normalize.tscn",
	"res://tests/character_style_refresh_m6_normalize_runner.gd",
	"res://tests/visual_reviews/character_style_refresh_m6_catalog_defenders.png",
	"res://tests/visual_reviews/character_style_refresh_m6_catalog_candidates.png",
	"res://tests/visual_reviews/character_style_refresh_m6_catalog_retainers.png",
	"res://tests/visual_reviews/character_style_refresh_m6_catalog_guards.png",
	"res://export_presets.cfg",
	"res://tools/android_character_m7_validation.ps1",
	"res://docs/CHARACTER_RESOURCE_M7_ANDROID_VALIDATION_2026-08-29.md",
	"res://resources/tutorial_scenario_data.gd",
	"res://resources/codex_rule_entry_data.gd",
	"res://resources/codex_rule_catalog_data.gd",
	"res://data/meta/codex_rules_v0_17.tres",
	"res://resources/defense_stat_axis_data.gd",
	"res://resources/defense_stat_mapping_data.gd",
	"res://resources/defense_stat_catalog_data.gd",
	"res://scripts/progression/defense_stat_resolver.gd",
	"res://data/meta/defense_stat_catalog_v0_19.tres",
	"res://resources/overgrowth_option_data.gd",
	"res://resources/overgrowth_catalog_data.gd",
	"res://scripts/progression/overgrowth_service.gd",
	"res://data/meta/overgrowth_catalog_v0_19.tres",
	"res://resources/artifact_effect_data.gd",
	"res://resources/artifact_data.gd",
	"res://resources/artifact_catalog_data.gd",
	"res://scripts/progression/artifact_inventory_state.gd",
	"res://scripts/progression/artifact_eligibility_service.gd",
	"res://scripts/progression/artifact_effect_resolver.gd",
	"res://scripts/progression/artifact_offer_service.gd",
	"res://data/meta/artifact_catalog_v0_19.tres",
	"res://scripts/ui/artifact_resolution_panel.gd",
	"res://scenes/ui/artifact_resolution_panel.tscn",
	"res://scripts/tutorial/tutorial_director.gd",
	"res://scripts/ui/tutorial_action_guide.gd",
	"res://data/tutorial/tutorial_v0_17.tres",
	"res://data/tutorial/tutorial_60s_stage.tres",
	"res://scenes/tutorial/tutorial_game.tscn",
	"res://tests/audit/balance_audit_build_policy.gd",
	"res://tests/audit/balance_audit_skill_policy.gd",
	"res://tests/audit/balance_audit_movement_policy.gd",
	"res://tests/audit/balance_audit_active_policy.gd",
	"res://tests/audit/balance_audit_placement_policy.gd",
	"res://scenes/main/main_menu.tscn",
	"res://scenes/game/game.tscn",
	"res://tests/smoke_test.tscn",
	"res://tests/content_election_runtime_smoke.tscn",
	"res://tests/content_election_runtime_smoke_runner.gd",
	"res://tests/meta_progression_persistence_smoke.tscn",
	"res://tests/meta_progression_persistence_smoke_runner.gd",
	"res://tests/preparation_runtime_smoke.tscn",
	"res://tests/preparation_runtime_smoke_runner.gd",
	"res://tests/tutorial_runtime_smoke_test.tscn",
	"res://tools/run_headless_quality_gate.ps1",
	"res://tests/ui_snapshot.tscn",
	"res://tests/balance_audit.tscn",
	"res://tests/economy_audit.tscn",
]

const RETIRED_PATHS: Array[String] = [
	"res://scripts/progression/legacy_column_fixture_catalog.gd",
	"res://scripts/progression/legacy_column_snapshot_adapter.gd",
]

const REQUIRED_SMOKE_CONTRACT_CALLS: Array[String] = [
	"AssetCoverageContractTest.run()",
	"AudioPresentationContractTest.run()",
	"CombatMotionProfileContractTest.run()",
	"RetainerMotionProfileContractTest.run()",
	"CombatCharacterArtContractTest.run()",
	"V019CharacterStyleRefreshContractTest.run()",
	"ElectionCampaignContractTest.run()",
	"StageRuntimeBossPlanContractTest.run()",
	"ElectionCombatMechanicsContractTest.run(self)",
	"NecromancyReactivationContractTest.run(self)",
	"ComboVanguardContractTest.run(self)",
	"CandidateProgressionContractTest.run()",
	"CombatModifierResolverContractTest.run()",
	"SummonServiceContractTest.run()",
	"PerformanceBudgetContractTest.run()",
	"FormationBoardContractTest.run()",
	"FormationBoardContractTest.run_runtime(self)",
	"BossControlResistanceContractTest.run()",
	"ModularizationContractTest.run()",
	"FormationOfferBuilderContractTest.run()",
	"V013MigrationContractTest.run()",
	"V014FormationCatalogContractTest.run()",
	"V015EnemySpawnFoundationContractTest.run()",
	"V015FactionEnemyContractTest.run(self)",
	"V015FactionPreludeCompositionContractTest.run()",
	"V016EnemyObservabilityContractTest.run()",
	"V016BalanceAuditPolicyContractTest.run()",
	"V016BalanceConvergenceMetricsContractTest.run()",
	"V019M0BaselineContractTest.run()",
	"V019M1MetaUnlockContractTest.run()",
	"V019M2TutorialContractTest.run()",
	"V019M3HubCodexContractTest.run()",
	"V019M4DefenseStatContractTest.run(self)",
	"V019M5OvergrowthContractTest.run()",
	"V019M6ArtifactFoundationContractTest.run()",
	"V019M7ArtifactOfferUiContractTest.run(self)",
	"V019M8ArtifactMetricsAuditContractTest.run()",
	"UiUxFoundationContractTest.run(self)",
	"UiUxM2ChoiceCardContractTest.run(self)",
	"UiUxM3CombatHudContractTest.run(self)",
	"UiUxM4UnitInfoContractTest.run(self)",
	"UiUxM5MetaPagesContractTest.run(self)",
	"UiUxM6ModalFlowsContractTest.run(self)",
	"UiUxM7ResponsiveAccessibilityContractTest.run(self)",
	"RetainerProgressionContractTest.run()",
	"CommonStatusV013ContractTest.run()",
	"EnemyStatusVisualContractTest.run(self)",
	"EnemyRuntimeStateContractTest.run(self)",
	"CatalogGrowthRuntimeContractTest.run(self)",
	"SpawnDirectorContractTest.run()",
	"SpawnCompositionContractTest.run()",
	"RunOutcomeSummaryContractTest.run()",
	"FirstFiveRunEconomyContractTest.run()",
	"BalanceAuditSummaryContractTest.run()",
	"ImplementationFreezeContractTest.run()",
]

const GUARD_CELL_COUNTS := {
	&"partason": 4,
	&"jiane": 4,
	&"kasuha": 4,
	&"irelai": 6,
	&"judaginda": 4,
}

static func run() -> Array[String]:
	var failures: Array[String] = []
	for path in REQUIRED_PATHS:
		_expect(FileAccess.file_exists(path), "implementation freeze requires '%s'" % path, failures)
	for path in RETIRED_PATHS:
		_expect(not FileAccess.file_exists(path), "retired implementation path must stay absent: '%s'" % path, failures)

	var smoke_source := FileAccess.get_file_as_string("res://tests/smoke_test_runner.gd")
	for call in REQUIRED_SMOKE_CONTRACT_CALLS:
		_expect(smoke_source.contains(call), "the smoke entrypoint must invoke %s" % call, failures)
	var meta_persistence_source := FileAccess.get_file_as_string("res://tests/meta_progression_persistence_smoke_runner.gd")
	var content_election_source := FileAccess.get_file_as_string("res://tests/content_election_runtime_smoke_runner.gd")
	var preparation_runtime_source := FileAccess.get_file_as_string("res://tests/preparation_runtime_smoke_runner.gd")
	var quality_gate_source := FileAccess.get_file_as_string("res://tools/run_headless_quality_gate.ps1")
	_expect(not smoke_source.contains("example_arcane_reskin.tres") and content_election_source.contains("example_arcane_reskin.tres"), "concept swaps and election UI fixtures must run only in the isolated content-election smoke process", failures)
	_expect(content_election_source.contains("CONTENT ELECTION SMOKE PASS") and quality_gate_source.contains("res://tests/content_election_runtime_smoke.tscn") and quality_gate_source.contains("CONTENT ELECTION SMOKE PASS"), "the strict quality gate must require the isolated content-election scene and exact success marker", failures)
	_expect(not smoke_source.contains("smoke_meta_save.json") and meta_persistence_source.contains("smoke_meta_save.json"), "meta-save and checkpoint fixtures must run only in the isolated persistence smoke process", failures)
	_expect(meta_persistence_source.contains("META PERSISTENCE SMOKE PASS") and quality_gate_source.contains("res://tests/meta_progression_persistence_smoke.tscn") and quality_gate_source.contains("META PERSISTENCE SMOKE PASS"), "the strict quality gate must require the isolated meta-persistence scene and exact success marker", failures)
	_expect(not smoke_source.contains("formation-result-contract") and preparation_runtime_source.contains("formation-result-contract") and preparation_runtime_source.contains("PREPARATION RUNTIME SMOKE PASS"), "guard preparation, formation abandonment, and result-board fixtures must run only in the isolated preparation smoke process", failures)
	_expect(quality_gate_source.contains("res://tests/preparation_runtime_smoke.tscn") and quality_gate_source.contains("PREPARATION RUNTIME SMOKE PASS"), "the strict quality gate must require the isolated preparation scene and exact success marker", failures)
	_expect(quality_gate_source.contains("StageTimeoutSeconds") and quality_gate_source.contains("Invoke-BoundedProcess") and quality_gate_source.contains('violations.Add("timeout")') and quality_gate_source.contains("bounded-process timeout probe"), "the strict quality gate must bound every child process and self-test explicit timeout classification and termination", failures)
	_expect(quality_gate_source.contains('ExpectedFullStageSignature = "parse|content|meta|preparation|smoke|tutorial|verbose"') and quality_gate_source.contains("ExpectedFullStageArgumentTemplates") and quality_gate_source.contains("Get-QualityGateStages") and quality_gate_source.contains("Test-StageConfiguration") and quality_gate_source.contains("removing --verbose must fail") and quality_gate_source.contains("replacing the tutorial scene must fail") and quality_gate_source.contains("exact seven-stage manifest and arguments"), "the strict quality gate must freeze and mutation-test the exact ordered seven-stage manifest, arguments, and scene routes", failures)
	var modularization_source := FileAccess.get_file_as_string("res://tests/contracts/modularization_contract_test.gd")
	_expect(modularization_source.contains("class ContractContext") and modularization_source.contains("const DOMAIN_ORDER") and modularization_source.contains("static func run_domain") and modularization_source.contains("_run_domain_contracts") and not modularization_source.contains("contracts(context: Dictionary"), "the modularization contract must retain typed, explicitly dispatchable domain execution boundaries", failures)
	_expect(modularization_source.contains("_run_spirit_and_candidate_policy_contracts") and modularization_source.contains("_run_attack_execution_contracts") and modularization_source.contains("_run_skeleton_and_branch_contracts") and modularization_source.contains("_run_tactics_cursor_and_counter_contracts") and modularization_source.contains("_run_core_execution_and_presentation_contracts") and modularization_source.contains("_run_phase_offer_and_startup_contracts") and modularization_source.contains("_run_shutdown_and_cleanup_contracts"), "the modularization contract must retain every explicit domain boundary instead of regrowing a single monolithic run function", failures)
	for domain_failure in ModularizationContractTest.run_domain(&"phase_offer_and_startup"):
		failures.append("independent modularization domain: %s" % domain_failure)
	_expect(not smoke_source.contains("GDD v0.9") and not smoke_source.contains("v0.9 block"), "the current smoke contract must use v0.10 terminology", failures)
	var audit_source := FileAccess.get_file_as_string("res://tests/balance_audit_runner.gd")
	_expect(not audit_source.contains("v0.9 block"), "the current balance audit must use v0.10 terminology", failures)
	var audit_matrix_source := FileAccess.get_file_as_string("res://tests/balance_audit_matrix_runner.gd")
	_expect(audit_source.contains("AUDIT_REPORT_SCHEMA_VERSION := 20") and audit_matrix_source.contains("AUDIT_REPORT_SCHEMA_VERSION := 20"), "current audit runners must reject checkpoints that predate elite artifact draft timelines", failures)
	_expect(audit_source.contains("--speed=") and audit_source.contains("func _physics_process") and audit_matrix_source.contains("--speeds=") and audit_matrix_source.contains("speed_equivalence"), "the balance audit must preserve its 1x/2x/3x fixed-tick equivalence gate", failures)
	_expect(audit_source.contains("--build-policy=") and audit_source.contains("--skill-policy=") and audit_source.contains("--bonus-mode=") and audit_matrix_source.contains("--build-policies=") and audit_matrix_source.contains("--skill-policies=") and audit_matrix_source.contains("--bonus-modes="), "the v0.16 balance audit must expose independent build, skill, and bonus axes", failures)
	var game_controller_source := FileAccess.get_file_as_string("res://scripts/game/game_controller.gd")
	_expect(game_controller_source.contains("BASE_PHYSICS_TICKS_PER_SECOND := 60") and game_controller_source.contains("Engine.physics_ticks_per_second") and game_controller_source.contains("func _physics_process"), "the runtime must preserve a 60 game-tick simulation step at every supported speed", failures)

	_expect(DataRegistry.cores.size() == 5, "the frozen v0.10 catalog must contain five candidate cores", failures)
	_expect(DataRegistry.cursors.size() == 5, "the frozen v0.10 catalog must contain five retainers", failures)
	_expect(DataRegistry.towers.size() == 15 and DataRegistry.NORMAL_DEFENDER_IDS.size() == 9, "the frozen catalog must contain nine normal defenders and six candidate-exclusive guard unit types", failures)
	_expect(DataRegistry.formations.size() == 55, "the v0.13 registry must contain 49 normal, five candidate guard, and one hidden reinforcement formation", failures)
	_expect(DataRegistry.tower_branches.size() == 27, "the frozen v0.10 catalog must contain three specialization branches for each normal defender", failures)

	var campaign := ConceptService.get_election_campaign()
	_expect(campaign != null, "the frozen v0.10 profile must expose its election campaign", failures)
	if campaign != null:
		_expect(campaign.candidates.size() == 5 and campaign.retainers.size() == 5 and campaign.factions.size() == 5, "the frozen v0.10 campaign must contain five candidates, retainers, and factions", failures)
		for candidate in campaign.candidates:
			if candidate == null:
				failures.append("the frozen v0.10 campaign must not contain a null candidate")
				continue
			_expect(candidate.growth_data != null and candidate.growth_data.branch_upgrades.size() == 3, "candidate '%s' must retain fixed-branch-fixed growth with three branches" % candidate.id, failures)
			_expect(candidate.guard_growth_data != null and candidate.guard_growth_data.specializations.size() == 3, "candidate '%s' must retain three guard specializations" % candidate.id, failures)
			if candidate.guard_growth_data == null:
				continue
			var guard := DataRegistry.get_formation(candidate.guard_growth_data.formation_id)
			var expected_cells := int(GUARD_CELL_COUNTS.get(candidate.id, -1))
			_expect(guard != null and guard.is_guard and guard.get_tower_count() == expected_cells, "candidate '%s' guard must retain its frozen %d-cell formation" % [candidate.id, expected_cells], failures)
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
