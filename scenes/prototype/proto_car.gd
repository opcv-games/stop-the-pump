class_name ProtoCar
extends Node2D
## A car in the god-pump prototype (#36), seen from above. It drives along the road; a customer turns
## into the lot and moves in a readable pattern until it is at least 80% full. When the stream leaves
## a car that is 80% full or more, it grades its fill, plays that grade's animation, pays (sale + a
## tip that grows toward 100%) and drives away. Gas poured on a full car overflows onto the ground.
## Patterns are learnable on purpose: spotting them is how you fill several cars in one sweep.
## Serves: Mastery (moving targets, juggling) and Comedy (the car's reaction).

enum Phase { ROAD, ENTERING, WANDER, CELEBRATE, LEAVING, GONE }

const SIZE := Vector2(58, 30)
const ROAD_SPEED := 230.0
const TURN_RATE := 3.4
const CELEBRATE_SECONDS := 1.1
## A car leaves once the stream moves off it at this share of its order or more.
const LEAVE_AT := 0.8
## Readable movement: circles the lot / drives back and forth along a row / parks, waits, moves on.
const PATTERNS := ["loop", "shuttle", "park"]
const PATTERN_SPEED := {"loop": 75.0, "shuttle": 95.0, "park": 110.0}

var phase := Phase.ROAD
var customer := false
var target := 0.0
var amount := 0.0
var spilled := 0.0
var tier := ""
var paid := 0.0
var tip := 0.0
var heading := 0.0
var moving := true
var pattern := "loop"
var color := Color(0.45, 0.55, 0.7)
## Pixel-art body from claude-pxl (assets/art/pixel), drawn at 2x. Null = the greybox shapes.
var sprite: Texture2D
## Which sprite stack the isometric view draws (#36): stack_<name>_0..7.
var stack := "blue"
var tiers: ScoreTiers
var anim_t := 0.0
var _route: Array[Vector2] = []
var _fill_wobble := 0.0
var _t := 0.0
# Pattern state.
var _centre := Vector2.ZERO
var _radii := Vector2.ZERO
var _theta := 0.0
var _dir := 1.0
var _ends: Array[Vector2] = []
var _leg := 0
var _wait := 0.0
var _goal := Vector2.ZERO


## Fuel lands on this car. What doesn't fit overflows; the caller spills it on the ground.
func receive(dollars: float) -> float:
	var take := minf(dollars, maxf(target - amount, 0.0))
	amount += take
	_fill_wobble = 1.0
	var overflow := dollars - take
	spilled += overflow
	return overflow


func accepts_fuel() -> bool:
	return phase == Phase.ENTERING or phase == Phase.WANDER


func fill() -> float:
	return clampf(amount / maxf(target, 0.01), 0.0, 1.0)


## The stream moved off (or was released). From 80% full the car settles and returns its grade.
func stream_left() -> String:
	if not accepts_fuel() or amount < target * LEAVE_AT - 0.0001:
		return ""
	var f := fill()
	if f >= 0.995:
		tier = ScoreTiers.SUPER_PERFECT if spilled <= 0.25 else ScoreTiers.PERFECT  # topped off / full
	elif f >= 0.95:
		tier = ScoreTiers.GOOD
	else:
		tier = ScoreTiers.OK
	phase = Phase.CELEBRATE
	anim_t = 0.0
	return tier


## What the grade says on screen.
static func grade_name(t: String) -> String:
	match t:
		ScoreTiers.SUPER_PERFECT:
			return "TOPPED OFF!"
		ScoreTiers.PERFECT:
			return "FULL"
		ScoreTiers.GOOD:
			return "ALMOST FULL"
	return "GOOD ENOUGH"


## Sends the car off the lot (round over, or after its celebration).
func leave(game: GodPump) -> void:
	phase = Phase.LEAVING
	_route = [game.EXIT, Vector2(game.EXIT.x + 60, game.ROAD_Y), Vector2(game.WIDTH + 120, game.ROAD_Y)]


## Sets up this car's movement pattern around the lot.
func start_pattern(game: GodPump) -> void:
	var lot := game.LOT
	match pattern:
		"loop":
			_centre = lot.get_center() + Vector2(game.rng.randf_range(-60, 60), game.rng.randf_range(-20, 20))
			_radii = Vector2(game.rng.randf_range(230, 360), game.rng.randf_range(110, 150))
			_dir = 1.0 if game.rng.randf() < 0.5 else -1.0
			var rel := (position - _centre) / _radii
			_theta = rel.angle()
		"shuttle":
			var y := game.rng.randf_range(lot.position.y + 80, lot.end.y - 60)
			_ends = [Vector2(lot.position.x + 90, y), Vector2(lot.end.x - 90, y)]
			_leg = 0 if position.x > lot.get_center().x else 1
		"park":
			_goal = game.random_lot_point()


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
				start_pattern(game)
		Phase.WANDER:
			if moving:
				_move_pattern(dt, game)
				position += game.separation(self) * dt  # cars nudge apart instead of stacking
		Phase.CELEBRATE:
			anim_t += dt
			if anim_t >= CELEBRATE_SECONDS:
				leave(game)
		Phase.LEAVING:
			if _drive_route(dt, 190.0):
				phase = Phase.GONE
	queue_redraw()


