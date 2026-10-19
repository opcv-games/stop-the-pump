extends GutTest
## Spec: features/juice.feature. Refs #26

const SCENE := preload("res://scenes/greybox/pump_station.tscn")

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.profile_file = ""
	station.cars_gate_service = false
	station.special_customer_chance = 0.0
	station.arrival_min = 60.0
	station.arrival_max = 60.0
	station.second_customer_offset = 0.0
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func _world() -> StationWorld:
	return station.world_view.world


func test_given_pouring_then_a_stream_flows_and_stops_with_the_pour() -> void:
	station.press(0)
	assert_true(_world().stream(0).emitting)
	station.release(0)
	assert_false(_world().stream(0).emitting)


func test_given_streams_switched_off_then_no_stream() -> void:
	Tuning.set_value(station, "station/juice_streams", 0)
	station.press(0)
	assert_false(_world().stream(0).emitting)
	station.release(0)


func test_given_perfect_then_a_green_sparkle_pops_at_that_pump() -> void:
	var pump: PumpComponent = station.bays[0].pump
	pump.finish_at(pump.target + 0.07)
	assert_eq(_world().last_sparkle_lane, 0)
	assert_eq(_world().last_sparkle_colour, StationWorld.SPARKLE_PERFECT)


func test_given_super_perfect_then_the_sparkle_is_gold() -> void:
	var pump: PumpComponent = station.bays[1].pump
	pump.finish_at(pump.target)
	assert_eq(_world().last_sparkle_lane, 1)
	assert_eq(_world().last_sparkle_colour, StationWorld.SPARKLE_SUPER)


func test_given_good_then_no_sparkle() -> void:
	var pump: PumpComponent = station.bays[0].pump
	pump.finish_at(pump.target + 0.3)
	assert_eq(_world().last_sparkle_lane, -1)


func test_given_money_earned_then_a_cash_pop_floats_up_and_fades() -> void:
	var pump: PumpComponent = station.bays[0].pump
	pump.finish_at(pump.target)
	var pop: Label = station.cash_pops.back()
	assert_string_contains(pop.text, "+$")
	var y := pop.position.y
	station.tick_pops(0.5)
	assert_lt(pop.position.y, y, "floats up")
	station.tick_pops(5.0)
	assert_true(station.cash_pops.is_empty(), "gone after fading")


func test_given_customer_on_the_way_then_the_car_starts_on_the_road_and_ends_at_its_pump() -> void:
	var car: Node3D = _world().car_at(1)
	assert_almost_eq(car.position.z, StationWorld.ROAD_Z, 0.01, "starts on the road")
	assert_gt(car.position.x, 20.0, "far to the top right")
	_world().tick_cars(20.0)
	assert_almost_eq(car.position.x, StationWorld.STOP_X, 0.01)
	assert_almost_eq(car.position.z, _world().lane_z(1), 0.01)
	assert_almost_eq(car.rotation.y, 0.0, 0.01, "parked facing the way out")


func test_given_served_then_the_car_leaves_by_the_exit_apron_and_the_road() -> void:
	_world().tick_cars(20.0)
	var car: Node3D = _world().car_at(0)
	var pump: PumpComponent = station.bays[0].pump
	pump.finish_at(pump.target)
	var reached_apron := false
	for i in 200:
		_world().tick_cars(0.05)
		if car.position.x < StationWorld.APRON_OUT_X + 1.0 and car.position.z > _world().lane_z(0) + 1.0:
			reached_apron = true
			break
	assert_true(reached_apron, "turned down the exit apron toward the road")
	_world().tick_cars(30.0)
	assert_false(is_instance_valid(car) and car.is_inside_tree())


func test_given_miss_then_the_world_shakes_and_the_hud_does_not() -> void:
	var hud_before: Vector2 = station.bays[0].position
	var pump: PumpComponent = station.bays[0].pump
	pump.finish_at(pump.target + 5.0)
	assert_gt(_world().shake_amount, 0.0)
	_world().tick_shake(0.05)
	assert_true(_world().camera.h_offset != 0.0 or _world().camera.v_offset != 0.0)
	assert_eq(station.bays[0].position, hud_before)
	_world().tick_shake(3.0)
	assert_eq(_world().shake_amount, 0.0)
	assert_eq(_world().camera.h_offset, 0.0)


func test_given_shake_set_to_zero_then_no_shake() -> void:
	Tuning.set_value(station, "station/shake_strength", 0.0)
	var pump: PumpComponent = station.bays[0].pump
	pump.finish_at(pump.target + 5.0)
	assert_eq(_world().shake_amount, 0.0)
