class_name JudagindaGuardController
extends RefCounted

const FORMATION_ID: StringName = &"obsidian_tribunal"
const SUPPORTED_TOWER_IDS: Array[StringName] = [&"obsidian_verdict", &"obsidian_inquisitor"]

var ritual_cooldown_remaining: float = 0.0

func update(delta: float) -> void:
	ritual_cooldown_remaining = maxf(ritual_cooldown_remaining - maxf(delta, 0.0), 0.0)

func should_sudden_execute(column: TowerColumn, tower: TowerData, enemy_data: EnemyData, loadout: LoadoutManager, roll: float = -1.0) -> bool:
	if not _is_judaginda_guard(column, tower) or not bool(loadout.get_guard_modifier(&"guard_sudden_death", false)):
		return false
	var resolved_roll := RunRng.roll() if roll < 0.0 else roll
	return sudden_death_triggered(
		resolved_roll,
		enemy_data,
		float(loadout.get_guard_modifier(&"guard_sudden_death_chance", 0.04)),
		float(loadout.get_guard_modifier(&"guard_sudden_death_elite_ratio", 0.25))
	)

func resolve_execution(column: TowerColumn, row_index: int, tower: TowerData, enemy_data: EnemyData, loadout: LoadoutManager) -> Dictionary:
	var result := {"martyr_added": 0, "disabled_duration": 0.0, "skill_charge": 0.0}
	if not _is_judaginda_guard(column, tower) or enemy_data == null:
		return result
	if bool(loadout.get_guard_modifier(&"guard_martyrdom", false)):
		var stack_cap := maxi(int(loadout.get_guard_modifier(&"guard_martyr_max_stacks", 30)), 1)
		var previous := loadout.get_guard_runtime_value(&"martyr")
		var current := loadout.add_guard_runtime_value(&"martyr", 1.0, stack_cap)
		var disabled_duration := maxf(float(loadout.get_guard_modifier(&"guard_martyr_disabled_duration", 1.4)), 0.1)
		column.disable_row_for(row_index, disabled_duration)
		result.martyr_added = roundi(current - previous)
		result.disabled_duration = disabled_duration
	if bool(loadout.get_guard_modifier(&"guard_reaper_ritual", false)) and ritual_cooldown_remaining <= 0.0 and not enemy_data.is_boss:
		var charge_key := &"guard_reaper_charge_elite" if enemy_data.is_elite else &"guard_reaper_charge_normal"
		result.skill_charge = maxf(float(loadout.get_guard_modifier(charge_key, 2.5 if enemy_data.is_elite else 1.0)), 0.0)
		ritual_cooldown_remaining = maxf(float(loadout.get_guard_modifier(&"guard_reaper_ritual_cooldown", 0.6)), 0.05)
	return result

static func sudden_death_chance(enemy_data: EnemyData, base_chance: float, elite_ratio: float) -> float:
	if enemy_data == null or enemy_data.is_boss:
		return 0.0
	var chance := maxf(base_chance, 0.0)
	if enemy_data.is_elite:
		chance *= clampf(elite_ratio, 0.0, 1.0)
	return clampf(chance, 0.0, 1.0)

static func sudden_death_triggered(roll: float, enemy_data: EnemyData, base_chance: float, elite_ratio: float) -> bool:
	return clampf(roll, 0.0, 1.0) < sudden_death_chance(enemy_data, base_chance, elite_ratio)

func _is_judaginda_guard(column: TowerColumn, tower: TowerData) -> bool:
	return column != null and tower != null and column.is_guard_formation and column.formation_data != null and column.formation_data.id == FORMATION_ID and tower.id in SUPPORTED_TOWER_IDS
