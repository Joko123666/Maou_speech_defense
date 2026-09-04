extends Node

const OUTPUT_PATH := "res://data/concepts/demon_election_content_pack.tres"
const CONTENT_ROOT := "res://data/content/demon_election"
const DATA_REGISTRY_SCRIPT := preload("res://autoload/data_registry.gd")

var save_errors := PackedStringArray()

func _ready() -> void:
	_export.call_deferred()

func _export() -> void:
	# The live DataRegistry has already applied CombatPace. Rebuild the source
	# catalogs on a detached instance so saved values remain pace-neutral.
	var builder := DATA_REGISTRY_SCRIPT.new()
	builder._build_cores()
	builder._build_cursors()
	builder._build_towers()
	builder._build_formations()
	builder._build_tower_branches()
	builder._build_specialization_branches()
	builder._build_enemies()
	builder._build_enemy_spawn_profiles()
	builder._build_bosses()

	var pack := ContentPackData.new()
	pack.id = &"demon_election_builtin_v019"
	pack.description = "활성 선거 콘셉트의 후보·심복·병력·편대·성장·적·보스 편집용 기본 콘텐츠 팩"
	pack.cores.assign(_save_catalog("cores", builder.cores))
	pack.cursors.assign(_save_catalog("cursors", builder.cursors))
	pack.towers.assign(_save_catalog("towers", builder.towers))
	pack.formations.assign(_save_catalog("formations", builder.formations))
	pack.tower_branches.assign(_save_catalog("tower_branches", builder.tower_branches))
	pack.specialization_branches.assign(_save_catalog("specializations", builder.specialization_branches))
	pack.enemies.assign(_save_catalog("enemies", builder.enemies + builder.faction_enemies))
	pack.bosses.assign(_save_catalog("bosses", builder.bosses))
	pack.enemy_spawn_profiles.assign(_save_catalog("spawn_profiles", builder.enemy_spawn_profiles, &"enemy_id"))
	if not save_errors.is_empty():
		push_error("Content item export rejected: %s" % ", ".join(save_errors))
		builder.free()
		get_tree().quit(1)
		return

	var errors := pack.get_validation_errors(ConceptService.get_default_stage(), ConceptService.get_stage_reward())
	if not errors.is_empty():
		push_error("Content pack export rejected: %s" % ", ".join(errors))
		builder.free()
		get_tree().quit(1)
		return
	var save_error := ResourceSaver.save(pack, OUTPUT_PATH)
	builder.free()
	if save_error != OK:
		push_error("Content pack export failed with error %d" % save_error)
		get_tree().quit(1)
		return
	print("CONTENT PACK EXPORT PASS: %s" % OUTPUT_PATH)
	get_tree().quit(0)

func _save_catalog(directory: String, catalog: Array, id_property: StringName = &"id") -> Array:
	var output: Array = []
	var directory_path := "%s/%s" % [CONTENT_ROOT, directory]
	var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory_path))
	if make_error != OK:
		save_errors.append("cannot create '%s' (error %d)" % [directory_path, make_error])
		return output
	for item in catalog:
		if item == null:
			save_errors.append("'%s' contains a null resource" % directory)
			continue
		var stable_id := String(item.get(id_property))
		if stable_id.is_empty() or stable_id.contains("/") or stable_id.contains("\\") or stable_id.contains(".."):
			save_errors.append("'%s' contains unsafe id '%s'" % [directory, stable_id])
			continue
		var item_path := "%s/%s.tres" % [directory_path, stable_id]
		var save_error := ResourceSaver.save(item, item_path)
		if save_error != OK:
			save_errors.append("cannot save '%s' (error %d)" % [item_path, save_error])
			continue
		var saved_item := ResourceLoader.load(item_path, "", ResourceLoader.CACHE_MODE_REPLACE)
		if saved_item == null:
			save_errors.append("cannot reload '%s'" % item_path)
			continue
		output.append(saved_item)
	return output
