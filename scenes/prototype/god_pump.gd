class_name GodPump
extends Node2D
## God-pump prototype (#36): you are a giant nozzle above a top-down lot (Bills Must Be Paid's table,
## with a pump instead of a hammer). Hold the mouse to pour; the stream lands on whatever is below.
## Cars flow along the road; some pull in and drive around until filled. Filled cars score on their
## overshoot, celebrate by tier, burst into coins that fly to your cash, and drive off. Gas on the
## floor is wasted and pools in gold. After playtest 1: a car leaves once 80% full, the tip grows toward
## 100%, overflow spills, and the round lasts as long as its gas (the clock is only a safeguard).
## Greybox, separate from the real game: it
## reuses ScoreTiers, ComboComponent and FuelEconomy so the rules stay the game's.
## Serves: Mastery (aim + stop on the dollar, several cars at once) and Comedy.

const WIDTH := 1152.0
const HEIGHT := 648.0
const ROAD_Y := 78.0
const LOT := Rect2(120, 170, 912, 420)
const ENTRANCE := Vector2(300, ROAD_Y)
const EXIT := Vector2(900, 180)
const CASH_AT := Vector2(70, 26)
const NOZZLE_RAISE := Vector2(-20, -96)  # the nozzle hovers up-left of where its stream lands
const CAR_COLORS := [Color(0.45, 0.55, 0.7), Color(0.7, 0.42, 0.36), Color(0.5, 0.62, 0.45),
	Color(0.72, 0.66, 0.48), Color(0.55, 0.48, 0.66), Color(0.8, 0.8, 0.78)]
const COINS := {ScoreTiers.SUPER_PERFECT: 12, ScoreTiers.PERFECT: 8, ScoreTiers.GOOD: 5, ScoreTiers.OK: 3, ScoreTiers.MISS: 1}
const TIER_COLORS := {
	ScoreTiers.SUPER_PERFECT: Color(1.0, 0.85, 0.3), ScoreTiers.PERFECT: Color(0.35, 0.9, 0.45),
	ScoreTiers.GOOD: Color(0.6, 0.8, 1.0), ScoreTiers.OK: Color(0.95, 0.85, 0.4), ScoreTiers.MISS: Color(0.95, 0.35, 0.3),
}
const GAS := Color(0.98, 0.76, 0.18)

@export var flow_rate := 4.0
## A safeguard: the round's gas is what really ends it.
@export var round_seconds := 45.0
## Gas the round starts with, in pump dollars.
@export var tank_size := 75.0  # god-pump playtest 2: $150 took too long
## Tip at 100% full; a top-off without spilling adds the bonus.
@export var max_tip := 6.0
@export var topoff_bonus := 2.0
@export var customer_chance := 0.5
@export var max_in_lot := 5
@export var traffic_gap := Vector2(0.5, 1.4)
@export var orders: Array[float] = [10.0, 15.0, 20.0, 25.0, 30.0]
## Tests switch these off.
var auto_traffic := true
var sound_on := true

var rng := RandomNumberGenerator.new()
var tiers := ScoreTiers.new()
var economy := FuelEconomy.new()
var combo := ComboComponent.new()
var cars: Array[ProtoCar] = []
var puddles: Array[Dictionary] = []
var round_num := 1
var round_t := 0.0
var round_over := false
var round_earned := 0.0
var round_wasted := 0.0
var round_poured := 0.0
var cash := 0.0
var shown_cash := 0.0
var cars_spawned := 0
var customers_arrived := 0
var pouring := false
var tank := 75.0
var round_tips := 0.0

var _aim := Vector2(WIDTH * 0.5, 380)
var _nozzle := _aim
var _stream_car: ProtoCar
var _next_car := 0.0
## Cash dropped by cars (#36): bills for the sale, coins for the tip. They fall out of the car,
## bounce, lie on the lot for a beat, then get pulled into the cash counter.
var money: Array[Dictionary] = []
var _bits: Array[Dictionary] = []
var _floaters: Array[Dictionary] = []
var _shake := 0.0
var _t := 0.0
var _overlay: Node2D
var _sfx := {}
var _glug: AudioStreamPlayer


