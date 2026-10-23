extends SceneTree
## The screen reveals itself as onboarding says (docs/ONBOARDING.md O1, O3, O4).

const Main = preload("res://scenes/main.tscn")
const T = preload("res://src/core/tuning.gd")
const S = preload("res://src/ui/style.gd")
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

	# L10 (D044): the full dashboard from the first second.
	var blank: Button = screen.find_child("BlankButton", true, false)
	check(blank != null and blank.visible and blank.text == "" and blank.icon == null, "L10: the Blank Button is shown, unlabelled")
	var bar: Control = screen.find_child("StatusBar", true, false)
	var nav: Control = screen.find_child("Nav", true, false)
	var deck: Control = screen.find_child("Deck", true, false)
	var factory: Control = screen.find_child("Factory", true, false)
	check(bar.visible and nav.visible and deck.visible and factory.visible, "L10: status bar, tab selectors, panel and factory view all show at the start")
	check(absf(nav.get_global_rect().position.y - (blank.get_global_rect().end.y + 36.0)) < 1.0 and deck.get_global_rect().position.y >= nav.get_global_rect().end.y - 1.0, "L10: the selectors sit directly under the viewport, the panel under them")
	var tabs := []
	for tab in ["farms", "processing", "tech", "market", "roster", "hq"]:
		tabs.append((screen.find_child("Tab_" + tab, true, false) as Button).text)
	check(tabs == ["Farms", "Processing\n$4K", "Tech Tree\n$7.5K", "Market\nVan", "Shift Roster\n$150K", "HQ\n$10M"], "L11: every tab shows, the locked ones with what opens them: %s" % str(tabs))
	var goal: Label = screen.find_child("Goal", true, false)
	var ring: Control = screen.find_child("Ring", true, false)
	await settle()
	check(goal.text == "Next: tap the button" and ring.visible and ring.get_global_rect().encloses(blank.get_global_rect()), "L13: the button is ringed and named: %s" % goal.text)

	blank.pressed.emit()
	await process_frame
	var counter: Label = screen.find_child("Counter", true, false)
	check(counter.visible and counter.text == "Bell Peppers: 1", "O3: the counter reads 'Bell Peppers: 1': %s" % counter.text)
	for i in 19:
		blank.pressed.emit()
	await process_frame
	var texts := visible_text(screen)
	check("Cash: $0.00" in texts and "Sell Raw Peppers ($1.00/ea)" in texts, "O4: Cash and the sell button: %s" % str(texts))

	var sell: Button = screen.find_child("SellRaw", true, false)
	sell.pressed.emit()
	await process_frame
	check("Cash: $20.00" in visible_text(screen) and counter.text == "Bell Peppers: 0", "selling updates cash and the counter")
	check(sell.disabled, "the sell button is disabled with no peppers")
	for i in 80:
		blank.pressed.emit()
	await process_frame
	await settle()
	check(goal.text.begins_with("Next: sell") and ring.get_global_rect().encloses(sell.get_global_rect()), "L13: with enough peppers for the plot, Sell Raw Peppers is ringed: %s" % goal.text)
	sell.pressed.emit()
	await create_timer(0.5).timeout
	var buy_plot: Button = screen.find_child("Buy_plot_bell", true, false)
	check(goal.text.begins_with("Next: buy the Bell Pepper Plot") and ring.get_global_rect().encloses(buy_plot.get_global_rect()), "L13: then the plot's Buy is ringed: %s" % goal.text)
	(screen.find_child("Tab_tech", true, false) as Button).pressed.emit()
	await process_frame
	check(not (screen.find_child("Page_tech", true, false) as Control).visible, "L11: a locked tab doesn't open")
	var plot_card: Control = screen.find_child("Card_plot_bell", true, false)
	var buy_vat: Control = screen.find_child("BuySlot_vat", true, false)
	var buy_line: Control = screen.find_child("BuySlot_line", true, false)
	check(plot_card.visible and buy_vat.visible and not buy_line.visible, "the plot and vat are offered, not the line")
	check(not buy_plot.disabled, "$100 buys the plot")
	buy_plot.pressed.emit()
	await process_frame
	check(screen.game.plots.bell.owned and not buy_plot.visible, "the buy button buys it and goes")
	var manage: Button = screen.find_child("Manage_plot_bell", true, false)
	check(manage.visible and screen.find_child("Upgrade_plot_bell_speed", true, false) == null, "L3: the card shows Manage, not its upgrades")
	manage.pressed.emit()
	await process_frame
	var speed: Button = screen.find_child("Upgrade_plot_bell_speed", true, false)
	check(speed != null and speed.is_visible_in_tree() and speed.text.begins_with("Harvest Speed"), "L3: Manage opens its sheet with the upgrades: %s" % (speed.text if speed else "none"))
	(screen.find_child("SheetDone", true, false) as Button).pressed.emit()
	await process_frame

	# Processing opens at $4,000 Operation Value, as it did.
	screen.game.cash = 10000.0
	(screen.find_child("BuySlot_vat", true, false) as Button).pressed.emit()
	screen.game.account.best_ov = T.TAB_THRESHOLDS.processing
	await create_timer(0.6).timeout
	check((screen.find_child("Tab_processing", true, false) as Button).text == "Processing", "L11: Processing opens at $%.0f" % T.TAB_THRESHOLDS.processing)
	(screen.find_child("Tab_processing", true, false) as Button).pressed.emit()
	await process_frame
	var vat_card: Control = screen.find_child("Card_vat_0", true, false)
	check((screen.find_child("Page_processing", true, false) as Control).visible and vat_card.is_visible_in_tree(), "Processing shows the vat")
	check((screen.find_child("Recipe_vat_0", true, false) as OptionButton).item_count == 2, "its picker offers Off and Sweet Pepper Mash")
	(screen.find_child("Tab_tech", true, false) as Button).pressed.emit()
	await process_frame
	check(not (screen.find_child("Page_tech", true, false) as Control).visible, "O9: a locked tab doesn't open")

	# O9: the Tech Tree at $7,500.
	screen.game.account.best_ov = T.TAB_THRESHOLDS.tech
	await process_frame
	check((screen.find_child("Tab_tech", true, false) as Button).text == "Tech Tree", "O9: the Tech Tree tab opens at $%.0f" % T.TAB_THRESHOLDS.tech)
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
	check(not (screen.find_child("ValveCard", true, false) as Control).is_visible_in_tree(), "L8: the valve isn't on Processing")
	(screen.find_child("Tab_market", true, false) as Button).pressed.emit()
	await process_frame
	check((screen.find_child("ValveCard", true, false) as Control).is_visible_in_tree() and (screen.find_child("VanCard", true, false) as Control).is_visible_in_tree(), "L8: Market holds the valve and Auto-Sell")
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
	(screen.find_child("Manage_plot_bell", true, false) as Button).pressed.emit()
	await process_frame
	check((screen.find_child("Upgrade_plot_bell_cargo", true, false) as Button).text.begins_with("Cargo") and screen.find_child("Upgrade_plot_bell_quality", true, false) == null, "C1: plots offer Cargo, not Crop Quality")
	(screen.find_child("SheetDone", true, false) as Button).pressed.emit()
	await process_frame

	screen.queue_free()
	await process_frame
	await test_return_card()
	await test_return_waiting()
	await test_hq()
	await test_after_sale()
	await test_layout()
	await test_raw_sales()
	await test_dashboard()
	await test_bottling()
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
	g.cash = g.plot_price("bell")
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
	check(text.call("cash").text.begins_with("+$") and text.call("ov").text.begins_with("Operation Value +$"), "X8: cash and Operation Value")
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


