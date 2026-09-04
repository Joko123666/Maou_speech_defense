class_name AudiencePresentationContractTest
extends RefCounted

const DEMON_BACKGROUND := "res://assets/graphics/backgrounds/demon_election_campaign_arena_v019.png"
const STAGED_DEMON_BACKGROUND := "res://assets/graphics/style_refresh_v019/backgrounds/demon_election_campaign_arena_v019.png"
const FORMATION_BACKGROUND := "res://assets/graphics/backgrounds/formation_campaign_arena_v019.png"
const CROWD_TEXTURE := "res://assets/graphics/audience/demon_spectator_ribbon_v019.png"

static func run(root: Node) -> Array[String]:
	var failures: Array[String] = []
	_test_background_assets(failures)
	_test_audience_asset(failures)
	_test_runtime_stage(root, failures)
	_test_integration_hooks(failures)
	return failures

static func _test_background_assets(failures: Array[String]) -> void:
	for path in [DEMON_BACKGROUND, FORMATION_BACKGROUND]:
		_expect(ResourceLoader.exists(path), "audience refresh background is missing: %s" % path, failures)
		var texture := load(path) as Texture2D
		var image := texture.get_image() if texture != null else Image.new()
		_expect(not image.is_empty(), "audience refresh background cannot be decoded: %s" % path, failures)
		if not image.is_empty():
			_expect(image.get_size() == Vector2i(1280, 720), "audience refresh background must be exactly 1280x720: %s" % path, failures)
	var demon_assets := FileAccess.get_file_as_string("res://data/concepts/demon_election_assets.tres")
	var formation_assets := FileAccess.get_file_as_string("res://data/concepts/formation_defense_assets.tres")
	_expect(DEMON_BACKGROUND in demon_assets and "demon_election_rally_plaza.png" not in demon_assets, "active demon concept must use only the v0.19 campaign arena", failures)
	_expect(FORMATION_BACKGROUND in formation_assets and "battlefield_background.png" not in formation_assets, "formation fallback must not retain the legacy science-fiction background", failures)
	_expect(FileAccess.file_exists(STAGED_DEMON_BACKGROUND), "minimal-detail campaign arena staging master is missing", failures)
	_expect(FileAccess.get_file_as_bytes(DEMON_BACKGROUND) == FileAccess.get_file_as_bytes(STAGED_DEMON_BACKGROUND), "active campaign arena must match its approved minimal-detail staging master", failures)

static func _test_audience_asset(failures: Array[String]) -> void:
	_expect(ResourceLoader.exists(CROWD_TEXTURE), "dynamic audience ribbon is missing", failures)
	var texture := load(CROWD_TEXTURE) as Texture2D
	var image := texture.get_image() if texture != null else Image.new()
	_expect(not image.is_empty(), "dynamic audience ribbon cannot be decoded", failures)
	if image.is_empty():
		return
	var size := image.get_size()
	_expect(image.detect_alpha() != Image.ALPHA_NONE, "dynamic audience ribbon must preserve real transparency", failures)
	_expect(float(size.x) / maxf(float(size.y), 1.0) >= 7.0, "dynamic audience ribbon must remain shallow enough for the 75px gallery", failures)
	_expect(image.get_pixel(0, 0).a <= 0.02 and image.get_pixel(size.x - 1, 0).a <= 0.02, "dynamic audience ribbon top corners must remain transparent", failures)

static func _test_runtime_stage(root: Node, failures: Array[String]) -> void:
	var stage := AudienceReactionStage.new()
	stage.crowd_texture = load(CROWD_TEXTURE) as Texture2D
	root.add_child(stage)
	stage.configure(Color("d83a91"), false)
	var idle_state := stage.get_presentation_state()
	_expect(bool(idle_state.has_crowd_texture), "audience stage must expose the crowd texture", failures)
	var viewport_size := root.get_viewport().get_visible_rect().size
	var expected_gallery := Rect2(150.0, viewport_size.y - 75.0, maxf(viewport_size.x - 220.0, 0.0), minf(75.0, viewport_size.y))
	_expect(idle_state.gallery_rect == expected_gallery, "audience stage must use the existing bottom margin without shrinking the battlefield", failures)
	stage.set_threat_level(AudienceReactionStage.THREAT_DANGER)
	_expect(int(stage.get_presentation_state().threat_level) == AudienceReactionStage.THREAT_DANGER, "audience stage must expose enemy-approach danger state", failures)
	stage.react(&"skill_release", Color("fff0a8"), 1.0, 1.8)
	_expect(StringName(stage.get_presentation_state().reaction) == &"skill_release", "audience stage must expose candidate skill reactions", failures)
	stage.set_reduced_motion_enabled(true)
	_expect(bool(stage.get_presentation_state().reduced_motion), "audience reactions must honor the persisted reduced-motion option", failures)
	stage.free()

static func _test_integration_hooks(failures: Array[String]) -> void:
	var game_scene := FileAccess.get_file_as_string("res://scenes/game/game.tscn")
	var controller := FileAccess.get_file_as_string("res://scripts/game/game_controller.gd")
	_expect("AudienceStage" in game_scene and CROWD_TEXTURE in game_scene, "game scene must mount the dynamic audience below combat actors", failures)
	for hook in ["skill_cast", "skill_release", "boss_warning", "breach", "boss_defeated", "_update_audience_threat"]:
		_expect(hook in controller, "game controller is missing audience presentation hook '%s'" % hook, failures)
	_expect("audience_stage.set_reduced_motion_enabled" in controller, "reduced-motion changes must reach the audience presentation", failures)
	_expect(not FileAccess.file_exists("res://assets/graphics/backgrounds/battlefield_background.png") and not FileAccess.file_exists("res://assets/graphics/backgrounds/demon_election_rally_plaza.png"), "unreferenced legacy backgrounds must be removed from the project", failures)

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
