class_name GameController
extends Node2D

const GAME_SPEEDS: Array[float] = [1.0, 2.0, 3.0]
const BASE_PHYSICS_TICKS_PER_SECOND := 60
const LEVEL_UP_REROLL_LIMIT: int = 3
const SPLITTER_CHILD_ENEMY_ID: StringName = &"civilian_slime"
const BOSS_SUMMON_ENEMY_IDS: Array[StringName] = [&"civilian_slime", &"goblin_raider", &"skeleton_raider", &"orc_shield"]

@export var stage_data: StageData
@export var enemy_scene: PackedScene

@onready var battlefield: Battlefield = $Battlefield
@onready var audience_stage: AudienceReactionStage = $AudienceStage
@onready var range_overlay: CombatRangeOverlay = $RangeOverlay
@onready var core: DefenseCore = $Core
@onready var target_cursor: TargetCursor = $TargetCursor
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var enemy_container: Node2D = $Enemies
@onready var summon_container: Node2D = $Summons
@onready var experience_rewards: ExperienceRewardService = $Pickups/ExperienceRewards
@onready var column_container: Node2D = $TowerColumns
@onready var effect_container: Node2D = $Effects
@onready var screen_effects = $ScreenEffects
@onready var loadout: LoadoutManager = $LoadoutManager
@onready var experience: ExperienceManager = $ExperienceManager
@onready var metrics: RunMetrics = $RunMetrics
@onready var hud: GameHUD = $UI/HUD
@onready var unit_info_popover: UnitInfoPopover = $UI/UnitInfoPopover
@onready var level_up_panel: LevelUpPanel = $UI/LevelUpPanel
@onready var artifact_resolution_panel: ArtifactResolutionPanel = $UI/ArtifactResolutionPanel
@onready var pause_menu: PauseMenu = $UI/PauseMenu

var game_finished: bool = false
var testing_random_seed: int = 1847
var reward_queue := RunRewardQueue.new()
var reward_selection_coordinator := RewardSelectionCoordinator.new()
var selecting_upgrade: bool:
	get: return reward_queue.selection_active
	set(value): reward_queue.selection_active = value
var pending_level_ups: int:
	get: return reward_queue.pending_level_ups
	set(value): reward_queue.pending_level_ups = value
var pending_reward_levels: Array[int]:
	get: return reward_queue.reward_levels
	set(value): reward_queue.reward_levels = value
var pending_candidate_branch_rewards: int:
	get: return reward_queue.pending_candidate_branches
	set(value): reward_queue.pending_candidate_branches = value
var candidate_reward_active: bool:
	get: return reward_queue.candidate_branch_active
	set(value): reward_queue.candidate_branch_active = value
var kill_count: int = 0
var boss_kill_count: int = 0
var tower_damage: Dictionary = {}
var enemy_lifecycle_controller := EnemyLifecycleController.new()
var current_boss: Enemy:
	get: return enemy_lifecycle_controller.current_boss
	set(value): enemy_lifecycle_controller.current_boss = value
var active_bosses: Array[Enemy]:
	get: return enemy_lifecycle_controller.active_bosses
	set(value): enemy_lifecycle_controller.active_bosses = value
var final_boss_reward_pending: bool = false
var warning_spawn_ratio: float = -1.0
var testing_mode: bool = false
var phase_coordinator := GamePhaseCoordinator.new()
var run_pause_coordinator := RunPauseCoordinator.new()
var game_phase: GameTypes.GamePhase:
	get: return phase_coordinator.current_phase
	set(value): phase_coordinator.current_phase = value
var pause_menu_open: bool:
	get: return phase_coordinator.pause_open
	set(value): phase_coordinator.pause_open = value
var phase_before_pause: GameTypes.GamePhase:
	get: return phase_coordinator.phase_before_pause
	set(value): phase_coordinator.phase_before_pause = value
var game_speed_index: int = 0
var cursor_attack_count: int = 0
var core_attack_count: int = 0
var previous_cursor_position := Vector2.ZERO
var rear_overcharge_remaining: float = 0.0
var specialization_refresh_accumulator: float = 0.0
var performance_sample_accumulator: float = 0.0
var audience_threat_sample_accumulator: float = 0.0
var cursor_trail_cooldown: float = 0.0
var cursor_trail_distance_accumulator: float = 0.0
var targeting_service := TargetingService.new()
var judgment_service := JudgmentService.new()
var combo_attack_service := ComboAttackService.new()
var tower_status_service := TowerStatusApplicationService.new()
var combat_presentation_service := CombatPresentationService.new()
var boss_presentation_service := BossPresentationService.new()
var candidate_core_skill_policy := CandidateCoreSkillPolicy.new()
var candidate_core_attack_policy := CandidateCoreAttackPolicy.new()
var tower_attack_dispatch_policy := TowerAttackDispatchPolicy.new()
var unique_field_attack_execution_service := UniqueFieldAttackExecutionService.new()
var chain_network_attack_execution_service := ChainNetworkAttackExecutionService.new()
var precision_attack_execution_service := PrecisionAttackExecutionService.new()
var control_attack_execution_service := ControlAttackExecutionService.new()
var pierce_attack_execution_service := PierceAttackExecutionService.new()
var projectile_attack_execution_service := ProjectileAttackExecutionService.new()
var skeleton_area_followup_service := SkeletonAreaFollowupService.new()
var skeleton_fire_zone_service := SkeletonFireZoneService.new()
var skeleton_bone_shard_service := SkeletonBoneShardService.new()
var tower_branch_hit_execution_service := TowerBranchHitExecutionService.new()
var goblin_tactics_service := GoblinTacticsService.new()
var cursor_attack_execution_service := CursorAttackExecutionService.new()
var core_attack_execution_service := CoreAttackExecutionService.new()
var core_hit_execution_service := CoreHitExecutionService.new()
var core_skill_execution_service := CoreSkillExecutionService.new()
var candidate_charm_echo_service := CandidateCharmEchoService.new()
var candidate_death_wave_launch_service := CandidateDeathWaveLaunchService.new()
var candidate_death_wave_runtime_service := CandidateDeathWaveRuntimeService.new()
var candidate_necromancy_effect_service := CandidateNecromancyEffectService.new()
var spirit_attack_execution_service := SpiritAttackExecutionService.new()
var cursor_hit_effect_service := CursorHitEffectService.new()
var enemy_special_action_execution_service := EnemySpecialActionExecutionService.new()
var upgrade_selection_router := UpgradeSelectionRouter.new()
var artifact_reward_resolution_service := ArtifactRewardResolutionService.new()
var spatial_index := EnemySpatialIndex.new()
var guard_ability_controller := GuardAbilityController.new()
var kasuha_guard_controller := KasuhaGuardController.new()
var irelai_guard_controller := IrelaiGuardController.new()
var judaginda_guard_controller := JudagindaGuardController.new()
var summon_service: SummonService
var necromancy_controller: NecromancyController
var death_wave_controller: DeathWaveController
var candidate_abyss_controller: CandidateAbyssController
var retainer_reactivation_registry := RetainerReactivationRegistry.new()
var retainer_reactivation_components: Dictionary:
	get: return retainer_reactivation_registry.components
	set(value): retainer_reactivation_registry.components = value
var active_retainer_profile: RetainerProfileData
var retainer_combat_controller: RetainerCombatController
var retainer_reconstruction_component: RetainerReconstructionComponent
var vanguard_squad_component: VanguardSquadComponent
var run_result_service := RunResultService.new()
var run_startup_service := RunStartupService.new()
var run_shutdown_service := RunShutdownService.new()
var run_signal_binding_service := RunSignalBindingService.new()
var candidate_mechanics_factory := CandidateMechanicsFactory.new()
var enemy_defeat_policy := EnemyDefeatPolicy.new()
var enemy_death_effect_service := EnemyDeathEffectService.new()
var regular_core_breach_service := RegularCoreBreachService.new()
var core_counterattack_service := CoreCounterattackService.new()
var vanguard_reaper_execution_service := VanguardReaperExecutionService.new()
var input_policy := GameInputPolicy.new()
var unit_info_presenter := UnitInfoPresenter.new()
var current_run_id: String = ""
var level_up_rerolls_remaining: int = LEVEL_UP_REROLL_LIMIT
var boss_plan: StageRuntimeBossPlan
var preparation_panel: PreparationPanel
## 은퇴한 열 기반 회귀 픽스처가 꼭 필요한 테스트만 명시적으로 켭니다.
## 기본 테스트와 실제 런은 모두 현재 4×6 블록 보드를 사용합니다.
var block_board_active: bool = true
var pending_block_formation_choice: UpgradeData
var pending_artifact_choice: UpgradeData:
	get: return artifact_reward_resolution_service.pending_choice
	set(value): artifact_reward_resolution_service.pending_choice = value
var pending_block_placement_started_msec: int = 0
var abyss_sacrifice_controller := AbyssSacrificeController.new()
var abyss_summon_attack_service := AbyssSummonAttackService.new()
var candidate_abyss_swarm_service := CandidateAbyssSwarmService.new()
var abyss_sacrifice_stacks: Dictionary:
	get: return abyss_sacrifice_controller.sacrifice_stacks
	set(value): abyss_sacrifice_controller.sacrifice_stacks = value
var active_abyss_summons: Dictionary:
	get: return abyss_sacrifice_controller.active_summons
	set(value): abyss_sacrifice_controller.active_summons = value
var skeleton_fire_zone_serial: int = 0
var candidate_charm_stage_controller := CandidateCharmStageController.new()
var candidate_charm_stage_remaining: float:
	get: return candidate_charm_stage_controller.remaining
	set(value): candidate_charm_stage_controller.remaining = value
var candidate_charm_stage_tick: float:
	get: return candidate_charm_stage_controller.tick_remaining
	set(value): candidate_charm_stage_controller.tick_remaining = value
var candidate_charm_zone_profile: CharmProfileData:
	get: return candidate_charm_stage_controller.profile
	set(value): candidate_charm_stage_controller.profile = value
var candidate_charm_stage_grants_buff: bool:
	get: return candidate_charm_stage_controller.grants_stage_buff
	set(value): candidate_charm_stage_controller.grants_stage_buff = value
var judaginda_reaper_summon: ReaperSummon
var tutorial_scenario: TutorialScenarioData
var tutorial_director: TutorialDirector
var tutorial_action_guide: TutorialActionGuide
var tutorial_completion_pending: bool = false
var boss_breach_counts: Dictionary = {}
var final_boss_contest_started: bool = false

func _ready() -> void:
	var startup := run_startup_service.build_plan(stage_data, enemy_scene, testing_mode, testing_random_seed, run_result_service)
	if not bool(startup.get("success", false)):
		_abort_run_startup(String(startup.get("error_message", "GameController could not initialize the run.")))
		return
	stage_data = startup.stage_data
	boss_plan = startup.boss_plan
	tutorial_scenario = startup.get("tutorial_scenario") as TutorialScenarioData
	current_run_id = String(startup.run_id)
	if not String(startup.warning_message).is_empty():
		push_warning(String(startup.warning_message))
	_prepare_run_runtime(startup)
	if not _begin_run_checkpoint():
		return
	_initialize_run_hud(startup)
	_enter_initial_run_phase(startup)

func _abort_run_startup(error_message: String) -> void:
	GameSession.meta_notice = "출격 데이터 오류 [RUN-STARTUP] · 빌드 %s" % BuildInfo.display_text()
	push_error("[RUN-STARTUP] %s · %s" % [BuildInfo.display_text(), error_message])
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main/main_menu.tscn")

func _prepare_run_runtime(startup: Dictionary) -> void:
	_prepare_run_environment()
	_configure_run_combat_actors(startup)
	_configure_run_loadout_systems()
	_configure_run_support_services()

func _prepare_run_environment() -> void:
	pause_menu.persist_options = not testing_mode
	_connect_signals()
	_reset_game_speed()

func _configure_run_combat_actors(startup: Dictionary) -> void:
	var core_data: CoreData = startup.core_data
	var cursor_data: CursorData = startup.cursor_data
	core.position = battlefield.get_core_position()
	core.configure(core_data)
	target_cursor.setup(battlefield, cursor_data)
	previous_cursor_position = target_cursor.global_position

func _configure_run_loadout_systems() -> void:
	block_board_active = true
	loadout.setup(battlefield, column_container)
	# 표준 런의 normal 모드는 정예 드롭을 주 획득원으로 사용한다.
	# disabled/forced 감사 모드는 기존 의미를 유지한다.
	loadout.set_random_artifact_offers_enabled(not (stage_data.has_artifact_elite_schedule() and GameSession.artifact_mode == GameSession.ARTIFACT_MODE_NORMAL))
	_apply_runtime_loadout_stats()
	_setup_candidate_mechanics()
	_setup_enemy_lifecycle()

func _configure_run_support_services() -> void:
	experience_rewards.setup(battlefield, experience, target_cursor, loadout, spatial_index)
	range_overlay.setup(core, loadout, battlefield)
	run_signal_binding_service.connect_once(range_overlay.inspection_snapshot_changed, _on_range_inspection_snapshot_changed)
	run_signal_binding_service.connect_once(unit_info_popover.close_requested, _on_unit_info_close_requested)
	experience.reset()
	metrics.configure_lanes(battlefield.lane_count)
	enemy_spawner.configure_pressure_sources(Callable(self, "_regular_alive_pressure"), Callable(self, "_has_active_spawn_boss"))
	combat_presentation_service.configure(effect_container, metrics)
	artifact_reward_resolution_service.configure(loadout, metrics)
	reward_selection_coordinator.configure(reward_queue, phase_coordinator, get_tree(), level_up_panel, artifact_resolution_panel)
	run_pause_coordinator.configure(phase_coordinator, get_tree(), pause_menu)
	tower_status_service.configure(loadout, metrics, spatial_index, Callable(self, "_show_effect"))

func _begin_run_checkpoint() -> bool:
	if run_startup_service.begin_checkpoint(_build_checkpoint_result(false), testing_mode):
		return true
	GameSession.meta_notice = "출격 저장 오류 [RUN-CHECKPOINT] · 이전 출격 복구 상태를 확인한 뒤 다시 시도해 주세요."
	push_error("[RUN-CHECKPOINT] %s · GameController could not begin a durable run checkpoint." % BuildInfo.display_text())
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main/main_menu.tscn")
	return false

func _initialize_run_hud(startup: Dictionary) -> void:
	var core_data: CoreData = startup.core_data
	var cursor_data: CursorData = startup.cursor_data
	audience_stage.configure(core.presentation_color, GameSession.reduced_motion_enabled)
	hud.set_run_identity(core_data.display_name, cursor_data.display_name, GameSession.selected_challenge_level, String(startup.decree_name))
	hud.set_governance_reaction(startup.governance_reaction, int(startup.governance_approval))
	hud.update_target_position(target_cursor.global_position, battlefield.get_battle_rect(), battlefield.lane_count)
	hud.update_build(loadout.get_build_summary())
	hud.set_tutorial_mode(_is_tutorial())

func _enter_initial_run_phase(startup: Dictionary) -> void:
	if _is_tutorial():
		_enter_tutorial_run(startup.core_data)
		return
	_enter_guard_preparation(startup.core_data, startup.candidate)

func _is_tutorial() -> bool:
	return GameSession.is_tutorial_run() and tutorial_scenario != null

func _ensure_preparation_panel() -> void:
	if preparation_panel != null:
		return
	preparation_panel = PreparationPanel.new()
	$UI.add_child(preparation_panel)
	preparation_panel.setup(loadout)
	preparation_panel.guard_confirmed.connect(_on_guard_confirmed)
	preparation_panel.formation_confirmed.connect(_on_block_formation_confirmed)
	preparation_panel.placement_abandoned.connect(_on_block_placement_abandoned)

func _enter_tutorial_run(core_data: CoreData) -> void:
	_ensure_preparation_panel()
	_ensure_tutorial_action_guide()
	var guard_formation := DataRegistry.get_formation(core_data.unique_formation_id)
	var placements := loadout.get_valid_board_placements(guard_formation)
	if placements.is_empty():
		push_error("Tutorial could not place the fixed guard formation.")
		_return_to_menu()
		return
	var placement := placements[0] as Dictionary
	var guard_anchor := placement.anchor as Vector2i
	var guard_flip := bool(placement.vertical_flipped)
	var owner_id := loadout.place_formation_block(guard_formation, guard_anchor, guard_flip, true, &"guard_emerald")
	if owner_id == &"":
		push_error("Tutorial fixed guard placement failed.")
		_return_to_menu()
		return
	metrics.record_mechanic_event(&"guard_formation_placed")
	metrics.record_guard_placement(guard_formation.candidate_id, guard_anchor, guard_flip, loadout.board_state)
	hud.update_build(loadout.get_build_summary())
	tutorial_director = TutorialDirector.new()
	tutorial_director.step_changed.connect(_on_tutorial_step_changed)
	tutorial_director.guidance_changed.connect(_on_tutorial_guidance_changed)
	tutorial_director.practice_wave_requested.connect(_on_tutorial_practice_wave_requested)
	tutorial_director.boss_warning_requested.connect(_on_tutorial_boss_warning_requested)
	tutorial_director.boss_requested.connect(_on_tutorial_boss_requested)
	tutorial_director.completed.connect(_on_tutorial_completed)
	if not tutorial_director.begin(tutorial_scenario):
		push_error("Tutorial director rejected the scenario.")
		_return_to_menu()
		return
	_begin_running()

func _enter_guard_preparation(core_data: CoreData, candidate: CandidateProfileData) -> void:
	phase_coordinator.enter_preparation()
	core.set_physics_process(false)
	target_cursor.set_physics_process(false)
	target_cursor.set_process_unhandled_input(false)
	_ensure_preparation_panel()
	var guard_formation := DataRegistry.get_formation(core_data.unique_formation_id)
	var candidate_name: String = candidate.short_name if candidate != null else core_data.display_name
	preparation_panel.show_guard(candidate_name, guard_formation)
	hud.show_notice("친위대를 배치하면 10분 공개 연설이 시작됩니다.", 5.0)

func _on_guard_confirmed(formation: TowerFormationData, anchor: Vector2i, vertical_flipped: bool) -> void:
	if game_phase != GameTypes.GamePhase.PREPARATION:
		return
	var owner_id := loadout.place_formation_block(
		formation,
		anchor,
		vertical_flipped,
		true,
		StringName("guard_%s" % GameSession.selected_core_id)
	)
	if owner_id == &"":
		preparation_panel.show_guard(DataRegistry.get_core(GameSession.selected_core_id).display_name, formation)
		hud.show_notice("친위대 배치를 확정하지 못했습니다. 다른 위치를 선택해 주세요.", 3.0)
		return
	metrics.record_mechanic_event(&"guard_formation_placed")
	metrics.record_guard_placement(formation.candidate_id, anchor, vertical_flipped, loadout.board_state)
	hud.update_build(loadout.get_build_summary())
	_begin_running()

func _begin_running() -> void:
	core.set_physics_process(true)
	target_cursor.set_physics_process(true)
	target_cursor.set_process_unhandled_input(true)
	enemy_spawner.start(
		stage_data,
		DataRegistry.enemies,
		DataRegistry.bosses,
		battlefield.lane_count,
		GameSession.selected_challenge_level,
		boss_plan,
		DataRegistry.faction_enemies,
		not _is_tutorial() and GameSession.artifact_mode != GameSession.ARTIFACT_MODE_DISABLED
	)
	if _is_tutorial():
		enemy_spawner.spawn_director.configure_bonus_mode(&"disabled")
		enemy_spawner.set_boss_schedule_enabled(false)
	phase_coordinator.enter_running()
	if _is_tutorial():
		pass
	elif SaveManager.total_runs == 0 and not testing_mode:
		hud.show_notice("클릭·드래그 위치로 %s이 이동하며 자동 공격·경험치 회수 · Ⅱ 버튼으로 일시정지" % ConceptService.term(&"cursor"), 6.0)
	elif GameSession.selected_challenge_level > 0:
		hud.show_notice("도전 %d단계 · 적 강화 적용 · 경험치 +%d%%" % [GameSession.selected_challenge_level, roundi((ChallengeRules.experience_multiplier(GameSession.selected_challenge_level) - 1.0) * 100.0)], 4.0)
	SignalBus.game_started.emit()

func _physics_process(delta: float) -> void:
	if game_finished:
		return
	judaginda_guard_controller.update(delta)
	_record_runtime_frame_state(delta)
	_update_runtime_timers(delta)
	_update_runtime_combat_systems(delta)
	_update_runtime_balance_sampling(delta)
	if tutorial_director != null:
		tutorial_director.advance(delta)

func _on_tutorial_step_changed(step_index: int, _step_id: StringName, instruction: String) -> void:
	hud.set_tutorial_step(step_index, TutorialDirector.LEARNING_STEP_COUNT, instruction)
	match step_index:
		TutorialDirector.Step.PLACE_GOBLINS:
			phase_coordinator.enter_preparation()
			get_tree().paused = true
			preparation_panel.show_required_formation(DataRegistry.get_formation(tutorial_scenario.formation_id), tutorial_scenario.required_formation_anchor)
		TutorialDirector.Step.OBSERVE_DEFENSE:
			preparation_panel.hide()
			phase_coordinator.enter_running()
			get_tree().paused = false
		TutorialDirector.Step.FIXED_GROWTH:
			reward_selection_coordinator.enter_selection()
			var tower := DataRegistry.get_tower(tutorial_scenario.fixed_upgrade_id)
			var fixed_choice := UpgradeData.new().configure(
				tutorial_scenario.fixed_upgrade_category,
				"%s 전체 Lv.2" % tower.display_name,
				"튜토리얼 고정 성장 · 배치한 고블린 창병 전열을 강화합니다.",
				tutorial_scenario.fixed_upgrade_id
			)
			reward_selection_coordinator.show_event_choices([fixed_choice], "훈련 · 첫 성장", "고정 카드 한 장을 선택하세요. 리롤과 무작위 선택은 없습니다.")
		TutorialDirector.Step.TUTORIAL_BOSS:
			reward_selection_coordinator.hide_level_up()
			phase_coordinator.enter_running()
			get_tree().paused = false
			enemy_spawner.set_regular_schedule_enabled(false)
		TutorialDirector.Step.CANDIDATE_SKILL:
			core.add_skill_charge(core.data.skill_charge_seconds)
	_update_tutorial_action_guide(step_index)

func _ensure_tutorial_action_guide() -> void:
	if is_instance_valid(tutorial_action_guide):
		return
	tutorial_action_guide = TutorialActionGuide.new()
	tutorial_action_guide.name = "TutorialActionGuide"
	$UI.add_child(tutorial_action_guide)

func _update_tutorial_action_guide(step_index: int) -> void:
	if not is_instance_valid(tutorial_action_guide):
		return
	match step_index:
		TutorialDirector.Step.MOVE_RETAINER:
			tutorial_action_guide.focus_world(target_cursor, 72.0, "칸다를 클릭·드래그해 이동")
		TutorialDirector.Step.PLACE_GOBLINS:
			tutorial_action_guide.focus_controls(preparation_panel.tutorial_action_controls(), "지정 칸 확인 후 배치 확정")
		TutorialDirector.Step.OBSERVE_DEFENSE:
			tutorial_action_guide.clear()
		TutorialDirector.Step.FIXED_GROWTH:
			tutorial_action_guide.focus_controls(level_up_panel.tutorial_action_controls(), "고정 성장 카드를 선택")
		TutorialDirector.Step.TUTORIAL_BOSS:
			tutorial_action_guide.focus_world(target_cursor, 72.0, "칸다를 위험한 행으로 이동")
		TutorialDirector.Step.CANDIDATE_SKILL:
			tutorial_action_guide.focus_controls([hud.skill_button], "필살 공약 버튼을 누르기")
		_:
			tutorial_action_guide.clear()

func _on_tutorial_guidance_changed(step_index: int, instruction: String) -> void:
	hud.set_tutorial_step(step_index, TutorialDirector.LEARNING_STEP_COUNT, instruction)

func _on_tutorial_practice_wave_requested(wave_index: int) -> void:
	if not _is_tutorial() or tutorial_scenario == null:
		return
	var enemy := DataRegistry.get_enemy(tutorial_scenario.tutorial_enemy_id)
	if enemy == null:
		push_error("Tutorial practice wave references a missing enemy.")
		return
	var lane_pattern := PackedInt32Array([1, 2])
	match wave_index % 3:
		1:
			lane_pattern = PackedInt32Array([0, 3])
		2:
			lane_pattern = PackedInt32Array([2, 1])
	var spawn_y_ratios := PackedFloat32Array()
	for unit_index in tutorial_scenario.practice_units_per_wave:
		var lane_index := lane_pattern[unit_index % lane_pattern.size()]
		spawn_y_ratios.append((float(lane_index) + 0.5) / float(battlefield.lane_count))
	enemy_spawner.spawn_scripted_regular_wave(
		enemy,
		spawn_y_ratios,
		tutorial_scenario.practice_enemy_health_multiplier,
		tutorial_scenario.practice_enemy_speed_multiplier
	)

func _on_tutorial_boss_warning_requested(seconds_remaining: float) -> void:
	if _is_tutorial():
		enemy_spawner.warn_boss_now(0, seconds_remaining)

func _on_tutorial_boss_requested() -> void:
	if _is_tutorial() and not enemy_spawner.spawn_boss_now(0):
		push_error("Tutorial could not spawn its scripted boss.")

func _on_tutorial_completed() -> void:
	if tutorial_completion_pending:
		return
	if is_instance_valid(tutorial_action_guide):
		tutorial_action_guide.clear()
	tutorial_completion_pending = true
	_complete_tutorial_after_feedback.call_deferred()

func _complete_tutorial_after_feedback() -> void:
	await get_tree().create_timer(1.4).timeout
	if not testing_mode and not SaveManager.complete_tutorial():
		tutorial_completion_pending = false
		hud.show_notice("튜토리얼 완료 상태를 저장하지 못했습니다. 메뉴로 돌아가기 전에 다시 시도해 주세요.", 5.0)
		return
	game_finished = true
	_shutdown_combat_runtime()
	_reset_game_speed(false)
	get_tree().paused = false
	GameSession.end_tutorial_run()
	GameSession.meta_notice = "튜토리얼 완료 · 출격 설정과 허브 기능이 열렸습니다."
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

func _record_runtime_frame_state(delta: float) -> void:
	metrics.update_time(enemy_spawner.elapsed)
	_update_faction_prelude_hud()
	_update_audience_threat(delta)
	var current_speed := maxf(Engine.time_scale, 0.01)
	metrics.record_runtime_frame(delta, delta / current_speed, current_speed)
	metrics.record_cursor_lane(target_cursor.current_sector, delta)

func _update_audience_threat(delta: float) -> void:
	audience_threat_sample_accumulator += delta
	if audience_threat_sample_accumulator < 0.12:
		return
	audience_threat_sample_accumulator = 0.0
	var battle_rect := battlefield.get_battle_rect()
	var approach_span := maxf(battle_rect.end.x - core.global_position.x, 1.0)
	var closest_progress := 1.0
	var found_active_enemy := false
	for enemy in _active_enemies():
		if enemy == null or not is_instance_valid(enemy) or not enemy.active:
			continue
		found_active_enemy = true
		closest_progress = minf(closest_progress, clampf((enemy.global_position.x - core.global_position.x) / approach_span, 0.0, 1.0))
	var next_threat := AudienceReactionStage.THREAT_CLEAR
	if found_active_enemy and closest_progress <= 0.24:
		next_threat = AudienceReactionStage.THREAT_DANGER
	elif found_active_enemy and closest_progress <= 0.42:
		next_threat = AudienceReactionStage.THREAT_WARNING
	audience_stage.set_threat_level(next_threat)

func _update_faction_prelude_hud() -> void:
	var state := enemy_spawner.get_faction_prelude_state(enemy_spawner.elapsed)
	state["current_seconds"] = enemy_spawner.elapsed
	var campaign := ConceptService.get_election_campaign()
	var faction := campaign.faction(StringName(state.get("faction_id", &""))) if campaign != null and bool(state.get("active", false)) else null
	hud.update_faction_prelude(
		state,
		faction.display_name if faction != null else "",
		faction.accent_color if faction != null else Color("e4bd67"),
		faction.marker_style if faction != null else &"",
		faction.primary_color if faction != null else Color.WHITE,
		faction.secondary_color if faction != null else Color.WHITE
	)

func _update_runtime_timers(delta: float) -> void:
	rear_overcharge_remaining = maxf(rear_overcharge_remaining - delta, 0.0)
	cursor_trail_cooldown = maxf(cursor_trail_cooldown - delta, 0.0)
	specialization_refresh_accumulator += delta
	if specialization_refresh_accumulator >= 0.2:
		specialization_refresh_accumulator = 0.0
		_refresh_specialization_tower_bonuses()

