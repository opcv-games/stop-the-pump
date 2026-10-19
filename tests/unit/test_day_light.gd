extends GutTest
## Spec: features/world_look.feature. Refs #22


func test_given_8am_then_sun_is_low_warm_and_from_the_east() -> void:
	var s := DayLightComponent.sample(8.0)
	assert_lt(s.elevation, 25.0)
	assert_gt(s.elevation, 0.0)
	assert_lt(s.azimuth, 45.0, "east")
	assert_gt(s.sun_color.r, s.sun_color.b + 0.2, "warm")


func test_given_2pm_then_sun_is_high_and_white() -> void:
	var s := DayLightComponent.sample(14.0)
	assert_gt(s.elevation, 55.0)
	assert_almost_eq(s.sun_color.r, s.sun_color.b, 0.15)


func test_given_10pm_then_sun_is_down_and_night_glow_is_bright() -> void:
	var s := DayLightComponent.sample(22.0)
	assert_lt(s.sun_energy, 0.3)
	assert_gt(s.glow, 2.0)
	assert_gt(s.glow, DayLightComponent.sample(14.0).glow * 5.0)


func test_given_hours_between_keys_then_values_blend() -> void:
	var a := DayLightComponent.sample(10.0)
	var b := DayLightComponent.sample(14.0)
	var mid := DayLightComponent.sample(12.0)
	assert_between(mid.elevation, a.elevation, b.elevation)


func test_given_light_node_when_hour_applied_then_its_energy_follows() -> void:
	var day := DayLightComponent.new()
	var sun := DirectionalLight3D.new()
	day.sun = sun
	add_child_autofree(day)
	add_child_autofree(sun)
	day.apply_hour(14.0)
	var noon := sun.light_energy
	day.apply_hour(22.0)
	assert_lt(sun.light_energy, noon)
