extends SceneTree
## Renders the screen at the start and mid-game to PNGs, for looking at after a
## UI change (tests don't catch layout faults). Needs a window, so not headless:
##   bash run_godot.sh --path . -s res://tools/capture_ui.gd -- --out /abs/dir

const Main = preload("res://scenes/main.tscn")
const G = preload("res://src/core/guesses.gd")


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

	var g = screen.game
	g.cash = 123.45
	g.bell = 37.0
	g.jalapeno = 9
	g.heat = 62.0
	g.levels = {"capper": 2, "picker": 1, "shears": 3}
	g.unlocked = {"bottling": true, "upgrades": true, "jalapeno": true}
	g.stats.peppers = 812.0
	g.stats.bottles = 31
	g.stats.revenue = 214.5
	g.stats.boils = 4
	await _shot(out.path_join("mid.png"))

	g.heat = G.HEAT_MAX
	g.boil_ticks = 64
	await _shot(out.path_join("boil.png"))

	print("PASS: captured to ", out)
	quit()



func _shot(path: String) -> void:
	for f in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
