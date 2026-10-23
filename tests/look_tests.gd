extends SceneTree
## The pixel-art trial's look (docs/LOOK.md PX1-PX6): whole pixels, one font,
## every character drawn, no flat boxes, readable colours, and a screen that fits,
## checked on the real screen at the stages tools/capture_ui.gd visits.

const Main = preload("res://scenes/main.tscn")
const T = preload("res://src/core/tuning.gd")
const S = preload("res://src/ui/style.gd")
const Kit = preload("res://src/ui/pixel_kit.gd")
const Game = preload("res://src/core/game.gd")
const Player = preload("res://src/sim/engaged_player.gd")

const BOXES := ["panel", "normal", "hover", "pressed", "disabled", "background", "fill"]

var failures: Array[String] = []
var checks := 0
var screen


func _init() -> void:
	run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)


func run() -> void:
	test_whole_pixels()
	test_contrast()
	await test_screens()
	for f in failures:
		print("  FAIL ", f)
	print("%s: look tests (%d checks)" % ["FAIL" if failures else "PASS", checks])
	quit()


## PX1: Nearest filtering, and every kit texture and margin at exactly PIXEL_SCALE.
func test_whole_pixels() -> void:
	check(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter") == 0, "PX1: the default texture filter is Nearest")
	var src: Theme = load(Kit.THEME)
	var t := Kit.theme()
	var k := S.PIXEL_SCALE
	var boxes := 0
	for type in src.get_type_list():
		for n in src.get_stylebox_list(type):
			var a := src.get_stylebox(n, type)
			if not a is StyleBoxTexture:
				continue
			var b := t.get_stylebox(n, type) as StyleBoxTexture
			boxes += 1
			check(b.texture.get_size() == a.texture.get_size() * k, "PX1: %s/%s is %s, not %d× %s" % [type, n, b.texture.get_size(), k, a.texture.get_size()])
			check(_same_pixels(a.texture.get_image(), b.texture.get_image(), k), "PX1: %s/%s is the kit's art, each pixel %d×%d" % [type, n, k, k])
			for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
				check(b.get_texture_margin(side) == (a as StyleBoxTexture).get_texture_margin(side) * k, "PX1: %s/%s's 9-slice margin %d is %d×" % [type, n, side, k])
				if a.get_content_margin(side) >= 0.0:
					check(b.get_content_margin(side) == a.get_content_margin(side) * k, "PX1: %s/%s's content margin %d is %d×" % [type, n, side, k])
		for n in src.get_icon_list(type):
			var ia := src.get_icon(n, type)
			check(t.get_icon(n, type).get_size() == ia.get_size() * k, "PX1: icon %s/%s is %d×" % [type, n, k])
	check(boxes >= 20, "PX1: the kit's boxes were all looked at (%d)" % boxes)
	check(Kit.icon("coin").get_size() == Vector2(16, 16) * k, "PX1: icons are %d×" % k)


## Each pixel of `small`, drawn k×k in `big`.
func _same_pixels(small: Image, big: Image, k: int) -> bool:
	if small.is_compressed():
		small.decompress()
	for y in big.get_height():
		for x in big.get_width():
			if not small.get_pixel(x / k, y / k).is_equal_approx(big.get_pixel(x, y)):
				return false
	return true


func _whole_disc(size: Vector2) -> bool:
	return is_equal_approx(size.x, size.y) and is_equal_approx(fmod(size.x, S.BLANK_DISC_PX), 0.0)


## PX5: WCAG contrast on the colours the surfaces really are (their art's centre).
func test_contrast() -> void:
	var inset := _centre(Kit.box(&"InsetPanel"))
	var panel := _centre(Kit.box(&"PanelContainer")) * Color(S.PANEL_SHADE, S.PANEL_SHADE, S.PANEL_SHADE)
	var surfaces := {"inset card": inset, "panel": panel, "background": S.BG}
	var body := {"TEXT": S.TEXT, "DIM": S.DIM, "GREEN": S.GREEN, "HEAT": S.HEAT, "ORANGE": S.ORANGE, "GOLD": S.GOLD}
	for s in surfaces:
		for c in body:
			var r := _contrast(body[c], surfaces[s])
			check(r >= 4.5, "PX5: %s on the %s is %.2f:1, under 4.5" % [c, s, r])
		var m := _contrast(S.MUTED, surfaces[s])
		check(m >= 3.0, "PX5: MUTED on the %s is %.2f:1, under 3" % [s, m])
	# The kit's buttons: dark ink, deeper when pressed; grey "not yet" boxes at 3:1.
	var t := Kit.theme()
	for state in ["normal", "hover"]:
		var r := _contrast(t.get_color(&"font_color", &"Button"), _centre(Kit.box(&"Button", state)))
		check(r >= 4.5, "PX5: button text, %s, is %.2f:1" % [state, r])
	var p := _contrast(t.get_color(&"font_pressed_color", &"Button"), _centre(Kit.box(&"Button", &"pressed")))
	check(p >= 4.5, "PX5: button text, pressed, is %.2f:1" % p)
	var d := _contrast(t.get_color(&"font_disabled_color", &"Button"), _centre(Kit.box(&"Button", &"disabled")))
	check(d >= 3.0, "PX5: disabled button text is %.2f:1" % d)
	var g := _contrast(S.GREEN, inset)
	check(g >= 4.5, "PX5: a researched node's text is %.2f:1" % g)


func _centre(box: StyleBox) -> Color:
	var img := (box as StyleBoxTexture).texture.get_image()
	return img.get_pixel(img.get_width() / 2, img.get_height() / 2) * (box as StyleBoxTexture).modulate_color


func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _luminance(c: Color) -> float:
	var ch := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * ch.call(c.r) + 0.7152 * ch.call(c.g) + 0.0722 * ch.call(c.b)


## PX2-PX4 and PX6 on the screen, stage by stage.
func test_screens() -> void:
	# Headless, the window isn't the phone's shape; lay out at the design size.
	root.size = Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width"), ProjectSettings.get_setting("display/window/size/viewport_height"))
	screen = Main.instantiate()
	screen.save_path = ""
	screen.settings_path = ""
	root.add_child(screen)
	await look("stage 0")
	var blank: Button = screen.find_child("BlankButton", true, false)
	check(_whole_disc(blank.size), "PX1: the Blank Button is a whole multiple of its %d px disc at the start (%s)" % [S.BLANK_DISC_PX, blank.size])

	for p in 20:
		blank.pressed.emit()
	await look("the status bar")
	for p in 80:
		blank.pressed.emit()
	(screen.find_child("SellRaw", true, false) as Button).pressed.emit()
	await look("the deck")
	check(_whole_disc(blank.size), "PX1: the Blank Button is a whole multiple of its disc once compact (%s)" % blank.size)

	var g = screen.game
	var played := Game.new()
	var player := Player.new()
	for t in roundi(30 * 60 / T.TICK_SECONDS):
		player.step(played)
		played.tick()
	g.load_state(played.to_state())
	for tab in ["farms", "processing", "tech", "market"]:
		await look_tab(tab, "30 minutes")

	for t in roundi(70 * 60 / T.TICK_SECONDS):
		player.step(played)
		played.tick()
	g.load_state(played.to_state())
	screen._rebase_juice()
	for tab in ["farms", "processing", "tech", "market"]:
		await look_tab(tab, "1:40")
	(screen.find_child("Tab_farms", true, false) as Button).pressed.emit()
	var farms: ScrollContainer = screen.find_child("Page_farms", true, false)
	farms.scroll_vertical = 1000000
	await look("the foot of Farms")
	farms.scroll_vertical = 0
	(screen.find_child("Manage_plot_bell", true, false) as Button).pressed.emit()
	await look("a station sheet")
	(screen.find_child("SheetDone", true, false) as Button).pressed.emit()
	screen.open_drawer()
	await look("the warehouse")
	(screen.find_child("Drawer", true, false) as Control).visible = false
	screen._return_from(9 * 3600.0 + 720.0)
	await look("the return card")
	screen.close_card()

	g.cash = 2e7
	g._note_value()
	await look_tab("hq", "a run worth $20M")
	g.prestige()
	g.account.credits = 40
	g.account.rooms = {"seed_vault": 3, "tasting_room": 1}
	g._refresh_fx()
	g.open_room(g.rooms_offered()[0])
	screen._refresh(false)
	await look("HQ after a sale")

	# I13: the deep end's Farms tab, every farm owned and upgraded.
	var deep := Game.new()
	deep.cash = 1e35
	for id in deep.data.plots:
		deep.plots[id].owned = true
		deep.plots[id].harvest = 60
		deep.plots[id].truck = 60
		deep.plots[id].cargo = 60
		for crop in deep.plots[id].field:
			deep.plots[id].field[crop] = 1000000000
	for id in deep.data.tech:
		if id.begins_with("survey_"):
			deep.research[id] = true
	g.load_state(deep.to_state())
	await look_tab("farms", "every farm owned")
	var cards := 0
	var headers := {}
	for id in g.data.plots:
		var card: Control = screen.find_child("Card_plot_" + id, true, false)
		cards += 1 if card != null and card.is_visible_in_tree() else 0
		headers[g.data.plots[id].survey] = true
	var shown := _texts(screen.find_child("Page_farms", true, false))
	var grouped := 0
	for n in headers:
		grouped += 1 if n == 0 or ("LAND SURVEY %d" % n) in shown else 0
	check(cards == g.data.plots.size(), "I13: every farm's card shows (%d of %d)" % [cards, g.data.plots.size()])
	check(grouped == headers.size(), "I13: grouped under every survey (%d of %d headings)" % [grouped, headers.size()])
	(screen.find_child("Manage_plot_farm_79", true, false) as Button).pressed.emit()
	await look("the last farm's sheet")
	(screen.find_child("SheetDone", true, false) as Button).pressed.emit()

	# The nav with every tab open fits too, whatever is unlocked today.
	var nav: Control = screen.find_child("Nav", true, false)
	var widest := 0.0
	var font := Kit.font()
	for tab in screen.NAV_NAMES:
		widest += font.get_string_size(screen.NAV_NAMES[tab], HORIZONTAL_ALIGNMENT_LEFT, -1, S.SIZE_TINY).x
	check(widest <= nav.size.x - 12 - 4 * (screen.NAV_NAMES.size() - 1), "PX6: every tab's name fits the nav at once (%.0f px of %.0f)" % [widest, nav.size.x])

	# Tech Tree nodes: no word broken across lines.
	# A node is a kit button or, researched or out of reach, a card: the tighter padding.
	var pad := maxf(Kit.theme().get_stylebox(&"normal", &"Button").get_content_margin(SIDE_LEFT), screen._card_box().get_content_margin(SIDE_LEFT))
	var room := S.WEB_NODE.x - 2 * pad
	var longest := ""
	for id in g.data.tech:
		var node: Dictionary = g.data.tech[id]
		for word in ("%s %s" % [node.label, screen._short_name(node.name)]).split(" "):
			if font.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, S.SIZE_WEB).x > font.get_string_size(longest, HORIZONTAL_ALIGNMENT_LEFT, -1, S.SIZE_WEB).x:
				longest = word
	var w := font.get_string_size(longest, HORIZONTAL_ALIGNMENT_LEFT, -1, S.SIZE_WEB).x
	check(w <= room, "PX6: the longest word on a Tech Tree node, '%s', is %.0f px, wider than the node's %.0f" % [longest, w, room])


