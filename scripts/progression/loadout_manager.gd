class_name LoadoutManager
extends Node

const SPECIALIZATION_ENTRY_CHANCE := 0.58
const SPECIALIZATION_PITY_MISSES := 2
const GUARD_GROWTH_ENTRY_CHANCE := 0.50
const GUARD_GROWTH_PITY_MISSES := 2
const CORE_DAMAGE_LEVEL_CURVE: Array[float] = [0.0, 1.0, 1.50, 1.50, 1.50, 1.50, 1.50, 1.50]
const CORE_HEALTH_LEVEL_CURVE: Array[float] = [0.0, 1.0, 1.0, 1.45, 1.45, 1.45, 1.45, 1.45]
const CORE_REGEN_LEVEL_CURVE: Array[float] = [0.0, 1.0, 1.0, 1.0, 1.0, 2.25, 2.25, 2.25]
const CORE_SKILL_LEVEL_CURVE: Array[float] = [0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 2.0, 2.0]
const CURSOR_DAMAGE_LEVEL_CURVE: Array[float] = [0.0, 1.0, 1.55, 1.55, 1.55, 1.55, 1.55, 1.55]
const CURSOR_CONTROL_LEVEL_CURVE: Array[float] = [0.0, 1.0, 1.0, 1.55, 1.55, 1.55, 1.55, 1.55]
const CURSOR_MOVEMENT_LEVEL_CURVE: Array[float] = [0.0, 1.0, 1.0, 1.0, 1.0, 1.50, 1.50, 1.50]
const CURSOR_AREA_LEVEL_CURVE: Array[float] = [0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.45, 1.45]

signal tower_attack_requested(column: TowerColumn, row_index: int)
signal loadout_changed(summary: String)
signal effects_changed(global_effects: Array)
signal artifacts_changed(artifacts: Array)
signal upgrade_applied(title: String)

var columns: Array[TowerColumn] = []
var tower_type_levels: Dictionary = {}
var tower_branch_ids: Dictionary = {}
var core_state := GrowthTrackState.new()
var cursor_state := GrowthTrackState.new()
var retainer_progression := RetainerProgressionService.new()
var candidate_progression := CandidateProgressionService.new()
var guard_progression := GuardProgressionService.new()
var overgrowth_service := OvergrowthService.new()
var artifact_catalog := load(ArtifactEffectResolver.CATALOG_PATH) as ArtifactCatalogData
var artifact_inventory := ArtifactInventoryState.new()
var artifact_effect_resolver := ArtifactEffectResolver.new(artifact_catalog, artifact_inventory)
var artifact_eligibility_service := ArtifactEligibilityService.new()
var candidate_stage_buff_active: bool = false
var candidate_execution_stacks: int = 0
var candidate_abyss_stacks: int = 0
var candidate_abyss_boss_damage_progress: float = 0.0
var candidate_soul_stacks: int = 0
var global_upgrade_level: int = 0
var defense_stat_resolver := DefenseStatResolver.new()
var additional_defense_axis_bonuses: Dictionary = {&"power": 0.0, &"speed": 0.0, &"range": 0.0}
var selected_global_effects: Dictionary = {}
var status_upgrade_levels: Dictionary = {
	&"poison": 0,
	&"burn": 0,
	&"bleed": 0,
	&"shock": 0,
}
var battlefield: Battlefield
var column_container: Node2D
var suppress_column_events: bool = false
var active_decree: CandidateDecreeData
var stat_calculator := LoadoutStatCalculator.new()
var upgrade_application_service := LoadoutUpgradeApplicationService.new()
var placement_service := FormationPlacementService.new()
var offer_service := UpgradeOfferService.new(SPECIALIZATION_ENTRY_CHANCE, SPECIALIZATION_PITY_MISSES, GUARD_GROWTH_ENTRY_CHANCE, GUARD_GROWTH_PITY_MISSES)
var specialization_policy: SpecializationOfferPolicy:
	get: return offer_service.specialization_policy
var guard_growth_offer_policy: SpecializationOfferPolicy:
	get: return offer_service.guard_growth_policy
var board_state: FormationBoardState:
	get: return placement_service.board_state
var placed_formation_slices: Dictionary:
	get: return placement_service.placed_formation_slices
var specialization_offer_misses: int:
	get: return specialization_policy.offer_misses
	set(value): specialization_policy.offer_misses = value
var specialization_entry_waits: Dictionary:
	get: return specialization_policy.entry_waits
	set(value): specialization_policy.entry_waits = value

func setup(target_battlefield: Battlefield, container: Node2D) -> void:
	battlefield = target_battlefield
	column_container = container
	core_state = GrowthTrackState.new(GameSession.selected_core_id)
	active_decree = MetaProgressionService.get_candidate_decree(GameSession.selected_decree_id)
	var campaign := ConceptService.get_election_campaign()
	var candidate := campaign.candidate_for_core(GameSession.selected_core_id) if campaign != null else null
	var retainer := campaign.retainer_for_cursor(GameSession.selected_cursor_id) if campaign != null else null
	retainer_progression.configure(retainer.growth_data if retainer != null else null, GrowthTrackState.new(GameSession.selected_cursor_id))
	# Cursor state remains the save/checkpoint compatibility view of the authoritative retainer state.
	cursor_state = retainer_progression.state
	candidate_progression.configure(candidate.growth_data if candidate != null else null)
	guard_progression.configure(candidate.guard_growth_data if candidate != null else null)
	overgrowth_service.reset()
	artifact_inventory.reset()
	global_upgrade_level = 0
	guard_growth_offer_policy.restore_state({})
	candidate_stage_buff_active = false
	candidate_execution_stacks = 0
	candidate_abyss_stacks = 0
	candidate_abyss_boss_damage_progress = 0.0
	candidate_soul_stacks = 0
	additional_defense_axis_bonuses = {&"power": 0.0, &"speed": 0.0, &"range": 0.0}
	stat_calculator.configure(_stat_curve_config(), core_state, cursor_state, active_decree)
	suppress_column_events = true
	columns.clear()
	placement_service.configure(
		FormationBoardState.new(battlefield.column_count, battlefield.lane_count),
		battlefield,
		column_container,
		columns,
		tower_type_levels,
		tower_branch_ids,
		Callable(self, "_forward_tower_attack_requested"),
		Callable(self, "_on_column_state_changed")
	)
	offer_service.configure(
		Callable(self, "_random_tower_level_choice"),
		Callable(self, "_growth_track_choice"),
		Callable(self, "_random_status_upgrade_choice"),
		Callable(self, "_fallback_choice"),
		Callable(self, "get_specialization_entry_choices"),
		Callable(self, "get_guard_growth_choice"),
		Callable(self, "_formation_offer_context"),
		Callable(self, "_overgrowth_choice"),
		Callable(self, "get_eligible_artifacts")
	)
	offer_service.artifact_offer_service.mode = GameSession.artifact_mode if GameSession.artifact_mode in GameSession.ARTIFACT_MODES else GameSession.ARTIFACT_MODE_NORMAL
	offer_service.reset_run_state()
	suppress_column_events = false
	_emit_summary()

func set_random_artifact_offers_enabled(enabled: bool) -> void:
	var requested_mode := GameSession.artifact_mode if GameSession.artifact_mode in GameSession.ARTIFACT_MODES else GameSession.ARTIFACT_MODE_NORMAL
	offer_service.artifact_offer_service.mode = requested_mode if enabled or requested_mode != GameSession.ARTIFACT_MODE_NORMAL else GameSession.ARTIFACT_MODE_DISABLED

func get_valid_board_placements(formation: TowerFormationData) -> Array[Dictionary]:
	return board_state.valid_placements(formation)

func can_place_formation_block(formation: TowerFormationData, anchor: Vector2i, vertical_flipped: bool = false) -> bool:
	return board_state.can_place(formation, anchor, vertical_flipped)

func place_formation_block(formation: TowerFormationData, anchor: Vector2i, vertical_flipped: bool = false, guard: bool = false, requested_id: StringName = &"") -> StringName:
	var result := placement_service.place(formation, anchor, vertical_flipped, guard, requested_id)
	var owner_id := result.owner_id as StringName
	if owner_id == &"":
		return &""
	for tower_id in result.tower_ids as Array:
		if not tower_type_levels.has(tower_id):
			tower_type_levels[tower_id] = 1
			SignalBus.tower_type_activated.emit(tower_id)
	if not guard and not formation.is_guard:
		SaveManager.mark_tower_use_discovered(formation.get_tower_ids())
	SignalBus.formation_equipped.emit(anchor.x, formation)
	_refresh_runtime_bonuses()
	_emit_summary()
	return owner_id

func remove_formation_block(owner_id: StringName) -> bool:
	if not placement_service.remove(owner_id):
		return false
	_emit_summary()
	return true

func get_board_snapshot() -> Array[Dictionary]:
	return board_state.build_snapshot()

func refresh_layout() -> void:
	for column in columns:
		column.position.x = battlefield.get_column_x(column.column_index)
		column.queue_redraw()

