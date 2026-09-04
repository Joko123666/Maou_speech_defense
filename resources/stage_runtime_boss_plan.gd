class_name StageRuntimeBossPlan
extends Resource

const SOURCE_FIXED := &"fixed"
const SOURCE_CAMPAIGN := &"campaign"
const PRESENTATION_REVISION := 1
const PRESENTATION_CANDIDATE := &"candidate"
const PRESENTATION_RETAINER := &"retainer"
const PRESENTATION_GUARD := &"guard"
const CAMPAIGN_PRESENTATION_KINDS: Array[StringName] = [PRESENTATION_CANDIDATE, PRESENTATION_RETAINER, PRESENTATION_GUARD]

@export var id: StringName = &""
@export var source: StringName = SOURCE_FIXED
@export var seed: int = 0
@export var selected_candidate_id: StringName = &""
@export var final_boss_id: StringName = &""
@export var fallback_reason: String = ""
@export var slots: Array[Dictionary] = []

func get_validation_errors(
	stage: StageData,
	boss_catalog_ids: Dictionary = {},
	faction_catalog_ids: Dictionary = {},
	excluded_faction_id: StringName = &""
) -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("runtime boss plan id is empty")
	if source not in [SOURCE_FIXED, SOURCE_CAMPAIGN]:
		errors.append("runtime boss plan has unsupported source '%s'" % source)
	if stage == null:
		errors.append("runtime boss plan has no stage")
		return errors
	if slots.size() != stage.boss_times.size():
		errors.append("runtime boss plan slot count %d does not match stage boss time count %d" % [slots.size(), stage.boss_times.size()])
	var seen_bosses: Dictionary = {}
	var seen_factions: Dictionary = {}
	var seen_presentations: Dictionary = {}
	var previous_time := -1.0
	for index in slots.size():
		var slot := slots[index]
		var boss_id := StringName(slot.get("boss_id", ""))
		var faction_id := StringName(slot.get("faction_id", ""))
		var presentation_kind := StringName(slot.get("presentation_kind", ""))
		var presentation_id := StringName(slot.get("presentation_id", ""))
		var slot_time_value: Variant = slot.get("time")
		if boss_id == &"":
			errors.append("runtime boss plan slot %d has no boss id" % index)
		elif seen_bosses.has(boss_id):
			errors.append("runtime boss plan contains duplicate boss '%s'" % boss_id)
		else:
			seen_bosses[boss_id] = true
		if not boss_catalog_ids.is_empty() and boss_id != &"" and not boss_catalog_ids.has(boss_id):
			errors.append("runtime boss plan references missing boss '%s'" % boss_id)
		if slot_time_value is not float and slot_time_value is not int:
			errors.append("runtime boss plan slot %d has a non-numeric time" % index)
		else:
			var slot_time := float(slot_time_value)
			if slot_time <= previous_time or slot_time <= 0.0 or slot_time > stage.duration_seconds:
				errors.append("runtime boss plan times must be strictly increasing within the stage duration")
			previous_time = slot_time
			if index < stage.boss_times.size() and not is_equal_approx(slot_time, stage.boss_times[index]):
				errors.append("runtime boss plan slot %d time %.2f does not match stage time %.2f" % [index, slot_time, stage.boss_times[index]])
		if source == SOURCE_CAMPAIGN:
			if faction_id == &"":
				errors.append("campaign boss plan slot %d has no faction id" % index)
			elif faction_id == excluded_faction_id:
				errors.append("campaign boss plan includes the selected faction '%s'" % faction_id)
			elif seen_factions.has(faction_id):
				errors.append("campaign boss plan contains duplicate faction '%s'" % faction_id)
			else:
				seen_factions[faction_id] = true
			if not faction_catalog_ids.is_empty() and faction_id != &"" and not faction_catalog_ids.has(faction_id):
				errors.append("campaign boss plan references missing faction '%s'" % faction_id)
			if presentation_kind not in CAMPAIGN_PRESENTATION_KINDS:
				errors.append("campaign boss plan slot %d has unsupported presentation kind '%s'" % [index, presentation_kind])
			if presentation_id == &"":
				errors.append("campaign boss plan slot %d has no presentation id" % index)
			else:
				var presentation_key := "%s/%s" % [presentation_kind, presentation_id]
				if seen_presentations.has(presentation_key):
					errors.append("campaign boss plan contains duplicate presentation '%s'" % presentation_key)
				else:
					seen_presentations[presentation_key] = true
			if index == slots.size() - 1 and presentation_kind != PRESENTATION_CANDIDATE:
				errors.append("campaign boss plan final slot must present a candidate")
			elif index < slots.size() - 1 and presentation_kind == PRESENTATION_CANDIDATE:
				errors.append("campaign boss plan opening slot %d cannot present a candidate" % index)
	if final_boss_id == &"":
		errors.append("runtime boss plan has no final boss id")
	elif not slots.is_empty() and StringName(slots.back().get("boss_id", "")) != final_boss_id:
		errors.append("runtime boss plan final boss '%s' does not match its last slot" % final_boss_id)
	elif source == SOURCE_FIXED and stage.final_boss_id != &"" and final_boss_id != stage.final_boss_id:
		errors.append("fixed runtime boss plan final boss '%s' does not match stage final boss '%s'" % [final_boss_id, stage.final_boss_id])
	return errors

