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
## Where tips and sales land on screen: the tip jar, and the pile of bills beside it.
const JAR_AT := Vector2(1104, 588)
const JAR_RECT := Rect2(1080, 574, 48, 56)
const PILE_AT := Vector2(1010, 612)
const NOZZLE_RAISE := Vector2(-20, -96)  # the nozzle hovers up-left of where its stream lands
const CAR_COLORS := [Color(0.45, 0.55, 0.7), Color(0.7, 0.42, 0.36), Color(0.5, 0.62, 0.45),
	Color(0.72, 0.66, 0.48), Color(0.55, 0.48, 0.66), Color(0.8, 0.8, 0.78), Color(0.82, 0.42, 0.17)]
const COINS := {ScoreTiers.SUPER_PERFECT: 12, ScoreTiers.PERFECT: 8, ScoreTiers.GOOD: 5, ScoreTiers.OK: 3, ScoreTiers.MISS: 1}
const TIER_COLORS := {
	ScoreTiers.SUPER_PERFECT: Color(1.0, 0.85, 0.3), ScoreTiers.PERFECT: Color(0.35, 0.9, 0.45),
	ScoreTiers.GOOD: Color(0.6, 0.8, 1.0), ScoreTiers.OK: Color(0.95, 0.85, 0.4), ScoreTiers.MISS: Color(0.95, 0.35, 0.3),
}
const GAS := Color(0.98, 0.76, 0.18)
## Pixel art from claude-pxl (assets/art/pixel/god_pump.px.js), shown at 2x with nearest filtering.
const PIXEL := "res://assets/art/pixel/out/sprites/%s.png"
const CAR_SPRITES := ["car", "car_red", "car_green", "car_cream", "car_purple", "car_white", "car_orange"]
const NOZZLE_TIP := Vector2(110, 74)  # the spout's tip in the nozzle sprite, at 2x
const NOZZLE_HOSE := Vector2(2, 90)  # where the hose leaves the handle, at 2x
## The vintage pump on screen (bottom left): it shows the round's gas on its dial, and its hose runs
## to the nozzle in your hand.
const PUMP_AT := Vector2(18, 474)
## Isometric try (#36): the world is drawn into a half-resolution viewport and doubled on screen.
const ISO_VIEWPORT := Vector2(576, 324)
const STACKS := ["blue", "red", "green", "cream", "purple", "white", "orange"]

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

## GOD PUMP (docs/GOD_PUMP_PLAN.md): GodGame runs the day through start_day() and listens for day_over;
## unmanaged (tests, the old prototype) the day shows its own summary.
signal day_over(report: Dictionary)
var managed := false
## The numbers this day runs on (GodMods.compute): upgrades, cards, Papa's Garage.
var mods := GodData.BASE.duplicate()
## Car types that can show up today (unlocked in the meta).
var car_pool: Array = ["sedan"]
var day_num := 1
## Drone nozzles: each {pos, car, state, goal}.
var drones: Array[Dictionary] = []
var _first_car_done := false
var _cars_today := 0
var _saves_left := 0
var _best_combo := 1
var fines := 0.0
var stolen := 0.0
var applause := 0
const DRONE_FLOW := 2.2
const DRONE_SPEED := 260.0

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
## This round's tips, in the jar, and sales, as a pile of bills beside it (#36): no running cash
## counter during the round; the summary adds it all up.
var tip_jar := 0.0
var round_sales := 0.0
var jar_shown := 0.0
var bills_shown := 0.0
## The GAZ BAR neon flashes like a pinball machine on Good or better (seconds left, and the grade).
var neon_flash := 0.0
var neon_tier := ""
## The regulars on the bench by the dépanneur, and what one of them just said.
var regulars: Array[Dictionary] = []
var quip_text := ""
var quip_who := 0
var quip_t := 0.0
var _next_idle_quip := 6.0
var _spill_quipped := 0.0
## The opening sign on the door: the clock reads 7 h at the start of a round and 13 h at the
## safeguard; the round's length doesn't change.
const OPEN_HOUR := 7.0
const CLOSE_HOUR := 13.0
const QUIPS := {
	ScoreTiers.SUPER_PERFECT: ["WOW, MON HOMME!", "ÇA C'EST DE L'OUVRAGE!", "PILE POIL!", "Y'A DU TALENT, LE JEUNE!"],
	ScoreTiers.PERFECT: ["BELLE JOB!", "PAS PIRE PANTOUTE!", "PLEIN COMME UN OEUF!"],
	ScoreTiers.GOOD: ["C'EST BEAU, ÇA.", "CORRECT.", "PAS MAL."],
	"spill": ["AYOYE...", "VOYONS DONC!", "Y'EN A PARTOUT!", "TON PÈRE FAISAIT PAS ÇA."],
	"idle": ["Y FAIT BEAU À MATIN.", "T'AS-TU VU LE PRIX DU GAZ?", "MON BEAU-FRÈRE A UN CHAR DE MÊME.",
		"TON PÈRE, LUI, Y'ALLAIT À PÊCHE.", "UNE AUTRE PETITE BIÈRE?"],
}

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
var _tex := {}
## Which view draws the lot (I cycles them): "hd" (HD-2D: pixel art in a lit 3D scene, the try after
## god-pump playtest 5), "pixel" (the three-quarter pixel view) or "flat" (top-down greybox).
@export var view := "hd"
## True while the three-quarter pixel view is up; `hd` while the HD-2D view is.
var iso := false
var hd := false
var _hd_vp: SubViewport
var _hd_view: HD2DView
var _hd_sprite: Sprite2D
## World (top-down) to iso viewport pixels: x runs down-right, y down-left, at 0.4 scale.
## World (top-down) to the scene view's pixels: a high-angle three-quarter camera, the ground
## foreshortened to 0.8 (designer's ask after the isometric try).
var iso_xf := Transform2D(Vector2(0.5, 0), Vector2(0, 0.4), Vector2(0, 52))
## The OUVERT/FERMÉ sign's flip (1 = just flipped, 0 = settled).
var sign_flip := 0.0
var _kick := 0.0
var _music: AudioStreamPlayer
var _iso_vp: SubViewport
var _iso_view: IsoView
var _iso_sprite: Sprite2D


