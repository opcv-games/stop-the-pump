extends GutTest
## Spec: features/god_run.feature (#37): the run, the fuel truck, cards, and Papa's Garage.

const SAVE := "user://test_godpump_meta.cfg"


func after_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _run() -> RunState:
	var r := RunState.new()
	r.rng.seed = 7
	return r


func test_a_new_run_starts_with_a_full_tank_and_starting_cash() -> void:
	var r := _run()
	assert_almost_eq(r.tank, GodData.BASE.tank_capacity, 0.01)
	assert_almost_eq(r.cash, GodData.BASE.start_cash, 0.01)
	assert_eq(r.day, 1)


func test_a_day_folds_into_the_run() -> void:
	var r := _run()
	r.end_day({"loot": 120.0, "tank_left": r.tank - 150.0, "xp": 30, "cars": 8, "tiers": {ScoreTiers.SUPER_PERFECT: 2}})
	assert_almost_eq(r.cash, 180.0, 0.01)
	assert_almost_eq(r.tank, GodData.BASE.tank_capacity - 150.0, 0.01)
	assert_eq(r.totals.supers, 2)
	assert_eq(r.xp, 30)


func test_the_truck_fills_the_tank_at_the_wholesale_price() -> void:
	var r := _run()
	r.tank = 400.0
	r.cash = 1000.0
	var cost := r.delivery_cost()
	assert_almost_eq(cost, (r.tank_capacity() - 400.0) / GodData.PUMP_PRICE * GodData.WHOLESALE_START, 0.5)
	assert_true(r.call_truck())
	assert_almost_eq(r.tank, r.tank_capacity(), 0.01)
	assert_almost_eq(r.cash, 1000.0 - cost, 0.01)


func test_every_delivery_raises_the_price() -> void:
	var r := _run()
	r.tank = 0.0
	r.cash = 5000.0
	r.call_truck()
	r.pick_card(r.offer[0])
	assert_almost_eq(r.price, GodData.WHOLESALE_START * (1.0 + GodData.PRICE_RISE), 0.0001)


func test_a_delivery_offers_three_different_cards() -> void:
	var r := _run()
	r.tank = 0.0
	r.cash = 5000.0
	r.call_truck()
	assert_eq(r.offer.size(), 3)
	assert_eq(r.offer.size(), {r.offer[0]: 1, r.offer[1]: 1, r.offer[2]: 1}.size())
	var picked: String = r.offer[1]
	assert_true(r.pick_card(picked))
	assert_true(picked in r.cards)
	assert_true(r.offer.is_empty())


func test_cards_change_the_mods() -> void:
	var r := _run()
	r.cards.append("rush_hour")
	assert_eq(r.mods().queue, 2)


func test_price_freeze_and_the_cousins_loan() -> void:
	var r := _run()
	r.cards.append("price_freeze")
	r.price_frozen = true
	r.tank = 0.0
	r.cash = 5000.0
	r.call_truck()
	assert_almost_eq(r.price, GodData.WHOLESALE_START, 0.0001, "frozen")
	r.offer = ["loan"]
	var cash := r.cash
	r.pick_card("loan")
	assert_almost_eq(r.cash, cash + 300.0, 0.01)
	r.tank = 0.0
	assert_almost_eq(r.delivery_cost(), roundf(r.tank_capacity() / 2.0 * r.price * 1.4), 1.0)


func test_luck_brings_rarer_cards() -> void:
	var plain := 0
	var lucky := 0
	for seed in 300:
		var r := _run()
		r.rng.seed = seed
		for id in r.draw_cards(3):
			if GodData.card(id).rarity != "common":
				plain += 1
	var m := MetaState.new()
	m.path = ""
	m.perk_tiers = {"lucky": 4}
	m.owned_bling = ["fuzzy_dice"]
	m.equipped_bling = ["fuzzy_dice"]
	for seed in 300:
		var r := RunState.new(m)
		r.rng.seed = seed
		for id in r.draw_cards(3):
			if GodData.card(id).rarity != "common":
				lucky += 1
	assert_gt(lucky, plain)


func test_out_of_gas_and_broke_is_bankrupt() -> void:
	var r := _run()
	r.tank = 0.0
	r.cash = 10.0
	assert_true(r.bankrupt())
	r.cash = 25.0  # enough for a partial delivery
	assert_false(r.bankrupt())
	r.cash = 5000.0
	assert_false(r.bankrupt())


func test_surviving_day_50_wins_the_run() -> void:
	var r := _run()
	r.day = GodData.FINAL_DAY
	r.end_day({"loot": 10.0})
	assert_true(r.won)
	assert_true(r.over)


func test_the_shop_sells_nodes_in_order() -> void:
	var r := _run()
	r.cash = 1000.0
	assert_eq(r.next_node("hours").id, "thermos")
	assert_true(r.buy("hours"))
	assert_almost_eq(r.mods().close_hour, 14.0, 0.001)
	assert_eq(r.next_node("hours").id, "mom_lunch")


func test_garage_purchases_apply_and_are_saved() -> void:
	var m := MetaState.new()
	m.path = SAVE
	m.xp = 5000
	assert_true(m.buy_nozzle("laser"))
	assert_true(m.buy_bling("receipt"))
	assert_true(m.buy_perk("nest_egg"))
	var r := RunState.new(m)
	assert_almost_eq(r.cash, GodData.BASE.start_cash + 50.0 + 40.0, 0.01)
	assert_almost_eq(r.mods().flow_mult, 1.4, 0.001)
	var back := MetaState.load_from(SAVE)
	assert_eq(back.nozzle, "laser")
	assert_true("receipt" in back.equipped_bling)
	assert_eq(back.perk_tiers.get("nest_egg", 0), 1)


