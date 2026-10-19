extends GutTest
## Spec: features/lanes.feature (anchored HUD). Refs #25

const SCENE := preload("res://scenes/greybox/pump_station.tscn")

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.profile_file = ""
	station.special_customer_chance = 0.0
	station.arrival_min = 60.0
	station.arrival_max = 60.0
	station.second_customer_offset = 0.0
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false
	await wait_frames(2)


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func _five_pumps() -> void:
	station.wallet.add(9000.0)
	station.dev_end_day()
	station.continue_pressed()
	for i in 4:
		station.buy(1)
	station.continue_pressed()
	station.clock.running = false
	station.place_bays()


func test_given_station_then_each_card_sits_at_its_lane_anchor() -> void:
	station.place_bays()
	for bay in station.bays:
		assert_almost_eq(bay.position, station.anchor_position(bay.index), Vector2(0.5, 0.5))


func test_given_lane_anchor_then_it_is_on_that_lane_in_the_world() -> void:
	var world: StationWorld = station.world_view.world
	for i in StationWorld.MAX_LANES:
		assert_almost_eq(world.hud_anchor(i).z, world.lane_z(i), 0.001)


func test_given_bays_then_cards_are_compact_and_no_grey_panels_or_2d_cars() -> void:
	for bay in station.bays:
		assert_lte(bay.size.x, 270.0)
		assert_lte(bay.size.y, 80.0)
		assert_null(bay.get("_car"), "no 2D car")


func test_given_five_pumps_then_no_two_cards_overlap() -> void:
	_five_pumps()
	assert_eq(station.bays.size(), 5)
	for a in station.bays:
		for b in station.bays:
			if a == b:
				continue
			var ra := Rect2(a.position, PumpBay.FOOTPRINT)
			var rb := Rect2(b.position, PumpBay.FOOTPRINT)
			assert_false(ra.intersects(rb), "pump %d and pump %d cards overlap" % [a.index + 1, b.index + 1])


func test_given_five_pumps_then_every_card_is_on_screen() -> void:
	_five_pumps()
	var screen := Rect2(Vector2.ZERO, Vector2(1152, 648))
	for bay in station.bays:
		assert_true(screen.encloses(Rect2(bay.position, PumpBay.FOOTPRINT)), "pump %d card on screen" % (bay.index + 1))


func test_given_customer_then_car_visible_follows_the_3d_car() -> void:
	var bay: PumpBay = station.bays[0]
	assert_true(bay.car_visible())
	bay.show_empty()
	assert_false(bay.car_visible())


func test_given_result_then_it_pops_up_and_fades() -> void:
	var bay: PumpBay = station.bays[0]
	bay.show_result("GOOD  $0.30 over", Color.WHITE)
	assert_eq(bay.result_label.modulate.a, 1.0)
	bay.tick_popup(5.0)
	assert_eq(bay.result_label.modulate.a, 0.0)
	assert_string_contains(bay.result_label.text, "GOOD", "the text stays for anyone reading it")
