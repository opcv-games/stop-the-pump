extends GutTest
## Spec: features/run_arc.feature. Refs #19

const SCENE := preload("res://scenes/greybox/pump_station.tscn")

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
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


func test_given_speed_cycles_then_1_2_3_1() -> void:
	var seen := []
	for i in 4:
		station.cycle_speed()
		seen.append(station.speed)
	assert_eq(seen, [2, 3, 1, 2])


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


func test_given_station_then_version_is_0_18() -> void:
	assert_string_contains((station.get_node("VersionLabel") as Label).text, "v0.18")
