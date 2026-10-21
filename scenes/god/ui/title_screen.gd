class_name TitleScreen
extends Control
## The title: GOD PUMP over the gaz bar at dawn, with the neon flickering behind. PLAY, Papa's Garage,
## the intro again, QUIT; the best day so far, and a nod if Dad has come home.

signal play_pressed
signal garage_pressed
signal intro_pressed
signal quit_pressed

var meta: MetaState
var _t := 0.0
var _hover_run := -1
## Round 8: the menu shows the story so far. Left: lifetime numbers; right: the scrapbook (your runs,
## the last headline, Dad's postcards).
const STATS_BOX := Rect2(26, 300, 370, 292)
const BOOK := Rect2(756, 300, 370, 292)
const RUNS_CHART := Rect2(776, 312, 330, 110)


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var labels := [["PLAY", "play_pressed"], ["PAPA'S GARAGE", "garage_pressed"], ["THE STORY", "intro_pressed"], ["QUIT", "quit_pressed"]]
	if OS.has_feature("web"):
		labels.pop_back()  # a browser tab has nothing to quit to
	for i in labels.size():
		var b := GodUI.button(labels[i][0], Vector2(300, 48), 20)
		b.position = Vector2(426, 330 + i * 60)
		var sig: String = labels[i][1]
		b.pressed.connect(func() -> void: emit_signal(sig))
		add_child(b)


func show_title(the_meta: MetaState) -> void:
	meta = the_meta
	visible = true


func _process(dt: float) -> void:
	if visible:
		_t += dt
		queue_redraw()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and meta:
		_hover_run = -1
		var n := meta.history.size()
		if n >= 2 and RUNS_CHART.grow(4).has_point(e.position):
			_hover_run = clampi(int((e.position.x - RUNS_CHART.position.x) / (RUNS_CHART.size.x / n)), 0, n - 1)


