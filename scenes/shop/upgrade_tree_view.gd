class_name UpgradeTreeView
extends Control
## Draws the night shop's upgrade tree (#31), after Bills Must Be Paid: dark warm backdrop, square
## icon nodes on a 45° lattice, diamonds for the big moments, gold links along what you own.
## Owned nodes are tinted with their branch colour, nodes you can buy next glow and pulse, the rest
## sit dim. Hover for name, effect and price; click to buy (a pop and a gold ring answer it).
## The model is UpgradeGraph; this node only draws it and forwards clicks. Serves: Advancement.

const GOLD := Color(0.96, 0.73, 0.26)
const BG_EDGE := Color(0.07, 0.055, 0.045)
const BG_CENTRE := Color(0.19, 0.14, 0.10)
const LOCKED_FILL := Color(0.09, 0.08, 0.075)
const LOCKED_EDGE := Color(0.20, 0.18, 0.16)
const OPEN_FILL := Color(0.13, 0.11, 0.095)
const BRANCH_FILL := {
	"marketing": Color(0.42, 0.22, 0.38), "tank": Color(0.18, 0.34, 0.38), "service": Color(0.20, 0.36, 0.22),
	"vibe": Color(0.47, 0.33, 0.13), "pumps": Color(0.50, 0.14, 0.11), "hours": Color(0.20, 0.24, 0.42),
}
const PUMP_TREE_FILL := Color(0.22, 0.28, 0.48)
const ROOT_FILL := Color(0.36, 0.29, 0.20)
## Where captions go, in cells past each branch's last node.
const CAPTIONS := {
	"marketing": [Vector2(-3.75, -3.75), "MARKETING"], "vibe": [Vector2(2.75, -2.75), "VIBE"],
	"tank": [Vector2(-4.4, 3.1), "TANK"], "service": [Vector2(4.5, 3.1), "SERVICE"],
	"hours": [Vector2(1.05, -4.0), "HOURS"],
}
const NODE := 48.0
const KEYSTONE := 50.0
const POP_SECONDS := 0.55

## The rectangle the tree is fitted into (set by the station's layout).
var area := Rect2(240, 70, 900, 520)
var station: Node
var nodes: Array[Dictionary] = []
var hover_key := ""
var _by_key := {}
var _icons := {}
var _t := 0.0
var _pops := {}  # key -> seconds since bought
var _unit := 68.0
var _origin := Vector2.ZERO


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS


func setup(owner_station: Node) -> void:
	station = owner_station
	refresh()


## Rebuilds the node states from the station (after a purchase, a new night, a new run).
func refresh() -> void:
	if not station:
		return
	nodes = UpgradeGraph.build(station)
	_by_key.clear()
	for n in nodes:
		_by_key[n.key] = n
		if not _icons.has(n.icon):
			var path := "res://assets/art/icons/%s.png" % n.icon
			_icons[n.icon] = load(path) if ResourceLoader.exists(path) else null
	_layout()
	queue_redraw()


## Clicking a node: buys it when it is next in line and affordable. True when bought.
func press(key: String) -> bool:
	if not _by_key.has(key):
		return false
	var ok := UpgradeGraph.buy(station, _by_key[key])
	if ok:
		_pops[key] = 0.0
	refresh()
	return ok


func tooltip_for(key: String) -> String:
	var n: Dictionary = _by_key.get(key, {})
	if n.is_empty():
		return ""
	var lines: Array[String] = [n.name, n.helps]
	match n.state:
		UpgradeGraph.OWNED:
			lines.append("OWNED")
		UpgradeGraph.AVAILABLE:
			var short: bool = station.spendable_cash() < n.price
			lines.append("$%.0f%s" % [n.price, "   (not enough cash)" if short else "   click to buy"])
		UpgradeGraph.LOCKED:
			lines.append("$%.0f   buy the one before it first" % n.price)
	return "\n".join(lines)


func cell_position(cell: Vector2) -> Vector2:
	return _origin + cell * _unit


