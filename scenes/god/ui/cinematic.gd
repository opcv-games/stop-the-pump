class_name Cinematic
extends Control
## GOD PUMP's in-engine "videos" (designer: the intro must do justice to the tongue-in-cheek title).
## Shots of captions over three kinds of backdrop: black, the heavens (a golden sky, parting clouds,
## god rays, a golden nozzle descending, a choir), and the gaz bar itself behind a letterbox. One
## shot can slam the GOD PUMP title. Any key moves on; ESC skips; the last shot waits for ENTER.

signal finished

## The opening: mock-biblical, then down to earth in Saint-Clin-Clin.
const INTRO := [
	{"bg": "black", "text": "OPCV Games presents", "hold": 2.0},
	{"bg": "black", "text": "In the beginning, there was gas."},
	{"bg": "heaven", "text": "And the gas was good."},
	{"bg": "heaven", "nozzle": true, "text": "Then came the one who would pour it."},
	{"bg": "heaven", "nozzle": true, "title": true, "text": "", "hold": 3.2, "choir": true},
	{"bg": "scene", "text": "Saint-Clin-Clin-des-Meuh-Meuh, Québec."},
	{"bg": "scene", "text": "Your father passed away last spring."},
	{"bg": "scene", "text": "At the reading of the will, Me Tremblay, the notary, cleared his throat. Nervously."},
	{"bg": "heaven", "nozzle": true, "text": "\"...and to my only child, I leave... THE GOD PUMP.\"", "choir": true},
	{"bg": "scene", "text": "It's a gas station."},
	{"bg": "scene", "text": "One pump. A boarded window. Ti-Guy, Mme Gagnon, Bertrand and Le Grand, four regulars who never leave."},
	{"bg": "scene", "text": "He only opened mornings. After 11, he went fishing."},
	{"bg": "scene", "text": "Are you worthy?", "last": true},
]
## Day 50: Dad drives in.
const ENDING := [
	{"bg": "scene", "text": "Day 50."},
	{"bg": "scene", "text": "An old orange hatchback pulls in. A fishing rod sticks out the window."},
	{"bg": "scene", "text": "You top it off. To the cent."},
	{"bg": "scene", "text": "The driver gets out. Sunburnt. Smells like a lake."},
	{"bg": "scene", "text": "\"Salut, mon grand.\""},
	{"bg": "scene", "text": "\"After 11, I went fishing. Then I just... kept going.\""},
	{"bg": "scene", "text": "Four postcards, signed \"un pêcheur\". Mme Gagnon gasps. Bertrand doesn't."},
	{"bg": "scene", "text": "He looks at the lot. The regulars. The jar."},
	{"bg": "heaven", "nozzle": true, "text": "\"T'es un vrai gaz bar boy.\"", "choir": true},
	{"bg": "heaven", "title": true, "text": "Thanks for playing.", "credits": true, "last": true},
]
const SHOT_SECONDS := 3.6

var shots: Array = INTRO
var index := 0
var _t := 0.0
var _total := 0.0
var _choir: AudioStreamPlayer
var _nozzle: Texture2D


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func play(which: Array) -> void:
	shots = which
	index = 0
	_t = 0.0
	_total = 0.0
	visible = true
	_nozzle = load("res://assets/art/pixel/out/sprites/nozzle_idle.png") if ResourceLoader.exists("res://assets/art/pixel/out/sprites/nozzle_idle.png") else null
	_enter_shot()


func shot() -> Dictionary:
	return shots[index]


func on_last() -> bool:
	return index >= shots.size() - 1


func advance() -> void:
	if on_last():
		visible = false
		finished.emit()
		return
	index += 1
	_t = 0.0
	_enter_shot()


func skip() -> void:
	index = shots.size() - 1
	_t = 0.0
	_enter_shot()


func _enter_shot() -> void:
	if shot().get("choir", false):
		if not _choir:
			_choir = AudioStreamPlayer.new()
			var path := "res://assets/audio/placeholder/choir.wav"
			if ResourceLoader.exists(path):
				_choir.stream = load(path)
			add_child(_choir)
		if _choir.stream:
			_choir.play()
	queue_redraw()


func _unhandled_input(e: InputEvent) -> void:
	if not visible:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		get_viewport().set_input_as_handled()
		if e.physical_keycode == KEY_ESCAPE and not on_last():
			skip()
		elif not on_last() or e.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			advance()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		advance()
		accept_event()


