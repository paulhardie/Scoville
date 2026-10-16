extends SceneTree
## The Tier 1 spine's rules (docs/FACTORY.md): the deck, buying stations, cycles,
## the Starter Crate, Sell Batch, upgrades, and the v1 → v2 save migration.

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func close(a: float, b: float, eps: float = 1e-9) -> bool:
	return absf(a - b) <= eps * maxf(1.0, maxf(absf(a), absf(b)))


func run() -> void:
	for method in get_method_list():
		if String(method.name).begins_with("test_"):
			call(method.name)
	for failure in failures:
		printerr("FAIL: ", failure)
	print("%s: factory tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


func seconds(s: float) -> int:
	return roundi(s / T.TICK_SECONDS)


## A game with the deck open and the given cash.
func opened(cash: float) -> Game:
	var g := Game.new()
	for i in 100:
		g.press()
	g.sell_raw()
	g.cash = cash
	return g


func test_deck_opens_at_ten_pounds() -> void:
	var g := Game.new()
	for i in 99:
		g.press()
	g.sell_raw()
	check(not g.revealed.deck, "no deck at £9.90 earned")
	check(not g.can_buy("plot") and not g.buy("plot"), "can't buy before the deck")
	g.press()
	g.sell_raw()
	check(g.revealed.deck, "the deck opens at £10 earned")
	g.buy("plot")
	check(g.revealed.deck, "it stays after spending")


func test_stations_are_offered_in_order() -> void:
	var g := opened(1000.0)
	check(g.is_offered("plot") and g.is_offered("vat"), "the plot and vat are offered with the deck")
	check(not g.is_offered("line") and not g.buy("line"), "the line isn't offered before the vat")
	check(g.buy("vat") and g.is_offered("line"), "buying the vat offers the line")
	check(not g.buy("vat"), "a station can't be bought twice")
	check(close(g.cash, 1000.0 - T.VAT_PRICE), "the vat's price was paid")


func test_plot_harvests() -> void:
	var g := opened(T.PLOT_PRICE)
	check(g.buy("plot") and g.cash == 0.0, "the plot costs £%.0f" % T.PLOT_PRICE)
	var before: int = g.stock.bell
	g.advance(seconds(10.0))
	check(g.stock.bell - before == 5, "1 pepper every 2 s: %d in 10 s" % (g.stock.bell - before))
	g.stations.plot.yield = 2
	before = g.stock.bell
	g.advance(seconds(10.0))
	check(g.stock.bell - before == 15, "yield 2 levels: 3 a cycle, %d in 10 s" % (g.stock.bell - before))


func test_vat_takes_ten_and_makes_mash() -> void:
	var g := opened(1000.0)
	g.stock.bell = 25
	g.buy("vat")
	check(g.stock.bell == 15 and g.stations.vat.running, "the vat takes 10 peppers at once")
	g.advance(seconds(T.VAT_CYCLE_SECONDS) - 1)
	check(g.stock.sweet_mash == 0, "no mash before the cycle ends")
	g.tick()
	check(g.stock.sweet_mash == 1 and g.stock.bell == 5, "1 mash after 8 s, and the next 10 taken")
	g.advance(seconds(T.VAT_CYCLE_SECONDS) * 3)
	check(g.stock.sweet_mash == 2 and not g.stations.vat.running, "it stops with under 10 peppers")
	check(g.stations.vat.progress == 0.0, "an idle vat holds no progress")


func test_line_and_starter_crate() -> void:
	var g := opened(1000.0)
	g.buy("vat")
	g.stock.sweet_mash = 60
	check(g.buy("line"), "buys the line")
	check(g.stations.line.crate == T.STARTER_CRATE_BOTTLES, "it comes with a Starter Crate of 50")
	var fast := T.LINE_CYCLE_SECONDS / T.STARTER_CRATE_SPEED
	check(close(g.cycle_seconds("line"), fast), "the crate runs at 10×")
	g.advance(seconds(fast * T.STARTER_CRATE_BOTTLES))
	check(g.stats.bottles_made == T.STARTER_CRATE_BOTTLES, "50 bottles in 40 s: %d" % g.stats.bottles_made)
	check(g.stations.line.crate == 0 and close(g.cycle_seconds("line"), T.LINE_CYCLE_SECONDS), "then base speed")
	g.advance(seconds(T.LINE_CYCLE_SECONDS))
	check(g.stats.bottles_made == T.STARTER_CRATE_BOTTLES + 1, "one more at base speed: %d" % g.stats.bottles_made)


func test_sell_batch() -> void:
	var g := Game.new()
	check(not g.sell_batch(), "nothing to sell")
	g.stock.table_mild = 7
	check(g.sell_batch() and close(g.cash, 35.0) and g.stock.table_mild == 0, "7 Table Mild sell for £35")
	check(g.stats.bottles_sold == 7 and close(g.stats.cash_earned, 35.0), "sales are counted")


func test_upgrades() -> void:
	var g := opened(10000.0)
	check(not g.buy_upgrade("plot", "speed"), "can't upgrade a station not owned")
	g.buy("plot")
	check(close(g.upgrade_cost("plot", "speed"), T.PLOT_SPEED_COST), "first speed level at base cost")
	check(g.buy_upgrade("plot", "speed") and g.stations.plot.speed == 1, "buys a speed level")
	check(close(g.upgrade_cost("plot", "speed"), T.PLOT_SPEED_COST * T.PLOT_SPEED_GROWTH), "the next costs more")
	check(close(g.cycle_seconds("plot"), T.PLOT_CYCLE_SECONDS / (1.0 + T.PLOT_SPEED_STEP)), "and the cycle is shorter")
	check(not g.buy_upgrade("vat", "yield") and not g.buy_upgrade("plot", "colour"), "unknown upgrades don't buy")
	var poor := opened(1.0)
	poor.cash = T.PLOT_PRICE
	poor.buy("plot")
	check(not poor.buy_upgrade("plot", "speed") and poor.stations.plot.speed == 0, "can't upgrade without the cash")


func test_whole_spine_runs() -> void:
	var g := opened(1000.0)
	for station in ["plot", "vat", "line"]:
		check(g.buy(station), "buys the " + station)
	g.advance(seconds(600.0))
	check(g.stats.bell_harvested > 0 and g.stats.mash_made > 0 and g.stats.bottles_made > 0, "peppers become mash become bottles")
	check(g.stats.mash_made * T.VAT_PEPPERS_IN <= g.stats.bell_harvested + 100, "the vat never makes mash from nothing")
	check(g.stats.bottles_made <= g.stats.mash_made, "the line never bottles from nothing")


func test_same_inputs_same_game() -> void:
	var a := opened(1000.0)
	var b := opened(1000.0)
	for g in [a, b]:
		for station in ["plot", "vat", "line"]:
			g.buy(station)
		for i in 3000:
			if i % 7 == 0:
				g.press()
			g.tick()
	check(JSON.stringify(a.to_state()) == JSON.stringify(b.to_state()), "deterministic")


func test_save_round_trip_mid_cycle() -> void:
	var g := opened(1000.0)
	for station in ["plot", "vat", "line"]:
		g.buy(station)
	g.advance(seconds(37.3))
	var c := Game.new()
	var problem := c.load_state(JSON.parse_string(JSON.stringify(g.to_state(), "", false, true)))
	check(problem == "", "a v2 save loads: " + problem)
	check(JSON.stringify(c.to_state()) == JSON.stringify(g.to_state()), "it matches what was saved")
	g.advance(seconds(60.0))
	c.advance(seconds(60.0))
	check(JSON.stringify(c.to_state()) == JSON.stringify(g.to_state()), "and plays on identically")


func test_v1_save_migrates() -> void:
	# A save as v0.1 wrote it: Stages 0–1 only.
	var v1 := {
		"version": 1, "cash": 12.5, "bell": 7,
		"revealed": {"counter": true, "status_bar": true},
		"stats": {"presses": 132, "bell_picked": 132, "cash_earned": 12.5},
	}
	var g := Game.new()
	var problem := g.load_state(v1)
	check(problem == "", "a v1 save loads: " + problem)
	check(close(g.cash, 12.5) and g.stock.bell == 7, "cash and peppers carry over")
	check(g.revealed.counter and g.revealed.status_bar, "reveals carry over")
	check(g.revealed.deck, "£12.50 earned opens the deck at once")
	check(g.stats.presses == 132 and close(g.stats.cash_earned, 12.5), "stats carry over")
	check(not g.stations.plot.owned and g.stock.sweet_mash == 0, "no stations or mash yet")
	var early := v1.duplicate(true)
	early.stats.cash_earned = 4.0
	var e := Game.new()
	e.load_state(early)
	check(not e.revealed.deck, "£4 earned keeps the deck shut")
	var broken := v1.duplicate(true)
	broken.erase("bell")
	check(Game.new().load_state(broken) != "", "a broken v1 save is refused")
