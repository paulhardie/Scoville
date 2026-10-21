extends SceneTree
## The factory's rules (docs/FACTORY.md): the deck, plots, vat and line slots,
## recipes (S1–S3), the Starter Crate, Sell Batch, upgrades, Operation Value
## (S5) and the save migrations (S4).

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


## A game past Stage 3 and the Tech Tree, with the Tier 2 blueprints researched.
func tier_2(cash: float = 100000.0) -> Game:
	var g := opened(cash)
	g.account.best_ov = T.TAB_THRESHOLDS.tech
	g.stock.table_mild = 1000
	g.stock.sweet_mash = 100
	for node in ["jalapeno_blueprint", "verde_blueprint", "vinegar_blueprint", "brine_blueprint", "bistro_blueprint"]:
		check(g.research_node(node), "researches " + node)
	g.stock.table_mild = 0
	g.stock.sweet_mash = 0
	return g


func test_deck_opens_at_stage_2_cash() -> void:
	var g := Game.new()
	for i in 99:
		g.press()
	g.sell_raw()
	check(not g.revealed.deck, "no deck at $%.2f earned" % g.stats.cash_earned)
	check(not g.buy_plot("bell"), "can't buy before the deck")
	g.press()
	g.sell_raw()
	check(g.revealed.deck, "the deck opens at $%.0f earned" % T.STAGE_2_CASH)
	g.buy_plot("bell")
	check(g.revealed.deck, "it stays after spending")


func test_tier_1_offered_in_order() -> void:
	var g := opened(1000.0)
	check(g.plot_offered("bell") and g.slot_offered("vat"), "the plot and first vat are offered with the deck")
	check(not g.slot_offered("line") and not g.buy_slot("line"), "the line isn't offered before a vat")
	check(g.buy_slot("vat") and g.slot_offered("line"), "buying a vat offers the line")
	check(not g.slot_offered("vat"), "no second vat before Stage 3")
	check(close(g.cash, 1000.0 - g.data.slots.vat.prices[0]), "vat slot 1 costs its listed price")
	check(not g.plot_offered("vinegar") and not g.buy_plot("vinegar"), "no Vinegar Cask without its blueprint")


func test_plot_harvests() -> void:
	var price: float = Game.new().plot_price("bell")
	var cycle: float = Game.new().data.plots.bell.seconds
	var g := opened(price)
	check(g.buy_plot("bell") and g.cash == 0.0, "the plot costs its listed $%.0f" % price)
	check(not g.buy_plot("bell"), "a plot can't be bought twice")
	var before: int = g.stock.bell
	g.advance(seconds(10.0))
	var cycles := roundi(10.0 / cycle)
	check(g.stock.bell - before == cycles, "1 pepper every %.1f s: %d in 10 s" % [cycle, g.stock.bell - before])
	g.plots.bell["yield"] = 50   # 1 × (1 + 50 × 6%): 4 a cycle (D041)
	before = g.stock.bell
	g.advance(seconds(10.0))
	check(g.stock.bell - before == roundi(g.plot_yield_exact("bell")) * cycles, "yield 50 levels: %d a cycle, %d in 10 s" % [roundi(g.plot_yield_exact("bell")), g.stock.bell - before])


func test_vat_takes_ten_and_makes_mash() -> void:
	var g := opened(1000.0)
	g.stock.bell = 25
	g.buy_slot("vat")
	check(g.vats[0].recipe == "sweet_mash", "a new vat starts on Sweet Pepper Mash")
	check(g.stock.bell == 15 and g.vats[0].running, "S1: it takes 10 peppers at once")
	g.advance(seconds(8.0) - 1)
	check(g.stock.sweet_mash == 0, "no mash before the cycle ends")
	g.tick()
	check(g.stock.sweet_mash == 1 and g.stock.bell == 5, "S1: 1 mash after 8 s, and the next 10 taken")
	g.advance(seconds(8.0) * 3)
	check(g.stock.sweet_mash == 2 and not g.vats[0].running, "it stops with under 10 peppers")
	check(g.vats[0].progress == 0.0, "an idle vat holds no progress")


