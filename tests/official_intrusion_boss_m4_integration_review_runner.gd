extends Control

const CAPTURE_ARGUMENTS := {
	"--capture-1280": {"path": "res://tests/visual_reviews/official_intrusion_boss_m4_integration_1280x720.png", "size": Vector2i(1280, 720)},
	"--capture-wide": {"path": "res://tests/visual_reviews/official_intrusion_boss_m4_integration_1600x720.png", "size": Vector2i(1600, 720)},
	"--capture-fhd": {"path": "res://tests/visual_reviews/official_intrusion_boss_m4_integration_1920x1080.png", "size": Vector2i(1920, 1080)},
}

func _ready() -> void:
	_build_review()
	for argument in OS.get_cmdline_user_args():
		if CAPTURE_ARGUMENTS.has(argument):
			var capture := CAPTURE_ARGUMENTS[argument] as Dictionary
			_capture_and_quit.call_deferred(String(capture.path), capture.size as Vector2i)
			return

func _build_review() -> void:
	var battlefield := TextureRect.new()
	battlefield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	battlefield.texture = ConceptService.texture(&"battlefield_background")
	battlefield.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	battlefield.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(battlefield)
	var wash := ColorRect.new()
	wash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wash.color = Color(0.025, 0.03, 0.075, 0.9)
	add_child(wash)

	_add_panel(Rect2(16, 12, 1248, 58), Color("111725ee"), Color("c9a75d"), 2)
	_add_label(Rect2(32, 17, 1216, 25), "OFFICIAL INTRUSION M4 · FULL PRESENTATION MATRIX", Color("f0d58a"), 18)
	_add_label(Rect2(32, 42, 1216, 19), "Five guard-collision fixtures · actual campaign resolver · direct active candidate / retainer / guard textures", Color("cbd2e2"), 10)

	var scenarios := _guard_collision_scenarios()
	if scenarios.size() != 5:
		push_error("official intrusion M4 review requires five guard-collision scenarios")
	for row_index in scenarios.size():
		_build_scenario_row(scenarios[row_index] as Dictionary, row_index)

	_add_panel(Rect2(16, 641, 1248, 63), Color("111725ee"), Color("758097"), 1)
	_add_label(Rect2(32, 648, 1216, 20), "M4 GATE · 5 CANDIDATES × 5 RETAINERS × 3 SEEDS = 75 PLANS / 300 SLOTS", Color("f0d58a"), 11)
	_add_label(Rect2(32, 672, 1216, 19), "Opening: RETAINER or same-faction GUARD · Final: unselected CANDIDATE · no ally duplicate · no horizontal flip", Color("d7dce8"), 10)

func _guard_collision_scenarios() -> Array[Dictionary]:
	var scenarios: Array[Dictionary] = []
	var campaign := ConceptService.get_election_campaign()
	var stage := ConceptService.get_default_stage()
	if campaign == null or stage == null:
		return scenarios
	for target_index in campaign.factions.size():
		var target_faction := campaign.factions[target_index]
		var target_candidate := campaign.candidate(target_faction.candidate_id) if target_faction != null else null
		if target_candidate == null:
			continue
		var selected_candidate := campaign.candidates[(target_index + 1) % campaign.candidates.size()]
		var selected_retainer := campaign.retainer(target_candidate.default_retainer_id)
		if selected_candidate == null or selected_retainer == null:
			continue
		for seed_value in range(1, 257):
			var plan := CampaignStageResolver.resolve(stage, DataRegistry.bosses, campaign, selected_candidate.core_id, selected_retainer.cursor_id, seed_value)
			var guard_found := false
			for slot_index in plan.slots.size() - 1:
				guard_found = guard_found or (
					plan.presentation_kind_at(slot_index) == StageRuntimeBossPlan.PRESENTATION_GUARD
					and plan.presentation_id_at(slot_index) == target_faction.id
				)
			if guard_found:
				scenarios.append({
					"selected_candidate": selected_candidate,
					"selected_retainer": selected_retainer,
					"target_faction": target_faction,
					"plan": plan,
					"seed": seed_value,
				})
				break
	return scenarios

