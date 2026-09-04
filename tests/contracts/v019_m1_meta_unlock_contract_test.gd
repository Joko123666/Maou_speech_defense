class_name V019M1MetaUnlockContractTest
extends RefCounted

const STAGE_ID := "standard_20m"

static func run() -> Array[String]:
	var failures: Array[String] = []
	var save_backup := SaveManager._build_save_data()
	var bypass_backup := MetaProgressionService.testing_content_lock_bypass
	var campaign := ConceptService.get_election_campaign()
	_expect(campaign != null and campaign.candidates.size() == 5 and campaign.retainers.size() == 5, "M1 sequential unlocks require the authoritative five-entry campaign arrays", failures)
	if campaign == null:
		SaveManager._apply_save_data(save_backup)
		MetaProgressionService.set_testing_content_lock_bypass(bypass_backup)
		return failures

	var fresh_v11 := SaveManager._normalize_save_data({
		"meta_progression_version": 11,
		"best_time": 0.0,
		"best_level": 1,
		"total_runs": 0,
		"unlocked_ids": ["emerald", "iron"],
		"legacy_full_unlock": false,
	})
	SaveManager._apply_save_data(fresh_v11)
	MetaProgressionService.set_testing_content_lock_bypass(false)
	_expect(int(fresh_v11.meta_progression_version) == 14 and int(fresh_v11.unlock_sequence_revision) == SaveManager.META_UNLOCK_SEQUENCE_REVISION, "v11 saves must migrate through the v12 unlock sequence into the current v14 schema", failures)
	_expect(SaveManager.candidate_first_clear_ids.is_empty() and SaveManager.retainer_first_clear_ids.is_empty(), "a fresh migrated save must retain its unclaimed first-clear rewards", failures)
	_expect(
		MetaProgressionService.is_core_unlocked(&"emerald") and not MetaProgressionService.is_core_unlocked(&"sapphire")
		and MetaProgressionService.is_cursor_unlocked(&"iron") and not MetaProgressionService.is_cursor_unlocked(&"silver"),
		"fresh progression must expose only Partason and Kanda",
		failures
	)

	_expect(_settle("m1-first", "partason", "kanda", 0), "the first standard victory must settle", failures)
	_expect("sapphire" in SaveManager.unlocked_ids and "silver" in SaveManager.unlocked_ids, "one victory must independently unlock the next candidate and retainer", failures)
	_expect(SaveManager.candidate_first_clear_ids == ["partason"] and SaveManager.retainer_first_clear_ids == ["kanda"], "the first winning combination must be recorded once per identity", failures)
	_expect(SaveManager.get_highest_challenge(&"standard_20m") == 0 and SaveManager.get_max_selectable_challenge(&"standard_20m") == 1, "the first clear must unlock only Challenge 1 above the cleared standard tier", failures)

	_expect(_settle("m1-repeat", "partason", "kanda", 0), "a repeat victory with a new run id must still settle", failures)
	_expect("amethyst" not in SaveManager.unlocked_ids and "gold" not in SaveManager.unlocked_ids, "re-clearing the same combination must not grant duplicate chain progress", failures)

	_expect(_settle("m1-candidate-cross", "jiane", "kanda", 0), "a cross-combination candidate victory must settle", failures)
	_expect("amethyst" in SaveManager.unlocked_ids and "gold" not in SaveManager.unlocked_ids, "candidate and retainer first clears must progress independently", failures)
	_expect(_settle("m1-retainer-cross", "jiane", "given", 0), "a cross-combination retainer victory must settle", failures)
	_expect("gold" in SaveManager.unlocked_ids, "the newly selected retainer must unlock its own successor without another candidate reward", failures)

	SaveManager.selected_challenge_by_stage[STAGE_ID] = 10
	_expect(SaveManager.get_selected_challenge(&"standard_20m") == 1, "saved challenge selection must clamp to the next sequential tier", failures)
	_expect(_settle("m1-no-skip", "partason", "kanda", 2), "an out-of-sequence challenge result fixture must settle safely", failures)
	_expect(SaveManager.get_highest_challenge(&"standard_20m") == 1 and SaveManager.get_max_selectable_challenge(&"standard_20m") == 2, "challenge progress must cap an attempted skip and expose only the following tier", failures)

	var recorded_v11 := SaveManager._normalize_save_data({
		"meta_progression_version": 11,
		"best_time": 100.0,
		"best_level": 5,
		"total_runs": 2,
		"unlocked_ids": ["emerald", "iron"],
		"candidate_clear_records": {"partason": {"victories": 1}},
		"legacy_full_unlock": false,
	})
	_expect("partason" in recorded_v11.candidate_first_clear_ids and "sapphire" in recorded_v11.unlocked_ids, "v11 candidate victories must conservatively preserve their earned successor unlock", failures)
	var successor_v11 := SaveManager._normalize_save_data({
		"meta_progression_version": 11,
		"best_time": 100.0,
		"best_level": 5,
		"total_runs": 2,
		"unlocked_ids": ["emerald", "iron", "sapphire", "silver"],
		"legacy_full_unlock": false,
	})
	_expect("partason" in successor_v11.candidate_first_clear_ids and "kanda" in successor_v11.retainer_first_clear_ids, "v11 successor content must infer already-consumed predecessor rewards without inventing fresh-save clears", failures)

	SaveManager._apply_save_data(save_backup)
	MetaProgressionService.set_testing_content_lock_bypass(bypass_backup)
	return failures

static func _settle(run_id: String, candidate_id: String, retainer_id: String, challenge_level: int) -> bool:
	return SaveManager._apply_run_settlement_in_memory({
		"run_id": run_id,
		"victory": true,
		"stage_id": STAGE_ID,
		"challenge_level": challenge_level,
		"candidate_id": candidate_id,
		"retainer_id": retainer_id,
		"elapsed": 600.0,
		"stage_duration_seconds": 600.0,
		"level": 20,
	}, {
		"total_funds": 0,
		"stage_first_reward_id": "",
		"challenge_first_reward_id": "",
		"achievement_actions": {},
		"candidate_progression": {},
		"governance_progression": {},
	})

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
