class_name ComboComponent
extends Node
## Chains good stops into a tip multiplier so every stop has something to lose.
## One combo for the whole station (design rule 5): a miss on any pump breaks it.
## Serves: Mastery. Refs #7, #3

signal multiplier_changed(multiplier: int)
signal combo_broken(lost_multiplier: int)
## Every Good-or-better stop, with how many good stops in a row so far (drives the chord progression, #10).
signal chained(length: int, tier: String)

@export var tiers: ScoreTiers = ScoreTiers.new()
@export var max_multiplier := 5

var multiplier := 1
## Good-or-better stops in a row. Keeps counting past the multiplier cap.
var chain_length := 0


## Updates the chain for one stop and returns the multiplier that stop is paid at.
## A good stop is paid at the current multiplier, then grows it; a bad stop is paid x1 and resets.
func register(tier: String) -> int:
	if tiers.extends_combo(tier):
		var paid := multiplier
		chain_length += 1
		chained.emit(chain_length, tier)
		if multiplier < max_multiplier:
			multiplier += 1
			multiplier_changed.emit(multiplier)
		return paid
	chain_length = 0
	if multiplier > 1:
		combo_broken.emit(multiplier)
		multiplier = 1
		multiplier_changed.emit(multiplier)
	return 1


## Back to x1 without counting as a broken chain (e.g. a new day).
func reset() -> void:
	multiplier = 1
	chain_length = 0
	multiplier_changed.emit(multiplier)
