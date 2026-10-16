extends SceneTree
## The screen builds, reports taps to the game and shows what's unlocked.

const Main = preload("res://scenes/main.tscn")

var failures: Array[String] = []
var checks := 0


func _init() -> void:
	run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func run() -> void:
	var screen := Main.instantiate()
	screen.save_path = ""
	root.add_child(screen)
	await process_frame

	var pick: Button = screen.find_child("Pick", true, false)
	check(pick != null, "the pick button exists")
	check(not screen._kitchen.visible and not screen._upgrades.visible, "kitchen and upgrades start hidden")
	for i in 25:
		pick.pressed.emit()
	check(screen.game.stats.peppers >= 25, "pressing the button picks peppers")
	check(screen._kitchen.visible, "the kitchen shows once it opens")
	screen._bottle_table.pressed.emit()
	check(screen.game.bottles.table == 1, "the bottle button bottles")
	check(screen._upgrades.visible, "upgrades show after the first bottle")
	check(not screen._jalapeno_row.visible, "jalapeños hidden until the patch")

	screen.queue_free()
	await process_frame
	for failure in failures:
		printerr("FAIL: ", failure)
	print("%s: ui tests (%d checks)" % ["PASS" if failures.is_empty() else "FAIL", checks])
	quit(0 if failures.is_empty() else 1)
