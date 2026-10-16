extends Control
## The one screen. Presents the game and reports presses to it; every rule lives
## in src/core/game.gd. Builds its nodes in code so the layout is all in one place.
## Reveals animate when they happen and appear at once when loaded from a save.

const Game = preload("res://src/core/game.gd")
const T = preload("res://src/core/tuning.gd")
const S = preload("res://src/ui/style.gd")

## Where the game saves. Tests clear it so nothing is read or written.
var save_path := "user://save.json"
var game: Game

var _since_save := 0.0
var _shown := {}

var _blank: Button
var _counter: Label
var _status_bar: PanelContainer
var _cash: Label
var _sell: Button


func _ready() -> void:
	game = Game.new()
	_load()
	_build()
	_refresh(false)


func _process(delta: float) -> void:
	_since_save += delta
	if _since_save >= T.AUTOSAVE_SECONDS:
		_save()


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

	# Stage 0: the Blank Button, centred, with no label at all.
	_blank = Button.new()
	_blank.name = "BlankButton"
	_blank.focus_mode = Control.FOCUS_NONE
	_blank.custom_minimum_size = Vector2.ONE * S.BLANK_BUTTON_SIZE
	var half := S.BLANK_BUTTON_SIZE / 2.0
	_blank.set_anchors_preset(Control.PRESET_CENTER)
	_blank.offset_left = -half
	_blank.offset_right = half
	_blank.offset_top = -half
	_blank.offset_bottom = half
	_blank.pivot_offset = Vector2.ONE * half
	var round := int(half)
	var looks := {"normal": S.BUTTON, "hover": S.BUTTON_HOVER, "pressed": S.BUTTON_PRESSED}
	for state in looks:
		var box := _box(looks[state], round)
		box.border_color = S.BUTTON_EDGE
		box.set_border_width_all(4)
		box.shadow_color = Color(0, 0, 0, 0.45)
		box.shadow_size = 18
		_blank.add_theme_stylebox_override(state, box)
	_blank.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_blank.pressed.connect(_on_blank_pressed)
	add_child(_blank)

	# Stage 0, after the first press: the counter at the top.
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
	_cash = Label.new()
	_cash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cash.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_cash.add_theme_font_size_override("font_size", S.SIZE_BODY)
	_cash.add_theme_color_override("font_color", S.GREEN)
	row.add_child(_cash)
	_sell = Button.new()
	_sell.name = "SellRaw"
	_sell.text = "Sell Raw Peppers (%s/ea)" % _money(T.BELL_RAW_PRICE)
	_sell.focus_mode = Control.FOCUS_NONE
	_sell.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_control(_sell)
	_sell.pressed.connect(func() -> void:
		game.sell_raw()
		_refresh(true))
	row.add_child(_sell)


func _on_blank_pressed() -> void:
	game.press()
	var squash := create_tween()
	squash.tween_property(_blank, "scale", Vector2.ONE * 0.92, S.PRESS_SQUASH * 0.4)
	squash.tween_property(_blank, "scale", Vector2.ONE, S.PRESS_SQUASH * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_refresh(true)


## Shows the state. `animate` plays a reveal's entrance the moment it happens.
func _refresh(animate: bool) -> void:
	_counter.text = "Bell Peppers: %d" % game.bell
	_cash.text = "Cash: " + _money(game.cash)
	_sell.disabled = not game.can_sell_raw()
	_reveal("counter", _counter, animate, func() -> void:
		_counter.modulate.a = 0.0
		create_tween().tween_property(_counter, "modulate:a", 1.0, S.FADE_IN))
	_reveal("status_bar", _status_bar, animate, func() -> void:
		_status_bar.position.y = -S.STATUS_BAR_HEIGHT
		create_tween().tween_property(_status_bar, "position:y", 0.0, S.SLIDE_IN).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT))


func _reveal(key: String, node: Control, animate: bool, entrance: Callable) -> void:
	var on: bool = game.revealed[key]
	node.visible = on
	if on and not _shown.get(key, false) and animate:
		entrance.call()
	_shown[key] = on


# --- Pieces ----------------------------------------------------------------

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


static func _money(amount: float) -> String:
	return "£%.2f" % amount