func _update_runtime_combat_systems(delta: float) -> void:
	_update_guard_abilities(delta)
	_update_candidate_charm_stage(delta)

func _update_runtime_balance_sampling(delta: float) -> void:
	performance_sample_accumulator += delta
	if performance_sample_accumulator >= 0.5:
		performance_sample_accumulator = 0.0
		_record_runtime_balance_sample()

func _record_runtime_balance_sample() -> void:
	var summon_snapshot := summon_service.budget_snapshot() if summon_service != null else {}
	metrics.record_spawn_director_snapshot(enemy_spawner.spawn_budget_snapshot())
	_record_scene_load_balance_sample(summon_snapshot)
	_record_kasuha_balance_samples()
	_record_irelai_balance_samples()
	_record_retainer_balance_samples()

func _record_scene_load_balance_sample(summon_snapshot: Dictionary) -> void:
	metrics.record_scene_load(
		_active_enemies().size(),
		get_tree().get_nodes_in_group(&"projectiles").size(),
		effect_container.get_child_count(),
		int(summon_snapshot.get("active", 0)),
		int(summon_snapshot.get("active_cost", 0))
	)
	metrics.record_mechanic_sample(&"summon_total_active", float(summon_snapshot.get("active", 0)))
	metrics.record_mechanic_sample(&"summon_budget_cost", float(summon_snapshot.get("active_cost", 0)))

func _record_kasuha_balance_samples() -> void:
	if bool(loadout.get_candidate_modifier(&"abyss_presence", false)):
		metrics.record_mechanic_sample(&"kasuha_abyss_presence_stacks", loadout.candidate_abyss_stacks)
	if bool(loadout.get_candidate_modifier(&"candidate_summoning", false)):
		metrics.record_mechanic_sample(&"kasuha_active_summons", candidate_abyss_controller.active_count() if candidate_abyss_controller != null else 0)
	if bool(loadout.get_guard_modifier(&"guard_erosion_zone", false)):
		metrics.record_mechanic_sample(&"kasuha_guard_erosion_zones", kasuha_guard_controller.active_erosion_zone_count())
	if core.data != null and core.data.id == &"amethyst":
		var pillar_summon_count := abyss_sacrifice_controller.active_total()
		var candidate_summon_count := candidate_abyss_controller.active_count() if candidate_abyss_controller != null else 0
		metrics.record_mechanic_sample(&"kasuha_total_abyss_summons", pillar_summon_count + candidate_summon_count)

func _record_irelai_balance_samples() -> void:
	if necromancy_controller != null and is_instance_valid(necromancy_controller):
		metrics.record_mechanic_sample(&"necromancy_charges", necromancy_controller.charges)
		metrics.record_mechanic_sample(&"necromancy_active_summons", necromancy_controller.active_summon_lifetimes.size())
		if bool(loadout.get_candidate_modifier(&"soul_harvest", false)):
			metrics.record_mechanic_sample(&"irelai_soul_stacks", loadout.candidate_soul_stacks)

func _record_retainer_balance_samples() -> void:
	if vanguard_squad_component != null and is_instance_valid(vanguard_squad_component):
		metrics.record_mechanic_sample(&"vanguard_members", vanguard_squad_component.current_members)
	if retainer_reconstruction_component != null and is_instance_valid(retainer_reconstruction_component):
		metrics.record_mechanic_sample(&"retainer_reconstructing", 0.0 if retainer_reconstruction_component.can_attack() else 1.0)
	if retainer_reactivation_registry.component_count() > 0:
		metrics.record_mechanic_sample(&"reactivation_inactive_towers", retainer_reactivation_registry.inactive_count())
	if bool(loadout.get_guard_modifier(&"guard_devotion", false)):
		metrics.record_mechanic_sample(&"jiane_guard_devotion_stacks", loadout.get_guard_runtime_value(&"devotion"))
	if bool(loadout.get_guard_modifier(&"guard_martyrdom", false)):
		metrics.record_mechanic_sample(&"judaginda_guard_martyr_stacks", loadout.get_guard_runtime_value(&"martyr"))

func _connect_signals() -> void:
	run_signal_binding_service.bind_runtime(
		core, target_cursor, experience_rewards, enemy_spawner, loadout, experience,
		level_up_panel, artifact_resolution_panel, pause_menu, hud, get_viewport(),
		_run_signal_callbacks()
	)

func _run_signal_callbacks() -> Dictionary:
	return {
		&"core_health_relay": Callable(self, "_relay_core_health_changed"),
		&"core_destroyed": _on_core_destroyed,
		&"core_attack": _on_core_attack_requested,
		&"core_skill_cast_started": _on_core_skill_cast_started,
		&"core_skill": _on_core_skill_requested,
		&"cursor_attack": _on_target_attack_requested,
		&"collection": _on_collection_requested,
		&"boss_reward_completed": _on_boss_reward_completed,
		&"retainer_experience_collected": Callable(self, "_on_retainer_experience_collected"),
		&"experience_orb_spawned": Callable(self, "_on_experience_orb_spawned"),
		&"experience_orb_collected": Callable(self, "_on_experience_orb_collected"),
		&"cursor_moved": _on_cursor_moved,
		&"spawn": _on_spawn_requested,
		&"boss_warning": _on_boss_warning,
		&"tower_attack": _on_tower_attack_requested,
		&"range_refresh": Callable(self, "_refresh_range_overlay"),
		&"execute_threshold_refresh": _refresh_enemy_execute_thresholds,
		&"candidate_loadout_changed": _on_candidate_loadout_changed,
		&"leveled_up": _on_leveled_up,
		&"upgrade_selected": _on_upgrade_selected,
		&"level_up_reroll": _on_level_up_reroll_requested,
		&"artifact_replace": _on_artifact_replacement_requested,
		&"artifact_discard": _on_artifact_discard_requested,
		&"pause_resume": _close_pause_menu,
		&"return_to_menu": _return_to_menu,
		&"screen_shake": screen_effects.set_shake_enabled,
		&"screen_flash": screen_effects.set_flash_enabled,
		&"reduced_motion": _set_reduced_motion_enabled,
		&"restart": _restart_game,
		&"request_core_skill": _request_core_skill,
		&"cycle_speed": _cycle_game_speed,
		&"set_range_overlay": _set_range_overlay,
		&"open_pause": _open_pause_menu,
		&"viewport_size_changed": _on_viewport_size_changed,
	}

func _relay_core_health_changed(current: float, maximum: float) -> void:
	SignalBus.core_health_changed.emit(current, maximum)

func _refresh_range_overlay(_summary: String = "") -> void:
	range_overlay.refresh()

func _on_range_inspection_snapshot_changed(selection: Dictionary) -> void:
	if selection.is_empty():
		unit_info_popover.hide_popover()
		return
	var snapshot := unit_info_presenter.present(selection, core, loadout, battlefield, _resolve_unit_info_tower_damage)
	if snapshot.is_empty():
		unit_info_popover.hide_popover()
		if not range_overlay.get_inspection_snapshot().is_empty():
			range_overlay.clear_inspection()
		return
	var world_position := snapshot.get("world_position", Vector2.ZERO) as Vector2
	var screen_position := get_viewport().get_canvas_transform() * world_position
	var viewport_size := Vector2i(roundi(get_viewport_rect().size.x), roundi(get_viewport_rect().size.y))
	unit_info_popover.show_snapshot(snapshot, screen_position, viewport_size)

func _on_unit_info_close_requested() -> void:
	range_overlay.clear_inspection()

func _resolve_unit_info_tower_damage(column: TowerColumn, row_index: int) -> float:
	if not is_instance_valid(column) or column.get_tower_data(row_index) == null:
		return 0.0
	return column.get_damage(row_index) * loadout.get_axis_independent_tower_damage_multiplier() * _get_specialization_tower_damage_multiplier(column)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel") and input_policy.allows_pause(game_phase):
		_open_pause_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"restart_game") and input_policy.allows_restart(game_phase):
		_restart_game()
	elif event.is_action_pressed(&"cycle_game_speed") and input_policy.allows_speed_change(game_phase):
		_cycle_game_speed()
	elif event.is_action_pressed(&"toggle_attack_ranges") and input_policy.allows_range_inspection(game_phase):
		_set_range_overlay(not range_overlay.is_overlay_enabled())
	elif event.is_action_pressed(&"core_skill"):
		_request_core_skill()

func _cycle_game_speed() -> void:
	if _is_tutorial() or not input_policy.allows_speed_change(game_phase):
		return
	game_speed_index = (game_speed_index + 1) % GAME_SPEEDS.size()
	_apply_game_speed(true)
	AudioManager.play_ui()

func _apply_game_speed(enabled: bool = true) -> void:
	game_speed_index = clampi(game_speed_index, 0, GAME_SPEEDS.size() - 1)
	Engine.time_scale = GAME_SPEEDS[game_speed_index]
	# 배속이 커져도 한 물리 스텝이 처리하는 게임 시간은 1×와 같게 유지한다.
	# 그렇지 않으면 빠른 배속에서 이동·충돌·경험치 회수가 큰 델타로 건너뛰어
	# 같은 시드의 성장과 편대 선택 결과가 달라진다.
	Engine.physics_ticks_per_second = roundi(float(BASE_PHYSICS_TICKS_PER_SECOND) * Engine.time_scale)
	hud.update_game_speed(Engine.time_scale, enabled)

func _reset_game_speed(enabled: bool = true) -> void:
	game_speed_index = 0
	_apply_game_speed(enabled)

func _set_reduced_motion_enabled(enabled: bool) -> void:
	screen_effects.set_reduced_motion_enabled(enabled)
	audience_stage.set_reduced_motion_enabled(enabled)

func _set_range_overlay(enabled: bool, play_sound: bool = true) -> void:
	if _is_tutorial() and enabled:
		return
	if enabled and not input_policy.allows_range_inspection(game_phase):
		return
	range_overlay.set_overlay_enabled(enabled)
	target_cursor.set_movement_input_enabled(not enabled)
	hud.update_range_overlay(enabled)
	if enabled:
		hud.show_notice("사거리 확인 모드 · %s/%s 선택" % [ConceptService.term(&"core"), ConceptService.term(&"tower")])
	if play_sound:
		AudioManager.play_ui()

func _request_core_skill() -> void:
	if _is_tutorial() and (tutorial_director == null or not tutorial_director.is_step(TutorialDirector.Step.CANDIDATE_SKILL)):
		return
	if input_policy.allows_core_skill(game_phase):
		core.activate_skill()

func _setup_candidate_mechanics() -> void:
	var components := candidate_mechanics_factory.create_components(
		core, target_cursor, effect_container, summon_container, battlefield, spatial_index,
		loadout, _irelai_necromancy_modifiers(), _candidate_mechanic_callbacks()
	)
	summon_service = components.summon_service
	candidate_abyss_controller = components.candidate_abyss_controller
	necromancy_controller = components.necromancy_controller
	death_wave_controller = components.death_wave_controller
	active_retainer_profile = components.retainer_profile
	retainer_combat_controller = components.retainer_combat_controller
	retainer_reconstruction_component = components.retainer_reconstruction_component
	vanguard_squad_component = components.vanguard_squad_component
	abyss_sacrifice_controller.configure(spatial_index, summon_container, summon_service)
	run_signal_binding_service.connect_once(abyss_sacrifice_controller.attack_requested, _on_abyss_summon_attack)
	run_signal_binding_service.connect_once(abyss_sacrifice_controller.summon_expired, _on_abyss_summon_expired)

func _setup_enemy_lifecycle() -> void:
	enemy_lifecycle_controller.configure(spatial_index, irelai_guard_controller.clear_enemy)
	run_signal_binding_service.connect_once(enemy_lifecycle_controller.enemy_reached_core, _on_enemy_reached_core)
	run_signal_binding_service.connect_once(enemy_lifecycle_controller.enemy_died, _on_enemy_died)
	run_signal_binding_service.connect_once(enemy_lifecycle_controller.charmed_enemy_defeated, _on_charmed_enemy_defeated)
	run_signal_binding_service.connect_once(enemy_lifecycle_controller.enemy_damage_received, _on_enemy_damage_received)
	run_signal_binding_service.connect_once(enemy_lifecycle_controller.enemy_special_action, _on_enemy_special_action)
	run_signal_binding_service.connect_once(enemy_lifecycle_controller.enemy_acceleration_changed, _on_enemy_acceleration_changed)
	run_signal_binding_service.connect_once(enemy_lifecycle_controller.enemy_control_resolved, _on_enemy_control_resolved)
	run_signal_binding_service.connect_once(enemy_lifecycle_controller.boss_health_changed, _on_boss_health_changed)
	run_signal_binding_service.connect_once(enemy_lifecycle_controller.boss_tree_exiting, _on_boss_tree_exiting)

func _candidate_mechanic_callbacks() -> Dictionary:
	return {
		&"candidate_abyss_attack": _on_candidate_abyss_summon_attack,
		&"candidate_abyss_expired": _on_candidate_abyss_summon_expired,
		&"spirits_generated": _on_irelai_spirits_generated,
		&"spirit_expired": _on_irelai_summon_expired,
		&"death_wave_hit": _on_death_wave_hit_requested,
		&"death_wave_finished": _on_death_wave_finished,
		&"reconstruction_started": Callable(self, "_on_retainer_reconstruction_started"),
		&"reconstruction_completed": Callable(self, "_on_retainer_reconstruction_completed"),
		&"vanguard_member_spent": Callable(self, "_on_vanguard_member_spent"),
		&"vanguard_reinforcement_arrived": Callable(self, "_on_vanguard_reinforcement_arrived"),
		&"vanguard_sacrifice": Callable(self, "_on_vanguard_sacrifice"),
		&"retainer_resummoned": Callable(self, "_on_retainer_resummoned"),
	}

func _on_retainer_reconstruction_started(duration: float) -> void:
	metrics.record_mechanic_event(&"combo_reconstruction", duration)
	if not game_finished:
		hud.show_notice("주그디에드 뼈 상태 · 공격 중지 %.1f초" % duration, 2.0)

func _on_retainer_reconstruction_completed() -> void:
	if game_finished:
		return
	hud.show_notice("주그디에드 재구성 완료 · 공격 재개", 1.6)
	_show_pattern_effect(target_cursor.global_position, target_cursor.data.color, 58.0, &"sigil", 0.7, 0.5)

func _on_vanguard_member_spent(current: int, maximum: int) -> void:
	metrics.record_mechanic_event(&"vanguard_member_spent")
	if not game_finished:
		hud.show_notice("처형 집행 · 돌격부대 %d/%d · 충원 시작" % [current, maximum], 1.5)

func _on_vanguard_reinforcement_arrived(current: int, maximum: int) -> void:
	metrics.record_mechanic_event(&"vanguard_reinforcement")
	if game_finished:
		return
	_show_effect(core.global_position, target_cursor.global_position, target_cursor.data.color, 0.0, 0.42)
	_show_pattern_effect(target_cursor.global_position, target_cursor.data.color, 48.0, &"sigil", 0.55, 0.45)
	hud.show_notice("본진 충원 도착 · 돌격부대 %d/%d" % [current, maximum], 1.4)

func _on_vanguard_sacrifice(members: int) -> void:
	var modifiers := loadout.get_cursor_branch_modifiers()
	var damage := target_cursor.data.damage * target_cursor.stat_multiplier * float(modifiers.get("vanguard_sacrifice_damage", 1.6)) * float(members)
	var dealt := 0.0
	for enemy in spatial_index.query_radius(target_cursor.global_position, target_cursor.get_effective_attack_radius() * 1.35):
		dealt += enemy.take_damage(damage, &"vanguard_sacrifice", true)
		enemy.apply_knockback(target_cursor.get_effective_knockback() * 1.2)
	metrics.record_cursor_damage(dealt)
	metrics.record_mechanic_event(&"vanguard_timed_sacrifice", members)
	_show_burst_effect(target_cursor.global_position, target_cursor.data.color, target_cursor.get_effective_attack_radius() * 1.35, 0.7)

func _on_retainer_resummoned(arrival_position: Vector2, damage_multiplier: float, slow_power: float) -> void:
	metrics.record_mechanic_event(&"jeomujeom_resummon")
	var radius := target_cursor.get_effective_attack_radius() * 0.82
	var dealt := 0.0
	var control_count := 0
	for enemy in spatial_index.query_radius(arrival_position, radius):
		if damage_multiplier > 0.0:
			dealt += enemy.take_damage(target_cursor.data.damage * target_cursor.stat_multiplier * damage_multiplier, &"jeomujeom_arrival", true)
		if slow_power > 0.0 and enemy.apply_slow(&"retainer_jeomujeom_arrival", 2.4, slow_power):
			control_count += 1
	metrics.record_cursor_damage(dealt)
	metrics.record_retainer_control(control_count)
	if dealt > 0.0:
		metrics.record_mechanic_event(&"jeomujeom_arrival_damage", dealt)
	if control_count > 0:
		metrics.record_mechanic_event(&"jeomujeom_arrival_slow", control_count)
	_show_pattern_effect(arrival_position, target_cursor.data.color, radius, &"sigil", 0.9, 0.68, CombatEffectBudget.Priority.IMPORTANT)
	_show_burst_effect(arrival_position, target_cursor.data.color, radius, 0.65)

func _on_candidate_loadout_changed(_summary: String = "") -> void:
	if necromancy_controller != null and is_instance_valid(necromancy_controller):
		necromancy_controller.apply_modifiers(_irelai_necromancy_modifiers())
		necromancy_controller.set_soul_display(loadout.candidate_soul_stacks, int(loadout.get_candidate_modifier(&"soul_harvest_cap", 0)))
	if retainer_reconstruction_component != null and is_instance_valid(retainer_reconstruction_component):
		retainer_reconstruction_component.apply_modifiers(loadout.get_cursor_branch_modifiers())
	if retainer_combat_controller != null and is_instance_valid(retainer_combat_controller):
		retainer_combat_controller.apply_modifiers(loadout.get_cursor_branch_modifiers())
	if vanguard_squad_component != null and is_instance_valid(vanguard_squad_component):
		vanguard_squad_component.apply_modifiers(loadout.get_cursor_branch_modifiers())
	_sync_retainer_reactivation_components()

func _irelai_necromancy_modifiers() -> Dictionary:
	var result := loadout.get_core_branch_modifiers().duplicate(true)
	var candidate_modifiers := loadout.get_candidate_modifiers()
	for key in candidate_modifiers:
		result[key] = candidate_modifiers[key]
	return result

func _retainer_component_key(column: TowerColumn, row_index: int) -> String:
	return retainer_reactivation_registry.key_for(column, row_index)

func _retainer_reactivation_modifiers(column: TowerColumn) -> Dictionary:
	var result := loadout.get_core_branch_modifiers().duplicate(true)
	if column != null and column.is_guard_formation:
		var guard_modifiers := loadout.get_guard_modifiers()
		for key in guard_modifiers:
			result[key] = guard_modifiers[key]
	return result

func _get_retainer_reactivation_component(column: TowerColumn, row_index: int, tower: TowerData) -> RetainerReactivationComponent:
	return retainer_reactivation_registry.get_or_create(
		column, row_index, tower, effect_container,
		_retainer_reactivation_modifiers(column), _retainer_reactivation_callbacks()
	)

func _retainer_reactivation_callbacks() -> Dictionary:
	return {
		&"deactivated": Callable(self, "_on_retainer_deactivated"),
		&"reactivated": Callable(self, "_on_retainer_reactivated"),
		&"removed": Callable(irelai_guard_controller, "clear_source"),
	}

func _on_retainer_deactivated(column: TowerColumn, row_index: int, tower: TowerData) -> void:
	metrics.record_mechanic_event(&"retainer_deactivated")
	_resolve_irelai_guard_deactivation.call_deferred(column, row_index, tower)
	if not game_finished:
		hud.show_notice("망자 부활진 행동불능 · 재가동 준비", 2.0)

func _on_retainer_reactivated(column: TowerColumn, row_index: int, tower: TowerData) -> void:
	metrics.record_mechanic_event(&"retainer_reactivated")
	var guard_result := irelai_guard_controller.register_reactivation(column, row_index, tower, loadout)
	if bool(guard_result.get("curse_ready", false)):
		metrics.record_mechanic_event(&"irelai_guard_curse_readied")
		_show_pattern_effect(column.get_attack_origin(row_index), Color("b8ff8e"), 48.0, &"sigil", 0.55, 0.42)
	elif bool(guard_result.get("fast_soul", false)):
		metrics.record_mechanic_event(&"irelai_guard_fast_soul")
	if not game_finished:
		hud.show_notice("망자 부활진 완전 재가동", 1.6)

func _resolve_irelai_guard_deactivation(column: TowerColumn, row_index: int, tower: TowerData) -> void:
	if game_finished or not is_instance_valid(column):
		return
	var result := _request_irelai_guard_deactivation(column, row_index, tower)
	if int(result.get("hit_count", 0)) <= 0:
		return
	_finalize_irelai_guard_deactivation(column, row_index, tower, result)

func _request_irelai_guard_deactivation(column: TowerColumn, row_index: int, tower: TowerData) -> Dictionary:
	return irelai_guard_controller.resolve_deactivation(
		column,
		row_index,
		tower,
		loadout,
		spatial_index,
		loadout.get_tower_damage_multiplier(),
		_get_specialization_tower_damage_multiplier(column)
	)

func _finalize_irelai_guard_deactivation(column: TowerColumn, row_index: int, tower: TowerData, result: Dictionary) -> void:
	var hit_count := int(result.get("hit_count", 0))
	var origin := result.get("position", column.get_attack_origin(row_index)) as Vector2
	var tracked_enemies: Array[Enemy] = []
	tracked_enemies.assign(result.get("tracked_enemies", []) as Array)
	var dealt := float(result.get("damage", 0.0))
	_record_tower_result(column, tower, dealt, tracked_enemies, origin, hit_count)
	metrics.record_mechanic_event(&"irelai_guard_inactive_explosion_damage", dealt)
	metrics.record_mechanic_event(&"irelai_guard_inactive_explosion_hits", hit_count)
	_show_burst_effect(origin, Color("9ddd55"), float(result.get("radius", 0.0)), 0.58)

func _sync_retainer_reactivation_components() -> void:
	retainer_reactivation_registry.synchronize(
		loadout.columns, effect_container, Callable(self, "_retainer_reactivation_modifiers"),
		_retainer_reactivation_callbacks(), Callable(irelai_guard_controller, "clear_source")
	)

func _release_spirit_attacks(fallback_origin: Vector2, base_damage: float, requested: int) -> float:
	if necromancy_controller == null or not is_instance_valid(necromancy_controller):
		return 0.0
	var result := spirit_attack_execution_service.execute(
		fallback_origin, base_damage, requested, necromancy_controller.spirit_damage_multiplier,
		necromancy_controller.profile.spirit_blast_radius if necromancy_controller.profile != null else 0.0,
		Callable(self, "_active_enemies"), Callable(necromancy_controller, "request_summon_entries"), Callable(RunRng, "pick"),
		Callable(self, "_apply_spirit_curse"), Callable(spatial_index, "query_radius"), Callable(self, "_apply_spirit_damage"),
		Callable(self, "_present_spirit_attack"), Callable(necromancy_controller, "update_active_summon")
	)
	_record_spirit_attack_summary(int(result.released_count), float(result.damage), int(result.hit_count))
	return float(result.damage)

func _release_single_spirit_attack(fallback_origin: Vector2, base_damage: float) -> Dictionary:
	if necromancy_controller == null or not is_instance_valid(necromancy_controller):
		return {"released": false}
	return spirit_attack_execution_service.execute_single(
		fallback_origin, base_damage, necromancy_controller.spirit_damage_multiplier,
		necromancy_controller.profile.spirit_blast_radius if necromancy_controller.profile != null else 0.0,
		Callable(self, "_active_enemies"), Callable(necromancy_controller, "request_summon_entries"), Callable(RunRng, "pick"),
		Callable(self, "_apply_spirit_curse"), Callable(spatial_index, "query_radius"), Callable(self, "_apply_spirit_damage"),
		Callable(self, "_present_spirit_attack"), Callable(necromancy_controller, "update_active_summon")
	)

func _apply_spirit_curse(spirit_target: Enemy, curse_generation: int) -> bool:
	if curse_generation <= 0 or not irelai_guard_controller.apply_curse(spirit_target, curse_generation):
		return false
	metrics.record_mechanic_event(&"irelai_guard_spirit_curse", curse_generation)
	_show_pattern_effect(spirit_target.global_position, Color("b8ff8e"), 38.0 + curse_generation * 5.0, &"sigil", 0.48, 0.42)
	return true

func _apply_spirit_damage(target: Enemy, damage: float, source: StringName, is_area: bool) -> float:
	return target.take_damage(damage, source, is_area)

func _present_spirit_attack(origin: Vector2, target_position: Vector2, blast_radius: float) -> void:
	_show_effect(origin, target_position, Color("a8ffcf"), 0.0, 0.36)
	_show_pattern_effect(target_position, Color("78dba6"), blast_radius, &"sigil", 0.55, 0.5)

func _record_spirit_attack_summary(released_count: int, dealt: float, hit_count: int) -> void:
	if released_count > 0:
		metrics.record_mechanic_event(&"necromancy_summons_released", released_count)
	if dealt > 0.0:
		metrics.record_mechanic_event(&"necromancy_damage", dealt)
		metrics.record_mechanic_event(&"necromancy_hits", hit_count)

func _on_irelai_spirits_generated(generation_position: Vector2, count: int) -> void:
	metrics.record_mechanic_event(&"irelai_spirits_generated", count)
	var result := candidate_necromancy_effect_service.apply_generation_fear(
		generation_position,
		Callable(loadout, "get_candidate_modifier"),
		Callable(spatial_index, "query_radius")
	)
	if int(result.feared_count) <= 0:
		return
	metrics.record_mechanic_event(&"irelai_generation_fear", int(result.feared_count))
	_show_pattern_effect(generation_position, Color("8c76d9"), float(result.radius), &"shockwave", 0.52, 0.44)

func _on_irelai_summon_expired(expire_position: Vector2, summon_damage: float) -> void:
	metrics.record_mechanic_event(&"irelai_spirit_expired")
	var result := candidate_necromancy_effect_service.apply_expiration_blast(
		expire_position,
		summon_damage,
		Callable(loadout, "get_candidate_modifier"),
		Callable(spatial_index, "query_radius")
	)
	if int(result.hit_count) <= 0:
		return
	metrics.record_mechanic_event(&"irelai_expiration_blast_damage", float(result.damage))
	metrics.record_mechanic_event(&"irelai_expiration_blast_hits", int(result.hit_count))
	_show_burst_effect(expire_position, Color("9ddd55"), float(result.radius), 0.5)

func _on_death_wave_hit_requested(enemy: Enemy, damage: float, spirit_gain: int, spirit_damage_multiplier: float) -> void:
	var add_charges_callback := Callable(necromancy_controller, "add_charges") if is_instance_valid(necromancy_controller) else Callable()
	var result := candidate_death_wave_runtime_service.resolve_hit(
		game_finished,
		enemy,
		damage,
		spirit_gain,
		spirit_damage_multiplier,
		func(target: Enemy, requested_damage: float) -> float:
			return target.take_damage(requested_damage, &"irelai_death_wave", true),
		func(dealt: float) -> void:
			metrics.record_mechanic_event(&"irelai_death_wave_damage", dealt),
		add_charges_callback
	)
	if not bool(result.resolved):
		return
	if int(result.generated_spirit_gain) > 0:
		metrics.record_mechanic_event(&"irelai_death_wave_spirits", int(result.generated_spirit_gain))

func _on_death_wave_finished() -> void:
	metrics.record_mechanic_event(&"irelai_death_wave_finished")
	var begin_active_window_callback := Callable(necromancy_controller, "begin_active_window") if is_instance_valid(necromancy_controller) else Callable()
	candidate_death_wave_runtime_service.finish(begin_active_window_callback)

func _launch_irelai_death_wave(base_damage: float) -> void:
	if loadout == null or target_cursor == null or core == null or core.data == null or death_wave_controller == null:
		return
	var result := candidate_death_wave_launch_service.execute(
		base_damage,
		loadout.candidate_soul_stacks,
		target_cursor.global_position.y,
		core.data.color,
		Callable(loadout, "get_candidate_modifier"),
		Callable(loadout, "consume_candidate_souls"),
		Callable(death_wave_controller, "launch")
	)
	if not bool(result.launched):
		return
	candidate_death_wave_runtime_service.arm_post_wave_window(float(result.post_wave_window))
	if necromancy_controller != null:
		necromancy_controller.set_soul_display(0, int(result.soul_cap))
	metrics.record_mechanic_event(&"irelai_death_wave_cast")
	var consumed_souls := int(result.consumed_souls)
	if consumed_souls > 0:
		metrics.record_mechanic_event(&"irelai_souls_spent", consumed_souls)
		hud.show_notice("죽음의 파도 · 영혼 %d 소모" % consumed_souls, 2.2)

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _on_spawn_requested(spawn_y_ratio: float, enemy_data: EnemyData, health_multiplier: float, speed_multiplier: float, spawn_context: EnemySpawnContext = null) -> void:
	var spawn_position := battlefield.get_free_spawn_position(spawn_y_ratio, RunRng.spawn_rangef(24.0, 72.0))
	var spawn_zone := battlefield.world_to_lane(spawn_position)
	_spawn_enemy(enemy_data, spawn_position, spawn_zone, health_multiplier, speed_multiplier, spawn_context)