func generate_upgrade_choices() -> Array[UpgradeData]:
	return offer_service.generate(board_state, get_formation_choice_pool(), global_upgrade_level)

func get_formation_set_size(choice: UpgradeData) -> int:
	return offer_service.formation_set_size(choice)

func get_formation_candidates(size: int, limit: int = 3) -> Array[UpgradeData]:
	return offer_service.formation_candidates(board_state, get_formation_choice_pool(), size, limit)

func get_offer_state_snapshot() -> Dictionary:
	return offer_service.get_state_snapshot()

func restore_offer_state(snapshot: Dictionary) -> void:
	offer_service.restore_state(snapshot)

func generate_rerolled_upgrade_choices(previous_choices: Array[UpgradeData], max_attempts: int = 4) -> Array[UpgradeData]:
	return offer_service.generate_rerolled(previous_choices, board_state, get_formation_choice_pool(), global_upgrade_level, max_attempts)

func _upgrade_choice_signature(choices: Array[UpgradeData]) -> String:
	return offer_service.signature(choices)

func is_specialization_entry(choice: UpgradeData) -> bool:
	return choice != null and choice.category in [&"tower_specialization_entry", &"core_specialization_entry", &"cursor_specialization_entry", &"guard_specialization_entry"]

func get_specialization_entry_choices() -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	for tower_id in get_installed_tower_ids():
		if get_tower_type_level(tower_id) == 3 and get_tower_branch_id(tower_id) == &"":
			var tower := DataRegistry.get_tower(tower_id)
			result.append(_choice(
				&"tower_specialization_entry",
				"%s Lv.4 특화" % tower.display_name,
				"%s의 전투 역할을 결정합니다.\n선택하면 3개의 전용 특화를 확인합니다." % tower.display_name,
				tower_id
			))
	if not is_candidate_growth_enabled() and core_state.requires_branch_choice():
		result.append(_choice(
			&"core_specialization_entry",
			"핵 Lv.4 특화",
			"선택한 핵의 고유 기능을 강화합니다.\n선택하면 3개의 전용 특화를 확인합니다.",
			core_state.id
		))
	if cursor_state.requires_branch_choice():
		result.append(_choice(
			&"cursor_specialization_entry",
			"심복 Lv.4 특화",
			"선택한 심복의 전투 방식을 결정합니다.\n선택하면 3개의 전용 특화를 확인합니다.",
			cursor_state.id
		))
	return result

func get_specialization_subchoices(entry: UpgradeData) -> Array[UpgradeData]:
	if not is_specialization_entry(entry):
		return []
	match entry.category:
		&"tower_specialization_entry":
			if get_tower_type_level(entry.data_id) != 3 or get_tower_branch_id(entry.data_id) != &"":
				return []
			var result: Array[UpgradeData] = []
			var tower := DataRegistry.get_tower(entry.data_id)
			for branch in DataRegistry.get_tower_branches(entry.data_id):
				var level_4_stats := "  /  ".join(_tower_branch_stat_lines(branch.id, branch.level_4_modifiers))
				var level_7_stats := "  /  ".join(_tower_branch_stat_lines(branch.id, branch.level_7_modifiers))
				result.append(_choice(&"tower_branch", branch.display_name, "%s Lv.4 · %s\nLv.4 수치 · %s\nLv.7 완성 수치 · %s" % [tower.display_name, branch.description, level_4_stats, level_7_stats], branch.id))
			return result
		&"core_specialization_entry":
			if not core_state.requires_branch_choice() or entry.data_id != core_state.id:
				return []
			return _track_branch_choices(false)
		&"cursor_specialization_entry":
			if not cursor_state.requires_branch_choice() or entry.data_id != cursor_state.id:
				return []
			return _track_branch_choices(true)
		&"guard_specialization_entry":
			if not guard_progression.is_enabled() or guard_progression.get_stage() != 1:
				return []
			var result: Array[UpgradeData] = []
			for specialization in guard_progression.get_specializations():
				result.append(_choice(
					&"guard_branch",
					specialization.display_name,
					"친위대 특화 · %s\n완성 효과 · %s" % [specialization.description, specialization.completion_description],
					specialization.id
				))
			return result
	return []

func get_guard_growth_choice() -> UpgradeData:
	if not guard_progression.is_enabled():
		return null
	match guard_progression.get_stage():
		0:
			return _choice(&"guard_training", guard_progression.growth_data.training_display_name, guard_progression.growth_data.training_description, guard_progression.growth_data.formation_id)
		1:
			return _choice(&"guard_specialization_entry", "친위대 특화 선택", "이번 런에서 사용할 친위대 특화 하나를 선택합니다. 선택 후 다른 특화로 변경할 수 없습니다.", guard_progression.growth_data.formation_id)
		2:
			var specialization := guard_progression.get_selected_specialization()
			if specialization != null:
				return _choice(&"guard_completion", "%s 완성" % specialization.display_name, specialization.completion_description, specialization.id)
	return null

func apply_upgrade(choice: UpgradeData) -> bool:
	if choice == null:
		return false
	suppress_column_events = true
	var applied := false
	match choice.category:
		&"new_formation":
			var formation := DataRegistry.find_formation(choice.data_id)
			if formation != null and not formation.is_guard and choice.board_anchor.x >= 0:
				choice.placement_id = place_formation_block(formation, choice.board_anchor, choice.vertical_flip)
				applied = choice.placement_id != &""
		&"candidate_overgrowth", &"retainer_overgrowth":
			applied = overgrowth_service.apply(choice.data_id, is_candidate_growth_complete(), is_retainer_growth_complete())
		_:
			var growth_result := upgrade_application_service.apply(choice, _upgrade_application_state(), is_candidate_growth_enabled())
			if bool(growth_result.handled):
				applied = bool(growth_result.applied)
				global_upgrade_level = int(growth_result.global_upgrade_level)
	if not applied:
		suppress_column_events = false
		return false
	_sync_columns()
	_refresh_runtime_bonuses()
	suppress_column_events = false
	upgrade_applied.emit(choice.display_name)
	_emit_summary()
	return true

func _upgrade_application_state() -> Dictionary:
	return {
		"tower_type_levels": tower_type_levels,
		"tower_branch_ids": tower_branch_ids,
		"core_state": core_state,
		"cursor_state": cursor_state,
		"guard_progression": guard_progression,
		"global_upgrade_level": global_upgrade_level,
		"selected_global_effects": selected_global_effects,
		"status_upgrade_levels": status_upgrade_levels,
	}

func get_tower_type_level(tower_id: StringName) -> int:
	return int(tower_type_levels.get(tower_id, 0))

func get_tower_branch_id(tower_id: StringName) -> StringName:
	return tower_branch_ids.get(tower_id, &"") as StringName

func get_installed_tower_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for column in columns:
		for tower in column.row_towers:
			if tower != null and tower.id not in result:
				result.append(tower.id)
	return result

func get_formation_choice_pool() -> Array[TowerFormationData]:
	# 편대는 소유형 수집품이 아니라 설치 레시피다. 이미 설치한 레시피도 빈 열이 있는 동안 계속 등장한다.
	var regular_formations := DataRegistry.formations.filter(func(formation: TowerFormationData) -> bool: return not formation.is_unique())
	return MetaProgressionService.filter_unlocked_formations(regular_formations)

func get_eligible_artifacts() -> Array[ArtifactData]:
	return artifact_eligibility_service.eligible_artifacts(artifact_catalog, _artifact_eligibility_context())

func is_artifact_eligible(artifact: ArtifactData) -> bool:
	return artifact_eligibility_service.is_eligible(artifact, _artifact_eligibility_context())

func equip_artifact(artifact_id: StringName) -> bool:
	var artifact := artifact_catalog.find_artifact(artifact_id) if artifact_catalog != null else null
	if not is_artifact_eligible(artifact) or not artifact_inventory.equip(artifact_id):
		return false
	_refresh_runtime_bonuses()
	_emit_summary()
	return true

func replace_artifact(slot_index: int, artifact_id: StringName) -> bool:
	var artifact := artifact_catalog.find_artifact(artifact_id) if artifact_catalog != null else null
	if not is_artifact_eligible(artifact) or not artifact_inventory.replace(slot_index, artifact_id):
		return false
	_refresh_runtime_bonuses()
	_emit_summary()
	return true

func remove_artifact(slot_index: int) -> bool:
	if not artifact_inventory.remove_at(slot_index):
		return false
	_refresh_runtime_bonuses()
	_emit_summary()
	return true

func get_artifact_snapshot() -> Dictionary:
	return artifact_inventory.snapshot()

func get_artifact_presentations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for artifact_id in artifact_inventory.artifact_ids:
		var artifact := artifact_catalog.find_artifact(artifact_id) if artifact_catalog != null else null
		if artifact == null:
			continue
		result.append({
			"id": String(artifact.id),
			"name": artifact.display_name,
			"subtitle": "아티팩트 · 1칸",
			"description": artifact.description,
			"icon": artifact.icon_key,
			"color": artifact.color,
			"level": 1,
			"trade_off": artifact.has_trade_off(),
		})
	return result

