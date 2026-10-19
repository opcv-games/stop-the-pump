extends GutTest
## Spec: features/customers.feature. Refs #5

var pump: PumpComponent
var customer: CustomerComponent


func before_each() -> void:
	pump = PumpComponent.new()
	pump.flow_rate = 4.0
	add_child_autofree(pump)
	customer = CustomerComponent.new()
	customer.patience_seconds = 4.0
	add_child_autofree(customer)
	customer.attach(pump)


func _arrive(type: String, target: float) -> void:
	pump.reset(target)
	customer.begin(type)


func test_given_grandpa_wants_30_when_pour_passes_18_then_order_changes_to_reachable_amount() -> void:
	watch_signals(customer)
	_arrive("grandpa", 30.0)
	pump.start_pour()
	pump.tick(18.2 / 4.0)
	assert_signal_emitted(customer, "order_changed")
	assert_ne(pump.target, 30.0)
	assert_gte(pump.target, pump.amount + 3.0)


func test_given_grandpa_changed_once_then_he_never_changes_again() -> void:
	watch_signals(customer)
	_arrive("grandpa", 30.0)
	pump.start_pour()
	pump.tick(18.2 / 4.0)
	pump.tick(2.0)
	pump.tick(2.0)
	assert_signal_emit_count(customer, "order_changed", 1)


func test_given_regular_when_pouring_then_order_never_changes() -> void:
	_arrive("regular", 30.0)
	pump.start_pour()
	pump.tick(7.0)
	assert_eq(pump.target, 30.0)


func test_given_businessman_when_3_9s_pass_without_pouring_then_he_stays() -> void:
	watch_signals(customer)
	_arrive("businessman", 40.0)
	customer.tick(3.9)
	assert_signal_not_emitted(customer, "drove_off")


func test_given_businessman_when_4s_pass_without_pouring_then_he_drives_off() -> void:
	watch_signals(customer)
	_arrive("businessman", 40.0)
	customer.tick(3.9)
	customer.tick(0.2)
	assert_signal_emit_count(customer, "drove_off", 1)


func test_given_businessman_when_pouring_starts_in_time_then_he_stays() -> void:
	watch_signals(customer)
	_arrive("businessman", 40.0)
	customer.tick(2.0)
	pump.start_pour()
	customer.tick(5.0)
	assert_signal_not_emitted(customer, "drove_off")


func test_given_twenty_guy_then_overshoot_comes_out_of_pocket() -> void:
	_arrive("twenty_guy", 20.0)
	assert_true(customer.out_of_pocket())


func test_given_special_chance_0_then_every_customer_is_regular() -> void:
	for i in 50:
		assert_eq(Customers.roll(0.0, [10.0, 20.0]).type, "regular")


func test_given_twenty_guy_retired_then_he_is_never_rolled() -> void:
	for i in 300:
		assert_ne(Customers.roll(1.0, [10.0, 40.0]).type, "twenty_guy")
