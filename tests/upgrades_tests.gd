extends SceneTree
## The South and West Wings, the bridges, Tier 3 and Crop Quality
## (docs/TECH_TREE.md R9–R18, docs/FACTORY.md S7–S8).

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
	print("%s: upgrades tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


func seconds(s: float) -> int:
	return roundi(s / T.TICK_SECONDS)


func with(nodes: Array, seed_value: int = 1) -> Game:
	return Helpers.with(nodes, seed_value)


func test_slot_expansion() -> void:
	var g := with([])
	check(g.slot_cap("vat") == 3 and g.slot_cap("line") == 2, "base caps 3 and 2")
	Helpers.research_with_parents(_rich(g), "slot_expansion_1")
	check(g.slot_cap("vat") == 4 and g.slot_cap("line") == 3, "R9: Slot Expansion I: 4 and 3")
	Helpers.research_with_parents(_rich(g), "slot_expansion_2")
	check(g.slot_cap("vat") == 5 and g.slot_cap("line") == 4, "R9: Slot Expansion II: 5 and 4")
	g.cash = 1e6
	for i in 6:
		g.buy_slot("vat")
	for i in 5:
		g.buy_slot("line")
	check(g.vats.size() == 5 and g.lines.size() == 4, "R9: exactly that many can be bought")


func _rich(g: Game) -> Game:
	for item in g.stock:
		g.stock[item] = 100000
	return g


func test_packaging() -> void:
	for c in [["flint_glass", 1.5], ["foil_wraps", 2.2]]:
		var g := with([c[0]])
		check(close(g.fx.packaging, c[1]), "R10: %s is %.1f×" % c)
		g.stock.table_mild = 4
		g.stock.bistro_verde = 2
		g.stock.bell = 10
		var bottles: float = 4 * g.value("table_mild") + 2 * g.value("bistro_verde")
		check(close(g.operation_value() - g.stats.cash_earned, bottles * c[1] + 10 * g.value("bell")), "R10: bottles in Operation Value × the tier; crops not")
		var before: float = g.cash
		g.sell_batch()
		check(close(g.cash - before, bottles * c[1]), "R10: and on sale")
	var lines := with(["flint_glass", "slot_expansion_1", "bistro_blueprint", "delivery_van"])
	lines.cash = 1e6
	lines.buy_slot("vat")
	lines.buy_slot("line")
	lines.buy_slot("line")
	lines.assign("line", 1, "bistro_verde")
	lines.lines[0].crate = 0
	lines.stock.sweet_mash = 1
	lines.stock.verde_mash = 1
	lines.stock.pickled_brine = 1
	lines._start_cycles()
	var before: float = lines.stats.cash_earned
	lines.advance(seconds(10.0))
	check(close(lines.stats.cash_earned - before, (lines.value("table_mild") + lines.value("bistro_verde")) * 1.5), "R10: every line's bottles get it: $%.2f" % (lines.stats.cash_earned - before))


func test_zero_waste() -> void:
	var none := with(["cayenne_mash_blueprint"])
	check(none.recipe_inputs("cayenne_mash") == {"cayenne": 25, "pickled_brine": 1}, "no reduction before the node")
	var one := with(["zero_waste_1", "cayenne_mash_blueprint", "paste_blueprint"])
	check(one.recipe_inputs("sweet_mash") == {"bell": 9}, "R11: 10 Bell × 0.9 = 9")
	check(one.recipe_inputs("pickled_brine") == {"vinegar": 9, "bell": 4}, "R11: 5 Bell × 0.9 rounds down to 4")
	check(one.recipe_inputs("cayenne_mash") == {"cayenne": 22, "pickled_brine": 1}, "R11: 25 × 0.9 = 22.5 → 22; Brine unchanged")
	var two := with(["zero_waste_2", "cayenne_mash_blueprint", "paste_blueprint", "louisiana_blueprint"])
	check(two.recipe_inputs("sweet_mash") == {"bell": 8} and two.recipe_inputs("garlic_paste") == {"garlic": 16}, "R11: × 0.8")
	check(two.recipe_inputs("classic_louisiana") == {"cayenne_mash": 1, "garlic_paste": 1}, "R11: line inputs unchanged")
	check(close(two.value("cayenne_mash"), Game.new().value("cayenne_mash")), "R11: values unchanged")
	var tiny := with([])
	tiny.data = tiny.data.duplicate(true)
	tiny.data.recipes.sweet_mash.inputs = {"bell": 1}
	Helpers.research_with_parents(_rich(tiny), "zero_waste_2")
	check(tiny.recipe_inputs("sweet_mash") == {"bell": 1}, "R11: never below 1")
	two.stock.bell = 8
	two.cash = 1000.0
	two.buy_slot("vat")
	check(two.vats[0].running and two.stock.bell == 0, "R11: a vat takes the reduced amount")
	check(two.assign("vat", 0, "") and two.stock.bell == 8, "and switching off returns what it took")


func test_overdrive() -> void:
	var g := with(["overdrive_turbines"])
	g.cash = 1000.0
	g.buy_slot("vat")
	check(close(g.slot_cycle("vat", 0), 8.0 / 1.25), "R12: Turbines: +25%")
	check(g.activate_overdrive(), "R12: the button works")
	check(close(g.slot_cycle("vat", 0), 8.0 / 2.5), "R12: ×2 on top while it runs")
	g.advance(seconds(60.0) - 1)
	check(g.overdrive_active(), "still running at 59.9 s")
	g.tick()
	check(not g.overdrive_active() and close(g.slot_cycle("vat", 0), 8.0 / 1.25), "R12: off after 60 s")
	check(not g.activate_overdrive(), "R12: refused during the cooldown")
	g.advance(seconds(900.0 - 60.0) - 1)
	check(not g.activate_overdrive(), "R12: still refused at 14:59.9 from the press")
	g.tick()
	check(g.activate_overdrive(), "R12: ready 15 minutes from the press")
	check(not with(["foil_wraps"]).activate_overdrive(), "no button without the Turbines")


func test_overflow_valve() -> void:
	var g := with(["overflow_valve", "bistro_blueprint"])
	check(g.default_keep("bell") == (10 + 5) * 5, "R13: Bell keeps 5 cycles of Sweet Pepper Mash and Pickled Brine: %d" % g.default_keep("bell"))
	check(g.default_keep("verde_mash") == 5 and g.default_keep("jalapeno") == 75, "R13: Verde Mash 5, Jalapeño 75")
	g.stock.bell = 100
	g.stock.verde_mash = 3
	g.advance(10)
	check(g.stock.bell == 75 and g.stock.verde_mash == 3, "R13: sells only what's above the keep amount")
	check(close(g.stats.cash_earned, 25 * g.value("bell")), "R13: at its value")
	g.set_keep("verde_mash", -1)
	g.stock.verde_mash = 500
	g.advance(10)
	check(g.stock.verde_mash == 500, "R13: an item switched off is left alone")
	g.stock.table_mild = 100
	g.advance(10)
	check(g.stock.table_mild == 100, "R13: never bottles")
	check(not with([]).set_keep("bell", 3), "no keep amounts before the valve")


func test_smart_stockpiling() -> void:
	# E16 is paid in Bistro Verde and Verde Mash (E6 was, before v0.6a).
	var g := with(["smart_stockpiling", "serrano_blueprint"])
	var cost: Dictionary = g.data.tech.serrano_mash_blueprint.cost
	check(g.set_pin("serrano_mash_blueprint"), "pins E16")
	g.cash = 1e6
	for s in ["vat", "vat", "line", "line"]:
		g.buy_slot(s)
	g.assign("vat", 0, "verde_mash")
	g.assign("vat", 1, "pickled_brine")
	g.assign("line", 0, "")
	g.assign("line", 1, "bistro_verde")
	g.lines[1].crate = 0
	g.set_keep("jalapeno", -1)
	g.set_keep("vinegar", -1)
	g.set_keep("bell", -1)
	g.stock.jalapeno = 100000
	g.stock.vinegar = 100000
	g.stock.bell = 100000
	g.set_keep("verde_mash", 0)
	g.advance(seconds(600.0))
	check(g.stock.bistro_verde >= cost.bistro_verde and g.stock.bistro_verde <= cost.bistro_verde + 1, "R14: Bistro Verde held back until the %d are in stock: %d" % [cost.bistro_verde, g.stock.bistro_verde])
	check(g.stats.sold.bistro_verde > 0, "R14: then Auto-Sell works as set again")
	check(g.stock.verde_mash <= cost.verde_mash, "R13/R14: the valve keeps the pinned node's Verde Mash, no more: %d" % g.stock.verde_mash)
	g.stock.verde_mash = cost.verde_mash
	check(g.research_node("serrano_mash_blueprint") and g.pin == "", "researching the node unpins it")
	check(not with([]).set_pin("serrano_mash_blueprint"), "no pins before the node")


func test_market_ticker() -> void:
	var g := with(["market_ticker", "bistro_blueprint"], 7)
	var starts: Array = []
	var last := ""
	for i in seconds(4 * 3600.0):
		g.tick()
		if g.ticker.sauce != "" and last == "":
			starts.append([g.now_seconds(), g.ticker.sauce, g.ticker.mult])
		last = g.ticker.sauce
	check(starts.size() >= 3, "R15: several spikes in four hours: %d" % starts.size())
	check(starts[0][0] >= 60.0 and starts[0][0] <= 300.1, "R15: the first 1–5 minutes after research: %.0f s" % starts[0][0])
	for i in range(1, starts.size()):
		var gap: float = starts[i][0] - starts[i - 1][0]
		check(gap >= 2700.0 - 0.1 and gap <= 4500.1, "R15: spikes start 45–75 minutes apart: %.0f s" % gap)
	for s in starts:
		check(s[1] in ["table_mild", "bistro_verde"] and s[2] in [2.0, 3.0], "R15: an unlocked sauce, ×2 or ×3: %s" % str(s))
	var h := with(["market_ticker", "bistro_blueprint"], 7)
	h.advance(seconds(4 * 3600.0))
	check(h.stats.spikes == starts.size() and JSON.stringify(h.ticker) == JSON.stringify(g.ticker), "R15: the same seed gives the same spikes")
	# A spike lasts 30 minutes and only changes that sauce's sale price.
	var k := with(["market_ticker", "bistro_blueprint"], 7)
	while k.ticker.sauce == "":
		k.tick()
	var began := k.now_seconds()
	var sauce: String = k.ticker.sauce
	check(close(k.sale_price(sauce), k.value(sauce) * k.ticker.mult) and close(k.appraisal(sauce), k.value(sauce)), "R15: sale price × the spike; Operation Value unchanged")
	while k.ticker.sauce != "":
		k.tick()
	check(close(k.now_seconds() - began, 1800.0, 1e-3), "R15: 30 minutes: %.1f s" % (k.now_seconds() - began))


func test_byproduct_recycling() -> void:
	var g := with(["byproduct_recycling"])
	g.cash = 1e6
	g.buy_plot("bell")
	g.buy_plot("jalapeno")
	g.plots.bell.speed = 3
	for i in 5:
		g.buy_slot("vat")
	for i in 5:
		g.assign("vat", i, "sweet_mash")
	g.set_keep("bell", -1)
	g.stock.bell = 1000000
	var free_times: Array = []
	var last := 0
	for i in seconds(1800.0):
		g.tick()
		if g.stats.free_levels > last:
			free_times.append(g.now_seconds())
			last = g.stats.free_levels
	check(free_times.size() >= 25 and free_times.size() <= 30, "R16: about one a minute at most over 30 minutes: %d" % free_times.size())
	var min_gap := INF
	for i in range(1, free_times.size()):
		min_gap = minf(min_gap, free_times[i] - free_times[i - 1])
	check(min_gap >= 60.0 - 1e-6, "R16: never two within a minute: %.1f s" % min_gap)
	var bell_levels: int = g.plots.bell.speed + g.plots.bell["yield"] + g.plots.bell.quality
	var jal_levels: int = g.plots.jalapeno.speed + g.plots.jalapeno["yield"] + g.plots.jalapeno.quality
	check(absi(bell_levels - jal_levels) <= 1, "R16: levels go to the lowest plot, so they even out: %d and %d" % [bell_levels, jal_levels])
	var chance := with(["byproduct_recycling"], 5)
	chance.cash = 1e6
	chance.buy_plot("bell")
	chance.buy_slot("vat")
	var hits := 0
	var tries := 4000
	for i in tries:
		chance.byproduct_ready = 0
		var before: int = chance.stats.free_levels
		chance._byproduct()
		hits += chance.stats.free_levels - before
	check(absf(hits / float(tries) - 0.25) < 0.025, "R16: 25%% of eligible vat cycles: %.1f%%" % (hits * 100.0 / tries))


func test_franchise_auditors() -> void:
	var g := with(["franchise_auditors"])
	g.stock.bistro_verde = 10
	g.stock.bell = 100
	var bottle: float = g.value("bistro_verde")
	var stock_value: float = 10 * bottle * 1.5 + 100 * g.value("bell")
	check(close(g.operation_value() - g.stats.cash_earned, stock_value * 1.2), "R17: stock counts 20% more (with Flint Glass on bottles)")
	var before: float = g.cash
	g.sell_batch()
	check(close(g.cash - before, 10 * bottle * 1.5), "R17: sales unchanged")


func test_hydroponic_bell() -> void:
	var g := with(["hydroponic_bell"])
	g.cash = 1000.0
	g.buy_plot("bell")
	check(close(g.plot_cycle("bell"), g.data.plots.bell.seconds / 4.0), "R18: the Bell Pepper Plot's cycle is a quarter: %.2f s" % g.plot_cycle("bell"))
	g.buy_plot("jalapeno")
	check(close(g.plot_cycle("jalapeno"), 2.0), "R18: other plots unchanged")


func test_tier_3() -> void:
	var g := with(["louisiana_blueprint", "slot_expansion_2"])
	g.cash = 1e6
	for i in 5:
		g.buy_slot("vat")
	g.buy_slot("line")
	g.assign("vat", 3, "garlic_paste")
	g.assign("vat", 4, "cayenne_mash")
	g.assign("line", 0, "classic_louisiana")
	g.lines[0].crate = 0
	g.stock.garlic = 20
	g.stock.cayenne = 25
	g.stock.pickled_brine = 1
	g._start_cycles()
	check(g.stock.garlic == 0 and g.stock.cayenne == 0 and g.stock.pickled_brine == 0, "S7: each takes exactly its inputs, Cayenne Mash using Brine")
	g.advance(seconds(12.0))
	check(g.stats.made.garlic_paste == 1 and g.stats.made.cayenne_mash == 1, "S7: one Paste and one Cayenne Mash in 12 s")
	g.advance(seconds(12.0))
	check(g.stock.classic_louisiana == 1 and close(g.value("classic_louisiana"), 3950.0), "S7: then one $3,950 Classic Louisiana")
	check(g.plot_offered("cayenne") and g.plot_offered("garlic"), "the Tier 3 plots are offered")
	g.buy_plot("cayenne")
	g.buy_plot("garlic")
	check(close(g.plot_cycle("cayenne"), 2.4) and g.plot_yield("cayenne") == 5 and g.plot_yield("garlic") == 4, "Tier 3 plots: 5 Cayenne, 4 Garlic every 2.4 s")


func test_crop_quality() -> void:
	var g := with([], 11)
	g.cash = 1e9
	g.buy_plot("bell")
	check(close(g.plot_upgrade_cost("bell", "quality"), T.CROP_QUALITY_COST), "the first level costs $%.0f on the Bell plot" % T.CROP_QUALITY_COST)
	for i in 12:
		g.upgrade_plot("bell", "quality")
	check(g.plots.bell.quality == T.CROP_QUALITY_MAX and close(g.quality_chance("bell"), 0.30), "S8: capped at 10 levels, 30%")
	g.plots.bell.quality = 4
	var harvests := 10000
	var base: int = g.plot_yield("bell")
	var before: int = g.stats.harvested.bell
	var doubled := 0
	for i in harvests:
		g.plots.bell.progress = g.plot_cycle("bell")
		var b: int = g.stats.harvested.bell
		g.tick()
		if g.stats.harvested.bell - b == 2 * base:
			doubled += 1
	check(absf(doubled / float(harvests) - 0.12) <= 0.01, "S8: 4 levels double 12%% of harvests: %.1f%%" % (doubled * 100.0 / harvests))
