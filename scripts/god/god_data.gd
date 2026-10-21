class_name GodData
extends RefCounted
## Everything GOD PUMP can own, as data (docs/GOD_PUMP_PLAN.md): the night shop's branches, the
## fuel-truck cards, the car types, and Papa's Garage (nozzles, bling, perks). Each item carries `fx`:
## effects that GodMods adds up into the numbers a day runs on. Keeping it all here means balance is a
## data edit, and the bot plays exactly what the player plays. Serves: Advancement.

## How each effect combines: "add" sums, "mul" multiplies, "max" keeps the largest.
const FX_OPS := {
	"close_hour": "max", "queue": "add", "customer_chance": "add", "per_car_bonus": "add",
	"perfect_bonus": "add", "topoff_bonus": "add", "stream_radius": "add", "auto_aim": "add", "drones": "add",
	"combo_max": "add", "applause_bonus": "add", "loto_chance": "add", "luck": "add", "start_cash": "add",
	"tank_capacity": "add", "flow_mult": "mul", "tip_mult": "mul", "patience_mult": "mul", "spill_mult": "mul",
	"happy_hour": "max", "twin_stream": "max", "golden_chance": "add", "recycle": "max", "first_car_tip_mult": "max",
	"combo_lock": "max", "overfill_saves": "add", "refund_every": "max", "upgrade_discount": "add",
	"jackpot_chance": "add", "first_delivery_discount": "add", "cards_offered": "add", "rerolls": "add",
	"bling_slots": "add", "price_rise_mult": "mul", "sale_mult": "mul",
	# round 8: the CAMION branch and the upgrades with two parents
	"tank_alarm": "max", "bulk_discount": "add", "partial_rise_mult": "mul", "freeze_every": "max",
	"coffee_sale": "add", "hockey_every": "max", "loyalty_every": "max", "night_tip_mult": "mul",
	"drone_bonus": "add",
}

## The defaults a day runs on before anything is bought.
const BASE := {
	"close_hour": 13.0, "queue": 0, "customer_chance": 0.5, "per_car_bonus": 0.0, "perfect_bonus": 0.0,
	"topoff_bonus": 2.0, "stream_radius": 0.0, "auto_aim": 0.0, "drones": 0, "combo_max": 5, "applause_bonus": 0.0,
	"loto_chance": 0.0, "luck": 0.0, "start_cash": 60.0, "tank_capacity": 700.0, "flow_mult": 1.0,
	"tip_mult": 1.0, "patience_mult": 1.0, "spill_mult": 1.0, "happy_hour": 0, "twin_stream": 0,
	"golden_chance": 0.0, "recycle": 0, "first_car_tip_mult": 1.0, "combo_lock": 0, "overfill_saves": 0,
	"refund_every": 0, "upgrade_discount": 0.0, "jackpot_chance": 0.0, "first_delivery_discount": 0.0,
	"cards_offered": 3, "rerolls": 0, "bling_slots": 1, "price_rise_mult": 1.0, "sale_mult": 1.0,
	"tank_alarm": 0, "bulk_discount": 0.0, "partial_rise_mult": 1.0, "freeze_every": 0, "coffee_sale": 0.0,
	"hockey_every": 0, "loyalty_every": 0, "night_tip_mult": 1.0, "drone_bonus": 0.0,
}

