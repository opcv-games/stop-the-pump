class_name PumpBay
extends Control
## One pump station slot: a pump, its current customer, its display and its last result.
## The station owns as many bays as it likes; scoring and combo stay at the station. Refs #4

signal pump_stopped(bay: PumpBay, final_amount: float)
signal cleaning_finished(bay: PumpBay)

const IDLE_LIGHT := Color(0.3, 0.3, 0.32)
const POUR_LIGHT := Color(0.35, 0.9, 0.45)
const CLEANING_LIGHT := Color(0.95, 0.35, 0.3)
const SIZE := Vector2(300, 470)

var index := 0
var pump: PumpComponent
var waiting := true
var result_label: Label
var target_label: Label
## Out of service while the attendant cleans an overshoot off the car (#9).
var cleaning := false

var _cleaning_left := 0.0

var _amount_label: Label
var _light: ColorRect


func setup(bay_index: int, flow_rate: float) -> void:
	index = bay_index
	size = SIZE
	pump = PumpComponent.new()
	pump.name = "PumpComponent"
	pump.flow_rate = flow_rate
	add_child(pump)
	_build()
	pump.amount_changed.connect(func(a: float) -> void: _amount_label.text = "$%.2f" % a)
	pump.stopped.connect(_on_stopped)
	show_empty()


func show_empty() -> void:
	cleaning = false
	waiting = true
	pump.reset(0.0)
	target_label.text = "PUMP %d\nno customer" % (index + 1)
	target_label.modulate = Color(1, 1, 1, 0.4)
	_light.color = IDLE_LIGHT


func new_customer(target: float) -> void:
	cleaning = false
	waiting = false
	pump.reset(target)
	target_label.text = "PUMP %d\nWANTS  $%.2f" % [index + 1, target]
	target_label.modulate = Color.WHITE
	result_label.text = ""
	_light.color = IDLE_LIGHT


func _process(delta: float) -> void:
	tick_cleaning(delta)


## The pump is out of service for `seconds`; the station brings the next customer when it's done.
func start_cleaning(seconds: float) -> void:
	cleaning = true
	waiting = true
	_cleaning_left = seconds
	_light.color = CLEANING_LIGHT
	_show_cleaning()


## Kept separate from _process so tests control time.
func tick_cleaning(delta: float) -> void:
	if not cleaning:
		return
	_cleaning_left -= delta
	if _cleaning_left <= 0.0:
		cleaning = false
		_light.color = IDLE_LIGHT
		target_label.text = "PUMP %d\nclean, next car..." % (index + 1)
		cleaning_finished.emit(self)
	else:
		_show_cleaning()


func _show_cleaning() -> void:
	target_label.text = "PUMP %d   CLEANING  %ds\n\"Hey! My paint!\"" % [index + 1, ceili(_cleaning_left)]
	target_label.modulate = Color(0.95, 0.45, 0.4)


func press() -> void:
	if waiting:
		return
	pump.start_pour()
	if pump.is_pouring:
		_light.color = POUR_LIGHT


func release() -> void:
	pump.stop_pour()


func show_result(text: String, color: Color) -> void:
	result_label.text = text
	result_label.add_theme_color_override("font_color", color)


func _on_stopped(final_amount: float) -> void:
	waiting = true
	_light.color = IDLE_LIGHT
	pump_stopped.emit(self, final_amount)


func _build() -> void:
	target_label = Greybox.label(self, "", 26, Vector2(0, 0), Vector2(SIZE.x, 70))

	var body := ColorRect.new()
	body.color = Color(0.55, 0.55, 0.58)
	body.position = Vector2(25, 80)
	body.size = Vector2(250, 280)
	add_child(body)

	var screen := ColorRect.new()
	screen.color = Color(0.08, 0.08, 0.09)
	screen.position = Vector2(15, 30)
	screen.size = Vector2(220, 100)
	body.add_child(screen)
	_amount_label = Greybox.label(screen, "$0.00", 54, Vector2.ZERO, screen.size)
	_amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_light = ColorRect.new()
	_light.position = Vector2(100, 160)
	_light.size = Vector2(50, 50)
	body.add_child(_light)

	var key := Greybox.label(body, "[ %d ]" % ((index + 1) % 10), 26, Vector2(0, 225), Vector2(250, 40))
	key.add_theme_color_override("font_color", Color(0.15, 0.15, 0.17))

	result_label = Greybox.label(self, "", 21, Vector2(-10, 368), Vector2(SIZE.x + 20, 100))
