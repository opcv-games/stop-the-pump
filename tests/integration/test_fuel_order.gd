extends GutTest
## Spec: features/fuel_order.feature (#32): the player decides each night how much fuel to buy.

const SCENE := preload("res://scenes/greybox/pump_station.tscn")

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.profile_file = ""
	station.cars_gate_service = false
	station.special_customer_chance = 0.0
	station.arrival_min = 60.0
	station.arrival_max = 60.0
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


## Ends day 1 with `used` litres gone, then opens the night shop.
func _night(used: float, cash: float = 5000.0) -> void:
	station.wallet.add(cash - station.wallet.cash + station.economy.rent_for(1))
	station.tank.draw(used * station.tank.price_per_liter)  # an empty tank closes the day by itself
	station.dev_end_day()
	station.continue_pressed()


func _cost(liters: float) -> float:
	return station.economy.refill_cost(liters)


func test_a_new_run_starts_with_a_full_tank() -> void:
	assert_almost_eq(station.tank.liters, station.tank.capacity_liters, 0.01)


func test_given_leftover_fuel_and_no_order_then_it_carries_over() -> void:
	_night(250.0)
	station.set_fuel_order(0.0)
	station.continue_pressed()
	assert_almost_eq(station.tank.liters, 150.0, 0.01)


func test_the_night_shop_orders_a_fill_up_by_default() -> void:
	_night(250.0)
	assert_almost_eq(station.fuel_order_liters, 250.0, 0.01)
	assert_almost_eq(station.spendable_cash(), station.wallet.cash - _cost(250.0), 0.01)


func test_given_little_cash_then_the_default_order_is_what_it_can_afford() -> void:
	_night(250.0, 200.0)
	assert_almost_eq(station.fuel_order_liters, 200.0 / _cost(1.0), 0.01)


func test_lowering_the_order_frees_cash_for_upgrades() -> void:
	_night(250.0)
	var before: float = station.spendable_cash()
	station.set_fuel_order(100.0)
	assert_almost_eq(station.spendable_cash(), before + _cost(150.0), 0.01)


func test_the_order_never_overfills_the_tank() -> void:
	_night(50.0)
	station.set_fuel_order(9999.0)
	assert_almost_eq(station.fuel_order_liters, 50.0, 0.01)


func test_given_an_order_when_the_station_opens_then_it_is_paid_and_poured_in() -> void:
	_night(250.0)
	station.set_fuel_order(100.0)
	var cash: float = station.wallet.cash
	station.continue_pressed()
	assert_almost_eq(station.wallet.cash, cash - _cost(100.0), 0.01)
	assert_almost_eq(station.tank.liters, 250.0, 0.01)


func test_upgrades_can_only_use_cash_not_set_aside_for_fuel() -> void:
	_night(250.0, _cost(250.0) + 50.0)
	assert_false(station.buy(0), "Flyers cost $80 but only $50 is free")
	station.set_fuel_order(200.0)
	assert_true(station.buy(0))


func test_the_day_summary_charges_rent_only_and_shows_fuel_left() -> void:
	station.tank.draw(100.0 * station.tank.price_per_liter)
	var cash: float = station.wallet.cash
	station.dev_end_day()
	assert_almost_eq(station.wallet.cash, cash - station.economy.rent_for(1), 0.01)
	assert_false(station.summary_label.text.contains("Refill"))
	assert_string_contains(station.summary_label.text, "Fuel left")


func test_given_an_empty_tank_and_no_order_then_the_day_closes_at_once() -> void:
	_night(400.0)
	station.set_fuel_order(0.0)
	station.continue_pressed()
	assert_eq(station.state, station.State.SUMMARY)
