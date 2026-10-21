class_name NewspaperScreen
extends Control
## The morning paper (round 8): L'Écho de Saint-Clin-Clin, laid out like a small-town broadsheet. The
## masthead, yesterday's headline with a sepia photo and its story, Mme Gagnon's gossip, the gas-price
## box with two little charts (the price per delivery, your cash per day), the weather, the classifieds,
## and on days 10, 20, 30 and 40 a postcard from "un pêcheur". It slides in each morning; a click or
## ENTER opens the gaz bar. Content: Newspaper.edition(). Serves: the story, Comedy, Advancement.

signal done

const PAGE := Rect2(176, 10, 800, 628)
const PAPER := Color(0.93, 0.9, 0.82)
const INK := Color(0.14, 0.12, 0.1)
const RED_INK := Color(0.6, 0.16, 0.12)

var ed := {}
var _t := 0.0


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func show_paper(edition: Dictionary) -> void:
	ed = edition
	_t = 0.0
	visible = true
	queue_redraw()


func _process(dt: float) -> void:
	if visible:
		_t += dt
		queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and _t > 0.4:
		accept_event()
		done.emit()


func _unhandled_input(e: InputEvent) -> void:
	if visible and e is InputEventKey and e.pressed and not e.echo and e.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and _t > 0.4:
		get_viewport().set_input_as_handled()
		done.emit()


func _draw() -> void:
	if ed.is_empty():
		return
	GodUI.dim(self, size, 0.62)
	var k := clampf(_t / 0.35, 0.0, 1.0)
	var ease := 1.0 - pow(1.0 - k, 3.0)
	draw_set_transform(Vector2(0, (1.0 - ease) * 420.0), (1.0 - ease) * 0.05, Vector2.ONE)  # slides in, settles
	_draw_page()
	draw_set_transform(Vector2.ZERO)


