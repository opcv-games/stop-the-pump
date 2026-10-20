class_name StationShopView
extends Control
## The night shop's "Your station" tab (#33): the 3D station itself, with a card pinned to each pump
## (its own upgrades as a little chain of icon nodes) and a ghost card on the next free lane to build
## the next pump, or on the vacant lot to expand it. Pumps are bought where they stand, so the
## upgrade tree stays about the station as a whole. Same node language as UpgradeTreeView: owned =
## tinted + gold, next = glowing with a price tag, later = dim. Serves: Advancement.

const GOLD := UpgradeTreeView.GOLD
const CARD := Vector2(244, 50)  # the day HUD's lane card size: the staircase keeps them apart
const NODE := 34.0
const NODE_GAP := 42.0
const PUMP_FILL := Color(0.22, 0.28, 0.48)
const EXPAND_LANE := 3  # the expansion card stands on the vacant lot, where lane 4 will go

var station: Node
var hover_key := ""
var _rects := {}  # key -> Rect2 (hit areas, in this control's coordinates)
var _icons := {}
var _t := 0.0
var _pops := {}


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS


func setup(owner_station: Node) -> void:
	station = owner_station
	for id in ["pump", "expand", "self_service", "faster_self_serve", "card_deal"]:
		_icons[id] = load("res://assets/art/icons/%s.png" % id)


## Everything clickable, in drawing order: each pump's upgrades, then the build card.
func keys() -> Array[String]:
	var out: Array[String] = []
	for i in station.bays.size():
		for l in Upgrades.PUMP_TREE.size():
			out.append("pump:%d:%d" % [i, l])
	if not _build_node().is_empty():
		out.append("build")
	return out


func card_position(i: int) -> Vector2:
	return station.anchor_position(i) + Vector2(0, (PumpBay.SIZE.y - CARD.y) * 0.5)


func press(key: String) -> bool:
	var ok := false
	if key == "build":
		ok = station.buy(_pumps_branch())
	elif key.begins_with("pump:"):
		var parts := key.split(":")
		var i := int(parts[1])
		var l := int(parts[2])
		if i < station.bays.size() and l == station.bays[i].pump_level:
			ok = station.buy_pump(i)
	if ok:
		_pops[key] = 0.0
	queue_redraw()
	return ok


func tooltip_for(key: String) -> String:
	if key == "build":
		var node := _build_node()
		if node.is_empty():
			return ""
		var price: float = Upgrades.next_price(station, _pumps_branch())
		return "%s\n%s\n%s" % [node.name, node.helps, _price_line(price, true)]
	var parts := key.split(":")
	var i := int(parts[1])
	var l := int(parts[2])
	var node: Dictionary = Upgrades.PUMP_TREE[l]
	var level: int = station.bays[i].pump_level
	var status := "OWNED"
	var price := roundf(node.price * station.shop_price_scale)
	if l == level:
		status = _price_line(price, true)
	elif l > level:
		status = "$%.0f   buy the one before it first" % price
	return "Pump %d: %s\n%s\n%s" % [i + 1, node.name, node.helps, status]


func _price_line(price: float, open: bool) -> String:
	if not open:
		return "$%.0f" % price
	return "$%.0f%s" % [price, "   (not enough cash)" if station.spendable_cash() < price else "   click to buy"]


func _pumps_branch() -> int:
	for i in Upgrades.BRANCHES.size():
		if Upgrades.BRANCHES[i].id == "pumps":
			return i
	return -1


## The next PUMPS node (a pump or the lot expansion), or {} when every pump is built.
func _build_node() -> Dictionary:
	return Upgrades.next_node(station, _pumps_branch())


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var k := _key_at(event.position)
		if k != hover_key:
			hover_key = k
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if k != "" else Control.CURSOR_ARROW
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var k := _key_at(event.position)
		if k != "":
			press(k)
			accept_event()


func _key_at(p: Vector2) -> String:
	for k in _rects:
		if (_rects[k] as Rect2).grow(4).has_point(p):
			return k
	return ""


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	for k in _pops.keys():
		_pops[k] += delta
		if _pops[k] > 0.9:
			_pops.erase(k)
	queue_redraw()


# --- Drawing ------------------------------------------------------------------------------------

