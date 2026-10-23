extends SceneTree
## The South and West Wings and the bridges (docs/TECH_TREE.md R10–R18, as
## v0.7 changes them), Bumper Crop (C4), and Idle Planet Miner's adopted
## projects (docs/SKELETON.md I1: each node's effect).

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


## Recipes bought, as the Recipe Book does (D051).
func bought(g: Game, recipes: Array) -> Game:
	for r in recipes:
		g.bought[r] = true
	g._refresh_fx()
	return g


func test_sauce_values() -> void:
	# R10 as v0.7 has it: Heavy Flint Glass and Foil Neck Wraps are IPM's Item
	# Values (×1.2 each); Embossed Artisan Decanters keeps its packaging.
	for c in [[["flint_glass"], 1.2], [["foil_wraps"], 1.44]]:
		var g := with(c[0])
		check(close(g.sale_price("bistro_verde"), g.value("bistro_verde") * c[1]), "R10: %s: sauces ×%.2f" % [c[0][0], c[1]])
		check(close(g.sale_price("bell_puree"), g.value("bell_puree")) and close(g.sale_price("bell"), g.value("bell")), "R10: mash and crops unchanged")
		g.stock.bistro_verde = 2
		var before: float = g.cash
		g.sell_batch()
		check(close(g.cash - before, 2 * g.value("bistro_verde") * c[1]), "R10: and on sale")
	var d := with(["artisan_decanters"])
	check(close(d.sale_price("table_mild"), d.value("table_mild") * 1.44 * d.fx.packaging) and d.fx.packaging > 1.0, "R10: Decanters' packaging on top")


func test_mash_values() -> void:
	# IPM's Alloy Values: Slow Roasting and Wood-Fired Roasting, ×1.2 each.
	var g := with(["slow_roasting"])
	check(close(g.sale_price("bell_puree"), g.value("bell_puree") * 1.2) and close(g.sale_price("table_mild"), g.value("table_mild")), "mash ×1.2, sauces not")
	var h := with(["wood_fired_roasting"])
	check(close(h.appraisal("cascabel_mash"), h.value("cascabel_mash") * 1.44), "×1.44 with both, in Operation Value too")


func test_zero_waste() -> void:
	# R11 as v0.7 has it: IPM's Smelting and Crafting Efficiency, 20% off every
	# input of a vat or line recipe, rounded down, at least 1.
	var none := with([])
	check(none.recipe_inputs("pickled_brine") == {"vinegar": 1000}, "no cut before the node")
	var one := with(["zero_waste_1"])
	check(one.recipe_inputs("pickled_brine") == {"vinegar": 800} and one.recipe_inputs("sweet_mash") == {"bell": 8}, "R11: vats × 0.8")
	check(one.recipe_inputs("sofrito_base") == {"hungarian_wax_mash": 1, "bell_puree": 8}, "R11: 2 × 0.8 rounds down to 1; 10 → 8")
	check(one.recipe_inputs("bistro_verde") == none.recipe_inputs("bistro_verde"), "R11: lines unchanged by Zero-Waste I")
	var two := with(["zero_waste_2"])
	check(two.recipe_inputs("sweet_pepper_relish") == {"bell_puree": 4} and two.recipe_inputs("table_mild") == {"sweet_mash": 1}, "R11: lines × 0.8, never below 1")
	check(close(two.value("cascabel_mash"), Game.new().value("cascabel_mash")), "R11: values unchanged")
	one.stock.bell = 8
	one.cash = 1000.0
	one.buy_slot("vat")
	check(one.vats[0].running and one.stock.bell == 0, "R11: a vat takes the reduced amount")
	check(one.assign("vat", 0, "") and one.stock.bell == 8, "and switching off returns what it took")


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
	var g := with(["overflow_valve"])
	# Bell Peppers go into Sweet Pepper Mash (10) and Bell Pepper Purée (1,000),
	# the two free vat recipes: 5 cycles of each.
	check(g.default_keep("bell") == (10 + 1000) * 5, "R13: Bell keeps 5 cycles of its unlocked recipes: %d" % g.default_keep("bell"))
	check(g.default_keep("bell_puree") == 5 * 5, "R13: Purée keeps 5 cycles of Sweet Pepper Relish, the free line recipe that takes it: %d" % g.default_keep("bell_puree"))
	g.stock.bell = 6000
	g.stock.bell_puree = 3
	g.advance(10)
	check(g.stock.bell == 5050 and g.stock.bell_puree == 3, "R13: sells only what's above the keep amount")
	check(close(g.stats.cash_earned, 950 * g.value("bell")), "R13: at its value")
	g.set_keep("bell_puree", -1)
	g.stock.bell_puree = 500
	g.advance(10)
	check(g.stock.bell_puree == 500, "R13: an item switched off is left alone")
	g.stock.table_mild = 100
	g.advance(10)
	check(g.stock.table_mild == 100, "R13: never bottles")
	check(not with([]).set_keep("bell", 3), "no keep amounts before the valve")