func get_equipped_artifacts() -> Array[ArtifactData]:
	return artifact_effect_resolver.active_artifacts()

func restore_artifact_snapshot(snapshot: Dictionary) -> void:
	artifact_inventory.restore(snapshot, artifact_catalog)
	_refresh_runtime_bonuses()
	_emit_summary()

func _artifact_eligibility_context() -> Dictionary:
	var status_source_ids: Array[StringName] = []
	for status_id in CommonStatusCatalog.STATUS_IDS:
		if has_common_status_application_source(status_id):
			status_source_ids.append(status_id)
	var roles: Array[StringName] = []
	var guard_available := false
	if board_state != null:
		for placement in board_state.placements.values():
			var placement_data := placement as Dictionary
			if bool(placement_data.get("is_guard", false)):
				guard_available = true
				continue
			var formation := DataRegistry.get_formation(StringName(placement_data.get("formation_id", "")))
			if formation != null:
				for role in formation.role_tags:
					if role not in roles:
						roles.append(role)
	return {
		"installed_tower_ids": get_installed_tower_ids(),
		"role_tags": roles,
		"status_source_ids": status_source_ids,
		"candidate_available": is_candidate_growth_enabled(),
		"retainer_available": retainer_progression.is_enabled(),
		"guard_available": guard_available,
		"equipped_artifact_ids": artifact_inventory.artifact_ids.duplicate(),
	}

func _formation_offer_context() -> Dictionary:
	var current_roles: Array[StringName] = []
	for placement in board_state.placements.values():
		var formation := DataRegistry.get_formation(StringName((placement as Dictionary).get("formation_id", "")))
		if formation == null or formation.is_guard:
			continue
		for role in formation.role_tags:
			if role not in current_roles:
				current_roles.append(role)
	return {
		"installed_tower_ids": get_installed_tower_ids(),
		"tower_levels": tower_type_levels.duplicate(),
		"tower_branches": tower_branch_ids.duplicate(),
		"current_role_tags": current_roles,
		"discovered_tower_use_ids": SaveManager.discovered_tower_use_ids.duplicate(),
	}

func get_tower_damage_multiplier() -> float:
	_sync_stat_calculator()
	return stat_calculator.tower_damage_multiplier(0) * _candidate_multiplier(&"tower_damage") * _candidate_stage_multiplier(&"charm_stage_damage")

func get_axis_independent_tower_damage_multiplier() -> float:
	_sync_stat_calculator()
	return stat_calculator.tower_damage_multiplier(0) * _candidate_multiplier(&"tower_damage") * _candidate_stage_multiplier(&"charm_stage_damage")

func get_tower_speed_multiplier() -> float:
	_sync_stat_calculator()
	return CombatModifierResolver.additive_multiplier([
		stat_calculator.tower_speed_multiplier(0),
		_candidate_multiplier(&"tower_speed"),
		_candidate_diversity_range_speed_multiplier(),
		_candidate_stage_multiplier(&"charm_stage_speed"),
	])

func get_axis_independent_tower_speed_multiplier() -> float:
	_sync_stat_calculator()
	return CombatModifierResolver.additive_multiplier([
		stat_calculator.tower_speed_multiplier(0),
		_candidate_multiplier(&"tower_speed"),
		_candidate_diversity_range_speed_multiplier(),
		_candidate_stage_multiplier(&"charm_stage_speed"),
	])

func get_tower_range_multiplier() -> float:
	return _candidate_diversity_range_speed_multiplier()

func get_defense_axis_bonuses() -> Dictionary:
	var artifact_bonuses := artifact_effect_resolver.defense_axis_bonuses()
	return {
		&"power": float(additional_defense_axis_bonuses.get(&"power", 0.0)) + float(artifact_bonuses.get(&"power", 0.0)),
		&"speed": float(additional_defense_axis_bonuses.get(&"speed", 0.0)) + float(artifact_bonuses.get(&"speed", 0.0)),
		&"range": float(additional_defense_axis_bonuses.get(&"range", 0.0)) + float(artifact_bonuses.get(&"range", 0.0)),
	}

func set_additional_defense_axis_bonus(axis_id: StringName, bonus: float) -> void:
	if axis_id not in DefenseStatCatalogData.REQUIRED_AXIS_IDS:
		return
	additional_defense_axis_bonuses[axis_id] = bonus
	_refresh_runtime_bonuses()

func get_core_damage_multiplier() -> float:
	_sync_stat_calculator()
	var candidate_core_damage := _candidate_multiplier(&"core_damage") + candidate_execution_stacks * maxf(float(get_candidate_modifier(&"execution_growth_per_stack", 0.0)), 0.0)
	return stat_calculator.core_damage_multiplier(get_core_branch_modifiers()) * candidate_core_damage * _candidate_stage_multiplier(&"charm_stage_damage") * overgrowth_service.get_multiplier(&"candidate", &"damage") * artifact_effect_resolver.multiplier(&"candidate", &"damage")

func get_core_health_multiplier() -> float:
	_sync_stat_calculator()
	return stat_calculator.core_health_multiplier(get_core_branch_modifiers()) * _candidate_multiplier(&"core_health")

func get_core_regeneration_multiplier() -> float:
	_sync_stat_calculator()
	return stat_calculator.core_regeneration_multiplier(get_core_branch_modifiers()) * _candidate_multiplier(&"core_regeneration")

func get_core_breach_damage_multiplier() -> float:
	return _candidate_multiplier(&"core_breach_damage")

func get_skill_charge_multiplier() -> float:
	_sync_stat_calculator()
	return stat_calculator.decree_multiplier(&"skill_charge")

func get_core_skill_damage_multiplier() -> float:
	_sync_stat_calculator()
	return stat_calculator.core_skill_damage_multiplier(get_core_branch_modifiers()) * _candidate_multiplier(&"core_skill_damage") * _candidate_stage_multiplier(&"charm_stage_damage") * overgrowth_service.get_multiplier(&"candidate", &"skill") * artifact_effect_resolver.multiplier(&"candidate", &"skill")

func get_core_attack_speed_multiplier() -> float:
	_sync_stat_calculator()
	return CombatModifierResolver.additive_multiplier([
		stat_calculator.core_attack_speed_multiplier(get_core_branch_modifiers()),
		_candidate_multiplier(&"core_attack_speed"),
		_candidate_stage_multiplier(&"charm_stage_speed"),
		get_guard_martyr_speed_multiplier(),
	])

func get_cursor_damage_multiplier() -> float:
	_sync_stat_calculator()
	return stat_calculator.cursor_damage_multiplier(get_cursor_branch_modifiers()) * _candidate_stage_multiplier(&"charm_stage_damage") * overgrowth_service.get_multiplier(&"retainer", &"damage") * artifact_effect_resolver.multiplier(&"retainer", &"damage")

func get_cursor_attack_speed_multiplier() -> float:
	_sync_stat_calculator()
	return CombatModifierResolver.additive_multiplier([
		stat_calculator.decree_multiplier(&"cursor_attack_speed"),
		_candidate_stage_multiplier(&"charm_stage_speed"),
		overgrowth_service.get_multiplier(&"retainer", &"action_speed"),
		artifact_effect_resolver.multiplier(&"retainer", &"action_speed"),
	])

func get_cursor_movement_speed_multiplier() -> float:
	_sync_stat_calculator()
	return stat_calculator.cursor_movement_speed_multiplier(get_cursor_branch_modifiers()) * overgrowth_service.get_multiplier(&"retainer", &"movement") * artifact_effect_resolver.multiplier(&"retainer", &"movement")

func get_cursor_area_multiplier() -> float:
	_sync_stat_calculator()
	return stat_calculator.cursor_area_multiplier(get_cursor_branch_modifiers()) * overgrowth_service.get_multiplier(&"retainer", &"collection")

func get_cursor_control_multiplier() -> float:
	_sync_stat_calculator()
	return stat_calculator.cursor_control_multiplier(get_cursor_branch_modifiers())

func _decree_multiplier(stat_key: StringName) -> float:
	_sync_stat_calculator()
	return stat_calculator.decree_multiplier(stat_key)

func _sync_stat_calculator() -> void:
	stat_calculator.configure(_stat_curve_config(), core_state, cursor_state, active_decree)

func get_core_branch() -> SpecializationBranchData:
	return DataRegistry.get_specialization_branch(core_state.selected_branch_id)

func get_cursor_branch() -> SpecializationBranchData:
	return DataRegistry.get_specialization_branch(cursor_state.selected_branch_id)

func get_core_branch_modifiers() -> Dictionary:
	var branch := get_core_branch()
	return branch.get_modifiers(core_state.current_level >= 7) if branch != null else {}

