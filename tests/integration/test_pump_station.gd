extends GutTest
## Spec: features/multi_pump.feature, features/economy.feature, features/day.feature.
## Wiring check: bays -> tier -> shared combo -> cash + XP -> tank -> day end. Refs #4, #3, #8

const SCENE := preload("res://scenes/greybox/pump_station.tscn")

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.pump_count = 2
	station.arrival_min = 60.0  # keep results on screen for the assertions
	station.arrival_max = 60.0
	station.second_customer_offset = 0.0  # both customers present at once
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false  # tests move time themselves


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func _pump(i: int) -> PumpComponent:
	return station.bays[i].pump


func _stop_exactly_on_target(i: int) -> void:
	_pump(i).start_pour()
	_pump(i).tick(_pump(i).target / _pump(i).flow_rate)
	_pump(i).stop_pour()


func _end_day_by_clock() -> void:
	station.clock.running = true
	station.clock.tick(station.clock.day_seconds)


# --- Two pumps (#4) ---

func test_given_two_pumps_then_station_has_two_bays_with_customers() -> void:
	assert_eq(station.bays.size(), 2)
	assert_gt(_pump(0).target, 0.0)
	assert_gt(_pump(1).target, 0.0)


func test_given_both_pouring_when_key_1_released_then_pump_1_stops_and_pump_2_continues() -> void:
	station.press(0)
	station.press(1)
	_pump(0).tick(1.0)
	_pump(1).tick(1.0)
	station.release(0)
	_pump(0).tick(1.0)
	_pump(1).tick(1.0)
	assert_true(_pump(0).is_done)
	assert_true(_pump(1).is_pouring)
	assert_almost_eq(_pump(1).amount, 8.0, 0.001)


func test_given_x3_when_pump_2_misses_then_combo_resets_and_bay_says_combo_lost() -> void:
	station.combo.register(ScoreTiers.GOOD)
	station.combo.register(ScoreTiers.GOOD)
	_pump(1).start_pour()
	_pump(1).tick(1.0)
	_pump(1).stop_pour()
	assert_eq(station.combo.multiplier, 1)
	assert_string_contains(station.bays[1].result_label.text, "COMBO LOST  x3")


# --- Cash and XP (#3, #8) ---

func test_given_new_run_then_cash_is_starting_cash() -> void:
	assert_almost_eq(station.wallet.cash, station.starting_cash, 0.001)


func test_given_x1_when_stopped_exactly_then_cash_gains_full_sale_plus_tip_and_xp_gains_200() -> void:
	var target: float = _pump(0).target
	_stop_exactly_on_target(0)
	assert_almost_eq(station.wallet.cash, station.starting_cash + target + 8.0, 0.001)
	assert_eq(station.wallet.xp, 200)


func test_given_x2_when_stopped_exactly_then_xp_doubles_but_tip_does_not() -> void:
	_stop_exactly_on_target(0)
	var cash_before: float = station.wallet.cash
	var target: float = _pump(1).target
	_stop_exactly_on_target(1)
	assert_almost_eq(station.wallet.cash - cash_before, target + 8.0, 0.001)
	assert_eq(station.wallet.xp, 600)
	assert_string_contains(station.bays[1].result_label.text, "+400 XP (x2)")


# --- Tank and day (#8) ---

func test_given_full_tank_when_pump_pours_20_dollars_then_tank_loses_10_litres() -> void:
	var before: float = station.tank.liters
	_pump(0).start_pour()
	_pump(0).tick(5.0)
	assert_almost_eq(before - station.tank.liters, 10.0, 0.001)


func test_given_overshoot_then_bay_says_litres_wasted() -> void:
	_pump(0).start_pour()
	_pump(0).tick((_pump(0).target + 3.0) / _pump(0).flow_rate)
	_pump(0).stop_pour()
	assert_string_contains(station.bays[0].result_label.text, "wasted 1.5 L")


func test_given_clock_runs_out_with_pumps_idle_then_summary_shows_costs() -> void:
	station.wallet.add(1000.0)  # one stop alone cannot cover rent
	_stop_exactly_on_target(0)
	_end_day_by_clock()
	assert_eq(station.state, station.State.SUMMARY)
	assert_true(station._overlay.visible)
	assert_string_contains(station.summary_label.text, "DAY 1 CLOSED")
	assert_string_contains(station.summary_label.text, "Rent")