func _spawn_enemy(enemy_data: EnemyData, spawn_position: Vector2, lane_index: int, health_multiplier: float, speed_multiplier: float, spawn_context: EnemySpawnContext = null) -> Enemy:
	if game_finished:
		return null
	var enemy := _request_enemy_spawn(enemy_data, spawn_position, lane_index, health_multiplier, speed_multiplier, spawn_context)
	if enemy == null:
		return null
	_finalize_spawned_enemy(enemy, enemy_data, lane_index)
	return enemy

func _request_enemy_spawn(enemy_data: EnemyData, spawn_position: Vector2, lane_index: int, health_multiplier: float, speed_multiplier: float, spawn_context: EnemySpawnContext = null) -> Enemy:
	var destination_world_y := NAN
	if spawn_context != null and spawn_context.destination_y_ratio >= 0.0:
		var rect := battlefield.get_battle_rect()
		destination_world_y = rect.position.y + rect.size.y * spawn_context.destination_y_ratio
	return enemy_lifecycle_controller.spawn_enemy(
		enemy_scene,
		enemy_container,
		enemy_data,
		spawn_position,
		lane_index,
		battlefield.get_core_goal_position(spawn_position.y),
		health_multiplier,
		speed_multiplier,
		GameSession.selected_challenge_level,
		_campaign_faction_for_enemy(enemy_data),
		_get_execute_threshold_ratio,
		spawn_context,
		destination_world_y
	)

func _finalize_spawned_enemy(enemy: Enemy, enemy_data: EnemyData, lane_index: int) -> void:
	if not testing_mode and not _is_tutorial():
		SaveManager.queue_enemy_encounter(enemy_data.id)
	if enemy_data.is_boss:
		_finalize_spawned_boss(enemy, enemy_data)
	else:
		SignalBus.enemy_spawned.emit(enemy)
	metrics.record_enemy_spawn(lane_index, enemy_data, enemy.spawn_context, enemy.get_instance_id())
	if enemy.spawn_context != null and enemy.spawn_context.is_artifact_elite():
		var tier := enemy.spawn_context.artifact_reward_tier
		metrics.record_mechanic_event(&"artifact_elite_spawned")
		metrics.record_mechanic_event(StringName("artifact_elite_tier_%d_spawned" % tier))
		hud.show_warning("아티팩트 운반 정예 %d단계 출현 · 처치 시 아티팩트 확정" % tier)

func _finalize_spawned_boss(enemy: Enemy, enemy_data: EnemyData) -> void:
	if _is_final_boss(enemy_data):
		final_boss_contest_started = true
	phase_coordinator.enter_boss_battle()
	warning_spawn_ratio = -1.0
	battlefield.set_spawn_warning(-1.0)
	_apply_campaign_boss_character_art(enemy, enemy_data)
	var boss_presentation := _boss_presentation(enemy_data)
	hud.show_boss(
		String(boss_presentation.name),
		boss_presentation.color,
		boss_presentation.marker_style,
		boss_presentation.primary_color,
		boss_presentation.secondary_color
	)
	if enemy_data.boss_tier >= 2:
		loadout.disable_random_column(4.0 + enemy_data.boss_tier)
	_present_boss_spawn(enemy, enemy_data)
	SignalBus.boss_spawned.emit(enemy)
	if _is_tutorial() and tutorial_director != null:
		tutorial_director.record_boss(enemy_data.id)

func _apply_campaign_boss_character_art(enemy: Enemy, enemy_data: EnemyData) -> void:
	var campaign := ConceptService.get_election_campaign()
	var faction := _resolve_campaign_faction(campaign, enemy_data)
	if campaign == null or faction == null:
		return
	var slot_index := _boss_plan_slot_index(enemy_data.id)
	if slot_index >= 0:
		var presentation_kind := boss_plan.presentation_kind_at(slot_index)
		var presentation_id := boss_plan.presentation_id_at(slot_index)
		if presentation_kind != &"" and presentation_id != &"":
			enemy.set_campaign_character_presentation(
				presentation_kind,
				presentation_id,
				_campaign_guard_fallback_tower_id(campaign, faction) if presentation_kind == StageRuntimeBossPlan.PRESENTATION_GUARD else &""
			)
			return
	# Revision 0 campaign plans keep the pre-presentation split compatibility path.
	var is_final_candidate := boss_plan != null and boss_plan.source == StageRuntimeBossPlan.SOURCE_CAMPAIGN and boss_plan.final_boss_id == enemy_data.id
	if is_final_candidate:
		var candidate := campaign.candidate(faction.candidate_id)
		if candidate != null:
			enemy.set_campaign_character_identity(candidate.id, true)
		return
	var retainer := campaign.retainer_for_boss(enemy_data.id)
	if retainer != null:
		enemy.set_campaign_character_identity(retainer.id, false)

func _boss_plan_slot_index(boss_id: StringName) -> int:
	if boss_plan == null:
		return -1
	for slot_index in boss_plan.slots.size():
		if boss_plan.boss_id_at(slot_index) == boss_id:
			return slot_index
	return -1

func _campaign_guard_fallback_tower_id(campaign: ElectionCampaignData, faction: ElectionFactionData) -> StringName:
	if campaign == null or faction == null:
		return &""
	var candidate := campaign.candidate(faction.candidate_id)
	var core := DataRegistry.get_core(candidate.core_id) if candidate != null else null
	return core.unique_tower_id if core != null else &""

func _present_boss_spawn(enemy: Enemy, enemy_data: EnemyData) -> void:
	_show_burst_effect(enemy.global_position, enemy_data.body_color, 90.0 + enemy_data.boss_tier * 18.0, 0.62 + enemy_data.boss_tier * 0.08, CombatEffectBudget.Priority.IMPORTANT)
	screen_effects.shake(0.42 + enemy_data.boss_tier * 0.1, 0.34)
	screen_effects.flash(enemy_data.body_color, 0.1 + enemy_data.boss_tier * 0.02, 0.22)
	AudioManager.play_boss_spawn()

func _get_execute_threshold_ratio(enemy: Enemy = null) -> float:
	var threshold := 0.0
	var selected_core := DataRegistry.get_core(GameSession.selected_core_id)
	if selected_core.judgment_profile != null:
		threshold = selected_core.judgment_profile.execute_health_ratio
		threshold = maxf(threshold, float(loadout.get_core_branch_modifiers().get("execute_ratio", threshold)))
	if &"execute" in loadout.get_installed_tower_ids():
		threshold = maxf(threshold, 0.10)
		for column in loadout.columns:
			if column.contains_tower_type(&"execute"):
				threshold = maxf(threshold, float(column.get_branch_modifiers(&"execute").get("execute_ratio", 0.10)))
	if enemy != null and selected_core.judgment_profile != null:
		return judgment_service.threshold_for(enemy, threshold, selected_core.judgment_profile, _candidate_execution_overrides())
	return threshold

func _resolve_core_hit(enemy: Enemy, damage: float, source_type: StringName, guaranteed_charm: bool = false, sentence_stacks: int = 1, charm_duration_bonus_seconds: float = 0.0, source_core_data: CoreData = null) -> float:
	var modifiers := loadout.get_core_branch_modifiers()
	var core_data: CoreData = source_core_data if source_core_data != null else core.data
	var execution_overrides := _candidate_execution_overrides() if core_data != null and core_data.judgment_profile != null else {}
	var result := core_hit_execution_service.execute(
		enemy,
		damage,
		source_type,
		core_data,
		modifiers,
		guaranteed_charm,
		sentence_stacks,
		charm_duration_bonus_seconds,
		execution_overrides,
		Callable(loadout, "get_candidate_modifier")
	)
	if not bool(result.applied):
		return 0.0
	if result.route == &"judgment":
		var judgment: Dictionary = result.judgment
		_record_judgment_metrics(judgment, bool(result.boss_target))
		_record_candidate_execution(judgment, result.execution_position)
	elif bool(result.charm_applied):
		metrics.record_mechanic_event(&"charm_applied")
	var dealt := float(result.damage)
	_record_kasuha_candidate_hit(enemy, dealt)
	return dealt

func _record_kasuha_candidate_hit(enemy: Enemy, dealt: float) -> void:
	if GameSession.selected_core_id != &"amethyst" or enemy == null or enemy.data == null or dealt <= 0.0 or not bool(loadout.get_candidate_modifier(&"abyss_presence", false)):
		return
	var previous_stacks := loadout.candidate_abyss_stacks
	if enemy.data.is_boss:
		loadout.record_candidate_abyss_boss_damage(dealt / maxf(enemy.get_max_health(), 1.0))
	elif not enemy.active:
		loadout.record_candidate_abyss_defeat(enemy.data)
	if loadout.candidate_abyss_stacks > previous_stacks:
		metrics.record_mechanic_event(&"kasuha_abyss_presence_stack", loadout.candidate_abyss_stacks - previous_stacks)

func _record_judgment_metrics(result: Dictionary, boss_target: bool) -> void:
	if bool(result.get("verdict_triggered", false)):
		metrics.record_mechanic_event(&"judgment_verdict")
		if boss_target:
			metrics.record_mechanic_event(&"judgment_boss_verdict")
	if bool(result.get("executed", false)):
		metrics.record_mechanic_event(&"judgment_execution")

func _candidate_execution_overrides() -> Dictionary:
	if GameSession.selected_core_id != &"obsidian" or not loadout.is_candidate_growth_enabled():
		return {}
	return {
		&"execute_threshold_multiplier": float(loadout.get_candidate_modifier(&"execute_threshold_multiplier", 1.0)),
		&"execute_threshold_normal_multiplier": float(loadout.get_candidate_modifier(&"execute_threshold_normal_multiplier", 1.0)),
		&"execute_threshold_elite_multiplier": float(loadout.get_candidate_modifier(&"execute_threshold_elite_multiplier", 1.0)),
		&"execute_threshold_boss_multiplier": float(loadout.get_candidate_modifier(&"execute_threshold_boss_multiplier", 1.0)),
		&"execute_boss_damage_multiplier": float(loadout.get_candidate_modifier(&"execute_boss_damage_multiplier", 1.0)),
	}

func _record_candidate_execution(result: Dictionary, execution_position: Vector2, guard_column: TowerColumn = null, guard_row_index: int = -1, guard_tower: TowerData = null, enemy_data: EnemyData = null) -> void:
	if not bool(result.get("executed", false)) or GameSession.selected_core_id != &"obsidian":
		return
	_show_candidate_stamp_effect(execution_position, &"judaginda_verdict_seal", Color("d43b52"), 62.0, &"judaginda_verdict_seal", 0.82, 0.58)
	var guard_result := judaginda_guard_controller.resolve_execution(guard_column, guard_row_index, guard_tower, enemy_data, loadout)
	_apply_judaginda_execution_guard_response(guard_result, execution_position)
	_apply_judaginda_execution_skill_charge(guard_result, execution_position)
	_record_judaginda_execution_growth()
	_apply_judaginda_execution_fear(execution_position)

func _apply_judaginda_execution_guard_response(guard_result: Dictionary, execution_position: Vector2) -> void:
	if float(guard_result.get("disabled_duration", 0.0)) > 0.0:
		metrics.record_mechanic_event(&"judaginda_guard_martyr_deactivation")
		_show_pattern_effect(execution_position, Color("9f72ff"), 42.0, &"sigil", float(guard_result.disabled_duration), 0.5)
	if int(guard_result.get("martyr_added", 0)) > 0:
		metrics.record_mechanic_event(&"judaginda_guard_martyr_stack")
		_refresh_specialization_tower_bonuses()
		_apply_runtime_loadout_stats()
		hud.update_build(loadout.get_build_summary())

func _apply_judaginda_execution_skill_charge(guard_result: Dictionary, execution_position: Vector2) -> void:
	var requested_charge := float(guard_result.get("skill_charge", 0.0))
	if requested_charge > 0.0:
		var previous_charge := core.skill_charge
		core.add_skill_charge(requested_charge)
		var gained_charge := maxf(core.skill_charge - previous_charge, 0.0)
		if gained_charge > 0.0:
			metrics.record_mechanic_event(&"judaginda_guard_reaper_charge", gained_charge)
			_show_pattern_effect(execution_position, Color("c7a0ff"), 54.0, &"shockwave", 0.42, 0.42)

func _record_judaginda_execution_growth() -> void:
	if loadout.record_candidate_execution():
		metrics.record_mechanic_event(&"judaginda_execution_growth")

func _apply_judaginda_execution_fear(execution_position: Vector2) -> void:
	if not bool(loadout.get_candidate_modifier(&"execution_fear", false)):
		return
	var fear_radius := float(loadout.get_candidate_modifier(&"execution_fear_radius", 150.0))
	var fear_duration := float(loadout.get_candidate_modifier(&"execution_fear_duration", 4.0))
	var fear_power := float(loadout.get_candidate_modifier(&"execution_fear_power", 0.8))
	var fear_targets := 0
	for fear_target in spatial_index.query_radius(execution_position, fear_radius):
		if fear_target.apply_fear(fear_duration, fear_power):
			fear_targets += 1
	if fear_targets > 0:
		metrics.record_mechanic_event(&"judaginda_execution_fear", fear_targets)
		_show_pattern_effect(execution_position, Color("9f72ff"), fear_radius, &"shockwave", 0.55, 0.48)

func _get_unique_judgment_profile(tower: TowerData) -> JudgmentProfileData:
	if tower == null or tower.unique_core_id == &"":
		return null
	return DataRegistry.get_core(tower.unique_core_id).judgment_profile

func _unique_tower_damage(tower: TowerData, enemy: Enemy, damage: float) -> float:
	if tower != null and tower.id == &"sapphire_lance" and enemy != null and enemy.has_charm_effect():
		return damage * 1.75
	return damage

func _refresh_enemy_execute_thresholds(_summary: String = "") -> void:
	for enemy in _active_enemies():
		enemy.set_execute_threshold(0.0 if enemy.data.is_boss else _get_execute_threshold_ratio(enemy))

func _on_enemy_reached_core(damage: float, enemy: Enemy) -> void:
	if game_finished:
		return
	metrics.record_enemy_breach(enemy.lane_index, enemy.data, enemy.spawn_context, enemy.get_instance_id())
	if enemy.spawn_context != null and enemy.spawn_context.is_artifact_elite():
		metrics.record_mechanic_event(&"artifact_elite_escaped")
		hud.show_notice("아티팩트 운반 정예가 퇴각했습니다.", 2.8)
	var challenge_damage := ChallengeRules.enemy_damage_multiplier(GameSession.selected_challenge_level)
	if enemy.data.is_boss:
		_resolve_boss_core_breach(damage, enemy, challenge_damage)
	else:
		_resolve_regular_core_breach(damage, challenge_damage, enemy)
	_apply_core_breach_followups(enemy)
	_present_core_breach(enemy)

func _resolve_boss_core_breach(damage: float, enemy: Enemy, challenge_damage: float) -> void:
	var is_final_boss := _is_final_boss(enemy.data)
	var boss_key := enemy.get_instance_id()
	var previous_breaches := int(boss_breach_counts.get(boss_key, 0))
	var first_breach_damage := BossBreachPolicy.breach_damage(damage, core.max_health, enemy.data.boss_tier, is_final_boss) * challenge_damage * loadout.get_core_breach_damage_multiplier()
	var breach_damage := first_breach_damage * BossBreachPolicy.repeat_damage_multiplier(previous_breaches, is_final_boss)
	boss_breach_counts[boss_key] = previous_breaches + 1
	metrics.record_mechanic_event(&"boss_core_breach_damage", breach_damage)
	if breach_damage + 0.0001 < first_breach_damage:
		metrics.record_mechanic_event(&"repeated_midboss_breach_damage_prevented", first_breach_damage - breach_damage)
	if is_final_boss:
		metrics.record_mechanic_event(&"final_boss_core_breach_damage", breach_damage)
	core.take_damage(breach_damage)
	if game_finished or not enemy.active:
		return
	var retreat_distance := battlefield.get_column_spacing() * BossBreachPolicy.retreat_columns(enemy.data.boss_tier, is_final_boss)
	enemy.retreat_from_core(retreat_distance, BossBreachPolicy.recovery_seconds(enemy.data.boss_tier, is_final_boss))
	hud.show_warning("%s 돌파 · %s 피해 %d · 전선 후퇴" % [ConceptService.term(&"boss"), ConceptService.term(&"core"), ceili(breach_damage)])

func _resolve_regular_core_breach(damage: float, challenge_damage: float, enemy: Enemy) -> void:
	var group_id := enemy.spawn_context.group_id if enemy != null and enemy.spawn_context != null else &""
	var result := regular_core_breach_service.resolve(
		damage, challenge_damage, loadout.get_core_breach_damage_multiplier(),
		core.current_health, core.max_health, group_id, final_boss_contest_started
	)
	var breach_damage := float(result.damage)
	if float(result.group_prevented_damage) > 0.0001:
		metrics.record_mechanic_event(&"regular_group_breach_damage_prevented", float(result.group_prevented_damage))
	if float(result.reserve_prevented_damage) > 0.0001:
		metrics.record_mechanic_event(&"pre_final_core_reserve_damage_prevented", float(result.reserve_prevented_damage))
	metrics.record_mechanic_event(&"regular_core_breach_damage", breach_damage)
	core.take_damage(breach_damage)

func _apply_core_breach_followups(enemy: Enemy) -> void:
	_apply_core_counterattack(enemy)
	if bool(loadout.get_core_branch_modifiers().get("rear_overcharge", false)):
		rear_overcharge_remaining = 3.0

func _present_core_breach(enemy: Enemy) -> void:
	AudioManager.play_core_hit(enemy.data.is_boss)
	var breach_effect_position := battlefield.get_core_goal_position(enemy.global_position.y)
	_show_burst_effect(breach_effect_position, Color("ff6577"), 76.0 if enemy.data.is_boss else 42.0, 0.85 if enemy.data.is_boss else 0.38, CombatEffectBudget.Priority.IMPORTANT if enemy.data.is_boss else CombatEffectBudget.Priority.STANDARD)
	if loadout.get_core_breach_damage_multiplier() < 1.0:
		_show_candidate_stamp_effect(breach_effect_position, &"jiane_dream_barrier", Color("69d9ff"), 70.0 if enemy.data.is_boss else 54.0, &"jiane_dream_barrier", 0.88, 0.68)
	screen_effects.shake(0.85 if enemy.data.is_boss else 0.28, 0.38 if enemy.data.is_boss else 0.16)
	screen_effects.flash(Color("ff435d"), 0.18 if enemy.data.is_boss else 0.07, 0.18)
	audience_stage.react(&"breach", Color("ff5366"), 1.0 if enemy.data.is_boss else 0.68, 1.5 if enemy.data.is_boss else 0.8)

func _on_boss_tree_exiting(enemy: Enemy) -> void:
	_refresh_boss_state()
	if game_finished or final_boss_reward_pending or enemy.data == null or not _is_final_boss(enemy.data):
		return
	# 최종보스가 사망 신호 없이 제거되는 예외 경로도 런을 무한 대기시키지 않는다.
	if enemy.active and enemy.current_health > 0.0:
		_finish_game.call_deferred(false)
	elif enemy.current_health <= 0.0:
		_finish_game.call_deferred(true)

func _on_enemy_died(value: float, death_position: Vector2, enemy_data: EnemyData, lane_index: int, source_enemy: Enemy) -> void:
	var plan := enemy_defeat_policy.build_plan(
		enemy_data,
		value,
		_is_final_boss(enemy_data),
		GameSession.selected_core_id == &"jade" and bool(loadout.get_candidate_modifier(&"soul_harvest", false)),
		core.skill_charge >= core.data.skill_charge_seconds and not core.is_skill_casting(),
		bool(loadout.get_cursor_branch_modifiers().get("reward_chain", false)),
		candidate_death_wave_runtime_service.is_resolving_hit()
	)
	if not bool(plan.get("valid", false)):
		return
	_record_enemy_defeat(enemy_data, death_position, value, lane_index, source_enemy)
	_queue_artifact_elite_reward(source_enemy)
	_resolve_enemy_death_effect(enemy_data, death_position, source_enemy)
	_resolve_faction_group_death_acceleration(source_enemy)
	_resolve_irelai_defeat_reactions(source_enemy, enemy_data, death_position, plan)
	_register_abyss_sacrifices(death_position)
	_grant_enemy_defeat_reward(enemy_data, death_position, value, plan, source_enemy)
	_apply_cursor_reward_chain(death_position, value, plan)
	var campaign_faction := _present_enemy_defeat(enemy_data, death_position)
	_spawn_splitter_children(death_position, plan)
	if bool(plan.settle_boss):
		_settle_boss_defeat(source_enemy, enemy_data, death_position, campaign_faction, plan)

func _resolve_enemy_death_effect(enemy_data: EnemyData, death_position: Vector2, source_enemy: Enemy = null) -> void:
	var result := enemy_death_effect_service.resolve(enemy_data, death_position, source_enemy, loadout.columns)
	if not bool(result.applied):
		return
	var targets: Array[String] = []
	targets.assign(result.targets)
	var mechanic_id := result.mechanic_id as StringName
	metrics.record_mechanic_event(mechanic_id, targets.size())
	metrics.record_defender_disable(enemy_data, source_enemy.spawn_context if is_instance_valid(source_enemy) else null, mechanic_id, float(result.duration), targets)
	_show_burst_effect(death_position, result.burst_color as Color, float(result.burst_radius), float(result.burst_duration))

func _resolve_faction_group_death_acceleration(source_enemy: Enemy) -> int:
	var accelerated := FactionGroupAccelerationResolver.resolve(source_enemy, _active_enemies())
	if accelerated > 0:
		metrics.record_mechanic_event(&"cult_group_death_acceleration", accelerated)
	return accelerated

func _record_enemy_defeat(enemy_data: EnemyData, death_position: Vector2, value: float, lane_index: int, source_enemy: Enemy = null) -> void:
	kill_count += 1
	metrics.record_kill(lane_index, enemy_data)
	metrics.record_enemy_defeat(lane_index, enemy_data, source_enemy.spawn_context if is_instance_valid(source_enemy) else null, source_enemy.last_death_cause if is_instance_valid(source_enemy) else Enemy.DEATH_CAUSE_DIRECT_KILL, source_enemy.get_instance_id() if is_instance_valid(source_enemy) else 0)
	SignalBus.enemy_died.emit(enemy_data, death_position, value)
	hud.update_kills(kill_count, boss_kill_count)

func _on_enemy_acceleration_changed(enemy: Enemy, acceleration_kind: StringName, stacks: int, speed_bonus: float, duration: float) -> void:
	if not is_instance_valid(enemy):
		return
	metrics.record_enemy_acceleration(enemy.data, enemy.spawn_context, acceleration_kind, stacks, speed_bonus, duration)

func _on_enemy_control_resolved(enemy: Enemy, control_type: StringName, accepted: bool, requested_effect: float, effective_effect: float, requested_duration: float, effective_duration: float) -> void:
	if is_instance_valid(enemy):
		metrics.record_enemy_control(enemy.data, control_type, accepted, requested_effect, effective_effect, requested_duration, effective_duration)

func _resolve_irelai_defeat_reactions(source_enemy: Enemy, enemy_data: EnemyData, death_position: Vector2, plan: Dictionary) -> void:
	_record_irelai_candidate_soul(plan)
	var curse_generation := irelai_guard_controller.consume_curse_on_defeat(source_enemy)
	if necromancy_controller == null or not is_instance_valid(necromancy_controller):
		return
	var spirit_gain := _resolve_irelai_spirit_gain(enemy_data, death_position, plan, curse_generation)
	_present_irelai_spirit_gain(enemy_data, death_position, spirit_gain)

func _record_irelai_candidate_soul(plan: Dictionary) -> void:
	if bool(plan.record_candidate_soul):
		var previous_souls := loadout.candidate_soul_stacks
		loadout.record_candidate_souls()
		if loadout.candidate_soul_stacks > previous_souls:
			metrics.record_mechanic_event(&"irelai_soul_gained")
			if necromancy_controller != null:
				necromancy_controller.set_soul_display(loadout.candidate_soul_stacks, int(loadout.get_candidate_modifier(&"soul_harvest_cap", 300)))

func _resolve_irelai_spirit_gain(enemy_data: EnemyData, death_position: Vector2, plan: Dictionary, curse_generation: int) -> int:
	if curse_generation > 0:
		return _add_irelai_curse_spirit(death_position, curse_generation)
	if bool(plan.allow_random_necromancy):
		return necromancy_controller.record_defeat(enemy_data, death_position)
	return 0

func _add_irelai_curse_spirit(death_position: Vector2, curse_generation: int) -> int:
	var maximum_generation := maxi(int(loadout.get_guard_modifier(&"guard_death_curse_max_generation", 3)), 1)
	var next_generation := IrelaiGuardController.next_curse_generation(curse_generation, maximum_generation)
	var curse_spirit_damage := maxf(float(loadout.get_guard_modifier(&"guard_curse_spirit_damage", 1.0)), 0.0)
	if not necromancy_controller.add_guaranteed_charge(death_position, curse_spirit_damage, next_generation):
		return 0
	candidate_death_wave_runtime_service.mark_curse_spirit_generated()
	metrics.record_mechanic_event(&"irelai_guard_curse_spirit", curse_generation)
	_show_pattern_effect(death_position, Color("b8ff8e"), 42.0 + curse_generation * 7.0, &"sigil", 0.55, 0.5)
	return 1

func _present_irelai_spirit_gain(enemy_data: EnemyData, death_position: Vector2, spirit_gain: int) -> void:
	if spirit_gain <= 0:
		return
	metrics.record_mechanic_event(&"necromancy_charges_gained", spirit_gain)
	_show_pattern_effect(death_position, Color("8df0ad"), 34.0 + spirit_gain * 8.0, &"sigil", 0.48, 0.48)
	if enemy_data.is_boss:
		hud.show_notice("%s 사령 고용 +%d · %d/%d" % [ConceptService.term(&"boss"), spirit_gain, necromancy_controller.charges, necromancy_controller.maximum_charges], 2.2)

func _register_abyss_sacrifices(death_position: Vector2) -> void:
	for column in loadout.columns:
		for row_index in column.row_towers.size():
			_register_abyss_sacrifice_for_column(column, row_index, death_position)

func _grant_enemy_defeat_reward(enemy_data: EnemyData, death_position: Vector2, value: float, plan: Dictionary, source_enemy: Enemy = null) -> void:
	if StringName(plan.reward_kind) == &"boss_burst":
		if bool(plan.stop_timeline):
			final_boss_reward_pending = true
			enemy_spawner.stop()
			for remaining_enemy in _active_enemies():
				if remaining_enemy.data != enemy_data:
					remaining_enemy.stop()
		experience_rewards.emit_boss_reward(death_position, value, enemy_data)
	else:
		var source_channel := source_enemy.spawn_context.channel if is_instance_valid(source_enemy) and source_enemy.spawn_context != null else &"base"
		experience_rewards.spawn_orb(death_position, value, Vector2.ZERO, 0.0, source_channel)

func _apply_cursor_reward_chain(death_position: Vector2, value: float, plan: Dictionary) -> void:
	if bool(plan.trigger_reward_chain):
		for nearby in spatial_index.query_radius(death_position, 135.0):
			nearby.take_damage(value * 1.8, &"cursor_reward", true)
		_show_pattern_effect(death_position, target_cursor.data.color, 135.0, &"zone", 0.55, 0.45)

func _present_enemy_defeat(enemy_data: EnemyData, death_position: Vector2) -> ElectionFactionData:
	var campaign_faction := _campaign_faction_for_enemy(enemy_data)
	if campaign_faction != null:
		_show_pattern_effect(
			death_position,
			campaign_faction.primary_color,
			maxf(enemy_data.radius * (2.7 if enemy_data.is_boss else 2.2), 34.0),
			&"campaign_exit",
			0.9 if enemy_data.is_boss else 0.48,
			0.9 if enemy_data.is_boss else 0.62,
			CombatEffectBudget.Priority.IMPORTANT if enemy_data.is_boss else -1
		)
	elif not enemy_data.is_boss:
		_show_burst_effect(death_position, enemy_data.body_color.lightened(0.25), maxf(enemy_data.radius * 2.1, 28.0), 0.26)
	return campaign_faction

