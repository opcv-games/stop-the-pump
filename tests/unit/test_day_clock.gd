extends GutTest
## Spec: features/day.feature. Refs #8

var clock: DayClock


func before_each() -> void:
	clock = DayClock.new()
	clock.open_hour = 7.0
	clock.close_hour = 23.0
	clock.day_seconds = 180.0
	add_child_autofree(clock)
	clock.start()


func test_given_day_started_then_it_is_7am() -> void:
	assert_eq(clock.label(), "7:00 AM")


func test_given_half_the_day_passed_then_it_is_3pm() -> void:
	clock.tick(90.0)
	assert_eq(clock.label(), "3:00 PM")


func test_given_3_minutes_passed_then_closed_signal_fires_once() -> void:
	watch_signals(clock)
	clock.tick(179.0)
	assert_signal_not_emitted(clock, "closed")
	clock.tick(5.0)
	clock.tick(5.0)
	assert_signal_emit_count(clock, "closed", 1)
	assert_true(clock.is_closed())


func test_given_clock_not_started_when_time_passes_then_nothing_moves() -> void:
	var idle := DayClock.new()
	add_child_autofree(idle)
	idle.tick(50.0)
	assert_eq(idle.elapsed, 0.0)