func test_line_and_starter_crate() -> void:
	var g := opened(1000.0)
	g.buy_slot("vat")
	g.stock.sweet_mash = 60
	check(g.buy_slot("line"), "buys the line")
	check(g.lines[0].crate == T.STARTER_CRATE_BOTTLES, "it comes with a Starter Crate of 50")
	check(close(g.slot_cycle("line", 0), 0.8), "the crate runs at 10×")
	g.advance(seconds(0.8 * T.STARTER_CRATE_BOTTLES))
	check(g.stats.made.table_mild == T.STARTER_CRATE_BOTTLES, "50 bottles in 40 s: %d" % g.stats.made.table_mild)
	check(g.lines[0].crate == 0 and close(g.slot_cycle("line", 0), 8.0), "then base speed")
	g.advance(seconds(8.0))
	check(g.stats.made.table_mild == T.STARTER_CRATE_BOTTLES + 1, "one more at base speed")


func test_sell_batch() -> void:
	var g := Game.new()
	check(not g.sell_batch(), "nothing to sell")
	g.stock.table_mild = 7
	g.stock.bistro_verde = 2
	var seven: float = 7 * g.value("table_mild")
	check(g.sell_batch("table_mild") and close(g.cash, seven) and g.stock.bistro_verde == 2, "sells one sauce: 7 Table Mild for $%.0f" % seven)
	g.stock.table_mild = 1
	check(g.sell_batch() and close(g.cash, seven + g.value("table_mild") + 2 * g.value("bistro_verde")) and g.bottles_held() == 0, "or every bottle")
	check(g.stats.sold.table_mild == 8 and g.stats.sold.bistro_verde == 2, "sales are counted")


func test_upgrades() -> void:
	var g := opened(10000.0)
	check(not g.upgrade_plot("bell", "speed"), "can't upgrade a plot not owned")
	g.buy_plot("bell")
	var first: float = g.plot_price("bell") * T.PLOT_UPGRADE_SHARE
	check(close(g.plot_upgrade_cost("bell", "speed"), first), "first speed level at %.0f%% of the plot's price" % (T.PLOT_UPGRADE_SHARE * 100.0))
	check(g.upgrade_plot("bell", "speed") and g.plots.bell.speed == 1, "buys a speed level")
	check(close(g.plot_upgrade_cost("bell", "speed"), first * T.PLOT_UPGRADE_GROWTH), "the next costs more")
	check(close(g.plot_cycle("bell"), g.data.plots.bell.seconds / (1.0 + T.PLOT_SPEED_STEP)), "and the cycle is shorter")
	check(not g.upgrade_plot("bell", "colour"), "unknown upgrades don't buy")
	g.buy_slot("vat")
	check(close(g.slot_upgrade_cost("vat", 0), T.VAT_SPEED_COST), "vat 1's speed at base cost")
	check(g.upgrade_slot("vat", 0) and close(g.slot_cycle("vat", 0), 8.0 / 1.25), "a vat speed level")
	check(not g.upgrade_slot("vat", 1), "no slot 2 to upgrade")


func test_upgrades_scale_with_price() -> void:
	var g := tier_2()
	check(g.buy_plot("jalapeno"), "buys the Jalapeño Plot")
	g.buy_slot("vat")
	g.buy_slot("vat")
	var prices: Array = g.data.slots.vat.prices
	check(close(g.slot_upgrade_cost("vat", 1), T.VAT_SPEED_COST * pow(prices[1] / T.VAT_PRICE_REFERENCE, T.COST_SCALE_POWER)), "vat slot 2's speed costs the vat curve × (price ÷ the $%.0f reference)^%.1f" % [T.VAT_PRICE_REFERENCE, T.COST_SCALE_POWER])


