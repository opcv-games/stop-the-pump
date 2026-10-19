extends GutTest
## Spec: features/core_loop.feature — pouring and stopping one pump. Refs #1

var pump: PumpComponent


func before_each() -> void:
	pump = PumpComponent.new()
	pump.flow_rate = 4.0
	add_child_autofree(pump)
	pump.reset(20.0)


func test_given_idle_pump_when_time_passes_then_amount_stays_zero() -> void:
	pump.tick(1.0)
	assert_eq(pump.amount, 0.0)


func test_given_idle_pump_when_pour_held_for_one_second_then_amount_climbs_by_flow_rate() -> void:
	pump.start_pour()
	pump.tick(1.0)
	assert_almost_eq(pump.amount, 4.0, 0.001)


func test_given_pouring_when_released_then_amount_stops_climbing() -> void:
	pump.start_pour()
	pump.tick(1.0)
	pump.stop_pour()
	pump.tick(1.0)
	assert_almost_eq(pump.amount, 4.0, 0.001)


func test_given_pouring_when_released_then_stopped_signal_carries_final_amount() -> void:
	watch_signals(pump)
	pump.start_pour()
	pump.tick(0.5)
	pump.stop_pour()
	assert_signal_emitted_with_parameters(pump, "stopped", [2.0])


func test_given_pump_already_stopped_when_pour_pressed_again_then_it_does_not_restart() -> void:
	pump.start_pour()
	pump.tick(1.0)
	pump.stop_pour()
	pump.start_pour()
	pump.tick(1.0)
	assert_almost_eq(pump.amount, 4.0, 0.001)


func test_given_stopped_pump_when_reset_for_new_customer_then_amount_is_zero_and_target_updates() -> void:
	pump.start_pour()
	pump.tick(1.0)
	pump.stop_pour()
	pump.reset(35.0)
	assert_eq(pump.amount, 0.0)
	assert_eq(pump.target, 35.0)


func test_given_pump_fed_by_tank_when_pouring_then_tank_drains() -> void:
	var tank := TankComponent.new()
	tank.price_per_liter = 2.0
	add_child_autofree(tank)
	pump.tank = tank
	pump.start_pour()
	pump.tick(1.0)
	assert_almost_eq(tank.liters, tank.capacity_liters - 2.0, 0.001)


func test_given_tank_with_1_litre_when_pouring_past_it_then_pump_stops_at_2_dollars() -> void:
	var tank := TankComponent.new()
	tank.price_per_liter = 2.0
	add_child_autofree(tank)
	tank.liters = 1.0
	pump.tank = tank
	watch_signals(pump)
	pump.start_pour()
	pump.tick(5.0)
	assert_almost_eq(pump.amount, 2.0, 0.001)
	assert_true(pump.is_done)
	assert_signal_emitted_with_parameters(pump, "stopped", [2.0])


func test_given_customer_when_finished_at_20_then_pump_stops_at_20() -> void:
	watch_signals(pump)
	pump.finish_at(20.0)
	assert_signal_emitted_with_parameters(pump, "stopped", [20.0])
	assert_true(pump.is_done)