func _process(dt: float) -> void:
	if not visible:
		return
	_t += dt
	_total += dt
	var hold: float = shot().get("hold", SHOT_SECONDS)
	if not on_last() and _t >= hold:
		advance()
	queue_redraw()


func _draw() -> void:
	var s := shot()
	match s.bg:
		"black":
			draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.015, 0.01))
		"heaven":
			_draw_heaven(s)
		_:
			draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.35))
	if s.get("title", false):
		_draw_title()
	# Letterbox and the caption.
	draw_rect(Rect2(0, 0, size.x, 56), Color(0.02, 0.015, 0.01))
	draw_rect(Rect2(0, size.y - 92, size.x, 92), Color(0.02, 0.015, 0.01))
	var a := clampf(_t / 0.7, 0.0, 1.0)
	if s.text != "":
		GodUI.text(self, Vector2(576, size.y - 46), s.text, 26, Color(GodUI.CREAM, a), true)
	if s.get("credits", false):
		var lines := ["A game by OPCV Games", "Built with the Indie Game Committee (Claude)", "Music: \"Roadside At Two\"  ·  Pixel art drawn with claude-pxl"]
		for i in lines.size():
			GodUI.text(self, Vector2(576, 372 + i * 30), lines[i], 18, Color(GodUI.CREAM, a * 0.9), true, 4)
	GodUI.text(self, Vector2(1130 - GodUI.font().get_string_size("ESC skip", HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x, 34),
		"ENTER" if on_last() else "ESC skip", 13, Color(1, 1, 1, 0.4))


## A golden sky, clouds parting, god rays, and (in some shots) a golden nozzle coming down.
func _draw_heaven(s: Dictionary) -> void:
	var top := Color(0.98, 0.86, 0.55)
	var low := Color(0.72, 0.45, 0.25)
	for i in 24:
		var k := i / 24.0
		draw_rect(Rect2(0, size.y * k, size.x, size.y / 24.0 + 1), top.lerp(low, k))
	var centre := Vector2(576, 150)
	for i in 12:  # rays
		var ang := PI / 2.0 + (i - 5.5) * 0.17 + sin(_total * 0.5 + i) * 0.02
		var tip := centre + Vector2.from_angle(ang) * 900.0
		var side := Vector2.from_angle(ang + PI / 2) * 46.0
		draw_colored_polygon(PackedVector2Array([centre, tip + side, tip - side]), Color(1, 1, 0.85, 0.08))
	for i in 9:
		draw_circle(centre, 210.0 - i * 20.0, Color(1, 0.98, 0.85, 0.06))
	var part := clampf(_t / 2.5, 0.0, 1.0)  # the clouds part
	for i in 7:
		var y := 120.0 + i * 70.0
		var offset := 140.0 + part * 260.0 + i * 20.0
		for side in [-1.0, 1.0]:
			var cx: float = 576.0 + side * offset
			for j in 4:
				draw_circle(Vector2(cx + side * j * 60.0, y + sin(i + j) * 10.0), 70.0 - j * 8.0, Color(1, 0.97, 0.92, 0.85))
	if s.get("nozzle", false) and _nozzle:
		var drop := clampf(_t / 2.2, 0.0, 1.0)
		var pos := Vector2(576, lerpf(-120.0, 300.0, 1.0 - pow(1.0 - drop, 3.0)))
		for i in 6:
			draw_circle(pos, 120.0 - i * 16.0, Color(1, 0.9, 0.5, 0.06))
		draw_set_transform(pos, -0.3, Vector2(3.4, 3.4))
		draw_texture(_nozzle, -_nozzle.get_size() * 0.5, Color(1.0, 0.85, 0.35))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## GOD PUMP slams in: big chrome-gold letters, a shake, a flash.
func _draw_title() -> void:
	var k := clampf(_t / 0.35, 0.0, 1.0)
	var scale := lerpf(2.6, 1.0, k * k)
	var shake := Vector2(sin(_t * 80.0), cos(_t * 70.0)) * 8.0 * maxf(0.0, 1.0 - _t * 2.5)
	if _t < 0.25:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 0.9, 0.6 * (1.0 - _t / 0.25)))
	var f := GodUI.font()
	var title := "GOD PUMP"
	var fs := 130
	var w := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_set_transform(Vector2(576, 210) + shake, 0.0, Vector2(scale, scale))
	draw_string_outline(f, Vector2(-w * 0.5, 40), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 16, Color(0.4, 0.2, 0.03))
	draw_string(f, Vector2(-w * 0.5, 40), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.84, 0.3))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
