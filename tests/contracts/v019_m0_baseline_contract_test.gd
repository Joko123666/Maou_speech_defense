class_name V019M0BaselineContractTest
extends RefCounted

const ACTIVE_PROFILE_PATH := "res://data/concepts/demon_election_vertical_slice.tres"
const COMPATIBILITY_PROFILE_PATH := "res://data/concepts/formation_defense.tres"

static func run() -> Array[String]:
	var failures: Array[String] = []
	_expect(String(ProjectSettings.get_setting("game/concept_profile", "")) == ACTIVE_PROFILE_PATH, "v0.19 must keep the election vertical slice as the active runtime profile", failures)
	_expect(ResourceLoader.exists(ACTIVE_PROFILE_PATH) and ResourceLoader.exists(COMPATIBILITY_PROFILE_PATH), "the active election profile and campaign-free compatibility profile must both remain available", failures)

	var gdd_source := FileAccess.get_file_as_string("res://godot_formation_defense_gdd_v0_19.md")
	_expect(gdd_source.contains("활성 콘셉트: `res://data/concepts/demon_election_vertical_slice.tres`"), "the v0.19 GDD header must name the runtime profile used by project.godot", failures)
	_expect(gdd_source.contains("## 첫 레벨업 `[확정]`") and gdd_source.contains("첫 레벨업에서 일반 병력 세트 1장을 보장"), "the v0.19 GDD must preserve the implemented first-level formation teaching contract", failures)

	_expect(DataRegistry.cores.size() == 5 and DataRegistry.cursors.size() == 5, "M0 must preserve the five-candidate and five-retainer combat foundation", failures)
	_expect(DataRegistry.NORMAL_DEFENDER_IDS.size() == 9 and DataRegistry.formations.size() == 55, "M0 must preserve the nine normal defenders and 55 block formations", failures)
	_expect(FileAccess.file_exists("res://scripts/progression/formation_placement_service.gd") and FileAccess.file_exists("res://scripts/progression/loadout_upgrade_application_service.gd") and FileAccess.file_exists("res://scripts/battlefield/enemy_spawn_director.gd"), "M0 must retain the existing board, growth, and SpawnDirector responsibility boundaries", failures)

	var audit_source := FileAccess.get_file_as_string("res://tests/balance_audit_runner.gd")
	var matrix_source := FileAccess.get_file_as_string("res://tests/balance_audit_matrix_runner.gd")
	_expect(audit_source.contains("AUDIT_REPORT_SCHEMA_VERSION := 20") and matrix_source.contains("AUDIT_REPORT_SCHEMA_VERSION := 20"), "the current elite-artifact-aware audit schema must invalidate older checkpoints", failures)
	_expect(audit_source.contains("GameSession.ARTIFACT_MODE_DISABLED") and audit_source.contains("\"artifact_mode\": String(artifact_mode)"), "each audit report must retain an explicit no-artifact control mode", failures)
	_expect(matrix_source.contains("GameSession.ARTIFACT_MODE_DISABLED") and matrix_source.contains("\"artifact_mode\": String(artifact_mode)"), "the matrix signature and summary must preserve the selected artifact control mode", failures)
	_expect(BalanceAuditBuildPolicy.REVISION >= 2 and RunRng.REVISION == 3, "the current RNG revision must include scheduled elite spawn and artifact-draft consumption", failures)
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
