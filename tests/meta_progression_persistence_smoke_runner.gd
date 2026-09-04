extends Node

const TEST_FILE_PATHS: Array[String] = [
	"user://smoke_meta_save.json",
	"user://smoke_meta_save.backup.json",
	"user://smoke_meta_save.tmp",
	"user://smoke_meta_save.previous.tmp",
	"user://smoke_meta_fault_primary.json",
	"user://smoke_meta_fault_backup",
	"user://smoke_meta_fault.tmp",
	"user://smoke_meta_fault.previous.tmp",
	"user://smoke_run_checkpoint.json",
	"user://smoke_run_checkpoint.backup.json",
	"user://smoke_run_checkpoint.tmp",
]

var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _write_json_file(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	file.close()
	return true

func _clear_test_files() -> void:
	for path in TEST_FILE_PATHS:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _run() -> void:
	await get_tree().process_frame
	AudioManager.muted = true
	_clear_test_files()
	var default_stage := ConceptService.get_default_stage()
	if default_stage == null:
		_check(false, "the active concept must expose a default stage for persistence smoke coverage")
		_finish()
		return
	var save_data := SaveManager._build_save_data()
	_check(save_data.has("sound_enabled") and save_data.has("screen_shake_enabled") and save_data.has("screen_flash_enabled"), "persistent save data must include all accessibility and sound preferences")
	_check(save_data.has("cleared_stage_ids") and save_data.has("highest_challenge_by_stage") and save_data.has("selected_challenge_by_stage"), "persistent save data must include per-stage challenge unlocks, records, and selection")
	_check(save_data.get("meta_progression_version", 0) == 14 and save_data.has("discovered_tower_use_ids") and save_data.has("defense_funds") and save_data.has("settled_run_ids") and save_data.has("candidate_support") and save_data.has("candidate_first_clear_ids") and save_data.has("retainer_first_clear_ids") and save_data.has("tutorial_completed") and save_data.has("encountered_enemy_ids") and not save_data.has("unlocked_module_ids"), "persistent save data must include the v14 tutorial, sequential-unlock, and encounter fields without the retired module inventory")
	_check(SaveManager.STARTER_TOWER_IDS == ["rapid", "pierce", "area", "rubber_golem"], "new saves must expose exactly the four v0.13 starter units")
	var migrated_save := SaveManager._normalize_save_data({"total_runs": 3, "unlocked_ids": ["emerald", "iron", "sapphire"]})
	_check(bool(migrated_save.legacy_full_unlock) and int(migrated_save.meta_progression_version) == 14 and "knockback" in migrated_save.unlocked_tower_ids and "rubber_golem" in migrated_save.unlocked_tower_ids, "legacy saves must migrate to v14 without losing existing content or the formation-defense starters")
	var migrated_v9_save := SaveManager._normalize_save_data({"meta_progression_version": 9, "unlocked_tower_ids": ["rapid", "pierce", "area", "knockback"], "legacy_full_unlock": false})
	_check(int(migrated_v9_save.meta_progression_version) == 14 and "knockback" in migrated_v9_save.unlocked_tower_ids and "rubber_golem" in migrated_v9_save.unlocked_tower_ids and "knockback" in migrated_v9_save.discovered_tower_use_ids, "v9 saves must retain KI-II and seed prior tower-use discovery during v14 migration")
	_check(not SaveManager._validate_save_dictionary({"total_runs": 3, "unlocked_ids": ["emerald", "iron", "sapphire"]}).is_empty(), "legacy save validation must preserve recognizable pre-v6 saves")
	var save_primary := "user://smoke_meta_save.json"
	var save_backup_path := "user://smoke_meta_save.backup.json"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_primary))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_backup_path))
	var durable_save := save_data.duplicate(true)
	durable_save["defense_funds"] = 777
	_check(_write_json_file(save_backup_path, durable_save), "the meta-save recovery test must write a valid backup")
	_check(_write_json_file(save_primary, {"meta_progression_version": 14}), "the meta-save recovery test must write a truncated current-version primary")
	var recovered_save := SaveManager._read_save_dictionary_from_paths(save_primary, save_backup_path)
	_check(int(recovered_save.get("defense_funds", 0)) == 777 and recovered_save.has("settled_run_ids"), "a structurally invalid v7 primary must not override a valid meta-save backup")
	var save_temp_path := "user://smoke_meta_save.tmp"
	var save_rotation_path := "user://smoke_meta_save.previous.tmp"
	var replacement_save := save_data.duplicate(true)
	replacement_save["defense_funds"] = 888
	_check(_write_json_file(save_temp_path, replacement_save), "the recovery rewrite test must write a valid temporary save")
	_check(SaveManager._replace_file_with_temp(save_primary, save_backup_path, save_temp_path, save_rotation_path), "a recovered meta save must be replaceable without sacrificing the valid backup")
	var replaced_primary := SaveManager._validate_save_dictionary(SaveManager._read_save_dictionary(save_primary))
	var preserved_backup := SaveManager._validate_save_dictionary(SaveManager._read_save_dictionary(save_backup_path))
	_check(int(replaced_primary.get("defense_funds", 0)) == 888 and int(preserved_backup.get("defense_funds", 0)) == 777, "rewriting an invalid primary after backup recovery must preserve the last valid backup until the new primary commits")
	var rotation_recovery := save_data.duplicate(true)
	rotation_recovery["defense_funds"] = 999
	_check(_write_json_file(save_rotation_path, rotation_recovery) and SaveManager._preserve_recovery_copy(save_rotation_path, save_backup_path), "a valid interrupted-rotation save must be promoted to a durable backup before rewrite")
	_check(int(SaveManager._validate_save_dictionary(SaveManager._read_save_dictionary(save_backup_path)).get("defense_funds", 0)) == 999, "rotation recovery must leave a validated backup copy on disk")
	var fault_primary := "user://smoke_meta_fault_primary.json"
	var fault_backup := "user://smoke_meta_fault_backup"
	var fault_temp := "user://smoke_meta_fault.tmp"
	var fault_rotation := "user://smoke_meta_fault.previous.tmp"
	var previous_fault_save := save_data.duplicate(true)
	previous_fault_save["defense_funds"] = 701
	var replacement_fault_save := save_data.duplicate(true)
	replacement_fault_save["defense_funds"] = 702
	_check(
		_write_json_file(fault_primary, previous_fault_save)
		and _write_json_file(fault_temp, replacement_fault_save)
		and DirAccess.make_dir_absolute(ProjectSettings.globalize_path(fault_backup)) == OK,
		"the backup-promotion fault probe must create a valid primary, replacement, and blocking backup directory"
	)
	var fault_result := SaveManager._replace_file_with_temp_result(fault_primary, fault_backup, fault_temp, fault_rotation)
	_check(
		bool(fault_result.primary_committed)
		and bool(fault_result.previous_primary_valid)
		and not bool(fault_result.backup_promoted)
		and bool(fault_result.previous_version_durable)
		and String(fault_result.recovery_path) == fault_rotation,
		"a committed primary must report degraded backup promotion separately while retaining the previous version in rotation"
	)
	_check(
		int(SaveManager._validate_save_dictionary(SaveManager._read_save_dictionary(fault_primary)).get("defense_funds", 0)) == 702
		and int(SaveManager._validate_save_dictionary(SaveManager._read_save_dictionary(fault_rotation)).get("defense_funds", 0)) == 701,
		"backup promotion failure must preserve both the committed primary and the previous valid rotation copy"
	)
	var recovery_priority_primary := "user://smoke_meta_recovery_priority.json"
	var recovery_priority_backup := "user://smoke_meta_recovery_priority.backup.json"
	var recovery_priority_rotation := "user://smoke_meta_recovery_priority.previous.tmp"
	var older_backup_save := save_data.duplicate(true)
	older_backup_save["defense_funds"] = 700
	var latest_rotation_save := save_data.duplicate(true)
	latest_rotation_save["defense_funds"] = 701
	_check(
		_write_json_file(recovery_priority_primary, {"meta_progression_version": 14})
		and _write_json_file(recovery_priority_backup, older_backup_save)
		and _write_json_file(recovery_priority_rotation, latest_rotation_save),
		"the recovery-priority probe must create an invalid primary and two valid generations"
	)
	var priority_recovery := SaveManager._resolve_save_recovery(recovery_priority_primary, recovery_priority_backup, recovery_priority_rotation)
	var priority_recovery_data := priority_recovery.get("data", {}) as Dictionary
	_check(
		priority_recovery.get("source", &"") == &"rotation"
		and int(priority_recovery_data.get("defense_funds", 0)) == 701,
		"an interrupted rotation must recover the latest previous primary before an older valid backup"
	)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fault_backup))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(recovery_priority_primary))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(recovery_priority_backup))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(recovery_priority_rotation))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_primary))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_backup_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_temp_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_rotation_path))
	var reward_data := MetaProgressionService.get_stage_reward_data(&"standard_20m")
	_check(reward_data != null and reward_data.boss_funds_by_id.has(default_stage.final_boss_id), "the standard stage must expose boss-id-based defense fund rewards for its declared final boss")
	var full_clear_result := {
		"stage_id": "standard_20m", "stage_duration_seconds": 600.0, "elapsed": 600.0,
		"victory": true, "challenge_level": 0,
		"boss_kill_ids": ["boss_5", "boss_10", "boss_15", "final_boss"],
	}
	var full_clear_reward := StageRewardCalculator.calculate(full_clear_result, reward_data, true, true)
	_check(int(full_clear_reward.total_funds) == 380 and int(full_clear_reward.boss_funds) == 125, "a repeat challenge-0 clear must award the documented 380 funds with boss rewards keyed by id")
	var challenge_clear_result := full_clear_result.duplicate(true)
	challenge_clear_result.challenge_level = 10
	var challenge_clear_reward := StageRewardCalculator.calculate(challenge_clear_result, reward_data, true, true)
	_check(int(challenge_clear_reward.total_funds) == 608, "challenge 10 must apply the documented 1.60 defense-fund multiplier")
	var first_clear_reward := StageRewardCalculator.calculate(full_clear_result, reward_data, false, true)
	_check(int(first_clear_reward.total_funds) == 530 and int(first_clear_reward.stage_first_clear_funds) == 150, "the first standard-stage clear must add its one-time 150-fund bonus")
	var half_run_reward := StageRewardCalculator.calculate({
		"stage_id": "standard_20m", "stage_duration_seconds": 600.0, "elapsed": 300.0,
		"victory": false, "challenge_level": 0, "boss_kill_ids": ["boss_5"],
	}, reward_data, true, true)
	_check(int(half_run_reward.total_funds) == 79, "a five-minute defeat with the first boss defeated must follow the nonlinear progress reward curve")
	var result_timeline_plan := CampaignStageResolver.build_fixed_plan(default_stage, DataRegistry.bosses, 1847)
	var result_timeline_data := RunResultService.new()._build_boss_timeline(result_timeline_plan, ["boss_5", "boss_10"])
	_check(result_timeline_data.size() == 4 and is_equal_approx(float(result_timeline_data[2].time), 450.0) and bool(result_timeline_data[1].defeated) and not bool(result_timeline_data[2].defeated), "run results must map all four scheduled boss times and their defeat state into the result timeline")
	var result_progress_timeline := ResultProgressTimeline.new()
	add_child(result_progress_timeline)
	result_progress_timeline.configure({"stage_duration_seconds": 600.0, "elapsed": 372.0, "boss_kills": 1, "boss_kill_ids": ["boss_5"]}, false)
	_check(is_equal_approx(result_progress_timeline.display_ratio, 0.62) and result_progress_timeline.get_boss_count() == 4 and result_progress_timeline.get_defeated_boss_count() == 1, "the result progress display must calculate clear rate from elapsed time and preserve boss defeat markers")
	result_progress_timeline.free()
	var checkpoint_backup := RunCheckpointService.checkpoint.duplicate(true)
	RunCheckpointService.checkpoint.clear()
	var checkpoint_seed := {
		"run_id": "smoke-checkpoint-run", "stage_id": "standard_20m",
		"stage_duration_seconds": 600.0, "elapsed": 0.0, "level": 1,
		"victory": false, "challenge_level": 0, "boss_kill_ids": [], "boss_plan": result_timeline_plan.to_snapshot(), "meta_metrics": {},
	}
	var legacy_checkpoint_result := checkpoint_seed.duplicate(true)
	legacy_checkpoint_result.erase("boss_plan")
	legacy_checkpoint_result["eligible_for_meta_rewards"] = true
	var legacy_checkpoint := {"version": 1, "run_id": "legacy-checkpoint-run", "confirmed": true, "result": legacy_checkpoint_result, "updated_unix": 1}
	legacy_checkpoint.result.run_id = "legacy-checkpoint-run"
	_check(not RunCheckpointService._validate_checkpoint(legacy_checkpoint).is_empty(), "valid version-1 checkpoints without a boss plan must remain recoverable after the version-2 plan snapshot migration")
	var missing_plan_checkpoint := {"version": 2, "run_id": "missing-plan-run", "confirmed": true, "result": legacy_checkpoint_result.duplicate(true), "updated_unix": 1}
	missing_plan_checkpoint.result.run_id = "missing-plan-run"
	_check(RunCheckpointService._validate_checkpoint(missing_plan_checkpoint).is_empty(), "new version-2 checkpoints must be rejected when their runtime boss plan snapshot is missing")
	_check(RunCheckpointService.begin_run(checkpoint_seed, false) and not RunCheckpointService.has_confirmed_checkpoint(), "a new run must not become reward-eligible before a boss checkpoint")
	var first_boss_checkpoint := checkpoint_seed.duplicate(true)
	first_boss_checkpoint.elapsed = 165.0
	first_boss_checkpoint.level = 5
	first_boss_checkpoint.boss_kill_ids = ["boss_5"]
	_check(RunCheckpointService.confirm_checkpoint(first_boss_checkpoint, false) and RunCheckpointService.has_confirmed_checkpoint(), "defeating a boss must confirm a recoverable run checkpoint")
	var memory_checkpoint_before_failed_write := RunCheckpointService.checkpoint.duplicate(true)
	var failed_write_candidate := memory_checkpoint_before_failed_write.duplicate(true)
	failed_write_candidate["updated_unix"] = float(failed_write_candidate.get("updated_unix", 0.0)) + 1.0
	var rejected_checkpoint_write := RunCheckpointService._commit_checkpoint(
		failed_write_candidate,
		true,
		func(_candidate: Dictionary) -> bool: return false
	)
	_check(not rejected_checkpoint_write and RunCheckpointService.checkpoint == memory_checkpoint_before_failed_write, "a failed checkpoint write must leave the previously durable in-memory checkpoint unchanged")
	var abandoned_checkpoint := RunCheckpointService.get_pending_result("abandon")
	var checkpoint_reward := StageRewardCalculator.calculate(abandoned_checkpoint, reward_data, true, true)
	_check(String(abandoned_checkpoint.run_id) == "smoke-checkpoint-run" and abandoned_checkpoint.outcome == "abandon" and int(checkpoint_reward.boss_funds) > 0 and int(checkpoint_reward.total_funds) < int(full_clear_reward.total_funds), "abandon recovery must preserve the run id and award only progress through the last defeated boss")
	var mismatched_checkpoint := RunCheckpointService.settle_pending("abandon", "another-run")
	_check(not bool(mismatched_checkpoint.get("completed", true)) and mismatched_checkpoint.get("reason", "") == "run_id_mismatch" and RunCheckpointService.has_confirmed_checkpoint(), "an active run must never settle or clear another run's pending checkpoint")
	var disk_primary := "user://smoke_run_checkpoint.json"
	var disk_backup := "user://smoke_run_checkpoint.backup.json"
	var disk_temp := "user://smoke_run_checkpoint.tmp"
	RunCheckpointService._clear_checkpoint_files(disk_primary, disk_backup, disk_temp)
	var disk_checkpoint := RunCheckpointService.checkpoint.duplicate(true)
	_check(RunCheckpointService._write_checkpoint_to_paths(disk_checkpoint, disk_primary, disk_backup, disk_temp), "a confirmed checkpoint must be written through the atomic file path")
	var newer_disk_checkpoint := disk_checkpoint.duplicate(true)
	newer_disk_checkpoint["updated_unix"] = 2
	_check(RunCheckpointService._write_checkpoint_to_paths(newer_disk_checkpoint, disk_primary, disk_backup, disk_temp), "updating a disk checkpoint must rotate the previous primary into a backup")
	var incomplete_v1_checkpoint := {"version": 1, "run_id": "truncated-run", "confirmed": true, "result": {}, "updated_unix": 3}
	_check(RunCheckpointService._write_checkpoint_to_paths(incomplete_v1_checkpoint, disk_primary, disk_backup, disk_temp), "the disk test must be able to place a structurally incomplete current-version primary after a valid backup")
	var reloaded_disk_checkpoint := RunCheckpointService._read_checkpoint_from_paths(disk_primary, disk_backup)
	RunCheckpointService.checkpoint = reloaded_disk_checkpoint
	var recovered_disk_result := RunCheckpointService.get_pending_result("recovered")
	_check(int(reloaded_disk_checkpoint.get("updated_unix", 0)) == 2 and String(recovered_disk_result.get("run_id", "")) == "smoke-checkpoint-run", "service reload must reject an incomplete v1 primary, recover its valid backup, and rebuild the pending result")
	RunCheckpointService._clear_checkpoint_files(disk_primary, disk_backup, disk_temp)
	_check(not FileAccess.file_exists(disk_primary) and not FileAccess.file_exists(disk_backup) and not FileAccess.file_exists(disk_temp), "checkpoint cleanup must remove primary, backup, and temporary files")
	RunCheckpointService.checkpoint = checkpoint_backup
	var meta_state_backup := SaveManager._build_save_data()
	var enforce_locks_backup := MetaProgressionService.config.enforce_content_locks
	var testing_bypass_backup := MetaProgressionService.testing_content_lock_bypass
	MetaProgressionService.config.enforce_content_locks = true
	MetaProgressionService.set_testing_content_lock_bypass(false)
	SaveManager.legacy_full_unlock = false
	SaveManager.unlocked_ids.assign(["emerald", "iron"])
	SaveManager.unlocked_tower_ids.assign(SaveManager.STARTER_TOWER_IDS)
	SaveManager.unlocked_feature_ids.assign(SaveManager.STARTER_FEATURE_IDS)
	SaveManager.achievement_progress.clear()
	SaveManager.completed_achievement_ids.clear()
	SaveManager.claimed_achievement_ids.clear()
	SaveManager.discovered_shop_product_ids.clear()
	SaveManager.purchased_shop_product_ids.clear()
	SaveManager.encountered_enemy_ids.clear()
	var starter_formations := MetaProgressionService.filter_unlocked_formations(DataRegistry.formations)
	_check(starter_formations.size() == 13 and starter_formations.any(func(formation: TowerFormationData) -> bool: return formation.id == &"emerald_guard") and not MetaProgressionService.is_formation_unlocked(DataRegistry.get_formation(&"cryo_net")), "lock-enabled new saves must expose 12 starter recipes plus the owned core's unique formation")
	_check(MetaProgressionService.get_codex_categories().size() == 6, "the codex must expose core, cursor, tower, formation, enemy, and terms categories")
	var starter_tower_codex := MetaProgressionService.get_codex_entries(&"tower")
	var starter_formation_codex := MetaProgressionService.get_codex_entries(&"formation")
	_check(starter_tower_codex.size() == 15 and starter_tower_codex.filter(func(entry: Dictionary) -> bool: return entry.state == &"discovered").size() == 5, "a lock-enabled new save codex must discover four starter towers and the owned core's unique tower")
	_check(starter_formation_codex.size() == 54 and starter_formation_codex.filter(func(entry: Dictionary) -> bool: return entry.state == &"discovered").size() == 13, "formation codex discovery must include 12 starter recipes and the owned core's unique recipe inside the 54-entry catalog")
	_check(starter_formation_codex.all(func(entry: Dictionary) -> bool: return (entry.stats as Array).any(func(line: String) -> bool: return line.contains("형태 ·") and line.contains("병종 ·") and line.contains("배치 난도 ·"))), "formation codex entries must expose concise shape, species-count, and placement-difficulty metadata")
	_check(MetaProgressionService.get_codex_entries(&"module").is_empty(), "the retired module category must not expose codex entries")
	SaveManager.total_runs = 1
	SaveManager.best_time = 200.0
	SaveManager.encountered_enemy_ids.assign(["civilian_slime", "goblin_raider", "boss_5"])
	var encountered_enemy_codex := MetaProgressionService.get_codex_entries(&"enemy")
	_check(encountered_enemy_codex.size() == 17 and encountered_enemy_codex.filter(func(entry: Dictionary) -> bool: return entry.state == &"discovered").size() == 3, "enemy codex discovery must follow the explicit encounter ledger rather than best survival time")
	_check(not MetaProgressionService.is_feature_unlocked(&"module_system"), "new saves must not expose the retired module feature")
	SaveManager.unlocked_tower_ids.append("slow")
	_check(MetaProgressionService.is_formation_unlocked(DataRegistry.get_formation(&"cryo_net")) and not MetaProgressionService.is_formation_unlocked(DataRegistry.get_formation(&"cascade")), "formation filtering must require every non-empty tower id in the recipe")
	_check(MetaProgressionService.get_shop_products().size() == 5 and MetaProgressionService.get_shop_products().all(func(product: ShopProductData) -> bool: return product.product_type == &"tower") and MetaProgressionService.get_achievements().size() == 11, "the active meta catalog must expose five tower products and eleven relevant achievements")
	var achievement_actions := MetaProgressionService.achievement_service.evaluate({"runs": 1.0, "boss_kills": 1.0, "run.slow_discovery": 1.0})
	_check("unlock_meta_hub" in achievement_actions.completed_ids and "tower_slow" in achievement_actions.discovered_product_ids, "result metrics must complete feature achievements and discover matching tower products together")
	SaveManager.defense_funds = 40
	SaveManager.settled_run_ids.clear()
	var settlement_runs_before := SaveManager.total_runs
	var settlement_result := {"run_id": "smoke-meta-settlement", "elapsed": 300.0, "level": 4, "victory": false, "stage_id": "standard_20m", "challenge_level": 0}
	var settlement_breakdown := {"total_funds": 79, "stage_first_reward_id": "", "challenge_first_reward_id": "", "achievement_actions": achievement_actions}
	var first_settlement := SaveManager._apply_run_settlement_in_memory(settlement_result, settlement_breakdown)
	var duplicate_settlement := SaveManager._apply_run_settlement_in_memory(settlement_result, settlement_breakdown)
	_check(first_settlement and not duplicate_settlement and SaveManager.defense_funds == 119 and SaveManager.total_runs == settlement_runs_before + 1 and "tower_slow" in SaveManager.discovered_shop_product_ids, "a run settlement id must award funds, achievements, and product discoveries exactly once")
	SaveManager.defense_funds = 300
	SaveManager.unlocked_tower_ids.assign(SaveManager.STARTER_TOWER_IDS)
	var slow_product := MetaProgressionService.get_shop_product(&"tower_slow")
	var purchased_slow := SaveManager._apply_product_purchase_in_memory(slow_product)
	var purchased_slow_twice := SaveManager._apply_product_purchase_in_memory(slow_product)
	_check(purchased_slow and not purchased_slow_twice and SaveManager.defense_funds == 80 and "slow" in SaveManager.unlocked_tower_ids and "codex_system" in SaveManager.unlocked_feature_ids, "shop purchases must atomically spend funds, grant content, unlock the codex, and reject duplicates")
	var metric_sample_meta := RunMetrics.new()
	metric_sample_meta.update_time(301.0)
	metric_sample_meta.record_tower_attack(&"rapid")
	metric_sample_meta.record_tower_hit(&"pierce", 90.0, 2, 3, 2)
	metric_sample_meta.record_damage_received(250.0, &"common_bleed", DataRegistry.bosses[0])
	metric_sample_meta.record_status_application(&"bleed", 2)
	for index in 10:
		metric_sample_meta.record_kill(index % Battlefield.LANE_COUNT, DataRegistry.enemies[0])
	var flattened_metrics := metric_sample_meta.build_meta_metrics(null)
	_check(flattened_metrics.get("tower_attacks.rapid", 0.0) == 1.0 and flattened_metrics.get("tower_multi_hit_events.pierce", 0.0) == 1.0 and flattened_metrics.get("tower_long_range_kills.pierce", 0.0) == 2.0, "tower attack, multi-hit, and long-range kill metrics must use stable flattened achievement keys")
	_check(flattened_metrics.get("boss_damage", 0.0) == 250.0 and flattened_metrics.get("status_damage.bleed", 0.0) == 250.0 and flattened_metrics.get("burst_10_kill_windows", 0.0) == 1.0, "boss, status, and rolling burst-kill metrics must be available to achievement evaluation")
	metric_sample_meta.free()
	SaveManager._apply_save_data(meta_state_backup)
	MetaProgressionService.config.enforce_content_locks = enforce_locks_backup
	MetaProgressionService.set_testing_content_lock_bypass(testing_bypass_backup)
	_check(ChallengeRules.MIN_LEVEL == 0 and ChallengeRules.MAX_LEVEL == 10 and ChallengeRules.clamp_level(99) == 10, "challenge stages must expose the requested adjustable 0-10 range")
	_check(is_equal_approx(ChallengeRules.enemy_health_multiplier(10), 2.2) and is_equal_approx(ChallengeRules.enemy_damage_multiplier(10), 1.8), "challenge 10 must apply the documented enemy health and core-damage pressure")
	_check(ChallengeRules.spawn_rate_multiplier(10) > 1.3 and is_equal_approx(ChallengeRules.experience_multiplier(10), 1.2), "challenge pressure must increase spawn density while retaining a modest experience reward")
	var cleared_stage_backup := SaveManager.cleared_stage_ids.duplicate()
	var highest_challenge_backup := SaveManager.highest_challenge_by_stage.duplicate(true)
	var selected_challenge_backup := SaveManager.selected_challenge_by_stage.duplicate(true)
	SaveManager.cleared_stage_ids.clear()
	SaveManager.highest_challenge_by_stage.clear()
	SaveManager.selected_challenge_by_stage.clear()
	var locked_challenge_menu := (load("res://scenes/main/main_menu.tscn") as PackedScene).instantiate()
	add_child(locked_challenge_menu)
	var locked_challenge_description := locked_challenge_menu.get_node("%ChallengeDescription") as Label
	_check(not (locked_challenge_menu.get_node("%ChallengeControls") as HBoxContainer).visible and locked_challenge_description.visible and locked_challenge_description.text.contains("도전 단계 잠김"), "challenge controls must stay hidden while M5 exposes the first-clear unlock reason")
	locked_challenge_menu.queue_free()
	SaveManager._apply_challenge_progress({"victory": false, "stage_id": "standard_20m", "challenge_level": 10})
	_check(not SaveManager.is_challenge_unlocked(&"standard_20m"), "a defeat must not unlock challenge selection")
	SaveManager._apply_challenge_progress({"victory": true, "stage_id": "standard_20m", "challenge_level": 0})
	_check(SaveManager.is_challenge_unlocked(&"standard_20m") and SaveManager.get_highest_challenge(&"standard_20m") == 0 and SaveManager.get_max_selectable_challenge(&"standard_20m") == 1, "the first stage clear must record challenge 0 and expose only challenge 1")
	SaveManager._apply_challenge_progress({"victory": true, "stage_id": "standard_20m", "challenge_level": 10})
	_check(SaveManager.get_highest_challenge(&"standard_20m") == 1 and SaveManager.get_max_selectable_challenge(&"standard_20m") == 2, "challenge victories must cap skipped tiers and expose only the next stage")
	SaveManager.selected_challenge_by_stage["standard_20m"] = 5
	var unlocked_challenge_menu := (load("res://scenes/main/main_menu.tscn") as PackedScene).instantiate()
	add_child(unlocked_challenge_menu)
	_check((unlocked_challenge_menu.get_node("%ChallengeControls") as HBoxContainer).visible and (unlocked_challenge_menu.get_node("%ChallengeSlider") as HSlider).editable and roundi((unlocked_challenge_menu.get_node("%ChallengeSlider") as HSlider).max_value) == 2 and roundi((unlocked_challenge_menu.get_node("%ChallengeSlider") as HSlider).value) == 2 and (unlocked_challenge_menu.get_node("%ChallengeSummary") as Label).text.contains("0~2단계"), "clearing the stage must show controls capped to the next sequential challenge")
	unlocked_challenge_menu.queue_free()
	SaveManager.cleared_stage_ids.assign(cleared_stage_backup)
	SaveManager.highest_challenge_by_stage = highest_challenge_backup
	SaveManager.selected_challenge_by_stage = selected_challenge_backup
	_clear_test_files()
	await get_tree().process_frame
	AudioManager.release_voice_pool()
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("META PERSISTENCE SMOKE PASS")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)
