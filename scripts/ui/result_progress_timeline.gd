class_name ResultProgressTimeline
extends Control

const TRACK_COLOR := Color("1d3540")
const FILL_COLOR := Color("62dfaa")
const MISSED_COLOR := Color("ef6b78")
const LOCKED_COLOR := Color("53636a")

var duration_seconds: float = 600.0
var target_ratio: float = 0.0
var display_ratio: float = 0.0
var bosses: Array[Dictionary] = []
var progress_tween: Tween

func _ready() -> void:
	custom_minimum_size = Vector2(0.0, 112.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(result: Dictionary, animate: bool = true) -> void:
	duration_seconds = maxf(float(result.get("stage_duration_seconds", 600.0)), 1.0)
	var elapsed := clampf(float(result.get("elapsed", 0.0)), 0.0, duration_seconds)
	target_ratio = elapsed / duration_seconds
	bosses = _resolve_bosses(result)
	if progress_tween != null and progress_tween.is_valid():
		progress_tween.kill()
	display_ratio = 0.0 if animate else target_ratio
	queue_redraw()
	if animate and UiMotion.should_animate():
		progress_tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		progress_tween.tween_interval(0.16)
		progress_tween.tween_method(_set_display_ratio, 0.0, target_ratio, 1.0)

func get_boss_count() -> int:
	return bosses.size()

func get_defeated_boss_count() -> int:
	return bosses.filter(func(boss: Dictionary) -> bool: return bool(boss.get("defeated", false))).size()

func _set_display_ratio(value: float) -> void:
	display_ratio = value
	queue_redraw()

func _resolve_bosses(result: Dictionary) -> Array[Dictionary]:
	var resolved: Array[Dictionary] = []
	var defeated_ids: Array = result.get("boss_kill_ids", [])
	var timeline_value: Variant = result.get("boss_timeline", [])
	if timeline_value is Array and not timeline_value.is_empty():
		for entry_value in timeline_value:
			if entry_value is not Dictionary:
				continue
			var entry: Dictionary = entry_value.duplicate()
			entry["defeated"] = bool(entry.get("defeated", String(entry.get("id", "")) in defeated_ids))
			resolved.append(entry)
		return resolved
	var plan_value: Variant = result.get("boss_plan", {})
	if StageRuntimeBossPlan.is_valid_snapshot(plan_value):
		for slot_value in (plan_value as Dictionary).get("slots", []):
			var slot := slot_value as Dictionary
			var boss := DataRegistry.find_enemy(StringName(slot.get("boss_id", "")))
			if boss == null:
				continue
			var campaign := ConceptService.get_election_campaign()
			var faction := campaign.faction(StringName(slot.get("faction_id", ""))) if campaign != null else null
			var identity := _snapshot_campaign_identity(
				campaign,
				faction,
				StringName(slot.get("presentation_kind", "")),
				StringName(slot.get("presentation_id", ""))
			)
			var identity_texture := identity.get("texture") as Texture2D
			resolved.append({
				"id": String(boss.id),
				"faction_id": String(slot.get("faction_id", "")),
				"presentation_kind": String(slot.get("presentation_kind", "")),
				"presentation_id": String(slot.get("presentation_id", "")),
				"display_name": String(identity.get("display_name", boss.display_name)),
				"time": float(slot.get("time", 0.0)),
				"texture": identity_texture if identity_texture != null else boss.texture,
				"color": faction.primary_color if faction != null else boss.body_color,
				"emblem_id": String(faction.emblem_id) if faction != null else "",
				"defeated": String(boss.id) in defeated_ids or boss.id in defeated_ids,
			})
		if not resolved.is_empty():
			return resolved

	var defeated_count := maxi(int(result.get("boss_kills", 0)), 0)
	var stage := ConceptService.get_default_stage()
	var fallback_plan := CampaignStageResolver.build_fixed_plan(stage, DataRegistry.bosses) if stage != null else null
	if fallback_plan == null:
		return resolved
	for index in fallback_plan.slots.size():
		var boss := DataRegistry.find_enemy(fallback_plan.boss_id_at(index))
		if boss == null:
			continue
		var fallback_time := fallback_plan.time_at(index)
		resolved.append({
			"id": String(boss.id),
			"display_name": boss.display_name,
			"time": fallback_time,
			"texture": boss.texture,
			"color": boss.body_color,
			"defeated": String(boss.id) in defeated_ids if not defeated_ids.is_empty() else index < defeated_count,
		})
	return resolved

func _snapshot_campaign_identity(
	campaign: ElectionCampaignData,
	faction: ElectionFactionData,
	presentation_kind: StringName,
	presentation_id: StringName
) -> Dictionary:
	if campaign == null:
		return {}
	match presentation_kind:
		StageRuntimeBossPlan.PRESENTATION_CANDIDATE:
			var candidate := campaign.candidate(presentation_id)
			if candidate != null:
				return {"display_name": candidate.full_name, "texture": ConceptService.optional_content_texture(&"candidates", candidate.id)}
		StageRuntimeBossPlan.PRESENTATION_RETAINER:
			var retainer := campaign.retainer(presentation_id)
			if retainer != null:
				return {"display_name": retainer.full_name, "texture": ConceptService.optional_content_texture(&"retainers", retainer.id)}
		StageRuntimeBossPlan.PRESENTATION_GUARD:
			var faction_candidate := campaign.candidate(faction.candidate_id) if faction != null else null
			var core := DataRegistry.get_core(faction_candidate.core_id) if faction_candidate != null else null
			var tower := DataRegistry.get_tower(core.unique_tower_id) if core != null else null
			if tower != null:
				var guard_texture := ConceptService.optional_content_texture(&"guard_intrusion_sd", presentation_id)
				return {"display_name": tower.display_name, "texture": guard_texture if guard_texture != null else tower.texture}
	# Revision-0 campaign snapshots only carried the faction, so preserve their
	# former conservative candidate portrait fallback instead of guessing a retainer.
	var legacy_candidate := campaign.candidate(faction.candidate_id) if faction != null else null
	if legacy_candidate != null:
		return {"display_name": legacy_candidate.full_name, "texture": ConceptService.optional_content_texture(&"candidates", legacy_candidate.id)}
	return {}

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var left := 42.0
	var right := maxf(size.x - 42.0, left + 1.0)
	var track_y := 49.0
	var track_width := right - left
	draw_line(Vector2(left, track_y), Vector2(right, track_y), TRACK_COLOR, 12.0, true)
	draw_line(Vector2(left, track_y), Vector2(left + track_width * display_ratio, track_y), FILL_COLOR, 12.0, true)
	draw_circle(Vector2(left, track_y), 7.0, FILL_COLOR)

	for boss in bosses:
		var time := clampf(float(boss.get("time", 0.0)), 0.0, duration_seconds)
		var ratio := time / duration_seconds
		var center := Vector2(left + track_width * ratio, track_y)
		var reached := display_ratio + 0.002 >= ratio
		var defeated := bool(boss.get("defeated", false))
		var faction := _faction_for_entry(boss)
		var boss_color: Color = faction.primary_color if faction != null else boss.get("color", Color("d88a63"))
		var ring_color := (FILL_COLOR if defeated else MISSED_COLOR) if reached else LOCKED_COLOR
		draw_circle(center, 27.0, Color("07141b"))
		draw_circle(center, 25.0, Color(boss_color, 0.22 if reached else 0.08))
		var texture: Texture2D = boss.get("texture") as Texture2D
		if texture != null:
			var icon_rect := Rect2(center - Vector2(20.0, 20.0), Vector2(40.0, 40.0))
			draw_texture_rect(texture, icon_rect, false, Color.WHITE if reached else Color(0.35, 0.4, 0.42, 0.7))
		var emblem_id := StringName(boss.get("emblem_id", faction.emblem_id if faction != null else &""))
		var emblem := ConceptService.optional_content_texture(&"emblems", emblem_id) if emblem_id != &"" else null
		if emblem != null:
			var emblem_center := center + Vector2(-19.0, 18.0)
			draw_circle(emblem_center, 9.5, Color("07141b"))
			draw_texture_rect(emblem, Rect2(emblem_center - Vector2.ONE * 7.0, Vector2.ONE * 14.0), false, Color.WHITE if reached else Color(0.45, 0.45, 0.48, 0.72))
		draw_arc(center, 25.0, 0.0, TAU, 32, ring_color, 3.0, true)

		if reached:
			var badge_center := center + Vector2(19.0, -18.0)
			draw_circle(badge_center, 9.0, ring_color)
			if defeated:
				draw_polyline(PackedVector2Array([badge_center + Vector2(-4.0, 0.0), badge_center + Vector2(-1.0, 3.0), badge_center + Vector2(5.0, -4.0)]), Color("07141b"), 2.4, true)
			else:
				draw_line(badge_center + Vector2(-3.5, -3.5), badge_center + Vector2(3.5, 3.5), Color("07141b"), 2.2, true)
				draw_line(badge_center + Vector2(3.5, -3.5), badge_center + Vector2(-3.5, 3.5), Color("07141b"), 2.2, true)

		var name := String(boss.get("display_name", "공식 난입" if ConceptService.get_election_campaign() != null else "보스"))
		var name_width := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13).x
		draw_string(font, Vector2(clampf(center.x - name_width * 0.5, 0.0, size.x - name_width), 15.0), name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 13, ring_color)
		var seconds := floori(time)
		var time_text := "%02d:%02d" % [seconds / 60, seconds % 60]
		var status_text := "격파" if defeated else ("미격파" if reached else "미도달")
		var footer := "%s  %s" % [time_text, status_text]
		var footer_width := font.get_string_size(footer, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12).x
		draw_string(font, Vector2(clampf(center.x - footer_width * 0.5, 0.0, size.x - footer_width), 92.0), footer, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(ring_color, 0.92))

func _faction_for_entry(entry: Dictionary) -> ElectionFactionData:
	var campaign := ConceptService.get_election_campaign()
	if campaign == null:
		return null
	var faction_id := StringName(entry.get("faction_id", ""))
	return campaign.faction(faction_id) if faction_id != &"" else null
