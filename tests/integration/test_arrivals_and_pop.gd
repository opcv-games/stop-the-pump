extends GutTest
## Spec: features/juice.feature (#27): parked-only service, smooth driving, sounds, pump pop-in.

const SCENE := preload("res://scenes/greybox/pump_station.tscn")

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.pump_count = 2  # these rules need two pumps; the one-pump start is in test_first_minutes
	station.profile_file = ""
	station.cars_gate_service = true
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


func test_given_car_still_driving_in_then_the_pump_cannot_be_poured() -> void:
	var bay: PumpBay = station.bays[0]
	assert_true(bay.waiting)
	assert_string_contains(bay.target_label.text, "arriving")
	station.press(0)
	bay.pump.tick(1.0)
	assert_eq(bay.pump.amount, 0.0)


func test_given_car_parks_then_the_order_appears_and_the_pump_can_be_poured() -> void:
	var bay: PumpBay = station.bays[0]
	_world().tick_cars(15.0)
	assert_false(bay.waiting)
	assert_gt(bay.pump.target, 0.0)
	assert_string_contains(bay.target_label.text, "$%.2f" % bay.pump.target)
	station.press(0)
	bay.pump.tick(1.0)
	assert_gt(bay.pump.amount, 0.0)
	station.release(0)


func test_given_businessman_then_his_patience_starts_only_once_parked() -> void:
	var bay: PumpBay = station.bays[0]
	bay.show_empty()
	station.arrive(bay, 40.0, "businessman")
	bay.customer.tick(10.0)
	assert_true(bay.car_visible(), "still coming: no honking countdown yet")
	_world().tick_cars(15.0)
	assert_eq(bay.customer.type, "businessman")


func test_given_a_corner_then_the_car_turns_gradually() -> void:
	var car: Node3D = _world().car_at(0)
	var last := car.rotation.y
	var biggest_step := 0.0
	var seen_between := false
	for i in 400:
		_world().tick_cars(0.02)
		biggest_step = maxf(biggest_step, absf(angle_difference(last, car.rotation.y)))
		last = car.rotation.y
		var deg := absf(rad_to_deg(car.rotation.y))
		if deg > 15.0 and deg < 75.0:
			seen_between = true
	assert_true(seen_between, "heading passes through in-between angles (no 90 degree snap)")
	assert_lt(rad_to_deg(biggest_step), 12.0, "no sudden turn")


func test_given_arrival_then_the_car_eases_to_a_stop() -> void:
	var car: Node3D = _world().car_at(0)
	var prev := car.position
	var last_speed := 99.0
	for i in 600:
		_world().tick_cars(0.02)
		if car.position.is_equal_approx(prev):
			break
		last_speed = car.position.distance_to(prev) / 0.02
		prev = car.position
	assert_lt(last_speed, 4.0, "slow on the last step before stopping")


func test_given_pouring_then_glug_and_counter_sounds_exist() -> void:
	assert_true(ResourceLoader.exists(SoundFeedback.DIR + "glug_loop.wav"))
	for i in 3:
		assert_true(ResourceLoader.exists(SoundFeedback.DIR + "counter_%d.wav" % (i + 1)))
	assert_true(ResourceLoader.exists(SoundFeedback.DIR + "pop.wav"))
	assert_false(ResourceLoader.exists(SoundFeedback.DIR + "tick.wav"), "the clicky tick is gone")


func test_given_pump_built_when_next_day_opens_then_it_pops_in() -> void:
	station.wallet.add(5000.0)
	station.dev_end_day()
	station.continue_pressed()
	station.buy(1)
	var pump: Node3D = _world().pumps[2].pump
	station.continue_pressed()
	assert_lt(pump.scale.y, 0.5, "starts squashed in the ground")
	_world().tick_pop(0.3)
	_world().tick_pop(3.0)
	assert_almost_eq(pump.scale.y, 1.0, 0.001)
	assert_almost_eq(pump.position.y, 0.22, 0.001)


func test_given_starting_pumps_then_they_do_not_pop() -> void:
	assert_almost_eq(_world().pumps[0].pump.scale.y, 1.0, 0.001)
