class_name UiFocusFlow
extends RefCounted

static func focusable_controls(root: Node) -> Array[Control]:
	var controls: Array[Control] = []
	if root is Control and _is_focusable(root as Control):
		controls.append(root as Control)
	for child in root.find_children("*", "Control", true, false):
		var control := child as Control
		if _is_focusable(control):
			controls.append(control)
	return controls

static func link_cycle(root: Node) -> Array[Control]:
	var controls := focusable_controls(root)
	if controls.size() < 2:
		return controls
	for index in controls.size():
		var control := controls[index]
		var previous := controls[(index - 1 + controls.size()) % controls.size()]
		var next := controls[(index + 1) % controls.size()]
		control.focus_previous = control.get_path_to(previous)
		control.focus_next = control.get_path_to(next)
		control.focus_neighbor_top = control.get_path_to(previous)
		control.focus_neighbor_bottom = control.get_path_to(next)
	return controls

static func spoken_label(control: Control) -> String:
	if control is BaseButton and not (control as BaseButton).text.strip_edges().is_empty():
		return (control as BaseButton).text.strip_edges()
	if control is LineEdit and not (control as LineEdit).placeholder_text.strip_edges().is_empty():
		return (control as LineEdit).placeholder_text.strip_edges()
	return control.tooltip_text.strip_edges()

static func _is_focusable(control: Control) -> bool:
	if not control.is_visible_in_tree() or control.focus_mode == Control.FOCUS_NONE:
		return false
	if control is BaseButton and (control as BaseButton).disabled:
		return false
	return true