func get_cursor_branch_modifiers() -> Dictionary:
	if retainer_progression != null and retainer_progression.is_enabled():
		if cursor_state != retainer_progression.state:
			retainer_progression.state.import_legacy_state(cursor_state)
		return retainer_progression.get_modifiers()
	var branch := get_cursor_branch()
	return branch.get_modifiers(cursor_state.current_level >= 7) if branch != null else {}

func get_retainer_growth_snapshot() -> Dictionary:
	return retainer_progression.get_snapshot() if retainer_progression != null else {}

func has_core_final_trait(branch_id: StringName = &"") -> bool:
	return core_state.current_level >= 7 and core_state.selected_branch_id != &"" and (branch_id == &"" or core_state.selected_branch_id == branch_id)

func has_cursor_final_trait(branch_id: StringName = &"") -> bool:
	return cursor_state.current_level >= 7 and cursor_state.selected_branch_id != &"" and (branch_id == &"" or cursor_state.selected_branch_id == branch_id)

func get_experience_multiplier() -> float:
	return 1.0

func is_candidate_growth_enabled() -> bool:
	return candidate_progression.is_enabled()

func is_candidate_growth_complete() -> bool:
	return candidate_progression.is_growth_complete()

func is_retainer_growth_complete() -> bool:
	return retainer_progression.is_growth_complete()

func get_overgrowth_snapshot() -> Dictionary:
	return overgrowth_service.snapshot()

func get_candidate_branch_choices(slot_index: int = 1) -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	for branch in candidate_progression.get_branch_upgrades(slot_index):
		result.append(_choice(&"candidate_branch", branch.display_name, branch.description, branch.id))
	return result

func claim_candidate_fixed_upgrade(slot_index: int) -> CandidateUpgradeData:
	var upgrade := candidate_progression.claim_fixed_slot(slot_index)
	if upgrade != null:
		_refresh_runtime_bonuses()
		upgrade_applied.emit(upgrade.display_name)
		_emit_summary()
	return upgrade

func apply_candidate_branch(choice: UpgradeData) -> bool:
	if choice == null or choice.category != &"candidate_branch":
		return false
	var branch := candidate_progression.select_branch(choice.data_id)
	if branch == null:
		return false
	_refresh_runtime_bonuses()
	upgrade_applied.emit(branch.display_name)
	_emit_summary()
	return true

func get_candidate_growth_snapshot() -> Dictionary:
	var snapshot := candidate_progression.snapshot()
	snapshot["execution_stacks"] = candidate_execution_stacks
	snapshot["abyss_presence_stacks"] = candidate_abyss_stacks
	snapshot["abyss_boss_damage_progress"] = candidate_abyss_boss_damage_progress
	snapshot["soul_stacks"] = candidate_soul_stacks
	return snapshot

func get_guard_growth_snapshot() -> Dictionary:
	return guard_progression.snapshot()

func add_guard_runtime_value(key: StringName, amount: float, maximum: float) -> float:
	return guard_progression.add_runtime_value(key, amount, maximum)

func consume_guard_runtime_value(key: StringName) -> float:
	return guard_progression.consume_runtime_value(key)

func get_guard_runtime_value(key: StringName) -> float:
	return guard_progression.get_runtime_value(key)

func record_candidate_execution() -> bool:
	var per_stack := float(get_candidate_modifier(&"execution_growth_per_stack", 0.0))
	var stack_cap := maxi(int(get_candidate_modifier(&"execution_growth_cap", 0)), 0)
	if per_stack <= 0.0 or stack_cap <= 0 or candidate_execution_stacks >= stack_cap:
		return false
	candidate_execution_stacks += 1
	return true

func get_candidate_execution_damage_multiplier() -> float:
	var per_stack := maxf(float(get_candidate_modifier(&"execution_growth_per_stack", 0.0)), 0.0)
	return 1.0 + candidate_execution_stacks * per_stack

func record_candidate_abyss_defeat(enemy_data: EnemyData) -> int:
	if not bool(get_candidate_modifier(&"abyss_presence", false)) or enemy_data == null or enemy_data.is_boss:
		return candidate_abyss_stacks
	var gained := int(get_candidate_modifier(&"abyss_presence_elite_stacks", 4)) if enemy_data.is_elite else int(get_candidate_modifier(&"abyss_presence_normal_stacks", 1))
	return _add_candidate_abyss_stacks(gained)

func record_candidate_abyss_boss_damage(damage_ratio: float) -> int:
	if not bool(get_candidate_modifier(&"abyss_presence", false)) or damage_ratio <= 0.0 or is_candidate_abyss_presence_ready():
		return candidate_abyss_stacks
	var ratio_per_stack := maxf(float(get_candidate_modifier(&"abyss_presence_boss_damage_ratio", 0.08)), 0.001)
	candidate_abyss_boss_damage_progress += damage_ratio
	var gained := floori((candidate_abyss_boss_damage_progress + 0.000001) / ratio_per_stack)
	if gained > 0:
		candidate_abyss_boss_damage_progress = maxf(candidate_abyss_boss_damage_progress - gained * ratio_per_stack, 0.0)
		_add_candidate_abyss_stacks(gained)
	return candidate_abyss_stacks

func is_candidate_abyss_presence_ready() -> bool:
	var threshold := maxi(int(get_candidate_modifier(&"abyss_presence_threshold", 0)), 0)
	return threshold > 0 and candidate_abyss_stacks >= threshold

func consume_candidate_abyss_presence() -> bool:
	if not is_candidate_abyss_presence_ready():
		return false
	var threshold := maxi(int(get_candidate_modifier(&"abyss_presence_threshold", 0)), 0)
	candidate_abyss_stacks = maxi(candidate_abyss_stacks - threshold, 0)
	return true

func _add_candidate_abyss_stacks(amount: int) -> int:
	var threshold := maxi(int(get_candidate_modifier(&"abyss_presence_threshold", 0)), 0)
	if threshold <= 0 or amount <= 0:
		return candidate_abyss_stacks
	candidate_abyss_stacks = mini(candidate_abyss_stacks + amount, threshold)
	if candidate_abyss_stacks >= threshold:
		candidate_abyss_boss_damage_progress = 0.0
	return candidate_abyss_stacks

func record_candidate_souls(amount: int = 1) -> int:
	if not bool(get_candidate_modifier(&"soul_harvest", false)) or amount <= 0:
		return candidate_soul_stacks
	var stack_cap := maxi(int(get_candidate_modifier(&"soul_harvest_cap", 300)), 0)
	candidate_soul_stacks = mini(candidate_soul_stacks + amount, stack_cap)
	return candidate_soul_stacks

func consume_candidate_souls() -> int:
	var consumed := candidate_soul_stacks
	candidate_soul_stacks = 0
	return consumed

static func candidate_soul_effective_value(stacks: int) -> float:
	return CandidateDeathWaveLaunchService.effective_soul_value(stacks)

func get_guard_damage_multiplier() -> float:
	return _candidate_multiplier(&"guard_damage") * float(get_guard_modifier(&"guard_damage", 1.0)) * artifact_effect_resolver.multiplier(&"guard", &"damage")

func get_guard_speed_multiplier() -> float:
	return CombatModifierResolver.additive_multiplier([
		_candidate_multiplier(&"guard_speed"),
		float(get_guard_modifier(&"guard_speed", 1.0)),
		get_guard_martyr_speed_multiplier(),
		artifact_effect_resolver.multiplier(&"guard", &"action_speed"),
	])

func get_guard_martyr_speed_multiplier() -> float:
	if not bool(get_guard_modifier(&"guard_martyrdom", false)):
		return 1.0
	var stack_cap := maxi(int(get_guard_modifier(&"guard_martyr_max_stacks", 30)), 1)
	var stacks := minf(get_guard_runtime_value(&"martyr"), stack_cap)
	var per_stack := maxf(float(get_guard_modifier(&"guard_martyr_speed_per_stack", 0.005)), 0.0)
	var bonus_cap := maxf(float(get_guard_modifier(&"guard_martyr_speed_bonus_cap", 0.15)), 0.0)
	return 1.0 + CombatModifierResolver.resolve_permanent_attack_speed_bonus(stacks * per_stack, bonus_cap)

func get_guard_range_multiplier() -> float:
	return float(get_guard_modifier(&"guard_range", 1.0)) * artifact_effect_resolver.multiplier(&"guard", &"range")

func get_guard_modifier(key: StringName, default_value: Variant = null) -> Variant:
	var modifiers := guard_progression.merged_modifiers()
	return modifiers.get(String(key), modifiers.get(key, default_value))

func get_guard_modifiers() -> Dictionary:
	return guard_progression.merged_modifiers().duplicate(true)

func candidate_requests_guard_reinforcement() -> bool:
	return int(candidate_progression.merged_modifiers().get("guard_reinforcement_cells", 0)) > 0

func get_candidate_modifier(key: StringName, default_value: Variant = null) -> Variant:
	var modifiers := candidate_progression.merged_modifiers()
	return modifiers.get(String(key), modifiers.get(key, default_value))

func get_candidate_modifiers() -> Dictionary:
	return candidate_progression.merged_modifiers().duplicate(true)

