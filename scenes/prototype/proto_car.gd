class_name ProtoCar
extends Node2D
## A car in the god-pump prototype (#36), seen from above. It drives along the road; a customer turns
## into the lot and drives around until it is filled to its order. You can only overfill: when the
## stream leaves a car that reached its order, the overshoot picks the tier, the car plays that tier's
## animation, pays, and drives away. Underfilled cars keep circling. Greybox: flat shapes only.
## Serves: Mastery (a moving target) and Comedy (the car's reaction).

enum Phase { ROAD, ENTERING, WANDER, CELEBRATE, LEAVING, GONE }

const SIZE := Vector2(58, 30)
const ROAD_SPEED := 230.0
const LOT_SPEED := 62.0
const TURN_RATE := 3.2
const CELEBRATE_SECONDS := 1.1

var phase := Phase.ROAD
var customer := false
var target := 0.0
var amount := 0.0
var tier := ""
var paid := 0.0
var heading := 0.0
var wander := true
var color := Color(0.45, 0.55, 0.7)
var tiers: ScoreTiers
var anim_t := 0.0
var _goal := Vector2.ZERO
var _route: Array[Vector2] = []
var _fill_wobble := 0.0
var _t := 0.0


## Called while the stream is on this car.
func receive(dollars: float) -> void:
	amount += dollars
	_fill_wobble = 1.0


func accepts_fuel() -> bool:
	return phase == Phase.ENTERING or phase == Phase.WANDER


## The stream moved off (or was released). Full cars settle and return their tier; others return "".
func stream_left() -> String:
	if not accepts_fuel() or amount < target - 0.0001:
		return ""
	tier = tiers.evaluate(amount, target)
	phase = Phase.CELEBRATE
	anim_t = 0.0
	return tier


## Sends the car off the lot (round over, or after its celebration).
func leave(game: GodPump) -> void:
	phase = Phase.LEAVING
	_route = [game.EXIT, Vector2(game.EXIT.x + 60, game.ROAD_Y), Vector2(game.WIDTH + 120, game.ROAD_Y)]


func fill_ratio() -> float:
	return clampf(amount / maxf(target, 0.01), 0.0, 1.4)


func step(dt: float, game: GodPump) -> void:
	_t += dt
	_fill_wobble = maxf(_fill_wobble - dt * 3.0, 0.0)
	match phase:
		Phase.ROAD:
			position.x += ROAD_SPEED * dt
			if customer and position.x >= game.ENTRANCE.x and game.lot_has_room():
				phase = Phase.ENTERING
				_route = [Vector2(game.ENTRANCE.x, game.LOT.position.y + 40)]
				game.customers_arrived += 1
			elif position.x > game.WIDTH + 100:
				phase = Phase.GONE
		Phase.ENTERING:
			if _drive_route(dt, 150.0):
				phase = Phase.WANDER
				_goal = game.random_lot_point()
		Phase.WANDER:
			if wander:
				_steer(_goal, dt, LOT_SPEED)
				position += game.separation(self) * dt
				if position.distance_to(_goal) < 30.0:
					_goal = game.random_lot_point()
		Phase.CELEBRATE:
			anim_t += dt
			if anim_t >= CELEBRATE_SECONDS:
				leave(game)
		Phase.LEAVING:
			var sputter := 0.0
			if tier == ScoreTiers.MISS:
				sputter = sin(_t * 18.0) * 0.6  # a Miss coughs and zigzags off
			heading += sputter * dt
			if _drive_route(dt, 190.0):
				phase = Phase.GONE
	queue_redraw()


## Follows _route; true when the last point is reached.
func _drive_route(dt: float, speed: float) -> bool:
	if _route.is_empty():
		return true
	_steer(_route[0], dt, speed)
	if position.distance_to(_route[0]) < 18.0:
		_route.pop_front()
	return _route.is_empty()


func _steer(goal: Vector2, dt: float, speed: float) -> void:
	var want := (goal - position).angle()
	heading = rotate_toward(heading, want, TURN_RATE * dt)
	position += Vector2.from_angle(heading) * speed * dt


# --- Drawing ------------------------------------------------------------------------------------

func _draw() -> void:
	var lift := 0.0
	var spin := 0.0
	var squash := Vector2.ONE * (1.0 + 0.16 * minf(fill_ratio(), 1.0))  # swells as it fills, like a piggy bank
	if _fill_wobble > 0.0:
		squash += Vector2(1, -1) * sin(_t * 32.0) * 0.05 * _fill_wobble
	if phase == Phase.CELEBRATE:
		var k := anim_t / CELEBRATE_SECONDS
		match tier:
			ScoreTiers.SUPER_PERFECT:
				lift = sin(k * PI) * 60.0
				spin = k * TAU
				squash *= 1.0 + 0.25 * sin(k * PI)
			ScoreTiers.PERFECT:
				lift = sin(k * PI) * 34.0
				spin = sin(k * PI) * PI * 0.5
			ScoreTiers.GOOD:
				lift = absf(sin(k * PI * 2.0)) * 14.0
			ScoreTiers.OK:
				spin = sin(k * PI * 4.0) * 0.12
			ScoreTiers.MISS:
				squash *= Vector2(1.0 + 0.12 * sin(k * PI * 6.0), 1.0 - 0.12 * sin(k * PI * 6.0))
	# Shadow stays on the ground; the body rises above it.
	draw_set_transform(Vector2(0, 6), heading, squash * (1.0 - lift / 240.0))
	draw_rect(Rect2(-SIZE * 0.5, SIZE), Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2(0, -lift), heading + spin, squash)
	var body := StyleBoxFlat.new()
	body.bg_color = color
	body.set_corner_radius_all(9)
	draw_style_box(body, Rect2(-SIZE * 0.5, SIZE))
	var roof := StyleBoxFlat.new()
	roof.bg_color = color.darkened(0.25)
	roof.set_corner_radius_all(6)
	draw_style_box(roof, Rect2(Vector2(-10, -11), Vector2(24, 22)))
	draw_rect(Rect2(Vector2(14, -10), Vector2(6, 20)), Color(0.75, 0.85, 0.95))  # windshield
	for w in [Vector2(-18, -16), Vector2(14, -16), Vector2(-18, 13), Vector2(14, 13)]:
		draw_rect(Rect2(w, Vector2(10, 4)), Color(0.08, 0.08, 0.08))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if customer and accepts_fuel():
		_draw_order(lift)


## The order and the meter float above the roof, never rotated.
func _draw_order(lift: float) -> void:
	var font := ThemeDB.fallback_font
	var at := Vector2(0, -40 - lift)
	var text := "$%.0f" % target
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 14
	var tag := StyleBoxFlat.new()
	tag.bg_color = Color(0.1, 0.09, 0.08, 0.92)
	tag.set_corner_radius_all(8)
	draw_style_box(tag, Rect2(at - Vector2(w * 0.5, 12), Vector2(w, 22)))
	draw_string(font, at + Vector2(-w * 0.5 + 7, 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	var bar := Rect2(at + Vector2(-26, 13), Vector2(52, 7))
	draw_rect(bar, Color(0.1, 0.09, 0.08, 0.9))
	var r := minf(amount / target, 1.0)
	var near := target - amount <= 1.0
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * r, bar.size.y)), Color(1.0, 0.8, 0.25) if near else Color(0.95, 0.6, 0.15))
	if amount > 0.0:
		var dollars := "$%.2f" % amount
		var dw := font.get_string_size(dollars, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, at + Vector2(-dw * 0.5, 34), dollars, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.85))
