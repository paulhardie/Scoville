extends Control
## The one screen. Presents the game and reports what the player does; every rule
## lives in src/core/game.gd. Builds its nodes in code so the layout is all in
## one place. Reveals animate when they happen and appear at once when loaded
## from a save.

const Game = preload("res://src/core/game.gd")
const RealClock = preload("res://src/core/real_clock.gd")
const T = preload("res://src/core/tuning.gd")
const S = preload("res://src/ui/style.gd")

const TAB_NAMES := {"farms": "Farms", "processing": "Processing", "tech": "Tech Tree", "market": "Market", "roster": "Shift Roster", "hq": "HQ"}
const MONEY_SUFFIXES := ["K", "M", "B", "T", "Qa", "Qi"]
const BUY_MODES := ["1", "10", "max"]
const STATION_NAMES := {"vat": "Vat", "line": "Line"}
const UPGRADE_NAMES := {"speed": "Harvest Speed", "yield": "Yield per Cycle", "cargo": "Cargo"}
## Steps for the valve's keep amounts.
const KEEP_STEP := 10

## Where the game saves. Tests clear it so nothing is read or written.
var save_path := "user://save.json"
## Sound and vibration switches (docs/FEEL.md), kept apart from the game save.
## Tests clear the path too.
var settings_path := "user://settings.json"
var settings := {"sound": true, "vibration": true, "buy_mode": "1"}
## Clicks played and vibrations asked for, and the last click's pitch, for tests.
var clicks_played := 0
var vibrations := 0
var last_pitch := 1.0
var _click: AudioStreamPlayer
var _settings_buttons := {}
## Wall-clock time (D021). Tests set their own before the screen is added.
var clock = RealClock.new()
var game: Game
## The last "While you were away" report shown, for tests.
var last_return := {}

var _saved_at := -1.0
var _last_frame := -1.0
var _return_card: Control
var _return_text := {}

var _acc := 0.0
var _since_save := 0.0
var _page := "farms"

var _blank: Button
var _counter: Label
var _status_bar: PanelContainer
var _cash: Label
var _ov: Label
var _sell: Button
var _sell_batch: Button
var _deck: PanelContainer
var _pages := {}                    # tab → its page (a ScrollContainer)
var _farms_col: VBoxContainer
var _processing_col: VBoxContainer
## The vats and lines; it sits on the Farms page until the Processing tab opens.
var _proc_box: VBoxContainer
var _plot_cards := {}               # crop → card nodes
var _slot_cards := {"vat": [], "line": []}
var _slot_lists := {}               # station → its VBoxContainer
var _buy_slot := {}                 # station → its buy button
var _van_card: PanelContainer
var _van_rows := {}                 # bottle → {row, slider, label}
var _nav: PanelContainer
var _tab_buttons := {}
var _hint: Label
var _spike: Label
var _heat_bar: ProgressBar
var _heat_label: Label
var _overdrive := {}                # card, status, button
var _valve_card: PanelContainer
var _valve_rows := {}               # item → {row, label, minus, plus, toggle, reset}
var _web_scroll: ScrollContainer
var _web_centred := false
var _web: WebLines
var _web_nodes := {}                # node id → Button
var _selected := "kitchen_table"
var _detail := {}
var _hq := {}                       # the HQ page's nodes (docs/PRESTIGE.md)
var _sell_armed := false            # the first tap on Sell the Franchise
# Layout step 1 (docs/LAYOUT.md).
var _goal: Label
var _shown_cash := 0.0
var _countup := {"from": 0.0, "to": 0.0, "t": 1.0}   # Cash's count-up
var _frame_delta := 0.0
var _sheet: Control
var _sheet_box: VBoxContainer
var _sheet_of := {}                  # {kind: "plot"/"slot", crop / station, index}
var _sheet_buttons := {}             # upgrade → Button
var _mode_buttons := {}              # buy mode → Button
var _drawer: Control
var _drawer_box: VBoxContainer
var _market_col: VBoxContainer
var _demand: Label
var _made_seen := {}                 # bottle → made, at the last look
var _earned_seen := -1.0
var _pending_pop := {}               # bottle → made since the last pop
var _pop_wait := 0.0
var _coin_wait := 0.0
var pops_shown := 0
var coins_flown := 0
var dots_shown := 0
var _factory: FactoryView
var _ring: Panel
var _ring_t := 0.0
var _ring_target: Control
var _dot_wait := 0.0
var _seen_delivered := -1
var _seen_mash := -1


## The Tech Tree's connecting lines, drawn under the node buttons.
class WebLines extends Control:
	var edges: Array = []   # [from, to, done]

	func _draw() -> void:
		for e in edges:
			draw_line(e[0], e[1], S.WEB_LINE_DONE if e[2] else S.WEB_LINE, 3.0, true)


## The factory view (LAYOUT.md step 2, D044): Bottling over Vats over Fields,
## each owned station a tile filling with its cycle, and dots climbing a floor
## as crops reach stock and mash is made.
class FactoryView extends Control:
	const FLOORS := ["line", "vat", "plot"]
	const NAMES := {"line": "Bottling", "vat": "Vats", "plot": "Fields"}
	const EMPTY := {"line": "Lines bottle here", "vat": "Vats make mash here", "plot": "Plots grow here"}
	var game
	var dots: Array = []    # [from floor index, x, age]

	func _process(delta: float) -> void:
		for d in dots:
			d[2] += delta
		dots = dots.filter(func(d) -> bool: return d[2] < S.DOT_SECONDS)
		queue_redraw()

	## A dot climbing from a floor (2 Fields, 1 Vats) to the one above.
	func climb(from: int) -> void:
		dots.append([from, randf_range(0.15, 0.95) * size.x, 0.0])

	func _tiles(floor: String) -> Array:
		var out := []
		if floor == "plot":
			for crop in game.plots:
				var p: Dictionary = game.plots[crop]
				if p.owned:
					out.append([p.progress / game.plot_cycle(crop), p.field > 2.0 * game.plot_yield_exact(crop)])
		else:
			for i in game.slots(floor).size():
				var sl: Dictionary = game.slots(floor)[i]
				var f: float = sl.progress / game.slot_cycle(floor, i) if sl.recipe != "" else 0.0
				out.append([f, false])
		return out

	func _draw() -> void:
		var font := get_theme_default_font()
		var h := size.y / FLOORS.size()
		for f in FLOORS.size():
			var top := f * h
			draw_rect(Rect2(0, top + 2, size.x, h - 4), S.FLOOR)
			draw_string(font, Vector2(8, top + 18), NAMES[FLOORS[f]], HORIZONTAL_ALIGNMENT_LEFT, -1, S.SIZE_TINY - 3, S.MUTED)
			var tiles := _tiles(FLOORS[f])
			if tiles.is_empty():
				draw_string(font, Vector2(8, top + h - 10), EMPTY[FLOORS[f]], HORIZONTAL_ALIGNMENT_LEFT, -1, S.SIZE_TINY - 2, S.DIM)
				continue
			var side := minf(S.TILE, (size.x - 16.0) / tiles.size() - S.TILE_GAP)
			for i in tiles.size():
				var r := Rect2(8 + i * (side + S.TILE_GAP), top + h - side - 8, side, side)
				draw_rect(r, S.PROGRESS_TRACK)
				var fill: float = clampf(tiles[i][0], 0.0, 1.0)
				draw_rect(Rect2(r.position.x, r.end.y - r.size.y * fill, r.size.x, r.size.y * fill), S.PROGRESS_FILL)
				draw_rect(r, S.ORANGE if tiles[i][1] else S.LINE, false, 2.0 if tiles[i][1] else 1.0)
		for d in dots:
			var t: float = d[2] / S.DOT_SECONDS
			var from_y: float = (d[0] + 0.5) * h
			var y: float = lerpf(from_y, from_y - h, t)
			draw_circle(Vector2(d[1], y), S.DOT_SIZE, Color(S.COIN, 1.0 - t * 0.6))


func _ready() -> void:
	game = Game.new({}, int(clock.now()))
	_load()
	_load_settings()
	_shown_cash = game.cash
	_countup = {"from": game.cash, "to": game.cash, "t": 1.0}
	_build()
	if _saved_at > 0.0:
		_return_from(clock.now() - _saved_at)
	_last_frame = clock.now()
	_refresh(false)


func _process(delta: float) -> void:
	# A gap longer than AWAY_SECONDS (the app in the background, or a frozen
	# screen) is time away, caught up at once rather than ticked (D021).
	var now: float = clock.now()
	if _last_frame > 0.0 and now - _last_frame > T.AWAY_SECONDS:
		_return_from(now - _last_frame)
		delta = 0.0
	_last_frame = now
	_acc += delta
	while _acc >= T.TICK_SECONDS:
		_acc -= T.TICK_SECONDS
		game.tick()
	_since_save += delta
	if _since_save >= T.AUTOSAVE_SECONDS:
		_save()
	_frame_delta = delta
	_juice(delta)
	_climb(delta)
	_place_ring(delta)
	_refresh(true)
	_frame_delta = 0.0