func test_slot_caps() -> void:
	var g := opened(100000.0)
	g.account.best_ov = T.TAB_THRESHOLDS.processing
	for i in 3:
		check(g.buy_slot("vat"), "buys vat slot %d" % (i + 1))
	check(g.slot_cap("vat") == 3 and not g.slot_offered("vat") and not g.buy_slot("vat"), "S3: no fourth vat before Slot Expansion")
	for i in 2:
		check(g.buy_slot("line"), "buys line slot %d" % (i + 1))
	check(not g.buy_slot("line"), "S3: no third line")
	check(g.lines[1].crate == 0, "only the first line has a Starter Crate")
	var spent := 0.0
	for station in ["vat", "line"]:
		for i in g.data.slots[station].base_cap:
			spent += g.data.slots[station].prices[i]
	check(close(g.cash, 100000.0 - spent), "each slot costs its listed price")


func test_recipes_need_blueprints() -> void:
	var g := opened(100000.0)
	g.account.best_ov = T.TAB_THRESHOLDS.tech
	g.buy_slot("vat")
	check(g.recipes_for("vat") == ["sweet_mash"], "only Sweet Pepper Mash at first")
	check(not g.assign("vat", 0, "verde_mash") and g.vats[0].recipe == "sweet_mash", "S1: can't run a recipe not researched")
	var t := tier_2()
	check(t.recipes_for("vat") == ["sweet_mash", "pickled_brine", "verde_mash"], "the blueprints add Tier 2's mashes")
	check(t.recipes_for("line") == ["table_mild", "bistro_verde"], "and Bistro Verde")


func test_tier_2_spine() -> void:
	var g := tier_2()
	g.stock.jalapeno = 15
	g.stock.vinegar = 10
	g.stock.bell = 5
	g.buy_slot("vat")
	g.buy_slot("vat")
	check(g.assign("vat", 0, "verde_mash") and g.assign("vat", 1, "pickled_brine"), "assigns Verde and Brine")
	check(g.stock.jalapeno == 0 and g.stock.vinegar == 0 and g.stock.bell == 0, "S1: each takes exactly its inputs")
	g.advance(seconds(12.0))
	check(g.stock.verde_mash == 1 and g.stock.pickled_brine == 1, "S1: 1 Verde Mash in 12 s, 1 Pickled Brine in 10 s")
	g.buy_slot("line")
	g.assign("line", 0, "bistro_verde")
	check(g.stock.verde_mash == 0 and g.stock.pickled_brine == 0, "S1: Bistro Verde takes one of each")
	g.lines[0].crate = 0
	g.lines[0].progress = 0.0
	g.advance(seconds(12.0))
	check(g.stock.bistro_verde == 1 and close(g.value("bistro_verde"), 425.0), "S1: a $425 Bistro Verde after 12 s")


func test_switching_returns_inputs() -> void:
	var g := tier_2()
	g.stock.bell = 10
	g.buy_slot("vat")
	g.advance(seconds(5.0))
	check(g.vats[0].running and g.stock.bell == 0, "mid-cycle on Sweet Pepper Mash")
	check(g.assign("vat", 0, ""), "switches it off")
	check(g.stock.bell == 10 and not g.vats[0].running and g.vats[0].progress == 0.0, "S2: the 10 peppers come back; the progress is lost")
	g.advance(seconds(20.0))
	check(g.stock.sweet_mash == 0 and g.stock.bell == 10, "an off slot does nothing")
	g.assign("vat", 0, "sweet_mash")
	check(g.vats[0].running and g.stock.bell == 0, "switched back on, it starts again")


func test_operation_value() -> void:
	var g := tier_2()
	g.stock.bell = 13
	g.stock.verde_mash = 2
	g.stock.bistro_verde = 3
	var expect: float = g.stats.cash_earned + 13 * g.value("bell") + 2 * g.value("verde_mash") + 3 * g.value("bistro_verde")
	check(close(g.operation_value(), expect), "S5: cash earned + stock at its values: $%.2f" % g.operation_value())
	var before := g.operation_value()
	g.cash -= 500.0
	check(close(g.operation_value(), before), "S5: spending doesn't lower it")
	g.sell_batch()
	check(close(g.operation_value(), before), "S5: selling at value doesn't change it")
	var h := opened(1000.0)
	h.buy_plot("bell")
	h.buy_slot("vat")
	h.buy_slot("line")
	for i in seconds(300.0):
		h.tick()
		if i % 97 == 0:
			var sum: float = h.stats.cash_earned
			for item in h.stock:
				sum += h.stock[item] * h.value(item)
			check(close(h.operation_value(), sum), "S5: holds while running (tick %d)" % i)
	check(h.account.best_ov >= h.operation_value(), "the account keeps the best")


