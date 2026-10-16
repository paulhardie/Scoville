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

	screen.queue_free()
	await process_frame
	for failure in failures:
		printerr("FAIL: ", failure)
	print("%s: ui tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)
