extends SceneTree
## Writes assets/fonts/pixel_extra.png and .fnt: the characters the game shows
## that the Pixel UI font lacks, drawn to match it (5x7 on an 8 px cell, base 7;
## docs/LOOK.md). Run once after changing GLYPHS, then commit the output:
##   bash run_godot.sh --headless --path . -s res://tools/make_pixel_glyphs.gd

const OUT := "res://assets/fonts/pixel_extra"
## Each glyph: its rows from `top` (0 is the cap line, -1 one above), and how far
## the pen moves after it. "#" is ink.
const GLYPHS := {
	"ñ": {"top": -1, "advance": 6, "rows": [".##.#", "#..#.", ".....", "####.", "#...#", "#...#", "#...#", "#...#"]},
	"×": {"top": 3, "advance": 4, "rows": ["#.#", ".#.", "#.#"]},
	"·": {"top": 4, "advance": 3, "rows": [".#"]},
	"→": {"top": 2, "advance": 6, "rows": ["..#..", "...#.", "#####", "...#.", "..#.."]},
	"−": {"top": 3, "advance": 6, "rows": ["#####"]},
	"é": {"top": 0, "advance": 6, "rows": ["...#.", "..#..", ".###.", "#...#", "#####", "#....", ".###."]},
	"Á": {"top": -2, "advance": 6, "rows": ["...#.", "..#..", ".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"]},
}


func _init() -> void:
	var img := Image.create(64, 16, false, Image.FORMAT_RGBA8)
	var fnt := PackedStringArray([
		'info face="Pixel UI Extra" size=8 bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1 outline=0',
		"common lineHeight=10 base=7 scaleW=64 scaleH=16 pages=1 packed=0",
		'page id=0 file="pixel_extra.png"',
		"chars count=%d" % GLYPHS.size(),
	])
	var x := 0
	for ch in GLYPHS:
		var g: Dictionary = GLYPHS[ch]
		var rows: Array = g.rows
		var w: int = rows[0].length()
		for r in rows.size():
			for c in w:
				if rows[r][c] == "#":
					img.set_pixel(x + c, r, Color.WHITE)
		fnt.append("char id=%d x=%d y=0 width=%d height=%d xoffset=0 yoffset=%d xadvance=%d page=0 chnl=15" % [ch.unicode_at(0), x, w, rows.size(), g.top, g.advance])
		x += w + 1
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	img.save_png(OUT + ".png")
	var f := FileAccess.open(OUT + ".fnt", FileAccess.WRITE)
	f.store_string("\n".join(fnt) + "\n")
	f.close()
	print("PASS: wrote ", OUT, ".png and .fnt")
	quit()
