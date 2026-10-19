extends GutTest
## The station's two currencies: cash (spent between days) and XP (permanent upgrades later). Refs #3, #8

var wallet: WalletComponent


func before_each() -> void:
	wallet = WalletComponent.new()
	add_child_autofree(wallet)


func test_given_wallet_when_cash_earned_and_spent_then_cash_tracks_both() -> void:
	watch_signals(wallet)
	wallet.add(25.0)
	wallet.add(-10.0)
	assert_almost_eq(wallet.cash, 15.0, 0.001)
	assert_signal_emit_count(wallet, "cash_changed", 2)


func test_given_wallet_when_xp_earned_then_xp_grows_and_cash_does_not() -> void:
	watch_signals(wallet)
	wallet.add_xp(300)
	assert_eq(wallet.xp, 300)
	assert_eq(wallet.cash, 0.0)
	assert_signal_emitted_with_parameters(wallet, "xp_changed", [300])