func test_smart_stockpiling() -> void:
	# Pin Land Survey 1 (Pimento and Bell Pepper Purée): the valve holds back
	# what it needs; researching it unpins.
	var g := with(["smart_stockpiling"])
	var cost: Dictionary = g.tech_cost("survey_1")
	check(g.set_pin("survey_1"), "pins Land Survey 1")
	check(g.pinned_need("bell_puree") == cost.bell_puree and g.pinned_need("pimento") == cost.pimento, "R14: what it needs is held back (%s)" % str(cost))
	g.set_keep("bell_puree", 0)
	g.stock.bell_puree = 12
	g.advance(10)
	check(g.stock.bell_puree == cost.bell_puree, "R13/R14: the valve keeps the pinned node's Purée, no more: %d" % g.stock.bell_puree)
	# Bottles: pinned Calloused Thumbs (10 Table Mild) keeps the Van's Auto-Sell
	# off them until it has 10.
	var b := with(["smart_stockpiling"])
	b.set_pin("calloused_thumbs")
	b.cash = 1000.0
	b.buy_slot("vat")
	b.buy_slot("line")
	b.set_keep("bell", -1)
	b.stock.bell = 100000
	b.advance(seconds(600.0))
	check(b.stock.table_mild >= 10 and b.stock.table_mild <= 11, "R14: Table Mild held back until 10 are in stock: %d" % b.stock.table_mild)
	check(b.stats.sold.table_mild > 0, "R14: then Auto-Sell works as set again")
	g.stock.pimento = cost.pimento
	check(g.research_node("survey_1") and g.pin == "", "researching the node unpins it")
	check(not with([]).set_pin("survey_1"), "no pins before the node")


func test_market_ticker() -> void:
	var g := with(["market_ticker"], 7)
	var sauces := g.unlocked_bottles()
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
		check(s[1] in sauces and s[2] in [2.0, 3.0], "R15: an unlocked sauce, ×2 or ×3: %s" % str(s))
	var h := with(["market_ticker"], 7)
	h.advance(seconds(4 * 3600.0))
	check(h.stats.spikes == starts.size() and JSON.stringify(h.ticker) == JSON.stringify(g.ticker), "R15: the same seed gives the same spikes")
	# A spike lasts 30 minutes and only changes that sauce's sale price.
	var k := with(["market_ticker"], 7)
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
	g.cash = 1e12
	g.buy_plot("bell")
	g.buy_plot("farm_02")
	g.plots.bell.harvest = 3
	for i in 5:
		g.buy_slot("vat")
	# Fast vats, so cycles come far more often than once a minute.
	for i in 5:
		g.assign("vat", i, "bell_puree")
		g.vats[i].speed = 30
	g.set_keep("bell", -1)
	g.stock.bell = 100000000
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
	var levels := func(id: String) -> int: return g.plots[id].harvest + g.plots[id].truck + g.plots[id].cargo
	check(absi(levels.call("bell") - levels.call("farm_02")) <= 1, "R16: levels go to the lowest farm, so they even out: %d and %d" % [levels.call("bell"), levels.call("farm_02")])
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
	# Franchise Auditors needs Heavy Flint Glass: sauces ×1.2 first.
	var bottle: float = g.value("bistro_verde") * 1.2
	var stock_value: float = 10 * bottle + 100 * g.value("bell")
	check(close(g.operation_value() - g.cash - g.stats.spent, stock_value * 1.2), "R17: stock counts 20% more")
	var before: float = g.cash
	g.sell_batch()
	check(close(g.cash - before, 10 * bottle), "R17: sales unchanged")


