class_name RunState
extends RefCounted
## One GOD PUMP run (docs/GOD_PUMP_PLAN.md): the day, the cash, the station's tank (in pump dollars),
## the fuel truck (the bill: each delivery raises the price, and lets you pick 1 of 3 cards), the shop
## upgrades bought, the cards picked, and the run's totals. Pure rules, no drawing: GodGame drives it,
## the tests and the balance bot play it. Serves: Advancement (the build) and tension (when to call
## the truck).

## The smallest delivery the truck will make: below this, with a dry tank, the run is over.
const MIN_DELIVERY := 20.0

var meta: MetaState
var rng := RandomNumberGenerator.new()
var day := 1
var cash := 60.0
var tank := 800.0
var price := GodData.WHOLESALE_START  # wholesale, per litre
var deliveries := 0
var owned := {}  # branch id -> nodes bought
var cards: Array = []
var price_frozen := false
var next_delivery_extra := 0.0
var xp := 0
var totals := {"cars": 0, "loot": 0.0, "supers": 0, "perfects": 0, "goods": 0, "oks": 0, "misses": 0, "best_combo": 1}
var over := false
var won := false
## The cards offered at the current delivery (empty when none is pending).
var offer: Array = []
var rerolls_left := 0


func _init(m: MetaState = null) -> void:
	if m:
		meta = m
	else:
		meta = MetaState.new()
		meta.path = ""  # a run without a meta (tests, the bot) saves nothing
	var mods := GodMods.compute(self)
	cash = mods.start_cash
	tank = mods.tank_capacity  # Dad's last delivery: the tank starts full


func mods() -> Dictionary:
	return GodMods.compute(self)


func tank_capacity() -> float:
	return mods().tank_capacity


# --- The night shop -----------------------------------------------------------------------------

func next_node(branch_id: String) -> Dictionary:
	var b := GodData.branch(branch_id)
	var level: int = owned.get(branch_id, 0)
	return b.nodes[level] if not b.is_empty() and level < b.nodes.size() else {}


func node_price(node: Dictionary) -> float:
	return roundf(node.price * (1.0 - mods().upgrade_discount))


func buy(branch_id: String) -> bool:
	var node := next_node(branch_id)
	if node.is_empty():
		return false
	var p := node_price(node)
	if cash < p:
		return false
	cash -= p
	owned[branch_id] = owned.get(branch_id, 0) + 1
	return true


# --- The fuel truck -----------------------------------------------------------------------------

## What a full delivery costs right now.
func delivery_cost() -> float:
	var missing := maxf(tank_capacity() - tank, 0.0)
	var cost := missing / GodData.PUMP_PRICE * price
	if deliveries == 0:
		cost *= 1.0 - mods().first_delivery_discount
	return roundf(cost * (1.0 + next_delivery_extra))


## The truck fills the tank, or, if the cash is short, brings as much gas as the cash buys (at least
## MIN_DELIVERY). A delivery of half a tank or more offers cards to pick from.
func call_truck() -> bool:
	var cost := delivery_cost()
	if cost <= 0.0 or cash < minf(cost, MIN_DELIVERY):
		return false
	var pay := minf(cost, cash)
	var share := pay / cost
	cash -= pay
	tank = tank_capacity() if share >= 0.999 else tank + (tank_capacity() - tank) * share
	deliveries += 1
	next_delivery_extra = 0.0
	if price_frozen:
		price_frozen = false
	else:
		price *= 1.0 + price_rise()
	rerolls_left = int(mods().rerolls)
	offer = draw_cards(int(mods().cards_offered)) if share >= 0.5 else []
	return true


## How much the wholesale price rises with each delivery (the supplier's contract slows it, the
## devil doubles it).
func price_rise() -> float:
	return GodData.PRICE_RISE * mods().price_rise_mult * (2.0 if "devil" in cards else 1.0)


## Out of gas and can't afford even a small delivery: the run is over.
func bankrupt() -> bool:
	return tank < 1.0 and cash < minf(delivery_cost(), MIN_DELIVERY)


## About how much gas a day burns, from this run so far (a cautious guess before the first day).
func gas_per_day() -> float:
	return maxf(totals.loot / maxf(day, 1) * 1.1, 90.0)


func days_of_gas() -> float:
	return tank / gas_per_day()


## The tank probably won't last tomorrow.
func tank_warning() -> bool:
	return days_of_gas() < 1.2 and delivery_cost() > 0.0


## Spending `price` now would leave too little to call the truck when the tank needs it.
func purchase_risky(price: float) -> bool:
	return tank_warning() and cash - price < delivery_cost()


## `n` different cards, weighted by rarity; luck tilts the odds toward rare and legendary.
func draw_cards(n: int) -> Array:
	var luck: float = mods().luck
	var weights := {"common": GodData.RARITY_WEIGHT.common, "rare": GodData.RARITY_WEIGHT.rare + luck * 0.6,
		"legendary": GodData.RARITY_WEIGHT.legendary + luck * 0.25}
	var pool := []
	for c in GodData.CARDS:
		pool.append(c.id)
	var out := []
	while out.size() < n and not pool.is_empty():
		var total := 0.0
		for id in pool:
			total += weights[GodData.card(id).rarity]
		var pick := rng.randf() * total
		for id in pool:
			pick -= weights[GodData.card(id).rarity]
			if pick <= 0.0:
				out.append(id)
				pool.erase(id)
				break
	return out


func reroll() -> bool:
	if rerolls_left <= 0 or offer.is_empty():
		return false
	rerolls_left -= 1
	offer = draw_cards(offer.size())
	return true


func pick_card(id: String) -> bool:
	if not id in offer:
		return false
	cards.append(id)
	offer = []
	match id:
		"price_freeze":
			price_frozen = true
		"loan":
			cash += 300.0
			next_delivery_extra = 0.4
	return true


# --- Days ---------------------------------------------------------------------------------------

## Folds a finished day into the run: its cash, gas left, XP and stats.
func end_day(report: Dictionary) -> void:
	cash += report.get("loot", 0.0)
	tank = report.get("tank_left", tank)
	xp += report.get("xp", 0)
	totals.cars += report.get("cars", 0)
	totals.loot += report.get("loot", 0.0)
	var t: Dictionary = report.get("tiers", {})
	totals.supers += t.get(ScoreTiers.SUPER_PERFECT, 0)
	totals.perfects += t.get(ScoreTiers.PERFECT, 0)
	totals.goods += t.get(ScoreTiers.GOOD, 0)
	totals.oks += t.get(ScoreTiers.OK, 0)
	totals.misses += t.get(ScoreTiers.MISS, 0)
	totals.best_combo = maxi(totals.best_combo, report.get("best_combo", 1))
	if day >= GodData.FINAL_DAY:
		won = true
		over = true


func next_day() -> void:
	day += 1


## Ends the run and banks it in the meta: XP, cars, best day.
func finish() -> void:
	over = true
	meta.xp += xp
	meta.total_cars += totals.cars
	meta.runs += 1
	meta.best_day = maxi(meta.best_day, day)
	if won:
		meta.ending_seen = true
	meta.save()
