extends SceneTree
## The screen reveals itself as onboarding says (docs/ONBOARDING.md O1, O3, O4).

const Main = preload("res://scenes/main.tscn")
const T = preload("res://src/core/tuning.gd")

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

	screen.queue_free()
	await process_frame
	for failure in failures:
		printerr("FAIL: ", failure)
	print("%s: ui tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)