func test_hydroponic_bell() -> void:
	# R18 as v0.7 has it: IPM's Advanced Mining, every farm ×1.25.
	var g := with(["hydroponic_bell"])
	check(close(g.harvest_rate("bell"), 1.25) and close(g.harvest_rate("farm_02"), 0.25 * 1.25), "R18: every farm harvests ×1.25")
	var h := with(["hydroponic_jalapeno"])
	check(close(h.harvest_rate("farm_04"), 0.25 * 1.25 * 1.25), "Superior Mining: ×1.25 again (assumed multiplied)")


func test_ipm_farm_projects() -> void:
	var g := with(["highway_route", "bigger_crates", "pallet_racking"])
	check(close(g.truck_speed("farm_02"), 1.25 * 1.25) and g.truck_cargo("farm_02") == roundi(5 * 1.25 * 1.25), "Truck Tune-Up and Highway Route ×1.25 each; Bigger Crates and Pallet Racking too (%d)" % g.truck_cargo("farm_02"))
	# Crop Priority and Targeted Fertiliser: a farm's chosen crop first, +15%.
	var p := with(["targeted_fertiliser"])
	p.cash = 1e6
	p.buy_plot("farm_02")
	check(p.set_priority("farm_02", "pimento") and p.plots.farm_02.priority == "pimento", "Crop Priority picks a farm's crop")
	check(close(p.crop_rate("farm_02", "pimento"), 0.25 * 0.2 * 1.15), "Targeted Fertiliser: +15%% on it (%.4f)" % p.crop_rate("farm_02", "pimento"))
	check(not p.set_priority("farm_02", "cayenne"), "only a crop the farm grows")
	var q := with(["precision_fertiliser"])
	q.cash = 1e6
	q.buy_plot("farm_02")
	q.set_priority("farm_02", "pimento")
	check(close(q.crop_rate("farm_02", "pimento"), 0.25 * 0.2 * 1.3), "Precision Fertiliser: +30%, not added to 15%")
	q.plots.farm_02.field = {"bell": 10, "pimento": 10}
	q.plots.farm_02.trip = q.trip_seconds("farm_02") - 0.05
	q.tick()
	check(q.stock.pimento == 5 and q.stock.bell == 0, "the truck takes the priority crop first (%d Pimento, %d Bell)" % [q.stock.pimento, q.stock.bell])
	check(not with([]).set_priority("bell", "bell"), "no priority before Crop Priority")


func test_crossbreeding() -> void:
	var g := with(["crossbreed_ii"])
	g.cash = 1e9
	g.buy_plot("farm_04")   # Pimento 80, Poblano 20
	check(g.crossbreeds_left() == ["crossbreed_i", "crossbreed_ii"], "two Crossbreedings to use")
	check(g.crossbreed("crossbreed_i", "farm_04", "pimento"), "Crossbreed I on farm 4's Pimento")
	check(g.plot_crops("farm_04") == {"cascabel": 0.0} or g.plot_crops("farm_04").get("poblano", 0.0) > 0.0, "it now grows the rung above")
	check(close(g.plot_crops("farm_04").get("poblano", 0.0), 1.0), "Pimento (rung 2) becomes Poblano (rung 3): all of farm 4 is Poblano")
	check(not g.crossbreed("crossbreed_ii", "farm_04", "poblano"), "a farm is crossbred once")
	check(not g.crossbreed("crossbreed_i", "farm_02", "bell"), "a node is used once")
	g.buy_plot("farm_02")
	check(g.crossbreed("crossbreed_ii", "farm_02", "bell") and g.plots.farm_02.bred.to == "poblano", "Crossbreed II: Bell (rung 1) two rungs up is Poblano")
	var s := g.to_state()
	var h := Game.new()
	check(h.load_state(JSON.parse_string(JSON.stringify(s))) == "" and h.plots.farm_04.bred == g.plots.farm_04.bred and h.bred == g.bred, "crossbreeds survive a save")


