class_name NozzleBling
extends RefCounted
## The bling on the God Pump's nozzle (round 8, designer: "as if you were wearing a lot of rings and
## bracelets"). Every bling you own is a gold ring or bracelet on the handle; each one equipped shows as
## itself: fuzzy dice, the pine air freshener, the medal and the rabbit's foot dangle and swing when the
## nozzle moves, the hula girl and the bobblehead stand on top, the flames, chrome tip, coupons and
## receipt are painted or tucked onto it. A component: GodPump owns one for the day, the garage one
## for its preview. Serves: Advancement (what you earned, worn on the thing you use most).

## Points on the nozzle sprite (nozzle_idle's PNG pixels; assets/art/pixel/god_pump.px.js).
const HANDLE_A := Vector2(10, 37)
const HANDLE_B := Vector2(23, 17)
const HOSE_A := Vector2(2, 46)
const HOSE_B := Vector2(9, 38)
## Where each dangling bling hangs from, and how long its string is (sprite pixels).
const DANGLES := {
	"fuzzy_dice": [Vector2(24, 36), 7.0], "pine": [Vector2(35, 33), 6.0],
	"medal": [Vector2(19, 25), 5.0], "rabbit": [Vector2(8, 41), 5.0],
}
const OVERLAYS := {"flame_decal": "bling_flames", "chrome_tip": "bling_chrome", "coupons": "bling_coupons", "receipt": "bling_receipt"}
const GEMS := [Color(0.9, 0.15, 0.2), Color(0.2, 0.8, 0.4), Color(0.3, 0.5, 1.0), Color(0.95, 0.95, 1.0)]
const GOLD := Color(1.0, 0.8, 0.3)
const GOLD_DARK := Color(0.72, 0.5, 0.14)

var equipped: Array = []
var owned: Array = []
var _swing := {}  # id -> {a, w}: angle from hanging straight down, and its speed
var _bob := 0.0
var _bob_v := 0.0
var _t := 0.0
var _vel := Vector2.ZERO
var _prev := Vector2.ZERO
var _has_prev := false


## Moves with the nozzle: `at` is where the nozzle is (any space, as long as it's the same each frame).
func step(dt: float, at: Vector2) -> void:
	if dt <= 0.0:
		return
	_t += dt
	var vel := (at - _prev) / dt if _has_prev else Vector2.ZERO
	var acc := (vel - _vel) / dt
	_vel = vel
	_prev = at
	_has_prev = true
	acc = acc.limit_length(9000.0)
	for id in DANGLES:
		if not id in equipped:
			continue
		var s: Dictionary = _swing.get(id, {"a": 0.0, "w": 0.0})
		s.w += (-38.0 * sin(s.a) - acc.x * 0.006) * dt  # gravity back to hanging; lags behind a push
		s.w *= exp(-1.8 * dt)
		s.a = clampf(s.a + s.w * dt, -1.4, 1.4)
		_swing[id] = s
	_bob_v += (-220.0 * _bob - acc.y * 0.002 - acc.x * 0.001) * dt  # the bobblehead's spring
	_bob_v *= exp(-3.0 * dt)
	_bob = clampf(_bob + _bob_v * dt, -3.0, 3.0)


## Draws onto `ci` over a nozzle whose sprite's top-left is `origin`, at `scale` (2 in the day).
func draw(ci: CanvasItem, origin: Vector2, scale: float, tex: Callable) -> void:
	ci.draw_set_transform(origin, 0.0, Vector2(scale, scale))
	for id in OVERLAYS:
		if id in equipped:
			var o: Texture2D = tex.call(OVERLAYS[id])
			if o:
				ci.draw_texture(o, Vector2.ZERO)
	_draw_rings(ci)
	for id in DANGLES:
		if id in equipped:
			_draw_dangle(ci, id, tex)
	if "hula" in equipped:
		var hula: Texture2D = tex.call("bling_hula")
		if hula:
			var base := Vector2(28, 5)
			ci.draw_set_transform(origin + base * scale, sin(_t * 9.0) * 0.14, Vector2(scale, scale))
			ci.draw_texture(hula, Vector2(-hula.get_width() * 0.5, -hula.get_height()))
			ci.draw_set_transform(origin, 0.0, Vector2(scale, scale))
	if "bobblehead" in equipped:
		var body: Texture2D = tex.call("bling_bobble_body")
		var head: Texture2D = tex.call("bling_bobble_head")
		var base := Vector2(19, 15) if not "hula" in equipped else Vector2(17, 16)
		if body:
			ci.draw_texture(body, base - Vector2(body.get_width() * 0.5, body.get_height()))
		if head:
			ci.draw_texture(head, base + Vector2(-head.get_width() * 0.5, -body.get_height() - head.get_height() + 2 + _bob))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A gold band around the handle for every bling owned (bracelets round the hose past five).
func _draw_rings(ci: CanvasItem) -> void:
	var n := mini(owned.size(), 10)
	for i in n:
		var on_hose := i >= 5
		var a := HOSE_A if on_hose else HANDLE_A
		var b := HOSE_B if on_hose else HANDLE_B
		var k := (float(i % 5) + 0.6) / 5.4
		var p := a.lerp(b, k)
		var axis := (b - a).normalized()
		var perp := axis.orthogonal() * (3.0 if on_hose else 4.6)
		ci.draw_line(p - perp, p + perp, GOLD_DARK, 2.2)
		ci.draw_line(p - perp * 0.8 + axis * 0.35, p + perp * 0.5 + axis * 0.35, GOLD, 1.0)
		if i % 2 == 0:  # every other one is set with a stone
			ci.draw_circle(p - perp * 0.9, 0.9, GEMS[(i / 2) % GEMS.size()])
		if fmod(_t * 0.7 + i * 0.37, 2.0) < 0.12:  # a glint runs along them now and then
			ci.draw_circle(p + perp * 0.2, 0.8, Color(1, 1, 0.9))


func _draw_dangle(ci: CanvasItem, id: String, tex: Callable) -> void:
	var spec: Array = DANGLES[id]
	var anchor: Vector2 = spec[0]
	var a: float = _swing.get(id, {"a": 0.0}).a
	var end: Vector2 = anchor + Vector2(sin(a), cos(a)) * spec[1]
	ci.draw_line(anchor, end, Color(0.15, 0.13, 0.12), 0.6)
	if id == "fuzzy_dice":  # two dice on two strings
		var die: Texture2D = tex.call("bling_die")
		var end2: Vector2 = anchor + Vector2(sin(a * 1.2 + 0.25), cos(a * 1.2 + 0.25)) * (spec[1] + 3.0)
		ci.draw_line(anchor, end2, Color(0.15, 0.13, 0.12), 0.6)
		if die:
			ci.draw_texture(die, end - die.get_size() * Vector2(0.5, 0.1))
			ci.draw_texture(die, end2 - die.get_size() * Vector2(0.5, 0.1))
		return
	var t: Texture2D = tex.call({"pine": "bling_pine", "medal": "bling_medal", "rabbit": "bling_rabbit"}[id])
	if t:
		ci.draw_texture(t, end - t.get_size() * Vector2(0.5, 0.05))