func _spawn_splitter_children(death_position: Vector2, plan: Dictionary) -> void:
	var child_count := int(plan.splitter_child_count)
	if child_count <= 0:
		return
	var swarm := DataRegistry.get_enemy(SPLITTER_CHILD_ENEMY_ID)
	if swarm == null or swarm.id != SPLITTER_CHILD_ENEMY_ID:
		return
	var split_angles := [-0.58, 0.58]
	for child_index in mini(child_count, split_angles.size()):
		var split_position := battlefield.clamp_to_battlefield(death_position + Vector2.from_angle(float(split_angles[child_index])) * 26.0)
		_spawn_enemy(swarm, split_position, battlefield.world_to_lane(split_position), 0.8, 1.1)

func _settle_boss_defeat(source_enemy: Enemy, enemy_data: EnemyData, death_position: Vector2, campaign_faction: ElectionFactionData, plan: Dictionary) -> void:
	if campaign_faction == null:
		_show_burst_effect(death_position, enemy_data.body_color.lightened(0.25), 145.0, 1.0)
	screen_effects.shake(0.9, 0.48)
	screen_effects.flash(enemy_data.body_color, 0.18, 0.3)
	audience_stage.react(&"boss_defeated", enemy_data.body_color.lightened(0.32), 1.0, 2.0)
	_unregister_boss(source_enemy)
	boss_kill_count += 1
	hud.update_kills(kill_count, boss_kill_count)
	SignalBus.boss_defeated.emit(enemy_data)
	metrics.record_boss_kill(enemy_data.id)
	_handle_candidate_boss_reward(enemy_data)
	if not testing_mode:
		if not RunCheckpointService.confirm_checkpoint(_build_checkpoint_result(bool(plan.is_final_boss))):
			hud.show_notice("%s 체크포인트 저장에 실패했습니다. 이전 체크포인트는 유지됩니다." % ConceptService.term(&"boss"), 4.0)

func _on_enemy_damage_received(amount: float, source_type: StringName, enemy_data: EnemyData) -> void:
	metrics.record_damage_received(amount, source_type, enemy_data)

func _on_charmed_enemy_defeated(death_position: Vector2, enemy_data: EnemyData) -> void:
	var result := candidate_charm_echo_service.execute(
		death_position,
		enemy_data,
		core.data,
		Callable(loadout, "get_candidate_modifier"),
		Callable(spatial_index, "query_radius")
	)
	var spread_count := int(result.spread_count)
	for _spread_index in spread_count:
		metrics.record_mechanic_event(&"charm_echo_applied")
	if spread_count > 0:
		_show_pattern_effect(death_position, Color("ff78cf"), float(result.radius), &"sigil", 0.52, 0.48)

func _on_collection_requested(target_position: Vector2, radius: float) -> void:
	experience_rewards.collect_at(target_position, radius)

func _on_retainer_experience_collected(value: float) -> void:
	metrics.record_retainer_collection(value)

func _on_experience_orb_spawned(channel: StringName, raw_value: float) -> void:
	metrics.record_experience_drop(channel, raw_value)

func _on_experience_orb_collected(channel: StringName, raw_value: float, awarded_value: float) -> void:
	metrics.record_experience_collection(channel, raw_value, awarded_value)

func _on_boss_reward_completed(enemy_data: EnemyData) -> void:
	if _is_tutorial():
		return
	if _is_final_boss(enemy_data) and not game_finished:
		final_boss_reward_pending = false
		_finish_game(true)

func _is_final_boss(enemy_data: EnemyData) -> bool:
	return enemy_data != null and boss_plan != null and boss_plan.final_boss_id != &"" and enemy_data.id == boss_plan.final_boss_id

func _on_target_attack_requested(target_position: Vector2, cursor_data: CursorData) -> void:
	var context := _build_cursor_attack_context(target_position, cursor_data)
	if not bool(context.valid):
		return
	var candidates: Array[Enemy] = context.candidates
	if candidates.is_empty():
		_show_cursor_attack_effect(target_position, cursor_data, float(context.radius), null)
		return
	var primary_result := _resolve_cursor_primary_attack(context)
	var primary_target := primary_result.target as Enemy
	_show_cursor_attack_effect(target_position, cursor_data, float(context.radius), primary_target)
	var dealt := float(primary_result.dealt)
	dealt += _resolve_cursor_damage_followups(context, float(primary_result.damage))
	_trigger_cursor_support_followups(context)
	_finalize_cursor_attack(cursor_data, dealt)

func _build_cursor_attack_context(target_position: Vector2, cursor_data: CursorData) -> Dictionary:
	if not _can_build_cursor_attack_context():
		return {"valid": false}
	cursor_attack_count += 1
	var modifiers := loadout.get_cursor_branch_modifiers()
	var damage := _calculate_cursor_attack_damage(cursor_data, modifiers)
	return _compose_cursor_attack_context(target_position, cursor_data, modifiers, damage)

func _can_build_cursor_attack_context() -> bool:
	return not game_finished and (retainer_reconstruction_component == null or not is_instance_valid(retainer_reconstruction_component) or retainer_reconstruction_component.can_attack())

func _calculate_cursor_attack_damage(cursor_data: CursorData, modifiers: Dictionary) -> float:
	var damage := cursor_data.damage * target_cursor.stat_multiplier
	if vanguard_squad_component != null and is_instance_valid(vanguard_squad_component):
		damage *= vanguard_squad_component.get_damage_multiplier()
	if modifiers.has("stationary_damage_cap"):
		damage *= 1.0 + target_cursor.get_stationary_ratio() * float(modifiers.stationary_damage_cap)
	return damage

func _compose_cursor_attack_context(target_position: Vector2, cursor_data: CursorData, modifiers: Dictionary, damage: float) -> Dictionary:
	var radius := target_cursor.get_effective_attack_radius()
	var knockback := target_cursor.get_effective_knockback()
	var candidates: Array[Enemy] = spatial_index.query_radius(target_position, radius)
	var context := {
		"valid": true,
		"target_position": target_position,
		"cursor_data": cursor_data,
		"modifiers": modifiers,
		"damage": damage,
		"radius": radius,
		"knockback": knockback,
		"candidates": candidates,
	}
	context.retainer_plan = retainer_combat_controller.build_attack_plan(cursor_attack_count) if retainer_combat_controller != null and is_instance_valid(retainer_combat_controller) else {}
	(context.retainer_plan as Dictionary).attack_position = target_position
	(context.retainer_plan as Dictionary).attack_radius = radius
	return context

func _resolve_cursor_primary_attack(context: Dictionary) -> Dictionary:
	var cursor_data: CursorData = context.cursor_data
	var candidates: Array[Enemy] = context.candidates
	var retainer_plan: Dictionary = context.get("retainer_plan", {})
	return cursor_attack_execution_service.execute_primary(
		cursor_data.attack_type,
		candidates,
		context.target_position,
		float(context.damage),
		float(context.radius),
		float(context.knockback),
		context.modifiers,
		retainer_plan,
		Callable(self, "_closest_to_position"),
		Callable(self, "_cursor_retainer_damage_multiplier"),
		Callable(self, "_resolve_cursor_hit"),
		Callable(self, "_cursor_retainer_knockback_multiplier"),
		Callable(self, "_record_cursor_boosted_knockback"),
		Callable(self, "_try_break_boss_lock")
	)

func _cursor_retainer_damage_multiplier(enemy: Enemy, target_position: Vector2, radius: float, retainer_plan: Dictionary) -> float:
	if retainer_combat_controller == null or not is_instance_valid(retainer_combat_controller):
		return 1.0
	return retainer_combat_controller.damage_multiplier_for(enemy, target_position, radius, retainer_plan)

func _resolve_cursor_hit(enemy: Enemy, damage: float, is_area: bool, modifiers: Dictionary, retainer_plan: Dictionary = {}) -> float:
	var hit_result := cursor_hit_effect_service.execute(
		enemy, damage, is_area, modifiers,
		Callable(self, "_apply_cursor_damage"),
		Callable(self, "_apply_cursor_followup_damage"),
		Callable(spatial_index, "query_radius")
	)
	var retainer_effects := {"statuses": [] as Array[StringName], "charm_rolls": 0, "fear_spread": 0}
	if retainer_combat_controller != null and is_instance_valid(retainer_combat_controller):
		retainer_effects = retainer_combat_controller.apply_on_hit(enemy, retainer_plan)
		for status_id in retainer_effects.statuses as Array[StringName]:
			metrics.record_status_application(status_id)
			metrics.record_mechanic_event(StringName("retainer_%s_applied" % status_id))
			if status_id in [&"slow", &"fear", &"charm"]:
				metrics.record_retainer_control()
		if int(retainer_effects.charm_rolls) > 0:
			metrics.record_mechanic_event(&"given_charm_roll", int(retainer_effects.charm_rolls))
	if int(retainer_effects.get("fear_spread", 0)) > 0:
		metrics.record_mechanic_event(&"jeomujeom_fear_spread", int(retainer_effects.fear_spread))
	return float(hit_result.primary_damage)

func _cursor_retainer_knockback_multiplier(enemy: Enemy, retainer_plan: Dictionary) -> float:
	if retainer_combat_controller == null or not is_instance_valid(retainer_combat_controller):
		return 1.0
	return retainer_combat_controller.knockback_multiplier_for(enemy, Vector2(retainer_plan.get("attack_position", enemy.global_position)), float(retainer_plan.get("attack_radius", 0.0)), retainer_plan)

func _record_cursor_boosted_knockback() -> void:
	metrics.record_retainer_control()
	metrics.record_mechanic_event(&"given_edge_knockback")

func _resolve_cursor_damage_followups(context: Dictionary, damage: float) -> float:
	var cursor_data: CursorData = context.cursor_data
	var retainer_plan: Dictionary = context.get("retainer_plan", {})
	return cursor_attack_execution_service.execute_damage_followups(
		context.target_position,
		damage,
		float(context.radius),
		target_cursor.get_stationary_ratio(),
		context.modifiers,
		retainer_plan,
		Callable(spatial_index, "query_segment"),
		Callable(spatial_index, "query_radius"),
		Callable(self, "_apply_cursor_followup_damage"),
		Callable(self, "_present_cursor_damage_followup").bind(cursor_data)
	)

func _apply_cursor_followup_damage(enemy: Enemy, damage: float, source: StringName) -> float:
	return enemy.take_damage(damage, source, true)

func _present_cursor_damage_followup(event: Dictionary, cursor_data: CursorData) -> void:
	match StringName(event.type):
		&"final_slash":
			metrics.record_mechanic_event(&"kanda_final_slash")
			if int(event.target_count) > 0:
				metrics.record_mechanic_event(&"kanda_final_slash_targets", int(event.target_count))
			_show_effect(event.start, event.finish, cursor_data.color.lightened(0.25), float(event.radius), 0.42)
		&"split_zone":
			_show_pattern_effect(event.position, cursor_data.color, float(event.radius), &"zone", 0.4, 0.36)
		&"charged_explosion":
			_show_burst_effect(event.position, cursor_data.color, float(event.radius), 0.72)
		&"horse_area":
			_show_pattern_effect(event.position, cursor_data.color, float(event.radius), &"shockwave", 0.55, 0.4)

func _trigger_cursor_support_followups(context: Dictionary) -> void:
	var target_position: Vector2 = context.target_position
	var modifiers: Dictionary = context.modifiers
	var candidates: Array[Enemy] = context.candidates
	if int(modifiers.get("synchronized_volley", 0)) > 0 and cursor_attack_count % int(modifiers.synchronized_volley) == 0:
		_trigger_synchronized_volley()
	var core_modifiers := loadout.get_core_branch_modifiers()
	if core_modifiers.has("core_follow_shot"):
		var follow_target := _closest_to_position(candidates, target_position)
		if follow_target != null:
			follow_target.take_damage(core.data.damage * core.damage_multiplier * float(core_modifiers.core_follow_shot), &"core_follow")
			_show_effect(core.global_position, follow_target.global_position, core.data.color, 0.0, 0.2)

func _finalize_cursor_attack(cursor_data: CursorData, dealt: float) -> void:
	metrics.record_cursor_damage(dealt)
	if dealt > 0.0:
		var cursor_impact := 0.5 if cursor_data.attack_type == &"heavy" else 0.22
		AudioManager.play_impact(cursor_data.attack_type == &"heavy")
		screen_effects.shake(cursor_impact, 0.13 + cursor_impact * 0.12)

func _apply_cursor_damage(enemy: Enemy, damage: float, is_area: bool) -> float:
	var modifiers := loadout.get_cursor_branch_modifiers()
	var adjusted_damage := damage * (float(modifiers.get("boss_damage", 1.0)) if enemy.data.is_boss else 1.0)
	var dealt := 0.0
	if vanguard_squad_component != null and is_instance_valid(vanguard_squad_component):
		var execution := judgment_service.resolve(enemy, adjusted_damage, &"vanguard_cursor", vanguard_squad_component.execution_health_ratio)
		_record_judgment_metrics(execution, enemy.data.is_boss)
		dealt = float(execution.damage)
		if bool(execution.executed) and vanguard_squad_component.record_execution():
			metrics.record_mechanic_event(&"vanguard_execution")
			_show_pattern_effect(enemy.global_position, target_cursor.data.color, 52.0, &"slash", 0.9, 0.46)
			screen_effects.shake(0.48, 0.18)
	else:
		dealt = enemy.take_damage(adjusted_damage, &"cursor", is_area)
	if enemy.data.is_boss and modifiers.has("core_charge_on_boss"):
		core.add_skill_charge(float(modifiers.core_charge_on_boss))
		_show_pattern_effect(enemy.global_position, target_cursor.data.color, 42.0, &"slash", 0.7, 0.36)
	return dealt

func _show_cursor_attack_effect(target_position: Vector2, cursor_data: CursorData, radius: float, primary_target: Enemy) -> void:
	var impact_position := primary_target.global_position if is_instance_valid(primary_target) else target_position
	match cursor_data.id:
		&"iron":
			_show_iron_cursor_attack_effect(target_position, cursor_data, radius)
		&"silver":
			_show_silver_cursor_attack_effect(target_position, impact_position, cursor_data, radius, primary_target)
		&"gold":
			_show_gold_cursor_attack_effect(target_position, cursor_data, radius)
		&"platinum":
			_show_platinum_cursor_attack_effect(target_position, impact_position, cursor_data, radius, primary_target)
		&"vanguard":
			_show_vanguard_cursor_attack_effect(target_position, impact_position, cursor_data, radius, primary_target)
		_:
			_show_impact_effect(impact_position, cursor_data.color, radius)

func _show_iron_cursor_attack_effect(target_position: Vector2, cursor_data: CursorData, radius: float) -> void:
	_show_pattern_effect(target_position, cursor_data.color, radius, &"cursor_iron", 0.72, 0.5)
	_show_pattern_effect(target_position, cursor_data.color.lightened(0.18), radius * 0.9, &"shockwave", 0.58, 0.42)

func _show_silver_cursor_attack_effect(target_position: Vector2, impact_position: Vector2, cursor_data: CursorData, radius: float, primary_target: Enemy) -> void:
	if is_instance_valid(primary_target):
		_show_effect(target_position, impact_position, cursor_data.color.lightened(0.35), 0.0, 0.42)
	_show_pattern_effect(impact_position, cursor_data.color, maxf(radius * 0.72, 28.0), &"cursor_silver", 0.78, 0.34)

func _show_gold_cursor_attack_effect(target_position: Vector2, cursor_data: CursorData, radius: float) -> void:
	_show_pattern_effect(target_position, cursor_data.color, radius, &"zone", 0.62, 0.78)
	_show_pattern_effect(target_position, cursor_data.color.lightened(0.15), radius * 0.82, &"cursor_gold", 0.68, 0.66)

func _show_platinum_cursor_attack_effect(target_position: Vector2, impact_position: Vector2, cursor_data: CursorData, radius: float, primary_target: Enemy) -> void:
	if is_instance_valid(primary_target):
		_show_effect(target_position, impact_position, cursor_data.color.lightened(0.48), 0.0, 0.5)
	_show_pattern_effect(impact_position, cursor_data.color, maxf(radius, 44.0), &"cursor_platinum", 0.95, 0.5)
	_show_pattern_effect(impact_position, cursor_data.color.lightened(0.24), maxf(radius * 0.72, 36.0), &"slash", 0.72, 0.38)

func _show_vanguard_cursor_attack_effect(target_position: Vector2, impact_position: Vector2, cursor_data: CursorData, radius: float, primary_target: Enemy) -> void:
	if is_instance_valid(primary_target):
		_show_effect(target_position, impact_position, cursor_data.color.lightened(0.34), 0.0, 0.48)
	_show_pattern_effect(impact_position, cursor_data.color, maxf(radius, 48.0), &"cursor_vanguard", 0.9, 0.52)
	_show_pattern_effect(impact_position, cursor_data.color.lightened(0.22), maxf(radius * 0.8, 38.0), &"slash", 0.76, 0.4)

func _trigger_synchronized_volley() -> void:
	for column in loadout.columns:
		if not column.is_occupied() or column.disabled_remaining > 0.0:
			continue
		for row_index in column.row_towers.size():
			if column.get_tower_data(row_index) != null:
				_on_tower_attack_requested(column, row_index)
	hud.show_notice("집중 지휘 · 편대 동시 사격")

func _apply_core_counterattack(attacker: Enemy) -> void:
	var modifiers := loadout.get_core_branch_modifiers()
	var result := core_counterattack_service.execute(
		attacker, core.data.damage, core.damage_multiplier, modifiers,
		func(center: Vector2, radius: float) -> Array[Enemy]: return spatial_index.query_radius(center, radius)
	)
	if not bool(result.applied):
		return
	_show_effect(core.global_position, result.impact_position as Vector2, core.data.color, 0.0, 0.35)

func _refresh_specialization_tower_bonuses() -> void:
	var cursor_modifiers := loadout.get_cursor_branch_modifiers()
	for column in loadout.columns:
		var speed_sources: Array = [loadout.get_tower_speed_multiplier()]
		if column.is_guard_formation:
			speed_sources.append(loadout.get_guard_speed_multiplier())
		if cursor_modifiers.has("nearby_tower_speed") and absf(column.global_position.x - target_cursor.global_position.x) <= target_cursor.get_effective_attack_radius():
			var relay_speed := float(cursor_modifiers.nearby_tower_speed)
			if bool(cursor_modifiers.get("stationary_relay", false)):
				relay_speed = lerpf(1.14, relay_speed, target_cursor.get_stationary_ratio())
			speed_sources.append(relay_speed)
		if rear_overcharge_remaining > 0.0 and column.column_index <= 1:
			speed_sources.append(1.45)
		column.global_speed_multiplier = CombatModifierResolver.additive_multiplier(speed_sources)

func _get_specialization_tower_damage_multiplier(column: TowerColumn) -> float:
	var modifiers := loadout.get_core_branch_modifiers()
	var result := loadout.get_guard_damage_multiplier() if column.is_guard_formation else 1.0
	if modifiers.has("rear_tower_damage") and column.column_index <= 1:
		result *= float(modifiers.rear_tower_damage)
	if modifiers.has("cursor_tower_damage") and absf(column.global_position.x - target_cursor.global_position.x) <= target_cursor.get_effective_attack_radius():
		result *= float(modifiers.cursor_tower_damage)
	if modifiers.has("fortress_aura") and column.column_index <= 1:
		result *= float(modifiers.fortress_aura)
	return result

func _try_break_boss_lock(enemy: Enemy) -> void:
	if _is_final_boss(enemy.data) and enemy.final_phase == 2:
		loadout.clear_disabled_columns()
		hud.show_notice("약점 타격 · 비활성화 해제")

func _on_core_attack_requested(core_data: CoreData) -> void:
	var active_enemies := _active_enemies()
	if active_enemies.is_empty():
		return
	var context := _build_core_attack_context(core_data, active_enemies)
	if bool(context.plan.trigger_abyss_presence) and _trigger_candidate_abyss_presence(active_enemies, float(context.damage), context.plan):
		core_attack_count += 1
		return
	var enemies: Array[Enemy] = context.enemies
	if enemies.is_empty():
		return
	core_attack_count += 1
	var damage := core_attack_execution_service.resolve_attack_damage(float(context.damage), context.modifiers, core_attack_count)
	if bool(context.plan.replace_with_spirit):
		var released_spirit_damage := _release_spirit_attacks(core.global_position, damage, 1)
		if released_spirit_damage > 0.0:
			AudioManager.play_impact(false)
		return
	var result := _resolve_core_attack_pattern(core_data, enemies, context.plan, context.modifiers, damage)
	var hit_targets: Array[Enemy] = result.hit_targets
	if hit_targets.is_empty():
		return
	_finalize_core_attack(core_data, hit_targets, damage, float(result.lucky_roll), context.modifiers)
	_present_core_attack(core_data, hit_targets, context.plan, context.modifiers, float(context.attack_range_multiplier))
	AudioManager.play_impact(core_data.attack_type == &"radial")

func _build_core_attack_context(core_data: CoreData, active_enemies: Array[Enemy]) -> Dictionary:
	var plan := candidate_core_attack_policy.build_plan(
		core_data,
		core.data,
		loadout.get_candidate_modifiers(),
		loadout.is_candidate_growth_enabled(),
		loadout.is_candidate_abyss_presence_ready()
	)
	var attack_range_multiplier := float(plan.attack_range_multiplier)
	return {
		"plan": plan,
		"attack_range_multiplier": attack_range_multiplier,
		"enemies": active_enemies.filter(func(enemy: Enemy) -> bool: return enemy.global_position.distance_to(core.global_position) <= core_data.attack_range * attack_range_multiplier),
		"modifiers": loadout.get_core_branch_modifiers(),
		"damage": core_data.damage * core.damage_multiplier,
	}

func _resolve_core_attack_pattern(core_data: CoreData, enemies: Array[Enemy], plan: Dictionary, modifiers: Dictionary, damage: float) -> Dictionary:
	return core_attack_execution_service.execute(
		core_data.attack_type,
		enemies,
		core.global_position,
		target_cursor.global_position,
		battlefield.get_battle_rect().end.x,
		core_data.attack_range,
		plan,
		modifiers,
		damage,
		core_attack_count,
		Callable(self, "_closest_to_core"),
		Callable(self, "_apply_core_attack_hit").bind(core_data)
	)

func _apply_core_attack_hit(target: Enemy, hit_damage: float, source: StringName, core_data: CoreData) -> void:
	_resolve_core_hit(target, hit_damage, source, false, 1, 0.0, core_data)

func _finalize_core_attack(core_data: CoreData, hit_targets: Array[Enemy], damage: float, lucky_roll: float, modifiers: Dictionary) -> void:
	if core_data == core.data:
		core_attack_execution_service.execute_specializations(
			hit_targets.back(),
			damage,
			lucky_roll,
			modifiers,
			Callable(self, "_active_enemies"),
			Callable(spatial_index, "query_radius"),
			Callable(targeting_service, "closest_other"),
			Callable(self, "_apply_core_specialization_hit"),
			Callable(self, "_present_core_specialization_event")
		)
	if core_data.necromancy_profile != null:
		_release_spirit_attacks(core.global_position, damage, 1)

func _apply_core_specialization_hit(target: Enemy, damage: float, source: StringName) -> float:
	return target.take_damage(damage, source, true)

func _present_core_specialization_event(event: Dictionary) -> void:
	match StringName(event.type):
		&"link":
			_show_effect(event.from, event.to, core.data.color, 0.0, float(event.duration))
		&"burst":
			_show_burst_effect(event.position, core.data.color, float(event.radius), float(event.strength))

func _present_core_attack(core_data: CoreData, hit_targets: Array[Enemy], plan: Dictionary, modifiers: Dictionary, attack_range_multiplier: float) -> void:
	match core_data.attack_type:
		&"pierce":
			if bool(plan.charm_radial):
				for target in hit_targets:
					_show_effect(core.global_position, target.global_position, core_data.color, 0.0, 0.32)
				_show_pattern_effect(core.global_position, core_data.color, 210.0, &"sigil", 0.6, 0.42)
			else:
				var coordinate_rail := bool(modifiers.get("coordinate_rail", false))
				var beam_start := core.global_position if coordinate_rail else Vector2(core.global_position.x, target_cursor.global_position.y)
				var beam_end := target_cursor.global_position if coordinate_rail else Vector2(battlefield.get_battle_rect().end.x, target_cursor.global_position.y)
				_show_effect(beam_start, beam_end, core_data.color, 0.0, 0.42)
			_show_target_impacts(hit_targets, core_data.color, 0.2)
		&"radial":
			_show_burst_effect(core.global_position, core_data.color, core_data.attack_range * attack_range_multiplier, 0.5)
			_show_target_impacts(hit_targets, core_data.color, 0.16)
		_:
			var visual_target := hit_targets[0]
			_show_effect(core.global_position, visual_target.global_position, core_data.color, 0.0, 0.22)
			_show_impact_effect(visual_target.global_position, core_data.color, 0.0, 0.18)

func _trigger_candidate_abyss_presence(enemies: Array[Enemy], damage: float, attack_plan: Dictionary) -> bool:
	var result := core_attack_execution_service.execute_abyss_presence(
		enemies,
		core.global_position,
		core.data.attack_range,
		damage,
		attack_plan,
		Callable(loadout, "consume_candidate_abyss_presence"),
		Callable(self, "_apply_candidate_abyss_presence_hit")
	)
	if not bool(result.triggered):
		return false
	var targets: Array[Enemy] = result.targets
	var radius := float(result.radius)
	metrics.record_mechanic_event(&"kasuha_abyss_presence_attack")
	_show_pattern_effect(core.global_position, core.data.color, radius, &"shockwave", 0.9, 0.7, CombatEffectBudget.Priority.IMPORTANT)
	_show_target_impacts(targets, core.data.color, 0.66)
	screen_effects.shake(0.72, 0.42)
	AudioManager.play_impact(true)
	return true

func _apply_candidate_abyss_presence_hit(target: Enemy, hit_damage: float, source: StringName) -> void:
	_resolve_core_hit(target, hit_damage, source)

func _on_core_skill_cast_started(core_data: CoreData, duration: float) -> void:
	var candidate_plan := _candidate_core_skill_plan(core_data)
	var effect := _create_combat_effect(CombatEffectBudget.Priority.CRITICAL)
	if effect != null:
		effect.setup_core_cast(core.global_position, target_cursor.global_position, battlefield.get_battle_rect(), core_data.color, core_data.skill_type, duration)
	if retainer_reconstruction_component != null and is_instance_valid(retainer_reconstruction_component) and retainer_reconstruction_component.can_attack():
		var combo_profile := retainer_reconstruction_component.profile
		_show_effect(core.global_position, target_cursor.global_position, target_cursor.data.color, combo_profile.path_half_width, duration)
	if bool(candidate_plan.reaper_summon):
		_summon_judaginda_reaper(duration)
	hud.show_notice("%s 시전 · %.1f초" % [_core_skill_title(core_data), duration], duration)
	audience_stage.react(&"skill_cast", core_data.color, 0.72, duration)
	screen_effects.flash(core_data.color, 0.07, minf(duration, 0.45))
	AudioManager.play_ui()

func _on_core_skill_requested(core_data: CoreData) -> void:
	var enemies := _active_enemies()
	var modifiers := loadout.get_core_branch_modifiers()
	var candidate_plan := _candidate_core_skill_plan(core_data)
	var candidate_summon_active := bool(candidate_plan.mass_summon)
	var irelai_death_wave := bool(candidate_plan.death_wave)
	var damage := core_data.skill_damage * loadout.get_core_skill_damage_multiplier()
	var extension_result := core_skill_execution_service.execute_candidate_extensions(
		core_data,
		candidate_plan,
		damage,
		Callable(self, "_execute_jiane_core_skill"),
		Callable(self, "_spawn_candidate_abyss_swarm"),
		Callable(self, "_trigger_guard_core_active_abilities"),
		Callable(self, "_launch_irelai_death_wave")
	)
	var guard_charm_extension := float(extension_result.guard_charm_extension)
	# 합동 돌격은 후보 스킬의 넉백·처치로 대형이 흩어지기 전 후보–심복 선분을 판정한다.
	_trigger_retainer_combo()
	_trigger_vanguard_reaper_circle()
	var result := _resolve_core_skill_pattern(core_data, enemies, modifiers, damage, guard_charm_extension, candidate_summon_active, irelai_death_wave)
	var hit_targets: Array[Enemy] = result.hit_targets
	var barrage_positions: Array[Vector2] = result.barrage_positions
	if bool(candidate_plan.uses_native_necromancy) and necromancy_controller != null:
		_release_spirit_attacks(core.global_position, damage * 0.85, necromancy_controller.charges)
	hud.show_notice("%s 발동!" % _core_skill_title(core_data), 2.2)
	audience_stage.react(&"skill_release", core_data.color.lightened(0.26), 1.0, 1.8)
	_present_core_skill_pattern(core_data, hit_targets, barrage_positions, candidate_summon_active, irelai_death_wave)
	screen_effects.flash(core_data.color, 0.24, 0.36)
	AudioManager.play_skill(core_data.id)
	if _is_tutorial() and tutorial_director != null and tutorial_director.record_skill_cast():
		if is_instance_valid(current_boss) and current_boss.active:
			current_boss.take_damage(current_boss.current_health + 1.0, &"tutorial_candidate_skill", true)

