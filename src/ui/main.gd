extends Control
## The one screen. Presents the game and reports what the player does; every rule
## lives in src/core/game.gd. Builds its nodes in code so the layout is all in
## one place. Reveals animate when they happen and appear at once when loaded
## from a save.

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const S = preload("res://src/ui/style.gd")

const TAB_NAMES := {"farms": "Farms", "processing": "Processing", "tech": "Tech Tree", "roster": "Shift Roster", "hq": "HQ"}
const STATION_NAMES := {"vat": "Vat", "line": "Line"}
const UPGRADE_NAMES := {"speed": "Harvest Speed", "yield": "Yield per Cycle", "quality": "Crop Quality"}
## Steps for the valve's keep amounts.
const KEEP_STEP := 10

## Where the game saves. Tests clear it so nothing is read or written.
var save_path := "user://save.json"
var game: Game

var _acc := 0.0
var _since_save := 0.0
var _shown := {}
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


## The Tech Tree's connecting lines, drawn under the node buttons.
class WebLines extends Control:
	var edges: Array = []   # [from, to, done]

	func _draw() -> void:
		for e in edges:
			draw_line(e[0], e[1], S.WEB_LINE_DONE if e[2] else S.WEB_LINE, 3.0, true)


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
	_build_deck()
	_build_nav()
	_build_upper()
	_build_status_bar()


## Stage 2: the Operation Deck, the lower 65%, which slides up from below. Its
## pages are the tabs; until Stage 3 only Farms exists.
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
	add_child(_deck)
	var holder := Control.new()
	_deck.add_child(holder)

	_farms_col = _page_column(holder, "farms")
	for crop in game.data.plots:
		_plot_cards[crop] = _plot_card(_farms_col, crop)
	_proc_box = VBoxContainer.new()
	_proc_box.add_theme_constant_override("separation", 12)
	_farms_col.add_child(_proc_box)
	_build_processing(_proc_box)

	_processing_col = _page_column(holder, "processing")
	_build_tech(holder)


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

	for station in ["vat", "line"]:
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 12)
		parent.add_child(list)
		_slot_lists[station] = list
		var b := _control_button("", func() -> void: game.buy_slot(station))
		b.name = "BuySlot_" + station
		parent.add_child(b)
		_buy_slot[station] = b
	# The vats and lines come first; the Van's sliders and the valve after them.
	parent.move_child(_van_card, -1)
	parent.move_child(_valve_card, -1)


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
	_nav.add_theme_stylebox_override("panel", bar)
	_nav.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_nav.offset_top = -S.NAV_HEIGHT
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
	# Tapping a locked tab says what opens it, just above the bar.
	_hint = _label("", S.SIZE_SMALL, S.TEXT)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_hint.offset_top = -S.NAV_HEIGHT - 40
	_hint.offset_bottom = -S.NAV_HEIGHT - 8
	_hint.modulate.a = 0.0
	add_child(_hint)


func _build_upper() -> void:
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
	# Holding the button down: Ergonomic Grip presses it while held.
	_blank.button_down.connect(func() -> void: game.set_holding(true))
	_blank.button_up.connect(func() -> void: game.set_holding(false))
	add_child(_blank)
	_place_blank(false)

	# The Heat Meter (D011): a bar under the button and the bonus beside it.
	_heat_bar = ProgressBar.new()
	_heat_bar.name = "HeatBar"
	_heat_bar.max_value = T.HEAT_MAX
	_heat_bar.show_percentage = false
	_heat_bar.add_theme_stylebox_override("background", _box(S.CONTROL_DISABLED, 3))
	_heat_bar.add_theme_stylebox_override("fill", _box(S.HEAT, 3))
	_heat_bar.anchor_left = 0.5
	_heat_bar.anchor_right = 0.5
	_heat_bar.anchor_top = S.UPPER_FRACTION
	_heat_bar.anchor_bottom = S.UPPER_FRACTION
	_heat_bar.offset_left = -S.BLANK_BUTTON_COMPACT / 2.0
	_heat_bar.offset_right = S.BLANK_BUTTON_COMPACT / 2.0
	_heat_bar.offset_top = -13.0
	_heat_bar.offset_bottom = -6.0
	add_child(_heat_bar)
	_heat_label = _label("", S.SIZE_SMALL, S.HEAT)
	_heat_label.name = "HeatLabel"
	_heat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heat_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_heat_label.anchor_top = S.UPPER_FRACTION
	_heat_label.anchor_bottom = S.UPPER_FRACTION
	_heat_label.offset_left = S.GUTTER
	_heat_label.offset_right = S.GUTTER + S.SELL_BATCH_WIDTH
	_heat_label.offset_bottom = -18.0 - (S.BLANK_BUTTON_COMPACT - S.SELL_BATCH_HEIGHT) / 2.0
	_heat_label.offset_top = _heat_label.offset_bottom - S.SELL_BATCH_HEIGHT
	add_child(_heat_label)

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
	_counter.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_counter.add_theme_font_size_override("font_size", S.SIZE_BODY)
	_counter.add_theme_color_override("font_color", S.TEXT)
	_counter.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_counter.offset_left = S.GUTTER
	_counter.offset_right = -S.GUTTER
	_counter.offset_top = S.STATUS_BAR_HEIGHT + 14
	_counter.offset_bottom = _counter.offset_top + 64
	add_child(_counter)