func _unhandled_input(e: InputEvent) -> void:
	if visible and e is InputEventKey and e.pressed and not e.echo and e.physical_keycode in [KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		play_pressed.emit()


## The logo: chrome-gold letters with a heavenly glow and a slow shimmer.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.015, 0.01, 0.45))
	var centre := Vector2(576, 170)
	for i in 10:
		draw_circle(centre, 260.0 - i * 22.0, Color(1.0, 0.8, 0.35, 0.025))
	for i in 9:  # rays from the heavens
		var a := -PI / 2.0 + (i - 4) * 0.22 + sin(_t * 0.4) * 0.03
		var tip := centre + Vector2.from_angle(a) * 380.0
		draw_colored_polygon(PackedVector2Array([centre, tip + Vector2.from_angle(a + PI / 2) * 30, tip - Vector2.from_angle(a + PI / 2) * 30]), Color(1, 0.85, 0.45, 0.05))
	var f := GodUI.font()
	var title := "GOD PUMP"
	var fs := 124
	var w := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var at := Vector2(576 - w * 0.5, 210)
	draw_string_outline(f, at + Vector2(6, 8), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 18, Color(0, 0, 0, 0.6))
	draw_string_outline(f, at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 10, Color(0.45, 0.25, 0.05))
	draw_string(f, at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.82, 0.32))
	var shine := fmod(_t * 0.35, 1.6) - 0.3
	draw_string(f, at, title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 0.9, clampf(0.35 - absf(shine - 0.5) * 0.7, 0.0, 0.35)))
	GodUI.text(self, Vector2(576, 256), "Saint-Clin-Clin-des-Meuh-Meuh, Québec", 20, GodUI.CREAM, true, 5)
	if meta:
		var line := "Best day: %d / %d   ·   Runs: %d   ·   XP: %d" % [meta.best_day, GodData.FINAL_DAY, meta.runs, meta.xp]
		GodUI.text(self, Vector2(576, 300), line, 16, Color(GodUI.CREAM, 0.75), true, 4)
		var v := "v" + str(ProjectSettings.get_setting("application/config/version", ""))
		GodUI.text(self, Vector2(12, 636), "OPCV Games", 14, Color(1, 1, 1, 0.5))
		GodUI.text(self, Vector2(1140 - GodUI.font().get_string_size(v, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x, 636), v, 14, Color(1, 1, 1, 0.5))
		if meta.ending_seen:
			GodUI.text(self, Vector2(576, 610), "Dad came home. ✓", 16, GodUI.GOLD, true, 4)
		_draw_stats()
		_draw_scrapbook()


## THE GAZ BAR SO FAR: every run added up (MetaState.lifetime).
func _draw_stats() -> void:
	var r := STATS_BOX
	draw_style_box(GodUI.panel_box(GodUI.GOLD_DIM, Color(0.08, 0.065, 0.05, 0.9)), r)
	GodUI.text(self, Vector2(r.position.x + 18, r.position.y + 30), "THE GAZ BAR SO FAR", 17, GodUI.GOLD)
	var lt: Dictionary = meta.lifetime
	if meta.runs == 0:
		GodUI.para(self, Vector2(r.get_center().x, r.position.y + 90), "No runs yet. Dad's old pump is waiting.", 15, r.size.x - 40, Color(GodUI.CREAM, 0.7))
		return
	var rows := [
		["Runs", str(meta.runs)], ["Best day", "%d / %d" % [meta.best_day, GodData.FINAL_DAY]],
		["Days at the pump", str(lt.get("days", 0))], ["Cars fueled", str(meta.total_cars)],
		["Topped off · Perfect", "%d · %d" % [lt.get("supers", 0), lt.get("perfects", 0)]],
		["Overfilled · Unserved", "%d · %d" % [lt.get("overfilled", 0), lt.get("unserved", 0)]],
		["Best combo", "×%d" % lt.get("best_combo", 1)],
		["Truck deliveries", str(lt.get("deliveries", 0))],
		["Highest price paid", "$%.2f / L" % lt.get("top_price", GodData.WHOLESALE_START)],
		["Loot, every run", "$%d" % int(lt.get("loot", 0.0))],
	]
	var y := r.position.y + 58.0
	for row in rows:
		GodUI.text(self, Vector2(r.position.x + 18, y), row[0], 14, Color(GodUI.CREAM, 0.8))
		var v: String = row[1]
		GodUI.text(self, Vector2(r.end.x - 18 - GodUI.font().get_string_size(v, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x, y), v, 15, GodUI.GOLD)
		y += 23.0


## The scrapbook, on newsprint: days survived per run, the last headline, Dad's postcards.
func _draw_scrapbook() -> void:
	var r := BOOK
	draw_rect(Rect2(r.position + Vector2(5, 6), r.size), Color(0, 0, 0, 0.35))
	draw_rect(r, NewspaperScreen.PAPER)
	var ink := NewspaperScreen.INK
	var serif := GodUI.serif()
	var days: Array = meta.history.map(func(h: Dictionary) -> int: return h.days)
	GodChart.bars(self, RUNS_CHART, days, "Days survived, run by run", ink, NewspaperScreen.RED_INK, serif, float(GodData.FINAL_DAY), _hover_run)
	if _hover_run >= 0 and _hover_run < meta.history.size():
		var h: Dictionary = meta.history[_hover_run]
		var tip := "Run %d: day %d%s, $%d" % [meta.runs - meta.history.size() + _hover_run + 1, h.days, " (Dad came home)" if h.won else "", int(h.loot)]
		var tw := serif.get_string_size(tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 12
		var tr := Rect2(clampf(RUNS_CHART.position.x + (_hover_run + 0.5) * RUNS_CHART.size.x / meta.history.size() - tw * 0.5, r.position.x, r.end.x - tw), RUNS_CHART.position.y - 6, tw, 20)
		draw_rect(tr, ink)
		GodUI.text_in(self, serif, tr.position + Vector2(6, 14), tip, 12, NewspaperScreen.PAPER)
	draw_line(Vector2(r.position.x + 16, r.position.y + 132), Vector2(r.end.x - 16, r.position.y + 132), Color(ink, 0.35), 1.0)
	var headline: String = meta.clippings[-1] if not meta.clippings.is_empty() else "Nothing in the paper yet."
	GodUI.text_in(self, GodUI.serif(true), Vector2(r.position.x + 16, r.position.y + 150), "THE LAST HEADLINE", 11, Color(ink, 0.7))
	GodUI.para_in(self, GodUI.serif(true), Vector2(r.position.x + 16, r.position.y + 170), headline, 15, r.size.x - 32, ink, 1.15)
	GodUI.text_in(self, GodUI.serif(true), Vector2(r.position.x + 16, r.position.y + 214), "POSTCARDS FROM \"UN PÊCHEUR\"", 11, Color(ink, 0.7))
	for i in Newspaper.POSTCARDS.size():
		var pc: Array = Newspaper.POSTCARDS[i]
		var slot := Rect2(r.position.x + 16 + i * 86, r.position.y + 224, 78, 52)
		if pc[0] in meta.postcards:
			draw_rect(slot.grow(2), Color(0.98, 0.97, 0.93))
			var tex := GodUI.sprite(pc[3])
			if tex:
				draw_texture_rect(tex, slot.grow(-3), false)
		else:
			draw_rect(slot, Color(ink, 0.07))
			draw_rect(slot, Color(ink, 0.3), false, 1.0)
			GodUI.text_in(self, serif, slot.get_center() + Vector2(0, 5), "day %d" % pc[0], 12, Color(ink, 0.45), true)