func has_candidate_modifier(key: StringName) -> bool:
	var modifiers := candidate_progression.merged_modifiers()
	return modifiers.has(String(key)) or modifiers.has(key)

func set_candidate_stage_buff_active(active: bool) -> void:
	if candidate_stage_buff_active == active:
		return
	candidate_stage_buff_active = active
	_refresh_runtime_bonuses()
	_emit_summary()

func _candidate_multiplier(stat_key: StringName) -> float:
	return float(get_candidate_modifier(stat_key, 1.0))

func _candidate_stage_multiplier(stat_key: StringName) -> float:
	return float(get_candidate_modifier(stat_key, 1.0)) if candidate_stage_buff_active else 1.0

func _candidate_diversity_range_speed_multiplier() -> float:
	if not bool(candidate_progression.merged_modifiers().get("diversity_scaling", false)):
		return 1.0
	var general_types := 0
	for tower_id in get_installed_tower_ids():
		var tower := DataRegistry.find_tower(tower_id)
		if tower != null and &"unique" not in tower.tags:
			general_types += 1
	if general_types >= 9: return 1.20
	if general_types >= 7: return 1.15
	if general_types >= 5: return 1.10
	if general_types >= 3: return 1.05
	return 1.0

func get_status_upgrade_level(status_id: StringName) -> int:
	return int(status_upgrade_levels.get(status_id, 0))

func get_common_status_profile(status_id: StringName) -> Dictionary:
	var level := get_status_upgrade_level(status_id)
	if level <= 0:
		return {}
	return _common_status_profile_at_level(status_id, level)

func get_common_status_source_profile(status_id: StringName) -> Dictionary:
	return _common_status_profile_at_level(status_id, get_status_upgrade_level(status_id))

func get_common_status_profile_for_attack(column: TowerColumn, tower: TowerData, status_id: StringName) -> Dictionary:
	if not can_tower_apply_common_status(column, tower, status_id):
		return {}
	return _common_status_profile_at_level(status_id, get_status_upgrade_level(status_id))

func can_tower_apply_common_status(column: TowerColumn, tower: TowerData, status_id: StringName) -> bool:
	return tower != null and (CommonStatusCatalog.tower_applies_on_hit(tower, status_id) or (column != null and CommonStatusCatalog.branch_applies_on_hit(column.get_branch_modifiers(tower.id), status_id)))

func _common_status_profile_at_level(status_id: StringName, level: int) -> Dictionary:
	return artifact_effect_resolver.apply_status_profile(status_id, CommonStatusCatalog.profile_at_level(status_id, level))

func get_build_summary() -> String:
	var formation_parts: Array[String] = []
	for placement in board_state.build_snapshot():
		var formation := DataRegistry.get_formation(StringName(placement.formation_id))
		if formation == null:
			continue
		var guard_mark := "★" if bool(placement.is_guard) else ""
		var flip_mark := "↕" if bool(placement.vertical_flipped) else ""
		formation_parts.append("%s%s%s(%d열 %d행)" % [guard_mark, flip_mark, formation.display_name, int(placement.anchor_x) + 1, int(placement.anchor_y) + 1])
	var level_parts: Array[String] = []
	for tower_id in get_installed_tower_ids():
		var tower := DataRegistry.get_tower(tower_id)
		var branch := DataRegistry.get_tower_branch(get_tower_branch_id(tower_id))
		var branch_mark := " · %s%s" % [branch.display_name, " 완성" if get_tower_type_level(tower_id) >= 7 else ""] if branch != null else ""
		level_parts.append("%s L%d%s" % [tower.display_name.replace(" 타워", ""), get_tower_type_level(tower_id), branch_mark])
	var core_branch := _track_branch_name(core_state.selected_branch_id)
	var cursor_branch := _track_branch_name(cursor_state.selected_branch_id)
	if core_state.current_level >= 7 and core_branch != "":
		core_branch += " 완성"
	if cursor_state.current_level >= 7 and cursor_branch != "":
		cursor_branch += " 완성"
	var common := "%s L%d%s · %s L%d%s" % [ConceptService.term(&"core"), core_state.current_level, core_branch, ConceptService.term(&"cursor"), cursor_state.current_level, cursor_branch]
	if is_candidate_growth_enabled():
		var growth_snapshot := get_candidate_growth_snapshot()
		var branch_title := "미선택"
		for branch in candidate_progression.growth_data.branch_upgrades:
			if String(branch.id) == String(growth_snapshot.selected_branch_id):
				branch_title = branch.display_name
				break
		common = "후보 성장 %d/3 · %s · 심복 L%d%s" % [(growth_snapshot.completed_slots as Dictionary).size(), branch_title, cursor_state.current_level, cursor_branch]
	if guard_progression.is_enabled():
		var guard_stage := guard_progression.get_stage()
		var guard_specialization := guard_progression.get_selected_specialization()
		var guard_title := guard_specialization.display_name if guard_specialization != null else ("훈련 완료" if guard_stage >= 1 else "훈련 전")
		common += " · 친위대 %d/3 %s" % [guard_stage, guard_title]
		if bool(get_guard_modifier(&"guard_devotion", false)):
			common += " · 헌신 %d/%d" % [roundi(get_guard_runtime_value(&"devotion")), int(get_guard_modifier(&"guard_devotion_max_stacks", 30))]
		if bool(get_guard_modifier(&"guard_martyrdom", false)):
			common += " · 순교 %d/%d" % [roundi(get_guard_runtime_value(&"martyr")), int(get_guard_modifier(&"guard_martyr_max_stacks", 30))]
	var overgrowth_snapshot := get_overgrowth_snapshot()
	if int(overgrowth_snapshot.total) > 0:
		common += " · 초과성장 후보 %d / 심복 %d" % [int(overgrowth_snapshot.candidate_total), int(overgrowth_snapshot.retainer_total)]
	if not artifact_inventory.artifact_ids.is_empty():
		var artifact_names: Array[String] = []
		for artifact_id in artifact_inventory.artifact_ids:
			var artifact := artifact_catalog.find_artifact(artifact_id) if artifact_catalog != null else null
			artifact_names.append(artifact.display_name if artifact != null else String(artifact_id))
		common += " · 아티팩트 %d/6 [%s]" % [artifact_inventory.artifact_ids.size(), ", ".join(artifact_names)]
	var status_parts: Array[String] = []
	for status_id in CommonStatusCatalog.STATUS_IDS:
		var status_level := get_status_upgrade_level(status_id)
		if status_level > 0:
			var milestone := " 완성" if status_level >= 7 else (" 특화" if status_level >= 4 else "")
			status_parts.append("%s L%d%s" % [_status_display_name(status_id), status_level, milestone])
	if not status_parts.is_empty():
		common += " · " + " / ".join(status_parts)
	return "편대  %s\n종류 강화  %s   |   %s" % ["   ".join(formation_parts), " · ".join(level_parts) if not level_parts.is_empty() else "없음", common]

func get_selected_global_effects() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for effect_id in selected_global_effects:
		var effect: Dictionary = selected_global_effects[effect_id]
		var level := int(effect.get("level", 1))
		if bool(effect.get("status", false)):
			var milestone := " · 완성" if level >= 7 else (" · 특화" if level >= 4 else "")
			result.append({
				"name": effect.get("name", _status_display_name(effect_id)),
				"level": level,
				"subtitle": "공통 상태이상 · Lv.%d%s" % [level, milestone],
				"description": effect.get("description", "타워 공격에 공통 상태이상 부여"),
				"icon": effect_id,
				"color": _status_color(effect_id),
			})
			continue
		result.append({
			"name": effect.get("name", "전역 강화"),
			"level": level,
			"subtitle": "Lv.%d · 피해 +%d%% · 공속 +%d%%" % [level, level * 7, roundi(level * 3.5)],
			"description": effect.get("description", "모든 타워 강화"),
			"icon": &"global",
			"color": Color("62dc92"),
		})
	return result

func disable_random_column(duration: float) -> void:
	var equipped := columns.filter(func(column: TowerColumn) -> bool: return column.is_occupied())
	if not equipped.is_empty():
		(RunRng.pick(equipped) as TowerColumn).disable_for(duration)

func clear_disabled_columns() -> void:
	var changed := false
	suppress_column_events = true
	for column in columns:
		if column.disabled_remaining > 0.0:
			changed = true
			column.clear_disable()
	suppress_column_events = false
	if changed:
		_emit_summary()

func _track_branch_choices(cursor: bool) -> Array[UpgradeData]:
	var state := cursor_state if cursor else core_state
	var source := DataRegistry.get_specialization_branches(&"cursor" if cursor else &"core", state.id)
	var category: StringName = &"cursor_branch" if cursor else &"core_branch"
	var prefix := "심복" if cursor else "핵"
	var result: Array[UpgradeData] = []
	for branch in source:
		var level_4_stats := "  /  ".join(_modifier_stat_lines(branch.level_4_modifiers))
		var level_7_stats := "  /  ".join(_modifier_stat_lines(branch.level_7_modifiers))
		result.append(_choice(category, branch.display_name, "%s Lv.4 · %s\nLv.4 수치 · %s\nLv.7 완성 · %s\nLv.7 수치 · %s" % [prefix, branch.level_4_description, level_4_stats, branch.level_7_description, level_7_stats], branch.id))
	return result

