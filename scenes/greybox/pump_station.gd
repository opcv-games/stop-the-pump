extends Control
## Ugly Prototype: a station of pumps, keys 1..N, one shared combo, one shared tank. Flat colors only.
## Kept: #1 tiered stop, #7 combo + sound (M toggles), #4 two pumps.
## Kept: #8 a full day (7am-11pm in 3 minutes), cash at the pump, XP from combos, costs at day end.
## Kept: #9 car-cleaning delay after a big overshoot (C toggles it), one fuel-to-cash gauge.
## Testing: #10 random car arrivals; chord progression on good stops (M toggles sound).

enum State { OPEN, CLOSING, SUMMARY }

## How many pumps the station runs. The difficulty ladder (1 to 10) is this one number.
@export_range(1, 10) var pump_count := 2
## Customer orders, in dollars. Picked at random each customer.
@export var possible_targets: Array[float] = [10.0, 15.0, 20.0, 25.0, 30.0, 40.0]
## The next car pulls in after a random wait between these, so the rhythm can't be memorized (#10).
## The marketing upgrade branch will shorten it.
@export var arrival_min := 1.0
@export var arrival_max := 5.0
## At opening, pump N's first car arrives within N x this many seconds, so pumps start out of sync.
@export var second_customer_offset := 2.0
@export var flow_rate := 4.0
## Seconds a pump is out of service after an overshoot past the OK window (#9).
@export var cleaning_seconds := 4.0
## Playtest switch (C) so the cleaning delay can be judged on its own.
@export var cleaning_enabled := true
## Cash the player starts a run with.
@export var starting_cash := 50.0
@export var economy: FuelEconomy = FuelEconomy.new()

const TIER_COLORS := {
	ScoreTiers.PERFECT: Color(0.35, 0.9, 0.45),
	ScoreTiers.GOOD: Color(0.6, 0.8, 1.0),
	ScoreTiers.OK: Color(0.95, 0.85, 0.4),
	ScoreTiers.MISS: Color(0.95, 0.35, 0.3),
}

@onready var combo: ComboComponent = $ComboComponent
@onready var sound: SoundFeedback = $SoundFeedback
@onready var wallet: WalletComponent = $WalletComponent
@onready var tank: TankComponent = $TankComponent
@onready var clock: DayClock = $DayClock

var bays: Array[PumpBay] = []
var state := State.OPEN
var day := 0
var evicted := false

var _day_id := 0  # stale customer timers from a previous day are ignored
var _day_earned := 0.0
var _start_fuel_value := 1.0
var _counts := {ScoreTiers.PERFECT: 0, ScoreTiers.GOOD: 0, ScoreTiers.OK: 0, ScoreTiers.MISS: 0}
var _best_combo := 1

var _combo_label: Label
var _xp_label: Label
var _clock_label: Label
var _day_bar: ColorRect
var _stats_label: Label
var _hint_label: Label
var _day_gauge: DayGauge
var _cash_label: Label
var _tank_label: Label
var _overlay: Control
var summary_label: Label


func _ready() -> void:
	tank.price_per_liter = economy.price_per_liter
	_ensure_input_actions()
	_build_station()
	combo.multiplier_changed.connect(_on_multiplier_changed)
	wallet.cash_changed.connect(func(_c: float, _d: float) -> void: _update_gauges())
	wallet.xp_changed.connect(func(xp: int) -> void: _xp_label.text = "XP\n%d" % xp)
	tank.level_changed.connect(func(_l: float) -> void: _update_gauges())
	tank.emptied.connect(_close_day)
	clock.time_changed.connect(_on_time_changed)
	clock.closed.connect(_close_day)
	sound.watch_combo(combo)
	start_run()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("toggle_sound"):
		sound.enabled = not sound.enabled
		_update_hint()
		return
	if event.is_action_pressed("toggle_cleaning"):
		cleaning_enabled = not cleaning_enabled
		_update_hint()
		return
	if state == State.SUMMARY:
		if event.is_action_pressed("continue"):
			continue_pressed()
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


## A new run: starting cash, day 1. XP is kept (it is the run-to-run currency).
func start_run() -> void:
	evicted = false
	day = 0
	wallet.add(starting_cash - wallet.cash)
	start_next_day()


func start_next_day() -> void:
	day += 1
	_day_id += 1
	_day_earned = 0.0
	tank.refill()
	combo.reset()  # every day starts at x1
	_start_fuel_value = tank.remaining_value()
	_overlay.visible = false
	state = State.OPEN
	clock.start()
	for bay in bays:
		bay.show_empty()
		bay.result_label.text = ""
		_customer_after(bay, randf_range(0.0, second_customer_offset * bay.index))
	_update_gauges()


func continue_pressed() -> void:
	if state != State.SUMMARY:
		return
	if evicted:
		start_run()
	else:
		start_next_day()


