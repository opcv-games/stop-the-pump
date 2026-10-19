extends GutTest
## Spec: features/multi_pump.feature, features/economy.feature.
## Wiring check: bays -> tier -> shared combo -> money -> screen. Refs #4, #3

const SCENE := preload("res://scenes/greybox/pump_station.tscn")

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.pump_count = 2
	station.next_customer_delay = 60.0  # keep results on screen for the assertions
	station.second_customer_offset = 0.0  # both customers present at once
	add_child_autofree(station)
	station.sound.enabled = false


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func _pump(i: int) -> PumpComponent:
	return station.bays[i].pump


func _stop_exactly_on_target(i: int) -> void:
	_pump(i).start_pour()
	_pump(i).tick(_pump(i).target / _pump(i).flow_rate)
	_pump(i).stop_pour()


func test_given_two_pumps_then_station_has_two_bays_with_customers() -> void:
	assert_eq(station.bays.size(), 2)
	assert_gt(_pump(0).target, 0.0)
	assert_gt(_pump(1).target, 0.0)


func test_given_key_1_and_key_2_held_then_both_amounts_climb_independently() -> void:
	station.press(0)
	station.press(1)
	_pump(0).tick(1.0)
	_pump(1).tick(0.5)
	assert_almost_eq(_pump(0).amount, 4.0, 0.001)
	assert_almost_eq(_pump(1).amount, 2.0, 0.001)


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


func test_given_x1_when_pump_1_perfect_then_pump_2_perfect_then_shared_combo_is_x3() -> void:
	_stop_exactly_on_target(0)
	_stop_exactly_on_target(1)
	assert_eq(station.combo.multiplier, 3)
	assert_string_contains(station.bays[1].result_label.text, "PERFECT")


func test_given_x3_when_pump_2_misses_then_combo_resets_and_bay_says_combo_lost() -> void:
	station.combo.register(ScoreTiers.GOOD)
	station.combo.register(ScoreTiers.GOOD)
	_pump(1).start_pour()
	_pump(1).tick(1.0)
	_pump(1).stop_pour()
	assert_eq(station.combo.multiplier, 1)
	assert_string_contains(station.bays[1].result_label.text, "COMBO LOST  x3")


func test_given_pump_waiting_for_next_customer_when_its_key_pressed_then_nothing_pours() -> void:
	_stop_exactly_on_target(0)
	var before := _pump(0).amount
	station.press(0)
	_pump(0).tick(1.0)
	assert_eq(_pump(0).amount, before)


func test_given_x1_when_pump_1_stops_exactly_then_cash_gains_margin_plus_tip() -> void:
	var target: float = _pump(0).target
	_stop_exactly_on_target(0)
	var expected: float = target - target * station.economy.wholesale_ratio + station.economy.perfect_tip
	assert_almost_eq(station.wallet.cash, expected, 0.001)
	assert_string_contains(station._cash_label.text, "$%.2f" % expected)


func test_given_x2_when_pump_2_stops_exactly_then_tip_is_doubled_on_screen() -> void:
	_stop_exactly_on_target(0)
	_stop_exactly_on_target(1)
	assert_string_contains(station.bays[1].result_label.text, "(x2)")


func test_given_customer_when_pump_badly_overshoots_then_bay_says_fuel_was_given_away() -> void:
	_pump(0).start_pour()
	_pump(0).tick((_pump(0).target + 3.0) / _pump(0).flow_rate)
	_pump(0).stop_pour()
	assert_string_contains(station.bays[0].result_label.text, "gave away $3.00")
