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

var _players := {}
var _pour: AudioStreamPlayer
var _last_dollar := 0


func _ready() -> void:
	for sfx in ["tick", "perfect", "good", "ok", "miss", "combo_up", "combo_break"]:
		var p := AudioStreamPlayer.new()
		p.stream = load(DIR + sfx + ".wav")
		add_child(p)
		_players[sfx] = p
	var loop: AudioStreamWAV = load(DIR + "pour_loop.wav")
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_end = 44100
	_pour = AudioStreamPlayer.new()
	_pour.stream = loop
	_pour.volume_db = -8.0
	add_child(_pour)


func watch_pump(pump: PumpComponent) -> void:
	pump.amount_changed.connect(_on_amount_changed.bind(pump))
	pump.stopped.connect(func(_final: float) -> void: _pour.stop())


func watch_combo(combo: ComboComponent) -> void:
	combo.multiplier_changed.connect(_on_multiplier_changed)
	combo.combo_broken.connect(func(_lost: int) -> void: _play("combo_break"))


func play_tier(tier: String) -> void:
	_play(tier.to_lower())


func _on_amount_changed(amount: float, pump: PumpComponent) -> void:
	if pump.is_pouring and not _pour.playing:
		_pour.play()
	var dollar := int(amount)
	if tick_every_dollar and dollar > _last_dollar:
		_play("tick")
	_last_dollar = dollar


func _on_multiplier_changed(multiplier: int) -> void:
	if multiplier <= 1:
		return
	# Each step up the chain plays a little higher.
	_players["combo_up"].pitch_scale = 1.0 + 0.15 * (multiplier - 2)
	_play("combo_up")


func _play(sfx: String) -> void:
	if _players.has(sfx):
		_players[sfx].play()
