class_name PumpComponent
extends Node
## One fuel pump: pours while held, stops on release, one pour per customer.
## A standalone component so a station can own 1 or 10 of these, and each can be tested alone.
## Serves: Mastery (the micro loop).

signal amount_changed(amount: float)
signal stopped(final_amount: float)

## Dollars poured per second while the key is held.
@export var flow_rate := 4.0

var amount := 0.0
var target := 0.0
var is_pouring := false
var is_done := false


func _process(delta: float) -> void:
	tick(delta)


## Advances the pump by delta seconds. Kept separate from _process so tests control time.
func tick(delta: float) -> void:
	if not is_pouring:
		return
	amount += flow_rate * delta
	amount_changed.emit(amount)


func start_pour() -> void:
	if is_done:
		return
	is_pouring = true


func stop_pour() -> void:
	if not is_pouring:
		return
	is_pouring = false
	is_done = true
	stopped.emit(amount)


## Readies the pump for the next customer.
func reset(new_target: float) -> void:
	amount = 0.0
	target = new_target
	is_pouring = false
	is_done = false
	amount_changed.emit(amount)
