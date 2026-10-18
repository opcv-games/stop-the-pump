extends GutTest
## Spec: features/combo.feature. Refs #7

var combo: ComboComponent
var tiers: ScoreTiers


func before_each() -> void:
	tiers = ScoreTiers.new()
	combo = ComboComponent.new()
	combo.tiers = tiers
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


func test_given_x3_when_good_then_pays_good_points_times_three() -> void:
	_build_to(3)
	assert_eq(combo.register(ScoreTiers.GOOD), tiers.good_points * 3)
	assert_eq(combo.multiplier, 4)


func test_given_x3_when_ok_then_pays_ok_points_once_and_resets() -> void:
	_build_to(3)
	assert_eq(combo.register(ScoreTiers.OK), tiers.ok_points)
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


func test_given_several_stops_then_total_score_adds_up() -> void:
	combo.register(ScoreTiers.PERFECT)  # 100 x1
	combo.register(ScoreTiers.GOOD)     # 50 x2
	assert_eq(combo.total_score, tiers.perfect_points + tiers.good_points * 2)
