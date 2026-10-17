extends SceneTree
## The first 15 minutes against docs/FACTORY.md's criteria F1–F8, played by the
## pacing player. Prints a timeline and each criterion's measurement.

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const Player = preload("res://src/sim/engaged_player.gd")

const MINUTES := 15
const STAGE_WATCH := ["status_bar", "deck"]

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
	return "%d:%04.1f" % [int(seconds) / 60, fmod(seconds, 60.0)]


func run() -> void:
	var g := Game.new()
	var p := Player.new()
	var reached := {}
	var ticks := roundi(MINUTES * 60 / T.TICK_SECONDS)
	for i in ticks:
		p.step(g)
		g.tick()
		for key in STAGE_WATCH:
			if g.revealed[key] and not reached.has(key):
				reached[key] = g.stats.ticks * T.TICK_SECONDS

	print("Pacing: the first %d minutes" % MINUTES)
	for entry in p.events:
		if not String(entry[1]).begins_with("sell"):
			print("  %s  %s" % [clock(entry[0]), entry[1]])
	print("  at %s: £%.2f cash, £%.2f earned, plot speed %d yield %d, vat speed %d, line speed %d, %d bottles sold" % [
		clock(ticks * T.TICK_SECONDS), g.cash, g.stats.cash_earned, g.stations.plot.speed, g.stations.plot.yield,
		g.stations.vat.speed, g.stations.line.speed, g.stats.bottles_sold])

	var stage_1: float = reached.get("status_bar", INF)
	var stage_2: float = reached.get("deck", INF)
	criterion("F1", stage_1 <= 15.0, "status bar at %s (by 0:15)" % clock(stage_1))
	criterion("F2", stage_2 <= 90.0, "deck at %s (by 1:30)" % clock(stage_2))
	criterion("F3", p.first("buy vat") <= 180.0, "vat at %s (by 3:00)" % clock(p.first("buy vat")))
	var line_at := p.first("buy line")
	criterion("F4", line_at <= 300.0, "line at %s (by 5:00)" % clock(line_at))
	criterion("F5", p.first("sell_batch") <= 330.0, "first Sell Batch at %s (by 5:30)" % clock(p.first("sell_batch")))

	var last := line_at
	var longest := 0.0
	for entry in p.events:
		if entry[0] >= line_at and String(entry[1]).begins_with("upgrade"):
			longest = maxf(longest, entry[0] - last)
			last = entry[0]
	longest = maxf(longest, MINUTES * 60.0 - last)
	criterion("F6", longest <= 90.0, "longest wait between purchases after the line: %.0f s (at most 90)" % longest)

	var idle := minute_from(g, 0.0)
	var tapping := minute_from(g, p.taps_per_second)
	criterion("F7", idle >= 18.0, "factory alone earns £%.2f a minute at 15:00 (at least £18)" % idle)
	var lift := (tapping - idle) / idle if idle > 0.0 else INF
	criterion("F8", lift >= 0.25, "tapping adds %.0f%% (at least 25%%): £%.2f vs £%.2f a minute" % [lift * 100.0, tapping, idle])

	for failure in failures:
		printerr("FAIL: ", failure)
	print("%s: pacing tests (%d criteria)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


## Cash earned in the next minute from a copy of g, by a player tapping at the
## given rate who otherwise sells and buys nothing more.
func minute_from(g: Game, taps_per_second: float) -> float:
	var c := Game.new()
	c.load_state(JSON.parse_string(JSON.stringify(g.to_state(), "", false, true)))
	var p := Player.new()
	p.taps_per_second = taps_per_second
	p.buys = false
	var start: float = c.stats.cash_earned
	for i in roundi(60.0 / T.TICK_SECONDS):
		p.step(c)
		c.tick()
	c.sell_batch()
	return c.stats.cash_earned - start
