extends SceneTree
## The factory's rules (docs/FACTORY.md, SKELETON.md): the deck, farms, vat and
## line slots, recipes (S1–S3), the kitchen, the Starter Crate, Sell Batch,
## slot upgrades, Operation Value as Galaxy Value (S5), selling raw (A3),
## determinism (S10) and old saves reaching v12 without loss (I11).

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


## A game with Processing and the Tech Tree open and the given cash.
func factory(cash: float = 1e9) -> Game:
	var g := opened(cash)
	g.account.best_ov = T.TAB_THRESHOLDS.tech
	return g


func test_on_sale_from_the_start() -> void:
	# D044 retires the deck's reveal at $100 earned.
	var g := Game.new()
	for i in 50:
		g.press()
	g.sell_raw()
	check(g.buy_plot("bell"), "the Bell Plot can be bought from the start, once cash covers it")


func test_tier_1_offered_in_order() -> void:
	var g := opened(1000.0)
	check(g.plot_offered("bell") and g.slot_offered("vat"), "the plot and first vat are offered with the deck")
	check(not g.slot_offered("line") and not g.buy_slot("line"), "the line isn't offered before a vat")
	check(g.buy_slot("vat") and g.slot_offered("line"), "buying a vat offers the line")
	check(not g.slot_offered("vat"), "no second vat before Processing opens")
	check(close(g.cash, 1000.0 - g.data.slots.vat.prices[0]), "vat slot 1 costs its listed price")
	check(not g.plot_offered("vinegar") and not g.buy_plot("vinegar"), "no Vinegar Cask before Land Survey 1")


func test_bell_plot() -> void:
	# The kitchen's Bell Plot (D052): IPM's Balor at four times the harvest
	# and cargo, so a Bell Pepper a second, its truck carrying 20 every 20 s.
	var price: float = Game.new().plot_price("bell")
	var g := opened(price)
	check(g.buy_plot("bell") and g.cash == 0.0, "the plot costs its listed $%.0f" % price)
	check(not g.buy_plot("bell"), "a plot can't be bought twice")
	check(close(g.harvest_rate("bell"), 1.0) and g.truck_cargo("bell") == 20 and close(g.trip_seconds("bell"), 20.0), "1 a second, 20 a trip, 20 s a trip")
	var before: int = g.stock.bell
	g.advance(seconds(60.0))
	check(g.stock.bell - before == 60, "60 Bell Peppers reach stock in 60 s: %d" % (g.stock.bell - before))


func test_vat_takes_ten_and_makes_mash() -> void:
	var g := opened(1000.0)
	g.stock.bell = 25
	g.buy_slot("vat")
	check(g.vats[0].recipe == "sweet_mash", "the kitchen vat starts on Sweet Pepper Mash")
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


func test_sell_any_item() -> void:
	# IPM sells any ore, bar or item (SKELETON.md); sell_item takes a count.
	var g := Game.new()
	g.stock.bell_puree = 5
	check(g.sell_item("bell_puree", 2) and g.stock.bell_puree == 3 and close(g.cash, 2 * g.value("bell_puree")), "two of five Bell Pepper Purée sell at their value")
	check(g.sell_item("bell_puree") and g.stock.bell_puree == 0, "the rest with no count")
	check(not g.sell_item("bell_puree"), "nothing to sell with none held")


func test_slot_upgrades() -> void:
	var g := opened(10000.0)
	g.buy_slot("vat")
	check(close(g.slot_upgrade_cost("vat", 0), T.VAT_SPEED_COST), "vat 1's speed at base cost")
	check(g.upgrade_slot("vat", 0) and close(g.slot_cycle("vat", 0), 8.0 / 1.25), "a vat speed level")
	check(not g.upgrade_slot("vat", 1), "no slot 2 to upgrade")


func test_slot_caps() -> void:
	var g := factory(1e40)
	for i in 11:
		check(g.buy_slot("vat"), "buys vat slot %d" % (i + 1))
	check(g.slot_cap("vat") == 11 and not g.slot_offered("vat") and not g.buy_slot("vat"), "S3: the kitchen's vat and IPM's ten smelters, no twelfth (T4)")
	for i in 11:
		check(g.buy_slot("line"), "buys line slot %d" % (i + 1))
	check(not g.buy_slot("line"), "S3: no twelfth line")
	check(g.lines[1].crate == 0, "only the first line has a Starter Crate")
	check(g.vats[1].recipe == "" and g.lines[1].recipe == "", "slots after the kitchen's start switched off")
	var spent := 0.0
	for station in ["vat", "line"]:
		for p in g.data.slots[station].prices:
			spent += p
	check(close(g.cash, 1e40 - spent, 1e-12), "each slot costs its listed price")


