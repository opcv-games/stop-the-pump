extends GutTest
## Spec: features/world_look.feature. The world behind the HUD. Refs #22

const SCENE := preload("res://scenes/greybox/pump_station.tscn")

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.profile_file = ""  # skip the naming screen in tests
	station.special_customer_chance = 0.0
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func test_given_station_then_a_clean_world_is_drawn_behind_the_hud() -> void:
	var view: WorldView = station.world_view
	assert_not_null(view)
	assert_lt(view.get_index(), station.bays[0].get_index(), "behind the pumps' HUD")
	assert_null(view.display.material, "no painterly filter (review of v0.20)")
	assert_false(ResourceLoader.exists("res://shaders/painterly.gdshader"))
	await wait_frames(2)
	assert_eq(view.display.size, station.size, "the world fills the screen (it was 0x0 once)")


func test_given_the_clock_moves_then_the_world_light_follows() -> void:
	var world: StationWorld = station.world_view.world
	station.clock.running = true
	station.clock.tick(station.clock.day_seconds * 0.4)
	assert_almost_eq(world.day_light.hour, station.clock.hour(), 0.01)


func test_given_f5_then_rain_toggles() -> void:
	var weather: WeatherComponent = station.world_view.world.weather
	var before := weather.raining
	station.toggle_rain()
	weather.update_hour(station.clock.hour())
	assert_ne(weather.raining, before)


func test_given_the_kit_then_scenery_and_decor_are_in_the_world() -> void:
	var world: StationWorld = station.world_view.world
	for n in ["Station", "Woods", "Road", "NamePylon", "VacantLot", "BrokenCar", "TirePile", "Dirt"]:
		assert_not_null(world.scenery.get_node_or_null(n), n)
