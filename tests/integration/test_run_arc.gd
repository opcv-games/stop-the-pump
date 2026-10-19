extends GutTest
## Spec: features/run_arc.feature. Refs #19

const SCENE := preload("res://scenes/greybox/pump_station.tscn")

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.profile_file = ""  # skip the naming screen in tests
	station.cars_gate_service = false  # customers ready at once: these tests are about other rules
	station.special_customer_chance = 0.0
	station.arrival_min = 60.0
	station.arrival_max = 60.0
	station.second_customer_offset = 0.0
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false


func after_each() -> void:
	Engine.time_scale = 1.0
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func _survive_days(n: int) -> void:
	for i in n:
		station.wallet.add(5000.0)
		station.dev_end_day()
		if station.day < n:
			station.continue_pressed()  # summary -> tree
			station.continue_pressed()  # tree -> next day


func test_given_new_run_then_clock_shows_day_1_of_10() -> void:
	station._on_time_changed(7.0)
	assert_string_contains(station._clock_label.text, "DAY 1/10")


func test_given_day_3_survived_when_enter_then_upgrade_tree_opens() -> void:
	_survive_days(3)
	station.continue_pressed()
	assert_eq(station.state, station.State.SHOP)


func test_given_day_10_survived_then_run_complete_screen() -> void:
	_survive_days(10)
	assert_true(station.run_complete)
	assert_string_contains(station.summary_label.text, "RUN COMPLETE")


func test_given_run_complete_when_enter_then_new_run_day_1_with_xp_kept() -> void:
	station.wallet.add_xp(1234)
	_survive_days(10)
	station.continue_pressed()
	assert_eq(station.day, 1)
	assert_eq(station.state, station.State.OPEN)
	assert_eq(station.wallet.xp, 1234)
	assert_almost_eq(station.wallet.cash, station.starting_cash, 0.001)
	assert_false(station.run_complete)


func test_given_speed_2x_then_engine_runs_twice_as_fast() -> void:
	station.set_speed(2)
	assert_eq(Engine.time_scale, 2.0)
	assert_string_contains(station.speed_text(), "2x")


func test_given_speed_cycles_then_2_3_10_1() -> void:
	var seen := []
	for i in 4:
		station.cycle_speed()
		seen.append(station.speed)
	assert_eq(seen, [2, 3, 10, 1])


func test_given_10x_then_engine_runs_ten_times_as_fast_and_its_button_is_lit() -> void:
	station.set_speed(10)
	assert_eq(Engine.time_scale, 10.0)
	assert_true(station._speed_buttons[3].button_pressed)
	assert_false(station._speed_buttons[0].button_pressed)


func test_given_both_pumps_when_both_converted_then_both_self_service() -> void:
	station.wallet.add(5000.0)
	station.dev_end_day()
	station.continue_pressed()
	assert_true(station.buy_pump(0))
	assert_true(station.buy_pump(1))
	assert_true(station.bays[0].self_service)
	assert_true(station.bays[1].self_service)
	station.continue_pressed()
	assert_eq(station.state, station.State.OPEN)


func test_given_run_complete_when_endless_chosen_then_shop_then_day_11() -> void:
	_survive_days(10)
	station.go_endless()
	assert_eq(station.state, station.State.SHOP)
	station.continue_pressed()
	assert_eq(station.day, 11)
	station._on_time_changed(7.0)
	assert_string_contains(station._clock_label.text, "endless")
	station.wallet.add(5000.0)
	station.dev_end_day()
	assert_false(station.run_complete, "endless days never complete the run")


func test_given_new_run_after_endless_then_endless_is_off() -> void:
	_survive_days(10)
	station.go_endless()
	station.continue_pressed()
	station.wallet.add(-station.wallet.cash - 5000.0)
	station.dev_end_day()
	assert_true(station.evicted)
	station.continue_pressed()
	assert_false(station.endless)


func _auto_pump_1() -> PumpBay:
	station.wallet.add(5000.0)
	station.dev_end_day()
	station.continue_pressed()
	station.buy_pump(0)
	station.continue_pressed()
	station.clock.running = false
	return station.bays[0]


func test_given_auto_pump_when_toggled_then_player_pours_it_and_earns_combo() -> void:
	var bay := _auto_pump_1()
	assert_true(station.toggle_auto(0))
	assert_false(bay.self_service)
	assert_true(bay.pump_level >= 1, "the upgrade is still owned")
	bay.new_customer(20.0)
	station.press(0)
	bay.pump.tick(5.0)
	station.release(0)
	assert_eq(station.combo.multiplier, 2)
	assert_almost_eq(bay.pump.flow_rate, station.flow_rate, 0.001, "full speed by hand")


func test_given_auto_switched_off_with_a_customer_then_labels_show_a_hand_poured_pump() -> void:
	var bay := _auto_pump_1()
	bay.new_customer(20.0)
	station.toggle_auto(0)
	assert_false(bay.target_label.text.contains("SELF"))
	assert_false(bay.bubble_text().contains("card"))


func test_given_manual_pump_when_toggled_back_then_it_serves_itself() -> void:
	var bay := _auto_pump_1()
	station.toggle_auto(0)
	assert_true(station.toggle_auto(0))
	assert_true(bay.self_service)
	assert_false(bay.pump.is_processing(), "the self-service component drives the pump")


func test_given_pump_without_upgrade_when_toggled_then_nothing_happens() -> void:
	assert_false(station.toggle_auto(1))
	assert_false(station.bays[1].self_service)


func test_given_self_service_customer_paying_when_toggled_then_refused() -> void:
	var bay := _auto_pump_1()
	bay.new_customer(10.0)
	var ss: SelfServiceComponent = bay.self_service_component
	while ss.phase != SelfServiceComponent.Phase.PAYING:
		ss.tick(0.1)
	assert_false(station.toggle_auto(0))
	assert_true(bay.self_service)
