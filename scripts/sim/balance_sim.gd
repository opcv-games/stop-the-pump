class_name BalanceSim
extends RefCounted
## The bot harness (#6): plays Gas Bar Blues headless, thousands of times, to compare buying
## strategies. A day is simulated event by event (cars arrive, drive in, get served, leave) with the
## game's own numbers; the bot lands Super Perfect, Perfect, Good, OK and Miss equally often. Upgrades
## go through Upgrades.apply() on a SimStation, so the bots always play today's rules.

const TIERS := [ScoreTiers.SUPER_PERFECT, ScoreTiers.PERFECT, ScoreTiers.GOOD, ScoreTiers.OK, ScoreTiers.MISS]
## Furthest a Miss lands from the order, in dollars (it starts just past the OK window).
const MISS_REACH := 3.0
## Fuel bought just in time covers yesterday's use per pump, times tonight's pumps, plus this margin.
const JIT_MARGIN := 1.15

## Each strategy: what the bot buys at night, in priority order, and how it orders fuel.
## Wants: a branch id, "auto_all" (every pump self-serves), "auto_keep1" (all but pump 1),
## "pump_tree" (Faster self-serve and Card deal on self-serve pumps), "cheapest" (anything, cheapest first).
const STRATEGIES := {
	"hoard": {"label": "Hoard (buy nothing)", "fuel": "jit", "wants": []},
	"pumps_first": {"label": "Pumps first, play every pump by hand", "fuel": "jit", "wants": ["pumps", "cheapest"]},
	"pumps_first_fill": {"label": "Pumps first, but always fill the tank", "fuel": "fill", "wants": ["pumps", "cheapest"]},
	"automate_all": {"label": "Automate every pump", "fuel": "jit", "wants": ["pumps", "auto_all", "pump_tree", "cheapest"]},
	"hybrid": {"label": "Play pump 1, automate the rest", "fuel": "jit", "wants": ["pumps", "auto_keep1", "pump_tree", "cheapest"]},
	"marketing_first": {"label": "Marketing first", "fuel": "jit", "wants": ["marketing", "pumps", "cheapest"]},
	"tips_first": {"label": "Service and vibe first", "fuel": "jit", "wants": ["service", "vibe", "pumps", "cheapest"]},
	"cheapest": {"label": "Always the cheapest upgrade", "fuel": "jit", "wants": ["cheapest"]},
}


static func strategy(id: String) -> Dictionary:
	var s: Dictionary = STRATEGIES[id].duplicate()
	s.id = id
	return s


# --- A day ---------------------------------------------------------------------------------------

## Plays one day on `st` (cash and tank change). Returns what happened.
static func play_day(st: SimStation) -> Dictionary:
	var out := {"stops": 0, "self_stops": 0, "left": 0, "earned": 0.0, "tips": 0.0, "fuel_liters": 0.0,
		"ran_dry": false, "xp": 0, "tiers": {}}
	if st.tank.liters <= 0.0:
		out.ran_dry = true
		return out
	var events: Array[Dictionary] = []
	var manual := 0
	for p in st.pumps:
		if not p.self_service:
			manual += 1
	for i in st.pumps.size():
		_pump_timeline(st, i, manual, events)
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.t < b.t)
	st.combo.multiplier = 1
	var ppl := st.economy.price_per_liter
	for e in events:
		match e.kind:
			"left":
				out.left += 1
				st.combo.multiplier = 1
			"self":
				var dollars: float = minf(e.target, st.tank.liters * ppl)
				st.tank.liters -= dollars / ppl
				var earned: float = dollars * (1.0 - e.fee)
				st.cash += earned
				out.earned += earned
				out.fuel_liters += dollars / ppl
				out.stops += 1
				out.self_stops += 1
			"manual":
				var final: float = minf(e.final, st.tank.liters * ppl)
				var tier: String = e.tier if final >= e.final else st.tiers.evaluate(final, e.target)
				st.tank.liters -= final / ppl
				var r := st.economy.settle(final, e.target, tier)
				st.cash += r.earned
				out.earned += r.earned
				out.tips += r.tip
				out.fuel_liters += final / ppl
				out.stops += 1
				out.tiers[tier] = out.tiers.get(tier, 0) + 1
				out.xp += st.economy.xp_for(tier, st.combo.multiplier)
				if st.tiers.extends_combo(tier):
					st.combo.multiplier = mini(st.combo.multiplier + 1, st.combo.max_multiplier)
				else:
					st.combo.multiplier = 1
		if st.tank.liters <= 0.000001:
			st.tank.liters = 0.0
			out.ran_dry = true
			break  # the tank ran dry: the day closes (#8)
	st.xp += out.xp
	return out