func _layout() -> void:
	var lo := Vector2i(0, 0)
	var hi := Vector2i(0, 0)
	for n in nodes:
		lo = Vector2i(mini(lo.x, n.cell.x), mini(lo.y, n.cell.y))
		hi = Vector2i(maxi(hi.x, n.cell.x), maxi(hi.y, n.cell.y))
	var span := Vector2(hi - lo) + Vector2(1.6, 1.6)
	_unit = minf(area.size.x / span.x, area.size.y / span.y)
	_origin = area.get_center() - Vector2(lo + hi) * 0.5 * _unit


func _node_at(p: Vector2) -> String:
	for n in nodes:
		if cell_position(n.cell).distance_to(p) <= NODE * 0.62:
			return n.key
	return ""


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var k := _node_at(event.position)
		if k != hover_key:
			hover_key = k
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if k != "" else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var k := _node_at(event.position)
		if k != "":
			press(k)
			accept_event()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	for k in _pops.keys():
		_pops[k] += delta
		if _pops[k] > POP_SECONDS * 1.6:
			_pops.erase(k)
	queue_redraw()


# --- Drawing ------------------------------------------------------------------------------------

func _draw() -> void:
	_draw_backdrop()
	for n in nodes:
		if n.parent != "":
			_draw_link(_by_key[n.parent], n)
	for n in nodes:
		_draw_node(n)
	_draw_captions()
	if hover_key != "":
		_draw_tooltip(_by_key[hover_key])


## Dark warm room with a lamp-lit centre: concentric rings blended from edge to centre colour.
func _draw_backdrop() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_EDGE)
	var centre := cell_position(Vector2.ZERO)
	var steps := 18
	for i in steps:
		var k := float(i) / steps
		draw_circle(centre, lerpf(size.x * 0.62, 30.0, k), BG_EDGE.lerp(BG_CENTRE, pow(k, 1.6)))


func _draw_link(a: Dictionary, b: Dictionary) -> void:
	var pa := cell_position(a.cell)
	var pb := cell_position(b.cell)
	match b.state:
		UpgradeGraph.OWNED:
			draw_line(pa, pb, GOLD.darkened(0.45), 7.0, true)
			draw_line(pa, pb, GOLD, 3.5, true)
		UpgradeGraph.AVAILABLE:
			draw_line(pa, pb, GOLD.darkened(0.35), 3.0, true)
		_:
			draw_line(pa, pb, LOCKED_EDGE, 2.0, true)


func _fill_for(n: Dictionary) -> Color:
	if n.kind == "root":
		return ROOT_FILL
	return BRANCH_FILL.get(Upgrades.BRANCHES[n.branch].id, ROOT_FILL)