func _notification(what: int) -> void:
	if what in [NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		_save()


## Catches up time away and, after more than a minute, says what it brought.
func _return_from(seconds: float) -> void:
	if seconds <= 0.0:
		return
	var report := game.catch_up(seconds)
	# What was made while away is on the card, not in a pop.
	_rebase_juice()
	if seconds > T.RETURN_CARD_SECONDS:
		last_return = report
		_show_card(report)


# --- Saving ----------------------------------------------------------------

func _load() -> void:
	if save_path == "" or not FileAccess.file_exists(save_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	var problem := game.load_state(parsed)
	if problem == "" and typeof(parsed.get("saved_at")) in [TYPE_FLOAT, TYPE_INT]:
		_saved_at = float(parsed.saved_at)
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
	var state := game.to_state()
	state.saved_at = clock.now()
	f.store_string(JSON.stringify(state, "", false, true))
	f.close()
	DirAccess.rename_absolute(save_path + ".tmp", save_path)


# --- Building --------------------------------------------------------------

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = S.BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	_build_deck()
	_build_nav()
	_build_upper()
	_build_status_bar()
	_sheet = _build_overlay("Sheet")
	_sheet_box = _sheet.get_meta("box")
	_drawer = _build_overlay("Drawer")
	_drawer_box = _drawer.get_meta("box")
	_build_card()
	# The ring round the next action (D044), over everything but the overlays.
	_ring = Panel.new()
	_ring.name = "Ring"
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ring_box := StyleBoxFlat.new()
	ring_box.draw_center = false
	ring_box.border_color = S.ORANGE
	ring_box.set_border_width_all(S.RING_WIDTH)
	ring_box.set_corner_radius_all(S.RADIUS)
	_ring.add_theme_stylebox_override("panel", ring_box)
	_ring.visible = false
	add_child(_ring)
	move_child(_ring, _sheet.get_index())


## The panel of the open tab, under the tab selectors (D044). Its pages are the
## tabs.
func _build_deck() -> void:
	_deck = PanelContainer.new()
	_deck.name = "Deck"
	var deck_box := _box(S.PANEL, 0)
	deck_box.border_color = S.LINE
	deck_box.border_width_top = 1
	deck_box.content_margin_left = S.GUTTER
	deck_box.content_margin_right = S.GUTTER
	deck_box.content_margin_top = 14
	deck_box.content_margin_bottom = 8
	_deck.add_theme_stylebox_override("panel", deck_box)
	_deck.anchor_right = 1.0
	_deck.anchor_top = S.UPPER_FRACTION
	_deck.anchor_bottom = 1.0
	_deck.offset_top = S.NAV_HEIGHT
	add_child(_deck)
	var holder := Control.new()
	_deck.add_child(holder)

	_farms_col = _page_column(holder, "farms")
	# Cheapest first, as Idle Planet Miner lists its planets (D041).
	var crops: Array = game.data.plots.keys()
	crops.sort_custom(func(a: String, b: String) -> bool: return game.plot_price(a) < game.plot_price(b))
	for crop in crops:
		_plot_cards[crop] = _plot_card(_farms_col, crop)
	_proc_box = VBoxContainer.new()
	_proc_box.add_theme_constant_override("separation", 12)
	_farms_col.add_child(_proc_box)
	_build_processing(_proc_box)
	_build_settings(_farms_col)

	_processing_col = _page_column(holder, "processing")
	_build_tech(holder)
	_market_col = _page_column(holder, "market")
	_build_market(_market_col)
	_build_hq(_page_column(holder, "hq"))


func _page_column(holder: Control, tab: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "Page_" + tab
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	holder.add_child(scroll)
	_pages[tab] = scroll
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	scroll.add_child(col)
	col.add_child(_label(TAB_NAMES[tab].to_upper(), S.SIZE_SMALL, S.DIM))
	return col


## HQ (brief §6, docs/PRESTIGE.md): selling the franchise, the credits, the
## room draft and the rooms.
func _build_hq(col: VBoxContainer) -> void:
	var sell := _card(col, "SellCard", "Sell the Franchise")
	sell.bar.visible = false
	sell.button = _control_button("", func() -> void:
		if _sell_armed:
			_sell_armed = false
			game.prestige()
		else:
			_sell_armed = true)
	sell.button.name = "SellFranchise"
	sell.col.add_child(sell.button)
	var rooms := _card(col, "RoomsCard", "HQ Facilities")
	rooms.bar.visible = false
	rooms.open = _control_button("", func() -> void: game.open_room())
	rooms.open.name = "OpenRoom"
	rooms.col.add_child(rooms.open)
	rooms.draft = HBoxContainer.new()
	rooms.draft.add_theme_constant_override("separation", 8)
	rooms.col.add_child(rooms.draft)
	rooms.list = VBoxContainer.new()
	rooms.list.add_theme_constant_override("separation", 6)
	rooms.col.add_child(rooms.list)
	_hq = {"sell": sell, "rooms": rooms, "draft_shown": [], "rows": {}}


func _refresh_hq() -> void:
	var sell: Dictionary = _hq.sell
	var credits := game.prestige_credits()
	if game.can_prestige():
		sell.info.text = "Operation Value %s. Selling resets the run and pays %d Franchise Credits. HQ rooms, credits and your open tabs stay." % [_money(game.operation_value()), credits]
	else:
		sell.info.text = "Opens at %s Operation Value this run (now %s)." % [_money(T.PRESTIGE_OV), _money(game.operation_value())]
	sell.button.disabled = not game.can_prestige()
	sell.button.text = "Tap again to sell" if _sell_armed else ("Sell (+%d credits)" % credits if game.can_prestige() else "Sell")
	var sold: int = game.account.prestiges
	sell.status.text = "" if sold == 0 else ("Sold once before." if sold == 1 else "Sold %d times before." % sold)

	var rooms: Dictionary = _hq.rooms
	rooms.info.text = "Franchise Credits: %d" % game.account.credits
	var all_open: bool = game.account.rooms.size() >= game.data.rooms.size()
	rooms.open.visible = game.account.draft.is_empty() and not all_open
	rooms.open.text = "Open a new room (%d credits)" % game.room_open_cost()
	rooms.open.disabled = not game.can_open_room()
	rooms.status.text = "Pick one:" if not game.account.draft.is_empty() else ""
	if _hq.draft_shown != game.account.draft:
		for child in rooms.draft.get_children():
			child.queue_free()
		for id in game.account.draft:
			var b := _control_button("%s\n%s" % [game.data.rooms[id].name, _room_text(id, 1)], func() -> void: game.choose_room(id))
			b.name = "Draft_" + id
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			rooms.draft.add_child(b)
		_hq.draft_shown = game.account.draft.duplicate()
	for id in game.account.rooms:
		if not _hq.rows.has(id):
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			rooms.list.add_child(row)
			var l := _label("", S.SIZE_SMALL, S.DIM)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			row.add_child(l)
			var up := _small_button("", func() -> void: game.level_room(id))
			up.name = "LevelRoom_" + id
			row.add_child(up)
			_hq.rows[id] = {"label": l, "button": up}
		var r: Dictionary = _hq.rows[id]
		var lv: int = game.account.rooms[id]
		r.label.text = "%s  Lv %d\n%s" % [game.data.rooms[id].name, lv, _room_text(id, lv)]
		var at_cap: bool = lv >= game.data.rooms[id].cap
		r.button.text = "Max" if at_cap else "Lv %d: %d" % [lv + 1, game.room_level_cost(id)]
		r.button.disabled = not game.can_level_room(id)


## What a room does at a level, in words.
func _room_text(id: String, lv: int) -> String:
	var room: Dictionary = game.data.rooms[id]
	if room.effect == "start_cash":
		var amounts: Array = room.amounts
		var amount: float = amounts[lv - 1] if lv <= amounts.size() else amounts[-1] * pow(room.growth, lv - amounts.size())
		return "Start each run with %s." % _money(amount)
	var v: float = room.base + room.step * (lv - 1)
	var pct := roundi(v * 100.0)
	match room.effect:
		"plot_speed": return "Plots harvest %d%% faster." % pct
		"plot_yield": return "Plots yield %d%% more." % pct
		"vat_speed": return "Vats run %d%% faster." % pct
		"line_speed": return "Lines run %d%% faster." % pct
		"crop_input": return "Vats need %d%% fewer raw crops." % pct
		"mash_input": return "Lines need %d%% less mash." % pct
		"tech_cost": return "Tech Tree costs %d%% less." % pct
		"button_yield": return "The button picks %d%% more." % pct
		"bottle_value": return "Bottles are worth %d%% more." % pct
		"credits": return "%d%% more Franchise Credits." % pct
		"offline_hours": return "Time away counts %d hours longer." % roundi(v)
	return ""


## Settings (docs/FEEL.md): the Sound and Vibration switches, at the foot of
## Farms.
func _build_settings(parent: VBoxContainer) -> void:
	var card := _card(parent, "SettingsCard", "Settings")
	card.bar.visible = false
	card.info.visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	card.col.add_child(row)
	for key in ["sound", "vibration"]:
		var b := _small_button("", func() -> void:
			settings[key] = not settings[key]
			_save_settings())
		b.name = "Setting_" + key
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
		_settings_buttons[key] = b


## The click and the buzz of a finger press; Grip and the Piston press
## through the game, not here, so they stay silent.
func _feel_press() -> void:
	if settings.sound:
		if _click == null:
			_click = AudioStreamPlayer.new()
			_click.stream = _click_sound()
			_click.volume_db = S.CLICK_VOLUME_DB
			_click.max_polyphony = 4
			add_child(_click)
		last_pitch = (1.0 + randf_range(-S.CLICK_PITCH_SPREAD, S.CLICK_PITCH_SPREAD)) * (1.0 + S.CLICK_HEAT_PITCH * game.heat / T.HEAT_MAX)
		_click.pitch_scale = last_pitch
		_click.play()
		clicks_played += 1
	if settings.vibration:
		Input.vibrate_handheld(S.HAPTIC_MS)
		vibrations += 1


## A short click made in code: a tone that dies away fast, with a little
## noise at its start for the edge of the press.
static func _click_sound() -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * S.CLICK_SECONDS)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var decay := exp(-t / (S.CLICK_SECONDS * 0.25))
		var tone := sin(TAU * S.CLICK_HZ * t)
		var edge := (randf() * 2.0 - 1.0) * exp(-t / 0.003)
		var v := clampf((tone * 0.8 + edge * 0.3) * decay, -1.0, 1.0)
		data.encode_s16(i * 2, int(v * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav


func _load_settings() -> void:
	if settings_path == "" or not FileAccess.file_exists(settings_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(settings_path))
	if typeof(parsed) == TYPE_DICTIONARY:
		for key in settings:
			if typeof(parsed.get(key)) == typeof(settings[key]):
				settings[key] = parsed[key]
		if not settings.buy_mode in BUY_MODES:
			settings.buy_mode = "1"


func _save_settings() -> void:
	if settings_path == "":
		return
	var f := FileAccess.open(settings_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(settings))
		f.close()


func _build_processing(parent: VBoxContainer) -> void:
	# Factory Overdrive (Overdrive Turbines): ×2 for 60 s, then a cooldown.
	var od := PanelContainer.new()
	od.name = "OverdriveCard"
	od.add_theme_stylebox_override("panel", _card_box())
	parent.add_child(od)
	var od_row := HBoxContainer.new()
	od.add_child(od_row)
	var od_text := VBoxContainer.new()
	od_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	od_row.add_child(od_text)
	od_text.add_child(_label("Factory Overdrive", S.SIZE_BODY, S.TEXT))
	var od_status := _label("", S.SIZE_SMALL, S.DIM)
	od_text.add_child(od_status)
	var od_button := _control_button("Overdrive", func() -> void: game.activate_overdrive())
	od_button.name = "Overdrive"
	od_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	od_row.add_child(od_button)
	_overdrive = {"card": od, "status": od_status, "button": od_button}

	for station in ["vat", "line"]:
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 12)
		parent.add_child(list)
		_slot_lists[station] = list
		var b := _control_button("", func() -> void: game.buy_slot(station))
		b.name = "BuySlot_" + station
		parent.add_child(b)
		_buy_slot[station] = b


## The Market tab (LAYOUT.md): every money lever in one place: demand spikes,
## the Delivery Van's Auto-Sell and the Raw Overflow Valve.
func _build_market(parent: VBoxContainer) -> void:
	var demand := _card(parent, "DemandCard", "Demand")
	demand.bar.visible = false
	demand.info.text = "Market Ticker spikes show here."
	_demand = demand.info
	# The Raw Overflow Valve's keep amounts, one row per crop and mash (D014).
	_valve_card = PanelContainer.new()
	_valve_card.name = "ValveCard"
	_valve_card.add_theme_stylebox_override("panel", _card_box())
	parent.add_child(_valve_card)
	var valve_col := VBoxContainer.new()
	_valve_card.add_child(valve_col)
	valve_col.add_child(_label("Raw Overflow Valve: keep", S.SIZE_BODY, S.TEXT))
	var hint := _label("Anything above the keep amount is sold.", S.SIZE_TINY, S.MUTED)
	valve_col.add_child(hint)
	for item in game.data.items:
		if game.data.items[item].kind == "bottle":
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		valve_col.add_child(row)
		var l := _label("", S.SIZE_SMALL, S.DIM)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		var minus := _small_button("−", func() -> void: game.set_keep(item, maxi(0, game.keep_amount(item) - KEEP_STEP)))
		var plus := _small_button("+", func() -> void: game.set_keep(item, maxi(0, game.keep_amount(item)) + KEEP_STEP))
		var toggle := _small_button("", func() -> void:
			if game.keep_amount(item) < 0:
				game.clear_keep(item)
			else:
				game.set_keep(item, -1))
		toggle.name = "ValveToggle_" + item
		var reset := _small_button("Default", func() -> void: game.clear_keep(item))
		for b in [minus, plus, toggle, reset]:
			row.add_child(b)
		_valve_rows[item] = {"row": row, "label": l, "minus": minus, "plus": plus, "toggle": toggle, "reset": reset}

	# The Delivery Van's Auto-Sell sliders, one per sauce (TECH_TREE.md).
	_van_card = PanelContainer.new()
	_van_card.name = "VanCard"
	_van_card.add_theme_stylebox_override("panel", _card_box())
	parent.add_child(_van_card)
	var van_col := VBoxContainer.new()
	_van_card.add_child(van_col)
	van_col.add_child(_label("Delivery Van: Auto-Sell", S.SIZE_BODY, S.TEXT))
	for item in game.data.items:
		if game.data.items[item].kind != "bottle":
			continue
		var row := HBoxContainer.new()
		van_col.add_child(row)
		var l := _label("", S.SIZE_SMALL, S.DIM)
		l.custom_minimum_size.x = 210
		row.add_child(l)
		var slider := HSlider.new()
		slider.name = "Autosell_" + item
		slider.min_value = 0
		slider.max_value = 100
		slider.step = T.AUTOSELL_STEP
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		slider.value_changed.connect(func(v: float) -> void: game.set_autosell(item, int(v)))
		row.add_child(slider)
		_van_rows[item] = {"row": row, "slider": slider, "label": l}
	# Auto-Sell comes before the valve: it's the lever used most.
	parent.move_child(_van_card, _valve_card.get_index())



## The Tech Tree page: the web pans in both directions above a fixed panel for
## the selected node.
func _build_tech(holder: Control) -> void:
	var col := VBoxContainer.new()
	col.name = "Page_tech"
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 10)
	holder.add_child(col)
	_pages.tech = col
	col.add_child(_label("TECH TREE", S.SIZE_SMALL, S.DIM))
	_web_scroll = ScrollContainer.new()
	_web_scroll.name = "WebScroll"
	_web_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(_web_scroll)

	# The web: node buttons on a grid around the Kitchen Table, joined by lines.
	var lo := Vector2(INF, INF)
	var hi := -lo
	for id in game.data.tech:
		var pos: Vector2 = game.data.tech[id].pos
		lo = lo.min(pos)
		hi = hi.max(pos)
	_web = WebLines.new()
	_web.name = "Web"
	_web.custom_minimum_size = (hi - lo) * S.WEB_STEP + S.WEB_NODE
	_web_scroll.add_child(_web)
	for id in game.data.tech_order:
		var node: Dictionary = game.data.tech[id]
		var b := Button.new()
		b.name = "Tech_" + id
		b.focus_mode = Control.FOCUS_NONE
		b.text = "%s\n%s" % [node.label, _short_name(node.name)]
		b.add_theme_font_size_override("font_size", S.SIZE_WEB)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.position = (node.pos - lo) * S.WEB_STEP
		b.size = S.WEB_NODE
		b.pressed.connect(func() -> void:
			_selected = id
			_refresh(true))
		_web.add_child(b)
		_web_nodes[id] = b
	for id in game.data.tech:
		for need in game.data.tech[id].needs:
			_web.edges.append([_web_nodes[need].position + S.WEB_NODE / 2.0, _web_nodes[id].position + S.WEB_NODE / 2.0, false])

	# The selected node: what it does, what it costs, and Research.
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _card_box())
	col.add_child(panel)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 6)
	panel.add_child(detail)
	_detail.title = _label("", S.SIZE_BODY, S.TEXT)
	detail.add_child(_detail.title)
	_detail.effect = _label("", S.SIZE_SMALL, S.DIM)
	_detail.effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_detail.effect)
	_detail.cost = _label("", S.SIZE_SMALL, S.MUTED)
	_detail.cost.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_detail.cost)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	detail.add_child(buttons)
	_detail.button = _control_button("Research", func() -> void: game.research_node(_selected))
	_detail.button.name = "Research"
	_detail.button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_child(_detail.button)
	# Smart Stockpiling: pin the node to hold back what it needs.
	_detail.pin = _control_button("Pin", func() -> void: game.set_pin("" if game.pin == _selected else _selected))
	_detail.pin.name = "Pin"
	buttons.add_child(_detail.pin)