## Every customer one pump serves today, as timed events (when the sale lands).
static func _pump_timeline(st: SimStation, i: int, manual: int, events: Array[Dictionary]) -> void:
	var p: SimStation.SimPump = st.pumps[i]
	var rng := st.rng
	var t := rng.randf_range(0.0, st.second_customer_offset * i)
	while true:
		t += st.drive_in_seconds  # the car drives in and parks before anyone is served (#27)
		if t >= st.day_seconds:
			return
		var target: float = st.possible_targets[rng.randi() % st.possible_targets.size()]
		if p.self_service:
			var start := t + rng.randf_range(st.card_wait.x, st.card_wait.y)
			if start >= st.day_seconds:
				return
			var end := start + target / st.self_service_flow(p)
			events.append({"t": end, "kind": "self", "target": target, "fee": st.card_fee_for(p)})
			t = end + st.paying_seconds + rng.randf_range(st.arrival_min, st.arrival_max)
			continue
		var type := "regular"
		if rng.randf() < st.special_customer_chance:
			type = "grandpa" if rng.randf() < 0.5 else "businessman"
		var reaction := st.reaction_seconds + st.attention_penalty * rng.randf() * (manual - 1)
		if type == "businessman" and reaction > st.businessman_patience:
			events.append({"t": t + st.businessman_patience, "kind": "left"})
			t += st.businessman_patience + rng.randf_range(st.arrival_min, st.arrival_max)
			continue
		var start := t + reaction
		if start >= st.day_seconds:
			return
		if type == "grandpa":  # changes his mind mid-pour: the pour runs to the new order
			target = st.possible_targets[rng.randi() % st.possible_targets.size()]
		var tier: String = TIERS[rng.randi() % TIERS.size()]
		var final := maxf(target + _miss_by(st, tier, rng), 0.0)
		var end := start + final / st.flow_rate
		events.append({"t": end, "kind": "manual", "target": target, "final": final, "tier": tier})
		t = end
		if final - target > st.tiers.ok_window:
			t += st.cleaning_seconds  # overshoot: the car needs cleaning (#9)
		t += rng.randf_range(st.arrival_min, st.arrival_max)


## How far from the order a stop of `tier` lands: a random distance inside that tier's ring, over
## or under at random. Super Perfect snaps to the order.
static func _miss_by(st: SimStation, tier: String, rng: RandomNumberGenerator) -> float:
	var w := st.tiers
	var ring := Vector2.ZERO
	match tier:
		ScoreTiers.SUPER_PERFECT:
			return 0.0
		ScoreTiers.PERFECT:
			ring = Vector2(w.super_window + 0.01, w.perfect_window)
		ScoreTiers.GOOD:
			ring = Vector2(w.perfect_window + 0.01, w.good_window)
		ScoreTiers.OK:
			ring = Vector2(w.good_window + 0.01, w.ok_window)
		_:
			ring = Vector2(w.ok_window + 0.01, MISS_REACH)
	return rng.randf_range(ring.x, ring.y) * (1.0 if rng.randf() < 0.5 else -1.0)


# --- A run ---------------------------------------------------------------------------------------

