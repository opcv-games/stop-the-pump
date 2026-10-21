class_name MetaState
extends RefCounted
## What carries over between runs (docs/GOD_PUMP_PLAN.md): XP and what it bought in Papa's Garage
## (nozzles, bling, perk tiers), what's equipped, cars filled across all runs (they unlock new car
## types), runs played, the best day reached, and whether Dad has come home. Saved to a small file.
## Serves: Advancement across runs.

const DEFAULT_PATH := "user://godpump_meta.cfg"

var path := DEFAULT_PATH  # "" = don't save (tests)
var xp := 0
var total_cars := 0
var runs := 0
var best_day := 0
var ending_seen := false
var intro_seen := false
var station_name := "GAZ BAR"
var volume := 0.8  # master volume, 0..1
var owned_nozzles: Array = ["classique"]
var owned_bling: Array = []
var perk_tiers := {}
var nozzle := "classique"
var equipped_bling: Array = []
## Round 8, for the menu screen: lifetime numbers, the last runs, Dad's postcards (the days they came)
## and the newspaper's last headlines.
var lifetime := {}
var history: Array = []  # {days, won, loot, deliveries, xp}, oldest first, the last 24 runs
var postcards: Array = []
var clippings: Array = []
const LIFETIME_KEYS := ["days", "loot", "deliveries", "xp_earned", "supers", "perfects", "goods", "oks",
	"overfilled", "unserved", "best_combo", "top_price"]


static func load_from(p: String) -> MetaState:
	var m := MetaState.new()
	m.path = p
	if p == "":
		return m
	var cfg := ConfigFile.new()
	if cfg.load(p) != OK:
		return m
	m.xp = cfg.get_value("meta", "xp", 0)
	m.total_cars = cfg.get_value("meta", "total_cars", 0)
	m.runs = cfg.get_value("meta", "runs", 0)
	m.best_day = cfg.get_value("meta", "best_day", 0)
	m.ending_seen = cfg.get_value("meta", "ending_seen", false)
	m.intro_seen = cfg.get_value("meta", "intro_seen", false)
	m.station_name = cfg.get_value("meta", "station_name", "GAZ BAR")
	m.volume = cfg.get_value("meta", "volume", 0.8)
	m.owned_nozzles = cfg.get_value("garage", "nozzles", ["classique"])
	m.owned_bling = cfg.get_value("garage", "bling", [])
	m.perk_tiers = cfg.get_value("garage", "perks", {})
	m.nozzle = cfg.get_value("garage", "nozzle", "classique")
	m.equipped_bling = cfg.get_value("garage", "equipped_bling", [])
	m.lifetime = cfg.get_value("story", "lifetime", {})
	m.history = cfg.get_value("story", "history", [])
	m.postcards = cfg.get_value("story", "postcards", [])
	m.clippings = cfg.get_value("story", "clippings", [])
	return m


func save() -> void:
	if path == "":
		return
	var cfg := ConfigFile.new()
	cfg.set_value("meta", "xp", xp)
	cfg.set_value("meta", "total_cars", total_cars)
	cfg.set_value("meta", "runs", runs)
	cfg.set_value("meta", "best_day", best_day)
	cfg.set_value("meta", "ending_seen", ending_seen)
	cfg.set_value("meta", "intro_seen", intro_seen)
	cfg.set_value("meta", "station_name", station_name)
	cfg.set_value("meta", "volume", volume)
	cfg.set_value("garage", "nozzles", owned_nozzles)
	cfg.set_value("garage", "bling", owned_bling)
	cfg.set_value("garage", "perks", perk_tiers)
	cfg.set_value("garage", "nozzle", nozzle)
	cfg.set_value("garage", "equipped_bling", equipped_bling)
	cfg.set_value("story", "lifetime", lifetime)
	cfg.set_value("story", "history", history)
	cfg.set_value("story", "postcards", postcards)
	cfg.set_value("story", "clippings", clippings)
	cfg.save(path)


