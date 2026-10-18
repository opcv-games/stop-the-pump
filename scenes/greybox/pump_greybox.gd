extends Control
## Ugly Prototype: one pump, one customer at a time. Flat colors only.
## Hypothesis (#1): a climbing number + tiered score makes a single stop feel skillful (Mastery).

## Customer orders, in dollars. Picked at random each customer.
@export var possible_targets: Array[float] = [10.0, 15.0, 20.0, 25.0, 30.0, 40.0]
## Pause between customers so the result can be read.
@export var next_customer_delay := 1.5
@export var tiers: ScoreTiers = ScoreTiers.new()

const TIER_COLORS := {
	ScoreTiers.PERFECT: Color(0.35, 0.9, 0.45),
	ScoreTiers.GOOD: Color(0.6, 0.8, 1.0),
	ScoreTiers.OK: Color(0.95, 0.85, 0.4),
	ScoreTiers.MISS: Color(0.95, 0.35, 0.3),
}

@onready var pump: PumpComponent = $PumpComponent

var _counts := {ScoreTiers.PERFECT: 0, ScoreTiers.GOOD: 0, ScoreTiers.OK: 0, ScoreTiers.MISS: 0}
var _streak := 0
var _waiting := false

var _amount_label: Label
var _target_label: Label
var _result_label: Label
var _stats_label: Label
var _nozzle_light: ColorRect


func _ready() -> void:
	_ensure_input_action()
	_build_greybox()
	pump.amount_changed.connect(_on_amount_changed)
	pump.stopped.connect(_on_pump_stopped)
	_next_customer()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or _waiting:
		return
	if event.is_action_pressed("pour_1"):
		pump.start_pour()
		_nozzle_light.color = Color(0.35, 0.9, 0.45)
	elif event.is_action_released("pour_1"):
		pump.stop_pour()


func _next_customer() -> void:
	_waiting = false
	pump.reset(possible_targets.pick_random())
	_target_label.text = "CUSTOMER WANTS  $%.2f" % pump.target
	_result_label.text = ""
	_nozzle_light.color = Color(0.3, 0.3, 0.32)


func _on_amount_changed(amount: float) -> void:
	_amount_label.text = "$%.2f" % amount


func _on_pump_stopped(final_amount: float) -> void:
	_waiting = true
	_nozzle_light.color = Color(0.3, 0.3, 0.32)
	var tier := tiers.evaluate(final_amount, pump.target)
	_counts[tier] += 1
	_streak = _streak + 1 if tier == ScoreTiers.PERFECT else 0
	var diff := final_amount - pump.target
	_result_label.text = "%s   (%s$%.2f)" % [tier.to_upper(), "+" if diff >= 0 else "-", absf(diff)]
	_result_label.add_theme_color_override("font_color", TIER_COLORS[tier])
	_stats_label.text = "Perfect %d   Good %d   OK %d   Miss %d   |   Perfect streak %d" % [
		_counts[ScoreTiers.PERFECT], _counts[ScoreTiers.GOOD], _counts[ScoreTiers.OK],
		_counts[ScoreTiers.MISS], _streak]
	await get_tree().create_timer(next_customer_delay).timeout
	_next_customer()


## Space or 1 pours pump 1. Done in code for the greybox; moves to the Input Map later.
func _ensure_input_action() -> void:
	if InputMap.has_action("pour_1"):
		return
	InputMap.add_action("pour_1")
	for key in [KEY_SPACE, KEY_1]:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event("pour_1", ev)


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
	_amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_nozzle_light = ColorRect.new()
	_nozzle_light.position = Vector2(125, 220)
	_nozzle_light.size = Vector2(50, 50)
	pump_body.add_child(_nozzle_light)

	_target_label = _label(self, "", 32, Vector2(0, 30), Vector2(1152, 50))
	_result_label = _label(self, "", 48, Vector2(0, 490), Vector2(1152, 60))
	_stats_label = _label(self, "Perfect 0   Good 0   OK 0   Miss 0   |   Perfect streak 0", 20, Vector2(0, 560), Vector2(1152, 30))
	_label(self, "Hold SPACE (or 1) to pour.  Release to stop.", 18, Vector2(0, 600), Vector2(1152, 30)).modulate = Color(1, 1, 1, 0.6)
	for l in [_target_label, _result_label, _stats_label]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _label(parent: Node, text: String, size: int, pos: Vector2, box: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = box
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l
