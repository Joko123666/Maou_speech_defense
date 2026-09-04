class_name EnemyStatusVisualContractTest
extends RefCounted

const EXPECTED_STATUS_IDS: Array[StringName] = [
	&"poison", &"bleed", &"shock", &"burn",
	&"slow", &"fear", &"charm", &"stun", &"freeze",
	&"mark", &"sentence", &"pierce_mark", &"frost_stack",
	&"haste", &"fortify",
]
const EXPECTED_TRANSIENT_IDS: Array[StringName] = [&"knockback"]
const STATUS_ICON_PATH := "res://assets/graphics/effects/status_effect_icon_atlas_v019.png"

static func run(root: Node) -> Array[String]:
	var failures: Array[String] = []
	_expect(EnemyStatusEffectRenderer.SUPPORTED_STATUS_IDS == EXPECTED_STATUS_IDS, "the enemy status renderer must cover every active ailment, control, mark, stack, and enemy buff ID", failures)
	_expect(EnemyStatusEffectRenderer.TRANSIENT_EFFECT_IDS == EXPECTED_TRANSIENT_IDS, "knockback must have its own transient directional visual contract", failures)
	_expect(FileAccess.file_exists(STATUS_ICON_PATH), "the v0.19 status icon atlas must exist at its stable active path", failures)
	var atlas := load(STATUS_ICON_PATH) as Texture2D
	_expect(atlas != null and atlas.get_size() == Vector2(512.0, 512.0), "the status atlas must import at the 512px mobile cap", failures)
	var source_image := Image.load_from_file(ProjectSettings.globalize_path(STATUS_ICON_PATH))
	_expect(source_image != null and source_image.get_size() == Vector2i(1024, 1024) and source_image.get_format() in [Image.FORMAT_RGBA8, Image.FORMAT_RGBAF, Image.FORMAT_RGBAH], "the status atlas source must be a square alpha-capable RGBA master", failures)
	if source_image != null and not source_image.is_empty():
		var corners := [Vector2i.ZERO, Vector2i(1023, 0), Vector2i(0, 1023), Vector2i(1023, 1023)]
		_expect(corners.all(func(point: Vector2i) -> bool: return source_image.get_pixelv(point).a <= 0.01), "the status atlas must preserve truly transparent corners", failures)
	var import_path := STATUS_ICON_PATH + ".import"
	_expect(FileAccess.file_exists(import_path) and FileAccess.get_file_as_string(import_path).contains("process/size_limit=512"), "the status atlas import must preserve the 512px mobile cap", failures)

	var families: Array[StringName] = []
	var icon_cells: Array[Vector2i] = []
	for status_id in EXPECTED_STATUS_IDS + EnemyStatusEffectRenderer.TRANSIENT_EFFECT_IDS:
		var family := EnemyStatusEffectRenderer.visual_family_for(status_id)
		_expect(family != &"", "status '%s' must expose a named silhouette family" % status_id, failures)
		families.append(family)
		var icon_cell := EnemyStatusEffectRenderer.icon_cell_for(status_id)
		_expect(icon_cell.x >= 0 and icon_cell.x < 4 and icon_cell.y >= 0 and icon_cell.y < 4, "status '%s' must map to one bounded atlas cell" % status_id, failures)
		icon_cells.append(icon_cell)
	_expect(_unique_count(families) == families.size(), "each supported status and knockback must use a distinct silhouette family instead of color-only differentiation", failures)
	_expect(_unique_vector_count(icon_cells) == 16, "the 16 status and transient visuals must occupy distinct atlas cells", failures)
	_expect(EnemyStatusEffectRenderer.color_for(&"stun").r > 0.9 and EnemyStatusEffectRenderer.color_for(&"stun").g > 0.7, "stun must use the GDD yellow impact language", failures)
	_expect(EnemyStatusEffectRenderer.color_for(&"freeze").b > EnemyStatusEffectRenderer.color_for(&"freeze").r and EnemyStatusEffectRenderer.color_for(&"fear").b > EnemyStatusEffectRenderer.color_for(&"fear").g, "freeze and fear must retain distinct cyan and muted-purple control palettes", failures)

	var deduplicated := EnemyStatusEffectRenderer.active_visual_ids(
		{&"burn": {}, &"slow": {}, &"mark": {}},
		{&"poison": {}, &"burn": {}, &"shock": {}}
	)
	var expected_deduplicated: Array[StringName] = [&"poison", &"shock", &"burn", &"slow", &"mark"]
	_expect(deduplicated == expected_deduplicated, "status visual ordering must be stable and must not render legacy/common burn twice", failures)

	var enemy := Enemy.new()
	root.add_child(enemy)
	enemy.set_process(false)
	enemy.set_physics_process(false)
	enemy.setup(DataRegistry.get_enemy(&"normal"), Vector2(520.0, 220.0), 0, Vector2(120.0, 220.0), 50.0, 1.0)
	enemy.apply_common_poison(5.0, 5.0, 3)
	enemy.apply_common_bleed(&"visual_contract", 0.001, 4.0, 3, 20.0)
	enemy.apply_common_shock(4.0, 3)
	enemy.apply_common_burn(&"visual_contract", 4.0, 4.0, 2)
	enemy.apply_slow(&"visual_contract", 3.0, 0.3)
	enemy.apply_fear(2.0, 0.5)
	enemy.apply_charm(CharmProfileData.new())
	enemy.apply_status(&"stun", 1.0, 1.0)
	enemy.apply_status(&"mark", 3.0, 0.2)
	enemy.add_sentence_stacks(2, 3.0)
	enemy.apply_status(&"pierce_mark", 3.0, 1.0)
	enemy.statuses[&"frost_stack"] = {"remaining": 3.0, "power": 2}
	enemy.trigger_status_visual(&"frost_stack")
	enemy.apply_status(&"haste", 3.0, 0.2)
	enemy.apply_status(&"fortify", 3.0, 2.0)
	var active_ids := enemy.get_active_status_visual_ids()
	for expected_id in [&"poison", &"bleed", &"shock", &"burn", &"slow", &"fear", &"charm", &"stun", &"mark", &"sentence", &"pierce_mark", &"frost_stack", &"haste", &"fortify"]:
		_expect(expected_id in active_ids, "successfully applied status '%s' must be routed to the persistent enemy visual layer" % expected_id, failures)
		_expect(enemy.status_visual_flashes.has(expected_id), "status '%s' application must trigger only its short readability pulse" % expected_id, failures)
	var previous_distance := enemy.position.distance_to(enemy.target_position)
	var knockback_distance := enemy.apply_knockback(45.0)
	_expect(knockback_distance > 0.0 and enemy.position.distance_to(enemy.target_position) > previous_distance and enemy.knockback_flash > 0.9, "accepted knockback must create a short direction-matched compression effect", failures)

	enemy.clear_statuses()
	var expected_beneficial: Array[StringName] = [&"haste", &"fortify"]
	_expect(enemy.get_active_status_visual_ids() == expected_beneficial, "cleanse must remove negative visual state while preserving beneficial haste and fortify", failures)
	enemy.free()
	return failures

static func _unique_count(values: Array[StringName]) -> int:
	var unique := {}
	for value in values:
		unique[value] = true
	return unique.size()

static func _unique_vector_count(values: Array[Vector2i]) -> int:
	var unique := {}
	for value in values:
		unique[value] = true
	return unique.size()

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