func test_given_clock_runs_out_while_pouring_then_summary_waits_for_the_pour() -> void:
	_pump(0).start_pour()
	_pump(0).tick(1.0)
	_end_day_by_clock()
	assert_eq(station.state, station.State.CLOSING)
	_pump(0).stop_pour()
	assert_eq(station.state, station.State.SUMMARY)


func test_given_day_ends_then_refill_and_rent_are_taken_from_cash() -> void:
	var target: float = _pump(0).target
	_stop_exactly_on_target(0)
	var liters: float = station.tank.liters_used()
	_end_day_by_clock()
	var expected: float = station.starting_cash + target + 8.0 - station.economy.refill_cost(liters) - station.economy.rent_for(1)
	assert_almost_eq(station.wallet.cash, expected, 0.001)


func test_given_tank_runs_dry_mid_pour_then_pour_stops_and_day_ends() -> void:
	station.tank.liters = 1.0
	_pump(0).start_pour()
	_pump(0).tick(5.0)
	assert_true(_pump(0).is_done)
	assert_eq(station.state, station.State.SUMMARY)
	assert_string_contains(station.summary_label.text, "Out of fuel")


func test_given_summary_when_continue_past_the_shop_then_day_2_starts_with_full_tank() -> void:
	station.wallet.add(1000.0)
	_stop_exactly_on_target(0)
	_end_day_by_clock()
	station.continue_pressed()  # summary -> night shop
	station.continue_pressed()  # night shop -> day 2
	assert_eq(station.day, 2)
	assert_eq(station.state, station.State.OPEN)
	assert_eq(station.tank.liters, station.tank.capacity_liters)
	assert_false(station._overlay.visible)


func test_given_costs_exceed_cash_then_evicted_and_continue_starts_new_run_keeping_xp() -> void:
	station.wallet.add(-station.wallet.cash)
	_stop_exactly_on_target(0)
	var xp: int = station.wallet.xp
	_end_day_by_clock()
	assert_true(station.evicted)
	assert_string_contains(station.summary_label.text, "EVICTED")
	station.continue_pressed()
	assert_eq(station.day, 1)
	assert_almost_eq(station.wallet.cash, station.starting_cash, 0.001)
	assert_eq(station.wallet.xp, xp)


# --- Cleaning delay (#9) ---

func _overshoot(i: int, by: float) -> void:
	_pump(i).start_pour()
	_pump(i).tick((_pump(i).target + by) / _pump(i).flow_rate)
	_pump(i).stop_pour()


func test_given_overshoot_of_3_dollars_then_bay_is_cleaning() -> void:
	_overshoot(0, 3.0)
	assert_true(station.bays[0].cleaning)
	assert_string_contains(station.bays[0].target_label.text, "CLEANING")


func test_given_overshoot_of_80_cents_then_bay_is_not_cleaning() -> void:
	_overshoot(0, 0.8)
	assert_false(station.bays[0].cleaning)


func test_given_cleaning_switched_off_when_big_overshoot_then_bay_is_not_cleaning() -> void:
	station.cleaning_enabled = false
	_overshoot(0, 3.0)
	assert_false(station.bays[0].cleaning)


# --- Super Perfect (#12) ---

func test_given_stop_2_cents_over_then_super_perfect_and_display_snaps_to_target() -> void:
	var target: float = _pump(0).target
	_pump(0).start_pour()
	_pump(0).tick((target + 0.02) / _pump(0).flow_rate)
	_pump(0).stop_pour()
	assert_string_contains(station.bays[0].result_label.text, "SUPER PERFECT  on the dot")
	assert_eq(station.bays[0].amount_label.text, "$%.2f" % target)


# --- Random arrivals (#10) ---

func test_given_arrivals_between_1_and_5_then_waits_stay_in_range_and_vary() -> void:
	station.arrival_min = 1.0
	station.arrival_max = 5.0
	var waits := {}
	for i in 50:
		var w: float = station.next_arrival_delay()
		assert_between(w, 1.0, 5.0)
		waits[snappedf(w, 0.1)] = true
	assert_gt(waits.size(), 5, "waits should not all be the same")