func test_recipes_are_bought() -> void:
	# D051: recipes are bought with cash at IPM's unlock prices.
	var g := factory(100000.0)
	g.buy_slot("vat")
	g.buy_slot("vat")
	check(g.recipe_unlocked("bell_puree") and not g.recipe_unlocked("pimento_mash"), "Bell Pepper Purée is free; Pimento Mash isn't")
	check(not g.assign("vat", 1, "pimento_mash") and g.vats[1].recipe == "", "S1: can't run a recipe not bought")
	var price: float = g.recipe_price("pimento_mash")
	check(close(price, 3000.0), "Pimento Mash costs $3,000 (IPM's Iron Bar)")
	var before := g.cash
	check(g.buy_recipe("pimento_mash") and close(g.cash, before - price) and g.recipe_unlocked("pimento_mash"), "buys it")
	check(not g.buy_recipe("pimento_mash"), "a recipe can't be bought twice")
	check(g.assign("vat", 1, "pimento_mash"), "then a vat runs it")
	g.cash = 0.0
	check(not g.buy_recipe("ancho_mash"), "not without the cash")


func test_kitchen_recipes_only_in_the_kitchen() -> void:
	# D052: Sweet Pepper Mash and Table Mild run only in the first vat and line,
	# which run nothing else (PR 3's T4).
	var g := factory()
	g.buy_slot("vat")
	g.buy_slot("vat")
	g.buy_slot("line")
	g.buy_slot("line")
	check(g.recipes_for("vat", 0).has("sweet_mash") and not g.recipes_for("vat", 1).has("sweet_mash"), "Sweet Pepper Mash only in vat 1")
	check(not g.assign("vat", 1, "sweet_mash") and not g.assign("line", 1, "table_mild"), "and Table Mild only in line 1")
	check(not g.assign("vat", 0, "bell_puree") and g.recipes_for("vat", 0) == ["sweet_mash"] and g.recipes_for("line", 0) == ["table_mild"], "T4: the kitchen's vat and line run only the kitchen's recipes")
	check(g.assign("vat", 1, "bell_puree"), "T4: IPM's free smelter, Vat 2, runs the rest")


func test_ipm_chain_runs() -> void:
	# S1: Bell Pepper Purée takes 1,000 Bell Peppers and makes one in 20 s;
	# Sweet Pepper Relish takes 5 of them (IPM's Copper Bar and Copper Wire).
	var g := factory()
	for i in 2:
		g.buy_slot("vat")
		g.buy_slot("line")
	g.lines[0].crate = 0
	g.assign("vat", 0, "")
	g.assign("line", 0, "")
	g.stock.bell = 1000
	check(g.assign("vat", 1, "bell_puree") and g.stock.bell == 0, "S1: the vat takes exactly 1,000 Bell Peppers")
	g.advance(seconds(20.0))
	check(g.stock.bell_puree == 1, "S1: one Purée after 20 s")
	g.stock.bell_puree = 5
	check(g.assign("line", 1, "sweet_pepper_relish") and g.stock.bell_puree == 0, "S1: Relish takes 5 Purée")
	g.advance(seconds(60.0))
	check(g.stock.sweet_pepper_relish == 1 and close(g.value("sweet_pepper_relish"), 10000.0), "S1: a $10,000 Relish after 60 s")


func test_switching_returns_inputs() -> void:
	var g := factory()
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
	# S5 (SKELETON.md): IPM's Galaxy Value: cash, what was spent, stock and
	# crops waiting at the farms.
	var g := factory(5000.0)
	g.stock.bell = 13
	g.stock.verde_mash = 2
	g.stock.bistro_verde = 3
	var expect: float = g.cash + g.stats.spent + 13 * g.value("bell") + 2 * g.value("verde_mash") + 3 * g.value("bistro_verde")
	check(close(g.operation_value(), expect), "S5: cash + spent + stock at its values: $%.2f" % g.operation_value())
	var before := g.operation_value()
	check(g.buy_plot("farm_02") and close(g.operation_value(), before), "S5: buying a farm doesn't lower it")
	check(g.buy_recipe("pimento_mash") and close(g.operation_value(), before), "S5: nor buying a recipe")
	g.sell_batch()
	check(close(g.operation_value(), before), "S5: selling at value doesn't change it")
	g.account.best_ov = T.TAB_THRESHOLDS.tech
	g.stock.table_mild = 100
	before = g.operation_value()
	check(g.research_node("calloused_thumbs") and close(g.operation_value(), before), "S5: research keeps its items' worth in it")
	var h := opened(1000.0)
	h.buy_plot("bell")
	h.buy_slot("vat")
	h.buy_slot("line")
	for i in seconds(300.0):
		h.tick()
		if i % 97 == 0:
			var sum: float = h.cash + h.stats.spent
			for item in h.stock:
				sum += h.stock[item] * h.appraisal(item)
			sum += h.field_total("bell") * h.value("bell")
			check(close(h.operation_value(), sum), "S5: holds while running (tick %d)" % i)
	check(h.account.best_ov >= h.operation_value(), "the account keeps the best")


