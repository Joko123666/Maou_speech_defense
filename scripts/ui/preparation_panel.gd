class_name PreparationPanel
extends Control

signal guard_confirmed(formation: TowerFormationData, anchor: Vector2i, vertical_flipped: bool)
signal formation_confirmed(formation: TowerFormationData, anchor: Vector2i, vertical_flipped: bool)
signal placement_abandoned(formation: TowerFormationData)

const MODAL_SHELL_SCENE := preload("res://scenes/ui/components/modal_shell.tscn")
const EMPTY_CELL_FILL := Color("e4d2b5")
const EMPTY_CELL_BORDER := Color("6f6079")
const UNAVAILABLE_CELL_FILL := Color("c8bba8")
const UNAVAILABLE_CELL_BORDER := Color("8f8296")

var loadout: LoadoutManager
var formation: TowerFormationData
var modal_shell: UiModalShell
var selected_anchor := Vector2i(-1, -1)
var vertical_flipped: bool = false
var cell_buttons: Array[Button] = []
var title_label: Label
var description_label: Label
var status_label: Label
var hint_label: Label
var grid: GridContainer
var flip_button: Button
var confirm_button: Button
var abandon_button: Button
var abandon_dialog: ConfirmationDialog
var guard_mode: bool = true
var required_anchor := Vector2i(-1, -1)
var guard_primary_color: Color = UiTokens.ACCENT_GOLD
var guard_secondary_color: Color = UiTokens.INK_ROYAL
var guard_marker_label: String = "친위대"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	hide()

func setup(target_loadout: LoadoutManager) -> void:
	loadout = target_loadout

func show_guard(candidate_name: String, guard_formation: TowerFormationData) -> void:
	guard_mode = true
	required_anchor = Vector2i(-1, -1)
	formation = guard_formation
	vertical_flipped = false
	selected_anchor = Vector2i(-1, -1)
	var campaign := ConceptService.get_election_campaign()
	var candidate := campaign.candidate(guard_formation.candidate_id) if campaign != null and guard_formation != null else null
	var faction := campaign.faction(candidate.faction_id) if campaign != null and candidate != null else null
	guard_primary_color = faction.primary_color if faction != null else UiTokens.ACCENT_GOLD
	guard_secondary_color = faction.secondary_color if faction != null else UiTokens.INK_ROYAL
	guard_marker_label = faction.marker_display_name() if faction != null else "친위대"
	title_label.text = "친위대 배치 · %s · %s" % [candidate_name, guard_marker_label]
	hint_label.text = "추천 위치가 선택되어 있습니다. 다른 빈 칸을 누르면 배치를 바꿀 수 있습니다."
	confirm_button.text = "추천 배치로 연설 시작"
	description_label.text = "%s\n%s\n문양 %s · %d칸 · 기초 편성점수 %d" % [
		formation.display_name,
		formation.description,
		guard_marker_label,
		formation.cells.size(),
		formation.formation_score,
	]
	flip_button.visible = formation.can_vertical_flip and formation.get_bounds().size.y > 1
	abandon_button.visible = false
	var placements := loadout.get_valid_board_placements(formation)
	if not placements.is_empty():
		var recommended := placements[placements.size() / 2] as Dictionary
		selected_anchor = recommended.anchor as Vector2i
		vertical_flipped = bool(recommended.vertical_flipped)
	_refresh_grid()
	_open_panel()

func show_formation(placement_formation: TowerFormationData) -> void:
	guard_mode = false
	required_anchor = Vector2i(-1, -1)
	formation = placement_formation
	vertical_flipped = false
	selected_anchor = Vector2i(-1, -1)
	title_label.text = "일반 병력 편대 배치"
	hint_label.text = "빈 칸을 눌러 이동 · 밝은 병력색은 미리보기, 진한 병력색은 이미 배치된 병력입니다."
	confirm_button.text = "편대 배치 확정"
	description_label.text = "%s\n%s\n%d칸 · 기초 편성점수 %d" % [
		formation.display_name,
		formation.description,
		formation.cells.size(),
		formation.formation_score,
	]
	flip_button.visible = formation.can_vertical_flip and formation.get_bounds().size.y > 1
	abandon_button.visible = true
	var placements := loadout.get_valid_board_placements(formation)
	if not placements.is_empty():
		var recommended := placements[placements.size() / 2] as Dictionary
		selected_anchor = recommended.anchor as Vector2i
		vertical_flipped = bool(recommended.vertical_flipped)
	_refresh_grid()
	_open_panel()

func show_required_formation(placement_formation: TowerFormationData, anchor: Vector2i) -> void:
	show_formation(placement_formation)
	required_anchor = anchor
	vertical_flipped = false
	selected_anchor = anchor if loadout.can_place_formation_block(formation, anchor, false) else Vector2i(-1, -1)
	title_label.text = "훈련 · 고블린 전열 배치"
	hint_label.text = "밝게 표시된 지정 칸을 선택하고 배치를 확정하세요."
	abandon_button.visible = false
	flip_button.visible = false
	_refresh_grid()

