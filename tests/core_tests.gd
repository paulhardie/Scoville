extends SceneTree
## Onboarding Stages 0–1 (docs/ONBOARDING.md O2–O7) and saves.

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
	print("%s: core tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


func pressed(times: int) -> Game:
	var g := Game.new()
	for i in times:
		g.press()
	return g


func test_fresh_game_has_everything() -> void:
	# D044 retires O1: nothing waits to be revealed.
	var g := Game.new()
	check(g.revealed.counter and g.revealed.status_bar and g.revealed.deck, "L10: everything is open from the start")
	check(g.plot_offered("bell") and g.slot_offered("vat") and g.tab_open("farms"), "L10: the plot and the first vat are on sale from the start")
	check(g.stock.bell == 0 and g.cash == 0.0, "starts empty")


func test_each_press_picks_one() -> void:
	var g := Game.new()
	for i in 50:
		check(g.press() == 1, "O2: a press reports 1 pepper")
	check(g.stock.bell == 50 and g.stats.bell_picked == 50 and g.stats.presses == 50, "O2: 50 presses, 50 peppers")


func test_next_action() -> void:
	# L13–L14 (D044): the early run's one next action.
	var g := Game.new()
	check(g.next_action() == {"do": "press", "id": ""}, "L13: a fresh game: tap the button")
	for i in 30:
		g.press()
	check(g.next_action().do == "press", "L13: 30 peppers don't cover the $50 plot: keep tapping")
	for i in 20:
		g.press()
	check(g.next_action().do == "sell_raw", "L13: 50 peppers cover it: sell them")
	g.sell_raw()
	check(g.next_action() == {"do": "buy_plot", "id": "bell"}, "L13: then buy the Bell Pepper Plot")
	g.buy_plot("bell")
	check(g.next_action().do == "press", "L13: then save up for Vat 1")
	g.cash = 1000.0
	check(g.next_action() == {"do": "buy_slot", "id": "vat"}, "L13: Vat 1 once cash covers it")
	g.buy_slot("vat")
	check(g.next_action() == {"do": "buy_slot", "id": "line"}, "L13: then Line 1")
	g.buy_slot("line")
	check(g.next_action().do == "press", "L13: no bottles yet: tap")
	g.stock.table_mild = 3
	check(g.next_action().do == "sell_batch", "L13: bottles held: Sell Batch")
	g.sell_batch()
	g.cash = 0.0
	check(g.next_action().do == "press", "L13: farm 2 next, cash short and nothing to sell: tap")
	# Under the Tech Tree's $7,500: since v0.7 cash on hand counts in
	# Operation Value (Galaxy Value).
	g.cash = 1000.0
	check(g.next_action() == {"do": "buy_plot", "id": "farm_02"}, "L13: farm 2 (v0.7: IPM's second planet)")
	g.buy_plot("farm_02")
	check(g.next_action() == {"do": "buy_plot", "id": "farm_03"}, "L13: farm 3")
	g.buy_plot("farm_03")
	check(g.next_action().is_empty(), "L14: the Tech Tree not open yet: nothing to ring, the goal bar shows")
	g.account.best_ov = T.TAB_THRESHOLDS.tech
	check(g.next_action() == {"do": "tab", "id": "tech"}, "L13: once it opens: open the Tech Tree")
	g.stock.table_mild = 100
	g.research_node("calloused_thumbs")
	check(g.next_action().is_empty(), "L14: after the first research the sequence is done")


func test_sell_raw() -> void:
	var g := pressed(37)
	check(g.sell_raw(), "O5: selling works with peppers held")
	var worth: float = 37 * g.value("bell")
	check(close(g.cash, worth) and g.stock.bell == 0, "O5: 37 peppers sell for $%.2f: $%.2f" % [worth, g.cash])
	check(not g.sell_raw() and close(g.cash, worth), "O5: selling with none does nothing")
	check(close(g.stats.cash_earned, worth), "earned cash is counted")


func test_reveals_stay() -> void:
	var g := pressed(20)
	g.sell_raw()
	var s: Dictionary = g.to_state()
	s.run.revealed = {"counter": false, "status_bar": false, "deck": false}
	var c := Game.new()
	check(c.load_state(JSON.parse_string(JSON.stringify(s))) == "", "O6: a save loads")
	check(c.revealed.counter and c.revealed.status_bar and c.revealed.deck, "D044: an older save that hid things opens on the full dashboard")


func test_save_round_trip() -> void:
	var g := pressed(23)
	g.sell_raw()
	g.press()
	var c := Game.new()
	var problem := c.load_state(JSON.parse_string(JSON.stringify(g.to_state(), "", false, true)))
	check(problem == "", "a save loads: " + problem)
	check(JSON.stringify(c.to_state()) == JSON.stringify(g.to_state()), "a loaded save matches what was saved")


func test_bad_saves_are_refused() -> void:
	var g := pressed(30)
	var before := JSON.stringify(g.to_state())
	check(g.load_state("nope") != "", "O7: a non-object is refused")
	check(g.load_state({"version": 99}) != "", "O7: a newer version is refused")
	var s := g.to_state()
	s.run.erase("stock")
	check(g.load_state(s) != "", "O7: a save missing a field is refused")
	s = g.to_state()
	s.run.stats = 3
	check(g.load_state(s) != "", "O7: a malformed field is refused")
	check(JSON.stringify(g.to_state()) == before, "O7: a refused save changes nothing")
