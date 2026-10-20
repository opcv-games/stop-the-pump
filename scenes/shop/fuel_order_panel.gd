class_name FuelOrderPanel
extends Control
## The night's fuel order (#32), beside the upgrade tree: what's left in the tank, what you order on
## top (the lighter band), and what it costs. Fuel and upgrades share the same cash, so every litre
## ordered is a dollar not spent on the tree. Keys: - and = adjust by 50 L. Serves: Advancement.

const STEP := 50.0
const AMBER := Color(0.98, 0.62, 0.16)
const GOLD := UpgradeTreeView.GOLD

var station: Node
var gauge := Rect2(66, 70, 68, 250)
var _info: Label


func _init() -> void:
	position = Vector2(24, 92)
	size = Vector2(200, 470)
	mouse_filter = Control.MOUSE_FILTER_PASS
	_info = Label.new()
	_info.position = Vector2(0, 330)
	_info.size = Vector2(200, 70)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info.add_theme_font_size_override("font_size", 15)
	add_child(_info)
	_button("-50 L", Vector2(14, 404), func() -> void: nudge(-STEP))
	_button("+50 L", Vector2(104, 404), func() -> void: nudge(STEP))
	_button("None", Vector2(14, 438), func() -> void: station.set_fuel_order(0.0))
	_button("Fill up", Vector2(104, 438), func() -> void: station.set_fuel_order(INF))


func setup(owner_station: Node) -> void:
	station = owner_station
	refresh()


func nudge(liters: float) -> void:
	station.set_fuel_order(station.fuel_order_liters + liters)


func refresh() -> void:
	if not station:
		return
	_info.text = "In tank  %.0f L\nOrder  +%.0f L\nCost  $%.0f" % [
		station.tank.liters, station.fuel_order_liters, station.fuel_order_cost()]
	queue_redraw()


func _button(text: String, at: Vector2, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.position = at
	b.size = Vector2(82, 28)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 14)
	b.pressed.connect(action)
	add_child(b)


func _draw() -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.10, 0.085, 0.07, 0.92)
	box.border_color = GOLD.darkened(0.5)
	box.set_border_width_all(1)
	box.set_corner_radius_all(8)
	draw_style_box(box, Rect2(Vector2.ZERO, size))
	var font := get_theme_default_font()
	var title := "FUEL ORDER"
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(font, Vector2((size.x - tw) * 0.5, 34), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, GOLD)
	if not station:
		return
	var cap: float = station.tank.capacity_liters
	draw_rect(gauge, Color(0.05, 0.045, 0.04))
	var have: float = station.tank.liters / cap
	var order: float = station.fuel_order_liters / cap
	var h_have := gauge.size.y * have
	var h_order := gauge.size.y * order
	draw_rect(Rect2(gauge.position.x, gauge.end.y - h_have, gauge.size.x, h_have), AMBER)
	var top := gauge.end.y - h_have - h_order
	draw_rect(Rect2(gauge.position.x, top, gauge.size.x, h_order), Color(AMBER, 0.4))
	# Stripes on the ordered band: it isn't in the tank yet.
	var y := gauge.end.y - h_have
	while y > top + 1.0:
		draw_line(Vector2(gauge.position.x, y), Vector2(gauge.end.x, maxf(y - 10.0, top)), Color(AMBER, 0.7), 2.0)
		y -= 12.0
	draw_rect(gauge, GOLD.darkened(0.4), false, 1.5)
	var cap_text := "%.0f L" % cap
	var cw := font.get_string_size(cap_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, Vector2((size.x - cw) * 0.5, gauge.position.y - 6), cap_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.5))
