class_name SoundFeedback
extends Node
## Listens to game signals and plays sound effects over a looping background track.
## Gameplay never calls audio directly, so sounds can be swapped in Phase 4 without touching rules.
## Plain SFX + background music only (playtest 12). Serves: Mastery (feel). Refs #7, #16

const DIR := "res://assets/audio/placeholder/"
const MUSIC := "res://assets/audio/music/roadside_at_two.wav"
const TIER_SFX := {
	ScoreTiers.SUPER_PERFECT: "sfx_super_perfect",
	ScoreTiers.PERFECT: "sfx_perfect",
	ScoreTiers.GOOD: "sfx_good",
	ScoreTiers.OK: "sfx_ok",
	ScoreTiers.MISS: "sfx_miss",
}

## Toggled with M during playtests so sound can be judged on its own.
@export var enabled := true:
	set(value):
		enabled = value
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), not value)
## Play a counter knock (crick, crack or crock) every time the meter passes a whole dollar.
@export var tick_every_dollar := true
## Each extra pump hums and clicks a little higher so pumps can be told apart by ear.
@export var pitch_step_per_pump := 0.12
@export var music_volume_db := -9.0

var _players := {}
var _loop: AudioStreamWAV
var _counters: Array[AudioStream] = []
var _music: AudioStreamPlayer
var _pumps: Array[PumpComponent] = []


func _ready() -> void:
	for sfx in TIER_SFX.values() + ["sfx_combo_break", "pop"]:
		var p := AudioStreamPlayer.new()
		p.stream = load(DIR + sfx + ".wav")
		add_child(p)
		_players[sfx] = p
	for k in 3:
		_counters.append(load(DIR + "counter_%d.wav" % (k + 1)))
	_loop = load(DIR + "glug_loop.wav")  # glug-glug while fuel flows (#27)
	_loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	_loop.loop_end = 44100
	var music: AudioStreamWAV = load(MUSIC)
	music.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.loop_begin = 0
	music.loop_end = music.data.size() / (4 if music.stereo else 2)  # 16-bit: 2 bytes per sample per channel
	_music = AudioStreamPlayer.new()
	_music.stream = music
	_music.volume_db = music_volume_db
	add_child(_music)
	_music.play()


## Re-applies tuned values that live on child players.
func apply_tuning() -> void:
	if _music:
		_music.volume_db = music_volume_db


## Gives a pump its own hum and click players. index sets its pitch.
func watch_pump(pump: PumpComponent, index := 0) -> void:
	var pitch := 1.0 + pitch_step_per_pump * index
	var hum := AudioStreamPlayer.new()
	hum.stream = _loop
	hum.volume_db = -6.0
	hum.pitch_scale = pitch
	add_child(hum)
	var tick := AudioStreamPlayer.new()
	tick.volume_db = -8.0
	tick.pitch_scale = pitch
	add_child(tick)
	_pumps.append(pump)
	var state := {"last_dollar": 0}
	pump.amount_changed.connect(func(amount: float) -> void:
		if pump.is_pouring and not hum.playing:
			hum.play()
		var dollar := int(amount)
		if tick_every_dollar and dollar > state.last_dollar:
			tick.stream = _counters.pick_random()
			tick.pitch_scale = pitch * randf_range(0.95, 1.05)
			tick.play()
		state.last_dollar = dollar)
	pump.stopped.connect(func(_final: float) -> void: hum.stop())


## A pump was removed (new run after eviction): stop following it.
func unwatch_pump(pump: PumpComponent) -> void:
	_pumps.erase(pump)


func watch_combo(combo: ComboComponent) -> void:
	combo.combo_broken.connect(func(_lost: int) -> void: _play("sfx_combo_break"))


## A new pump popped out of the ground (#27).
func play_pop() -> void:
	_play("pop")


func play_tier(tier: String) -> void:
	if TIER_SFX.has(tier):
		_play(TIER_SFX[tier])


func _play(sfx: String) -> void:
	if _players.has(sfx):
		_players[sfx].play()
