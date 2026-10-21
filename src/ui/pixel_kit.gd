extends RefCounted
## The Pixel UI kit (addons/pixel_ui, docs/LOOK.md) at a whole-number scale.
## The kit's art is 1x; this builds a copy of its theme with every texture,
## margin and spacing multiplied by Style.PIXEL_SCALE, so its pixels stay square
## on our 540x960 screen. The screen sets `theme()` on its root and takes boxes
## and icons from here.

const S = preload("res://src/ui/style.gd")

const KIT := "res://addons/pixel_ui/"
const THEME := KIT + "themes/wood.tres"
## The characters the kit's font lacks (tools/make_pixel_glyphs.gd).
const EXTRA_FONT := "res://assets/fonts/pixel_extra.fnt"
## The kit's font is drawn at whole multiples of this.
const FONT_PX := 8

static var _theme: Theme
static var _font: FontFile
static var _scaled := {}            # source texture path → its scaled copy


## The kit's theme at PIXEL_SCALE, built once.
static func theme() -> Theme:
	if _theme != null:
		return _theme
	var src: Theme = load(THEME)
	var k := S.PIXEL_SCALE
	var t := Theme.new()
	for type in src.get_type_list():
		var base := src.get_type_variation_base(type)
		if base != &"":
			t.set_type_variation(type, base)
		for n in src.get_color_list(type):
			t.set_color(n, type, src.get_color(n, type))
		for n in src.get_constant_list(type):
			t.set_constant(n, type, src.get_constant(n, type) * k)
		for n in src.get_font_size_list(type):
			t.set_font_size(n, type, src.get_font_size(n, type) * k)
		for n in src.get_font_list(type):
			t.set_font(n, type, font())
		for n in src.get_icon_list(type):
			t.set_icon(n, type, scaled(src.get_icon(n, type)))
		for n in src.get_stylebox_list(type):
			t.set_stylebox(n, type, _scaled_box(src.get_stylebox(n, type)))
	# Darker ink while pressed and on the grey disabled buttons, for contrast (PX5).
	for type in [&"Button", &"OptionButton"]:
		t.set_color(&"font_pressed_color", type, S.INK_PRESSED)
		t.set_color(&"font_hover_pressed_color", type, S.INK_PRESSED)
		t.set_color(&"font_disabled_color", type, S.INK)
	t.default_font = font()
	t.default_font_size = S.SIZE_SMALL
	_theme = t
	return t


## The kit's font, scaled only by whole steps, with the companion glyphs behind it.
static func font() -> FontFile:
	if _font != null:
		return _font
	var src: Theme = load(THEME)
	var f: FontFile = src.default_font.duplicate()
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	var extra: FontFile = (load(EXTRA_FONT) as FontFile).duplicate()
	extra.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	f.fallbacks = [extra]
	_font = f
	return f


## A copy of one of the theme's boxes, to change without touching the theme.
static func box(type: StringName, name: StringName = &"panel") -> StyleBox:
	return theme().get_stylebox(name, type).duplicate()


## A kit icon (icons/<name>.png) at PIXEL_SCALE.
static func icon(name: String) -> Texture2D:
	return scaled(load(KIT + "icons/%s.png" % name))


## `tex` with each pixel drawn PIXEL_SCALE times as wide and high.
static func scaled(tex: Texture2D) -> Texture2D:
	if tex == null:
		return null
	var key := tex.resource_path if tex.resource_path != "" else str(tex.get_instance_id())
	if _scaled.has(key):
		return _scaled[key]
	# get_image() can hand back the texture's own copy; resize a duplicate.
	var img: Image = tex.get_image().duplicate()
	if img.is_compressed():
		img.decompress()
	img.resize(img.get_width() * S.PIXEL_SCALE, img.get_height() * S.PIXEL_SCALE, Image.INTERPOLATE_NEAREST)
	var out := ImageTexture.create_from_image(img)
	_scaled[key] = out
	return out


static func _scaled_box(src: StyleBox) -> StyleBox:
	var k := float(S.PIXEL_SCALE)
	var b: StyleBox = src.duplicate()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		if src.get_content_margin(side) >= 0.0:
			b.set_content_margin(side, src.get_content_margin(side) * k)
	if b is StyleBoxTexture:
		var t := b as StyleBoxTexture
		t.texture = scaled((src as StyleBoxTexture).texture)
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			t.set_texture_margin(side, (src as StyleBoxTexture).get_texture_margin(side) * k)
			t.set_expand_margin(side, (src as StyleBoxTexture).get_expand_margin(side) * k)
		if t.region_rect.has_area():
			t.region_rect = Rect2(t.region_rect.position * k, t.region_rect.size * k)
	elif b is StyleBoxLine:
		var l := b as StyleBoxLine
		l.thickness = int(l.thickness * k)
		l.grow_begin *= k
		l.grow_end *= k
	return b


## The Blank Button as a pixel disc `px` pixels across (brief §2: chilli red, no
## label), to be drawn at a whole multiple of `px`. `fill` is its face; the rim
## is darker below and lighter above, inside a 1 px ink outline.
static func disc(px: int, fill: Color, pressed: bool = false) -> Texture2D:
	var img := Image.create(px, px, false, Image.FORMAT_RGBA8)
	var c := (px - 1) / 2.0
	var r := px / 2.0
	var light := fill.lightened(0.25)
	var dark := fill.darkened(0.3)
	for y in px:
		for x in px:
			var d := Vector2(x - c, y - c)
			var dist := d.length()
			if dist > r - 0.5:
				continue
			var col := fill
			if dist > r - 1.5:
				col = S.INK
			elif dist > r - 4.5:
				# The rim: lit from above-left, unless pressed in.
				var up := d.normalized().dot(Vector2(-0.6, -0.8))
				col = (dark if up > -0.2 else light) if pressed else (light if up > 0.2 else dark)
			img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)
