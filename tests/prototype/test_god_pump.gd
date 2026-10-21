extends GutTest
## Spec: features/god_pump.feature (#36): pour from the sky onto cars moving around the lot.
## Rules after god-pump playtest 1: leave at 80%, tips grow toward 100%, overflow spills, gas ends the round.

const SCENE := preload("res://scenes/prototype/god_pump.tscn")

var game: GodPump


func before_each() -> void:
	game = SCENE.instantiate()
	game.auto_traffic = false  # tests place cars themselves
	game.sound_on = false
	game.iso = false  # most rules are checked in world coordinates; the iso tests switch it on
	add_child_autofree(game)
	game.rng.seed = 4


func _car(target: float, at := Vector2(500, 380)) -> ProtoCar:
	var car := game.park_customer(target, at)
	car.moving = false  # holds still so the stream stays on it
	return car


func _pour_on(car: ProtoCar, seconds: float) -> void:
	game.aim(car.position)
	game.set_pouring(true)
	game.step(seconds)


func test_holding_on_a_car_fills_it_at_the_flow_rate() -> void:
	var car := _car(20.0)
	_pour_on(car, 1.0)
	assert_almost_eq(car.amount, game.flow_rate, 0.01)


func test_below_80_percent_the_car_keeps_moving() -> void:
	var car := _car(20.0)
	car.amount = 15.0
	assert_eq(car.stream_left(), "")
	assert_eq(car.phase, ProtoCar.Phase.WANDER)


func test_at_80_percent_the_car_pays_and_leaves() -> void:
	var car := _car(20.0)
	car.amount = 17.0
	assert_ne(car.stream_left(), "")
	assert_eq(car.phase, ProtoCar.Phase.CELEBRATE)
	for i in 40:
		car.step(0.05, game)
	assert_eq(car.phase, ProtoCar.Phase.LEAVING)


func test_tips_grow_toward_100_percent() -> void:
	assert_eq(game.tip_for(0.85, 0.0), game.tip_for(0.85, 0.0))
	assert_lt(game.tip_for(0.85, 0.0), game.tip_for(0.95, 0.0))
	assert_lt(game.tip_for(0.95, 0.0), game.tip_for(1.0, 1.0), "full, even with a spill, beats 95%")
	assert_lt(game.tip_for(1.0, 1.0), game.tip_for(1.0, 0.0), "topped off without spilling tips the most")
	assert_almost_eq(game.tip_for(0.8, 0.0), 0.0, 0.001)


func test_fill_grades() -> void:
	var cases := [[17.0, 0.0, ScoreTiers.OK], [19.2, 0.0, ScoreTiers.GOOD], [20.0, 0.0, ScoreTiers.SUPER_PERFECT],
		[20.0, 2.0, ScoreTiers.PERFECT]]
	for c in cases:
		var car := _car(20.0)
		car.amount = c[0]
		car.spilled = c[1]
		assert_eq(car.stream_left(), c[2], "%.1f spilled %.1f" % [c[0], c[1]])


func test_overflow_spills_as_wasted_gas() -> void:
	var car := _car(10.0)
	_pour_on(car, 3.0)  # $12 poured on a $10 car
	assert_almost_eq(car.amount, 10.0, 0.01)
	assert_almost_eq(game.round_wasted, 2.0, 0.05)
	assert_gt(game.puddles.size(), 0)


func test_releasing_on_a_full_car_pays_sale_and_top_tip() -> void:
	var car := _car(10.0)
	_pour_on(car, 2.5)  # exactly $10 at $4/s
	game.set_pouring(false)
	assert_eq(car.tier, ScoreTiers.SUPER_PERFECT)
	assert_almost_eq(game.round_earned, 10.0 + game.tip_for(1.0, 0.0), 0.01)


func test_moving_the_stream_off_a_car_settles_it() -> void:
	var car := _car(10.0)
	_pour_on(car, 2.2)
	game.aim(Vector2(200, 560))  # bare ground
	game.step(0.01)
	assert_ne(car.tier, "")


func test_pouring_on_the_floor_wastes_gas_and_leaves_a_puddle() -> void:
	game.aim(Vector2(200, 560))
	game.set_pouring(true)
	game.step(1.0)
	assert_almost_eq(game.round_wasted, game.flow_rate, 0.01)
	assert_gt(game.puddles.size(), 0)


func test_pouring_draws_from_the_round_tank() -> void:
	var start: float = game.tank
	game.aim(Vector2(200, 560))
	game.set_pouring(true)
	game.step(1.0)
	assert_almost_eq(game.tank, start - game.flow_rate, 0.01)


func test_an_empty_tank_ends_the_round() -> void:
	game.tank = 2.0
	game.aim(Vector2(200, 560))
	game.set_pouring(true)
	game.step(1.0)
	assert_true(game.round_over)
	assert_almost_eq(game.tank, 0.0, 0.001)


func test_the_clock_is_a_safeguard() -> void:
	for i in int(game.round_seconds) + 1:
		game.step(1.0)
	assert_true(game.round_over)
	assert_gt(game.round_seconds, 15.0, "gas is the main limit")


