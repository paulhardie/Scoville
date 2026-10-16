extends SceneTree
## Renders each onboarding stage and the factory to PNGs, for looking at after a
## UI change (tests don't catch layout faults). Needs a window, so not headless:
##   bash run_godot.sh --path . --quit-after 1200 -s res://tools/capture_ui.gd -- --out /abs/dir

const Main = preload("res://scenes/main.tscn")
const T = preload("res://src/core/tuning.gd")


func _init() -> void:
	run.call_deferred()


func run() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	var out := args[i + 1] if i >= 0 and i + 1 < args.size() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(out)

	var screen := Main.instantiate()
	screen.save_path = ""
	root.add_child(screen)
	await _shot(out.path_join("start.png"))

	var blank: Button = screen.find_child("BlankButton", true, false)
	for p in 3:
		blank.pressed.emit()
	await _shot(out.path_join("counter.png"), 1.0)

	for p in T.STAGE_1_PEPPERS:
		blank.pressed.emit()
	await _shot(out.path_join("status_bar.png"), 1.0)

	for p in 80:
		blank.pressed.emit()
	(screen.find_child("SellRaw", true, false) as Button).pressed.emit()
	await _shot(out.path_join("deck.png"), 1.2)

	# Mid-factory: everything bought, the crate half used, some upgrades.
	var g = screen.game
	g.cash = 1234.5
	for station in ["plot", "vat", "line"]:
		g.buy(station)
	g.stations.plot.speed = 3
	g.stations.plot.yield = 1
	g.stations.vat.speed = 2
	g.stations.line.crate = 23
	g.stock.bell = 48
	g.stock.sweet_mash = 3
	g.stock.table_mild = 17
	await _shot(out.path_join("factory.png"), 0.6)

	print("PASS: captured to ", out)
	quit()


## Waits `settle` seconds so entrances finish, then saves the frame.
func _shot(path: String, settle: float = 0.0) -> void:
	if settle > 0.0:
		await create_timer(settle).timeout
	for f in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
