class_name CombatResultOverlay
extends UiModalShell

@onready var subtitle_label: Label = %ResultSubtitle
@onready var progress_label: Label = %ResultProgressLabel
@onready var timeline: ResultProgressTimeline = %ResultTimeline
@onready var funds_earned_label: Label = %FundsEarnedLabel
@onready var funds_total_label: Label = %FundsTotalLabel
@onready var reward_breakdown_label: Label = %RewardBreakdownLabel
@onready var candidate_support_section: PanelContainer = %CandidateSupportSection
@onready var candidate_support_label: Label = %CandidateSupportLabel
@onready var candidate_support_bar: ProgressBar = %CandidateSupportBar
@onready var candidate_election_label: Label = %CandidateElectionLabel
@onready var governance_result_label: Label = %GovernanceResultLabel
@onready var detail_label: Label = %ResultDetail
@onready var formation_board_preview: FormationBoardPreview = %FormationBoardPreview
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton

var modal_shell: UiModalShell
var backdrop: ColorRect

func _ready() -> void:
	super._ready()
	modal_shell = self
	backdrop = dimmer
	configure("원정 결과", false)
	set_panel_minimum_size(Vector2(1160.0, 650.0))
	var content := get_body().get_node("Content") as VBoxContainer
	var buttons := restart_button.get_parent() as HBoxContainer
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	menu_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_result_styles(content)
	_install_result_hierarchy(content)
	hide_overlay()

func _install_result_hierarchy(content: VBoxContainer) -> void:
	var stages := [
		{"target": content.get_node("ProgressSection"), "text": "01  진행 · 전투 경로"},
		{"target": content.get_node("CurrencyRow"), "text": "02  보상 · 정산 내역"},
		{"target": content.get_node("CandidateSupportSection"), "text": "03  지지도 · 통치 반응"},
		{"target": content.get_node("SummarySection"), "text": "04  빌드 · 전투 기여"},
	]
	for stage in stages:
		var label := Label.new()
		label.text = String(stage.text)
		label.add_theme_font_size_override(&"font_size", UiTokens.FONT_CAPTION)
		label.add_theme_color_override(&"font_color", UiTokens.ACCENT_GOLD_TEXT)
		content.add_child(label)
		content.move_child(label, (stage.target as Control).get_index())

func _apply_result_styles(content: VBoxContainer) -> void:
	for label in content.find_children("*", "Label", true, false):
		(label as Label).add_theme_color_override(&"font_color", UiTokens.INK_ROYAL)
	for section in content.find_children("*", "PanelContainer", true, false):
		(section as PanelContainer).add_theme_stylebox_override(&"panel", UiStyleFactory.panel(UiTokens.SURFACE_PARCHMENT_MUTED, UiTokens.INK_MUTED, UiTokens.RADIUS_SMALL, 1, float(UiTokens.SPACE_3)))
	UiStyleFactory.apply_button(restart_button, UiTokens.ACCENT_GOLD, true)
	UiStyleFactory.apply_button(menu_button, UiTokens.INK_ROYAL)

func show_overlay() -> void:
	show_modal(restart_button)
	backdrop.visible = true
	panel.visible = true

func hide_overlay() -> void:
	hide_modal()
	backdrop.visible = false
	panel.visible = false