func test_finishing_a_run_banks_xp_and_cars() -> void:
	var m := MetaState.new()
	m.path = ""
	var r := RunState.new(m)
	r.xp = 120
	r.totals.cars = 40
	r.day = 6
	r.finish()
	assert_eq(m.xp, 120)
	assert_eq(m.total_cars, 40)
	assert_eq(m.best_day, 6)
	assert_eq(m.runs, 1)


func test_car_types_unlock_with_cars_filled() -> void:
	var m := MetaState.new()
	m.path = ""
	assert_eq(m.unlocked_cars(), ["sedan"])
	assert_eq(m.next_unlock().id, "pickup")
	m.total_cars = 95
	assert_true("cadillac" in m.unlocked_cars())
	assert_eq(m.next_unlock().id, "bazou")


func test_the_truck_sells_what_the_cash_buys() -> void:
	var r := _run()
	r.tank = 0.0
	var full := r.delivery_cost()
	r.cash = full * 0.25
	assert_true(r.call_truck())
	assert_almost_eq(r.cash, 0.0, 0.01)
	assert_almost_eq(r.tank, r.tank_capacity() * 0.25, 1.0)
	assert_true(r.offer.is_empty(), "under half a tank: no cards")
	r.cash = 5.0
	assert_false(r.call_truck(), "under $20: no truck")


func test_a_big_partial_delivery_still_deals_cards() -> void:
	var r := _run()
	r.tank = 0.0
	r.cash = r.delivery_cost() * 0.6
	assert_true(r.call_truck())
	assert_eq(r.offer.size(), 3)


func test_the_run_knows_when_the_tank_wont_last() -> void:
	var r := _run()
	r.tank = r.tank_capacity()
	assert_false(r.tank_warning())
	r.tank = 40.0
	assert_true(r.tank_warning())
	r.cash = 500.0
	assert_true(r.purchase_risky(400.0), "leaves less than the truck costs")
	assert_false(r.purchase_risky(10.0))


func test_the_suppliers_contract_slows_the_price_rise() -> void:
	var r := _run()
	var plain := r.price_rise()
	r.meta.perk_tiers = {"contract": 2}
	assert_almost_eq(r.price_rise(), plain * 0.64, 0.0001)


func test_premium_gas_makes_sales_pay_more() -> void:
	var r := _run()
	r.meta.perk_tiers = {"premium": 3}
	assert_almost_eq(r.mods().sale_mult, 1.331, 0.001)


# --- Round 8: the CAMION branch and the upgrades with two parents ------------------------------

func test_a_link_needs_both_of_its_parents() -> void:
	var r := _run()
	r.cash = 5000.0
	assert_false(r.link_open("drive_thru"))
	assert_false(r.buy_link("drive_thru"))
	while r.owned.get("service", 0) < 3:
		assert_true(r.buy("service"))  # ...up to Café pour la file
	assert_false(r.link_open("drive_thru"), "one parent isn't enough")
	assert_true(r.buy("hours"))  # Thermos de café
	assert_true(r.owns("coffee") and r.owns("thermos"))
	assert_true(r.link_open("drive_thru"))
	var before := r.cash
	assert_true(r.buy_link("drive_thru"))
	assert_eq(r.cash, before - GodData.link("drive_thru").price)
	assert_eq(r.mods().coffee_sale, 1.0)
	assert_false(r.buy_link("drive_thru"), "only once")


func test_every_link_names_two_real_parents() -> void:
	for l in GodData.LINKS:
		assert_eq(l.needs.size(), 2, l.id)
		for need in l.needs:
			assert_false(GodData.shop_node(need).is_empty(), "%s needs %s" % [l.id, need])


func test_bulk_buying_when_the_tank_is_low() -> void:
	var r := _run()
	r.tank = r.tank_capacity() * 0.2
	var plain := r.delivery_cost()
	r.owned["truck"] = 2  # Jauge d'alarme, Achat en vrac
	assert_almost_eq(r.delivery_cost(), roundf(plain * 0.9), 1.0)
	r.tank = r.tank_capacity() * 0.5
	var half := r.delivery_cost()
	r.owned["truck"] = 0
	assert_eq(r.delivery_cost(), half, "no discount above 25%")


func test_the_used_tanker_halves_a_partial_deliverys_rise() -> void:
	var r := _run()
	r.owned["truck"] = 3
	r.tank = 0.0
	r.cash = r.delivery_cost() * 0.6
	var p := r.price
	assert_true(r.call_truck())
	assert_almost_eq(r.price, p * (1.0 + GodData.PRICE_RISE * 0.5), 0.0001)


func test_the_forward_contract_freezes_every_fourth_delivery() -> void:
	var r := _run()
	r.links = ["forward_contract"]
	r.cash = 100000.0
	var prices := []
	for i in 4:
		r.tank = 0.0
		assert_true(r.call_truck())
		prices.append(r.price)
	assert_gt(prices[2], prices[1])
	assert_eq(prices[3], prices[2], "the fourth delivery comes at the old price")
