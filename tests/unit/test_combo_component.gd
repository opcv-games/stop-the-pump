extends GutTest
## Spec: features/combo.feature. Refs #7, #3

var combo: ComboComponent


func before_each() -> void:
	combo = ComboComponent.new()
	combo.max_multiplier = 5
	add_child_autofree(combo)


func _build_to(multiplier: int) -> void:
	while combo.multiplier < multiplier:
		combo.register(ScoreTiers.GOOD)


func test_given_fresh_combo_then_multiplier_is_one() -> void:
	assert_eq(combo.multiplier, 1)


func test_given_x1_when_good_then_multiplier_becomes_two() -> void:
	combo.register(ScoreTiers.GOOD)
	assert_eq(combo.multiplier, 2)


func test_given_x3_when_good_then_stop_is_paid_at_x3_and_combo_becomes_x4() -> void:
	_build_to(3)
	assert_eq(combo.register(ScoreTiers.GOOD), 3)
	assert_eq(combo.multiplier, 4)


func test_given_x3_when_ok_then_stop_is_paid_at_x1_and_combo_resets() -> void:
	_build_to(3)
	assert_eq(combo.register(ScoreTiers.OK), 1)
	assert_eq(combo.multiplier, 1)


func test_given_x3_when_miss_then_combo_broken_signal_carries_lost_multiplier() -> void:
	_build_to(3)
	watch_signals(combo)
	combo.register(ScoreTiers.MISS)
	assert_signal_emitted_with_parameters(combo, "combo_broken", [3])


func test_given_x1_when_ok_then_no_combo_broken_signal() -> void:
	watch_signals(combo)
	combo.register(ScoreTiers.OK)
	assert_signal_not_emitted(combo, "combo_broken")


func test_given_max_multiplier_when_perfect_then_multiplier_stays_capped() -> void:
	_build_to(5)
	combo.register(ScoreTiers.PERFECT)
	assert_eq(combo.multiplier, 5)
