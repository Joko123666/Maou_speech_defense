extends Node

const VOICE_COUNT := 16
const IMPACT_COOLDOWN_MSEC := 45
const CORE_HIT_COOLDOWN_MSEC := 90

var _muted: bool = false
var muted: bool:
	get:
		return _muted
	set(value):
		_muted = value
		if _muted:
			stop_all()

var voices: Array[AudioStreamPlayer] = []
var voice_cursor: int = 0
var last_impact_msec: int = -100000
var last_core_hit_msec: int = -100000
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	_create_voice_pool()
	muted = not SaveManager.sound_enabled

func play_ui() -> void:
	_play(ConceptService.audio(&"ui_click"), -15.0, rng.randf_range(0.96, 1.04))

func play_level_up() -> void:
	_play(ConceptService.audio(&"level_up"), -8.0)

func play_warning() -> void:
	_play(ConceptService.audio(&"boss_warning"), -6.0)

func play_boss_spawn() -> void:
	_play(ConceptService.audio(&"boss_spawn"), -5.0, rng.randf_range(0.94, 1.0))

func play_skill(core_id: StringName = &"") -> void:
	_play(ConceptService.audio(core_skill_role(core_id)), -4.0)

func core_skill_role(core_id: StringName) -> StringName:
	var campaign := ConceptService.get_election_campaign()
	if campaign != null:
		var candidate := campaign.candidate_for_core(core_id)
		if candidate != null:
			var candidate_role := StringName("candidate_skill_%s" % String(candidate.id))
			if ConceptService.audio(candidate_role) != null:
				return candidate_role
	var role := StringName("core_skill_%s" % String(core_id))
	return role if core_id != &"" and ConceptService.audio(role) != null else &"core_skill"

func tower_attack_role(behavior: StringName) -> StringName:
	match behavior:
		&"rapid", &"unique_single":
			return &"tower_rapid"
		&"area", &"unique_radial":
			return &"tower_blast"
		&"pierce", &"unique_pierce", &"chain":
			return &"tower_energy"
		&"knockback":
			return &"tower_saw"
		&"slow", &"execute", &"mark", &"unique_random":
			return &"tower_arcane"
	return &"hit_light"

func play_tower_attack(behavior: StringName) -> void:
	if not _claim_impact_slot():
		return
	var role := tower_attack_role(behavior)
	var volume_db := -21.0
	match role:
		&"tower_blast":
			volume_db = -12.0
		&"tower_energy", &"tower_saw":
			volume_db = -16.0
		&"tower_arcane":
			volume_db = -17.0
	_play(ConceptService.audio(role), volume_db, rng.randf_range(0.96, 1.04))

func play_impact(heavy: bool = false) -> void:
	if not _claim_impact_slot():
		return
	if heavy:
		_play(ConceptService.audio(&"hit_heavy"), -12.0, rng.randf_range(0.92, 1.06))
	else:
		_play(ConceptService.audio(&"hit_light"), -19.0, rng.randf_range(0.94, 1.12))

func play_core_hit(boss_hit: bool = false) -> void:
	if muted:
		return
	var now := Time.get_ticks_msec()
	if now - last_core_hit_msec < CORE_HIT_COOLDOWN_MSEC:
		return
	last_core_hit_msec = now
	_play(ConceptService.audio(&"core_hit"), -4.0 if boss_hit else -8.0, 0.88 if boss_hit else rng.randf_range(0.96, 1.04))

func play_result(victory: bool) -> void:
	_play(ConceptService.audio(&"victory" if victory else &"defeat"), -4.0)

func stop_all() -> void:
	for player in voices:
		if not is_instance_valid(player):
			continue
		player.stop()
		# 재생이 끝난 뒤에도 stream을 유지하면 짧은 헤드리스 실행 종료 시
		# AudioStreamPlayback과 원본 WAV가 다음 프레임까지 남을 수 있다.
		player.stream = null

func release_voice_pool() -> void:
	for player in voices:
		if not is_instance_valid(player):
			continue
		player.stop()
		player.stream = null
		player.free()
	voices.clear()
	voice_cursor = 0

func _exit_tree() -> void:
	release_voice_pool()

func _create_voice_pool() -> void:
	if not voices.is_empty():
		return
	for _index in VOICE_COUNT:
		var player := AudioStreamPlayer.new()
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(player)
		voices.append(player)

func _play(stream: AudioStream, volume_db: float, pitch_scale: float = 1.0) -> void:
	if muted or stream == null:
		return
	if voices.is_empty():
		_create_voice_pool()
	var player := _acquire_voice()
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	player.play()

func _acquire_voice() -> AudioStreamPlayer:
	for offset in voices.size():
		var index := (voice_cursor + offset) % voices.size()
		if not voices[index].playing:
			voice_cursor = (index + 1) % voices.size()
			return voices[index]
	var fallback := voices[voice_cursor]
	voice_cursor = (voice_cursor + 1) % voices.size()
	return fallback

func _claim_impact_slot() -> bool:
	if muted:
		return false
	var now := Time.get_ticks_msec()
	if now - last_impact_msec < IMPACT_COOLDOWN_MSEC:
		return false
	last_impact_msec = now
	return true
