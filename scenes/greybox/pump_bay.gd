class_name PumpBay
extends Control
## One pump station slot: a pump, its current customer (car + speech bubble), its display and its
## last result. The station owns as many bays as it likes; scoring and combo stay at the station. Refs #4, #5

signal pump_stopped(bay: PumpBay, final_amount: float)
signal cleaning_finished(bay: PumpBay)
## A self-service customer has paid for `amount` and left.
signal self_service_paid(bay: PumpBay, amount: float)
## The player clicked this pump's AUTO button (#20).
signal auto_toggle_requested(bay: PumpBay)
## A car pulled in (`colour` = customer type) or left this pump: the 3D world follows these (#24).
signal car_arrived(bay: PumpBay, colour: Color)
signal car_departed(bay: PumpBay)
## The customer gave up and drove off without buying (Impatient Businessman, #5).
signal customer_left(bay: PumpBay)

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
## Self-service is running right now (#17): customers serve themselves; the player's key does nothing.
## A pump that owns the upgrade (pump_level >= 1) can switch it off to be poured by hand (#20).
var self_service := false
## How far up its own upgrade tree this pump is (#18): 1 self-service, 2 faster, 3 card deal.
var pump_level := 0
var self_service_component: SelfServiceComponent
## The car at this pump and its rules (#5).
var customer: CustomerComponent
## Out of service while the attendant cleans an overshoot off the car (#9).
var cleaning := false

var _cleaning_left := 0.0

var amount_label: Label
var _light: ColorRect
var _key_label: Label
var _bubble: ColorRect
var _bubble_label: Label
var _car: Control
var _car_body: ColorRect
var _car_roof: ColorRect
var _auto_button: Button


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
	customer = CustomerComponent.new()
	customer.name = "Customer"
	add_child(customer)
	customer.attach(pump)
	customer.said.connect(say)
	customer.order_changed.connect(_on_order_changed)
	customer.drove_off.connect(_on_drove_off)
	show_empty()


func show_empty() -> void:
	cleaning = false
	waiting = true
	if self_service:
		self_service_component.phase = SelfServiceComponent.Phase.IDLE
	customer.clear()
	pump.reset(0.0)
	target_label.text = "PUMP %d\nno customer" % (index + 1)
	target_label.modulate = Color(1, 1, 1, 0.4)
	_light.color = IDLE_LIGHT
	if _car.visible:
		car_departed.emit(self)
	_car.visible = false
	_bubble.visible = false


## A car pulls in. `type` is a Customers.TYPES id; self-service pumps only get Regulars.
func new_customer(target: float, type := "regular") -> void:
	cleaning = false
	waiting = false
	pump.reset(target)
	_show_order(false)
	result_label.text = ""
	_light.color = IDLE_LIGHT
	_car_body.color = Customers.TYPES[type].car
	_car_roof.color = _car_body.color.darkened(0.25)
	_car.visible = true
	car_arrived.emit(self, _car_body.color)
	customer.begin(type)
	if self_service:
		self_service_component.begin()


func say(text: String) -> void:
	_bubble_label.text = text
	_bubble.visible = text != ""


func bubble_text() -> String:
	return _bubble_label.text if _bubble.visible else ""


func car_visible() -> bool:
	return _car.visible


## The served car pulls away after a moment (the reaction stays in the bubble a little longer).
func car_leaves(after := 1.2) -> void:
	car_departed.emit(self)  # the 3D car pulls away at once
	await get_tree().create_timer(after).timeout
	if waiting and not cleaning:
		_car.visible = false


func _show_order(changed: bool) -> void:
	var tag := "  SELF" if self_service else ""
	target_label.text = "PUMP %d%s\nWANTS  $%.2f%s" % [index + 1, tag, pump.target, "  (changed!)" if changed else ""]
	target_label.modulate = Color(1.0, 0.85, 0.4) if changed else Color.WHITE


func _on_order_changed(_new_target: float) -> void:
	_show_order(true)


func _on_drove_off() -> void:
	waiting = true
	_car.visible = false
	car_departed.emit(self)
	_light.color = IDLE_LIGHT
	customer_left.emit(self)


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
		_car.visible = false
		car_departed.emit(self)
		_bubble.visible = false
		cleaning_finished.emit(self)
	else:
		_show_cleaning()


func _show_cleaning() -> void:
	target_label.text = "PUMP %d\nCLEANING  %ds" % [index + 1, ceili(_cleaning_left)]
	target_label.modulate = Color(0.95, 0.45, 0.4)
	say("Hey! My paint!")


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


## First Self-service upgrade: give this pump its self-service component and switch it on.
func make_self_service() -> void:
	if not self_service_component:
		self_service_component = SelfServiceComponent.new()
		self_service_component.name = "SelfService"
		add_child(self_service_component)
		self_service_component.phase_changed.connect(_on_self_service_phase)
		self_service_component.paid.connect(func(amount: float) -> void: self_service_paid.emit(self, amount))
	_auto_button.visible = true
	set_auto(true)


