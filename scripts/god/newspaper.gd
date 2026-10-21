class_name Newspaper
extends RefCounted
## L'Écho de Saint-Clin-Clin (round 8): the village's morning paper, about yesterday at your gaz bar.
## The headline and story come from yesterday's day report; Mme Gagnon's gossip column carries the lore
## (the town wonders about the kid, and about his father), unlocking day by day; the classified ads
## tease upgrades you don't own yet; Dad's postcards arrive on days 10, 20, 30 and 40, signed
## "un pêcheur". Pure: the same run and report always write the same paper. Serves: Comedy and the
## story; Advancement (yesterday made the news).
##
## English with French names and quotes, like the rest of the game (DESIGN.md, decision log).

const WEEKDAYS := ["MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY", "SUNDAY"]
const WEATHER := ["Sunny, 22°", "Cloudy, 17°", "Light rain, 14°", "Hot and humid, 29°", "Fog on the rang, 12°",
	"Windy, 18°", "Clear skies, 24°", "Thunderstorms by suppertime, 21°"]

## The gossip column, by the day it first becomes possible.
const GOSSIP := [
	[1, "Bertrand says the old pump still has a few good years in it. \"Like me,\" he added."],
	[1, "Le Grand's band, Les Pistons, rehearses Thursday in the church basement. Earplugs recommended."],
	[2, "\"Ton père faisait pas ça,\" Ti-Guy said of the gas on the ground. Your father never spilled a drop, apparently."],
	[3, "Gaétan, across the road, raised his prices again. \"Competition,\" he says."],
	[5, "Ti-Guy swears he saw your father at Lac-à-la-Truite last week. \"I'm telling you, it was him. Same hat.\""],
	[7, "Le Grand wants to know: \"Y'é-tu célibataire, lui?\" The whole bench is wondering."],
	[9, "The notary, Me Tremblay, looked very nervous at the post office. He bought a lot of stamps."],
	[12, "The kid is getting good at this, says Bertrand. \"Better than his father.\" He then looked around, worried."],
	[15, "Someone keeps leaving fresh trout on the dépanneur's doorstep. Nobody knows who."],
	[18, "Me Tremblay declined to comment on \"certain matters regarding the late owner.\""],
	[22, "Is the kid seeing anyone? Asking for my niece, Sylvie. She's very nice. — Mme G."],
	[26, "Bertrand bought a new fishing rod and a bus ticket to Gaspésie. He won't say for whom."],
	[30, "A sunburnt man in an orange hatchback was spotted at the Lac Saint-Jean rest stop. He tipped well."],
	[35, "Ti-Guy is taking bets on \"the father's return.\" The odds are improving."],
	[40, "The church bells rang at 11 sharp yesterday. \"That's when he used to go fishing,\" said the curé."],
	[45, "Mme Gagnon has kept every one of the kid's headlines. \"For when his father gets back,\" she says."],
]

## Dad's postcards: [day, from, text, picture sprite].
const POSTCARDS := [
	[10, "Lac-à-la-Truite", "The fish are biting. Hope the old pump is behaving. Don't spill.", "postcard_truite"],
	[20, "Lac Saint-Jean", "Heard the gaz bar's busy again. Not bad, kid. Not bad.", "postcard_st_jean"],
	[30, "Gaspésie", "Saw your price sign from the bus. You're too cheap. Keep the coffee hot.", "postcard_gaspesie"],
	[40, "Floride", "Sunburnt. Bored. Running out of worms. See you soon.", "postcard_floride"],
]


static func weekday(day: int) -> String:
	return WEEKDAYS[(day - 1) % 7]


## The paper for the morning of `run.day`, about `report` (yesterday).
static func edition(run: RunState, meta: MetaState, report: Dictionary) -> Dictionary:
	var day := run.day
	var r := RandomNumberGenerator.new()
	r.seed = hash([day, run.deliveries, int(run.totals.loot)])
	var lead := _lead(report, r)
	var out := {
		"day": day, "weekday": weekday(day), "headline": lead.headline, "sub": lead.sub, "photo": lead.photo,
		"story": _story(report, run), "gossip": _gossip(day, r), "ads": _ads(run, meta, r),
		"weather": WEATHER[(day * 5 + 3) % WEATHER.size()], "price": run.price, "prices": run.price_history.duplicate(),
		"cash": run.cash_history.duplicate(), "days_of_gas": run.days_of_gas(), "postcard": postcard(day),
		"hockey_tonight": "hockey" in run.links and day % 7 == 0, "kind": lead.kind,
	}
	return out


static func postcard(day: int) -> Dictionary:
	for p in POSTCARDS:
		if p[0] == day:
			return {"day": p[0], "from": p[1], "text": p[2], "picture": p[3]}
	return {}


