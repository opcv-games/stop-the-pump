extends GutTest
## The station's cash. Rent will draw from it later. Refs #3

var wallet: WalletComponent


func before_each() -> void:
	wallet = WalletComponent.new()
	add_child_autofree(wallet)


func test_given_new_wallet_then_cash_is_zero() -> void:
	assert_eq(wallet.cash, 0.0)


func test_given_wallet_when_profit_and_loss_added_then_cash_tracks_both() -> void:
	watch_signals(wallet)
	wallet.add(9.0)
	wallet.add(-4.0)
	assert_almost_eq(wallet.cash, 5.0, 0.001)
	assert_signal_emit_count(wallet, "cash_changed", 2)
