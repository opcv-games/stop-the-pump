extends GutTest
## Spec: features/core_loop.feature — "Stop is scored by distance from the target". Refs #1

var tiers: ScoreTiers


func before_each() -> void:
	tiers = ScoreTiers.new()


func test_given_target_20_when_final_is_exactly_20_then_super_perfect() -> void:
	assert_eq(tiers.evaluate(20.0, 20.0), ScoreTiers.SUPER_PERFECT)


func test_given_target_20_when_final_is_20_03_then_super_perfect() -> void:
	assert_eq(tiers.evaluate(20.03, 20.0), ScoreTiers.SUPER_PERFECT)


func test_given_target_20_when_final_is_20_05_then_perfect() -> void:
	assert_eq(tiers.evaluate(20.05, 20.0), ScoreTiers.PERFECT)


func test_given_super_perfect_then_it_keeps_the_combo() -> void:
	assert_true(tiers.extends_combo(ScoreTiers.SUPER_PERFECT))


func test_given_target_20_when_final_is_19_70_then_good() -> void:
	assert_eq(tiers.evaluate(19.70, 20.0), ScoreTiers.GOOD)


func test_given_target_20_when_final_is_19_20_then_ok() -> void:
	assert_eq(tiers.evaluate(19.20, 20.0), ScoreTiers.OK)


func test_given_target_20_when_final_is_17_then_miss() -> void:
	assert_eq(tiers.evaluate(17.0, 20.0), ScoreTiers.MISS)


func test_given_target_20_when_overshoot_by_0_40_then_good() -> void:
	assert_eq(tiers.evaluate(20.40, 20.0), ScoreTiers.GOOD)


func test_given_target_20_when_overshoot_by_2_then_miss() -> void:
	assert_eq(tiers.evaluate(22.0, 20.0), ScoreTiers.MISS)


func test_given_wider_perfect_window_when_final_is_20_25_then_perfect() -> void:
	tiers.perfect_window = 0.30
	assert_eq(tiers.evaluate(20.25, 20.0), ScoreTiers.PERFECT)
