class_name IsoView
extends Node2D
## The isometric try for the god pump (#36). The simulation stays top-down (GodPump's world
## coordinates); this view only draws it through an isometric camera, inside a half-resolution
## SubViewport that is doubled on screen, so everything lands on one crisp pixel grid. Cars are
## sprite stacks: 8 top-down slices drawn a pixel apart, turned to the car's heading, which gives a
## solid 3D car at any angle from one claude-pxl drawing. Styled after the dépanneur reference:
## a cream-walled store with an aluminium glass front, shelves, and a red curb.
## Serves: Immersion and readability (cars read as cars from every side).

const WALL := Color(0.85, 0.79, 0.64)
const WALL_SHADE := Color(0.70, 0.64, 0.50)
const GLASS := Color(0.22, 0.27, 0.32)
const ALU := Color(0.78, 0.80, 0.82)
const CURB := Color(0.75, 0.22, 0.18)
const ROOF := Color(0.30, 0.29, 0.30)
## The store, in world coordinates (left of the lot), and its height in viewport pixels.
const STORE := Rect2(-10, 200, 118, 340)
const STORE_H := 26.0

var game: GodPump


func _draw() -> void:
	if not game:
		return
	draw_rect(Rect2(Vector2.ZERO, GodPump.ISO_VIEWPORT), Color(0.16, 0.13, 0.10))
	_draw_ground()
	_draw_store()
	var order := game.cars.duplicate()
	order.sort_custom(func(a: ProtoCar, b: ProtoCar) -> bool: return a.position.x + a.position.y < b.position.x + b.position.y)
	for car in order:
		_draw_car(car)


func _draw_ground() -> void:
	draw_set_transform_matrix(game.iso_xf)
	_tile("dirt", Rect2(-500, -400, 2200, 1500))
	draw_rect(Rect2(-500, GodPump.ROAD_Y - 34, 2200, 68), Color(0.12, 0.12, 0.13))
	_tile("road", Rect2(-500, GodPump.ROAD_Y - 32, 2200, 64))
	var lot := GodPump.LOT
	draw_rect(lot, Color(0.21, 0.20, 0.20))
	_tile("asphalt", lot.grow(-6))
	for x in [GodPump.ENTRANCE.x, GodPump.EXIT.x]:
		draw_rect(Rect2(x - 40, GodPump.ROAD_Y + 30, 80, lot.position.y - GodPump.ROAD_Y - 20), Color(0.21, 0.20, 0.20))
	for i in 9:
		draw_rect(Rect2(lot.position.x + 70 + i * 98, lot.end.y - 70, 4, 60), Color(1, 1, 1, 0.16))
	for p in game.puddles:
		var a := clampf(p.life / 3.0, 0.0, 1.0)
		var id := "puddle_s" if p.r < 13.0 else ("puddle_m" if p.r < 28.0 else "puddle_l")
		var tex: Texture2D = game.tex(id)
		if tex:
			var k: float = 2.0 * clampf(p.r / (tex.get_width() * 0.9), 0.6, 1.6)
			draw_set_transform_matrix(game.iso_xf * Transform2D(0.0, Vector2(k, k), 0.0, p.pos))
			draw_texture(tex, -tex.get_size() * 0.5, Color(1, 1, 1, a))
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _tile(id: String, r: Rect2) -> void:
	var tex: Texture2D = game.tex(id)
	if tex:
		draw_set_transform_matrix(game.iso_xf * Transform2D(0.0, Vector2(2, 2), 0.0, r.position))
		draw_texture_rect(tex, Rect2(Vector2.ZERO, r.size * 0.5), true)
		draw_set_transform_matrix(game.iso_xf)


## World point on the ground, raised by `h` viewport pixels.
func _p(x: float, y: float, h := 0.0) -> Vector2:
	return game.iso_xf * Vector2(x, y) - Vector2(0, h)