## Stage 3: the bottom navigation bar, one button per tab.
func _build_nav() -> void:
	_nav = PanelContainer.new()
	_nav.name = "Nav"
	var bar := _box(S.PANEL, 0)
	bar.border_color = S.LINE
	bar.border_width_top = 1
	bar.content_margin_left = 6
	bar.content_margin_right = 6
	bar.border_width_bottom = 1
	_nav.add_theme_stylebox_override("panel", bar)
	# Directly under the upper viewport (D044), every tab from the start.
	_nav.anchor_right = 1.0
	_nav.anchor_top = S.UPPER_FRACTION
	_nav.anchor_bottom = S.UPPER_FRACTION
	_nav.offset_bottom = S.NAV_HEIGHT
	add_child(_nav)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	_nav.add_child(row)
	for tab in Game.TABS:
		var b := Button.new()
		b.name = "Tab_" + tab
		b.focus_mode = Control.FOCUS_NONE
		b.flat = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", S.SIZE_TINY)
		b.pressed.connect(_on_tab.bind(tab))
		row.add_child(b)
		_tab_buttons[tab] = b
	# Tapping a locked tab says what opens it, just under the selectors.
	_hint = _label("", S.SIZE_SMALL, S.TEXT)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.anchor_right = 1.0
	_hint.anchor_top = S.UPPER_FRACTION
	_hint.anchor_bottom = S.UPPER_FRACTION
	_hint.offset_top = S.NAV_HEIGHT + 8
	_hint.offset_bottom = S.NAV_HEIGHT + 40
	_hint.modulate.a = 0.0
	add_child(_hint)


