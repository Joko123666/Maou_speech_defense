class_name MetaCatalogFactory
extends RefCounted

static func build_products() -> Array[ShopProductData]:
	return [
		_product(&"tower_knockback", "죽음교 자동포교기계 KI-Ⅱ", "회전 톱날과 넉백으로 전선을 밀어내는 제어 병기", &"tower", &"knockback", 340, &"discover_tower_knockback"),
		_product(&"tower_slow", "심연의 기둥", "심연의 냉기로 범위 안의 난입자 진군을 늦추는 제어 병력", &"tower", &"slow", 220, &"discover_tower_slow"),
		_product(&"tower_mark", "서큐버스 약화주술사", "강한 난입자에게 취약 주술을 걸어 수비병력의 화력을 집중시키는 지원대", &"tower", &"mark", 260, &"discover_tower_mark"),
		_product(&"tower_execute", "트롤 스나이퍼", "약해진 난입자와 정예를 장거리 저격으로 퇴장시키는 단일 화력대", &"tower", &"execute", 320, &"discover_tower_execute"),
		_product(&"tower_chain", "마력 전도탑", "전도탑 사이의 마력 망으로 다수의 난입자를 연쇄 제압하는 지원 시설", &"tower", &"chain", 380, &"discover_tower_chain"),
	]

static func build_achievements() -> Array[AchievementData]:
	var result: Array[AchievementData] = []
	var first_run := _achievement(&"unlock_meta_hub", "첫 귀환", "첫 출격을 마치고 상점과 업적 기능을 개방", &"start", &"runs", 1.0)
	first_run.unlock_feature_ids = [&"shop_system", &"achievement_system"]
	result.append(first_run)
	var first_clear := _achievement(&"unlock_challenge_system", "첫 연설 완주", "공식 연설을 처음 완주해 도전 단계를 개방", &"challenge", &"run.victory", 1.0, &"single_run")
	first_clear.unlock_feature_ids = [&"challenge_system"]
	result.append(first_clear)

	result.append(_discovery(&"discover_tower_knockback", "기초 마군단 완성", "한 출격에서 고블린·오크·스켈레톤·고무 골렘을 모두 배치", &"tower", &"run.starter_tower_types", 4.0, &"single_run", &"tower_knockback"))
	result.append(_discovery(&"discover_tower_slow", "흔들리지 않는 연설대", "5분까지 연설대에 도달한 난입자를 3기 이하로 통제", &"tower", &"run.slow_discovery", 1.0, &"single_run", &"tower_slow"))
	result.append(_discovery(&"discover_tower_mark", "공식 난입 분석", "공식 난입자에게 누적 피해 10,000 달성", &"tower", &"boss_damage", 10000.0, &"cumulative", &"tower_mark"))
	result.append(_discovery(&"discover_tower_execute", "정예 퇴장 조치", "중장갑·정예 난입자를 누적 100기 퇴장", &"tower", &"elite_kills", 100.0, &"cumulative", &"tower_execute"))
	result.append(_discovery(&"discover_tower_chain", "연쇄 제압", "2초 안에 난입자 10기 퇴장을 5회 달성", &"tower", &"burst_10_kill_windows", 5.0, &"cumulative", &"tower_chain"))

	var poison_growth := _achievement(&"unlock_status_growth_poison", "스며드는 독기", "독을 50회 적용", &"status", &"status_applications.poison", 50.0)
	poison_growth.unlock_feature_ids = [&"status_growth_poison"]
	result.append(poison_growth)
	var bleed_growth := _achievement(&"unlock_status_growth_bleed", "깊은 상처", "출혈 피해 누적 1,000 달성", &"status", &"status_damage.bleed", 1000.0)
	bleed_growth.unlock_feature_ids = [&"status_growth_bleed"]
	result.append(bleed_growth)
	var burn_growth := _achievement(&"unlock_status_growth_burn", "확산 연소", "화상을 50회 적용", &"status", &"status_applications.burn", 50.0)
	burn_growth.unlock_feature_ids = [&"status_growth_burn"]
	result.append(burn_growth)
	var shock_growth := _achievement(&"unlock_status_growth_shock", "전도 회로", "마력 전도탑을 고용한 뒤 감전을 50회 적용", &"status", &"status_applications.shock", 50.0)
	shock_growth.required_any_product_ids = [&"tower_chain"]
	shock_growth.unlock_feature_ids = [&"status_growth_shock"]
	result.append(shock_growth)
	return result

static func _product(id: StringName, title: String, description: String, type: StringName, content_id: StringName, price: int, achievement_id: StringName) -> ShopProductData:
	return ShopProductData.new().configure(id, title, description, type, content_id, price, achievement_id)

static func _achievement(id: StringName, title: String, description: String, category: StringName, metric_id: StringName, target: float, mode: StringName = &"cumulative") -> AchievementData:
	return AchievementData.new().configure(id, title, description, category, metric_id, target, mode)

static func _discovery(id: StringName, title: String, description: String, category: StringName, metric_id: StringName, target: float, mode: StringName, product_id: StringName) -> AchievementData:
	var data := _achievement(id, title, description, category, metric_id, target, mode)
	data.discover_product_ids = [product_id]
	return data
