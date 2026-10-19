extends GutTest
## Spec: features/designer_tools.feature. Refs #13

const SCENE := preload("res://scenes/greybox/pump_station.tscn")
const TEST_FILE := "user://test_tuning.cfg"

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.profile_file = ""  # skip the naming screen in tests  # never read the designer's own saved tuning in tests
	station.special_customer_chance = 0.0
	station.arrival_min = 60.0
	station.arrival_max = 60.0
	station.second_customer_offset = 0.0
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	if FileAccess.file_exists(TEST_FILE):
		DirAccess.remove_absolute(TEST_FILE)


func test_given_dev_mode_when_perfect_forced_then_pump_1_stops_with_perfect() -> void:
	station.dev_force("perfect")
	assert_string_contains(station.bays[0].result_label.text, "PERFECT")
	assert_false(station.bays[0].result_label.text.contains("SUPER"))


func test_given_dev_mode_when_super_forced_then_super_perfect() -> void:
	station.dev_force("super")
	assert_string_contains(station.bays[0].result_label.text, "SUPER PERFECT")


func test_given_dev_mode_when_miss_under_forced_then_10_dollars_short() -> void:
	var target: float = station.bays[0].pump.target
	station.dev_force("miss_under")
	assert_string_contains(station.bays[0].result_label.text, "MISS  $%.2f short" % minf(10.0, target))


func test_given_pump_1_already_done_when_forced_then_pump_2_takes_it() -> void:
	station.dev_force("good")
	station.dev_force("ok")
	assert_string_contains(station.bays[1].result_label.text, "OK")


func test_given_flow_rate_tuned_to_6_then_every_pump_pours_at_6() -> void:
	Tuning.set_value(station, "station/flow_rate", 6.0)
	for bay in station.bays:
		assert_eq(bay.pump.flow_rate, 6.0)


func test_given_tuning_saved_when_changed_and_loaded_then_saved_value_returns() -> void:
	Tuning.set_value(station, "economy/perfect_tip", 7.5)
	Tuning.save(station, TEST_FILE)
	Tuning.set_value(station, "economy/perfect_tip", 1.0)
	Tuning.load_into(station, TEST_FILE)
	assert_eq(station.economy.perfect_tip, 7.5)


func test_given_tuning_then_copy_text_lists_every_value() -> void:
	Tuning.set_value(station, "station/flow_rate", 6.0)
	var text := Tuning.as_text(station)
	assert_string_contains(text, "station/flow_rate = 6")
	assert_string_contains(text, "economy/rent_base")




func test_given_pumps_pouring_when_end_day_clicked_then_summary_appears() -> void:
	station.bays[0].pump.start_pour()
	station.bays[0].pump.tick(1.0)
	station.dev_end_day()
	assert_eq(station.state, station.State.SUMMARY)
	assert_false(station.bays[0].pump.is_pouring)


func test_given_any_time_when_plus_100_clicked_then_cash_goes_up_100() -> void:
	var cash: float = station.wallet.cash
	station.dev_add_cash()
	assert_almost_eq(station.wallet.cash, cash + 100.0, 0.001)


func test_given_upgrade_tree_when_plus_100_clicked_then_tree_shows_new_cash() -> void:
	station.wallet.add(1000.0)
	station.dev_end_day()
	station.continue_pressed()
	station.dev_add_cash()
	assert_string_contains(station._shop_title.text, "cash $%.0f" % station.wallet.cash)


func test_given_dev_buttons_then_both_exist() -> void:
	assert_not_null(station.find_child("EndDayButton", true, false))
	assert_not_null(station.find_child("AddCashButton", true, false))
