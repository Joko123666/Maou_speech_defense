class_name FormationOfferBuilder
extends RefCounted

const SLOT_TYPES: Array[StringName] = [&"build", &"expansion", &"wildcard"]
const DISCOVERY_MULTIPLIER := 2.25
const RECENT_MULTIPLIER := 0.30
const RECENT_BATCH_LIMIT := 2

var recent_offer_batches: Array[Array] = []
var last_offer_diagnostics: Array[Dictionary] = []

func reset_run_state() -> void:
	recent_offer_batches.clear()
	last_offer_diagnostics.clear()

func eligible_formations(board_state: FormationBoardState, formation_pool: Array[TowerFormationData], size: int) -> Array[TowerFormationData]:
	var result: Array[TowerFormationData] = []
	if board_state == null or size not in [2, 3, 4]:
		return result
	for formation in formation_pool:
		if formation == null or formation.is_guard or formation.cells.size() != size:
			continue
		if board_state.valid_placements(formation).is_empty():
			continue
		result.append(formation)
	return result

func build(board_state: FormationBoardState, formation_pool: Array[TowerFormationData], size: int, limit: int, context: Dictionary = {}) -> Array[Dictionary]:
	var eligible := eligible_formations(board_state, formation_pool, size)
	var selected: Array[TowerFormationData] = []
	var selected_slots: Array[StringName] = []
	var target_count := mini(maxi(limit, 0), mini(SLOT_TYPES.size(), eligible.size()))
	for index in target_count:
		var slot_type := SLOT_TYPES[index]
		var candidates := eligible.filter(func(formation: TowerFormationData) -> bool: return formation not in selected)
		candidates = _purpose_candidates(candidates, slot_type, context)
		candidates = _diverse_candidates(candidates, selected)
		var chosen := _weighted_pick(candidates, slot_type, context)
		if chosen == null:
			break
		selected.append(chosen)
		selected_slots.append(slot_type)

	var primary_role_counts: Dictionary = {}
	for formation in selected:
		var primary_role := _primary_role(formation)
		primary_role_counts[primary_role] = int(primary_role_counts.get(primary_role, 0)) + 1
	var result: Array[Dictionary] = []
	last_offer_diagnostics.clear()
	for index in selected.size():
		var formation := selected[index]
		var primary_role := _primary_role(formation)
		var valid_position_count := board_state.valid_placements(formation).size()
		var diagnostic := {
			"formation": formation,
			"slot_type": selected_slots[index],
			"discovery_bonus": _has_discovery_bonus(formation, context),
			"recent_penalty": _is_recent(formation.id),
			"primary_role": primary_role,
			"role_duplicate": int(primary_role_counts.get(primary_role, 0)) > 1,
			"eligible_pool_size": eligible.size(),
			"shape_class": formation.shape_class,
			"distinct_tower_count": formation.get_distinct_tower_count(),
			"valid_position_count": valid_position_count,
		}
		result.append(diagnostic)
		last_offer_diagnostics.append(diagnostic.duplicate())
	_remember(selected)
	return result

func get_state_snapshot() -> Dictionary:
	var batches: Array = []
	for batch in recent_offer_batches:
		batches.append(batch.duplicate())
	return {"recent_offer_batches": batches}

func restore_state(snapshot: Dictionary) -> void:
	recent_offer_batches.clear()
	var batches_value: Variant = snapshot.get("recent_offer_batches", [])
	if batches_value is not Array:
		return
	for batch_value in batches_value as Array:
		if batch_value is not Array:
			continue
		var batch: Array = []
		for formation_id in batch_value as Array:
			batch.append(StringName(formation_id))
		if not batch.is_empty():
			recent_offer_batches.append(batch)
	while recent_offer_batches.size() > RECENT_BATCH_LIMIT:
		recent_offer_batches.pop_front()

