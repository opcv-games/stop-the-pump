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


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var labels := [["PLAY", "play_pressed"], ["PAPA'S GARAGE", "garage_pressed"], ["THE STORY", "intro_pressed"], ["QUIT", "quit_pressed"]]
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
		if meta.ending_seen:
			GodUI.text(self, Vector2(576, 610), "Dad came home. ✓", 16, GodUI.GOLD, true, 4)