## The front page: the most newsworthy thing about yesterday. {kind, headline, sub, photo}.
static func _lead(rep: Dictionary, r: RandomNumberGenerator) -> Dictionary:
	var t: Dictionary = rep.get("tiers", {})
	var supers: int = t.get(ScoreTiers.SUPER_PERFECT, 0)
	var over: int = t.get(ScoreTiers.MISS, 0)
	var unserved: int = t.get(ScoreTiers.UNSERVED, 0)
	var cars: int = rep.get("cars", 0)
	var loot: float = rep.get("loot", 0.0)
	var combo: int = rep.get("best_combo", 1)
	var grabs: int = rep.get("tube_grabs", 0)
	var options := [[10, "quiet", "QUIET DAY IN SAINT-CLIN-CLIN", "%d cars, $%d in the till. The cows were unimpressed." % [cars, int(loot)], "storefront"]]
	if rep.get("out_of_gas", false):
		options.append([100, "dry", "THE PUMP RAN DRY", "Drivers turned away. Bertrand: \"Call the truck, mon grand.\"", "gas_tank"])
	if rep.get("hockey", false):
		options.append([90, "hockey", "HOCKEY NIGHT: THE WHOLE PARISH FILLED UP", "%d cars before the puck dropped." % cars, "prop_hockey_net"])
	if supers >= 4:
		options.append([80 + supers, "supers", "%d CARS TOPPED OFF TO THE CENT" % supers, "\"Y'a du talent, le jeune,\" says Ti-Guy.", "tiguy_cheer"])
	if combo >= 4:
		options.append([75, "combo", "THE KID IS ON FIRE: COMBO ×%d" % combo, "The regulars ran out of applause.", "gagnon_cheer"])
	if over >= 3:
		options.append([72 + over, "spills", "GAS ALL OVER THE LOT AGAIN", "%d cars overfilled. The town council is \"concerned.\"" % over, "puddle_l"])
	if unserved >= 3:
		options.append([71 + unserved, "unserved", "%d DRIVERS GAVE UP WAITING" % unserved, "\"Y dort-tu, le p'tit?\" asks Mme Gagnon.", "legrand_stand"])
	if grabs >= 2:
		options.append([70, "tube", "INFLATABLE MAN SNATCHES %d CARS ON THE 132" % grabs, "Police \"looking into it.\" The man was unavailable for comment.", "tube_man_grab"])
	if rep.get("stolen", 0.0) > 5.0:
		options.append([68, "thief", "THIEF SIPHONS $%d FROM CUSTOMERS" % int(rep.stolen), "Witnesses describe \"a black car, very rude.\"", "badge_thief"])
	if rep.get("fines", 0.0) > 0.0:
		options.append([66, "electric", "ELECTRIC CAR OWNER FILES COMPLAINT", "\"He poured gas on my car,\" says the owner.", "stack_electric_4"])
	if loot >= 300.0:
		options.append([60, "record", "BIG DAY AT THE GAZ BAR: $%d" % int(loot), "Gaétan, across the road, \"not worried.\"", "storefront"])
	var best: Array = options[0]
	for o in options:
		if o[0] > best[0]:
			best = o
	return {"kind": best[1], "headline": best[2], "sub": best[3], "photo": best[4]}


static func _story(rep: Dictionary, run: RunState) -> String:
	var t: Dictionary = rep.get("tiers", {})
	var cars: int = rep.get("cars", 0)
	var supers: int = t.get(ScoreTiers.SUPER_PERFECT, 0)
	var perfects: int = t.get(ScoreTiers.PERFECT, 0)
	var s := "The new owner of the gaz bar on the 132 served %d cars yesterday" % cars
	s += (", %d of them topped off to the cent and %d more near perfect." % [supers, perfects]) if supers + perfects > 0 else "."
	s += " Takings: $%d." % int(rep.get("loot", 0.0))
	var wasted: float = rep.get("wasted", 0.0)
	if wasted > 1.0:
		s += " About $%d of gas ended up on the ground." % int(wasted)
	if rep.get("tube_gas", 0.0) > 0.0:
		s += " An inflatable man by the road brought in $%d of gas, by unusual means." % int(rep.tube_gas)
	s += " The tank holds about %.1f days of gas; the truck charges $%.2f a litre." % [run.days_of_gas(), run.price]
	return s


## Two items from Mme Gagnon's column: the newest rumour unlocked, and an older one.
static func _gossip(day: int, r: RandomNumberGenerator) -> Array:
	var open := GOSSIP.filter(func(g: Array) -> bool: return g[0] <= day)
	var newest: Array = open[-1]
	var older := open.filter(func(g: Array) -> bool: return g != newest)
	var out := [newest[1] if day - newest[0] < 3 or older.is_empty() else open[r.randi() % open.size()][1]]
	if not older.is_empty():
		var pick: String = older[r.randi() % older.size()][1]
		if pick != out[0]:
			out.append(pick)
	return out


## Two classified ads: something you could buy next, and a car type or a Garage item coming.
static func _ads(run: RunState, meta: MetaState, r: RandomNumberGenerator) -> Array:
	var ads := []
	var options := []
	for b in GodData.BRANCHES:
		var n := run.next_node(b.id)
		if not n.is_empty():
			options.append("FOR SALE: %s. %s. $%d, ask at the gaz bar." % [n.name, n.helps[0].to_upper() + n.helps.substr(1), int(run.node_price(n))])
	if not options.is_empty():
		ads.append(options[r.randi() % options.size()])
	var nxt := meta.next_unlock() if meta else {}
	if not nxt.is_empty() and float(nxt.have) / nxt.need >= 0.7:
		ads.append("WARNING TO DRIVERS: %s spotted on the 132. — Ti-Guy" % nxt.name)
	elif meta and meta.perk_tiers.get("tube_man", 0) == 0:
		ads.append("WANTED: inflatable man, 20 ft, must dance. Inquire at Papa's Garage.")
	elif run.day >= 15:
		ads.append("LOST: one father. Answers to \"Papa\". Last seen with a fishing rod. Do not call the notary.")
	else:
		ads.append("FOR SALE: worms. Fresh. Ask Bertrand.")
	return ads