func _draw_page() -> void:
	var p := PAGE
	draw_rect(Rect2(p.position + Vector2(8, 10), p.size), Color(0, 0, 0, 0.35))  # its shadow
	draw_rect(p, PAPER)
	draw_rect(p, Color(0.62, 0.58, 0.5), false, 1.0)
	var serif := GodUI.serif()
	var bold := GodUI.serif(true)
	var ital := GodUI.serif(false, true)
	var L := p.position.x + 20.0
	var R := p.end.x - 20.0
	# The masthead.
	GodUI.text_in(self, serif, Vector2(L, p.position.y + 22), "SAINT-CLIN-CLIN-DES-MEUH-MEUH, QUÉBEC  ·  SINCE 1952", 11, Color(INK, 0.75))
	var price := "25¢"
	GodUI.text_in(self, serif, Vector2(R - serif.get_string_size(price, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, p.position.y + 22), price, 12, Color(INK, 0.75))
	GodUI.text_in(self, bold, Vector2(p.get_center().x, p.position.y + 66), "L'ÉCHO DE SAINT-CLIN-CLIN", 42, INK, true)
	draw_line(Vector2(L, p.position.y + 78), Vector2(R, p.position.y + 78), INK, 2.0)
	draw_line(Vector2(L, p.position.y + 82), Vector2(R, p.position.y + 82), INK, 1.0)
	GodUI.text_in(self, bold, Vector2(L, p.position.y + 98), "%s, DAY %d" % [ed.weekday, ed.day], 12, INK)
	GodUI.text_in(self, ital, Vector2(p.get_center().x, p.position.y + 98), "Weather: " + ed.weather, 12, INK, true)
	var vol := "No. %d" % ed.day
	GodUI.text_in(self, serif, Vector2(R - serif.get_string_size(vol, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, p.position.y + 98), vol, 12, INK)
	draw_line(Vector2(L, p.position.y + 105), Vector2(R, p.position.y + 105), Color(INK, 0.6), 1.0)
	# The headline, across the page.
	var y := p.position.y + 142.0
	y += _headline(bold, ed.headline, Vector2(L, y), R - L) - 6.0
	y += GodUI.para_in(self, ital, Vector2(L, y), ed.sub, 16, R - L, Color(INK, 0.85))
	draw_line(Vector2(L, y - 6), Vector2(R, y - 6), Color(INK, 0.35), 1.0)
	var col_top := y + 4.0
	# Left column: the photo, the story, the gossip.
	var left_w := 440.0
	var photo := Rect2(L, col_top, left_w, 128)
	draw_rect(photo, Color(0.8, 0.76, 0.66))
	var tex := GodUI.sepia(ed.photo)
	if tex:
		var sc := minf((photo.size.y - 16) / tex.get_height(), (photo.size.x - 40) / tex.get_width())
		sc = maxf(floorf(sc), 1.0)
		var ts := tex.get_size() * sc
		draw_texture_rect(tex, Rect2(photo.get_center() - ts * 0.5, ts), false)
	draw_rect(photo, Color(INK, 0.5), false, 1.0)
	var yy := photo.end.y + 20.0
	yy += GodUI.para_in(self, serif, Vector2(L, yy), ed.story, 14, left_w, INK, 1.32)
	var gossip_box := Rect2(L, yy + 4, left_w, p.end.y - 92 - yy - 4)
	draw_rect(gossip_box, Color(INK, 0.06))
	draw_rect(gossip_box, Color(INK, 0.4), false, 1.0)
	GodUI.text_in(self, bold, Vector2(L + 10, gossip_box.position.y + 18), "LES POTINS DE MME GAGNON", 13, INK)
	var gy := gossip_box.position.y + 36.0
	for g in ed.gossip:
		gy += GodUI.para_in(self, ital, Vector2(L + 10, gy), "· " + g, 13, left_w - 20, INK, 1.28) + 2.0
	# Right column: the gas prices and the charts.
	var rx := L + left_w + 20.0
	var rw := R - rx
	draw_line(Vector2(rx - 10, col_top), Vector2(rx - 10, p.end.y - 92), Color(INK, 0.35), 1.0)
	GodUI.text_in(self, bold, Vector2(rx, col_top + 14), "GAS PRICES", 14, INK)
	GodUI.text_in(self, bold, Vector2(rx, col_top + 46), "$%.2f / L" % ed.price, 28, RED_INK)
	GodUI.text_in(self, serif, Vector2(rx, col_top + 66), "wholesale, at the truck", 12, Color(INK, 0.7))
	GodChart.line(self, Rect2(rx, col_top + 76, rw, 96), ed.prices, "The price per delivery", "$%.2f", INK, RED_INK, serif)
	GodChart.line(self, Rect2(rx, col_top + 184, rw, 96), ed.cash, "Your cash at closing, day by day", "$%d", INK, INK, serif)
	var gas_line := "Gas in the tank: about %.1f days" % ed.days_of_gas
	GodUI.text_in(self, serif, Vector2(rx, col_top + 300), gas_line, 13, RED_INK if ed.days_of_gas < 1.2 else INK)
	if ed.get("hockey_tonight", false):
		var hb := Rect2(rx, col_top + 312, rw, 30)
		draw_rect(hb, RED_INK)
		GodUI.text_in(self, bold, hb.get_center() + Vector2(0, 5), "TONIGHT: HOCKEY NIGHT", 14, PAPER, true)
	# The classifieds along the bottom.
	var cy := p.end.y - 86.0
	draw_line(Vector2(L, cy), Vector2(R, cy), INK, 1.0)
	GodUI.text_in(self, bold, Vector2(L, cy + 16), "PETITES ANNONCES", 12, INK)
	var aw := (R - L - 16.0) / 2.0
	for i in ed.ads.size():
		GodUI.para_in(self, serif, Vector2(L + i * (aw + 16.0), cy + 34), ed.ads[i], 12, aw, INK, 1.25)
	var hint := "click or press ENTER to open the gaz bar"
	GodUI.text_in(self, ital, Vector2(R - ital.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x, p.end.y - 6), hint, 11, Color(INK, 0.55))
	if not ed.postcard.is_empty():
		_draw_postcard(ed.postcard, Vector2(rx - 30, col_top + 110))


## The headline, wrapped in big bold serif capitals. Returns the height used.
func _headline(f: Font, s: String, at: Vector2, width: float) -> float:
	var size := 32
	while size > 22 and f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > width * 1.9:
		size -= 2
	return GodUI.para_in(self, f, at, s, size, width, INK, 1.12)


## A postcard from "un pêcheur", tilted on the page: the picture, where it's from, a few words.
func _draw_postcard(pc: Dictionary, at: Vector2) -> void:
	draw_set_transform(at, -0.06, Vector2.ONE)
	var card := Rect2(0, 0, 300, 236)
	draw_rect(Rect2(card.position + Vector2(5, 6), card.size), Color(0, 0, 0, 0.3))
	draw_rect(card, Color(0.98, 0.97, 0.93))
	draw_rect(card, Color(0.55, 0.5, 0.42), false, 1.0)
	var pic := GodUI.sprite(pc.picture)
	if pic:
		draw_texture_rect(pic, Rect2(Vector2(12, 12), pic.get_size() * 3.0), false)
	var serif := GodUI.serif(false, true)
	var bold := GodUI.serif(true)
	GodUI.text_in(self, bold, Vector2(14, 160), "Greetings from %s!" % pc.from, 15, RED_INK)
	GodUI.para_in(self, serif, Vector2(14, 180), pc.text, 13, 272, INK, 1.25)
	GodUI.text_in(self, serif, Vector2(196, 228), "- un pêcheur", 13, INK)
	draw_set_transform(Vector2.ZERO)
