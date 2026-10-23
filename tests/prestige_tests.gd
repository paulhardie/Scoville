extends SceneTree
## Selling the franchise, credits, HQ rooms and their offer (docs/PRESTIGE.md, SKELETON.md;
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
	# lines between, × CREDIT_SCALE (PR 3's T9), rounded.
	var k: float = T.CREDIT_SCALE
	for c in [[1e7, 10.0], [1.25e7, 10.0 + 20.0 / 36.0], [1.75e7, 10.0 + 20.0 / 12.0], [1e8, 30.0], [5.5e8, 45.0], [1e9, 60.0], [1e10, 101.0]]:
		var got: int = worth(c[0]).prestige_credits()
		check(got == roundi(c[1] * k), "Q2: %d credits at $%.0f, IPM's %.2f × %.0f (got %d)" % [roundi(c[1] * k), c[0], c[1], k, got])
	check(worth(1e7).prestige_credits() == 50, "Q2/T9: the first sale pays 50 credits (got %d)" % worth(1e7).prestige_credits())
	var lounge := worth(1e8, {"boardroom": 1})
	check(lounge.prestige_credits() == roundi(30.0 * k * 1.15), "Q2: the Boardroom (IPM's Lounge) ×1.15, rounded (got %d)" % lounge.prestige_credits())
	var g := worth(1e8)
	g.prestige()
	check(g.account.credits == roundi(30.0 * k) and g.account.prestiges == 1, "Q2: the sale pays them into the account")


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
	g.cash = 2.0 * T.PRESTIGE_OV
	var best: float = g.operation_value()
	var credits: int = g.prestige_credits()
	check(g.prestige(), "Q3: sells at $%.0f" % best)
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


func test_offer() -> void:
	# Q4 as v0.7 has it (SKELETON.md): IPM's rooms, two offered at a time in
	# rooms.json's order; the n-th bought costs the n-th price (3, 6, 12, 21…).
	var g := worth(0.0)
	g.account.credits = 100
	var order: Array = g.data.room_order
	check(g.rooms_offered() == [order[0], order[1]], "Q4: the first two rooms are offered: %s" % str(g.rooms_offered()))
	check(g.room_open_cost() == 3 and not g.open_room(order[2]), "Q4: the first room costs 3; one not on offer can't be opened")
	check(g.open_room(order[1]) and g.account.credits == 97 and g.account.rooms == {order[1]: 1}, "Q4: opening one takes 3 and opens it at Level 1")
	check(g.rooms_offered() == [order[0], order[2]], "Q4: the next in order joins the offer: %s" % str(g.rooms_offered()))
	check(g.room_open_cost() == 6, "Q4: the second costs 6 (IPM's)")
	var c := Game.new()
	check(c.load_state(JSON.parse_string(JSON.stringify(g.to_state()))) == "" and c.rooms_offered() == g.rooms_offered(), "Q4: the offer survives a save")
	var last := worth(0.0)
	last.account.credits = 100000
	for i in order.size() - 1:
		last.account.rooms[order[i]] = 1
	check(last.rooms_offered() == [order[-1]], "Q4: one offered when one room is left")
	check(last.room_open_cost() == 1946 and last.open_room(order[-1]), "Q4: the 15th room costs 1,946 credits")
	check(last.rooms_offered().is_empty() and not last.can_open_room(order[0]), "Q4: nothing to open once all 15 are owned")


func test_levels() -> void:
	# Q5 as v0.7 has it: each room's own IPM level table.
	var g := worth(0.0, {"night_watchman": 1})
	g.account.credits = 2000000  # the whole table is 1,666,401
	var costs: Array = g.data.rooms.night_watchman.level_costs
	check(costs[0] == 21 and costs[1] == 29, "Q5: the Backup Generator's table: 21, 29… (%s)" % str(costs.slice(0, 3)))
	check(g.room_level_cost("night_watchman") == 21 and g.level_room("night_watchman") and g.account.credits == 2000000 - 21, "Q5: Level 2 costs 21")
	check(g.room_level_cost("night_watchman") == 29, "Q5: Level 3 costs 29")
	while g.level_room("night_watchman"):
		pass
	check(g.account.rooms.night_watchman == 44, "Q5: Night Watchman stops at Level 44 (got %d)" % g.account.rooms.night_watchman)
	check(not g.level_room("seed_vault"), "Q5: a room not owned can't be levelled")


