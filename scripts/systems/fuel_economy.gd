class_name FuelEconomy
extends Resource
## Turns one finished pour into money: margin on fuel sold, plus a tip, minus overshoot fuel.
## A Resource so prices and tips can be tuned in the inspector. Serves: Advancement. Refs #3


## What one stop earned, shown to the player as a breakdown.
class Receipt:
	var sale := 0.0       ## What the customer pays: never more than they asked for.
	var fuel_cost := 0.0  ## Wholesale cost of every drop pumped, overshoot included.
	var tip := 0.0        ## Tier tip times the combo multiplier.
	var overshoot := 0.0  ## Dollars pumped past the target, given away.
	var short := false    ## Stopped below the target outside the Perfect window: no tip.
	var profit := 0.0


@export var tiers: ScoreTiers = ScoreTiers.new()
## Wholesale fuel price as a share of the pump price. 0.8 means $20 of fuel costs the station $16.
@export_range(0.0, 1.0) var wholesale_ratio := 0.8
@export var perfect_tip := 5.0
@export var good_tip := 2.0
@export var ok_tip := 0.0


func settle(final_amount: float, target: float, tier: String, multiplier := 1) -> Receipt:
	var r := Receipt.new()
	r.sale = minf(final_amount, target)
	r.fuel_cost = final_amount * wholesale_ratio
	r.overshoot = maxf(0.0, final_amount - target)
	r.short = final_amount < target and tier != ScoreTiers.PERFECT
	r.tip = 0.0 if r.short else tip_for(tier) * multiplier
	r.profit = r.sale - r.fuel_cost + r.tip
	return r


func tip_for(tier: String) -> float:
	match tier:
		ScoreTiers.PERFECT:
			return perfect_tip
		ScoreTiers.GOOD:
			return good_tip
		ScoreTiers.OK:
			return ok_tip
	return 0.0
