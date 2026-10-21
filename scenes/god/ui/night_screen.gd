class_name NightScreen
extends Control
## The night (GOD PUMP plan): the upgrade tree (cash, always available) in the middle, the GAS TANK
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
	GodUI.wood_wall(self, size, Vector2(690, 330), _t)  # round 8: Dad's office, wood paneling
	var plate := Rect2(386, 8, 380, 74)
	GodUI.enamel(self, plate, Color(0.93, 0.89, 0.8), Color(0.62, 0.16, 0.12))
	GodUI.text(self, Vector2(576, 42), "THE NIGHT AFTER DAY %d" % run.day, 24, Color(0.62, 0.16, 0.12), true)
	GodUI.text(self, Vector2(576, 68), "Cash: $%.0f" % run.cash, 19, Color(0.14, 0.12, 0.1), true)
	_draw_tank()
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
		GodUI.enamel(self, r, Color(0.1, 0.08, 0.06), GodUI.RARITY[c.rarity])
		var tex := GodUI.icon(c.id)
		if tex:
			draw_texture_rect(tex, r.grow(-4), false)
	if _hover_card >= 0:
		var c := GodData.card(run.cards[_hover_card])
		var tip := Rect2(260 + _hover_card * 44, 520, 300, 64)
		draw_style_box(GodUI.panel_box(GodUI.RARITY[c.rarity]), tip)
		GodUI.text(self, tip.position + Vector2(12, 26), c.name, 17, GodUI.GOLD)
		GodUI.text(self, tip.position + Vector2(12, 50), c.helps, 14, GodUI.CREAM)


## The GAS TANK panel (round 8): the station's industrial tank, its sight glass and dial showing the
## gas left, how many days it might last, the price per litre, and what the next delivery costs.
func _draw_tank() -> void:
	var r := Rect2(16, 96, 232, 440)
	GodUI.enamel(self, r, Color(0.12, 0.29, 0.2))  # an old-station green enamel sign
	GodUI.text(self, Vector2(r.get_center().x, r.position.y + 36), "GAS TANK", 22, Color(0.98, 0.9, 0.6), true)
	var cap := run.tank_capacity()
	var tank_at := Vector2(r.position.x + 28, r.position.y + 52)
	var tex := GodUI.sprite("gas_tank")
	if tex:
		draw_texture_rect(tex, Rect2(tank_at, Vector2(88, 58) * 2.0), false)
	GasTankArt.draw_level(self, tank_at, 2.0, run.tank / cap, _t)
	var days := run.days_of_gas()
	var y := r.position.y + 196
	GodUI.text(self, Vector2(r.get_center().x, y), "Gas: $%.0f / $%.0f" % [run.tank, cap], 16, GodUI.CREAM, true)
	GodUI.text(self, Vector2(r.get_center().x, y + 22), "≈ %.1f day%s left" % [days, "s" if days >= 2.0 else ""], 16, GodUI.RED if days < 1.5 else GodUI.CREAM, true)
	draw_line(Vector2(r.position.x + 24, y + 40), Vector2(r.end.x - 24, y + 40), Color(1, 1, 1, 0.1), 1.0)
	GodUI.text(self, Vector2(r.get_center().x, y + 66), "Price: $%.2f / L" % run.price, 16, GodUI.CREAM, true)
	GodUI.text(self, Vector2(r.get_center().x, y + 86), "+%d%% every delivery" % roundi(run.price_rise() * 100.0), 13, Color(GodUI.CREAM, 0.6), true)
	var cost := run.delivery_cost()
	GodUI.text(self, Vector2(r.get_center().x, y + 120), "Delivery: $%.0f" % cost, 19, GodUI.GOLD if run.cash >= cost else GodUI.RED, true)
	GodUI.text(self, Vector2(r.get_center().x, y + 142), "+ choose 1 of %d cards" % int(run.mods().cards_offered), 13, Color(GodUI.GOLD, 0.7), true)
