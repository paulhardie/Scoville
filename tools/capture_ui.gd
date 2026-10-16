extends SceneTree
## Renders each onboarding stage to PNGs, for looking at after a UI change
## (tests don't catch layout faults). Needs a window, so not headless:
##   bash run_godot.sh --path . -s res://tools/capture_ui.gd -- --out /abs/dir

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