## A finished run goes into the lifetime numbers and the run history (RunState.finish).
func bank_run(run: RunState) -> void:
	var t: Dictionary = run.totals
	var add := {"days": run.day, "loot": t.loot, "deliveries": run.deliveries, "xp_earned": run.xp,
		"supers": t.supers, "perfects": t.perfects, "goods": t.goods, "oks": t.oks, "overfilled": t.misses,
		"unserved": t.unserved}
	for k in add:
		lifetime[k] = lifetime.get(k, 0) + add[k]
	lifetime["best_combo"] = maxi(lifetime.get("best_combo", 1), t.best_combo)
	lifetime["top_price"] = maxf(lifetime.get("top_price", 0.0), run.price)
	history.append({"days": run.day, "won": run.won, "loot": t.loot, "deliveries": run.deliveries, "xp": run.xp})
	while history.size() > 24:
		history.pop_front()


## The morning paper went out: keep its headline, and a postcard if Dad sent one.
func clip(headline: String, postcard_day := 0) -> void:
	clippings.append(headline)
	while clippings.size() > 6:
		clippings.pop_front()
	if postcard_day > 0 and not postcard_day in postcards:
		postcards.append(postcard_day)
	save()


func bling_slots() -> int:
	return 1 + perk_tiers.get("slot", 0)


## What the next tier of a perk costs, or -1 if it's maxed.
func perk_price(id: String) -> int:
	var p := GodData.item(GodData.PERKS, id)
	var tier: int = perk_tiers.get(id, 0)
	return -1 if p.is_empty() or tier >= p.tiers else p.price * (tier + 1)


func buy_nozzle(id: String) -> bool:
	var n := GodData.item(GodData.NOZZLES, id)
	if n.is_empty() or id in owned_nozzles or xp < n.price:
		return false
	xp -= n.price
	owned_nozzles.append(id)
	nozzle = id
	save()
	return true


func buy_bling(id: String) -> bool:
	var b := GodData.item(GodData.BLING, id)
	if b.is_empty() or id in owned_bling or xp < b.price:
		return false
	xp -= b.price
	owned_bling.append(id)
	if equipped_bling.size() < bling_slots():
		equipped_bling.append(id)
	save()
	return true


func buy_perk(id: String) -> bool:
	var price := perk_price(id)
	if price < 0 or xp < price:
		return false
	xp -= price
	perk_tiers[id] = perk_tiers.get(id, 0) + 1
	save()
	return true


func equip_nozzle(id: String) -> bool:
	if not id in owned_nozzles:
		return false
	nozzle = id
	save()
	return true


## Toggles a bling on or off (if a slot is free).
func toggle_bling(id: String) -> bool:
	if not id in owned_bling:
		return false
	if id in equipped_bling:
		equipped_bling.erase(id)
	elif equipped_bling.size() < bling_slots():
		equipped_bling.append(id)
	else:
		return false
	save()
	return true


## Car types unlocked by cars filled across all runs.
func unlocked_cars() -> Array:
	var out := []
	for id in GodData.CAR_ORDER:
		if total_cars >= GodData.CAR_TYPES[id].unlock:
			out.append(id)
	return out


## The next car type to unlock: {id, name, have, need}, or {} when all are unlocked.
func next_unlock() -> Dictionary:
	for id in GodData.CAR_ORDER:
		var need: int = GodData.CAR_TYPES[id].unlock
		if total_cars < need:
			return {"id": id, "name": GodData.CAR_TYPES[id].name, "have": total_cars, "need": need}
	return {}


## The permanent effects: the equipped nozzle, equipped bling, and every perk tier.
func fx_mods(mods: Dictionary) -> void:
	GodData.apply_fx(mods, GodData.item(GodData.NOZZLES, nozzle).get("fx", {}))
	for id in equipped_bling:
		GodData.apply_fx(mods, GodData.item(GodData.BLING, id).get("fx", {}))
	for id in perk_tiers:
		GodData.apply_fx(mods, GodData.item(GodData.PERKS, id).get("fx", {}), perk_tiers[id])
	if "bobblehead" in equipped_bling:
		mods["bobblehead"] = 1