func _build_upper() -> void:
	# The Blank Button, unlabelled, on the left of the upper viewport (D044).
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
	# Holding the button down: Ergonomic Grip presses it while held.
	_blank.button_down.connect(func() -> void: game.set_holding(true))
	_blank.button_up.connect(func() -> void: game.set_holding(false))
	add_child(_blank)
	_place_blank()

	# The Heat Meter (D011): a bar under the button and the bonus beside it.
	_heat_bar = ProgressBar.new()
	_heat_bar.name = "HeatBar"
	_heat_bar.max_value = T.HEAT_MAX
	_heat_bar.show_percentage = false
	_heat_bar.add_theme_stylebox_override("background", _box(S.CONTROL_DISABLED, 3))
	_heat_bar.add_theme_stylebox_override("fill", _box(S.HEAT, 3))
	_heat_bar.anchor_top = S.UPPER_FRACTION
	_heat_bar.anchor_bottom = S.UPPER_FRACTION
	_heat_bar.offset_left = S.GUTTER
	_heat_bar.offset_right = S.GUTTER + S.BLANK_BUTTON_COMPACT
	_heat_bar.offset_top = -30.0
	_heat_bar.offset_bottom = -24.0
	add_child(_heat_bar)
	_heat_label = _label("", S.SIZE_TINY, S.HEAT)
	_heat_label.name = "HeatLabel"
	_heat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heat_label.anchor_top = S.UPPER_FRACTION
	_heat_label.anchor_bottom = S.UPPER_FRACTION
	_heat_label.offset_left = S.GUTTER
	_heat_label.offset_right = S.GUTTER + S.BLANK_BUTTON_COMPACT
	_heat_label.offset_top = -22.0
	_heat_label.offset_bottom = -2.0
	add_child(_heat_label)

	# The factory view, right of the button, and Sell Batch under it (D044).
	var right := S.GUTTER + S.BLANK_BUTTON_COMPACT + 14.0
	_factory = FactoryView.new()
	_factory.name = "Factory"
	_factory.game = game
	_factory.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_factory.anchor_right = 1.0
	_factory.anchor_bottom = S.UPPER_FRACTION
	_factory.offset_left = right
	_factory.offset_right = -S.GUTTER
	_factory.offset_top = S.STATUS_BAR_HEIGHT + S.STRIP_TOP + 30.0
	_factory.offset_bottom = -S.SELL_BATCH_HEIGHT - 16.0
	add_child(_factory)
	_sell_batch = _control_button("", func() -> void: game.sell_batch())
	_sell_batch.name = "SellBatch"
	_sell_batch.anchor_right = 1.0
	_sell_batch.anchor_top = S.UPPER_FRACTION
	_sell_batch.anchor_bottom = S.UPPER_FRACTION
	_sell_batch.offset_left = right
	_sell_batch.offset_right = -S.GUTTER
	_sell_batch.offset_bottom = -8.0
	_sell_batch.offset_top = -8.0 - S.SELL_BATCH_HEIGHT
	add_child(_sell_batch)

	# The stock line, under the goal line.
	_counter = Label.new()
	_counter.name = "Counter"
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_counter.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_counter.add_theme_font_size_override("font_size", S.SIZE_BODY)
	_counter.add_theme_color_override("font_color", S.TEXT)
	_counter.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_counter.offset_left = S.GUTTER
	_counter.offset_right = -S.GUTTER
	_counter.offset_top = S.STATUS_BAR_HEIGHT + S.STRIP_TOP
	_counter.offset_bottom = _counter.offset_top + 26
	_counter.max_lines_visible = 1
	_counter.add_theme_font_size_override("font_size", S.SIZE_TINY)
	# Tapping the stock opens the warehouse drawer.
	_counter.mouse_filter = Control.MOUSE_FILTER_STOP
	_counter.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
			open_drawer())
	add_child(_counter)

	# The goal line (LAYOUT.md): the next action early on, then the goal bar.
	_goal = _label("", S.SIZE_TINY, S.ORANGE)
	_goal.name = "Goal"
	_goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_goal.clip_text = true
	_goal.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_goal.offset_left = S.GUTTER
	_goal.offset_right = -S.GUTTER
	_goal.offset_top = S.STATUS_BAR_HEIGHT + S.GOAL_TOP
	_goal.offset_bottom = _goal.offset_top + 24
	add_child(_goal)


func _build_status_bar() -> void:
	# The status bar, from the start (D044).
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
	var money := VBoxContainer.new()
	money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	money.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	money.add_theme_constant_override("separation", 0)
	row.add_child(money)
	_cash = _label("", S.SIZE_BODY, S.GREEN)
	money.add_child(_cash)
	# Operation Value under Cash.
	_ov = _label("", S.SIZE_TINY, S.DIM)
	_ov.name = "OperationValue"
	_ov.clip_text = true
	money.add_child(_ov)
	# A Market Ticker spike, while one runs.
	_spike = _label("", S.SIZE_TINY, S.HEAT)
	_spike.name = "Spike"
	_spike.clip_text = true
	money.add_child(_spike)
	money.custom_minimum_size.x = 0
	money.clip_contents = true
	_sell = _control_button("Sell Raw Peppers (%s/ea)" % _money(game.value("bell")), func() -> void: game.sell_raw())
	_sell.name = "SellRaw"
	_sell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_sell)


## The "While you were away" card (OFFLINE.md): over everything, closed by a tap
## anywhere.
func _build_card() -> void:
	_return_card = ColorRect.new()
	_return_card.name = "ReturnCard"
	(_return_card as ColorRect).color = S.SHADE
	_return_card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_return_card.mouse_filter = Control.MOUSE_FILTER_STOP
	_return_card.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
			close_card())
	_return_card.visible = false
	add_child(_return_card)
	var panel := PanelContainer.new()
	var box := _box(S.PANEL, S.RADIUS)
	box.set_content_margin_all(22)
	box.border_color = S.LINE
	box.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", box)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(400, 0)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_return_card.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	col.add_child(_label("While you were away", S.SIZE_SMALL, S.DIM))
	for key in ["time", "cap", "cash", "ov", "made"]:
		var l := _label("", S.SIZE_BODY if key == "time" else S.SIZE_SMALL, S.GREEN if key == "cash" else S.TEXT)
		l.name = "Return_" + key
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(l)
		_return_text[key] = l
	col.add_child(_label("Tap to carry on", S.SIZE_TINY, S.MUTED))


func _show_card(r: Dictionary) -> void:
	_return_text.time.text = _duration(r.away)
	_return_text.cap.visible = r.capped
	var more := false
	for id in game.data.tech:
		for e in game.data.tech[id].effects:
			if e.has("offline") and not game.is_researched(id):
				more = true
	_return_text.cap.text = "Counted up to %s at %d%%.%s" % [_duration(r.counted), roundi(game.offline_speed() * 100.0), " Night Shift Protocols raise it." if more else ""]
	_return_text.cash.text = "+%s cash" % _money(r.cash_earned)
	_return_text.ov.text = "Operation Value +%s" % _money(r.ov)
	var made: Array = r.made.keys()
	# The three worth most, so sauces aren't crowded out by heaps of crops.
	made.sort_custom(func(a, b): return r.made[a] * game.appraisal(a) > r.made[b] * game.appraisal(b))
	var top := []
	for item in made.slice(0, 3):
		top.append("%s %s" % [_count(r.made[item]), game.data.items[item].plural])
	_return_text.made.text = "Made: " + ", ".join(top) if not top.is_empty() else "Nothing was running."
	_return_card.visible = true
	_return_card.move_to_front()


func close_card() -> void:
	_return_card.visible = false


## "3 h 12 m", "12 m", "40 s".
static func _duration(seconds: float) -> String:
	var s := int(seconds)
	if s >= 3600:
		return "%d h %d m" % [s / 3600, (s / 60) % 60]
	if s >= 60:
		return "%d m" % (s / 60)
	return "%d s" % s


## A plot's card: what it grows, a cycle bar, then its buy button, or Manage
## for its upgrades (the station sheet, LAYOUT.md).
func _plot_card(parent: Container, crop: String) -> Dictionary:
	var nodes := _card(parent, "Card_plot_" + crop, game.data.plots[crop].name)
	nodes.buy = _control_button("", func() -> void: game.buy_plot(crop))
	nodes.buy.name = "Buy_plot_" + crop
	nodes.col.add_child(nodes.buy)
	# Every crop sells raw, as ore does (D041).
	nodes.sell = _control_button("", func() -> void: game.sell_crop(crop))
	nodes.sell.name = "Sell_plot_" + crop
	nodes.col.add_child(nodes.sell)
	nodes.manage = _control_button("Manage", func() -> void: open_sheet({"kind": "plot", "crop": crop}))
	nodes.manage.name = "Manage_plot_" + crop
	nodes.col.add_child(nodes.manage)
	return nodes