func test_values_follow_d004() -> void:
	# Every bottle is worth 5× the raw value inside it and every mash 2× its
	# inputs (D004), worked out from the recipes themselves.
	var g := Game.new()
	for id in g.data.recipes:
		var r: Dictionary = g.data.recipes[id]
		var inputs := 0.0
		for item in r.inputs:
			inputs += r.inputs[item] * g.value(item)
		if r.station == "vat":
			check(close(g.value(r.output), 2.0 * inputs, 1e-6), "D004: %s is 2× its inputs" % r.output)
		else:
			check(close(g.value(r.output), 5.0 * raw_value(g, r.output), 0.01), "D004: %s is 5× its raw value (%.2f)" % [r.output, raw_value(g, r.output)])


## The raw value inside an item: crops at their value, bottles used as inputs at
## their sale value (D004).
func raw_value(g: Game, item: String) -> float:
	var kind: String = g.data.items[item].kind
	if kind == "crop":
		return g.value(item)
	for id in g.data.recipes:
		var r: Dictionary = g.data.recipes[id]
		if r.output == item:
			var v := 0.0
			for input in r.inputs:
				var k: String = g.data.items[input].kind
				v += r.inputs[input] * (g.value(input) if k == "bottle" else raw_value(g, input))
			return v
	return 0.0


func test_whole_spine_runs() -> void:
	var g := opened(1000.0)
	check(g.buy_plot("bell") and g.buy_slot("vat") and g.buy_slot("line"), "buys the Tier 1 spine")
	g.advance(seconds(600.0))
	check(g.stats.harvested.bell > 0 and g.stats.made.sweet_mash > 0 and g.stats.made.table_mild > 0, "peppers become mash become bottles")
	check(g.stats.made.sweet_mash * 10 <= g.stats.harvested.bell + 100, "the vat never makes mash from nothing")
	check(g.stats.made.table_mild <= g.stats.made.sweet_mash, "the line never bottles from nothing")


func test_same_inputs_same_game() -> void:
	var a := tier_2()
	var b := tier_2()
	for g in [a, b]:
		g.buy_plot("bell")
		g.buy_plot("jalapeno")
		g.buy_slot("vat")
		g.buy_slot("vat")
		g.assign("vat", 1, "verde_mash")
		for i in 3000:
			if i % 7 == 0:
				g.press()
			g.tick()
	check(JSON.stringify(a.to_state()) == JSON.stringify(b.to_state()), "deterministic")


func test_save_round_trip_mid_cycle() -> void:
	var g := tier_2()
	g.buy_plot("bell")
	g.buy_plot("jalapeno")
	g.buy_slot("vat")
	g.buy_slot("vat")
	g.assign("vat", 1, "verde_mash")
	g.buy_slot("line")
	g.advance(seconds(37.3))
	var c := Game.new()
	var problem := c.load_state(JSON.parse_string(JSON.stringify(g.to_state(), "", false, true)))
	check(problem == "", "a v3 save loads: " + problem)
	check(JSON.stringify(c.to_state()) == JSON.stringify(g.to_state()), "it matches what was saved")
	g.advance(seconds(60.0))
	c.advance(seconds(60.0))
	check(JSON.stringify(c.to_state()) == JSON.stringify(g.to_state()), "and plays on identically")


func test_bad_v3_saves_are_refused() -> void:
	var g := tier_2()
	g.buy_slot("vat")
	var before := JSON.stringify(g.to_state())
	var s := g.to_state()
	s.run.vats[0].recipe = "table_mild"
	check(g.load_state(s) != "", "a vat running a line recipe is refused")
	s = g.to_state()
	s.run.stock["unobtainium"] = 3
	check(g.load_state(s) != "", "an unknown item is refused")
	s = g.to_state()
	s.run.research.append("time_machine")
	check(g.load_state(s) != "", "unknown research is refused")
	s = g.to_state()
	s.run.vats = [{}, {}, {}, {}]
	check(g.load_state(s) != "", "more slots than the cap are refused")
	check(JSON.stringify(g.to_state()) == before, "a refused save changes nothing")