func _random_tower_level_choice(excluded_keys: Dictionary = {}) -> UpgradeData:
	var candidates: Array[StringName] = []
	for tower_id in get_installed_tower_ids():
		var tower := DataRegistry.get_tower(tower_id)
		var level := get_tower_type_level(tower_id)
		var key := UpgradeOfferService.choice_key_from_parts(&"tower_type_level", tower_id)
		if tower.max_level > 1 and level < tower.max_level and not (level == 3 and get_tower_branch_id(tower_id) == &"") and not excluded_keys.has(key):
			candidates.append(tower_id)
	if candidates.is_empty():
		return null
	var tower_id := RunRng.progression_pick(candidates) as StringName
	var next_level := get_tower_type_level(tower_id) + 1
	var tower := DataRegistry.get_tower(tower_id)
	return _choice(&"tower_type_level", "%s 전체 Lv.%d" % [tower.display_name, next_level], _tower_level_description(tower_id, next_level), tower_id)

func _growth_track_choice(excluded_keys: Dictionary = {}) -> UpgradeData:
	var available: Array[GrowthTrackState] = []
	if not is_candidate_growth_enabled() and core_state.can_level_up() and not core_state.requires_branch_choice() and not excluded_keys.has(UpgradeOfferService.choice_key_from_parts(&"core_level", core_state.id)):
		available.append(core_state)
	if cursor_state.can_level_up() and not cursor_state.requires_branch_choice() and not excluded_keys.has(UpgradeOfferService.choice_key_from_parts(&"cursor_level", cursor_state.id)):
		available.append(cursor_state)
	if available.is_empty():
		return null
	var state := available[0]
	if available.size() == 2:
		state = cursor_state if cursor_state.current_level < core_state.current_level or (cursor_state.current_level == core_state.current_level and RunRng.progression_roll() < 0.5) else core_state
	var is_cursor := state == cursor_state
	var next_level := state.current_level + 1
	var description := _growth_track_level_description(state, is_cursor, next_level)
	return _choice(&"cursor_level" if is_cursor else &"core_level", "%s Lv.%d" % ["심복" if is_cursor else "핵", next_level], description, state.id)

func _overgrowth_choice(excluded_keys: Dictionary = {}) -> UpgradeData:
	var options := overgrowth_service.eligible_options(is_candidate_growth_complete(), is_retainer_growth_complete())
	options = options.filter(func(candidate: OvergrowthOptionData) -> bool:
		var category: StringName = &"candidate_overgrowth" if candidate.target_group == &"candidate" else &"retainer_overgrowth"
		return not excluded_keys.has(UpgradeOfferService.choice_key_from_parts(category, candidate.id))
	)
	var option := _pick_weighted_overgrowth_option(options)
	if option == null:
		return null
	var current_stack := overgrowth_service.get_stack_count(option.id)
	var current_multiplier := 1.0 + current_stack * option.bonus_per_stack
	var next_multiplier := current_multiplier + option.bonus_per_stack
	var category: StringName = &"candidate_overgrowth" if option.target_group == &"candidate" else &"retainer_overgrowth"
	var choice := _choice(category, option.display_name, "%s\n반복 %d회 → %d회 · %.1f%% → %.1f%%" % [option.description, current_stack, current_stack + 1, (current_multiplier - 1.0) * 100.0, (next_multiplier - 1.0) * 100.0], option.id)
	choice.offer_metadata = {
		"family": "overgrowth",
		"target_group": String(option.target_group),
		"stat_key": String(option.stat_key),
		"stack": current_stack + 1,
	}
	return choice

func _pick_weighted_overgrowth_option(options: Array[OvergrowthOptionData]) -> OvergrowthOptionData:
	var total_weight := 0.0
	for option in options:
		total_weight += maxf(option.offer_weight, 0.0)
	if total_weight <= 0.0:
		return null
	var cursor := RunRng.progression_roll() * total_weight
	for option in options:
		cursor -= maxf(option.offer_weight, 0.0)
		if cursor <= 0.0:
			return option
	return options.back()

func _sync_columns() -> void:
	for column in columns:
		column.set_shared_progress(tower_type_levels, tower_branch_ids)

func _forward_tower_attack_requested(column: TowerColumn, row_index: int) -> void:
	tower_attack_requested.emit(column, row_index)

func _on_column_state_changed() -> void:
	if not suppress_column_events:
		_emit_summary()

func _refresh_runtime_bonuses() -> void:
	var defense_bonuses := get_defense_axis_bonuses()
	for column in columns:
		column.global_speed_multiplier = get_axis_independent_tower_speed_multiplier()
		column.guard_range_multiplier = get_guard_range_multiplier()
		column.general_range_multiplier = get_tower_range_multiplier()
		column.set_defense_stat_context(defense_stat_resolver, defense_bonuses)

func _tower_level_description(tower_id: StringName, next_level: int) -> String:
	var tower := DataRegistry.get_tower(tower_id)
	var branch := DataRegistry.get_tower_branch(get_tower_branch_id(tower_id))
	var current_level := clampi(next_level - 1, 1, 7)
	var stat_changes: Array[String] = []
	var current_damage := TowerColumn.DAMAGE_LEVEL_CURVE[current_level]
	var next_damage := TowerColumn.DAMAGE_LEVEL_CURVE[clampi(next_level, 1, 7)]
	if tower.damage > 0.0 and not is_equal_approx(current_damage, next_damage):
		stat_changes.append(_multiplier_change("피해", current_damage, next_damage))
	var current_speed := TowerColumn.SPEED_LEVEL_CURVE[current_level]
	var next_speed := TowerColumn.SPEED_LEVEL_CURVE[clampi(next_level, 1, 7)]
	if not is_equal_approx(current_speed, next_speed):
		stat_changes.append(_multiplier_change("공격속도", current_speed, next_speed))
	var current_range := TowerColumn.RANGE_LEVEL_CURVE[current_level]
	var next_range := TowerColumn.RANGE_LEVEL_CURVE[clampi(next_level, 1, 7)]
	if not is_equal_approx(current_range, next_range):
		stat_changes.append(_multiplier_change("사거리", current_range, next_range))
	if tower.behavior == &"slow":
		stat_changes.append("둔화 지속 %.2f초 → %.2f초" % [1.35 + current_level * 0.28, 1.35 + next_level * 0.28])
	if tower.behavior == &"knockback" and next_level in [3, 6]:
		var current_blades := 2 + (1 if current_level >= 3 else 0) + (1 if current_level >= 6 else 0)
		var next_blades := 2 + (1 if next_level >= 3 else 0) + (1 if next_level >= 6 else 0)
		stat_changes.append("톱날 수 %d개 → %d개" % [current_blades, next_blades])
	if next_level == 7 and branch != null:
		stat_changes.append_array(_modifier_stat_lines(branch.level_7_modifiers))
	var change_text := "수치 변화 · %s" % "  /  ".join(stat_changes) if not stat_changes.is_empty() else "기본 수치 변화 없음"
	var axis_text := _defense_axis_mapping_text(tower_id)
	match next_level:
		2: return "같은 종류의 모든 타워 강화\n%s\n%s" % [axis_text, change_text]
		3: return "Lv.4 특화 진입 카드 해금\n%s\n%s" % [axis_text, change_text]
		4: return "선택한 분기 효과 활성화\n%s\n%s" % [axis_text, change_text]
		5, 6: return "%s 성장\n%s\n%s\n%s" % [branch.display_name, branch.description, axis_text, change_text] if branch != null else "전투 역할 강화\n%s\n%s" % [axis_text, change_text]
		7: return "Lv.7 %s 완성\n%s\n%s\n%s" % [branch.display_name, branch.description, axis_text, change_text] if branch != null else "선택 분기 최종 완성\n%s\n%s" % [axis_text, change_text]
	return "같은 종류의 모든 타워 강화\n%s\n%s" % [axis_text, change_text]

func _defense_axis_mapping_text(tower_id: StringName) -> String:
	var parts: Array[String] = []
	for presentation in defense_stat_resolver.tower_axis_presentations(tower_id):
		var marker := {&"power": "🔴", &"speed": "🟢", &"range": "🔵"}.get(presentation.axis_id, "◆") as String
		parts.append("%s %s·%s" % [marker, presentation.display_name, presentation.mapping_name])
	return "병종 능력축 · %s" % "  /  ".join(parts) if not parts.is_empty() else "병종 능력축 · 적용 없음"

