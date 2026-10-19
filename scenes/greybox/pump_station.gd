extends Control
## Ugly Prototype: a station of pumps, keys 1..N, one shared combo. Flat colors only.
## Kept: #1 tiered stop, #7 combo + sound (M toggles). Testing: #4 two pumps at once.

## How many pumps the station runs. The difficulty ladder (1 to 10) is this one number.
@export_range(1, 10) var pump_count := 2
## Customer orders, in dollars. Picked at random each customer.
@export var possible_targets: Array[float] = [10.0, 15.0, 20.0, 25.0, 30.0, 40.0]
## Pause before the next customer pulls in, so the result can be read.
@export var next_customer_delay := 1.5
## Later pumps get their first customer this many seconds after the previous one,
## so pumps fall out of sync instead of all starting together.
@export var second_customer_offset := 2.0
@export var flow_rate := 4.0

const TIER_COLORS := {
	ScoreTiers.PERFECT: Color(0.35, 0.9, 0.45),
	ScoreTiers.GOOD: Color(0.6, 0.8, 1.0),
	ScoreTiers.OK: Color(0.95, 0.85, 0.4),
	ScoreTiers.MISS: Color(0.95, 0.35, 0.3),
}

@onready var combo: ComboComponent = $ComboComponent
@onready var sound: SoundFeedback = $SoundFeedback

var bays: Array[PumpBay] = []

var _counts := {ScoreTiers.PERFECT: 0, ScoreTiers.GOOD: 0, ScoreTiers.OK: 0, ScoreTiers.MISS: 0}
var _best_combo := 1
var _combo_label: Label
var _score_label: Label
var _stats_label: Label
var _hint_label: Label


func _ready() -> void:
	_ensure_input_actions()
	_build_station()
	combo.multiplier_changed.connect(_on_multiplier_changed)
	sound.watch_combo(combo)
	_on_multiplier_changed(1)
	for bay in bays:
		var delay := second_customer_offset * bay.index
		if delay <= 0.0:
			bay.new_customer(possible_targets.pick_random())
		else:
			_customer_after(bay, delay)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("toggle_sound"):
		sound.enabled = not sound.enabled
		_update_hint()
		return
	for i in bays.size():
		var action := "pour_%d" % (i + 1)
		if event.is_action_pressed(action):
			press(i)
		elif event.is_action_released(action):
			release(i)


func press(i: int) -> void:
	bays[i].press()


func release(i: int) -> void:
	bays[i].release()


func _on_bay_stopped(bay: PumpBay, final_amount: float) -> void:
	var target := bay.pump.target
	var tier := combo.tiers.evaluate(final_amount, target)
	var keeps := combo.tiers.extends_combo(tier)
	var lost := combo.multiplier if not keeps and combo.multiplier > 1 else 0
	var paid_multiplier := combo.multiplier if keeps else 1
	var points := combo.register(tier)
	sound.play_tier(tier)
	_counts[tier] += 1

	var diff := final_amount - target
	var text := "%s  %s$%.2f\n+%d" % [tier.to_upper(), "+" if diff >= 0 else "-", absf(diff), points]
	if paid_multiplier > 1:
		text += "  (x%d)" % paid_multiplier
	if lost:
		text += "\nCOMBO LOST  x%d" % lost
	bay.show_result(text, TIER_COLORS[tier])

	_score_label.text = "SCORE\n%d" % combo.total_score
	_stats_label.text = "Perfect %d   Good %d   OK %d   Miss %d   |   Best combo x%d" % [
		_counts[ScoreTiers.PERFECT], _counts[ScoreTiers.GOOD], _counts[ScoreTiers.OK],
		_counts[ScoreTiers.MISS], _best_combo]
	_customer_after(bay, next_customer_delay)


func _customer_after(bay: PumpBay, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if is_instance_valid(bay):
		bay.new_customer(possible_targets.pick_random())


func _on_multiplier_changed(multiplier: int) -> void:
	_best_combo = maxi(_best_combo, multiplier)
	_combo_label.text = "x%d" % multiplier
	# Greybox "heat": the label warms from grey to orange as the chain grows.
	var heat := float(multiplier - 1) / float(combo.max_multiplier - 1)
	_combo_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.72).lerp(Color(1.0, 0.55, 0.15), heat))
	_combo_label.add_theme_font_size_override("font_size", 48 + multiplier * 10)


func _update_hint() -> void:
	var keys := "1" if bays.size() == 1 else "1–%d" % mini(bays.size(), 9)
	_hint_label.text = "Hold keys %s to pour each pump.  Release to stop.     M: sound %s" % [keys, "ON" if sound.enabled else "OFF"]


## Greybox input, done in code; moves to the Input Map later. Keys 1..9 then 0 for pump 10.
func _ensure_input_actions() -> void:
	var bindings := {"toggle_sound": [KEY_M]}
	for i in 10:
		bindings["pour_%d" % (i + 1)] = [KEY_1 + i if i < 9 else KEY_0]
	bindings["pour_1"].append(KEY_SPACE)
	for action in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key in bindings[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


func _build_station() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.18, 0.18, 0.2)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Bays sit side by side in the space between the score (left) and combo (right) columns.
	var area_left := 200.0
	var area_width := 1152.0 - 400.0
	var gap := 20.0
	var scale_factor := minf(1.0, (area_width - gap * (pump_count - 1)) / (PumpBay.SIZE.x * pump_count))
	var row_width := (PumpBay.SIZE.x * scale_factor + gap) * pump_count - gap
	for i in pump_count:
		var bay := PumpBay.new()
		bay.name = "Bay%d" % (i + 1)
		add_child(bay)
		bay.setup(i, flow_rate)
		bay.scale = Vector2.ONE * scale_factor
		bay.position = Vector2(area_left + (area_width - row_width) / 2.0 + i * (PumpBay.SIZE.x * scale_factor + gap), 40)
		bay.pump_stopped.connect(_on_bay_stopped)
		sound.watch_pump(bay.pump, i)
		bays.append(bay)

	_score_label = Greybox.label(self, "SCORE\n0", 28, Vector2(10, 200), Vector2(180, 100))
	_combo_label = Greybox.label(self, "", 48, Vector2(952, 130), Vector2(200, 160))
	_combo_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	Greybox.label(self, "COMBO", 26, Vector2(952, 290), Vector2(200, 40)).modulate = Color(1, 1, 1, 0.6)
	_stats_label = Greybox.label(self, "Perfect 0   Good 0   OK 0   Miss 0   |   Best combo x1", 20, Vector2(0, 572), Vector2(1152, 30))
	_hint_label = Greybox.label(self, "", 18, Vector2(0, 606), Vector2(1152, 30))
	_hint_label.modulate = Color(1, 1, 1, 0.6)
	_update_hint()