func _draw() -> void:
	if not station:
		return
	_rects.clear()
	# A soft dusk veil so the cards read over the 3D station, darker at the top under the title.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.04, 0.03, 0.28))
	for i in 6:
		draw_rect(Rect2(0, i * 14, size.x, 14), Color(0.05, 0.04, 0.03, 0.55 - i * 0.09))
	for i in station.bays.size():
		_draw_pump_card(i)
	var build := _build_node()
	if not build.is_empty():
		_draw_build_card(build)
	if hover_key != "" and _rects.has(hover_key):
		_draw_tooltip(hover_key)


func _card_box(border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.09, 0.075, 0.06, 0.94)
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	box.shadow_color = Color(0, 0, 0, 0.55)
	box.shadow_size = 8
	return box


func _draw_pump_card(i: int) -> void:
	var bay: PumpBay = station.bays[i]
	var at := card_position(i)
	draw_style_box(_card_box(GOLD.darkened(0.5)), Rect2(at, CARD))
	_text(at + Vector2(40, 22), "PUMP %d" % (i + 1), 14, Color.WHITE, false)
	var mode := "you pour it"
	if bay.pump_level >= 1:
		mode = "self-serve" if bay.self_service else "self-serve, off"
	_text(at + Vector2(40, 39), mode, 11, Color(0.8, 0.77, 0.7), false)
	var first := at + Vector2(140, CARD.y * 0.5)
	for l in Upgrades.PUMP_TREE.size():
		var c := first + Vector2(l * NODE_GAP, 0)
		if l > 0:
			var prev := first + Vector2((l - 1) * NODE_GAP, 0)
			var owned := l < bay.pump_level
			draw_line(prev + Vector2(NODE * 0.5, 0), c - Vector2(NODE * 0.5, 0),
				GOLD if owned else (GOLD.darkened(0.35) if l == bay.pump_level else UpgradeTreeView.LOCKED_EDGE), 3.0 if owned else 2.0)
		var state := UpgradeGraph.OWNED if l < bay.pump_level else (UpgradeGraph.AVAILABLE if l == bay.pump_level else UpgradeGraph.LOCKED)
		var node: Dictionary = Upgrades.PUMP_TREE[l]
		var key := "pump:%d:%d" % [i, l]
		_draw_node(key, c, state, _icons.get(node.id), roundf(node.price * station.shop_price_scale), PUMP_FILL)
	# The pump number badge on the card's left edge.
	draw_circle(at + Vector2(20, CARD.y * 0.5), 12, Color(0.50, 0.14, 0.11))
	draw_arc(at + Vector2(20, CARD.y * 0.5), 12, 0, TAU, 28, GOLD, 1.5, true)
	_text(at + Vector2(20, CARD.y * 0.5 + 5), str(i + 1), 14, Color.WHITE)


func _draw_build_card(node: Dictionary) -> void:
	var expanding: bool = node.id == "expand"
	var lane: int = EXPAND_LANE if expanding else station.bays.size()
	var at := card_position(lane)
	var price: float = Upgrades.next_price(station, _pumps_branch())
	var can: bool = station.spendable_cash() >= price
	var pulse := 0.5 + 0.5 * sin(_t * 3.2)
	var box := _card_box(GOLD if can else GOLD.darkened(0.55))
	box.bg_color = Color(0.09, 0.075, 0.06, 0.78)
	if can:
		box.shadow_color = Color(GOLD, 0.2 + 0.3 * pulse)
		box.shadow_size = int(8 + 8 * pulse)
	var scale := 1.0
	if _pops.has("build"):
		var k: float = _pops["build"] / 0.55
		scale = 1.0 + 0.2 * exp(-4.0 * k) * sin(k * PI * 3.0) if k < 1.0 else 1.0
	var r := Rect2(at, CARD)
	r = Rect2(r.get_center() - r.size * scale * 0.5, r.size * scale)
	draw_style_box(box, r)
	var icon: Texture2D = _icons["expand" if expanding else "pump"]
	draw_texture_rect(icon, Rect2(at + Vector2(6, 3), Vector2(44, 44)), false, Color.WHITE if can else Color(0.7, 0.7, 0.7))
	var title := "EXPAND THE LOT" if expanding else "+ BUILD PUMP %s" % node.name.trim_prefix("Pump ")
	_text(at + Vector2(56, 22), title, 15, GOLD if can else Color(0.8, 0.7, 0.55), false)
	_text(at + Vector2(56, 40), "$%.0f   %s" % [price, "room for pumps 4 and 5" if expanding else "a new lane"], 12,
		Color(0.85, 0.82, 0.76) if can else Color(0.95, 0.42, 0.35), false)
	_rects["build"] = Rect2(at, CARD)