func test_room_effects() -> void:
	# Q6: each room's IPM effect, base + step × (level − 1).
	var base := worth(0.0)
	var vault := worth(0.0, {"seed_vault": 3})
	check(close(vault.harvest_rate("farm_02"), base.harvest_rate("farm_02") * 1.55), "Q6: Seed Vault Lv3: farms ×1.55 (1.25 + 0.15 × 2)")
	var pool := worth(0.0, {"motor_pool": 1, "crate_yard": 1})
	check(close(pool.truck_speed("farm_02"), 1.5) and pool.truck_cargo("farm_02") == roundi(5 * 1.5), "Q6: Motor Pool and Crate Yard Lv1: trucks ×1.5 and cargo ×1.5")
	var office := worth(0.0, {"land_office": 2})
	check(close(office.plot_upgrade_cost("farm_02", "harvest"), base.plot_upgrade_cost("farm_02", "harvest") * 0.86), "Q6: Land Office Lv2: farm upgrades 14% less")
	for pair in [["fermentation_cellar", "vat", "sweet_mash"], ["high_speed_cannery", "line", "table_mild"]]:
		var g := worth(1e6, {pair[0]: 2})
		var plain := worth(1e6)
		for x in [g, plain]:
			x.buy_slot("vat")
			if pair[1] == "line":
				x.buy_slot("line")
			x.assign(pair[1], 0, pair[2])
		check(close(g.slot_cycle(pair[1], 0), plain.slot_cycle(pair[1], 0) / 1.3), "Q6: %s Lv2: %ss ×1.3 faster" % [pair[0], pair[1]])
	var coop := worth(0.0, {"cooperage": 2})
	check(coop.recipe_inputs("pickled_brine").vinegar == 860 and coop.recipe_inputs("sofrito_base") == {"hungarian_wax_mash": 1, "bell_puree": 8}, "Q6: Cooperage Lv2: vat recipes 14% less, rounded down, at least 1")
	check(coop.recipe_inputs("sweet_pepper_relish") == base.recipe_inputs("sweet_pepper_relish"), "Q6: Cooperage leaves lines alone")
	var glass := worth(0.0, {"glassworks": 11})
	check(glass.recipe_inputs("garden_hot_sauce") == {"sweet_pepper_relish": 1, "bell_puree": 5} and glass.recipe_inputs("table_mild") == {"sweet_mash": 1}, "Q6/Q7: Glassworks Lv11: line recipes half, 1 stays 1: %s" % str(glass.recipe_inputs("garden_hot_sauce")))
	check(glass.recipe_inputs("pickled_brine").vinegar == 1000, "Q6: Glassworks leaves vats alone")
	var lab := worth(0.0, {"ergonomics_lab": 1})
	research(lab, "calloused_thumbs")
	check(lab.tap_yield() == 11, "Q6: Ergonomics Lab Lv1 with Calloused Thumbs: 9 × 1.25 rounds to 11 (got %d)" % lab.tap_yield())
	var amounts := []
	for lv in range(1, 6):
		amounts.append(worth(0.0, {"seed_capital": lv}).start_cash())
	check(amounts == [1000.0, 5000.0, 25000.0, 500000.0, 2500000.0], "Q6: Seed Capital: %s" % str(amounts))
	var taste := worth(0.0, {"tasting_room": 1})
	check(close(taste.sale_price("bistro_verde"), base.sale_price("bistro_verde") * 1.15) and close(taste.appraisal("bell_puree"), base.appraisal("bell_puree") * 1.15), "Q6: Tasting Room Lv1: mash and sauces ×1.15, sold and in stock")
	check(close(taste.sale_price("bell"), base.sale_price("bell")), "Q6: but not crops")
	var watch := worth(0.0, {"night_watchman": 3})
	check(close(watch.offline_cap(), base.offline_cap() + 1.5 * 3600.0), "Q6: Night Watchman Lv3: +1.5 hours (IPM's 30 minutes a level)")
	var ads := worth(0.0, {"ad_agency": 1})
	research(ads, "market_ticker")
	while ads.ticker.sauce == "":
		ads.tick()
	check(ads.ticker.mult in [2.0 * 1.3, 3.0 * 1.3], "Q6: Ad Agency Lv1: spikes ×1.3 (×%.2f)" % ads.ticker.mult)