func _growth_track_level_description(state: GrowthTrackState, is_cursor: bool, next_level: int) -> String:
	var current_level := state.current_level
	var branch := DataRegistry.get_specialization_branch(state.selected_branch_id)
	var current_modifiers := branch.get_modifiers(current_level >= 7) if branch != null else {}
	var next_modifiers := branch.get_modifiers(next_level >= 7) if branch != null else {}
	var changes: Array[String] = []
	if is_cursor:
		var cursor_data := DataRegistry.get_cursor(state.id)
		match next_level:
			2:
				changes.append("공격 피해 %.1f → %.1f" % [cursor_data.damage * _level_curve_value(CURSOR_DAMAGE_LEVEL_CURVE, current_level), cursor_data.damage * _level_curve_value(CURSOR_DAMAGE_LEVEL_CURVE, next_level)])
			3:
				changes.append("넉백 %.1f → %.1f" % [cursor_data.knockback * _level_curve_value(CURSOR_CONTROL_LEVEL_CURVE, current_level), cursor_data.knockback * _level_curve_value(CURSOR_CONTROL_LEVEL_CURVE, next_level)])
			5:
				changes.append("이동속도 %.0f → %.0f" % [cursor_data.movement_speed * _level_curve_value(CURSOR_MOVEMENT_LEVEL_CURVE, current_level) * float(current_modifiers.get("movement", 1.0)), cursor_data.movement_speed * _level_curve_value(CURSOR_MOVEMENT_LEVEL_CURVE, next_level) * float(next_modifiers.get("movement", 1.0))])
			6:
				changes.append("공격 반경 %.0f → %.0f" % [cursor_data.attack_radius * _level_curve_value(CURSOR_AREA_LEVEL_CURVE, current_level) * float(current_modifiers.get("area", 1.0)), cursor_data.attack_radius * _level_curve_value(CURSOR_AREA_LEVEL_CURVE, next_level) * float(next_modifiers.get("area", 1.0))])
	else:
		var core_data := DataRegistry.get_core(state.id)
		match next_level:
			2:
				changes.append("공격 피해 %.1f → %.1f" % [core_data.damage * _level_curve_value(CORE_DAMAGE_LEVEL_CURVE, current_level), core_data.damage * _level_curve_value(CORE_DAMAGE_LEVEL_CURVE, next_level)])
			3:
				changes.append("최대 체력 %.0f → %.0f" % [core_data.max_health * _level_curve_value(CORE_HEALTH_LEVEL_CURVE, current_level), core_data.max_health * _level_curve_value(CORE_HEALTH_LEVEL_CURVE, next_level)])
			5:
				changes.append("초당 재생 %.2f → %.2f" % [core_data.regeneration * _level_curve_value(CORE_REGEN_LEVEL_CURVE, current_level) * float(current_modifiers.get("regeneration", 1.0)), core_data.regeneration * _level_curve_value(CORE_REGEN_LEVEL_CURVE, next_level) * float(next_modifiers.get("regeneration", 1.0))])
			6:
				changes.append("액티브 피해 %.0f → %.0f" % [core_data.skill_damage * _level_curve_value(CORE_SKILL_LEVEL_CURVE, current_level) * float(current_modifiers.get("damage", 1.0)), core_data.skill_damage * _level_curve_value(CORE_SKILL_LEVEL_CURVE, next_level) * float(next_modifiers.get("damage", 1.0))])
	if next_level == 7 and branch != null:
		changes.append_array(_modifier_stat_lines(branch.level_7_modifiers))
	var heading := "%s 집중 강화" % ("심복" if is_cursor else "핵")
	if is_cursor and retainer_progression != null and retainer_progression.growth_data != null:
		var retainer_description := retainer_progression.growth_data.description_for_level(next_level)
		if not retainer_description.is_empty():
			heading = retainer_description
	if next_level == 7 and branch != null:
		heading = "%s 최종 특성 완성 · %s" % ["심복" if is_cursor else "핵", branch.level_7_description]
	return "%s\n수치 변화 · %s" % [heading, "  /  ".join(changes) if not changes.is_empty() else "특화 효과 활성화"]

func _level_curve_value(curve: Array[float], level: int) -> float:
	return stat_calculator.level_curve_value(curve, level)

func _stat_curve_config() -> Dictionary:
	return {
		&"core_damage": CORE_DAMAGE_LEVEL_CURVE,
		&"core_health": CORE_HEALTH_LEVEL_CURVE,
		&"core_regeneration": CORE_REGEN_LEVEL_CURVE,
		&"core_skill": CORE_SKILL_LEVEL_CURVE,
		&"cursor_damage": CURSOR_DAMAGE_LEVEL_CURVE,
		&"cursor_control": CURSOR_CONTROL_LEVEL_CURVE,
		&"cursor_movement": CURSOR_MOVEMENT_LEVEL_CURVE,
		&"cursor_area": CURSOR_AREA_LEVEL_CURVE,
	}

func _multiplier_change(label: String, current: float, next: float) -> String:
	var relative_percent := (next / maxf(current, 0.001) - 1.0) * 100.0
	return "%s ×%.2f → ×%.2f (+%.0f%%)" % [label, current, next, relative_percent]

