class_name FuelEconomy
extends Resource
## What a stop pays (cash + XP) and what a day costs (refill + rent).
## A Resource so every price can be tuned in the inspector. Serves: Advancement. Refs #3, #8


## What one stop earned, shown to the player under the pump.
class Receipt:
	var sale := 0.0       ## What the customer pays: never more than they asked for.
	var tip := 0.0        ## By tier only. The combo never changes cash.
	var overshoot := 0.0  ## Dollars of fuel pumped past the target, given away from the tank.
	var short := false    ## Stopped below the target outside the Perfect window: no tip.
	var earned := 0.0     ## sale + tip, paid in full at the pump.


@export_group("At the pump")
@export var super_perfect_tip := 8.0
@export var perfect_tip := 5.0
@export var good_tip := 2.0
@export var ok_tip := 0.0
@export_group("XP (multiplied by the combo)")
@export var super_perfect_xp := 200
@export var perfect_xp := 100
@export var good_xp := 50
@export var ok_xp := 10
@export_group("Between days")
## Wholesale fuel price as a share of the pump price. 0.8 means a $2 litre costs the station $1.60.
@export_range(0.0, 1.0) var wholesale_ratio := 0.8
@export var price_per_liter := 2.0
@export var rent_base := 100.0
## Added to the rent every new day of a run.
@export var rent_growth := 40.0

## Tip jar upgrade (#15): added to Good-or-better tips. Reset on a new run.
var tip_bonus := 0.0


func settle(final_amount: float, target: float, tier: String) -> Receipt:
	var r := Receipt.new()
	r.sale = minf(final_amount, target)
	r.overshoot = maxf(0.0, final_amount - target)
	r.short = final_amount < target and tier != ScoreTiers.PERFECT and tier != ScoreTiers.SUPER_PERFECT
	r.tip = 0.0 if r.short else tip_for(tier)
	if tip_bonus != 0.0 and not r.short and tiers_keep_combo(tier):
		r.tip += tip_bonus
	r.earned = r.sale + r.tip
	return r


func tiers_keep_combo(tier: String) -> bool:
	return tier == ScoreTiers.SUPER_PERFECT or tier == ScoreTiers.PERFECT or tier == ScoreTiers.GOOD


func tip_for(tier: String) -> float:
	match tier:
		ScoreTiers.SUPER_PERFECT:
			return super_perfect_tip
		ScoreTiers.PERFECT:
			return perfect_tip
		ScoreTiers.GOOD:
			return good_tip
		ScoreTiers.OK:
			return ok_tip
	return 0.0


func xp_for(tier: String, multiplier: int) -> int:
	match tier:
		ScoreTiers.SUPER_PERFECT:
			return super_perfect_xp * multiplier
		ScoreTiers.PERFECT:
			return perfect_xp * multiplier
		ScoreTiers.GOOD:
			return good_xp * multiplier
		ScoreTiers.OK:
			return ok_xp
	return 0


func refill_cost(liters: float) -> float:
	return liters * price_per_liter * wholesale_ratio


func rent_for(day: int) -> float:
	return rent_base + rent_growth * (day - 1)
