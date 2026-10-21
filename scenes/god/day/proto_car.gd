class_name ProtoCar
extends Node2D
## A car in the god-pump prototype (#36), seen from above. It drives along the road; a customer turns
## into the lot and moves in a readable pattern until it is at least 80% full. When the stream leaves
## a car that is 80% full or more, it grades its fill, plays that grade's animation, pays (sale + a
## tip that grows toward 100%) and drives away. Gas poured on a full car overflows onto the ground.
## Patterns are learnable on purpose: spotting them is how you fill several cars in one sweep.
## Serves: Mastery (moving targets, juggling) and Comedy (the car's reaction).

enum Phase { ROAD, ENTERING, WANDER, CELEBRATE, LEAVING, GONE, GRABBED }

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
## +1 eastbound (may pull in), -1 westbound (drives by).
var road_dir := 1.0
var moving := true
var pattern := "loop"
var color := Color(0.45, 0.55, 0.7)
## Pixel-art body from claude-pxl (assets/art/pixel), drawn at 2x. Null = the greybox shapes.
var sprite: Texture2D
## Which sprite stack the isometric view draws (#36): stack_<name>_0..7.
var stack := "blue"
var tiers: ScoreTiers
var anim_t := 0.0
## Car type (GodData.CAR_TYPES): its role and rules.
var type_id := "sedan"
var role := ""  # "", "sweeper", "thief", "electric", "clumsy"
var fill_speed := 1.0  # how fast its tank takes fuel
var pay_share := 1.0  # share of the sale it pays (the pickup haggles)
var tip_mult := 1.0
var speed_mult := 1.0
## Seconds spent waiting in the lot; past its patience it drives off (a Miss).
var waited := 0.0
var patience := 24.0
var drone_target := false  # a drone has claimed it
var wants_in := false  # on the road: will pull in (customers and troublemakers)
var by_drone := false  # filled by a drone
# Role state.
var role_t := 0.0
var victim: ProtoCar
var stolen := 0.0
var bump_cool := 0.0
var angry := false
# The tube man's grab (round 8): up into his arms, held while he siphons it, then put down.
const GRAB_UP := 0.7
const GRAB_HOLD := 1.0
const GRAB_DOWN := 0.6
const GRAB_HIGH := 110.0
var grab_t := 0.0
var grab_lift := 0.0
var _grab_from := Vector2.ZERO
var _grab_to := Vector2.ZERO
var _grab_to_lot := false
var _siphoned := false
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
	var take := minf(dollars, maxf(target - amount, 0.0))  # (GodPump already scales by fill_speed)
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
	tier = grade(fill(), spilled)
	phase = Phase.CELEBRATE
	anim_t = 0.0
	return tier


## The grade for a fill (GOD PUMP plan): an overfill (a spill over $0.25) is a Miss; then Topped off
## (99.5%+), Perfect (97%+), Good (90%+), OK (80%+).
static func grade(f: float, spill: float) -> String:
	if spill > 0.25:
		return ScoreTiers.MISS
	if f >= 0.995:
		return ScoreTiers.SUPER_PERFECT
	if f >= 0.97:
		return ScoreTiers.PERFECT
	if f >= 0.90:
		return ScoreTiers.GOOD
	return ScoreTiers.OK


## How close the fill came, from 0 to 1 (an overfill counts against it): the day report's accuracy.
func accuracy() -> float:
	return clampf(1.0 - absf(amount + spilled - target) / maxf(target, 0.01), 0.0, 1.0)


## What the grade says on screen.
static func grade_name(t: String) -> String:
	match t:
		ScoreTiers.SUPER_PERFECT:
			return "TOPPED OFF!"
		ScoreTiers.PERFECT:
			return "PERFECT!"
		ScoreTiers.GOOD:
			return "GOOD"
		ScoreTiers.MISS:
			return "OVERFILLED!"
	return "OK"


## Sends the car off the lot (round over, or after its celebration).
func leave(game: GodPump) -> void:
	phase = Phase.LEAVING
	_route = [game.EXIT, Vector2(game.EXIT.x + 60, game.ROAD_Y), Vector2(game.WIDTH + 120, game.ROAD_Y)]


