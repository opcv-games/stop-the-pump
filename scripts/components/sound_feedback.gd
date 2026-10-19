class_name SoundFeedback
extends Node
## Listens to game signals and plays placeholder sounds. Gameplay never calls audio directly,
## so sound can be muted or swapped in Phase 4 without touching rules. Serves: Mastery (feel). Refs #7

const DIR := "res://assets/audio/placeholder/"

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
	for sfx in ["perfect", "good", "ok", "miss", "combo_up", "combo_break"]:
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
	combo.multiplier_changed.connect(_on_multiplier_changed)
	combo.combo_broken.connect(func(_lost: int) -> void: _play("combo_break"))


func play_tier(tier: String) -> void:
	_play(tier.to_lower())


func _on_multiplier_changed(multiplier: int) -> void:
	if multiplier <= 1:
		return
	_players["combo_up"].pitch_scale = combo_pitch(multiplier)
	_play("combo_up")


## One octave up per combo step: x2 plays the base note, x3 an octave higher, and so on.
static func combo_pitch(multiplier: int) -> float:
	return pow(2.0, multiplier - 2)


func _play(sfx: String) -> void:
	if _players.has(sfx):
		_players[sfx].play()
