class_name SimStation
extends Node
## A station with no screen, for the balance simulator (#6). It carries the same fields the real
## station exposes to Upgrades.apply(), so upgrades run through the game's own code and the bots
## always play today's rules. Defaults are read from the game's scripts, never copied by hand.

## A pump as the simulator sees it: its own tree level and whether it serves cars by itself.
class SimPump:
	var pump_level := 0
	var self_service := false


## Just the tank numbers Upgrades.apply() and the day touch.
class SimTank:
	var capacity_liters := 400.0
	var liters := 400.0


class SimCombo:
	var max_multiplier := 5
	var multiplier := 1


# --- Fields Upgrades.apply() / next_node() use (same names as the real station) ------------------
var owned := {}
var shop_price_scale := 1.0
var arrival_min := 1.0
var arrival_max := 5.0
var possible_targets: Array[float] = []
var cleaning_seconds := 4.0
var expanded := false
var economy := FuelEconomy.new()
var tank := SimTank.new()
var combo := SimCombo.new()

# --- Rules read from the game -------------------------------------------------------------------
var flow_rate := 4.0
var second_customer_offset := 2.0
var special_customer_chance := 0.45
var businessman_patience := 4.0
var self_service_speed := 0.5
var card_fee := 0.03
var starting_cash := 50.0
var run_days := 10
var day_seconds := 180.0
var card_wait := Vector2(2.0, 4.0)
var paying_seconds := 2.0
var tiers := ScoreTiers.new()

# --- The bot's body: assumptions about a human, not game rules (see docs/balance/REPORT.md) ------
## Seconds from a car parking to the player starting the pour on a manual pump.
var reaction_seconds := 1.0
## Extra seconds, at most, per other manual pump the player is juggling (attention is split).
var attention_penalty := 0.6
## Seconds a car takes to drive in from the road and park (#27).
var drive_in_seconds := 3.0

# --- Run state -----------------------------------------------------------------------------------
var pumps: Array[SimPump] = []
var cash := 50.0
var xp := 0
var day := 0
## Cash set aside tonight for the fuel order (#32): upgrades can't spend it.
var fuel_reserve := 0.0
var rng := RandomNumberGenerator.new()
## Price overrides for pump-tree nodes, by id, used by the tuning search (#34). Empty = the game's.
var pump_tree_prices := {}


## Changes numbers for a what-if run (tuning search, lever sweep). Keys: economy fields
## (rent_base, rent_growth, wholesale_ratio, *_tip), station fields, or "price:<pump tree id>".
func apply_overrides(changes: Dictionary) -> void:
	for key: String in changes:
		if key.begins_with("price:"):
			pump_tree_prices[key.trim_prefix("price:")] = changes[key]
		elif key in ["rent_base", "rent_growth", "wholesale_ratio", "super_perfect_tip", "perfect_tip", "good_tip", "ok_tip"]:
			economy.set(key, changes[key])
		else:
			set(key, changes[key])


## The game's defaults, read once from its scripts and reused for every simulated run.
static var _defaults := {}


## A fresh run with every number taken from the game's own defaults.
static func from_game_defaults() -> SimStation:
	if _defaults.is_empty():
		_defaults = _read_game_defaults()
	var st := SimStation.new()
	for key in _defaults:
		if key == "possible_targets":
			st.possible_targets.assign(_defaults[key])
		elif key == "card_wait":
			st.card_wait = _defaults[key]
		elif key != "pump_count" and key != "tank" and key != "combo":
			st.set(key, _defaults[key])
	st.tank.capacity_liters = _defaults.tank
	st.tank.liters = st.tank.capacity_liters
	st.combo.max_multiplier = _defaults.combo
	st.cash = st.starting_cash
	for i in _defaults.pump_count:
		st.pumps.append(SimPump.new())
	var level := Upgrades.starting_level("pumps", _defaults.pump_count)
	if level > 0:
		st.owned["pumps"] = level
	return st


static func _read_game_defaults() -> Dictionary:
	var d := {}
	var game: Control = load("res://scenes/greybox/pump_station.gd").new()
	for key in ["arrival_min", "arrival_max", "cleaning_seconds", "flow_rate", "second_customer_offset",
			"special_customer_chance", "businessman_patience", "self_service_speed", "card_fee",
			"starting_cash", "run_days", "shop_price_scale", "pump_count"]:
		d[key] = game.get(key)
	d.possible_targets = game.possible_targets.duplicate()
	game.free()
	var tank_node := TankComponent.new()
	d.tank = tank_node.capacity_liters
	tank_node.free()
	var clock := DayClock.new()
	d.day_seconds = clock.day_seconds
	clock.free()
	var ss := SelfServiceComponent.new()
	d.card_wait = Vector2(ss.card_wait_min, ss.card_wait_max)
	d.paying_seconds = ss.paying_seconds
	ss.free()
	var combo_node := ComboComponent.new()
	d.combo = combo_node.max_multiplier
	combo_node.free()
	return d


# --- Called by Upgrades.apply() ------------------------------------------------------------------

func add_pump() -> void:
	pumps.append(SimPump.new())


func set_expanded(on: bool) -> void:
	expanded = on


func apply_tuning() -> void:
	pass


# --- Buying (the bot's hands) ----------------------------------------------------------------------

func spendable() -> float:
	return cash - fuel_reserve


func branch_index(id: String) -> int:
	for i in Upgrades.BRANCHES.size():
		if Upgrades.BRANCHES[i].id == id:
			return i
	return -1


## Price of the next node in a branch, or -1 when the branch is complete.
func branch_price(id: String) -> float:
	var b := branch_index(id)
	return Upgrades.next_price(self, b) if not Upgrades.next_node(self, b).is_empty() else -1.0


func buy_branch(id: String) -> bool:
	var b := branch_index(id)
	var node := Upgrades.next_node(self, b)
	if node.is_empty():
		return false
	var price := Upgrades.next_price(self, b)
	if spendable() < price:
		return false
	cash -= price
	owned[id] = owned.get(id, 0) + 1
	Upgrades.apply(self, node.id)
	return true


## Price of pump `i`'s next upgrade, or -1 when its tree is complete.
func pump_price(i: int) -> float:
	if i >= pumps.size() or pumps[i].pump_level >= Upgrades.PUMP_TREE.size():
		return -1.0
	var node: Dictionary = Upgrades.PUMP_TREE[pumps[i].pump_level]
	return roundf(pump_tree_prices.get(node.id, node.price) * shop_price_scale)


func buy_pump(i: int) -> bool:
	var price := pump_price(i)
	if price < 0.0 or spendable() < price:
		return false
	cash -= price
	pumps[i].pump_level += 1
	if pumps[i].pump_level == 1:
		pumps[i].self_service = true
	return true


func self_service_flow(p: SimPump) -> float:
	return flow_rate * self_service_speed * (1.5 if p.pump_level >= 2 else 1.0)


func card_fee_for(p: SimPump) -> float:
	return card_fee * (0.5 if p.pump_level >= 3 else 1.0)
