extends GutTest
## Spec: features/night_shop.feature (upgrade tree). Refs #15

const SCENE := preload("res://scenes/greybox/pump_station.tscn")
const MARKETING := 0
const PUMPS := 1
const TANK := 2
const SERVICE := 3
const VIBE := 4

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


func _to_shop(cash := 5000.0) -> void:
	station.wallet.add(cash)
	station.clock.running = true
	station.clock.tick(station.clock.day_seconds)
	station.continue_pressed()


func test_given_day_survived_when_enter_pressed_then_tree_shows_5_branches() -> void:
	_to_shop()
	assert_eq(station.state, station.State.SHOP)
	assert_eq(Upgrades.BRANCHES.size(), 5)
	assert_string_contains(station.shop_card_text(TANK), "+100 L")


func test_given_shop_when_enter_pressed_then_day_2_opens() -> void:
	_to_shop()
	station.continue_pressed()
	assert_eq(station.state, station.State.OPEN)
	assert_eq(station.day, 2)


func test_given_cash_when_tank_branch_bought_then_paid_tank_grows_and_rent_does_not() -> void:
	_to_shop()
	var cash: float = station.wallet.cash
	var rent: float = station.economy.rent_for(2)
	var price: float = Upgrades.next_price(station, TANK)
	assert_true(station.buy(TANK))
	assert_almost_eq(station.wallet.cash, cash - price, 0.001)
	assert_eq(station.tank.capacity_liters, 500.0)
	assert_almost_eq(station.economy.rent_for(2), rent, 0.001, "no gameplay downside")
	assert_eq(station.owned.get("tank", 0), 1)


func test_given_too_little_cash_when_buying_then_nothing_happens() -> void:
	_to_shop(0.0)
	station.wallet.add(-station.wallet.cash + 10.0)
	assert_false(station.buy(PUMPS))
	assert_almost_eq(station.wallet.cash, 10.0, 0.001)
	assert_eq(station.owned.get("pumps", 0), 0)


func test_given_branch_complete_then_card_says_complete_and_buying_does_nothing() -> void:
	_to_shop()
	assert_true(station.buy(VIBE))
	assert_true(station.buy(VIBE))
	assert_false(station.buy(VIBE))
	assert_string_contains(station.shop_card_text(VIBE), "COMPLETE")
	assert_eq(station.combo.max_multiplier, 7)


func test_given_marketing_branch_then_cars_come_sooner_then_bigger_orders() -> void:
	_to_shop()
	station.buy(MARKETING)
	assert_almost_eq(station.arrival_max, 60.0 * 0.8, 0.001)
	station.buy(MARKETING)
	assert_almost_eq(station.arrival_max, 60.0 * 0.64, 0.001)
	station.buy(MARKETING)
	assert_true(station.possible_targets.has(60.0))


func test_given_pumps_branch_then_turbo_extra_pump_turbo_everywhere_another_pump() -> void:
	_to_shop()
	station.buy(PUMPS)
	assert_almost_eq(station.bays[0].pump.flow_rate, station.flow_rate * 1.3, 0.001)
	assert_almost_eq(station.bays[1].pump.flow_rate, station.flow_rate, 0.001)
	station.buy(PUMPS)
	assert_eq(station.bays.size(), 3)
	station.buy(PUMPS)
	for bay in station.bays:
		assert_almost_eq(bay.pump.flow_rate, station.flow_rate * 1.3, 0.001)
	station.buy(PUMPS)
	assert_eq(station.bays.size(), 4)
	assert_almost_eq(station.bays[3].pump.flow_rate, station.flow_rate * 1.3, 0.001, "new pumps get turbo too")
	Tuning.set_value(station, "station/flow_rate", 4.0)
	assert_almost_eq(station.bays[3].pump.flow_rate, 5.2, 0.001, "turbo survives retuning")


func test_given_extra_pump_then_day_2_gives_it_a_customer() -> void:
	_to_shop()
	station.buy(PUMPS)
	station.buy(PUMPS)
	station.continue_pressed()
	assert_false(station.bays[2].waiting)


func test_given_service_branch_then_cleaning_2s_then_tip_jar_then_cleaning_1s() -> void:
	_to_shop()
	station.buy(SERVICE)
	assert_almost_eq(station.cleaning_seconds, 2.0, 0.001)
	station.buy(SERVICE)
	var good: FuelEconomy.Receipt = station.economy.settle(20.3, 20.0, ScoreTiers.GOOD)
	assert_almost_eq(good.tip, station.economy.good_tip + 2.0, 0.001)
	var ok: FuelEconomy.Receipt = station.economy.settle(20.8, 20.0, ScoreTiers.OK)
	assert_almost_eq(ok.earned, 20.0, 0.001, "no penalty on OK")
	station.buy(SERVICE)
	assert_almost_eq(station.cleaning_seconds, 1.0, 0.001)


func test_given_vibe_branch_then_max_combo_up_and_good_window_unchanged() -> void:
	_to_shop()
	station.buy(VIBE)
	assert_eq(station.combo.max_multiplier, 6)
	assert_almost_eq(station.combo.tiers.good_window, 0.5, 0.001)


func test_given_upgrades_when_evicted_then_new_run_starts_clean() -> void:
	_to_shop()
	for branch in 5:
		station.buy(branch)
		station.buy(branch)
	station.continue_pressed()
	station.wallet.add(-station.wallet.cash - 5000.0)
	station.clock.running = true
	station.clock.tick(station.clock.day_seconds)
	assert_true(station.evicted)
	station.continue_pressed()
	assert_eq(station.bays.size(), 2)
	assert_eq(station.tank.capacity_liters, 400.0)
	assert_eq(station.combo.max_multiplier, 5)
	assert_almost_eq(station.cleaning_seconds, 4.0, 0.001)
	assert_almost_eq(station.arrival_max, 60.0, 0.001)
	assert_almost_eq(station.bays[0].pump.flow_rate, station.flow_rate, 0.001)
	assert_true(station.owned.is_empty())


func test_given_day_2_after_shop_then_every_bay_is_drawn_in_front_of_the_background() -> void:
	_to_shop()
	station.buy(PUMPS)
	station.buy(PUMPS)
	station.continue_pressed()
	for bay in station.bays:
		assert_gt(bay.get_index(), station._bg.get_index())
		assert_lt(bay.get_index(), station._overlay.get_index())


func test_given_station_then_version_is_0_14() -> void:
	assert_string_contains((station.get_node("VersionLabel") as Label).text, "v0.14")
