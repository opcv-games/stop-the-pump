class_name PumpBay
extends Control
## One pump station slot: a pump, its current customer, and its HUD card. The card is small and the
## station places it on this pump's lane in the 3D view (#25): key, meter, order and the customer's
## line, with a result popup beside it that fades. The 3D car stands in for the customer (#24).
## Scoring and combo stay at the station. Refs #4, #5, #25

signal pump_stopped(bay: PumpBay, final_amount: float)
signal cleaning_finished(bay: PumpBay)
## A self-service customer has paid for `amount` and left.
signal self_service_paid(bay: PumpBay, amount: float)
## The player clicked this pump's AUTO button (#20).
signal auto_toggle_requested(bay: PumpBay)
## A car pulled in (`colour` = customer type) or left this pump: the 3D world follows these (#24).
signal car_arrived(bay: PumpBay, colour: Color)
signal car_departed(bay: PumpBay)
## A self-service customer started or stopped pumping (drives the pour stream, #26).
signal self_pouring(bay: PumpBay, on: bool)
## The customer gave up and drove off without buying (Impatient Businessman, #5).
signal customer_left(bay: PumpBay)

const IDLE_LIGHT := Color(0.3, 0.3, 0.32)
const POUR_LIGHT := Color(0.35, 0.9, 0.45)
const CLEANING_LIGHT := Color(0.95, 0.35, 0.3)
## The card itself, and the card plus its result popup (used to keep neighbouring lanes apart).
const SIZE := Vector2(236, 50)
const POPUP_W := 176.0
const FOOTPRINT := Vector2(SIZE.x + 6.0 + POPUP_W, SIZE.y)
## Seconds a result stays fully visible, then fades out over POPUP_FADE.
const POPUP_HOLD := 2.5
const POPUP_FADE := 1.0
const SELF_LIGHT := Color(0.45, 0.6, 1.0)

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
var _popup: ColorRect
var _popup_left := 0.0
var _car_present := false  # a customer's car is at this pump (the 3D world draws it)
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
	clear_result()
	pump.reset(0.0)
	target_label.text = "no car"
	target_label.modulate = Color(1, 1, 1, 0.45)
	_light.color = IDLE_LIGHT
	if _car_present:
		car_departed.emit(self)
	_car_present = false
	_bubble.visible = false


## A car pulls in. `type` is a Customers.TYPES id; self-service pumps only get Regulars.
func new_customer(target: float, type := "regular") -> void:
	cleaning = false
	waiting = false
	pump.reset(target)
	_show_order(false)
	result_label.text = ""
	_set_popup(0.0)
	_light.color = IDLE_LIGHT
	_car_present = true
	car_arrived.emit(self, Customers.TYPES[type].car)
	customer.begin(type)
	if self_service:
		self_service_component.begin()


func say(text: String) -> void:
	_bubble_label.text = text
	_bubble.visible = text != ""


func bubble_text() -> String:
	return _bubble_label.text if _bubble.visible else ""


func car_visible() -> bool:
	return _car_present


## The served car pulls away after a moment (the reaction stays in the bubble a little longer).
func car_leaves(after := 1.2) -> void:
	car_departed.emit(self)  # the 3D car pulls away at once
	await get_tree().create_timer(after).timeout
	if waiting and not cleaning:
		_car_present = false


func _show_order(changed: bool) -> void:
	target_label.text = "of $%.2f%s" % [pump.target, "\nchanged!" if changed else ""]
	target_label.modulate = Color(1.0, 0.85, 0.4) if changed else Color.WHITE


func _on_order_changed(_new_target: float) -> void:
	_show_order(true)


func _on_drove_off() -> void:
	waiting = true
	_car_present = false
	car_departed.emit(self)
	_light.color = IDLE_LIGHT
	customer_left.emit(self)


func _process(delta: float) -> void:
	tick_cleaning(delta)
	tick_popup(delta)


## The result popup holds, then fades; its text stays for anyone reading it. Kept apart for tests.
func tick_popup(delta: float) -> void:
	if _popup_left <= 0.0:
		return
	_popup_left = maxf(0.0, _popup_left - delta)
	_set_popup(clampf(_popup_left / POPUP_FADE, 0.0, 1.0))


func _set_popup(alpha: float) -> void:
	result_label.modulate.a = alpha
	_popup.modulate.a = alpha


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
		target_label.text = "clean,\nnext car"
		_car_present = false
		car_departed.emit(self)
		_bubble.visible = false
		cleaning_finished.emit(self)
	else:
		_show_cleaning()


