@tool
extends EditorPlugin

const BUILD_STAMP_EXPORT_PLUGIN := preload("res://addons/build_stamp/build_stamp_export_plugin.gd")

var export_plugin: EditorExportPlugin

func _enter_tree() -> void:
	export_plugin = BUILD_STAMP_EXPORT_PLUGIN.new()
	add_export_plugin(export_plugin)

func _exit_tree() -> void:
	if export_plugin != null:
		remove_export_plugin(export_plugin)
		export_plugin = null
