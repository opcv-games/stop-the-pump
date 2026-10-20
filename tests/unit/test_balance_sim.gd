extends GutTest
## Spec: features/balance_sim.feature (#6): bots play headless runs to compare strategies.


func _station(seed: int = 1) -> SimStation:
	var st := SimStation.from_game_defaults()
	st.rng.seed = seed
	autofree(st)
	return st


func test_defaults_come_from_the_game() -> void:
	var st := _station()
	assert_eq(st.pumps.size(), 1, "one starting pump (#30)")
	assert_almost_eq(st.economy.rent_for(1), 60.0, 0.01)
	assert_almost_eq(st.tank.capacity_liters, 400.0, 0.01)
	assert_almost_eq(st.day_seconds, 180.0, 0.01)


func test_a_day_serves_cars_and_earns_cash() -> void:
	var st := _station()
	var day := BalanceSim.play_day(st)
	assert_gt(day.stops, 5)
	assert_gt(day.earned, 0.0)
	assert_lt(st.tank.liters, st.tank.capacity_liters)


func test_tiers_are_evenly_split() -> void:
	var st := _station(7)
	var counts := {}
	for i in 60:
		st.tank.liters = st.tank.capacity_liters
		var day := BalanceSim.play_day(st)
		for t in day.tiers:
			counts[t] = counts.get(t, 0) + day.tiers[t]
	var total := 0
	for t in counts:
		total += counts[t]
	for t in BalanceSim.TIERS:
		assert_almost_eq(float(counts.get(t, 0)) / total, 0.2, 0.04, t)


func test_an_empty_tank_ends_the_day_early() -> void:
	var st := _station()
	st.tank.liters = 10.0
	var day := BalanceSim.play_day(st)
	assert_true(day.ran_dry)
	assert_almost_eq(st.tank.liters, 0.0, 0.001)


func test_rent_with_no_cash_evicts() -> void:
	var st := _station()
	st.tank.liters = 0.0
	st.cash = 0.0
	var run := BalanceSim.play_run(BalanceSim.strategy("hoard"), st)
	assert_true(run.evicted)
	assert_eq(run.days, 1)


func test_upgrades_apply_through_the_game_code() -> void:
	var st := _station()
	st.cash = 5000.0
	assert_true(st.buy_branch("pumps"))
	assert_eq(st.pumps.size(), 2)
	assert_true(st.buy_branch("marketing"))
	assert_almost_eq(st.arrival_max, 4.0, 0.01, "Flyers: cars arrive 20% sooner")
	assert_true(st.buy_pump(1))
	assert_true(st.pumps[1].self_service)


func test_buying_respects_the_fuel_set_aside() -> void:
	var st := _station()
	st.cash = 100.0
	st.fuel_reserve = 60.0
	assert_false(st.buy_branch("marketing"), "Flyers cost $80; only $40 is free")


func test_self_service_pumps_earn_without_tiers() -> void:
	var st := _station()
	st.cash = 5000.0
	st.buy_pump(0)
	var day := BalanceSim.play_day(st)
	assert_gt(day.self_stops, 0)
	assert_eq(day.stops, day.self_stops)


func test_every_strategy_completes_a_seeded_run() -> void:
	for name in BalanceSim.STRATEGIES:
		var st := _station(3)
		var run := BalanceSim.play_run(BalanceSim.strategy(name), st)
		assert_between(run.days, 1, st.run_days, name)


func test_same_seed_same_result() -> void:
	var a := BalanceSim.play_run(BalanceSim.strategy("pumps_first"), _station(42))
	var b := BalanceSim.play_run(BalanceSim.strategy("pumps_first"), _station(42))
	assert_almost_eq(a.cash, b.cash, 0.001)
