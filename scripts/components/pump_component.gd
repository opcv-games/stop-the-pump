class_name PumpComponent
extends Node
## One fuel pump: pours while held, stops on release, one pour per customer.
## A standalone component so a station can own 1 or 10 of these, and each can be tested alone.
## Serves: Mastery (the micro loop).

signal amount_changed(amount: float)
signal stopped(final_amount: float)

## Dollars poured per second while the key is held.
@export var flow_rate := 4.0
## Optional shared tank. When set, fuel comes out of it and an empty tank stops the pour (#8).
var tank: TankComponent

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
	var dollars := flow_rate * delta
	if tank:
		dollars = tank.draw(dollars)
	amount += dollars
	amount_changed.emit(amount)
	if tank and tank.is_empty():
		stop_pour()


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


## Dev mode: jumps the pump straight to `final_amount` and stops it (fuel still comes from the tank).
func finish_at(final_amount: float) -> void:
	if is_done:
		return
	var extra := final_amount - amount
	if tank and extra > 0.0:
		extra = tank.draw(extra)
	amount += extra
	amount_changed.emit(amount)
	is_pouring = true
	stop_pour()


## Readies the pump for the next customer.
func reset(new_target: float) -> void:
	amount = 0.0
	target = new_target
	is_pouring = false
	is_done = false
	amount_changed.emit(amount)