func _show_cleaning() -> void:
	target_label.text = "CLEANING %ds" % ceili(_cleaning_left)
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
	_auto_button.text = "AUTO" if on else "HAND"
	_auto_button.button_pressed = on
	if not waiting and not pump.is_done:
		_show_order(false)
		if not on:
			say(Customers.line(customer.type if customer.type != "" else "regular", "hello", pump.target))
	_key_label.text = "%d" % ((index + 1) % 10)  # the blue strip and the AUTO button say self-serve


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
	_key_label.text = "%d" % ((index + 1) % 10)


func _on_self_service_phase(phase: SelfServiceComponent.Phase) -> void:
	self_pouring.emit(self, phase == SelfServiceComponent.Phase.PUMPING)
	match phase:
		SelfServiceComponent.Phase.CARD:
			say("*fumbles with the card*")
			_light.color = SELF_LIGHT
		SelfServiceComponent.Phase.PUMPING:
			say("*pumps their own gas*")
			_light.color = POUR_LIGHT
		SelfServiceComponent.Phase.PAYING:
			say("*taps the card... again*")
			_light.color = SELF_LIGHT
		SelfServiceComponent.Phase.IDLE:
			_light.color = IDLE_LIGHT


## Super Perfect: the display shows the exact target ("on the dot").
func show_amount(amount: float) -> void:
	amount_label.text = "$%.2f" % amount


func clear_result() -> void:
	result_label.text = ""
	_popup_left = 0.0
	_set_popup(0.0)


func show_result(text: String, color: Color) -> void:
	result_label.text = text
	result_label.add_theme_color_override("font_color", color)
	_popup_left = POPUP_HOLD + POPUP_FADE
	_set_popup(1.0)


func _on_stopped(final_amount: float) -> void:
	waiting = true
	_light.color = IDLE_LIGHT
	pump_stopped.emit(self, final_amount)


## The card: [key | meter | order] on top, the customer's line below; the result popup to its right.
func _build() -> void:
	size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box(self, Vector2.ZERO, SIZE, Color(0.07, 0.07, 0.09, 0.82))
	_light = _box(self, Vector2.ZERO, Vector2(6, SIZE.y), IDLE_LIGHT)  # pouring / cleaning / self-serve

	_key_label = Greybox.label(self, "%d" % ((index + 1) % 10), 16, Vector2(8, 1), Vector2(30, 28))
	_key_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var plate := _box(self, Vector2(40, 2), Vector2(94, 27), Color(0.02, 0.02, 0.03))
	amount_label = Greybox.label(plate, "$0.00", 21, Vector2.ZERO, plate.size)
	amount_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	target_label = Greybox.label(self, "", 12, Vector2(138, 0), Vector2(96, 30))
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Customer's line (flavour; the rules live in CustomerComponent).
	_bubble = _box(self, Vector2(40, 31), Vector2(SIZE.x - 43, 17), Color(0.93, 0.91, 0.86))
	_bubble_label = Greybox.label(_bubble, "", 11, Vector2(4, 0), Vector2(_bubble.size.x - 8, 17))
	_bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bubble_label.clip_text = true  # one line; long lines end in …
	_bubble_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_bubble_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.12))

	# AUTO switch (#20): only on pumps that own the Self-service upgrade. Shift + number does the same.
	_auto_button = Button.new()
	_auto_button.toggle_mode = true
	_auto_button.focus_mode = Control.FOCUS_NONE
	_auto_button.add_theme_font_size_override("font_size", 9)
	_auto_button.position = Vector2(7, 31)
	_auto_button.size = Vector2(32, 17)
	_auto_button.visible = false
	_auto_button.pressed.connect(func() -> void:
		_auto_button.button_pressed = self_service  # the station decides; show the real state
		auto_toggle_requested.emit(self))
	add_child(_auto_button)

	# Result popup beside the card; fades after POPUP_HOLD.
	_popup = _box(self, Vector2(SIZE.x + 6, 0), Vector2(POPUP_W, SIZE.y), Color(0.05, 0.05, 0.07, 0.78))
	result_label = Greybox.label(_popup, "", 11, Vector2(6, 0), Vector2(POPUP_W - 12, SIZE.y))
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_set_popup(0.0)


func _box(parent: Control, at: Vector2, box_size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = at
	r.size = box_size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r
