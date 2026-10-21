class_name GodUI
extends RefCounted
## The look shared by every GOD PUMP screen: Bills Must Be Paid's dark, warm panels with gold lines
## (designer's reference), big condensed gold titles, cards with a rarity colour. Static helpers so
## each screen stays short.

const GOLD := Color(0.96, 0.73, 0.26)
const GOLD_DIM := Color(0.62, 0.46, 0.18)
const INK := Color(0.08, 0.065, 0.05)
const PANEL := Color(0.11, 0.09, 0.075, 0.96)
const CREAM := Color(0.93, 0.88, 0.78)
const RED := Color(0.95, 0.38, 0.3)
const GREEN := Color(0.45, 0.85, 0.5)
const RARITY := {"common": Color(0.75, 0.72, 0.66), "rare": Color(0.45, 0.7, 1.0), "legendary": Color(1.0, 0.65, 0.2)}
const ICON := "res://assets/art/pixel/out/sprites/icon_%s.png"
## Newsprint (the menu's scrapbook and the run's last front page): paper, ink, red ink.
const PAPER := Color(0.93, 0.9, 0.82)
const PAPER_INK := Color(0.14, 0.12, 0.1)
const RED_INK := Color(0.6, 0.16, 0.12)


## A translated string for code that isn't a node (round 9: French and English, locale/strings.csv).
static func t(s: String) -> String:
	return String(TranslationServer.translate(s))


static func font() -> Font:
	return ThemeDB.fallback_font


static var _serifs := {}


## The newspaper's type (round 8): a serif from the system (Georgia, Times...), the default font
## where there's none (the web build).
static func serif(bold := false, italic := false) -> Font:
	var key := "%s%s" % [bold, italic]
	if not _serifs.has(key):
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Georgia", "Times New Roman", "Liberation Serif", "DejaVu Serif", "serif"])
		f.font_weight = 700 if bold else 400
		f.font_italic = italic
		f.fallbacks = [ThemeDB.fallback_font]
		_serifs[key] = f
	return _serifs[key]