## A vat or line slot's card: its recipe picker, a cycle bar and its speed.
func _slot_card(station: String, index: int) -> Dictionary:
	var nodes := _card(_slot_lists[station], "Card_%s_%d" % [station, index], "%s %d" % [STATION_NAMES[station], index + 1])
	var picker := OptionButton.new()
	picker.name = "Recipe_%s_%d" % [station, index]
	picker.focus_mode = Control.FOCUS_NONE
	picker.add_theme_font_size_override("font_size", S.SIZE_SMALL)
	picker.item_selected.connect(func(i: int) -> void:
		game.assign(station, index, str(picker.get_item_metadata(i)))
		_refresh(true))
	nodes.col.add_child(picker)
	nodes.col.move_child(picker, 1)
	nodes.picker = picker
	nodes.recipes = []
	nodes.manage = _control_button("Manage", func() -> void: open_sheet({"kind": "slot", "station": station, "index": index}))
	nodes.manage.name = "Manage_%s_%d" % [station, index]
	nodes.col.add_child(nodes.manage)
	return nodes


## A card with a title, an info line, a cycle bar and a status line. Returns its
## nodes; "col" is where more go.
func _card(parent: Container, name: String, title: String) -> Dictionary:
	var panel := PanelContainer.new()
	panel.name = name
	panel.add_theme_stylebox_override("panel", _card_box())
	parent.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var nodes := {"card": panel, "col": col}
	nodes.title = _label(title, S.SIZE_BODY, S.TEXT)
	col.add_child(nodes.title)
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
	return nodes


## Puts the Blank Button in the middle of the screen, or (compact) at the foot
## of the upper viewport once the deck is open.
func _place_blank() -> void:
	var side := S.BLANK_BUTTON_COMPACT
	_blank.anchor_left = 0.0
	_blank.anchor_right = 0.0
	_blank.anchor_top = S.UPPER_FRACTION
	_blank.anchor_bottom = S.UPPER_FRACTION
	_blank.offset_left = S.GUTTER
	_blank.offset_right = S.GUTTER + side
	_blank.offset_bottom = -36.0
	_blank.offset_top = -36.0 - side
	_blank.pivot_offset = Vector2.ONE * side / 2.0