func _trigger_vanguard_reaper_circle() -> void:
	var modifiers := loadout.get_cursor_branch_modifiers()
	var result := vanguard_reaper_execution_service.execute(
		vanguard_squad_component, target_cursor.data.damage, target_cursor.stat_multiplier,
		target_cursor.global_position, target_cursor.get_effective_attack_radius(), modifiers,
		func(center: Vector2, radius: float) -> Array[Enemy]: return spatial_index.query_radius(center, radius),
		func(enemy: Enemy, damage: float, source: StringName, execute_ratio: float) -> Dictionary: return judgment_service.resolve(enemy, damage, source, execute_ratio)
	)
	if not bool(result.applied):
		return
	metrics.record_cursor_damage(float(result.dealt))
	metrics.record_mechanic_event(&"vanguard_reaper_snapshot", int(result.snapshot))
	_show_pattern_effect(target_cursor.global_position, target_cursor.data.color, float(result.radius), &"sigil", 1.0, 0.85, CombatEffectBudget.Priority.IMPORTANT)
	screen_effects.shake(0.8, 0.4)

func _execute_jiane_core_skill(core_data: CoreData, grants_stage_buff: bool) -> float:
	var activation_result := candidate_charm_stage_controller.activate_candidate_skill(
		core_data,
		grants_stage_buff,
		loadout,
		Callable(guard_ability_controller, "consume_candidate_active"),
		func(devotion_result: Dictionary) -> void:
			var consumed_devotion := int(devotion_result.get("consumed_stacks", 0))
			if consumed_devotion <= 0:
				return
			var extension := float(devotion_result.get("extension", 0.0))
			metrics.record_mechanic_event(&"jiane_guard_devotion_consumed", consumed_devotion)
			metrics.record_mechanic_event(&"jiane_guard_devotion_extension", extension)
			hud.update_build(loadout.get_build_summary())
			hud.show_notice("헌신 %d 소모 · 매혹 +%.1f초" % [consumed_devotion, extension], 1.8)
	)
	if not bool(activation_result.applied):
		return 0.0
	_apply_runtime_loadout_stats()
	_refresh_specialization_tower_bonuses()
	metrics.record_mechanic_event(&"charm_zone_activated")
	var stage_duration := float(activation_result.stage_duration)
	if bool(activation_result.grants_stage_buff):
		metrics.record_mechanic_event(&"charm_stage_activated")
		hud.show_notice("사랑의 무대 · 지속 환혹 + 전군 공격 강화", stage_duration)
	else:
		hud.show_notice("광역 환혹 무대 · 지속 환혹", stage_duration)
	return float(activation_result.extension)

func _resolve_core_skill_pattern(core_data: CoreData, enemies: Array[Enemy], modifiers: Dictionary, damage: float, guard_charm_extension: float, candidate_summon_active: bool, irelai_death_wave: bool) -> Dictionary:
	var sentence_stacks := core_data.judgment_profile.required_sentence_stacks if core_data.judgment_profile != null else 1
	var result := core_skill_execution_service.execute(
		core_data.skill_type,
		enemies,
		target_cursor.global_position,
		damage,
		modifiers,
		float(loadout.get_candidate_modifier(&"core_skill_range", 1.0)),
		guard_charm_extension,
		candidate_summon_active,
		irelai_death_wave,
		sentence_stacks,
		Callable(self, "_apply_core_skill_hit"),
		Callable(self, "_apply_core_wall_bonus_hit"),
		Callable(self, "_apply_core_barrage_hit"),
		Callable(self, "_apply_core_barrage_highroll")
	)
	if core_data.id == &"obsidian" and is_instance_valid(judaginda_reaper_summon):
		if core_data.skill_type == &"beam":
			judaginda_reaper_summon.strike(target_cursor.global_position)
			metrics.record_mechanic_event(&"judaginda_reaper_strike")
	return result

func _apply_core_skill_hit(target: Enemy, hit_damage: float, source: StringName, guaranteed_charm: bool, sentence_stacks: int, charm_extension: float) -> void:
	_resolve_core_hit(target, hit_damage, source, guaranteed_charm, sentence_stacks, charm_extension)

func _apply_core_wall_bonus_hit(target: Enemy, hit_damage: float) -> void:
	target.take_damage(hit_damage, &"core_wall", true)

func _apply_core_barrage_hit(target: Enemy, hit_damage: float) -> void:
	target.take_damage(hit_damage, &"core")

func _apply_core_barrage_highroll(barrage_target: Enemy, splash_damage: float) -> void:
	for nearby in spatial_index.query_radius(barrage_target.global_position, 82.0):
		if nearby != barrage_target:
			nearby.take_damage(splash_damage, &"core_highroll", true)

func _present_core_skill_pattern(core_data: CoreData, hit_targets: Array[Enemy], barrage_positions: Array[Vector2], candidate_summon_active: bool, irelai_death_wave: bool) -> void:
	match core_data.skill_type:
		&"beam":
			_present_beam_core_skill(core_data, hit_targets)
		&"radial":
			_present_radial_core_skill(core_data, hit_targets)
		&"wall":
			_present_wall_core_skill(core_data, hit_targets, candidate_summon_active)
		&"barrage":
			_present_barrage_core_skill(core_data, barrage_positions, irelai_death_wave)

func _present_beam_core_skill(core_data: CoreData, hit_targets: Array[Enemy]) -> void:
	var beam_start := Vector2(core.global_position.x, target_cursor.global_position.y)
	var beam_end := Vector2(battlefield.get_battle_rect().end.x, target_cursor.global_position.y)
	for offset in [-14.0, 0.0, 14.0]:
		_show_effect(beam_start + Vector2(0.0, offset), beam_end + Vector2(0.0, offset), core_data.color, 110.0, 1.0)
	_show_pattern_effect(target_cursor.global_position, core_data.color, 118.0, &"sigil", 1.0, 0.72)
	_show_target_impacts(hit_targets, core_data.color, 0.75)
	screen_effects.shake(0.92, 0.52)

func _present_radial_core_skill(core_data: CoreData, hit_targets: Array[Enemy]) -> void:
	_show_burst_effect(core.global_position, core_data.color, battlefield.get_battle_rect().size.length() * 0.72, 1.0)
	_show_pattern_effect(core.global_position, core_data.color, 360.0, &"shockwave", 1.0, 0.82)
	_show_target_impacts(hit_targets, core_data.color, 0.52)
	screen_effects.shake(1.0, 0.62)

func _present_wall_core_skill(core_data: CoreData, hit_targets: Array[Enemy], candidate_summon_active: bool) -> void:
	if candidate_summon_active:
		_show_burst_effect(core.global_position, core_data.color, battlefield.get_battle_rect().size.length() * 0.72, 0.85)
		_show_pattern_effect(core.global_position, core_data.color, 380.0, &"sigil", 1.0, 1.05, CombatEffectBudget.Priority.IMPORTANT)
	else:
		var wall_rect := battlefield.get_battle_rect()
		var candidate_skill_range := float(loadout.get_candidate_modifier(&"core_skill_range", 1.0))
		for offset in [-112.0 * candidate_skill_range, 0.0, 112.0 * candidate_skill_range]:
			_show_effect(Vector2(wall_rect.position.x, target_cursor.global_position.y + offset), Vector2(wall_rect.end.x, target_cursor.global_position.y + offset), core_data.color, 42.0, 0.95)
		_show_pattern_effect(target_cursor.global_position, core_data.color, 190.0 * candidate_skill_range, &"zone", 1.0, 1.15)
		_show_target_impacts(hit_targets, core_data.color, 0.62)
	screen_effects.shake(0.78, 0.7)

func _present_barrage_core_skill(core_data: CoreData, barrage_positions: Array[Vector2], irelai_death_wave: bool) -> void:
	if irelai_death_wave:
		_show_pattern_effect(core.global_position, core_data.color, 150.0, &"shockwave", 0.9, 0.72, CombatEffectBudget.Priority.IMPORTANT)
	else:
		for impact_index in barrage_positions.size():
			var impact_position := barrage_positions[impact_index]
			_show_effect(core.global_position, impact_position, core_data.color, 0.0, 0.48 + float(impact_index % 3) * 0.12)
			_show_pattern_effect(impact_position, core_data.color, 72.0 + float(impact_index % 2) * 18.0, &"sigil", 0.82, 0.68)
			_show_burst_effect(impact_position, core_data.color, 78.0, 0.7)
	screen_effects.shake(0.88, 0.58)

func _trigger_retainer_combo() -> Dictionary:
	var profile := _eligible_retainer_combo_profile()
	if profile == null:
		return {"damage": 0.0, "targets": [] as Array[Enemy]}
	var result := _resolve_retainer_combo(profile)
	retainer_reconstruction_component.begin_reconstruction()
	_present_retainer_combo(profile, result)
	_record_retainer_combo(result)
	return result

func _eligible_retainer_combo_profile() -> ComboAttackProfileData:
	if retainer_reconstruction_component == null or not is_instance_valid(retainer_reconstruction_component) or not retainer_reconstruction_component.can_attack():
		return null
	var profile := retainer_reconstruction_component.profile
	if profile == null or profile.combo_type != &"line_charge":
		return null
	return profile

func _resolve_retainer_combo(profile: ComboAttackProfileData) -> Dictionary:
	var cursor_modifiers := loadout.get_cursor_branch_modifiers()
	return combo_attack_service.resolve_line_charge(
		profile,
		core.global_position,
		target_cursor.global_position,
		_active_enemies(),
		target_cursor.data.damage * target_cursor.stat_multiplier,
		float(cursor_modifiers.get("combo_damage", 1.0)),
		float(cursor_modifiers.get("combo_knockback", 1.0)),
		float(cursor_modifiers.get("combo_path_width", 1.0))
	)

func _present_retainer_combo(profile: ComboAttackProfileData, result: Dictionary) -> void:
	_show_effect(core.global_position, target_cursor.global_position, target_cursor.data.color, profile.path_half_width, 0.58)
	_show_pattern_effect(target_cursor.global_position, target_cursor.data.color, 68.0, &"slash", 0.95, 0.55)
	_show_target_impacts(result.targets as Array[Enemy], target_cursor.data.color, 0.62)

func _record_retainer_combo(result: Dictionary) -> void:
	metrics.record_cursor_damage(float(result.damage))
	metrics.record_mechanic_event(&"combo_cast")
	metrics.record_mechanic_event(&"combo_targets", (result.targets as Array).size())
	if float(result.damage) > 0.0:
		metrics.record_mechanic_event(&"combo_damage", float(result.damage))
	if not (result.targets as Array).is_empty():
		screen_effects.shake(0.72, 0.32)


func _core_skill_title(core_data: CoreData) -> String:
	return candidate_core_skill_policy.title_for(core_data, _candidate_core_skill_plan(core_data), ConceptService.term(&"core"))

func _candidate_core_skill_plan(core_data: CoreData) -> Dictionary:
	var candidate_modifiers := loadout.get_candidate_modifiers() if loadout != null else {}
	var growth_enabled := loadout != null and loadout.is_candidate_growth_enabled()
	return candidate_core_skill_policy.build_plan(core_data, candidate_modifiers, growth_enabled, death_wave_controller != null)

func _on_tower_attack_requested(column: TowerColumn, row_index: int) -> void:
	var context := _build_tower_attack_context(column, row_index)
	if not bool(context.valid):
		return
	if _execute_early_tower_attack(context):
		return
	_confirm_hitscan_tower_attack(context)
	var result := _resolve_hitscan_tower_attack(context)
	if bool(result.cancelled):
		return
	var column_context: TowerColumn = context.column
	var tower_context: TowerData = context.tower
	var target := result.target as Enemy
	var enemies: Array[Enemy] = context.enemies
	var tracked_enemies: Array[Enemy] = context.tracked_enemies
	var origin: Vector2 = result.origin
	var beam_end: Vector2 = result.beam_end
	_finalize_hitscan_tower_attack(
		column_context, int(context.row_index), tower_context, target,
		enemies, tracked_enemies, origin, beam_end,
		float(context.damage), float(result.dealt), int(result.hit_count), bool(result.deferred)
	)

func _build_tower_attack_context(column: TowerColumn, row_index: int) -> Dictionary:
	var context := _build_tower_attack_source_context(column, row_index)
	if not bool(context.valid):
		return context
	var tower: TowerData = context.tower
	var target_context := _build_tower_attack_target_context(column, row_index, tower)
	if not bool(target_context.valid):
		return target_context
	context.merge(target_context, true)
	context.merge(_prepare_tower_attack_power(column, row_index, tower, context.origin), true)
	return context

func _build_tower_attack_source_context(column: TowerColumn, row_index: int) -> Dictionary:
	if column.is_row_disabled(row_index):
		return {"valid": false}
	var tower := column.get_tower_data(row_index)
	if tower == null:
		return {"valid": false}
	if guard_ability_controller.is_attack_suppressed(column, row_index):
		return {"valid": false}
	return {"valid": true, "column": column, "row_index": row_index, "tower": tower}

func _build_tower_attack_target_context(column: TowerColumn, row_index: int, tower: TowerData) -> Dictionary:
	var origin := column.get_attack_origin(row_index)
	var enemies := spatial_index.query_radius(
		origin,
		column.get_attack_range(row_index)
	)
	if enemies.is_empty():
		return {"valid": false}
	var reactivation_component := _get_retainer_reactivation_component(column, row_index, tower)
	if reactivation_component != null and not reactivation_component.can_attack():
		return {"valid": false}
	var tracked_enemies: Array[Enemy] = enemies.duplicate()
	enemies = _prioritize_tower_attack_targets(enemies, tower)
	return {
		"valid": true,
		"enemies": enemies,
		"tracked_enemies": tracked_enemies,
		"reactivation_component": reactivation_component,
		"origin": origin,
	}

func _prioritize_tower_attack_targets(enemies: Array[Enemy], tower: TowerData) -> Array[Enemy]:
	var cursor_priority := bool(loadout.get_cursor_branch_modifiers().get("tower_priority", false))
	if not cursor_priority or tower.behavior in [&"pierce", &"unique_pierce"]:
		return enemies
	var preferred_cursor := enemies.filter(func(enemy: Enemy) -> bool: return enemy.global_position.distance_to(target_cursor.global_position) <= target_cursor.get_effective_attack_radius())
	return preferred_cursor if not preferred_cursor.is_empty() else enemies

func _prepare_tower_attack_power(column: TowerColumn, row_index: int, tower: TowerData, origin: Vector2) -> Dictionary:
	var damage := column.get_damage(row_index) * loadout.get_axis_independent_tower_damage_multiplier()
	damage *= _get_specialization_tower_damage_multiplier(column)
	var guard_attack_preparation := kasuha_guard_controller.prepare_attack(column, row_index, tower, loadout)
	damage *= float(guard_attack_preparation.get("damage_multiplier", 1.0))
	if bool(guard_attack_preparation.get("replacement_boosted", false)):
		metrics.record_mechanic_event(&"kasuha_guard_replacement_first_attack")
		_show_burst_effect(origin, tower.color.lightened(0.2), 44.0, 0.42)
	return {
		"damage": damage,
		"guard_attack_preparation": guard_attack_preparation,
	}

func _execute_early_tower_attack(context: Dictionary) -> bool:
	var column: TowerColumn = context.column
	var row_index := int(context.row_index)
	var tower: TowerData = context.tower
	var reactivation_component := context.reactivation_component as RetainerReactivationComponent
	if _handle_kasuha_guard_single_attack(column, row_index, tower, reactivation_component, context.origin):
		return true
	if tower_attack_dispatch_policy.family_for(tower.behavior) != &"projectile":
		return false
	var enemies: Array[Enemy] = context.enemies
	_handle_projectile_tower_attack(column, row_index, tower, enemies, float(context.damage), reactivation_component)
	return true

func _confirm_hitscan_tower_attack(context: Dictionary) -> void:
	var column: TowerColumn = context.column
	var row_index := int(context.row_index)
	var tower: TowerData = context.tower
	var reactivation_component := context.reactivation_component as RetainerReactivationComponent
	_confirm_tower_attack_usage(column, row_index, tower, reactivation_component)

func _confirm_tower_attack_usage(column: TowerColumn, row_index: int, tower: TowerData, reactivation_component: RetainerReactivationComponent) -> void:
	column.confirm_attack(row_index)
	if reactivation_component != null:
		reactivation_component.consume_attack()
	metrics.record_tower_attack(tower.id, _guard_formation_metric_id(column))

func _resolve_hitscan_tower_attack(context: Dictionary) -> Dictionary:
	var column: TowerColumn = context.column
	var row_index := int(context.row_index)
	var tower: TowerData = context.tower
	var enemies: Array[Enemy] = context.enemies
	var origin: Vector2 = context.origin
	var damage := float(context.damage)
	var guard_attack_preparation: Dictionary = context.guard_attack_preparation
	var family := tower_attack_dispatch_policy.family_for(tower.behavior)
	var attack_result: Dictionary
	match family:
		&"pierce":
			attack_result = _resolve_pierce_tower_attack(column, row_index, tower, enemies, origin, damage)
		&"control":
			attack_result = _resolve_control_tower_attack(column, row_index, tower, enemies, origin, guard_attack_preparation)
		&"precision":
			attack_result = _resolve_precision_tower_attack(column, row_index, tower, enemies, origin, damage)
		&"network":
			attack_result = _resolve_network_tower_attack(column, row_index, tower, origin, damage)
		&"unique_field":
			attack_result = _resolve_unique_field_tower_attack(column, row_index, tower, enemies, origin, damage)
		_:
			attack_result = _resolve_direct_hitscan_tower_attack(column, row_index, tower, enemies, origin, damage)
	return _normalize_hitscan_tower_result(attack_result, origin, family == &"pierce")

func _resolve_direct_hitscan_tower_attack(column: TowerColumn, row_index: int, tower: TowerData, enemies: Array[Enemy], origin: Vector2, damage: float) -> Dictionary:
	var target := _select_target_by_rule(enemies, column, tower)
	var dealt := _apply_tower_damage(target, damage, tower.behavior, false, column, row_index, tower)
	_apply_common_tower_statuses(column, row_index, tower, target, damage)
	_present_tower_hit(tower, target, origin, damage, 0.65)
	return {"target": target, "dealt": dealt, "hit_count": 1}

func _normalize_hitscan_tower_result(attack_result: Dictionary, origin: Vector2, cancel_without_target: bool) -> Dictionary:
	var target := attack_result.get("target") as Enemy
	var result_origin := attack_result.get("origin", origin) as Vector2
	var beam_end := attack_result.get("beam_end", Vector2.ZERO) as Vector2
	return {
		"cancelled": cancel_without_target and target == null,
		"target": target,
		"dealt": float(attack_result.get("dealt", 0.0)),
		"hit_count": int(attack_result.get("hit_count", 0)),
		"origin": result_origin,
		"beam_end": beam_end,
		"deferred": bool(attack_result.get("deferred", false)),
	}

func _resolve_precision_tower_attack(
		column: TowerColumn,
		row_index: int,
		tower: TowerData,
		enemies: Array[Enemy],
		origin: Vector2,
		damage: float
	) -> Dictionary:
	var target := _select_target_by_rule(enemies, column, tower)
	match tower.behavior:
		&"execute":
			return _resolve_execute_precision_attack(column, row_index, tower, enemies, target, origin, damage)
		&"mark":
			return _resolve_mark_precision_attack(column, row_index, tower, target, origin, damage)
	return {"target": target, "dealt": 0.0, "hit_count": 0}

func _resolve_execute_precision_attack(
		column: TowerColumn,
		row_index: int,
		tower: TowerData,
		enemies: Array[Enemy],
		target: Enemy,
		origin: Vector2,
		damage: float
	) -> Dictionary:
	var modifiers := column.get_branch_modifiers(tower.id)
	var guard_overrides := _candidate_execution_overrides() if column.is_guard_formation and column.formation_data != null and column.formation_data.unique_core_id == &"obsidian" else {}
	var sudden_death := judaginda_guard_controller.should_sudden_execute(column, tower, target.data, loadout)
	var profile := precision_attack_execution_service.build_execute_profile(modifiers, target, guard_overrides, sudden_death)
	var verdict := _resolve_execute_precision_verdict(column, row_index, tower, target, damage, profile)
	_record_execute_precision_verdict(verdict, profile, column, row_index, tower)
	return precision_attack_execution_service.execute_verdict(
		enemies,
		target,
		origin,
		damage,
		profile,
		verdict,
		Callable(self, "_apply_execute_precision_primary_hit").bind(column, row_index, tower, origin, damage),
		Callable(self, "_apply_execute_collateral_hit").bind(column, row_index, tower, origin, damage),
		Callable(self, "_query_execute_stun_targets")
	)

func _resolve_execute_precision_verdict(column: TowerColumn, row_index: int, tower: TowerData, target: Enemy, damage: float, profile: Dictionary) -> Dictionary:
	if bool(profile.sudden_death):
		return judgment_service.resolve_forced_non_boss_execution(target, &"guard_sudden_death")
	return judgment_service.resolve(target, damage, profile.execute_source, profile.execute_ratio, null, 0, profile.guard_overrides, _normal_defender_damage_context(column, row_index, tower))

func _record_execute_precision_verdict(verdict: Dictionary, profile: Dictionary, column: TowerColumn, row_index: int, tower: TowerData) -> void:
	var enemy_data: EnemyData = profile.enemy_data
	_record_judgment_metrics(verdict, enemy_data.is_boss)
	_record_candidate_execution(verdict, profile.execute_position, column, row_index, tower, enemy_data)

func _apply_execute_precision_primary_hit(target: Enemy, verdict: Dictionary, profile: Dictionary, column: TowerColumn, row_index: int, tower: TowerData, origin: Vector2, damage: float) -> float:
	if bool(profile.sudden_death):
		metrics.record_mechanic_event(&"judaginda_guard_sudden_death")
		_show_pattern_effect(profile.execute_position, Color("e9d5ff"), 48.0, &"slash", 0.7, 0.46)
	var dealt := float(verdict.damage)
	_apply_common_tower_statuses(column, row_index, tower, target, damage)
	_present_tower_hit(tower, target, origin, dealt, 1.0)
	return dealt

func _apply_execute_collateral_hit(collateral_target: Enemy, collateral_damage: float, column: TowerColumn, row_index: int, tower: TowerData, origin: Vector2, base_damage: float) -> float:
	var dealt := _apply_tower_damage(collateral_target, collateral_damage, &"pierce", false, column, row_index, tower)
	_apply_common_tower_statuses(column, row_index, tower, collateral_target, base_damage)
	_present_tower_hit(tower, collateral_target, origin, collateral_damage, 0.48)
	return dealt

func _query_execute_stun_targets(stun_origin: Vector2, stun_radius: float) -> Array[Enemy]:
	return spatial_index.query_radius(stun_origin, stun_radius)

func _resolve_mark_precision_attack(column: TowerColumn, row_index: int, tower: TowerData, target: Enemy, origin: Vector2, damage: float) -> Dictionary:
	var modifiers := column.get_branch_modifiers(tower.id)
	var mark_power := column.resolve_defense_stat(row_index, &"power", &"vulnerability_strength", float(modifiers.get("mark", tower.status_power)))
	return precision_attack_execution_service.execute_mark(
		target,
		damage,
		modifiers,
		mark_power,
		Callable(self, "_apply_mark_precision_primary_hit").bind(column, row_index, tower, origin)
	)

func _apply_mark_precision_primary_hit(target: Enemy, damage: float, column: TowerColumn, row_index: int, tower: TowerData, origin: Vector2) -> float:
	var dealt := _apply_tower_damage(target, damage, &"mark", false, column, row_index, tower)
	_apply_common_tower_statuses(column, row_index, tower, target, damage)
	_present_tower_hit(tower, target, origin, damage, 0.62)
	return dealt

func _resolve_network_tower_attack(
		column: TowerColumn,
		row_index: int,
		tower: TowerData,
		origin: Vector2,
		damage: float
	) -> Dictionary:
	var relay_points := chain_network_attack_execution_service.build_relay_path(column, row_index, loadout.columns)
	var modifiers := column.get_branch_modifiers(tower.id)
	var network_multiplier := column.get_chain_network_damage_multiplier(row_index, relay_points.size())
	metrics.record_mechanic_event(&"chain_network_relays", relay_points.size())
	metrics.record_mechanic_event(&"chain_network_multiplier", network_multiplier)
	var result := chain_network_attack_execution_service.execute(
		relay_points,
		damage,
		network_multiplier,
		modifiers,
		Callable(self, "_query_network_segment_targets"),
		Callable(self, "_apply_network_forward_hit").bind(column, row_index, tower, damage),
		Callable(self, "_apply_network_return_hit").bind(column, row_index, tower)
	)
	if bool(result.return_triggered):
		metrics.record_mechanic_event(&"chain_resonance_return")
	_show_chain_effect(relay_points, tower.color, 0.72)
	return result

func _query_network_segment_targets(segment_start: Vector2, segment_end: Vector2, half_width: float) -> Array[Enemy]:
	return _enemies_near_segment(spatial_index.query_segment(segment_start, segment_end, half_width), segment_start, segment_end, half_width)

func _apply_network_forward_hit(chain_target: Enemy, segment_origin: Vector2, relay_damage: float, column: TowerColumn, row_index: int, tower: TowerData, base_damage: float) -> float:
	var dealt := _apply_tower_damage(chain_target, relay_damage, &"chain", true, column, row_index, tower)
	_apply_common_tower_statuses(column, row_index, tower, chain_target, base_damage)
	_present_tower_hit(tower, chain_target, segment_origin, relay_damage, 0.62)
	return dealt

func _apply_network_return_hit(return_target: Enemy, return_damage: float, column: TowerColumn, row_index: int, tower: TowerData) -> float:
	return _apply_tower_damage(return_target, return_damage, &"chain", true, column, row_index, tower)

func _resolve_unique_field_tower_attack(
		column: TowerColumn,
		row_index: int,
		tower: TowerData,
		enemies: Array[Enemy],
		origin: Vector2,
		damage: float
	) -> Dictionary:
	match tower.behavior:
		&"unique_radial":
			return _resolve_unique_radial_attack(column, row_index, tower, enemies, origin, damage)
		&"unique_random":
			return _resolve_unique_random_attack(column, row_index, tower, enemies, origin, damage)
	return {"target": null, "dealt": 0.0, "hit_count": 0}

func _resolve_unique_radial_attack(column: TowerColumn, row_index: int, tower: TowerData, enemies: Array[Enemy], origin: Vector2, damage: float) -> Dictionary:
	var target := _select_target_by_rule(enemies, column, tower)
	var result := unique_field_attack_execution_service.execute_radial(
		enemies,
		origin,
		column.get_attack_range(row_index),
		damage,
		Callable(self, "_apply_unique_radial_hit").bind(column, row_index, tower, origin, damage)
	)
	_show_pattern_effect(origin, tower.color, column.get_attack_range(row_index), &"burst", 0.72, 0.52)
	result["target"] = target
	return result

func _apply_unique_radial_hit(radial_target: Enemy, radial_damage: float, show_presentation: bool, column: TowerColumn, row_index: int, tower: TowerData, origin: Vector2, base_damage: float) -> float:
	var dealt := _apply_tower_damage(radial_target, radial_damage, &"unique_radial", true, column, row_index, tower)
	radial_target.apply_slow(&"unique_radial", 1.15, tower.status_power)
	_apply_common_tower_statuses(column, row_index, tower, radial_target, base_damage)
	if show_presentation:
		_present_tower_hit(tower, radial_target, origin, radial_damage, 0.52)
	return dealt

func _resolve_unique_random_attack(column: TowerColumn, row_index: int, tower: TowerData, enemies: Array[Enemy], origin: Vector2, damage: float) -> Dictionary:
	return unique_field_attack_execution_service.execute_random(
		enemies,
		damage,
		Callable(self, "_apply_unique_random_first_target").bind(column, row_index, tower),
		Callable(self, "_apply_unique_random_hit").bind(column, row_index, tower, origin, damage)
	)

func _apply_unique_random_first_target(target: Enemy, column: TowerColumn, row_index: int, tower: TowerData) -> void:
	_apply_unique_random_first_target_curse(column, row_index, tower, target)