## J1–J2 (D046): before the Delivery Van a return shows the sauce waiting to
## sell, not "+$0.00 cash"; with the Van selling everything, the cash line.
func test_return_waiting() -> void:
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
	g.cash = 1e6
	g.buy_plot("bell")
	g.buy_slot("vat")
	g.buy_slot("line")
	var text := func(key): return (screen.find_child("Return_" + key, true, false) as Label)
	fake.t += 3 * 3600.0
	await process_frame
	var r: Dictionary = screen.last_return
	check(r.cash_earned == 0.0 and r.bottles_waiting > 0.0 and is_equal_approx(r.bottles_waiting, g.bottles_value()),
		"J1: no Van, 3 hours away: $%.0f of bottles waiting, matching Sell Batch's $%.0f; $%.0f cash" % [r.bottles_waiting, g.bottles_value(), r.cash_earned])
	check(text.call("waiting").visible and text.call("waiting").text == "+%s of sauce waiting: tap Sell Batch" % screen._money(g.bottles_value()),
		"J1: the card says so: %s" % text.call("waiting").text)
	check(not text.call("cash").visible, "J1: and no +$0.00 cash line")
	screen.close_card()

	g.sell_batch()
	for item in g.stock:
		g.stock[item] = 100000
	Helpers.research_with_parents(g, "delivery_van")
	for item in g.stock:
		g.stock[item] = 0
	check(g.has_van(), "J2: the Delivery Van researched")
	fake.t += 3 * 3600.0
	await process_frame
	r = screen.last_return
	check(r.cash_earned > 0.0 and text.call("cash").visible and text.call("cash").text == "+%s cash" % screen._money(r.cash_earned),
		"J2: with the Van, the cash line: %s" % text.call("cash").text)
	check(not text.call("waiting").visible, "J2: and no waiting line (%d bottles held)" % g.bottles_held())
	screen.close_card()
	# After the Van, bottles held back from Auto-Sell still show as waiting.
	g.set_autosell("table_mild", 50)
	fake.t += 3 * 3600.0
	await process_frame
	check(text.call("waiting").visible and is_equal_approx(screen.last_return.bottles_waiting, g.bottles_value()) and g.bottles_held() > 0,
		"J2: Auto-Sell at 50%%, the held bottles show as waiting: %s" % text.call("waiting").text)
	screen.queue_free()
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
	g.stats.cash_earned = 1e8
	g._note_value()
	(screen.find_child("Tab_hq", true, false) as Button).pressed.emit()
	await process_frame
	var sell: Button = screen.find_child("SellFranchise", true, false)
	check(sell.is_visible_in_tree() and not sell.disabled and sell.text == "Sell (+30 credits)", "Q9: HQ offers the sale at $100M: %s" % sell.text)
	sell.pressed.emit()
	await process_frame
	check(g.account.prestiges == 0 and sell.text == "Tap again to sell", "Q9: the first tap only asks again")
	sell.pressed.emit()
	await process_frame
	check(g.account.prestiges == 1 and g.account.credits == 30, "Q9: the second tap sells")
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
	check(g.account.rooms[picks[0]] == 2 and g.account.credits == 23, "Q9: and levels it")
	screen.queue_free()
	await process_frame