func test_ipm_factory_projects() -> void:
	var g := with(["steam_jackets", "rotary_filler"])
	check(close(g.fx.vat_speed, 1.44) and close(g.fx.line_speed, 1.44), "Hotter Burners × Steam Jackets, Faster Cappers × Rotary Filler: ×1.44 each")
	g.cash = 1e9
	g.buy_slot("vat")
	check(close(g.slot_cycle("vat", 0), 8.0 / 1.44), "vats run faster")
	var club := with(["bulk_buyers_club"])
	check(close(club.slot_price("vat"), club.data.slots.vat.prices[0] * 0.5), "Bulk Buyer's Club: new vats and lines half price")
	var batch := with(["double_batch", "double_fill"], 3)
	batch.cash = 1e9
	batch.buy_slot("vat")
	batch.set_keep("bell", -1)
	batch.stock.bell = 10000000
	var cycles: float = 8.0 * 2000 / batch.slot_cycle("vat", 0)
	batch.advance(seconds(8.0 * 2000))
	var share: float = (batch.stats.made.sweet_mash - cycles) / cycles
	check(absf(share - 0.1) < 0.02, "Double Batch: 10%% of vat cycles make two (%.1f%%)" % (share * 100.0))


func test_pressure_cooker() -> void:
	var g := with(["pressure_cooker"])
	g.cash = 1e9
	g.buy_slot("vat")
	g.buy_slot("vat")
	g.buy_recipe("pimento_mash")
	g.assign("vat", 1, "pimento_mash")
	var plain: float = g.slot_cycle("vat", 1)
	var inputs: int = g.recipe_inputs("pimento_mash").pimento
	check(g.set_pressure(1, true) and not g.set_pressure(0, true), "one vat under pressure, not two")
	check(close(g.slot_cycle("vat", 1), plain / 2.0) and g.slot_inputs("vat", 1).pimento == ceili(inputs * 1.5), "×2 speed, inputs +50%")
	var two := with(["pressure_cooker_ii", "pressure_valve"])
	two.cash = 1e9
	two.buy_slot("vat")
	var cycle: float = two.slot_cycle("vat", 0)
	var bell: int = two.recipe_inputs("sweet_mash").bell
	two.set_pressure(0, true)
	check(close(two.slot_cycle("vat", 0), cycle / 4.0) and two.slot_inputs("vat", 0).bell == ceili(bell * 1.2), "Pressure Cooker II ×4; the Valve's +20%")
	check(with(["third_pressure_cooker"]).fx.pressure == 3, "three cookers with all three nodes")


func test_bumper_crop() -> void:
	# C4 (D043): Bumper Crop I–III, 10% a node, on each farm's harvest.
	check(close(with([], 11).fx.bumper, 0.0), "C4: no doubles without Bumper Crop")
	check(close(with(["bumper_crop_1"], 11).fx.bumper, 0.1) and close(with(["bumper_crop_2"], 11).fx.bumper, 0.2), "C4: 10% with I, 20% with II")
	var g := with(["bumper_crop_3"], 11)
	check(close(g.fx.bumper, 0.3), "C4: 30% with all three")
	g.cash = 1e9
	g.buy_plot("bell")
	var harvests := 10000
	var doubled := 0
	for i in harvests:
		g.plots.bell.grow = T.HARVEST_SECONDS - T.TICK_SECONDS
		g.plots.bell.spare.bell = 0.0
		var before: int = g.stats.harvested.bell
		g.tick()
		if g.stats.harvested.bell - before == 2:
			doubled += 1
	check(absf(doubled / float(harvests) - 0.3) <= 0.015, "C4: 30%% of harvests come in double: %.1f%%" % (doubled * 100.0 / harvests))