func _on_bay_stopped(bay: PumpBay, final_amount: float) -> void:
	var target := bay.pump.target
	var tier := combo.tiers.evaluate(final_amount, target)
	var lost := combo.multiplier if not combo.tiers.extends_combo(tier) and combo.multiplier > 1 else 0
	var paid_multiplier := combo.register(tier)
	var receipt := economy.settle(final_amount, target, tier)
	var xp := economy.xp_for(tier, paid_multiplier)
	_day_earned += receipt.earned
	wallet.add(receipt.earned)
	wallet.add_xp(xp)
	sound.play_tier(tier)
	_counts[tier] += 1
	bay.show_result(_receipt_text(tier, final_amount - target, receipt, xp, paid_multiplier, lost), TIER_COLORS[tier])
	_stats_label.text = "Perfect %d   Good %d   OK %d   Miss %d   |   Best combo x%d" % [
		_counts[ScoreTiers.PERFECT], _counts[ScoreTiers.GOOD], _counts[ScoreTiers.OK],
		_counts[ScoreTiers.MISS], _best_combo]
	if cleaning_enabled and receipt.overshoot > combo.tiers.ok_window:
		bay.start_cleaning(cleaning_seconds)  # the next customer comes when cleaning finishes
	elif state == State.OPEN:
		_customer_after(bay, next_arrival_delay())
	if state != State.OPEN:
		_check_day_over()


## Three short lines under the pump: tier and distance, cash and why, XP (and combo lost).
func _receipt_text(tier: String, diff: float, r: FuelEconomy.Receipt, xp: int, paid_multiplier: int, lost: int) -> String:
	var distance := "on the dot" if absf(diff) < 0.005 else "$%.2f %s" % [absf(diff), "over" if diff > 0 else "short"]
	var text := "%s  %s\n+$%.2f" % [tier.to_upper(), distance, r.earned]
	if r.short:
		text += "  no tip"
	elif r.overshoot >= 0.5:
		text += "  wasted %.1f L" % (r.overshoot / economy.price_per_liter)
	elif r.tip > 0.0:
		text += "  incl. tip $%.0f" % r.tip
	if lost:
		text += "\nCOMBO LOST  x%d" % lost
	elif xp > 0:
		text += "\n+%d XP" % xp
		if paid_multiplier > 1:
			text += " (x%d)" % paid_multiplier
	return text


func next_arrival_delay() -> float:
	return randf_range(arrival_min, arrival_max)


func _customer_after(bay: PumpBay, delay: float) -> void:
	var id := _day_id
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if is_instance_valid(bay) and state == State.OPEN and id == _day_id:
		bay.new_customer(possible_targets.pick_random())


## The clock ran out or the tank is empty: no new customers, unserved ones drive off,
## pours in progress finish, then the day is settled.
func _close_day() -> void:
	if state != State.OPEN:
		return
	state = State.CLOSING
	for bay in bays:
		if not bay.pump.is_pouring:
			bay.show_empty()
	_update_hint()
	_check_day_over()


func _check_day_over() -> void:
	if state != State.CLOSING:
		return
	for bay in bays:
		if bay.pump.is_pouring:
			return
	_settle_day()


func _settle_day() -> void:
	clock.running = false
	var liters := tank.liters_used()
	var refill := economy.refill_cost(liters)
	var rent := economy.rent_for(day)
	wallet.add(-(refill + rent))
	evicted = wallet.cash < 0.0
	state = State.SUMMARY
	var reason := "Out of fuel" if tank.is_empty() else "11:00 PM"
	summary_label.text = "\n".join([
		"EVICTED" if evicted else "DAY %d CLOSED" % day,
		reason,
		"",
		"Earned today         +$%.2f" % _day_earned,
		"Refill %3.0f L         -$%.2f" % [liters, refill],
		"Rent                   -$%.2f" % rent,
		"",
		"Cash   %s$%.2f        XP   %d" % ["-" if wallet.cash < 0 else "", absf(wallet.cash), wallet.xp],
		"",
		"Press ENTER to start a new run" if evicted else "Press ENTER for day %d  (rent $%.0f)" % [day + 1, economy.rent_for(day + 1)],
	])
	summary_label.add_theme_color_override("font_color", TIER_COLORS[ScoreTiers.MISS] if evicted else Color.WHITE)
	_overlay.visible = true
	_update_hint()


func _on_time_changed(_hour: float) -> void:
	_clock_label.text = "DAY %d     %s" % [day, clock.label()]
	_day_bar.size.x = 400.0 * clock.progress()