func test_whole_spine_runs() -> void:
	var g := opened(1000.0)
	check(g.buy_plot("bell") and g.buy_slot("vat") and g.buy_slot("line"), "buys the kitchen")
	g.advance(seconds(600.0))
	check(g.stats.harvested.bell > 0 and g.stats.made.sweet_mash > 0 and g.stats.made.table_mild > 0, "peppers become mash become bottles")
	check(g.stats.made.sweet_mash * 10 <= g.stats.harvested.bell + 100, "the vat never makes mash from nothing")
	check(g.stats.made.table_mild <= g.stats.made.sweet_mash, "the line never bottles from nothing")


func test_same_inputs_same_game() -> void:
	var a := factory()
	var b := factory()
	for g in [a, b]:
		g.buy_plot("bell")
		g.buy_plot("farm_04")
		g.buy_slot("vat")
		g.buy_slot("vat")
		g.buy_recipe("ancho_mash")
		g.assign("vat", 1, "ancho_mash")
		for i in 3000:
			if i % 7 == 0:
				g.press()
			g.tick()
	check(JSON.stringify(a.to_state()) == JSON.stringify(b.to_state()), "deterministic")


func test_save_round_trip_mid_cycle() -> void:
	var g := factory()
	g.buy_plot("bell")
	g.buy_plot("farm_04")
	g.buy_slot("vat")
	g.buy_slot("vat")
	g.buy_recipe("ancho_mash")
	g.assign("vat", 1, "ancho_mash")
	g.buy_slot("line")
	g.advance(seconds(37.3))
	var c := Game.new()
	var problem := c.load_state(JSON.parse_string(JSON.stringify(g.to_state(), "", false, true)))
	check(problem == "", "a v12 save loads: " + problem)
	check(JSON.stringify(c.to_state()) == JSON.stringify(g.to_state()), "it matches what was saved")
	g.advance(seconds(60.0))
	c.advance(seconds(60.0))
	check(JSON.stringify(c.to_state()) == JSON.stringify(g.to_state()), "and plays on identically")


func test_bad_saves_are_refused() -> void:
	var g := factory()
	g.buy_slot("vat")
	g.buy_plot("farm_02")
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
	s.run.bought.append("perpetual_motion")
	check(g.load_state(s) != "", "an unknown recipe bought is refused")
	s = g.to_state()
	s.run.plots.farm_02.field["unobtainium"] = 4
	check(g.load_state(s) != "", "an unknown crop in a field is refused")
	s = g.to_state()
	s.run.vats = []
	for i in g.slot_cap("vat") + 1:
		s.run.vats.append({})
	check(g.load_state(s) != "", "more slots than the cap are refused")
	check(JSON.stringify(g.to_state()) == before, "a refused save changes nothing")


func test_chances_are_deterministic() -> void:
	# S10: a game with every chance in play, played twice from the same seed,
	# and saved and reloaded halfway.
	var Helpers = load("res://tests/button_tests.gd")
	var nodes := ["double_tap", "byproduct_recycling", "market_ticker", "ergonomic_grip", "bumper_crop_1"]
	var a: Game = Helpers.with(nodes, 99)
	var b: Game = Helpers.with(nodes, 99)
	for g in [a, b]:
		g.cash = 1e6
		g.buy_plot("bell")
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


func test_sell_any_crop() -> void:
	var g := opened(0.0)
	g.stock.poblano = 7
	g.stock.jalapeno = 3
	g.stock.bell = 2
	check(g.can_sell_crop("poblano") and g.sell_crop("poblano"), "A3: Poblanos sell raw")
	check(g.stock.poblano == 0 and close(g.cash, 7 * g.value("poblano")), "A3: at their value")
	check(g.stock.jalapeno == 3 and g.stock.bell == 2, "A3: selling one crop leaves the others alone")
	check(not g.sell_crop("poblano") and not g.can_sell_crop("poblano"), "A3: nothing to sell with none held")
	g.stock.sweet_mash = 4
	check(not g.can_sell_crop("sweet_mash") and not g.sell_crop("sweet_mash"), "A3: only crops sell with Sell (mash sells with sell_item)")


