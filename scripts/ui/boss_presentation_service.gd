class_name BossPresentationService
extends RefCounted

func compose(boss_data: EnemyData, campaign: ElectionCampaignData = null, faction: ElectionFactionData = null, presentation_label: String = "") -> Dictionary:
	if boss_data == null:
		return {}
	var candidate := _candidate_for_boss(campaign, boss_data, faction)
	var candidate_name := presentation_label if not presentation_label.is_empty() else (candidate.short_name if candidate != null else boss_data.display_name)
	var faction_name := faction.display_name if faction != null else ConceptService.term(&"enemy")
	var accent := faction.accent_color if faction != null else boss_data.body_color
	var marker_style := faction.active_marker_style() if faction != null else &""
	var primary_color := faction.primary_color if faction != null else boss_data.body_color
	var secondary_color := faction.secondary_color if faction != null else boss_data.body_color.lightened(0.3)
	var display_name := ConceptService.ui_text(&"hud.boss_name", {
		&"boss": boss_data.display_name,
		&"candidate": candidate_name,
		&"faction": faction_name,
	}, boss_data.display_name)
	return {
		"name": display_name,
		"candidate": candidate_name,
		"faction": faction_name,
		"color": accent,
		"marker_style": marker_style,
		"primary_color": primary_color,
		"secondary_color": secondary_color,
	}

func warning_text(boss_data: EnemyData, presentation: Dictionary, spawn_y_ratio: float) -> String:
	if boss_data == null or presentation.is_empty():
		return ""
	var position_label := "%02d" % roundi(spawn_y_ratio * 99.0)
	return ConceptService.ui_text(&"hud.boss_warning", {
		&"position": position_label,
		&"boss": boss_data.display_name,
		&"candidate": presentation.get("candidate", boss_data.display_name),
		&"faction": presentation.get("faction", ConceptService.term(&"enemy")),
	}, "30초 후 Y%s 지점 %s 출현 · %s" % [position_label, ConceptService.term(&"boss"), boss_data.display_name])

func _candidate_for_boss(campaign: ElectionCampaignData, boss_data: EnemyData, faction: ElectionFactionData) -> CandidateProfileData:
	if campaign == null:
		return null
	return campaign.candidate(faction.candidate_id) if faction != null else campaign.candidate_for_boss(boss_data.id)