func _on_blank_pressed() -> void:
	game.press()
	_feel_press()
	var squash := create_tween()
	squash.tween_property(_blank, "scale", Vector2.ONE * 0.92, S.PRESS_SQUASH * 0.4)
	squash.tween_property(_blank, "scale", Vector2.ONE, S.PRESS_SQUASH * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_refresh(true)


func _on_tab(tab: String) -> void:
	if game.tab_open(tab):
		_page = tab
		if tab == "tech" and not _web_centred:
			_web_centred = true
			_centre_web.call_deferred()
	else:
		var at: float = T.TAB_THRESHOLDS.get(tab, INF)
		_hint.text = "Opens with The Delivery Van (Tech Tree)" if tab == "market" else "Opens at %s Operation Value%s" % [_money(at), "" if tab in T.TABS_BUILT else ", in a later version"]
		_hint.modulate.a = 1.0
		create_tween().tween_property(_hint, "modulate:a", 0.0, 0.6).set_delay(1.6)
	_refresh(true)


# --- Showing ---------------------------------------------------------------

## Shows the state. `animate` plays a reveal's entrance the moment it happens.
func _refresh(animate: bool) -> void:
	_counter.text = _stock_text()
	_goal.text = _goal_text()
	_count_cash()
	_cash.text = "Cash: " + _money(_shown_cash)
	_ov.text = "Operation Value " + _money(game.operation_value())
	_spike.visible = game.ticker.sauce != ""
	if _spike.visible:
		var left: float = (game.ticker.ends - game.stats.ticks) * T.TICK_SECONDS
		_spike.text = "%s ×%d · %d min left" % [game.data.items[game.ticker.sauce].short, int(game.ticker.mult), ceili(left / 60.0)]
	_demand.text = ("%s sells for ×%d now." % [game.data.items[game.ticker.sauce].name, int(game.ticker.mult)]) if _spike.visible \
		else ("Calm: no spike now. Spikes come about once an hour." if game.fx.ticker else "The Market Ticker (Tech Tree) brings demand spikes.")
	var heat_on: bool = game.fx.heat
	_heat_bar.visible = heat_on
	_heat_label.visible = heat_on
	_heat_bar.value = game.heat
	_heat_label.text = "Heat +%d%%" % roundi((game.heat_mult() - 1.0) * 100.0)
	_sell.disabled = not game.can_sell_raw()
	_sell_batch.visible = not game.lines.is_empty()
	_sell_batch.text = "Sell Batch   %s" % _money(game.bottles_value())
	_sell_batch.disabled = game.bottles_held() == 0

	# The vats and lines live on Farms until Processing opens.
	var home := _processing_col if game.tab_open("processing") else _farms_col
	if _proc_box.get_parent() != home:
		_proc_box.reparent(home)
	if not game.tab_open(_page):
		_page = "farms"
	for tab in _pages:
		_pages[tab].visible = tab == _page
	for crop in _plot_cards:
		_refresh_plot(crop)
	for key in _settings_buttons:
		_settings_buttons[key].text = "%s: %s" % [key.capitalize(), "On" if settings[key] else "Off"]
	_refresh_processing()
	if _page == "tech":
		_refresh_tech()
	if _page == "hq":
		_refresh_hq()
	else:
		_sell_armed = false
	if _sheet.visible:
		_refresh_sheet()
	if _drawer.visible:
		_refresh_drawer()
	for tab in _tab_buttons:
		var b: Button = _tab_buttons[tab]
		var open := game.tab_open(tab)
		# A locked tab says what opens it (D044): its price, or the Van.
		b.text = TAB_NAMES[tab] if open else "%s\n%s" % [TAB_NAMES[tab], "Van" if tab == "market" else _short_money(T.TAB_THRESHOLDS.get(tab, INF))]
		b.add_theme_color_override("font_color", S.ORANGE if tab == _page else (S.TEXT if open else S.MUTED))


## The stock line: Bell Peppers first, then everything the player has had. Short
## names once Tier 2 crowds it.
func _stock_text() -> String:
	var parts := []
	for item in game.data.items:
		var seen: bool = item == "bell" or game.stock[item] > 0 or game.stats.made[item] > 0 or game.stats.harvested[item] > 0
		if seen:
			parts.append([item, game.stock[item]])
	if parts.size() <= 3:
		var long := []
		for p in parts:
			long.append("%s: %d" % [game.data.items[p[0]].plural, p[1]])
		return "   ".join(long)
	# A crowded factory: Bell Peppers and the bottles in stock, on one line;
	# everything else is in the warehouse drawer (LAYOUT.md).
	var short := []
	for p in parts:
		if p[1] > 0 and game.data.items[p[0]].kind == "bottle":
			short.append("%s %s" % [game.data.items[p[0]].short, _count(p[1])])
	short.push_front("%s %s" % [game.data.items.bell.short, _count(game.stock.bell)])
	return "  ·  ".join(short)


func _refresh_plot(crop: String) -> void:
	var nodes: Dictionary = _plot_cards[crop]
	var p: Dictionary = game.plots[crop]
	var name: String = game.data.items[crop].name
	var plural: String = game.data.items[crop].plural
	nodes.card.visible = game.plot_offered(crop)
	if p.owned:
		# Yield levels add fractions (D041): one decimal once it isn't whole.
		var n := game.plot_yield_exact(crop)
		var amount := "%d" % roundi(n) if absf(n - roundf(n)) < 0.05 else "%.1f" % n
		nodes.info.text = "%s %s every %.1f s" % [amount, name if amount == "1" else plural, game.plot_cycle(crop)]
	else:
		nodes.info.text = "Harvests %s by itself." % plural
	nodes.bar.visible = p.owned
	nodes.bar.value = clampf(p.progress / game.plot_cycle(crop), 0.0, 1.0)
	# The truck (Cargo, D043): what it carries, and what's waiting once the
	# plot has outgrown it.
	nodes.status.visible = p.owned
	if p.owned:
		var backed_up: bool = p.field > 2.0 * game.plot_yield_exact(crop)
		nodes.status.text = "Truck carries %.1f a second" % game.cargo_rate(crop)
		if backed_up:
			nodes.status.text += "   ·   %s waiting" % _count(p.field)
		nodes.status.add_theme_color_override("font_color", S.ORANGE if backed_up else S.MUTED)
	nodes.buy.visible = not p.owned
	nodes.buy.text = "Buy   %s" % _money(game.plot_price(crop))
	nodes.buy.disabled = not game.can_buy_plot(crop)
	nodes.sell.visible = p.owned
	nodes.sell.text = "Sell %s   %s" % [_count(game.stock[crop]), _money(game.stock[crop] * game.sale_price(crop) * game.heat_mult())]
	nodes.sell.disabled = not game.can_sell_crop(crop)
	nodes.manage.visible = p.owned
	var ready := false
	for upgrade in UPGRADE_NAMES:
		ready = ready or game.can_upgrade_plot(crop, upgrade)
	nodes.manage.text = "Manage   !" if ready else "Manage"


func _refresh_processing() -> void:
	_overdrive.card.visible = game.fx.overdrive
	if game.fx.overdrive:
		if game.overdrive_active():
			_overdrive.status.text = "Running: ×2 for %d s" % ceili((game.overdrive.until - game.stats.ticks) * T.TICK_SECONDS)
		elif game.can_overdrive():
			_overdrive.status.text = "Ready: ×2 vat and line speed for 60 s"
		else:
			var wait: int = ceili((game.overdrive.ready - game.stats.ticks) * T.TICK_SECONDS)
			_overdrive.status.text = "Ready in %d:%02d" % [wait / 60, wait % 60]
		_overdrive.button.disabled = not game.can_overdrive()
	_valve_card.visible = game.fx.valve
	if game.fx.valve:
		for item in _valve_rows:
			var r: Dictionary = _valve_rows[item]
			var seen: bool = game.stock[item] > 0 or game.stats.made[item] > 0 or game.stats.harvested[item] > 0
			r.row.visible = seen
			var k := game.keep_amount(item)
			var name: String = game.data.items[item].name
			if k < 0:
				r.label.text = "%s: not sold" % name
			else:
				r.label.text = "%s: %d%s" % [name, k, "" if game.keep.has(item) else " (default)"]
			if game.pinned_need(item) > k and k >= 0:
				r.label.text += ", pinned %d" % game.pinned_need(item)
			r.toggle.text = "On" if k < 0 else "Off"
			r.minus.disabled = k <= 0
			r.reset.disabled = not game.keep.has(item)
	_van_card.visible = game.has_van()
	if game.has_van():
		for item in _van_rows:
			var r: Dictionary = _van_rows[item]
			r.row.visible = _bottle_unlocked(item)
			r.label.text = "%s  %d%%" % [game.data.items[item].name, game.autosell[item]]
			r.slider.set_value_no_signal(game.autosell[item])
	for station in ["vat", "line"]:
		var cards: Array = _slot_cards[station]
		while cards.size() < game.slots(station).size():
			cards.append(_slot_card(station, cards.size()))
		# A loaded save (or, later, a Prestige) can have fewer slots.
		while cards.size() > game.slots(station).size():
			cards.pop_back().card.queue_free()
		for i in cards.size():
			_refresh_slot(station, i)
		var b: Button = _buy_slot[station]
		var n := game.slots(station).size()
		b.visible = game.slot_offered(station)
		var extra := "  ·  with a Starter Crate of %d" % T.STARTER_CRATE_BOTTLES if station == "line" and n == 0 else ""
		b.text = "Buy %s %d   %s%s" % [STATION_NAMES[station], n + 1, _money(game.slot_price(station)), extra]
		b.disabled = not game.can_buy_slot(station)


func _refresh_slot(station: String, i: int) -> void:
	var nodes: Dictionary = _slot_cards[station][i]
	var s: Dictionary = game.slots(station)[i]
	# The picker's list: Off, then every recipe researched for this station.
	var recipes := game.recipes_for(station)
	if recipes != nodes.recipes:
		nodes.recipes = recipes
		var picker: OptionButton = nodes.picker
		picker.clear()
		picker.add_item("Off")
		picker.set_item_metadata(0, "")
		for r in recipes:
			picker.add_item(game.data.items[game.data.recipes[r].output].name)
			picker.set_item_metadata(picker.item_count - 1, r)
	nodes.picker.select(nodes.recipes.find(s.recipe) + 1)
	if s.recipe == "":
		nodes.info.text = "Off. Pick a recipe to start it."
		nodes.bar.value = 0.0
	else:
		var r: Dictionary = game.data.recipes[s.recipe]
		var inputs := game.recipe_inputs(s.recipe)
		var ins := []
		for item in inputs:
			var n: int = inputs[item]
			ins.append("%d %s" % [n, game.data.items[item].name if n == 1 else game.data.items[item].plural])
		var out: Dictionary = game.data.items[r.output]
		var worth := " (%s)" % _money(out.value) if out.kind == "bottle" else ""
		nodes.info.text = "%s → 1 %s%s every %.1f s" % [" + ".join(ins), out.name, worth, game.slot_cycle(station, i)]
		nodes.bar.value = clampf(s.progress / game.slot_cycle(station, i), 0.0, 1.0)
	var status := ""
	if s.recipe != "" and not s.running:
		status = "Waiting for inputs"
	if station == "line" and s.crate > 0:
		status = "Starter Crate: %d bottles left at %d× speed" % [s.crate, int(T.STARTER_CRATE_SPEED)]
	nodes.status.text = status
	nodes.status.visible = status != ""
	nodes.manage.text = "Manage   !" if game.can_upgrade_slot(station, i) else "Manage"


func _refresh_tech() -> void:
	for id in _web_nodes:
		var b: Button = _web_nodes[id]
		var researched := game.is_researched(id)
		var reachable := game.research_reachable(id)
		var fill := S.CONTROL_DISABLED
		var edge := S.LINE
		if researched:
			fill = Color(S.GREEN, 0.25)
			edge = S.GREEN
		elif game.can_research(id):
			fill = S.CONTROL
			edge = S.ORANGE
		elif reachable:
			fill = S.CONTROL
		if id == game.pin:
			edge = S.HEAT
		var box := _box(fill, 10)
		box.border_color = S.TEXT if id == _selected else edge
		box.set_border_width_all(3 if id == _selected else 2)
		for state in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(state, box)
		b.add_theme_color_override("font_color", S.TEXT if researched or reachable else S.MUTED)
		b.add_theme_color_override("font_hover_color", S.TEXT)
	var i := 0
	for id in game.data.tech:
		for need in game.data.tech[id].needs:
			_web.edges[i][2] = game.is_researched(id)
			i += 1
	_web.queue_redraw()

	var node: Dictionary = game.data.tech[_selected]
	_detail.title.text = "%s  %s" % [node.label, node.name]
	_detail.effect.text = _effect_text(node)
	var costs := []
	var cost := game.tech_cost(_selected)
	for item in cost:
		costs.append("%d %s (have %d)" % [cost[item], game.data.items[item].plural, game.stock[item]])
	var fork := game.fork_taken(_selected)
	if game.is_researched(_selected):
		_detail.cost.text = "Researched."
	elif node.after_sale and game.account.prestiges < 1:
		_detail.cost.text = "Opens after your first franchise sale."
	elif fork != "":
		_detail.cost.text = "Chose %s instead: locked for this run." % game.data.tech[fork].name.get_slice(": ", 1)
	elif costs.is_empty():
		_detail.cost.text = "Free."
	else:
		var needs := []
		for need in node.needs:
			if not game.is_researched(need):
				needs.append(game.data.tech[need].label)
		_detail.cost.text = "Costs " + ", ".join(costs) + (".  Needs %s first." % ", ".join(needs) if not needs.is_empty() else ".")
	_detail.button.visible = not game.is_researched(_selected)
	_detail.button.disabled = not game.can_research(_selected)
	_detail.pin.visible = game.fx.stockpile and not game.is_researched(_selected)
	_detail.pin.text = "Unpin" if game.pin == _selected else "Pin"
	if game.pin != "" and game.pin == _selected:
		_detail.cost.text += "  Pinned: what it needs is held back."


## Scrolls the web so the Kitchen Table is in the middle, once the page has
## been laid out.
func _centre_web() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var b: Button = _web_nodes.kitchen_table
	var centre := b.position + S.WEB_NODE / 2.0
	_web_scroll.scroll_horizontal = int(centre.x - _web_scroll.size.x / 2.0)
	_web_scroll.scroll_vertical = int(centre.y - _web_scroll.size.y / 2.0)


func _effect_text(node: Dictionary) -> String:
	if node.effects.is_empty():
		return "The centre of the web."
	var out := []
	for e in node.effects:
		if e.has("unlock_plot"):
			out.append("The %s can be bought." % game.data.plots[e.unlock_plot].name)
		elif e.has("unlock_recipe"):
			var r: Dictionary = game.data.recipes[e.unlock_recipe]
			out.append("Vats and lines can make %s." % game.data.items[r.output].name if r.station == "vat" else "Lines can bottle %s." % game.data.items[r.output].name)
		elif e.has("delivery_van"):
			out.append("Auto-Sell sliders: finished bottles sell the moment they're made.")
		elif e.has("tap_yield"):
			out.append("+%d Bell Peppers a press of the button." % int(e.tap_yield))
		elif e.has("double_tap"):
			out.append("%d%% of presses count twice." % roundi(e.double_tap * 100.0))
		elif e.has("grip"):
			out.append("Holding the button presses it %d times a second." % int(e.grip))
		elif e.has("heat_meter"):
			out.append("Pressing builds Heat, up to +50% on every sale while you keep it up.")
		elif e.has("heat_drain"):
			out.append("Heat drains half as fast.")
		elif e.has("overclock"):
			out.append("Each press takes %.2f s off every running vat and line." % e.overclock)
		elif e.has("piston"):
			out.append("Presses the button once a second, always, with every button perk.")
		elif e.has("plot_speed"):
			out.append("The %s runs %d× faster." % [game.data.plots[e.plot_speed.crop].name, int(e.plot_speed.mult)])
		elif e.has("plot_yield"):
			out.append("The %s yields %d× a harvest." % [game.data.plots[e.plot_yield.crop].name, int(e.plot_yield.mult)])
		elif e.has("concentrate"):
			out.append("Vats need %d%% less %s." % [roundi(e.concentrate.share * 100.0), game.data.items[e.concentrate.item].name])
		elif e.has("reserve"):
			out.append("Every sauce made with %s sells for +%d%%." % [game.data.items[e.reserve.item].name, roundi(e.reserve.bonus * 100.0)])
		elif e.has("slot_cap"):
			out.append("One more vat slot and one more line slot.")
		elif e.has("packaging"):
			out.append("Every bottle is worth %.1f× (packaging, every line)." % e.packaging)
		elif e.has("input_reduction"):
			out.append("Vats need %d%% fewer raw crops." % roundi(e.input_reduction * 100.0))
		elif e.has("overdrive"):
			out.append("Vats and lines +25% faster, and the Factory Overdrive button: ×2 for 60 s, every 15 minutes.")
		elif e.has("overflow_valve"):
			out.append("Crops and mash above their keep amount sell automatically.")
		elif e.has("smart_stockpiling"):
			out.append("Pin a node to hold back the bottles, mash and crops it needs.")
		elif e.has("sop"):
			out.append("Any node costing under 1% of an hour's bottles researches itself, free. Either/or nodes stay your choice.")
		elif e.has("market_ticker"):
			out.append("Demand spikes: a sauce sells for ×2 or ×3 for 30 minutes, about once an hour.")
		elif e.has("forage"):
			out.append("Each press has a %.1f%% chance to drop a harvest of the ingredient you're shortest of." % (e.forage * 100.0))
		elif e.has("byproduct_recycling"):
			out.append("Vat cycles can give your lowest-level plot a free level, up to one a minute.")
		elif e.has("offline"):
			out.append("Time away counts %d hours longer, and runs %d points faster." % [int(e.offline.hours), roundi(e.offline.speed * 100.0)])
		elif e.has("stock_value_bonus"):
			out.append("Stock counts %d%% more in Operation Value." % roundi(e.stock_value_bonus * 100.0))
	for other in node.excludes:
		out.append("Either/or: it locks %s for this run." % game.data.tech[other].name)
	return " ".join(out)


func _bottle_unlocked(item: String) -> bool:
	for r in game.recipes_for("line"):
		if game.data.recipes[r].output == item:
			return true
	return false


## Moves the Blank Button between its full-screen and compact places, sliding
## from where it was when `animate`.
# --- Layout step 1 (docs/LAYOUT.md) ------------------------------------------

## The goal bar: the next tab before the Tech Tree, then the next node; the
## sale's progress from half way.
func _goal_text() -> String:
	# Early on, the one next action (D044).
	var next := game.next_action()
	if not next.is_empty():
		return "Next: " + _next_text(next)
	var parts := []
	if not game.tab_open("tech"):
		var at: float = T.TAB_THRESHOLDS.tech
		parts.append("Tech Tree at %s: %d%%" % [_money(at), floori(minf(game.account.best_ov / at, 1.0) * 100.0)])
	else:
		var node := game.goal_node()
		if node != "":
			var scarce := game.scarcest_cost(node)
			var name: String = _short_name(game.data.tech[node].name)
			if scarce.is_empty():
				parts.append("Next: %s, free" % name)
			else:
				parts.append("Next: %s, %s/%s %s" % [name, _count(mini(scarce[1], scarce[2])), _count(scarce[2]), game.data.items[scarce[0]].short])
	var sale := game.operation_value() / T.PRESTIGE_OV
	if sale >= 1.0:
		parts.append("Sale ready")
	elif sale >= 0.5:
		parts.append("Sale %d%%" % floori(sale * 100.0))
	return "  ·  ".join(parts)


## A threshold on a tab selector, as short as it goes: $4K, $7.5K, $10M.
static func _short_money(amount: float) -> String:
	var v := amount
	var i := -1
	while v >= 1000.0 and i < MONEY_SUFFIXES.size() - 1:
		v /= 1000.0
		i += 1
	var n := ("%.1f" % v).trim_suffix(".0")
	return "$" + n + (MONEY_SUFFIXES[i] if i >= 0 else "")


## The next action in words, for the goal line.
func _next_text(next: Dictionary) -> String:
	match next.do:
		"press":
			return "tap the button"
		"sell_raw":
			return "sell your Bell Peppers"
		"sell_batch":
			return "Sell Batch"
		"buy_plot":
			return "buy the %s (%s)" % [game.data.plots[next.id].name, _money(game.plot_price(next.id))]
		"buy_slot":
			return "buy %s %d (%s)" % [STATION_NAMES[next.id], game.slots(next.id).size() + 1, _money(game.slot_price(next.id))]
		"tab":
			return "open the %s" % TAB_NAMES[next.id]
	return ""


## The control the next action is on, and the tab it lives on ("" for one
## always on screen).
func _next_target(next: Dictionary) -> Array:
	match next.get("do", ""):
		"press":
			return [_blank, ""]
		"sell_raw":
			return [_sell, ""]
		"sell_batch":
			return [_sell_batch, ""]
		"buy_plot":
			return [_plot_cards[next.id].buy, "farms"]
		"buy_slot":
			return [_buy_slot[next.id], "processing" if game.tab_open("processing") else "farms"]
		"tab":
			return [_tab_buttons[next.id], ""]
	return [null, ""]


## Rings the next action, or its tab's selector while another tab is open, and
## scrolls a long page to it when it changes.
func _place_ring(delta: float) -> void:
	var found := _next_target(game.next_action())
	var target: Control = found[0]
	var page: String = found[1]
	if target != null and page != "" and page != _page:
		target = _tab_buttons[page]
	elif target != null and page != "" and target != _ring_target:
		(_pages[page] as ScrollContainer).ensure_control_visible(target)
	_ring_target = target
	_ring.visible = target != null and target.is_visible_in_tree() and not _sheet.visible and not _drawer.visible
	if not _ring.visible:
		return
	_ring_t += delta
	var r := target.get_global_rect().grow(4.0)
	_ring.position = r.position - global_position
	_ring.size = r.size
	_ring.modulate.a = 0.55 + 0.45 * sin(_ring_t * TAU / S.RING_PULSE)


## Dots climbing the factory view: crops reaching stock, mash made.
func _climb(delta: float) -> void:
	var delivered := 0
	for crop in game.plots:
		delivered += game.stats.harvested[crop] - game.plots[crop].field
	var mash := 0
	for item in game.data.items:
		if game.data.items[item].kind == "mash":
			mash += game.stats.made[item]
	_dot_wait = maxf(0.0, _dot_wait - delta)
	# Between dots the counts build up; the next dot stands for all of them.
	if _seen_delivered < 0 or _dot_wait <= 0.0:
		if _seen_delivered >= 0 and (mash > _seen_mash or delivered > _seen_delivered):
			_factory.climb(1 if mash > _seen_mash else 2)
			dots_shown += 1
			_dot_wait = 1.0 / S.DOTS_PER_SECOND
		_seen_delivered = delivered
		_seen_mash = mash


## Cash on screen counts up to a rise of COUNT_UP_FROM or more over COUNT_UP
## seconds; a smaller rise, or any fall (spending), shows at once.
func _count_cash() -> void:
	var real: float = game.cash
	if real < _shown_cash or real - _countup.to < S.COUNT_UP_FROM and _countup.t >= 1.0:
		_shown_cash = real
		_countup = {"from": real, "to": real, "t": 1.0}
		return
	if real > _countup.to:
		_countup = {"from": _shown_cash, "to": real, "t": 0.0}
	_countup.t = minf(1.0, _countup.t + _frame_delta / S.COUNT_UP)
	_shown_cash = minf(real, lerpf(_countup.from, _countup.to, _countup.t))
	if _countup.t >= 1.0:
		_shown_cash = real


## A shaded overlay with a panel over the bottom of the screen, closed by a tap
## outside it. The panel's column is the overlay's "box" meta.
func _build_overlay(name: String) -> Control:
	var shade := ColorRect.new()
	shade.name = name
	shade.color = S.SHADE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	shade.visible = false
	shade.gui_input.connect(func(e: InputEvent) -> void:
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
			shade.visible = false)
	add_child(shade)
	var panel := PanelContainer.new()
	var box := _box(S.PANEL, S.RADIUS)
	box.set_content_margin_all(S.GUTTER)
	box.border_color = S.LINE
	box.border_width_top = 1
	panel.add_theme_stylebox_override("panel", box)
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0 - S.SHEET_FRACTION
	panel.anchor_bottom = 1.0
	shade.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	scroll.add_child(col)
	shade.set_meta("box", col)
	return shade


## Opens a station's sheet: its upgrades, bought ×1, ×10 or Max.
func open_sheet(of: Dictionary) -> void:
	_sheet_of = of
	# Out of the tree at once, so the new buttons keep their names.
	for c in _sheet_box.get_children():
		_sheet_box.remove_child(c)
		c.queue_free()
	_sheet_buttons = {}
	_mode_buttons = {}
	var title: String = game.data.plots[of.crop].name if of.kind == "plot" else "%s %d" % [STATION_NAMES[of.station], of.index + 1]
	_sheet_box.add_child(_label(title, S.SIZE_BODY, S.TEXT))
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 8)
	_sheet_box.add_child(modes)
	for mode in BUY_MODES:
		var b := _small_button("Max" if mode == "max" else "×" + mode, func() -> void:
			settings.buy_mode = mode
			_save_settings())
		b.name = "Mode_" + mode
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		modes.add_child(b)
		_mode_buttons[mode] = b
	var upgrades: Array = UPGRADE_NAMES.keys() if of.kind == "plot" else ["speed"]
	for upgrade in upgrades:
		var b := _control_button("", func() -> void: _buy_levels(upgrade))
		b.name = "Upgrade_%s_%s" % ["plot_" + of.crop if of.kind == "plot" else "%s_%d" % [of.station, of.index], upgrade]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_sheet_box.add_child(b)
		_sheet_buttons[upgrade] = b
	var done := _control_button("Done", func() -> void: _sheet.visible = false)
	done.name = "SheetDone"
	_sheet_box.add_child(done)
	_sheet.visible = true
	_sheet.move_to_front()
	_refresh_sheet()


