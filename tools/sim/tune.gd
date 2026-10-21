extends SceneTree
## Tuning search (#34): tries every combination of a few economy numbers and scores each against the
## design targets, using the balance simulator's bots (even tier split). Prints the best candidates.
##
##     godot --headless -s tools/sim/tune.gd -- 400        (runs per strategy per candidate)
##
## Targets: the best strategy survives most runs (about 80%); hoarding does not; playing pump 1 and
## automating the rest is nearly as strong as playing everything; a pump self-serves by day 3-4.

## Third pass (#35, 15-second days): days earn about a quarter of what 3-minute days did, so rent and
## every price scale down. (Earlier passes: wholesale, rent growth, self-serve speed and price.)
const GRID := {
	"rent_base": [20.0],
	"rent_growth": [6.0, 7.0],
	"shop_price_scale": [0.4, 0.5],
	"hours_x": [1.0, 1.5, 2.0],  # multiplies the HOURS prices
}
const STRATS := ["hoard", "pumps_first", "cheapest", "hybrid", "automate_all", "hours_first", "hours_and_pumps"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var runs := int(args[0]) if args.size() > 0 else 400
	var results: Array[Dictionary] = []
	for combo in _combos(GRID.keys(), 0, {}):
		var r := {"set": combo}
		for id in STRATS:
			var ok := 0
			var auto_day := 0.0
			var autos := 0
			var self4 := 0.0
			for seed in runs:
				var st := SimStation.from_game_defaults()
				st.rng.seed = seed + 1
				var changes: Dictionary = combo.duplicate()
				var hx: float = changes.get("hours_x", 1.0)
				changes.erase("hours_x")
				for node in Upgrades.BRANCHES[st.branch_index("hours")].nodes:
					changes["price:" + node.id] = node.price * hx
				st.apply_overrides(changes)
				var run := BalanceSim.play_run(BalanceSim.strategy(id), st)
				st.free()
				if run.complete:
					ok += 1
				if run.first_auto_day > 0:
					auto_day += run.first_auto_day
					autos += 1
				self4 += run.self_pumps_day4
			r[id] = float(ok) / runs
			r[id + "_auto_day"] = auto_day / maxf(autos, 1.0)
			r[id + "_self4"] = self4 / runs
		r.score = _score(r)
		results.append(r)
	results.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.score < b.score)
	for r in results.slice(0, 12):
		print("score %.3f | %s | hoard %.0f%% pumps %.0f%% cheapest %.0f%% hybrid %.0f%% auto %.0f%% hours %.0f%% hours+pumps %.0f%% | hybrid first auto day %.1f, self pumps day4 %.2f" % [
			r.score, JSON.stringify(r.set), r.hoard * 100, r.pumps_first * 100, r.cheapest * 100, r.hybrid * 100,
			r.automate_all * 100, r.hours_first * 100, r.hours_and_pumps * 100, r.hybrid_auto_day, r.hybrid_self4])
	quit()


func _score(r: Dictionary) -> float:
	var best: float = [r.pumps_first, r.cheapest, r.hybrid, r.automate_all, r.hours_first, r.hours_and_pumps].max()
	var s := absf(best - 0.8)                                   # most runs, not all
	s += maxf(0.0, r.hoard - 0.1)                               # hoarding must not work
	s += maxf(0.0, best - r.hybrid - 0.1)                       # automation nearly as strong
	s += maxf(0.0, r.hybrid_auto_day - 4.0) * 0.1 if r.hybrid_auto_day > 0 else 0.5  # self-serve by day 3-4
	s += maxf(0.0, 1.0 - r.hybrid_self4) * 0.2                  # at least one self-serve pump on day 4
	return s


func _combos(keys: Array, i: int, acc: Dictionary) -> Array:
	if i == keys.size():
		return [acc.duplicate()]
	var out := []
	for v in GRID[keys[i]]:
		acc[keys[i]] = v
		out += _combos(keys, i + 1, acc)
	return out
