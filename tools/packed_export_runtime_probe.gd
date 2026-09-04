extends SceneTree

const MAIN_MENU_PATH := "res://scenes/main/main_menu.tscn"
const EXPECTED_CONCEPT_ID := &"demon_election_vertical_slice"
const EXPECTED_CAMPAIGN_CHOICES := 5

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var concept_service := root.get_node_or_null("ConceptService")
	var save_manager := root.get_node_or_null("SaveManager")
	var progression_service := root.get_node_or_null("MetaProgressionService")
	if concept_service == null or save_manager == null or progression_service == null:
		_fail("required autoloads are missing")
		return
	var concept: Resource = concept_service.get("active") as Resource
	if concept == null or StringName(concept.get("id")) != EXPECTED_CONCEPT_ID:
		_fail("exported concept profile did not load: %s" % concept_service.call("get_load_error_summary"))
		return

	save_manager.set("tutorial_completed", true)
	progression_service.call("set_testing_content_lock_bypass", true)
	var scene_error := change_scene_to_file(MAIN_MENU_PATH)
	if scene_error != OK:
		_fail("main menu scene change failed with error %d" % scene_error)
		return
	await process_frame
	await process_frame
	var menu := current_scene
	if menu == null:
		_fail("main menu did not become the current scene")
		return
	menu.call("_enter_main_hub")
	menu.call("show_page", 1, false)
	await process_frame
	await process_frame

	var campaign_section := menu.get_node("%CampaignChoiceSection") as Control
	var core_option := menu.get_node("%CoreOption") as Control
	var cursor_option := menu.get_node("%CursorOption") as Control
	var candidate_list := menu.get_node("%CandidateChoiceList") as Control
	var retainer_list := menu.get_node("%RetainerChoiceList") as Control
	var page_title := menu.get_node("SafeArea/Shell/Pages/GameSetupPage/Center/Panel/Content/PageTitle") as Label
	if not campaign_section.visible or core_option.visible or cursor_option.visible or page_title.text.contains("방어 프로토콜"):
		_fail("exported setup UI fell back to the legacy protocol selector: campaign=%s core=%s cursor=%s title=%s" % [campaign_section.visible, core_option.visible, cursor_option.visible, page_title.text])
		return
	if candidate_list.get_child_count() != EXPECTED_CAMPAIGN_CHOICES or retainer_list.get_child_count() != EXPECTED_CAMPAIGN_CHOICES:
		_fail("exported campaign choices are incomplete: candidate=%d retainer=%d" % [candidate_list.get_child_count(), retainer_list.get_child_count()])
		return
	for child in candidate_list.get_children():
		if child is Button and (child as Button).icon == null:
			_fail("an exported candidate portrait is missing")
			return

	menu.call("_start_game")
	for _frame in range(12):
		await process_frame
	if current_scene == null or current_scene.name != "Game":
		_fail("10-minute defense did not remain in the Game scene")
		return
	print("PACKED EXPORT RUNTIME PASS")
	call_deferred("_finish", 0)

func _finish(exit_code: int) -> void:
	unload_current_scene()
	await process_frame
	await process_frame
	quit(exit_code)

func _fail(message: String) -> void:
	print("PACKED EXPORT RUNTIME FAIL: %s" % message)
	call_deferred("_finish", 1)