func test_tech_cost_formula() -> void:
	var g := worth(1e6, {"test_kitchen": 11})
	var c: Dictionary = g.tech_cost("survey_2")
	var base: Dictionary = g.data.tech.survey_2.cost
	for item in base:
		check(c[item] == maxi(1, roundi(base[item] * 0.5)), "Q7: Test Kitchen Lv11 (−50%%, IPM's Laboratory): %d %s becomes %d" % [base[item], item, c[item]])
	check(g.tech_cost("calloused_thumbs").table_mild == 5, "Q7: 10 × 0.5 = 5")
	var one := worth(0.0, {"test_kitchen": 11})
	one.data = one.data.duplicate(true)
	one.data.tech.calloused_thumbs.cost = {"table_mild": 1}
	check(one.tech_cost("calloused_thumbs").table_mild == 1, "Q7: a 1-item cost stays 1")
	for item in g.stock:
		g.stock[item] = 0
	g.stock.table_mild = 5
	check(g.research_node("calloused_thumbs") and g.stock.table_mild == 0, "Q7: research takes the discounted cost")


func test_saves() -> void:
	var old := Game.new()
	var s: Dictionary = old.to_state()
	s.version = 6
	s.account = {"best_ov": 1234.0}
	var g := Game.new()
	var problem := g.load_state(JSON.parse_string(JSON.stringify(s)))
	check(problem == "" and g.account.credits == 0 and g.account.prestiges == 0 and g.account.rooms.is_empty() and close(g.account.best_ov, 1234.0 * T.SAVE_V8_MONEY), "Q8: a v6 save loads with an account that has never sold, its best ×10 (D035): %s" % problem)
	# v7 → v8 (D035): pounds became dollars ×10, Event Horizon became Extinction Event.
	# A v7 save had no Event Horizon pepper; its event_horizon was the sauce.
	var v7: Dictionary = old.to_state()
	v7.version = 7
	v7.run.cash = 123.5
	v7.run.stats.cash_earned = 4567.0
	v7.run.stock.erase("extinction_event")
	v7.run.stock.event_horizon = 3
	v7.account.best_ov = 1e40  # above the stock's worth, so the record isn't raised on loading
	var m := Game.new()
	problem = m.load_state(JSON.parse_string(JSON.stringify(v7)))
	check(problem == "", "Q8/D035: a v7 save loads: %s" % problem)
	# v12 (I11): cash is what the run earned, so ×10 of 4,567.
	check(close(m.cash, 4567.0 * T.SAVE_V8_MONEY) and close(m.stats.cash_earned, 4567.0 * T.SAVE_V8_MONEY) and close(m.account.best_ov, 1e40 * T.SAVE_V8_MONEY), "Q8/D035: a v7 save's money comes back ×10, cash as all it earned (v12): $%.2f, $%.2f, $%.2f" % [m.cash, m.stats.cash_earned, m.account.best_ov])
	check(m.stock.get("extinction_event", 0) == 3 and m.stock.get("event_horizon", 0) == 0, "Q8/D035: a v7 save's Event Horizon loads as Extinction Event")
	var a := worth(0.0, {"tasting_room": 4, "cooperage": 2})
	a.account.credits = 37
	a.account.prestiges = 3
	a.open_room(a.rooms_offered()[0])
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
		g.bought[sauce] = true
		g._refresh_fx()
		g.assign("line", 0, sauce)
		for item in g.data.recipes[sauce].inputs:
			g.stock[item] = 1000
		g.advance(1)
	return g


