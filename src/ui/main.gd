extends Control
## The one screen. Presents the game and reports taps to it; every rule lives in
## src/core/game.gd. Builds its nodes in code so the layout is all in one place.

const Game = preload("res://src/core/game.gd")
const G = preload("res://src/core/guesses.gd")
const S = preload("res://src/ui/style.gd")

const UPGRADE_INFO := {
	"shears": ["Sharp Shears", "+1 pepper a tap"],
	"picker": ["Field Picker", "+2 peppers a second"],
	"capper": ["Hand Capper", "bottles Table Sauce by itself"],
	"jalapeno": ["Jalapeño Patch", "taps can pick jalapeños; unlocks Smoky Sauce"],
}

## Where the game saves. Tests clear it so nothing is read or written.
var save_path := "user://save.json"
var game: Game

var _acc := 0.0
var _since_save := 0.0

var _tier: Label
var _cash: Label
var _heat_label: Label
var _heat_bar: ProgressBar
var _heat_fill: StyleBoxFlat
var _pick: Button
var _bell: Label
var _sell_bell: Button
var _jalapeno_row: Control
var _jalapeno: Label
var _sell_jalapeno: Button
var _kitchen: Control
var _bottle_table: Button
var _bottle_smoky: Button
var _bottles: Label
var _upgrades: Control
var _upgrade_buttons := {}
var _stats: Label


func _ready() -> void:
	game = Game.new(int(Time.get_unix_time_from_system()))
	_load()
	theme = _make_theme()
	_build()
	_refresh()


func _process(delta: float) -> void:
	_acc += delta
	while _acc >= G.TICK_SECONDS:
		_acc -= G.TICK_SECONDS
		game.tick()
	_since_save += delta
	if _since_save >= G.AUTOSAVE_SECONDS:
		_save()
	_refresh()


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
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, S.GUTTER)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", S.GAP)
	scroll.add_child(col)

	# Header: brand on the left, cash on the right.
	var header := HBoxContainer.new()
	col.add_child(header)
	var brand := VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	brand.add_child(_label("SCOVILLE", S.SIZE_TITLE, S.GOLD))
	_tier = _label("", S.SIZE_SMALL, S.DIM)
	brand.add_child(_tier)
	_cash = _label("", S.SIZE_BIG, S.GREEN)
	_cash.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_cash)

	# Heat.
	var heat_head := HBoxContainer.new()
	col.add_child(heat_head)
	var heat_title := _label("HEAT", S.SIZE_SMALL, S.ORANGE)
	heat_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heat_head.add_child(heat_title)
	_heat_label = _label("", S.SIZE_SMALL, S.ORANGE)
	heat_head.add_child(_heat_label)
	_heat_bar = ProgressBar.new()
	_heat_bar.max_value = G.HEAT_MAX
	_heat_bar.show_percentage = false
	_heat_bar.custom_minimum_size.y = 14
	_heat_bar.add_theme_stylebox_override("background", _box(S.CARD, 7))
	_heat_fill = _box(S.ORANGE, 7)
	_heat_bar.add_theme_stylebox_override("fill", _heat_fill)
	col.add_child(_heat_bar)

	# The field: the big button.
	_pick = _button("", game.tap)
	_pick.name = "Pick"
	_pick.custom_minimum_size.y = 200
	_pick.add_theme_font_size_override("font_size", S.SIZE_BIG)
	col.add_child(_pick)

	# Stock.
	var stock := _card(col)
	var bell_row := HBoxContainer.new()
	stock.add_child(bell_row)
	_bell = _label("", S.SIZE_BODY, S.TEXT)
	_bell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bell_row.add_child(_bell)
	_sell_bell = _button("", game.sell_loose_bell)
	bell_row.add_child(_sell_bell)
	var jal_row := HBoxContainer.new()
	_jalapeno_row = jal_row
	stock.add_child(jal_row)
	_jalapeno = _label("", S.SIZE_BODY, S.TEXT)
	_jalapeno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	jal_row.add_child(_jalapeno)
	_sell_jalapeno = _button("", game.sell_loose_jalapeno)
	jal_row.add_child(_sell_jalapeno)

	# Kitchen.
	var kitchen := _card(col)
	_kitchen = kitchen.get_parent()
	kitchen.add_child(_label("KITCHEN", S.SIZE_SMALL, S.DIM))
	_bottle_table = _button("Bottle Table Sauce   %d bell → %s" % [G.TABLE_SAUCE_PEPPERS, _money(G.TABLE_SAUCE_PRICE)], game.bottle_table)
	kitchen.add_child(_bottle_table)
	_bottle_smoky = _button("Bottle Smoky Sauce   %d jalapeño → %s" % [G.SMOKY_SAUCE_PEPPERS, _money(G.SMOKY_SAUCE_PRICE)], game.bottle_smoky)
	kitchen.add_child(_bottle_smoky)
	_bottles = _label("", S.SIZE_SMALL, S.DIM)
	kitchen.add_child(_bottles)

	# Upgrades.
	var ups := _card(col)
	_upgrades = ups.get_parent()
	ups.add_child(_label("UPGRADES", S.SIZE_SMALL, S.DIM))
	for key in UPGRADE_INFO:
		var b := _button("", game.buy.bind(key))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_upgrade_buttons[key] = b
		ups.add_child(b)

	_stats = _label("", S.SIZE_SMALL, S.MUTED)
	_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_stats)