func _apply_unique_random_hit(random_target: Enemy, lucky_damage: float, column: TowerColumn, row_index: int, tower: TowerData, origin: Vector2, base_damage: float) -> float:
	var dealt := _apply_tower_damage(random_target, lucky_damage, &"unique_random", false, column, row_index, tower)
	_apply_common_tower_statuses(column, row_index, tower, random_target, base_damage)
	_present_tower_hit(tower, random_target, origin, lucky_damage, 0.58)
	_show_pattern_effect(random_target.global_position, tower.color, 30.0, &"burst", 0.58, 0.36)
	return dealt

func _apply_unique_random_first_target_curse(column: TowerColumn, row_index: int, tower: TowerData, target: Enemy) -> void:
	var curse_generation := irelai_guard_controller.apply_first_attack_curse(column, row_index, tower, target, loadout)
	if curse_generation > 0:
		metrics.record_mechanic_event(&"irelai_guard_first_attack_curse", curse_generation)
		_show_pattern_effect(target.global_position, Color("c084fc"), 42.0, &"sigil", 0.75, 0.48)

func _resolve_pierce_tower_attack(
		column: TowerColumn,
		row_index: int,
		tower: TowerData,
		enemies: Array[Enemy],
		origin: Vector2,
		damage: float
	) -> Dictionary:
	var context := _build_pierce_tower_context(column, row_index, tower, enemies, origin)
	var target: Enemy = context.target as Enemy
	var beam_end: Vector2 = context.beam_end
	if target == null:
		return {"target": null, "dealt": 0.0, "hit_count": 0, "beam_end": beam_end, "deferred": false}
	var modifiers: Dictionary = context.modifiers
	var explosive_plan := pierce_attack_execution_service.build_explosive_plan(tower.behavior, modifiers, target, damage)
	if bool(explosive_plan.deferred):
		_defer_orc_explosive_arrow(column, row_index, tower, origin, explosive_plan)
		return {"target": target, "dealt": 0.0, "hit_count": 0, "beam_end": beam_end, "deferred": true}
	var profile := pierce_attack_execution_service.build_band_profile(tower.behavior, modifiers, column.attack_counts[row_index])
	if bool(profile.power_shot):
		metrics.record_mechanic_event(&"orc_power_shot")
	var hit_result := pierce_attack_execution_service.execute_band(
		origin,
		beam_end,
		damage,
		profile,
		Callable(self, "_query_pierce_band_targets"),
		Callable(self, "_apply_pierce_band_hit").bind(column, row_index, tower, origin)
	)
	return {"target": target, "dealt": hit_result.dealt, "hit_count": hit_result.hit_count, "beam_end": beam_end, "deferred": false}

func _build_pierce_tower_context(column: TowerColumn, row_index: int, tower: TowerData, enemies: Array[Enemy], origin: Vector2) -> Dictionary:
	var cursor_targets := enemies.filter(func(enemy: Enemy) -> bool: return enemy.global_position.distance_to(target_cursor.global_position) <= target_cursor.get_effective_attack_radius())
	var target := _closest_to_position(cursor_targets, target_cursor.global_position) if not cursor_targets.is_empty() else _select_target_by_rule(enemies, column, tower)
	var beam_end := Vector2.ZERO if target == null else origin + origin.direction_to(target.global_position) * column.get_attack_range(row_index)
	return {"target": target, "beam_end": beam_end, "modifiers": column.get_branch_modifiers(tower.id)}

func _defer_orc_explosive_arrow(column: TowerColumn, row_index: int, tower: TowerData, origin: Vector2, plan: Dictionary) -> void:
	var explosion_position: Vector2 = plan.position
	_show_effect(origin, explosion_position, tower.color, 0.0, 0.24)
	pierce_attack_execution_service.run_deferred_explosion(
		plan,
		Callable(self, "_wait_for_orc_explosive_arrow"),
		Callable(self, "_can_resolve_orc_explosive_arrow").bind(column, tower),
		Callable(self, "_active_enemies"),
		Callable(spatial_index, "query_radius"),
		Callable(self, "_apply_orc_explosive_arrow_hit").bind(column, row_index, tower, explosion_position),
		Callable(self, "_finalize_orc_explosive_arrow").bind(column, tower, origin)
	)

func _wait_for_orc_explosive_arrow(delay: float) -> Signal:
	return get_tree().create_timer(delay, false).timeout

func _can_resolve_orc_explosive_arrow(column: TowerColumn, tower: TowerData) -> bool:
	return not game_finished and is_instance_valid(column) and tower != null

func _query_pierce_band_targets(origin: Vector2, beam_end: Vector2, band_width: float) -> Array[Enemy]:
	return _enemies_near_segment(spatial_index.query_segment(origin, beam_end, band_width), origin, beam_end, band_width)

func _apply_pierce_band_hit(enemy: Enemy, hit_damage: float, show_presentation: bool, presentation_strength: float, column: TowerColumn, row_index: int, tower: TowerData, origin: Vector2) -> float:
	var pierce_damage := _unique_tower_damage(tower, enemy, hit_damage)
	var dealt := _apply_tower_damage(enemy, pierce_damage, tower.behavior, false, column, row_index, tower)
	_apply_common_tower_statuses(column, row_index, tower, enemy, pierce_damage)
	if show_presentation:
		_present_tower_hit(tower, enemy, origin, pierce_damage, presentation_strength)
	return dealt

func _resolve_control_tower_attack(
		column: TowerColumn,
		row_index: int,
		tower: TowerData,
		enemies: Array[Enemy],
		origin: Vector2,
		guard_attack_preparation: Dictionary
	) -> Dictionary:
	var target := _select_target_by_rule(enemies, column, tower)
	match tower.behavior:
		&"slow":
			return _resolve_slow_control_attack(column, row_index, tower, enemies, target, origin, guard_attack_preparation)
		&"knockback":
			return _resolve_knockback_control_attack(column, row_index, tower, enemies, target, origin)
		&"golem":
			return _resolve_golem_control_attack(column, row_index, tower, target, origin)
	return {"target": target, "dealt": 0.0, "hit_count": 0, "origin": origin}

func _resolve_slow_control_attack(
		column: TowerColumn,
		row_index: int,
		tower: TowerData,
		enemies: Array[Enemy],
		target: Enemy,
		origin: Vector2,
		guard_attack_preparation: Dictionary
	) -> Dictionary:
	var level := column.get_tower_level(tower.id)
	var modifiers := column.get_branch_modifiers(tower.id)
	var base_slow_power := tower.status_power * float(modifiers.get("slow_multiplier", 1.0)) * float(guard_attack_preparation.get("status_multiplier", 1.0))
	var slow_power := clampf(column.resolve_defense_stat(row_index, &"power", &"slow_strength", base_slow_power), 0.0, 0.8)
	var profile := control_attack_execution_service.build_slow_profile(level, modifiers, column.attack_counts[row_index], slow_power)
	if bool(profile.erosion_pulse):
		metrics.record_mechanic_event(&"abyss_erosion_pulse")
	var result := control_attack_execution_service.execute_slow(
		enemies,
		target,
		origin,
		StringName("slow_aura:%d:%d" % [column.column_index, row_index]),
		profile,
		Callable(self, "_apply_slow_control_common_status").bind(column, row_index, tower),
		Callable(self, "_present_control_hit").bind(tower, origin),
		Callable(self, "_show_slow_frost_burst").bind(tower)
	)
	_show_pattern_effect(origin, tower.color, column.get_attack_range(row_index), &"zone", 0.48, 0.46)
	return result

func _apply_slow_control_common_status(slow_target: Enemy, column: TowerColumn, row_index: int, tower: TowerData) -> void:
	_apply_common_tower_statuses(column, row_index, tower, slow_target, 0.0)

func _show_slow_frost_burst(slow_target: Enemy, tower: TowerData) -> void:
	_show_burst_effect(slow_target.global_position, tower.color, 48.0, 0.42)

func _present_control_hit(target: Enemy, damage: float, strength: float, tower: TowerData, origin: Vector2) -> void:
	_present_tower_hit(tower, target, origin, damage, strength)

func _resolve_knockback_control_attack(
		column: TowerColumn,
		row_index: int,
		tower: TowerData,
		enemies: Array[Enemy],
		target: Enemy,
		origin: Vector2
	) -> Dictionary:
	var modifiers := column.get_branch_modifiers(tower.id)
	var saw_damage := column.get_saw_contact_damage(row_index) * loadout.get_axis_independent_tower_damage_multiplier()
	saw_damage *= _get_specialization_tower_damage_multiplier(column)
	var push := column.resolve_defense_stat(row_index, &"power", &"knockback_strength", tower.status_power * float(modifiers.get("push", 1.0)))
	var profile := control_attack_execution_service.build_knockback_profile(saw_damage, push, modifiers, column.attack_counts[row_index])
	return control_attack_execution_service.execute_knockback(
		enemies,
		target,
		origin,
		profile,
		Callable(self, "_apply_knockback_control_hit").bind(column, row_index, tower, origin),
		Callable(self, "_apply_knockback_control_overheat").bind(column, row_index, origin)
	)

func _apply_knockback_control_hit(saw_target: Enemy, damage: float, show_presentation: bool, strength: float, column: TowerColumn, row_index: int, tower: TowerData, origin: Vector2) -> float:
	var dealt := _apply_tower_damage(saw_target, damage, &"knockback", true, column, row_index, tower)
	_apply_common_tower_statuses(column, row_index, tower, saw_target, damage)
	if show_presentation:
		_present_tower_hit(tower, saw_target, origin, damage, strength)
	return dealt

func _apply_knockback_control_overheat(overheat_duration: float, column: TowerColumn, row_index: int, origin: Vector2) -> void:
	column.disable_row_for(row_index, overheat_duration)
	metrics.record_mechanic_event(&"ki2_turbo_overheat")
	_show_burst_effect(origin, Color("ff7b55"), column.get_saw_blade_radius(row_index) * 2.4, 0.46)

func _resolve_golem_control_attack(
		column: TowerColumn,
		row_index: int,
		tower: TowerData,
		target: Enemy,
		_origin: Vector2
	) -> Dictionary:
	var modifiers := column.get_branch_modifiers(tower.id)
	var impact_origin := column.advance_golem_toward(row_index, target.global_position)
	var targets := spatial_index.query_radius(impact_origin, column.get_golem_control_radius(row_index))
	var push_distance := column.resolve_defense_stat(row_index, &"power", &"knockback_strength", tower.status_power * float(modifiers.get("push", 1.0)))
	var profile := control_attack_execution_service.build_golem_profile(modifiers, impact_origin, targets, push_distance)
	var result := control_attack_execution_service.execute_golem(
		target,
		profile,
		Callable(self, "_record_golem_control_event"),
		Callable(self, "_present_control_hit").bind(tower, impact_origin),
		Callable(self, "_apply_golem_self_recoil").bind(column, row_index)
	)
	_show_pattern_effect(profile.origin, tower.color, column.get_golem_control_radius(row_index), &"zone", 0.42, 0.38)
	return result

func _record_golem_control_event(target: Enemy, control_distance: float) -> void:
	metrics.record_mechanic_event(&"rubber_golem_control_success", control_distance)
	if target.data.is_boss:
		metrics.record_mechanic_event(&"rubber_golem_boss_control", control_distance)

func _apply_golem_self_recoil(threat_position: Vector2, recoil_factor: float, column: TowerColumn, row_index: int) -> float:
	var recoil_distance := column.apply_golem_recoil(row_index, threat_position, recoil_factor)
	if recoil_distance > 0.0:
		metrics.record_mechanic_event(&"rubber_golem_self_recoil", recoil_distance)
	return recoil_distance

func _handle_kasuha_guard_single_attack(
		column: TowerColumn,
		row_index: int,
		tower: TowerData,
		reactivation_component: RetainerReactivationComponent,
		origin: Vector2
	) -> bool:
	var result := _request_kasuha_guard_single_attack(column, row_index, tower)
	if not bool(result.get("handled", false)):
		return false
	var target := result.get("target") as Enemy
	if target == null:
		return true
	_confirm_kasuha_guard_single_attack(column, row_index, tower, reactivation_component)
	_finalize_kasuha_guard_single_attack(column, row_index, tower, target, origin, result)
	return true

func _request_kasuha_guard_single_attack(column: TowerColumn, row_index: int, tower: TowerData) -> Dictionary:
	return kasuha_guard_controller.resolve_single_target_attack(
		column,
		row_index,
		tower,
		loadout,
		spatial_index,
		Callable(self, "_select_target_by_rule"),
		loadout.get_tower_damage_multiplier(),
		_get_specialization_tower_damage_multiplier(column)
	)

func _confirm_kasuha_guard_single_attack(column: TowerColumn, row_index: int, tower: TowerData, reactivation_component: RetainerReactivationComponent) -> void:
	_confirm_tower_attack_usage(column, row_index, tower, reactivation_component)

func _finalize_kasuha_guard_single_attack(column: TowerColumn, row_index: int, tower: TowerData, target: Enemy, origin: Vector2, result: Dictionary) -> void:
	var tracked: Array[Enemy] = []
	tracked.assign(result.get("tracked_enemies", []) as Array)
	var dealt := float(result.get("damage", 0.0))
	_apply_common_tower_statuses(column, row_index, tower, target, float(result.get("attack_damage", 0.0)))
	_record_tower_result(column, tower, dealt, tracked, origin, int(result.get("hit_count", 0)))
	metrics.record_mechanic_event(&"kasuha_guard_obsession_damage", dealt)
	_present_tower_hit(tower, target, origin, dealt, 0.82)
	_show_effect(origin, result.get("position", origin) as Vector2, tower.color, 0.0, 0.24)
	AudioManager.play_tower_attack(&"unique_single")

func _handle_projectile_tower_attack(
		column: TowerColumn,
		row_index: int,
		tower: TowerData,
		enemies: Array[Enemy],
		damage: float,
		reactivation_component: RetainerReactivationComponent
	) -> void:
	var target := _select_projectile_target(enemies, column, tower)
	if target == null:
		return
	_confirm_tower_attack_usage(column, row_index, tower, reactivation_component)
	var volley := _projectile_tower_volley_profile(column, row_index, tower, damage)
	_fire_projectile_tower_volley(column, row_index, tower, target.global_position, volley)

func _projectile_tower_volley_profile(column: TowerColumn, row_index: int, tower: TowerData, damage: float) -> Dictionary:
	var modifiers := column.get_branch_modifiers(tower.id) if tower.behavior == &"rapid" else {}
	var profile := projectile_attack_execution_service.build_volley_profile(tower.behavior, damage, modifiers, column.attack_counts[row_index])
	if bool(profile.warcry_triggered):
		metrics.record_mechanic_event(&"goblin_warcry")
		_show_burst_effect(column.get_attack_origin(row_index), tower.color, 46.0, 0.42)
	return profile

func _fire_projectile_tower_volley(column: TowerColumn, row_index: int, tower: TowerData, aim_position: Vector2, volley: Dictionary) -> void:
	for shot_index in int(volley.count):
		_spawn_tower_projectile(column, row_index, tower, aim_position, float(volley.damage), shot_index)

func _finalize_hitscan_tower_attack(
		column: TowerColumn,
		row_index: int,
		tower: TowerData,
		target: Enemy,
		enemies: Array[Enemy],
		tracked_enemies: Array[Enemy],
		origin: Vector2,
		pierce_beam_end: Vector2,
		damage: float,
		dealt: float,
		hit_count: int,
		deferred_attack: bool
	) -> void:
	if not deferred_attack and target != null:
		var followup_result := _resolve_confirmed_hitscan_followups(column, row_index, tower, target, enemies, damage, dealt, hit_count)
		dealt = float(followup_result.dealt)
		hit_count = int(followup_result.hit_count)
	if not deferred_attack:
		_record_tower_result(column, tower, dealt, tracked_enemies, origin, hit_count)
	if target == null:
		return
	_present_hitscan_tower_attack(tower, target, origin, pierce_beam_end)

func _resolve_confirmed_hitscan_followups(
		column: TowerColumn,
		row_index: int,
		tower: TowerData,
		target: Enemy,
		enemies: Array[Enemy],
		damage: float,
		dealt: float,
		hit_count: int
	) -> Dictionary:
	dealt += _apply_tower_branch_hit(column, row_index, tower, target, enemies, damage)
	var guard_result := _resolve_confirmed_guard_followup(column, row_index, tower, target, damage, hit_count)
	dealt += float(guard_result.get("damage", 0.0))
	hit_count += int(guard_result.get("hit_count", 0))
	_present_confirmed_guard_attack_result(tower, target, guard_result)
	_resolve_kasuha_confirmed_followup(column, row_index, tower, target)
	return {"dealt": dealt, "hit_count": hit_count}

func _resolve_confirmed_guard_followup(column: TowerColumn, row_index: int, tower: TowerData, target: Enemy, damage: float, hit_count: int) -> Dictionary:
	return guard_ability_controller.resolve_confirmed_attack(
		column,
		row_index,
		tower,
		target.global_position,
		damage,
		hit_count,
		loadout,
		spatial_index
	)

func _resolve_kasuha_confirmed_followup(column: TowerColumn, row_index: int, tower: TowerData, target: Enemy) -> void:
	var kasuha_guard_result := kasuha_guard_controller.resolve_confirmed_attack(column, row_index, tower, target.global_position, loadout)
	_present_kasuha_guard_result(tower, kasuha_guard_result)

func _present_confirmed_guard_attack_result(tower: TowerData, target: Enemy, result: Dictionary) -> void:
	if result.get("mode", &"") == &"shockwave":
		_show_pattern_effect(target.global_position, tower.color, float(result.get("radius", 0.0)), &"shockwave", 0.52, 0.48)
		metrics.record_mechanic_event(&"jiane_guard_pure_shockwave", float(result.get("damage", 0.0)))
	var devotion_added := int(result.get("devotion_added", 0))
	if devotion_added > 0:
		metrics.record_mechanic_event(&"jiane_guard_devotion_gain", devotion_added)
		hud.update_build(loadout.get_build_summary())

func _present_hitscan_tower_attack(tower: TowerData, target: Enemy, origin: Vector2, pierce_beam_end: Vector2) -> void:
	var hit_intensity := 0.32 if tower.behavior == &"execute" else 0.18
	AudioManager.play_tower_attack(tower.behavior)
	match tower.behavior:
		&"pierce", &"unique_pierce":
			_present_hitscan_pierce_beams(tower, origin, pierce_beam_end)
		&"execute", &"knockback", &"chain", &"slow", &"unique_radial", &"unique_random":
			pass
		&"mark":
			_show_effect(origin, target.global_position, tower.color, 0.0, 0.16)
			_show_pattern_effect(target.global_position, tower.color, 34.0, &"sigil", 0.72, 0.72)
		_:
			_show_effect(origin, target.global_position, tower.color, 0.0, hit_intensity)
			_show_impact_effect(target.global_position, tower.color, 0.0, hit_intensity)
	if tower.behavior == &"execute":
		screen_effects.shake(0.24, 0.12)

func _present_hitscan_pierce_beams(tower: TowerData, origin: Vector2, beam_end: Vector2) -> void:
	var beam_offsets: Array[float] = [-7.0, 0.0, 7.0]
	if tower.behavior == &"unique_pierce":
		beam_offsets.assign([-12.0, -6.0, 0.0, 6.0, 12.0])
	for beam_offset in beam_offsets:
		var offset: Vector2 = origin.direction_to(beam_end).orthogonal() * float(beam_offset)
		_show_effect(origin + offset, beam_end + offset, tower.color, 0.0, 0.28 if is_zero_approx(beam_offset) else 0.14)

func _uses_projectile(behavior: StringName) -> bool:
	return tower_attack_dispatch_policy.uses_projectile(behavior)

func _select_projectile_target(enemies: Array[Enemy], column: TowerColumn, tower: TowerData) -> Enemy:
	return _select_target_by_rule(enemies, column, tower)

func _spawn_tower_projectile(column: TowerColumn, row_index: int, tower: TowerData, aim_position: Vector2, damage: float, volley_index: int = 0) -> void:
	var profile := _tower_projectile_profile(tower, volley_index)
	var origin := column.get_attack_origin(row_index)
	var payload := _build_tower_projectile_payload(column, row_index, tower, origin, damage, volley_index)
	var maximum_distance := origin.distance_to(aim_position) if tower.behavior == &"area" else column.get_attack_range(row_index)
	var projectile := _create_tower_projectile_node()
	projectile.setup(
		origin,
		aim_position,
		profile.texture as Texture2D,
		float(profile.speed),
		profile.tint as Color,
		float(profile.length),
		payload,
		maximum_distance
	)

func _tower_projectile_profile(tower: TowerData, volley_index: int) -> Dictionary:
	var configured_texture := ConceptService.optional_content_texture(&"projectiles", tower.projectile_texture_id) if tower.projectile_texture_id != &"" else null
	var profile := projectile_attack_execution_service.build_motion_profile(tower.behavior, volley_index, tower.color)
	profile.texture = configured_texture
	if configured_texture == null:
		profile.texture = ConceptService.fallback_texture(&"projectile_artillery" if bool(profile.uses_artillery_fallback) else &"projectile_plasma")
	return profile

func _build_tower_projectile_payload(column: TowerColumn, row_index: int, tower: TowerData, origin: Vector2, damage: float, volley_index: int) -> Dictionary:
	var behavior := tower.behavior
	return {
		"column": column,
		"tower": tower,
		"row_index": row_index,
		"behavior": behavior,
		"damage": damage,
		"area_radius": tower.area_radius * column.get_range_multiplier(row_index),
		"impact_at_aim": behavior == &"area",
		"volley_index": volley_index,
		"max_hits": 1,
		"collision_mode": &"path" if behavior == &"rapid" else &"impact",
		"spatial_index": spatial_index,
		"origin": origin,
		"attack_count": column.attack_counts[row_index],
	}

func _create_tower_projectile_node() -> Projectile:
	var projectile := Projectile.new()
	effect_container.add_child(projectile)
	projectile.impacted.connect(_on_projectile_impacted)
	return projectile

func _on_projectile_impacted(target: Enemy, impact_position: Vector2, payload: Dictionary) -> void:
	if game_finished:
		return
	var context := _build_projectile_impact_context(target, impact_position, payload)
	if not bool(context.valid):
		return
	var result := _resolve_area_projectile_impact(context) if context.behavior == &"area" else _resolve_direct_projectile_impact(context)
	if bool(result.terminal_miss):
		_show_impact_effect(impact_position, context.tower.color)
		return
	_finalize_projectile_impact(context, result)

func _build_projectile_impact_context(target: Enemy, impact_position: Vector2, payload: Dictionary) -> Dictionary:
	var column := payload.get("column") as TowerColumn
	var tower := payload.get("tower") as TowerData
	if not is_instance_valid(column) or tower == null:
		return {"valid": false}
	var enemies := _active_enemies()
	return {
		"valid": true,
		"column": column,
		"tower": tower,
		"behavior": StringName(payload.get("behavior", &"rapid")),
		"damage": float(payload.get("damage", 0.0)),
		"row_index": int(payload.get("row_index", 0)),
		"hit_target": target if is_instance_valid(target) and target.active else null,
		"impact_position": impact_position,
		"effective_area_radius": float(payload.get("area_radius", 0.0)),
		"origin": payload.get("origin", impact_position),
		"attack_count": int(payload.get("attack_count", 0)),
		"enemies": enemies,
		"tracked_enemies": enemies.duplicate(),
	}

func _resolve_area_projectile_impact(context: Dictionary) -> Dictionary:
	var column: TowerColumn = context.column
	var tower: TowerData = context.tower
	var row_index := int(context.row_index)
	var impact_position: Vector2 = context.impact_position
	var damage := float(context.damage)
	var effective_area_radius := maxf(float(context.effective_area_radius), tower.area_radius * column.get_range_multiplier(row_index))
	var modifiers := column.get_branch_modifiers(tower.id)
	return projectile_attack_execution_service.execute_area(
		impact_position,
		effective_area_radius,
		damage,
		modifiers,
		Callable(spatial_index, "query_radius"),
		Callable(self, "_apply_area_projectile_hit").bind(column, row_index, tower, impact_position, modifiers),
		Callable(self, "_resolve_skeleton_area_followups").bind(column, row_index, tower, impact_position, damage, modifiers),
		Callable(self, "_closest_to_position")
	)

func _apply_area_projectile_hit(enemy: Enemy, area_damage: float, show_presentation: bool, presentation_strength: float, column: TowerColumn, row_index: int, tower: TowerData, impact_position: Vector2, modifiers: Dictionary) -> float:
	var dealt := _apply_tower_damage(enemy, area_damage, &"area", true, column, row_index, tower)
	_apply_common_tower_statuses(column, row_index, tower, enemy, area_damage, &"burn" if modifiers.has("fire_zone_duration") else &"")
	if show_presentation:
		_present_tower_hit(tower, enemy, impact_position, area_damage, presentation_strength)
	return dealt

func _resolve_skeleton_area_followups(area_targets: Array[Enemy], column: TowerColumn, row_index: int, tower: TowerData, impact_position: Vector2, damage: float, modifiers: Dictionary) -> float:
	var result := skeleton_area_followup_service.execute(
		area_targets,
		damage,
		modifiers,
		Callable(self, "_request_skeleton_fire_zone").bind(column, row_index, tower, impact_position, damage, modifiers),
		Callable(self, "_spawn_skeleton_bone_shards").bind(column, row_index, tower, impact_position, damage, modifiers),
		func(target: Enemy, lightning_damage: float, source: StringName) -> float: return target.take_damage(lightning_damage, source, true),
		func(target: Enemy) -> void: _show_effect(impact_position, target.global_position, Color("78d7ff"), 0.0, 0.2)
	)
	if bool(result.lightning_requested):
		metrics.record_mechanic_event(&"skeleton_lightning_strike", float(result.lightning_dealt))
	return float(result.lightning_dealt)

func _request_skeleton_fire_zone(column: TowerColumn, _row_index: int, _tower: TowerData, impact_position: Vector2, damage: float, modifiers: Dictionary) -> void:
	skeleton_fire_zone_serial += 1
	var owner_instance_id := column.get_instance_id()
	var profile := skeleton_fire_zone_service.build_profile(
		owner_instance_id, skeleton_fire_zone_serial, damage, modifiers,
		loadout.get_common_status_source_profile(&"burn")
	)
	_show_pattern_effect(impact_position, Color("ff7548"), float(profile.radius), &"zone", float(profile.duration), 0.78)
	metrics.record_mechanic_event(&"skeleton_fire_zone_created")
	skeleton_fire_zone_service.run_zone(
		impact_position,
		profile,
		Callable(self, "_is_skeleton_fire_zone_active").bind(owner_instance_id),
		Callable(spatial_index, "query_radius"),
		Callable(self, "_skeleton_fire_zone_timeout"),
		Callable(self, "_record_skeleton_fire_zone_burn")
	)

func _is_skeleton_fire_zone_active(owner_instance_id: int) -> bool:
	return is_instance_id_valid(owner_instance_id) and not game_finished

func _skeleton_fire_zone_timeout(seconds: float) -> Signal:
	return get_tree().create_timer(seconds, false).timeout

func _resolve_direct_projectile_impact(context: Dictionary) -> Dictionary:
	var hit_target := context.hit_target as Enemy
	var column: TowerColumn = context.column
	var tower: TowerData = context.tower
	var behavior: StringName = context.behavior
	var row_index := int(context.row_index)
	return projectile_attack_execution_service.execute_direct(
		hit_target,
		context.impact_position,
		float(context.effective_area_radius),
		float(context.damage),
		Callable(self, "_resolve_direct_projectile_damage").bind(column, row_index, tower, behavior),
		Callable(self, "_apply_direct_projectile_common_status").bind(column, row_index, tower),
		Callable(self, "_apply_direct_projectile_behavior_hit").bind(column, row_index, tower, behavior),
		Callable(self, "_present_direct_projectile_hit").bind(tower, context.impact_position),
		Callable(self, "_resolve_direct_projectile_followups").bind(context)
	)

func _apply_direct_projectile_common_status(hit_target: Enemy, damage: float, column: TowerColumn, row_index: int, tower: TowerData) -> void:
	_apply_common_tower_statuses(column, row_index, tower, hit_target, damage)

func _apply_direct_projectile_behavior_hit(hit_target: Enemy, damage: float, dealt: float, column: TowerColumn, row_index: int, tower: TowerData, behavior: StringName) -> void:
	if behavior == &"rapid":
		_apply_goblin_tactics(column, row_index, tower, hit_target, damage)
	elif behavior == &"area_shard":
		metrics.record_mechanic_event(&"skeleton_bone_shard_hit", dealt)

