class_name Customers
extends RefCounted
## Who pulls in. Design rule 2: every type changes one variable of the micro loop; their lines are
## flavour on top (Comedy). Weights are relative among the special types. Refs #5

const TYPES := {
	"regular": {
		"name": "Regular", "car": Color(0.45, 0.52, 0.62),
		"hello": ["{t} on this one, thanks.", "{t}, please.", "Just {t} today.", "{t}. Nice night for it."],
	},
	"twenty_guy": {
		"name": "$20 Guy", "car": Color(0.36, 0.56, 0.36), "weight": 1.0,
		"hello": ["I've only got a twenty. Not a cent more!", "Twenty bucks. Exactly twenty.", "One crumpled twenty. That's it."],
	},
	"grandpa": {
		"name": "Confused Grandpa", "car": Color(0.72, 0.64, 0.48), "weight": 1.0,
		"hello": ["{t} of regular, sonny.", "{t}... I think. Yes. {t}.", "My wife said {t}."],
		"changed": ["Wait... make that {t}. Or was it diesel?", "Hold on, she said {t}!", "Did I say that? I meant {t}."],
	},
	"businessman": {
		"name": "Impatient Businessman", "car": Color(0.36, 0.38, 0.48), "weight": 1.0,
		"hello": ["{t}. I have a meeting.", "{t}. Chop chop.", "{t}, and I'm timing you."],
		"honk": ["*HONK*", "*HONK HONK*", "Any day now!"],
		"left": ["Forget it!", "I'll go to the place across the street.", "Unbelievable."],
	},
}

## Reaction after the stop, by tier. Type-specific lines win when they exist.
const REACTIONS := {
	ScoreTiers.SUPER_PERFECT: ["To the cent. Respect.", "Now THAT is service."],
	ScoreTiers.PERFECT: ["Nice.", "Right on."],
	ScoreTiers.GOOD: ["Close enough.", "Thanks."],
	ScoreTiers.OK: ["Hm.", "If you say so."],
	ScoreTiers.MISS: ["Seriously?", "That's not what I asked."],
}
const TWENTY_GUY_OVER := ["That's coming out of YOUR pocket.", "I said a twenty!"]


## Picks the next customer: a Regular, or (with `special_chance`) one of the special types.
static func roll(special_chance: float, targets: Array) -> Dictionary:
	var type := "regular"
	if randf() < special_chance:
		var total := 0.0
		for id in TYPES:
			total += TYPES[id].get("weight", 0.0)
		var pick := randf() * total
		for id in TYPES:
			pick -= TYPES[id].get("weight", 0.0)
			if TYPES[id].get("weight", 0.0) > 0.0 and pick <= 0.0:
				type = id
				break
	var target: float = 20.0 if type == "twenty_guy" else targets.pick_random()
	return {"type": type, "target": target}


static func line(type: String, key: String, target := 0.0) -> String:
	var lines: Array = TYPES[type].get(key, [])
	if lines.is_empty():
		return ""
	return (lines.pick_random() as String).replace("{t}", "$%.0f" % target)


static func reaction(type: String, tier: String, overshoot: float) -> String:
	if type == "twenty_guy" and overshoot > 0.004:
		return TWENTY_GUY_OVER.pick_random()
	return REACTIONS[tier].pick_random()
