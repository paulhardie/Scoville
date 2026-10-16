extends SceneTree
## The Tech Tree slice and the Delivery Van (docs/TECH_TREE.md R1–R4), the tab
## thresholds (docs/ONBOARDING.md O8–O10) and the data checks (FACTORY.md S6).

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const DataLoader = preload("res://src/core/data_loader.gd")

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
	print("%s: tech tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


## A game with the Tech Tree open and plenty of stock.
func open_tree() -> Game:
	var g := Game.new()
	g.revealed.deck = true
	g.account.best_ov = 800.0
	g.stock.table_mild = 500
	g.stock.sweet_mash = 50
	return g


func test_tabs_open_at_thresholds() -> void:
	var g := Game.new()
	g.revealed.deck = true
	g.account.best_ov = 399.0
	check(g.tab_open("farms") and not g.nav_shown() and not g.tab_open("processing"), "O8: no nav bar at £399")
	g.account.best_ov = 400.0
	check(g.nav_shown() and g.tab_open("processing"), "O8: the nav bar and Processing at £400")
	check(not g.tab_open("tech") and not g.tab_open("roster") and not g.tab_open("hq"), "O8: three tabs still locked")
	g.account.best_ov = 749.0
	check(not g.tab_open("tech"), "O9: no Tech Tree at £749")
	g.account.best_ov = 750.0
	check(g.tab_open("tech"), "O9: the Tech Tree opens at £750")
	g.account.best_ov = 5e6
	check(not g.tab_open("roster") and not g.tab_open("hq"), "O9: Shift Roster and HQ stay locked in v0.3")


func test_tabs_follow_the_best_value() -> void:
	var g := Game.new()
	g.revealed.deck = true
	g.stock.table_mild = 100
	g.tick()
	check(close(g.account.best_ov, 500.0) and g.tab_open("processing"), "100 Table Mild in stock is £500 of Operation Value")
	g.stock.table_mild = 0
	g.tick()
	check(g.tab_open("processing"), "O10: losing the stock doesn't close the tab")
	var c := Game.new()
	c.load_state(JSON.parse_string(JSON.stringify(g.to_state())))
	check(c.tab_open("processing"), "O10: it stays open after a reload")
	var s := g.to_state()
	check(s.account.has("best_ov") and not s.run.has("best_ov"), "O10: the record is the account's, outside the run")


func test_research_needs_parents_and_cost() -> void:
	var g := open_tree()
	check(g.is_researched("kitchen_table"), "the Kitchen Table starts researched")
	check(not g.can_research("verde_blueprint") and not g.research_node("verde_blueprint"), "R1: Verde needs the Jalapeño blueprint first")
	var closed := Game.new()
	closed.stock.table_mild = 500
	check(not closed.research_node("jalapeno_blueprint"), "R1: nothing before the tab opens")
	var price: int = g.data.tech.jalapeno_blueprint.cost.table_mild
	g.stock.table_mild = price - 1
	var before := JSON.stringify(g.to_state())
	check(not g.research_node("jalapeno_blueprint"), "R1: one bottle short can't pay")
	check(JSON.stringify(g.to_state()) == before, "R1: a refused research changes nothing")
	g.stock.table_mild = price
	check(g.research_node("jalapeno_blueprint") and g.stock.table_mild == 0, "R2: it takes exactly its cost")
	check(not g.research_node("jalapeno_blueprint"), "a node can't be researched twice")


func test_research_costs_and_permanence() -> void:
	var g := open_tree()
	for node in ["jalapeno_blueprint", "vinegar_blueprint", "brine_blueprint", "verde_blueprint", "bistro_blueprint", "delivery_van", "calloused_thumbs"]:
		var cost: Dictionary = g.data.tech[node].cost
		var had := {}
		for item in cost:
			had[item] = g.stock[item]
		check(g.research_node(node), "researches " + node)
		for item in cost:
			check(g.stock[item] == had[item] - cost[item], "R2: %s takes %d %s" % [node, cost[item], item])
	check(g.stats.researched == 7, "seven researched")
	var c := Game.new()
	c.load_state(JSON.parse_string(JSON.stringify(g.to_state())))
	for node in g.research:
		check(c.is_researched(node), "R2: %s survives a reload" % node)
	check(c.research.size() == g.research.size(), "R2: and nothing else is researched")


func test_blueprints_open_what_they_name() -> void:
	var g := open_tree()
	g.cash = 100000.0
	check(not g.plot_unlocked("jalapeno") and not g.recipe_unlocked("verde_mash"), "nothing open before research")
	g.research_node("jalapeno_blueprint")
	check(g.plot_unlocked("jalapeno") and g.buy_plot("jalapeno"), "R3: E1 opens the Jalapeño Plot")
	check(not g.plot_unlocked("vinegar") and not g.recipe_unlocked("verde_mash"), "R3: and only that")
	g.research_node("verde_blueprint")
	check(g.recipe_unlocked("verde_mash") and not g.recipe_unlocked("pickled_brine"), "R3: E2 opens Verde Mash only")
	g.research_node("vinegar_blueprint")
	check(g.plot_unlocked("vinegar"), "R3: E3 opens the White Vinegar Plot")
	g.research_node("brine_blueprint")
	check(g.recipe_unlocked("pickled_brine") and not g.recipe_unlocked("bistro_verde"), "R3: E4 opens Pickled Brine only")
	g.research_node("bistro_blueprint")
	check(g.recipe_unlocked("bistro_verde"), "R3: E5 opens Bistro Verde")
	check(not g.has_van(), "no Van yet")
	g.research_node("delivery_van")
	check(g.has_van(), "R3: W1 brings the Delivery Van")


## A Tier 1 factory run for 10 minutes with the given Auto-Sell share, selling
## anything left in stock at the end. Returns {earned, made, sold_auto}.
func factory_run(van: bool, percent: int) -> Dictionary:
	var g := open_tree()
	g.stock.table_mild = 25
	g.stock.sweet_mash = 0
	if van:
		g.research_node("delivery_van")
		g.set_autosell("table_mild", percent)
	g.stock.table_mild = 0
	g.cash = 1000.0
	g.buy_plot("bell")
	g.buy_slot("vat")
	g.buy_slot("line")
	g.lines[0].crate = 0
	var start: float = g.stats.cash_earned
	var auto := 0
	for i in 6000:
		var sold_before: int = g.stats.sold.table_mild
		var stock_before: int = g.stock.table_mild
		g.tick()
		if g.stats.sold.table_mild > sold_before and g.stock.table_mild == stock_before:
			auto += g.stats.sold.table_mild - sold_before
	var made: int = g.stats.made.table_mild
	var in_stock: int = g.stock.table_mild
	g.sell_batch()
	return {"earned": g.stats.cash_earned - start, "made": made, "auto": auto, "stock": in_stock}


func test_delivery_van_autosell() -> void:
	var by_hand := factory_run(false, 0)
	var full := factory_run(true, 100)
	check(full.made == by_hand.made, "the Van doesn't change production")
	check(close(full.earned, by_hand.earned, 1e-12), "R4: 100%% Auto-Sell earns what Sell Batch does: £%.2f vs £%.2f" % [full.earned, by_hand.earned])
	check(full.stock == 0 and full.auto == full.made, "R4: at 100% nothing reaches stock")
	var none := factory_run(true, 0)
	check(none.auto == 0 and none.stock == none.made, "R4: at 0% everything goes to stock")
	var part := factory_run(true, 30)
	check(part.auto == part.made * 3 / 10, "R4: at 30%%, 3 in 10 are sold: %d of %d" % [part.auto, part.made])


func test_calloused_thumbs() -> void:
	var g := open_tree()
	check(g.press() == 1, "a press picks 1 before")
	g.research_node("calloused_thumbs")
	var before: int = g.stock.bell
	check(g.press() == 3 and g.stock.bell - before == 3, "N1 (Calloused Thumbs): +2 a press, so 3")


func test_autosell_slider() -> void:
	var g := open_tree()
	check(not g.set_autosell("table_mild", 50), "no slider without the Van")
	g.research_node("delivery_van")
	check(g.set_autosell("table_mild", 34) and g.autosell.table_mild == 30, "the slider moves in steps of 10")
	check(g.set_autosell("bistro_verde", 150) and g.autosell.bistro_verde == 100, "and stays within 0–100")
	check(not g.set_autosell("bell", 50), "only sauces have sliders")


func test_real_data_loads() -> void:
	var loaded := DataLoader.load_dir()
	check(loaded.errors.is_empty(), "S6: the real data loads: %s" % str(loaded.errors))


func test_bad_data_names_file_and_row() -> void:
	var good := {}
	for name in DataLoader.FILES:
		good[name] = JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % name))
	var cases := [
		["recipes", func(d): d.recipes.recipes[2].output = "table_mild", "recipes.json row 3 (verde_mash)"],
		["recipes", func(d): d.recipes.recipes[1].inputs["moonbeam"] = 2.0, "recipes.json row 2 (pickled_brine)"],
		["items", func(d): d.items.items[0].value = -1.0, "items.json row 1 (bell)"],
		["plots", func(d): d.plots.plots[1].crop = "table_mild", "plots.json row 2 (table_mild)"],
		["tech", func(d): d.tech.nodes[2].needs = ["nowhere"], "tech.json row 3 (verde_blueprint)"],
		["tech", func(d): d.tech.nodes[1].effects = [{"unlock_plot": "mars"}], "tech.json row 2 (jalapeno_blueprint)"],
		["slots", func(d): d.slots.vat.prices = [], "slots.json"],
	]
	for c in cases:
		var d: Dictionary = good.duplicate(true)
		c[1].call(d)
		var result := DataLoader.check(d)
		var named := false
		for e in result.errors:
			if String(e).begins_with(c[2]):
				named = true
		check(named and result.data.is_empty(), "S6: bad %s names '%s': %s" % [c[0], c[2], str(result.errors)])