# --- Old saves reach v12 without loss (I11) -------------------------------------

## What every old save's migration owes (I11): cash at least the run's earnings
## (all spent cash came back), stock kept, best Operation Value kept.
func check_no_loss(g: Game, earned: float, best: float, stock: Dictionary, label: String) -> void:
	check(g.cash >= earned - 1e-6, "I11 %s: cash %.2f is at least the run's earnings %.2f" % [label, g.cash, earned])
	check(g.account.best_ov >= best - 1e-6, "I11 %s: the best Operation Value is kept" % label)
	var kept := true
	for item in stock:
		kept = kept and g.stock[item] >= stock[item]
	check(kept, "I11 %s: every item still in the game keeps at least its count" % label)
	check(g.vats.is_empty() and g.lines.is_empty() and not g.plots.bell.owned, "I11 %s: the factory came back as cash" % label)
	check(g.to_state().version == Game.SAVE_VERSION, "I11 %s: saved again as v%d" % [label, Game.SAVE_VERSION])


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
	check_no_loss(g, 1100.0 * T.SAVE_V8_MONEY, 0.0, {"bell": 23, "sweet_mash": 2, "table_mild": 6}, "v2")
	check(g.stock.bell == 23 + 10 and g.stock.sweet_mash == 2 + 1, "I11 v2: the running vat's and line's inputs come back")
	check(g.stats.made.table_mild == 200 and g.stats.sold.table_mild == 194, "S4: stats carry over")


func test_v1_save_migrates() -> void:
	var v1 := {
		"version": 1, "cash": 12.5, "bell": 7,
		"revealed": {"counter": true, "status_bar": true},
		"stats": {"presses": 132, "bell_picked": 132, "cash_earned": 12.5},
	}
	var g := Game.new()
	var problem := g.load_state(v1)
	check(problem == "", "a v1 save loads: " + problem)
	check(g.cash >= 12.5 * T.SAVE_V8_MONEY - 1e-9 and g.stock.bell == 7 and g.revealed.deck, "cash (×10, D035), peppers and the deck carry over")
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
	check_no_loss(g, 3100.0 * T.SAVE_V8_MONEY, 3300.0 * T.SAVE_V8_MONEY, {"jalapeno": 30, "vinegar": 12, "verde_mash": 1}, "v3")
	check(g.autosell.table_mild == 50, "S9: sliders carry over")
	check(g.has_van() and g.tap_yield() == 1 + g.data.tech.calloused_thumbs.effects[0].tap_yield, "S9: research that still exists carries over, with its effects (Calloused Thumbs)")
	check(not g.research.has("jalapeno_blueprint") and not g.research.has("verde_blueprint"), "I11 v3: removed blueprints are gone")
	# The two removed blueprints cost 3 + 10 Table Mild in v11; they come back.
	check(g.stock.table_mild >= 3 + 3 + 10, "I11 v3: their items come back (%d Table Mild)" % g.stock.table_mild)
	var again := Game.new()
	again.load_state(v3_save())
	check(JSON.stringify(again.to_state()) == JSON.stringify(g.to_state()), "S9: the same save migrates the same way, random stream included")


func test_v11_save_refunds() -> void:
	# I11: a v11 save, built by hand as v0.6 wrote it, mid-run with rooms.
	var s := v11_save()
	var g := Game.new()
	var problem := g.load_state(JSON.parse_string(JSON.stringify(s)))
	check(problem == "", "I11: a v11 save loads: " + problem)
	# Cash: every dollar earned plus Seed Capital Level 2's $5,000.
	check(close(g.cash, 50000.0 + 5000.0), "I11: cash is the run's earnings plus its starting cash ($%.2f)" % g.cash)
	check(g.stock.bell == 10 + 7 + 10 and g.stock.poblano == 3 and g.stock.jalapeno == 5 and g.stock.bistro_verde == 2, "I11: fields and the vat's inputs go to stock")
	# Removed: Jalapeño Cultivation (3 Table Mild), Slot Expansion I (40 Sweet Mash + 20 Verde).
	check(g.stock.table_mild == 3 and g.stock.sweet_mash == 40 and g.stock.verde_mash == 20, "I11: removed nodes give back their items")
	check(g.is_researched("delivery_van") and not g.is_researched("slot_expansion_1"), "I11: kept research stays")
	# Credits: 2 rooms (5 + 10), levels (2 for Seed Capital; 2 + 4 for the
	# Tasting Room), the paid draft (15), plus 4 held.
	check(g.account.credits == 4 + 15 + 2 + 6 + 15 and g.account.rooms.is_empty(), "I11: every room comes back as its credits (%d)" % g.account.credits)
	check(g.account.best_ov >= 90000.0 and g.account.prestiges == 1, "I11: the account's best Operation Value and sales kept")
	# A pin on a removed node goes with it rather than refusing the save.
	var pinned := v11_save()
	pinned.run.pin = "jalapeno_blueprint"
	var h := Game.new()
	problem = h.load_state(JSON.parse_string(JSON.stringify(pinned)))
	check(problem == "" and h.pin == "", "I11: a v11 save pinning a removed node loads, unpinned: %s" % problem)
	pinned.run.pin = "delivery_van"
	h = Game.new()
	check(h.load_state(JSON.parse_string(JSON.stringify(pinned))) == "" and h.pin == "delivery_van", "I11: a pin on a kept node stays")