## Auto on: customers serve themselves. Auto off: the player pours this pump by hand (#20).
func set_auto(on: bool) -> void:
	self_service = on
	if on:
		self_service_component.attach(pump)
		if not waiting and not pump.is_done and pump.amount == 0.0:
			self_service_component.begin()
	else:
		self_service_component.detach()
		_light.color = IDLE_LIGHT
	_auto_button.text = "AUTO ON" if on else "AUTO OFF"
	_auto_button.button_pressed = on
	if not waiting and not pump.is_done:
		_show_order(false)
		if not on:
			say(Customers.line(customer.type if customer.type != "" else "regular", "hello", pump.target))
	_key_label.text = "[ %d ]  SELF-SERVE" % ((index + 1) % 10) if on else "[ %d ]" % ((index + 1) % 10)


## Switches auto on/off. Refused without the upgrade, mid-pour, or while a customer pays.
func toggle_auto() -> bool:
	if pump_level < 1 or pump.is_pouring:
		return false
	if self_service and self_service_component.phase == SelfServiceComponent.Phase.PAYING:
		return false
	set_auto(not self_service)
	return true


## Back to a plain pump the player pours (new run).
func make_manual() -> void:
	pump_level = 0
	_auto_button.visible = false
	if not self_service_component:
		return
	self_service = false
	self_service_component.detach()
	self_service_component.queue_free()
	self_service_component = null
	_key_label.text = "[ %d ]" % ((index + 1) % 10)


func _on_self_service_phase(phase: SelfServiceComponent.Phase) -> void:
	match phase:
		SelfServiceComponent.Phase.CARD:
			say("*fumbles with the card*")
			_light.color = Color(0.45, 0.6, 1.0)
		SelfServiceComponent.Phase.PUMPING:
			say("*pumps their own gas*")
			_light.color = POUR_LIGHT
		SelfServiceComponent.Phase.PAYING:
			say("*taps the card... again*")
			_light.color = Color(0.45, 0.6, 1.0)
		SelfServiceComponent.Phase.IDLE:
			_light.color = IDLE_LIGHT


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
	target_label = Greybox.label(self, "", 22, Vector2(0, 0), Vector2(SIZE.x, 58))

	# Speech bubble: what the customer says (flavour; the rules live in CustomerComponent).
	_bubble = ColorRect.new()
	_bubble.color = Color(0.93, 0.91, 0.86)
	_bubble.position = Vector2(14, 62)
	_bubble.size = Vector2(272, 46)
	add_child(_bubble)
	_bubble_label = Greybox.label(_bubble, "", 15, Vector2(6, 2), Vector2(260, 42))
	_bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.12))

	var body := ColorRect.new()
	body.color = Color(0.55, 0.55, 0.58, 0.55)  # see-through: the painted world shows behind (#22)
	body.position = Vector2(25, 114)
	body.size = Vector2(250, 214)
	add_child(body)

	var screen := ColorRect.new()
	screen.color = Color(0.08, 0.08, 0.09)
	screen.position = Vector2(15, 16)
	screen.size = Vector2(220, 92)
	body.add_child(screen)
	amount_label = Greybox.label(screen, "$0.00", 50, Vector2.ZERO, screen.size)
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_light = ColorRect.new()
	_light.position = Vector2(105, 120)
	_light.size = Vector2(40, 40)
	body.add_child(_light)

	_key_label = Greybox.label(body, "[ %d ]" % ((index + 1) % 10), 24, Vector2(0, 170), Vector2(250, 36))
	_key_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.17))

	# AUTO switch (#20): only on pumps that own the Self-service upgrade. Shift + number does the same.
	_auto_button = Button.new()
	_auto_button.toggle_mode = true
	_auto_button.focus_mode = Control.FOCUS_NONE
	_auto_button.add_theme_font_size_override("font_size", 14)
	_auto_button.position = Vector2(170, 124)
	_auto_button.size = Vector2(72, 30)
	_auto_button.visible = false
	_auto_button.pressed.connect(func() -> void:
		_auto_button.button_pressed = self_service  # the station decides; show the real state
		auto_toggle_requested.emit(self))
	body.add_child(_auto_button)

	# The car parked in front of the pump: flat boxes, colour = customer type (#5).
	_car = Control.new()
	_car.position = Vector2(60, 334)
	_car.size = Vector2(180, 44)
	add_child(_car)
	_car_roof = _box(_car, Vector2(45, 0), Vector2(90, 16), Color.GRAY)
	_car_body = _box(_car, Vector2(0, 14), Vector2(180, 22), Color.GRAY)
	_box(_car, Vector2(22, 30), Vector2(28, 14), Color(0.08, 0.08, 0.09))
	_box(_car, Vector2(130, 30), Vector2(28, 14), Color(0.08, 0.08, 0.09))

	result_label = Greybox.label(self, "", 18, Vector2(-10, 384), Vector2(SIZE.x + 20, 86))


func _box(parent: Control, at: Vector2, box_size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = at
	r.size = box_size
	r.color = color
	parent.add_child(r)
	return r