func _modifier_stat_lines(modifiers: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var labels := {
		"damage": "피해", "speed": "공격속도", "range": "사거리", "push": "넉백",
		"slow_multiplier": "둔화율", "mark": "피해 증폭", "execute_ratio": "처형선",
		"ricochet": "도탄 피해", "shrapnel": "파편 피해", "stun": "기절 시간",
		"relay_return": "역방향 빔", "missing_health": "잃은 체력 보너스", "bleed_power": "출혈",
		"saw_fixed": "톱날 고정", "saw_multiplier": "톱날 수", "ritual_hits": "발동 타격 수",
		"ritual_damage": "의식 피해", "frost_stack": "빙결 발동 중첩", "frost_stun": "빙결 기절",
		"execute_stun": "처형 기절", "execute_stun_radius": "기절 반경", "center_damage": "중심 추가 피해",
		"edge_damage": "외곽 피해", "area": "범위", "knockback": "넉백", "health": "최대 체력",
		"regeneration": "재생", "experience": "경험치", "boss_damage": "%s 피해" % ConceptService.term(&"boss"), "movement": "이동속도",
		"spirit_gain_chance_bonus": "일반 적 사령 확률", "reactivation_speed": "친위대 재가동 속도",
		"spirit_capacity_bonus": "사령 상한", "spirit_damage": "사령 피해", "spirit_simultaneous_bonus": "동시 사령",
		"spirit_duration": "사령 지속시간", "soul_harvest_cap": "영혼 상한", "post_active_spirit_window": "재고용 강화 지속",
		"post_active_spirit_chance_bonus": "재고용 사령 확률", "active_generated_spirit_damage": "파도 사령 피해",
		"spirit_expiration_damage": "소멸 폭발 피해", "spirit_expiration_radius": "소멸 폭발 반경",
		"spirit_generation_fear_duration": "생성 공포 지속", "spirit_generation_fear_radius": "생성 공포 반경",
		"retainer_health": "친위대 체력", "retainer_passive_drain": "지속 체력 소모", "retainer_attack_cost": "공격 체력 소모",
		"guard_martyr_disabled_duration": "순교 비활성", "guard_martyr_max_stacks": "순교 상한", "guard_martyr_speed_bonus_cap": "순교 공속 상한", "guard_martyr_speed_per_stack": "순교 스택당 공속",
		"guard_sudden_death_chance": "일반 즉사 확률", "guard_sudden_death_elite_ratio": "정예 즉사 보정",
		"guard_reaper_charge_normal": "일반 처형 액티브 충전", "guard_reaper_charge_elite": "정예 처형 액티브 충전", "guard_reaper_ritual_cooldown": "사신 의식 내부 대기",
		"combo_damage": "합동 공격 피해", "reconstruction_speed": "재구성 속도",
		"vanguard_member_damage": "인원당 화력", "vanguard_execute_bonus": "처형선",
		"reinforcement_speed": "충원 속도", "vanguard_member_bonus": "최대 인원",
		"volley_shots": "주기당 창병 공격", "volley_damage": "개별 창병 피해", "warcry_interval": "워크라이 주기",
		"warcry_damage": "워크라이 피해", "tactics_cycle": "병법 발동 주기", "tactics_mark": "병법 취약",
		"tactics_bleed_ratio": "병법 출혈", "power_shot_hits": "파워샷 주기", "power_shot_width": "파워샷 폭",
		"power_shot_damage": "파워샷 피해", "explosive_arrow": "폭파각인", "explosion_delay": "폭발 지연", "explosion_radius": "폭발 반경",
		"explosion_damage": "폭발 피해", "armor_pierce": "방어 관통", "collateral_damage": "경로 부수 피해",
		"collateral_width": "경로 폭", "ricochet_count": "도탄 횟수", "ricochet_falloff": "도탄 유지 피해",
		"sacrifice_required": "소환 제물", "summon_cap": "동시 피조물", "summon_duration": "피조물 지속",
		"summon_interval": "피조물 공격주기", "summon_damage": "피조물 피해", "summon_radius": "피조물 탐색 반경",
		"erosion_cycle": "침식 주기", "erosion_stun": "침식 기절", "mark_duration": "취약 지속",
		"hex_slow": "추가 둔화", "fire_zone_duration": "화염 장판 지속", "fire_zone_radius": "화염 장판 반경",
		"fire_zone_burn_ratio": "장판 화상", "bone_shard_count": "뼈 투사체", "bone_shard_damage": "뼈 투사체 피해",
		"bone_shard_range": "뼈 투사체 사거리", "lightning_damage": "추가 번개 피해",
		"overheat_cycle": "과열 주기", "overheat_duration": "과열 정지", "saw_size": "톱날 크기", "shock": "감전",
		"network_damage_per_relay": "추가 중계기 증폭", "relay_return_falloff": "역방향 유지 피해",
	}
	for key in modifiers:
		var value: Variant = modifiers[key]
		if value is bool:
			if bool(value):
				result.append("%s 활성화" % labels.get(String(key), String(key)))
			continue
		if not (value is int or value is float):
			continue
		var label := String(labels.get(String(key), String(key)))
		if String(key) in ["damage", "speed", "range", "push", "slow_multiplier", "bleed_power", "saw_multiplier", "saw_size", "ritual_damage", "area", "knockback", "health", "regeneration", "experience", "boss_damage", "reactivation_speed", "spirit_damage", "spirit_duration", "active_generated_spirit_damage", "spirit_expiration_damage", "retainer_health", "retainer_passive_drain", "retainer_attack_cost", "combo_damage", "reconstruction_speed", "vanguard_member_damage", "reinforcement_speed", "volley_damage", "warcry_damage", "power_shot_width", "power_shot_damage", "explosion_damage"]:
			result.append("%s ×%.2f" % [label, float(value)])
		elif String(key) in ["saw_fixed", "ritual_hits", "frost_stack", "spirit_capacity_bonus", "spirit_simultaneous_bonus", "soul_harvest_cap", "vanguard_member_bonus", "volley_shots", "warcry_interval", "tactics_cycle", "power_shot_hits", "ricochet_count", "sacrifice_required", "summon_cap", "erosion_cycle", "bone_shard_count", "overheat_cycle", "guard_martyr_max_stacks"]:
			result.append("%s %d" % [label, int(value)])
		elif String(key) in ["stun", "frost_stun", "execute_stun", "explosion_delay", "summon_duration", "summon_interval", "erosion_stun", "mark_duration", "fire_zone_duration", "overheat_duration", "post_active_spirit_window", "spirit_generation_fear_duration", "guard_martyr_disabled_duration", "guard_reaper_charge_normal", "guard_reaper_charge_elite", "guard_reaper_ritual_cooldown"]:
			result.append("%s %.2f초" % [label, float(value)])
		elif String(key) in ["execute_stun_radius", "explosion_radius", "collateral_width", "summon_damage", "summon_radius", "fire_zone_radius", "bone_shard_range", "spirit_expiration_radius", "spirit_generation_fear_radius"]:
			result.append("%s %.0f" % [label, float(value)])
		elif String(key) in ["spirit_gain_chance_bonus", "post_active_spirit_chance_bonus", "vanguard_execute_bonus", "guard_martyr_speed_per_stack", "guard_martyr_speed_bonus_cap", "guard_sudden_death_chance"]:
			result.append("%s +%.0f%%p" % [label, float(value) * 100.0])
		else:
			result.append("%s %.0f%%" % [label, float(value) * 100.0])
	return result

func _tower_branch_stat_lines(branch_id: StringName, modifiers: Dictionary) -> Array[String]:
	if branch_id == &"slow_power":
		return [
			"제물 %d · 동시 %d · 지속 %.1f초" % [int(modifiers.get("sacrifice_required", 0)), int(modifiers.get("summon_cap", 0)), float(modifiers.get("summon_duration", 0.0))],
			"피해 %.0f · 주기 %.2f초 · 반경 %.0f" % [float(modifiers.get("summon_damage", 0.0)), float(modifiers.get("summon_interval", 0.0)), float(modifiers.get("summon_radius", 0.0))],
		]
	if branch_id == &"push_mark":
		return [
			"톱 %d · 크기 ×%.2f · 공속 ×%.2f" % [int(modifiers.get("saw_fixed", 1)), float(modifiers.get("saw_size", 1.0)), float(modifiers.get("speed", 1.0))],
			"피해 ×%.2f · 넉백 ×%.2f" % [float(modifiers.get("damage", 1.0)), float(modifiers.get("push", 1.0))],
		]
	if branch_id == &"push_wave":
		var summary := "톱 %d · 피해 ×%.2f · 넉백 ×%.2f" % [int(modifiers.get("saw_fixed", 8)), float(modifiers.get("damage", 1.0)), float(modifiers.get("push", 1.0))]
		if modifiers.has("bleed_power"):
			summary += " · 출혈 ×%.2f" % float(modifiers.bleed_power)
		return [summary]
	return _modifier_stat_lines(modifiers)

func _tower_role_name(tower: TowerData) -> String:
	match tower.behavior:
		&"rapid": return "속사"
		&"area": return "포격"
		&"pierce": return "관통"
		&"slow": return "둔화"
		&"knockback": return "톱날"
		&"execute": return "처형"
		&"mark": return "표식"
		&"chain": return "연쇄"
	return tower.display_name.replace(" 타워", "")

func _track_branch_name(branch_id: StringName) -> String:
	var branch := DataRegistry.get_specialization_branch(branch_id)
	return " · %s" % branch.display_name if branch != null else ""

func _fallback_choice(excluded_keys: Dictionary = {}) -> UpgradeData:
	var candidates: Array[UpgradeData] = []
	for choice in [_random_tower_level_choice(excluded_keys), _growth_track_choice(excluded_keys), _random_status_upgrade_choice(excluded_keys), _overgrowth_choice(excluded_keys)]:
		if choice != null:
			candidates.append(choice)
	return RunRng.progression_pick(candidates) as UpgradeData if not candidates.is_empty() else null

func _random_status_upgrade_choice(excluded_keys: Dictionary = {}) -> UpgradeData:
	var candidates: Array[StringName] = []
	for status_id in CommonStatusCatalog.STATUS_IDS:
		var feature_id := StringName("status_growth_%s" % String(status_id))
		var key := UpgradeOfferService.choice_key_from_parts(&"status_upgrade", status_id)
		if MetaProgressionService.is_feature_unlocked(feature_id) and get_status_upgrade_level(status_id) < 7 and has_common_status_application_source(status_id) and not excluded_keys.has(key):
			candidates.append(status_id)
	if candidates.is_empty():
		return null
	var status_id := RunRng.progression_pick(candidates) as StringName
	var next_level := get_status_upgrade_level(status_id) + 1
	var suffix := " 완성" if next_level == 7 else (" 특화" if next_level == 4 else "")
	return _choice(&"status_upgrade", "%s Lv.%d%s" % [_status_display_name(status_id), next_level, suffix], _status_upgrade_description(status_id, next_level), status_id)

func has_common_status_application_source(status_id: StringName) -> bool:
	if get_status_upgrade_level(status_id) > 0:
		return true
	for column in columns:
		for tower in column.row_towers:
			if tower != null and (_tower_supports_common_status(tower, status_id) or _branch_supports_common_status(column.get_branch_modifiers(tower.id), status_id)):
				return true
	return false

func _tower_supports_common_status(tower: TowerData, status_id: StringName) -> bool:
	return CommonStatusCatalog.tower_supports(tower, status_id)

func _branch_supports_common_status(modifiers: Dictionary, status_id: StringName) -> bool:
	return CommonStatusCatalog.branch_supports(modifiers, status_id)

func _status_upgrade_description(status_id: StringName, next_level: int) -> String:
	var current_level := clampi(next_level - 1, 0, 7)
	var heading := "상태이상 수치 강화"
	if next_level == 4:
		heading = "Lv.4 특화 보너스 · 중첩과 영향 범위 대폭 강화"
	elif next_level == 7:
		heading = "Lv.7 완성 보너스 · 피해와 최대 중첩 최종 강화"
	return "%s\n수치 변화 · %s → %s" % [heading, _status_profile_text(status_id, _common_status_profile_at_level(status_id, current_level)), _status_profile_text(status_id, _common_status_profile_at_level(status_id, next_level))]

func _status_profile_text(status_id: StringName, profile: Dictionary) -> String:
	return CommonStatusCatalog.profile_text(status_id, profile)

func _status_display_name(status_id: StringName) -> String:
	return CommonStatusCatalog.display_name(status_id)

func _status_color(status_id: StringName) -> Color:
	return CommonStatusCatalog.color(status_id)

func _choice(category: StringName, title: String, description: String, data_id: StringName) -> UpgradeData:
	return UpgradeData.new().configure(category, title, description, data_id)

func _emit_summary() -> void:
	loadout_changed.emit(get_build_summary())
	effects_changed.emit(get_selected_global_effects())
	artifacts_changed.emit(get_artifact_presentations())
