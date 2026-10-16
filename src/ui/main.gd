extends Control
## The one screen. Presents the game and reports presses to it; every rule lives
## in src/core/game.gd. Builds its nodes in code so the layout is all in one place.
## Reveals animate when they happen and appear at once when loaded from a save.

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const S = preload("res://src/ui/style.gd")

## Station names and upgrade labels, in the deck's order.
const STATIONS := {
	"plot": {"title": "Bell Pepper Plot", "upgrades": {"speed": "Harvest Speed", "yield": "Yield per Cycle"}},
	"vat": {"title": "Sweet Pepper Mash Vat", "upgrades": {"speed": "Vat Speed"}},
	"line": {"title": "Table Mild Line", "upgrades": {"speed": "Bottling Speed"}},
}

## Where the game saves. Tests clear it so nothing is read or written.
var save_path := "user://save.json"
var game: Game

var _acc := 0.0
var _since_save := 0.0
var _shown := {}

var _blank: Button
var _counter: Label
var _status_bar: PanelContainer
var _cash: Label
var _sell: Button
var _deck: PanelContainer
## Per station: its card's nodes ("card", "info", "status", "bar", "buy", upgrade buttons by key).
var _cards := {}
var _sell_batch: Button


func _ready() -> void:
	game = Game.new()
	_load()
	_build()
	_refresh(false)


func _process(delta: float) -> void:
	_acc += delta
	while _acc >= T.TICK_SECONDS:
		_acc -= T.TICK_SECONDS
		game.tick()
	_since_save += delta
	if _since_save >= T.AUTOSAVE_SECONDS:
		_save()
	_refresh(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		_save()


# --- Saving ----------------------------------------------------------------

func _load() -> void:
	if save_path == "" or not FileAccess.file_exists(save_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	var problem := game.load_state(parsed)
	if problem != "":
		# Keep the unreadable save beside the new one rather than overwrite it.
		push_warning("Scoville: save not loaded (%s); kept as %s.bad" % [problem, save_path])
		DirAccess.rename_absolute(save_path, save_path + ".bad")


func _save() -> void:
	_since_save = 0.0
	if save_path == "":
		return
	var f := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(game.to_state(), "", false, true))
	f.close()
	DirAccess.rename_absolute(save_path + ".tmp", save_path)


# --- Building --------------------------------------------------------------

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = S.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Stage 2: the Operation Deck, the lower 65%, which slides up from below.
	_deck = PanelContainer.new()
	_deck.name = "Deck"
	var deck_box := _box(S.PANEL, 0)
	deck_box.border_color = S.LINE
	deck_box.border_width_top = 1
	deck_box.content_margin_left = S.GUTTER
	deck_box.content_margin_right = S.GUTTER
	deck_box.content_margin_top = 14
	_deck.add_theme_stylebox_override("panel", deck_box)
	_deck.anchor_left = 0.0
	_deck.anchor_right = 1.0
	_deck.anchor_top = S.UPPER_FRACTION
	_deck.anchor_bottom = 1.0
	add_child(_deck)
	var deck_col := VBoxContainer.new()
	deck_col.add_theme_constant_override("separation", 10)
	_deck.add_child(deck_col)
	# One tab until v0.3 brings the navigation bar.
	deck_col.add_child(_label("FARMS", S.SIZE_SMALL, S.DIM))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	deck_col.add_child(scroll)
	var cards := VBoxContainer.new()
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("separation", 12)
	scroll.add_child(cards)
	for station in STATIONS:
		_cards[station] = _station_card(cards, station)

	# Stage 0: the Blank Button, centred, with no label at all.
	_blank = Button.new()
	_blank.name = "BlankButton"
	_blank.focus_mode = Control.FOCUS_NONE
	var looks := {"normal": S.BUTTON, "hover": S.BUTTON_HOVER, "pressed": S.BUTTON_PRESSED}
	for state in looks:
		var box := _box(looks[state], 999)
		box.border_color = S.BUTTON_EDGE
		box.set_border_width_all(4)
		box.shadow_color = Color(0, 0, 0, 0.45)
		box.shadow_size = 18
		_blank.add_theme_stylebox_override(state, box)
	_blank.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_blank.pressed.connect(_on_blank_pressed)
	add_child(_blank)
	_place_blank(false)

	# Sell Batch sits beside the compact button, always in reach.
	_sell_batch = _control_button("", func() -> void: game.sell_batch())
	_sell_batch.name = "SellBatch"
	_sell_batch.anchor_left = 1.0
	_sell_batch.anchor_right = 1.0
	_sell_batch.anchor_top = S.UPPER_FRACTION
	_sell_batch.anchor_bottom = S.UPPER_FRACTION
	_sell_batch.offset_right = -S.GUTTER
	_sell_batch.offset_left = -S.GUTTER - S.SELL_BATCH_WIDTH
	_sell_batch.offset_bottom = -18.0 - (S.BLANK_BUTTON_COMPACT - S.SELL_BATCH_HEIGHT) / 2.0
	_sell_batch.offset_top = _sell_batch.offset_bottom - S.SELL_BATCH_HEIGHT
	add_child(_sell_batch)

	# Stage 0, after the first press: the counter (later, the stock) at the top.
	_counter = Label.new()
	_counter.name = "Counter"
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_counter.add_theme_font_size_override("font_size", S.SIZE_BODY)
	_counter.add_theme_color_override("font_color", S.TEXT)
	_counter.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_counter.offset_top = S.STATUS_BAR_HEIGHT + 24
	_counter.offset_bottom = _counter.offset_top + 40
	add_child(_counter)

	# Stage 1: the status bar, which slides down from above the screen.
	_status_bar = PanelContainer.new()
	_status_bar.name = "StatusBar"
	var bar := _box(S.PANEL, 0)
	bar.content_margin_left = S.GUTTER
	bar.content_margin_right = S.GUTTER
	bar.border_color = S.LINE
	bar.border_width_bottom = 1
	_status_bar.add_theme_stylebox_override("panel", bar)
	_status_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_status_bar.offset_bottom = S.STATUS_BAR_HEIGHT
	add_child(_status_bar)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_status_bar.add_child(row)
	_cash = _label("", S.SIZE_BODY, S.GREEN)
	_cash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cash.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_cash)
	_sell = _control_button("Sell Raw Peppers (%s/ea)" % _money(T.BELL_RAW_PRICE), func() -> void: game.sell_raw())
	_sell.name = "SellRaw"
	_sell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_sell)


