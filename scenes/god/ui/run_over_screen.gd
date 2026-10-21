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
	_btn = GodUI.button("PAPA'S GARAGE  »", Vector2(280, 48))
	_btn.position = Vector2(436, 506)
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


## The run's last front page (round 8): a SPECIAL EDITION of L'Écho. The headline (the gaz bar closes,
## or Dad is back), the run's numbers, and two charts: your cash at closing day by day, and the price
## per delivery. The button goes to Papa's Garage.
func _draw() -> void:
	if not run:
		return
	GodUI.dim(self, size, 0.8)
	var p := Rect2(196, 40, 760, 440)
	draw_rect(Rect2(p.position + Vector2(8, 10), p.size), Color(0, 0, 0, 0.35))
	draw_rect(p, GodUI.PAPER)
	var ink := GodUI.PAPER_INK
	var red := GodUI.RED_INK
	var serif := GodUI.serif()
	var bold := GodUI.serif(true)
	var ital := GodUI.serif(false, true)
	var L := p.position.x + 20.0
	var R := p.end.x - 20.0
	var band := Rect2(L, p.position.y + 14, R - L, 22)
	draw_rect(band, red)
	GodUI.text_in(self, bold, band.get_center() + Vector2(0, 6), tr("SPECIAL EDITION"), 14, GodUI.PAPER, true)
	GodUI.text_in(self, bold, Vector2(p.get_center().x, p.position.y + 78), tr("L'ÉCHO DE SAINT-CLIN-CLIN"), 34, ink, true)
	draw_line(Vector2(L, p.position.y + 88), Vector2(R, p.position.y + 88), ink, 2.0)
	var headline := tr("DAD IS BACK!") if run.won else tr("THE GAZ BAR CLOSES AFTER %d DAYS") % run.day
	var sub := tr("\"T'es un vrai gaz bar boy,\" says the man in the orange hatchback.") if run.won else tr("No gas, no money, and the truck won't come. \"He'll be back,\" says Bertrand.")
	var y := p.position.y + 130.0
	y += GodUI.para_in(self, bold, Vector2(L, y), headline, 32, R - L, ink, 1.1)
	y += GodUI.para_in(self, ital, Vector2(L, y), sub, 15, R - L, Color(ink, 0.85))
	draw_line(Vector2(L, y - 6), Vector2(R, y - 6), Color(ink, 0.35), 1.0)
	var t: Dictionary = run.totals
	var rows := [
		[tr("Days"), "%d / %d" % [run.day, GodData.FINAL_DAY]], [tr("Cars fueled"), str(t.cars)],
		[tr("Topped off · Perfect · Good"), "%d · %d · %d" % [t.supers, t.perfects, t.goods]],
		[tr("OK · Overfilled · Unserved"), "%d · %d · %d" % [t.oks, t.misses, t.unserved]],
		[tr("Best combo"), "×%d" % t.best_combo], [tr("Truck deliveries"), str(run.deliveries)],
		[tr("Loot"), "$%d" % int(t.loot)], [tr("XP earned"), tr("+%d  (garage: %d)") % [run.xp, meta.xp if meta else 0]],
	]
	var ry := y + 14.0
	for row in rows:
		GodUI.text_in(self, serif, Vector2(L, ry), row[0], 14, ink)
		var v: String = row[1]
		GodUI.text_in(self, bold, Vector2(L + 340 - bold.get_string_size(v, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x, ry), v, 14, ink)
		ry += 24.0
	var cx := L + 370.0
	draw_line(Vector2(cx - 12, y + 2), Vector2(cx - 12, p.end.y - 16), Color(ink, 0.35), 1.0)
	GodChart.line(self, Rect2(cx, y + 2, R - cx, 104), run.cash_history, tr("Your cash at closing, day by day"), "$%d", ink, ink, serif)
	GodChart.line(self, Rect2(cx, y + 118, R - cx, 104), run.price_history, tr("The price per delivery"), "$%.2f", ink, red, serif)
