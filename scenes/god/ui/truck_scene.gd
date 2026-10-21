class_name TruckScene
extends Control
## The delivery (round 8): when you call the truck, a cinematic strip across the night screen shows it.
## The tanker rolls in, its hose arcs onto the station's tank, gas flows while the tank's sight glass
## and dial climb and the price per litre ticks up, then the truck pulls away and the cards come.
## About 4 seconds; a click or a key skips it. Serves: Advancement (the bill you chose, made physical)
## and tension (the price rise is spelled out every time).

signal finished

const SCALE := 3.0
const DRIVE_IN := 1.2
const HOSE_OUT := 0.3
const FLOW := 1.4
const HOSE_IN := 0.25
const DRIVE_OUT := 0.9
const BAND := Rect2(0, 118, 1152, 412)
const GROUND_Y := 466.0
## Points in the sprites (PNG pixels, outline included): see assets/art/pixel/station.px.js.
const TRUCK_SIZE := Vector2(134, 52)
const TRUCK_WHEELS := [Vector2(12, 45), Vector2(24, 45), Vector2(71, 45), Vector2(111, 45)]
const TRUCK_VALVE := Vector2(46, 39)
const TRUCK_STACK := Vector2(94, 1)
const TANK_SIZE := Vector2(88, 58)
const TANK_PIPE := Vector2(25, 2)
const TANK_DIAL := Vector2(13, 25)
const TANK_GLASS := Rect2(63, 11, 3, 27)
const TANK_AT := Vector2(760, GROUND_Y - 58 * 3.0)
const TRUCK_STOP_X := 210.0

var info := {}
var sound_on := true
var t := 0.0
var _puffs: Array = []
var _sfx := {}
var _done := false


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


static func duration() -> float:
	return DRIVE_IN + HOSE_OUT + FLOW + HOSE_IN + DRIVE_OUT


## info: tank_from, tank_to, capacity (pump dollars), cost, price_from, price_to, cards (bool).
func play(the_info: Dictionary) -> void:
	info = the_info
	t = 0.0
	_done = false
	_puffs.clear()
	visible = true
	_sound("truck", "res://assets/audio/placeholder/truck.wav")
	queue_redraw()


func skip() -> void:
	if visible and not _done:
		_finish()


func _finish() -> void:
	_done = true
	visible = false
	if _sfx.has("glug"):
		_sfx.glug.stop()
	finished.emit()


func _sound(id: String, path: String, loop := false) -> void:
	if not sound_on or not ResourceLoader.exists(path):
		return
	if not _sfx.has(id):
		var p := AudioStreamPlayer.new()
		p.stream = load(path)
		p.volume_db = -6.0
		if loop:
			p.finished.connect(p.play)
		add_child(p)
		_sfx[id] = p
	_sfx[id].play()


func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		accept_event()
		skip()


func _unhandled_input(e: InputEvent) -> void:
	if visible and e is InputEventKey and e.pressed and not e.echo:
		get_viewport().set_input_as_handled()
		skip()


func _process(dt: float) -> void:
	if not visible or _done:
		return
	var before := t
	t += dt
	var flow_at := DRIVE_IN + HOSE_OUT
	if before < flow_at and t >= flow_at:
		_sound("glug", "res://assets/audio/placeholder/glug_loop.wav", true)
	if before < flow_at + FLOW and t >= flow_at + FLOW:
		if _sfx.has("glug"):
			_sfx.glug.stop()
		_sound("cash", "res://assets/audio/placeholder/cash.wav")
	# Exhaust while the truck moves.
	if _moving() and fmod(t, 0.09) < dt:
		_puffs.append({"pos": truck_pos() + TRUCK_STACK * SCALE, "age": 0.0})
	for p in _puffs:
		p.age += dt
		p.pos += Vector2(-30.0, -38.0) * dt
	_puffs = _puffs.filter(func(p: Dictionary) -> bool: return p.age < 1.1)
	if t >= duration():
		_finish()
	queue_redraw()


