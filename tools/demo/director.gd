extends SceneTree
## GOD PUMP's 45-second demo video (playtest 7). A director plays the real game on a timeline (intro,
## title, a day poured by an autopilot, the report, the night shop, the truck's cards, a late-game day
## with drones and troublemakers, Dad's line, the credits) while Godot's Movie Maker records it:
##
##     godot --path . --write-movie docs/video/demo.avi --fixed-fps 30 --resolution 1920x1080 -s tools/demo/director.gd
##     ffmpeg -y -i docs/video/demo.avi -c:v libx264 -pix_fmt yuv420p -crf 20 -c:a aac -b:a 160k docs/video/godpump_demo.mp4

const FPS := 30.0
const META := "user://demo_meta.cfg"

var g: GodGame
var f := 0
var _car: ProtoCar
var _plan := 1.0
var _last_amount := 0.0
var _aim := Vector2(576, 380)
var _rest := 0.0
var _drawn := -1


func t() -> float:
	return f / FPS


func at(sec: float) -> bool:
	return f == int(round(sec * FPS))


func _initialize() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)  # a covered window isn't drawn
	root.gui_disable_input = true  # the real mouse would fight the autopilot
	DirAccess.remove_absolute(ProjectSettings.globalize_path(META))
	g = load("res://scenes/god/god_game.tscn").instantiate()
	g.meta_path = META
	root.add_child(g)


func _process(_dt: float) -> bool:
	if Engine.get_frames_drawn() <= _drawn:
		return false  # the timeline follows the recorded frames
	_drawn = Engine.get_frames_drawn()
	if at(0.0):
		for n in [g, g.day, g.cinematic]:
			n.set_process_unhandled_input(false)
		g.meta.intro_seen = true
		g._play_cinematic([
			{"bg": "black", "text": "OPCV Games presents", "hold": 99.0},
			{"bg": "black", "text": "In the beginning, there was gas.", "hold": 99.0},
			{"bg": "heaven", "nozzle": true, "title": true, "text": "", "hold": 99.0, "choir": true},
			{"bg": "scene", "text": "Saint-Clin-Clin-des-Meuh-Meuh, Québec.", "hold": 99.0, "last": true},
		], "title")
	for s in [1.8, 4.0, 7.6]:
		if at(s):
			g.cinematic.advance()
	if at(9.6):
		g.cinematic.visible = false
		g.show_title()
	if at(11.2):
		_day_a()
	if at(24.0):
		g.day.set_pouring(false)
		_clear_waiting()
		g.day.end_round()
	if at(27.0):
		g._after_report()
	if at(28.0):
		g.night.tree.press("marketing:%d" % g.run.owned.get("marketing", 0))
	if at(28.8):
		g.night.tree.press("hours:%d" % g.run.owned.get("hours", 0))
	if at(29.6):
		g.night.tree.press("vibe:%d" % g.run.owned.get("vibe", 0))
	if at(30.6):
		g.run.tank = g.run.tank_capacity() * 0.3
		g.run.cash += 2000.0
		g.night.refresh()
		g.call_truck()
	if at(32.8):
		var id: String = g.run.offer[0]
		g.run.pick_card(id)
		g.cards.picked.emit(id)
	if at(33.8):
		_day_b()
	if at(41.2):
		g.day.set_pouring(false)
		g.day.round_over = true
		g._play_cinematic([
			{"bg": "heaven", "nozzle": true, "text": "\"T'es un vrai gaz bar boy.\"", "choir": true, "hold": 99.0},
			{"bg": "heaven", "title": true, "text": "Thanks for playing.", "credits": true, "last": true},
		], "title")
	if at(43.2):
		g.cinematic.advance()
	if g.state == "day" and not g.day.round_over:
		_autopilot()
	f += 1
	if f % 150 == 0:
		print("demo frame %d drawn %d" % [f, Engine.get_frames_drawn()])
	return f > int(45.0 * FPS)


## The demo closes the day early: cars still waiting leave quietly instead of counting as misses.
func _clear_waiting() -> void:
	for c in g.day.cars.duplicate():
		if c.customer and c.accepts_fuel() and c.fill() < ProtoCar.LEAVE_AT:
			g.day.cars.erase(c)
			c.queue_free()


## Day 6 of a good run: a few upgrades on the lot, the first car types unlocked.
func _day_a() -> void:
	g.meta.total_cars = 200
	g.meta.owned_nozzles = ["classique", "laser"]
	g.meta.nozzle = "laser"  # flow +40%: more fills in a short clip
	g.run = RunState.new(g.meta)
	g.run.rng.seed = 6
	g.run.day = 6
	g.run.cash = 180.0
	g.run.owned = {"hours": 2, "marketing": 2, "attractions": 2, "nozzle": 3, "service": 1, "vibe": 1, "tank": 1}
	g.day.rng.seed = 66
	g.start_day()
	g.day.tank = g.run.tank


## Day 31: everything unlocked, drones flying, thieves and sweepers on the lot.
func _day_b() -> void:
	g.meta.total_cars = 1500
	g.run.day = 31
	g.run.owned = {"hours": 4, "marketing": 3, "attractions": 4, "nozzle": 6, "service": 3, "vibe": 3, "tank": 3}
	g.run.tank = g.run.tank_capacity()
	g.start_day()


## Chase a car, pour, and let go on a Topped off (or a Perfect, now and then).
func _autopilot() -> void:
	var day := g.day
	if _rest > 0.0:
		_rest -= 1.0 / FPS
		return
	if not _car or not is_instance_valid(_car) or not _car.accepts_fuel():
		_car = null
		var best := INF
		for c in day.cars:
			if c.customer and c.accepts_fuel() and not c.drone_target and c.fill() < 0.8:
				var d := _aim.distance_to(c.position) + (c.target - c.amount) * 25.0  # near, and quick to finish
				if d < best:
					best = d
					_car = c
		_plan = 0.998 if randf() < 0.7 else 0.98
		_last_amount = _car.amount if _car else 0.0
		if not _car:
			day.set_pouring(false)
			return
	var gap := _car.position - _aim
	_aim += gap.normalized() * minf(gap.length(), 900.0 / FPS)
	if gap.length() < 40.0:
		_aim = _car.position  # locked on
		gap = Vector2.ZERO
	day.aim(_aim)
	if gap.length() > 14.0:
		day.set_pouring(false)
		_last_amount = _car.amount
		return
	day.set_pouring(true)
	var rate := (_car.amount - _last_amount) * FPS
	_last_amount = _car.amount
	var left := _plan * _car.target - _car.amount
	if rate > 0.0 and left < rate / FPS:
		if left > 0.0:
			day.step(left / rate)
		day.set_pouring(false)
		_car = null
		_rest = 0.35
