extends GutTest
## Spec: features/self_service.feature. Refs #17

var pump: PumpComponent
var ss: SelfServiceComponent


func before_each() -> void:
	pump = PumpComponent.new()
	pump.flow_rate = 2.0
	add_child_autofree(pump)
	ss = SelfServiceComponent.new()
	ss.card_wait_min = 1.0
	ss.card_wait_max = 1.0
	ss.paying_seconds = 1.0
	add_child_autofree(ss)
	ss.attach(pump)
	pump.reset(20.0)
	ss.begin()


func test_given_customer_fumbling_with_card_then_nothing_pours() -> void:
	ss.tick(0.9)
	assert_eq(pump.amount, 0.0)
	assert_eq(ss.phase, SelfServiceComponent.Phase.CARD)


func test_given_card_ready_then_pumps_at_flow_rate() -> void:
	ss.tick(1.0)
	ss.tick(2.0)
	assert_almost_eq(pump.amount, 4.0, 0.001)
	assert_eq(ss.phase, SelfServiceComponent.Phase.PUMPING)


func test_given_pumping_then_stops_exactly_on_the_order() -> void:
	watch_signals(pump)
	ss.tick(1.0)
	for i in 30:
		ss.tick(0.37)
	assert_almost_eq(pump.amount, 20.0, 0.0001)
	assert_signal_emitted_with_parameters(pump, "stopped", [20.0])


func test_given_order_pumped_then_pays_after_paying_time() -> void:
	watch_signals(ss)
	ss.tick(1.0)
	ss.tick(10.0)
	assert_signal_not_emitted(ss, "paid")
	ss.tick(1.0)
	assert_signal_emitted_with_parameters(ss, "paid", [20.0])
	assert_eq(ss.phase, SelfServiceComponent.Phase.IDLE)


func test_given_self_service_then_pump_does_not_run_on_its_own() -> void:
	assert_false(pump.is_processing())