func _present_direct_projectile_hit(hit_target: Enemy, damage: float, tower: TowerData, impact_position: Vector2) -> void:
	_present_tower_hit(tower, hit_target, impact_position - Vector2.RIGHT * 28.0, damage, 0.55)

func _resolve_direct_projectile_damage(hit_target: Enemy, damage: float, column: TowerColumn, row_index: int, tower: TowerData, behavior: StringName) -> float:
	var judgment_profile := _get_unique_judgment_profile(tower)
	if judgment_profile == null:
		return _apply_tower_damage(hit_target, _unique_tower_damage(tower, hit_target, damage), behavior, false, column, row_index, tower)
	var execution_position := hit_target.global_position
	var enemy_data := hit_target.data
	var execution_overrides := _candidate_execution_overrides() if tower.unique_core_id == &"obsidian" else {}
	var sudden_death := judaginda_guard_controller.should_sudden_execute(column, tower, enemy_data, loadout)
	var judgment := judgment_service.resolve_forced_non_boss_execution(hit_target, &"guard_sudden_death") if sudden_death else judgment_service.resolve(hit_target, damage, behavior, judgment_profile.execute_health_ratio, judgment_profile, 1, execution_overrides, _normal_defender_damage_context(column, row_index, tower))
	_record_judgment_metrics(judgment, enemy_data.is_boss)
	_record_candidate_execution(judgment, execution_position, column, row_index, tower, enemy_data)
	if sudden_death:
		metrics.record_mechanic_event(&"judaginda_guard_sudden_death")
		_show_pattern_effect(execution_position, Color("e9d5ff"), 48.0, &"slash", 0.7, 0.46)
	return float(judgment.damage)

func _resolve_direct_projectile_followups(hit_target: Enemy, damage: float, context: Dictionary) -> float:
	var column: TowerColumn = context.column
	var tower: TowerData = context.tower
	var row_index := int(context.row_index)
	var dealt := 0.0
	if context.behavior == &"unique_single" and _get_unique_judgment_profile(tower) == null:
		var guard_result := guard_ability_controller.resolve_projectile(column, row_index, tower, hit_target, context.impact_position, damage, int(context.attack_count), loadout, spatial_index)
		dealt += float(guard_result.damage)
		_present_guard_ability_result(tower, guard_result)
	var modifiers := column.get_branch_modifiers(tower.id)
	if modifiers.has("ritual_hits") and column.attack_counts[row_index] % int(modifiers.ritual_hits) == 0:
		var ritual_damage := damage * float(modifiers.ritual_damage)
		dealt += _apply_tower_damage(hit_target, ritual_damage, &"ritual", true, column, row_index, tower)
		_show_burst_effect(hit_target.global_position, tower.color, 42.0, 0.55)
	return dealt

func _finalize_projectile_impact(context: Dictionary, result: Dictionary) -> void:
	var dealt := _resolve_projectile_impact_branch_damage(context, result)
	_record_projectile_impact(context, result, dealt)
	_present_projectile_impact(context, result)

func _resolve_projectile_impact_branch_damage(context: Dictionary, result: Dictionary) -> float:
	var dealt := float(result.dealt)
	var hit_target := result.hit_target as Enemy
	if hit_target == null:
		return dealt
	var column: TowerColumn = context.column
	var tower: TowerData = context.tower
	var enemies: Array[Enemy] = context.enemies
	return dealt + _apply_tower_branch_hit(column, int(context.row_index), tower, hit_target, enemies, float(context.damage))

func _record_projectile_impact(context: Dictionary, result: Dictionary, dealt: float) -> void:
	var column: TowerColumn = context.column
	var tower: TowerData = context.tower
	var behavior: StringName = context.behavior
	var tracked_enemies: Array[Enemy] = context.tracked_enemies
	_record_tower_result(column, tower, dealt, tracked_enemies, context.origin, int(result.hit_count))
	if dealt > 0.0:
		AudioManager.play_tower_attack(behavior)

func _present_projectile_impact(context: Dictionary, result: Dictionary) -> void:
	var tower: TowerData = context.tower
	var behavior: StringName = context.behavior
	var impact_position: Vector2 = context.impact_position
	var impact_intensity := 0.48 if behavior == &"area" else 0.12
	match behavior:
		&"area":
			_present_area_projectile_impact(tower, impact_position, result, impact_intensity)
		&"rapid", &"unique_single":
			pass
		_:
			_show_impact_effect(impact_position, tower.color, 0.0, impact_intensity)

func _present_area_projectile_impact(tower: TowerData, impact_position: Vector2, result: Dictionary, impact_intensity: float) -> void:
	_show_pattern_effect(impact_position, tower.color, float(result.effective_area_radius), &"zone", 0.72, 0.82)
	var impact_points: Array = result.impact_points
	for point_index in range(1, impact_points.size()):
		_show_effect(impact_position, Vector2(impact_points[point_index]), tower.color.lightened(0.18), 0.0, 0.13)
	screen_effects.shake(impact_intensity * 0.55, 0.12)

func _present_guard_ability_result(tower: TowerData, result: Dictionary) -> void:
	var mode: StringName = result.get("mode", &"") as StringName
	if mode == &"shield":
		_show_pattern_effect(result.get("position", Vector2.ZERO) as Vector2, tower.color, float(result.get("radius", 0.0)), &"shockwave", 0.74, 0.5)
	elif mode == &"sword":
		_show_effect(result.get("origin", Vector2.ZERO) as Vector2, result.get("end", Vector2.ZERO) as Vector2, tower.color.lightened(0.22), float(result.get("width", 0.0)), 0.28)
	var mechanic_id: StringName = result.get("mechanic_id", &"") as StringName
	if mechanic_id != &"":
		metrics.record_mechanic_event(mechanic_id, float(result.damage))

func _present_kasuha_guard_result(tower: TowerData, result: Dictionary) -> void:
	var mode: StringName = result.get("mode", &"") as StringName
	var position := result.get("position", Vector2.ZERO) as Vector2
	match mode:
		&"replacement":
			metrics.record_mechanic_event(&"kasuha_guard_replacement")
			_show_pattern_effect(position, tower.color, 46.0, &"sigil", 0.62, 0.58)
		&"erosion_zone":
			metrics.record_mechanic_event(&"kasuha_guard_erosion_created")
			_show_pattern_effect(position, tower.color.darkened(0.18), float(result.get("radius", 0.0)), &"zone", float(loadout.get_guard_modifier(&"guard_erosion_duration", 2.6)), 0.52)

func _update_guard_abilities(delta: float) -> void:
	_update_jiane_guard_frenzy(delta)
	_update_kasuha_guard_erosion(delta)

func _update_jiane_guard_frenzy(delta: float) -> void:
	var events := guard_ability_controller.update_frenzy(
		delta,
		loadout.columns,
		loadout,
		spatial_index,
		battlefield.get_battle_rect(),
		loadout.get_tower_damage_multiplier(),
		Callable(self, "_get_specialization_tower_damage_multiplier")
	)
	var started_count := 0
	for event in events:
		started_count += int(_consume_jiane_guard_frenzy_event(event))
	if started_count > 0:
		hud.show_notice("정숙의 광란 · 지아네 친위대 %d명 돌입" % started_count, 1.4)

func _consume_jiane_guard_frenzy_event(event: Dictionary) -> bool:
	var event_type: StringName = event.get("type", &"") as StringName
	var column := event.get("column") as TowerColumn
	var tower := event.get("tower") as TowerData
	var row_index := int(event.get("row_index", -1))
	if column == null or tower == null or row_index < 0:
		return false
	match event_type:
		&"frenzy_started":
			metrics.record_mechanic_event(&"jiane_guard_frenzy_started")
			_show_pattern_effect(column.get_attack_origin(row_index), tower.color, 50.0, &"burst", 0.46, 0.62)
			return true
		&"frenzy_hit":
			_consume_jiane_guard_frenzy_hit(event, column, tower)
		&"frenzy_ended":
			metrics.record_mechanic_event(&"jiane_guard_frenzy_ended")
			_show_pattern_effect(column.get_attack_origin(row_index), tower.color, 38.0, &"sigil", 0.42, 0.48)
	return false

func _consume_jiane_guard_frenzy_hit(event: Dictionary, column: TowerColumn, tower: TowerData) -> void:
	var tracked_enemies: Array[Enemy] = []
	tracked_enemies.assign(event.get("tracked_enemies", []) as Array)
	var position := event.get("position", Vector2.ZERO) as Vector2
	var dealt := float(event.get("damage", 0.0))
	var hit_count := int(event.get("hit_count", 0))
	metrics.record_tower_attack(tower.id, _guard_formation_metric_id(column))
	_record_tower_result(column, tower, dealt, tracked_enemies, position, hit_count)
	metrics.record_mechanic_event(&"jiane_guard_frenzy_damage", dealt)
	_show_pattern_effect(position, tower.color, float(event.get("radius", 0.0)), &"zone", 0.3, 0.38)

func _update_kasuha_guard_erosion(delta: float) -> void:
	for erosion_event in kasuha_guard_controller.update_erosion_zones(delta, spatial_index):
		_consume_kasuha_guard_erosion_event(erosion_event)

func _consume_kasuha_guard_erosion_event(event: Dictionary) -> void:
	var event_type: StringName = event.get("type", &"") as StringName
	match event_type:
		&"erosion_tick":
			var erosion_count := int(event.get("count", 0))
			metrics.record_mechanic_event(&"kasuha_guard_erosion_slow", erosion_count)
			metrics.record_status_application(&"slow", erosion_count)
		&"erosion_ended":
			metrics.record_mechanic_event(&"kasuha_guard_erosion_ended")

func _trigger_guard_core_active_abilities() -> void:
	var casts := guard_ability_controller.resolve_core_active(
		loadout.columns,
		loadout,
		spatial_index,
		Callable(self, "_select_target_by_rule"),
		loadout.get_tower_damage_multiplier(),
		Callable(self, "_get_specialization_tower_damage_multiplier")
	)
	var total_damage := 0.0
	for cast in casts:
		total_damage += _present_guard_core_active_cast(cast)
	_present_guard_core_active_summary(casts.size(), total_damage)

func _present_guard_core_active_cast(cast: Dictionary) -> float:
	var column := cast.get("column") as TowerColumn
	var tower := cast.get("tower") as TowerData
	var origin := cast.get("origin", Vector2.ZERO) as Vector2
	var impact_position := cast.get("impact_position", Vector2.ZERO) as Vector2
	var tracked_enemies: Array[Enemy] = []
	tracked_enemies.assign(cast.get("tracked_enemies", []) as Array)
	var dealt := float(cast.get("damage", 0.0))
	_show_effect(origin, impact_position, tower.color, 18.0, 0.22)
	_show_pattern_effect(impact_position, tower.color, float(cast.get("radius", 0.0)), &"shockwave", 0.58, 0.38)
	_record_tower_result(column, tower, dealt, tracked_enemies, origin, int(cast.get("hit_count", 0)))
	return dealt

func _present_guard_core_active_summary(cast_count: int, total_damage: float) -> void:
	if cast_count <= 0:
		return
	metrics.record_mechanic_event(&"partason_guard_liege_cast", total_damage)
	hud.show_notice("마왕의 수족 · 친위대 %d명 동시 시전" % cast_count, 1.6)

func _record_skeleton_fire_zone_burn(event: Dictionary) -> void:
	metrics.record_status_application(&"burn")
	metrics.record_mechanic_event(&"skeleton_fire_zone_burn")
	if bool(event.reignited):
		metrics.record_mechanic_event(&"status.burn_reignition")

func _spawn_skeleton_bone_shards(column: TowerColumn, row_index: int, tower: TowerData, impact_position: Vector2, attack_damage: float, modifiers: Dictionary) -> void:
	var plan := skeleton_bone_shard_service.build_spawn_plan(
		column,
		row_index,
		tower,
		impact_position,
		attack_damage,
		modifiers,
		spatial_index,
		func(minimum: float, maximum: float) -> float: return RunRng.rangef(minimum, maximum)
	)
	if not bool(plan.applied):
		return
	for request in plan.shards as Array:
		var shard := Projectile.new()
		effect_container.add_child(shard)
		shard.impacted.connect(_on_projectile_impacted)
		shard.setup(
			request.origin,
			request.target,
			ConceptService.fallback_texture(&"projectile_plasma"),
			request.speed,
			request.color,
			request.length,
			request.payload,
			request.max_distance
		)
	metrics.record_mechanic_event(&"skeleton_bone_shards_spawned", plan.count)

func _apply_orc_explosive_arrow_hit(explosion_target: Enemy, explosion_damage: float, show_presentation: bool, column: TowerColumn, row_index: int, tower: TowerData, impact_position: Vector2) -> float:
	var dealt := _apply_tower_damage(explosion_target, explosion_damage, &"pierce", true, column, row_index, tower)
	_apply_common_tower_statuses(column, row_index, tower, explosion_target, explosion_damage)
	if show_presentation:
		_present_tower_hit(tower, explosion_target, impact_position, explosion_damage, 0.72)
	return dealt

func _finalize_orc_explosive_arrow(result: Dictionary, column: TowerColumn, tower: TowerData, origin: Vector2) -> void:
	var tracked_targets: Array[Enemy] = []
	tracked_targets.assign(result.tracked_targets as Array)
	_record_tower_result(column, tower, float(result.dealt), tracked_targets, origin, int(result.hit_count))
	metrics.record_mechanic_event(&"orc_explosive_arrow", int(result.hit_count))
	AudioManager.play_tower_attack(&"area")
	_show_pattern_effect(result.position, tower.color, float(result.radius), &"burst", 0.72, 0.76)
	screen_effects.shake(0.32, 0.12)

func _apply_goblin_tactics(column: TowerColumn, row_index: int, tower: TowerData, target: Enemy, attack_damage: float) -> bool:
	var result := goblin_tactics_service.execute(
		tower, target, attack_damage, column.attack_counts[row_index], column.get_branch_modifiers(tower.id),
		loadout.get_common_status_source_profile(&"poison"), loadout.get_common_status_source_profile(&"bleed")
	)
	if not bool(result.applied):
		return false
	for status_id in result.status_ids as Array:
		metrics.record_status_application(status_id as StringName)
	metrics.record_mechanic_sample(result.sample_id as StringName, float(result.sample_value))
	metrics.record_mechanic_event(&"goblin_tactics")
	return true

func _abyss_sacrifice_key(column: TowerColumn, row_index: int) -> StringName:
	return abyss_sacrifice_controller.key_for(column, row_index)

func _register_abyss_sacrifice_for_column(column: TowerColumn, row_index: int, death_position: Vector2) -> bool:
	var result := abyss_sacrifice_controller.register_sacrifice(
		column,
		row_index,
		death_position,
		func(source_column: TowerColumn, tower: TowerData) -> bool:
			return kasuha_guard_controller.allows_pillar_sacrifice(source_column, tower, loadout)
	)
	for metric_id in result.metric_events as Array:
		metrics.record_mechanic_event(StringName(metric_id))
	return bool(result.accepted)

func _on_abyss_summon_attack(summon: AbyssSummon, target: Enemy, damage: float, column: TowerColumn, _row_index: int, tower: TowerData) -> void:
	var result := abyss_summon_attack_service.execute(
		not game_finished,
		summon,
		target,
		damage,
		column,
		tower,
		Callable(metrics, "record_tower_attack")
	)
	if not bool(result.applied):
		return
	_record_abyss_summon_hit(result)
	_present_abyss_summon_attack(summon, target, tower, float(result.dealt))

func _record_abyss_summon_hit(result: Dictionary) -> void:
	var tower_id: StringName = result.tower_id
	var dealt := float(result.dealt)
	tower_damage[tower_id] = float(tower_damage.get(tower_id, 0.0)) + dealt
	metrics.record_tower_hit(
		tower_id,
		dealt,
		int(result.kills),
		int(result.hit_count),
		0,
		result.formation_id,
		0
	)
	metrics.record_mechanic_event(&"abyss_summon_damage", dealt)

func _present_abyss_summon_attack(summon: AbyssSummon, target: Enemy, tower: TowerData, dealt: float) -> void:
	_present_tower_hit(tower, target, summon.global_position, dealt, 0.48)
	_show_pattern_effect(summon.global_position, tower.color, 30.0, &"sigil", 0.32, 0.38)

func _on_abyss_summon_expired(_summon: AbyssSummon, _key: StringName) -> void:
	metrics.record_mechanic_event(&"abyss_summon_expired")

func _spawn_candidate_abyss_swarm() -> int:
	if candidate_abyss_controller == null:
		return 0
	var profile := candidate_abyss_swarm_service.build_profile(
		Callable(loadout, "get_candidate_modifier"),
		loadout.get_candidate_growth_snapshot(),
		loadout.get_core_skill_damage_multiplier()
	)
	var result := candidate_abyss_swarm_service.execute(
		profile,
		core.data.color,
		_active_enemies(),
		Callable(candidate_abyss_controller, "spawn_swarm")
	)
	if not bool(result.attempted):
		return 0
	metrics.record_mechanic_event(result.metric_id, float(result.metric_value))
	if not String(result.notice).is_empty():
		hud.show_notice(result.notice, float(result.notice_duration))
	return int(result.spawn_count)

func _on_candidate_abyss_summon_attack(summon: AbyssSummon, target: Enemy, damage: float) -> void:
	var result := abyss_summon_attack_service.execute_candidate(not game_finished, summon, target, damage)
	if not bool(result.applied):
		return
	var dealt := float(result.dealt)
	_record_kasuha_candidate_hit(target, dealt)
	metrics.record_mechanic_event(&"kasuha_summon_damage", dealt)
	_show_pattern_effect(summon.global_position, core.data.color, 32.0, &"sigil", 0.34, 0.36)

func _on_candidate_abyss_summon_expired(summon: AbyssSummon) -> void:
	metrics.record_mechanic_event(&"kasuha_summon_expired")

func _record_tower_result(column: TowerColumn, tower: TowerData, dealt: float, tracked_enemies: Array[Enemy], origin: Vector2, hit_count: int) -> void:
	var defeated := _defeated_enemies(tracked_enemies)
	var long_range_kills := 0
	for enemy in defeated:
		if origin.distance_to(enemy.global_position) >= 360.0:
			long_range_kills += 1
	tower_damage[tower.id] = float(tower_damage.get(tower.id, 0.0)) + dealt
	metrics.record_tower_hit(
		tower.id,
		dealt,
		defeated.size(),
		hit_count,
		long_range_kills,
		_guard_formation_metric_id(column),
		hit_count if tower.status_power > 0.0 else 0
	)

func _guard_formation_metric_id(column: TowerColumn) -> StringName:
	if column == null or not column.is_guard_formation or column.formation_data == null:
		return &""
	return column.formation_data.id

func _apply_tower_branch_hit(column: TowerColumn, row_index: int, tower: TowerData, target: Enemy, enemies: Array[Enemy], damage: float) -> float:
	var modifiers := column.get_branch_modifiers(tower.id)
	var wave_knockback := 0.0
	if modifiers.has("wave"):
		wave_knockback = column.resolve_defense_stat(row_index, &"power", &"knockback_strength", tower.status_power * float(modifiers.wave))
	var result := tower_branch_hit_execution_service.execute(
		tower, target, enemies, damage, modifiers,
		tower.area_radius * column.get_range_multiplier(row_index), wave_knockback,
		Callable(self, "_apply_tower_damage").bind(column, row_index, tower),
		Callable(self, "_present_tower_branch_event").bind(tower)
	)
	return float(result.dealt)

func _present_tower_branch_event(event: Dictionary, tower: TowerData) -> void:
	_present_tower_hit(tower, event.target, event.origin, float(event.damage), float(event.strength))

func _apply_common_tower_statuses(column: TowerColumn, row_index: int, tower: TowerData, target: Enemy, attack_damage: float, excluded_status: StringName = &"") -> void:
	var stage_progress := clampf(enemy_spawner.elapsed / maxf(stage_data.duration_seconds, 1.0), 0.0, 1.0)
	tower_status_service.apply(column, row_index, tower, target, attack_damage, stage_progress, excluded_status)

func _normal_defender_damage_context(column: TowerColumn, row_index: int, tower: TowerData) -> EnemyDamageContext:
	if not is_instance_valid(column) or tower == null or column.is_guard_formation or tower.id not in DataRegistry.NORMAL_DEFENDER_IDS:
		return null
	return EnemyDamageContext.normal_defender(column, row_index, tower.id)

func _apply_tower_damage(enemy: Enemy, amount: float, source_type: StringName, is_area: bool, column: TowerColumn, row_index: int, tower: TowerData) -> float:
	if not is_instance_valid(enemy):
		return 0.0
	return enemy.take_damage(amount, source_type, is_area, _normal_defender_damage_context(column, row_index, tower))

func _on_enemy_special_action(action: StringName, source: Enemy) -> void:
	var result := enemy_special_action_execution_service.execute(
		action, source,
		Callable(battlefield, "get_battle_rect"), Callable(RunRng, "roll"), Callable(RunRng, "rangef"), Callable(RunRng, "pick"),
		Callable(spatial_index, "query_radius"), Callable(battlefield, "world_to_lane"), Callable(source, "change_vertical_position"),
		Callable(loadout, "disable_random_column"), Callable(self, "_enemy_pool_by_ids").bind(BOSS_SUMMON_ENEMY_IDS),
		Callable(battlefield, "clamp_to_battlefield"), Callable(self, "_spawn_enemy")
	)
	if action != &"disable_column" or not bool(result.applied):
		return
	hud.show_notice("%s 열 일시 비활성화" % ConceptService.term(&"tower"))
	screen_effects.shake(0.3 if bool(result.is_boss) else 0.16, 0.18)
	screen_effects.flash(Color("df72ff"), 0.08, 0.16)

func _on_boss_warning(boss_data: EnemyData, spawn_y_ratio: float, _seconds: float) -> void:
	phase_coordinator.enter_boss_warning()
	warning_spawn_ratio = spawn_y_ratio
	battlefield.set_spawn_warning(spawn_y_ratio)
	var presentation := _boss_presentation(boss_data)
	var warning_text := boss_presentation_service.warning_text(boss_data, presentation, spawn_y_ratio)
	hud.show_warning(
		warning_text,
		presentation.color,
		presentation.marker_style,
		presentation.primary_color,
		presentation.secondary_color
	)
	screen_effects.shake(0.14, 0.16)
	screen_effects.flash(presentation.color, 0.06, 0.2)
	audience_stage.react(&"boss_warning", presentation.color, 0.9, 2.2)
	SignalBus.boss_warning_started.emit(boss_data, battlefield.get_free_spawn_position(spawn_y_ratio))
	AudioManager.play_warning()

func _on_boss_health_changed(current: float, maximum: float, _display_name: String, source: Enemy) -> void:
	if source == current_boss:
		hud.update_boss_health(current, maximum, String(_boss_presentation(source.data).name))

func _boss_presentation(boss_data: EnemyData) -> Dictionary:
	var campaign := ConceptService.get_election_campaign()
	var faction := _resolve_campaign_faction(campaign, boss_data)
	return boss_presentation_service.compose(boss_data, campaign, faction, _campaign_boss_presentation_label(campaign, faction, boss_data))

func _campaign_boss_presentation_label(campaign: ElectionCampaignData, faction: ElectionFactionData, boss_data: EnemyData) -> String:
	if campaign == null or faction == null or boss_data == null:
		return ""
	var slot_index := _boss_plan_slot_index(boss_data.id)
	if slot_index < 0:
		return ""
	var presentation_kind := boss_plan.presentation_kind_at(slot_index)
	var presentation_id := boss_plan.presentation_id_at(slot_index)
	match presentation_kind:
		StageRuntimeBossPlan.PRESENTATION_CANDIDATE:
			var candidate := campaign.candidate(presentation_id)
			return candidate.short_name if candidate != null else ""
		StageRuntimeBossPlan.PRESENTATION_RETAINER:
			var retainer := campaign.retainer(presentation_id)
			return retainer.short_name if retainer != null else ""
		StageRuntimeBossPlan.PRESENTATION_GUARD:
			var tower := DataRegistry.get_tower(_campaign_guard_fallback_tower_id(campaign, faction))
			return tower.display_name if tower != null else faction.display_name
	return ""

func _campaign_faction_for_enemy(enemy_data: EnemyData) -> ElectionFactionData:
	return _resolve_campaign_faction(ConceptService.get_election_campaign(), enemy_data)

func _resolve_campaign_faction(campaign: ElectionCampaignData, enemy_data: EnemyData) -> ElectionFactionData:
	if campaign == null or enemy_data == null:
		return null
	if enemy_data.is_boss:
		if boss_plan != null:
			for slot_index in boss_plan.slots.size():
				if boss_plan.boss_id_at(slot_index) == enemy_data.id:
					var planned_faction := campaign.faction(boss_plan.faction_id_at(slot_index))
					if planned_faction != null:
						return planned_faction
		return campaign.faction_for_boss(enemy_data.id)
	return campaign.faction_for_enemy(enemy_data.id)

func _unregister_boss(enemy: Enemy) -> void:
	enemy_lifecycle_controller.unregister_boss(enemy)
	_refresh_boss_state()

func _unregister_boss_by_data(enemy_data: EnemyData) -> void:
	enemy_lifecycle_controller.unregister_boss_by_data(enemy_data)
	_refresh_boss_state()

func _refresh_boss_state() -> void:
	enemy_lifecycle_controller.refresh_bosses()
	if current_boss != null:
		var presentation := _boss_presentation(current_boss.data)
		hud.update_boss_health(current_boss.current_health, current_boss.get_max_health(), String(presentation.name))
	else:
		hud.hide_boss()
	if not selecting_upgrade and not game_finished:
		_resume_combat_phase()

func _resume_combat_phase() -> void:
	phase_coordinator.resume_combat(not active_bosses.is_empty(), warning_spawn_ratio >= 0.0)

func _on_cursor_moved(target_position: Vector2) -> void:
	var modifiers := loadout.get_cursor_branch_modifiers()
	var movement_distance := previous_cursor_position.distance_to(target_position)
	if tutorial_director != null:
		tutorial_director.record_movement(movement_distance)
	_apply_cursor_movement_haste(movement_distance, modifiers)
	_update_cursor_trail_attack(target_position, movement_distance, modifiers)
	_commit_cursor_movement(target_position)
	_present_cursor_spawn_warning(target_position)

func _apply_cursor_movement_haste(movement_distance: float, modifiers: Dictionary) -> void:
	if movement_distance > 2.0 and modifiers.has("move_haste"):
		target_cursor.boost_attack_speed(float(modifiers.move_haste), 2.0)

func _update_cursor_trail_attack(target_position: Vector2, movement_distance: float, modifiers: Dictionary) -> void:
	if not bool(modifiers.get("trail_shot", false)):
		cursor_trail_distance_accumulator = 0.0
		return
	cursor_trail_distance_accumulator += movement_distance
	if cursor_trail_distance_accumulator < 24.0 or cursor_trail_cooldown > 0.0:
		return
	cursor_trail_cooldown = 0.12
	cursor_trail_distance_accumulator = fmod(cursor_trail_distance_accumulator, 24.0)
	_fire_cursor_trail_shot(target_position)

func _fire_cursor_trail_shot(target_position: Vector2) -> void:
	var trail_position := previous_cursor_position.lerp(target_position, 0.5)
	var trail_target := _closest_to_position(spatial_index.query_radius(trail_position, 90.0), trail_position)
	if trail_target == null:
		return
	trail_target.take_damage(target_cursor.data.damage * target_cursor.stat_multiplier * 0.65, &"cursor_trail", true)
	_show_effect(previous_cursor_position, trail_target.global_position, target_cursor.data.color, 0.0, 0.18)

func _commit_cursor_movement(target_position: Vector2) -> void:
	previous_cursor_position = target_position
	_refresh_specialization_tower_bonuses()
	hud.update_target_position(target_position, battlefield.get_battle_rect(), battlefield.lane_count)
	SignalBus.target_cursor_moved.emit(target_position)

func _present_cursor_spawn_warning(target_position: Vector2) -> void:
	if warning_spawn_ratio < 0.0:
		return
	var battle_rect := battlefield.get_battle_rect()
	var warning_y := battle_rect.position.y + battle_rect.size.y * warning_spawn_ratio
	if absf(target_position.y - warning_y) <= 56.0:
		hud.show_notice("%s 출현 예상 지점" % ConceptService.term(&"boss"))

func _on_leveled_up(new_level: int) -> void:
	metrics.record_level_reached(new_level, experience.total_experience)
	if _is_tutorial():
		return
	var should_open_reward := reward_queue.enqueue_level_up(new_level)
	SignalBus.player_leveled_up.emit(experience.level)
	AudioManager.play_level_up()
	if should_open_reward:
		_open_level_up()

func _open_pause_menu() -> void:
	if not input_policy.allows_pause(game_phase):
		return
	run_pause_coordinator.open(Callable(self, "_set_range_overlay").bind(false, false))