## Applies a car type's rules (GodData.CAR_TYPES).
func set_type(id: String, rng: RandomNumberGenerator) -> void:
	var t: Dictionary = GodData.CAR_TYPES.get(id, GodData.CAR_TYPES.sedan)
	type_id = id
	role = t.get("role", "")
	customer = t.get("customer", true)
	fill_speed = t.get("fill_speed", 1.0)
	pay_share = t.get("pay", 1.0)
	tip_mult = t.get("tip", 1.0)
	speed_mult = t.get("speed", 1.0)
	var orders: Array = t.get("orders", [20.0])
	target = orders[rng.randi() % orders.size()]
	if id != "sedan":
		stack = t.get("stack", id)


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
			position.x += ROAD_SPEED * dt * road_dir
			if road_dir < 0.0 and position.x < -100:
				phase = Phase.GONE
			elif (customer or wants_in) and position.x >= game.ENTRANCE.x and game.lot_has_room():
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
				# Fast cars (the racer) overshoot their turns: the curb keeps everyone on the lot.
				position = position.clamp(game.LOT.position + Vector2(24, 20), game.LOT.end - Vector2(24, 20))
		Phase.CELEBRATE:
			anim_t += dt
			if anim_t >= CELEBRATE_SECONDS:
				leave(game)
		Phase.LEAVING:
			if _drive_route(dt, 190.0):
				phase = Phase.GONE
		Phase.GRABBED:
			_step_grab(dt, game)
	queue_redraw()


## The tube man has it (round 8): lifted off the road into his arms, held while he siphons it, then
## set down further along the road (tier 1) or on the lot (tier 2, where it becomes a customer).
func grab(game: GodPump, to_lot: bool) -> void:
	phase = Phase.GRABBED
	grab_t = 0.0
	_grab_from = position
	_grab_to_lot = to_lot and game.lot_has_room()
	_grab_to = game.random_lot_point() if _grab_to_lot else Vector2(position.x + road_dir * 80.0, position.y)
	_siphoned = false
	wants_in = false


func _step_grab(dt: float, game: GodPump) -> void:
	grab_t += dt
	var hold: Vector2 = game.TUBE_AT + Vector2(0, 4)
	if grab_t < GRAB_UP:
		var k := grab_t / GRAB_UP
		position = _grab_from.lerp(hold, k * k * (3.0 - 2.0 * k))
		grab_lift = sin(k * PI * 0.5) * GRAB_HIGH
	elif grab_t < GRAB_UP + GRAB_HOLD:
		position = hold
		grab_lift = GRAB_HIGH + sin(_t * 9.0) * 6.0
		if not _siphoned:
			_siphoned = true
			game.tube_siphon(self)
	elif grab_t < GRAB_UP + GRAB_HOLD + GRAB_DOWN:
		var k := (grab_t - GRAB_UP - GRAB_HOLD) / GRAB_DOWN
		position = hold.lerp(_grab_to, k)
		grab_lift = GRAB_HIGH * (1.0 - k * k)
	else:
		grab_lift = 0.0
		position = _grab_to
		if _grab_to_lot:
			game.tube_drop(self)
		else:
			phase = Phase.ROAD
			heading = 0.0 if road_dir > 0.0 else PI


func _move_pattern(dt: float, game: GodPump) -> void:
	var speed: float = PATTERN_SPEED[pattern] * speed_mult
	if role == "clumsy":
		heading += sin(_t * 7.0) * 1.2 * dt  # can't drive straight
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
	if phase == Phase.GRABBED:
		lift = grab_lift
		spin = sin(grab_t * 6.0) * 0.4  # dangling
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
## Drawn on every car by the god pump (#36): a dial gauge from empty to full.
static var gauge_tex: Texture2D


## The order and a dial gauge above the roof (designer's ask: a fuel gauge, not a bar). The needle
## sweeps from E to F; the gauge's green ticks mark 80% and up, where the car can leave.
func draw_meter_at(ci: CanvasItem, at: Vector2) -> void:
	var font := ThemeDB.fallback_font
	var f := fill()
	var text := "$%.0f" % target
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 12
	var tag := StyleBoxFlat.new()
	tag.bg_color = Color(0.1, 0.09, 0.08, 0.92)
	tag.set_corner_radius_all(8)
	ci.draw_style_box(tag, Rect2(at + Vector2(-w * 0.5, -30), Vector2(w, 20)))
	ci.draw_string(font, at + Vector2(-w * 0.5 + 6, -15), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
	var centre := at + Vector2(0, 18)
	if gauge_tex:
		var size := gauge_tex.get_size() * 2.0
		ci.draw_texture_rect(gauge_tex, Rect2(centre - Vector2(size.x * 0.5, size.y - 2), size), false)
	var a := PI * (1.0 - f)
	var col := Color(0.15, 0.1, 0.1) if f < LEAVE_AT else (Color(0.1, 0.55, 0.2) if f < 0.995 else Color(0.85, 0.6, 0.05))
	ci.draw_line(centre, centre + Vector2(cos(a), -sin(a)) * 19.0, col, 2.0, true)
	ci.draw_circle(centre, 2.5, Color(0.1, 0.1, 0.1))
