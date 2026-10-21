extends GutTest
## Spec: features/god_pump.feature (#36): pour from the sky onto cars driving around the lot.

const SCENE := preload("res://scenes/prototype/god_pump.tscn")

var game: GodPump


func before_each() -> void:
	game = SCENE.instantiate()
	game.auto_traffic = false  # tests place cars themselves
	game.sound_on = false
	add_child_autofree(game)
	game.rng.seed = 4


func _car(target: float, at := Vector2(500, 380)) -> ProtoCar:
	var car := game.park_customer(target, at)
	car.wander = false  # holds still so the stream stays on it
	return car


func test_holding_on_a_car_fills_it_at_the_flow_rate() -> void:
	var car := _car(20.0)
	game.aim(car.position)
	game.set_pouring(true)
	game.step(1.0)
	assert_almost_eq(car.amount, game.flow_rate, 0.01)


func test_underfilled_car_keeps_driving_around() -> void:
	var car := _car(20.0)
	car.amount = 15.0
	assert_eq(car.stream_left(), "")
	assert_eq(car.phase, ProtoCar.Phase.WANDER)


func test_overshoot_decides_the_tier() -> void:
	var cases := {20.0: ScoreTiers.SUPER_PERFECT, 20.08: ScoreTiers.PERFECT, 20.4: ScoreTiers.GOOD,
		20.9: ScoreTiers.OK, 22.0: ScoreTiers.MISS}
	for amount in cases:
		var car := _car(20.0)
		car.amount = amount
		assert_eq(car.stream_left(), cases[amount], "%.2f" % amount)


func test_a_filled_car_celebrates_then_drives_away() -> void:
	var car := _car(20.0)
	car.amount = 20.0
	car.stream_left()
	assert_eq(car.phase, ProtoCar.Phase.CELEBRATE)
	for i in 40:
		car.step(0.05, game)
	assert_eq(car.phase, ProtoCar.Phase.LEAVING)


func test_releasing_on_a_full_car_settles_and_pays() -> void:
	var car := _car(10.0)
	game.aim(car.position)
	game.set_pouring(true)
	game.step(2.5)  # exactly $10 at $4/s
	game.set_pouring(false)
	assert_eq(car.tier, ScoreTiers.SUPER_PERFECT)
	assert_gt(game.round_earned, 10.0, "sale + Super Perfect tip")


func test_moving_the_stream_off_a_car_settles_it_too() -> void:
	var car := _car(10.0)
	game.aim(car.position)
	game.set_pouring(true)
	game.step(2.6)
	game.aim(Vector2(200, 560))  # bare ground
	game.step(0.01)
	assert_ne(car.tier, "")


func test_pouring_on_the_floor_wastes_gas_and_leaves_a_puddle() -> void:
	game.aim(Vector2(200, 560))
	game.set_pouring(true)
	game.step(1.0)
	assert_almost_eq(game.round_wasted, game.flow_rate, 0.01)
	assert_gt(game.puddles.size(), 0)


func test_traffic_brings_cars_and_only_some_pull_in() -> void:
	game.auto_traffic = true
	game.customer_chance = 0.5
	for i in 600:
		game.step(0.05)
	assert_gt(game.cars_spawned, 10)
	assert_gt(game.customers_arrived, 0)
	assert_lt(game.customers_arrived, game.cars_spawned)


func test_round_end_sends_underfilled_cars_away_paying_what_they_got() -> void:
	var car := _car(20.0)
	car.amount = 8.0
	game.end_round()
	assert_eq(car.phase, ProtoCar.Phase.LEAVING)
	assert_almost_eq(game.round_earned, 8.0, 0.01)


func test_a_round_lasts_15_seconds() -> void:
	assert_almost_eq(game.round_seconds, 15.0, 0.001)
	game.auto_traffic = false
	for i in 16:
		game.step(1.0)
	assert_true(game.round_over)