func _ready() -> void:
	rng.randomize()
	tank = tank_size
	add_child(combo)
	_overlay = Node2D.new()
	_overlay.z_index = 10
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	if sound_on:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN  # the nozzle is the cursor
		for id in ["sfx_super_perfect", "sfx_perfect", "sfx_good", "sfx_ok", "sfx_miss", "pop", "counter_1", "counter_2", "counter_3"]:
			var p := AudioStreamPlayer.new()
			p.stream = load("res://assets/audio/placeholder/%s.wav" % id)
			add_child(p)
			_sfx[id] = p
		_glug = AudioStreamPlayer.new()
		_glug.stream = load("res://assets/audio/placeholder/glug_loop.wav")
		_glug.volume_db = -8.0
		add_child(_glug)


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		aim(event.position)
		set_pouring(event.pressed)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and round_over:
			next_round()
		elif event.physical_keycode == KEY_ESCAPE:
			get_tree().quit()


func _process(delta: float) -> void:
	step(delta)


# --- Controls -----------------------------------------------------------------------------------

## Where the stream lands (the mouse).
func aim(p: Vector2) -> void:
	_aim = p


func set_pouring(on: bool) -> void:
	if pouring and not on and _stream_car:
		_settle(_stream_car)
		_stream_car = null
	pouring = on and not round_over
	if _glug:
		if pouring and not _glug.playing:
			_glug.play()
		elif not pouring:
			_glug.stop()


# --- Simulation ---------------------------------------------------------------------------------

func step(dt: float) -> void:
	_t += dt
	_nozzle = _nozzle.lerp(_aim, minf(dt * 18.0, 1.0))
	if not round_over:
		round_t += dt
		if auto_traffic:
			_next_car -= dt
			if _next_car <= 0.0:
				spawn_road_car()
				_next_car = rng.randf_range(traffic_gap.x, traffic_gap.y)
		_pour(dt)
		if round_t >= round_seconds:
			end_round()
	for car in cars.duplicate():
		car.step(dt, self)
		if car.phase == ProtoCar.Phase.GONE:
			cars.erase(car)
			car.queue_free()
	_step_fx(dt)
	queue_redraw()
	_overlay.queue_redraw()


func _pour(dt: float) -> void:
	if not pouring:
		return
	var car := car_at(_aim)
	if car != _stream_car:
		if _stream_car:
			_settle(_stream_car)  # the stream slid off: a car 80% full or more settles now
		_stream_car = car
	var dollars := minf(flow_rate * dt, tank)
	tank -= dollars
	round_poured += dollars
	if car:
		var overflow := car.receive(dollars)
		if overflow > 0.0:  # the tank is full: it runs down the side of the car
			round_wasted += overflow
			_spill(car.position + Vector2(rng.randf_range(-24, 24), rng.randf_range(12, 22)), overflow)
	else:
		round_wasted += dollars
		_spill(_aim, dollars)
	if tank <= 0.0001:
		tank = 0.0
		end_round()  # out of gas
		return
	if rng.randf() < 0.6:
		_bits.append({"pos": _aim, "vel": Vector2(rng.randf_range(-60, 60), rng.randf_range(-90, -30)),
			"life": 0.35, "color": GAS, "size": 2.5})


func car_at(p: Vector2) -> ProtoCar:
	for car in cars:
		if car.customer and car.accepts_fuel() and p.distance_to(car.position) <= ProtoCar.SIZE.x * 0.55:
			return car
	return null


func spawn_road_car() -> ProtoCar:
	var car := _new_car(Vector2(-60, ROAD_Y + rng.randf_range(-8, 8)))
	car.customer = rng.randf() < customer_chance
	car.pattern = ProtoCar.PATTERNS[rng.randi() % ProtoCar.PATTERNS.size()]
	car.target = orders[rng.randi() % orders.size()]
	cars_spawned += 1
	return car


## A customer already parked in the lot (tests, and handy for tuning).
func park_customer(target: float, at: Vector2) -> ProtoCar:
	var car := _new_car(at)
	car.customer = true
	car.target = target
	car.phase = ProtoCar.Phase.WANDER
	car.pattern = ProtoCar.PATTERNS[rng.randi() % ProtoCar.PATTERNS.size()]
	car.start_pattern(self)
	return car


func _new_car(at: Vector2) -> ProtoCar:
	var car := ProtoCar.new()
	car.position = at
	car.tiers = tiers
	car.color = CAR_COLORS[rng.randi() % CAR_COLORS.size()]
	add_child(car)
	move_child(car, _overlay.get_index())  # cars draw under the stream and HUD
	cars.append(car)
	return car