## A save as v0.2 wrote it, mid-game: plot, vat and line, crate half used.
func v2_save() -> Dictionary:
	return {
		"version": 2, "cash": 41.5,
		"stock": {"bell": 23, "sweet_mash": 2, "table_mild": 6},
		"revealed": {"counter": true, "status_bar": true, "deck": true},
		"stations": {
			"plot": {"owned": true, "speed": 3, "yield": 1, "progress": 0.7},
			"vat": {"owned": true, "speed": 2, "progress": 3.2, "running": true},
			"line": {"owned": true, "speed": 1, "progress": 0.3, "running": true, "crate": 21},
		},
		"stats": {"presses": 900, "bell_picked": 900, "bell_harvested": 1500, "mash_made": 210,
			"bottles_made": 200, "bottles_sold": 194, "cash_earned": 1100.0, "ticks": 6000},
	}


func test_v2_save_migrates() -> void:
	var g := Game.new()
	var problem := g.load_state(v2_save())
	check(problem == "", "S4: a v2 save loads: " + problem)
	check(close(g.cash, 41.5 * T.SAVE_V8_MONEY) and g.stock.bell == 23 and g.stock.table_mild == 6, "S4: cash and stock carry over")
	# v2's speed 3 (+45%) and yield 1 (+1 a harvest), in v9's levels (D041).
	check(g.plots.bell.owned and g.plot_cycle("bell") <= g.data.plots.bell.seconds / 1.45 + 1e-9 and g.plot_yield_exact("bell") >= 2.0 - 1e-9, "S4: the plot and its levels")
	check(g.vats.size() == 1 and g.vats[0].recipe == "sweet_mash" and g.vats[0].speed == 2 and g.vats[0].running, "S4: the vat is vat slot 1 on Sweet Pepper Mash")
	check(g.lines.size() == 1 and g.lines[0].recipe == "table_mild" and g.lines[0].crate == 21, "S4: the line is line slot 1, crate kept")
	check(g.stats.made.table_mild == 200 and g.stats.sold.table_mild == 194 and close(g.stats.cash_earned, 1100.0 * T.SAVE_V8_MONEY), "S4: stats carry over, money ×10 (D035)")
	# v8: pounds became dollars ×10; the stock is valued at today's values.
	var ov: float = 1100.0 * T.SAVE_V8_MONEY + 23 * g.value("bell") + 2 * g.value("sweet_mash") + 6 * g.value("table_mild")
	check(close(g.account.best_ov, ov), "S4: the account starts at the run's Operation Value, $%.2f: $%.2f" % [ov, g.account.best_ov])
	check(g.tab_open("processing") and g.tab_open("tech"), "$%.0f opens Processing and the Tech Tree" % ov)


func test_v2_migration_produces_the_same() -> void:
	# The v2 rules, replayed by hand for 60 s from the same state, against the
	# migrated game: same peppers harvested, mash and bottles made (S4).
	var g := Game.new()
	g.load_state(v2_save())
	g.advance(seconds(60.0))
	# Production follows today's rules: the migrated levels at today's plot
	# speed and yield, at least v2's rate (D041 rounds levels up).
	var v2_rate := floori((60.0 + 0.7) / (g.data.plots.bell.seconds / 1.45) + 1e-6) * 2
	var harvested := floori(floori((60.0 + 0.7) / g.plot_cycle("bell") + 1e-6) * g.plot_yield_exact("bell") + 1e-6)
	var got: int = g.stats.harvested.bell - 1500
	check(got == harvested and got >= v2_rate, "S4: the migrated plot's rate: %d (want %d, at least v2's %d)" % [got, harvested, v2_rate])
	check(g.stats.made.sweet_mash > 210 and g.stats.made.table_mild > 200, "S4: the vat and line keep going")