## A station's card: title, what it does, a cycle bar, then its buy button or
## its upgrades.
func _station_card(parent: Container, station: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = "Card_" + station
	var box := _box(S.BG, S.RADIUS)
	box.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", box)
	parent.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var nodes := {"card": panel, "col": col}
	col.add_child(_label(STATIONS[station].title, S.SIZE_BODY, S.TEXT))
	nodes.info = _label("", S.SIZE_SMALL, S.DIM)
	nodes.info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(nodes.info)
	nodes.bar = ProgressBar.new()
	nodes.bar.max_value = 1.0
	nodes.bar.show_percentage = false
	nodes.bar.custom_minimum_size.y = S.PROGRESS_HEIGHT
	nodes.bar.add_theme_stylebox_override("background", _box(S.PROGRESS_TRACK, 4))
	nodes.bar.add_theme_stylebox_override("fill", _box(S.PROGRESS_FILL, 4))
	col.add_child(nodes.bar)
	nodes.status = _label("", S.SIZE_SMALL, S.MUTED)
	col.add_child(nodes.status)
	nodes.buy = _control_button("", func() -> void: game.buy(station))
	nodes.buy.name = "Buy_" + station
	col.add_child(nodes.buy)
	for upgrade in STATIONS[station].upgrades:
		var b := _control_button("", func() -> void: game.buy_upgrade(station, upgrade))
		b.name = "Upgrade_%s_%s" % [station, upgrade]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		col.add_child(b)
		nodes[upgrade] = b
	return nodes


## Puts the Blank Button in the middle of the screen, or (compact) at the foot
## of the upper viewport once the deck is open.
func _place_blank(compact: bool) -> void:
	var side := S.BLANK_BUTTON_COMPACT if compact else S.BLANK_BUTTON_SIZE
	var half := side / 2.0
	_blank.anchor_left = 0.5
	_blank.anchor_right = 0.5
	if compact:
		_blank.anchor_top = S.UPPER_FRACTION
		_blank.anchor_bottom = S.UPPER_FRACTION
		_blank.offset_top = -side - 18.0
		_blank.offset_bottom = -18.0
	else:
		_blank.anchor_top = 0.5
		_blank.anchor_bottom = 0.5
		_blank.offset_top = -half
		_blank.offset_bottom = half
	_blank.offset_left = -half
	_blank.offset_right = half
	_blank.pivot_offset = Vector2.ONE * half


func _on_blank_pressed() -> void:
	game.press()
	var squash := create_tween()
	squash.tween_property(_blank, "scale", Vector2.ONE * 0.92, S.PRESS_SQUASH * 0.4)
	squash.tween_property(_blank, "scale", Vector2.ONE, S.PRESS_SQUASH * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_refresh(true)


# --- Showing ---------------------------------------------------------------

## Shows the state. `animate` plays a reveal's entrance the moment it happens.
func _refresh(animate: bool) -> void:
	var parts := ["Bell Peppers: %d" % game.stock.bell]
	if game.stations.vat.owned:
		parts.append("Mash: %d" % game.stock.sweet_mash)
	if game.stations.line.owned:
		parts.append("Table Mild: %d" % game.stock.table_mild)
	_counter.text = "   ".join(parts)
	_cash.text = "Cash: " + _money(game.cash)
	_sell.disabled = not game.can_sell_raw()
	for station in STATIONS:
		_refresh_card(station)
	_sell_batch.visible = game.stations.line.owned
	_sell_batch.text = "Sell Batch\n%s" % _money(game.stock.table_mild * T.TABLE_MILD_PRICE)
	_sell_batch.disabled = not game.can_sell_batch()

	_reveal("counter", _counter, animate, func() -> void:
		_counter.modulate.a = 0.0
		create_tween().tween_property(_counter, "modulate:a", 1.0, S.FADE_IN))
	_reveal("status_bar", _status_bar, animate, func() -> void:
		_status_bar.position.y = -S.STATUS_BAR_HEIGHT
		create_tween().tween_property(_status_bar, "position:y", 0.0, S.SLIDE_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))
	var compact: bool = game.revealed.deck
	if compact != _shown.get("compact", false):
		_compress_blank(compact and animate)
		_shown.compact = compact
	_reveal("deck", _deck, animate, func() -> void:
		var target := _deck.position.y
		_deck.position.y = size.y
		create_tween().tween_property(_deck, "position:y", target, S.SLIDE_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(S.COMPRESS * 0.4))


func _refresh_card(station: String) -> void:
	var nodes: Dictionary = _cards[station]
	var s: Dictionary = game.stations[station]
	nodes.card.visible = game.is_offered(station)
	var every := "every %.1f s" % game.cycle_seconds(station)
	match station:
		"plot":
			nodes.info.text = "%d Bell Pepper%s %s" % [game.plot_yield(), "" if game.plot_yield() == 1 else "s", every] if s.owned else "Harvests Bell Peppers by itself."
		"vat":
			nodes.info.text = "%d Bell Peppers → 1 Sweet Pepper Mash %s" % [T.VAT_PEPPERS_IN, every]
		"line":
			nodes.info.text = "1 Mash → 1 Table Mild (%s) %s" % [_money(T.TABLE_MILD_PRICE), every]
	nodes.bar.visible = s.owned
	nodes.bar.value = clampf(s.progress / game.cycle_seconds(station), 0.0, 1.0)
	var status := ""
	if s.owned and station != "plot" and not s.running:
		status = "Waiting for %s" % ("peppers" if station == "vat" else "mash")
	if station == "line" and s.owned and s.crate > 0:
		status = "Starter Crate: %d bottles left at %d× speed" % [s.crate, int(T.STARTER_CRATE_SPEED)]
	nodes.status.text = status
	nodes.status.visible = status != ""
	nodes.buy.visible = not s.owned
	var extra := "  ·  includes a Starter Crate of %d" % T.STARTER_CRATE_BOTTLES if station == "line" else ""
	nodes.buy.text = "Buy   %s%s" % [_money(game.price(station)), extra]
	nodes.buy.disabled = not game.can_buy(station)
	for upgrade in STATIONS[station].upgrades:
		var b: Button = nodes[upgrade]
		b.visible = s.owned
		b.text = "%s   Lv %d   %s" % [STATIONS[station].upgrades[upgrade], s[upgrade], _money(game.upgrade_cost(station, upgrade))]
		b.disabled = not game.can_upgrade(station, upgrade)


## Moves the Blank Button between its full-screen and compact places, sliding
## from where it was when `animate`.
func _compress_blank(animate: bool) -> void:
	var from_pos := _blank.position
	var from_size := _blank.size
	_place_blank(game.revealed.deck)
	if not animate:
		return
	var to_pos := _blank.position
	var to_size := _blank.size
	_blank.position = from_pos
	_blank.size = from_size
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(_blank, "position", to_pos, S.COMPRESS)
	t.tween_property(_blank, "size", to_size, S.COMPRESS)


func _reveal(key: String, node: Control, animate: bool, entrance: Callable) -> void:
	var on: bool = game.revealed[key]
	node.visible = on
	if on and not _shown.get(key, false) and animate:
		entrance.call()
	_shown[key] = on


# --- Pieces ----------------------------------------------------------------

func _label(text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


## A plain button that runs `action` on the game, then redraws.
func _control_button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	_style_control(b)
	b.pressed.connect(func() -> void:
		action.call()
		_refresh(true))
	return b


func _box(color: Color, radius: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = color
	b.set_corner_radius_all(radius)
	return b


func _style_control(b: Button) -> void:
	var looks := {"normal": S.CONTROL, "hover": S.CONTROL, "pressed": S.CONTROL_PRESSED, "disabled": S.CONTROL_DISABLED}
	for state in looks:
		var box := _box(looks[state], S.RADIUS)
		box.set_content_margin_all(12)
		box.border_color = S.LINE
		box.set_border_width_all(1)
		b.add_theme_stylebox_override(state, box)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.add_theme_font_size_override("font_size", S.SIZE_SMALL)
	b.add_theme_color_override("font_color", S.TEXT)
	b.add_theme_color_override("font_hover_color", S.TEXT)
	b.add_theme_color_override("font_pressed_color", S.TEXT)
	b.add_theme_color_override("font_disabled_color", S.MUTED)


## Pounds with thousands separators: £1,234.50.
static func _money(amount: float) -> String:
	var pence := roundi(amount * 100.0)
	var whole := str(pence / 100)
	var grouped := ""
	while whole.length() > 3:
		grouped = "," + whole.right(3) + grouped
		whole = whole.left(whole.length() - 3)
	return "£%s%s.%02d" % [whole, grouped, pence % 100]
