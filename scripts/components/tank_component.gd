class_name TankComponent
extends Node
## The station's single fuel tank. Every pump draws from it, so it works like stamina:
## when it runs dry the day is over. Overshoot fuel comes out of here too. Serves: Advancement. Refs #8

signal level_changed(liters: float)
signal emptied

@export var capacity_liters := 400.0
## Pump price, used to turn the dollars on a pump display into litres.
@export var price_per_liter := 2.0

var liters := 400.0


func _ready() -> void:
	liters = capacity_liters


## Takes up to `dollars` worth of fuel and returns the dollars actually drawn.
func draw(dollars: float) -> float:
	if liters <= 0.0:
		return 0.0
	var wanted := dollars / price_per_liter
	var taken := minf(wanted, liters)
	liters -= taken
	level_changed.emit(liters)
	if liters <= 0.000001:
		liters = 0.0
		emptied.emit()
	return taken * price_per_liter


func is_empty() -> bool:
	return liters <= 0.0


func liters_used() -> float:
	return capacity_liters - liters


func remaining_value() -> float:
	return liters * price_per_liter


## Fills the tank back up and returns how many litres went in.
func refill() -> float:
	var added := liters_used()
	liters = capacity_liters
	level_changed.emit(liters)
	return added
