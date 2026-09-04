class_name BuildInfo
extends RefCounted

const METADATA_PATH := "res://build_info.json"
const FALLBACK_VERSION := "0.04"

static func display_text() -> String:
	var metadata := read_metadata()
	var version := String(metadata.get("version", ProjectSettings.get_setting("application/config/version", FALLBACK_VERSION))).strip_edges()
	if version.is_empty():
		version = FALLBACK_VERSION
	var build_id := String(metadata.get("build_id", "")).strip_edges()
	if build_id.is_empty():
		return "v%s · DEV" % version
	return "v%s · build %s" % [version, build_id]

static func read_metadata() -> Dictionary:
	if not FileAccess.file_exists(METADATA_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(METADATA_PATH))
	if parsed is not Dictionary:
		push_warning("Build metadata is not a JSON object: %s" % METADATA_PATH)
		return {}
	var metadata := parsed as Dictionary
	if int(metadata.get("schema_version", 0)) != 1:
		push_warning("Build metadata schema is unsupported: %s" % METADATA_PATH)
		return {}
	return metadata
