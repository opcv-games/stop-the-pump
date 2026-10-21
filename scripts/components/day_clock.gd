class_name DayClock
extends Node
## The station's opening hours, squeezed into a few real seconds. A game hour always lasts the same
## real time, so opening longer (the HOURS branch, #35) makes the day longer. Serves: Advancement
## (round shape) and Mastery (short, dense days). Refs #8, #35

signal time_changed(hour: float)
signal closed

@export var open_hour := 7.0
## Dad only opened mornings: after 11 he went fishing (#35). HOURS upgrades push this later.
@export var close_hour := 11.0
## Real seconds per game hour: 7 to 11 AM is 15 s; 7 AM to 11 PM is 60 s.
@export var seconds_per_hour := 3.75
## How many real seconds today lasts (setting it changes the pace, not the hours).
var day_seconds: float:
	get:
		return (close_hour - open_hour) * seconds_per_hour
	set(value):
		seconds_per_hour = value / maxf(close_hour - open_hour, 0.01)

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