## Levels the buy mode would buy of an upgrade now: 1, BULK_LEVELS, or as many
## as cash covers; 0 when that many aren't affordable.
func _levels(upgrade: String) -> int:
	var can: int = game.plot_levels_affordable(_sheet_of.crop, upgrade) if _sheet_of.kind == "plot" else game.slot_levels_affordable(_sheet_of.station, _sheet_of.index)
	match settings.buy_mode:
		"10":
			return T.BULK_LEVELS if can >= T.BULK_LEVELS else 0
		"max":
			return can
	return 1 if can >= 1 else 0


func _buy_levels(upgrade: String) -> void:
	var n := _levels(upgrade)
	if _sheet_of.kind == "plot":
		game.upgrade_plot_n(_sheet_of.crop, upgrade, n)
	else:
		game.upgrade_slot_n(_sheet_of.station, _sheet_of.index, n)


func _refresh_sheet() -> void:
	# A sale can take the station away under an open sheet.
	if _sheet_of.kind == "slot" and _sheet_of.index >= game.slots(_sheet_of.station).size() \
			or _sheet_of.kind == "plot" and not game.plots[_sheet_of.crop].owned:
		_sheet.visible = false
		return
	for mode in _mode_buttons:
		_mode_buttons[mode].add_theme_color_override("font_color", S.ORANGE if mode == settings.buy_mode else S.TEXT)
	for upgrade in _sheet_buttons:
		var b: Button = _sheet_buttons[upgrade]
		var n := _levels(upgrade)
		var shown := n if n > 0 else (T.BULK_LEVELS if settings.buy_mode == "10" else 1)
		var lv: int
		var cost: float
		var name: String
		if _sheet_of.kind == "plot":
			lv = game.plots[_sheet_of.crop][upgrade]
			cost = game.plot_upgrade_cost_n(_sheet_of.crop, upgrade, shown)
			name = UPGRADE_NAMES[upgrade]
		else:
			lv = game.slots(_sheet_of.station)[_sheet_of.index].speed
			cost = game.slot_upgrade_cost_n(_sheet_of.station, _sheet_of.index, shown)
			name = "Speed"
		if cost < INF:
			b.text = "%s   Lv %d → %d   %s" % [name, lv, lv + shown, _money(cost)]
		else:
			b.text = "%s   Lv %d   max" % [name, lv]
		b.disabled = n == 0