func _build_scenario_row(scenario: Dictionary, row_index: int) -> void:
	var row_y := 78.0 + row_index * 112.0
	var selected_candidate := scenario.selected_candidate as CandidateProfileData
	var selected_retainer := scenario.selected_retainer as RetainerProfileData
	var target_faction := scenario.target_faction as ElectionFactionData
	var plan := scenario.plan as StageRuntimeBossPlan
	var accent := target_faction.accent_color
	_add_panel(Rect2(16, row_y, 1248, 103), Color("182033df"), Color(accent, 0.8), 1)
	_add_label(Rect2(28, row_y + 8, 250, 19), "ALLY · %s + %s" % [selected_candidate.short_name, selected_retainer.short_name], Color("f7f2e7"), 10, HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(Rect2(28, row_y + 31, 250, 18), "FORCES %s GUARD" % target_faction.display_name, accent.lightened(0.22), 9, HORIZONTAL_ALIGNMENT_LEFT)
	_add_label(Rect2(28, row_y + 55, 250, 16), "SEED %d · 4 UNIQUE RIVALS" % int(scenario.seed), Color("aeb8cf"), 8, HORIZONTAL_ALIGNMENT_LEFT)

	for slot_index in plan.slots.size():
		var faction := ConceptService.get_election_campaign().faction(plan.faction_id_at(slot_index))
		var kind := plan.presentation_kind_at(slot_index)
		var identity_id := plan.presentation_id_at(slot_index)
		var slot_accent := faction.accent_color if faction != null else Color("758097")
		var is_guard := kind == StageRuntimeBossPlan.PRESENTATION_GUARD
		var card_x := 292.0 + slot_index * 239.0
		_add_panel(Rect2(card_x, row_y + 7, 228, 89), Color("101726e8"), slot_accent, 3 if is_guard else 1)
		var texture := _presentation_texture(kind, identity_id)
		var art := TextureRect.new()
		art.position = Vector2(card_x + 5, row_y + 13)
		art.size = Vector2(72, 72)
		art.texture = texture
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(art)
		var role := "FINAL" if kind == StageRuntimeBossPlan.PRESENTATION_CANDIDATE else ("GUARD" if is_guard else "RETAINER")
		_add_label(Rect2(card_x + 81, row_y + 13, 139, 17), "%s · %s" % [_time_label(plan.time_at(slot_index)), role], slot_accent.lightened(0.2), 8, HORIZONTAL_ALIGNMENT_LEFT)
		_add_label(Rect2(card_x + 81, row_y + 33, 139, 30), _presentation_name(kind, identity_id, faction), Color("f7f2e7"), 9, HORIZONTAL_ALIGNMENT_LEFT)
		_add_label(Rect2(card_x + 81, row_y + 66, 139, 15), "DIRECT LEFT · NO FLIP", Color("aeb8cf"), 7, HORIZONTAL_ALIGNMENT_LEFT)

func _presentation_texture(kind: StringName, identity_id: StringName) -> Texture2D:
	var category := &"candidate_intrusion_sd" if kind == StageRuntimeBossPlan.PRESENTATION_CANDIDATE else (&"guard_intrusion_sd" if kind == StageRuntimeBossPlan.PRESENTATION_GUARD else &"retainer_intrusion_sd")
	return ConceptService.optional_content_texture(category, identity_id)

func _presentation_name(kind: StringName, identity_id: StringName, faction: ElectionFactionData) -> String:
	var campaign := ConceptService.get_election_campaign()
	if kind == StageRuntimeBossPlan.PRESENTATION_CANDIDATE:
		var candidate := campaign.candidate(identity_id)
		return candidate.short_name if candidate != null else String(identity_id)
	if kind == StageRuntimeBossPlan.PRESENTATION_RETAINER:
		var retainer := campaign.retainer(identity_id)
		return retainer.short_name if retainer != null else String(identity_id)
	var faction_candidate := campaign.candidate(faction.candidate_id) if faction != null else null
	var core := DataRegistry.get_core(faction_candidate.core_id) if faction_candidate != null else null
	var tower := DataRegistry.get_tower(core.unique_tower_id) if core != null else null
	return tower.display_name if tower != null else String(identity_id)

func _time_label(seconds: float) -> String:
	return "%02d:%02d" % [int(seconds) / 60, int(seconds) % 60]

func _add_panel(rect: Rect2, fill: Color, border: Color, border_width: int) -> void:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(7)
	panel.add_theme_stylebox_override(&"panel", style)
	add_child(panel)

func _add_label(rect: Rect2, value: String, color: Color, font_size: int, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.text = value
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	add_child(label)

func _capture_and_quit(output_path: String, output_size: Vector2i) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tests/visual_reviews"))
	var image := get_viewport().get_texture().get_image()
	if image.get_size() != output_size:
		var fitted := image.duplicate() as Image
		fitted.convert(Image.FORMAT_RGBA8)
		var scale := minf(float(output_size.x) / fitted.get_width(), float(output_size.y) / fitted.get_height())
		var fitted_size := Vector2i(roundi(fitted.get_width() * scale), roundi(fitted.get_height() * scale))
		fitted.resize(fitted_size.x, fitted_size.y, Image.INTERPOLATE_LANCZOS)
		var framed := Image.create(output_size.x, output_size.y, false, Image.FORMAT_RGBA8)
		framed.fill(Color.BLACK)
		framed.blit_rect(fitted, Rect2i(Vector2i.ZERO, fitted_size), (output_size - fitted_size) / 2)
		image = framed
	var error := image.save_png(ProjectSettings.globalize_path(output_path))
	if error == OK:
		print("OFFICIAL INTRUSION M4 REVIEW CAPTURE PASS: %s · %dx%d" % [output_path, image.get_width(), image.get_height()])
	else:
		push_error("official intrusion M4 review capture failed with error %d" % error)
	get_tree().quit(error)
