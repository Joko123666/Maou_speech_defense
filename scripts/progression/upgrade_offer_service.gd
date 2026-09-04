class_name UpgradeOfferService
extends RefCounted

var specialization_policy: SpecializationOfferPolicy
var guard_growth_policy: SpecializationOfferPolicy

var tower_choice_provider := Callable()
var growth_choice_provider := Callable()
var status_choice_provider := Callable()
var fallback_choice_provider := Callable()
var specialization_entries_provider := Callable()
var guard_choice_provider := Callable()
var formation_context_provider := Callable()
var overgrowth_choice_provider := Callable()
var formation_offer_builder := FormationOfferBuilder.new()
var artifact_offer_service := ArtifactOfferService.new()
var artifact_candidates_provider := Callable()

const OVERGROWTH_FAMILY_CHANCE := 0.18
const DISPLAY_CHOICE_COUNT := 3
const REQUIRED_INITIAL_FORMATION_META := &"required_initial_formation"
const OPTIONAL_INITIAL_FORMATION_META := &"optional_initial_formation"

func _init(
	specialization_chance: float = 0.58,
	specialization_pity: int = 2,
	guard_chance: float = 0.50,
	guard_pity: int = 2
) -> void:
	specialization_policy = SpecializationOfferPolicy.new(specialization_chance, specialization_pity)
	guard_growth_policy = SpecializationOfferPolicy.new(guard_chance, guard_pity)

func configure(
	tower_provider: Callable,
	growth_provider: Callable,
	status_provider: Callable,
	fallback_provider: Callable,
	specialization_provider: Callable,
	guard_provider: Callable,
	formation_context: Callable = Callable(),
	overgrowth_provider: Callable = Callable(),
	artifact_provider: Callable = Callable()
) -> void:
	tower_choice_provider = tower_provider
	growth_choice_provider = growth_provider
	status_choice_provider = status_provider
	fallback_choice_provider = fallback_provider
	specialization_entries_provider = specialization_provider
	guard_choice_provider = guard_provider
	formation_context_provider = formation_context
	overgrowth_choice_provider = overgrowth_provider
	artifact_candidates_provider = artifact_provider

func reset_run_state() -> void:
	formation_offer_builder.reset_run_state()

func generate(board_state: FormationBoardState, formation_pool: Array[TowerFormationData], _legacy_global_upgrade_level: int) -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	if board_state == null or not _providers_valid():
		push_error("Level-up offer generation requires a board and every mandatory reward provider")
		return result
	var formation_set := _random_formation_set_choice(board_state, formation_pool)
	var tower_choice := tower_choice_provider.call() as UpgradeData
	var regular_formation_count := _regular_formation_count(board_state)
	# 첫 일반 병력 세트는 보장한다. 이 카드만 정책 교체에서 보호한다.
	if formation_set != null and (regular_formation_count == 0 or RunRng.progression_roll() < 0.62):
		if regular_formation_count == 0:
			formation_set.offer_metadata[REQUIRED_INITIAL_FORMATION_META] = true
		_append_unique_choice(result, formation_set)
	elif tower_choice != null:
		_append_unique_choice(result, tower_choice)
	else:
		_append_fallback(result)
	var regular_growth := growth_choice_provider.call() as UpgradeData
	var overgrowth := overgrowth_choice_provider.call() as UpgradeData if overgrowth_choice_provider.is_valid() else null
	# 비대상 런에서는 기존 RNG 소비 순서까지 보존한다.
	var overgrowth_roll := RunRng.progression_roll() if overgrowth != null else 1.0
	var growth_slot := choose_growth_slot(regular_growth, overgrowth, overgrowth_roll)
	if growth_slot != null:
		_append_unique_choice(result, growth_slot)
	else:
		_append_fallback(result)
	var status_choice := status_choice_provider.call() as UpgradeData
	if status_choice != null and RunRng.progression_roll() < 0.58:
		_append_unique_choice(result, status_choice)
	elif _append_unique_choice(result, tower_choice):
		pass
	else:
		_append_fallback(result)
	_fill_unique_fallbacks(result)
	# 초기 직접 성장 후보가 부족할 때만 첫 카드와 크기가 다른 병력 세트로 빈 한 칸을 채운다.
	# 심복 성장 카드는 유지하며, 이 선택 병력 카드는 친위대·특화·아티팩트 교체 대상이다.
	if regular_formation_count == 0 and result.size() < DISPLAY_CHOICE_COUNT:
		var optional_formation := _random_formation_set_choice(board_state, formation_pool, formation_set_size(formation_set))
		if optional_formation != null:
			optional_formation.offer_metadata[OPTIONAL_INITIAL_FORMATION_META] = true
			_append_unique_choice(result, optional_formation)
	var protect_required_formation := regular_formation_count == 0
	# 화면이 비어 있을 때는 확률 교체보다 고유 적격 카드를 먼저 채워 3택 구성을 우선한다.
	specialization_policy.inject(result, _specialization_entries(), protect_required_formation, DISPLAY_CHOICE_COUNT)
	guard_growth_policy.inject(result, _guard_entries(), protect_required_formation, DISPLAY_CHOICE_COUNT)
	# 정책 주입이 기존 카드를 교체했다면 빠진 일반 후보가 다시 고유 후보가 될 수 있다.
	_fill_unique_fallbacks(result)
	if artifact_candidates_provider.is_valid():
		var artifact_candidates: Array[ArtifactData] = []
		artifact_candidates.assign(artifact_candidates_provider.call() as Array)
		artifact_offer_service.inject(result, artifact_candidates, protect_required_formation, DISPLAY_CHOICE_COUNT)
	# 모든 고유 후보가 소진된 뒤에만 이미 유효한 카드를 복제한다.
	_fill_duplicate_fallbacks(result)
	result = result.slice(0, DISPLAY_CHOICE_COUNT)
	if result.size() != DISPLAY_CHOICE_COUNT:
		push_error("Level-up offer generation could not satisfy the exact three-card contract")
	return result