## The warehouse: everything the run has had, by kind, with counts and worth.
func open_drawer() -> void:
	_drawer.visible = true
	_drawer.move_to_front()
	_refresh_drawer()


func _refresh_drawer() -> void:
	var lines := []
	for kind in ["bottle", "mash", "crop"]:
		var rows := []
		for item in game.data.items:
			var seen: bool = game.stock[item] > 0 or game.stats.made[item] > 0 or game.stats.harvested[item] > 0
			if game.data.items[item].kind == kind and seen:
				rows.append("%s   %s   %s" % [game.data.items[item].plural, _count(game.stock[item]), _money(game.stock[item] * game.appraisal(item))])
		if not rows.is_empty():
			lines.append({"head": {"bottle": "Bottles", "mash": "Mash", "crop": "Crops"}[kind], "rows": rows})
	var want := ["Warehouse"]
	for l in lines:
		want.append(l.head)
		want.append_array(l.rows)
	# Rebuilt only when what it lists changes, so a tap doesn't land on a moving row.
	if _drawer_box.get_meta("rows", []) == want:
		return
	_drawer_box.set_meta("rows", want)
	for c in _drawer_box.get_children():
		_drawer_box.remove_child(c)
		c.queue_free()
	_drawer_box.add_child(_label("Warehouse", S.SIZE_BODY, S.TEXT))
	for l in lines:
		_drawer_box.add_child(_label(l.head.to_upper(), S.SIZE_TINY, S.DIM))
		for r in l.rows:
			var row := _label(r, S.SIZE_SMALL, S.TEXT)
			row.name = "Ware_" + str(_drawer_box.get_child_count())
			_drawer_box.add_child(row)


## Counts from now on: nothing made or earned before this pops or flies.
func _rebase_juice() -> void:
	_seen_delivered = -1
	_made_seen = {}
	_pending_pop = {}
	_earned_seen = -1.0


## A bottle lands: a pop over Sell Batch for bottles made, and a coin to Cash
## for money from a sale, each held to its rate.
func _juice(delta: float) -> void:
	_pop_wait = maxf(0.0, _pop_wait - delta)
	_coin_wait = maxf(0.0, _coin_wait - delta)
	for item in game.data.items:
		if game.data.items[item].kind != "bottle":
			continue
		var made: int = game.stats.made[item]
		var before: int = _made_seen.get(item, made)
		if made > before:
			_pending_pop[item] = _pending_pop.get(item, 0) + made - before
		_made_seen[item] = made
	if not _pending_pop.is_empty() and _pop_wait <= 0.0 and _sell_batch.visible:
		_pop(_pending_pop)
		_pending_pop = {}
		_pop_wait = 1.0 / S.POPS_PER_SECOND
	var earned: float = game.stats.cash_earned
	if _earned_seen >= 0.0 and earned > _earned_seen + EPS_MONEY and _coin_wait <= 0.0 and _sell_batch.visible:
		_coin()
		_coin_wait = 1.0 / S.COINS_PER_SECOND
	_earned_seen = earned


const EPS_MONEY := 0.001


func _pop(made: Dictionary) -> void:
	# The most valuable sauce names the pop; the rest add to its value.
	var best := ""
	var total := 0.0
	var count := 0
	for item in made:
		total += made[item] * game.value(item)
		count += made[item]
		if best == "" or game.value(item) > game.value(best):
			best = item
	var text: String = "+%d %s  %s" % [count, game.data.items[best].short, _money(total)] if made.size() == 1 else "+%d bottles  %s" % [count, _money(total)]
	var l := _label(text, S.SIZE_SMALL, S.COIN)
	l.name = "Pop"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	l.size = Vector2(S.SELL_BATCH_WIDTH * 1.6, 28)
	var start := _sell_batch.position + Vector2((_sell_batch.size.x - l.size.x) / 2.0, -l.size.y)
	start.x = clampf(start.x, S.GUTTER, size.x - S.GUTTER - l.size.x)
	l.position = start
	var t := create_tween().set_parallel()
	t.tween_property(l, "position:y", start.y - S.POP_RISE, S.POP_SECONDS).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(l, "modulate:a", 0.0, S.POP_SECONDS).set_ease(Tween.EASE_IN)
	t.chain().tween_callback(l.queue_free)
	pops_shown += 1


func _coin() -> void:
	var c := Panel.new()
	c.name = "Coin"
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_theme_stylebox_override("panel", _box(S.COIN, 999))
	c.size = Vector2.ONE * S.COIN_SIZE
	add_child(c)
	c.position = _sell_batch.position + _sell_batch.size / 2.0
	var to := _cash.global_position + Vector2(_cash.size.x * 0.3, _cash.size.y / 2.0)
	var t := create_tween()
	t.tween_property(c, "position", to, S.COIN_SECONDS).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(c.queue_free)
	coins_flown += 1


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


## A compact button for rows of controls.
func _small_button(text: String, action: Callable) -> Button:
	var b := _control_button(text, action)
	b.add_theme_font_size_override("font_size", S.SIZE_TINY)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var box: StyleBoxFlat = b.get_theme_stylebox(state).duplicate()
		box.set_content_margin_all(6)
		b.add_theme_stylebox_override(state, box)
	return b


func _card_box() -> StyleBoxFlat:
	var box := _box(S.BG, S.RADIUS)
	box.set_content_margin_all(14)
	return box


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


## A node's name without its "Crop Blueprint:" kind or a leading "The".
static func _short_name(name: String) -> String:
	var short := name.split(": ")[-1]
	return short.trim_prefix("The ")


## Counts past 9,999 to three figures: 12.3K, 4.50M (LAYOUT.md).
static func _count(n: int) -> String:
	return str(n) if n < 10000 else _short(float(n))


## Three significant figures and a suffix: 12.3K, 2.93M, 757M, 1.20B.
static func _short(x: float) -> String:
	var k := 0
	var v := x / 1000.0
	while true:
		v = x / pow(1000.0, k + 1)
		var shown := "%.0f" % v if v >= 100.0 else ("%.1f" % v if v >= 10.0 else "%.2f" % v)
		if float(shown) < 1000.0 or k + 1 >= MONEY_SUFFIXES.size():
			return shown + MONEY_SUFFIXES[k]
		k += 1
	return ""


## Dollars (D035): with cents under $10,000 ($1,234.50), then three figures
## and a suffix ($12.3K, $2.93M; LAYOUT.md).
static func _money(amount: float) -> String:
	if absf(amount) >= 10000.0:
		return ("-$" if amount < 0.0 else "$") + _short(absf(amount))
	var cents := roundi(amount * 100.0)
	var whole := str(cents / 100)
	var grouped := ""
	while whole.length() > 3:
		grouped = "," + whole.right(3) + grouped
		whole = whole.left(whole.length() - 3)
	return "$%s%s.%02d" % [whole, grouped, cents % 100]