func _moving() -> bool:
	return t < DRIVE_IN or t > DRIVE_IN + HOSE_OUT + FLOW + HOSE_IN


## Where the truck's top-left is now: easing in from off the left edge, parked, then off to the right.
func truck_pos() -> Vector2:
	var y := GROUND_Y - TRUCK_SIZE.y * SCALE
	var x := TRUCK_STOP_X
	if t < DRIVE_IN:
		var k := t / DRIVE_IN
		x = lerpf(-TRUCK_SIZE.x * SCALE - 20.0, TRUCK_STOP_X, 1.0 - pow(1.0 - k, 3.0))
	var leave_at := DRIVE_IN + HOSE_OUT + FLOW + HOSE_IN
	if t > leave_at:
		var k := clampf((t - leave_at) / DRIVE_OUT, 0.0, 1.0)
		x = lerpf(TRUCK_STOP_X, 1200.0, k * k)
	if _moving():
		y += sin(t * 40.0) * 1.0  # the road's little bumps
	return Vector2(x, y)


## How far the gas has gone: 0 before the hose locks on, 1 when the delivery is done.
func flow_k() -> float:
	return clampf((t - DRIVE_IN - HOSE_OUT) / FLOW, 0.0, 1.0)


## How far out the hose is: 0 stowed, 1 locked onto the tank.
func hose_k() -> float:
	var out_k := clampf((t - DRIVE_IN) / HOSE_OUT, 0.0, 1.0)
	var in_k := clampf((t - DRIVE_IN - HOSE_OUT - FLOW) / HOSE_IN, 0.0, 1.0)
	return out_k * (1.0 - in_k)


func tank_level() -> float:
	var cap: float = maxf(info.get("capacity", 1.0), 1.0)
	var k := flow_k()
	k = k * k * (3.0 - 2.0 * k)
	return lerpf(info.get("tank_from", 0.0), info.get("tank_to", 0.0), k) / cap


func _draw() -> void:
	if info.is_empty():
		return
	GodUI.dim(self, size, 0.55)
	# The yard at night: a deep sky, a tree line, the asphalt and a lamp's pool of light.
	for i in 14:
		var k := i / 13.0
		draw_rect(Rect2(BAND.position.x, BAND.position.y + i * 22.0, BAND.size.x, 22.0), Color(0.07, 0.07, 0.13).lerp(Color(0.2, 0.13, 0.12), k))
	var hills := PackedVector2Array([Vector2(0, GROUND_Y - 60)])
	for i in 25:
		hills.append(Vector2(i * 48.0, GROUND_Y - 70.0 - absf(sin(i * 1.7)) * 34.0 - (i % 3) * 8.0))
	hills.append(Vector2(1152, GROUND_Y - 60))
	hills.append(Vector2(1152, GROUND_Y))
	hills.append(Vector2(0, GROUND_Y))
	draw_colored_polygon(hills, Color(0.05, 0.06, 0.06))
	draw_rect(Rect2(0, GROUND_Y, 1152, BAND.end.y - GROUND_Y), Color(0.16, 0.15, 0.15))
	draw_rect(Rect2(0, GROUND_Y, 1152, 3), Color(0.25, 0.23, 0.22))
	for i in 6:
		draw_circle(Vector2(820, GROUND_Y + 8), 260.0 - i * 40.0, Color(1.0, 0.8, 0.45, 0.025))
	draw_rect(Rect2(BAND.position.x, BAND.position.y, BAND.size.x, 2), GodUI.GOLD_DIM)
	draw_rect(Rect2(BAND.position.x, BAND.end.y - 2, BAND.size.x, 2), GodUI.GOLD_DIM)
	_draw_tank()
	_draw_hose()
	_draw_truck()
	for p in _puffs:
		var a: float = 1.0 - p.age / 1.1
		draw_circle(p.pos, 6.0 + p.age * 14.0, Color(0.55, 0.55, 0.58, 0.35 * a))
	_draw_numbers()


