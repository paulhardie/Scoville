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


func test_fresh_game_reveals_nothing() -> void:
	var g := Game.new()
	check(not g.revealed.counter and not g.revealed.status_bar, "O1: nothing revealed at the start")
	check(g.stock.bell == 0 and g.cash == 0.0, "starts empty")


func test_each_press_picks_one() -> void:
	var g := Game.new()
	for i in 50:
		check(g.press() == 1, "O2: a press reports 1 pepper")
	check(g.stock.bell == 50 and g.stats.bell_picked == 50 and g.stats.presses == 50, "O2: 50 presses, 50 peppers")


func test_counter_appears_on_first_press() -> void:
	var g := Game.new()
	check(not g.revealed.counter, "O3: no counter before the first press")
	g.press()
	check(g.revealed.counter, "O3: the counter appears on the first press")


func test_status_bar_at_twenty() -> void:
	check(not pressed(T.STAGE_1_PEPPERS - 1).revealed.status_bar, "O4: no status bar at 19 peppers")
	check(pressed(T.STAGE_1_PEPPERS).revealed.status_bar, "O4: the status bar appears at 20 peppers")


func test_sell_raw() -> void:
	var early := pressed(5)
	check(not early.sell_raw() and early.stock.bell == 5, "can't sell before the status bar appears")
	var g := pressed(37)
	check(g.sell_raw(), "O5: selling works with peppers held")
	var worth: float = 37 * g.value("bell")
	check(close(g.cash, worth) and g.stock.bell == 0, "O5: 37 peppers sell for $%.2f: $%.2f" % [worth, g.cash])
	check(not g.sell_raw() and close(g.cash, worth), "O5: selling with none does nothing")
	check(close(g.stats.cash_earned, worth), "earned cash is counted")


func test_reveals_stay() -> void:
	var g := pressed(T.STAGE_1_PEPPERS)
	g.sell_raw()
	check(g.revealed.counter and g.revealed.status_bar, "O6: reveals stay after selling to zero")
	var c := Game.new()
	check(c.load_state(JSON.parse_string(JSON.stringify(g.to_state()))) == "", "O6: a save loads")
	check(c.revealed.counter and c.revealed.status_bar, "O6: reveals stay after a reload")


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
	s.run.erase("revealed")
	check(g.load_state(s) != "", "O7: a save missing a field is refused")
	s = g.to_state()
	s.run.stats = 3
	check(g.load_state(s) != "", "O7: a malformed field is refused")
	check(JSON.stringify(g.to_state()) == before, "O7: a refused save changes nothing")
