extends GutTest
## Spec: features/economy.feature. Refs #3, #8

var economy: FuelEconomy
var tiers: ScoreTiers


func before_each() -> void:
	tiers = ScoreTiers.new()
	economy = FuelEconomy.new()


func _settle(final_amount: float) -> FuelEconomy.Receipt:
	return economy.settle(final_amount, 20.0, tiers.evaluate(final_amount, 20.0))


func test_given_target_20_when_stopped_exactly_then_full_sale_plus_super_perfect_tip() -> void:
	var r: FuelEconomy.Receipt = _settle(20.0)
	assert_almost_eq(r.sale, 20.0, 0.001)
	assert_almost_eq(r.tip, 8.0, 0.001)
	assert_almost_eq(r.earned, 28.0, 0.001)


func test_given_target_20_when_stopped_at_20_08_then_perfect_tip() -> void:
	assert_almost_eq(_settle(20.08).tip, 5.0, 0.001)


func test_given_target_20_when_overshot_to_21_then_customer_pays_20_and_1_dollar_is_given_away() -> void:
	var r: FuelEconomy.Receipt = _settle(21.0)
	assert_almost_eq(r.sale, 20.0, 0.001)
	assert_almost_eq(r.overshoot, 1.0, 0.001)


func test_given_target_20_when_stopped_short_with_good_then_no_tip() -> void:
	var r: FuelEconomy.Receipt = _settle(19.70)
	assert_almost_eq(r.sale, 19.70, 0.001)
	assert_almost_eq(r.tip, 0.0, 0.001)
	assert_true(r.short)


func test_given_target_20_when_stopped_short_but_perfect_then_tip_is_paid() -> void:
	assert_almost_eq(_settle(19.93).tip, 5.0, 0.001)
	assert_almost_eq(_settle(19.98).tip, 8.0, 0.001)


func test_given_good_overshoot_then_good_tip_is_paid() -> void:
	assert_almost_eq(_settle(20.30).tip, 2.0, 0.001)


func test_given_perfect_at_combo_x3_then_xp_is_300() -> void:
	assert_eq(economy.xp_for(ScoreTiers.PERFECT, 3), 300)


func test_given_super_perfect_at_combo_x2_then_xp_is_400() -> void:
	assert_eq(economy.xp_for(ScoreTiers.SUPER_PERFECT, 2), 400)


func test_given_miss_then_no_xp() -> void:
	assert_eq(economy.xp_for(ScoreTiers.MISS, 4), 0)


func test_given_100_litres_used_then_refill_costs_70_percent_of_pump_price() -> void:
	assert_almost_eq(economy.refill_cost(100.0), 140.0, 0.001)  # balance pass (#34): was 80%


func test_given_day_1_and_day_3_then_rent_grows_each_day() -> void:
	assert_almost_eq(economy.rent_for(1), economy.rent_base, 0.001)
	assert_almost_eq(economy.rent_for(3), economy.rent_base + 2 * economy.rent_growth, 0.001)
