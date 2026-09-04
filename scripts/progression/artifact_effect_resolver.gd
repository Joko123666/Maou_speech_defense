class_name ArtifactEffectResolver
extends RefCounted

const CATALOG_PATH := "res://data/meta/artifact_catalog_v0_19.tres"

var catalog: ArtifactCatalogData
var inventory: ArtifactInventoryState

func _init(source_catalog: ArtifactCatalogData = null, source_inventory: ArtifactInventoryState = null) -> void:
	catalog = source_catalog if source_catalog != null else load(CATALOG_PATH) as ArtifactCatalogData
	inventory = source_inventory if source_inventory != null else ArtifactInventoryState.new()

func multiplier(target_group: StringName, stat_key: StringName) -> float:
	var bonus := 0.0
	for effect in _active_effects():
		if effect.target_group == target_group and effect.stat_key == stat_key and effect.value_mode == ArtifactEffectData.MULTIPLIER_BONUS:
			bonus += effect.value
	return maxf(1.0 + bonus, 0.01)

func fixed_bonus(target_group: StringName, stat_key: StringName) -> float:
	var bonus := 0.0
	for effect in _active_effects():
		if effect.target_group == target_group and effect.stat_key == stat_key and effect.value_mode == ArtifactEffectData.FIXED_BONUS:
			bonus += effect.value
	return bonus

func defense_axis_bonuses() -> Dictionary:
	var result := {&"power": 0.0, &"speed": 0.0, &"range": 0.0}
	for effect in _active_effects():
		if effect.target_group == &"normal_defender" and effect.axis_id in DefenseStatCatalogData.REQUIRED_AXIS_IDS:
			result[effect.axis_id] = float(result[effect.axis_id]) + effect.value
	return result

func status_damage_multiplier(status_id: StringName) -> float:
	var bonus := 0.0
	for effect in _active_effects():
		if effect.target_group == &"status" and effect.status_id == status_id and effect.stat_key == &"damage" and effect.value_mode == ArtifactEffectData.MULTIPLIER_BONUS:
			bonus += effect.value
	return maxf(1.0 + bonus, 0.01)

func apply_status_profile(status_id: StringName, profile: Dictionary) -> Dictionary:
	if profile.is_empty():
		return profile
	var result := profile.duplicate(true)
	var scale := status_damage_multiplier(status_id)
	match status_id:
		&"poison": result["damage_per_second"] = float(result.get("damage_per_second", 0.0)) * scale
		&"burn": result["damage_ratio"] = float(result.get("damage_ratio", 0.0)) * scale
		&"bleed":
			result["health_ratio"] = float(result.get("health_ratio", 0.0)) * scale
			result["damage_cap"] = float(result.get("damage_cap", 0.0)) * scale
		&"shock": result["damage"] = float(result.get("damage", 0.0)) * scale
	return result

func active_artifacts() -> Array[ArtifactData]:
	var result: Array[ArtifactData] = []
	if catalog == null or inventory == null:
		return result
	for artifact_id in inventory.artifact_ids:
		var artifact := catalog.find_artifact(artifact_id)
		if artifact != null:
			result.append(artifact)
	return result

func _active_effects() -> Array[ArtifactEffectData]:
	var result: Array[ArtifactEffectData] = []
	for artifact in active_artifacts():
		result.append_array(artifact.effects)
	return result
