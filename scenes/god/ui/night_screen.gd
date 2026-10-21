class_name NightScreen
extends Control
## The night (GOD PUMP plan): the upgrade tree (cash, always available) in the middle, the fuel truck
## on the left (the bill: the price rises with every delivery, and each one deals you 1 of 3 cards),
## the cards you've picked along the bottom, and OPEN for the next day. Serves: Advancement, tension.

signal truck_called
signal open_pressed

var run: RunState
var tree: GodTreeView
var _truck_btn: Button
var _open_btn: Button
var _t := 0.0
var _hover_card := -1


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	tree = GodTreeView.new()
	add_child(tree)
	tree.bought.connect(func(_b: String) -> void: refresh())
	_truck_btn = GodUI.button("CALL THE TRUCK", Vector2(212, 44), 17)
	_truck_btn.position = Vector2(26, 476)
	_truck_btn.pressed.connect(func() -> void: truck_called.emit())
	add_child(_truck_btn)
	_open_btn = GodUI.button("OPEN  →", Vector2(240, 48), 20)
	_open_btn.position = Vector2(888, 586)
	_open_btn.pressed.connect(func() -> void: open_pressed.emit())
	add_child(_open_btn)


func show_night(the_run: RunState) -> void:
	run = the_run
	tree.run = run
	visible = true
	refresh()


func refresh() -> void:
	if not run:
		return
	var cost := run.delivery_cost()
	_truck_btn.disabled = cost <= 0.0 or run.cash < minf(cost, RunState.MIN_DELIVERY)
	_truck_btn.text = "TANK FULL" if cost <= 0.0 else ("CALL THE TRUCK" if run.cash >= cost else "BUY $%.0f OF GAS" % run.cash)
	_open_btn.disabled = run.tank < 1.0
	_open_btn.text = "OPEN  ·  DAY %d  →" % (run.day + 1)
	queue_redraw()


func _process(dt: float) -> void:
	if visible:
		_t += dt
		queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if visible and e is InputEventKey and e.pressed and not e.echo and e.physical_keycode in [KEY_ENTER, KEY_KP_ENTER] and not _open_btn.disabled:
		get_viewport().set_input_as_handled()
		open_pressed.emit()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion:
		var i := int((e.position.x - 260) / 44) if e.position.y > 590 and e.position.x > 260 else -1
		_hover_card = i if i >= 0 and run and i < run.cards.size() else -1


func _draw() -> void:
	if not run:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.045, 0.035, 0.93))
	GodUI.text(self, Vector2(576, 40), "THE NIGHT AFTER DAY %d" % run.day, 26, GodUI.GOLD, true)
	GodUI.text(self, Vector2(576, 70), "Cash: $%.0f" % run.cash, 20, GodUI.CREAM, true)
	_draw_truck()
	if run.tank_warning():  # playtest 7: forgetting the truck shouldn't end a run by surprise
		var a := 0.75 + 0.25 * sin(_t * 6.0)
		var band := Rect2(262, 84, 440, 32)
		draw_style_box(GodUI.panel_box(Color(GodUI.RED, a), Color(0.25, 0.04, 0.03, 0.95), 8), band)
		GodUI.text(self, band.get_center() + Vector2(0, 7), "⚠  THE TANK WON'T LAST TOMORROW: CALL THE TRUCK", 15, Color(1, 0.9, 0.8, a), true)
		_truck_btn.modulate = Color(1, 1, 1).lerp(Color(1.4, 0.7, 0.6), 0.5 + 0.5 * sin(_t * 6.0))
	else:
		_truck_btn.modulate = Color.WHITE
	# The cards picked this run.
	GodUI.text(self, Vector2(260, 586), "CARDS" if not run.cards.is_empty() else "", 12, Color(GodUI.GOLD, 0.6))
	for i in run.cards.size():
		var c := GodData.card(run.cards[i])
		var r := Rect2(260 + i * 44, 594, 38, 38)
		draw_style_box(GodUI.panel_box(GodUI.RARITY[c.rarity], Color(0.1, 0.08, 0.06), 6), r)
		var tex := GodUI.icon(c.id)
		if tex:
			draw_texture_rect(tex, r.grow(-4), false)
	if _hover_card >= 0:
		var c := GodData.card(run.cards[_hover_card])
		var tip := Rect2(260 + _hover_card * 44, 520, 300, 64)
		draw_style_box(GodUI.panel_box(GodUI.RARITY[c.rarity]), tip)
		GodUI.text(self, tip.position + Vector2(12, 26), c.name, 17, GodUI.GOLD)
		GodUI.text(self, tip.position + Vector2(12, 50), c.helps, 14, GodUI.CREAM)


## The fuel truck panel: the tank, how many days it might last, the price, the next delivery's cost.
func _draw_truck() -> void:
	var r := Rect2(16, 96, 232, 440)
	draw_style_box(GodUI.panel_box(GodUI.GOLD_DIM), r)
	GodUI.text(self, Vector2(r.get_center().x, r.position.y + 34), "THE TRUCK", 22, GodUI.GOLD, true)
	var cap := run.tank_capacity()
	var gauge := Rect2(r.position.x + 92, r.position.y + 62, 48, 200)
	draw_rect(gauge, Color(0.05, 0.04, 0.03))
	var h := gauge.size.y * clampf(run.tank / cap, 0.0, 1.0)
	draw_rect(Rect2(gauge.position.x, gauge.end.y - h, gauge.size.x, h), GodPump.GAS)
	draw_rect(gauge, GodUI.GOLD_DIM, false, 1.5)
	var days := run.days_of_gas()
	GodUI.text(self, Vector2(r.get_center().x, gauge.end.y + 28), "Gas: $%.0f / $%.0f" % [run.tank, cap], 15, GodUI.CREAM, true)
	GodUI.text(self, Vector2(r.get_center().x, gauge.end.y + 50), "≈ %.1f day%s left" % [days, "s" if days >= 2.0 else ""], 15, GodUI.RED if days < 1.5 else GodUI.CREAM, true)
	GodUI.text(self, Vector2(r.get_center().x, gauge.end.y + 82), "Price: $%.2f / L" % run.price, 15, GodUI.CREAM, true)
	GodUI.text(self, Vector2(r.get_center().x, gauge.end.y + 102), "+%d%% every delivery" % int(GodData.PRICE_RISE * 100.0 * (2.0 if "devil" in run.cards else 1.0)), 13, Color(GodUI.CREAM, 0.6), true)
	var cost := run.delivery_cost()
	GodUI.text(self, Vector2(r.get_center().x, gauge.end.y + 134), "Delivery: $%.0f" % cost, 18, GodUI.GOLD if run.cash >= cost else GodUI.RED, true)
	GodUI.text(self, Vector2(r.get_center().x, gauge.end.y + 156), "+ choose 1 of 3 cards", 13, Color(GodUI.GOLD, 0.7), true)