func test_v1_save_migrates() -> void:
	var v1 := {
		"version": 1, "cash": 12.5, "bell": 7,
		"revealed": {"counter": true, "status_bar": true},
		"stats": {"presses": 132, "bell_picked": 132, "cash_earned": 12.5},
	}
	var g := Game.new()
	var problem := g.load_state(v1)
	check(problem == "", "a v1 save loads: " + problem)
	check(close(g.cash, 12.5 * T.SAVE_V8_MONEY) and g.stock.bell == 7 and g.revealed.deck, "cash (×10, D035), peppers and the deck carry over")
	check(g.stats.presses == 132 and g.vats.is_empty(), "stats, and no stations yet")
	var broken := v1.duplicate(true)
	broken.erase("bell")
	check(Game.new().load_state(broken) != "", "a broken v1 save is refused")


## A save as v0.3 wrote it: Tier 2 running, a vat mid-cycle, the Van researched.
func v3_save() -> Dictionary:
	return {
		"version": 3,
		"run": {
			"cash": 812.5,
			"stock": {"bell": 40, "jalapeno": 30, "vinegar": 12, "sweet_mash": 2, "pickled_brine": 1, "verde_mash": 1, "table_mild": 3, "bistro_verde": 0},
			"revealed": {"counter": true, "status_bar": true, "deck": true},
			"plots": {
				"bell": {"owned": true, "speed": 4, "yield": 2, "progress": 0.4},
				"jalapeno": {"owned": true, "speed": 1, "yield": 0, "progress": 1.1},
				"vinegar": {"owned": false, "speed": 0, "yield": 0, "progress": 0.0},
			},
			"vats": [
				{"recipe": "sweet_mash", "speed": 5, "progress": 2.0, "running": true},
				{"recipe": "verde_mash", "speed": 1, "progress": 0.0, "running": false},
			],
			"lines": [{"recipe": "table_mild", "speed": 3, "progress": 1.5, "running": true, "crate": 0}],
			"research": ["kitchen_table", "jalapeno_blueprint", "calloused_thumbs", "verde_blueprint", "delivery_van"],
			"autosell": {"table_mild": 50, "bistro_verde": 100},
			"autosell_acc": {"table_mild": 50, "bistro_verde": 0},
			"stats": {"presses": 4000, "bell_picked": 9000, "cash_earned": 3100.0, "ticks": 15000, "researched": 4,
				"harvested": {"bell": 8000, "jalapeno": 300}, "made": {"sweet_mash": 700, "table_mild": 650, "verde_mash": 10},
				"sold": {"table_mild": 600}, "consumed": {"bell": 7000}},
		},
		"account": {"best_ov": 3300.0},
	}


func test_v3_save_migrates() -> void:
	var g := Game.new()
	var problem := g.load_state(v3_save())
	check(problem == "", "S9: a v3 save loads: " + problem)
	check(close(g.cash, 812.5 * T.SAVE_V8_MONEY) and g.stock.jalapeno == 30 and g.autosell.table_mild == 50, "S9: cash, stock and sliders carry over")
	check(g.vats[0].running and g.vats[0].taken == {"bell": 10}, "S9: a running vat's taken inputs are its recipe's")
	check(g.heat == 0.0 and g.pin == "" and g.keep.is_empty() and g.plots.bell.quality == 0, "S9: new state starts empty")
	check(g.has_van() and g.tap_yield() == 3, "S9: research carries over, with its effects")
	var again := Game.new()
	again.load_state(v3_save())
	check(JSON.stringify(again.to_state()) == JSON.stringify(g.to_state()), "S9: the same save migrates the same way, random stream included")
	# Production goes on as v0.3's rules had it: the plot's harvests, by hand.
	g.advance(seconds(60.0))
	# The migrated levels at today's plot speed and yield, at least v0.3's rate.
	var v3_rate := floori((60.0 + 0.4) / (g.data.plots.bell.seconds / 1.6) + 1e-6) * 3
	var harvested := floori(floori((60.0 + 0.4) / g.plot_cycle("bell") + 1e-6) * g.plot_yield_exact("bell") + 1e-6)
	var got: int = g.stats.harvested.bell - 8000
	check(got == harvested and got >= v3_rate, "S9: the migrated Bell plot's rate: %d (want %d, at least v0.3's %d)" % [got, harvested, v3_rate])
	var sm_cycle := 8.0 / (1.0 + 0.25 * 5)
	check(g.stats.made.sweet_mash - 700 >= floori(60.0 / sm_cycle) - 1, "S9: the vat keeps going")
	var h := Game.new()
	h.load_state(v3_save())
	check(h.assign("vat", 0, "") and h.stock.bell == 50, "S9: switching the migrated vat off returns its 10 peppers")


