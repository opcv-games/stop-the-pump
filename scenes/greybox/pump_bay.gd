class_name PumpBay
extends Control
## One pump station slot: a pump, its current customer, its display and its last result.
## The station owns as many bays as it likes; scoring and combo stay at the station. Refs #4

signal pump_stopped(bay: PumpBay, final_amount: float)
signal cleaning_finished(bay: PumpBay)
## A self-service customer has paid for `amount` and left.
signal self_service_paid(bay: PumpBay, amount: float)

const IDLE_LIGHT := Color(0.3, 0.3, 0.32)
const POUR_LIGHT := Color(0.35, 0.9, 0.45)
const CLEANING_LIGHT := Color(0.95, 0.35, 0.3)
const SIZE := Vector2(300, 470)

var index := 0
var pump: PumpComponent
var waiting := true
var result_label: Label
var target_label: Label
## Pour speed relative to the station's (self-service pumps are slower, #17).
var flow_multiplier := 1.0
## Converted to self-service (#17): customers serve themselves; the player's key does nothing.
var self_service := false
## How far up its own upgrade tree this pump is (#18): 1 self-service, 2 faster, 3 card deal.
var pump_level := 0
var self_service_component: SelfServiceComponent
## Out of service while the attendant cleans an overshoot off the car (#9).
var cleaning := false

var _cleaning_left := 0.0

var amount_label: Label
var _light: ColorRect
var _key_label: Label


func setup(bay_index: int, flow_rate: float) -> void:
	index = bay_index
	size = SIZE
	pump = PumpComponent.new()
	pump.name = "PumpComponent"
	pump.flow_rate = flow_rate
	add_child(pump)
	_build()
	pump.amount_changed.connect(func(a: float) -> void: amount_label.text = "$%.2f" % a)
	pump.stopped.connect(_on_stopped)
	show_empty()


func show_empty() -> void:
	cleaning = false
	waiting = true
	if self_service:
		self_service_component.phase = SelfServiceComponent.Phase.IDLE
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
	if self_service:
		self_service_component.begin()


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
	if waiting or self_service:
		return
	pump.start_pour()
	if pump.is_pouring:
		_light.color = POUR_LIGHT


func release() -> void:
	if self_service:
		return  # the customer is pumping, not the player (playtest 13: releasing froze them)
	pump.stop_pour()


func make_self_service() -> void:
	if self_service:
		return
	self_service = true
	self_service_component = SelfServiceComponent.new()
	self_service_component.name = "SelfService"
	add_child(self_service_component)
	self_service_component.attach(pump)
	self_service_component.phase_changed.connect(_on_self_service_phase)
	self_service_component.paid.connect(func(amount: float) -> void: self_service_paid.emit(self, amount))
	_key_label.text = "[ %d ]  SELF-SERVE" % ((index + 1) % 10)
	if not waiting and not pump.is_done:
		self_service_component.begin()


## Back to a pump the player pours (new run).
func make_manual() -> void:
	pump_level = 0
	if not self_service:
		return
	self_service = false
	self_service_component.detach()
	self_service_component.queue_free()
	self_service_component = null
	_key_label.text = "[ %d ]" % ((index + 1) % 10)


func _on_self_service_phase(phase: SelfServiceComponent.Phase) -> void:
	var line := ""
	match phase:
		SelfServiceComponent.Phase.CARD:
			line = "fumbling with the card..."
			_light.color = Color(0.45, 0.6, 1.0)
		SelfServiceComponent.Phase.PUMPING:
			line = "pumping (self-serve)"
			_light.color = POUR_LIGHT
		SelfServiceComponent.Phase.PAYING:
			line = "paying..."
			_light.color = Color(0.45, 0.6, 1.0)
		SelfServiceComponent.Phase.IDLE:
			_light.color = IDLE_LIGHT
			return
	target_label.text = "PUMP %d  WANTS $%.2f\n%s" % [index + 1, pump.target, line]


## Super Perfect: the display shows the exact target ("on the dot").
func show_amount(amount: float) -> void:
	amount_label.text = "$%.2f" % amount


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
	amount_label = Greybox.label(screen, "$0.00", 54, Vector2.ZERO, screen.size)
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_light = ColorRect.new()
	_light.position = Vector2(100, 160)
	_light.size = Vector2(50, 50)
	body.add_child(_light)

	_key_label = Greybox.label(body, "[ %d ]" % ((index + 1) % 10), 26, Vector2(0, 225), Vector2(250, 40))
	_key_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.17))

	result_label = Greybox.label(self, "", 21, Vector2(-10, 368), Vector2(SIZE.x + 20, 100))
