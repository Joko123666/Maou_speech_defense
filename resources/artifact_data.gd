class_name ArtifactData
extends Resource

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon_key: StringName = &"global"
@export var color: Color = Color("ffe16b")
@export var effects: Array[ArtifactEffectData] = []
@export var required_role_tags: Array[StringName] = []
@export var required_status_ids: Array[StringName] = []

func has_trade_off() -> bool:
	return effects.any(func(effect: ArtifactEffectData) -> bool: return effect != null and effect.value < 0.0)

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"": errors.append("artifact id is empty")
	if display_name.strip_edges().is_empty(): errors.append("artifact '%s' has no display name" % id)
	if description.strip_edges().is_empty(): errors.append("artifact '%s' has no description" % id)
	if effects.is_empty(): errors.append("artifact '%s' has no effects" % id)
	for effect in effects:
		if effect == null:
			errors.append("artifact '%s' contains a null effect" % id)
		else:
			errors.append_array(effect.get_validation_errors(id))
	for role_tag in required_role_tags:
		if role_tag == &"": errors.append("artifact '%s' has an empty required role" % id)
	for status_id in required_status_ids:
		if status_id not in CommonStatusCatalog.STATUS_IDS: errors.append("artifact '%s' has invalid required status '%s'" % [id, status_id])
	return errors
