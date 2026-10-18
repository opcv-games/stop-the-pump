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
