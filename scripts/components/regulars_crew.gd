class_name RegularsCrew
extends RefCounted
## The regulars (round 8): Ti-Guy, Mme Gagnon, Bertrand and Le Grand. They don't just sit: each one
## spends a while on the bench, then gets up to watch you pour from the edge of the lot, goes inside
## for a coffee and comes back out with it, or (Le Grand) steps out for a smoke. Two at most are away
## from the bench at once. Wherever they are they react: arms up for a top-off, applause for a Perfect.
## GodPump owns the crew and steps it; the views draw `list` (world positions and poses).
## Serves: Comedy (a cast with habits) and Advancement (an audience that cares).

const NAMES := ["tiguy", "gagnon", "bertrand", "legrand"]
const FULL_NAMES := {"tiguy": "Ti-Guy", "gagnon": "Mme Gagnon", "bertrand": "Bertrand", "legrand": "Le Grand"}
const BENCH := Vector2(60, 186)
const SEAT_GAP := 38.0
const DOOR := Vector2(216, 176)
const WATCH := [Vector2(352, 166), Vector2(404, 158), Vector2(468, 162), Vector2(522, 166)]
const SMOKE := Vector2(-20, 202)
const SPEED := 34.0
const MAX_AWAY := 2

## Each: {name, sprite, seat, pos, state, t, goal, after, flip, cup, walk_t, cheer, clap, bob}.
## state: sit, walk, watch, stand, inside.
var list: Array[Dictionary] = []


func _init(rng: RandomNumberGenerator) -> void:
	for i in NAMES.size():
		list.append({"name": NAMES[i], "sprite": NAMES[i], "seat": i, "pos": seat_pos(i), "state": "sit",
			"t": rng.randf_range(3.0, 12.0), "goal": seat_pos(i), "after": "sit", "flip": false, "cup": 0.0,
			"walk_t": 0.0, "cheer": 0.0, "clap": 0.0, "bob": rng.randf() * TAU})


static func seat_pos(i: int) -> Vector2:
	return BENCH + Vector2(18 + i * SEAT_GAP, 2)


func away() -> int:
	return list.filter(func(r: Dictionary) -> bool: return r.state != "sit").size()


## Their routines, while the gaz bar is open (`open`); at closing they drift back to the bench.
func step(dt: float, rng: RandomNumberGenerator, open: bool) -> void:
	for r in list:
		r.cheer = maxf(r.cheer - dt, 0.0)
		r.clap = maxf(r.clap - dt, 0.0)
		r.cup = maxf(r.cup - dt, 0.0)
		match r.state:
			"sit":
				r.t -= dt
				if r.t <= 0.0:
					if open and away() < MAX_AWAY:
						_head_out(r, rng)
					else:
						r.t = rng.randf_range(3.0, 6.0)
			"walk":
				var to: Vector2 = r.goal - r.pos
				r.walk_t += dt
				if absf(to.x) > 1.0:
					r.flip = to.x < 0.0
				if to.length() <= SPEED * dt:
					r.pos = r.goal
					_arrive(r, rng)
				else:
					r.pos += to.normalized() * SPEED * dt
			"watch", "stand":
				r.t -= dt
				if r.t <= 0.0 or not open:
					_walk(r, seat_pos(r.seat), "sit")
			"inside":
				r.t -= dt
				if r.t <= 0.0:
					r.pos = DOOR
					r.cup = 14.0  # out the door with a coffee
					_walk(r, seat_pos(r.seat), "sit")


func _head_out(r: Dictionary, rng: RandomNumberGenerator) -> void:
	var roll := rng.randf()
	if r.name == "legrand" and roll < 0.35:
		_walk(r, SMOKE, "stand")
	elif roll < 0.65:
		var free: Array = WATCH.filter(func(p: Vector2) -> bool: return not list.any(func(o: Dictionary) -> bool: return o.goal == p and o.state != "sit"))
		_walk(r, free[rng.randi() % free.size()] if not free.is_empty() else WATCH[0], "watch")
	else:
		_walk(r, DOOR, "inside")


func _walk(r: Dictionary, goal: Vector2, after: String) -> void:
	r.goal = goal
	r.after = after
	r.state = "walk"
	r.walk_t = 0.0


func _arrive(r: Dictionary, rng: RandomNumberGenerator) -> void:
	r.state = r.after
	match r.after:
		"sit":
			r.t = rng.randf_range(8.0, 16.0)
			r.flip = false
		"watch":
			r.t = rng.randf_range(6.0, 10.0)
		"stand":
			r.t = rng.randf_range(5.0, 8.0)
		"inside":
			r.t = rng.randf_range(3.0, 5.0)


## The sprite pose for a regular now: sit / stand / walk_0..3, with cheer, clap or coffee. "" = inside.
static func pose(r: Dictionary) -> String:
	if r.state == "inside":
		return ""
	var react := "cheer" if r.cheer > 0.0 else ("clap" if r.clap > 0.0 and int(r.clap * 10.0) % 2 == 0 else "")
	if r.state == "sit":
		return "sit_" + react if react != "" else ("sit_coffee" if r.cup > 0.0 else "sit")
	if react != "":
		return react
	if r.cup > 0.0:
		return "coffee"
	if r.state == "walk":
		return "walk_%d" % (int(r.walk_t * 7.0) % 4)
	return "stand"


static func seated(r: Dictionary) -> bool:
	return r.state == "sit"