## The dépanneur: cream walls, an aluminium-framed glass front with shelves, a red curb.
func _draw_store() -> void:
	var r := STORE
	var x1 := r.end.x
	var y0 := r.position.y
	var y1 := r.end.y
	# Red curb along the front.
	draw_colored_polygon(PackedVector2Array([_p(x1, y0), _p(x1 + 8, y0), _p(x1 + 8, y1 + 8), _p(x1, y1 + 8)]), CURB)
	# Side wall (facing +y) and front wall (facing the lot, +x).
	draw_colored_polygon(PackedVector2Array([_p(r.position.x, y1), _p(x1, y1), _p(x1, y1, STORE_H), _p(r.position.x, y1, STORE_H)]), WALL_SHADE)
	draw_colored_polygon(PackedVector2Array([_p(x1, y0), _p(x1, y1), _p(x1, y1, STORE_H), _p(x1, y0, STORE_H)]), WALL)
	# The glass front: dark glass, shelves of oil cans, aluminium mullions.
	var g0 := STORE_H * 0.12
	var g1 := STORE_H * 0.72
	var gy0 := y0 + 30
	var gy1 := y1 - 40
	draw_colored_polygon(PackedVector2Array([_p(x1, gy0, g0), _p(x1, gy1, g0), _p(x1, gy1, g1), _p(x1, gy0, g1)]), GLASS)
	for shelf in [0.3, 0.5, 0.68]:
		var h := lerpf(g0, g1, shelf)
		draw_line(_p(x1, gy0 + 4, h), _p(x1, gy1 - 4, h), Color(0.55, 0.45, 0.30), 1.0)
		var y := gy0 + 8.0
		var i := 0
		while y < gy1 - 8:
			var col: Color = [Color(0.85, 0.3, 0.2), Color(0.9, 0.75, 0.3), Color(0.3, 0.5, 0.75), Color(0.85, 0.85, 0.8)][i % 4]
			draw_line(_p(x1, y, h), _p(x1, y, h + 2.0), col, 1.0)
			y += 9.0
			i += 1
	var m := gy0
	while m <= gy1:
		draw_line(_p(x1, m, g0), _p(x1, m, g1), ALU, 1.0)
		m += (gy1 - gy0) / 4.0
	draw_line(_p(x1, gy0, g1), _p(x1, gy1, g1), ALU, 1.0)
	draw_line(_p(x1, gy0, g0), _p(x1, gy1, g0), ALU, 1.0)
	# Flat roof with a lip.
	draw_colored_polygon(PackedVector2Array([_p(r.position.x, y0, STORE_H), _p(x1, y0, STORE_H), _p(x1, y1, STORE_H), _p(r.position.x, y1, STORE_H)]), ROOF)
	draw_polyline(PackedVector2Array([_p(r.position.x, y1, STORE_H), _p(x1, y1, STORE_H), _p(x1, y0, STORE_H)]), Color(0.45, 0.43, 0.44), 1.0)
	_draw_neon()


## The red GAZ BAR neon on the roof (designer's references): a soft glow, a red pool of light on the
## asphalt, and now and then the tired tube flickers.
func _draw_neon() -> void:
	var t := game._t
	var phase := fmod(t, 7.0)
	var lit := not ((phase > 3.1 and phase < 3.22) or (phase > 3.34 and phase < 3.42))
	var at := _p(STORE.end.x - 10, STORE.get_center().y, STORE_H) - Vector2(15, 34)
	var centre := at + Vector2(15, 13)
	if lit:
		var pool := _p(STORE.end.x + 70, STORE.get_center().y)
		draw_set_transform(pool, 0.0, Vector2(1.0, 0.5))
		for i in 5:
			draw_circle(Vector2.ZERO, 60.0 - i * 10.0, Color(1.0, 0.25, 0.2, 0.035))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for i in 6:
			draw_circle(centre, 30.0 - i * 4.0, Color(1.0, 0.3, 0.22, 0.05))
	draw_line(at + Vector2(8, 26), at + Vector2(8, 34), Color(0.2, 0.2, 0.22), 1.0)  # the sign's posts
	draw_line(at + Vector2(22, 26), at + Vector2(22, 34), Color(0.2, 0.2, 0.22), 1.0)
	var tex: Texture2D = game.tex("neon_gazbar" if lit else "neon_gazbar_off")
	if tex:
		draw_texture(tex, at)


## A sprite-stacked car with its shadow; celebrations lift, spin and squash the whole stack.
func _draw_car(car: ProtoCar) -> void:
	if car.phase == ProtoCar.Phase.GONE:
		return
	var anim := car.anim_offsets()
	var lift: float = anim.lift * 0.4
	var base := game.iso_xf * car.position
	var shadow := game.iso_xf * Transform2D(car.heading, Vector2(2, 2), 0.0, car.position)
	draw_set_transform_matrix(shadow)
	draw_rect(Rect2(-15, -8, 30, 16), Color(0, 0, 0, 0.3 * (1.0 - lift / 40.0)))
	var linear := game.iso_xf
	linear.origin = Vector2.ZERO
	for i in 8:
		var tex: Texture2D = game.tex("stack_%s_%d" % [car.stack, i])
		if not tex:
			continue
		var xf := Transform2D(0.0, base - Vector2(0, i + lift)) * linear * Transform2D(car.heading + anim.spin, Vector2(2, 2) * anim.squash, 0.0, Vector2.ZERO)
		draw_set_transform_matrix(xf)
		draw_texture(tex, -tex.get_size() * 0.5)
	draw_set_transform_matrix(Transform2D.IDENTITY)