## Plays a whole run with `strat` buying at night. Returns the outcome and the cash after each day.
static func play_run(strat: Dictionary, st: SimStation) -> Dictionary:
	var out := {"strategy": strat.id, "evicted": false, "complete": false, "days": 0, "cash": 0.0,
		"history": [], "stops": 0, "pumps": 0, "self_pumps": 0, "xp": 0, "ran_dry_days": 0,
		"first_auto_day": 0, "self_pumps_day4": 0}
	var last_fuel := 0.0
	for d in range(1, st.run_days + 1):
		st.day = d
		var day := play_day(st)
		last_fuel = day.fuel_liters / maxf(st.pumps.size(), 1.0)  # per pump
		out.stops += day.stops
		if day.ran_dry:
			out.ran_dry_days += 1
		st.cash -= st.economy.rent_for(d)
		out.days = d
		out.history.append(st.cash)
		if st.cash < 0.0:
			out.evicted = true
			break
		if d == st.run_days:
			out.complete = true
			break
		_night(strat, st, last_fuel)
		var self_now := 0
		for p in st.pumps:
			if p.self_service:
				self_now += 1
		if self_now > 0 and out.first_auto_day == 0:
			out.first_auto_day = d + 1  # the first day a pump serves by itself
		if d + 1 == 4:
			out.self_pumps_day4 = self_now
	out.cash = st.cash
	out.xp = st.xp
	out.pumps = st.pumps.size()
	for p in st.pumps:
		if p.self_service:
			out.self_pumps += 1
	return out


## The bot's night: order fuel first (it sets cash aside), then buy what the strategy wants.
## "fill" orders a full tank before shopping. "jit" keeps cash for tomorrow's fuel (yesterday's use per
## pump, for tonight's pumps) and spends the rest, then orders exactly that.
static func _night(strat: Dictionary, st: SimStation, fuel_per_pump: float) -> void:
	var unit := st.economy.refill_cost(1.0)
	var room := st.tank.capacity_liters - st.tank.liters
	var liters := minf(room, maxf(st.cash, 0.0) / unit)
	if strat.fuel == "jit":
		liters = minf(clampf(fuel_per_pump * st.pumps.size() * JIT_MARGIN - st.tank.liters, 0.0, room), liters)
	st.fuel_reserve = st.economy.refill_cost(liters)
	var bought := true
	while bought:
		bought = false
		for w in strat.wants:
			if _try(w, st):
				bought = true
				break  # start again from the top priority
	# Re-plan with what was bought: new pumps need fuel too, tank upgrades make room.
	room = st.tank.capacity_liters - st.tank.liters
	var need: float = room if strat.fuel == "fill" else clampf(fuel_per_pump * st.pumps.size() * JIT_MARGIN - st.tank.liters, 0.0, room)
	liters = minf(need, maxf(st.cash, 0.0) / unit)
	st.fuel_reserve = 0.0
	st.cash -= st.economy.refill_cost(liters)
	st.tank.liters += liters


static func _try(want: String, st: SimStation) -> bool:
	match want:
		"auto_all", "auto_keep1":
			for i in range(st.pumps.size() - 1, (0 if want == "auto_all" else 1) - 1, -1):
				if not st.pumps[i].self_service and st.buy_pump(i):
					return true
			return false
		"pump_tree":
			for i in st.pumps.size():
				if st.pumps[i].self_service and st.buy_pump(i):
					return true
			return false
		"cheapest":
			return _buy_cheapest(st)
	return st.buy_branch(want)


static func _buy_cheapest(st: SimStation) -> bool:
	var best := INF
	var action := Callable()
	for b in Upgrades.BRANCHES:
		var price := st.branch_price(b.id)
		if price >= 0.0 and price < best:
			best = price
			action = st.buy_branch.bind(b.id)
	for i in st.pumps.size():
		var price := st.pump_price(i)
		if price >= 0.0 and price < best:
			best = price
			action = st.buy_pump.bind(i)
	return action.is_valid() and st.spendable() >= best and action.call()
