class_name GodTreeView
extends Control
## The night shop's tree for GOD PUMP (GodData.BRANCHES), Bills-style: the station in the centre,
## eight branches radiating out on a 45° lattice, and between them the upgrades with two parents
## (GodData.LINKS, round 8), each in the gap between the two branches it needs. Owned nodes tinted with
## gold links, buyable ones glow with a price tag, the rest dim. Hover explains, click buys.
## The branches sit so that every pair a link joins is side by side. Serves: Advancement, Mastery.

signal bought(branch_id: String)

## The node waiting for a second click (buying it would leave too little for the truck).
var _confirm := ""

const CELLS := {
	"vibe": [Vector2i(0, -1), Vector2i(0, -2), Vector2i(0, -3)],
	"hours": [Vector2i(1, -1), Vector2i(2, -2), Vector2i(3, -3), Vector2i(4, -4)],
	"service": [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)],
	"marketing": [Vector2i(1, 1), Vector2i(2, 2), Vector2i(3, 3)],
	"tank": [Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3)],
	"truck": [Vector2i(-1, 1), Vector2i(-2, 2), Vector2i(-3, 3)],
	"nozzle": [Vector2i(-1, 0), Vector2i(-2, 0), Vector2i(-3, 0), Vector2i(-4, 0), Vector2i(-5, 0), Vector2i(-6, 0)],
	"attractions": [Vector2i(-1, -1), Vector2i(-2, -2), Vector2i(-3, -3), Vector2i(-4, -4)],
}
## Where each two-parent upgrade sits: in the wedge between its parents' branches.
const LINK_CELLS := {
	"drive_thru": Vector2i(3, -1), "hockey": Vector2i(1, -2), "night_neons": Vector2i(2, -3),
	"loyalty": Vector2i(2, 1), "drone_hangar": Vector2i(-5, -2), "chip_truck": Vector2i(-1, -2),
	"price_board": Vector2i(1, 2), "forward_contract": Vector2i(1, 3), "clamp_1": Vector2i(-3, 1), "clamp_2": Vector2i(-4, 2),
}
const FILL := {"hours": Color(0.2, 0.24, 0.42), "marketing": Color(0.42, 0.22, 0.38), "attractions": Color(0.2, 0.38, 0.36),
	"nozzle": Color(0.5, 0.14, 0.11), "tank": Color(0.35, 0.3, 0.12), "service": Color(0.2, 0.36, 0.22), "vibe": Color(0.47, 0.33, 0.13),
	"truck": Color(0.45, 0.18, 0.16), "link": Color(0.3, 0.22, 0.42)}
const NODE := 46.0

var area := Rect2(250, 96, 880, 470)
var run: RunState
var hover := ""
var _t := 0.0
var _pops := {}
var _unit := 56.0
var _origin := Vector2.ZERO


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	_layout()


func _layout() -> void:
	var span := Vector2(11.6, 8.6)
	_unit = minf(area.size.x / span.x, area.size.y / span.y)
	_origin = area.get_center() + Vector2(1.0, 0.5) * _unit


func _pos(c: Vector2i) -> Vector2:
	return _origin + Vector2(c) * _unit


## Every node: {key, branch, level, cell, state, node, parents}. State: 0 owned, 1 can be bought,
## 2 later (a branch node further out, or a link missing a parent). `parents`: the cells it hangs from.
func nodes() -> Array:
	var out := []
	if not run:
		return out
	var cell_of := {}
	for b in GodData.BRANCHES:
		var level: int = run.owned.get(b.id, 0)
		for i in b.nodes.size():
			var cell: Vector2i = CELLS[b.id][i]
			cell_of[b.nodes[i].id] = cell
			out.append({"key": "%s:%d" % [b.id, i], "branch": b.id, "level": i, "cell": cell,
				"state": 0 if i < level else (1 if i == level else 2), "node": b.nodes[i],
				"parents": [Vector2i.ZERO if i == 0 else CELLS[b.id][i - 1]]})
	for l in GodData.LINKS:
		var st := 0 if l.id in run.links else (1 if run.link_open(l.id) else 2)
		out.append({"key": "link:" + l.id, "branch": "link", "level": -1, "cell": LINK_CELLS[l.id], "state": st,
			"node": l, "parents": l.needs.map(func(id: String) -> Vector2i: return cell_of.get(id, Vector2i.ZERO))})
	return out