func boss_id_at(index: int) -> StringName:
	return StringName(slots[index].get("boss_id", "")) if index >= 0 and index < slots.size() else &""

func faction_id_at(index: int) -> StringName:
	return StringName(slots[index].get("faction_id", "")) if index >= 0 and index < slots.size() else &""

func time_at(index: int) -> float:
	return float(slots[index].get("time", 0.0)) if index >= 0 and index < slots.size() else 0.0

func presentation_kind_at(index: int) -> StringName:
	return StringName(slots[index].get("presentation_kind", "")) if index >= 0 and index < slots.size() else &""

func presentation_id_at(index: int) -> StringName:
	return StringName(slots[index].get("presentation_id", "")) if index >= 0 and index < slots.size() else &""

func to_snapshot() -> Dictionary:
	var snapshot_slots: Array[Dictionary] = []
	for slot in slots:
		snapshot_slots.append({
			"boss_id": String(slot.get("boss_id", "")),
			"faction_id": String(slot.get("faction_id", "")),
			"presentation_kind": String(slot.get("presentation_kind", "")),
			"presentation_id": String(slot.get("presentation_id", "")),
			"time": float(slot.get("time", 0.0)),
		})
	return {
		"presentation_revision": PRESENTATION_REVISION,
		"id": String(id),
		"source": String(source),
		"seed": seed,
		"selected_candidate_id": String(selected_candidate_id),
		"final_boss_id": String(final_boss_id),
		"fallback_reason": fallback_reason,
		"slots": snapshot_slots,
	}

static func is_valid_snapshot(value: Variant) -> bool:
	if value is not Dictionary:
		return false
	var snapshot := value as Dictionary
	if snapshot.get("id", null) is not String or String(snapshot.get("id", "")).is_empty():
		return false
	if snapshot.get("source", null) is not String or StringName(snapshot.get("source", "")) not in [SOURCE_FIXED, SOURCE_CAMPAIGN]:
		return false
	if snapshot.get("seed", null) is not int and snapshot.get("seed", null) is not float:
		return false
	if snapshot.get("selected_candidate_id", null) is not String or snapshot.get("final_boss_id", null) is not String:
		return false
	var snapshot_source := StringName(snapshot.get("source", ""))
	var presentation_revision_value: Variant = snapshot.get("presentation_revision", 0)
	if presentation_revision_value is not int and presentation_revision_value is not float:
		return false
	var presentation_revision := int(presentation_revision_value)
	if presentation_revision < 0 or presentation_revision > PRESENTATION_REVISION:
		return false
	if snapshot_source == SOURCE_CAMPAIGN and String(snapshot.get("selected_candidate_id", "")).is_empty():
		return false
	var slots_value: Variant = snapshot.get("slots", null)
	if slots_value is not Array or slots_value.is_empty():
		return false
	var seen_bosses: Dictionary = {}
	var seen_factions: Dictionary = {}
	var seen_presentations: Dictionary = {}
	var previous_time := -1.0
	for slot_index in (slots_value as Array).size():
		var slot_value: Variant = (slots_value as Array)[slot_index]
		if slot_value is not Dictionary:
			return false
		var slot := slot_value as Dictionary
		if slot.get("boss_id", null) is not String or String(slot.get("boss_id", "")).is_empty():
			return false
		if slot.get("faction_id", null) is not String:
			return false
		if slot.get("time", null) is not float and slot.get("time", null) is not int:
			return false
		var slot_time := float(slot.get("time", 0.0))
		if slot_time <= previous_time or slot_time <= 0.0:
			return false
		previous_time = slot_time
		var boss_id := String(slot.get("boss_id", ""))
		if seen_bosses.has(boss_id):
			return false
		seen_bosses[boss_id] = true
		if snapshot_source == SOURCE_CAMPAIGN:
			var faction_id := String(slot.get("faction_id", ""))
			if faction_id.is_empty() or seen_factions.has(faction_id):
				return false
			seen_factions[faction_id] = true
			if presentation_revision >= PRESENTATION_REVISION:
				if slot.get("presentation_kind", null) is not String or slot.get("presentation_id", null) is not String:
					return false
				var presentation_kind := StringName(slot.get("presentation_kind", ""))
				if presentation_kind not in CAMPAIGN_PRESENTATION_KINDS or String(slot.get("presentation_id", "")).is_empty():
					return false
				var presentation_key := "%s/%s" % [presentation_kind, String(slot.get("presentation_id", ""))]
				if seen_presentations.has(presentation_key):
					return false
				seen_presentations[presentation_key] = true
				if slot_index == (slots_value as Array).size() - 1:
					if presentation_kind != PRESENTATION_CANDIDATE:
						return false
				elif presentation_kind == PRESENTATION_CANDIDATE:
					return false
	return String(snapshot.get("final_boss_id", "")) == String((slots_value as Array).back().get("boss_id", ""))
