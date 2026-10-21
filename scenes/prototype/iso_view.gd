class_name IsoView
extends Node2D
## The god pump's scene view (#36): a high-angle, three-quarter top-down camera (the designer's ask
## after the isometric try). The simulation stays top-down; this view draws it with the ground
## foreshortened and things standing up, into a half-resolution SubViewport doubled on screen, so
## everything lands on one crisp pixel grid. Cars are sprite stacks (8 slices a pixel apart, turned
## to the heading). At the back: the dépanneur from the reference
## photos, with its glass front and shelves, a clock and an OUVERT/FERMÉ sign, a red curb, the GAZ BAR
## neon on the roof (it flashes like a pinball machine on Good or better), and the regulars on their
## bench. Serves: Immersion (the gaz bar is alive) and readability.

const WALL := Color(0.85, 0.79, 0.64)
const WALL_SHADE := Color(0.70, 0.64, 0.50)
const GLASS := Color(0.22, 0.27, 0.32)
const ALU := Color(0.78, 0.80, 0.82)
const CURB := Color(0.75, 0.22, 0.18)
const ROOF := Color(0.30, 0.29, 0.30)
## The store in world coordinates (between the road and the lot, left of the entrance), and its
## height in viewport pixels.
const STORE := Rect2(16, 100, 262, 66)
const STORE_H := 40.0
## The bench and the regulars, in world coordinates (in front of the store).
const BENCH := Vector2(60, 186)
const SEAT_GAP := 38.0

var game: GodPump


func _draw() -> void:
	if not game:
		return
	draw_rect(Rect2(Vector2.ZERO, GodPump.ISO_VIEWPORT), Color(0.16, 0.13, 0.10))
	_draw_ground()
	var order := game.cars.duplicate()
	order.sort_custom(func(a: ProtoCar, b: ProtoCar) -> bool: return a.position.y < b.position.y)
	for car in order:  # cars on the road pass behind the store
		if car.position.y < STORE.end.y:
			_draw_car(car)
	_draw_store()
	_draw_regulars()
	for car in order:
		if car.position.y >= STORE.end.y:
			_draw_car(car)


## World point on the ground, raised by `h` viewport pixels.
func _p(x: float, y: float, h := 0.0) -> Vector2:
	return game.iso_xf * Vector2(x, y) - Vector2(0, h)


## Where regular `i`'s head is on screen (for speech bubbles).
func seat_screen(i: int) -> Vector2:
	return (_p(BENCH.x, BENCH.y) + Vector2(4 + i * SEAT_GAP * 0.5 + 9, -26)) * 2.0


func _draw_ground() -> void:
	draw_set_transform_matrix(game.iso_xf)
	_tile("dirt", Rect2(-100, -100, 1400, 900))
	draw_rect(Rect2(-100, GodPump.ROAD_Y - 34, 1400, 68), Color(0.12, 0.12, 0.13))
	_tile("road", Rect2(-100, GodPump.ROAD_Y - 32, 1400, 64))
	var lot := GodPump.LOT
	draw_rect(lot, Color(0.21, 0.20, 0.20))
	_tile("asphalt", lot.grow(-6))
	for x in [GodPump.ENTRANCE.x, GodPump.EXIT.x]:
		draw_rect(Rect2(x - 40, GodPump.ROAD_Y + 30, 80, lot.position.y - GodPump.ROAD_Y - 20), Color(0.21, 0.20, 0.20))
	for i in 9:
		draw_rect(Rect2(lot.position.x + 70 + i * 98, lot.end.y - 70, 4, 60), Color(1, 1, 1, 0.16))
	for p in game.puddles:
		var id := "puddle_s" if p.r < 13.0 else ("puddle_m" if p.r < 28.0 else "puddle_l")
		var tex: Texture2D = game.tex(id)
		if tex:
			var k: float = 2.8 * clampf(p.r / (tex.get_width() * 0.9), 1.0, 1.8)  # big enough to read as gas on the ground
			draw_set_transform_matrix(game.iso_xf * Transform2D(0.0, Vector2(k, k), 0.0, p.pos))
			draw_texture(tex, -tex.get_size() * 0.5)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _tile(id: String, r: Rect2) -> void:
	var tex: Texture2D = game.tex(id)
	if tex:
		draw_set_transform_matrix(game.iso_xf * Transform2D(0.0, Vector2(2, 2), 0.0, r.position))
		draw_texture_rect(tex, Rect2(Vector2.ZERO, r.size * 0.5), true)
		draw_set_transform_matrix(game.iso_xf)


