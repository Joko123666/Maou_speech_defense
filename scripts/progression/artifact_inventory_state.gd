class_name ArtifactInventoryState
extends RefCounted

const DEFAULT_CAPACITY := 6

var capacity: int = DEFAULT_CAPACITY
var artifact_ids: Array[StringName] = []

func reset() -> void:
	artifact_ids.clear()

func is_full() -> bool:
	return artifact_ids.size() >= capacity

func contains(artifact_id: StringName) -> bool:
	return artifact_id in artifact_ids

func equip(artifact_id: StringName) -> bool:
	if artifact_id == &"" or contains(artifact_id) or is_full():
		return false
	artifact_ids.append(artifact_id)
	return true

func remove_at(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= artifact_ids.size():
		return false
	artifact_ids.remove_at(slot_index)
	return true

func replace(slot_index: int, artifact_id: StringName) -> bool:
	if slot_index < 0 or slot_index >= artifact_ids.size() or artifact_id == &"" or contains(artifact_id):
		return false
	artifact_ids[slot_index] = artifact_id
	return true

func snapshot() -> Dictionary:
	var ids: Array[String] = []
	for artifact_id in artifact_ids:
		ids.append(String(artifact_id))
	return {"capacity": capacity, "artifact_ids": ids, "count": artifact_ids.size()}

func restore(snapshot: Dictionary, catalog: ArtifactCatalogData = null) -> void:
	artifact_ids.clear()
	# 슬롯 수는 런 규칙이다. 외부/구버전 스냅샷이 용량을 늘릴 수 없다.
	capacity = DEFAULT_CAPACITY
	var raw_ids: Variant = snapshot.get("artifact_ids", [])
	if not raw_ids is Array:
		return
	for raw_id in raw_ids as Array:
		var artifact_id := StringName(raw_id)
		if artifact_ids.size() >= capacity or artifact_id == &"" or artifact_id in artifact_ids:
			continue
		if catalog == null or catalog.find_artifact(artifact_id) != null:
			artifact_ids.append(artifact_id)
