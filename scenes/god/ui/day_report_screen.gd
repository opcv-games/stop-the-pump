class_name DayReportScreen
extends Control
## End of a day (designer's ask): accuracy, loot, cars fueled, Super / Perfect / Good / OK /
## Overfilled / Unserved, XP, and progress toward the next car type. ENTER or the button goes on.

signal done

var report := {}
var run: RunState
var meta: MetaState
var _t := 0.0
var _btn: Button


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_btn = GodUI.button("THE NIGHT  →")
	_btn.position = Vector2(466, 548)
	_btn.pressed.connect(func() -> void: done.emit())
	add_child(_btn)


func show_report(r: Dictionary, the_run: RunState, the_meta: MetaState) -> void:
	report = r
	run = the_run
	meta = the_meta
	_t = 0.0
	_btn.text = "THE END  →" if run.won else "THE NIGHT  →"
	visible = true
	queue_redraw()


func _process(dt: float) -> void:
	if visible:
		_t += dt
		queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if visible and e is InputEventKey and e.pressed and not e.echo and e.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		get_viewport().set_input_as_handled()
		done.emit()


func _draw() -> void:
	if report.is_empty():
		return
	GodUI.dim(self, size, 0.6)
	var r := Rect2(286, 52, 580, 480)
	draw_style_box(GodUI.panel_box(GodUI.GOLD_DIM), r)
	var day: int = report.get("day", 1)
	GodUI.text(self, Vector2(576, 104), "FERMÉ  ·  DAY %d / %d" % [day, GodData.FINAL_DAY], 34, GodUI.GOLD, true)
	if report.get("out_of_gas", false):
		GodUI.text(self, Vector2(576, 134), "out of gas before closing!", 17, GodUI.RED, true)
	var rows := [
		["Accuracy", "%d%%" % int(report.get("accuracy", 0.0) * 100.0)],
		["Loot", "$%.2f" % report.get("loot", 0.0)],
		["Cars fueled", str(report.get("cars", 0))],
		["Best combo", "x%d" % report.get("best_combo", 1)],
		["XP", "+%d" % report.get("xp", 0)],
	]
	var y := 178.0
	for row in rows:
		GodUI.text(self, Vector2(330, y), row[0], 20, GodUI.CREAM)
		GodUI.text(self, Vector2(820 - GodUI.font().get_string_size(row[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x, y), row[1], 22, GodUI.GOLD)
		y += 34.0
	var tiers: Dictionary = report.get("tiers", {})
	var grades := [[ScoreTiers.SUPER_PERFECT, "SUPER"], [ScoreTiers.PERFECT, "PERFECT"], [ScoreTiers.GOOD, "GOOD"],
		[ScoreTiers.OK, "OK"], [ScoreTiers.MISS, "OVERFILLED"], [ScoreTiers.UNSERVED, "UNSERVED"]]
	for i in grades.size():
		var x := 331.0 + i * 98.0
		var col: Color = GodPump.TIER_COLORS[grades[i][0]]
		GodUI.text(self, Vector2(x, 372), str(tiers.get(grades[i][0], 0)), 30, col, true)
		GodUI.text(self, Vector2(x, 396), grades[i][1], 13, Color(col, 0.8), true)
	# Progress to the next car type (cars filled across all runs, this one included).
	var have: int = meta.total_cars + run.totals.cars if meta and run else 0
	var nxt := {}
	for id in GodData.CAR_ORDER:
		if have < GodData.CAR_TYPES[id].unlock:
			nxt = {"name": GodData.CAR_TYPES[id].name, "need": GodData.CAR_TYPES[id].unlock}
			break
	if nxt.is_empty():
		GodUI.text(self, Vector2(576, 452), "Every car type unlocked!", 17, GodUI.GREEN, true)
	else:
		GodUI.text(self, Vector2(576, 440), "Next car type: %s  (%d / %d cars)" % [nxt.name, have, nxt.need], 17, GodUI.CREAM, true)
		var bar := Rect2(376, 452, 400, 12)
		draw_rect(bar, Color(0, 0, 0, 0.5))
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(float(have) / nxt.need, 0.0, 1.0), bar.size.y)), GodUI.GOLD)
	GodUI.text(self, Vector2(576, 500), "Gas left in the tank: $%.0f" % report.get("tank_left", 0.0), 16, Color(GodUI.CREAM, 0.7), true)
