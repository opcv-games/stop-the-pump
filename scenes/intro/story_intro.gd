class_name StoryIntro
extends Control
## The story before day 1 (#29): your late father left you a run-down gas station in the middle of
## nowhere, Québec. Captions over the real station at sunrise: black cards first, then the station is
## revealed while the camera slowly pushes in and the sun comes up. In-engine rather than a video, so
## the player's first look is at the place they will rebuild. Serves: Comedy, Advancement.
##
## Any key or click moves on (clicks arrive through _gui_input), Esc jumps to the last card, Enter on the last card accepts.

signal accepted

const CARDS := [
	"Your father passed away last spring.",
	"At the reading of the will, the notary cleared his throat.",
	"\"...and to my only child, I leave my gas station.\"",
	"What gas station?",
	"Saint-Clin-Clin-des-Meuh-Meuh, Québec.\nPopulation: 212. Moose: more.",
	"One pump. A boarded window.\nA car that hasn't moved since 1987.",
	"You could sell it.\nNobody would buy it.",
	"So you'll rebuild it, one tank at a time.",
	"Are you up to the challenge?",
]
## The first card that shows the station; the cards before it are on black.
const REVEAL_CARD := 4
const CARD_SECONDS := 4.0
const FADE_SECONDS := 0.7
const START_HOUR := 7.0  # first light
const END_HOUR := 8.6
const START_ZOOM := 1.35  # camera size multiplier at the reveal, eased back to 1

var index := 0
var world: StationWorld
var _t := 0.0
var _total_t := 0.0
var _base_camera_size := 0.0
var _black: ColorRect
var _text: Label
var _prompt: Label


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_black = ColorRect.new()
	_black.color = Color(0.03, 0.03, 0.04)
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)
	# Letterbox bars: reads as a film, and hides the empty top and bottom of the frame.
	for top in [true, false]:
		var bar := ColorRect.new()
		bar.color = Color(0.03, 0.03, 0.04)
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE if top else Control.PRESET_BOTTOM_WIDE)
		bar.custom_minimum_size = Vector2(0, 70)
		bar.offset_top = 0 if top else -70
		bar.offset_bottom = 70 if top else 0
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bar)
	_text = Greybox.label(self, "", 34, Vector2(0, 250), Vector2(1152, 150))
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	_text.add_theme_constant_override("shadow_offset_x", 2)
	_text.add_theme_constant_override("shadow_offset_y", 2)
	_prompt = Greybox.label(self, "", 18, Vector2(0, 596), Vector2(1152, 30))
	_prompt.modulate = Color(1, 1, 1, 0.6)


## Starts from the first card. `station_world` gets the sunrise and the camera push-in.
func start(station_world: StationWorld) -> void:
	world = station_world
	if world and world.camera:
		_base_camera_size = world.camera.size
	index = 0
	_total_t = 0.0
	visible = true
	_show_card()


func card_text() -> String:
	return CARDS[index]


func on_last_card() -> bool:
	return index == CARDS.size() - 1


## Next card; on the last card, accepting the challenge.
func advance() -> void:
	if on_last_card():
		_finish()
		return
	index += 1
	_show_card()


## Esc: straight to the challenge.
func skip() -> void:
	index = CARDS.size() - 1
	_total_t = maxf(_total_t, (CARDS.size() - REVEAL_CARD) * CARD_SECONDS)
	_show_card()


func handle_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE and not on_last_card():
			skip()
		elif not on_last_card() or event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			advance()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		advance()
		accept_event()


func _show_card() -> void:
	_t = 0.0
	_text.text = CARDS[index]
	_prompt.text = "ENTER  I'm up to it" if on_last_card() else "any key to continue     ESC skip"
	_apply(0.0)


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if index >= REVEAL_CARD:
		_total_t += delta
	if not on_last_card() and _t >= CARD_SECONDS:
		advance()
		return
	_apply(delta)


## Text fades in; the black lifts at the reveal; the sun climbs and the camera eases in.
func _apply(_delta: float) -> void:
	_text.modulate.a = clampf(_t / FADE_SECONDS, 0.0, 1.0)
	var revealed := index >= REVEAL_CARD
	var target_black := 0.18 if revealed else 1.0
	_black.color.a = target_black if not revealed or index > REVEAL_CARD else lerpf(1.0, target_black, clampf(_t / 2.0, 0.0, 1.0))
	if world and world.camera and _base_camera_size > 0.0:
		var span := (CARDS.size() - REVEAL_CARD) * CARD_SECONDS
		var k := clampf(_total_t / span, 0.0, 1.0)
		var ease_k := 1.0 - pow(1.0 - k, 2.0)
		world.camera.size = _base_camera_size * lerpf(START_ZOOM, 1.0, ease_k)
		world.set_hour(lerpf(START_HOUR, END_HOUR, ease_k))


func _finish() -> void:
	visible = false
	if world and world.camera and _base_camera_size > 0.0:
		world.camera.size = _base_camera_size
	accepted.emit()
