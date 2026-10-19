class_name SoundFeedback
extends Node
## Listens to game signals and plays placeholder sounds. Gameplay never calls audio directly,
## so sound can be muted or swapped in Phase 4 without touching rules. Serves: Mastery (feel).
## A backing band loops a 12-bar blues; each stop adds melody notes that fit the current bar,
## so the song never stops and the player's notes are always in key. Refs #7, #12

const DIR := "res://assets/audio/placeholder/"
const BPM := 90.0
const TWELVE_BAR := ["A7", "A7", "A7", "A7", "D7", "D7", "A7", "A7", "E7", "D7", "A7", "E7"]
const CHORDS := ["A7", "D7", "E7"]
## Melody file suffix for each tier that plays notes (OK plays nothing).
const TIER_NOTES := {
	ScoreTiers.SUPER_PERFECT: "super",
	ScoreTiers.PERFECT: "perfect",
	ScoreTiers.GOOD: "good",
	ScoreTiers.MISS: "bad",
}

## Toggled with M during playtests so sound can be judged on its own.
@export var enabled := true:
	set(value):
		enabled = value
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not value)
## Play a click every time the meter passes a whole dollar.
@export var tick_every_dollar := true
## Each extra pump hums and clicks a little higher so pumps can be told apart by ear.
@export var pitch_step_per_pump := 0.12
@export var backing_volume_db := -9.0
## Click mode: false = a click per dollar poured; true = a shaker on the band's swung eighths while pouring (#13).
@export var tick_on_beat := false

var _players := {}
var _loop: AudioStreamWAV
var _tick: AudioStream
var _backing: AudioStreamPlayer
var _pumps: Array[PumpComponent] = []
var _shaker: AudioStreamPlayer
var _last_eighth := -1


func _ready() -> void:
	for chord in CHORDS:
		for suffix in TIER_NOTES.values():
			var p := AudioStreamPlayer.new()
			p.stream = load(DIR + "note_%s_%s.wav" % [chord, suffix])
			add_child(p)
			_players["%s_%s" % [chord, suffix]] = p
	_tick = load(DIR + "tick.wav")
	_loop = load(DIR + "pour_loop.wav")
	_loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_loop.loop_end = 44100
	var band: AudioStreamWAV = load(DIR + "backing_12bar.wav")
	band.loop_mode = AudioStreamWAV.LOOP_FORWARD
	band.loop_end = band.data.size() / 2  # 16-bit mono: 2 bytes per sample
	_backing = AudioStreamPlayer.new()
	_backing.stream = band
	_backing.volume_db = backing_volume_db
	add_child(_backing)
	_backing.play()
	_shaker = AudioStreamPlayer.new()
	_shaker.stream = _tick
	_shaker.volume_db = -4.0
	add_child(_shaker)


func _process(_delta: float) -> void:
	if not tick_on_beat or not _backing.playing:
		return
	var eighth := eighth_index(_backing.get_playback_position())
	if eighth == _last_eighth:
		return
	_last_eighth = eighth
	for pump in _pumps:
		if pump.is_pouring:
			_shaker.play()
			return


## Re-applies tuned values that live on child players.
func apply_tuning() -> void:
	if _backing:
		_backing.volume_db = backing_volume_db


## Gives a pump its own hum and click players. index sets its pitch.
func watch_pump(pump: PumpComponent, index := 0) -> void:
	var pitch := 1.0 + pitch_step_per_pump * index
	var hum := AudioStreamPlayer.new()
	hum.stream = _loop
	hum.volume_db = -10.0
	hum.pitch_scale = pitch
	add_child(hum)
	var tick := AudioStreamPlayer.new()
	tick.stream = _tick
	tick.pitch_scale = pitch
	add_child(tick)
	_pumps.append(pump)
	var state := {"last_dollar": 0}
	pump.amount_changed.connect(func(amount: float) -> void:
		if pump.is_pouring and not hum.playing:
			hum.play()
		var dollar := int(amount)
		if tick_every_dollar and not tick_on_beat and dollar > state.last_dollar:
			tick.play()
		state.last_dollar = dollar)
	pump.stopped.connect(func(_final: float) -> void: hum.stop())


## Plays this stop's melody notes in the chord the band is on right now.
func play_tier(tier: String) -> void:
	if not TIER_NOTES.has(tier):
		return
	var position := _backing.get_playback_position() if _backing and _backing.playing else 0.0
	var key := "%s_%s" % [chord_at(position), TIER_NOTES[tier]]
	if _players.has(key):
		_players[key].play()


static func bar_seconds() -> float:
	return 4.0 * 60.0 / BPM


## The chord the band is playing `seconds` into the loop.
static func chord_at(seconds: float) -> String:
	var bar := int(floor(seconds / bar_seconds())) % TWELVE_BAR.size()
	return TWELVE_BAR[bar]


## Super Perfect 3, Perfect 2, Good 1, OK and Miss 0 (a Miss plays a sour note instead).
static func note_count(tier: String) -> int:
	match tier:
		ScoreTiers.SUPER_PERFECT:
			return 3
		ScoreTiers.PERFECT:
			return 2
		ScoreTiers.GOOD:
			return 1
	return 0


## Which swung eighth note of the band `seconds` falls in: the beat, then two-thirds through it.
static func eighth_index(seconds: float) -> int:
	var beat := 60.0 / BPM
	var beats := floori(seconds / beat)
	var frac := seconds / beat - beats
	return beats * 2 + (1 if frac >= 2.0 / 3.0 else 0)