## Text in a given font (the newspaper's serifs), optionally centred.
static func text_in(ci: CanvasItem, f: Font, at: Vector2, s: String, size: int, col: Color, centred := false) -> void:
	var x := at.x - (f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5 if centred else 0.0)
	ci.draw_string(f, Vector2(x, at.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## Word-wrapped text in a font, left-aligned in `width` from `at`. Returns the height used.
static func para_in(ci: CanvasItem, f: Font, at: Vector2, s: String, size: int, width: float, col: Color, lead := 1.3) -> float:
	var y := at.y
	var line := ""
	for w in s.split(" "):
		var tryline := (line + " " + w).strip_edges()
		if f.get_string_size(tryline, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width and line != "":
			ci.draw_string(f, Vector2(at.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
			y += size * lead
			line = w
		else:
			line = tryline
	if line != "":
		ci.draw_string(f, Vector2(at.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
		y += size * lead
	return y - at.y


static var _sepia := {}


## A game sprite as a newspaper photo: sepia, a bit faded (round 8).
static func sepia(name: String) -> Texture2D:
	if _sepia.has(name):
		return _sepia[name]
	var tex: Texture2D = null
	var path := "res://assets/art/pixel/out/sprites/%s.png" % name
	if ResourceLoader.exists(path):
		var img: Image = (load(path) as Texture2D).get_image()
		if img:
			img = img.duplicate()
			img.decompress()
			img.convert(Image.FORMAT_RGBA8)
			for y in img.get_height():
				for x in img.get_width():
					var c := img.get_pixel(x, y)
					var l := clampf(c.r * 0.3 + c.g * 0.59 + c.b * 0.11, 0.0, 1.0) * 0.85 + 0.08
					img.set_pixel(x, y, Color(l * 1.0, l * 0.9, l * 0.74, c.a))
			tex = ImageTexture.create_from_image(img)
	_sepia[name] = tex
	return tex


static func panel_box(border := GOLD_DIM, fill := PANEL, radius := 10) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = fill
	b.border_color = border
	b.set_border_width_all(2)
	b.set_corner_radius_all(radius)
	b.shadow_color = Color(0, 0, 0, 0.55)
	b.shadow_size = 12
	return b


static func text(ci: CanvasItem, at: Vector2, s: String, size: int, col := CREAM, centred := false, outline := 0) -> void:
	var f := font()
	var x := at.x - (f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5 if centred else 0.0)
	if outline > 0:
		ci.draw_string_outline(f, Vector2(x, at.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(0, 0, 0, 0.85))
	ci.draw_string(f, Vector2(x, at.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


## Word-wrapped text inside `width`, centred on `at.x`. Returns the height used.
static func para(ci: CanvasItem, at: Vector2, s: String, size: int, width: float, col := CREAM) -> float:
	var f := font()
	var words := s.split(" ")
	var line := ""
	var y := at.y
	for w in words:
		var tryline := (line + " " + w).strip_edges()
		if f.get_string_size(tryline, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width and line != "":
			text(ci, Vector2(at.x, y), line, size, col, true)
			y += size + 6
			line = w
		else:
			line = tryline
	if line != "":
		text(ci, Vector2(at.x, y), line, size, col, true)
		y += size + 6
	return y - at.y


static var _icons := {}


## An icon by id. Rebuilt as an ImageTexture from the imported image: the tiny imported icons drew as
## white squares in the UI layer, a fresh texture from the same pixels draws fine.
static func icon(id: String) -> Texture2D:
	if _icons.has(id):
		return _icons[id]
	var path := ICON % id
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		var img: Image = (load(path) as Texture2D).get_image()
		if img:
			tex = ImageTexture.create_from_image(img)
	_icons[id] = tex
	return tex


static var _sprites := {}


## A game sprite (assets/art/pixel/out/sprites/<name>.png) for the UI layer, rebuilt the same way as
## the icons above.
static func sprite(name: String) -> Texture2D:
	if _sprites.has(name):
		return _sprites[name]
	var path := "res://assets/art/pixel/out/sprites/%s.png" % name
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		var img: Image = (load(path) as Texture2D).get_image()
		if img:
			tex = ImageTexture.create_from_image(img)
	_sprites[name] = tex
	return tex


## A gold-bordered button in the house style.
static func button(label: String, size := Vector2(220, 46), font_size := 20) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = size
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", font_size)
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := panel_box(GOLD if state != "disabled" else Color(0.3, 0.27, 0.22), Color(0.16, 0.12, 0.08) if state == "normal" else
			(Color(0.26, 0.19, 0.1) if state == "hover" else (Color(0.34, 0.25, 0.12) if state == "pressed" else Color(0.1, 0.09, 0.08))), 8)
		sb.shadow_size = 4
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", GOLD)
	b.add_theme_color_override("font_hover_color", Color(1, 0.88, 0.5))
	b.add_theme_color_override("font_disabled_color", Color(0.4, 0.36, 0.3))
	return b


## A Bills-style card: title band, icon, description; `col` tints the frame (rarity or state).
static func card(ci: CanvasItem, r: Rect2, title: String, body: String, icon_tex: Texture2D, col := GOLD_DIM, hover := false, footer := "") -> void:
	var box := panel_box(col.lightened(0.25) if hover else col, Color(0.09, 0.075, 0.06, 0.97), 12)
	if hover:
		box.shadow_color = Color(col, 0.45)
		box.shadow_size = 18
	ci.draw_style_box(box, r)
	var band := StyleBoxFlat.new()
	band.bg_color = Color(col.darkened(0.55), 0.95)
	band.corner_radius_top_left = 12
	band.corner_radius_top_right = 12
	ci.draw_style_box(band, Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 44)))
	text(ci, Vector2(r.get_center().x, r.position.y + 32), title, 20, GOLD, true)
	if icon_tex:
		var isz := minf(r.size.x * 0.42, 96.0)
		ci.draw_texture_rect(icon_tex, Rect2(Vector2(r.get_center().x - isz * 0.5, r.position.y + 62), Vector2(isz, isz)), false)
	ci.draw_line(Vector2(r.position.x + 30, r.position.y + 176), Vector2(r.end.x - 30, r.position.y + 176), Color(1, 1, 1, 0.15), 2.0)
	para(ci, Vector2(r.get_center().x, r.position.y + 206), body, 16, r.size.x - 34)
	if footer != "":
		text(ci, Vector2(r.get_center().x, r.end.y - 18), footer, 16, col.lightened(0.3), true)


## An enamel sign (round 8, the night screen's look): a glossy coloured plate with a cream rim and
## four rivets, like an old gas-station sign.
static func enamel(ci: CanvasItem, r: Rect2, fill: Color, rim := Color(0.93, 0.89, 0.8)) -> void:
	var outer := StyleBoxFlat.new()
	outer.bg_color = rim
	outer.set_corner_radius_all(12)
	outer.shadow_color = Color(0, 0, 0, 0.5)
	outer.shadow_size = 8
	outer.shadow_offset = Vector2(3, 4)
	ci.draw_style_box(outer, r)
	var inner := StyleBoxFlat.new()
	inner.bg_color = fill
	inner.set_corner_radius_all(9)
	ci.draw_style_box(inner, r.grow(-4))
	ci.draw_rect(Rect2(r.position + Vector2(10, 6), Vector2(r.size.x - 20, 3)), Color(1, 1, 1, 0.12))  # the gloss
	for c in [Vector2(9, 9), Vector2(r.size.x - 9, 9), Vector2(9, r.size.y - 9), Vector2(r.size.x - 9, r.size.y - 9)]:
		ci.draw_circle(r.position + c, 3.0, Color(0.55, 0.53, 0.5))
		ci.draw_circle(r.position + c + Vector2(-0.8, -0.8), 1.2, Color(0.9, 0.9, 0.88))


## Dad's office wall at night (round 8): 80s wood paneling, a desk lamp's warm pool around `glow_at`.
static func wood_wall(ci: CanvasItem, size: Vector2, glow_at: Vector2, t := 0.0) -> void:
	var wood := sprite("wood_panel")
	if wood:
		ci.draw_texture_rect(wood, Rect2(Vector2.ZERO, size), true, Color(0.62, 0.55, 0.5))
	else:
		ci.draw_rect(Rect2(Vector2.ZERO, size), Color(0.22, 0.14, 0.09))
	ci.draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.03, 0.02, 0.35))
	for i in 12:  # the lamp
		var k := i / 11.0
		ci.draw_circle(glow_at, lerpf(560.0, 60.0, k), Color(1.0, 0.72, 0.38, 0.018 + 0.004 * sin(t * 0.7)))
	for i in 8:  # dark corners
		var a := 0.05 * (8 - i) / 8.0
		ci.draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 10 + i * 9)), Color(0, 0, 0, a))
		ci.draw_rect(Rect2(Vector2(0, size.y - 10 - i * 9), Vector2(size.x, 10 + i * 9)), Color(0, 0, 0, a))


static func dim(ci: CanvasItem, size: Vector2, a := 0.72) -> void:
	ci.draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.02, 0.015, a))