# --- The night shop (cash, always available) ----------------------------------------------------
const BRANCHES := [
	{"id": "hours", "name": "HEURES", "nodes": [
		{"id": "thermos", "name": "Thermos de café", "helps": "you stay awake: open until 14 h", "price": 60.0, "fx": {"close_hour": 14.0}},
		{"id": "mom_lunch", "name": "Maman fait le dîner", "helps": "Mom covers lunch: open until 16 h", "price": 140.0, "fx": {"close_hour": 16.0}},
		{"id": "permit", "name": "Permis du soir", "helps": "the council says yes: open until 19 h", "price": 260.0, "fx": {"close_hour": 19.0}},
		{"id": "cousin", "name": "Cousin Réjean de nuit", "helps": "open until 23 h", "price": 420.0, "fx": {"close_hour": 23.0}},
	]},
	{"id": "marketing", "name": "MARKETING", "nodes": [
		{"id": "flyers", "name": "Flyers", "helps": "+1 car waiting when you open", "price": 50.0, "fx": {"queue": 1}},
		{"id": "radio_ad", "name": "Pub à la radio", "helps": "+2 cars waiting when you open", "price": 120.0, "fx": {"queue": 2}},
		{"id": "billboard", "name": "Panneau", "helps": "+3 cars waiting, and more cars pull in", "price": 240.0, "fx": {"queue": 3, "customer_chance": 0.05}},
	]},
	{"id": "attractions", "name": "ATTRACTIONS", "nodes": [
		{"id": "traffic_light", "name": "Feu de circulation", "helps": "cars cut through your lot: more pull in", "price": 90.0, "fx": {"customer_chance": 0.15}},
		{"id": "grocery", "name": "Mini-épicerie", "helps": "every car also buys a snack: +$2", "price": 160.0, "fx": {"per_car_bonus": 2.0}},
		{"id": "car_wash", "name": "Lave-auto", "helps": "+$4 a car, and cars wait 30% longer", "price": 300.0, "fx": {"per_car_bonus": 4.0, "patience_mult": 1.3}},
		{"id": "loto", "name": "Machine à loto", "helps": "5% chance a car tips $20 more", "price": 380.0, "fx": {"loto_chance": 0.05}},
	]},
	{"id": "nozzle", "name": "PISTOLET", "nodes": [
		{"id": "wide", "name": "Bec large", "helps": "a wider stream: easier to land on a car", "price": 70.0, "fx": {"stream_radius": 12.0}},
		{"id": "aim_1", "name": "Visée auto I", "helps": "the stream bends toward a car nearby", "price": 130.0, "fx": {"auto_aim": 30.0}},
		{"id": "flow_1", "name": "Débit +", "helps": "the nozzle pours 20% faster", "price": 180.0, "fx": {"flow_mult": 1.2}},
		{"id": "aim_2", "name": "Visée auto II", "helps": "the stream bends from even further", "price": 260.0, "fx": {"auto_aim": 30.0}},
		{"id": "drone_1", "name": "Drone pistolet", "helps": "a little drone fills cars on its own", "price": 340.0, "fx": {"drones": 1}},
		{"id": "drone_2", "name": "Drone pistolet II", "helps": "a second drone", "price": 520.0, "fx": {"drones": 1}},
	]},
	{"id": "service", "name": "SERVICE", "nodes": [
		{"id": "tip_sign", "name": "Pancarte pourboire", "helps": "tips +20%", "price": 60.0, "fx": {"tip_mult": 1.2}},
		{"id": "squeegee", "name": "Raclette", "helps": "+$2 on a Perfect or better", "price": 140.0, "fx": {"perfect_bonus": 2.0}},
		{"id": "coffee", "name": "Café pour la file", "helps": "cars wait 30% longer", "price": 220.0, "fx": {"patience_mult": 1.3}},
	]},
	{"id": "vibe", "name": "AMBIANCE", "nodes": [
		{"id": "radio", "name": "Radio bluesy", "helps": "max combo +1", "price": 80.0, "fx": {"combo_max": 1}},
		{"id": "bench", "name": "Banc des habitués", "helps": "every applause from the regulars: +$1", "price": 170.0, "fx": {"applause_bonus": 1.0}},
		{"id": "jukebox", "name": "Juke-box", "helps": "max combo +1", "price": 300.0, "fx": {"combo_max": 1}},
	]},
	{"id": "tank", "name": "RÉSERVOIR", "nodes": [
		{"id": "tank_1", "name": "Gros réservoir", "helps": "the tank holds $200 more gas", "price": 120.0, "fx": {"tank_capacity": 200.0}},
		{"id": "tank_2", "name": "Gros réservoir II", "helps": "$200 more", "price": 240.0, "fx": {"tank_capacity": 200.0}},
		{"id": "tank_3", "name": "Gros réservoir III", "helps": "$300 more", "price": 400.0, "fx": {"tank_capacity": 300.0}},
	]},
	# Round 8: the truck itself. Plays on the tension between refuelling early (cards) and late (price).
	{"id": "truck", "name": "CAMION", "nodes": [
		{"id": "tank_gauge", "name": "Jauge d'alarme", "helps": "know to the hour how long the tank lasts, and get warned in the day", "price": 40.0, "fx": {"tank_alarm": 1}},
		{"id": "bulk", "name": "Achat en vrac", "helps": "a delivery costs 10% less when the tank is under 25%", "price": 150.0, "fx": {"bulk_discount": 0.10}},
		{"id": "used_tanker", "name": "Citerne usagée", "helps": "a partial delivery raises the price half as much", "price": 220.0, "fx": {"partial_rise_mult": 0.5}},
	]},
]