func _draw_node(n: Dictionary) -> void:
	var p := cell_position(n.cell)
	var s: float = KEYSTONE if n.keystone else NODE
	var scale := 1.0
	var ring := -1.0
	if _pops.has(n.key):
		var k: float = _pops[n.key] / POP_SECONDS
		scale = 1.0 + 0.35 * exp(-4.0 * k) * sin(k * PI * 3.0) if k < 1.0 else 1.0
		ring = _pops[n.key] / (POP_SECONDS * 1.6)
	if n.key == hover_key:
		scale *= 1.08
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(7)
	box.anti_aliasing = true
	var icon_tint := Color.WHITE
	match n.state:
		UpgradeGraph.OWNED:
			box.bg_color = _fill_for(n)
			box.border_color = GOLD
			box.set_border_width_all(2)
			box.shadow_color = Color(0, 0, 0, 0.5)
			box.shadow_size = 6
		UpgradeGraph.AVAILABLE:
			var can: bool = station.spendable_cash() >= n.price
			var pulse := 0.5 + 0.5 * sin(_t * 3.2)
			box.bg_color = OPEN_FILL
			box.border_color = GOLD if can else GOLD.darkened(0.55)
			box.set_border_width_all(2)
			box.shadow_color = Color(GOLD, 0.25 + 0.35 * pulse) if can else Color(0, 0, 0, 0.5)
			box.shadow_size = int(8 + 8 * pulse) if can else 4
			icon_tint = Color.WHITE if can else Color(0.7, 0.7, 0.7)
		_:
			box.bg_color = LOCKED_FILL
			box.border_color = LOCKED_EDGE
			box.set_border_width_all(1)
			icon_tint = Color(0.32, 0.30, 0.28)
	var half := s * 0.5 * scale
	if n.keystone:
		draw_set_transform(p, PI / 4.0, Vector2.ONE)
		box.set_corner_radius_all(6)
		draw_style_box(box, Rect2(Vector2(-half, -half) * 0.86, Vector2(half, half) * 2.0 * 0.86))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_style_box(box, Rect2(p - Vector2(half, half), Vector2(half, half) * 2.0))
	var icon: Texture2D = _icons.get(n.icon)
	if icon:
		var isz := s * 0.86 * scale
		draw_texture_rect(icon, Rect2(p - Vector2(isz, isz) * 0.5, Vector2(isz, isz)), false, icon_tint)
	_draw_badge(n, p, half)
	if ring >= 0.0 and ring < 1.0:
		draw_arc(p, s * (0.6 + ring * 1.1), 0.0, TAU, 40, Color(GOLD, 1.0 - ring), 3.0, true)
	if n.state == UpgradeGraph.AVAILABLE:
		_draw_price_tag(n, p + Vector2(0, half * (0.95 if n.keystone else 0.82)))


## A price tag pinned to the bottom edge of a node you can buy: gold if affordable, red if not.
func _draw_price_tag(n: Dictionary, at: Vector2) -> void:
	var can: bool = station.spendable_cash() >= n.price
	var label := "$%.0f" % n.price
	var font := get_theme_default_font()
	var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12
	var tag := StyleBoxFlat.new()
	tag.bg_color = Color(0.07, 0.06, 0.05, 0.95)
	tag.border_color = GOLD if can else Color(0.6, 0.25, 0.2)
	tag.set_border_width_all(1)
	tag.set_corner_radius_all(8)
	draw_style_box(tag, Rect2(at - Vector2(w * 0.5, 8), Vector2(w, 16)))
	_text(at + Vector2(0, 4.5), label, 12, GOLD if can else Color(0.95, 0.42, 0.35))


## Small corner marks: tank tiers.
func _draw_badge(n: Dictionary, p: Vector2, half: float) -> void:
	var mark := ""
	if n.icon == "tank":
		mark = ["I", "II", "III"][n.level]
	if mark == "" or n.kind == "root":
		return
	var c := p + Vector2(half - 4, -half + 4)
	draw_circle(c, 9.0, Color(0.06, 0.05, 0.04, 0.9))
	_text(c + Vector2(0, 4.5), mark, 11, GOLD if n.state != UpgradeGraph.LOCKED else LOCKED_EDGE.lightened(0.3))


func _draw_captions() -> void:
	for id in CAPTIONS:
		var c: Array = CAPTIONS[id]
		_text(cell_position(c[0]), c[1], 13, Color(GOLD, 0.55))


func _draw_tooltip(n: Dictionary) -> void:
	var lines := tooltip_for(n.key).split("\n")
	var font := get_theme_default_font()
	var w := 0.0
	for i in lines.size():
		w = maxf(w, font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18 if i == 0 else 15).x)
	var box_size := Vector2(w + 28, 22 + lines.size() * 22)
	var p := cell_position(n.cell) + Vector2(NODE * 0.7, -box_size.y * 0.5)
	if p.x + box_size.x > size.x - 8:
		p.x = cell_position(n.cell).x - NODE * 0.7 - box_size.x
	p.y = clampf(p.y, 8, size.y - box_size.y - 8)
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


func _text(centre: Vector2, s: String, font_size: int, col: Color) -> void:
	var font := get_theme_default_font()
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, centre - Vector2(w * 0.5, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, col)
