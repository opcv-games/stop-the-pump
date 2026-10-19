extends GutTest
## Spec: features/economy.feature. Refs #3

var economy: FuelEconomy
var tiers: ScoreTiers


func before_each() -> void:
	tiers = ScoreTiers.new()
	economy = FuelEconomy.new()
	economy.tiers = tiers


func _settle(final_amount: float, multiplier := 1) -> FuelEconomy.Receipt:
	return economy.settle(final_amount, 20.0, tiers.evaluate(final_amount, 20.0), multiplier)


func test_given_target_20_when_stopped_exactly_then_margin_plus_perfect_tip() -> void:
	var r := _settle(20.0)
	assert_almost_eq(r.sale, 20.0, 0.001)
	assert_almost_eq(r.fuel_cost, 16.0, 0.001)
	assert_almost_eq(r.tip, 5.0, 0.001)
	assert_almost_eq(r.profit, 9.0, 0.001)


func test_given_target_20_when_overshot_to_21_then_customer_pays_20_and_player_pays_21_of_fuel() -> void:
	var r := _settle(21.0)
	assert_almost_eq(r.sale, 20.0, 0.001)
	assert_almost_eq(r.fuel_cost, 16.8, 0.001)
	assert_almost_eq(r.overshoot, 1.0, 0.001)


func test_given_target_20_when_stopped_short_with_good_then_sale_is_what_was_pumped_and_no_tip() -> void:
	var r := _settle(19.70)
	assert_almost_eq(r.sale, 19.70, 0.001)
	assert_almost_eq(r.tip, 0.0, 0.001)
	assert_true(r.short)


func test_given_target_20_when_stopped_short_but_perfect_then_tip_is_paid() -> void:
	var r := _settle(19.95)
	assert_almost_eq(r.tip, 5.0, 0.001)


func test_given_combo_x3_when_good_overshoot_then_tip_is_tripled() -> void:
	var r := _settle(20.30, 3)
	assert_almost_eq(r.tip, 6.0, 0.001)
	assert_almost_eq(r.profit, 20.0 - 16.24 + 6.0, 0.001)


func test_given_miss_far_over_then_profit_can_go_negative() -> void:
	var r := _settle(30.0)
	assert_almost_eq(r.profit, 20.0 - 24.0, 0.001)