func _draw_tank() -> void:
	var tex := GodUI.sprite("gas_tank")
	if tex:
		draw_texture_rect(tex, Rect2(TANK_AT, TANK_SIZE * SCALE), false)
	var level := clampf(tank_level(), 0.0, 1.0)
	GasTankArt.draw_level(self, TANK_AT, SCALE, level, t)


func _draw_hose() -> void:
	var k := hose_k()
	if k <= 0.0:
		return
	var from := truck_pos() + TRUCK_VALVE * SCALE
	var to := TANK_AT + TANK_PIPE * SCALE
	var pts := PackedVector2Array()
	var n := 28
	var reach := int(n * k)
	for i in reach + 1:
		var s := float(i) / n
		var p := from.lerp(to, s)
		p.y -= sin(s * PI) * 120.0 - s * s * 10.0  # it arcs up over the gap and drops onto the pipe
		pts.append(p)
	if pts.size() < 2:
		return
	draw_polyline(pts, Color(0.08, 0.08, 0.09), 9.0)
	draw_polyline(pts, Color(0.2, 0.2, 0.23), 5.0)
	# Gas running through it, while it flows.
	if flow_k() > 0.0 and flow_k() < 1.0:
		for i in range(pts.size() - 1):
			if int(i + t * 24.0) % 4 == 0:
				draw_line(pts[i], pts[i + 1], GodPump.GAS, 3.0)


func _draw_truck() -> void:
	var at := truck_pos()
	var tex := GodUI.sprite("fuel_truck")
	if tex:
		draw_texture_rect(tex, Rect2(at, TRUCK_SIZE * SCALE), false)
	var wheel := GodUI.sprite("truck_wheel")
	if wheel:
		var turn := at.x / (6.5 * SCALE)
		for w in TRUCK_WHEELS:
			var c: Vector2 = at + w * SCALE
			draw_set_transform(c, turn, Vector2.ONE)
			draw_texture_rect(wheel, Rect2(Vector2(-7.5, -7.5) * SCALE, Vector2(15, 15) * SCALE), false)
		draw_set_transform(Vector2.ZERO)


## The delivery's numbers, top left: what it cost, the gas it brought, the price per litre going up.
func _draw_numbers() -> void:
	var k := flow_k()
	var x := 40.0
	GodUI.text(self, Vector2(x, BAND.position.y + 50), tr("LA LIVRAISON"), 34, GodUI.GOLD, false, 6)
	var brought: float = (info.get("tank_to", 0.0) - info.get("tank_from", 0.0)) * k
	GodUI.text(self, Vector2(x, BAND.position.y + 86), tr("+ $%.0f of gas in the tank") % brought, 20, GodUI.CREAM, false, 4)
	GodUI.text(self, Vector2(x, BAND.position.y + 114), tr("Paid: $%.0f") % (info.get("cost", 0.0) * k), 20, GodUI.CREAM, false, 4)
	var p0: float = info.get("price_from", 0.0)
	var p1: float = info.get("price_to", 0.0)
	var shown := p0 if k < 1.0 else p1
	var line := tr("Price per litre: $%.2f") % shown
	GodUI.text(self, Vector2(x, BAND.position.y + 150), line, 20, GodUI.CREAM, false, 4)
	if k >= 1.0 and p1 > p0:
		var w := GodUI.font().get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		var pop := clampf((t - DRIVE_IN - HOSE_OUT - FLOW) / 0.25, 0.0, 1.0)
		GodUI.text(self, Vector2(x + w + 14, BAND.position.y + 150), "+%d%%" % roundi((p1 / p0 - 1.0) * 100.0), int(20 + 10 * (1.0 - pop)), GodUI.RED, false, 4)
	if not info.get("cards", true):
		GodUI.text(self, Vector2(x, BAND.position.y + 180), tr("A small delivery: no cards this time"), 15, Color(GodUI.CREAM, 0.7), false, 3)
	var hint := tr("click to skip")
	GodUI.text(self, Vector2(1140 - GodUI.font().get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x, BAND.end.y - 14), hint, 13, Color(1, 1, 1, 0.35))