func _refresh() -> void:
	var boiling := game.is_boiling()
	_tier.text = "Backyard Jalapeño Batch #2" if game.unlocked.jalapeno else "Kitchen Table Batch #1"
	_cash.text = _money(game.cash)

	_heat_bar.value = G.HEAT_MAX if boiling else game.heat
	_heat_fill.bg_color = S.CRIMSON if boiling else S.ORANGE
	if boiling:
		_heat_label.text = "FLASH BOIL  %.0fs" % ceilf(game.boil_ticks * G.TICK_SECONDS)
	else:
		_heat_label.text = "%d%%" % int(game.heat)
	var per_tap := roundi(game.tap_yield() * (G.BOIL_MULT if boiling else 1.0))
	_pick.text = "%s\n+%d bell pepper%s" % ["FLASH BOIL!" if boiling else "PICK PEPPER", per_tap, "" if per_tap == 1 else "s"]
	_pick.add_theme_color_override("font_color", S.CRIMSON if boiling else S.TEXT)

	_bell.text = "Bell peppers   %s" % _count(game.bell)
	_sell_bell.text = "Sell loose  " + _money(game.bell * G.BELL_LOOSE_PRICE)
	_sell_bell.disabled = game.bell <= 0.0
	_jalapeno_row.visible = game.unlocked.jalapeno
	_jalapeno.text = "Jalapeños   %s" % _count(game.jalapeno)
	_sell_jalapeno.text = "Sell loose  " + _money(game.jalapeno * G.JALAPENO_LOOSE_PRICE)
	_sell_jalapeno.disabled = game.jalapeno <= 0

	_kitchen.visible = game.unlocked.bottling
	_bottle_table.disabled = not game.can_bottle_table()
	_bottle_smoky.visible = game.unlocked.jalapeno
	_bottle_smoky.disabled = not game.can_bottle_smoky()
	_bottles.text = "Bottles sold: %s" % _count(game.stats.bottles)

	_upgrades.visible = game.unlocked.upgrades
	for key in _upgrade_buttons:
		var b: Button = _upgrade_buttons[key]
		var info: Array = UPGRADE_INFO[key]
		if key == "jalapeno":
			b.visible = not game.unlocked.jalapeno
			b.text = "%s   %s\n%s" % [info[0], _money(game.cost(key)), info[1]]
		else:
			b.text = "%s  Lv %d   %s\n%s" % [info[0], game.levels[key], _money(game.cost(key)), info[1]]
		b.disabled = not game.can_buy(key)

	_stats.text = "Picked %s  ·  Bottled %s  ·  Earned %s  ·  Boils %s" % [
		_count(game.stats.peppers), _count(game.stats.bottles), _money(game.stats.revenue), _count(game.stats.boils)]


# --- Pieces ----------------------------------------------------------------

func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


## Every action returns whether it did anything; the screen just redraws.
func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func() -> void:
		action.call()
		_refresh())
	return b


## A card: a panel with a column inside. Returns the column; its parent is the panel.
func _card(parent: Container) -> VBoxContainer:
	var panel := PanelContainer.new()
	var box := _box(S.CARD, S.RADIUS)
	box.set_content_margin_all(S.GAP)
	panel.add_theme_stylebox_override("panel", box)
	parent.add_child(panel)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	panel.add_child(inner)
	return inner


func _box(color: Color, radius: int) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = color
	b.set_corner_radius_all(radius)
	return b


func _make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = S.SIZE_BODY
	t.set_color("font_color", "Label", S.TEXT)
	var states := {"normal": Color("#232a3a"), "hover": Color("#2b3346"), "pressed": Color("#343e55"), "disabled": Color("#181c26")}
	for state in states:
		var b := _box(states[state], S.RADIUS - 4)
		b.set_content_margin_all(12)
		b.border_color = S.LINE
		b.set_border_width_all(1)
		t.set_stylebox(state, "Button", b)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", S.TEXT)
	t.set_color("font_hover_color", "Button", S.TEXT)
	t.set_color("font_pressed_color", "Button", S.TEXT)
	t.set_color("font_disabled_color", "Button", S.MUTED)
	return t


static func _money(amount: float) -> String:
	for step in [[1e9, "B"], [1e6, "M"], [1e3, "k"]]:
		if amount >= step[0]:
			return "$%.2f%s" % [amount / step[0], step[1]]
	return "$%.2f" % amount


static func _count(n: float) -> String:
	for step in [[1e9, "B"], [1e6, "M"], [1e3, "k"]]:
		if n >= step[0]:
			return "%.1f%s" % [n / step[0], step[1]]
	return str(int(floorf(n)))