# --- Upgrades with two parents (round 8): each sits between two branches and unlocks once you own
# both of the upgrades it names in `needs`. The tree view places them (GodTreeView.LINK_CELLS).
const LINKS := [
	{"id": "drive_thru", "name": "Fenêtre au volant", "helps": "a car that waited over 3 s buys a coffee: +$1", "price": 150.0, "needs": ["coffee", "thermos"], "fx": {"coffee_sale": 1.0}},
	{"id": "hockey", "name": "Soirée du hockey", "helps": "every 7th day is hockey night: 3 more cars waiting, more cars pull in", "price": 200.0, "needs": ["mom_lunch", "radio"], "fx": {"hockey_every": 7}},
	{"id": "loyalty", "name": "Carte fidélité", "helps": "every 5th car is a regular who tips double", "price": 180.0, "needs": ["radio_ad", "tip_sign"], "fx": {"loyalty_every": 5}},
	{"id": "night_neons", "name": "Néons de nuit", "helps": "tips +30% after 19 h", "price": 320.0, "needs": ["permit", "jukebox"], "fx": {"night_tip_mult": 1.3}},
	{"id": "drone_hangar", "name": "Hangar à drones", "helps": "a drone fill earns $2 more", "price": 300.0, "needs": ["drone_1", "car_wash"], "fx": {"drone_bonus": 2.0}},
	{"id": "chip_truck", "name": "Cantine à patates", "helps": "a chip truck on the lot: cars wait 20% longer, every applause +$2", "price": 260.0, "needs": ["grocery", "bench"], "fx": {"patience_mult": 1.2, "applause_bonus": 2.0}},
	{"id": "price_board", "name": "Prix affiché", "helps": "a big price sign by the road: every sale pays 5% more", "price": 280.0, "needs": ["billboard", "tank_1"], "fx": {"sale_mult": 1.05}},
	{"id": "forward_contract", "name": "Contrat à terme", "helps": "every third delivery comes without a price rise", "price": 380.0, "needs": ["tank_2", "billboard"], "fx": {"freeze_every": 3}},
]

# --- Fuel-truck cards: choose 1 of 3 per delivery (luck raises the rarity) ----------------------
const CARDS := [
	{"id": "happy_hour", "name": "Happy hour", "rarity": "common", "helps": "tips ×2 for the first 2 hours of each day", "fx": {"happy_hour": 1}},
	{"id": "gas_saver", "name": "Économiseur", "rarity": "common", "helps": "spills are halved", "fx": {"spill_mult": 0.5}},
	{"id": "rush_hour", "name": "Heure de pointe", "rarity": "common", "helps": "+2 cars waiting every morning", "fx": {"queue": 2}},
	{"id": "gold_rush", "name": "Ruée vers l'or", "rarity": "common", "helps": "a top-off pays $4 more", "fx": {"topoff_bonus": 4.0}},
	{"id": "combo_lock", "name": "Combo béton", "rarity": "common", "helps": "an OK no longer breaks the combo", "fx": {"combo_lock": 1}},
	{"id": "fat_tips", "name": "Gros pourboires", "rarity": "common", "helps": "tips +35%", "fx": {"tip_mult": 1.35}},
	{"id": "twin_stream", "name": "Double jet", "rarity": "rare", "helps": "the stream fills two cars at once", "fx": {"twin_stream": 1}},
	{"id": "magnet", "name": "Pistolet aimanté", "rarity": "rare", "helps": "auto-aim reaches 60 further", "fx": {"auto_aim": 60.0}},
	{"id": "drone_card", "name": "Drone en prime", "rarity": "rare", "helps": "+1 drone nozzle", "fx": {"drones": 1}},
	{"id": "price_freeze", "name": "Gel des prix", "rarity": "rare", "helps": "the next delivery doesn't raise the gas price", "fx": {}},
	{"id": "encourage", "name": "Encouragements", "rarity": "rare", "helps": "every applause from the regulars: +$2", "fx": {"applause_bonus": 2.0}},
	{"id": "golden_hose", "name": "Boyau doré", "rarity": "legendary", "helps": "10% of fills are golden: tip ×3", "fx": {"golden_chance": 0.10}},
	{"id": "recycler", "name": "Recycleur", "rarity": "legendary", "helps": "spilled gas flows back into the tank", "fx": {"recycle": 1}},
	{"id": "devil", "name": "Pacte avec le diable", "rarity": "legendary", "helps": "tips ×2, but gas prices rise twice as fast", "fx": {"tip_mult": 2.0}},
	{"id": "loan", "name": "Prêt du cousin", "rarity": "legendary", "helps": "+$300 now; the next delivery costs 40% more", "fx": {}},
]
const RARITY_WEIGHT := {"common": 70.0, "rare": 25.0, "legendary": 5.0}

