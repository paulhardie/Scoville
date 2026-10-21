extends SceneTree
## The North Wing and Heat (docs/TECH_TREE.md R5–R8, H1–H3).

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
	print("%s: button tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


func seconds(s: float) -> int:
	return roundi(s / T.TICK_SECONDS)


## A game with the Tech Tree open, rich in everything, with these nodes (and
## their parents) researched.
static func with(nodes: Array, seed_value: int = 1) -> Game:
	var g := Game.new({}, seed_value)
	g.revealed.deck = true
	g.revealed.status_bar = true
	g.account.best_ov = 1e9
	for item in g.stock:
		g.stock[item] = 100000
	for node in nodes:
		research_with_parents(g, node)
	for item in g.stock:
		g.stock[item] = 0
	return g


static func research_with_parents(g: Game, node: String) -> void:
	for need in g.data.tech[node].needs:
		if not g.is_researched(need):
			research_with_parents(g, need)
	if not g.is_researched(node):
		g.research_node(node)


func test_double_tap() -> void:
	var g := with(["double_tap"])
	var n := 10000
	var picked := 0
	for i in n:
		picked += g.press()
	var share: float = g.stats.doubles / float(n)
	check(share >= 0.09 and share <= 0.11, "R5: %.1f%% of presses register twice (9–11%%)" % (share * 100.0))
	check(picked == (n + g.stats.doubles) * g.tap_yield(), "R5: a double picks twice")
	check(g.stats.presses == n + g.stats.doubles, "R5: and counts as two presses")
	var h := with(["double_tap", "heat_meter"], 3)
	var heat_from := 0.0
	var doubled := false
	for i in 200:
		var before_doubles: int = h.stats.doubles
		h.heat = 0.0
		h.press()
		if h.stats.doubles > before_doubles:
			heat_from = h.heat
			doubled = true
			break
	check(doubled and close(heat_from, 2 * T.HEAT_PER_PRESS), "R5: a double adds Heat twice: %.1f" % heat_from)
	check(Game.new().press() == 1 and Game.new().stats.doubles == 0, "no doubles before the node")


func test_ergonomic_grip() -> void:
	var g := with(["ergonomic_grip"])
	g.set_holding(true)
	g.advance(seconds(10.0))
	var held: int = g.stats.presses - g.stats.doubles
	check(held == 20, "R6: held for 10 s, 2 presses a second: %d" % held)
	g.set_holding(false)
	var before: int = g.stats.presses
	g.advance(seconds(10.0))
	check(g.stats.presses == before, "R6: released, it stops")
	var no_grip := with(["calloused_thumbs"])
	no_grip.set_holding(true)
	no_grip.advance(seconds(5.0))
	check(no_grip.stats.presses == 0, "holding does nothing without the Grip")


func test_overclock() -> void:
	for node in ["overclock_1", "overclock_2", "overclock_3"]:
		var g := with([node, "slot_expansion_1"])
		g.fx.double = 0.0  # one press is one press here
		var cut: float = g.fx.overclock
		g.cash = 1e6
		g.buy_slot("vat")
		g.buy_slot("vat")
		g.stock.bell = 10
		g.vats[1].recipe = ""
		g._start_cycles()
		g.advance(seconds(1.0))
		var running: float = g.vats[0].progress
		var idle: float = g.vats[1].progress
		g.press()
		check(close(g.vats[0].progress, running + cut), "R7: %s takes %.2f s off a running vat" % [node, cut])
		check(g.vats[1].progress == idle, "R7: not off an idle one")
		g.vats[0].progress = g.slot_cycle("vat", 0) - 0.01
		g.press()
		check(g.vats[0].progress <= g.slot_cycle("vat", 0) + 1e-9, "R7: never past the end of the cycle")
	check(close(with(["overclock_3"]).fx.overclock, 0.15), "Overclock III replaces, not adds: 0.15 s")


func test_piston() -> void:
	var g := with(["automated_piston"])
	g.advance(seconds(60.0))
	var presses: int = g.stats.presses - g.stats.doubles
	check(presses == 60, "R8: 60 presses in 60 s with no input: %d" % presses)
	check(g.stock.bell == (presses + g.stats.doubles) * g.tap_yield(), "R8: with Calloused Thumbs and Double-Tap")
	check(g.stats.doubles > 0 and g.heat < 10.0, "R8: Double-Tap applies; Heat can't build at 1 a second (%.1f)" % g.heat)


func test_heat_basics() -> void:
	var none := with(["ergonomic_grip"])
	for i in 50:
		none.press()
	check(none.heat == 0.0, "H1: no Heat before the Heat Meter")
	var g := with(["heat_meter"])
	g.press()
	check(close(g.heat, T.HEAT_PER_PRESS), "H1: +5 a press")
	for i in 100:
		g.press()
	check(g.heat == T.HEAT_MAX, "H1: never above 100")
	g.advance(seconds(1.0))
	check(close(g.heat, T.HEAT_MAX - T.HEAT_DRAIN, 1e-6), "H1: −12 a second: %.2f" % g.heat)
	g.advance(seconds(20.0))
	check(g.heat == 0.0, "H1: never below 0")
	var slow := with(["slow_burn"])
	slow.heat = 50.0
	slow.advance(seconds(1.0))
	check(close(slow.heat, 44.0, 1e-6), "H1: −6 a second with Slow Burn: %.2f" % slow.heat)


func test_heat_on_sales() -> void:
	var g := with(["heat_meter", "delivery_van", "overflow_valve"])
	g.heat = 60.0
	var mult := 1.0 + 0.5 * 0.6
	check(close(g.heat_mult(), mult), "H2: 60%% Heat is ×%.2f" % mult)
	g.stock.table_mild = 10
	var ov := g.operation_value()
	var batch: float = 10 * g.value("table_mild")
	check(close(ov, g.stats.cash_earned + batch), "H2: stock is valued as normal")
	var before: float = g.cash
	g.sell_batch()
	check(close(g.cash - before, batch * mult), "H2: Sell Batch gets the bonus")
	g.stock.bell = 100
	before = g.cash
	g.sell_raw()
	check(close(g.cash - before, 100 * g.value("bell") * mult), "H2: so do raw peppers")
	g.cash = 1e6
	g.buy_plot("bell")
	g.buy_slot("vat")
	g.buy_slot("line")
	g.lines[0].crate = 0
	g.stock.sweet_mash = 1
	g._start_cycles()
	before = g.stats.cash_earned
	var sold_before: int = g.stats.sold.table_mild
	g.heat = 100.0
	g.advance(seconds(8.0))
	check(g.stats.sold.table_mild - sold_before == 1, "an Auto-Sold bottle")
	check(g.stats.cash_earned - before > g.value("table_mild"), "H2: Auto-Sell gets the bonus: $%.2f for a $%.2f bottle" % [g.stats.cash_earned - before, g.value("table_mild")])
	var v := with(["heat_meter", "overflow_valve"])
	v.set_keep("bell", 0)
	v.stock.bell = 50
	v.heat = 100.0
	before = v.stats.cash_earned
	for i in 10:
		v.tick()
		if v.stock.bell == 0:
			break
	check(v.stock.bell == 0 and close(v.stats.cash_earned - before, 50 * v.value("bell") * v.heat_mult()), "H2: so do valve sales")


func test_heat_steady_states() -> void:
	# H3: what holds Heat, run for ten minutes from full and from empty.
	var cases := [
		["3 presses a second", ["heat_meter"], 3.0, false, true],
		["Ergonomic Grip", ["heat_meter", "ergonomic_grip"], 0.0, true, false],
		["Grip with Slow Burn", ["slow_burn", "ergonomic_grip"], 0.0, true, true],
		["Piston (it needs Slow Burn)", ["automated_piston"], 0.0, false, false],
	]
	for c in cases:
		for start in [0.0, 100.0]:
			var g := with(c[1])
			g.heat = start
			g.set_holding(c[3])
			var acc := 0.0
			var low := 100.0
			for i in seconds(600.0):
				acc += c[2] * T.TICK_SECONDS
				while acc >= 1.0:
					acc -= 1.0
					g.press()
				g.tick()
				if i > seconds(300.0):
					low = minf(low, g.heat)
			if c[4]:
				check(low >= 90.0, "H3: %s holds Heat (from %d%%, lowest %.0f%%)" % [c[0], start, low])
			else:
				check(g.heat < 10.0, "H3: %s can't hold Heat (from %d%%, ends %.0f%%)" % [c[0], start, g.heat])


## A Forager's Luck game owning these ingredient stations, with their recipes.
static func forager(crops: Array, nodes: Array, seed_value: int = 1) -> Game:
	var g := with(["foragers_luck"] + nodes, seed_value)
	for crop in crops:
		g.plots[crop].owned = true
	return g


func test_forage_rate() -> void:
	var g := forager(["vinegar"], ["brine_blueprint"])
	g.stock.vinegar = 1000000   # always the shortest (the only one); stock doesn't change the chance
	for i in 10000:
		g.press()
	var share: float = float(g.stats.foraged) / g.stats.presses
	check(share >= 0.02 and share <= 0.03, "T1: %.2f%% of presses forage (want 2–3%%)" % (share * 100.0))
	check(g.stats.harvested.vinegar == g.stats.foraged * g.plot_yield("vinegar"), "T1: each drop is one harvest of the Vinegar Cask")


func test_forage_goes_to_the_shortest() -> void:
	var g := forager(["vinegar", "garlic"], ["brine_blueprint", "paste_blueprint"])
	g.plots.garlic["yield"] = 10   # yield and speed upgrades count (D041)
	g.plots.garlic.speed = 10
	g.stock.vinegar = 50   # 5 cycles of Pickled Brine (10)
	g.stock.garlic = 40    # 2 cycles of Garlic Paste (20)
	check(g._shortest_ingredient() == "garlic", "T2: Garlic (2 cycles) is shorter than Vinegar (5)")
	while g.stats.foraged == 0:
		g.press()
	var drop := floori(g.plot_yield_exact("garlic") * g.data.plots.garlic.seconds / g.plot_cycle("garlic"))
	check(g.stock.garlic == 40 + drop and drop > g.data.plots.garlic["yield"], "T2: the drop is one Garlic harvest at its base cycle, upgrades included (got %d, want %d)" % [g.stock.garlic - 40, drop])
	check(g.stock.vinegar == 50, "T2: and nothing else")
	g.stock.garlic = 50
	g.stock.vinegar = 20
	check(g._shortest_ingredient() == "vinegar", "T2: Vinegar (2 cycles) is shorter than Garlic (2.5)")
	g.stock.vinegar = 25
	check(g._shortest_ingredient() == "vinegar", "T2: ties go in data order")
	var unused := forager(["vinegar", "garlic"], ["brine_blueprint"])
	unused.stock.vinegar = 1000
	check(unused._shortest_ingredient() == "vinegar", "T2: an ingredient no researched recipe uses is never the shortest")
	check(forager(["jalapeno"], ["brine_blueprint"])._shortest_ingredient() == "", "T2: peppers aren't ingredients")


func test_forage_needs_a_station() -> void:
	var a := with(["foragers_luck", "brine_blueprint"], 7)
	var b := with(["double_tap", "brine_blueprint"], 7)
	for i in 1000:
		a.press()
		b.press()
	check(a.stats.foraged == 0, "T3: nothing drops with no ingredient station")
	check(a.rng.state == b.rng.state, "T3: and nothing is drawn from the random stream")


func test_forage_while_away() -> void:
	var g := forager(["vinegar"], ["brine_blueprint", "automated_piston"])
	g.catch_up(3600.0)
	var expected: float = 3600.0 * g.offline_speed() * 1.1 * 0.025
	check(g.stats.foraged > expected * 0.6 and g.stats.foraged < expected * 1.4, "T2: the Piston forages while away (%d drops, about %d expected)" % [g.stats.foraged, roundi(expected)])
	check(g.stats.harvested.vinegar >= g.stats.foraged * g.plot_yield("vinegar"), "T2: and the drops count as harvested")
