extends SceneTree
## The first 110 minutes against docs/FACTORY.md's F1–F8 (to 15:00) and
## docs/ECONOMY.md's N1–N8 (to 50:00) and M1–M7 (to 1:50), played by the
## pacing player (D003).
## Prints a timeline and each criterion's measurement.

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const Player = preload("res://src/sim/engaged_player.gd")

const MINUTES := 110

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	run.call_deferred()


func criterion(id: String, ok: bool, measured: String) -> void:
	checks += 1
	print("  %s %s  %s" % [id, "PASS" if ok else "FAIL", measured])
	if not ok:
		failures.append("%s: %s" % [id, measured])


func clock(seconds: float) -> String:
	if seconds == INF:
		return "never"
	if seconds >= 3600.0:
		return "%d:%02d:%02d" % [int(seconds) / 3600, (int(seconds) / 60) % 60, int(seconds) % 60]
	return "%d:%04.1f" % [int(seconds) / 60, fmod(seconds, 60.0)]


func minute(m: float) -> int:
	return roundi(m * 60.0 / T.TICK_SECONDS)


func run() -> void:
	var g := Game.new()
	var p := Player.new()
	var reached := {}
	var watch := {
		"status_bar": func(): return g.revealed.status_bar,
		"deck": func(): return g.revealed.deck,
		"nav": func(): return g.nav_shown(),
		"tech": func(): return g.tab_open("tech"),
		"bistro": func(): return g.stats.made.bistro_verde > 0,
		"ov_1k": func(): return g.operation_value() >= 1000.0,
		"ov_10k": func(): return g.operation_value() >= 10000.0,
		"ov_100k": func(): return g.operation_value() >= 100000.0,
		"louisiana": func(): return g.stats.made.classic_louisiana > 0,
	}
	var at_15: Dictionary = {}
	var at_30: Dictionary = {}
	var at_90: Dictionary = {}
	var at_100: Dictionary = {}
	var ov_60 := 0.0
	var window := {"line_busy": 0, "ticks": 0, "brine_start": 0, "brine_end": 0}
	var late := {"table_mild": 0, "bistro_verde": 0, "ticks": 0}
	for i in minute(MINUTES):
		p.step(g)
		g.tick()
		var now: float = g.stats.ticks * T.TICK_SECONDS
		for key in watch:
			if not reached.has(key) and watch[key].call():
				reached[key] = now
		if g.stats.ticks == minute(15):
			at_15 = g.to_state()
		if g.stats.ticks == minute(30):
			at_30 = g.to_state()
		if g.stats.ticks == minute(90):
			at_90 = g.to_state()
		if g.stats.ticks == minute(60):
			ov_60 = g.operation_value()
		if g.stats.ticks == minute(100):
			at_100 = g.to_state()
		if g.stats.ticks > minute(90) and g.stats.ticks <= minute(100):
			late.ticks += 1
			for sauce in ["table_mild", "bistro_verde"]:
				for s in g.lines:
					if s.recipe == sauce and s.running:
						late[sauce] += 1
						break
		if g.stats.ticks == minute(40):
			window.brine_start = g.stats.made.pickled_brine
		if g.stats.ticks == minute(50):
			window.brine_end = g.stats.made.pickled_brine
		if g.stats.ticks > minute(40) and g.stats.ticks <= minute(50):
			window.ticks += 1
			for s in g.lines:
				if s.recipe == "table_mild" and s.running:
					window.line_busy += 1
					break

	print("Pacing: the first %d minutes" % MINUTES)
	for entry in p.events:
		if not String(entry[1]).begins_with("sell"):
			print("  %s  %s" % [clock(entry[0]), entry[1]])
	print("  at %s: £%.2f cash, £%.2f earned, Operation Value £%.2f; %d Table Mild and %d Bistro Verde made" % [
		clock(MINUTES * 60.0), g.cash, g.stats.cash_earned, g.operation_value(), g.stats.made.table_mild, g.stats.made.bistro_verde])
	for key in reached:
		print("  reached %s at %s" % [key, clock(reached[key])])

	# v0.2's criteria, to 15:00 (FACTORY.md).
	criterion("F1", reached.get("status_bar", INF) <= 15.0, "status bar at %s (by 0:15)" % clock(reached.get("status_bar", INF)))
	criterion("F2", reached.get("deck", INF) <= 90.0, "deck at %s (by 1:30)" % clock(reached.get("deck", INF)))
	criterion("F3", p.first("buy vat 1 (sweet_mash)") <= 180.0, "vat at %s (by 3:00)" % clock(p.first("buy vat 1 (sweet_mash)")))
	var line_at := p.first("buy line 1 (table_mild)")
	criterion("F4", line_at <= 300.0, "line at %s (by 5:00)" % clock(line_at))
	criterion("F5", p.first("sell_batch") <= 330.0, "first Sell Batch at %s (by 5:30)" % clock(p.first("sell_batch")))
	criterion("F6", longest_wait(p, line_at, 15 * 60.0) <= 90.0, "longest wait between purchases or research, line to 15:00: %.0f s (at most 90)" % longest_wait(p, line_at, 15 * 60.0))
	var idle_15 := minute_from(at_15, 0.0)
	var tap_15 := minute_from(at_15, p.taps_per_second)
	criterion("F7", idle_15 >= 18.0, "factory alone earns £%.2f a minute at 15:00 (at least £18)" % idle_15)
	var lift_15 := (tap_15 - idle_15) / idle_15 if idle_15 > 0.0 else INF
	criterion("F8", lift_15 >= 0.25, "tapping adds %.0f%% at 15:00 (at least 25%%)" % (lift_15 * 100.0))

	# v0.3's criteria, to 50:00 (ECONOMY.md).
	criterion("N1", reached.get("nav", INF) <= 9 * 60.0, "Stage 3 (£400) at %s (by 9:00)" % clock(reached.get("nav", INF)))
	criterion("N2", reached.get("tech", INF) <= 14 * 60.0, "Tech Tree (£750) at %s (by 14:00)" % clock(reached.get("tech", INF)))
	var e1 := p.first("research jalapeno_blueprint")
	criterion("N3", e1 <= 20 * 60.0, "Jalapeño blueprint at %s (by 20:00)" % clock(e1))
	criterion("N4", reached.get("bistro", INF) <= 30 * 60.0, "first Bistro Verde at %s (by 30:00)" % clock(reached.get("bistro", INF)))
	criterion("N5", reached.get("ov_10k", INF) <= 50 * 60.0, "Operation Value £10,000 at %s (by 50:00); £1,000 at %s" % [clock(reached.get("ov_10k", INF)), clock(reached.get("ov_1k", INF))])
	var wait := longest_wait(p, 15 * 60.0, 50 * 60.0)
	criterion("N6", wait <= 120.0, "longest wait between purchases or research, 15:00–50:00: %.0f s (at most 120)" % wait)
	var busy: float = window.line_busy / float(maxi(window.ticks, 1))
	var brine: int = window.brine_end - window.brine_start
	criterion("N7", busy >= 0.5 and brine > 0, "40:00–50:00: Table Mild line busy %.0f%% (at least 50%%), %d Pickled Brine made from Bell Peppers" % [busy * 100.0, brine])
	var idle_30 := minute_from(at_30, 0.0)
	var tap_30 := minute_from(at_30, p.taps_per_second)
	var lift_30 := (tap_30 - idle_30) / idle_30 if idle_30 > 0.0 else INF
	criterion("N8", lift_30 >= 0.10, "tapping adds %.0f%% at 30:00 (at least 10%%): £%.2f vs £%.2f a minute" % [lift_30 * 100.0, tap_30, idle_30])

	# v0.4's criteria, to 1:50 (ECONOMY.md).
	var tier_3 := minf(p.first("research cayenne_blueprint"), p.first("research garlic_blueprint"))
	criterion("M1", tier_3 <= 48 * 60.0, "first Tier 3 blueprint at %s (by 48:00)" % clock(tier_3))
	criterion("M2", reached.get("louisiana", INF) <= 55 * 60.0, "first Classic Louisiana at %s (by 55:00)" % clock(reached.get("louisiana", INF)))
	criterion("M3", reached.get("ov_100k", INF) <= 110 * 60.0, "Operation Value £100,000 at %s (by 1:50:00); at 1:50 £%.0f" % [clock(reached.get("ov_100k", INF)), g.operation_value()])
	var wait_m := longest_wait(p, 50 * 60.0, 110 * 60.0)
	criterion("M4", wait_m <= 150.0, "longest wait between purchases or research, 50:00–1:50:00: %.0f s (at most 150)" % wait_m)
	var idle_90 := minute_from(at_90, 0.0)
	var tap_90 := minute_from(at_90, p.taps_per_second)
	var lift_90 := (tap_90 - idle_90) / idle_90 if idle_90 > 0.0 else INF
	criterion("M5", lift_90 >= 0.30, "tapping adds %.0f%% at 1:30:00 (at least 30%%): £%.0f vs £%.0f a minute" % [lift_90 * 100.0, tap_90, idle_90])
	var tm: float = late.table_mild / float(maxi(late.ticks, 1))
	var bv: float = late.bistro_verde / float(maxi(late.ticks, 1))
	criterion("M6", tm >= 0.5 and bv >= 0.5, "1:30–1:40: Table Mild line busy %.0f%%, Bistro Verde line busy %.0f%% (each at least 50%%)" % [tm * 100.0, bv * 100.0])
	var piston := p.first("research automated_piston")
	criterion("M7", piston <= 110 * 60.0, "Automated Piston at %s (by 1:50:00)" % clock(piston))

	# v0.5's criteria (OFFLINE.md).
	var checker := Game.new()
	checker.load_state(JSON.parse_string(JSON.stringify(at_30, "", false, true)))
	var away := checker.catch_up(8 * 3600.0)
	var back := Player.new()
	for i in minute(30):
		back.step(checker)
		checker.tick()
	criterion("P1", checker.operation_value() >= 2.0 * ov_60, "30 min, 8 h away (counted %s at %d%%), 30 min: £%.0f against a straight hour's £%.0f (at least twice)" % [
		clock(away.counted), roundi(away.offline / maxf(away.counted, 1.0) * 100.0), checker.operation_value(), ov_60])
	var night := Game.new()
	night.load_state(JSON.parse_string(JSON.stringify(at_100, "", false, true)))
	var slept := night.catch_up(8 * 3600.0)
	var tapping_rate := minute_from(at_100, p.taps_per_second)
	criterion("P2", slept.ov >= tapping_rate * 120.0, "from 1:40, 8 h away (counted %s at %d%%) raise Operation Value £%.0f; 2 h of tapping would £%.0f" % [
		clock(slept.counted), roundi(night.offline_speed() * 100.0), slept.ov, tapping_rate * 120.0])

	for failure in failures:
		printerr("FAIL: ", failure)
	print("%s: pacing tests (%d criteria)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


## The longest stretch between the player's purchases and research in a window,
## counting from its start to its end.
func longest_wait(p: Player, from: float, to: float) -> float:
	var last := from
	var longest := 0.0
	for entry in p.events:
		var what := String(entry[1])
		if entry[0] < from or entry[0] > to or what.begins_with("sell"):
			continue
		longest = maxf(longest, entry[0] - last)
		last = entry[0]
	return maxf(longest, to - last)


## What the next minute earns from a saved state, by a player tapping at the
## given rate who buys and researches nothing more: the rise in Operation Value,
## so bottles saved up earlier and sold now don't count as new earnings.
func minute_from(state: Dictionary, taps_per_second: float) -> float:
	var c := Game.new()
	c.load_state(JSON.parse_string(JSON.stringify(state, "", false, true)))
	var p := Player.new()
	p.taps_per_second = taps_per_second
	p.buys = false
	var start := c.operation_value()
	for i in minute(1.0):
		p.step(c)
		c.tick()
	return c.operation_value() - start