func lot_has_room() -> bool:
	if round_over:
		return false  # closed: cars on the road drive past
	var n := 0
	for car in cars:
		if car.phase in [ProtoCar.Phase.ENTERING, ProtoCar.Phase.WANDER, ProtoCar.Phase.CELEBRATE]:
			n += 1
	return n < max_in_lot


func random_lot_point() -> Vector2:
	return Vector2(rng.randf_range(LOT.position.x + 60, LOT.end.x - 60), rng.randf_range(LOT.position.y + 70, LOT.end.y - 50))


## Cars nudge apart so they don't stack.
func separation(me: ProtoCar) -> Vector2:
	var push := Vector2.ZERO
	for other in cars:
		if other != me and other.phase == ProtoCar.Phase.WANDER:
			var d := me.position - other.position
			if d.length() < 70.0 and d.length() > 0.01:
				push += d.normalized() * (70.0 - d.length()) * 2.0
	return push


## The tip grows from nothing at 80% to max_tip at 100% (squared, so the last few percent count most);
## a top-off with (almost) no spill adds a bonus.
func tip_for(fill: float, spilled: float) -> float:
	if fill < ProtoCar.LEAVE_AT:
		return 0.0
	var k := clampf((fill - ProtoCar.LEAVE_AT) / (1.0 - ProtoCar.LEAVE_AT), 0.0, 1.0)
	var tip := max_tip * k * k
	if fill >= 0.995 and spilled <= 0.25:
		tip += topoff_bonus
	return tip


func _settle(car: ProtoCar) -> void:
	var t := car.stream_left()
	if t == "":
		return
	combo.register(t)
	car.tip = tip_for(car.fill(), car.spilled)
	car.paid = minf(car.amount, car.target) + car.tip
	round_earned += car.paid
	round_tips += car.tip
	cash += car.paid
	_burst(car, t)


func end_round() -> void:
	if _stream_car:
		_settle(_stream_car)
		_stream_car = null
	pouring = false
	if _glug:
		_glug.stop()
	round_over = true
	for car in cars:
		if car.customer and car.accepts_fuel() and car.fill() >= ProtoCar.LEAVE_AT:
			_settle(car)  # 80% or more: settles as usual
			continue
		if car.customer and car.accepts_fuel():
			var partial := minf(car.amount, car.target)  # they pay for what they got, no tip
			round_earned += partial
			cash += partial
			if partial > 0.0:
				drop_cash(car.position, partial, 0.0)
			car.leave(self)


func next_round() -> void:
	round_num += 1
	round_t = 0.0
	round_over = false
	round_earned = 0.0
	round_wasted = 0.0
	round_poured = 0.0
	round_tips = 0.0
	tank = tank_size
	combo.reset()


func round_fuel_cost() -> float:
	return economy.refill_cost(round_poured / economy.price_per_liter)


# --- Effects ------------------------------------------------------------------------------------

func _spill(at: Vector2, dollars: float) -> void:
	for p in puddles:
		if p.pos.distance_to(at) < p.r * 0.8:
			p.r = minf(p.r + dollars * 9.0, 46.0)
			p.life = 9.0
			return
	puddles.append({"pos": at + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)), "r": 7.0, "life": 9.0})


func _burst(car: ProtoCar, t: String) -> void:
	var col: Color = TIER_COLORS[t]
	var n := 26 if t == ScoreTiers.SUPER_PERFECT else (16 if t == ScoreTiers.PERFECT else 8)
	for i in n:
		var a := rng.randf() * TAU
		_bits.append({"pos": car.position, "vel": Vector2.from_angle(a) * rng.randf_range(80, 260),
			"life": rng.randf_range(0.4, 0.8), "color": col, "size": rng.randf_range(2.5, 5.0)})
	if t == ScoreTiers.MISS:  # overflow: gas sprays out of the tank
		for i in 18:
			_bits.append({"pos": car.position, "vel": Vector2(rng.randf_range(-120, 120), rng.randf_range(-260, -80)),
				"life": 0.7, "color": GAS, "size": 4.0})
		_spill(car.position + Vector2(rng.randf_range(-20, 20), 20), 0.8)
	drop_cash(car.position, car.paid - car.tip, car.tip, COINS[t])
	# Say exactly what was achieved: how full, what grade, what the tip was.
	var top := car.position + Vector2(0, -64)
	_floaters.append({"text": "%d%%" % int(car.fill() * 100.0), "pos": top, "life": 1.4, "color": col, "size": 34})
	_floaters.append({"text": ProtoCar.grade_name(t), "pos": top + Vector2(0, 26), "life": 1.4, "color": col,
		"size": 24 if t == ScoreTiers.SUPER_PERFECT else 18})
	if car.tip >= 0.01:
		_floaters.append({"text": "+$%.2f TIP" % car.tip, "pos": top + Vector2(0, 48), "life": 1.4,
			"color": Color(1.0, 0.85, 0.3), "size": 18})
	_shake = maxf(_shake, 0.8 if t == ScoreTiers.SUPER_PERFECT else (0.6 if t == ScoreTiers.MISS else 0.2))
	_play("sfx_" + t.to_lower().replace(" ", "_"))
	_play("pop")


