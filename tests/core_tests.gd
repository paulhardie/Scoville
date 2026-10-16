extends SceneTree
## The core rules (docs/CORE.md): picking, heat and Flash Boil, selling,
## bottling, upgrades, automation, determinism and saves.

const Game = preload("res://src/core/game.gd")
const G = preload("res://src/core/guesses.gd")

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
	print("%s: core tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


## A game past the opening: kitchen and upgrades open, with cash to spend.
func opened(cash: float = 1000.0) -> Game:
	var g := Game.new(7)
	g.unlocked.bottling = true
	g.unlocked.upgrades = true
	g.cash = cash
	return g


func test_tap_picks_one_or_a_crit() -> void:
	var seen := {}
	var g := Game.new(1)
	for i in 200:
		var before := g.bell
		var picked := g.tap()
		check(close(g.bell - before, picked), "tap adds what it reports")
		seen[picked] = true
		g.heat = 0.0  # keep Flash Boil out of it
	check(seen.keys().all(func(k): return k == 1 or k == 3), "a plain tap picks 1, a crit 3: %s" % str(seen.keys()))
	check(seen.has(1) and seen.has(3), "both plain taps and crits happen in 200 taps")


func test_shears_add_to_each_tap() -> void:
	var g := Game.new(1)
	g.levels.shears = 2
	check(g.tap_yield() == 3, "two shears make a tap pick 3 before crits")


func test_heat_fills_in_19_taps_and_boils() -> void:
	var g := Game.new(2)
	for i in 18:
		g.tap()
	check(not g.is_boiling(), "18 taps don't boil (heat %.1f)" % g.heat)
	g.tap()
	check(g.is_boiling(), "the 19th tap starts Flash Boil")
	check(g.stats.boils == 1, "a boil is counted")
	var heat := g.heat
	g.tap()
	check(g.heat == heat, "taps add no heat while boiling")


func test_boil_multiplies_taps_then_resets_heat() -> void:
	var g := Game.new(3)
	g.heat = G.HEAT_MAX - G.HEAT_PER_TAP
	g.tap()
	check(g.is_boiling(), "topping up heat boils")
	var picked := g.tap()
	check(picked == 5 or picked == 15, "a boiling tap picks 5, or 15 on a crit: %d" % picked)
	g.advance(roundi(G.BOIL_SECONDS / G.TICK_SECONDS) - 1)
	check(g.is_boiling(), "still boiling one tick before the end")
	g.tick()
	check(not g.is_boiling() and g.heat == 0.0, "boil ends after 10 s with heat at zero")


func test_heat_decays_when_not_boiling() -> void:
	var g := Game.new(4)
	g.heat = 50.0
	g.advance(10)
	check(close(g.heat, 50.0 - 10 * G.HEAT_DECAY_PER_TICK), "heat drops 1.2 a tick: %.2f" % g.heat)
	g.advance(1000)
	check(g.heat == 0.0, "heat stops at zero")


func test_kitchen_opens_at_20_peppers() -> void:
	var g := Game.new(5)
	check(not g.bottle_table(), "can't bottle before the kitchen opens")
	while g.stats.peppers < G.BOTTLING_UNLOCK_PEPPERS:
		check(not g.unlocked.bottling, "kitchen still shut under 20 peppers")
		g.tap()
	check(g.unlocked.bottling, "kitchen opens at 20 peppers picked")


func test_selling_loose() -> void:
	var g := Game.new(6)
	g.bell = 40.0
	g.jalapeno = 4
	check(g.sell_loose_bell() and close(g.cash, 2.0) and g.bell == 0.0, "40 bell sell for $2.00")
	check(g.sell_loose_jalapeno() and close(g.cash, 3.4) and g.jalapeno == 0, "4 jalapeños sell for $1.40")
	check(not g.sell_loose_bell() and not g.sell_loose_jalapeno(), "nothing to sell does nothing")
	check(close(g.stats.revenue, 3.4), "revenue counts loose sales")


func test_bottling_sells_and_opens_upgrades() -> void:
	var g := Game.new(7)
	g.unlocked.bottling = true
	g.bell = 25.0
	check(not g.unlocked.upgrades, "upgrades start shut")
	check(g.bottle_table(), "25 bell bottle a Table Sauce")
	check(close(g.bell, 5.0) and close(g.cash, 2.5) and g.bottles.table == 1, "it uses 20 bell and earns $2.50")
	check(g.unlocked.upgrades, "the first bottle opens upgrades")
	check(not g.bottle_table(), "5 bell can't bottle")
	g.jalapeno = 15
	check(not g.bottle_smoky(), "no Smoky Sauce before the jalapeño patch")
	g.unlocked.jalapeno = true
	check(g.bottle_smoky() and g.jalapeno == 0 and close(g.cash, 17.5), "15 jalapeños bottle a $15 Smoky Sauce")
	check(g.stats.bottles == 2, "both bottles are counted")


func test_upgrade_costs_grow() -> void:
	var g := opened()
	check(close(g.cost("capper"), 10.0) and close(g.cost("picker"), 25.0) and close(g.cost("shears"), 15.0), "starting prices")
	check(g.buy("shears") and g.levels.shears == 1, "buys shears")
	check(close(g.cost("shears"), 22.5), "shears grow ×1.5")
	check(close(g.cash, 985.0), "the price was paid")
	check(not g.buy("rocket"), "unknown upgrades don't buy")


func test_upgrades_need_cash_and_the_kitchen() -> void:
	var g := Game.new(8)
	g.cash = 1000.0
	check(not g.buy("shears"), "can't buy before the first bottle")
	var poor := opened(5.0)
	check(not poor.buy("capper") and poor.levels.capper == 0 and poor.cash == 5.0, "can't buy without the cash")


func test_jalapeno_patch_is_one_off() -> void:
	var g := opened()
	check(g.buy("jalapeno") and g.unlocked.jalapeno and close(g.cash, 900.0), "the patch costs $100")
	check(not g.buy("jalapeno") and close(g.cash, 900.0), "it can't be bought twice")
	var got := 0
	for i in 200:
		g.heat = 0.0
		var before := g.jalapeno
		g.tap()
		got += g.jalapeno - before
	check(got > 40 and got < 100, "about 35%% of taps pick a jalapeño: %d of 200" % got)


func test_pickers_pick_by_themselves() -> void:
	var g := opened()
	g.buy("picker")
	g.buy("picker")
	g.advance(roundi(10.0 / G.TICK_SECONDS))
	check(close(g.bell, 40.0, 1e-6), "two pickers pick 40 in 10 s: %.4f" % g.bell)


func test_capper_bottles_by_itself() -> void:
	var g := opened()
	g.buy("capper")
	check(g.capper_interval_ticks() == 30, "level 1 bottles every 3.0 s (4 / 1.35 rounded up to a tick)")
	g.bell = 45.0
	var cash := g.cash
	g.advance(29)
	check(g.bottles.table == 0, "nothing before the interval")
	g.tick()
	check(g.bottles.table == 1 and close(g.cash, cash + G.TABLE_SAUCE_PRICE), "bottles one at 3 s")
	g.advance(60)
	check(g.bottles.table == 2, "skips a bottle without 20 peppers: %d" % g.bottles.table)
	g.levels.capper = 50
	check(g.capper_interval_ticks() == 8, "never faster than 0.8 s")


func test_same_seed_same_game() -> void:
	var a := play(Game.new(42))
	var b := play(Game.new(42))
	check(JSON.stringify(a.to_state()) == JSON.stringify(b.to_state()), "the same seed and inputs give the same game")


func test_save_round_trip() -> void:
	var g := play(Game.new(9))
	var text := JSON.stringify(g.to_state(), "", false, true)
	var c := Game.new()
	var problem := c.load_state(JSON.parse_string(text))
	check(problem == "", "a save loads: " + problem)
	check(JSON.stringify(c.to_state()) == JSON.stringify(g.to_state()), "a loaded save matches what was saved")
	play(g)
	play(c)
	check(JSON.stringify(c.to_state()) == JSON.stringify(g.to_state()), "and plays on identically, crits included")


func test_bad_saves_are_refused() -> void:
	var g := Game.new(10)
	g.cash = 12.0
	check(g.load_state("nope") != "", "a non-object is refused")
	check(g.load_state({"version": 99}) != "", "a newer version is refused")
	var s := g.to_state()
	s.erase("levels")
	check(g.load_state(s) != "", "a save missing a field is refused")
	s = g.to_state()
	s.stats = 3
	check(g.load_state(s) != "", "a malformed field is refused")
	check(g.cash == 12.0, "a refused save changes nothing")


## Some minutes of play through the real actions.
func play(g: Game) -> Game:
	for i in 3000:
		g.tap()
		g.tick()
		g.bottle_table()
		g.bottle_smoky()
		for key in ["jalapeno", "capper", "picker", "shears"]:
			g.buy(key)
	return g
