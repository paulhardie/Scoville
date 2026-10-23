extends SceneTree
## Renders each onboarding stage and the factory to PNGs, for looking at after a
## UI change (tests don't catch layout faults). Needs a window, so not headless:
##   bash run_godot.sh --path . --quit-after 1200 -s res://tools/capture_ui.gd -- --out /abs/dir

const Main = preload("res://scenes/main.tscn")
const T = preload("res://src/core/tuning.gd")
const Game = preload("res://src/core/game.gd")
const Player = preload("res://src/sim/engaged_player.gd")


func _init() -> void:
	run.call_deferred()


func run() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--out")
	var out := args[i + 1] if i >= 0 and i + 1 < args.size() else OS.get_user_data_dir()
	DirAccess.make_dir_recursive_absolute(out)

	var screen := Main.instantiate()
	screen.save_path = ""
	screen.settings_path = ""
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

	# Mid-factory: the Tier 1 spine bought, the crate half used, some upgrades.
	var g = screen.game
	g.cash = 1234.5
	g.buy_plot("bell")
	g.buy_slot("vat")
	g.buy_slot("line")
	g.plots.bell.speed = 3
	g.plots.bell["yield"] = 1
	g.vats[0].speed = 2
	g.lines[0].crate = 23
	g.stock.bell = 48
	g.stock.sweet_mash = 3
	g.stock.table_mild = 17
	await _shot(out.path_join("factory.png"), 0.6)
	# Back after a night before the Delivery Van: sauce waiting, no cash (D046).
	screen._return_from(8 * 3600.0)
	await _shot(out.path_join("j1_return.png"), 0.2)
	screen.close_card()

	# 30 minutes of the pacing player: Tier 2 running, the Van researched.
	var played := Game.new()
	var player := Player.new()
	for t in roundi(30 * 60 / T.TICK_SECONDS):
		player.step(played)
		played.tick()
	g.load_state(played.to_state())
	await _shot(out.path_join("stage3_farms.png"), 1.0)
	(screen.find_child("Tab_processing", true, false) as Button).pressed.emit()
	await _shot(out.path_join("stage3_processing.png"), 0.2)
	(screen.find_child("Tab_tech", true, false) as Button).pressed.emit()
	(screen.find_child("Tech_bistro_blueprint", true, false) as Button).pressed.emit()
	await _shot(out.path_join("stage3_tech.png"), 0.2)

	# 1:40 of the pacing player: Tier 3, Heat, the valve and most of the tree.
	var late := Game.new()
	var late_player := Player.new()
	for t in roundi(100 * 60 / T.TICK_SECONDS):
		late_player.step(late)
		late.tick()
	g.load_state(late.to_state())
	screen._rebase_juice()
	g.heat = 74.0
	(screen.find_child("Tab_farms", true, false) as Button).pressed.emit()
	await _shot(out.path_join("v04_farms.png"), 0.3)
	# The Settings card at the foot of Farms (FEEL.md).
	var farms: ScrollContainer = screen.find_child("Page_farms", true, false)
	farms.scroll_vertical = 1000000
	await _shot(out.path_join("w2_settings.png"), 0.2)
	farms.scroll_vertical = 0
	(screen.find_child("Tab_processing", true, false) as Button).pressed.emit()
	await _shot(out.path_join("v04_processing.png"), 0.2)
	(screen.find_child("Tab_tech", true, false) as Button).pressed.emit()
	(screen.find_child("Tech_automated_piston", true, false) as Button).pressed.emit()
	await _shot(out.path_join("v04_tech.png"), 0.3)

	# Layout step 1 (LAYOUT.md): a station sheet, the Market tab, the warehouse.
	(screen.find_child("Tab_farms", true, false) as Button).pressed.emit()
	(screen.find_child("Manage_plot_bell", true, false) as Button).pressed.emit()
	(screen.find_child("Mode_10", true, false) as Button).pressed.emit()
	await _shot(out.path_join("l1_sheet.png"), 0.3)
	(screen.find_child("SheetDone", true, false) as Button).pressed.emit()
	screen.settings.buy_mode = "1"
	(screen.find_child("Tab_market", true, false) as Button).pressed.emit()
	await _shot(out.path_join("l1_market.png"), 0.3)
	screen.open_drawer()
	await _shot(out.path_join("l1_drawer.png"), 0.3)
	(screen.find_child("Drawer", true, false) as Control).visible = false

	# Back after a night: the "While you were away" card, capped.
	screen._return_from(9 * 3600.0 + 720.0)
	await _shot(out.path_join("v05_return.png"), 0.2)
	screen.close_card()

	# The Tech Tree just opened: nothing researched yet, the first node selected.
	var fresh := Game.new()
	var early := Player.new()
	while not fresh.tab_open("tech"):
		early.step(fresh)
		fresh.tick()
	g.load_state(fresh.to_state())
	(screen.find_child("Tech_jalapeno_blueprint", true, false) as Button).pressed.emit()
	await _shot(out.path_join("stage3_tech_open.png"), 0.2)
	(screen.find_child("Tab_hq", true, false) as Button).pressed.emit()
	await _shot(out.path_join("stage3_locked_hint.png"), 0.1)

	# HQ (v0.6b): a run worth $20M, then after a sale with two rooms and a draft.
	g.stats.cash_earned = 2e7
	g._note_value()
	(screen.find_child("Tab_hq", true, false) as Button).pressed.emit()
	await _shot(out.path_join("v06b_hq_sell.png"), 0.2)
	(screen.find_child("Tab_tech", true, false) as Button).pressed.emit()
	(screen.find_child("Tech_moruga_blueprint", true, false) as Button).pressed.emit()
	await _shot(out.path_join("w12_tier6_locked.png"), 0.2)
	(screen.find_child("Tab_hq", true, false) as Button).pressed.emit()
	g.prestige()
	g.account.credits = 40
	g.account.rooms = {"seed_vault": 3, "tasting_room": 1}
	g._refresh_fx()
	g.open_room()
	screen._refresh(false)
	await _shot(out.path_join("v06b_hq_draft.png"), 0.2)
	(screen.find_child("Tab_tech", true, false) as Button).pressed.emit()
	(screen.find_child("Tech_standard_operating_procedures", true, false) as Button).pressed.emit()
	await _shot(out.path_join("w12_sop.png"), 0.2)

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