func tutorial_action_controls() -> Array[Control]:
	var targets: Array[Control] = []
	if is_instance_valid(confirm_button):
		targets.append(confirm_button)
	if required_anchor.x >= 0:
		var cell_index := required_anchor.y * FormationBoardState.DEFAULT_WIDTH + required_anchor.x
		if cell_index >= 0 and cell_index < cell_buttons.size():
			targets.append(cell_buttons[cell_index])
	return targets

func _build_ui() -> void:
	modal_shell = MODAL_SHELL_SCENE.instantiate() as UiModalShell
	modal_shell.name = "PreparationModalShell"
	add_child(modal_shell)
	modal_shell.configure("편대 준비", false)
	modal_shell.set_panel_minimum_size(Vector2(940.0, 620.0))
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_shell.get_body().add_child(content)
	title_label = modal_shell.title_label
	description_label = Label.new()
	description_label.add_theme_font_size_override("font_size", UiTokens.FONT_BODY)
	description_label.add_theme_color_override("font_color", UiTokens.INK_ROYAL)
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description_label)
	hint_label = Label.new()
	hint_label.text = "빈 칸을 눌러 이동 · 밝은 병력색은 현재 배치 미리보기입니다."
	hint_label.add_theme_color_override("font_color", UiTokens.INK_MUTED)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint_label)
	var center := CenterContainer.new()
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(center)
	grid = GridContainer.new()
	grid.columns = FormationBoardState.DEFAULT_WIDTH
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	center.add_child(grid)
	for y in FormationBoardState.DEFAULT_HEIGHT:
		for x in FormationBoardState.DEFAULT_WIDTH:
			var button := Button.new()
			button.custom_minimum_size = Vector2(92.0, 64.0)
			button.text = ""
			button.tooltip_text = "빈 셀"
			button.focus_mode = Control.FOCUS_ALL
			button.pressed.connect(_select_anchor.bind(Vector2i(x, y)))
			grid.add_child(button)
			cell_buttons.append(button)
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 17)
	status_label.add_theme_color_override("font_color", UiTokens.INK_ROYAL)
	content.add_child(status_label)
	var actions := HBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 16)
	modal_shell.get_footer().add_child(actions)
	flip_button = Button.new()
	flip_button.text = "상하 반전"
	flip_button.custom_minimum_size = Vector2(170.0, 48.0)
	flip_button.pressed.connect(_toggle_flip)
	UiStyleFactory.apply_button(flip_button, UiTokens.AXIS_RANGE)
	actions.add_child(flip_button)
	abandon_button = Button.new()
	abandon_button.text = "배치 포기"
	abandon_button.custom_minimum_size = Vector2(150.0, 48.0)
	abandon_button.pressed.connect(_request_abandon)
	UiStyleFactory.apply_button(abandon_button, UiTokens.DANGER, false, true)
	actions.add_child(abandon_button)
	confirm_button = Button.new()
	confirm_button.text = "배치 확정 · 연설 시작"
	confirm_button.custom_minimum_size = Vector2(320.0, 64.0)
	confirm_button.pressed.connect(_confirm)
	UiStyleFactory.apply_button(confirm_button, UiTokens.ACCENT_GOLD)
	actions.add_child(confirm_button)
	abandon_dialog = ConfirmationDialog.new()
	abandon_dialog.title = "병력 배치 포기"
	abandon_dialog.dialog_text = "이번 병력 배치를 포기하시겠습니까?\n\n선택한 편대는 획득하지 못하며 이번 레벨업 보상은 소멸합니다.\n해당 레벨 요구 경험치의 40%를 다음 레벨 진행도로 돌려받습니다."
	abandon_dialog.ok_button_text = "배치 포기"
	abandon_dialog.cancel_button_text = "계속 배치"
	abandon_dialog.confirmed.connect(_confirm_abandon)
	add_child(abandon_dialog)
	UiStyleFactory.apply_button(abandon_dialog.get_ok_button(), UiTokens.DANGER, false, true)
	UiStyleFactory.apply_button(abandon_dialog.get_cancel_button(), UiTokens.INK_ROYAL)

func _open_panel() -> void:
	show()
	var initial_focus: Control = confirm_button
	if not guard_mode and selected_anchor.x >= 0:
		initial_focus = cell_buttons[selected_anchor.y * FormationBoardState.DEFAULT_WIDTH + selected_anchor.x]
	modal_shell.show_modal(initial_focus)

func _select_anchor(anchor: Vector2i) -> void:
	if required_anchor.x >= 0 and anchor != required_anchor:
		return
	if formation == null or loadout == null or not loadout.can_place_formation_block(formation, anchor, vertical_flipped):
		return
	selected_anchor = anchor
	if guard_mode:
		confirm_button.text = "선택한 배치로 연설 시작"
	_refresh_grid()

