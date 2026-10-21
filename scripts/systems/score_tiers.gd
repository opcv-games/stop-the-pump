class_name ScoreTiers
extends Resource
## Turns "how far from the target did the pump stop?" into a tier.
## A Resource so the windows can be tuned in the inspector during playtests. Serves: Mastery.

const SUPER_PERFECT := "Super Perfect"
const PERFECT := "Perfect"
const GOOD := "Good"
const OK := "OK"
const MISS := "Miss"  # GOD PUMP: overfilled (shown as "Overfilled")
## GOD PUMP: a customer who left under 80% (out of patience, or still waiting at closing).
const UNSERVED := "Unserved"

## Max distance from the target, in dollars, for each tier (over or under).
## Super Perfect = the best possible frame: at $4/s and 60 fps the meter moves ~7 cents a frame,
## so +/-3 cents is "released on the right frame" (#12). The display then snaps to the target.
@export var super_window := 0.03
@export var perfect_window := 0.10
@export var good_window := 0.50
@export var ok_window := 1.00


func evaluate(final_amount: float, target: float) -> String:
	var distance := absf(final_amount - target)
	# Small epsilon so 20.05 vs 20.00 isn't lost to float rounding at a window edge.
	if distance <= super_window + 0.0001:
		return SUPER_PERFECT
	if distance <= perfect_window + 0.0001:
		return PERFECT
	if distance <= good_window + 0.0001:
		return GOOD
	if distance <= ok_window + 0.0001:
		return OK
	return MISS


## Good or better keeps a combo alive.
func extends_combo(tier: String) -> bool:
	return tier == SUPER_PERFECT or tier == PERFECT or tier == GOOD