## The dépanneur seen from the front: roof, cream wall, an aluminium glass front with shelves of oil
## and chips, the door with its OUVERT/FERMÉ sign, a clock, the red curb, and the neon on top.
func _draw_store() -> void:
	var r := STORE
	var x0 := r.position.x
	var x1 := r.end.x
	var y0 := r.position.y
	var y1 := r.end.y
	draw_colored_polygon(PackedVector2Array([_p(x0, y0, STORE_H), _p(x1, y0, STORE_H), _p(x1, y1, STORE_H), _p(x0, y1, STORE_H)]), ROOF)
	draw_line(_p(x0, y1, STORE_H), _p(x1, y1, STORE_H), Color(0.45, 0.43, 0.44), 2.0)
	var wall := Rect2(_p(x0, y1, STORE_H), _p(x1, y1) - _p(x0, y1, STORE_H))
	draw_rect(wall, WALL)
	draw_rect(Rect2(wall.position.x, wall.end.y - 3, wall.size.x, 3), WALL_SHADE)
	draw_rect(Rect2(_p(x0 - 4, y1 + 2), Vector2(wall.size.x + 4, 4)), CURB)  # the red curb
	# Glass front with shelves.
	var glass := Rect2(wall.position + Vector2(10, 9), Vector2(wall.size.x * 0.62, wall.size.y - 14))
	draw_rect(glass, GLASS)
	var colours := [Color(0.85, 0.3, 0.2), Color(0.9, 0.75, 0.3), Color(0.3, 0.5, 0.75), Color(0.85, 0.85, 0.8), Color(0.4, 0.7, 0.35)]
	for shelf in 3:
		var y := glass.position.y + 6 + shelf * 8
		draw_line(Vector2(glass.position.x + 1, y + 3), Vector2(glass.end.x - 1, y + 3), Color(0.55, 0.45, 0.30), 1.0)
		var x := glass.position.x + 3
		var i := shelf
		while x < glass.end.x - 3:
			draw_rect(Rect2(x, y, 2, 3), colours[i % colours.size()])
			x += 4
			i += 1
	var m := glass.position.x
	while m <= glass.end.x + 0.5:
		draw_line(Vector2(m, glass.position.y), Vector2(m, glass.end.y), ALU, 1.0)
		m += glass.size.x / 4.0
	draw_rect(glass, ALU, false, 1.0)
	# The door, with the sign hanging in it (it flips when the store opens or closes).
	var door := Rect2(Vector2(glass.end.x + 8, wall.position.y + 9), Vector2(18, wall.size.y - 12))
	draw_rect(door, GLASS)
	draw_rect(door, ALU, false, 1.0)
	var sign_tex: Texture2D = game.tex("sign_ouvert" if game.is_open() else "sign_ferme")
	if sign_tex:
		var flip := clampf(absf(cos(game.sign_flip * PI)), 0.15, 1.0)
		draw_set_transform(door.get_center() - Vector2(0, 3), 0.0, Vector2(flip * 0.62, 0.62))
		draw_texture(sign_tex, -sign_tex.get_size() * 0.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_clock(Vector2(door.end.x + 16, wall.position.y + 14))
	_draw_neon(Vector2(wall.get_center().x, wall.position.y - 6))


## The store clock: 7 h when the round opens, 13 h at the safeguard.
func _draw_clock(c: Vector2) -> void:
	var tex: Texture2D = game.tex("clock_face")
	if tex:
		draw_texture(tex, c - tex.get_size() * 0.5)
	var h := game.hour_now()
	var hour_a := (fmod(h, 12.0) / 12.0) * TAU - PI / 2.0
	var min_a := (fmod(h, 1.0)) * TAU - PI / 2.0
	draw_line(c, c + Vector2.from_angle(hour_a) * 3.0, Color(0.1, 0.1, 0.1), 1.0)
	draw_line(c, c + Vector2.from_angle(min_a) * 5.0, Color(0.1, 0.1, 0.1), 1.0)


## The GAZ BAR neon: a soft glow and a red pool on the asphalt; a tired flicker now and then; and on
## Good or better it flashes like a pinball machine (Super: a chase between GAZ and BAR).
func _draw_neon(bottom: Vector2) -> void:
	var t := game._t
	var phase := fmod(t, 7.0)
	var id := "neon_gazbar"
	if (phase > 3.1 and phase < 3.22) or (phase > 3.34 and phase < 3.42):
		id = "neon_gazbar_off"
	var glow := 1.0
	if game.neon_flash > 0.0:
		var beat := int(game.neon_flash * (16.0 if game.neon_tier == ScoreTiers.SUPER_PERFECT else 10.0))
		match game.neon_tier:
			ScoreTiers.SUPER_PERFECT:
				id = ["neon_gazbar", "neon_gaz", "neon_bar", "neon_gazbar_off"][beat % 4]
			_:
				id = "neon_gazbar" if beat % 2 == 0 else "neon_gazbar_off"
		glow = 2.4 if game.neon_tier == ScoreTiers.SUPER_PERFECT else 1.7
	var tex: Texture2D = game.tex(id)
	if not tex:
		return
	var at := bottom - Vector2(tex.get_width() * 0.5, tex.get_height() + 10)
	var centre := at + tex.get_size() * 0.5
	if id != "neon_gazbar_off":
		var pool := _p(STORE.get_center().x, STORE.end.y + 40)
		draw_set_transform(pool, 0.0, Vector2(1.0, 0.45))
		for i in 5:
			draw_circle(Vector2.ZERO, (60.0 - i * 10.0) * glow, Color(1.0, 0.25, 0.2, 0.03 * glow))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for i in 6:
			draw_circle(centre, (28.0 - i * 4.0) * glow, Color(1.0, 0.3, 0.22, 0.05 * glow))
	draw_line(at + Vector2(8, tex.get_height()), at + Vector2(8, tex.get_height() + 10), Color(0.2, 0.2, 0.22), 1.0)
	draw_line(at + Vector2(22, tex.get_height()), at + Vector2(22, tex.get_height() + 10), Color(0.2, 0.2, 0.22), 1.0)
	draw_texture(tex, at)


## The regulars on their bench: a slow bob while they hang out; arms up when one of them cheers.
func _draw_regulars() -> void:
	var bench: Texture2D = game.tex("bench")
	var base := _p(BENCH.x, BENCH.y)
	if bench:
		draw_texture(bench, base - Vector2(0, 8))
	for r in game.regulars:
		var tex: Texture2D = game.tex(r.sprite + ("_cheer" if r.cheer > 0.0 else ""))
		if not tex:
			continue
		var bob := 1.0 if sin(game._t * 1.3 + r.bob) > 0.85 else 0.0
		var hop := 3.0 * absf(sin(r.cheer * 12.0)) if r.cheer > 0.0 else 0.0
		draw_texture(tex, base + Vector2(4 + r.seat * SEAT_GAP * 0.5, -tex.get_height() + 2 - bob - hop))


## A sprite-stacked car with its shadow; celebrations lift, spin and squash it.
func _draw_car(car: ProtoCar) -> void:
	if car.phase == ProtoCar.Phase.GONE:
		return
	var anim := car.anim_offsets()
	var lift: float = anim.lift * 0.4
	var base := game.iso_xf * car.position
	draw_set_transform_matrix(game.iso_xf * Transform2D(car.heading, Vector2(2, 2), 0.0, car.position))
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