# --- Car types (unlocked by cars filled across all runs) -----------------------------------------
## customer: wants gas. fill_speed: how fast its tank takes fuel. pay: share of the sale it pays.
## tip: tip multiplier. speed: how fast it drives. orders: what it asks for. unlock: cars filled needed.
const CAR_TYPES := {
	"sedan": {"name": "Berline", "customer": true, "orders": [10.0, 15.0, 20.0, 25.0, 30.0], "unlock": 0, "weight": 10.0},
	"pickup": {"name": "Le Pick-up", "customer": true, "orders": [40.0, 50.0, 60.0], "pay": 0.8, "unlock": 30, "weight": 3.0},
	"cadillac": {"name": "Le Cadillac", "customer": true, "orders": [20.0, 30.0, 40.0], "tip": 2.0, "unlock": 90, "weight": 2.0},
	"bazou": {"name": "Le Bazou", "customer": true, "orders": [10.0, 15.0, 20.0], "fill_speed": 0.6, "unlock": 180, "weight": 2.5},
	"racer": {"name": "Le Char de course", "customer": true, "orders": [15.0, 20.0, 25.0], "speed": 2.2, "tip": 1.3, "unlock": 300, "weight": 2.0},
	"sweeper": {"name": "La Balayeuse", "customer": false, "role": "sweeper", "unlock": 450, "weight": 1.0},
	"thief": {"name": "Le Voleur", "customer": false, "role": "thief", "unlock": 650, "weight": 1.2},
	"clumsy": {"name": "Le Maladroit", "customer": true, "orders": [15.0, 20.0, 25.0], "role": "clumsy", "unlock": 900, "weight": 1.5},
	"electric": {"name": "L'Électrique", "customer": false, "role": "electric", "unlock": 1200, "weight": 1.5},
	# Day 50 only: Dad, in the old orange hatchback (never drawn from the pool).
	"papa": {"name": "Papa", "customer": true, "orders": [30.0], "tip": 5.0, "unlock": 1000000000, "weight": 0.0, "stack": "orange"},
}
const CAR_ORDER := ["sedan", "pickup", "cadillac", "bazou", "racer", "sweeper", "thief", "clumsy", "electric"]

