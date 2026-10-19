class_name WalletComponent
extends Node
## The station's two currencies, kept apart on purpose (design rule: the combo never changes cash).
## Cash pays for refills and rent between days; XP will buy permanent upgrades. Serves: Advancement. Refs #3, #8

signal cash_changed(cash: float, delta: float)
signal xp_changed(xp: int)

@export var cash := 0.0
var xp := 0


func add(amount: float) -> void:
	cash += amount
	cash_changed.emit(cash, amount)


func add_xp(amount: int) -> void:
	if amount == 0:
		return
	xp += amount
	xp_changed.emit(xp)
