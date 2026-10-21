class_name RunOverScreen
extends Control
## The end of a run: FAILLITE (out of gas and broke) or, on day 50, PAPA EST REVENU. The run's totals
## and the XP banked for Papa's Garage. Serves: Advancement (the next run starts stronger).

signal done

var run: RunState
var meta: MetaState
var _t := 0.0
var _btn: Button


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_btn = GodUI.button("PAPA'S GARAGE  →", Vector2(280, 48))
	_btn.position = Vector2(436, 560)
	_btn.pressed.connect(func() -> void: done.emit())
	add_child(_btn)


func show_run(the_run: RunState, the_meta: MetaState) -> void:
	run = the_run
	meta = the_meta
	_t = 0.0
	visible = true


func _process(dt: float) -> void:
	if visible:
		_t += dt
		queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if visible and e is InputEventKey and e.pressed and not e.echo and e.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		done.emit()


func _draw() -> void:
	if not run:
		return
	GodUI.dim(self, size, 0.8)
	var title := "DAD IS BACK" if run.won else "BANKRUPT"
	var col := GodUI.GOLD if run.won else GodUI.RED
	GodUI.text(self, Vector2(576, 120), title, 64, col, true, 8)
	var sub := "\"T'es un vrai gaz bar boy.\"" if run.won else "No gas, no money. The truck won't come."
	GodUI.text(self, Vector2(576, 162), sub, 20, GodUI.CREAM, true)
	var r := Rect2(336, 196, 480, 330)
	draw_style_box(GodUI.panel_box(GodUI.GOLD_DIM), r)
	var t: Dictionary = run.totals
	var rows := [
		["Days survived", "%d / %d" % [run.day, GodData.FINAL_DAY]],
		["Cars fueled", str(t.cars)],
		["Super / Perfect / Good", "%d / %d / %d" % [t.supers, t.perfects, t.goods]],
		["OK / Miss", "%d / %d" % [t.oks, t.misses]],
		["Best combo", "x%d" % t.best_combo],
		["Truck deliveries", str(run.deliveries)],
		["XP earned", "+%d" % run.xp],
		["XP in the garage", str(meta.xp) if meta else "0"],
	]
	var y := r.position.y + 42
	for row in rows:
		GodUI.text(self, Vector2(r.position.x + 30, y), row[0], 19, GodUI.CREAM)
		var v: String = row[1]
		GodUI.text(self, Vector2(r.end.x - 30 - GodUI.font().get_string_size(v, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x, y), v, 20, GodUI.GOLD)
		y += 36
