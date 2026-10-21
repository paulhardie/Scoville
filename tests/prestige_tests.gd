extends SceneTree
## Selling the franchise, credits, HQ rooms and the draft (docs/PRESTIGE.md
## Q1–Q8), and part 2: after-sale nodes and Standard Operating Procedures
## (Q10, Q12, Q13).

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const Helpers = preload("res://tests/button_tests.gd")

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
	print("%s: prestige tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


## A game whose run has earned `ov` (its Operation Value, with nothing in stock).
static func worth(ov: float, rooms: Dictionary = {}) -> Game:
	var g := Game.new({}, 3)
	g.revealed = {"counter": true, "status_bar": true, "deck": true}
	for id in rooms:
		g.account.rooms[id] = rooms[id]
	g._refresh_fx()
	g.stats.cash_earned = ov
	g.cash = ov
	g._note_value()
	return g


func test_selling_threshold() -> void:
	var below := T.PRESTIGE_OV - 1.0
	check(not worth(below).can_prestige() and not worth(below).prestige(), "Q1: no sale below $%.0f" % T.PRESTIGE_OV)
	check(worth(T.PRESTIGE_OV).prestige(), "Q1: a sale at $%.0f" % T.PRESTIGE_OV)


func test_credits() -> void:
	# Idle Planet Miner's table (D035): 10, 30, 60 at $10M, $100M, $1B, straight
	# lines between, rounded.
	for c in [[1e7, 10], [1.25e7, 11], [1.75e7, 12], [1e8, 30], [5.5e8, 45], [1e9, 60], [1e10, 101]]:
		var got: int = worth(c[0]).prestige_credits()
		check(got == c[1], "Q2: %d credits at $%.0f (got %d)" % [c[1], c[0], got])
	var lounge := worth(1e8, {"executive_lounge": 1})
	check(lounge.prestige_credits() == 32, "Q2: the Executive Lounge adds 8%%, rounded: 30 × 1.08 = 32 (got %d)" % lounge.prestige_credits())
	var g := worth(1e8)
	g.prestige()
	check(g.account.credits == 30 and g.account.prestiges == 1, "Q2: the sale pays them into the account")


func test_reset_scope() -> void:
	var g: Game = Helpers.with(["automated_piston", "market_ticker", "smart_stockpiling"])
	g.account.rooms = {"seed_capital": 2}
	g._refresh_fx()
	g.cash = 5e5
	g.buy_plot("bell")
	g.buy_slot("vat")
	g.buy_slot("line")
	for item in g.stock:
		g.stock[item] = 50
	g.heat = 80.0
	g.set_keep("bell", 7)
	g.set_pin("foil_wraps")
	g.advance(600)
	g.stats.cash_earned = 2.0 * T.PRESTIGE_OV
	var best: float = g.operation_value()
	var credits: int = g.prestige_credits()
	check(g.prestige(), "Q3: sells at $%.0f" % g.stats.cash_earned)
	check(close(g.cash, 5000.0), "Q3: cash restarts at Seed Capital Level 2's $5,000 (got %.2f)" % g.cash)
	var owned := 0
	for crop in g.plots:
		owned += 1 if g.plots[crop].owned else 0
	var stocked := 0
	for item in g.stock:
		stocked += g.stock[item]
	check(owned == 0 and g.vats.is_empty() and g.lines.is_empty() and stocked == 0, "Q3: plots, slots and stock reset")
	check(g.research.keys() == ["kitchen_table"] and not g.fx.piston, "Q3: the Tech Tree resets to the Kitchen Table")
	check(g.heat == 0.0 and g.keep.is_empty() and g.pin == "" and g.ticker.next == -1 and g.stats.ticks == 0 and g.stats.cash_earned == 0.0, "Q3: Heat, keep amounts, the pin, the Ticker and the statistics reset")
	check(g.account.best_ov >= best and g.account.rooms == {"seed_capital": 2} and g.account.credits == credits, "Q3: the account stays")
	check(g.revealed.deck and g.nav_shown() and g.tab_open("tech") and g.tab_open("hq"), "Q3: the reveals and tabs stay")
	check(g.buy_plot("bell") and g.plots.bell.owned, "Q3: the new run plays on: the Bell Pepper Plot can be bought at once")


func test_draft() -> void:
	var g := worth(0.0)
	g.account.credits = 100
	check(g.room_open_cost() == 5 and g.open_room(), "Q4: the first room costs 5")
	check(g.account.credits == 95, "Q4: and takes it")
	var d: Array = g.account.draft
	check(d.size() == 2 and d[0] != d[1], "Q4: two different rooms dealt: %s" % str(d))
	check(not g.open_room() and g.account.credits == 95, "Q4: no second payment while a draft waits")
	var outside := ""
	for id in g.data.rooms:
		if not d.has(id):
			outside = id
			break
	check(not g.choose_room(outside), "Q4: a room outside the draft can't be picked")
	var c := Game.new()
	check(c.load_state(JSON.parse_string(JSON.stringify(g.to_state()))) == "" and c.account.draft == d, "Q4: the draft survives a save unchanged")
	check(c.choose_room(d[1]) and c.account.rooms == {d[1]: 1} and c.account.draft.is_empty(), "Q4: picking opens it at Level 1")
	check(c.room_open_cost() == 10, "Q4: the second room costs 10")
	var last := worth(0.0)
	last.account.credits = 1000
	var ids: Array = last.data.rooms.keys()
	for i in ids.size() - 1:
		last.account.rooms[ids[i]] = 1
	check(last.open_room() and last.account.draft == [ids[-1]], "Q4: one card when one room is left")
	last.choose_room(ids[-1])
	check(not last.can_open_room(), "Q4: nothing to open once all 12 are owned")


func test_levels() -> void:
	var g := worth(0.0, {"night_watchman": 1})
	g.account.credits = 1000
	check(g.room_level_cost("night_watchman") == 2 and g.level_room("night_watchman") and g.account.credits == 998, "Q5: Level 2 costs 2")
	check(g.room_level_cost("night_watchman") == 4, "Q5: Level 3 costs 4")
	while g.level_room("night_watchman"):
		pass
	check(g.account.rooms.night_watchman == 8, "Q5: Night Watchman stops at Level 8 (got %d)" % g.account.rooms.night_watchman)
	check(not g.level_room("seed_vault"), "Q5: a room not owned can't be levelled")


func test_room_effects() -> void:
	var base := worth(0.0)
	var vault := worth(0.0, {"seed_vault": 3})
	check(close(vault.plot_cycle("bell"), base.plot_cycle("bell") / 1.35), "Q6: Seed Vault Lv3: plots 35% faster")
	var bay := worth(0.0, {"hydroponics_bay": 1})
	check(bay.plot_yield("tabasco") == 11 and base.plot_yield("tabasco") == 10, "Q6: Hydroponics Bay Lv1: 10 a harvest becomes 11")
	for pair in [["fermentation_cellar", "vat", "sweet_mash"], ["high_speed_cannery", "line", "table_mild"]]:
		var g := worth(1e6, {pair[0]: 2})
		var plain := worth(1e6)
		for x in [g, plain]:
			x.buy_slot("vat")
			if pair[1] == "line":
				x.buy_slot("line")
			x.assign(pair[1], 0, pair[2])
		check(close(g.slot_cycle(pair[1], 0), plain.slot_cycle(pair[1], 0) / 1.25), "Q6: %s Lv2: %ss 25%% faster" % [pair[0], pair[1]])
	var coop := worth(0.0, {"cooperage": 2})
	check(coop.recipe_inputs("pickled_brine").vinegar == 9 and coop.recipe_inputs("tabasco_mash").tabasco == 45, "Q6: Cooperage Lv2: 10% fewer raw crops")
	check(coop.recipe_inputs("liquid_smoke").pickled_brine == 2, "Q6: Cooperage leaves mash inputs alone")
	var glass := worth(0.0, {"glassworks": 11})
	var sg: Dictionary = glass.recipe_inputs("savina_gold")
	check(sg.pickled_brine == 1 and sg.savina_mash == 1 and sg.classic_louisiana == 1, "Q6/Q7: Glassworks Lv11: 3 Brine rounds down to 1, 1 stays 1, bottles untouched: %s" % str(sg))
	check(glass.recipe_inputs("pickled_brine").vinegar == 10, "Q6: Glassworks leaves vats alone")
	var lab := worth(0.0, {"ergonomics_lab": 1})
	research(lab, "calloused_thumbs")
	check(lab.tap_yield() == 4, "Q6: Ergonomics Lab Lv1 with Calloused Thumbs: 3 × 1.25 rounds to 4 (got %d)" % lab.tap_yield())
	var amounts := []
	for lv in range(1, 6):
		amounts.append(worth(0.0, {"seed_capital": lv}).start_cash())
	check(amounts == [1000.0, 5000.0, 25000.0, 500000.0, 2500000.0], "Q6: Seed Capital: %s" % str(amounts))
	var taste := worth(0.0, {"tasting_room": 1})
	check(close(taste.sale_price("bistro_verde"), base.sale_price("bistro_verde") * 1.1) and close(taste.appraisal("bistro_verde"), base.appraisal("bistro_verde") * 1.1), "Q6: Tasting Room Lv1: bottles 10% more, sold and in stock")
	check(close(taste.sale_price("bell"), base.sale_price("bell")), "Q6: but not crops")
	var watch := worth(0.0, {"night_watchman": 3})
	check(close(watch.offline_cap(), base.offline_cap() + 3 * 3600.0), "Q6: Night Watchman Lv3: +3 hours")


func test_tech_cost_formula() -> void:
	var g := worth(1e6, {"test_kitchen": 11})
	var c: Dictionary = g.tech_cost("louisiana_blueprint")
	var base: Dictionary = g.data.tech.louisiana_blueprint.cost
	for item in base:
		check(c[item] == maxi(1, roundi(base[item] * 0.56)), "Q7: Test Kitchen Lv11 (−44%%): %d %s becomes %d" % [base[item], item, c[item]])
	check(g.tech_cost("jalapeno_blueprint").table_mild == 2, "Q7: 3 × 0.56 rounds to 2")
	for item in g.stock:
		g.stock[item] = 0
	g.stock.table_mild = 2
	check(g.research_node("jalapeno_blueprint") and g.stock.table_mild == 0, "Q7: research takes the discounted cost")


func test_saves() -> void:
	var old := Game.new()
	var s: Dictionary = old.to_state()
	s.version = 6
	s.account = {"best_ov": 1234.0}
	var g := Game.new()
	var problem := g.load_state(JSON.parse_string(JSON.stringify(s)))
	check(problem == "" and g.account.credits == 0 and g.account.prestiges == 0 and g.account.rooms.is_empty() and g.account.draft.is_empty() and close(g.account.best_ov, 1234.0 * T.SAVE_V8_MONEY), "Q8: a v6 save loads with an account that has never sold, its best ×10 (D035): %s" % problem)
	# v7 → v8 (D035): pounds became dollars ×10, Event Horizon became Extinction Event.
	var v7: Dictionary = JSON.parse_string(JSON.stringify(old.to_state()).replace("extinction_event", "event_horizon"))
	v7.version = 7
	v7.run.cash = 123.5
	v7.run.stats.cash_earned = 4567.0
	v7.run.stock.event_horizon = 3
	v7.account.best_ov = 5e8  # above the stock's worth, so the record isn't raised on loading
	var m := Game.new()
	problem = m.load_state(JSON.parse_string(JSON.stringify(v7)))
	check(problem == "", "Q8/D035: a v7 save loads: %s" % problem)
	check(close(m.cash, 123.5 * T.SAVE_V8_MONEY) and close(m.stats.cash_earned, 4567.0 * T.SAVE_V8_MONEY) and close(m.account.best_ov, 5e8 * T.SAVE_V8_MONEY), "Q8/D035: a v7 save's cash, cash earned and best Operation Value come back ×10: $%.2f, $%.2f, $%.2f" % [m.cash, m.stats.cash_earned, m.account.best_ov])
	check(m.stock.get("extinction_event", 0) == 3 and not m.stock.has("event_horizon"), "Q8/D035: a v7 save's Event Horizon loads as Extinction Event")
	var a := worth(0.0, {"tasting_room": 4, "cooperage": 2})
	a.account.credits = 37
	a.account.prestiges = 3
	a.open_room()
	var b := Game.new()
	check(b.load_state(JSON.parse_string(JSON.stringify(a.to_state()))) == "", "Q8: an account with rooms loads")
	check(b.account == a.account, "Q8: and round-trips exactly: %s against %s" % [str(b.account), str(a.account)])
	check(close(b.sale_price("bistro_verde"), a.sale_price("bistro_verde")), "Q8: its rooms work after loading")
	var bad: Dictionary = a.to_state()
	bad.account.rooms = {"moon_base": 1}
	check(Game.new().load_state(JSON.parse_string(JSON.stringify(bad))) != "", "Q8: an unknown room is refused, not loaded")


## A game after one sale with these nodes (and their parents) researched and
## nothing in stock, and a line bottling `sauce` with its inputs stocked.
static func sold(nodes: Array, sauce: String = "") -> Game:
	var g := Game.new({}, 5)
	g.revealed = {"counter": true, "status_bar": true, "deck": true}
	g.account.best_ov = 1e9
	g.account.prestiges = 1
	for item in g.stock:
		g.stock[item] = 100000
	for node in nodes:
		Helpers.research_with_parents(g, node)
	for item in g.stock:
		g.stock[item] = 0
	if sauce != "":
		g.cash = 1e9
		g.buy_slot("vat")
		g.buy_slot("line")
		g.assign("line", 0, sauce)
		for item in g.data.recipes[sauce].inputs:
			g.stock[item] = 1000
		g.advance(1)
	return g


## Nodes Standard Operating Procedures would research now.
static func under_bar(g: Game) -> Array:
	var bar: float = T.SOP_SHARE * T.SOP_WINDOW * g.bottle_rate()
	var out := []
	for id in g.data.tech_order:
		if g.data.tech[id].excludes.is_empty() and g.research_reachable(id) and g.tech_cost_value(id) < bar:
			out.append(id)
	return out


func test_after_sale_gate() -> void:
	var g := worth(1e9)
	for item in g.stock:
		g.stock[item] = 100000
	Helpers.research_with_parents(g, "phantom_blueprint")
	Helpers.research_with_parents(g, "delivery_van")
	var gated := []
	for id in g.data.tech:
		if g.data.tech[id].after_sale:
			gated.append(id)
	check(gated.size() == 10, "Q10: ten nodes open after a sale (got %d)" % gated.size())
	for id in ["moruga_blueprint", "standard_operating_procedures"]:
		check(not g.can_research(id) and not g.research_node(id), "Q10: %s can't be researched before a sale" % id)
	g.account.prestiges = 1
	for id in ["moruga_blueprint", "standard_operating_procedures"]:
		check(g.research_node(id), "Q10: %s can after one" % id)


func test_sop() -> void:
	var nodes := ["standard_operating_procedures", "pantry_vinegar_concentrate", "phantom_blueprint"]
	var g := sold(nodes, "phantom")
	var bar: float = T.SOP_SHARE * T.SOP_WINDOW * g.bottle_rate()
	check(bar > 0.0, "Q12: a running Phantom line sets a bar ($%.0f)" % bar)
	var due := under_bar(g)
	var waiting := []
	var later := []
	for id in g.data.tech_order:
		if g.is_researched(id) or due.has(id):
			continue
		if g.research_reachable(id):
			waiting.append(id)
		elif g.data.tech[id].excludes.is_empty() and g.tech_cost_value(id) < bar and (not g.data.tech[id].after_sale or g.account.prestiges > 0):
			var parents_due := true
			for need in g.data.tech[id].needs:
				parents_due = parents_due and (g.is_researched(need) or due.has(need))
			if parents_due:
				later.append(id)
	var forks := ["pantry_vinegar_bulk", "pantry_vinegar_reserve"]
	check(g.tech_cost_value(forks[0]) < bar and g.research_reachable(forks[0]), "Q12: a fork side is reachable and under the bar ($%.0f)" % g.tech_cost_value(forks[0]))
	check(not due.is_empty() and not later.is_empty(), "Q12: the setup has nodes due now (%d) and children due after (%d)" % [due.size(), later.size()])
	g.advance(9)
	var missed := []
	for id in due:
		if not g.is_researched(id):
			missed.append(id)
	check(missed.is_empty(), "Q12: every node under the bar researched itself within a second: missed %s" % str(missed))
	check(g.stock.table_mild == 0 and g.stock.bistro_verde == 0, "Q12: free: nothing was in stock to pay with (D040)")
	var over := []
	for id in waiting:
		if g.is_researched(id):
			over.append(id)
	check(over.is_empty(), "Q12: nothing at or over the bar: %s" % str(over))
	check(not g.is_researched(forks[0]) and not g.is_researched(forks[1]), "Q12: a fork side never researches itself")
	var early := []
	for id in later:
		if g.is_researched(id):
			early.append(id)
	check(early.is_empty(), "Q12: a child waits for the second after its parent: %s" % str(early))
	g.advance(10)
	var late := []
	for id in later:
		if not g.is_researched(id):
			late.append(id)
	check(late.is_empty(), "Q12: and then researches itself: missed %s" % str(late))

	var plain := sold(["delivery_van", "pantry_vinegar_concentrate", "phantom_blueprint"], "phantom")
	var before: int = plain.stats.researched
	plain.advance(50)
	check(plain.stats.researched == before, "Q12: without Standard Operating Procedures nothing researches itself")


func test_sop_offline() -> void:
	var g := sold(["standard_operating_procedures", "phantom_blueprint"], "phantom")
	var due := under_bar(g)
	g.catch_up(600.0)
	var missed := []
	for id in due:
		if not g.is_researched(id):
			missed.append(id)
	check(not due.is_empty() and missed.is_empty(), "Q13: the catch-up researches what play would: missed %s of %d" % [str(missed), due.size()])
	check(under_bar(g).is_empty(), "Q13: nothing under the bar is left after time away: %s" % str(under_bar(g)))


static func research(g: Game, node: String) -> void:
	g.account.best_ov = maxf(g.account.best_ov, 1e9)
	for item in g.stock:
		g.stock[item] = 100000
	Helpers.research_with_parents(g, node)
