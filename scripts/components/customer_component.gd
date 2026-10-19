class_name CustomerComponent
extends Node
## The car at a pump and its rules: the Grandpa changes his order once, the Businessman drives off
## if pouring doesn't start in time, the $20 Guy makes overshoot come out of the player's pocket.
## One per pump, so each pump's customer is tested and tuned on its own. Serves: Comedy, Mastery. Refs #5

signal said(text: String)
signal order_changed(new_target: float)
signal drove_off

## Seconds the Businessman waits for the pour to start.
@export var patience_seconds := 4.0
## Share of the order poured before the Grandpa changes his mind.
@export var grandpa_change_at := 0.6

var type := ""
var pump: PumpComponent

var _changed := false
var _patience := 0.0
var _last_honk := -1


func attach(p: PumpComponent) -> void:
	pump = p
	pump.amount_changed.connect(_on_amount_changed)


func _process(delta: float) -> void:
	tick(delta)


## A car pulled in; the pump's target is its order.
func begin(customer_type: String) -> void:
	type = customer_type
	_changed = false
	_patience = patience_seconds
	_last_honk = -1
	said.emit(Customers.line(type, "hello", pump.target))


func clear() -> void:
	type = ""


func out_of_pocket() -> bool:
	return type == "twenty_guy"


## Kept separate from _process so tests control time.
func tick(delta: float) -> void:
	if type != "businessman" or pump.is_pouring or pump.is_done or pump.amount > 0.0:
		return
	_patience -= delta
	var whole := ceili(_patience)
	if whole != _last_honk and _patience > 0.0:
		_last_honk = whole
		said.emit("%s  (%ds)" % [Customers.line(type, "honk"), whole])
	if _patience <= 0.0:
		said.emit(Customers.line(type, "left"))
		type = ""
		drove_off.emit()


func _on_amount_changed(amount: float) -> void:
	if type != "grandpa" or _changed or not pump.is_pouring:
		return
	if amount < pump.target * grandpa_change_at:
		return
	_changed = true
	# Rule 4: the new order is always still reachable, at least $3 above the meter.
	var options: Array[float] = []
	for delta in [-5.0, 5.0, 10.0]:
		var t: float = pump.target + delta
		if t >= amount + 3.0:
			options.append(t)
	var new_target: float = options.pick_random() if not options.is_empty() else ceilf(amount) + 5.0
	pump.target = new_target
	said.emit(Customers.line(type, "changed", new_target))
	order_changed.emit(new_target)
