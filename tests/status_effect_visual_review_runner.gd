extends Node2D

const OUTPUT_PATH := "res://tests/visual_reviews/status_effect_visual_review.png"
const DENSITY_OUTPUT_PATH := "res://tests/visual_reviews/status_effect_density_review.png"
const SAMPLE_IDS: Array[StringName] = [
	&"poison", &"bleed", &"shock", &"burn",
	&"slow", &"fear", &"charm", &"stun",
	&"freeze", &"mark", &"sentence", &"pierce_mark",
	&"frost_stack", &"haste", &"fortify", &"knockback",
]
const SAMPLE_LABELS: Array[String] = [
	"POISON", "BLEED", "SHOCK", "BURN",
	"SLOW", "FEAR", "CHARM", "STUN",
	"FREEZE", "MARK", "SENTENCE", "PIERCE MARK",
	"FROST STACK", "HASTE", "FORTIFY", "KNOCKBACK",
]

var sample_positions: Array[Vector2] = []
var review_mode: StringName = &"catalog"

func _ready() -> void:
	_build_positions()
	queue_redraw()
	_run.call_deferred()

func _build_positions() -> void:
	for index in SAMPLE_IDS.size():
		var column := index % 4
		var row := index / 4
		sample_positions.append(Vector2(190.0 + column * 300.0, 140.0 + row * 145.0))

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/visual_reviews"))
	for index in SAMPLE_IDS.size():
		var enemy := Enemy.new()
		add_child(enemy)
		var sample_position := sample_positions[index]
		enemy.setup(DataRegistry.get_enemy(&"normal"), sample_position, index % 4, sample_position + Vector2(-180.0, 0.0), 100.0, 1.0)
		enemy.set_process(false)
		enemy.set_physics_process(false)
		_apply_sample(enemy, SAMPLE_IDS[index])
		if SAMPLE_IDS[index] != &"knockback":
			enemy.status_visual_flashes[SAMPLE_IDS[index]] = 0.35
	for _frame in 8:
		await get_tree().process_frame
	_capture(OUTPUT_PATH)
	for child in get_children():
		if child is Enemy:
			child.free()
	review_mode = &"density"
	_build_density_samples()
	queue_redraw()
	for _frame in 8:
		await get_tree().process_frame
	_capture(DENSITY_OUTPUT_PATH)
	print("STATUS EFFECT VISUAL REVIEW PASS: %s" % OUTPUT_PATH)
	print("STATUS EFFECT DENSITY REVIEW PASS: %s" % DENSITY_OUTPUT_PATH)
	get_tree().quit(0)

func _capture(path: String) -> void:
	var image := get_viewport().get_texture().get_image()
	image.save_png(path)

func _build_density_samples() -> void:
	var enemy_ids: Array[StringName] = [&"normal", &"fast", &"swarm", &"armored", &"regenerator", &"charger"]
	for lane in 4:
		for column in 10:
			var enemy := Enemy.new()
			add_child(enemy)
			var sample_position := Vector2(300.0 + column * 88.0, 155.0 + lane * 142.0)
			enemy.setup(DataRegistry.get_enemy(enemy_ids[(lane + column) % enemy_ids.size()]), sample_position, lane, Vector2(150.0, sample_position.y), 100.0, 1.0)
			enemy.set_process(false)
			enemy.set_physics_process(false)
			_apply_density_combo(enemy, (lane * 10 + column) % 7)
			enemy.status_visual_flashes.clear()

func _apply_density_combo(enemy: Enemy, combo_index: int) -> void:
	match combo_index:
		0:
			enemy.apply_common_poison(5.0, 5.0, 3)
			enemy.apply_slow(&"density", 5.0, 0.3)
		1:
			enemy.apply_common_bleed(&"density", 0.001, 5.0, 3, 20.0)
			enemy.apply_status(&"mark", 5.0, 0.2)
		2:
			enemy.apply_common_shock(5.0, 3)
			enemy.apply_status(&"stun", 5.0, 1.0)
		3:
			enemy.apply_common_burn(&"density", 5.0, 5.0, 2)
			enemy.apply_fear(5.0, 0.5)
		4:
			enemy.apply_common_poison(5.0, 5.0, 3)
			enemy.apply_common_bleed(&"density_all", 0.001, 5.0, 3, 20.0)
			enemy.apply_common_shock(5.0, 3)
			enemy.apply_common_burn(&"density_all", 5.0, 5.0, 2)
		5:
			enemy.apply_slow(&"density", 5.0, 0.3)
			enemy.apply_status(&"pierce_mark", 5.0, 1.0)
			enemy.apply_status(&"fortify", 5.0, 2.0)
		6:
			enemy.apply_charm(CharmProfileData.new(), 5.0)
			enemy.add_sentence_stacks(2, 5.0)

