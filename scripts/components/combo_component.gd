class_name ComboComponent
extends Node
## Chains good stops into a multiplier so every stop has something to lose.
## Its own component so the station keeps one combo across all pumps later. Serves: Mastery. Refs #7

signal multiplier_changed(multiplier: int)
signal combo_broken(lost_multiplier: int)
signal scored(points: int, total: int)

@export var tiers: ScoreTiers = ScoreTiers.new()
@export var max_multiplier := 5

var multiplier := 1
var total_score := 0


## Scores one stop and updates the chain. Returns the points awarded.
## A good stop pays at the current multiplier, then grows it; a bad stop pays x1 and resets.
func register(tier: String) -> int:
	var points: int
	if tiers.extends_combo(tier):
		points = tiers.points_for(tier) * multiplier
		if multiplier < max_multiplier:
			multiplier += 1
			multiplier_changed.emit(multiplier)
	else:
		points = tiers.points_for(tier)
		if multiplier > 1:
			combo_broken.emit(multiplier)
			multiplier = 1
			multiplier_changed.emit(multiplier)
	total_score += points
	scored.emit(points, total_score)
	return points
