class_name UpgradeSelectionRouter
extends RefCounted

enum Route {
	IGNORE,
	TUTORIAL_FIXED,
	ARTIFACT,
	CANDIDATE_BRANCH,
	FORMATION_SET,
	SPECIALIZATION,
	BLOCK_FORMATION_PLACEMENT,
	APPLY,
}

enum FailureRoute {
	BLOCK_FORMATION_RETRY,
	REFRESH_MAIN_CHOICES,
}

const SPECIALIZATION_ENTRY_CATEGORIES: Array[StringName] = [
	&"tower_specialization_entry",
	&"core_specialization_entry",
	&"cursor_specialization_entry",
	&"guard_specialization_entry",
]

func route_for(
		choice: UpgradeData,
		candidate_reward_active: bool,
		tutorial_fixed_growth: bool = false,
		tutorial_category: StringName = &"",
		tutorial_data_id: StringName = &""
	) -> int:
	if tutorial_fixed_growth:
		if tutorial_category == &"" or tutorial_data_id == &"" or choice == null or choice.category != tutorial_category or choice.data_id != tutorial_data_id:
			return Route.IGNORE
		return Route.TUTORIAL_FIXED
	if not candidate_reward_active and choice != null and choice.category == &"artifact":
		return Route.ARTIFACT
	if candidate_reward_active:
		return Route.CANDIDATE_BRANCH
	if choice != null and choice.category == &"formation_set":
		return Route.FORMATION_SET
	if choice != null and choice.category in SPECIALIZATION_ENTRY_CATEGORIES:
		return Route.SPECIALIZATION
	if choice != null and choice.category == &"new_formation" and choice.requires_placement and not choice.placement_confirmed:
		return Route.BLOCK_FORMATION_PLACEMENT
	return Route.APPLY

func failure_route_for(choice: UpgradeData) -> int:
	if choice != null and choice.category == &"new_formation":
		return FailureRoute.BLOCK_FORMATION_RETRY
	return FailureRoute.REFRESH_MAIN_CHOICES
