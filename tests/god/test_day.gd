extends GutTest
## Spec: features/god_day.feature (#37): what shapes a GOD PUMP day.

const SCENE := preload("res://scenes/god/day/god_pump.tscn")

var game: GodPump


func before_each() -> void:
	game = SCENE.instantiate()
	game.auto_traffic = false
	game.sound_on = false
	game.view = "flat"
	add_child_autofree(game)
	game.rng.seed = 11


func _mods(changes := {}) -> Dictionary:
	var m := GodData.BASE.duplicate()
	for k in changes:
		m[k] = changes[k]
	return m


func _open(changes := {}, pool := ["sedan"]) -> void:
	game.start_day(_mods(changes), 800.0, 1, pool)


func _parked(type_id := "sedan", at := Vector2(500, 380), target := 20.0) -> ProtoCar:
	var car := game.park_customer(target, at)
	car.set_type(type_id, game.rng)
	car.target = target
	car.moving = false
	return car


func test_the_clock_limits_the_day() -> void:
	_open()
	assert_almost_eq(game.round_seconds, 27.0, 0.01)
	assert_almost_eq(game.hour_now(), 7.0, 0.01)
	for i in 28:
		game.step(1.0)
	assert_true(game.round_over)


func test_marketing_queues_cars_at_opening() -> void:
	_open({"queue": 3})
	var waiting := game.cars.filter(func(c: ProtoCar) -> bool: return c.customer and c.accepts_fuel())
	assert_eq(waiting.size(), 3)


func test_auto_aim_bends_the_stream_onto_a_nearby_car() -> void:
	_open({"auto_aim": 60.0})
	var car := _parked()
	game.aim(car.position + Vector2(70, 0))
	game.set_pouring(true)
	game.step(1.0)
	assert_gt(car.amount, 3.0)


func test_without_auto_aim_the_same_pour_misses() -> void:
	_open()
	var car := _parked()
	game.aim(car.position + Vector2(70, 0))
	game.set_pouring(true)
	game.step(1.0)
	assert_almost_eq(car.amount, 0.0, 0.001)


func test_twin_stream_fills_two_cars() -> void:
	_open({"twin_stream": 1})
	var a := _parked("sedan", Vector2(500, 380))
	var b := _parked("sedan", Vector2(580, 380))
	game.aim(a.position)
	game.set_pouring(true)
	game.step(1.0)
	assert_gt(a.amount, 3.0)
	assert_gt(b.amount, 3.0)


func test_a_drone_fills_and_settles_a_car() -> void:
	_open({"drones": 1})
	var car := _parked()
	for i in 200:
		game.step(0.1)
		if car.tier != "":
			break
	assert_ne(car.tier, "")
	assert_true(car.by_drone)


func test_the_pickup_pays_80_percent() -> void:
	_open()
	var car := _parked("pickup", Vector2(500, 380), 50.0)
	car.amount = 50.0
	game._settle(car)
	assert_almost_eq(game.round_sales, 40.0, 0.01)


func test_the_bazou_takes_fuel_slower() -> void:
	_open()
	var car := _parked("bazou")
	game.aim(car.position)
	game.set_pouring(true)
	game.step(1.0)
	assert_almost_eq(car.amount, game.flow_rate * 0.6, 0.05)


func test_the_thief_siphons_gas_and_pouring_scares_it() -> void:
	_open({}, ["sedan", "thief"])
	var victim := _parked("sedan", Vector2(500, 380))
	victim.amount = 15.0
	var thief := game.park_customer(0.0, Vector2(540, 380))
	thief.set_type("thief", game.rng)
	thief.moving = false
	for i in 20:
		game.step(0.1)
	assert_lt(victim.amount, 15.0)
	assert_gt(game.stolen, 0.0)
	game.aim(thief.position)
	game.set_pouring(true)
	game.step(0.1)
	assert_eq(thief.phase, ProtoCar.Phase.LEAVING)


func test_pouring_on_the_electric_car_costs_a_fine() -> void:
	_open({}, ["sedan", "electric"])
	var e := game.park_customer(0.0, Vector2(500, 380))
	e.set_type("electric", game.rng)
	e.moving = false
	game.aim(e.position)
	game.set_pouring(true)
	game.step(0.1)
	assert_almost_eq(game.fines, 10.0, 0.01)


func test_the_sweeper_cleans_puddles() -> void:
	_open()
	game._spill(Vector2(500, 380), 2.0)
	var sw := game.park_customer(0.0, Vector2(500, 380))
	sw.set_type("sweeper", game.rng)
	sw.moving = false
	game.step(0.1)
	assert_eq(game.puddles.size(), 0)


func test_the_clumsy_car_makes_others_spill() -> void:
	_open()
	var victim := _parked("sedan", Vector2(500, 380))
	victim.amount = 12.0
	var clumsy := _parked("clumsy", Vector2(530, 380))
	game.step(0.1)
	assert_lt(victim.amount, 12.0)
	assert_gt(game.round_wasted, 0.0)


func test_a_car_waiting_too_long_drives_off_unserved() -> void:
	_open()
	game.reset_day_stats()
	var car := _parked()
	car.patience = 2.0
	for i in 30:
		game.step(0.1)
	assert_eq(game.day_stats.tiers[ScoreTiers.UNSERVED], 1)
	assert_eq(car.phase, ProtoCar.Phase.LEAVING)


func test_combo_lock_keeps_the_chain_on_an_ok() -> void:
	_open({"combo_lock": 1})
	var a := _parked("sedan", Vector2(400, 380))
	a.amount = 20.0
	game._settle(a)
	var before: int = game.combo.multiplier
	var b := _parked("sedan", Vector2(700, 380))
	b.amount = 17.0
	game._settle(b)
	assert_eq(game.combo.multiplier, before)


func test_shop_bonuses_reach_the_till() -> void:
	_open({"per_car_bonus": 2.0, "tip_mult": 2.0})
	var car := _parked()
	car.amount = 20.0
	game._settle(car)
	assert_almost_eq(game.round_sales, 22.0, 0.01)
	assert_almost_eq(car.tip, game.tip_for(1.0, 0.0) * 2.0, 0.01)


func test_the_day_report_and_the_signal() -> void:
	game.managed = true
	_open()
	watch_signals(game)
	var car := _parked()
	car.amount = 20.0
	game._settle(car)
	game.end_round()
	assert_signal_emitted(game, "day_over")
	var r: Dictionary = game.day_report()
	for key in ["loot", "tank_left", "xp", "cars", "tiers", "accuracy", "best_combo"]:
		assert_true(r.has(key), key)
	assert_eq(r.cars, 1)