const MONEY_REST := 0.45
const MONEY_FLY := 0.55


## The car drops its cash: one bill per ~$5 of sale, gold coins for the tip (more for better grades).
func drop_cash(from: Vector2, sale: float, tip: float, tip_coins := 4) -> void:
	var bills := clampi(ceili(sale / 5.0), 1, 8) if sale > 0.0 else 0
	for i in bills:
		_drop("bill", from, sale / bills, i)
	if tip >= 0.01:
		for i in tip_coins:
			_drop("coin", from, tip / tip_coins, bills + i)


func _drop(kind: String, from: Vector2, value: float, i: int) -> void:
	var bill := kind == "bill"
	money.append({"kind": kind, "value": value, "pos": from, "z": 8.0,
		"vel": Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(40, 120 if bill else 160),
		"vz": rng.randf_range(160, 240) if bill else rng.randf_range(220, 320),
		"rot": rng.randf() * TAU, "spin": rng.randf_range(-6, 6), "state": "drop", "t": -i * 0.03, "from": from})


func _step_money(dt: float) -> void:
	for m in money.duplicate():
		m.t += dt
		if m.t < 0.0:
			continue
		match m.state:
			"drop":
				var bill: bool = m.kind == "bill"
				m.pos += m.vel * dt
				m.vel *= 1.0 - (3.0 if bill else 1.6) * dt
				m.vz -= (380.0 if bill else 900.0) * dt  # bills float down, coins drop
				m.z += m.vz * dt
				m.rot += m.spin * dt * (1.0 if bill else 2.5)
				if m.z <= 0.0:
					m.z = 0.0
					if not bill and m.vz < -80.0:
						m.vz = -m.vz * 0.45  # coins bounce
						_play("counter_%d" % (rng.randi() % 3 + 1))
					else:
						m.state = "rest"
						m.t = 0.0
			"rest":
				if m.t >= MONEY_REST:
					m.state = "fly"
					m.t = 0.0
					m.from = m.pos
			"fly":
				var k: float = clampf(m.t / MONEY_FLY, 0.0, 1.0)
				var j := k * k  # pulled in, faster and faster
				var mid: Vector2 = (m.from + CASH_AT) * 0.5 + Vector2(0, -90)
				m.pos = m.from.lerp(mid, j).lerp(mid.lerp(CASH_AT, j), j)
				m.z = 0.0
				if k >= 1.0:
					shown_cash += m.value
					money.erase(m)
					_play("counter_%d" % (rng.randi() % 3 + 1))
	if money.is_empty():
		shown_cash = cash


func _step_fx(dt: float) -> void:
	_step_money(dt)
	for b in _bits.duplicate():
		b.life -= dt
		b.pos += b.vel * dt
		b.vel.y += 420.0 * dt
		if b.life <= 0.0:
			_bits.erase(b)
	for f in _floaters.duplicate():
		f.life -= dt
		f.pos.y -= 40.0 * dt
		if f.life <= 0.0:
			_floaters.erase(f)
	for p in puddles.duplicate():
		p.life -= dt
		if p.life <= 0.0:
			puddles.erase(p)
	_shake = maxf(_shake - dt * 2.5, 0.0)
	position = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _shake * 8.0


func _play(id: String) -> void:
	if _sfx.has(id):
		_sfx[id].play()


# --- Drawing ------------------------------------------------------------------------------------

