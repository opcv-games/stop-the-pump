extends GutTest
## Spec: features/opening_hours.feature (#35): 15-second mornings that grow with the HOURS branch.

const SCENE := preload("res://scenes/greybox/pump_station.tscn")

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.profile_file = ""
	station.cars_gate_service = false
	station.special_customer_chance = 0.0
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func _hours() -> int:
	for i in Upgrades.BRANCHES.size():
		if Upgrades.BRANCHES[i].id == "hours":
			return i
	return -1


func _to_shop() -> void:
	station.wallet.add(9000.0)
	station.dev_end_day()
	station.continue_pressed()


func test_day_1_is_a_15_second_morning() -> void:
	assert_almost_eq(station.clock.open_hour, 7.0, 0.001)
	assert_almost_eq(station.clock.close_hour, 11.0, 0.001)
	assert_almost_eq(station.clock.day_seconds, 15.0, 0.001)


func test_the_hours_branch_exists_with_four_steps_to_11_pm() -> void:
	assert_ne(_hours(), -1)
	assert_eq(Upgrades.BRANCHES[_hours()].nodes.size(), 4)
	assert_eq(Upgrades.BRANCHES[_hours()].nodes[0].name, "Thermos of coffee")


func test_thermos_keeps_the_station_open_until_1_pm() -> void:
	_to_shop()
	assert_true(station.buy(_hours()))
	assert_almost_eq(station.clock.close_hour, 13.0, 0.001)
	assert_almost_eq(station.clock.day_seconds, 22.5, 0.001)


func test_every_hours_upgrade_opens_until_11_pm_for_60_seconds() -> void:
	_to_shop()
	for i in 4:
		assert_true(station.buy(_hours()))
	assert_almost_eq(station.clock.close_hour, 23.0, 0.001)
	assert_almost_eq(station.clock.day_seconds, 60.0, 0.001)


func test_one_game_hour_always_lasts_the_same() -> void:
	var before: float = station.clock.seconds_per_hour
	_to_shop()
	station.buy(_hours())
	assert_almost_eq(station.clock.seconds_per_hour, before, 0.001)


func test_the_pylon_shows_the_hours() -> void:
	var sign: Label3D = station.world_view.world.hours_label
	assert_eq(sign.text, "OPEN 7 AM – 11 AM")
	_to_shop()
	station.buy(_hours())
	assert_eq(sign.text, "OPEN 7 AM – 1 PM")


func test_a_new_run_resets_the_hours() -> void:
	_to_shop()
	station.buy(_hours())
	station.start_run()
	assert_almost_eq(station.clock.close_hour, 11.0, 0.001)
	assert_eq(station.world_view.world.hours_label.text, "OPEN 7 AM – 11 AM")


func test_the_hours_branch_is_in_the_tree() -> void:
	var found := false
	for n in UpgradeGraph.build(station):
		if n.kind == "branch" and Upgrades.BRANCHES[n.branch].id == "hours":
			found = true
	assert_true(found)
