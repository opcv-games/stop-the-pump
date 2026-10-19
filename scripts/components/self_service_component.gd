class_name SelfServiceComponent
extends Node
## Runs a pump without the player: the customer fumbles with their card, pumps exactly their order,
## takes a moment to pay, then leaves. A separate component so any pump can be converted, and the
## played pump stays untouched. Earns less than a played pump (design rule 1). Serves: Advancement. Refs #17

signal phase_changed(phase: Phase)
signal paid(amount: float)

enum Phase { IDLE, CARD, PUMPING, PAYING }

## Seconds the customer spends with their card before fuel flows (random between these).
@export var card_wait_min := 2.0
@export var card_wait_max := 4.0
## Seconds to pay once the order is in the tank.
@export var paying_seconds := 2.0

var phase := Phase.IDLE
var pump: PumpComponent

var _left := 0.0


## Takes over a pump: it no longer runs on its own clock, this component drives it.
func attach(p: PumpComponent) -> void:
	pump = p
	pump.set_process(false)


## Gives the pump back to the player.
func detach() -> void:
	if pump:
		pump.set_process(true)
	pump = null
	phase = Phase.IDLE


func _process(delta: float) -> void:
	tick(delta)


## A customer has pulled in (the pump's target is their order).
func begin() -> void:
	_set_phase(Phase.CARD)
	_left = randf_range(card_wait_min, card_wait_max)


## Kept separate from _process so tests control time.
func tick(delta: float) -> void:
	match phase:
		Phase.CARD:
			_left -= delta
			if _left <= 0.0:
				var spill := -_left
				_set_phase(Phase.PUMPING)
				pump.start_pour()
				_pump_for(spill)
		Phase.PUMPING:
			_pump_for(delta)
		Phase.PAYING:
			_left -= delta
			if _left <= 0.0:
				_set_phase(Phase.IDLE)
				paid.emit(pump.amount)


## Pours for `seconds`, stopping exactly on the order: self-service customers never overshoot.
func _pump_for(seconds: float) -> void:
	if seconds <= 0.0 or not pump.is_pouring:
		return
	var remaining := pump.target - pump.amount
	if pump.flow_rate * seconds >= remaining:
		pump.finish_at(pump.target)
	else:
		pump.tick(seconds)
	if pump.is_done:
		_left = paying_seconds
		_set_phase(Phase.PAYING)


func _set_phase(p: Phase) -> void:
	phase = p
	phase_changed.emit(p)