func test_traffic_brings_cars_and_only_some_pull_in() -> void:
	game.auto_traffic = true
	game.customer_chance = 0.5
	for i in 400:
		game.step(0.05)
	assert_gt(game.cars_spawned, 10)
	assert_gt(game.customers_arrived, 0)
	assert_lt(game.customers_arrived, game.cars_spawned)


func test_cars_move_in_readable_patterns() -> void:
	var seen := {}
	for i in 30:
		seen[game.park_customer(20.0, Vector2(500, 380)).pattern] = true
	for p in ProtoCar.PATTERNS:
		assert_true(seen.has(p), p)


func test_a_looping_car_comes_back_round() -> void:
	var car := game.park_customer(20.0, Vector2(500, 380))
	car.pattern = "loop"
	car.start_pattern(game)
	var start := car.position
	var far := 0.0
	for i in 400:
		car.step(0.05, game)
		far = maxf(far, car.position.distance_to(start))
	assert_gt(far, 150.0, "it travels round the lot")


func test_round_end_sends_cars_away_paying_what_they_got() -> void:
	var car := _car(20.0)
	car.amount = 8.0
	game.end_round()
	assert_eq(car.phase, ProtoCar.Phase.LEAVING)
	assert_almost_eq(game.round_earned, 8.0, 0.01)


func test_a_filled_car_drops_bills_for_the_sale_and_coins_for_the_tip() -> void:
	var car := _car(20.0)
	_pour_on(car, 5.0)  # $20: topped off
	game.set_pouring(false)
	var bills := game.money.filter(func(m: Dictionary) -> bool: return m.kind == "bill")
	var coins := game.money.filter(func(m: Dictionary) -> bool: return m.kind == "coin")
	assert_gt(bills.size(), 0)
	assert_gt(coins.size(), 0)
	var sale := 0.0
	for b in bills:
		sale += b.value
	assert_almost_eq(sale, 20.0, 0.01)


func test_dropped_cash_lands_in_the_counter() -> void:
	var car := _car(20.0)
	_pour_on(car, 5.0)
	game.set_pouring(false)
	for i in 60:
		game.step(0.05)
	assert_true(game.money.is_empty())
	assert_almost_eq(game.shown_cash, game.cash, 0.01)


func test_iso_view_maps_the_mouse_back_to_the_ground() -> void:
	game.set_iso(true)
	var w := Vector2(640, 410)
	assert_almost_eq(game.to_world(game.scr(w)).distance_to(w), 0.0, 0.01)
	assert_ne(game.scr(w), w, "the iso view moves things on screen")


func test_iso_view_hides_the_flat_cars_and_pours_where_the_mouse_points() -> void:
	game.set_iso(true)
	var car := _car(10.0)
	assert_false(car.visible)
	game.aim(game.to_world(game.scr(car.position)))
	game.set_pouring(true)
	game.step(1.0)
	assert_almost_eq(car.amount, game.flow_rate, 0.01)


func test_i_switches_views() -> void:
	var before: bool = game.iso
	var key := InputEventKey.new()
	key.physical_keycode = KEY_I
	key.pressed = true
	game._unhandled_input(key)
	assert_ne(game.iso, before)


# --- Requests after the isometric try (#36) -----------------------------------------------------

func test_spilled_gas_stays_for_the_whole_round_and_goes_with_it() -> void:
	game.aim(Vector2(200, 560))
	game.set_pouring(true)
	game.step(1.0)
	game.set_pouring(false)
	for i in 30:
		game.step(1.0)
	assert_gt(game.puddles.size(), 0, "still there 30 s later")
	game.end_round()
	game.next_round()
	assert_eq(game.puddles.size(), 0)


func test_tips_go_to_the_jar_and_sales_pile_up_as_bills() -> void:
	var car := _car(10.0)
	_pour_on(car, 2.5)
	game.set_pouring(false)
	assert_almost_eq(game.tip_jar, game.tip_for(1.0, 0.0), 0.01)
	assert_almost_eq(game.round_sales, 10.0, 0.01)


func test_the_clock_runs_from_7_to_13_and_the_sign_flips() -> void:
	assert_almost_eq(game.hour_now(), 7.0, 0.01)
	assert_true(game.is_open())
	game.round_t = game.round_seconds * 0.5
	assert_almost_eq(game.hour_now(), 10.0, 0.01)
	game.end_round()
	assert_false(game.is_open())


func test_good_or_better_flashes_the_neon_ok_does_not() -> void:
	var car := _car(10.0)
	car.amount = 8.5
	game._settle(car)
	assert_almost_eq(game.neon_flash, 0.0, 0.001, "OK: no flash")
	var car2 := _car(10.0, Vector2(700, 400))
	car2.amount = 10.0
	game._settle(car2)
	assert_gt(game.neon_flash, 0.0)


func test_the_regulars_hang_out_and_react() -> void:
	assert_eq(game.regulars.size(), 4)
	var car := _car(10.0)
	car.amount = 10.0
	game._settle(car)
	assert_ne(game.quip_text, "", "someone has something to say about a top-off")