## Q14: after-sale nodes say so on the Tech Tree, and Standard Operating
## Procedures says what it does (docs/PRESTIGE.md part 2).
func test_after_sale() -> void:
	var screen := Main.instantiate()
	screen.save_path = ""
	screen.settings_path = ""
	root.add_child(screen)
	await process_frame
	var g = screen.game
	g.revealed = {"counter": true, "status_bar": true, "deck": true}
	g.stats.cash_earned = 2e6
	g._note_value()
	(screen.find_child("Tab_tech", true, false) as Button).pressed.emit()
	(screen.find_child("Tech_moruga_blueprint", true, false) as Button).pressed.emit()
	await process_frame
	check("Opens after your first franchise sale." in visible_text(screen), "Q14: a Tier 6 node says it opens after the first sale")
	g.account.prestiges = 1
	(screen.find_child("Tech_standard_operating_procedures", true, false) as Button).pressed.emit()
	await process_frame
	var texts := visible_text(screen)
	check(not "Opens after your first franchise sale." in texts, "Q14: not once the franchise has been sold")
	var says := false
	for t in texts:
		says = says or t.contains("researches itself, free")
	check(says, "Q14: Standard Operating Procedures says what it does")
	screen.queue_free()
	await process_frame


## L3–L7: station sheets, the bottle pop and coin, Cash's count-up, the goal
## bar and the warehouse (docs/LAYOUT.md).
func test_layout() -> void:
	var path := "user://layout_settings_test.json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var screen := Main.instantiate()
	screen.save_path = ""
	screen.settings_path = path
	root.add_child(screen)
	await settle()
	var g = screen.game
	g.revealed = {"counter": true, "status_bar": true, "deck": true}
	g.cash = 1e9
	g.buy_plot("bell")
	g.buy_slot("vat")
	g.buy_slot("line")
	await settle()

	# L3: Manage carries "!" exactly when an upgrade is affordable.
	var manage: Button = screen.find_child("Manage_plot_bell", true, false)
	check(manage.text.contains("!"), "L3: Manage shows ! with upgrades affordable: %s" % manage.text)
	g.cash = 0.0
	await settle()
	check(not manage.text.contains("!"), "L3: and not without: %s" % manage.text)
	manage.pressed.emit()
	await settle()
	(screen.find_child("Mode_10", true, false) as Button).pressed.emit()
	var ten: float = g.plot_upgrade_cost_n("bell", "speed", 10)
	g.cash = ten - 1.0
	await settle()
	var speed: Button = screen.find_child("Upgrade_plot_bell_speed", true, false)
	check(speed.disabled and speed.text.contains("→ 10"), "L3: ×10 is off a dollar short, showing ten levels: %s" % speed.text)
	g.cash = ten
	await settle()
	speed.pressed.emit()
	await settle()
	check(g.plots.bell.speed == 10, "L3: ×10 buys ten levels (Lv %d)" % g.plots.bell.speed)
	(screen.find_child("Mode_max", true, false) as Button).pressed.emit()
	g.cash = 5e6
	var can: int = g.plot_levels_affordable("bell", "yield")
	(screen.find_child("Upgrade_plot_bell_yield", true, false) as Button).pressed.emit()
	await settle()
	check(can > 1 and g.plots.bell.yield == can, "L3: Max buys all %d it can (Lv %d)" % [can, g.plots.bell.yield])
	(screen.find_child("SheetDone", true, false) as Button).pressed.emit()
	var again := Main.instantiate()
	again.save_path = ""
	again.settings_path = path
	root.add_child(again)
	await settle()
	check(again.settings.buy_mode == "max", "L3: the buy mode survives a restart (%s)" % again.settings.buy_mode)
	again.queue_free()

	# L4: pops and coins, held to their rates however fast bottles come.
	var pops: int = screen.pops_shown
	var coins: int = screen.coins_flown
	var t0 := Time.get_ticks_msec()
	for i in 40:
		g.stats.made.table_mild += 3
		g.stats.cash_earned += 50.0
		await settle()
	var secs := (Time.get_ticks_msec() - t0) / 1000.0
	var p: int = screen.pops_shown - pops
	var c: int = screen.coins_flown - coins
	check(p >= 1 and p <= ceili(secs * S.POPS_PER_SECOND) + 1, "L4: %d pops in %.2f s (at most %.0f a second)" % [p, secs, S.POPS_PER_SECOND])
	check(c >= 1 and c <= ceili(secs * S.COINS_PER_SECOND) + 1, "L4: %d coins in %.2f s (at most %.0f a second)" % [c, secs, S.COINS_PER_SECOND])

	# L5: Cash counts up to a sale, then shows it exactly.
	g.cash = 1000.0
	await settle()
	await settle()
	g.cash += 5000.0
	await settle()
	var mid: float = screen._shown_cash
	check(mid > 1000.0 and mid < 6000.0, "L5: Cash is counting up two frames after a $5,000 sale: $%.2f" % mid)
	await create_timer(S.COUNT_UP + 0.15).timeout
	check(screen._cash.text == "Cash: $6,000.00", "L5: and shows it all after %.2f s: %s" % [S.COUNT_UP, screen._cash.text])

	# L6: the goal bar, once the early sequence is done (L14, D044).
	var goal: Label = screen.find_child("Goal", true, false)
	g.stats.sold.table_mild = 1
	g.plots.poblano.owned = true
	g.plots.jalapeno.owned = true
	g.stats.researched = 1
	g.account.best_ov = T.TAB_THRESHOLDS.processing
	await settle()
	check(goal.visible and goal.text.begins_with("Tech Tree at"), "L6: before the Tech Tree, it shows the way there: %s" % goal.text)
	g.account.best_ov = T.TAB_THRESHOLDS.tech
	await settle()
	check(goal.text.begins_with("Next: ") and goal.text.contains("/"), "L6: then the next node and its scarcest item: %s" % goal.text)
	g.stats.cash_earned = T.PRESTIGE_OV * 0.64
	await settle()
	check(goal.text.contains("Sale 6"), "L6: and the sale from half way: %s" % goal.text)

	# L7: the stock strip and the warehouse.
	g.stock.sweet_mash = 7
	g.stock.table_mild = 4
	g.stock.bistro_verde = 2
	g.stats.made.bistro_verde = 2
	await settle()
	var strip: Label = screen.find_child("Counter", true, false)
	check(strip.max_lines_visible == 1 and not strip.text.contains("Sweet") and strip.text.contains("Table Mild"), "L7: one line of Bell Peppers and bottles: %s" % strip.text)
	var tap := InputEventMouseButton.new()
	tap.pressed = true
	tap.button_index = MOUSE_BUTTON_LEFT
	strip.gui_input.emit(tap)
	await settle()
	var drawer: Control = screen.find_child("Drawer", true, false)
	var listed := visible_text(drawer)
	var has_mash := false
	for t in listed:
		has_mash = has_mash or t.begins_with("Sweet Pepper Mash")
	check(drawer.visible and "MASH" in listed and "BOTTLES" in listed and has_mash, "L7: tapping it opens the warehouse by kind: %s" % str(listed))
	screen.queue_free()
	await settle()
	DirAccess.remove_absolute(path)