func _update_gauges() -> void:
	if not _day_gauge:
		return
	_day_gauge.set_values(_day_earned, tank.remaining_value(), _start_fuel_value)
	_tank_label.text = "%.0f L in tank" % tank.liters
	_cash_label.text = "CASH\n%s$%.0f" % ["-" if wallet.cash < 0 else "", absf(wallet.cash)]
	_cash_label.add_theme_color_override("font_color", Color.WHITE if wallet.cash >= 0 else TIER_COLORS[ScoreTiers.MISS])


func _on_multiplier_changed(multiplier: int) -> void:
	_best_combo = maxi(_best_combo, multiplier)
	_combo_label.text = "x%d" % multiplier
	# Greybox "heat": the label warms from grey to orange as the chain grows.
	var heat := float(multiplier - 1) / float(combo.max_multiplier - 1)
	_combo_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.72).lerp(Color(1.0, 0.55, 0.15), heat))
	_combo_label.add_theme_font_size_override("font_size", 48 + multiplier * 10)


func _update_hint() -> void:
	if state == State.SUMMARY:
		_hint_label.text = "ENTER to continue.     M: sound %s" % ("ON" if sound.enabled else "OFF")
		return
	var keys := "1" if bays.size() == 1 else "1–%d" % mini(bays.size(), 9)
	_hint_label.text = "Hold keys %s to pour each pump.  Release to stop.     M: sound %s     C: cleaning %s" % [
		keys, "ON" if sound.enabled else "OFF", "ON" if cleaning_enabled else "OFF"]


## Greybox input, done in code; moves to the Input Map later. Keys 1..9 then 0 for pump 10.
func _ensure_input_actions() -> void:
	var bindings := {"toggle_sound": [KEY_M], "toggle_cleaning": [KEY_C], "continue": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]}
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

	# Day clock across the top.
	_clock_label = Greybox.label(self, "", 26, Vector2(0, 4), Vector2(1152, 36))
	var day_back := ColorRect.new()
	day_back.color = Color(0.1, 0.1, 0.11)
	day_back.position = Vector2(376, 42)
	day_back.size = Vector2(400, 8)
	add_child(day_back)
	_day_bar = ColorRect.new()
	_day_bar.color = Color(0.95, 0.85, 0.4)
	_day_bar.position = day_back.position
	_day_bar.size = Vector2(0, 8)
	add_child(_day_bar)

	# Bays side by side between the gauges (left) and the combo (right).
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
		bay.pump.tank = tank
		bay.scale = Vector2.ONE * scale_factor
		bay.position = Vector2(area_left + (area_width - row_width) / 2.0 + i * (PumpBay.SIZE.x * scale_factor + gap), 62)
		bay.pump_stopped.connect(_on_bay_stopped)
		bay.cleaning_finished.connect(func(b: PumpBay) -> void: _customer_after(b, next_arrival_delay()))
		sound.watch_pump(bay.pump, i)
		bays.append(bay)

	# Left: one gauge where fuel (orange) turns into today's cash (green), plus the bank balance.
	_day_gauge = DayGauge.new()
	add_child(_day_gauge)
	_day_gauge.setup(Vector2(60, 150), Vector2(80, 300))
	_tank_label = Greybox.label(self, "", 16, Vector2(0, 482), Vector2(200, 24))
	_tank_label.modulate = Color(1, 1, 1, 0.6)
	_cash_label = Greybox.label(self, "", 22, Vector2(0, 505), Vector2(200, 60))

	# Right: combo and XP.
	_combo_label = Greybox.label(self, "", 48, Vector2(952, 110), Vector2(200, 160))
	_combo_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	Greybox.label(self, "COMBO", 22, Vector2(952, 270), Vector2(200, 32)).modulate = Color(1, 1, 1, 0.6)
	_xp_label = Greybox.label(self, "XP\n0", 28, Vector2(952, 340), Vector2(200, 90))
	_on_multiplier_changed(1)

	_stats_label = Greybox.label(self, "Perfect 0   Good 0   OK 0   Miss 0   |   Best combo x1", 20, Vector2(0, 572), Vector2(1152, 30))
	_hint_label = Greybox.label(self, "", 18, Vector2(0, 606), Vector2(1152, 30))
	_hint_label.modulate = Color(1, 1, 1, 0.6)
	var version := Greybox.label(self, "v%s" % ProjectSettings.get_setting("application/config/version", "dev"), 16, Vector2(952, 618), Vector2(190, 26))
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	version.modulate = Color(1, 1, 1, 0.5)
	version.name = "VersionLabel"

	# End-of-day screen.
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(dim)
	var panel := ColorRect.new()
	panel.color = Color(0.12, 0.12, 0.14)
	panel.position = Vector2(256, 104)
	panel.size = Vector2(640, 420)
	_overlay.add_child(panel)
	summary_label = Greybox.label(panel, "", 26, Vector2(0, 20), Vector2(640, 380))
	summary_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_overlay.visible = false
	_update_hint()
