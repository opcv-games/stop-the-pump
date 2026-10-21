class_name Tuning
extends RefCounted
## Every gameplay number the designer can tune, where it lives, and its slider range.
## Saved to a config file so tuning survives restarts; "Copy values" pastes them to Claude. Refs #13

## key = "<part>/<property>". restart = only takes effect on a new run.
const PARAMS := [
	{"key": "station/pump_count", "label": "Pumps", "min": 1, "max": 10, "step": 1, "restart": true},
	{"key": "station/flow_rate", "label": "Pour speed ($/s)", "min": 1.0, "max": 10.0, "step": 0.25},
	{"key": "station/arrival_min", "label": "Car arrives after, min (s)", "min": 0.0, "max": 10.0, "step": 0.25},
	{"key": "station/arrival_max", "label": "Car arrives after, max (s)", "min": 0.0, "max": 15.0, "step": 0.25},
	{"key": "station/cleaning_seconds", "label": "Car cleaning (s)", "min": 0.0, "max": 10.0, "step": 0.5},
	{"key": "station/starting_cash", "label": "Starting cash ($)", "min": 0.0, "max": 500.0, "step": 10.0, "restart": true},
	{"key": "station/special_customer_chance", "label": "Special customers (share)", "min": 0.0, "max": 1.0, "step": 0.05},
	{"key": "station/businessman_patience", "label": "Businessman patience (s)", "min": 1.0, "max": 10.0, "step": 0.5},
	{"key": "station/self_service_speed", "label": "Self-service speed (x pour speed)", "min": 0.1, "max": 1.5, "step": 0.05},
	{"key": "station/card_fee", "label": "Self-service card fee (share)", "min": 0.0, "max": 0.2, "step": 0.005},
	{"key": "station/shop_price_scale", "label": "Shop prices (x)", "min": 0.25, "max": 3.0, "step": 0.05},
	{"key": "station/run_days", "label": "Days in a run", "min": 1, "max": 30, "step": 1},
	{"key": "clock/seconds_per_hour", "label": "Real seconds per game hour", "min": 1.0, "max": 20.0, "step": 0.25},
	{"key": "tank/capacity_liters", "label": "Tank size (L, next day)", "min": 50.0, "max": 1000.0, "step": 10.0},
	{"key": "tiers/super_window", "label": "Super Perfect window ($)", "min": 0.0, "max": 0.2, "step": 0.005},
	{"key": "tiers/perfect_window", "label": "Perfect window ($)", "min": 0.0, "max": 0.5, "step": 0.01},
	{"key": "tiers/good_window", "label": "Good window ($)", "min": 0.0, "max": 2.0, "step": 0.05},
	{"key": "tiers/ok_window", "label": "OK window ($)", "min": 0.0, "max": 3.0, "step": 0.05},
	{"key": "combo/max_multiplier", "label": "Max combo", "min": 1, "max": 10, "step": 1},
	{"key": "economy/super_perfect_tip", "label": "Tip: Super Perfect ($)", "min": 0.0, "max": 20.0, "step": 0.5},
	{"key": "economy/perfect_tip", "label": "Tip: Perfect ($)", "min": 0.0, "max": 20.0, "step": 0.5},
	{"key": "economy/good_tip", "label": "Tip: Good ($)", "min": 0.0, "max": 20.0, "step": 0.5},
	{"key": "economy/ok_tip", "label": "Tip: OK ($)", "min": 0.0, "max": 20.0, "step": 0.5},
	{"key": "economy/super_perfect_xp", "label": "XP: Super Perfect", "min": 0, "max": 500, "step": 10},
	{"key": "economy/perfect_xp", "label": "XP: Perfect", "min": 0, "max": 500, "step": 10},
	{"key": "economy/good_xp", "label": "XP: Good", "min": 0, "max": 500, "step": 10},
	{"key": "economy/ok_xp", "label": "XP: OK", "min": 0, "max": 500, "step": 10},
	{"key": "economy/price_per_liter", "label": "Pump price ($/L)", "min": 0.5, "max": 5.0, "step": 0.05},
	{"key": "economy/wholesale_ratio", "label": "Refill cost (share of price)", "min": 0.0, "max": 1.0, "step": 0.01},
	{"key": "economy/rent_base", "label": "Rent, day 1 ($)", "min": 0.0, "max": 500.0, "step": 10.0},
	{"key": "economy/rent_growth", "label": "Rent added per day ($)", "min": 0.0, "max": 200.0, "step": 5.0},
	{"key": "station/juice_streams", "label": "Juice: pour stream (0/1)", "min": 0, "max": 1, "step": 1},
	{"key": "station/juice_sparkles", "label": "Juice: Perfect sparkle (0/1)", "min": 0, "max": 1, "step": 1},
	{"key": "station/juice_cash_pops", "label": "Juice: cash pops (0/1)", "min": 0, "max": 1, "step": 1},
	{"key": "station/shake_strength", "label": "Juice: screen shake (0 = off)", "min": 0.0, "max": 1.5, "step": 0.05},
	{"key": "sound/music_volume_db", "label": "Music volume (dB)", "min": -40.0, "max": 0.0, "step": 1.0},
	{"key": "sound/pitch_step_per_pump", "label": "Pitch step per pump", "min": 0.0, "max": 0.5, "step": 0.01},
]


static func _target(station: Node, part: String) -> Object:
	match part:
		"station":
			return station
		"economy":
			return station.economy
		"tiers":
			return station.combo.tiers
		"combo":
			return station.combo
		"tank":
			return station.tank
		"clock":
			return station.clock
		"sound":
			return station.sound
	return null


static func get_value(station: Node, key: String) -> Variant:
	var parts := key.split("/")
	return _target(station, parts[0]).get(parts[1])


static func set_value(station: Node, key: String, value: Variant) -> void:
	var parts := key.split("/")
	var target := _target(station, parts[0])
	var current: Variant = target.get(parts[1])
	if current is bool:
		value = bool(value)
	elif current is int:
		value = int(round(value))
	target.set(parts[1], value)
	station.apply_tuning()


static func snapshot(station: Node) -> Dictionary:
	var values := {}
	for p in PARAMS:
		values[p.key] = get_value(station, p.key)
	return values


static func apply_snapshot(station: Node, values: Dictionary) -> void:
	for key in values:
		set_value(station, key, values[key])


static func save(station: Node, path: String) -> void:
	var cfg := ConfigFile.new()
	for p in PARAMS:
		var parts: PackedStringArray = p.key.split("/")
		cfg.set_value(parts[0], parts[1], get_value(station, p.key))
	cfg.save(path)


static func load_into(station: Node, path: String) -> void:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	for p in PARAMS:
		var parts: PackedStringArray = p.key.split("/")
		if cfg.has_section_key(parts[0], parts[1]):
			set_value(station, p.key, cfg.get_value(parts[0], parts[1]))


## One line per value, ready to paste to Claude.
static func as_text(station: Node) -> String:
	var lines := ["Gas Bar Blues tuning (v%s)" % ProjectSettings.get_setting("application/config/version", "dev")]
	for p in PARAMS:
		lines.append("%s = %s" % [p.key, str(get_value(station, p.key))])
	return "\n".join(lines)