## Every visible Label's and Button's text under `node`.
func _texts(node: Node) -> Array:
	var found := []
	for child in node.get_children():
		if child is CanvasItem and not child.is_visible_in_tree():
			continue
		if (child is Label or child is Button) and child.text != "":
			found.append(child.text)
		found.append_array(_texts(child))
	return found


func look_tab(tab: String, when: String) -> void:
	(screen.find_child("Tab_" + tab, true, false) as Button).pressed.emit()
	await look("%s, %s" % [tab, when])



## Lets entrances finish, then checks every visible control.
func look(where: String) -> void:
	await create_timer(1.0).timeout
	for f in 3:
		await process_frame
	var width: float = screen.get_viewport_rect().size.x
	var web: Control = screen.find_child("Web", true, false)
	_walk(screen, where, width, web)
	var bar: Control = screen.find_child("StatusBar", true, false)
	if bar.is_visible_in_tree():
		check(bar.size.y <= S.STATUS_BAR_HEIGHT + 0.5, "PX6: %s, the status bar has grown to %.0f px" % [where, bar.size.y])


func _walk(node: Node, where: String, width: float, web: Control) -> void:
	for child in node.get_children():
		if not child is Control or not (child as Control).is_visible_in_tree():
			continue
		var c := child as Control
		var in_web := web != null and (c == web or web.is_ancestor_of(c))
		if (c is Label or c is Button) and c.text != "":
			var f := c.get_theme_font(&"font")
			var px := c.get_theme_font_size(&"font_size")
			check(f == Kit.font(), "PX2: %s, %s uses another font" % [where, c.name])
			check(px % S.FONT_PX == 0, "PX2: %s, %s's text is %d px" % [where, c.name, px])
			# Wrapped text breaks between words, never inside one (tightened after
			# the first captures: a wrapped button collapsed to a letter a line).
			var wraps: bool = c.autowrap_mode != TextServer.AUTOWRAP_OFF
			if wraps:
				var box := c.get_theme_stylebox(&"normal") if c is Button else null
				var room: float = c.size.x - (box.get_minimum_size().x if box else 0.0)
				for word in c.text.replace("\n", " ").split(" ", false):
					var ww := f.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
					check(ww <= room + 0.5, "PX6: %s, %s breaks '%s' (%.0f px in %.0f)" % [where, c.name, word, ww, room])
			for ch in c.text:
				if ch != "\n" and not _drawn(ch):
					check(false, "PX3: %s, %s shows '%s', which no pixel font has" % [where, c.name, ch])
			if c is Label and (c as Label).max_lines_visible >= 0:
				check(c.get_line_count() <= c.max_lines_visible, "PX6: %s, %s hides %d of its %d lines: %s" % [where, c.name, c.get_line_count() - c.max_lines_visible, c.get_line_count(), c.text.c_escape()])
			if c.name == "Goal":
				check(c.get_line_count() <= 2, "PX6: %s, the goal runs to %d lines" % [where, c.get_line_count()])
			if c is Label and (c as Label).clip_text:
				var tw := f.get_multiline_string_size(c.text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
				check(tw <= c.size.x + 0.5, "PX6: %s, %s's text is cut off (%.0f px in %.0f)" % [where, c.name, tw, c.size.x])
		for n in BOXES:
			# An outline with square corners (the next action's ring, D044) is
			# drawn pixel-crisp, so only filled or rounded flat boxes fail.
			var sb = c.get_theme_stylebox(n) if c.has_theme_stylebox(n) else null
			if sb is StyleBoxFlat and (sb.draw_center or sb.corner_radius_top_left > 0):
				check(false, "PX4: %s, %s (%s) draws a flat %s box" % [where, c.name, c.get_class(), n])
		if not in_web:
			var r := c.get_global_rect()
			check(r.position.x >= -0.5 and r.end.x <= width + 0.5, "PX6: %s, %s runs off the screen (%.0f to %.0f)%s" % [where, c.name, r.position.x, r.end.x, (": " + c.text.c_escape()) if c is Label or c is Button else ""])
		if c is Button and not in_web and c.name != "BlankButton":
			check(c.size.y >= S.BUTTON_HEIGHT - 0.5, "PX6: %s, button %s is %.0f px tall" % [where, c.name, c.size.y])
		checks += 1
		_walk(c, where, width, web)


func _drawn(ch: String) -> bool:
	var f := Kit.font()
	if f.has_char(ch.unicode_at(0)):
		return true
	for fb in f.fallbacks:
		if fb.has_char(ch.unicode_at(0)):
			return true
	return false
