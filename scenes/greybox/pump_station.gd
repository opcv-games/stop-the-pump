extends Control
## Ugly Prototype: a station of pumps, keys 1..N, one shared combo, one shared tank. Flat colors only.
## Kept: #1 tiered stop, #7 combo + sound (M toggles), #4 two pumps.
## Kept: #8 a full day (7am-11pm in 3 minutes), cash at the pump, XP from combos, costs at day end.
## Kept: #9 car-cleaning delay after a big overshoot (C toggles it), one fuel-to-cash gauge.
## Kept: #10 random car arrivals, #11 the blues.
## Kept: #12 Super Perfect tier (M toggles sound). #13 designer tools.
## Kept: #15 cash upgrade tree between days (Bills-style, cost only).
## Kept: #16 plain SFX + background music (Roadside At Two).
## Kept: #17 self-service pumps (replace the Turbo nozzle).
## Kept: #18 an upgrade tree per pump (shop page 2, Tab).
## Kept: #5 customers with rules (Grandpa, Businessman), grey car + speech bubble.
## Kept: #19 run arc: 10-day run with a finish line, 1x/2x/3x speed, full automation allowed.
## Kept: #20 endless mode after day 10; auto on/off per pump (Shift + number).
## Phase 4 (#22): the painted 3D station world sits behind this HUD, lit by the clock, with rain.

enum State { OPEN, CLOSING, SUMMARY, SHOP }
enum ShopPage { STATION, PUMPS }

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
## Where the tuning panel saves the designer's numbers ("" = don't load or save, used by tests).
@export var tuning_file := "user://tuning.cfg"
## Cash the player starts a run with.
@export var starting_cash := 50.0
## Days in a run (#19). Surviving the last one completes the run.
@export var run_days := 10
## Customers (#5): chance a car is a special customer instead of a Regular, and how long the
## Impatient Businessman waits for the pour to start.
@export_range(0.0, 1.0) var special_customer_chance := 0.45
@export var businessman_patience := 4.0
## Upgrade tree (#15): a multiplier on every upgrade price.
@export var shop_price_scale := 1.0
## Self-service pumps (#17): share of the normal pour speed, and the card fee taken from each sale.
## A pump's own tree (#18) multiplies the speed by 1.5 (Faster self-serve) and halves the fee (Card deal).
@export var self_service_speed := 0.5
@export var card_fee := 0.03
@export var economy: FuelEconomy = FuelEconomy.new()

