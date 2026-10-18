extends Control
## Ugly Prototype: one pump, one customer at a time. Flat colors only.
## Hypothesis #1 (kept): a climbing number + tiered score makes a single stop feel skillful.
## Hypothesis #7: a combo multiplier gives every stop stakes; sound is toggled with M to judge it separately.

## Customer orders, in dollars. Picked at random each customer.
@export var possible_targets: Array[float] = [10.0, 15.0, 20.0, 25.0, 30.0, 40.0]
## Pause between customers so the result can be read.
@export var next_customer_delay := 1.5

const TIER_COLORS := {
	ScoreTiers.PERFECT: Color(0.35, 0.9, 0.45),
	ScoreTiers.GOOD: Color(0.6, 0.8, 1.0),
	ScoreTiers.OK: Color(0.95, 0.85, 0.4),
	ScoreTiers.MISS: Color(0.95, 0.35, 0.3),
}
const IDLE_LIGHT := Color(0.3, 0.3, 0.32)

@onready var pump: PumpComponent = $PumpComponent
@onready var combo: ComboComponent = $ComboComponent
@onready var sound: SoundFeedback = $SoundFeedback

var _counts := {ScoreTiers.PERFECT: 0, ScoreTiers.GOOD: 0, ScoreTiers.OK: 0, ScoreTiers.MISS: 0}
var _best_combo := 1
var _waiting := false

var _amount_label: Label
var _target_label: Label
var _result_label: Label
var _stats_label: Label
var _combo_label: Label
var _score_label: Label
var _hint_label: Label
var _nozzle_light: ColorRect


func _ready() -> void:
	_ensure_input_actions()
	_build_greybox()
	pump.amount_changed.connect(_on_amount_changed)
	pump.stopped.connect(_on_pump_stopped)
	combo.multiplier_changed.connect(_on_multiplier_changed)
	sound.watch_pump(pump)
	sound.watch_combo(combo)
	_next_customer()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("toggle_sound"):
		sound.enabled = not sound.enabled
		_update_hint()
		return
	if _waiting:
		return
	if event.is_action_pressed("pour_1"):
		pump.start_pour()
		_nozzle_light.color = TIER_COLORS[ScoreTiers.PERFECT]
	elif event.is_action_released("pour_1"):
		pump.stop_pour()


func _next_customer() -> void:
	_waiting = false
	pump.reset(possible_targets.pick_random())
	_target_label.text = "CUSTOMER WANTS  $%.2f" % pump.target
	_result_label.text = ""
	_nozzle_light.color = IDLE_LIGHT


func _on_amount_changed(amount: float) -> void:
	_amount_label.text = "$%.2f" % amount


func _on_pump_stopped(final_amount: float) -> void:
	_waiting = true
	_nozzle_light.color = IDLE_LIGHT
	var tier := pump_tier(final_amount)
	var lost := combo.multiplier if not combo.tiers.extends_combo(tier) and combo.multiplier > 1 else 0
	var paid_multiplier := combo.multiplier if combo.tiers.extends_combo(tier) else 1
	var points := combo.register(tier)
	sound.play_tier(tier)
	_counts[tier] += 1
	var diff := final_amount - pump.target
	var text := "%s   (%s$%.2f)   +%d" % [tier.to_upper(), "+" if diff >= 0 else "-", absf(diff), points]
	if paid_multiplier > 1:
		text += "  (x%d)" % paid_multiplier
	if lost:
		text += "\nCOMBO LOST  x%d" % lost
	_result_label.text = text
	_result_label.add_theme_color_override("font_color", TIER_COLORS[tier])
	_score_label.text = "SCORE  %d" % combo.total_score
	_stats_label.text = "Perfect %d   Good %d   OK %d   Miss %d   |   Best combo x%d" % [
		_counts[ScoreTiers.PERFECT], _counts[ScoreTiers.GOOD], _counts[ScoreTiers.OK],
		_counts[ScoreTiers.MISS], _best_combo]
	await get_tree().create_timer(next_customer_delay).timeout
	_next_customer()


func pump_tier(final_amount: float) -> String:
	return combo.tiers.evaluate(final_amount, pump.target)


func _on_multiplier_changed(multiplier: int) -> void:
	_best_combo = maxi(_best_combo, multiplier)
	_combo_label.text = "x%d\nCOMBO" % multiplier
	# Greybox "heat": the label warms from grey to orange as the chain grows.
	var heat := float(multiplier - 1) / float(combo.max_multiplier - 1)
	_combo_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.72).lerp(Color(1.0, 0.55, 0.15), heat))
	_combo_label.add_theme_font_size_override("font_size", 48 + multiplier * 8)


func _update_hint() -> void:
	_hint_label.text = "Hold SPACE (or 1) to pour.  Release to stop.     M: sound %s" % ("ON" if sound.enabled else "OFF")


## Greybox input, done in code; moves to the Input Map later.
func _ensure_input_actions() -> void:
	var bindings := {"pour_1": [KEY_SPACE, KEY_1], "toggle_sound": [KEY_M]}
	for action in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in bindings[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _build_greybox() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.18, 0.18, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var pump_body := ColorRect.new()
	pump_body.color = Color(0.55, 0.55, 0.58)
	pump_body.position = Vector2(426, 90)
	pump_body.size = Vector2(300, 380)
	add_child(pump_body)

	var screen := ColorRect.new()
	screen.color = Color(0.08, 0.08, 0.09)
	screen.position = Vector2(20, 60)
	screen.size = Vector2(260, 110)
	pump_body.add_child(screen)

	_amount_label = _label(screen, "$0.00", 64, Vector2.ZERO, screen.size)
	_amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_nozzle_light = ColorRect.new()
	_nozzle_light.position = Vector2(125, 220)
	_nozzle_light.size = Vector2(50, 50)
	pump_body.add_child(_nozzle_light)

	_combo_label = _label(self, "", 56, Vector2(760, 150), Vector2(320, 260))
	_combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_on_multiplier_changed(1)
	_score_label = _label(self, "SCORE  0", 28, Vector2(60, 250), Vector2(320, 50))

	_target_label = _label(self, "", 32, Vector2(0, 30), Vector2(1152, 50))
	_result_label = _label(self, "", 34, Vector2(0, 480), Vector2(1152, 90))
	_stats_label = _label(self, "Perfect 0   Good 0   OK 0   Miss 0   |   Best combo x1", 20, Vector2(0, 575), Vector2(1152, 30))
	_hint_label = _label(self, "", 18, Vector2(0, 608), Vector2(1152, 30))
	_hint_label.modulate = Color(1, 1, 1, 0.6)
	_update_hint()


func _label(parent: Node, text: String, size: int, pos: Vector2, box: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = box
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l
