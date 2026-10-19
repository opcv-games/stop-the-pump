extends GutTest
## Spec: features/world_look.feature. Refs #22

var weather: WeatherComponent


func before_each() -> void:
	weather = WeatherComponent.new()
	weather.ramp_seconds = 2.0
	add_child_autofree(weather)


func test_given_rain_started_when_time_passes_then_intensity_reaches_full() -> void:
	weather.set_raining(true)
	weather.tick(1.0)
	assert_between(weather.intensity, 0.3, 0.7)
	weather.tick(2.0)
	assert_eq(weather.intensity, 1.0)


func test_given_rain_stopped_then_it_eases_off() -> void:
	weather.set_raining(true)
	weather.tick(5.0)
	weather.set_raining(false)
	weather.tick(5.0)
	assert_eq(weather.intensity, 0.0)


func test_given_chance_1_then_the_day_has_a_rain_spell_inside_opening_hours() -> void:
	weather.rain_chance = 1.0
	weather.begin_day()
	assert_true(weather.has_spell)
	assert_between(weather.spell_start, 7.0, 23.0)
	assert_gt(weather.spell_end, weather.spell_start)
	weather.update_hour(weather.spell_start + 0.1)
	assert_true(weather.raining)
	weather.update_hour(weather.spell_end + 0.1)
	assert_false(weather.raining)


func test_given_chance_0_then_no_rain_today() -> void:
	weather.rain_chance = 0.0
	weather.begin_day()
	assert_false(weather.has_spell)
	weather.update_hour(15.0)
	assert_false(weather.raining)


func test_given_dev_toggle_then_rain_flips_and_overrides_the_schedule() -> void:
	weather.rain_chance = 0.0
	weather.begin_day()
	weather.toggle()
	weather.update_hour(15.0)
	assert_true(weather.raining)
	weather.toggle()
	weather.update_hour(15.0)
	assert_false(weather.raining)