## The table: dark ground, the road along the top, the lot, the gold puddles.
func _draw() -> void:
	draw_rect(Rect2(-20, -20, WIDTH + 40, HEIGHT + 40), Color(0.16, 0.13, 0.10))
	draw_rect(Rect2(-20, ROAD_Y - 34, WIDTH + 40, 68), Color(0.12, 0.12, 0.13))
	var x := -20.0 + fmod(-_t * 40.0, 60.0)
	while x < WIDTH:
		draw_rect(Rect2(x, ROAD_Y - 2, 30, 4), Color(0.85, 0.8, 0.5, 0.6))
		x += 60.0
	var lot := StyleBoxFlat.new()
	lot.bg_color = Color(0.21, 0.20, 0.20)
	lot.set_corner_radius_all(14)
	draw_style_box(lot, LOT)
	draw_rect(Rect2(ENTRANCE.x - 40, ROAD_Y + 30, 80, LOT.position.y - ROAD_Y - 20), Color(0.21, 0.20, 0.20))
	draw_rect(Rect2(EXIT.x - 40, ROAD_Y + 30, 80, LOT.position.y - ROAD_Y - 20), Color(0.21, 0.20, 0.20))
	for i in 9:
		var lx := LOT.position.x + 70 + i * 98
		draw_rect(Rect2(lx, LOT.end.y - 70, 3, 60), Color(1, 1, 1, 0.12))
	for p in puddles:
		var a := clampf(p.life / 3.0, 0.0, 1.0)
		draw_set_transform(p.pos, 0.0, Vector2(1.0, 0.62))
		draw_circle(Vector2.ZERO, p.r, Color(GAS.darkened(0.25), 0.75 * a))
		draw_circle(Vector2(-p.r * 0.15, -p.r * 0.2), p.r * 0.7, Color(GAS, 0.8 * a))
		draw_circle(Vector2(-p.r * 0.35, -p.r * 0.35), p.r * 0.22, Color(1, 1, 0.85, 0.7 * a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Above the cars: the stream, the god nozzle, coins in flight, bursts, words and the HUD.
func _draw_overlay() -> void:
	var o := _overlay
	var tip := _nozzle + NOZZLE_RAISE
	draw_shadow_ring(o)
	if pouring:
		var prev := tip
		for i in range(1, 11):
			var k := i / 10.0
			var p := tip.lerp(_aim, k) + Vector2(sin(_t * 30.0 + i) * 2.0 * k, 0)
			o.draw_line(prev, p, GAS, 6.0 - k * 2.0, true)
			prev = p
		for i in 4:
			var k := fmod(_t * 3.0 + i * 0.25, 1.0)
			o.draw_circle(tip.lerp(_aim, k) + Vector2(sin(_t * 20.0 + i * 2.0) * 3.0, 0), 3.0, GAS.lightened(0.2))
		o.draw_circle(_aim, 7.0 + sin(_t * 25.0) * 1.5, Color(GAS, 0.6))
	_draw_nozzle(o, tip)
	for b in _bits:
		o.draw_circle(b.pos, b.size, Color(b.color, clampf(b.life * 2.0, 0.0, 1.0)))
	for m in money:
		_draw_money(o, m)
	var font := ThemeDB.fallback_font
	for f in _floaters:
		var w := font.get_string_size(f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, f.size).x
		o.draw_string_outline(font, f.pos - Vector2(w * 0.5, 0), f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, f.size, 6, Color(0, 0, 0, 0.8))
		o.draw_string(font, f.pos - Vector2(w * 0.5, 0), f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, f.size, Color(f.color, clampf(f.life * 2.0, 0.0, 1.0)))
	_draw_hud(o, font)


func draw_shadow_ring(o: Node2D) -> void:
	o.draw_arc(_aim, 14.0, 0, TAU, 24, Color(1, 1, 1, 0.35), 2.0, true)


## A giant hand holding a pump nozzle, hovering above where the stream lands.
func _draw_nozzle(o: Node2D, tip: Vector2) -> void:
	var hand := tip + Vector2(-58, -30)
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	o.draw_line(hand + Vector2(20, 10), tip + Vector2(-6, -6), Color(0.15, 0.15, 0.17), 12.0, true)  # spout
	o.draw_line(hand + Vector2(-30, 4), hand + Vector2(20, 10), Color(0.8, 0.12, 0.1), 16.0, true)  # red grip
	o.draw_circle(hand + Vector2(-38, 2), 22.0, Color(0.93, 0.62, 0.45))  # the hand
	o.draw_circle(hand + Vector2(-20, -10), 10.0, Color(0.93, 0.62, 0.45))
	o.draw_circle(tip, 5.0, Color(0.1, 0.1, 0.1))


## A green bill or a gold coin, with its shadow on the ground while it falls.
func _draw_money(o: Node2D, m: Dictionary) -> void:
	if m.t < 0.0 and m.state == "drop":
		return
	var lift := Vector2(0, -m.z)
	o.draw_circle(m.pos + Vector2(0, 3), 5.0 if m.kind == "coin" else 7.0, Color(0, 0, 0, 0.25))
	if m.kind == "bill":
		o.draw_set_transform(m.pos + lift, m.rot, Vector2(1.0, 0.75 + 0.25 * sin(m.rot * 2.0)))  # flutters
		o.draw_rect(Rect2(-10, -5, 20, 10), Color(0.36, 0.62, 0.36))
		o.draw_rect(Rect2(-8, -3, 16, 6), Color(0.52, 0.78, 0.5), false, 1.0)
		o.draw_circle(Vector2.ZERO, 2.2, Color(0.25, 0.45, 0.25))
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var squash := absf(cos(m.rot))  # spins edge-on and back
		o.draw_set_transform(m.pos + lift, 0.0, Vector2(maxf(squash, 0.25), 1.0))
		o.draw_circle(Vector2.ZERO, 6.0, Color(0.85, 0.62, 0.15))
		o.draw_circle(Vector2(-1, -1), 4.5, Color(1.0, 0.84, 0.3))
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_hud(o: Node2D, font: Font) -> void:
	o.draw_string_outline(font, CASH_AT + Vector2(-50, 10), "$%.0f" % shown_cash, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, 8, Color(0, 0, 0, 0.8))
	o.draw_string(font, CASH_AT + Vector2(-50, 10), "$%.0f" % shown_cash, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(1.0, 0.85, 0.3))
	var left := maxf(round_seconds - round_t, 0.0)
	var clock := "ROUND %d    %.1f s" % [round_num, left]
	var cw := font.get_string_size(clock, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	o.draw_string_outline(font, Vector2((WIDTH - cw) * 0.5, 30), clock, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 8, Color(0, 0, 0, 0.8))
	o.draw_string(font, Vector2((WIDTH - cw) * 0.5, 30), clock, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE if left > 3.0 else Color(1, 0.4, 0.35))
	var bar := Rect2((WIDTH - 300) * 0.5, 38, 300, 5)
	o.draw_rect(bar, Color(0, 0, 0, 0.5))
	o.draw_rect(Rect2(bar.position, Vector2(bar.size.x * left / round_seconds, bar.size.y)), Color(1.0, 0.8, 0.25))
	# The round's gas: the real clock.
	var gauge := Rect2(20, 52, 26, 200)
	o.draw_rect(gauge, Color(0, 0, 0, 0.55))
	var h := gauge.size.y * tank / tank_size
	o.draw_rect(Rect2(gauge.position.x, gauge.end.y - h, gauge.size.x, h), GAS)
	o.draw_string(font, Vector2(14, 272), "GAS $%.0f" % tank, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, GAS)
	var combo_text := "x%d COMBO" % combo.multiplier
	o.draw_string(font, Vector2(WIDTH - 150, 30), combo_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.9))
	if round_wasted > 0.05:
		o.draw_string(font, Vector2(WIDTH - 150, 56), "wasted $%.2f" % round_wasted, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(GAS, 0.9))
	if round_over:
		o.draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color(0, 0, 0, 0.55))
		var lines := ["ROUND %d CLOSED" % round_num, "",
			"Earned            $%.2f   (tips $%.2f)" % [round_earned, round_tips],
			"Gas used        -$%.2f   (wasted $%.2f)" % [round_fuel_cost(), round_wasted],
			"Net                 $%.2f" % (round_earned - round_fuel_cost()), "",
			"ENTER  next round        ESC  quit"]
		for i in lines.size():
			var lw := font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26 if i == 0 else 20).x
			o.draw_string(font, Vector2((WIDTH - lw) * 0.5, 230 + i * 34), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26 if i == 0 else 20,
				Color(1.0, 0.85, 0.3) if i == 0 else Color.WHITE)