func test_chances_are_deterministic() -> void:
	# S10: a game with every chance in play, played twice from the same seed,
	# and saved and reloaded halfway.
	var Helpers = load("res://tests/button_tests.gd")
	var a: Game = Helpers.with(["double_tap", "byproduct_recycling", "market_ticker", "ergonomic_grip"], 99)
	var b: Game = Helpers.with(["double_tap", "byproduct_recycling", "market_ticker", "ergonomic_grip"], 99)
	for g in [a, b]:
		g.cash = 1e6
		g.buy_plot("bell")
		g.upgrade_plot("bell", "quality")
		g.upgrade_plot("bell", "quality")
		g.buy_slot("vat")
		g.set_holding(true)
		g.advance(seconds(1800.0))
	check(a.stats.doubles > 0 and a.stats.free_levels > 0 and a.stats.spikes > 0, "every chance came up")
	check(JSON.stringify(a.to_state()) == JSON.stringify(b.to_state()), "S10: the same seed and inputs give the same game")
	var c := Game.new()
	check(c.load_state(JSON.parse_string(JSON.stringify(a.to_state(), "", false, true))) == "", "S10: a mid-game save loads")
	c.set_holding(true)
	a.advance(seconds(1800.0))
	c.advance(seconds(1800.0))
	check(JSON.stringify(c.to_state()) == JSON.stringify(a.to_state()), "S10: and plays on identically, chances included")
	var other: Game = Helpers.with(["double_tap"], 100)
	var same: Game = Helpers.with(["double_tap"], 99)
	for g in [other, same]:
		for i in 200:
			g.press()
	check(other.stats.doubles != same.stats.doubles or other.rng.state != same.rng.state, "a different seed gives different chances")


# --- v0.6d: Idle Planet Miner's early flow (ECONOMY.md, D041) ---------------

func test_starting_plots() -> void:
	var before := Game.new()
	check(not before.plot_offered("poblano") and not before.plot_offered("jalapeno"), "A1: nothing on sale before the deck shows")
	var g := opened(100000.0)
	var order := ["bell", "poblano", "jalapeno"]
	for crop in order:
		check(g.plot_offered(crop) and g.data.plots[crop].unlocked, "A1: the %s is on sale with the deck, no blueprint" % g.data.plots[crop].name)
	for crop in g.data.plots:
		if not crop in order:
			check(not g.plot_offered(crop), "A1: the %s still needs its blueprint" % g.data.plots[crop].name)
	for i in range(1, order.size()):
		check(g.plot_price(order[i]) > g.plot_price(order[i - 1]), "A1: the %s costs more than the %s" % [g.data.plots[order[i]].name, g.data.plots[order[i - 1]].name])
	for crop in ["poblano", "jalapeno"]:
		var plot: Dictionary = g.data.plots[crop]
		var payback: float = g.plot_price(crop) / (plot["yield"] / plot.seconds * g.value(crop))
		check(payback >= 300.0 and payback <= 600.0, "A1: the %s pays for itself raw in %.1f minutes (5–10)" % [plot.name, payback / 60.0])


func test_upgrade_curve() -> void:
	var g := opened(1e12)
	for crop in g.data.plots:
		g.plots[crop].owned = true
		for upgrade in g.PLOT_UPGRADES:
			var first: float = g.plot_price(crop) * 0.05
			var ok := close(g.plot_upgrade_cost(crop, upgrade), first)
			for lv in 4:
				ok = ok and absf(g.plot_upgrade_cost(crop, upgrade, lv + 1) / g.plot_upgrade_cost(crop, upgrade, lv) - 1.3) < 1e-9
			check(ok, "A2: %s %s: 5%% of the price, then ×1.3 a level" % [crop, upgrade])