## Nodes Standard Operating Procedures would research now.
static func under_bar(g: Game) -> Array:
	var bar: float = g.sop_bar()
	var out := []
	for id in g.data.tech_order:
		if g.data.tech[id].excludes.is_empty() and g.research_reachable(id) and g.tech_cost_value(id) < bar:
			out.append(id)
	return out


func test_after_sale_gate() -> void:
	# Q10 as v0.7 rewrites it: only Standard Operating Procedures waits for a
	# sale; Tier 6's gate is gone (IPM gates nothing behind a sale).
	var g := worth(1e9)
	for item in g.stock:
		g.stock[item] = 100000
	Helpers.research_with_parents(g, "delivery_van")
	var gated := []
	for id in g.data.tech:
		if g.data.tech[id].after_sale:
			gated.append(id)
	check(gated == ["standard_operating_procedures"], "Q10: only SOP opens after a sale (got %s)" % str(gated))
	check(not g.can_research("standard_operating_procedures") and not g.research_node("standard_operating_procedures"), "Q10: SOP can't be researched before a sale")
	g.account.prestiges = 1
	check(g.research_node("standard_operating_procedures"), "Q10: it can after one")


func test_sop() -> void:
	var nodes := ["standard_operating_procedures", "pantry_vinegar_concentrate"]
	var g := sold(nodes, "island_heat")
	var bar: float = g.sop_bar()
	check(bar > 0.0, "Q12: a running Island Heat line sets a bar ($%.0f)" % bar)
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
			# IPM's "any of": one of them researched or due.
			var any: Array = g.data.tech[id].needs_any
			if not any.is_empty():
				parents_due = parents_due and any.any(func(n): return g.is_researched(n) or due.has(n))
			if parents_due:
				later.append(id)
	var forks := ["pantry_vinegar_bulk", "pantry_vinegar_reserve"]
	check(g.tech_cost_value(forks[0]) < bar and g.research_reachable(forks[0]), "Q12: a fork side is reachable and under the bar ($%.0f)" % g.tech_cost_value(forks[0]))
	check(not due.is_empty() and not later.is_empty(), "Q12: the setup has nodes due now (%d) and children due after (%d)" % [due.size(), later.size()])
	var cash_0: float = g.cash
	var earned_0: float = g.stats.cash_earned
	var consumed_0: Dictionary = g.stats.consumed.duplicate()
	g.advance(9)
	var missed := []
	for id in due:
		if not g.is_researched(id):
			missed.append(id)
	check(missed.is_empty(), "Q12: every node under the bar researched itself within a second: missed %s" % str(missed))
	# Free (D040): no cash beyond what the factory spent and earned, and no items.
	var spent: float = cash_0 + (g.stats.cash_earned - earned_0) - g.cash
	var took := false
	for id in due:
		for item in g.data.tech[id].cost:
			if not item in g.data.recipes.phantom.inputs:
				took = took or g.stats.consumed[item] != consumed_0[item]
	check(absf(spent) < 0.01 and not took, "Q12: free (D040): $%.2f spent, items taken: %s" % [spent, took])
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

	var plain := sold(["delivery_van", "pantry_vinegar_concentrate"], "island_heat")
	var before: int = plain.stats.researched
	plain.advance(50)
	check(plain.stats.researched == before, "Q12: without Standard Operating Procedures nothing researches itself")


func test_sop_offline() -> void:
	var g := sold(["standard_operating_procedures"], "island_heat")
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
