class_name WalletComponent
extends Node
## The station's cash. Its own component so rent, restocking and the shop can all draw from it.
## Serves: Advancement. Refs #3

signal cash_changed(cash: float, delta: float)

@export var cash := 0.0


func add(amount: float) -> void:
	cash += amount
	cash_changed.emit(cash, amount)
