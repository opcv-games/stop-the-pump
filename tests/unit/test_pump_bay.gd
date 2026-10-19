extends GutTest
## Spec: features/cleaning.feature. Refs #9

var bay: PumpBay


func before_each() -> void:
	bay = PumpBay.new()
	add_child_autofree(bay)
	bay.setup(0, 4.0)
	bay.new_customer(20.0)


func test_given_bay_when_cleaning_starts_then_it_takes_no_pours() -> void:
	bay.start_cleaning(4.0)
	bay.press()
	bay.pump.tick(1.0)
	assert_true(bay.cleaning)
	assert_eq(bay.pump.amount, 0.0)


func test_given_cleaning_for_4s_when_3_9s_pass_then_still_cleaning() -> void:
	bay.start_cleaning(4.0)
	bay.tick_cleaning(3.9)
	assert_true(bay.cleaning)


func test_given_cleaning_for_4s_when_4s_pass_then_done_and_signal_fires() -> void:
	watch_signals(bay)
	bay.start_cleaning(4.0)
	bay.tick_cleaning(2.0)
	bay.tick_cleaning(2.5)
	assert_false(bay.cleaning)
	assert_signal_emit_count(bay, "cleaning_finished", 1)