func _apply_sample(enemy: Enemy, status_id: StringName) -> void:
	match status_id:
		&"poison":
			enemy.apply_common_poison(5.0, 5.0, 3)
			enemy.apply_common_poison(5.0, 5.0, 3)
		&"bleed":
			enemy.apply_common_bleed(&"visual_review", 0.001, 5.0, 3, 20.0)
			enemy.apply_common_bleed(&"visual_review", 0.001, 5.0, 3, 20.0)
		&"shock":
			enemy.apply_common_shock(5.0, 3)
			enemy.apply_common_shock(5.0, 3)
		&"burn":
			enemy.apply_common_burn(&"visual_review", 5.0, 5.0, 2)
		&"slow":
			enemy.apply_slow(&"visual_review", 5.0, 0.35)
		&"fear":
			enemy.apply_fear(5.0, 0.6)
		&"charm":
			enemy.apply_charm(CharmProfileData.new(), 5.0)
		&"stun", &"freeze", &"mark", &"pierce_mark", &"haste", &"fortify":
			enemy.apply_status(status_id, 5.0, 1.0)
		&"sentence":
			enemy.add_sentence_stacks(2, 5.0)
		&"frost_stack":
			enemy.statuses[&"frost_stack"] = {"remaining": 5.0, "power": 3}
			enemy.trigger_status_visual(&"frost_stack")
		&"knockback":
			enemy.apply_knockback(52.0)

func _draw() -> void:
	if review_mode == &"density":
		_draw_density_background()
		return
	_draw_catalog_background()

func _draw_catalog_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), Color("111a27"), true)
	draw_string(ThemeDB.fallback_font, Vector2(42.0, 37.0), "ENEMY STATUS EFFECTS · COMPACT MOBILE READABILITY", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color("f0d58a"))
	draw_string(ThemeDB.fallback_font, Vector2(42.0, 60.0), "One shared 4×4 atlas · fixed visual layers · brief application pulse · no particles or child nodes", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("aeb8cf"))
	for index in SAMPLE_IDS.size():
		var center := sample_positions[index]
		var panel := Rect2(center + Vector2(-126.0, -57.0), Vector2(252.0, 120.0))
		draw_rect(panel, Color("192638"), true)
		draw_rect(panel, Color("334762"), false, 1.0)
		draw_string(ThemeDB.fallback_font, center + Vector2(-100.0, 53.0), SAMPLE_LABELS[index], HORIZONTAL_ALIGNMENT_CENTER, 200.0, 12, EnemyStatusEffectRenderer.color_for(SAMPLE_IDS[index]))

func _draw_density_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), Color("101824"), true)
	draw_string(ThemeDB.fallback_font, Vector2(42.0, 37.0), "STATUS DENSITY STRESS · 40 ENEMIES / MIXED EFFECTS", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color("f0d58a"))
	draw_string(ThemeDB.fallback_font, Vector2(42.0, 60.0), "Settled persistent state · worst-case four-ailment clusters included · no full-screen glow or orbit trails", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, Color("aeb8cf"))
	var battle_rect := Rect2(150.0, 82.0, 1060.0, 568.0)
	draw_rect(battle_rect, Color("182638"), true)
	draw_rect(battle_rect, Color("425976"), false, 2.0)
	for lane in 4:
		var lane_y := 155.0 + lane * 142.0
		draw_line(Vector2(battle_rect.position.x, lane_y), Vector2(battle_rect.end.x, lane_y), Color("30445e", 0.68), 1.0)
