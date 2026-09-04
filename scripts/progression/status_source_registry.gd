class_name StatusSourceRegistry
extends RefCounted

## 상태 성장 카드 적격과 일반 공격 자동 적용을 분리한다. 장판·주기 발동처럼
## 영구 소스이지만 매 타격마다 적용하면 안 되는 효과도 성장 적격에는 포함된다.
static func tower_is_source(tower: TowerData, status_id: StringName) -> bool:
	if tower == null:
		return false
	match status_id:
		&"bleed": return tower.behavior == &"knockback"
		&"shock": return tower.behavior == &"chain"
	return false

static func branch_is_source(modifiers: Dictionary, status_id: StringName) -> bool:
	if modifiers.get("spread_status", &"") == status_id:
		return true
	match status_id:
		&"poison": return modifiers.has("tactics_poison_damage")
		&"burn": return modifiers.has("burn") or modifiers.has("fire_zone_burn_ratio")
		&"bleed": return modifiers.has("bleed_power") or modifiers.has("tactics_bleed_ratio")
		&"shock": return modifiers.has("shock") or modifiers.has("lightning_damage")
	return false

static func tower_applies_on_hit(tower: TowerData, status_id: StringName) -> bool:
	return tower_is_source(tower, status_id)

static func branch_applies_on_hit(modifiers: Dictionary, status_id: StringName) -> bool:
	if modifiers.get("spread_status", &"") == status_id:
		return true
	match status_id:
		&"burn": return modifiers.has("burn")
		&"bleed": return modifiers.has("bleed_power")
		&"shock": return modifiers.has("shock")
	return false

static func bleed_source_id(tower: TowerData, modifiers: Dictionary) -> StringName:
	if tower == null:
		return &"unknown_bleed"
	if tower.behavior == &"knockback" or modifiers.has("bleed_power"):
		return &"ki2_saw_bleed"
	return StringName("%s_bleed" % tower.id)
