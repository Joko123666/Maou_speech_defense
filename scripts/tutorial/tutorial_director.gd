class_name TutorialDirector
extends RefCounted

signal step_changed(step_index: int, step_id: StringName, instruction: String)
signal guidance_changed(step_index: int, instruction: String)
signal practice_wave_requested(wave_index: int)
signal boss_warning_requested(seconds_remaining: float)
signal boss_requested
signal completed

enum Step {
	MOVE_RETAINER,
	PLACE_GOBLINS,
	OBSERVE_DEFENSE,
	FIXED_GROWTH,
	TUTORIAL_BOSS,
	CANDIDATE_SKILL,
	COMPLETE,
}

const LEARNING_STEP_COUNT := 6
const MOVE_DISTANCE_REQUIRED := 48.0
const CANDIDATE_PROTECTION_GOAL := "파르태손의 연설 종료까지 지키세요."
const RETAINER_ROLE_GUIDANCE := "칸다는 직접 움직여 싸우고 유세 열기를 회수합니다."
const STEP_IDS: Array[StringName] = [
	&"move_retainer", &"place_goblins", &"observe_defense",
	&"fixed_growth", &"tutorial_boss", &"candidate_skill",
]
const INSTRUCTIONS: Array[String] = [
	CANDIDATE_PROTECTION_GOAL + " " + RETAINER_ROLE_GUIDANCE + " 클릭/드래그로 이동하세요.",
	"표시된 칸에 고블린 창병 전열을 배치하세요.",
	"자동 공격과 경험치 회수를 잠시 관찰하세요.",
	"고정 성장 카드 한 장을 선택하세요.",
	"9초 실전 드릴: 일반 난입자를 막으며 칸다로 위험한 행을 지원하세요.",
	"충전된 파르태손의 필살 공약을 사용하세요.",
]

var scenario: TutorialScenarioData
var current_step: int = Step.MOVE_RETAINER
var movement_distance: float = 0.0
var observation_elapsed: float = 0.0
var boss_drill_elapsed: float = 0.0
var next_practice_wave_index: int = 0
var boss_warning_emitted: bool = false
var boss_requested_emitted: bool = false
var has_completed: bool = false

func begin(target_scenario: TutorialScenarioData) -> bool:
	scenario = target_scenario
	if scenario == null or not scenario.get_validation_errors().is_empty():
		return false
	current_step = Step.MOVE_RETAINER
	movement_distance = 0.0
	observation_elapsed = 0.0
	boss_drill_elapsed = 0.0
	next_practice_wave_index = 0
	boss_warning_emitted = false
	boss_requested_emitted = false
	has_completed = false
	_emit_step()
	return true

func advance(delta: float) -> void:
	if has_completed:
		return
	match current_step:
		Step.OBSERVE_DEFENSE:
			observation_elapsed += maxf(delta, 0.0)
			if observation_elapsed >= scenario.observation_seconds:
				_set_step(Step.FIXED_GROWTH)
		Step.TUTORIAL_BOSS:
			_advance_boss_drill(maxf(delta, 0.0))

func record_movement(distance: float) -> bool:
	if current_step != Step.MOVE_RETAINER:
		return false
	movement_distance += maxf(distance, 0.0)
	if movement_distance < MOVE_DISTANCE_REQUIRED:
		return false
	_set_step(Step.PLACE_GOBLINS)
	return true

func record_formation(formation_id: StringName, anchor: Vector2i) -> bool:
	if current_step != Step.PLACE_GOBLINS or formation_id != scenario.formation_id or anchor != scenario.required_formation_anchor:
		return false
	_set_step(Step.OBSERVE_DEFENSE)
	return true

func record_growth(category: StringName, data_id: StringName) -> bool:
	if current_step != Step.FIXED_GROWTH or category != scenario.fixed_upgrade_category or data_id != scenario.fixed_upgrade_id:
		return false
	_set_step(Step.TUTORIAL_BOSS)
	return true

func record_boss(boss_id: StringName) -> bool:
	if current_step != Step.TUTORIAL_BOSS or boss_id != scenario.tutorial_boss_id:
		return false
	_set_step(Step.CANDIDATE_SKILL)
	return true

func record_skill_cast() -> bool:
	if current_step != Step.CANDIDATE_SKILL:
		return false
	has_completed = true
	current_step = Step.COMPLETE
	completed.emit()
	return true

func is_step(step: Step) -> bool:
	return current_step == step

func snapshot() -> Dictionary:
	return {
		"step": current_step,
		"step_count": LEARNING_STEP_COUNT,
		"step_id": String(STEP_IDS[current_step]) if current_step < LEARNING_STEP_COUNT else "complete",
		"boss_drill_elapsed": boss_drill_elapsed,
		"practice_waves_requested": next_practice_wave_index,
		"boss_requested": boss_requested_emitted,
		"completed": has_completed,
	}

func _advance_boss_drill(delta: float) -> void:
	boss_drill_elapsed += delta
	while next_practice_wave_index < scenario.practice_wave_count:
		var wave_time := scenario.practice_first_wave_delay_seconds + scenario.practice_wave_interval_seconds * float(next_practice_wave_index)
		if boss_drill_elapsed + 0.0001 < wave_time:
			break
		var wave_index := next_practice_wave_index
		next_practice_wave_index += 1
		guidance_changed.emit(Step.TUTORIAL_BOSS, _practice_guidance(wave_index))
		practice_wave_requested.emit(wave_index)
	var warning_time := scenario.boss_lead_in_seconds - scenario.boss_warning_seconds
	if not boss_warning_emitted and boss_drill_elapsed + 0.0001 >= warning_time:
		boss_warning_emitted = true
		boss_warning_requested.emit(scenario.boss_warning_seconds)
	if not boss_requested_emitted and boss_drill_elapsed + 0.0001 >= scenario.boss_lead_in_seconds:
		boss_requested_emitted = true
		boss_requested.emit()

func _practice_guidance(wave_index: int) -> String:
	var prefix := "실전 %d/%d · " % [wave_index + 1, scenario.practice_wave_count]
	match wave_index % 3:
		0:
			return prefix + "전열은 자동 공격합니다. 칸다를 적이 많은 행으로 이동하세요."
		1:
			return prefix + "쓰러진 적의 유세 열기는 칸다가 가까이 가면 회수합니다."
		_:
			return prefix + "전열을 통과한 적을 칸다로 마무리하세요. 곧 우두머리가 옵니다."

func _set_step(next_step: Step) -> void:
	current_step = next_step
	_emit_step()

func _emit_step() -> void:
	if current_step >= LEARNING_STEP_COUNT:
		return
	step_changed.emit(current_step, STEP_IDS[current_step], INSTRUCTIONS[current_step])