func _move_pattern(dt: float, game: GodPump) -> void:
	var speed: float = PATTERN_SPEED[pattern]
	match pattern:
		"loop":
			_theta += _dir * speed / ((_radii.x + _radii.y) * 0.5) * dt
			var ahead := _theta + _dir * 0.35
			_steer(_centre + Vector2(cos(ahead), sin(ahead)) * _radii, dt, speed)
		"shuttle":
			if _wait > 0.0:
				_wait -= dt
				return
			_steer(_ends[_leg], dt, speed)
			if position.distance_to(_ends[_leg]) < 20.0:
				_leg = 1 - _leg
				_wait = 0.5
		"park":
			if _wait > 0.0:
				_wait -= dt
				return
			_steer(_goal, dt, speed)
			if position.distance_to(_goal) < 16.0:
				_wait = game.rng.randf_range(1.8, 3.0)
				_goal = game.random_lot_point()


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

## The celebration and fill animation as offsets, shared by both views: how high the car is
## lifted, how far it has spun, and how it is squashed.
func anim_offsets() -> Dictionary:
	var lift := 0.0
	var spin := 0.0
	var squash := Vector2.ONE * (1.0 + 0.16 * fill())  # swells as it fills, like a piggy bank
	if _fill_wobble > 0.0:
		squash += Vector2(1, -1) * sin(_t * 32.0) * 0.05 * _fill_wobble
	if phase == Phase.CELEBRATE:
		var k := anim_t / CELEBRATE_SECONDS
		match tier:
			ScoreTiers.SUPER_PERFECT:
				lift = sin(k * PI) * 70.0
				spin = k * TAU
				squash *= 1.0 + 0.3 * sin(k * PI)
			ScoreTiers.PERFECT:
				lift = sin(k * PI) * 40.0
				spin = sin(k * PI) * PI * 0.5
			ScoreTiers.GOOD:
				lift = absf(sin(k * PI * 2.0)) * 16.0
			_:
				spin = sin(k * PI * 4.0) * 0.12
	return {"lift": lift, "spin": spin, "squash": squash}


func _draw() -> void:
	var anim := anim_offsets()
	var lift: float = anim.lift
	var spin: float = anim.spin
	var squash: Vector2 = anim.squash
	draw_set_transform(Vector2(0, 6), heading, squash * (1.0 - lift / 240.0))
	draw_rect(Rect2(-SIZE * 0.5, SIZE), Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2(0, -lift), heading + spin, squash)
	if sprite:
		draw_set_transform(Vector2(0, -lift), heading + spin, squash * 2.0)
		draw_texture(sprite, -sprite.get_size() * 0.5)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if customer and accepts_fuel():
			draw_meter_at(self, Vector2(0, -40 - lift))
		return
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
		draw_meter_at(self, Vector2(0, -40 - lift))


## Order and fill meter above the roof: an 80% notch (it can leave from there), green once past it,
## gold when full. Never rotated.
func draw_meter_at(ci: CanvasItem, at: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var text := "$%.0f" % target
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 14
	var tag := StyleBoxFlat.new()
	tag.bg_color = Color(0.1, 0.09, 0.08, 0.92)
	tag.set_corner_radius_all(8)
	ci.draw_style_box(tag, Rect2(at - Vector2(w * 0.5, 12), Vector2(w, 22)))
	ci.draw_string(font, at + Vector2(-w * 0.5 + 7, 5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	var bar := Rect2(at + Vector2(-30, 13), Vector2(60, 8))
	ci.draw_rect(bar, Color(0.1, 0.09, 0.08, 0.9))
	var f := fill()
	var col := Color(0.95, 0.55, 0.15)
	if f >= 0.995:
		col = Color(1.0, 0.85, 0.25)
	elif f >= LEAVE_AT:
		col = Color(0.4, 0.9, 0.45)
	ci.draw_rect(Rect2(bar.position, Vector2(bar.size.x * f, bar.size.y)), col)
	ci.draw_rect(Rect2(bar.position + Vector2(bar.size.x * LEAVE_AT - 1, -2), Vector2(2, bar.size.y + 4)), Color.WHITE)
	if amount > 0.0:
		var pct := "%d%%" % int(f * 100.0)  # beside the meter, clear of the car
		ci.draw_string_outline(font, at + Vector2(34, 22), pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.8))
		ci.draw_string(font, at + Vector2(34, 22), pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(col, 0.95))
