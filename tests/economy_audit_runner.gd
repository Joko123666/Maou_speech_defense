extends Node

func _ready() -> void:
	var report := FirstFiveRunEconomyAudit.run_default()
	print("ECONOMY AUDIT JSON %s" % JSON.stringify(report))
	print(
		"ECONOMY AUDIT %s · 첫 패배 +%d · 첫 발견 %d런 · 첫 구매 %d런 · 5런 후 %d/9 · 완전 해금 예상 %d런" % [
			"PASS" if bool(report.get("quality_gate_passed", false)) else "FAIL",
			int(report.get("first_defeat_reward", 0)),
			int(report.get("first_discovery_run", 0)),
			int(report.get("first_purchase_run", 0)),
			int(report.get("unlocked_towers_after_five", 0)),
			int(report.get("projected_full_unlock_run", 0)),
		]
	)
	get_tree().quit(0 if bool(report.get("quality_gate_passed", false)) else 1)
