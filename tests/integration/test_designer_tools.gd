extends GutTest
## Spec: features/designer_tools.feature. Refs #13

const SCENE := preload("res://scenes/greybox/pump_station.tscn")
const TEST_FILE := "user://test_tuning.cfg"

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""  # never read the designer's own saved tuning in tests
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