func _close_pause_menu() -> void:
	run_pause_coordinator.close()

func _open_level_up() -> void:
	if not reward_selection_coordinator.begin_level_up(Callable(self, "_set_range_overlay").bind(false, false)):
		return
	_show_level_up_choices()

func _show_level_up_choices() -> void:
	var choices := loadout.generate_upgrade_choices()
	_record_upgrade_offers(choices)
	reward_selection_coordinator.show_level_up_choices(choices, experience.level, level_up_rerolls_remaining, LEVEL_UP_REROLL_LIMIT)

func _on_level_up_reroll_requested() -> void:
	if not selecting_upgrade or reward_queue.artifact_draft_active or game_phase != GameTypes.GamePhase.LEVEL_UP or level_up_rerolls_remaining <= 0:
		return
	var rerolled_choices := loadout.generate_rerolled_upgrade_choices(reward_selection_coordinator.current_choices())
	level_up_rerolls_remaining -= 1
	_record_upgrade_offers(rerolled_choices)
	reward_selection_coordinator.show_level_up_choices(rerolled_choices, experience.level, level_up_rerolls_remaining, LEVEL_UP_REROLL_LIMIT)

func _upgrade_choice_signature(upgrade_choices: Array[UpgradeData]) -> String:
	var parts: Array[String] = []
	for choice in upgrade_choices:
		parts.append("%s:%s" % [choice.category, choice.data_id])
	parts.sort()
	return "|".join(parts)

func _on_upgrade_selected(choice: UpgradeData) -> void:
	if reward_queue.artifact_draft_active and (choice == null or choice.category != &"artifact"):
		return
	var tutorial_fixed_growth := _is_tutorial() and tutorial_director != null and tutorial_director.is_step(TutorialDirector.Step.FIXED_GROWTH)
	var tutorial_category := tutorial_scenario.fixed_upgrade_category if tutorial_fixed_growth and tutorial_scenario != null else &""
	var tutorial_data_id := tutorial_scenario.fixed_upgrade_id if tutorial_fixed_growth and tutorial_scenario != null else &""
	var route := upgrade_selection_router.route_for(choice, candidate_reward_active, tutorial_fixed_growth, tutorial_category, tutorial_data_id)
	match route:
		UpgradeSelectionRouter.Route.IGNORE:
			return
		UpgradeSelectionRouter.Route.TUTORIAL_FIXED:
			_apply_tutorial_fixed_upgrade(choice)
		UpgradeSelectionRouter.Route.ARTIFACT:
			_handle_artifact_choice(choice)
		UpgradeSelectionRouter.Route.CANDIDATE_BRANCH:
			_handle_candidate_branch_choice(choice)
		UpgradeSelectionRouter.Route.FORMATION_SET:
			_handle_formation_set_choice(choice)
		UpgradeSelectionRouter.Route.SPECIALIZATION:
			_handle_specialization_entry_choice(choice)
		UpgradeSelectionRouter.Route.BLOCK_FORMATION_PLACEMENT:
			_begin_block_formation_placement(choice)
		_:
			_apply_selected_upgrade(choice)

func _apply_tutorial_fixed_upgrade(choice: UpgradeData) -> void:
	if not loadout.apply_upgrade(choice):
		hud.show_notice("고정 성장을 적용하지 못했습니다. 카드를 다시 선택해 주세요.", 3.0)
		return
	metrics.record_selection(choice)
	metrics.update_slot_completion(loadout)
	_apply_runtime_loadout_stats()
	_refresh_specialization_tower_bonuses()
	hud.update_build(loadout.get_build_summary())
	tutorial_director.record_growth(choice.category, choice.data_id)

func _handle_artifact_choice(choice: UpgradeData) -> void:
	var result := artifact_reward_resolution_service.begin(choice)
	match int(result.status):
		ArtifactRewardResolutionService.Status.ACQUIRED:
			_complete_artifact_acquisition(choice)
		ArtifactRewardResolutionService.Status.REPLACEMENT_REQUIRED:
			reward_selection_coordinator.show_artifact_resolution(result.artifact, loadout.get_equipped_artifacts())
		_:
			_recover_failed_upgrade_choice(choice)

func _on_artifact_replacement_requested(slot_index: int) -> void:
	if pending_artifact_choice == null or not selecting_upgrade or game_phase != GameTypes.GamePhase.LEVEL_UP:
		return
	var result := artifact_reward_resolution_service.replace(slot_index)
	if int(result.status) != ArtifactRewardResolutionService.Status.REPLACED:
		hud.show_notice("아티팩트를 교체하지 못했습니다. 슬롯을 다시 선택해 주세요.", 3.0)
		return
	reward_selection_coordinator.hide_artifact_resolution()
	_complete_artifact_acquisition(result.choice)

func _on_artifact_discard_requested() -> void:
	if pending_artifact_choice == null or not selecting_upgrade or game_phase != GameTypes.GamePhase.LEVEL_UP:
		return
	var result := artifact_reward_resolution_service.discard()
	if int(result.status) != ArtifactRewardResolutionService.Status.DISCARDED:
		hud.show_notice("아티팩트를 포기하지 못했습니다. 다시 시도해 주세요.", 3.0)
		return
	reward_selection_coordinator.hide_artifact_resolution()
	hud.show_notice("%s을(를) 포기했습니다." % (result.choice as UpgradeData).display_name, 2.4)
	_finish_artifact_choice_reward()

func _complete_artifact_acquisition(choice: UpgradeData) -> void:
	metrics.record_selection(choice)
	SignalBus.upgrade_selected.emit(choice.display_name)
	AudioManager.play_ui()
	_apply_runtime_loadout_stats()
	_refresh_specialization_tower_bonuses()
	hud.show_notice("아티팩트 획득 · %s" % choice.display_name, 2.8)
	_finish_artifact_choice_reward()

func _finish_artifact_choice_reward() -> void:
	if reward_queue.artifact_draft_active:
		_continue_reward_flow(reward_queue.complete_artifact_draft())
	else:
		_finish_level_up_reward()

func _handle_candidate_branch_choice(choice: UpgradeData) -> void:
	if choice == null or choice.category != &"candidate_branch" or not loadout.apply_candidate_branch(choice):
		hud.show_notice("후보 특성 선택을 적용하지 못했습니다. 다른 특성을 선택해 주세요.", 3.0)
		return
	metrics.record_selection(choice)
	SignalBus.upgrade_selected.emit(choice.display_name)
	AudioManager.play_ui()
	_apply_runtime_loadout_stats()
	_refresh_specialization_tower_bonuses()
	_try_place_candidate_guard_reinforcement()
	_finish_candidate_reward()

func _handle_formation_set_choice(choice: UpgradeData) -> void:
	var formation_set_size := loadout.get_formation_set_size(choice)
	var formation_candidates := loadout.get_formation_candidates(formation_set_size, 3)
	if formation_candidates.is_empty():
		# 보드 상태가 바뀌지 않는 정지 화면이므로 정상적으로는 발생하지 않는다.
		# 데이터/판정 오류는 플레이어에게 손실을 주지 않고 메인 제안을 복구한다.
		_show_level_up_choices()
		return
	metrics.record_selection(choice)
	metrics.record_formation_set_selection(formation_set_size)
	_record_upgrade_offers(formation_candidates)
	reward_selection_coordinator.show_subchoices(formation_candidates, choice.display_name, experience.level, false)
	AudioManager.play_ui()

func _handle_specialization_entry_choice(choice: UpgradeData) -> void:
	var subchoices := loadout.get_specialization_subchoices(choice)
	if subchoices.is_empty():
		_show_level_up_choices()
		return
	metrics.record_selection(choice)
	_record_upgrade_offers(subchoices)
	reward_selection_coordinator.show_subchoices(subchoices, choice.display_name, experience.level)
	AudioManager.play_ui()

func _begin_block_formation_placement(choice: UpgradeData) -> void:
	pending_block_formation_choice = choice
	pending_block_placement_started_msec = Time.get_ticks_msec()
	reward_selection_coordinator.hide_level_up()
	preparation_panel.show_formation(DataRegistry.get_formation(choice.data_id))

func _apply_selected_upgrade(choice: UpgradeData) -> void:
	if not loadout.apply_upgrade(choice):
		_recover_failed_upgrade_choice(choice)
		return
	metrics.record_selection(choice)
	if choice.category == &"new_formation":
		var placed_formation := DataRegistry.get_formation(choice.data_id)
		var placement_seconds := float(maxi(Time.get_ticks_msec() - pending_block_placement_started_msec, 0)) / 1000.0
		metrics.record_formation_selection(placed_formation, placement_seconds, choice.board_anchor, choice.vertical_flip, loadout.board_state, choice.offer_metadata)
		pending_block_placement_started_msec = 0
	metrics.update_slot_completion(loadout)
	SignalBus.upgrade_selected.emit(choice.display_name)
	AudioManager.play_ui()
	_apply_runtime_loadout_stats()
	_refresh_specialization_tower_bonuses()
	experience.experience_multiplier = loadout.get_experience_multiplier()
	_finish_level_up_reward()

func _recover_failed_upgrade_choice(choice: UpgradeData) -> void:
	if reward_queue.artifact_draft_active:
		hud.show_notice("아티팩트 보상을 적용하지 못했습니다. 선택지를 다시 구성합니다.", 3.0)
		_show_artifact_draft_choices()
		return
	match upgrade_selection_router.failure_route_for(choice):
		UpgradeSelectionRouter.FailureRoute.BLOCK_FORMATION_RETRY:
			hud.show_notice("편대를 배치하지 못했습니다. 패널을 복구했습니다.", 3.0)
			_begin_block_formation_placement(choice)
		_:
			hud.show_notice("선택한 강화를 적용하지 못했습니다. 다른 항목을 선택해 주세요.", 3.0)
			_show_level_up_choices()

func _on_block_formation_confirmed(formation: TowerFormationData, anchor: Vector2i, vertical_flipped: bool) -> void:
	if _is_tutorial() and tutorial_director != null and tutorial_director.is_step(TutorialDirector.Step.PLACE_GOBLINS):
		if formation == null or formation.id != tutorial_scenario.formation_id or anchor != tutorial_scenario.required_formation_anchor:
			return
		var owner_id := loadout.place_formation_block(formation, anchor, vertical_flipped, false, &"tutorial_goblins")
		if owner_id == &"":
			preparation_panel.show_required_formation(formation, tutorial_scenario.required_formation_anchor)
			return
		metrics.record_formation_selection(formation, 0.0, anchor, vertical_flipped, loadout.board_state, {"source": "tutorial"})
		hud.update_build(loadout.get_build_summary())
		tutorial_director.record_formation(formation.id, anchor)
		return
	if pending_block_formation_choice == null or pending_block_formation_choice.data_id != formation.id:
		return
	pending_block_formation_choice.board_anchor = anchor
	pending_block_formation_choice.vertical_flip = vertical_flipped
	pending_block_formation_choice.placement_confirmed = true
	var committed_choice := pending_block_formation_choice
	pending_block_formation_choice = null
	_on_upgrade_selected(committed_choice)

func _on_block_placement_abandoned(formation: TowerFormationData) -> void:
	if _is_tutorial():
		return
	if pending_block_formation_choice == null or pending_block_formation_choice.data_id != formation.id:
		return
	var reward_level := reward_queue.current_reward_level(experience.level)
	var refund := experience.refund_abandoned_reward(reward_level, 0.4)
	metrics.record_mechanic_event(&"formation_placement_abandoned")
	metrics.record_formation_abandon(formation, refund, loadout.board_state, pending_block_formation_choice.offer_metadata)
	pending_block_formation_choice = null
	pending_block_placement_started_msec = 0
	hud.show_notice("편대 배치를 포기했습니다. 경험치 %.0f를 환급했습니다." % refund, 3.0)
	_finish_level_up_reward()

func _finish_level_up_reward() -> void:
	_continue_reward_flow(reward_queue.complete_level_up())

func _queue_artifact_elite_reward(enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or enemy.spawn_context == null or not enemy.spawn_context.is_artifact_elite():
		return
	var tier := enemy.spawn_context.artifact_reward_tier
	metrics.record_mechanic_event(&"artifact_elite_defeated")
	metrics.record_mechanic_event(StringName("artifact_elite_tier_%d_defeated" % tier))
	if reward_queue.enqueue_artifact_draft(tier):
		_open_artifact_draft_reward.call_deferred()

func _open_artifact_draft_reward() -> void:
	if reward_queue.pending_artifact_draft_tiers.is_empty() or reward_queue.artifact_draft_active:
		return
	if not reward_selection_coordinator.begin_artifact_draft(Callable(self, "_set_range_overlay").bind(false, false)):
		return
	_show_artifact_draft_choices()

func _show_artifact_draft_choices() -> void:
	var tier := reward_queue.current_artifact_draft_tier()
	var choices := ArtifactOfferService.build_draft(loadout.get_eligible_artifacts(), UpgradeOfferService.DISPLAY_CHOICE_COUNT)
	if choices.is_empty():
		push_error("Artifact elite reward has no eligible artifact choices.")
		metrics.record_mechanic_event(&"artifact_elite_reward_unavailable")
		hud.show_notice("아티팩트 보상을 구성하지 못했습니다.", 3.0)
		_continue_reward_flow(reward_queue.complete_artifact_draft())
		return
	if choices.size() < UpgradeOfferService.DISPLAY_CHOICE_COUNT:
		push_warning("Artifact elite reward has fewer than three eligible choices.")
	for choice in choices:
		choice.offer_metadata[&"artifact_elite_tier"] = tier
	metrics.record_artifact_draft(tier, choices)
	_record_upgrade_offers(choices)
	reward_selection_coordinator.show_event_choices(
		choices,
		"정예 전리품 · 아티팩트 %d단계" % tier,
		"정예가 남긴 서로 다른 아티팩트 중 하나를 선택하세요. 리롤은 없습니다."
	)

func _handle_candidate_boss_reward(enemy_data: EnemyData) -> void:
	if enemy_data == null or boss_plan == null or not loadout.is_candidate_growth_enabled():
		return
	var slot_index := -1
	for index in boss_plan.slots.size():
		if boss_plan.boss_id_at(index) == enemy_data.id:
			slot_index = index
			break
	if slot_index in [0, 2]:
		var fixed_upgrade := loadout.claim_candidate_fixed_upgrade(slot_index)
		if fixed_upgrade != null:
			_apply_runtime_loadout_stats()
			_refresh_specialization_tower_bonuses()
			metrics.record_mechanic_event(StringName("candidate_growth_slot_%d" % slot_index))
			hud.show_notice("후보 성장 · %s\n%s" % [fixed_upgrade.display_name, fixed_upgrade.description], 4.0)
	elif slot_index == 1 and not loadout.get_candidate_branch_choices().is_empty():
		if reward_queue.enqueue_candidate_branch():
			_open_candidate_branch_reward.call_deferred()

func _open_candidate_branch_reward() -> void:
	if pending_candidate_branch_rewards <= 0 or candidate_reward_active:
		return
	var choices := loadout.get_candidate_branch_choices()
	if choices.is_empty():
		_continue_reward_flow(reward_queue.discard_candidate_branches())
		return
	if not reward_selection_coordinator.begin_candidate_branch(Callable(self, "_set_range_overlay").bind(false, false)):
		return
	_record_upgrade_offers(choices)
	reward_selection_coordinator.show_event_choices(choices, "후보 특성 선택", "세 특성 중 하나를 선택하세요. 선택은 이번 출정 동안 유지됩니다.")

func _finish_candidate_reward() -> void:
	_continue_reward_flow(reward_queue.complete_candidate_branch())

func _continue_reward_flow(next_reward_kind: int) -> void:
	reward_selection_coordinator.continue_flow(
		next_reward_kind,
		Callable(self, "_open_artifact_draft_reward"),
		Callable(self, "_open_candidate_branch_reward"),
		Callable(self, "_show_level_up_choices"),
		Callable(self, "_resume_combat_phase")
	)

func _update_candidate_charm_stage(delta: float) -> void:
	var update_result := candidate_charm_stage_controller.update(delta, loadout, _active_enemies())
	if bool(update_result.pulse):
		if bool(update_result.charm_applied):
			metrics.record_mechanic_event(&"charm_zone_tick")
			if bool(update_result.stage_tick):
				metrics.record_mechanic_event(&"charm_stage_tick")
		_show_pattern_effect(battlefield.get_battle_rect().get_center(), Color("ff78cf"), battlefield.get_battle_rect().size.length() * 0.46, &"zone", 0.24, 0.3)
	if bool(update_result.ended):
		_apply_runtime_loadout_stats()
		_refresh_specialization_tower_bonuses()
		metrics.record_mechanic_event(&"charm_zone_ended")
		if bool(update_result.ended_with_stage_buff):
			metrics.record_mechanic_event(&"charm_stage_ended")

static func should_replace_irelai_basic_attack(requested_core: CoreData, active_core: CoreData, candidate_growth_enabled: bool) -> bool:
	return CandidateCoreAttackPolicy.should_replace_irelai_basic_attack(requested_core, active_core, candidate_growth_enabled)

func _summon_judaginda_reaper(duration: float) -> void:
	if is_instance_valid(judaginda_reaper_summon):
		judaginda_reaper_summon.queue_free()
	judaginda_reaper_summon = ReaperSummon.new()
	effect_container.add_child(judaginda_reaper_summon)
	judaginda_reaper_summon.setup(core.global_position, target_cursor.global_position, battlefield.get_battle_rect(), core.data.color, duration)
	metrics.record_mechanic_event(&"judaginda_reaper_summoned")

func _try_place_candidate_guard_reinforcement() -> void:
	if not loadout.candidate_requests_guard_reinforcement():
		return
	var reinforcement := DataRegistry.find_formation(&"emerald_guard_reinforcement")
	if reinforcement == null:
		return
	var placements := loadout.get_valid_board_placements(reinforcement)
	if placements.is_empty():
		hud.show_notice("친위대 증원 공간이 없어 공격 강화만 적용되었습니다.", 3.0)
		return
	var placement := placements.front() as Dictionary
	var owner_id := loadout.place_formation_block(reinforcement, placement.anchor, bool(placement.vertical_flipped), true, &"guard_emerald_reinforcement")
	if owner_id != &"":
		metrics.record_mechanic_event(&"candidate_guard_reinforcement_placed")
		hud.show_notice("왕실 친위대 증원 2칸이 배치되었습니다.", 3.0)

func _record_upgrade_offers(choices: Array[UpgradeData]) -> void:
	metrics.record_choices(choices)
	for choice in choices:
		if choice.category == &"formation_set":
			metrics.record_formation_set_offer(loadout.get_formation_set_size(choice))
		elif choice.category == &"new_formation":
			var formation := DataRegistry.get_formation(choice.data_id)
			metrics.record_formation_offer(choice.data_id, loadout.get_valid_board_placements(formation).size(), choice.offer_metadata)

func _apply_runtime_loadout_stats() -> void:
	core.apply_runtime(
		loadout.get_core_damage_multiplier(),
		loadout.get_core_health_multiplier(),
		loadout.get_core_regeneration_multiplier(),
		loadout.get_skill_charge_multiplier(),
		loadout.get_core_attack_speed_multiplier()
	)
	target_cursor.apply_upgrade(
		loadout.get_cursor_damage_multiplier(),
		loadout.get_cursor_attack_speed_multiplier(),
		loadout.get_cursor_area_multiplier(),
		loadout.get_cursor_control_multiplier(),
		loadout.get_cursor_movement_speed_multiplier()
	)

func _on_core_destroyed() -> void:
	if _is_tutorial():
		GameSession.meta_notice = "튜토리얼이 중단되었습니다. 출격을 눌러 처음부터 다시 시작할 수 있습니다."
		_return_to_menu()
		return
	_finish_game(false)

func _finish_game(victory: bool) -> void:
	if _is_tutorial():
		return
	if game_finished:
		return
	game_finished = true
	audience_stage.react(&"victory" if victory else &"defeat", Color("ffe39a") if victory else Color("8d789c"), 1.0, 3.0)
	_prepare_finished_run(victory)
	_shutdown_combat_runtime()
	var result := _build_and_persist_run_result(victory)
	_present_run_result(result, victory)

func _prepare_finished_run(victory: bool) -> void:
	_reset_game_speed(false)
	_set_range_overlay(false, false)
	reward_queue.reset()
	artifact_reward_resolution_service.reset()
	reward_selection_coordinator.hide_all()
	run_pause_coordinator.finish_run(victory)

func _shutdown_combat_runtime() -> void:
	candidate_death_wave_runtime_service.reset()
	run_shutdown_service.cleanup_combat_runtime(
		enemy_spawner,
		target_cursor,
		core,
		_active_enemies(),
		judaginda_reaper_summon,
		death_wave_controller,
		necromancy_controller,
		get_tree().get_nodes_in_group(&"projectiles"),
		summon_container.get_children(),
		summon_service
	)

func _build_and_persist_run_result(victory: bool) -> Dictionary:
	var top_tower := _highest_damage_tower()
	var result := run_result_service.build_result(stage_data, boss_plan, enemy_spawner, experience, core, target_cursor, loadout, metrics, kill_count, boss_kill_count, top_tower, victory, current_run_id)
	var persisted_result := run_result_service.persist_result(result, metrics, testing_mode)
	if testing_mode or bool(persisted_result.get("settlement_awarded", false)) or bool(persisted_result.get("settlement_duplicate", false)):
		RunCheckpointService.clear_run(current_run_id)
	return result

func _present_run_result(result: Dictionary, victory: bool) -> void:
	hud.show_result(result)
	SignalBus.game_finished.emit(victory)
	AudioManager.play_result(victory)

func _restart_game() -> void:
	var settlement := _settle_abandoned_run()
	if not bool(settlement.get("completed", false)):
		hud.show_notice("체크포인트 저장에 실패했습니다. 재시작하지 않고 현재 출격을 유지합니다.", 4.0)
		return
	_reset_game_speed()
	run_pause_coordinator.clear_for_navigation()
	get_tree().reload_current_scene()

func _return_to_menu() -> void:
	_settle_abandoned_run()
	_reset_game_speed()
	run_pause_coordinator.clear_for_navigation()
	if _is_tutorial():
		GameSession.end_tutorial_run()
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

func _build_checkpoint_result(victory: bool) -> Dictionary:
	return run_result_service.build_checkpoint_result(
		stage_data,
		boss_plan,
		enemy_spawner,
		experience,
		loadout,
		metrics,
		kill_count,
		boss_kill_count,
		victory,
		current_run_id
	)

func _settle_abandoned_run() -> Dictionary:
	if game_finished or testing_mode or _is_tutorial():
		return {"completed": true}
	return RunCheckpointService.settle_pending("abandon", current_run_id)

func _on_viewport_size_changed() -> void:
	core.position = battlefield.get_core_position()
	target_cursor.refresh_layout()
	loadout.refresh_layout()
	range_overlay.refresh()
	for enemy in _active_enemies():
		enemy.set_core_goal_position(battlefield.get_core_goal_position(enemy.target_position.y))

func _active_enemies() -> Array[Enemy]:
	return spatial_index.get_active_enemies()

func _regular_alive_pressure() -> float:
	var pressure := 0.0
	for enemy in _active_enemies():
		if enemy.data != null and not enemy.data.is_boss:
			pressure += maxf(enemy.data.spawn_cost, 0.0)
	return pressure

func _has_active_spawn_boss() -> bool:
	return active_bosses.any(func(enemy: Enemy) -> bool: return is_instance_valid(enemy) and enemy.active)

func _enemy_pool_by_ids(enemy_ids: Array[StringName]) -> Array[EnemyData]:
	var pool: Array[EnemyData] = []
	for enemy_id in enemy_ids:
		var enemy_data := DataRegistry.get_enemy(enemy_id)
		if enemy_data != null and enemy_data.id == enemy_id:
			pool.append(enemy_data)
	return pool

func _count_defeated(enemies: Array[Enemy]) -> int:
	return _defeated_enemies(enemies).size()

func _defeated_enemies(enemies: Array[Enemy]) -> Array[Enemy]:
	var result: Array[Enemy] = []
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.active:
			result.append(enemy)
	return result

func _closest_to_core(enemies: Array[Enemy]) -> Enemy:
	return targeting_service.frontmost_to_core(enemies, core.global_position)

func _cursor_priority_targets(enemies: Array[Enemy]) -> Array[Enemy]:
	return targeting_service.filter_in_radius(enemies, target_cursor.global_position, target_cursor.get_effective_attack_radius() * 1.25)

func _enemies_in_cursor_band(enemies: Array[Enemy], half_width: float) -> Array[Enemy]:
	return targeting_service.filter_in_horizontal_band(enemies, target_cursor.global_position.y, half_width)

func _enemies_near_segment(enemies: Array[Enemy], start: Vector2, end: Vector2, half_width: float) -> Array[Enemy]:
	return enemies.filter(func(enemy: Enemy) -> bool:
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, start, end)
		return enemy.global_position.distance_to(closest) <= half_width
	)

func _sort_targets_along_segment(enemies: Array[Enemy], start: Vector2, end: Vector2) -> void:
	var direction := start.direction_to(end)
	if direction.is_zero_approx():
		direction = Vector2.RIGHT
	enemies.sort_custom(func(left: Enemy, right: Enemy) -> bool:
		var left_progress := (left.global_position - start).dot(direction)
		var right_progress := (right.global_position - start).dot(direction)
		if is_equal_approx(left_progress, right_progress):
			return left.get_instance_id() < right.get_instance_id()
		return left_progress < right_progress
	)

func _closest_to_position(enemies: Array, target_position: Vector2, prefer_boss: bool = false) -> Enemy:
	return targeting_service.closest_to(enemies, target_position, prefer_boss)

func _lowest_health(enemies: Array[Enemy]) -> Enemy:
	return targeting_service.lowest_current_health(enemies, core.global_position)

func _highest_health(enemies: Array[Enemy]) -> Enemy:
	return targeting_service.highest_current_health(enemies, core.global_position)

func _select_target_by_rule(enemies: Array[Enemy], column: TowerColumn, tower: TowerData) -> Enemy:
	return targeting_service.select_by_rule(
		enemies,
		tower.target_rule,
		core.global_position,
		target_cursor.global_position,
		tower.area_radius
	)

func _enemies_in_tower_range(enemies: Array[Enemy], column: TowerColumn, row_index: int, _tower: TowerData) -> Array[Enemy]:
	var origin := column.get_attack_origin(row_index)
	var attack_range := column.get_attack_range(row_index)
	return targeting_service.filter_in_radius(enemies, origin, attack_range)

func _highest_damage_tower() -> String:
	if tower_damage.is_empty():
		return "없음"
	var best_id: StringName
	var best_damage := -1.0
	for id in tower_damage:
		if float(tower_damage[id]) > best_damage:
			best_id = id
			best_damage = tower_damage[id]
	return "%s · %d 피해" % [DataRegistry.get_tower(best_id).display_name, roundi(best_damage)]

func _create_combat_effect(priority: int) -> CombatEffect:
	return combat_presentation_service.create_effect(priority)

func _show_effect(from: Vector2, to: Vector2, color: Color, radius: float = 0.0, intensity: float = 0.2, priority: int = -1) -> void:
	combat_presentation_service.show_trace(from, to, color, radius, intensity, priority)

func _show_impact_effect(at: Vector2, color: Color, radius: float = 0.0, intensity: float = 0.25, priority: int = -1) -> void:
	combat_presentation_service.show_impact(at, color, radius, intensity, priority)

func _present_tower_hit(tower: TowerData, target: Enemy, source_position: Vector2, damage: float, strength_scale: float = 1.0) -> void:
	combat_presentation_service.present_tower_hit(tower, target, source_position, damage, strength_scale)

func _show_burst_effect(at: Vector2, color: Color, radius: float = 110.0, intensity: float = 0.8, priority: int = -1) -> void:
	combat_presentation_service.show_burst(at, color, radius, intensity, priority)

func _show_pattern_effect(at: Vector2, color: Color, radius: float, style: StringName, intensity: float = 0.6, duration: float = 0.55, priority: int = -1) -> void:
	combat_presentation_service.show_pattern(at, color, radius, style, intensity, duration, priority)

func _show_candidate_stamp_effect(at: Vector2, effect_id: StringName, color: Color, radius: float, style: StringName, intensity: float = 0.8, duration: float = 0.6) -> void:
	combat_presentation_service.show_candidate_stamp(at, effect_id, color, radius, style, intensity, duration)

func _show_chain_effect(points: Array[Vector2], color: Color, intensity: float = 0.65, priority: int = -1) -> void:
	combat_presentation_service.show_chain(points, color, intensity, priority)

func _show_target_impacts(targets: Array[Enemy], color: Color, intensity: float, limit: int = 8) -> void:
	combat_presentation_service.show_target_impacts(targets, color, intensity, limit)