## A3 (ECONOMY.md, D041): every crop sells raw from its plot's card.
func test_raw_sales() -> void:
	var screen := Main.instantiate()
	screen.save_path = ""
	screen.settings_path = ""
	root.add_child(screen)
	await settle()
	var g = screen.game
	g.revealed = {"counter": true, "status_bar": true, "deck": true}
	g.cash = 1e6
	await settle()
	check((screen.find_child("Card_plot_poblano", true, false) as Control).visible, "A1: the Poblano Plot is on Farms with the deck")
	g.buy_plot("poblano")
	g.stock.poblano = 12
	g.stock.bell = 5
	await settle()
	var sell: Button = screen.find_child("Sell_plot_poblano", true, false)
	check(sell.visible and not sell.disabled and sell.text.contains("12"), "A3: the card offers its 12 Poblano Peppers: %s" % sell.text)
	var cash: float = g.cash
	sell.pressed.emit()
	await settle()
	check(g.stock.poblano == 0 and is_equal_approx(g.cash - cash, 12 * g.value("poblano")) and g.stock.bell == 5, "A3: they sell at their value, and nothing else does")
	check(sell.disabled, "A3: with none left the button is off")
	screen.queue_free()
	await settle()


## L12–L13 (D044): the factory view, and the ring on another tab's selector.
func test_dashboard() -> void:
	var screen := Main.instantiate()
	screen.save_path = ""
	screen.settings_path = ""
	root.add_child(screen)
	await settle()
	var g = screen.game
	var factory = screen.find_child("Factory", true, false)
	check(factory._tiles("plot").is_empty() and factory._tiles("vat").is_empty(), "L12: no stations, no tiles (each floor names what goes there)")
	g.cash = 1e6
	g.buy_plot("bell")
	g.buy_slot("vat")
	await settle()
	check(factory._tiles("plot").size() == 1 and factory._tiles("vat").size() == 1 and factory._tiles("line").is_empty(), "L12: a tile per owned station on its floor")
	g.plots.bell["yield"] = 100
	var dots_before: int = screen.dots_shown
	var seconds := 3.0
	await create_timer(seconds).timeout
	var dots: int = screen.dots_shown - dots_before
	check(dots > 0 and dots <= ceili(seconds * S.DOTS_PER_SECOND) + 1, "L12: dots climb as crops reach stock, at most %d a second (%d in %.0f s)" % [S.DOTS_PER_SECOND, dots, seconds])
	check(factory._tiles("plot")[0][1], "L12: a backed-up plot's tile shows orange")
	# The next action on another tab: its selector is ringed.
	g.account.best_ov = T.TAB_THRESHOLDS.processing
	g.buy_slot("line")
	g.stats.sold.table_mild = 1
	for item in g.stock:
		g.stock[item] = 0
	(screen.find_child("Tab_processing", true, false) as Button).pressed.emit()
	await settle()
	await settle()
	var ring: Control = screen.find_child("Ring", true, false)
	var farms_tab: Control = screen.find_child("Tab_farms", true, false)
	check(g.next_action() == {"do": "buy_plot", "id": "poblano"} and ring.visible and ring.get_global_rect().encloses(farms_tab.get_global_rect()), "L13: the Poblano Plot is on Farms, so the Farms selector is ringed")
	screen.queue_free()
	await settle()