func _ready() -> void:
	rng.randomize()
	tank = tank_size
	# The regulars (designer's reference photos): plaid and a moustache, a brown jacket and glasses,
	# a grey cardigan, a leather jacket and a beer. Seated on the bench by the store.
	for i in 4:
		regulars.append({"sprite": "regular_%d" % i, "seat": i, "cheer": 0.0, "clap": 0.0, "bob": rng.randf() * TAU})
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # crisp pixels; cars and the overlay inherit it
	for id in CAR_SPRITES + ["nozzle", "bill", "coin_0", "coin_1", "coin_2", "coin_3", "puddle_s", "puddle_m",
			"puddle_l", "sparkle", "asphalt", "road", "dirt", "neon_gazbar", "neon_gazbar_off", "neon_gaz", "neon_bar",
			"nozzle_idle", "nozzle_squeeze", "pump_hud", "tip_jar", "gauge_face", "bench", "clock_face",
			"sign_ouvert", "sign_ferme", "storefront", "dirt2", "grass_a", "grass_b", "grass_c", "oil_stain", "crack",
			"hatch", "concrete", "tree", "tire_pile", "dumpster", "regular_0_clap", "regular_1_clap", "regular_2_clap",
			"regular_3_clap", "badge_thief", "badge_electric", "badge_sweeper", "badge_clumsy", "regular_0", "regular_1", "regular_2", "regular_3", "regular_0_cheer",
			"regular_1_cheer", "regular_2_cheer", "regular_3_cheer"]:
		var path := PIXEL % id
		if ResourceLoader.exists(path):
			_tex[id] = load(path)
	for body in STACKS + ["rust"] + GodData.CAR_ORDER:
		for i in 8:
			var path := PIXEL % ("stack_%s_%d" % [body, i])
			if ResourceLoader.exists(path):
				_tex["stack_%s_%d" % [body, i]] = load(path)
	add_child(combo)
	_overlay = Node2D.new()
	_overlay.z_index = 10
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	_build_iso()
	_build_hd()
	set_view(view)
	ProtoCar.gauge_tex = _tex.get("gauge_face")
	if sound_on:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN  # the nozzle is the cursor
		for id in ["sfx_super_perfect", "sfx_perfect", "sfx_good", "sfx_ok", "sfx_miss", "pop", "counter_1", "counter_2", "counter_3"]:
			var p := AudioStreamPlayer.new()
			p.stream = load("res://assets/audio/placeholder/%s.wav" % id)
			add_child(p)
			_sfx[id] = p
		_music = AudioStreamPlayer.new()  # "Roadside At Two", looped
		_music.stream = load("res://assets/audio/music/roadside_at_two.wav")
		_music.volume_db = -12.0
		_music.finished.connect(_music.play)
		add_child(_music)
		_music.play()
		_glug = AudioStreamPlayer.new()
		_glug.stream = load("res://assets/audio/placeholder/glug_loop.wav")
		_glug.volume_db = -8.0
		add_child(_glug)


func _build_iso() -> void:
	_iso_vp = SubViewport.new()
	_iso_vp.size = Vector2i(ISO_VIEWPORT)
	_iso_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	_iso_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_iso_vp)
	_iso_view = IsoView.new()
	_iso_view.game = self
	_iso_vp.add_child(_iso_view)
	_iso_sprite = Sprite2D.new()
	_iso_sprite.texture = _iso_vp.get_texture()
	_iso_sprite.centered = false
	_iso_sprite.scale = Vector2(2, 2)
	_iso_sprite.visible = iso  # in case the view was switched before the game was ready
	add_child(_iso_sprite)
	move_child(_iso_sprite, _overlay.get_index())


## The HD-2D scene renders at twice the base resolution and is shown at half size: crisp on any screen.
func _build_hd() -> void:
	_hd_vp = SubViewport.new()
	_hd_vp.size = Vector2i(int(WIDTH) * 2, int(HEIGHT) * 2)
	_hd_vp.own_world_3d = true
	_hd_vp.msaa_3d = Viewport.MSAA_4X
	_hd_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_hd_vp)
	_hd_view = HD2DView.new()
	_hd_vp.add_child(_hd_view)
	_hd_view.setup(self)
	_hd_sprite = Sprite2D.new()
	_hd_sprite.texture = _hd_vp.get_texture()
	_hd_sprite.centered = false
	_hd_sprite.scale = Vector2(0.5, 0.5)
	_hd_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_hd_sprite.visible = false
	add_child(_hd_sprite)
	move_child(_hd_sprite, _overlay.get_index())


func set_view(v: String) -> void:
	view = v
	iso = v == "pixel"
	hd = v == "hd"
	if _iso_sprite:
		_iso_sprite.visible = iso
	if _hd_sprite:
		_hd_sprite.visible = hd
	if _hd_vp:
		_hd_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if hd else SubViewport.UPDATE_DISABLED
	for car in cars:
		car.visible = v == "flat"
	queue_redraw()


func cycle_view() -> void:
	set_view({"hd": "pixel", "pixel": "flat", "flat": "hd"}[view])


## Where a car's roof is on screen, in the current view.
func car_top(car: ProtoCar) -> Vector2:
	var lift: float = car.anim_offsets().lift
	if hd and _hd_view:
		return _hd_view.screen(car.position, 0.5 + lift * HD2DView.K)
	if iso:
		return scr(car.position) - Vector2(0, 16 + lift * 0.8)
	return car.position - Vector2(0, 16 + lift)


## Where regular `i`'s head is on screen (for speech bubbles), or null in the flat view.
func regular_head(i: int) -> Variant:
	if hd and _hd_view:
		return _hd_view.regular_head(i)
	if iso and _iso_view:
		return _iso_view.seat_screen(i)
	return null


## The gaz bar's name goes up on the sign (HD-2D view).
func set_station_name(text: String) -> void:
	if _hd_view:
		_hd_view.set_station_name(text)


func tex(id: String) -> Texture2D:
	return _tex.get(id)


## World point to screen point in the current view.
func scr(w: Vector2) -> Vector2:
	if hd and _hd_view:
		return _hd_view.screen(w)
	return (iso_xf * w) * 2.0 if iso else w


## Screen point (the mouse) to the world point on the ground beneath it.
func to_world(sp: Vector2) -> Vector2:
	if hd and _hd_view:
		return _hd_view.ground_at(sp)
	return iso_xf.affine_inverse() * (sp / 2.0) if iso else sp


