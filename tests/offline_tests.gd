extends SceneTree
## Offline progress (docs/OFFLINE.md X1–X7).

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const Player = preload("res://src/sim/engaged_player.gd")
const Helpers = preload("res://tests/button_tests.gd")

var failures: Array[String] = []
var checks := 0
## The pacing player's states at 0:30, 1:00 and 1:40.
var states := {}


func _init() -> void:
	run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func close(a: float, b: float, eps: float = 1e-9) -> bool:
	return absf(a - b) <= eps * maxf(1.0, maxf(absf(a), absf(b)))


func run() -> void:
	var g := Game.new()
	var p := Player.new()
	for i in roundi(100 * 60 / T.TICK_SECONDS):
		p.step(g)
		g.tick()
		for m in [30, 60, 100]:
			if g.stats.ticks == roundi(m * 60 / T.TICK_SECONDS):
				states[m] = g.to_state()
	for method in get_method_list():
		if String(method.name).begins_with("test_"):
			call(method.name)
	for failure in failures:
		printerr("FAIL: ", failure)
	print("%s: offline tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


func loaded(minute: int) -> Game:
	var g := Game.new()
	var problem := g.load_state(JSON.parse_string(JSON.stringify(states[minute], "", false, true)))
	check(problem == "", "the %d-minute state loads: %s" % [minute, problem])
	return g


func seconds(s: float) -> int:
	return roundi(s / T.TICK_SECONDS)


func test_cap_and_speed() -> void:
	var g := Game.new()
	check(close(g.offline_cap(), 4 * 3600.0) and close(g.offline_speed(), 0.5), "X1/X2: 4 hours at 50% to start")
	var one: Game = Helpers.with(["night_shift_1"])
	check(close(one.offline_cap(), 6 * 3600.0) and close(one.offline_speed(), 0.6), "X1/X2: Night Shift I: 6 hours at 60%")
	var two: Game = Helpers.with(["night_shift_2"])
	check(close(two.offline_cap(), 8 * 3600.0) and close(two.offline_speed(), 0.7), "X1/X2: Night Shift II: 8 hours at 70%")
	var r := g.catch_up(10 * 3600.0)
	check(r.capped and close(r.counted, 4 * 3600.0) and close(r.offline, 2 * 3600.0), "X1: 10 hours away counts 4, run as 2")
	var back := Game.new()
	var before := JSON.stringify(back.to_state())
	var r2 := back.catch_up(-500.0)
	check(r2.away == 0.0 and JSON.stringify(back.to_state()) == before, "X1: a clock gone backwards counts as no time and changes nothing")


func test_short_absence_is_exact() -> void:
	# X3: up to 5 minutes of offline time runs the real factory tick by tick.
	var a := loaded(60)
	var b := loaded(60)
	var speed := a.offline_speed()
	a.catch_up(600.0)
	b.holding = false
	b.ticker = {"sauce": "", "mult": 1.0, "ends": 0, "next": -1}
	b.overdrive.until = 0
	b.advance(seconds(600.0 * speed))
	check(close(a.operation_value(), b.operation_value(), 1e-9) and a.stock == b.stock, "X3: 10 minutes away at %d%% is exactly 5 minutes of the factory" % roundi(speed * 100.0))


func test_long_absence_matches_ticks() -> void:
	# X3: two hours away against the same offline time run tick by tick. The
	# Market Ticker and Overdrive are held off in both, as D019 has them.
	for m in [30, 60, 100]:
		var fast := loaded(m)
		var slow := loaded(m)
		var speed := fast.offline_speed()
		var r := fast.catch_up(7200.0)
		var ov_before := slow.operation_value()
		slow.holding = false
		slow.ticker = {"sauce": "", "mult": 1.0, "ends": 0, "next": -1}
		slow.overdrive.until = 0
		slow.advance(seconds(7200.0 * speed))
		var want := slow.operation_value() - ov_before
		var diff := absf(r.ov - want) / want
		print("  X3: at %d:%02d, 2 h away: £%.0f against £%.0f tick by tick, %.2f%% off (%d steps of %.1f s)" % [m / 60, m % 60, r.ov, want, diff * 100.0, r.steps, r.step])
		check(diff <= 0.02, "X3: at %d:%02d, 2 h away gives £%.0f against £%.0f tick by tick (%.2f%% off, at most 2%%)" % [m / 60, m % 60, r.ov, want, diff * 100.0])


func test_safety() -> void:
	for m in [30, 60, 100]:
		var g := loaded(m)
		var research_before := g.research.size()
		var slots_before := [g.vats.size(), g.lines.size()]
		var levels_before := 0
		for crop in g.plots:
			levels_before += g.plots[crop].speed + g.plots[crop]["yield"] + g.plots[crop].quality
		var recipes_before := []
		for s in g.vats + g.lines:
			recipes_before.append(s.recipe)
		var cash_spent_check: float = g.cash
		g.catch_up(8 * 3600.0)
		var negative := false
		for item in g.stock:
			if g.stock[item] < 0:
				negative = true
		check(not negative, "X4: no stock below zero (%d min)" % m)
		check(g.research.size() == research_before and [g.vats.size(), g.lines.size()] == slots_before, "X4: nothing researched or bought (%d min)" % m)
		var recipes_after := []
		for s in g.vats + g.lines:
			recipes_after.append(s.recipe)
		check(recipes_after == recipes_before, "X4: nothing reassigned (%d min)" % m)
		check(g.cash >= cash_spent_check, "X4: cash only goes up (%d min)" % m)
		check(g.heat <= T.HEAT_MAX * 0.2, "X4: Heat has drained (%d min): %.0f" % [m, g.heat])
	var piston: Game = Helpers.with(["automated_piston"])
	var r := piston.catch_up(3600.0)
	check(piston.stats.presses > 0 and r.made.has("bell"), "X4: the Piston keeps pressing while away")


func test_timers() -> void:
	var g: Game = Helpers.with(["overdrive_turbines", "byproduct_recycling", "market_ticker", "bistro_blueprint"], 3)
	check(g.activate_overdrive(), "Overdrive pressed before leaving")
	var ready_at: int = g.overdrive.ready
	var start: int = g.stats.ticks
	g.catch_up(10 * 60.0)
	check(g.stats.ticks == start + seconds(600.0), "X5: the clock moves on by the whole 10 minutes")
	check(g.overdrive.ready == ready_at and not g.overdrive_active(), "X5: Overdrive's cooldown is 10 minutes on, and the boost is over")
	check(not g.can_overdrive(), "X5: 5 minutes of cooldown still to go")
	g.catch_up(5 * 60.0)
	check(g.can_overdrive(), "X5: and ready after 5 more: 15 minutes from the press")
	# The Market Ticker: spikes while away aren't paid, and the schedule holds.
	var a: Game = Helpers.with(["market_ticker", "bistro_blueprint"], 7)
	var b: Game = Helpers.with(["market_ticker", "bistro_blueprint"], 7)
	a.catch_up(6 * 3600.0)
	b.advance(seconds(6 * 3600.0))
	check(a.ticker.next == b.ticker.next and a.stats.spikes == b.stats.spikes, "X5: the next spike keeps the Ticker's schedule (%d spikes either way)" % a.stats.spikes)
	check(a.ticker.sauce == b.ticker.sauce and a.ticker.ends == b.ticker.ends, "X5: one still running on return carries on")


func test_deterministic() -> void:
	var a := loaded(100)
	var b := loaded(100)
	var ra := a.catch_up(5 * 3600.0)
	var rb := b.catch_up(5 * 3600.0)
	check(JSON.stringify(a.to_state()) == JSON.stringify(b.to_state()) and JSON.stringify(ra) == JSON.stringify(rb), "X6: the same save and time away give the same result")


func test_speed() -> void:
	var g := loaded(100)
	var t0 := Time.get_ticks_usec()
	var r := g.catch_up(8 * 3600.0)
	var spent := (Time.get_ticks_usec() - t0) / 1000000.0
	print("  X7: 8 hours away worked out in %.3f s (%d steps of %.1f s)" % [spent, r.steps, r.step])
	check(spent < 0.5, "X7: 8 hours away in under 0.5 s: %.3f s" % spent)
