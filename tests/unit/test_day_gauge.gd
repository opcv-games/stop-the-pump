extends GutTest
## One gauge for the day: fuel (orange, in dollars) turns into cash (green). Refs #9

var gauge: DayGauge


func before_each() -> void:
	gauge = DayGauge.new()
	add_child_autofree(gauge)
	gauge.setup(Vector2.ZERO, Vector2(80, 400))


func test_given_start_of_day_then_all_orange_up_to_the_start_line() -> void:
	gauge.set_values(0.0, 800.0, 800.0)
	assert_almost_eq(gauge.green_share, 0.0, 0.001)
	assert_almost_eq(gauge.top_share, gauge.line_share, 0.001)


func test_given_perfect_on_100_then_green_plus_orange_rises_above_the_line_by_the_tip() -> void:
	gauge.set_values(105.0, 700.0, 800.0)
	assert_gt(gauge.top_share, gauge.line_share)
	assert_almost_eq(gauge.top_share - gauge.line_share, 5.0 / gauge.scale_value, 0.001)


func test_given_overshoot_then_total_falls_below_the_line() -> void:
	gauge.set_values(20.0, 776.0, 800.0)  # pumped $24 for a $20 order
	assert_lt(gauge.top_share, gauge.line_share)
