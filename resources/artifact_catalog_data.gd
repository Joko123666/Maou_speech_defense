class_name ArtifactCatalogData
extends Resource

const INITIAL_CATALOG_SIZE := 18

@export var artifacts: Array[ArtifactData] = []

func find_artifact(artifact_id: StringName) -> ArtifactData:
	for artifact in artifacts:
		if artifact != null and artifact.id == artifact_id:
			return artifact
	return null

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if artifacts.size() != INITIAL_CATALOG_SIZE:
		errors.append("artifact catalog must contain exactly %d initial artifacts" % INITIAL_CATALOG_SIZE)
	var ids: Dictionary = {}
	for artifact in artifacts:
		if artifact == null:
			errors.append("artifact catalog contains a null artifact")
			continue
		if ids.has(artifact.id): errors.append("duplicate artifact '%s'" % artifact.id)
		ids[artifact.id] = true
		errors.append_array(artifact.get_validation_errors())
	return errors
