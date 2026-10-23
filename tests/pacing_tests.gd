extends SceneTree
## The pacing player (D003) on v0.7's copy of Idle Planet Miner (SKELETON.md):
## I6 (the first sale on time), I7 (no dead air) and I8 (the button still
## matters: F8, N8 and M5's bars), and the criteria SKELETON.md keeps as they
## stand: FACTORY.md's F1–F6 and the early-game E1–E6 and A7 (played by both
## the eager pacing player and a casual one), OFFLINE.md's P1–P2 and FULL_RUN.md's
## U8. Prints a timeline and each criterion's measurement.

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const Player = preload("res://src/sim/engaged_player.gd")

## Long enough to see I6's band and past it, so a late sale is still timed.
const MINUTES := 195

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


## When the player first did something starting with `what`.
static func first_like(p: Player, what: String) -> float:
	for entry in p.events:
		if String(entry[1]).begins_with(what):
			return entry[0]
	return INF


func run() -> void:
	var g := Game.new()
	var p := Player.new()
	var reached := {}
	var watch := {
		"status_bar": func(): return g.revealed.status_bar,
		"deck": func(): return g.revealed.deck,
		"nav": func(): return g.nav_shown(),
		"tech": func(): return g.tab_open("tech"),
		"ov_150k": func(): return g.operation_value() >= 150000.0,
		"ov_1m": func(): return g.operation_value() >= 1e6,
		"ov_4m": func(): return g.operation_value() >= 4e6,
		"sale": func(): return g.operation_value() >= T.PRESTIGE_OV,
	}
	var at_15: Dictionary = {}
	var at_30: Dictionary = {}
	var at_60: Dictionary = {}
	var at_90: Dictionary = {}
	var at_100: Dictionary = {}
	var ov_60 := 0.0
	var ov_by_30 := []
	for i in minute(MINUTES):
		p.step(g)
		g.tick()
		var now: float = g.stats.ticks * T.TICK_SECONDS
		for key in watch:
			if not reached.has(key) and watch[key].call():
				reached[key] = now
		if g.stats.ticks % minute(30) == 0:
			ov_by_30.append("%s $%s" % [clock(now), String.num(g.operation_value(), 0)])
		if g.stats.ticks == minute(15):
			at_15 = g.to_state()
		elif g.stats.ticks == minute(30):
			at_30 = g.to_state()
		elif g.stats.ticks == minute(60):
			at_60 = g.to_state()
			ov_60 = g.operation_value()
		elif g.stats.ticks == minute(90):
			at_90 = g.to_state()
		elif g.stats.ticks == minute(100):
			at_100 = g.to_state()

	print("Pacing: the first %d minutes" % MINUTES)
	for entry in p.events:
		if not String(entry[1]).begins_with("sell") and not String(entry[1]).begins_with("upgrade"):
			print("  %s  %s" % [clock(entry[0]), entry[1]])
	print("  at %s: $%.2f cash, $%.2f earned, Operation Value $%.2f" % [clock(MINUTES * 60.0), g.cash, g.stats.cash_earned, g.operation_value()])
	print("  Operation Value every 30 minutes: " + ", ".join(ov_by_30))
	for key in reached:
		print("  reached %s at %s" % [key, clock(reached[key])])

	# I6: the first sale on time.
	var sale: float = reached.get("sale", INF)
	criterion("I6", sale >= 120 * 60.0 and sale <= 150 * 60.0, "$10M Operation Value at %s (2:00–2:30); $150K at %s, $1M at %s, $4M at %s; at 3:15 $%s" % [
		clock(sale), clock(reached.get("ov_150k", INF)), clock(reached.get("ov_1m", INF)), clock(reached.get("ov_4m", INF)), String.num(g.operation_value(), 0)])

	# FACTORY.md's kitchen criteria, to 15:00 (I4).
	criterion("F1", reached.get("status_bar", INF) <= 15.0, "status bar at %s (by 0:15)" % clock(reached.get("status_bar", INF)))
	criterion("F2", reached.get("deck", INF) <= 90.0, "deck at %s (by 1:30)" % clock(reached.get("deck", INF)))
	criterion("F3", first_like(p, "buy vat 1") <= 180.0, "vat at %s (by 3:00)" % clock(first_like(p, "buy vat 1")))
	var line_at := first_like(p, "buy line 1")
	criterion("F4", line_at <= 300.0, "line at %s (by 5:00)" % clock(line_at))
	criterion("F5", p.first("sell_batch") <= 330.0, "first Sell Batch at %s (by 5:30)" % clock(p.first("sell_batch")))
	criterion("F6", longest_wait(p, line_at, 15 * 60.0) <= 90.0, "longest wait between purchases or research, line to 15:00: %.0f s (at most 90)" % longest_wait(p, line_at, 15 * 60.0))

	# I7: no dead air from the first line to the sale (A4's bar, 6:30).
	var to := minf(sale, MINUTES * 60.0)
	var gap := 0.0
	var gap_where := ""
	var last := line_at
	for entry in p.events:
		var what := String(entry[1])
		if entry[0] <= line_at or entry[0] > to:
			continue
		if what.begins_with("buy ") or what.begins_with("research "):
			if entry[0] - last > gap:
				gap = entry[0] - last
				gap_where = "ending %s at %s" % [what, clock(entry[0])]
			last = entry[0]
	if to - last > gap:
		gap = to - last
		gap_where = "to %s at %s" % ["the sale" if sale < INF else "3:15", clock(to)]
	criterion("I7", gap <= 390.0, "longest stretch without buying a farm, vat, line or recipe or researching, first line to the sale: %s (at most 6:30; %s)" % [clock(gap), gap_where])

	# I8: the button still matters (F8, N8, M5's bars).
	var lifts := []
	var i8 := true
	for at in [[at_15, "15:00", 0.25, false], [at_30, "30:00", 0.10, false], [at_90, "1:30:00", 0.30, false]]:
		var idle := minute_from(at[0], 0.0)
		var tap := minute_from(at[0], p.taps_per_second)
		var lift := (tap - idle) / idle if idle > 0.0 else INF
		i8 = i8 and lift >= at[2]
		lifts.append("%.0f%% at %s (at least %.0f%%)" % [lift * 100.0, at[1], at[2] * 100.0])
	criterion("I8", i8, "tapping adds " + ", ".join(lifts))

	# The early game, for both players (FACTORY.md, I4).
	var eager := early(Player.new())
	var casual := early(Player.casual())
	criterion("E1", casual.deck <= 90.0, "casual player: the deck at %s (by 1:30)" % clock(casual.deck))
	criterion("E2", eager.line <= 150.0 and casual.line <= 240.0, "the first line at %s eager (by 2:30), %s casual (by 4:00)" % [clock(eager.line), clock(casual.line)])
	criterion("E3", eager.gap <= 75.0 and casual.gap <= 100.0, "longest stretch with nothing new, deck to 15:00: %.0f s eager (at most 75), %.0f s casual (at most 100)" % [eager.gap, casual.gap])
	criterion("E4", casual.plot_share >= 1.0 / 3.0, "the plot picks %.0f%% of the casual player's peppers in the first 5 minutes (at least a third)" % (casual.plot_share * 100.0))
	criterion("E5", casual.tech <= 15 * 60.0, "casual player: the Tech Tree at %s (by 15:00)" % clock(casual.tech))
	criterion("E6", casual.crate_mash >= 10, "Sweet Pepper Mash waiting for the Starter Crate: %d casual (at least 10); %d eager (not judged)" % [casual.crate_mash, eager.crate_mash])
	criterion("A7", casual.second_plot <= 210.0, "the casual player's first farm after the Bell Plot at %s (by 3:30); eager %s (not judged)" % [clock(casual.second_plot), clock(eager.second_plot)])

	# OFFLINE.md's P1–P2 and FULL_RUN.md's U8.
	var checker := set_up(at_30)
	var away := checker.catch_up(8 * 3600.0)
	var back := Player.new()
	for i in minute(30):
		back.step(checker)
		checker.tick()
	criterion("P1", checker.operation_value() >= 2.0 * ov_60, "30 min, 8 h away (counted %s at %d%%), 30 min: $%.0f against a straight hour's $%.0f (at least twice)" % [
		clock(away.counted), roundi(away.offline / maxf(away.counted, 1.0) * 100.0), checker.operation_value(), ov_60])
	var night := set_up(at_100)
	var slept := night.catch_up(8 * 3600.0)
	var tapping_rate := minute_from(at_100, p.taps_per_second, true)
	criterion("P2", slept.ov >= tapping_rate * 120.0, "from 1:40, 8 h away (counted %s at %d%%) raise Operation Value $%.0f; 2 h of tapping would $%.0f" % [
		clock(slept.counted), roundi(night.offline_speed() * 100.0), slept.ov, tapping_rate * 120.0])
	var night_60 := set_up(at_60)
	night_60.catch_up(8 * 3600.0)
	criterion("U8", night_60.operation_value() < T.PRESTIGE_OV, "from 1:00, 8 hours away leaves Operation Value at $%.0f (under the sale's $10,000,000, D035)" % night_60.operation_value())

	for failure in failures:
		printerr("FAIL: ", failure)
	print("%s: pacing tests (%d criteria)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


## Plays the first 30 minutes with a player and returns what the early-game
## criteria need: when the deck, the first line and the Tech Tree came, the
## longest stretch with nothing new (a purchase, research or reveal) from the
## deck to 15:00, the plot's share of peppers in the first 5 minutes, and the
## mash waiting when the line was bought.
func early(p: Player) -> Dictionary:
	var g := Game.new()
	var out := {"deck": INF, "line": INF, "tech": INF, "gap": 0.0, "late_gap": 0.0, "second_plot": INF, "plot_share": 0.0, "crate_mash": 0}
	var reveals := []
	for i in minute(30):
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
	# A7: the first plot after Bell.
	for e in p.events:
		if String(e[1]).begins_with("buy plot ") and e[1] != "buy plot bell":
			out.second_plot = minf(out.second_plot, e[0])
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
	# J3: the same, from 15:00 to 30:00.
	last = 15 * 60.0
	for t in times:
		if t > 15 * 60.0 and t <= 30 * 60.0:
			out.late_gap = maxf(out.late_gap, t - last)
			last = t
	out.late_gap = maxf(out.late_gap, 30 * 60.0 - last)
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
## A saved state with its slots set up the way the player runs them, as before
## a tapping minute (minute_from), so a night doesn't start with whatever the
## player had lent to research at that tick (D035).
func set_up(state: Dictionary) -> Game:
	var c := Game.new()
	c.load_state(JSON.parse_string(JSON.stringify(state, "", false, true)))
	var p := Player.new()
	p.buys = false
	p.decide(c)
	return c


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