static func choose_growth_slot(regular_growth: UpgradeData, overgrowth: UpgradeData, roll: float) -> UpgradeData:
	# 초과성장은 이 한 슬롯에서만 경쟁하므로 화면당 최대 한 장이며, 일반 성장보다 항상 낮은 가중치다.
	if overgrowth != null and clampf(roll, 0.0, 1.0) < OVERGROWTH_FAMILY_CHANCE:
		return overgrowth
	return regular_growth

func formation_set_size(choice: UpgradeData) -> int:
	if choice == null or choice.category != &"formation_set":
		return 0
	return int(String(choice.data_id).trim_prefix("size_"))

func formation_candidates(board_state: FormationBoardState, formation_pool: Array[TowerFormationData], size: int, limit: int = 3) -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	var context := formation_context_provider.call() as Dictionary if formation_context_provider.is_valid() else {}
	for candidate in formation_offer_builder.build(board_state, formation_pool, size, limit, context):
		var formation := candidate.formation as TowerFormationData
		var placement_count := maxi(int(candidate.get("valid_position_count", board_state.valid_placements(formation).size())), 0)
		var choice := UpgradeData.new().configure(
			&"new_formation",
			formation.display_name,
			"%s · %d칸 · %s / %d병종\n배치 %s · 현재 %d곳 · 편성점수 %d\n%s · %s" % [
				_slot_label(candidate.slot_type),
				formation.cells.size(),
				formation.get_shape_display_name(),
				formation.get_distinct_tower_count(),
				formation.get_placement_difficulty_display_name(),
				placement_count,
				formation.formation_score,
				", ".join(formation.role_tags),
				formation.description,
			],
			formation.id
		)
		choice.offer_metadata = candidate.duplicate()
		choice.offer_metadata.erase("formation")
		choice.offer_metadata["shape_class"] = formation.shape_class
		choice.offer_metadata["distinct_tower_count"] = formation.get_distinct_tower_count()
		choice.offer_metadata["valid_position_count"] = placement_count
		result.append(choice)
	return result

func get_state_snapshot() -> Dictionary:
	return {
		"specialization": specialization_policy.get_state_snapshot(),
		"guard_growth": guard_growth_policy.get_state_snapshot(),
		"formation_builder": formation_offer_builder.get_state_snapshot(),
	}

func restore_state(snapshot: Dictionary) -> void:
	var specialization_state: Variant = snapshot.get("specialization", {})
	specialization_policy.restore_state(specialization_state as Dictionary if specialization_state is Dictionary else {})
	var guard_growth_state: Variant = snapshot.get("guard_growth", {})
	guard_growth_policy.restore_state(guard_growth_state as Dictionary if guard_growth_state is Dictionary else {})
	var formation_builder_state: Variant = snapshot.get("formation_builder", {})
	formation_offer_builder.restore_state(formation_builder_state as Dictionary if formation_builder_state is Dictionary else {})

func generate_rerolled(
	previous_choices: Array[UpgradeData],
	board_state: FormationBoardState,
	formation_pool: Array[TowerFormationData],
	global_upgrade_level: int,
	max_attempts: int = 4
) -> Array[UpgradeData]:
	var previous_signature := signature(previous_choices)
	var offer_state := get_state_snapshot()
	var result: Array[UpgradeData] = []
	for _attempt in maxi(max_attempts, 1):
		restore_state(offer_state)
		result = generate(board_state, formation_pool, global_upgrade_level)
		if signature(result) != previous_signature:
			break
	return result

func signature(choices: Array[UpgradeData]) -> String:
	var parts: Array[String] = []
	for choice in choices:
		parts.append(String(choice_key(choice)))
	parts.sort()
	return "|".join(parts)

static func choice_key(choice: UpgradeData) -> StringName:
	if choice == null:
		return &""
	return choice_key_from_parts(choice.category, choice.data_id)

static func choice_key_from_parts(category: StringName, data_id: StringName) -> StringName:
	return StringName("%s:%s" % [category, data_id])

static func has_duplicate_choices(choices: Array[UpgradeData]) -> bool:
	var seen: Dictionary = {}
	for choice in choices:
		var key := choice_key(choice)
		if key == &"":
			continue
		if seen.has(key):
			return true
		seen[key] = true
	return false

