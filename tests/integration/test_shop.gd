extends GutTest
## Spec: features/night_shop.feature. Refs #14

const SCENE := preload("res://scenes/greybox/pump_station.tscn")

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.arrival_min = 60.0
	station.arrival_max = 60.0
	station.second_customer_offset = 0.0
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func _to_shop(cash := 1000.0) -> void:
	station.wallet.add(cash)
	station.clock.running = true
	station.clock.tick(station.clock.day_seconds)
	station.continue_pressed()


func _buy(id: String) -> bool:
	station.set_offers([id, "squeegee", "tip_jar"])
	return station.buy(0)


func test_given_day_survived_when_enter_pressed_then_shop_offers_3_different_upgrades() -> void:
	_to_shop()
	assert_eq(station.state, station.State.SHOP)
	assert_eq(station.shop_offers.size(), 3)
	var unique := {}
	for id in station.shop_offers:
		unique[id] = true
	assert_eq(unique.size(), 3)


func test_given_shop_when_enter_pressed_then_day_2_opens() -> void:
	_to_shop()
	station.continue_pressed()
	assert_eq(station.state, station.State.OPEN)
	assert_eq(station.day, 2)


func test_given_enough_cash_when_bigger_tank_bought_then_paid_and_tank_and_rent_grow() -> void:
	_to_shop()
	var cash: float = station.wallet.cash
	var rent: float = station.economy.rent_for(2)
	assert_true(_buy("bigger_tank"))
	assert_almost_eq(station.wallet.cash, cash - Upgrades.price(station, "bigger_tank"), 0.001)
	assert_eq(station.tank.capacity_liters, 500.0)
	assert_almost_eq(station.economy.rent_for(2), rent + 20.0, 0.001)
	assert_string_contains(station.shop_card_text(0), "SOLD")


func test_given_too_little_cash_when_buying_then_nothing_happens() -> void:
	_to_shop(0.0)
	station.wallet.add(-station.wallet.cash + 10.0)
	assert_false(_buy("extra_pump"))
	assert_eq(station.bays.size(), 2)
	assert_almost_eq(station.wallet.cash, 10.0, 0.001)


func test_given_shop_when_reroll_then_reroll_price_paid_and_3_offers() -> void:
	_to_shop()
	var cash: float = station.wallet.cash
	assert_true(station.reroll())
	assert_almost_eq(station.wallet.cash, cash - station.reroll_cost, 0.001)
	assert_eq(station.shop_offers.size(), 3)


func test_given_turbo_bought_then_one_pump_pours_30_percent_faster_even_after_tuning() -> void:
	_to_shop()
	_buy("turbo")
	Tuning.set_value(station, "station/flow_rate", 4.0)
	assert_almost_eq(station.bays[0].pump.flow_rate, 5.2, 0.001)
	assert_almost_eq(station.bays[1].pump.flow_rate, 4.0, 0.001)


func test_given_flyers_bought_then_cars_arrive_sooner_and_bigger_orders_join() -> void:
	_to_shop()
	_buy("flyers")
	assert_almost_eq(station.arrival_max, 60.0 * 0.7, 0.001)
	assert_true(station.possible_targets.has(60.0))


func test_given_extra_pump_bought_then_three_pumps_and_rent_plus_40() -> void:
	_to_shop()
	var rent: float = station.economy.rent_for(2)
	_buy("extra_pump")
	assert_eq(station.bays.size(), 3)
	assert_almost_eq(station.economy.rent_for(2), rent + 40.0, 0.001)
	station.continue_pressed()
	assert_false(station.bays[2].waiting, "pump 3 gets a customer on day 2")


func test_given_squeegee_bought_when_big_overshoot_then_2s_cleaning_and_5_dollar_fee() -> void:
	_to_shop()
	_buy("squeegee")
	station.continue_pressed()
	var pump: PumpComponent = station.bays[0].pump
	var cash_before: float = station.wallet.cash
	pump.finish_at(pump.target + 3.0)
	assert_almost_eq(station.bays[0]._cleaning_left, 2.0, 0.001)
	assert_almost_eq(station.wallet.cash, cash_before + pump.target - 5.0, 0.001)


func test_given_tip_jar_bought_then_good_earns_2_more_and_ok_costs_2() -> void:
	_to_shop()
	_buy("tip_jar")
	station.continue_pressed()
	var r: FuelEconomy.Receipt = station.economy.settle(20.3, 20.0, ScoreTiers.GOOD)
	assert_almost_eq(r.tip, station.economy.good_tip + 2.0, 0.001)
	var bad: FuelEconomy.Receipt = station.economy.settle(20.8, 20.0, ScoreTiers.OK)
	assert_almost_eq(bad.earned, 20.0 - 2.0, 0.001)


func test_given_radio_bought_then_max_combo_up_and_good_window_narrower() -> void:
	_to_shop()
	_buy("radio")
	assert_eq(station.combo.max_multiplier, 6)
	assert_almost_eq(station.combo.tiers.good_window, 0.45, 0.001)


func test_given_upgrades_when_evicted_then_new_run_has_none() -> void:
	_to_shop()
	_buy("extra_pump")
	station.set_offers(["bigger_tank", "radio", "flyers"])
	station.buy(0)
	station.buy(1)
	station.continue_pressed()
	station.wallet.add(-station.wallet.cash - 5000.0)
	station.clock.running = true
	station.clock.tick(station.clock.day_seconds)
	assert_true(station.evicted)
	station.continue_pressed()
	assert_eq(station.bays.size(), 2)
	assert_eq(station.tank.capacity_liters, 400.0)
	assert_eq(station.combo.max_multiplier, 5)
	assert_almost_eq(station.combo.tiers.good_window, 0.5, 0.001)
	assert_almost_eq(station.economy.rent_for(1), station.economy.rent_base, 0.001)
	assert_true(station.owned.is_empty())


func test_given_station_then_version_is_0_12() -> void:
	assert_string_contains((station.get_node("VersionLabel") as Label).text, "v0.12")


func test_given_day_2_after_shop_then_every_bay_is_drawn_in_front_of_the_background() -> void:
	_to_shop()
	_buy("extra_pump")
	station.continue_pressed()
	for bay in station.bays:
		assert_gt(bay.get_index(), station._bg.get_index())
		assert_lt(bay.get_index(), station._overlay.get_index())
