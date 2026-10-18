extends SceneTree
## The screen reveals itself as onboarding says (docs/ONBOARDING.md O1, O3, O4).

const Main = preload("res://scenes/main.tscn")
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


## Every visible Label and Button with text, outside the Blank Button.
func visible_text(node: Node) -> Array[String]:
	var found: Array[String] = []
	for child in node.get_children():
		if child is CanvasItem and not child.visible:
			continue
		if (child is Label or child is Button) and child.text != "":
			found.append(child.text)
		found.append_array(visible_text(child))
	return found


func run() -> void:
	var screen := Main.instantiate()
	screen.save_path = ""
	screen.settings_path = ""
	root.add_child(screen)
	await process_frame

	var blank: Button = screen.find_child("BlankButton", true, false)
	check(blank != null and blank.visible, "O1: the Blank Button is shown")
	check(blank != null and blank.text == "" and blank.icon == null, "O1: the Blank Button has no label")
	check(visible_text(screen).is_empty(), "O1: no text at the start: %s" % str(visible_text(screen)))

	blank.pressed.emit()
	await process_frame
	var counter: Label = screen.find_child("Counter", true, false)
	check(counter.visible and counter.text == "Bell Peppers: 1", "O3: the counter reads 'Bell Peppers: 1': %s" % counter.text)
	var bar: Control = screen.find_child("StatusBar", true, false)
	check(not bar.visible, "O4: no status bar after one press")

	for i in T.STAGE_1_PEPPERS - 1:
		blank.pressed.emit()
	await process_frame
	check(bar.visible, "O4: the status bar shows at 20 peppers")
	var texts := visible_text(screen)
	check("Cash: £0.00" in texts, "O4: it shows 'Cash: £0.00': %s" % str(texts))
	check("Sell Raw Peppers (£0.10/ea)" in texts, "O4: it shows the sell button: %s" % str(texts))

	var sell: Button = screen.find_child("SellRaw", true, false)
	sell.pressed.emit()
	await process_frame
	check("Cash: £2.00" in visible_text(screen) and counter.text == "Bell Peppers: 0", "selling updates cash and the counter")
	check(sell.disabled, "the sell button is disabled with no peppers")

	# Stage 2 (docs/FACTORY.md): the deck opens at £10 earned.
	var deck: Control = screen.find_child("Deck", true, false)
	check(not deck.visible, "no deck at £2 earned")
	var big := blank.size
	for i in 80:
		blank.pressed.emit()
	sell.pressed.emit()
	await create_timer(1.2).timeout
	check(deck.visible, "the deck shows at £10 earned")
	check(blank.size.x < big.x, "the Blank Button shrinks into the upper viewport: %s" % str(blank.size))
	check(blank.get_global_rect().end.y <= deck.get_global_rect().position.y + 1.0, "it sits above the deck")
	var plot_card: Control = screen.find_child("Card_plot_bell", true, false)
	var buy_vat: Control = screen.find_child("BuySlot_vat", true, false)
	var buy_line: Control = screen.find_child("BuySlot_line", true, false)
	check(plot_card.visible and buy_vat.visible and not buy_line.visible, "the plot and vat are offered, not the line")
	var buy_plot: Button = screen.find_child("Buy_plot_bell", true, false)
	check(not buy_plot.disabled, "£10 buys the plot")
	buy_plot.pressed.emit()
	await process_frame
	check(screen.game.plots.bell.owned and not buy_plot.visible, "the buy button buys it and goes")
	var speed: Button = screen.find_child("Upgrade_plot_bell_speed", true, false)
	check(speed.visible and speed.text.begins_with("Harvest Speed"), "its upgrades show: %s" % speed.text)

	# Stage 3 (O8): the nav bar at £400 Operation Value.
	var nav: Control = screen.find_child("Nav", true, false)
	check(not nav.visible, "O8: no nav bar before £400")
	screen.game.cash = 1000.0
	(screen.find_child("BuySlot_vat", true, false) as Button).pressed.emit()
	screen.game.account.best_ov = 400.0
	await create_timer(0.6).timeout
	check(nav.visible, "O8: the nav bar shows at £400")
	var tabs := []
	for tab in ["farms", "processing", "tech", "roster", "hq"]:
		tabs.append((screen.find_child("Tab_" + tab, true, false) as Button).text)
	check(tabs == ["Farms", "Processing", "[ ? ]", "[ ? ]", "[ ? ]"], "O8: Farms and Processing open, three [ ? ]: %s" % str(tabs))
	check(deck.get_global_rect().end.y <= nav.get_global_rect().position.y + 1.0, "the deck ends above the nav bar")
	(screen.find_child("Tab_processing", true, false) as Button).pressed.emit()
	await process_frame
	var vat_card: Control = screen.find_child("Card_vat_0", true, false)
	check((screen.find_child("Page_processing", true, false) as Control).visible and vat_card.is_visible_in_tree(), "Processing shows the vat")
	check((screen.find_child("Recipe_vat_0", true, false) as OptionButton).item_count == 2, "its picker offers Off and Sweet Pepper Mash")
	(screen.find_child("Tab_tech", true, false) as Button).pressed.emit()
	await process_frame
	check(not (screen.find_child("Page_tech", true, false) as Control).visible, "O9: a locked tab doesn't open")

	# O9: the Tech Tree at £750.
	screen.game.account.best_ov = 750.0
	await process_frame
	check((screen.find_child("Tab_tech", true, false) as Button).text == "Tech Tree", "O9: the Tech Tree tab opens at £750")
	(screen.find_child("Tab_tech", true, false) as Button).pressed.emit()
	await process_frame
	check((screen.find_child("Page_tech", true, false) as Control).visible, "the Tech Tree page shows")
	screen.game.stock.table_mild = 50
	(screen.find_child("Tech_jalapeno_blueprint", true, false) as Button).pressed.emit()
	await process_frame
	var research: Button = screen.find_child("Research", true, false)
	check(research.visible and not research.disabled, "the selected node can be researched")
	research.pressed.emit()
	await process_frame
	check(screen.game.is_researched("jalapeno_blueprint"), "Research researches it")
	check((screen.find_child("Card_plot_jalapeno", true, false) as Control).visible, "and the Jalapeño Plot appears on Farms")

	# v0.4: Heat, holding, Overdrive, the valve, pins (TECH_TREE.md).
	var Helpers = load("res://tests/button_tests.gd")
	var heat_bar: Control = screen.find_child("HeatBar", true, false)
	check(not heat_bar.visible, "no Heat bar before the Heat Meter")
	var g = screen.game
	for item in g.stock:
		g.stock[item] = 100000
	for node in ["heat_meter", "smart_stockpiling", "overdrive_turbines"]:
		Helpers.research_with_parents(g, node)
	await process_frame
	check(heat_bar.visible, "the Heat bar appears with the Heat Meter")
	g.heat = 0.0
	blank.pressed.emit()
	await process_frame
	# The screen's game is seeded from the clock, so a press may count twice
	# (Double-Tap): check the label against the Heat the game has.
	var bonus := "+%d%%" % roundi((g.heat_mult() - 1.0) * 100.0)
	check(g.heat > 0.0 and (screen.find_child("HeatLabel", true, false) as Label).text.contains(bonus), "a press shows its Heat bonus (%s): %s" % [bonus, (screen.find_child("HeatLabel", true, false) as Label).text])
	var presses: int = g.stats.presses
	blank.button_down.emit()
	await create_timer(1.1).timeout
	blank.button_up.emit()
	check(g.stats.presses - presses >= 2, "holding the button presses it (Ergonomic Grip): %d" % (g.stats.presses - presses))
	(screen.find_child("Tab_processing", true, false) as Button).pressed.emit()
	await process_frame
	var od: Button = screen.find_child("Overdrive", true, false)
	check(od.is_visible_in_tree() and not od.disabled, "the Overdrive button is ready")
	od.pressed.emit()
	await process_frame
	check(g.overdrive_active() and od.disabled, "it runs Overdrive, then waits")
	check((screen.find_child("ValveCard", true, false) as Control).is_visible_in_tree(), "the valve card shows")
	var toggle: Button = screen.find_child("ValveToggle_bell", true, false)
	toggle.pressed.emit()
	await process_frame
	check(g.keep_amount("bell") == -1 and toggle.text == "On", "a valve row can be switched off")
	(screen.find_child("Tab_tech", true, false) as Button).pressed.emit()
	(screen.find_child("Tech_automated_piston", true, false) as Button).pressed.emit()
	await process_frame
	var pin_button: Button = screen.find_child("Pin", true, false)
	check(pin_button.visible, "Pin shows for a node not yet researched")
	pin_button.pressed.emit()
	await process_frame
	check(g.pin == "automated_piston" and pin_button.text == "Unpin", "Pin pins it")
	(screen.find_child("Tab_farms", true, false) as Button).pressed.emit()
	await process_frame
	check((screen.find_child("Upgrade_plot_bell_quality", true, false) as Button).text.begins_with("Crop Quality"), "plots offer Crop Quality")

	screen.queue_free()
	await process_frame
	await test_return_card()
	await test_hq()
	await test_feel()
	for failure in failures:
		printerr("FAIL: ", failure)
	print("%s: ui tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)


## A clock the test moves by hand.
class FakeClock:
	var t := 1000000.0

	func now() -> float:
		return t


## X8: the "While you were away" card, with a fake clock.
func test_return_card() -> void:
	var fake := FakeClock.new()
	var screen := Main.instantiate()
	screen.save_path = ""
	screen.settings_path = ""
	screen.clock = fake
	root.add_child(screen)
	await process_frame
	var g = screen.game
	g.revealed.deck = true
	g.revealed.status_bar = true
	g.cash = 100.0
	g.buy_plot("bell")
	var card: Control = screen.find_child("ReturnCard", true, false)
	check(not card.visible, "X8: no card at the start")

	var ticks: int = g.stats.ticks
	fake.t += 30.0
	await process_frame
	check(not card.visible, "X8: no card after 30 s away")
	check(g.stats.ticks - ticks >= 300, "X8: but the 30 s are caught up")

	fake.t += 3 * 3600.0
	await process_frame
	check(card.visible, "X8: the card after 3 hours away")
	var text := func(key): return (screen.find_child("Return_" + key, true, false) as Label)
	check(text.call("time").text == "3 h 0 m", "X8: it shows the time away: %s" % text.call("time").text)
	check(not text.call("cap").visible, "X8: no cap note under the cap")
	check(text.call("cash").text.begins_with("+£") and text.call("ov").text.begins_with("Operation Value +£"), "X8: cash and Operation Value")
	check(text.call("made").text.contains("Bell Peppers"), "X8: and what was made: %s" % text.call("made").text)
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	card.gui_input.emit(tap)
	check(not card.visible, "X8: a tap closes it")

	fake.t += 10 * 3600.0
	await process_frame
	check(card.visible and text.call("cap").visible and text.call("cap").text.contains("4 h 0 m at 50%"), "X8: 10 hours away notes the cap: %s" % text.call("cap").text)
	screen.close_card()

	# Closing the app and coming back: the save carries the time.
	screen.save_path = "user://offline_test_save.json"
	screen._save()
	screen.queue_free()
	await process_frame
	fake.t += 2 * 3600.0
	var again := Main.instantiate()
	again.save_path = "user://offline_test_save.json"
	again.clock = fake
	root.add_child(again)
	await process_frame
	var card2: Control = again.find_child("ReturnCard", true, false)
	check(card2.visible and again.last_return.away >= 7200.0 - 1.0, "X8: reopening 2 hours after saving shows the card")
	again.queue_free()
	DirAccess.remove_absolute("user://offline_test_save.json")
	await process_frame


## Q9: the HQ tab sells the franchise on a second tap, and opens rooms through
## the draft (docs/PRESTIGE.md).
func test_hq() -> void:
	var screen := Main.instantiate()
	screen.save_path = ""
	screen.settings_path = ""
	root.add_child(screen)
	await process_frame
	var g = screen.game
	g.revealed = {"counter": true, "status_bar": true, "deck": true}
	g.stats.cash_earned = 2e6
	g._note_value()
	(screen.find_child("Tab_hq", true, false) as Button).pressed.emit()
	await process_frame
	var sell: Button = screen.find_child("SellFranchise", true, false)
	check(sell.is_visible_in_tree() and not sell.disabled and sell.text == "Sell (+13 credits)", "Q9: HQ offers the sale: %s" % sell.text)
	sell.pressed.emit()
	await process_frame
	check(g.account.prestiges == 0 and sell.text == "Tap again to sell", "Q9: the first tap only asks again")
	sell.pressed.emit()
	await process_frame
	check(g.account.prestiges == 1 and g.account.credits == 13, "Q9: the second tap sells")
	check(sell.disabled, "Q9: and the new run can't sell yet")
	var open: Button = screen.find_child("OpenRoom", true, false)
	open.pressed.emit()
	await process_frame
	var picks: Array = g.account.draft
	check(picks.size() == 2 and not open.visible, "Q9: opening a room deals two cards")
	var card: Button = screen.find_child("Draft_" + picks[0], true, false)
	check(card != null and card.is_visible_in_tree(), "Q9: both show as cards")
	card.pressed.emit()
	await process_frame
	check(g.account.rooms.has(picks[0]), "Q9: tapping one opens it")
	var up: Button = screen.find_child("LevelRoom_" + picks[0], true, false)
	check(up != null and up.text == "Lv 2: 2" and not up.disabled, "Q9: its row offers Level 2 for 2 credits: %s" % (up.text if up else "none"))
	up.pressed.emit()
	await process_frame
	check(g.account.rooms[picks[0]] == 2 and g.account.credits == 6, "Q9: and levels it")
	screen.queue_free()
	await process_frame


## K1–K5: the Blank Button's click and buzz (docs/FEEL.md).
func test_feel() -> void:
	var screen := Main.instantiate()
	screen.save_path = ""
	screen.settings_path = ""
	root.add_child(screen)
	await process_frame
	check(visible_text(screen).is_empty(), "K5: Stage 0 still shows no text")
	check(not (screen.find_child("SettingsCard", true, false) as Control).is_visible_in_tree(), "K5: no Settings card before the deck")
	var g = screen.game
	var blank: Button = screen.find_child("BlankButton", true, false)
	blank.pressed.emit()
	check(screen.clicks_played == 1 and screen.vibrations == 1, "K1/K3: a finger press clicks once and buzzes once")
	# Grip and the Piston press through the game: silent and still.
	g.revealed = {"counter": true, "status_bar": true, "deck": true}
	g.account.best_ov = 1e9
	for item in g.stock:
		g.stock[item] = 100000
	for node in ["ergonomic_grip", "automated_piston"]:
		Helpers.research_with_parents(g, node)
	g.set_holding(true)
	g.advance(100)
	g.set_holding(false)
	check(g.stats.presses > 20 and screen.clicks_played == 1 and screen.vibrations == 1, "K1/K3: Grip and Piston presses (%d) make no click and no buzz" % (g.stats.presses - 1))
	var pitches := {}
	var low := INF
	var high := -INF
	for i in 200:
		g.heat = 0.0
		screen._feel_press()
		pitches[snappedf(screen.last_pitch, 0.001)] = true
		low = minf(low, screen.last_pitch)
		high = maxf(high, screen.last_pitch)
	check(low >= 0.92 - 1e-6 and high <= 1.08 + 1e-6 and pitches.size() > 20, "K2: pitch at no Heat stays within 0.92–1.08 and varies (%.3f–%.3f, %d values)" % [low, high, pitches.size()])
	var sum := 0.0
	for i in 200:
		g.heat = T.HEAT_MAX
		screen._feel_press()
		sum += screen.last_pitch
	check(absf(sum / 200.0 - 1.2) < 0.02, "K2: at full Heat it's 1.2× on average (%.3f)" % (sum / 200.0))
	await process_frame
	check((screen.find_child("SettingsCard", true, false) as Control).is_visible_in_tree(), "K5: the Settings card shows with the deck")
	var sound: Button = screen.find_child("Setting_sound", true, false)
	var buzz: Button = screen.find_child("Setting_vibration", true, false)
	check(sound.text == "Sound: On" and buzz.text == "Vibration: On", "K4: both switches start on")
	screen.settings_path = "user://settings_test.json"
	sound.pressed.emit()
	buzz.pressed.emit()
	await process_frame
	var clicks: int = screen.clicks_played
	var buzzes: int = screen.vibrations
	blank.pressed.emit()
	check(screen.clicks_played == clicks and screen.vibrations == buzzes and sound.text == "Sound: Off", "K4: with both off, a press is silent and still")
	screen.queue_free()
	await process_frame
	var again := Main.instantiate()
	again.save_path = ""
	again.settings_path = "user://settings_test.json"
	root.add_child(again)
	await process_frame
	check(not again.settings.sound and not again.settings.vibration, "K4: the switches survive reopening")
	again.queue_free()
	DirAccess.remove_absolute("user://settings_test.json")
	await process_frame