const TIER_COLORS := {
	ScoreTiers.SUPER_PERFECT: Color(1.0, 0.85, 0.3),
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

## Dev mode (F1): force stop results with Q W E R T Y. Distances from the target, in dollars.
const DEV_RESULTS := {
	"super": 0.0, "perfect": 0.07, "good": 0.3, "ok": 0.8, "miss_under": -10.0, "miss_over": 10.0,
}
const DEV_KEYS := {
	KEY_Q: "super", KEY_W: "perfect", KEY_E: "good", KEY_R: "ok", KEY_T: "miss_under", KEY_Y: "miss_over",
}

var bays: Array[PumpBay] = []
var dev_mode := false
## Upgrade tree progress: branch id -> how many of its upgrades are owned. Wiped on eviction.
var owned := {}
var shop_page := ShopPage.STATION

## Numbers at the start of a run (after the designer's tuning), restored when a new run starts.
var _base := {}
var _base_targets: Array[float] = []
var state := State.OPEN
var day := 0
var evicted := false
## The last day of the run was survived (#19).
var run_complete := false
## Endless mode (#20): kept going after the last day; only eviction ends the run.
var endless := false
## Game speed picked by the player: 1, 2 or 3 (#19).
var speed := 1

var _day_id := 0  # stale customer timers from a previous day are ignored
var _day_earned := 0.0
var _run_earned := 0.0
var _start_fuel_value := 1.0
var _counts := {ScoreTiers.SUPER_PERFECT: 0, ScoreTiers.PERFECT: 0, ScoreTiers.GOOD: 0, ScoreTiers.OK: 0, ScoreTiers.MISS: 0}
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
var _dev_label: Label
var _tuning_panel: TuningPanel
var _shop: Control
var _bg: ColorRect
## The painted 3D station behind the HUD (#22).
var world_view: WorldView
var _speed_buttons: Array[Button] = []
var _shop_title: Label
var _shop_cards: Array[Label] = []
var _shop_footer: Label
var summary_label: Label


func _ready() -> void:
	if tuning_file != "":
		Tuning.load_into(self, tuning_file)
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
	_base = Tuning.snapshot(self)
	_base_targets = possible_targets.duplicate()
	start_run()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("toggle_sound"):
		sound.enabled = not sound.enabled
		_update_hint()
		return
	if event.is_action_pressed("toggle_dev"):
		dev_mode = not dev_mode
		_dev_label.visible = dev_mode
		return
	if event.is_action_pressed("toggle_tuning"):
		_tuning_panel.toggle()
		return
	if event.is_action_pressed("dev_rain"):
		toggle_rain()
		return
	if event.is_action_pressed("cycle_speed"):
		cycle_speed()
		return
	if event.is_action_pressed("dev_end_day"):
		dev_end_day()
		return
	if event.is_action_pressed("dev_add_cash"):
		dev_add_cash()
		return
	if dev_mode and state == State.OPEN and event is InputEventKey and event.pressed and DEV_KEYS.has(event.physical_keycode):
		dev_force(DEV_KEYS[event.physical_keycode])
		return
	if event.is_action_pressed("toggle_cleaning"):
		cleaning_enabled = not cleaning_enabled
		_update_hint()
		return
	if state == State.SUMMARY:
		if run_complete and event is InputEventKey and event.pressed and event.physical_keycode == KEY_E:
			go_endless()
			return
		if event.is_action_pressed("continue"):
			continue_pressed()
		return
	if state == State.SHOP:
		if event is InputEventKey and event.pressed:
			if event.physical_keycode == KEY_TAB:
				toggle_shop_page()
				return
			if event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_9:
				var i: int = event.physical_keycode - KEY_1
				if shop_page == ShopPage.STATION:
					buy(i)
				else:
					buy_pump(i)
				return
		if event.is_action_pressed("continue") and not (event is InputEventKey and event.physical_keycode == KEY_SPACE):
			continue_pressed()
		return
	# Shift + number: switch that pump between auto and manual (#20). Checked before pouring.
	if event is InputEventKey and event.pressed and event.shift_pressed \
			and event.physical_keycode >= KEY_1 and event.physical_keycode <= KEY_9:
		toggle_auto(event.physical_keycode - KEY_1)
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


## Dev mode: the first pump with a customer stops at a chosen distance from its target.
func dev_force(result: String) -> void:
	for bay in bays:
		if not bay.waiting and not bay.pump.is_done and not bay.self_service:
			bay.pump.finish_at(maxf(0.0, bay.pump.target + DEV_RESULTS[result]))
			return


## Dev (F3 or the "End day" button): stop every pour, send waiting cars away, settle the day now.
func dev_end_day() -> void:
	if state != State.OPEN and state != State.CLOSING:
		return
	for bay in bays:
		if bay.self_service:
			# The player's release is ignored on self-service pumps, so stop the pump itself.
			bay.self_service_component.phase = SelfServiceComponent.Phase.IDLE
			if bay.pump.is_pouring:
				bay.pump.stop_pour()
		elif bay.pump.is_pouring:
			bay.release()
	clock.elapsed = clock.day_seconds
	clock.running = false
	if state == State.OPEN:
		_close_day()
	else:
		_check_day_over()


## Dev (F4 or the "+$100" button): free cash, any time.
func dev_add_cash() -> void:
	wallet.add(100.0)
	if state == State.SHOP:
		_refresh_shop()


## Pushes tuned numbers out to the pieces that copy them (called by Tuning after any change).
func apply_tuning() -> void:
	tank.price_per_liter = economy.price_per_liter
	for bay in bays:
		bay.flow_multiplier = 1.0
		if bay.self_service:
			bay.flow_multiplier = self_service_speed * (1.5 if bay.pump_level >= 2 else 1.0)
		bay.customer.patience_seconds = businessman_patience
		bay.pump.flow_rate = flow_rate * bay.flow_multiplier
	sound.apply_tuning()


## The tuning panel changed a number: it becomes part of the run's starting setup too.
func note_tuned(key: String) -> void:
	_base[key] = Tuning.get_value(self, key)


## Game speed (#19): the whole game, clock and timers included, runs `n` times faster.
func set_speed(n: int) -> void:
	speed = clampi(n, 1, 3)
	Engine.time_scale = speed
	for i in _speed_buttons.size():
		_speed_buttons[i].button_pressed = i + 1 == speed


## Switches pump `i` between auto and manual (#20). False when it can't (no upgrade, busy).
func toggle_auto(i: int) -> bool:
	if i >= bays.size() or not bays[i].toggle_auto():
		return false
	apply_tuning()
	_update_hint()
	return true


## Dev (F5): start or stop rain now (#22).
func toggle_rain() -> void:
	world_view.world.weather.toggle()


## Endless mode (#20): keep the run going past the last day.
func go_endless() -> void:
	if not run_complete:
		return
	endless = true
	run_complete = false
	open_shop()


func cycle_speed() -> void:
	set_speed(speed % 3 + 1)


func speed_text() -> String:
	return "%dx" % speed


func _exit_tree() -> void:
	Engine.time_scale = 1.0  # never leave the engine fast-forwarded


## A new run: starting cash, day 1. XP is kept (it is the run-to-run currency).
func start_run() -> void:
	_reset_run_upgrades()
	evicted = false
	run_complete = false
	endless = false
	_run_earned = 0.0
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
	if _shop:
		_shop.visible = false
	state = State.OPEN
	world_view.world.weather.begin_day()
	clock.start()
	for bay in bays:
		bay.show_empty()
		bay.result_label.text = ""
		_customer_after(bay, randf_range(0.0, second_customer_offset * bay.index))
	_update_gauges()
	_update_hint()


func continue_pressed() -> void:
	match state:
		State.SUMMARY:
			if evicted or run_complete:
				start_run()
			else:
				open_shop()
		State.SHOP:
			start_next_day()


# --- Upgrade tree (#15) -------------------------------------------------------

func open_shop() -> void:
	state = State.SHOP
	shop_page = ShopPage.STATION
	_overlay.visible = false
	_refresh_shop()
	_shop.visible = true
	_update_hint()


## Buys the next upgrade in a branch (0..4). False if the branch is complete or cash is short.
func buy(branch: int) -> bool:
	if state != State.SHOP or branch >= Upgrades.BRANCHES.size():
		return false
	var node := Upgrades.next_node(self, branch)
	if node.is_empty():
		return false
	var price := Upgrades.next_price(self, branch)
	if wallet.cash < price:
		_shop_footer.text = "Not enough cash for the %s ($%.0f)." % [node.name, price]
		return false
	wallet.add(-price)
	var id: String = Upgrades.BRANCHES[branch].id
	owned[id] = owned.get(id, 0) + 1
	Upgrades.apply(self, node.id)
	_refresh_shop()
	return true


func toggle_shop_page() -> void:
	shop_page = ShopPage.PUMPS if shop_page == ShopPage.STATION else ShopPage.STATION
	_refresh_shop()
	_update_hint()


## Buys the next upgrade in pump `index`'s own tree. The last pump the player pours can't convert.
func buy_pump(index: int) -> bool:
	if state != State.SHOP or index >= bays.size():
		return false
	var bay := bays[index]
	var node := Upgrades.next_pump_node(bay)
	if node.is_empty():
		return false
	var price := Upgrades.next_pump_price(self, bay)
	if wallet.cash < price:
		_shop_footer.text = "Not enough cash for pump %d's %s ($%.0f)." % [index + 1, node.name, price]
		return false
	wallet.add(-price)
	bay.pump_level += 1
	owned["pump_%d" % (index + 1)] = bay.pump_level
	if node.id == "self_service":
		bay.make_self_service()
	apply_tuning()
	_refresh_shop()
	return true


func shop_card_text(branch: int) -> String:
	return _shop_cards[branch].text


func _refresh_shop() -> void:
	if not _shop:
		return
	var page := "STATION" if shop_page == ShopPage.STATION else "YOUR PUMPS"
	_shop_title.text = "UPGRADES: %s   after day %d      cash $%.0f" % [page, day, wallet.cash]
	for i in _shop_cards.size():
		if shop_page == ShopPage.STATION:
			_fill_branch_card(i)
		else:
			_fill_pump_card(i)
	var keys := Upgrades.BRANCHES.size() if shop_page == ShopPage.STATION else bays.size()
	_shop_footer.text = "1–%d buy     TAB %s     ENTER open the station for day %d  (rent $%.0f)" % [
		keys, "your pumps" if shop_page == ShopPage.STATION else "station upgrades", day + 1, economy.rent_for(day + 1)]


func _fill_branch_card(i: int) -> void:
	var b: Dictionary = Upgrades.BRANCHES[i]
	var level: int = owned.get(b.id, 0)
	var lines := ["[%d]  %s" % [i + 1, b.name], ""]
	for n in b.nodes.size():
		var node: Dictionary = b.nodes[n]
		if n < level:
			lines.append("✓ %s" % node.name)
		elif n == level:
			var price := Upgrades.next_price(self, i)
			lines.append("> %s\n   %s\n   $%.0f%s" % [node.name, node.helps, price, "" if wallet.cash >= price else "  (short)"])
		else:
			lines.append("· %s" % node.name)
	if level >= b.nodes.size():
		lines.append("\nCOMPLETE")
	_shop_cards[i].text = "\n".join(lines)
	_shop_cards[i].modulate = Color.WHITE if level < b.nodes.size() and wallet.cash >= Upgrades.next_price(self, i) else Color(1, 1, 1, 0.6)


func _fill_pump_card(i: int) -> void:
	if i >= bays.size():
		_shop_cards[i].text = "\n\n(build more pumps\nin the station's\nPUMPS branch)"
		_shop_cards[i].modulate = Color(1, 1, 1, 0.35)
		return
	var bay := bays[i]
	var mode := "you pour it"
	if bay.pump_level >= 1:
		mode = "self-serve (auto on)" if bay.self_service else "self-serve (auto off)"
	var lines := ["[%d]  PUMP %d" % [i + 1, i + 1], mode, ""]
	for n in Upgrades.PUMP_TREE.size():
		var node: Dictionary = Upgrades.PUMP_TREE[n]
		if n < bay.pump_level:
			lines.append("✓ %s" % node.name)
		elif n == bay.pump_level:
			var price := Upgrades.next_pump_price(self, bay)
			lines.append("> %s\n   %s\n   $%.0f%s" % [node.name, node.helps, price, "" if wallet.cash >= price else "  (short)"])
		else:
			lines.append("· %s" % node.name)
	if bay.pump_level >= Upgrades.PUMP_TREE.size():
		lines.append("\nCOMPLETE")
	_shop_cards[i].text = "\n".join(lines)
	var node := Upgrades.next_pump_node(bay)
	var can: bool = not node.is_empty() and wallet.cash >= Upgrades.next_pump_price(self, bay)
	_shop_cards[i].modulate = Color.WHITE if can else Color(1, 1, 1, 0.6)


## Eviction: the run's upgrades are gone; the station goes back to its starting setup.
func _reset_run_upgrades() -> void:
	if _base.is_empty():
		return
	Tuning.apply_snapshot(self, _base)
	possible_targets.assign(_base_targets)
	economy.tip_bonus = 0.0
	owned.clear()
	shop_page = ShopPage.STATION
	while bays.size() > pump_count:
		var bay: PumpBay = bays.pop_back()
		sound.unwatch_pump(bay.pump)
		bay.queue_free()
	while bays.size() < pump_count:
		_add_bay(bays.size())
	for bay in bays:
		bay.make_manual()
	_layout_bays()
	apply_tuning()


## Extra pump upgrade: one more bay, laid out with the others.
func add_pump() -> void:
	pump_count += 1
	_add_bay(bays.size())
	_layout_bays()


func _on_bay_stopped(bay: PumpBay, final_amount: float) -> void:
	if bay.self_service:
		_check_day_over()  # self-service is settled when the customer pays
		return
	var target := bay.pump.target
	var customer_type := bay.customer.type
	var tier := combo.tiers.evaluate(final_amount, target)
	var lost := combo.multiplier if not combo.tiers.extends_combo(tier) and combo.multiplier > 1 else 0
	var paid_multiplier := combo.register(tier)
	var receipt := economy.settle(final_amount, target, tier)
	var xp := economy.xp_for(tier, paid_multiplier)
	# $20 Guy (#5): whatever went over comes out of the player's own pocket.
	var pocket := receipt.overshoot if bay.customer.out_of_pocket() else 0.0
	_day_earned += receipt.earned - pocket
	wallet.add(receipt.earned - pocket)
	wallet.add_xp(xp)
	sound.play_tier(tier)
	if tier == ScoreTiers.SUPER_PERFECT:
		bay.show_amount(target)
	_counts[tier] += 1
	var text := _receipt_text(tier, final_amount - target, receipt, xp, paid_multiplier, lost)
	if pocket > 0.0:
		text = text.insert(text.find("\n"), "  out of your pocket -$%.2f" % pocket)
	bay.show_result(text, TIER_COLORS[tier])
	bay.say(Customers.reaction(customer_type if customer_type != "" else "regular", tier, receipt.overshoot))
	_stats_label.text = "Super %d   Perfect %d   Good %d   OK %d   Miss %d   |   Best combo x%d" % [
		_counts[ScoreTiers.SUPER_PERFECT], _counts[ScoreTiers.PERFECT], _counts[ScoreTiers.GOOD],
		_counts[ScoreTiers.OK], _counts[ScoreTiers.MISS], _best_combo]
	if cleaning_enabled and receipt.overshoot > combo.tiers.ok_window:
		bay.start_cleaning(cleaning_seconds)  # the next customer comes when cleaning finishes
	else:
		bay.car_leaves()
		if state == State.OPEN:
			_customer_after(bay, next_arrival_delay())
	if state != State.OPEN:
		_check_day_over()


## Three short lines under the pump: tier and distance, cash and why, XP (and combo lost).
func _receipt_text(tier: String, diff: float, r: FuelEconomy.Receipt, xp: int, paid_multiplier: int, lost: int) -> String:
	var distance := "on the dot" if absf(diff) < 0.005 or tier == ScoreTiers.SUPER_PERFECT else "$%.2f %s" % [absf(diff), "over" if diff > 0 else "short"]
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


## A self-service customer paid and drove off: the sale minus the card fee. No tip, combo or XP.
func _on_self_service_paid(bay: PumpBay, amount: float) -> void:
	var fee := amount * card_fee_for(bay)
	var earned := amount - fee
	_day_earned += earned
	wallet.add(earned)
	bay.show_result("SELF-SERVE  $%.2f\n+$%.2f  card fee -$%.2f" % [amount, earned, fee], Color(0.45, 0.6, 1.0))
	bay.waiting = true
	bay.car_leaves()
	if state == State.OPEN:
		_customer_after(bay, next_arrival_delay())
	else:
		bay.show_empty()
		_check_day_over()


## The Impatient Businessman gave up (#5): no sale, and the chain breaks like a miss.
func _on_customer_left(bay: PumpBay) -> void:
	var lost := combo.multiplier
	if lost > 1:
		combo.register(ScoreTiers.MISS)
	sound.play_tier(ScoreTiers.MISS)
	bay.show_result("DROVE OFF\nno sale%s" % ("\nCOMBO LOST  x%d" % lost if lost > 1 else ""), TIER_COLORS[ScoreTiers.MISS])
	if state == State.OPEN:
		_customer_after(bay, next_arrival_delay())
	else:
		_check_day_over()


## The card fee a pump charges: halved by its Card deal upgrade (#18).
func card_fee_for(bay: PumpBay) -> float:
	return card_fee * (0.5 if bay.pump_level >= 3 else 1.0)


func next_arrival_delay() -> float:
	return randf_range(arrival_min, arrival_max)


func _customer_after(bay: PumpBay, delay: float) -> void:
	var id := _day_id
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if is_instance_valid(bay) and state == State.OPEN and id == _day_id:
		if bay.self_service:
			bay.new_customer(possible_targets.pick_random())  # self-service only gets Regulars
		else:
			var c := Customers.roll(special_customer_chance, possible_targets)
			bay.new_customer(c.target, c.type)


## The clock ran out or the tank is empty: no new customers, unserved ones drive off,
## pours in progress finish, then the day is settled.
func _close_day() -> void:
	if state != State.OPEN:
		return
	state = State.CLOSING
	for bay in bays:
		if not bay.pump.is_pouring and not _self_service_busy(bay):
			bay.show_empty()
	_update_hint()
	_check_day_over()


func _check_day_over() -> void:
	if state != State.CLOSING:
		return
	for bay in bays:
		if bay.pump.is_pouring or _self_service_busy(bay):
			return
	_settle_day()


## A self-service customer who is pumping or paying finishes before the day closes.
func _self_service_busy(bay: PumpBay) -> bool:
	if not bay.self_service:
		return false
	var phase := bay.self_service_component.phase
	return phase == SelfServiceComponent.Phase.PUMPING or phase == SelfServiceComponent.Phase.PAYING


func _settle_day() -> void:
	clock.running = false
	var liters := tank.liters_used()
	var refill := economy.refill_cost(liters)
	var rent := economy.rent_for(day)
	wallet.add(-(refill + rent))
	evicted = wallet.cash < 0.0
	run_complete = not evicted and not endless and day >= run_days
	_run_earned += _day_earned
	state = State.SUMMARY
	var reason := "Out of fuel" if tank.is_empty() else "11:00 PM"
	if run_complete:
		summary_label.text = "\n".join([
			"RUN COMPLETE", "%d day%s at the Gas Bar" % [run_days, "" if run_days == 1 else "s"], "",
			"Earned this run      +$%.2f" % _run_earned,
			"Cash left               $%.2f" % wallet.cash,
			"XP                         %d" % wallet.xp, "",
			"ENTER  new run          E  keep going (endless)",
		])
		summary_label.add_theme_color_override("font_color", TIER_COLORS[ScoreTiers.SUPER_PERFECT])
		_overlay.visible = true
		_update_hint()
		return
	summary_label.text = "\n".join([
		"EVICTED" if evicted else ("DAY %d CLOSED (endless)" % day if endless else "DAY %d/%d CLOSED" % [day, run_days]),
		reason,
		"",
		"Earned today         +$%.2f" % _day_earned,
		"Refill %3.0f L         -$%.2f" % [liters, refill],
		"Rent                   -$%.2f" % rent,
		"",
		"Cash   %s$%.2f        XP   %d" % ["-" if wallet.cash < 0 else "", absf(wallet.cash), wallet.xp],
		"",
		"Press ENTER to start a new run" if evicted else "Press ENTER for the night shop",
	])
	summary_label.add_theme_color_override("font_color", TIER_COLORS[ScoreTiers.MISS] if evicted else Color.WHITE)
	_overlay.visible = true
	_update_hint()


func _on_time_changed(hour: float) -> void:
	if world_view and world_view.world:
		world_view.world.set_hour(hour)
	var day_text := "DAY %d (endless)" % day if endless else "DAY %d/%d" % [day, run_days]
	_clock_label.text = "%s     %s" % [day_text, clock.label()]
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
	if state == State.SHOP:
		_hint_label.text = "1–%d buy     TAB switch page     ENTER open the station" % (Upgrades.BRANCHES.size() if shop_page == ShopPage.STATION else bays.size())
		return
	var played: Array[String] = []
	for bay in bays:
		if not bay.self_service:
			played.append(str((bay.index + 1) % 10))
	var keys := ", ".join(played)
	var pour := "Hold %s to pour.  Release to stop." % keys if keys != "" else "Fully automated."
	for bay in bays:
		if bay.pump_level >= 1:
			pour += "  Shift+n auto"
			break
	_hint_label.text = "%s    S speed %s    M sound %s    C cleaning %s    F1 dev    F2 tuning" % [
		pour, speed_text(), "ON" if sound.enabled else "OFF", "ON" if cleaning_enabled else "OFF"]


## Greybox input, done in code; moves to the Input Map later. Keys 1..9 then 0 for pump 10.
func _ensure_input_actions() -> void:
	var bindings := {"toggle_sound": [KEY_M], "toggle_cleaning": [KEY_C], "cycle_speed": [KEY_S], "toggle_dev": [KEY_F1], "toggle_tuning": [KEY_F2], "dev_end_day": [KEY_F3], "dev_add_cash": [KEY_F4], "dev_rain": [KEY_F5], "continue": [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]}
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


func _add_bay(i: int) -> void:
	var bay := PumpBay.new()
	bay.name = "Bay%d" % (i + 1)
	add_child(bay)
	move_child(bay, world_view.get_index() + 1)  # in front of the world, behind the overlays
	bay.setup(i, flow_rate)
	bay.pump.tank = tank
	bay.pump_stopped.connect(_on_bay_stopped)
	bay.cleaning_finished.connect(func(b: PumpBay) -> void: _customer_after(b, next_arrival_delay()))
	bay.self_service_paid.connect(_on_self_service_paid)
	bay.customer_left.connect(_on_customer_left)
	bay.auto_toggle_requested.connect(func(b: PumpBay) -> void: toggle_auto(b.index))
	bay.customer.patience_seconds = businessman_patience
	sound.watch_pump(bay.pump, i)
	bays.append(bay)


## Bays side by side between the gauge (left) and the combo (right), shrinking to fit.
func _layout_bays() -> void:
	var area_left := 200.0
	var area_width := 1152.0 - 400.0
	var gap := 20.0
	var n := bays.size()
	var scale_factor := minf(1.0, (area_width - gap * (n - 1)) / (PumpBay.SIZE.x * n))
	var row_width := (PumpBay.SIZE.x * scale_factor + gap) * n - gap
	for i in n:
		bays[i].scale = Vector2.ONE * scale_factor
		bays[i].position = Vector2(area_left + (area_width - row_width) / 2.0 + i * (PumpBay.SIZE.x * scale_factor + gap), 62)


func _build_station() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg = ColorRect.new()
	_bg.color = Color(0.18, 0.18, 0.2)
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)
	world_view = WorldView.new()
	world_view.name = "WorldView"
	add_child(world_view)

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

	for i in pump_count:
		_add_bay(i)
	_layout_bays()

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

	_stats_label = Greybox.label(self, "Super 0   Perfect 0   Good 0   OK 0   Miss 0   |   Best combo x1", 20, Vector2(0, 572), Vector2(1152, 30))
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

	# Night shop screen (#14).
	_shop = Control.new()
	_shop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_shop)
	var shop_dim := ColorRect.new()
	shop_dim.color = Color(0.08, 0.08, 0.1, 0.94)
	shop_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shop.add_child(shop_dim)
	_shop_title = Greybox.label(_shop, "", 30, Vector2(0, 30), Vector2(1152, 44))
	for i in Upgrades.BRANCHES.size():
		var card_bg := ColorRect.new()
		card_bg.color = Color(0.16, 0.16, 0.19)
		card_bg.position = Vector2(26 + i * 222, 90)
		card_bg.size = Vector2(212, 400)
		_shop.add_child(card_bg)
		var card := Greybox.label(card_bg, "", 17, Vector2(10, 10), Vector2(192, 380))
		card.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_shop_cards.append(card)
	_shop_footer = Greybox.label(_shop, "", 20, Vector2(0, 510), Vector2(1152, 60))
	_shop.visible = false

	# Game speed (#19): 1x 2x 3x at the top left, also S to cycle.
	var speed_row := HBoxContainer.new()
	speed_row.position = Vector2(8, 6)
	speed_row.add_theme_constant_override("separation", 4)
	add_child(speed_row)
	for n in [1, 2, 3]:
		var b := Button.new()
		b.text = "%dx" % n
		b.toggle_mode = true
		b.button_pressed = n == 1
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(func() -> void:
			set_speed(n)
			_update_hint())
		speed_row.add_child(b)
		_speed_buttons.append(b)

	_dev_label = Greybox.label(self, "DEV   Q super   W perfect   E good   R ok   T -$10   Y +$10", 16, Vector2(8, 44), Vector2(400, 24))
	_dev_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_dev_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.8))
	_dev_label.visible = false
	# Dev buttons: always on screen, top right, for one-click testing.
	var dev_buttons := HBoxContainer.new()
	dev_buttons.position = Vector2(930, 6)
	dev_buttons.add_theme_constant_override("separation", 8)
	add_child(dev_buttons)
	for b in [["EndDayButton", "End day (F3)", dev_end_day], ["AddCashButton", "+$100 (F4)", dev_add_cash]]:
		var button := Button.new()
		button.name = b[0]
		button.text = b[1]
		button.focus_mode = Control.FOCUS_NONE  # never steals Space/Enter from the game
		button.add_theme_font_size_override("font_size", 14)
		button.pressed.connect(b[2])
		dev_buttons.add_child(button)
	_tuning_panel = TuningPanel.new()
	add_child(_tuning_panel)
	_tuning_panel.setup(self)
	_update_hint()
