class_name AudioPresentationContractTest
extends RefCounted

const DEFAULT_PROFILE_PATH := "res://data/concepts/formation_defense.tres"
const ELECTION_PROFILE_PATH := "res://data/concepts/demon_election_vertical_slice.tres"
const REQUIRED_VARIANTS := [
	&"core_skill_emerald", &"core_skill_sapphire", &"core_skill_amethyst", &"core_skill_jade", &"core_skill_obsidian",
	&"tower_rapid", &"tower_blast", &"tower_energy", &"tower_saw", &"tower_arcane",
]
const ELECTION_SKILL_VARIANTS := [
	&"candidate_skill_partason", &"candidate_skill_jiane", &"candidate_skill_kasuha", &"candidate_skill_irelai", &"candidate_skill_judaginda",
]

static func run() -> Array[String]:
	var failures: Array[String] = []
	var original_profile_path := ConceptService.active_path
	for profile_path in [DEFAULT_PROFILE_PATH, ELECTION_PROFILE_PATH]:
		if not ConceptService.load_profile(profile_path):
			failures.append("profile '%s' must load for the audio presentation audit" % profile_path)
			continue
		var streams: Dictionary = {}
		var waveform_hashes: Dictionary = {}
		for role in REQUIRED_VARIANTS:
			var stream := ConceptService.audio(role)
			_expect(stream != null and stream.get_length() >= 0.1, "audio variant '%s' must resolve a non-empty dedicated stream in %s" % [role, profile_path], failures)
			if stream != null:
				streams[stream] = true
			if stream is AudioStreamWAV:
				var wave := stream as AudioStreamWAV
				_expect(wave.mix_rate == 44100 and wave.format == AudioStreamWAV.FORMAT_QOA and not wave.stereo, "audio variant '%s' must use the approved mono 44.1kHz/QOA mobile format (rate=%d format=%d stereo=%s)" % [role, wave.mix_rate, wave.format, wave.stereo], failures)
				waveform_hashes[hash(wave.data)] = true
		_expect(streams.size() == REQUIRED_VARIANTS.size(), "all ten combat audio variants must use distinct stream resources in %s" % profile_path, failures)
		_expect(waveform_hashes.size() == REQUIRED_VARIANTS.size(), "all ten combat audio variants must contain distinct waveforms in %s" % profile_path, failures)
	for role in ELECTION_SKILL_VARIANTS:
		var stream := ConceptService.audio(role)
		_expect(stream != null and stream.get_length() >= 0.1, "election skill variant '%s' must resolve a non-empty candidate stream" % role, failures)
	_expect(AudioManager.core_skill_role(&"emerald") == &"candidate_skill_partason", "Partason must route to a candidate-named audio identity", failures)
	_expect(AudioManager.core_skill_role(&"sapphire") == &"candidate_skill_jiane", "Jiane must route to a candidate-named audio identity", failures)
	_expect(AudioManager.core_skill_role(&"amethyst") == &"candidate_skill_kasuha", "Kasuha must route to a candidate-named audio identity", failures)
	_expect(AudioManager.core_skill_role(&"jade") == &"candidate_skill_irelai", "Irelai must route to a candidate-named audio identity", failures)
	_expect(AudioManager.core_skill_role(&"obsidian") == &"candidate_skill_judaginda", "Judaginda must route to a candidate-named audio identity", failures)
	_expect(AudioManager.core_skill_role(&"unknown") == &"core_skill", "unknown core ids must retain the safe generic skill fallback", failures)
	var tower_routes := {
		&"rapid": &"tower_rapid", &"unique_single": &"tower_rapid",
		&"area": &"tower_blast", &"unique_radial": &"tower_blast",
		&"pierce": &"tower_energy", &"unique_pierce": &"tower_energy", &"chain": &"tower_energy",
		&"knockback": &"tower_saw",
		&"slow": &"tower_arcane", &"execute": &"tower_arcane", &"mark": &"tower_arcane", &"unique_random": &"tower_arcane",
	}
	for behavior in tower_routes:
		_expect(AudioManager.tower_attack_role(behavior) == tower_routes[behavior], "tower behavior '%s' must route to '%s'" % [behavior, tower_routes[behavior]], failures)
	_expect(AudioManager.tower_attack_role(&"unknown") == &"hit_light", "unknown tower behaviors must retain the safe light-impact fallback", failures)
	var restore_path := original_profile_path if not original_profile_path.is_empty() else DEFAULT_PROFILE_PATH
	if not ConceptService.load_profile(restore_path):
		failures.append("the original concept profile must be restored after the audio presentation audit")
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