func _purpose_candidates(candidates: Array[TowerFormationData], slot_type: StringName, context: Dictionary) -> Array[TowerFormationData]:
	if candidates.size() <= 1:
		return candidates
	if slot_type == &"build":
		var linked := candidates.filter(func(formation: TowerFormationData) -> bool: return _build_link_score(formation, context) > 0.0)
		return linked if not linked.is_empty() else candidates
	if slot_type == &"expansion":
		var expansion := candidates.filter(func(formation: TowerFormationData) -> bool: return _expansion_score(formation, context) > 0.0)
		return expansion if not expansion.is_empty() else candidates
	return candidates

func _diverse_candidates(candidates: Array[TowerFormationData], selected: Array[TowerFormationData]) -> Array[TowerFormationData]:
	if candidates.size() <= 1 or selected.size() < 2:
		return candidates
	var first_role := _primary_role(selected[0])
	if selected.all(func(formation: TowerFormationData) -> bool: return _primary_role(formation) == first_role):
		var diverse := candidates.filter(func(formation: TowerFormationData) -> bool: return _primary_role(formation) != first_role)
		if not diverse.is_empty():
			return diverse
	return candidates

func _weighted_pick(candidates: Array[TowerFormationData], slot_type: StringName, context: Dictionary) -> TowerFormationData:
	if candidates.is_empty():
		return null
	var weights: Array[float] = []
	var total := 0.0
	for formation in candidates:
		var weight := maxf(formation.base_weight, 0.05)
		match slot_type:
			&"build": weight *= 1.0 + _build_link_score(formation, context)
			&"expansion": weight *= 1.0 + _expansion_score(formation, context)
		if _has_discovery_bonus(formation, context):
			weight *= DISCOVERY_MULTIPLIER
		if _is_recent(formation.id):
			weight *= RECENT_MULTIPLIER
		weights.append(weight)
		total += weight
	if total <= 0.0:
		return candidates.front()
	var roll := RunRng.progression_rangef(0.0, total)
	for index in candidates.size():
		roll -= weights[index]
		if roll <= 0.0:
			return candidates[index]
	return candidates.back()

func _build_link_score(formation: TowerFormationData, context: Dictionary) -> float:
	var installed := _name_array(context.get("installed_tower_ids", []))
	var levels := context.get("tower_levels", {}) as Dictionary
	var branches := context.get("tower_branches", {}) as Dictionary
	var result := 0.0
	for tower_id in formation.get_tower_ids():
		if tower_id not in installed:
			continue
		var level := maxi(int(levels.get(tower_id, levels.get(String(tower_id), 1))), 1)
		result += 0.75 + float(level - 1) * 0.18
		if StringName(branches.get(tower_id, branches.get(String(tower_id), &""))) != &"":
			result += 0.35
	return result

func _expansion_score(formation: TowerFormationData, context: Dictionary) -> float:
	var installed := _name_array(context.get("installed_tower_ids", []))
	var current_roles := _name_array(context.get("current_role_tags", []))
	var unseen_types: Dictionary = {}
	for tower_id in formation.get_tower_ids():
		if tower_id not in installed:
			unseen_types[tower_id] = true
	var missing_role := 1.0 if _primary_role(formation) not in current_roles else 0.0
	return float(unseen_types.size()) * 0.85 + missing_role

func _has_discovery_bonus(formation: TowerFormationData, context: Dictionary) -> bool:
	var discovered := _name_array(context.get("discovered_tower_use_ids", []))
	for tower_id in formation.get_tower_ids():
		if tower_id not in discovered:
			return true
	return false

func _is_recent(formation_id: StringName) -> bool:
	for batch in recent_offer_batches:
		if formation_id in batch:
			return true
	return false

func _remember(formations: Array[TowerFormationData]) -> void:
	if formations.is_empty():
		return
	var batch: Array = []
	for formation in formations:
		batch.append(formation.id)
	recent_offer_batches.append(batch)
	while recent_offer_batches.size() > RECENT_BATCH_LIMIT:
		recent_offer_batches.pop_front()

func _primary_role(formation: TowerFormationData) -> StringName:
	return formation.role_tags.front() if formation != null and not formation.role_tags.is_empty() else &"basic"

func _name_array(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if value is not Array:
		return result
	for item in value as Array:
		var name := StringName(item)
		if name != &"" and name not in result:
			result.append(name)
	return result