func press(key: String) -> bool:
	var node := _node_for(key)
	if node.is_empty():
		return false
	var parts := key.split(":")
	if parts[0] != "link" and int(parts[1]) != run.owned.get(parts[0], 0):
		return false
	if parts[0] == "link" and not run.link_open(parts[1]):
		return false
	if run.purchase_risky(run.node_price(node)) and _confirm != key:
		_confirm = key  # the first click warns; a second click buys anyway
		queue_redraw()
		return false
	_confirm = ""
	var ok := run.buy_link(parts[1]) if parts[0] == "link" else run.buy(parts[0])
	if ok:
		_pops[key] = 0.0
		bought.emit(parts[0])
		queue_redraw()
	return ok


func _node_for(key: String) -> Dictionary:
	var parts := key.split(":")
	if parts.size() != 2:
		return {}
	if parts[0] == "link":
		return GodData.link(parts[1])
	var b := GodData.branch(parts[0])
	var i := int(parts[1])
	return b.nodes[i] if not b.is_empty() and i < b.nodes.size() else {}


func tooltip(key: String) -> String:
	for n in nodes():
		if n.key == key:
			var price := run.node_price(n.node)
			if n.branch == "link" and n.state == 2:
				var names: Array = n.node.needs.map(func(id: String) -> String: return GodData.shop_node(id).name + (" (owned)" if run.owns(id) else " (missing)"))
				return "%s\n%s\n$%.0f  needs %s" % [n.node.name, n.node.helps, price, "  +  ".join(names)]
			if _confirm == key:
				return "%s\n!! You'd be left without enough for the truck.\nClick again to buy anyway." % n.node.name
			var status := "OWNED" if n.state == 0 else ("$%.0f  %s" % [price, "click to buy" if run.cash >= price else "(not enough cash)"] if n.state == 1 else "$%.0f  buy the one before it first" % price)
			return "%s\n%s\n%s" % [n.node.name, n.node.helps, status]
	return ""


func _key_at(p: Vector2) -> String:
	for n in nodes():
		if _pos(n.cell).distance_to(p) < NODE * 0.62:
			return n.key
	return ""


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var k := _key_at(e.position)
		if k != hover:
			hover = k
			_confirm = ""
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if k != "" else Control.CURSOR_ARROW
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var k := _key_at(e.position)
		if k != "":
			press(k)
			accept_event()


func _process(dt: float) -> void:
	if is_visible_in_tree():
		_t += dt
		for k in _pops.keys():
			_pops[k] += dt
			if _pops[k] > 1.0:
				_pops.erase(k)
		queue_redraw()


func _draw() -> void:
	if not run:
		return
	var all := nodes()
	var centre := _pos(Vector2i.ZERO)
	for i in 14:
		var k := float(i) / 14.0
		draw_circle(centre, lerpf(420.0, 30.0, k), Color(0.19, 0.14, 0.10, 0.05 + 0.03 * k))
	for n in all:
		var p := _pos(n.cell)
		for pc in n.parents:
			var parent := _pos(pc)
			match n.state:
				0:
					draw_line(parent, p, GodUI.GOLD.darkened(0.45), 7.0, true)
					draw_line(parent, p, GodUI.GOLD, 3.5, true)
				1:
					draw_line(parent, p, GodUI.GOLD.darkened(0.35), 3.0, true)
				_:
					if n.branch == "link":  # a link's parents dashed, until it opens
						_dashed(parent, p, Color(0.42, 0.34, 0.52, 0.7))
					else:
						draw_line(parent, p, Color(0.2, 0.18, 0.16), 2.0, true)
	# The station in the middle.
	var root := StyleBoxFlat.new()
	root.bg_color = Color(0.36, 0.29, 0.20)
	root.border_color = GodUI.GOLD
	root.set_border_width_all(2)
	root.set_corner_radius_all(8)
	draw_set_transform(centre, PI / 4.0, Vector2.ONE)
	draw_style_box(root, Rect2(-22, -22, 44, 44))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var st: Texture2D = GodUI.icon("station")
	if st:
		draw_texture_rect(st, Rect2(centre - Vector2(18, 18), Vector2(36, 36)), false)
	for n in all:
		_draw_node(n)
	for b in GodData.BRANCHES:
		var last: Vector2i = CELLS[b.id][-1]
		var dir := Vector2(last).normalized()
		GodUI.text(self, _pos(last) + dir * _unit * 0.95 + Vector2(0, 5), b.name, 13, Color(GodUI.GOLD, 0.6), true)
	if hover != "":
		_draw_tooltip(hover)


