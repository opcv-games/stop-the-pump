class_name WeatherComponent
extends Node
## Rain cycles (art direction): some days roll a rain spell between opening and closing; rain eases
## in and out. Drives the rain particles and the wet-road look. Cosmetic for now. Refs #22

signal intensity_changed(intensity: float)

## Chance that a day gets a rain spell.
@export_range(0.0, 1.0) var rain_chance := 0.35
## Spell length, in game hours.
@export var spell_min_hours := 2.0
@export var spell_max_hours := 5.0
## Real seconds for rain to fade fully in or out.
@export var ramp_seconds := 3.0

var raining := false
var intensity := 0.0
var has_spell := false
var spell_start := 0.0
var spell_end := 0.0
var _forced := false  # dev toggle (F5) overrides the day's schedule


func _process(delta: float) -> void:
	tick(delta)


## A new day: maybe schedule a rain spell. Clears the dev override.
func begin_day() -> void:
	_forced = false
	has_spell = randf() < rain_chance
	if has_spell:
		var length := randf_range(spell_min_hours, spell_max_hours)
		spell_start = randf_range(7.0, 23.0 - length)
		spell_end = spell_start + length
	update_hour(7.0)


func update_hour(h: float) -> void:
	if _forced:
		return
	set_raining(has_spell and h >= spell_start and h < spell_end)


## Dev (F5): start or stop rain now, ignoring today's schedule.
func toggle() -> void:
	_forced = true
	set_raining(not raining)


func set_raining(on: bool) -> void:
	raining = on


## Kept separate from _process so tests control time.
func tick(delta: float) -> void:
	var target := 1.0 if raining else 0.0
	if is_equal_approx(intensity, target):
		return
	intensity = move_toward(intensity, target, delta / maxf(ramp_seconds, 0.001))
	intensity_changed.emit(intensity)
