class_name GodMods
extends RefCounted
## Adds up everything a run owns into the numbers a day runs on: the base values, the night-shop
## upgrades bought, the truck cards picked, and Papa's Garage (equipped nozzle and bling, perk tiers).
## One place, so the shop, the cards, the meta and the balance bot all agree.

static func compute(run: RunState) -> Dictionary:
	var mods := GodData.BASE.duplicate()
	for b in GodData.BRANCHES:
		var level: int = run.owned.get(b.id, 0)
		for i in level:
			GodData.apply_fx(mods, b.nodes[i].fx)
	for id in run.links:
		GodData.apply_fx(mods, GodData.link(id).fx)
	for id in run.cards:
		GodData.apply_fx(mods, GodData.card(id).fx)
	if run.meta:
		run.meta.fx_mods(mods)
	mods.customer_chance = clampf(mods.customer_chance, 0.0, 0.95)
	return mods
