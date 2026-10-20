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
	station.pump_count = 2  # these rules need two pumps; the one-pump start is in test_first_minutes
	station.profile_file = ""  # skip the naming screen in tests
	station.cars_gate_service = false  # customers ready at once: these tests are about other rules
	station.special_customer_chance = 0.0  # Regulars only: these tests are about other rules
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
	assert_string_contains(station.tree_view.tooltip_for("b:tank:0"), "+100 L")


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
	assert_eq(station.owned.get("pumps", 0), 1, "only the starting Pump 2 counts as owned (#30)")


func test_given_branch_complete_then_card_says_complete_and_buying_does_nothing() -> void:
	_to_shop()
	assert_true(station.buy(VIBE))
	assert_true(station.buy(VIBE))
	assert_false(station.buy(VIBE))
	assert_string_contains(station.tree_view.tooltip_for("b:vibe:1"), "OWNED")
	assert_eq(station.combo.max_multiplier, 7)


func test_given_marketing_branch_then_cars_come_sooner_then_bigger_orders() -> void:
	_to_shop()
	station.buy(MARKETING)
	assert_almost_eq(station.arrival_max, 60.0 * 0.8, 0.001)
	station.buy(MARKETING)
	assert_almost_eq(station.arrival_max, 60.0 * 0.64, 0.001)
	station.buy(MARKETING)
	assert_true(station.possible_targets.has(60.0))


func _make_self_service() -> PumpBay:
	_to_shop()
	station.buy(PUMPS)  # build pump 3
	assert_true(station.buy_pump(2))  # pump 3: self-service
	station.continue_pressed()
	return station.bays[2]


func test_given_pumps_branch_then_pump_3_expansion_pump_4_pump_5() -> void:
	_to_shop()
	assert_true(station.buy(PUMPS))
	assert_eq(station.bays.size(), 3)
	assert_false(station.expanded)
	assert_true(station.buy(PUMPS))
	assert_true(station.expanded, "the footprint expansion comes before pump 4")
	assert_eq(station.bays.size(), 3)
	assert_true(station.buy(PUMPS))
	assert_true(station.buy(PUMPS))
	assert_eq(station.bays.size(), 5)
	assert_false(station.buy(PUMPS))
	for bay in station.bays:
		assert_false(bay.self_service)


func test_given_the_tree_then_each_pump_has_its_own_nodes() -> void:
	_to_shop()
	assert_string_contains(station.tree_view.tooltip_for("p:0:0"), "Pump 1")
	assert_string_contains(station.tree_view.tooltip_for("p:0:0"), "Self-service")


func test_given_pump_3_converted_then_only_pump_3_is_self_service() -> void:
	_to_shop()
	station.buy(PUMPS)
	assert_true(station.buy_pump(2))
	assert_true(station.bays[2].self_service)
	assert_false(station.bays[0].self_service)
	assert_true(station.bays[2]._auto_button.visible, "the AUTO switch marks a self-serve pump")


func test_given_self_service_sale_then_cash_minus_card_fee_and_no_combo_or_xp() -> void:
	var bay := _make_self_service()
	var combo_before: int = station.combo.multiplier
	var xp_before: int = station.wallet.xp
	var cash_before: float = station.wallet.cash
	var tank_before: float = station.tank.liters
	var target: float = bay.pump.target
	bay.self_service_component.tick(10.0)
	bay.self_service_component.tick(100.0)
	bay.self_service_component.tick(10.0)
	assert_almost_eq(station.wallet.cash - cash_before, target * 0.97, 0.001)
	assert_eq(station.combo.multiplier, combo_before)
	assert_eq(station.wallet.xp, xp_before)
	assert_almost_eq(tank_before - station.tank.liters, target / station.economy.price_per_liter, 0.001)
	assert_string_contains(bay.result_label.text, "SELF-SERVE")


func test_given_self_service_customer_paying_when_day_ends_then_summary_waits_for_payment() -> void:
	var bay := _make_self_service()
	var ss: SelfServiceComponent = bay.self_service_component
	while ss.phase != SelfServiceComponent.Phase.PAYING:
		ss.tick(0.1)  # small steps so the customer can't pump and pay in a single step
	assert_eq(ss.phase, SelfServiceComponent.Phase.PAYING)
	station.clock.running = true
	station.clock.tick(station.clock.day_seconds)
	assert_eq(station.state, station.State.CLOSING)
	ss.tick(10.0)
	assert_eq(station.state, station.State.SUMMARY)


func test_given_self_service_pump_then_hint_lists_only_played_keys() -> void:
	_make_self_service()
	assert_string_contains(station._hint_label.text, "Hold 1, 2 to pour")


func test_given_dev_mode_then_it_never_forces_a_self_service_pump() -> void:
	var bay := _make_self_service()
	for i in 3:
		station.dev_force("good")
	assert_false(bay.pump.is_done)


func test_given_self_service_pump_when_its_key_is_pressed_then_nothing_pours() -> void:
	var bay := _make_self_service()
	station.press(2)
	bay.pump.tick(1.0)
	assert_eq(bay.pump.amount, 0.0)


func test_given_faster_self_serve_on_pump_3_then_only_pump_3_speeds_up() -> void:
	_to_shop()
	station.buy(PUMPS)  # pump 3
	station.buy(PUMPS)  # expansion
	station.buy(PUMPS)  # pump 4
	station.buy_pump(2)
	station.buy_pump(3)
	assert_true(station.buy_pump(2))  # pump 3: faster self-serve
	assert_almost_eq(station.bays[2].pump.flow_rate, station.flow_rate * station.self_service_speed * 1.5, 0.001)
	assert_almost_eq(station.bays[3].pump.flow_rate, station.flow_rate * station.self_service_speed, 0.001)


func test_given_card_deal_on_pump_3_then_its_fee_halves() -> void:
	_to_shop()
	station.buy(PUMPS)
	for i in 3:
		assert_true(station.buy_pump(2))
	assert_almost_eq(station.card_fee_for(station.bays[2]), 0.015, 0.0001)
	assert_false(station.buy_pump(2), "pump tree complete")
	assert_string_contains(station.tree_view.tooltip_for("p:2:2"), "OWNED")


func test_given_extra_pump_then_day_2_gives_it_a_customer() -> void:
	_to_shop()
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
	station.buy_pump(2)
	station.buy_pump(2)
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
	for bay in station.bays:
		assert_false(bay.self_service)
		assert_eq(bay.pump_level, 0)
	assert_false(station.expanded)
	assert_false(station.world_view.world.scenery.get_node("ForecourtExpansion").visible)
	assert_eq(station.owned, {"pumps": 1}, "only the starting Pump 2 counts as owned (#30)")


func test_given_day_2_after_shop_then_every_bay_is_drawn_in_front_of_the_background() -> void:
	_to_shop()
	station.buy(PUMPS)
	station.buy(PUMPS)
	station.continue_pressed()
	for bay in station.bays:
		assert_gt(bay.get_index(), station._bg.get_index())
		assert_lt(bay.get_index(), station._overlay.get_index())
