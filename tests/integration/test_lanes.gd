extends GutTest
## Spec: features/lanes.feature. Refs #24

const SCENE := preload("res://scenes/greybox/pump_station.tscn")
const PROFILE := "user://test_profile.cfg"

var station: Control


func _make(profile := "") -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.profile_file = profile
	station.special_customer_chance = 0.0
	station.arrival_min = 60.0
	station.arrival_max = 60.0
	station.second_customer_offset = 0.0
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	if FileAccess.file_exists(PROFILE):
		DirAccess.remove_absolute(PROFILE)


func _world() -> StationWorld:
	return station.world_view.world


func _to_shop() -> void:
	station.wallet.add(5000.0)
	station.dev_end_day()
	station.continue_pressed()


func test_given_two_pumps_then_two_lanes_with_pumps() -> void:
	_make()
	assert_eq(_world().lane_count, 2)
	assert_eq(_world().pumps.size(), 2)
	assert_true(_world().scenery.get_node("Lane_2").visible)
	assert_false(_world().scenery.get_node("Lane_3").visible)


func test_given_pump_3_built_then_a_third_lane_appears() -> void:
	_make()
	_to_shop()
	station.buy(1)
	assert_eq(_world().lane_count, 3)
	assert_true(_world().scenery.get_node("Lane_3").visible)


func test_given_expansion_bought_then_vacant_lot_becomes_concrete() -> void:
	_make()
	_to_shop()
	station.buy(1)
	assert_true(_world().scenery.get_node("VacantLot").visible)
	station.buy(1)
	assert_true(_world().scenery.get_node("ForecourtExpansion").visible)
	assert_false(_world().scenery.get_node("VacantLot").visible)
	assert_false(_world().scenery.get_node("LotForSaleSign").visible)


func test_given_customer_arrives_then_a_car_drives_in_and_stops_at_its_pump() -> void:
	_make()
	var car: Node3D = _world().car_at(1)
	assert_not_null(car, "pump 2 has a customer at the start of the day")
	assert_gt(car.position.x, _world().STOP_X + 5.0, "starts at the top right")
	_world().tick_cars(10.0)
	assert_almost_eq(car.position.x, _world().STOP_X, 0.01)
	assert_almost_eq(car.position.z, _world().lane_z(1), 0.01)


func test_given_served_then_the_car_drives_off_bottom_left_and_is_removed() -> void:
	_make()
	_world().tick_cars(10.0)
	var car: Node3D = _world().car_at(0)
	var pump: PumpComponent = station.bays[0].pump
	pump.finish_at(pump.target)
	assert_null(_world().car_at(0), "the lane is free for the next car")
	_world().tick_cars(1.0)
	assert_lt(car.position.x, _world().STOP_X)
	_world().tick_cars(30.0)
	assert_false(is_instance_valid(car) and car.is_inside_tree(), "gone off screen")


func test_given_customer_type_then_the_car_wears_its_colour() -> void:
	_make()
	station.bays[0].new_customer(30.0, "grandpa")
	assert_eq(_world().car_colour(0), Customers.TYPES["grandpa"].car)


func test_given_pouring_then_that_pump_glows_brighter() -> void:
	_make()
	var before := _world().globe_energy(0)
	station.press(0)
	assert_gt(_world().globe_energy(0), before)
	station.release(0)


func test_given_name_set_then_the_pylon_shows_it_in_capitals() -> void:
	_make()
	station.set_station_name("Bob's Gas")
	assert_eq(_world().name_label.text, "BOB'S GAS")


func test_given_no_saved_name_when_a_run_starts_then_the_naming_screen_waits() -> void:
	_make(PROFILE)
	assert_eq(station.state, station.State.NAMING)
	assert_false(station.clock.running)
	station.confirm_name("Lucky Pump")
	assert_eq(station.state, station.State.OPEN)
	assert_eq(_world().name_label.text, "LUCKY PUMP")


func test_given_saved_name_then_the_next_run_prefills_it() -> void:
	_make(PROFILE)
	station.confirm_name("Lucky Pump")
	station.free()
	_make(PROFILE)
	assert_eq(station.name_input.text, "Lucky Pump")


func test_given_empty_name_then_a_default_is_used() -> void:
	_make(PROFILE)
	station.confirm_name("   ")
	assert_eq(_world().name_label.text, "GAS BAR BLUES")


func test_given_station_then_version_is_0_22() -> void:
	_make()
	assert_string_contains((station.get_node("VersionLabel") as Label).text, "v0.22")
