class_name DayClock
extends Node
## The station's opening hours, squeezed into a few real minutes. Serves: Advancement (round shape). Refs #8

signal time_changed(hour: float)
signal closed

@export var open_hour := 7.0
@export var close_hour := 23.0
## How many real seconds a whole day lasts.
@export var day_seconds := 180.0

var elapsed := 0.0
var running := false


func _process(delta: float) -> void:
	tick(delta)


func start() -> void:
	elapsed = 0.0
	running = true
	time_changed.emit(hour())


func tick(delta: float) -> void:
	if not running:
		return
	elapsed = minf(elapsed + delta, day_seconds)
	time_changed.emit(hour())
	if elapsed >= day_seconds:
		running = false
		closed.emit()


func is_closed() -> bool:
	return not running and elapsed >= day_seconds


func progress() -> float:
	return elapsed / day_seconds


func hour() -> float:
	return lerpf(open_hour, close_hour, progress())


## "9:45 AM", rounded down to the quarter hour so it ticks like a station clock.
func label() -> String:
	var h := hour()
	var whole := int(h)
	var minutes := int((h - whole) * 4.0) * 15
	var suffix := "AM" if whole < 12 or whole == 24 else "PM"
	var shown := whole % 12
	if shown == 0:
		shown = 12
	return "%d:%02d %s" % [shown, minutes, suffix]