## K6–K9 (FEEL.md, D045): bottling's clink, the first-bottle buzz and the
## bottle in the factory view.
func test_bottling() -> void:
	var screen := Main.instantiate()
	screen.save_path = ""
	screen.settings_path = ""
	root.add_child(screen)
	await settle()
	var g = screen.game
	g.cash = 1e6
	g.buy_plot("bell")
	g.buy_slot("vat")
	g.buy_slot("line")
	await settle()
	var factory = screen.find_child("Factory", true, false)
	var clinks: int = screen.clinks_played
	var dropped: int = factory.bottles_dropped
	g.stats.made.table_mild += 1
	await create_timer(0.4).timeout
	check(screen.clinks_played == clinks + 1 and factory.bottles_dropped == dropped + 1, "K6/K9: a bottle pop clinks once and drops one bottle (%d, %d)" % [screen.clinks_played - clinks, factory.bottles_dropped - dropped])
	check(is_equal_approx(screen.last_clink_pitch, 1.0), "K7: Tier 1 clinks at 1.0 (%.2f)" % screen.last_clink_pitch)
	check(screen.bottle_buzzes == 1, "K8: the first Table Mild buzzes once")
	check(factory.bottles.size() == 1 and factory.bottles[0][2] == S.TIER_TINTS[0], "K9: the bottle is tinted Tier 1's colour")
	g.stats.made.table_mild += 1
	await create_timer(0.4).timeout
	check(screen.bottle_buzzes == 1, "K8: the second doesn't buzz")
	await create_timer(S.BOTTLE_SECONDS).timeout
	check(factory.bottles.is_empty(), "K9: bottles are gone within %.1f s" % S.BOTTLE_SECONDS)
	var tier: int = g.data.items.bistro_verde.tier
	screen.settings.vibration = false
	g.stats.made.bistro_verde += 1
	await create_timer(0.4).timeout
	check(is_equal_approx(screen.last_clink_pitch, 1.0 - S.BOTTLE_TIER_PITCH * (tier - 1)) and screen.last_clink_pitch < 1.0, "K7: a Tier %d sauce clinks lower (%.2f)" % [tier, screen.last_clink_pitch])
	check(screen.bottle_buzzes == 1, "K8: with Vibration off a first bottle doesn't buzz")
	screen.settings.sound = false
	clinks = screen.clinks_played
	dropped = factory.bottles_dropped
	g.stats.made.table_mild += 1
	await create_timer(0.4).timeout
	check(screen.clinks_played == clinks and factory.bottles_dropped == dropped + 1, "K6: with Sound off no clink, the bottle still drops")
	screen.settings.sound = true
	clinks = screen.clinks_played
	var seconds := 2.0
	var until: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < until:
		g.stats.made.table_mild += 5
		await process_frame
	var n: int = screen.clinks_played - clinks
	check(n >= 1 and n <= ceili(seconds * S.POPS_PER_SECOND) + 1, "K6: bottling flat out, at most %d clinks a second (%d in %.0f s)" % [S.POPS_PER_SECOND, n, seconds])
	screen.queue_free()
	await settle()


## Two frames: the tree signals a frame before the screen's _process runs,
## so one isn't enough for the screen to have shown a change.
func settle() -> void:
	await process_frame
	await process_frame


## K1–K5: the Blank Button's click and buzz (docs/FEEL.md).
func test_feel() -> void:
	var screen := Main.instantiate()
	screen.save_path = ""
	screen.settings_path = ""
	root.add_child(screen)
	await process_frame
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