## Kept for the older tests: on = the three-quarter pixel view, off = flat.
func set_iso(on: bool) -> void:
	set_view("pixel" if on else "flat")


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		aim(to_world(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		aim(to_world(event.position))
		set_pouring(event.pressed)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and round_over and not managed:
			next_round()
		elif event.physical_keycode == KEY_ESCAPE and not managed:
			get_tree().quit()
		elif event.physical_keycode == KEY_I:
			cycle_view()


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
	if on and not pouring and not round_over:
		_kick = 1.0  # the hand squeezes: a little jolt
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
	if not round_over:
		_step_patience(dt)
		_step_roles(dt)
		_step_drones(dt)
	_step_fx(dt)
	queue_redraw()
	_overlay.queue_redraw()
	if iso and _iso_view:
		_iso_view.queue_redraw()


func _pour(dt: float) -> void:
	if not pouring:
		return
	var car := car_at(_aim)
	if not car and mods.auto_aim > 0.0:  # auto-aim: the stream bends toward a car nearby
		car = nearest_customer(_aim, mods.auto_aim + ProtoCar.SIZE.x * 0.55)
	if car and car.role in ["thief", "electric"]:
		_react(car)
		car = null
	if car != _stream_car:
		if _stream_car:
			_settle(_stream_car)  # the stream slid off: a car 80% full or more settles now
		_stream_car = car
	var dollars := minf(flow_rate * dt * (car.fill_speed if car else 1.0), tank)
	if not car or car.amount >= car.target:
		dollars *= mods.spill_mult  # gas saver: less runs onto the ground
	tank -= dollars
	round_poured += dollars
	if car:
		var overflow := car.receive(dollars)
		if overflow > 0.0:  # the tank is full: it runs down the side of the car
			_waste(overflow, car.position + Vector2(rng.randf_range(-24, 24), rng.randf_range(12, 22)))
		if int(mods.twin_stream) > 0:  # twin stream: a second car nearby fills too
			var other := nearest_customer(car.position, 120.0, car)
			if other:
				var d2 := minf(flow_rate * dt * other.fill_speed, tank)
				tank -= d2
				round_poured += d2
				var o2 := other.receive(d2)
				if o2 > 0.0:
					_waste(o2, other.position + Vector2(0, 18))
	else:
		_waste(dollars, _aim)
	if tank <= 0.0001:
		tank = 0.0
		_floaters.append({"text": "PLUS DE GAZ!", "pos": Vector2(WIDTH * 0.5, 260), "life": 2.5, "color": Color(1, 0.4, 0.3), "size": 40})
		end_round()  # out of gas
		return
	if rng.randf() < 0.6:
		_bits.append({"pos": scr(_aim), "vel": Vector2(rng.randf_range(-60, 60), rng.randf_range(-90, -30)),
			"life": 0.35, "color": GAS, "size": 2.5})


func car_at(p: Vector2) -> ProtoCar:
	var reach := ProtoCar.SIZE.x * 0.55 + float(mods.get("stream_radius", 0.0))
	for car in cars:
		if (car.customer or car.role in ["thief", "electric"]) and car.accepts_fuel() and p.distance_to(car.position) <= reach:
			return car
	return null


## The nearest customer still taking fuel within `reach` of `p` (auto-aim, twin stream, drones).
func nearest_customer(p: Vector2, reach: float, except: ProtoCar = null) -> ProtoCar:
	var best: ProtoCar = null
	var best_d := reach
	for car in cars:
		if car == except or not car.customer or not car.accepts_fuel():
			continue
		var d := p.distance_to(car.position)
		if d <= best_d:
			best_d = d
			best = car
	return best


## Spilled gas: a puddle, counted as wasted (the recycler sends some back to the tank).
func _waste(dollars: float, at: Vector2) -> void:
	round_wasted += dollars
	_spill(at, dollars)
	if int(mods.get("recycle", 0)) > 0:
		tank += dollars * 0.7


## Pouring on the thief scares it off; pouring on the electric car earns a fine.
func _react(car: ProtoCar) -> void:
	if car.angry:
		return
	car.angry = true
	var top := scr(car.position) + Vector2(0, -60)
	if car.role == "thief":
		_floaters.append({"text": "SAUVE-TOI!", "pos": top, "life": 1.6, "color": Color(1, 0.6, 0.3), "size": 22})
	else:
		fines += 10.0
		cash -= 10.0
		_floaters.append({"text": "JE SUIS ÉLECTRIQUE! -$10", "pos": top, "life": 1.8, "color": Color(0.5, 1, 0.6), "size": 20})
	car.leave(self)


func spawn_road_car() -> ProtoCar:
	# Two-way traffic (playtest 6): cars heading east ride the near lane and may pull in; westbound
	# cars on the far lane just drive by.
	var east := rng.randf() < 0.55
	var car := _new_car(Vector2(-60, ROAD_Y + 12 + rng.randf_range(-3, 3)) if east else Vector2(WIDTH + 60, ROAD_Y - 14 + rng.randf_range(-3, 3)))
	car.road_dir = 1.0 if east else -1.0
	car.heading = 0.0 if east else PI
	car.pattern = ProtoCar.PATTERNS[rng.randi() % ProtoCar.PATTERNS.size()]
	car.target = orders[rng.randi() % orders.size()]
	if east and rng.randf() < customer_chance:
		car.set_type(_pick_type(), rng)  # it pulls in: a customer, or one of the troublemakers
		car.wants_in = true
	else:
		car.customer = false
	car.patience = 24.0 * mods.patience_mult
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
	var look := rng.randi() % CAR_COLORS.size()
	car.color = CAR_COLORS[look]
	car.sprite = _tex.get(CAR_SPRITES[look % CAR_SPRITES.size()])
	car.stack = STACKS[look % STACKS.size()]
	car.visible = view == "flat"
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
## topping off adds a bonus; overfilling (a spill over $0.25) loses the tip altogether.
## Everything that multiplies a car's tip today: the car type, the shop, cards, the meta, procs.
func _tip_mult(car: ProtoCar) -> float:
	var m: float = car.tip_mult * mods.tip_mult
	if car.by_drone:
		m *= 0.5
	if int(mods.happy_hour) > 0 and hour_now() < GodData.OPEN_HOUR + 2.0:
		m *= 2.0
	if not _first_car_done:
		_first_car_done = true
		m *= mods.first_car_tip_mult
	if int(mods.get("bobblehead", 0)) > 0:
		m *= 1.0 + 0.05 * combo.multiplier
	if mods.golden_chance > 0.0 and rng.randf() < mods.golden_chance:
		m *= 3.0
		_floaters.append({"text": "DORÉ!", "pos": scr(car.position) + Vector2(0, -130), "life": 1.4, "color": Color(1, 0.85, 0.2), "size": 24})
	if mods.jackpot_chance > 0.0 and rng.randf() < mods.jackpot_chance:
		m *= 4.0
		_floaters.append({"text": "JACKPOT!", "pos": scr(car.position) + Vector2(0, -130), "life": 1.6, "color": Color(1, 0.5, 0.9), "size": 26})
	return m


func tip_for(fill: float, spilled: float) -> float:
	if fill < 0.9 or spilled > 0.25:
		return 0.0  # OK fills and overfills don't tip
	var k := clampf((fill - 0.9) / 0.1, 0.0, 1.0)
	var tip := max_tip * pow(k, 1.5)
	if fill >= 0.995:
		tip += mods.get("topoff_bonus", topoff_bonus)
	return tip


func _settle(car: ProtoCar) -> void:
	var t := car.stream_left()
	if t == "":
		return
	var breaks := not combo.tiers.extends_combo(t)
	if t == ScoreTiers.OK and int(mods.combo_lock) > 0:
		breaks = false  # combo lock: an OK keeps the chain
	if t == ScoreTiers.MISS and _saves_left > 0:
		_saves_left -= 1  # Saint Christophe: an overfill forgiven
		breaks = false
	if not car.by_drone and (breaks or combo.tiers.extends_combo(t)):
		combo.register(t)
	_best_combo = maxi(_best_combo, combo.multiplier)
	_count(car, t)
	car.tip = tip_for(car.fill(), car.spilled) * _tip_mult(car)
	if t in [ScoreTiers.SUPER_PERFECT, ScoreTiers.PERFECT]:
		car.tip += mods.perfect_bonus + mods.applause_bonus
		applause += 1
	if mods.loto_chance > 0.0 and rng.randf() < mods.loto_chance:
		car.tip += 20.0
		_floaters.append({"text": "LOTO! +$20", "pos": scr(car.position) + Vector2(0, -110), "life": 1.6, "color": Color(1, 0.9, 0.3), "size": 22})
	var sale: float = minf(car.amount, car.target) * car.pay_share + mods.per_car_bonus
	_cars_today += 1
	if int(mods.refund_every) > 0 and _cars_today % int(mods.refund_every) == 0:
		tank += car.amount  # rabbit's foot: this car's gas goes back in the tank
	car.paid = sale + car.tip
	round_earned += car.paid
	round_tips += car.tip
	round_sales += sale
	tip_jar += car.tip
	cash += car.paid
	if t in [ScoreTiers.SUPER_PERFECT, ScoreTiers.PERFECT, ScoreTiers.GOOD]:
		neon_flash = {ScoreTiers.SUPER_PERFECT: 1.8, ScoreTiers.PERFECT: 1.1, ScoreTiers.GOOD: 0.6}[t]
		neon_tier = t
		say(QUIPS[t])
	# The regulars: everyone throws their arms up for a top-off and applauds a Perfect.
	for r in regulars:
		if t == ScoreTiers.SUPER_PERFECT:
			r.cheer = 1.3
		elif t == ScoreTiers.PERFECT:
			r.clap = 1.3
	if t == ScoreTiers.MISS:
		say(QUIPS.spill)
		regulars[quip_who].cheer = 0.0
	_burst(car, t)


## The day's numbers for the report (GOD PUMP plan): grades, cars, accuracy, loot.
var day_stats := {}


func reset_day_stats() -> void:
	day_stats = {"tiers": {ScoreTiers.SUPER_PERFECT: 0, ScoreTiers.PERFECT: 0, ScoreTiers.GOOD: 0,
		ScoreTiers.OK: 0, ScoreTiers.MISS: 0}, "cars": 0, "accuracy_sum": 0.0, "xp": 0}


func _count(car: ProtoCar, t: String) -> void:
	if day_stats.is_empty():
		reset_day_stats()
	day_stats.tiers[t] += 1
	day_stats.cars += 1
	day_stats.accuracy_sum += car.accuracy()
	day_stats.xp += xp_for(t)


## XP for one car: 1 for filling it, plus the combo multiplier on Good or better, plus 5 for a top-off.
func xp_for(t: String) -> int:
	var xp := 1
	if t in [ScoreTiers.SUPER_PERFECT, ScoreTiers.PERFECT, ScoreTiers.GOOD]:
		xp += combo.multiplier
	if t == ScoreTiers.SUPER_PERFECT:
		xp += 5
	return xp


func day_accuracy() -> float:
	return day_stats.accuracy_sum / day_stats.cars if not day_stats.is_empty() and day_stats.cars > 0 else 0.0


## One of the regulars says something (a random one, from `pool`).
func say(pool: Array) -> void:
	if regulars.is_empty():
		return
	quip_text = pool[rng.randi() % pool.size()]
	quip_who = rng.randi() % regulars.size()
	quip_t = 2.2
	regulars[quip_who].cheer = 0.9


func hour_now() -> float:
	return lerpf(OPEN_HOUR, CLOSE_HOUR, clampf(round_t / round_seconds, 0.0, 1.0))


func is_open() -> bool:
	return not round_over


func end_round() -> void:
	if _stream_car:
		_settle(_stream_car)
		_stream_car = null
	pouring = false
	if _glug:
		_glug.stop()
	round_over = true
	sign_flip = 1.0  # OUVERT -> FERMÉ
	for car in cars:
		if car.customer and car.accepts_fuel() and car.fill() >= ProtoCar.LEAVE_AT:
			_settle(car)  # 80% or more: settles as usual
			continue
		if car.customer and car.accepts_fuel():
			_count(car, ScoreTiers.MISS)  # still under 80% at closing: a miss
			var partial := minf(car.amount, car.target)  # they pay for what they got, no tip
			round_earned += partial
			round_sales += partial
			cash += partial
			if partial > 0.0:
				drop_cash(car.position, partial, 0.0)
			car.leave(self)
	if managed:
		day_over.emit(day_report())


## Opens a day for GodGame: today's mods, the gas in the station's tank, the day number and the car
## types that can show up. The clock limits the day (7 h to the closing hour); the tank can end it early.
func start_day(m: Dictionary, tank_dollars: float, day_n: int, pool: Array) -> void:
	mods = m.duplicate()
	car_pool = pool
	day_num = day_n
	flow_rate = 4.0 * mods.flow_mult
	round_seconds = (mods.close_hour - GodData.OPEN_HOUR) * GodData.HOUR_SECONDS
	customer_chance = mods.customer_chance
	combo.max_multiplier = int(mods.combo_max)
	next_round()
	round_num = day_n
	tank = tank_dollars
	_first_car_done = false
	_cars_today = 0
	_saves_left = int(mods.overfill_saves)
	_best_combo = 1
	fines = 0.0
	stolen = 0.0
	applause = 0
	for car in cars.duplicate():
		cars.erase(car)
		car.queue_free()
	for i in int(mods.queue):  # cars already waiting when you open (marketing)
		var car := park_customer(0.0, random_lot_point())
		car.set_type(_pick_type(true), rng)
		car.patience = 24.0 * mods.patience_mult
	drones.clear()
	for i in int(mods.drones):
		drones.append({"pos": Vector2(WIDTH * 0.5 + i * 40, 140), "car": null, "state": "idle", "goal": 0.0})


## Today's report for GodGame and the end-of-day screen.
func day_report() -> Dictionary:
	if day_stats.is_empty():
		reset_day_stats()
	return {"day": day_num, "loot": round_earned - fines, "sales": round_sales, "tips": round_tips,
		"tank_left": tank, "xp": day_stats.xp, "cars": day_stats.cars, "tiers": day_stats.tiers.duplicate(),
		"accuracy": day_accuracy(), "best_combo": _best_combo, "wasted": round_wasted, "fines": fines,
		"stolen": stolen, "out_of_gas": tank <= 0.0001}


## A car type for a new car, weighted; troublemakers ramp in over the first days.
func _pick_type(customers_only := false) -> String:
	var total := 0.0
	var weights := {}
	for id in car_pool:
		var t: Dictionary = GodData.CAR_TYPES[id]
		if customers_only and not t.get("customer", true):
			continue
		var w: float = t.weight
		if t.has("role") and t.role != "clumsy":
			w *= clampf(day_num / 6.0, 0.25, 1.0)
		weights[id] = w
		total += w
	var pick := rng.randf() * total
	for id in weights:
		pick -= weights[id]
		if pick <= 0.0:
			return id
	return "sedan"


func next_round() -> void:
	round_num += 1
	round_t = 0.0
	round_over = false
	round_earned = 0.0
	round_wasted = 0.0
	round_poured = 0.0
	round_tips = 0.0
	tip_jar = 0.0
	round_sales = 0.0
	jar_shown = 0.0
	bills_shown = 0.0
	puddles.clear()  # the lot is hosed down between rounds
	sign_flip = 1.0  # FERMÉ -> OUVERT
	_spill_quipped = 0.0
	reset_day_stats()
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
		_bits.append({"pos": scr(car.position), "vel": Vector2.from_angle(a) * rng.randf_range(80, 260),
			"life": rng.randf_range(0.4, 0.8), "color": col, "size": rng.randf_range(2.5, 5.0)})
	if t == ScoreTiers.SUPER_PERFECT or t == ScoreTiers.PERFECT:
		for i in (10 if t == ScoreTiers.SUPER_PERFECT else 5):
			_bits.append({"pos": scr(car.position) + Vector2(rng.randf_range(-30, 30), rng.randf_range(-30, 10)),
				"vel": Vector2(rng.randf_range(-40, 40), rng.randf_range(-160, -60)), "life": rng.randf_range(0.6, 1.0),
				"color": Color.WHITE, "size": 0.0, "sparkle": true})
	if t == ScoreTiers.MISS:  # overflow: gas sprays out of the tank
		for i in 18:
			_bits.append({"pos": scr(car.position), "vel": Vector2(rng.randf_range(-120, 120), rng.randf_range(-260, -80)),
				"life": 0.7, "color": GAS, "size": 4.0})
		_spill(car.position + Vector2(rng.randf_range(-20, 20), 20), 0.8)
	drop_cash(car.position, car.paid - car.tip, car.tip, COINS[t])
	# Say exactly what was achieved: how full, what grade, what the tip was.
	var top := scr(car.position) + Vector2(0, -64)
	_floaters.append({"text": "%d%%" % int(car.fill() * 100.0), "pos": top, "life": 1.4, "color": col, "size": 34})
	_floaters.append({"text": ProtoCar.grade_name(t), "pos": top + Vector2(0, 26), "life": 1.4, "color": col,
		"size": 24 if t == ScoreTiers.SUPER_PERFECT else 18})
	if car.tip >= 0.01:
		_floaters.append({"text": "+$%.2f TIP" % car.tip, "pos": top + Vector2(0, 48), "life": 1.4,
			"color": Color(1.0, 0.85, 0.3), "size": 18})
	_shake = maxf(_shake, 0.8 if t == ScoreTiers.SUPER_PERFECT else (0.6 if t == ScoreTiers.MISS else 0.2))
	_play("sfx_" + t.to_lower().replace(" ", "_"))
	_play("pop")


const MONEY_REST := 3.45  # cash lies on the lot a while before it's collected (god-pump playtest 5)
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
					m.target = JAR_AT if m.kind == "coin" else PILE_AT  # tips to the jar, sales to the pile
					m.state = "fly"
					m.t = 0.0
					m.from = scr(m.pos)  # from here on it travels on the screen
					m.screen = true
			"fly":
				var k: float = clampf(m.t / MONEY_FLY, 0.0, 1.0)
				var j := k * k  # pulled in, faster and faster
				var to: Vector2 = m.target
				var mid: Vector2 = (m.from + to) * 0.5 + Vector2(0, -90)
				m.pos = m.from.lerp(mid, j).lerp(mid.lerp(to, j), j)
				m.z = 0.0
				if k >= 1.0:
					shown_cash += m.value
					if m.kind == "coin":
						jar_shown += m.value
					else:
						bills_shown += m.value
					money.erase(m)
					_play("counter_%d" % (rng.randi() % 3 + 1))
	if money.is_empty():
		shown_cash = cash
		jar_shown = tip_jar
		bills_shown = round_sales


## A customer left waiting too long drives off: a Miss (they pay for what they got).
func _step_patience(dt: float) -> void:
	for car in cars:
		if not car.customer or car.phase != ProtoCar.Phase.WANDER or car == _stream_car:
			continue
		car.waited += dt
		if car.waited > car.patience:
			if car.fill() >= ProtoCar.LEAVE_AT:
				_settle(car)
				continue
			_count(car, ScoreTiers.MISS)
			var partial := minf(car.amount, car.target) * car.pay_share
			round_earned += partial
			round_sales += partial
			cash += partial
			if partial > 0.0:
				drop_cash(car.position, partial, 0.0)
			_floaters.append({"text": "TROP LONG!", "pos": scr(car.position) + Vector2(0, -60), "life": 1.4, "color": Color(1, 0.4, 0.3), "size": 20})
			combo.register(ScoreTiers.MISS)
			car.leave(self)


## The troublemakers and helpers (GodData.CAR_TYPES roles).
func _step_roles(dt: float) -> void:
	for car in cars:
		if car.phase != ProtoCar.Phase.WANDER:
			continue
		car.role_t += dt
		match car.role:
			"sweeper":  # cleans the puddles it drives over, then leaves
				for p in puddles.duplicate():
					if p.pos.distance_to(car.position) < 46.0:
						puddles.erase(p)
				if car.role_t > 14.0:
					car.leave(self)
			"electric":  # wanders a while, then leaves; it never wanted gas
				if car.role_t > 10.0:
					car.leave(self)
			"thief":  # siphons gas from a customer, then flees with it
				if not car.victim or not is_instance_valid(car.victim) or not car.victim.accepts_fuel():
					car.victim = nearest_customer(car.position, 2000.0, car)
				if car.victim:
					car.moving = car.position.distance_to(car.victim.position) > 60.0
					if car.moving:
						car.heading = rotate_toward(car.heading, (car.victim.position - car.position).angle(), 3.0 * dt)
						car.position += Vector2.from_angle(car.heading) * 120.0 * dt
					else:
						var take := minf(3.0 * dt, car.victim.amount)
						if take > 0.0 and car.stolen == 0.0:
							_floaters.append({"text": "VOLEUR!", "pos": scr(car.position) + Vector2(0, -60), "life": 1.4, "color": Color(1, 0.3, 0.3), "size": 22})
						car.victim.amount -= take
						car.stolen += take
						stolen += take
				if car.role_t > 7.0 or car.stolen > 12.0:
					car.leave(self)
			"clumsy":  # bumps into cars, who spill some of their gas
				car.bump_cool = maxf(car.bump_cool - dt, 0.0)
				if car.bump_cool <= 0.0:
					for other in cars:
						if other != car and other.customer and other.accepts_fuel() and other.amount > 1.0 \
								and other.position.distance_to(car.position) < 52.0:
							var lost: float = other.amount * 0.25
							other.amount -= lost
							_waste(lost, other.position + Vector2(0, 16))
							_floaters.append({"text": "BANG!", "pos": scr(other.position) + Vector2(0, -60), "life": 1.2, "color": Color(1, 0.7, 0.3), "size": 24})
							car.bump_cool = 3.0
							break


## Drone nozzles: each flies to a customer nobody is pouring on, fills it to a good-but-not-perfect
## level on its own (slower than you, half the tip, no combo), and moves on. The automation.
func _step_drones(dt: float) -> void:
	for d in drones:
		var car: ProtoCar = d.car
		if car and (not is_instance_valid(car) or not car.accepts_fuel()):
			car = null
			d.car = null
		if not car:
			for c in cars:
				if c.customer and c.accepts_fuel() and not c.drone_target and c != _stream_car and c.amount < c.target * 0.8:
					car = c
					c.drone_target = true
					d.car = c
					d.goal = rng.randf_range(0.86, 0.995)
					break
			if not car:
				continue
		var gap: Vector2 = car.position - d.pos
		if gap.length() > 8.0:
			d.pos += gap.normalized() * minf(DRONE_SPEED * dt, gap.length())
			d.state = "flying"
			continue
		d.state = "pouring"
		var dollars := minf(DRONE_FLOW * dt * car.fill_speed, tank)
		tank -= dollars
		round_poured += dollars
		car.receive(dollars)
		if car.fill() >= d.goal or car.amount >= car.target:
			car.by_drone = true
			_settle(car)
			d.car = null
			d.state = "idle"
		if tank <= 0.0001:
			tank = 0.0
			end_round()
			return


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
	# Puddles stay all round (cleared by next_round).
	neon_flash = maxf(neon_flash - dt, 0.0)
	sign_flip = maxf(sign_flip - dt * 2.0, 0.0)
	_kick = maxf(_kick - dt * 6.0, 0.0)
	quip_t = maxf(quip_t - dt, 0.0)
	for r in regulars:
		r.cheer = maxf(r.cheer - dt, 0.0)
		r.clap = maxf(r.clap - dt, 0.0)
	if not round_over and not regulars.is_empty():
		_next_idle_quip -= dt
		if _next_idle_quip <= 0.0 and quip_t <= 0.0:
			say(QUIPS.idle)
			regulars[quip_who].cheer = 0.0
			_next_idle_quip = rng.randf_range(7.0, 11.0)
		if round_wasted - _spill_quipped >= 4.0:
			_spill_quipped = round_wasted
			say(QUIPS.spill)
			regulars[quip_who].cheer = 0.0
	_shake = maxf(_shake - dt * 2.5, 0.0)
	position = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * _shake * 8.0


func _play(id: String) -> void:
	if _sfx.has(id):
		_sfx[id].play()


# --- Drawing ------------------------------------------------------------------------------------

## The table: dark ground, the road along the top, the lot, the gold puddles.
func _draw() -> void:
	if view != "flat":
		return  # a scene view draws the world
	draw_rect(Rect2(-20, -20, WIDTH + 40, HEIGHT + 40), Color(0.16, 0.13, 0.10))
	if _tex.has("dirt"):
		_tile("dirt", Rect2(-20, -20, WIDTH + 40, HEIGHT + 40))
	draw_rect(Rect2(-20, ROAD_Y - 34, WIDTH + 40, 68), Color(0.12, 0.12, 0.13))
	if _tex.has("road"):
		_tile("road", Rect2(-20, ROAD_Y - 32, WIDTH + 40, 64))
	var x := -20.0 + fmod(-_t * 40.0, 60.0)
	while x < WIDTH:
		draw_rect(Rect2(x, ROAD_Y - 2, 30, 4), Color(0.85, 0.8, 0.5, 0.6))
		x += 60.0
	var lot := StyleBoxFlat.new()
	lot.bg_color = Color(0.21, 0.20, 0.20)
	lot.set_corner_radius_all(14)
	draw_style_box(lot, LOT)
	if _tex.has("asphalt"):
		_tile("asphalt", LOT.grow(-6))
	draw_rect(Rect2(ENTRANCE.x - 40, ROAD_Y + 30, 80, LOT.position.y - ROAD_Y - 20), Color(0.21, 0.20, 0.20))
	draw_rect(Rect2(EXIT.x - 40, ROAD_Y + 30, 80, LOT.position.y - ROAD_Y - 20), Color(0.21, 0.20, 0.20))
	for i in 9:
		var lx := LOT.position.x + 70 + i * 98
		draw_rect(Rect2(lx, LOT.end.y - 70, 3, 60), Color(1, 1, 1, 0.12))
	for p in puddles:
		var a := clampf(p.life / 3.0, 0.0, 1.0)
		var size_id := "puddle_s" if p.r < 13.0 else ("puddle_m" if p.r < 28.0 else "puddle_l")
		if _tex.has(size_id):
			var tex: Texture2D = _tex[size_id]
			var k: float = 2.0 * clampf(p.r / (tex.get_width() * 0.9), 0.6, 1.6)
			draw_set_transform(p.pos, 0.0, Vector2(k, k))
			draw_texture(tex, -tex.get_size() * 0.5, Color(1, 1, 1, a))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			continue
		draw_set_transform(p.pos, 0.0, Vector2(1.0, 0.62))
		draw_circle(Vector2.ZERO, p.r, Color(GAS.darkened(0.25), 0.75 * a))
		draw_circle(Vector2(-p.r * 0.15, -p.r * 0.2), p.r * 0.7, Color(GAS, 0.8 * a))
		draw_circle(Vector2(-p.r * 0.35, -p.r * 0.35), p.r * 0.22, Color(1, 1, 0.85, 0.7 * a))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Tiles a 32 px texture over `r` at 2x.
func _tile(id: String, r: Rect2) -> void:
	draw_set_transform(r.position, 0.0, Vector2(2, 2))
	draw_texture_rect(_tex[id], Rect2(Vector2.ZERO, r.size * 0.5), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Above the cars: the stream, the god nozzle, coins in flight, bursts, words and the HUD.
func _draw_overlay() -> void:
	var o := _overlay
	var land := scr(_aim)
	if view != "flat" and pouring and _stream_car:  # the stream lands on the car's roof
		land = car_top(_stream_car)
	var tip := scr(_nozzle) + NOZZLE_RAISE + Vector2(-4, 6) * _kick
	if view != "flat":  # gauges float over the cars
		for car in cars:
			if car.customer and car.accepts_fuel():
				car.draw_meter_at(o, car_top(car) + Vector2(0, -46))
	_draw_badges(o)
	draw_shadow_ring(o)
	_draw_pump(o, tip)
	if pouring:
		var prev := tip
		for i in range(1, 11):
			var k := i / 10.0
			var p := tip.lerp(land, k) + Vector2(sin(_t * 30.0 + i) * 2.0 * k, 0)
			o.draw_line(prev, p, GAS, 6.0 - k * 2.0, true)
			prev = p
		for i in 4:
			var k := fmod(_t * 3.0 + i * 0.25, 1.0)
			o.draw_circle(tip.lerp(land, k) + Vector2(sin(_t * 20.0 + i * 2.0) * 3.0, 0), 3.0, GAS.lightened(0.2))
		o.draw_circle(land, 7.0 + sin(_t * 25.0) * 1.5, Color(GAS, 0.6))
	_draw_nozzle(o, tip)
	for b in _bits:
		if b.get("sparkle", false) and _tex.has("sparkle"):
			o.draw_set_transform(b.pos, _t * 3.0, Vector2(2, 2))
			o.draw_texture(_tex["sparkle"], Vector2(-3.5, -3.5), Color(1, 1, 1, clampf(b.life * 2.0, 0.0, 1.0)))
			o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			continue
		o.draw_circle(b.pos, b.size, Color(b.color, clampf(b.life * 2.0, 0.0, 1.0)))
	for m in money:
		_draw_money(o, m)
	var font := ThemeDB.fallback_font
	for f in _floaters:
		var w := font.get_string_size(f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, f.size).x
		o.draw_string_outline(font, f.pos - Vector2(w * 0.5, 0), f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, f.size, 6, Color(0, 0, 0, 0.8))
		o.draw_string(font, f.pos - Vector2(w * 0.5, 0), f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, f.size, Color(f.color, clampf(f.life * 2.0, 0.0, 1.0)))
	_draw_hud(o, font)


## Troublemakers wear a badge (a mask, a lightning bolt, a broom, dizzy stars); Dad wears his name.
func _draw_badges(o: Node2D) -> void:
	for car in cars:
		if not car.accepts_fuel() or (car.role == "" and car.type_id != "papa"):
			continue
		var top := car_top(car) + Vector2(0, (-96.0 if car.customer else -22.0) + sin(_t * 4.0 + car.position.x) * 3.0)
		if car.type_id == "papa":
			GodUI.text(o, top + Vector2(0, -6), "PAPA", 22, Color(1.0, 0.85, 0.3), true, 6)
			continue
		var tex: Texture2D = _tex.get("badge_" + car.role)
		if tex:
			o.draw_set_transform(top, 0.0, Vector2(2, 2))
			o.draw_texture(tex, -tex.get_size() * 0.5)
			o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func draw_shadow_ring(o: Node2D) -> void:
	if view != "flat":  # the landing spot lies flat on the ground
		o.draw_set_transform(scr(_aim), 0.0, Vector2(1.0, 0.5))
		o.draw_arc(Vector2.ZERO, 16.0, 0, TAU, 24, Color(1, 1, 1, 0.35), 2.0, true)
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	o.draw_arc(_aim, 14.0, 0, TAU, 24, Color(1, 1, 1, 0.35), 2.0, true)


## A giant hand holding a pump nozzle, hovering above where the stream lands.
func _draw_nozzle(o: Node2D, tip: Vector2) -> void:
	var id := "nozzle_squeeze" if pouring else "nozzle_idle"  # the hand squeezes the lever to pour
	if _tex.has(id):
		o.draw_set_transform(tip - NOZZLE_TIP, 0.0, Vector2(2, 2))
		o.draw_texture(_tex[id], Vector2.ZERO)
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
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
	var at: Vector2 = m.pos if m.get("screen", false) else scr(m.pos)
	o.draw_circle(at + Vector2(0, 3), 5.0 if m.kind == "coin" else 7.0, Color(0, 0, 0, 0.25))
	if m.kind == "bill" and _tex.has("bill"):
		o.draw_set_transform(at + lift, m.rot, Vector2(2.0, 2.0 * (0.7 + 0.3 * sin(m.rot * 2.0))))  # flutters
		o.draw_texture(_tex["bill"], -_tex["bill"].get_size() * 0.5)
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif m.kind == "coin" and _tex.has("coin_0"):
		var frame := int(fposmod(m.rot, TAU) / TAU * 4.0) % 4  # spinning
		var tex: Texture2D = _tex["coin_%d" % frame]
		o.draw_set_transform(at + lift, 0.0, Vector2(2, 2))
		o.draw_texture(tex, -tex.get_size() * 0.5)
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	elif m.kind == "bill":
		o.draw_set_transform(at + lift, m.rot, Vector2(1.0, 0.75 + 0.25 * sin(m.rot * 2.0)))  # flutters
		o.draw_rect(Rect2(-10, -5, 20, 10), Color(0.36, 0.62, 0.36))
		o.draw_rect(Rect2(-8, -3, 16, 6), Color(0.52, 0.78, 0.5), false, 1.0)
		o.draw_circle(Vector2.ZERO, 2.2, Color(0.25, 0.45, 0.25))
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var squash := absf(cos(m.rot))  # spins edge-on and back
		o.draw_set_transform(at + lift, 0.0, Vector2(maxf(squash, 0.25), 1.0))
		o.draw_circle(Vector2.ZERO, 6.0, Color(0.85, 0.62, 0.15))
		o.draw_circle(Vector2(-1, -1), 4.5, Color(1.0, 0.84, 0.3))
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The vintage pump (bottom left) with its dial on the round's gas, shaking while it pumps, and the
## hose sagging from its side to the nozzle in your hand.
func _draw_pump(o: Node2D, tip: Vector2) -> void:
	var tex: Texture2D = _tex.get("pump_hud")
	var shake := Vector2(sin(_t * 60.0), 0) * (1.5 if pouring else 0.0)
	var at := PUMP_AT + shake
	var outlet := at + Vector2(34, 46) * 2.0
	var hand := tip - NOZZLE_TIP + NOZZLE_HOSE
	var sag := (outlet + hand) * 0.5 + Vector2(0, 160)
	var prev := outlet
	for i in range(1, 25):
		var k := i / 24.0
		var p := outlet.lerp(sag, k).lerp(sag.lerp(hand, k), k)
		o.draw_line(prev, p, Color(0.08, 0.08, 0.09), 9.0, true)
		o.draw_line(prev + Vector2(-1, -2), p + Vector2(-1, -2), Color(0.25, 0.25, 0.28), 2.0, true)
		prev = p
	if tex:
		o.draw_set_transform(at, 0.0, Vector2(2, 2))
		o.draw_texture(tex, Vector2.ZERO)
		o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var c := at + Vector2(18, 42) * 2.0
	var a := PI * (1.0 - clampf(tank / tank_size, 0.0, 1.0))
	o.draw_line(c, c + Vector2(cos(a), -sin(a)) * 13.0, Color(0.75, 0.1, 0.08), 2.0, true)
	o.draw_circle(c, 2.5, Color(0.1, 0.1, 0.1))


## Tips in the jar (coins pile up inside), sales as a heap of bills beside it. No running counter:
## the round's summary adds it up (#36).
func _draw_till(o: Node2D, font: Font) -> void:
	var bills: Texture2D = _tex.get("bill")
	var n := mini(int(bills_shown / 5.0 + 0.5), 48)
	for i in n:
		var p := PILE_AT + Vector2(((i * 37) % 5 - 2) * 9, -(i / 5) * 5 + ((i * 13) % 3) * 2)
		if bills:
			o.draw_set_transform(p, ((i * 53) % 7 - 3) * 0.12, Vector2(2, 2))
			o.draw_texture(bills, -bills.get_size() * 0.5)
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var jar: Texture2D = _tex.get("tip_jar")
	if jar:
		o.draw_texture_rect(jar, JAR_RECT, false)
	var level := clampf(jar_shown / 25.0, 0.0, 1.0)
	var inner := Rect2(JAR_RECT.position + Vector2(10, 10), Vector2(28, 42))
	var rows := int(level * 9.0 + 0.999) if jar_shown > 0.0 else 0
	for row in rows:
		for col in 4:
			var cp := Vector2(inner.position.x + 4 + col * 7 + (row % 2) * 3, inner.end.y - 3 - row * 4.5)
			o.draw_circle(cp, 3.5, Color(0.85, 0.62, 0.15))
			o.draw_circle(cp + Vector2(-1, -1), 2.2, Color(1.0, 0.84, 0.3))
	if jar:  # the label stays in front of the coins
		o.draw_texture_rect_region(jar, Rect2(JAR_RECT.position + Vector2(8, 26), Vector2(32, 14)), Rect2(4, 13, 16, 7))
	var tips := "$%.2f" % jar_shown
	var tw := font.get_string_size(tips, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	o.draw_string_outline(font, Vector2(JAR_RECT.get_center().x - tw * 0.5, JAR_RECT.position.y - 6), tips, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 5, Color(0, 0, 0, 0.8))
	o.draw_string(font, Vector2(JAR_RECT.get_center().x - tw * 0.5, JAR_RECT.position.y - 6), tips, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1.0, 0.85, 0.3))


## What the regulars say, in a bubble over the one who said it.
func _draw_quip(o: Node2D, font: Font) -> void:
	if quip_t <= 0.0 or quip_text == "":
		return
	var where: Variant = regular_head(regulars[quip_who].seat)
	if where == null:
		return
	var head: Vector2 = where
	var w := font.get_string_size(quip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 18
	var box := Rect2(head + Vector2(-16, -46), Vector2(w, 26))
	box.position.x = clampf(box.position.x, 6, WIDTH - w - 6)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.98, 0.96, 0.9, minf(quip_t * 3.0, 1.0))
	sb.set_corner_radius_all(10)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.1, 0.09, 0.08, minf(quip_t * 3.0, 1.0))
	o.draw_style_box(sb, box)
	o.draw_colored_polygon(PackedVector2Array([head + Vector2(-4, -21), head + Vector2(8, -21), head + Vector2(0, -10)]), sb.bg_color)
	o.draw_string(font, box.position + Vector2(9, 18), quip_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.1, 0.09, 0.08, minf(quip_t * 3.0, 1.0)))


var _vignette: GradientTexture2D


## HD-2D's soft dark edges.
func _draw_vignette(o: Node2D) -> void:
	if not _vignette:
		var g := Gradient.new()
		g.set_color(0, Color(0, 0, 0, 0))
		g.set_color(1, Color(0.05, 0.03, 0.02, 0.55))
		g.set_offset(0, 0.55)
		_vignette = GradientTexture2D.new()
		_vignette.gradient = g
		_vignette.fill = GradientTexture2D.FILL_RADIAL
		_vignette.fill_from = Vector2(0.5, 0.5)
		_vignette.fill_to = Vector2(1.05, 1.05)
		_vignette.width = 256
		_vignette.height = 144
	o.draw_texture_rect(_vignette, Rect2(0, 0, WIDTH, HEIGHT), false)


func _draw_hud(o: Node2D, font: Font) -> void:
	if hd:
		_draw_vignette(o)
	var h := hour_now()
	var clock := "DAY %d     %d h %02d" % [round_num, int(h), int(fmod(h, 1.0) * 60.0) / 15 * 15]
	var cw := font.get_string_size(clock, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	o.draw_string_outline(font, Vector2((WIDTH - cw) * 0.5, 30), clock, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 8, Color(0, 0, 0, 0.8))
	o.draw_string(font, Vector2((WIDTH - cw) * 0.5, 30), clock, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	_draw_till(o, font)
	_draw_quip(o, font)
	var combo_text := "x%d COMBO" % combo.multiplier
	o.draw_string(font, Vector2(WIDTH - 150, 30), combo_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.9))
	if round_wasted > 0.05:
		o.draw_string(font, Vector2(WIDTH - 150, 56), "wasted $%.2f" % round_wasted, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(GAS, 0.9))
	if round_over and not managed:
		o.draw_rect(Rect2(0, 0, WIDTH, HEIGHT), Color(0, 0, 0, 0.55))
		var lines := ["FERMÉ   ROUND %d" % round_num, "",
			"Sales (the bills)      $%.2f" % round_sales,
			"Tips (the jar)          $%.2f" % round_tips,
			"Gas used               -$%.2f   (wasted $%.2f)" % [round_fuel_cost(), round_wasted],
			"Net                      $%.2f" % (round_earned - round_fuel_cost()),
			"In the bank           $%.2f" % (cash - round_fuel_cost()), "",
			"ENTER  open again        ESC  quit"]
		for i in lines.size():
			var lw := font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26 if i == 0 else 20).x
			o.draw_string(font, Vector2((WIDTH - lw) * 0.5, 230 + i * 34), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 26 if i == 0 else 20,
				Color(1.0, 0.85, 0.3) if i == 0 else Color.WHITE)