func _draw_node(key: String, c: Vector2, state: int, icon: Texture2D, price: float, fill: Color) -> void:
	var scale := 1.0
	if _pops.has(key):
		var k: float = _pops[key] / 0.55
		scale = 1.0 + 0.35 * exp(-4.0 * k) * sin(k * PI * 3.0) if k < 1.0 else 1.0
	if key == hover_key:
		scale *= 1.08
	var half := NODE * 0.5 * scale
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(6)
	var tint := Color.WHITE
	match state:
		UpgradeGraph.OWNED:
			box.bg_color = fill
			box.border_color = GOLD
			box.set_border_width_all(2)
		UpgradeGraph.AVAILABLE:
			var can: bool = station.spendable_cash() >= price
			var pulse := 0.5 + 0.5 * sin(_t * 3.2)
			box.bg_color = UpgradeTreeView.OPEN_FILL
			box.border_color = GOLD if can else GOLD.darkened(0.55)
			box.set_border_width_all(2)
			if can:
				box.shadow_color = Color(GOLD, 0.25 + 0.35 * pulse)
				box.shadow_size = int(6 + 6 * pulse)
			tint = Color.WHITE if can else Color(0.7, 0.7, 0.7)
		_:
			box.bg_color = UpgradeTreeView.LOCKED_FILL
			box.border_color = UpgradeTreeView.LOCKED_EDGE
			box.set_border_width_all(1)
			tint = Color(0.32, 0.30, 0.28)
	var r := Rect2(c - Vector2(half, half), Vector2(half, half) * 2.0)
	draw_style_box(box, r)
	if icon:
		draw_texture_rect(icon, r.grow(-2), false, tint)
	if state == UpgradeGraph.AVAILABLE:
		var can2: bool = station.spendable_cash() >= price
		var label := "$%.0f" % price
		var w := get_theme_default_font().get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 10
		var tag := StyleBoxFlat.new()
		tag.bg_color = Color(0.07, 0.06, 0.05, 0.95)
		tag.border_color = GOLD if can2 else Color(0.6, 0.25, 0.2)
		tag.set_border_width_all(1)
		tag.set_corner_radius_all(7)
		var at := c + Vector2(0, half - 3)  # on the node's bottom edge, inside the card
		draw_style_box(tag, Rect2(at - Vector2(w * 0.5, 7), Vector2(w, 14)))
		_text(at + Vector2(0, 4), label, 11, GOLD if can2 else Color(0.95, 0.42, 0.35))
	_rects[key] = Rect2(c - Vector2(NODE, NODE) * 0.5, Vector2(NODE, NODE))


func _draw_tooltip(key: String) -> void:
	var lines := tooltip_for(key).split("\n")
	var font := get_theme_default_font()
	var w := 0.0
	for i in lines.size():
		w = maxf(w, font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18 if i == 0 else 15).x)
	var box_size := Vector2(w + 28, 22 + lines.size() * 22)
	var anchor: Rect2 = _rects[key]
	var p := Vector2(anchor.position.x, anchor.position.y - box_size.y - 10)
	p.x = clampf(p.x, 8, size.x - box_size.x - 8)
	if p.y < 70:
		p.y = anchor.end.y + 22
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.11, 0.09, 0.075, 0.97)
	box.border_color = GOLD.darkened(0.2)
	box.set_border_width_all(1)
	box.set_corner_radius_all(6)
	box.shadow_color = Color(0, 0, 0, 0.6)
	box.shadow_size = 10
	draw_style_box(box, Rect2(p, box_size))
	for i in lines.size():
		var col := Color.WHITE if i == 0 else (Color(0.85, 0.82, 0.76) if i == 1 else GOLD)
		draw_string(font, p + Vector2(14, 30 + i * 22), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18 if i == 0 else 15, col)


func _text(at: Vector2, s: String, font_size: int, col: Color, centred := true) -> void:
	var font := get_theme_default_font()
	var x := at.x - (font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x * 0.5 if centred else 0.0)
	draw_string(font, Vector2(x, at.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
