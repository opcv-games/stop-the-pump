class_name ComboComponent
extends Node
## Chains good stops into a tip multiplier so every stop has something to lose.
## One combo for the whole station (design rule 5): a miss on any pump breaks it.
## Serves: Mastery. Refs #7, #3

signal multiplier_changed(multiplier: int)
signal combo_broken(lost_multiplier: int)

@export var tiers: ScoreTiers = ScoreTiers.new()
@export var max_multiplier := 5

var multiplier := 1


## Updates the chain for one stop and returns the multiplier that stop is paid at.
## A good stop is paid at the current multiplier, then grows it; a bad stop is paid x1 and resets.
func register(tier: String) -> int:
	if tiers.extends_combo(tier):
		var paid := multiplier
		if multiplier < max_multiplier:
			multiplier += 1
			multiplier_changed.emit(multiplier)
		return paid
	if multiplier > 1:
		combo_broken.emit(multiplier)
		multiplier = 1
		multiplier_changed.emit(multiplier)
	return 1