# --- Papa's Garage: bought with XP, kept forever ------------------------------------------------
const NOZZLES := [
	{"id": "classique", "name": "Le Classique", "helps": "Dad's old nozzle. Honest.", "price": 0, "fx": {}},
	{"id": "douche", "name": "La Douche", "helps": "a wide shower head: stream +20, flow -20%", "price": 400, "fx": {"stream_radius": 20.0, "flow_mult": 0.8}},
	{"id": "laser", "name": "Le Laser", "helps": "flow +40%, top-off tips +50%", "price": 900, "fx": {"flow_mult": 1.4, "topoff_bonus": 1.0}},
	{"id": "lente", "name": "La Lente", "helps": "flow -30%, tips +30%: for the precise", "price": 700, "fx": {"flow_mult": 0.7, "tip_mult": 1.3}},
	{"id": "gros_calibre", "name": "Le Gros Calibre", "helps": "flow ×2. Good luck.", "price": 1500, "fx": {"flow_mult": 2.0}},
	{"id": "doree", "name": "La Dorée", "helps": "10% golden fills (tip ×3), flow +10%", "price": 3000, "fx": {"golden_chance": 0.1, "flow_mult": 1.1}},
]
const BLING := [
	{"id": "fuzzy_dice", "name": "Dés en minou", "helps": "luck +10", "price": 150, "fx": {"luck": 10.0}},
	{"id": "flame_decal", "name": "Flammes", "helps": "max combo +1", "price": 300, "fx": {"combo_max": 1}},
	{"id": "chrome_tip", "name": "Embout chromé", "helps": "flow +10%", "price": 250, "fx": {"flow_mult": 1.1}},
	{"id": "hula", "name": "Danseuse hula", "helps": "the first car of each day tips double", "price": 350, "fx": {"first_car_tip_mult": 2.0}},
	{"id": "pine", "name": "Sapin parfumé", "helps": "cars wait 20% longer", "price": 200, "fx": {"patience_mult": 1.2}},
	{"id": "medal", "name": "Médaille de saint Christophe", "helps": "once a day, an overfill doesn't break the combo", "price": 500, "fx": {"overfill_saves": 1}},
	{"id": "rabbit", "name": "Patte de lapin", "helps": "every 10th car's gas goes back in the tank", "price": 800, "fx": {"refund_every": 10}},
	{"id": "bobblehead", "name": "Bobblehead", "helps": "+5% tip per combo level", "price": 600, "fx": {}},
	{"id": "coupons", "name": "Livret de coupons", "helps": "shop upgrades 10% cheaper", "price": 450, "fx": {"upgrade_discount": 0.10}},
	{"id": "receipt", "name": "Vieux reçu", "helps": "start each run with $50 more", "price": 300, "fx": {"start_cash": 50.0}},
]
## Perks have tiers; each tier costs more (price × tier).
const PERKS := [
	{"id": "truck_friend", "name": "Ami du camionneur", "helps": "the first delivery of each run costs 25% less", "price": 300, "tiers": 2, "fx": {"first_delivery_discount": 0.25}},
	{"id": "lucky", "name": "Bonne étoile", "helps": "luck +5", "price": 250, "tiers": 4, "fx": {"luck": 5.0}},
	{"id": "big_cards", "name": "Plus de choix", "helps": "4 cards per delivery", "price": 1200, "tiers": 1, "fx": {"cards_offered": 1}},
	{"id": "reroll", "name": "Rebrasser", "helps": "1 reroll per delivery", "price": 600, "tiers": 2, "fx": {"rerolls": 1}},
	{"id": "morning_rush", "name": "Rush du matin", "helps": "+1 car waiting when you open", "price": 400, "tiers": 3, "fx": {"queue": 1}},
	{"id": "jackpot", "name": "Jackpot", "helps": "3% of fills tip ×4", "price": 700, "tiers": 2, "fx": {"jackpot_chance": 0.03}},
	{"id": "slot", "name": "Place pour bling", "helps": "one more bling slot", "price": 500, "tiers": 2, "fx": {"bling_slots": 1}},
	{"id": "head_start", "name": "Longueur d'avance", "helps": "start each run with a drone nozzle", "price": 2000, "tiers": 1, "fx": {"drones": 1}},
	{"id": "contract", "name": "Contrat du fournisseur", "helps": "gas prices rise 20% slower", "price": 350, "tiers": 3, "fx": {"price_rise_mult": 0.8}},
	{"id": "premium", "name": "Super sans plomb", "helps": "premium gas: every sale pays 10% more", "price": 350, "tiers": 3, "fx": {"sale_mult": 1.1}},
	{"id": "nest_egg", "name": "Bas de laine", "helps": "start each run with $40 more", "price": 200, "tiers": 3, "fx": {"start_cash": 40.0}},
]

## The day the story ends: Dad drives in.
const FINAL_DAY := 50
## A game hour lasts this many real seconds (7 h to 13 h = 27 s; to 23 h = 72 s).
const HOUR_SECONDS := 4.5
const OPEN_HOUR := 7.0
## Gas price: pump price per litre, and the wholesale price the truck starts at, rising per delivery.
const PUMP_PRICE := 2.0
const WHOLESALE_START := 1.2  # balance bot (#37): fresh runs reach about day 13
const PRICE_RISE := 0.25  # balance bot campaign (#37): day 50 takes about 2 h of Garage upgrades


static func branch(id: String) -> Dictionary:
	for b in BRANCHES:
		if b.id == id:
			return b
	return {}


static func link(id: String) -> Dictionary:
	for l in LINKS:
		if l.id == id:
			return l
	return {}


## Any shop upgrade by id (a branch node or a link), or {}.
static func shop_node(id: String) -> Dictionary:
	for b in BRANCHES:
		for n in b.nodes:
			if n.id == id:
				return n
	return link(id)


static func card(id: String) -> Dictionary:
	for c in CARDS:
		if c.id == id:
			return c
	return {}


static func item(list: Array, id: String) -> Dictionary:
	for i in list:
		if i.id == id:
			return i
	return {}


## Adds one item's effects into `mods`, following FX_OPS.
static func apply_fx(mods: Dictionary, fx: Dictionary, times := 1) -> void:
	for k in fx:
		for t in times:
			match FX_OPS.get(k, "add"):
				"add":
					mods[k] = mods.get(k, 0) + fx[k]
				"mul":
					mods[k] = mods.get(k, 1.0) * fx[k]
				"max":
					mods[k] = maxf(mods.get(k, 0.0), fx[k])
