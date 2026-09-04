class_name ArtifactRewardResolutionService
extends RefCounted

enum Status {
	INVALID,
	ACQUIRED,
	REPLACEMENT_REQUIRED,
	REPLACED,
	DISCARDED,
}

var loadout: LoadoutManager
var metrics: RunMetrics
var pending_choice: UpgradeData

func configure(target_loadout: LoadoutManager, run_metrics: RunMetrics) -> void:
	loadout = target_loadout
	metrics = run_metrics
	pending_choice = null

func begin(choice: UpgradeData) -> Dictionary:
	if not _can_resolve() or pending_choice != null or choice == null or choice.category != &"artifact":
		return _result(Status.INVALID)
	var artifact := _artifact_for(choice)
	if artifact == null or not loadout.is_artifact_eligible(artifact):
		return _result(Status.INVALID, choice, artifact)
	if loadout.artifact_inventory.is_full():
		pending_choice = choice
		return _result(Status.REPLACEMENT_REQUIRED, choice, artifact)
	if not loadout.equip_artifact(artifact.id):
		return _result(Status.INVALID, choice, artifact)
	_record_decision(artifact, &"acquired", &"artifact_equipped")
	return _result(Status.ACQUIRED, choice, artifact)

func replace(slot_index: int) -> Dictionary:
	if not _can_resolve() or pending_choice == null:
		return _result(Status.INVALID)
	var choice := pending_choice
	var artifact := _artifact_for(choice)
	if artifact == null or slot_index < 0 or slot_index >= loadout.artifact_inventory.artifact_ids.size():
		return _result(Status.INVALID, choice, artifact)
	var replaced_artifact_id := loadout.artifact_inventory.artifact_ids[slot_index]
	if not loadout.replace_artifact(slot_index, artifact.id):
		return _result(Status.INVALID, choice, artifact)
	pending_choice = null
	_record_decision(artifact, &"replaced", &"artifact_replaced", replaced_artifact_id)
	return _result(Status.REPLACED, choice, artifact, replaced_artifact_id)

func discard() -> Dictionary:
	if not _can_resolve() or pending_choice == null:
		return _result(Status.INVALID)
	var choice := pending_choice
	var artifact := _artifact_for(choice)
	if artifact == null:
		return _result(Status.INVALID, choice)
	pending_choice = null
	_record_decision(artifact, &"discarded", &"artifact_discarded")
	return _result(Status.DISCARDED, choice, artifact)

func reset() -> void:
	pending_choice = null

func _can_resolve() -> bool:
	return is_instance_valid(loadout)

func _artifact_for(choice: UpgradeData) -> ArtifactData:
	if choice == null or loadout.artifact_catalog == null:
		return null
	return loadout.artifact_catalog.find_artifact(choice.data_id)

func _record_decision(artifact: ArtifactData, action: StringName, event_id: StringName, replaced_artifact_id: StringName = &"") -> void:
	if not is_instance_valid(metrics):
		return
	metrics.record_artifact_decision(artifact, action, loadout.get_artifact_snapshot(), replaced_artifact_id)
	metrics.record_mechanic_event(event_id)

func _result(status: int, choice: UpgradeData = null, artifact: ArtifactData = null, replaced_artifact_id: StringName = &"") -> Dictionary:
	return {
		"status": status,
		"choice": choice,
		"artifact": artifact,
		"replaced_artifact_id": replaced_artifact_id,
	}
