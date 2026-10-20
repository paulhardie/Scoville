extends SceneTree
## Layout step 1's rules (docs/LAYOUT.md L1–L2): number formats, and buying
## several upgrade levels at once.

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const Main = preload("res://src/ui/main.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func run() -> void:
	for method in get_method_list():
		if String(method.name).begins_with("test_"):
			call(method.name)
	for failure in failures:
		printerr("FAIL: ", failure)
	print("%s: layout tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


func test_numbers() -> void:
	var money := {9999.99: "$9,999.99", 10000.0: "$10.0K", 12345.0: "$12.3K", 999000.0: "$999K", 999999.0: "$1.00M",
		2931411.49: "$2.93M", 757000000.0: "$757M", 1234000000.0: "$1.23B", 0.0: "$0.00", 5.0: "$5.00"}
	for amount in money:
		check(Main._money(amount) == money[amount], "L1: %.2f shows as %s (got %s)" % [amount, money[amount], Main._money(amount)])
	var counts := {9999: "9999", 10000: "10.0K", 4500000: "4.50M", 999999: "1.00M"}
	for n in counts:
		check(Main._count(n) == counts[n], "L1: %d counts as %s (got %s)" % [n, counts[n], Main._count(n)])


static func owned(cash: float) -> Game:
	var g := Game.new({}, 1)
	g.revealed.deck = true
	g.cash = 1e12
	g.buy_plot("bell")
	g.buy_slot("vat")
	g.cash = cash
	return g


func test_buy_ten() -> void:
	var g := owned(0.0)
	var ten := g.plot_upgrade_cost_n("bell", "speed", 10)
	var sum := 0.0
	for i in 10:
		sum += g.plot_upgrade_cost("bell", "speed", i)
	check(absf(ten - sum) < 1e-6, "L2: ten levels cost the next ten prices together")
	g.cash = ten - 0.01
	check(g.upgrade_plot_n("bell", "speed", 10) == 0 and g.plots.bell.speed == 0, "L2: ten aren't bought a cent short")
	g.cash = ten
	check(g.upgrade_plot_n("bell", "speed", 10) == 10 and g.plots.bell.speed == 10 and absf(g.cash) < 1e-6, "L2: and are at the price (cash left %.2f)" % g.cash)
	var v := owned(0.0)
	v.cash = v.slot_upgrade_cost_n("vat", 0, 10)
	check(v.upgrade_slot_n("vat", 0, 10) == 10 and v.vats[0].speed == 10, "L2: a slot buys ten the same way")


func test_max() -> void:
	var g := owned(5e6)
	var n := g.plot_levels_affordable("bell", "yield")
	check(n >= 2, "L2: $5M covers several Yield levels (%d)" % n)
	check(g.upgrade_plot_n("bell", "yield", n) == n and g.cash < g.plot_upgrade_cost("bell", "yield"), "L2: Max buys %d and leaves less than the next level's price" % n)
	var q := owned(1e15)
	var can := q.plot_levels_affordable("bell", "quality")
	check(can == T.CROP_QUALITY_MAX and q.upgrade_plot_n("bell", "quality", can) == can and q.plot_upgrade_cost("bell", "quality") == INF, "L2: Crop Quality stops at its cap of %d (Max saw %d)" % [T.CROP_QUALITY_MAX, can])
	check(owned(0.0).plot_levels_affordable("bell", "speed") == 0, "L2: nothing affordable, nothing to buy")