func _toggle_flip() -> void:
	if formation == null or not formation.can_vertical_flip:
		return
	var next_flip := not vertical_flipped
	if selected_anchor.x >= 0 and loadout.can_place_formation_block(formation, selected_anchor, next_flip):
		vertical_flipped = next_flip
	else:
		var candidates := loadout.get_valid_board_placements(formation).filter(func(entry: Dictionary) -> bool: return bool(entry.vertical_flipped) == next_flip)
		if candidates.is_empty():
			return
		selected_anchor = (candidates[0] as Dictionary).anchor as Vector2i
		vertical_flipped = next_flip
	_refresh_grid()

func _refresh_grid() -> void:
	if formation == null or loadout == null:
		return
	var ghost_cells: Dictionary = {}
	var occupied_towers: Dictionary = {}
	if selected_anchor.x >= 0 and loadout.can_place_formation_block(formation, selected_anchor, vertical_flipped):
		for entry in loadout.board_state.transformed_cells(formation, selected_anchor, vertical_flipped):
			ghost_cells[entry.cell as Vector2i] = entry.tower_id
	for placement_value in loadout.board_state.placements.values():
		var placement := placement_value as Dictionary
		for entry_value in placement.get("cells", []):
			var entry := entry_value as Dictionary
			occupied_towers[entry.cell as Vector2i] = entry.tower_id as StringName
	for y in FormationBoardState.DEFAULT_HEIGHT:
		for x in FormationBoardState.DEFAULT_WIDTH:
			var cell := Vector2i(x, y)
			var button := cell_buttons[y * FormationBoardState.DEFAULT_WIDTH + x]
			button.disabled = (required_anchor.x >= 0 and cell != required_anchor) or not loadout.can_place_formation_block(formation, cell, vertical_flipped)
			button.text = ""
			if ghost_cells.has(cell):
				var tower := DataRegistry.get_tower(ghost_cells[cell] as StringName)
				button.tooltip_text = "%s · 배치 미리보기" % tower.display_name
				_apply_cell_style(
					button,
					guard_primary_color.darkened(0.18) if guard_mode else tower.color.darkened(0.18),
					guard_secondary_color.lightened(0.18) if guard_mode else tower.color.lightened(0.25)
				)
			elif occupied_towers.has(cell):
				var placed_tower := DataRegistry.get_tower(occupied_towers[cell] as StringName)
				button.tooltip_text = "%s · 배치됨" % placed_tower.display_name
				_apply_cell_style(button, placed_tower.color.darkened(0.55), placed_tower.color.darkened(0.08))
			else:
				var is_empty := loadout.board_state.is_empty(cell)
				button.tooltip_text = "빈 셀" if is_empty else "사용할 수 없는 셀"
				_apply_cell_style(
					button,
					EMPTY_CELL_FILL if is_empty else UNAVAILABLE_CELL_FILL,
					EMPTY_CELL_BORDER if is_empty else UNAVAILABLE_CELL_BORDER
				)
	confirm_button.disabled = selected_anchor.x < 0 or not loadout.can_place_formation_block(formation, selected_anchor, vertical_flipped)
	status_label.text = (
		"시작 준비 완료 · 아래 연설 시작 버튼을 누르세요."
		if guard_mode and selected_anchor.x >= 0 else
		"배치 미리보기 · %s" % ("상하 반전" if vertical_flipped else "기본 방향")
		if selected_anchor.x >= 0 else
		"배치할 수 있는 빈 공간이 없습니다."
	)

func _apply_cell_style(button: Button, fill: Color, border: Color) -> void:
	button.modulate = Color.WHITE
	var normal := _create_cell_style(fill, border, 2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_stylebox_override("hover", _create_cell_style(fill.lightened(0.08), border.lightened(0.14), 3))
	button.add_theme_stylebox_override("pressed", _create_cell_style(fill.darkened(0.08), border.lightened(0.2), 3))
	button.add_theme_stylebox_override("focus", _create_cell_style(Color(0, 0, 0, 0), border.lightened(0.24), 3))

func _create_cell_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	return style

func _confirm() -> void:
	if confirm_button.disabled or formation == null:
		return
	if guard_mode:
		guard_confirmed.emit(formation, selected_anchor, vertical_flipped)
	else:
		formation_confirmed.emit(formation, selected_anchor, vertical_flipped)
	modal_shell.hide_modal()
	hide()

func _request_abandon() -> void:
	if guard_mode or required_anchor.x >= 0 or formation == null:
		return
	abandon_dialog.popup_centered(Vector2i(620, 260))

func _confirm_abandon() -> void:
	if guard_mode or formation == null:
		return
	placement_abandoned.emit(formation)
	modal_shell.hide_modal()
	hide()
