class_name Upgrades
extends RefCounted
## The night shop's run upgrades, bought with cash. Every one helps and costs something
## (design rule 1). They last for the run and are wiped on eviction. Serves: Advancement. Refs #14

const LIST := [
	{"id": "bigger_tank", "name": "Bigger tank", "helps": "+100 L in the tank", "downside": "rent +$20 a day", "price": 150.0, "max": 3},
	{"id": "turbo", "name": "Turbo nozzle", "helps": "one pump pours 30% faster", "downside": "harder to stop precisely", "price": 120.0, "max": 10},
	{"id": "flyers", "name": "Flyers", "helps": "cars arrive 30% sooner", "downside": "$50 and $60 orders join in", "price": 100.0, "max": 2},
	{"id": "extra_pump", "name": "Extra pump", "helps": "one more pump", "downside": "rent +$40 a day", "price": 250.0, "max": 3},
	{"id": "squeegee", "name": "Squeegee", "helps": "car cleaning takes 2 s", "downside": "$5 per cleaning", "price": 80.0, "max": 1},
	{"id": "tip_jar", "name": "Tip jar", "helps": "+$2 on Good or better", "downside": "-$2 on OK or Miss", "price": 100.0, "max": 1},
	{"id": "radio", "name": "Bluesy radio", "helps": "max combo +1", "downside": "Good window 10% narrower", "price": 150.0, "max": 1},
]


static func info(id: String) -> Dictionary:
	for u in LIST:
		if u.id == id:
			return u
	return {}


static func price(station: Node, id: String) -> float:
	return roundf(info(id).price * station.shop_price_scale)


## Upgrades the station can still take (not maxed out, and there is something left to improve).
static func available(station: Node) -> Array[String]:
	var ids: Array[String] = []
	for u in LIST:
		if station.owned.get(u.id, 0) >= u.max:
			continue
		if u.id == "extra_pump" and station.bays.size() >= 10:
			continue
		if u.id == "turbo" and station.owned.get("turbo", 0) >= station.bays.size():
			continue
		ids.append(u.id)
	return ids


static func apply(station: Node, id: String) -> void:
	match id:
		"bigger_tank":
			station.tank.capacity_liters += 100.0  # filled at the next morning's refill
			station.economy.rent_extra += 20.0
		"turbo":
			for bay in station.bays:
				if bay.flow_multiplier == 1.0:
					bay.set_turbo(1.3)
					break
		"flyers":
			station.arrival_min *= 0.7
			station.arrival_max *= 0.7
			for order in [50.0, 60.0]:
				if not station.possible_targets.has(order):
					station.possible_targets.append(order)
		"extra_pump":
			station.add_pump()
			station.economy.rent_extra += 40.0
		"squeegee":
			station.cleaning_seconds = 2.0
			station.cleaning_fee = 5.0
		"tip_jar":
			station.economy.tip_bonus = 2.0
		"radio":
			station.combo.max_multiplier += 1
			station.combo.tiers.good_window *= 0.9
	station.apply_tuning()