func _dashed(a: Vector2, b: Vector2, col: Color) -> void:
	var steps := int(a.distance_to(b) / 9.0)
	for i in steps:
		if i % 2 == 0:
			draw_line(a.lerp(b, float(i) / steps), a.lerp(b, float(i + 1) / steps), col, 2.0, true)


func _draw_node(n: Dictionary) -> void:
	var p := _pos(n.cell)
	var scale := 1.0
	if _pops.has(n.key):
		var k: float = _pops[n.key] / 0.55
		scale = 1.0 + 0.35 * exp(-4.0 * k) * sin(k * PI * 3.0) if k < 1.0 else 1.0
	if n.key == hover:
		scale *= 1.08
	var half := NODE * 0.5 * scale
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(7 if n.branch != "link" else 20)
	var tint := Color.WHITE
	var price := run.node_price(n.node)
	match n.state:
		0:
			box.bg_color = FILL[n.branch]
			box.border_color = GodUI.GOLD
			box.set_border_width_all(2)
		1:
			var can := run.cash >= price
			var pulse := 0.5 + 0.5 * sin(_t * 3.2)
			box.bg_color = Color(0.13, 0.11, 0.095)
			box.border_color = GodUI.GOLD if can else GodUI.GOLD.darkened(0.55)
			box.set_border_width_all(2)
			if can:
				box.shadow_color = Color(GodUI.GOLD, 0.25 + 0.35 * pulse)
				box.shadow_size = int(8 + 8 * pulse)
			tint = Color.WHITE if can else Color(0.7, 0.7, 0.7)
		_:
			box.bg_color = Color(0.09, 0.08, 0.075)
			box.border_color = Color(0.2, 0.18, 0.16)
			box.set_border_width_all(1)
			tint = Color(0.32, 0.3, 0.28)
	draw_style_box(box, Rect2(p - Vector2(half, half), Vector2(half, half) * 2.0))
	var tex: Texture2D = GodUI.icon(n.node.id)
	if tex:
		draw_texture_rect(tex, Rect2(p - Vector2(half, half) * 0.8, Vector2(half, half) * 1.6), false, tint)
	if n.state == 1:
		var can2 := run.cash >= price
		var label := "$%.0f" % price
		var w := GodUI.font().get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12
		var tag := StyleBoxFlat.new()
		tag.bg_color = Color(0.07, 0.06, 0.05, 0.95)
		tag.border_color = GodUI.GOLD if can2 else Color(0.6, 0.25, 0.2)
		tag.set_border_width_all(1)
		tag.set_corner_radius_all(8)
		var at := p + Vector2(0, half * 0.9)
		draw_style_box(tag, Rect2(at - Vector2(w * 0.5, 8), Vector2(w, 16)))
		GodUI.text(self, at + Vector2(0, 4.5), label, 12, GodUI.GOLD if can2 else GodUI.RED, true)


func _draw_tooltip(key: String) -> void:
	var lines := tooltip(key).split("\n")
	var f := GodUI.font()
	var w := 0.0
	for i in lines.size():
		w = maxf(w, f.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18 if i == 0 else 15).x)
	var bs := Vector2(w + 28, 22 + lines.size() * 22)
	var cell: Vector2i = Vector2i.ZERO
	for n in nodes():
		if n.key == key:
			cell = n.cell
	var p := _pos(cell) + Vector2(NODE * 0.7, -bs.y * 0.5)
	if p.x + bs.x > size.x - 8:
		p.x = _pos(cell).x - NODE * 0.7 - bs.x
	if p.x < 260:  # no room on the left (the GAS TANK panel): open to the right, clamped on screen
		p.x = minf(_pos(cell).x + NODE * 0.7, size.x - bs.x - 8)
	p.y = clampf(p.y, 8, size.y - bs.y - 8)
	draw_style_box(GodUI.panel_box(GodUI.GOLD.darkened(0.2)), Rect2(p, bs))
	for i in lines.size():
		var col := Color.WHITE if i == 0 else (GodUI.CREAM if i == 1 else GodUI.GOLD)
		draw_string(f, p + Vector2(14, 30 + i * 22), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18 if i == 0 else 15, col)
