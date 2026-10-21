class_name Visitors
extends RefCounted
## The lore, told at the gaz bar (round 9, designer: "the paper is too much info; bring new characters
## to the gas station and chit-chat"). On set days a visitor drives in, parks by the store and trades a
## few lines with the regulars in speech bubbles, then drives off: Gaétan from across the road, Sylvie
## (Mme Gagnon's niece), Me Tremblay the nervous notary, cousin Réjean, the curé, and the mail carrier,
## who brings Dad's postcards (days 10, 20, 30, 40, signed "un pêcheur"). Pure data; GodPump plays it.
## Serves: the story, Comedy. The lore bible: docs/LORE.md.

## Who visits: their name in the bubbles and the car they drive (a sprite stack).
const CAST := {
	"gaetan": {"name": "Gaétan", "stack": "green"},
	"sylvie": {"name": "Sylvie", "stack": "cream"},
	"tremblay": {"name": "Me Tremblay", "stack": "purple"},
	"rejean": {"name": "Cousin Réjean", "stack": "red"},
	"cure": {"name": "The curé", "stack": "white"},
	"facteur": {"name": "The mail carrier", "stack": "blue"},
}

## Dad's postcards: [day, from, picture sprite]. The mail carrier reads them out.
const POSTCARDS := [
	[10, "Lac-à-la-Truite", "postcard_truite"],
	[20, "Lac Saint-Jean", "postcard_st_jean"],
	[30, "Gaspésie", "postcard_gaspesie"],
	[40, "Florida", "postcard_floride"],
]

## The visits, by day: who comes, and the lines (speaker: a CAST id or a regular's name).
const BEATS := [
	{"day": 2, "who": "gaetan", "lines": [["gaetan", "Gaétan, from across the road. Nice pump, kid."],
		["tiguy", "Your gas costs 19 cents more, Gaétan."], ["gaetan", "Quality costs money."]]},
	{"day": 4, "who": "sylvie", "lines": [["sylvie", "Hi! I'm Sylvie, Mme Gagnon's niece."],
		["gagnon", "She's single. Just saying."], ["legrand", "Is HE single, though?"]]},
	{"day": 6, "who": "tremblay", "lines": [["tremblay", "Just checking the gaz bar is in good hands."],
		["bertrand", "You look nervous, Tremblay."], ["tremblay", "Me? No. Why? Who said that?"]]},
	{"day": 8, "who": "rejean", "lines": [["rejean", "Cousin Réjean! I hear you need someone for nights."],
		["gagnon", "He sleeps on the job."], ["rejean", "Only at night."]]},
	{"day": 10, "who": "facteur", "postcard": 10, "lines": [["facteur", "A postcard for the kid! From Lac-à-la-Truite."],
		["facteur", "\"The fish are biting. Don't spill.\" Signed: un pêcheur."], ["tiguy", "A fisherman, eh? I KNEW it."]]},
	{"day": 12, "who": "cure", "lines": [["cure", "Bless this pump, my child."],
		["cure", "Your father always closed at 11. To go fishing, he said."], ["bertrand", "He said a lot of things."]]},
	{"day": 15, "who": "tremblay", "lines": [["tremblay", "Has anyone received any mail lately?"],
		["gagnon", "Why do you ask, Maître?"], ["tremblay", "No reason. Lovely weather. Goodbye."]]},
	{"day": 18, "who": "gaetan", "lines": [["gaetan", "Business is slow across the road."],
		["legrand", "Lower your prices, Gaétan."], ["gaetan", "Never."]]},
	{"day": 20, "who": "facteur", "postcard": 20, "lines": [["facteur", "Another postcard! From Lac Saint-Jean."],
		["facteur", "\"Heard the gaz bar's busy. Not bad, kid.\" Un pêcheur."], ["gagnon", "How does a fisherman know about our gaz bar?"]]},
	{"day": 23, "who": "sylvie", "lines": [["sylvie", "My aunt says you're getting good at this."],
		["gagnon", "I did say that."], ["sylvie", "She also says you're single."]]},
	{"day": 26, "who": "cure", "lines": [["cure", "Bertrand bought a bus ticket to Gaspésie. Did you know?"],
		["bertrand", "A man is allowed a vacation."]]},
	{"day": 30, "who": "facteur", "postcard": 30, "lines": [["facteur", "From Gaspésie! \"Your prices are too cheap. Keep the coffee hot.\""],
		["tiguy", "He knows our prices! He's been HERE!"], ["bertrand", "Calm down, Ti-Guy."]]},
	{"day": 34, "who": "tremblay", "lines": [["tremblay", "I may have misplaced a death certificate."],
		["gagnon", "MISPLACED?"], ["tremblay", "Forget I said anything."]]},
	{"day": 37, "who": "rejean", "lines": [["rejean", "Saw an orange hatchback at the rest stop. A fishing rod out the window."],
		["tiguy", "THAT'S HIM!"]]},
	{"day": 40, "who": "facteur", "postcard": 40, "lines": [["facteur", "From Florida! \"Sunburnt. Bored. Out of worms. See you soon.\""],
		["gagnon", "See you SOON?"], ["bertrand", "Better keep the coffee hot, kid."]]},
	{"day": 45, "who": "gaetan", "lines": [["gaetan", "Word is your father's coming home."],
		["gaetan", "He still owes me $20 for worms."]]},
]


## Today's visit, or {} on a day nobody comes.
static func beat_for(day: int) -> Dictionary:
	for b in BEATS:
		if b.day == day:
			return b
	return {}


## The name to show for a speaker (a visitor's, or a regular's full name).
static func speaker_name(id: String) -> String:
	if CAST.has(id):
		return CAST[id].name
	return RegularsCrew.FULL_NAMES.get(id, id)
