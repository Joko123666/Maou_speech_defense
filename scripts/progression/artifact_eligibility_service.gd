class_name ArtifactEligibilityService
extends RefCounted

func eligible_artifacts(catalog: ArtifactCatalogData, context: Dictionary) -> Array[ArtifactData]:
	var result: Array[ArtifactData] = []
	if catalog == null:
		return result
	for artifact in catalog.artifacts:
		if is_eligible(artifact, context):
			result.append(artifact)
	return result

func is_eligible(artifact: ArtifactData, context: Dictionary) -> bool:
	if artifact == null or not artifact.get_validation_errors().is_empty():
		return false
	var equipped_ids := _name_array(context.get("equipped_artifact_ids", []))
	if artifact.id in equipped_ids:
		return false
	var roles := _name_array(context.get("role_tags", []))
	for required_role in artifact.required_role_tags:
		if required_role not in roles:
			return false
	var status_sources := _name_array(context.get("status_source_ids", []))
	for required_status in artifact.required_status_ids:
		if required_status not in status_sources:
			return false
	for effect in artifact.effects:
		if effect == null or not _effect_has_target(effect, context, status_sources):
			return false
	return true

func _effect_has_target(effect: ArtifactEffectData, context: Dictionary, status_sources: Array[StringName]) -> bool:
	match effect.target_group:
		&"normal_defender": return not _name_array(context.get("installed_tower_ids", [])).is_empty()
		&"candidate": return bool(context.get("candidate_available", false))
		&"retainer": return bool(context.get("retainer_available", false))
		&"guard": return bool(context.get("guard_available", false))
		&"status": return effect.status_id in status_sources
	return false

func _name_array(value: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if value is Array:
		for item in value:
			result.append(StringName(item))
	return result
