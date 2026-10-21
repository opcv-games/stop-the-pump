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
	assert_almost_eq(cost, 400.0 / GodData.PUMP_PRICE * GodData.WHOLESALE_START, 0.5)
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
