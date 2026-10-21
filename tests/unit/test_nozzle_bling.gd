extends GutTest
## Spec: features/god_run.feature (round 8): the bling shows on the nozzle and swings with it.


func test_dangling_bling_swings_when_the_nozzle_moves() -> void:
	var b := NozzleBling.new()
	b.equipped = ["pine", "fuzzy_dice"]
	b.step(0.016, Vector2(400, 300))
	b.step(0.016, Vector2(400, 300))
	for i in 10:
		b.step(0.016, Vector2(400 + i * 12.0, 300))  # a quick move to the right
	assert_ne(b._swing.pine.a, 0.0)
	assert_lt(b._swing.pine.a, 0.0, "it lags behind: swings left when pushed right")
	for i in 400:
		b.step(0.016, Vector2(520, 300))
	assert_almost_eq(b._swing.pine.a, 0.0, 0.05, "and settles back to hanging straight")


func test_only_equipped_bling_dangles() -> void:
	var b := NozzleBling.new()
	b.equipped = ["medal"]
	b.owned = ["medal", "pine", "rabbit"]
	b.step(0.016, Vector2.ZERO)
	b.step(0.016, Vector2(50, 0))
	assert_true(b._swing.has("medal"))
	assert_false(b._swing.has("pine"), "owned but not equipped: just a ring")