func _build_status_bar() -> void:
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
	var money := VBoxContainer.new()
	money.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	money.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	money.add_theme_constant_override("separation", 0)
	row.add_child(money)
	_cash = _label("", S.SIZE_BODY, S.GREEN)
	money.add_child(_cash)
	# Stage 3: Operation Value under Cash.
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


## A plot's card: what it grows, a cycle bar, then its buy button or upgrades.
func _plot_card(parent: Container, crop: String) -> Dictionary:
	var nodes := _card(parent, "Card_plot_" + crop, "%s Plot" % game.data.items[crop].name)
	nodes.buy = _control_button("", func() -> void: game.buy_plot(crop))
	nodes.buy.name = "Buy_plot_" + crop
	nodes.col.add_child(nodes.buy)
	for upgrade in UPGRADE_NAMES:
		var b := _control_button("", func() -> void: game.upgrade_plot(crop, upgrade))
		b.name = "Upgrade_plot_%s_%s" % [crop, upgrade]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		nodes.col.add_child(b)
		nodes[upgrade] = b
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
	nodes.speed = _control_button("", func() -> void: game.upgrade_slot(station, index))
	nodes.speed.name = "Upgrade_%s_%d" % [station, index]
	nodes.speed.alignment = HORIZONTAL_ALIGNMENT_LEFT
	nodes.col.add_child(nodes.speed)
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


func _on_tab(tab: String) -> void:
	if game.tab_open(tab):
		_page = tab
		if tab == "tech" and not _web_centred:
			_web_centred = true
			_centre_web.call_deferred()
	else:
		var at: float = T.TAB_THRESHOLDS.get(tab, INF)
		_hint.text = "Opens at %s Operation Value%s" % [_money(at), "" if tab in T.TABS_BUILT else ", in a later version"]
		_hint.modulate.a = 1.0
		create_tween().tween_property(_hint, "modulate:a", 0.0, 0.6).set_delay(1.6)
	_refresh(true)


# --- Showing ---------------------------------------------------------------

