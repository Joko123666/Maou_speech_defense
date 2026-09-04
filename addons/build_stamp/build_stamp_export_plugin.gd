@tool
extends EditorExportPlugin

const METADATA_PATH := "res://build_info.json"
const FALLBACK_VERSION := "0.04"

func _get_name() -> String:
	return "BuildStamp"

func _export_begin(features: PackedStringArray, is_debug: bool, path: String, _flags: int) -> void:
	var now := Time.get_datetime_dict_from_system()
	var build_id := "%04d%02d%02d.%02d%02d%02d" % [
		int(now.year),
		int(now.month),
		int(now.day),
		int(now.hour),
		int(now.minute),
		int(now.second),
	]
	var version := String(ProjectSettings.get_setting("application/config/version", FALLBACK_VERSION)).strip_edges()
	if version.is_empty():
		version = FALLBACK_VERSION
	var metadata := {
		"schema_version": 1,
		"version": version,
		"build_id": build_id,
		"built_at_unix_ms": int(Time.get_unix_time_from_system() * 1000.0),
		"target": _target_name(features),
		"mode": "debug" if is_debug else "release",
		"output_file": path.get_file(),
	}
	add_file(METADATA_PATH, JSON.stringify(metadata).to_utf8_buffer(), false)
	print("BUILD STAMP: v%s · build %s (%s %s)" % [version, build_id, metadata.target, metadata.mode])

func _target_name(features: PackedStringArray) -> String:
	for target in ["android", "windows", "macos", "linux", "web", "ios"]:
		if features.has(target):
			return target
	return "unknown"
