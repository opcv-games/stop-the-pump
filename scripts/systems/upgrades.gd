class_name Upgrades
extends RefCounted
## The cash upgrade tree, bought each night (Bills-style). Five branches; each is bought in order.
## Upgrades cost cash only, never a gameplay downside, and never replace skill (design rule 1).
## They last for the run and are wiped on eviction. Serves: Advancement. Refs #15

const BRANCHES := [
	{"id": "marketing", "name": "MARKETING", "nodes": [
		{"id": "flyers", "name": "Flyers", "helps": "cars arrive 20% sooner", "price": 80.0},
		{"id": "radio_ad", "name": "Radio ad", "helps": "cars arrive 20% sooner", "price": 150.0},
		{"id": "billboard", "name": "Billboard", "helps": "$50 and $60 orders", "price": 220.0},
	]},
	{"id": "pumps", "name": "PUMPS", "nodes": [
		{"id": "turbo", "name": "Turbo nozzle", "helps": "pump 1 pours 30% faster", "price": 120.0},
		{"id": "extra_pump", "name": "Extra pump", "helps": "one more pump", "price": 250.0},
		{"id": "turbo_all", "name": "Turbo everywhere", "helps": "every pump pours 30% faster", "price": 300.0},
		{"id": "another_pump", "name": "Another pump", "helps": "one more pump", "price": 400.0},
	]},
	{"id": "tank", "name": "TANK", "nodes": [
		{"id": "tank_1", "name": "Bigger tank", "helps": "+100 L", "price": 150.0},
		{"id": "tank_2", "name": "Bigger tank II", "helps": "+100 L", "price": 250.0},
		{"id": "tank_3", "name": "Bigger tank III", "helps": "+100 L", "price": 350.0},
	]},
	{"id": "service", "name": "SERVICE", "nodes": [
		{"id": "squeegee", "name": "Squeegee", "helps": "car cleaning takes 2 s", "price": 80.0},
		{"id": "tip_jar", "name": "Tip jar", "helps": "+$2 tip on Good or better", "price": 120.0},
		{"id": "pressure_washer", "name": "Pressure washer", "helps": "car cleaning takes 1 s", "price": 180.0},
	]},
	{"id": "vibe", "name": "VIBE", "nodes": [
		{"id": "bluesy_radio", "name": "Bluesy radio", "helps": "max combo +1", "price": 150.0},
		{"id": "jukebox", "name": "Jukebox", "helps": "max combo +1", "price": 300.0},
	]},
]

const TURBO := 1.3


## The next upgrade to buy in a branch, or {} when the branch is complete.
static func next_node(station: Node, branch: int) -> Dictionary:
	var b: Dictionary = BRANCHES[branch]
	var level: int = station.owned.get(b.id, 0)
	return b.nodes[level] if level < b.nodes.size() else {}


static func next_price(station: Node, branch: int) -> float:
	var node := next_node(station, branch)
	return roundf(node.price * station.shop_price_scale) if node else 0.0


static func apply(station: Node, id: String) -> void:
	match id:
		"flyers", "radio_ad":
			station.arrival_min *= 0.8
			station.arrival_max *= 0.8
		"billboard":
			for order in [50.0, 60.0]:
				if not station.possible_targets.has(order):
					station.possible_targets.append(order)
		"turbo":
			station.bays[0].set_turbo(TURBO)
		"extra_pump", "another_pump":
			station.add_pump()
		"turbo_all":
			station.turbo_everywhere = true
			for bay in station.bays:
				bay.set_turbo(TURBO)
		"tank_1", "tank_2", "tank_3":
			station.tank.capacity_liters += 100.0  # filled at the next morning's refill
		"squeegee":
			station.cleaning_seconds = 2.0
		"tip_jar":
			station.economy.tip_bonus = 2.0
		"pressure_washer":
			station.cleaning_seconds = 1.0
		"bluesy_radio", "jukebox":
			station.combo.max_multiplier += 1
	station.apply_tuning()