func test_sell_any_crop() -> void:
	var g := opened(0.0)
	g.stock.poblano = 7
	g.stock.jalapeno = 3
	g.stock.bell = 2
	check(g.can_sell_crop("poblano") and g.sell_crop("poblano"), "A3: Poblano Peppers sell raw")
	check(g.stock.poblano == 0 and close(g.cash, 7 * g.value("poblano")), "A3: at their value")
	check(g.stock.jalapeno == 3 and g.stock.bell == 2, "A3: selling one crop leaves the others alone")
	check(not g.sell_crop("poblano") and not g.can_sell_crop("poblano"), "A3: nothing to sell with none held")
	g.stock.sweet_mash = 4
	check(not g.can_sell_crop("sweet_mash") and not g.sell_crop("sweet_mash"), "A3: only crops sell raw")
	var early := Game.new()
	early.stock.jalapeno = 5
	check(not early.sell_crop("jalapeno"), "A3: and not before the status bar")


func test_v8_plots_convert() -> void:
	# A v8 save with old levels: speed 3 (+45%), yield 2 (+2 crops), quality 10 (30%).
	var g := opened(0.0)
	g.buy_plot("jalapeno")
	var s: Dictionary = g.to_state()
	s.version = 8
	s.run.plots.jalapeno.speed = 3
	s.run.plots.jalapeno["yield"] = 2
	s.run.plots.jalapeno.quality = 10
	s.run.plots.jalapeno.erase("spare")
	var h := Game.new()
	check(h.load_state(JSON.parse_string(JSON.stringify(s))) == "", "A5: a v8 save loads")
	var p: Dictionary = h.plots.jalapeno
	var base: Dictionary = h.data.plots.jalapeno
	check(h.plot_cycle("jalapeno") <= base.seconds / 1.45 + 1e-9, "A5: at least as fast (%.3f s against %.3f)" % [h.plot_cycle("jalapeno"), base.seconds / 1.45])
	check(h.plot_yield_exact("jalapeno") >= base["yield"] + 2 - 1e-9, "A5: at least as productive (%.2f a harvest against %d)" % [h.plot_yield_exact("jalapeno"), base["yield"] + 2])
	check(h.quality_chance("jalapeno") >= 0.30 - 1e-9, "A5: as likely to double (%.0f%%)" % (h.quality_chance("jalapeno") * 100.0))
	check(p.speed <= 3 * 0.15 / T.PLOT_SPEED_STEP + 1 and h.to_state().version == Game.SAVE_VERSION, "A5: no more levels than it takes, saved as v%d" % Game.SAVE_VERSION)


func test_fractional_yield_carries() -> void:
	var g := opened(1000.0)
	g.buy_plot("bell")
	g.plots.bell["yield"] = 5   # 1 × (1 + 5 × step) a harvest
	var exact: float = g.plot_yield_exact("bell")
	var cycle: float = g.plot_cycle("bell")
	for i in roundi(100.0 * cycle / T.TICK_SECONDS):
		g.tick()
	check(absi(g.stats.harvested.bell - roundi(100.0 * exact)) <= 1, "a fractional yield carries: %d from 100 harvests of %.2f" % [g.stats.harvested.bell, exact])


func test_malformed_v8_plot_refused() -> void:
	var g := opened(0.0)
	var s: Dictionary = g.to_state()
	s.version = 8
	s.run.plots.bell = 5
	var h := Game.new()
	var problem := h.load_state(JSON.parse_string(JSON.stringify(s)))
	check(problem != "", "A5: a v8 save with a broken plot is refused, not crashed on: %s" % problem)
	s.run.plots.bell = {"owned": true, "speed": "fast"}
	check(Game.new().load_state(JSON.parse_string(JSON.stringify(s))) == "", "A5: a level that isn't a number reads as 0")

