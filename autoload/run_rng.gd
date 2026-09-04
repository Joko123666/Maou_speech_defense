extends Node

const REVISION := 3

var rng := RandomNumberGenerator.new()
var spawn_rng := RandomNumberGenerator.new()
var progression_rng := RandomNumberGenerator.new()
var current_seed: int = 0

func _ready() -> void:
	randomize_run()

func begin_run(deterministic: bool = false, seed_value: int = 0) -> void:
	if deterministic:
		seed_run(seed_value)
	else:
		randomize_run()

func seed_run(seed_value: int) -> void:
	current_seed = seed_value
	rng.seed = seed_value
	spawn_rng.seed = seed_value ^ 0x5F0A1
	progression_rng.seed = seed_value ^ 0x51A7E

func randomize_run() -> void:
	rng.randomize()
	seed_run(rng.seed)

func roll() -> float:
	return rng.randf()

func rangef(from: float, to: float) -> float:
	return rng.randf_range(from, to)

func pick(values: Array) -> Variant:
	if values.is_empty():
		return null
	return values[rng.randi_range(0, values.size() - 1)]

func randi_range(from: int, to: int) -> int:
	return rng.randi_range(from, to)

func spawn_roll() -> float:
	return spawn_rng.randf()

func spawn_rangef(from: float, to: float) -> float:
	return spawn_rng.randf_range(from, to)

func spawn_pick(values: Array) -> Variant:
	if values.is_empty():
		return null
	return values[spawn_rng.randi_range(0, values.size() - 1)]

func progression_roll() -> float:
	return progression_rng.randf()

func progression_rangef(from: float, to: float) -> float:
	return progression_rng.randf_range(from, to)

func progression_pick(values: Array) -> Variant:
	if values.is_empty():
		return null
	return values[progression_rng.randi_range(0, values.size() - 1)]
