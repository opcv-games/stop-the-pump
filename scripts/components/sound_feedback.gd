class_name SoundFeedback
extends Node
## Listens to game signals and plays placeholder sounds. Gameplay never calls audio directly,
## so sound can be muted or swapped in Phase 4 without touching rules. Serves: Mastery (feel). Refs #7

const DIR := "res://assets/audio/placeholder/"
## Good stops walk a 12-bar blues in A; a broken chain starts it again from bar 1 (#10, #11).
const CHORDS := ["A7", "D7", "E7"]
const TWELVE_BAR := ["A7", "A7", "A7", "A7", "D7", "D7", "A7", "A7", "E7", "D7", "A7", "E7"]

## Toggled with M during playtests so sound can be judged on its own.
@export var enabled := true:
	set(value):
		enabled = value
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not value)
## Play a click every time the meter passes a whole dollar.
@export var tick_every_dollar := true

## Each extra pump hums and clicks a little higher so pumps can be told apart by ear.
@export var pitch_step_per_pump := 0.12

var _players := {}
var _loop: AudioStreamWAV
var _tick: AudioStream


func _ready() -> void:
	var names := ["ok", "miss", "chord_break"]
	for chord in CHORDS:
		names.append("chord_" + chord)
		names.append("chord_" + chord + "_perfect")
	for sfx in names:
		var p := AudioStreamPlayer.new()
		p.stream = load(DIR + sfx + ".wav")
		add_child(p)
		_players[sfx] = p
	_tick = load(DIR + "tick.wav")
	_loop = load(DIR + "pour_loop.wav")
	_loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_loop.loop_end = 44100


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
	var state := {"last_dollar": 0}
	pump.amount_changed.connect(func(amount: float) -> void:
		if pump.is_pouring and not hum.playing:
			hum.play()
		var dollar := int(amount)
		if tick_every_dollar and dollar > state.last_dollar:
			tick.play()
		state.last_dollar = dollar)
	pump.stopped.connect(func(_final: float) -> void: hum.stop())


func watch_combo(combo: ComboComponent) -> void:
	combo.chained.connect(_on_chained)
	combo.combo_broken.connect(func(_lost: int) -> void: _play("chord_break"))


## Only OK and Miss have their own sound; good stops play the next chord instead.
func play_tier(tier: String) -> void:
	if tier == ScoreTiers.OK or tier == ScoreTiers.MISS:
		_play(tier.to_lower())


func _on_chained(length: int, tier: String) -> void:
	_play("chord_%s%s" % [chord_for(length), "_perfect" if tier == ScoreTiers.PERFECT else ""])


## The Nth good stop in a row plays bar N of the 12-bar blues, then the chorus repeats.
static func chord_for(chain_length: int) -> String:
	return TWELVE_BAR[(chain_length - 1) % TWELVE_BAR.size()]


func _play(sfx: String) -> void:
	if _players.has(sfx):
		_players[sfx].play()
