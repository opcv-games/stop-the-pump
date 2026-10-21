class_name DevPanel
extends Control
## The designer's configurator (F1, playtest 7): set the cash, the gas, the day, XP and cars filled
## (which unlock car types), change the game speed, skip to the next night, or wipe the save. It talks
## to GodGame directly; it's a testing tool, not part of the game.

const ROW_H := 46.0
const BOX := Rect2(306, 70, 540, 520)

var game: GodGame
var _rows := []  # [label, value callable]
var _reset_armed := false


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS


func build(g: GodGame) -> void:
	game = g
	_row("Cash", func() -> String: return "$%.0f" % game.run.cash if game.run else "-",
		[["-100", func() -> void: _cash(-100.0)], ["+100", func() -> void: _cash(100.0)], ["+1000", func() -> void: _cash(1000.0)]])
	_row("Gas in the tank", func() -> String: return "$%.0f / $%.0f" % [game.run.tank, game.run.tank_capacity()] if game.run else "-",
		[["EMPTY", func() -> void: _tank(0.0)], ["1 DAY", func() -> void: _tank(game.run.gas_per_day() if game.run else 0.0)], ["FILL", func() -> void: _tank(INF)]])
	_row("Day", func() -> String: return "%d / %d" % [game.run.day, GodData.FINAL_DAY] if game.run else "-",
		[["-1", func() -> void: _day(-1)], ["+1", func() -> void: _day(1)], ["+10", func() -> void: _day(10)]])
	_row("XP (garage)", func() -> String: return str(game.meta.xp),
		[["+1000", func() -> void: _xp(1000)], ["+10000", func() -> void: _xp(10000)]])
	_row("Cars filled (unlocks)", func() -> String:
		var n := game.meta.next_unlock()
		return "%d%s" % [game.meta.total_cars, "  (next: %s at %d)" % [n.name, n.need] if not n.is_empty() else "  (all)"],
		[["-50", func() -> void: _cars(-50)], ["+50", func() -> void: _cars(50)], ["ALL", func() -> void: _cars(100000)]])
	_row("Game speed", func() -> String: return "%.0fx" % Engine.time_scale,
		[["1x", func() -> void: Engine.time_scale = 1.0], ["2x", func() -> void: Engine.time_scale = 2.0], ["4x", func() -> void: Engine.time_scale = 4.0], ["8x", func() -> void: Engine.time_scale = 8.0]])
	var y := BOX.position.y + 76 + _rows.size() * ROW_H + 16
	var actions := [["NEXT NIGHT", func() -> void: game.dev_next_night()], ["END THE DAY", func() -> void: game.dev_end_day()], ["RESET SAVE", _reset]]
	for i in actions.size():
		var b := GodUI.button(actions[i][0], Vector2(160, 40), 15)
		b.position = Vector2(BOX.position.x + _action_x(i), y)
		b.pressed.connect(actions[i][1])
		add_child(b)
	var close := GodUI.button("CLOSE  (F1)", Vector2(200, 40), 15)
	close.position = Vector2(BOX.get_center().x - 100, BOX.end.y - 56)
	close.pressed.connect(func() -> void: game.toggle_dev())
	add_child(close)


func _action_x(i: int) -> float:
	return 24.0 + i * 168.0


func _row(label: String, value: Callable, buttons: Array) -> void:
	var y := BOX.position.y + 76 + _rows.size() * ROW_H
	_rows.append([label, value])
	var x := BOX.end.x - 24.0
	for i in range(buttons.size() - 1, -1, -1):
		var b := GodUI.button(buttons[i][0], Vector2(64, 34), 13)
		x -= 68.0
		b.position = Vector2(x, y - 4)
		b.pressed.connect(buttons[i][1])
		b.pressed.connect(_changed)
		add_child(b)


func _changed() -> void:
	_reset_armed = false
	game.dev_refresh()


func _cash(d: float) -> void:
	if game.run:
		game.run.cash = maxf(game.run.cash + d, 0.0)


func _tank(v: float) -> void:
	if game.run:
		game.run.tank = minf(v, game.run.tank_capacity())
		if game.state == "day":
			game.day.tank = game.run.tank


func _day(d: int) -> void:
	if game.run:
		game.run.day = clampi(game.run.day + d, 1, GodData.FINAL_DAY)


func _xp(d: int) -> void:
	game.meta.xp += d
	game.meta.save()


func _cars(d: int) -> void:
	game.meta.total_cars = maxi(game.meta.total_cars + d, 0)
	game.meta.save()


## Two clicks: wipes the save (XP, garage, unlocks, the intro) and goes back to the title.
func _reset() -> void:
	if not _reset_armed:
		_reset_armed = true
		return
	_reset_armed = false
	game.dev_reset_save()


func _process(_dt: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	GodUI.dim(self, size, 0.55)
	draw_style_box(GodUI.panel_box(GodUI.GOLD), BOX)
	GodUI.text(self, Vector2(BOX.get_center().x, BOX.position.y + 40), "DEV MODE", 28, GodUI.GOLD, true)
	GodUI.text(self, Vector2(BOX.get_center().x, BOX.position.y + 62), "state: %s" % game.state, 13, Color(GodUI.CREAM, 0.5), true)
	for i in _rows.size():
		var y := BOX.position.y + 76 + i * ROW_H + 20
		GodUI.text(self, Vector2(BOX.position.x + 24, y), _rows[i][0], 15, GodUI.CREAM)
		GodUI.text(self, Vector2(BOX.position.x + 24, y + 17), _rows[i][1].call(), 13, GodUI.GOLD)
	if _reset_armed:
		var y := BOX.position.y + 76 + _rows.size() * ROW_H + 74
		GodUI.text(self, Vector2(BOX.get_center().x, y), "Click RESET SAVE again to wipe XP, the garage and unlocks.", 13, GodUI.RED, true)
