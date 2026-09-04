class_name FirstFiveRunEconomyContractTest
extends RefCounted

static func run() -> Array[String]:
	var failures: Array[String] = []
	var report := FirstFiveRunEconomyAudit.run_default()
	_expect(bool(report.quality_gate_passed), "the representative new-account economy must pass defeat reward, discovery, purchase, and full-unlock gates", failures)
	_expect(int(report.starter_tower_count) == 4 and int(report.shop_product_count) == 5 and int(report.total_tower_count) == 9, "the economy audit must cover exactly four starters and five shop towers", failures)
	_expect(int(report.total_shop_price) == 1520, "the projection must consume the live five-product price catalog", failures)
	_expect(int(report.first_defeat_reward) == 45 and int(report.first_discovery_run) == 0, "the first three-minute defeat must pay progress and all shop products must already be public", failures)
	_expect(int(report.first_purchase_run) == 3, "the lowest-price-first onboarding policy must make the first purchase possible after run three", failures)
	_expect(int(report.discovered_after_five) == 5 and int(report.purchased_after_five) == 3 and int(report.unlocked_towers_after_five) == 7, "five representative runs must discover all products and fund three of the five purchases", failures)
	_expect(int(report.projected_full_unlock_run) == 7, "repeating a standard clear after the five-run sample must project all nine towers by run seven", failures)
	var runs := report.runs as Array
	_expect(runs.size() == 5 and int((runs[4] as Dictionary).reward_funds) == 530, "the five-run ledger must retain the first-clear reward breakdown from the live reward table", failures)
	_expect((runs as Array).all(func(row: Dictionary) -> bool: return int(row.funds_after) >= 0), "the purchase policy must never overspend the simulated balance", failures)
	return failures

static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
