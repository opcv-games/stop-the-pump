extends GutTest
## Spec: features/god_run.feature (round 8): L'Écho de Saint-Clin-Clin, the morning paper.


func _run(day := 6) -> RunState:
	var r := RunState.new()
	r.day = day
	return r


func _report(tiers := {}, extra := {}) -> Dictionary:
	var t := {ScoreTiers.SUPER_PERFECT: 0, ScoreTiers.PERFECT: 0, ScoreTiers.GOOD: 0, ScoreTiers.OK: 0,
		ScoreTiers.MISS: 0, ScoreTiers.UNSERVED: 0}
	for k in tiers:
		t[k] = tiers[k]
	var rep := {"day": 5, "loot": 120.0, "cars": 8, "tiers": t, "best_combo": 2, "wasted": 0.0, "tank_left": 300.0}
	for k in extra:
		rep[k] = extra[k]
	return rep


func test_a_great_day_makes_the_front_page() -> void:
	var e := Newspaper.edition(_run(), null, _report({ScoreTiers.SUPER_PERFECT: 6}))
	assert_string_contains(e.headline, "TOPPED OFF")


func test_running_dry_beats_everything() -> void:
	var e := Newspaper.edition(_run(), null, _report({ScoreTiers.SUPER_PERFECT: 6}, {"out_of_gas": true}))
	assert_string_contains(e.headline, "RAN DRY")


func test_spills_and_waiting_make_bad_news() -> void:
	assert_string_contains(Newspaper.edition(_run(), null, _report({ScoreTiers.MISS: 4})).headline, "GAS ALL OVER")
	assert_string_contains(Newspaper.edition(_run(), null, _report({ScoreTiers.UNSERVED: 5})).headline, "GAVE UP WAITING")


func test_dads_postcards_come_every_ten_days() -> void:
	for d in [10, 20, 30, 40]:
		assert_false(Newspaper.edition(_run(d), null, _report()).postcard.is_empty(), "day %d" % d)
	assert_true(Newspaper.edition(_run(11), null, _report()).postcard.is_empty())
	assert_string_contains(Newspaper.postcard(20).from, "Saint-Jean")


func test_the_gossip_unlocks_the_rumours() -> void:
	var day5: Array = Newspaper.edition(_run(5), null, _report()).gossip
	assert_string_contains(day5[0], "saw your father", "the newest rumour leads")
	var day1: Array = Newspaper.edition(_run(1), null, _report()).gossip
	for g in day1:
		assert_false(g.contains("saw your father"), "not yet on day 1")


func test_the_classifieds_and_the_charts() -> void:
	var r := _run(8)
	r.cash = 5000.0
	r.tank = 0.0
	r.call_truck()
	r.cash_history = [80.0, 140.0, 210.0]
	var e := Newspaper.edition(r, MetaState.new(), _report())
	assert_eq(e.ads.size(), 2)
	assert_eq(e.prices.size(), 2, "the starting price and one delivery")
	assert_eq(e.cash.size(), 3)


func test_the_paper_is_the_same_twice() -> void:
	var a := Newspaper.edition(_run(14), null, _report({ScoreTiers.PERFECT: 3}))
	var b := Newspaper.edition(_run(14), null, _report({ScoreTiers.PERFECT: 3}))
	assert_eq(a.gossip, b.gossip)
	assert_eq(a.headline, b.headline)
