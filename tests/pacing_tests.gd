extends SceneTree
## The first 110 minutes against docs/FACTORY.md's F1–F8 (to 15:00) and
## docs/ECONOMY.md's N1–N8 (to 50:00) and M1–M7 (to 1:50), played by the
## pacing player (D003); OFFLINE.md's P1–P2; and FACTORY.md's early-game E1–E6,
## played by both the eager pacing player and a casual one.
## Prints a timeline and each criterion's measurement.

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const Player = preload("res://src/sim/engaged_player.gd")

const MINUTES := 110
## T4's window. Ten minutes, not one: a minute holds only about five drops, so
## one minute's measurement swings by ±40% with the random stream.
const FORAGE_MINUTES := 10.0

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
	var at_45: Dictionary = {}
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
		if g.stats.ticks == minute(45):
			at_45 = g.to_state()
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

	# v0.5.1's early-game criteria (FACTORY.md), for both players.
	var eager := early(Player.new())
	var casual := early(Player.casual())
	criterion("E1", casual.deck <= 90.0, "casual player: the deck at %s (by 1:30)" % clock(casual.deck))
	criterion("E2", eager.line <= 150.0 and casual.line <= 240.0, "the first line at %s eager (by 2:30), %s casual (by 4:00)" % [clock(eager.line), clock(casual.line)])
	criterion("E3", eager.gap <= 75.0 and casual.gap <= 100.0, "longest stretch with nothing new, deck to 15:00: %.0f s eager (at most 75), %.0f s casual (at most 100)" % [eager.gap, casual.gap])
	criterion("E4", casual.plot_share >= 1.0 / 3.0, "the plot picks %.0f%% of the casual player's peppers in the first 5 minutes (at least a third)" % (casual.plot_share * 100.0))
	criterion("E5", casual.tech <= 15 * 60.0, "casual player: the Tech Tree at %s (by 15:00)" % clock(casual.tech))
	# Narrowed to the casual player after measuring: the eager one buys the line
	# 36 s after the vat, so little mash waits (FACTORY.md says so).
	criterion("E6", casual.crate_mash >= 10, "Sweet Pepper Mash waiting for the Starter Crate: %d casual (at least 10); %d eager (not judged)" % [casual.crate_mash, eager.crate_mash])

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
	var tapping_rate := minute_from(at_100, p.taps_per_second, true)
	criterion("P2", slept.ov >= tapping_rate * 120.0, "from 1:40, 8 h away (counted %s at %d%%) raise Operation Value £%.0f; 2 h of tapping would £%.0f" % [
		clock(slept.counted), roundi(night.offline_speed() * 100.0), slept.ov, tapping_rate * 120.0])

	# Forager's Luck (TECH_TREE.md T4): its top-up for this player at 0:45.
	var lucky := forage_minute(at_45, p.taps_per_second, true)
	var plain := forage_minute(at_45, p.taps_per_second, false)
	var gain := 0.0
	var short := ""
	for crop in lucky.drops:
		if lucky.drops[crop] > lucky.drops.get(short, 0):
			short = crop
	if short != "":
		gain = float(lucky.got[short] - plain.got[short]) / maxf(plain.got[short], 1.0)
	criterion("T4", gain >= 0.10 and gain <= 0.20, "Forager's Luck from 0:45 adds %.0f%% to the shortest ingredient (%s over 10 min: %d against %d; want 10–20%%)" % [
		gain * 100.0, short if short != "" else "none", lucky.got.get(short, 0), plain.got.get(short, 0)])

	for failure in failures:
		printerr("FAIL: ", failure)
	print("%s: pacing tests (%d criteria)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


## Plays the first 20 minutes with a player and returns what the early-game
## criteria need: when the deck, the first line and the Tech Tree came, the
## longest stretch with nothing new (a purchase, research or reveal) from the
## deck to 15:00, the plot's share of peppers in the first 5 minutes, and the
## mash waiting when the line was bought.
func early(p: Player) -> Dictionary:
	var g := Game.new()
	var out := {"deck": INF, "line": INF, "tech": INF, "gap": 0.0, "plot_share": 0.0, "crate_mash": 0}
	var reveals := []
	for i in minute(20):
		p.step(g)
		g.tick()
		var now: float = g.now_seconds()
		if g.revealed.deck and out.deck == INF:
			out.deck = now
			reveals.append(now)
		if g.lines.size() == 1 and out.line == INF:
			out.line = now
			out.crate_mash = g.stock.sweet_mash + g.stats.made.table_mild + (1 if g.lines[0].running else 0)
		for tab in ["processing", "tech"]:
			if g.tab_open(tab) and not out.has("seen_" + tab):
				out["seen_" + tab] = true
				reveals.append(now)
				if tab == "tech":
					out.tech = now
		if g.stats.ticks == minute(5):
			out.plot_share = g.stats.harvested.bell / float(maxi(1, g.stats.harvested.bell + g.stats.bell_picked))
	var times: Array = reveals.duplicate()
	for e in p.events:
		if not String(e[1]).begins_with("sell"):
			times.append(e[0])
	times.sort()
	var last: float = out.deck
	for t in times:
		if t > out.deck and t <= 15 * 60.0:
			out.gap = maxf(out.gap, t - last)
			last = t
	out.gap = maxf(out.gap, 15 * 60.0 - last)
	return out


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
func minute_from(state: Dictionary, taps_per_second: float, no_spike: bool = false) -> float:
	var c := Game.new()
	c.load_state(JSON.parse_string(JSON.stringify(state, "", false, true)))
	if no_spike:
		# A spike lasts 30 minutes; a minute scaled to hours mustn't carry it.
		c.ticker = {"sauce": "", "mult": 1.0, "ends": 0, "next": -1}
	var p := Player.new()
	p.taps_per_second = taps_per_second
	p.buys = false
	var start := c.operation_value()
	for i in minute(1.0):
		p.step(c)
		c.tick()
	return c.operation_value() - start


## FORAGE_MINUTES from a saved state, tapping at the given rate and buying nothing,
## with or without Forager's Luck granted: each ingredient's harvest (drops
## included), and how many drops it got.
func forage_minute(state: Dictionary, taps_per_second: float, lucky: bool) -> Dictionary:
	var c := Game.new()
	c.load_state(JSON.parse_string(JSON.stringify(state, "", false, true)))
	if lucky:
		c.research["foragers_luck"] = true
		c._refresh_fx()
	var p := Player.new()
	p.taps_per_second = taps_per_second
	p.buys = false
	var out := {"got": {}, "drops": {}}
	var before := {}
	for crop in c.plots:
		before[crop] = c.stats.harvested[crop]
	for i in minute(FORAGE_MINUTES):
		var short := c._shortest_ingredient()
		var foraged: int = c.stats.foraged
		p.step(c)
		c.tick()
		if c.stats.foraged > foraged:
			out.drops[short] = out.drops.get(short, 0) + c.stats.foraged - foraged
	for crop in c.plots:
		if c.data.items[crop].ingredient:
			out.got[crop] = c.stats.harvested[crop] - before[crop]
	return out
