class_name RetainerProfileData
extends Resource

@export var id: StringName = &""
@export var cursor_id: StringName = &""
@export var preferred_candidate_id: StringName = &""
@export var full_name: String = ""
@export var short_name: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var retainer_boss_id: StringName = &""
@export var movement_profile_id: StringName = &"default"
@export var special_resource_type: StringName = &"none"
@export var combo_attack_type: StringName = &"none"
@export var action_profile_id: StringName = &""
@export var growth_data: RetainerGrowthData
@export var combo_profile: ComboAttackProfileData
@export var vanguard_stack_profile: VanguardStackProfileData

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("retainer id is empty")
	if cursor_id == &"": errors.append("retainer '%s' has no cursor id" % id)
	if preferred_candidate_id == &"": errors.append("retainer '%s' has no preferred candidate id" % id)
	if full_name.is_empty(): errors.append("retainer '%s' has no full name" % id)
	if short_name.is_empty(): errors.append("retainer '%s' has no short name" % id)
	if retainer_boss_id == &"": errors.append("retainer '%s' has no boss id" % id)
	if movement_profile_id == &"": errors.append("retainer '%s' has no movement profile id" % id)
	if action_profile_id == &"": errors.append("retainer '%s' has no action profile id" % id)
	if growth_data == null:
		errors.append("retainer '%s' has no growth data" % id)
	else:
		errors.append_array(growth_data.get_validation_errors())
		if growth_data.retainer_id != id:
			errors.append("retainer '%s' growth owner is '%s'" % [id, growth_data.retainer_id])
		if growth_data.legacy_cursor_id != cursor_id:
			errors.append("retainer '%s' growth cursor is '%s'" % [id, growth_data.legacy_cursor_id])
	if combo_attack_type == &"line_charge":
		if combo_profile == null:
			errors.append("retainer '%s' has no line charge profile" % id)
		else:
			errors.append_array(combo_profile.get_validation_errors())
	if special_resource_type == &"vanguard_stack":
		if vanguard_stack_profile == null:
			errors.append("retainer '%s' has no vanguard stack profile" % id)
		else:
			errors.append_array(vanguard_stack_profile.get_validation_errors())
	return errors
