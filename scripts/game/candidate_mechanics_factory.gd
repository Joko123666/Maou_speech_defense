class_name CandidateMechanicsFactory
extends RefCounted

func component_plan(core_data: CoreData, retainer_profile: RetainerProfileData) -> Array[StringName]:
	var plan: Array[StringName] = [&"summon_service"]
	if core_data != null and core_data.id == &"amethyst":
		plan.append(&"candidate_abyss")
	if core_data != null and core_data.necromancy_profile != null:
		plan.append_array([&"necromancy", &"death_wave"])
	if retainer_profile != null and retainer_profile.combo_profile != null:
		plan.append(&"retainer_reconstruction")
	if retainer_profile != null and retainer_profile.id in [&"kanda", &"given", &"jeomujeom"]:
		plan.append(&"retainer_combat")
	if retainer_profile != null and retainer_profile.vanguard_stack_profile != null:
		plan.append(&"vanguard_squad")
	return plan

func create_components(
	core: DefenseCore,
	target_cursor: TargetCursor,
	effect_container: Node2D,
	summon_container: Node2D,
	battlefield: Battlefield,
	spatial_index: EnemySpatialIndex,
	loadout: LoadoutManager,
	necromancy_modifiers: Dictionary,
	callbacks: Dictionary
) -> Dictionary:
	var campaign := ConceptService.get_election_campaign()
	var retainer_profile := campaign.retainer_for_cursor(target_cursor.data.id) if campaign != null else null
	var plan := component_plan(core.data, retainer_profile)
	var components := {
		"summon_service": null,
		"candidate_abyss_controller": null,
		"necromancy_controller": null,
		"death_wave_controller": null,
		"retainer_profile": retainer_profile,
		"retainer_combat_controller": null,
		"retainer_reconstruction_component": null,
		"vanguard_squad_component": null,
		"component_count": plan.size(),
	}
	var summon_service := SummonService.new()
	effect_container.add_child(summon_service)
	components.summon_service = summon_service
	if &"retainer_combat" in plan:
		var retainer_combat := RetainerCombatController.new()
		effect_container.add_child(retainer_combat)
		retainer_combat.setup(retainer_profile, target_cursor, loadout.get_cursor_branch_modifiers(), spatial_index)
		_connect_once(retainer_combat.resummoned, callbacks.get(&"retainer_resummoned", Callable()))
		components.retainer_combat_controller = retainer_combat
	if &"candidate_abyss" in plan:
		var abyss_controller := CandidateAbyssController.new()
		effect_container.add_child(abyss_controller)
		abyss_controller.setup(spatial_index, summon_container, battlefield, summon_service)
		_connect_once(abyss_controller.attack_requested, callbacks.get(&"candidate_abyss_attack", Callable()))
		_connect_once(abyss_controller.summon_expired, callbacks.get(&"candidate_abyss_expired", Callable()))
		components.candidate_abyss_controller = abyss_controller
	if &"necromancy" in plan:
		var necromancy := NecromancyController.new()
		effect_container.add_child(necromancy)
		necromancy.setup(core, core.data.necromancy_profile, summon_service)
		necromancy.apply_modifiers(necromancy_modifiers)
		_connect_once(necromancy.spirits_generated, callbacks.get(&"spirits_generated", Callable()))
		_connect_once(necromancy.summon_expired, callbacks.get(&"spirit_expired", Callable()))
		components.necromancy_controller = necromancy
		var death_wave := DeathWaveController.new()
		effect_container.add_child(death_wave)
		death_wave.setup(battlefield, spatial_index, summon_service)
		_connect_once(death_wave.hit_requested, callbacks.get(&"death_wave_hit", Callable()))
		_connect_once(death_wave.wave_finished, callbacks.get(&"death_wave_finished", Callable()))
		components.death_wave_controller = death_wave
	if &"retainer_reconstruction" in plan:
		var reconstruction := RetainerReconstructionComponent.new()
		effect_container.add_child(reconstruction)
		reconstruction.setup(target_cursor, retainer_profile.combo_profile, target_cursor.presentation_color, loadout.get_cursor_branch_modifiers())
		_connect_once(reconstruction.reconstruction_started, callbacks.get(&"reconstruction_started", Callable()))
		_connect_once(reconstruction.reconstruction_completed, callbacks.get(&"reconstruction_completed", Callable()))
		components.retainer_reconstruction_component = reconstruction
	if &"vanguard_squad" in plan:
		var vanguard := VanguardSquadComponent.new()
		effect_container.add_child(vanguard)
		vanguard.setup(target_cursor, retainer_profile.vanguard_stack_profile, target_cursor.presentation_color, loadout.get_cursor_branch_modifiers())
		_connect_once(vanguard.member_spent, callbacks.get(&"vanguard_member_spent", Callable()))
		_connect_once(vanguard.reinforcement_arrived, callbacks.get(&"vanguard_reinforcement_arrived", Callable()))
		_connect_once(vanguard.sacrifice_triggered, callbacks.get(&"vanguard_sacrifice", Callable()))
		components.vanguard_squad_component = vanguard
	return components

func _connect_once(signal_value: Signal, callback: Callable) -> void:
	if callback.is_valid() and not signal_value.is_connected(callback):
		signal_value.connect(callback)
