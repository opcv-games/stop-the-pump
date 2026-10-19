extends GutTest
## Spec: features/day.feature. Refs #8

var tank: TankComponent


func before_each() -> void:
	tank = TankComponent.new()
	tank.capacity_liters = 400.0
	tank.price_per_liter = 2.0
	add_child_autofree(tank)


func test_given_new_tank_then_it_is_full() -> void:
	assert_eq(tank.liters, 400.0)


func test_given_full_tank_when_20_dollars_drawn_then_390_litres_left() -> void:
	assert_almost_eq(tank.draw(20.0), 20.0, 0.001)
	assert_almost_eq(tank.liters, 390.0, 0.001)
	assert_almost_eq(tank.liters_used(), 10.0, 0.001)


func test_given_1_litre_left_when_5_dollars_requested_then_only_2_dollars_drawn_and_tank_empties() -> void:
	tank.liters = 1.0
	watch_signals(tank)
	assert_almost_eq(tank.draw(5.0), 2.0, 0.001)
	assert_true(tank.is_empty())
	assert_signal_emitted(tank, "emptied")


func test_given_used_tank_when_refilled_then_full_and_returns_litres_added() -> void:
	tank.draw(100.0)
	assert_almost_eq(tank.refill(), 50.0, 0.001)
	assert_eq(tank.liters, 400.0)


func test_given_tank_then_remaining_value_is_litres_times_price() -> void:
	tank.draw(100.0)
	assert_almost_eq(tank.remaining_value(), 700.0, 0.001)