## Shows the state. `animate` plays a reveal's entrance the moment it happens.
func _refresh(animate: bool) -> void:
	_counter.text = _stock_text()
	_counter.add_theme_font_size_override("font_size", S.SIZE_TINY if game.nav_shown() else S.SIZE_BODY)
	_cash.text = "Cash: " + _money(game.cash)
	_ov.visible = game.nav_shown()
	_ov.text = "Operation Value " + _money(game.operation_value())
	_spike.visible = game.ticker.sauce != ""
	if _spike.visible:
		var left: float = (game.ticker.ends - game.stats.ticks) * T.TICK_SECONDS
		_spike.text = "%s ×%d · %d min left" % [game.data.items[game.ticker.sauce].short, int(game.ticker.mult), ceili(left / 60.0)]
	var heat_on: bool = game.fx.heat and game.revealed.deck
	_heat_bar.visible = heat_on
	_heat_label.visible = heat_on
	_heat_bar.value = game.heat
	_heat_label.text = "HEAT\n+%d%%" % roundi((game.heat_mult() - 1.0) * 100.0)
	_sell.disabled = not game.can_sell_raw()
	_sell_batch.visible = not game.lines.is_empty()
	_sell_batch.text = "Sell Batch\n%s" % _money(game.bottles_value())
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
	_refresh_processing()
	if _page == "tech":
		_refresh_tech()
	for tab in _tab_buttons:
		var b: Button = _tab_buttons[tab]
		var open := game.tab_open(tab)
		b.text = TAB_NAMES[tab] if open else "[ ? ]"
		b.add_theme_color_override("font_color", S.ORANGE if tab == _page else (S.TEXT if open else S.MUTED))

	_reveal("counter", _counter, game.revealed.counter, animate, func() -> void:
		_counter.modulate.a = 0.0
		create_tween().tween_property(_counter, "modulate:a", 1.0, S.FADE_IN))
	_reveal("status_bar", _status_bar, game.revealed.status_bar, animate, func() -> void:
		_status_bar.position.y = -S.STATUS_BAR_HEIGHT
		create_tween().tween_property(_status_bar, "position:y", 0.0, S.SLIDE_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))
	var compact: bool = game.revealed.deck
	if compact != _shown.get("compact", false):
		_compress_blank(compact and animate)
		_shown.compact = compact
	_reveal("deck", _deck, game.revealed.deck, animate, func() -> void:
		var target := _deck.position.y
		_deck.position.y = size.y
		create_tween().tween_property(_deck, "position:y", target, S.SLIDE_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(S.COMPRESS * 0.4))
	_deck.offset_bottom = -S.NAV_HEIGHT if game.nav_shown() else 0.0
	_reveal("nav", _nav, game.nav_shown(), animate, func() -> void:
		var target := _nav.position.y
		_nav.position.y = size.y
		create_tween().tween_property(_nav, "position:y", target, S.SLIDE_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))


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
	var short := []
	for p in parts:
		short.append("%s %s" % [game.data.items[p[0]].short, _count(p[1])])
	return "  ·  ".join(short)


func _refresh_plot(crop: String) -> void:
	var nodes: Dictionary = _plot_cards[crop]
	var p: Dictionary = game.plots[crop]
	var name: String = game.data.items[crop].name
	var plural: String = game.data.items[crop].plural
	nodes.card.visible = game.plot_offered(crop)
	if p.owned:
		var n := game.plot_yield(crop)
		nodes.info.text = "%d %s every %.1f s" % [n, name if n == 1 else plural, game.plot_cycle(crop)]
	else:
		nodes.info.text = "Harvests %s by itself." % plural
	nodes.bar.visible = p.owned
	nodes.bar.value = clampf(p.progress / game.plot_cycle(crop), 0.0, 1.0)
	nodes.status.visible = false
	nodes.buy.visible = not p.owned
	nodes.buy.text = "Buy   %s" % _money(game.plot_price(crop))
	nodes.buy.disabled = not game.can_buy_plot(crop)
	for upgrade in UPGRADE_NAMES:
		var b: Button = nodes[upgrade]
		b.visible = p.owned
		var cost := game.plot_upgrade_cost(crop, upgrade)
		b.text = "%s   Lv %d   %s" % [UPGRADE_NAMES[upgrade], p[upgrade], _money(cost) if cost < INF else "max"]
		if upgrade == "quality" and p.quality > 0:
			b.text += "   (%d%% double)" % roundi(game.quality_chance(crop) * 100.0)
		b.disabled = not game.can_upgrade_plot(crop, upgrade)


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
	nodes.speed.text = "Speed   Lv %d   %s" % [s.speed, _money(game.slot_upgrade_cost(station, i))]
	nodes.speed.disabled = not game.can_upgrade_slot(station, i)


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
	for item in node.cost:
		costs.append("%d %s (have %d)" % [node.cost[item], game.data.items[item].plural, game.stock[item]])
	if game.is_researched(_selected):
		_detail.cost.text = "Researched."
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
			out.append("The %s Plot can be bought." % game.data.items[e.unlock_plot].name)
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
			out.append("The %s Plot runs %d× faster." % [game.data.items[e.plot_speed.crop].name, int(e.plot_speed.mult)])
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
		elif e.has("market_ticker"):
			out.append("Demand spikes: a sauce sells for ×2 or ×3 for 30 minutes, about once an hour.")
		elif e.has("byproduct_recycling"):
			out.append("Vat cycles can give your lowest-level plot a free level, up to one a minute.")
		elif e.has("stock_value_bonus"):
			out.append("Stock counts %d%% more in Operation Value." % roundi(e.stock_value_bonus * 100.0))
	return " ".join(out)


func _bottle_unlocked(item: String) -> bool:
	for r in game.recipes_for("line"):
		if game.data.recipes[r].output == item:
			return true
	return false


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


func _reveal(key: String, node: Control, on: bool, animate: bool, entrance: Callable) -> void:
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


## Counts past 9,999 in thousands: 12.3k.
static func _count(n: int) -> String:
	return str(n) if n < 10000 else "%.1fk" % (n / 1000.0)


## Pounds with thousands separators: £1,234.50.
static func _money(amount: float) -> String:
	var pence := roundi(amount * 100.0)
	var whole := str(pence / 100)
	var grouped := ""
	while whole.length() > 3:
		grouped = "," + whole.right(3) + grouped
		whole = whole.left(whole.length() - 3)
	return "£%s%s.%02d" % [whole, grouped, pence % 100]
