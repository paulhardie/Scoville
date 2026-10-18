extends SceneTree
## The first 110 minutes against docs/FACTORY.md's F1–F8 (to 15:00) and
## docs/ECONOMY.md's N1–N8 (to 50:00) and M1–M7 (to 1:50), played by the
## pacing player (D003); OFFLINE.md's P1–P2; and FACTORY.md's early-game E1–E6,
## played by both the eager pacing player and a casual one.
## Prints a timeline and each criterion's measurement.

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const Player = preload("res://src/sim/engaged_player.gd")

const MINUTES := 195
## The sauce ladder (FULL_RUN.md), with each rung's expected time in minutes (U3).
const LADDER := {"smoky_ancho": 19, "bistro_verde": 21, "serrano_fire": 35, "classic_louisiana": 50, "cajun_red": 68,
	"island_heat": 95, "sweet_heat": 115, "savina_gold": 138, "phantom": 160}
## Mashes made from an ingredient: what U5's waits are on (D026).
const INGREDIENT_MASH := ["pickled_brine", "garlic_paste", "glaze", "liquid_smoke"]
## U6's swaps: each track's fork to its other side, one run each.
const SWAPS := [{"pantry_vinegar_bulk": "pantry_vinegar_reserve"}, {"pantry_garlic_bulk": "pantry_garlic_reserve"},
	{"pantry_sugar_reserve": "pantry_sugar_bulk"}, {"pantry_oak_reserve": "pantry_oak_bulk"}]
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
		"ov_1m": func(): return g.operation_value() >= 1000000.0,
	}
	for sauce in LADDER:
		watch["made " + sauce] = (func(item): return func(): return g.stats.made[item] > 0).call(sauce)
	var at_15: Dictionary = {}
	var at_30: Dictionary = {}
	var at_45: Dictionary = {}
	var at_90: Dictionary = {}
	var at_100: Dictionary = {}
	var ov_60 := 0.0
	var ov_110 := 0.0
	var ov_180 := 0.0
	var at_150: Dictionary = {}
	var u4 := {"classic_louisiana": 0, "pickled_brine": 0}
	var at_80: Dictionary = {}
	var u5 := {"waiting": 0, "busy": 0, "longest": 0.0, "since": {}}
	var window := {"line_busy": 0, "ticks": 0, "brine_start": 0, "brine_end": 0}
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
		if g.stats.ticks == minute(80):
			at_80 = g.to_state()
		if g.stats.ticks == minute(110):
			ov_110 = g.operation_value()
		if g.stats.ticks == minute(150):
			at_150 = g.to_state()
		if g.stats.ticks == minute(180):
			ov_180 = g.operation_value()
		if g.stats.ticks == minute(150):
			for item in u4:
				u4[item] = -g.stats.made[item]
		if g.stats.ticks == minute(160):
			for item in u4:
				u4[item] += g.stats.made[item]
		if g.stats.ticks > minute(60) and g.stats.ticks <= minute(180):
			u5_tick(g, u5)
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
	criterion("M3", reached.get("ov_100k", INF) <= 110 * 60.0, "Operation Value £100,000 at %s (by 1:50:00); at 1:50 £%.0f" % [clock(reached.get("ov_100k", INF)), ov_110])
	var wait_m := longest_wait(p, 50 * 60.0, 110 * 60.0)
	criterion("M4", wait_m <= 150.0, "longest wait between purchases or research, 50:00–1:50:00: %.0f s (at most 150)" % wait_m)
	var idle_90 := minute_from(at_90, 0.0)
	var tap_90 := minute_from(at_90, p.taps_per_second)
	var lift_90 := (tap_90 - idle_90) / idle_90 if idle_90 > 0.0 else INF
	criterion("M5", lift_90 >= 0.30, "tapping adds %.0f%% at 1:30:00 (at least 30%%): £%.0f vs £%.0f a minute" % [lift_90 * 100.0, tap_90, idle_90])
	# M6 is retired: U4 checks the same thing for v0.6a's run (D032).
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

	# v0.6a's criteria (FULL_RUN.md).
	var bands := [["ov_1k", "£1,000", 12, 18], ["ov_10k", "£10,000", 40, 55], ["ov_100k", "£100,000", 95, 115], ["ov_1m", "£1,000,000", 165, 195]]
	var u1_ok := true
	var u1_text := []
	for b in bands:
		var at: float = reached.get(b[0], INF)
		u1_ok = u1_ok and at >= b[2] * 60.0 and at <= b[3] * 60.0
		u1_text.append("%s at %s (%s–%s)" % [b[1], clock(at), clock(b[2] * 60.0), clock(b[3] * 60.0)])
	criterion("U1", u1_ok, ", ".join(u1_text))
	var wait_u := longest_wait(p, 110 * 60.0, 180 * 60.0)
	criterion("U2", wait_u <= 150.0, "longest wait between purchases or research, 1:50–3:00: %.0f s (at most 150)" % wait_u)
	var u3_ok := true
	var u3_text := []
	for sauce in LADDER:
		var at: float = reached.get("made " + sauce, INF)
		u3_ok = u3_ok and at <= 180 * 60.0 and absf(at - LADDER[sauce] * 60.0) <= 20 * 60.0
		u3_text.append("%s %s (%s)" % [sauce, clock(at), clock(LADDER[sauce] * 60.0)])
	criterion("U3", u3_ok, "first made, against expected: " + ", ".join(u3_text))
	criterion("U4", u4.classic_louisiana > 0 and u4.pickled_brine > 0, "2:30–2:40 made: %d Classic Louisiana, %d Pickled Brine (each at least 1)" % [u4.classic_louisiana, u4.pickled_brine])
	var share: float = u5.waiting / float(maxi(u5.busy, 1))
	criterion("U5", share >= 0.10 and share <= 0.40 and u5.longest <= 300.0, "1:00–3:00: slots wait on an ingredient's mash %.0f%% of the time (10–40%%), longest %.0f s (at most 300)" % [share * 100.0, u5.longest])
	var edge := 0.0
	var edge_text := ""
	for swap in SWAPS:
		var other := run_to(180, swap)
		var e := absf(other - ov_180) / ov_180 if ov_180 > 0.0 else 0.0
		if e > edge:
			edge = e
			edge_text = "%s (£%.0f against £%.0f)" % [swap.keys()[0], other, ov_180]
	var forks_taken := 0
	for id in g.data.tech:
		if g.data.tech[id].excludes.size() > 0 and g.is_researched(id):
			forks_taken += 1
	criterion("U6", forks_taken >= 2 and edge >= 0.05, "%d forks taken by 3:15; the biggest swing from swapping one fork: %.1f%% at 3:00, %s (at least 5%%)" % [forks_taken, edge * 100.0, edge_text])
	var idle_150 := minute_from(at_150, 0.0)
	var tap_150 := minute_from(at_150, p.taps_per_second)
	var lift_150 := (tap_150 - idle_150) / idle_150 if idle_150 > 0.0 else INF
	criterion("U7", lift_150 >= 0.30, "tapping adds %.0f%% at 2:30 (at least 30%%): £%.0f vs £%.0f a minute" % [lift_150 * 100.0, tap_150, idle_150])
	var night_80 := Game.new()
	night_80.load_state(JSON.parse_string(JSON.stringify(at_80, "", false, true)))
	night_80.catch_up(8 * 3600.0)
	criterion("U8", night_80.operation_value() < 1000000.0, "from 1:20, 8 hours away leaves Operation Value at £%.0f (under £1,000,000)" % night_80.operation_value())

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
	# The backlog a save holds (bottles saved up for research) is sold before
	# the minute starts, so it doesn't count for tapping and idling alike. An
	# idle minute starts at Heat 0, where idling settles (the Piston alone
	# can't hold it, H3), not at the tapping player's saved Heat.
	p.decide(c)
	if taps_per_second <= 0.0:
		c.heat = 0.0
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


## U5: one tick of slot time, and whether each slot is waiting on an
## ingredient's mash; the longest such wait is kept per slot.
func u5_tick(g: Game, u5: Dictionary) -> void:
	for station in ["vat", "line"]:
		for i in g.slots(station).size():
			var s: Dictionary = g.slots(station)[i]
			if s.recipe == "":
				continue
			u5.busy += 1
			var key := "%s%d" % [station, i]
			var short := false
			if not s.running:
				var inputs: Dictionary = g.recipe_inputs(s.recipe)
				for item in INGREDIENT_MASH:
					if inputs.has(item) and g.stock[item] < inputs[item]:
						short = true
			if short:
				u5.waiting += 1
				u5.since[key] = u5.since.get(key, 0.0) + T.TICK_SECONDS
				u5.longest = maxf(u5.longest, u5.since[key])
			else:
				u5.since.erase(key)


## Operation Value at `minutes` for a fresh run by the pacing player with these
## fork swaps (U6).
func run_to(minutes: int, forks: Dictionary) -> float:
	var g := Game.new()
	var p := Player.new()
	p.forks = forks
	for i in minute(minutes):
		p.step(g)
		g.tick()
	return g.operation_value()