## v8–v10 saves, made from the v11 fixture in each version's shape, reach v12
## with nothing lost (I11): their plot conversions and renames still run first.
func test_v8_to_v10_saves_refund() -> void:
	var v10 := v11_save()
	v10.version = 10
	for id in v10.run.plots:
		var p: Dictionary = v10.run.plots[id]
		p.quality = p.cargo
		for k in ["cargo", "field", "haul"]:
			p.erase(k)
	var v9: Dictionary = JSON.parse_string(JSON.stringify(v10).replace("thai_chili", "tabasco"))
	v9.version = 9
	v9.run.stock["savina_gold"] = 4
	var v8: Dictionary = v9.duplicate(true)
	v8.version = 8
	for id in v8.run.plots:
		v8.run.plots[id].erase("spare")
	for save in [v10, v9, v8]:
		var g := Game.new()
		var problem := g.load_state(JSON.parse_string(JSON.stringify(save)))
		var label := "v%d" % save.version
		check(problem == "", "I11 %s: loads: %s" % [label, problem])
		check_no_loss(g, 50000.0, 90000.0, {"bell": 10, "jalapeno": 5, "bistro_verde": 2}, label)
		check(g.account.credits == 4 + 15 + 2 + 6 + 15, "I11 %s: rooms back as credits (%d)" % [label, g.account.credits])
	var g9 := Game.new()
	g9.load_state(JSON.parse_string(JSON.stringify(v9)))
	check(g9.stock.cocoa_loco == 4, "I11 v9: D042's renames still run (Savina Gold is Cocoa Loco: %d)" % g9.stock.cocoa_loco)
	var bad := v8.duplicate(true)
	bad.run.plots.bell = 5
	check(Game.new().load_state(JSON.parse_string(JSON.stringify(bad))) != "", "I11 v8: a broken plot is refused, not crashed on")


func v11_save() -> Dictionary:
	return {
		"version": 11,
		"run": {
			"cash": 1234.0, "stock": {"bell": 10, "jalapeno": 5, "bistro_verde": 2},
			"plots": {"bell": {"owned": true, "speed": 3, "yield": 2, "cargo": 1, "progress": 0.0, "spare": 0.0, "field": 7, "haul": 0.0},
				"poblano": {"owned": true, "speed": 0, "yield": 0, "cargo": 0, "progress": 0.0, "spare": 0.0, "field": 3, "haul": 0.0}},
			"vats": [{"recipe": "sweet_mash", "speed": 1, "progress": 1.0, "running": true, "taken": {"bell": 10}}],
			"lines": [{"recipe": "table_mild", "speed": 0, "progress": 0.0, "running": false, "taken": {}, "crate": 0}],
			"research": ["kitchen_table", "jalapeno_blueprint", "slot_expansion_1", "delivery_van"],
			"autosell": {}, "autosell_acc": {}, "heat": 0.0, "press_acc": {"grip": 0.0, "piston": 0.0}, "overdrive": {"until": 0, "ready": 0},
			"keep": {}, "pin": "", "ticker": {"sauce": "", "mult": 1.0, "ends": 0, "next": -1}, "byproduct_ready": 0.0,
			"rng": {"seed": "1", "state": "2"}, "stats": {"cash_earned": 50000.0, "ticks": 100},
		},
		"account": {"best_ov": 90000.0, "credits": 4, "prestiges": 1, "rooms": {"seed_capital": 2, "tasting_room": 3}, "draft": ["cooperage", "glassworks"]},
	}