func _random_formation_set_choice(board_state: FormationBoardState, formation_pool: Array[TowerFormationData], excluded_size: int = 0) -> UpgradeData:
	var candidates_by_size: Dictionary = {}
	for size in [2, 3, 4]:
		if size == excluded_size:
			continue
		var candidates := formation_offer_builder.eligible_formations(board_state, formation_pool, size)
		if not candidates.is_empty():
			candidates_by_size[size] = candidates
	if candidates_by_size.is_empty():
		return null
	var occupancy := board_state.get_occupancy_ratio()
	var weighted_sizes: Array[int] = []
	for size in candidates_by_size:
		var weight := 1
		if occupancy < 0.35:
			weight = {2: 2, 3: 5, 4: 6}.get(int(size), 1)
		elif occupancy < 0.68:
			weight = {2: 3, 3: 6, 4: 3}.get(int(size), 1)
		else:
			weight = {2: 7, 3: 3, 4: 1}.get(int(size), 1)
		for _index in weight:
			weighted_sizes.append(int(size))
	var selected_size := int(RunRng.progression_pick(weighted_sizes))
	var valid_count := (candidates_by_size[selected_size] as Array).size()
	return UpgradeData.new().configure(
		&"formation_set",
		"%d칸 병력 세트" % selected_size,
		"현재 전장에 배치 가능한 %d칸 편대를 최대 3개 제안합니다.\n유효 편대: %d" % [selected_size, valid_count],
		StringName("size_%d" % selected_size)
	)

func _regular_formation_count(board_state: FormationBoardState) -> int:
	var result := 0
	for placement in board_state.placements.values():
		if not bool((placement as Dictionary).get("is_guard", false)):
			result += 1
	return result

func _specialization_entries() -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	result.assign(specialization_entries_provider.call() as Array)
	return result

func _guard_entries() -> Array[UpgradeData]:
	var result: Array[UpgradeData] = []
	var guard_choice := guard_choice_provider.call() as UpgradeData
	if guard_choice != null:
		result.append(guard_choice)
	return result

func _append_fallback(result: Array[UpgradeData]) -> void:
	var choice := fallback_choice_provider.call(_choice_key_set(result)) as UpgradeData
	if choice == null or choice.category == &"global_upgrade":
		return
	if choice.category in [&"candidate_overgrowth", &"retainer_overgrowth"] and result.any(func(existing: UpgradeData) -> bool: return existing.category in [&"candidate_overgrowth", &"retainer_overgrowth"]):
		return
	_append_unique_choice(result, choice)

func _fill_unique_fallbacks(result: Array[UpgradeData]) -> void:
	while result.size() < DISPLAY_CHOICE_COUNT:
		var before := result.size()
		_append_fallback(result)
		if result.size() == before:
			break

func _fill_duplicate_fallbacks(result: Array[UpgradeData]) -> void:
	if result.is_empty():
		push_error("Level-up offer generation produced no valid reward to duplicate")
		return
	var preferred_sources := result.filter(func(choice: UpgradeData) -> bool:
		return choice.category not in [
			&"formation_set", &"new_formation", &"artifact",
			&"candidate_overgrowth", &"retainer_overgrowth",
			&"guard_training", &"guard_specialization_entry", &"guard_completion",
		]
	)
	var duplicate_sources: Array[UpgradeData] = []
	duplicate_sources.assign(preferred_sources if not preferred_sources.is_empty() else result)
	var source_index := 0
	while result.size() < DISPLAY_CHOICE_COUNT:
		result.append(_duplicate_choice(duplicate_sources[source_index % duplicate_sources.size()]))
		source_index += 1

func _duplicate_choice(source: UpgradeData) -> UpgradeData:
	var duplicate := UpgradeData.new().configure(source.category, source.display_name, source.description, source.data_id)
	duplicate.requires_placement = source.requires_placement
	duplicate.offer_metadata = source.offer_metadata.duplicate(true)
	duplicate.offer_metadata[&"duplicate_fallback"] = true
	return duplicate

func _append_unique_choice(result: Array[UpgradeData], choice: UpgradeData) -> bool:
	var key := choice_key(choice)
	if key == &"" or result.any(func(existing: UpgradeData) -> bool: return choice_key(existing) == key):
		return false
	result.append(choice)
	return true

func _choice_key_set(choices: Array[UpgradeData]) -> Dictionary:
	var result: Dictionary = {}
	for choice in choices:
		var key := choice_key(choice)
		if key != &"":
			result[key] = true
	return result

func _providers_valid() -> bool:
	return tower_choice_provider.is_valid() and growth_choice_provider.is_valid() and status_choice_provider.is_valid() and fallback_choice_provider.is_valid() and specialization_entries_provider.is_valid() and guard_choice_provider.is_valid()

func _slot_label(slot_type: StringName) -> String:
	return {&"build": "A 빌드 연계", &"expansion": "B 확장", &"wildcard": "C 자유"}.get(slot_type, "자유")
