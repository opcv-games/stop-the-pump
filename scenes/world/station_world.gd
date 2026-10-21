class_name StationWorld
extends Node3D
## The 3D station: the run-down lanes kit seen through an orthographic isometric camera. One lane per
## game pump; cars drive in at the top right and leave at the bottom left; the footprint expansion
## paves the vacant lot; the pylon shows the player's station name. Lit by DayLightComponent (day
## clock) and dressed by WeatherComponent (rain). No rules here: the HUD on top owns them. Refs #22, #24
##
## Axes: Blender (x, y, z) arrives in Godot as (x, z, -y). Cars travel toward -X, which the camera
## shows as top right -> bottom left. Numbers below mirror tools/blender/build_lanes_kit.py.

const SCENERY := preload("res://assets/art/export/station_scenery.glb")
const PROPS := preload("res://assets/art/export/station_props.glb")
## One prop per upgrade (#28): station props sit in place; Pump* props attach to a pump.
const UPGRADE_PROPS := preload("res://assets/art/export/station_upgrades.glb")

const LANE_W := 3.4
const LANE_Y0 := 5.0  # Blender y of lane 1
const MAX_LANES := 5
const STOP_X := -0.4   # where a car parks beside its pump
## Cars come along the road, up the entry apron, into their lane; they leave by the exit apron (#26).
const ROAD_Z := 14.6        # Godot z of the road's centre (Blender ROAD_Y = -14.6)
const ROAD_FAR := 28.0      # just off screen along the road
const APRON_IN_X := 13.0    # entry apron, top right
const APRON_OUT_X := -13.0  # exit apron, bottom left
## Driving (#27): cruise speed, how hard cars speed up and brake, how slow they take a corner,
## and how round the corners are.
const CAR_SPEED := 14.0
const CAR_ACCEL := 10.0
const CAR_BRAKE := 9.0
const CORNER_SPEED := 4.5
const CORNER_RADIUS := 3.0
const SPARKLE_PERFECT := Color(0.45, 1.0, 0.55)
const SPARKLE_SUPER := Color(1.0, 0.85, 0.3)
const HUD_X0 := 7.6     # lane 1's card anchor, up-right of the pump (clear of pump and car)
const HUD_SLIDE := 1.25 # each next lane's card slides this far down its lane (stays clear of its pump)
## Framed a little right of the Blender review so the station sits left of centre: the lane cards
## and their result popups need the room on the right (#25).
const CAMERA_SHIFT := Vector3(2.2, 0.0, 2.2)  # one screen-right step in world space
const CAMERA_POS := Vector3(-28.5, 30.0, 28.4) + CAMERA_SHIFT
const CAMERA_TARGET := Vector3(1.5, 0.8, -1.6) + CAMERA_SHIFT

var scenery: Node3D
var camera: Camera3D
var sun: DirectionalLight3D
var environment: Environment
var day_light: DayLightComponent
var weather: WeatherComponent
var rain: GPUParticles3D
var name_label: Label3D
## "OPEN 7 AM – 11 AM" under the station's name (#35).
var hours_label: Label3D
var billboard_label: Label3D
var upgrades: Node3D
var lane_count := 0
var expanded := false
## One entry per lane: {"pump": Node3D, "island": Node3D, "globe": StandardMaterial3D, "light": OmniLight3D}
var pumps: Array[Dictionary] = []

var _props: Node3D
var _cars := {}          # lane -> parked or arriving car (Node3D)
var _leaving: Array[Node3D] = []
var _pouring := {}       # lane -> true while the player pours
var _wet_materials := {}  # material -> [dry albedo, dry roughness]
var _streams := {}        # lane -> GPUParticles3D
## Juice (#26), switched from the tuning panel through the station.
var streams_enabled := true
var sparkles_enabled := true
var shake_strength := 0.6
var shake_amount := 0.0
var last_sparkle_lane := -1
var last_sparkle_colour := Color.BLACK
var _pops: Array[Dictionary] = []  # pumps rising out of the ground (#27)

## A car reached its pump and stopped: its customer can now be served (#27).
signal car_parked(lane: int)


func _ready() -> void:
	scenery = SCENERY.instantiate()
	add_child(scenery)
	_props = PROPS.instantiate()  # a library: Pump, Island and Car are copied from it
	upgrades = UPGRADE_PROPS.instantiate()
	upgrades.name = "Upgrades"
	add_child(upgrades)
	reset_props()
	_build_camera()
	_build_environment()
	_build_lights()
	_build_rain()
	_build_name_label()
	# The text rides on the billboard: hidden until it is bought, and pops in with it (playtest 20).
	var board_anchor: Node3D = upgrades.get_node("BillboardAnchor")
	board_anchor.reparent(upgrades.get_node("UpBillboard"))
	billboard_label = _sign_label(board_anchor, 72, 0.0061, 760.0)  # board is 0.72 scale
	billboard_label.modulate = Color(0.16, 0.14, 0.12)
	weather = WeatherComponent.new()
	weather.name = "Weather"
	add_child(weather)
	weather.intensity_changed.connect(func(_i: float) -> void: _apply_look())
	set_expanded(false)
	set_lane_count(2)
	set_hour(7.0)


func _exit_tree() -> void:
	if is_instance_valid(_props):
		_props.free()


func _process(delta: float) -> void:
	tick_cars(delta)
	tick_shake(delta)
	tick_pop(delta)


## A newly built pump rises out of the ground and pops out like an inflatable (#27).
signal pumped_up(lane: int)


func pop_in(lane: int) -> void:
	if lane < pumps.size():
		_pop_nodes([pumps[lane].pump, pumps[lane].island], lane)


## An upgrade's station prop appears (#28), popping in unless `pop` is false.
func show_prop(prop_name: String, pop := true) -> void:
	var n: Node3D = upgrades.get_node(prop_name)
	n.visible = true
	if pop:
		_pop_nodes([n], -1)


## A per-pump upgrade prop (card reader, speed band, sticker) attaches to `lane`'s pump (#28).
func attach_pump_prop(lane: int, prop_name: String, pop := true) -> void:
	if lane >= pumps.size():
		return
	var pump: Node3D = pumps[lane].pump
	if pump.has_node(prop_name):
		return
	var prop: Node3D = upgrades.get_node(prop_name).duplicate()
	prop.name = prop_name
	prop.visible = true
	prop.position = Vector3.ZERO
	pump.add_child(prop)
	if pop:
		_pop_nodes([prop], lane)


## New run: hide every station prop and take the per-pump props off the pumps.
func reset_props() -> void:
	for c in upgrades.get_children():
		if c is MeshInstance3D:
			c.visible = false
	for p in pumps:
		for c in p.pump.get_children():
			if c.name.begins_with("Pump"):
				c.queue_free()
				p.pump.remove_child(c)
	_pops.clear()


## Rise out of the ground, then POP into shape with an elastic wobble, a dust puff and a sound.
func _pop_nodes(nodes: Array, lane: int) -> void:
	for n in nodes:
		if not n.has_meta("rest_y"):
			n.set_meta("rest_y", n.position.y)
		n.scale = Vector3(1.0, 0.05, 1.0)
		n.position.y = n.get_meta("rest_y") - 1.6
	_pops.append({"nodes": nodes, "lane": lane, "t": 0.0, "popped": false})


## Kept separate from _process so tests control time. Rise (0-0.45 s), POP with an elastic wobble
## (0.45-1.2 s), then rest at full size.
func tick_pop(delta: float) -> void:
	for pop in _pops.duplicate():
		pop.t += delta
		var t: float = pop.t
		var nodes: Array = pop.nodes.filter(func(n): return is_instance_valid(n))
		if nodes.is_empty():
			_pops.erase(pop)
			continue
		var rise := clampf(t / 0.45, 0.0, 1.0)
		var wobble := 0.0
		if t > 0.45:
			var k := clampf((t - 0.45) / 0.75, 0.0, 1.0)
			wobble = 0.35 * sin(k * PI * 3.0) * (1.0 - k)
			if not pop.popped:
				pop.popped = true
				_puff((nodes[0] as Node3D).global_position)
				pumped_up.emit(pop.lane)
		for n in nodes:
			var rest: float = n.get_meta("rest_y")
			n.position.y = lerpf(rest - 1.6, rest, ease(rise, 0.4))
			var sy := lerpf(0.05, 1.0, rise) + wobble
			n.scale = Vector3(1.0 - wobble * 0.5, sy, 1.0 - wobble * 0.5)
		if t >= 1.2:
			for n in nodes:
				n.position.y = n.get_meta("rest_y")
				n.scale = Vector3.ONE
			_pops.erase(pop)


func _puff(at: Vector3) -> void:
	var p := GPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 18
	p.lifetime = 0.8
	p.position = Vector3(at.x, 0.2, at.z)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 0.4, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 1.5
	pm.initial_velocity_max = 3.0
	pm.gravity = Vector3(0, 0.5, 0)
	pm.damping_min = 3.0
	pm.damping_max = 4.0
	pm.scale_min = 1.0
	pm.scale_max = 2.0
	p.process_material = pm
	var puff := SphereMesh.new()
	puff.radius = 0.18
	puff.height = 0.36
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.62, 0.57, 0.48, 0.8)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff.material = m
	p.draw_pass_1 = puff
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


# --- Lanes and pumps -------------------------------------------------------------------------

## Godot z of lane `i`'s centre line (0-based).
func lane_z(i: int) -> float:
	return -(LANE_Y0 - i * LANE_W - 0.3)


## Where lane `i`'s HUD card is pinned: on the lane, up-right of its pump. Each lane's point slides a
## little further down its lane than the previous one, so the cards stack in a column without
## overlapping (neighbouring lanes are only ~75 px apart on screen). Refs #25
func hud_anchor(i: int) -> Vector3:
	return Vector3(HUD_X0 - i * HUD_SLIDE, 1.0, lane_z(i))


func set_lane_count(n: int) -> void:
	n = clampi(n, 1, MAX_LANES)
	while pumps.size() < n:
		_add_pump(pumps.size())
	while pumps.size() > n:
		var p: Dictionary = pumps.pop_back()
		day_light.glow_lights.erase(p.light)
		day_light.glow_materials.erase(p.globe)
		for key in ["pump", "island", "light", "stream"]:
			p[key].queue_free()
		_streams.erase(pumps.size())
	lane_count = n
	for i in MAX_LANES:
		scenery.get_node("Lane_%d" % (i + 1)).visible = i < n
	_apply_look()


func _add_pump(i: int) -> void:
	var z := -(LANE_Y0 - i * LANE_W + 1.25)
	var island: Node3D = _props.get_node("Island").duplicate()
	island.position = Vector3(0.6, 0.0, z)
	add_child(island)
	var pump: MeshInstance3D = _props.get_node("Pump").duplicate()
	pump.position = Vector3(0.6, 0.22, z)
	add_child(pump)
	var globe := _own_material(pump, "PumpGlobe")
	globe.emission_energy_multiplier = 2.5
	day_light.glow_materials.append(globe)
	var light := OmniLight3D.new()
	light.position = Vector3(0.6, 2.6, z + 0.6)
	light.light_energy = 1.6
	light.omni_range = 6.0
	light.light_color = Color(1.0, 0.78, 0.5)
	add_child(light)
	day_light.glow_lights.append(light)
	# Starts high and arcs over the roofline: the car sits between the camera and the nozzle (#26).
	var stream := _make_stream(Vector3(0.4, 1.55, z + 0.45))
	_streams[i] = stream
	pumps.append({"pump": pump, "island": island, "globe": globe, "light": light, "stream": stream})


## Footprint expansion (#24): the vacant lot and its FOR SALE sign give way to new concrete.
func set_expanded(on: bool) -> void:
	expanded = on
	scenery.get_node("ForecourtExpansion").visible = on
	scenery.get_node("VacantLot").visible = not on
	scenery.get_node("LotForSaleSign").visible = not on


## The player is pouring this lane's pump: its globe glows brighter.
func set_pouring(lane: int, on: bool) -> void:
	_pouring[lane] = on
	if _streams.has(lane):
		_streams[lane].emitting = on and streams_enabled
	_apply_look()


func stream(lane: int) -> GPUParticles3D:
	return _streams[lane]


## A great stop: a burst of stars from the pump's globe (green Perfect, gold Super Perfect).
func sparkle(lane: int, colour: Color) -> void:
	if not sparkles_enabled or lane >= pumps.size():
		return
	last_sparkle_lane = lane
	last_sparkle_colour = colour
	var p := GPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 26
	p.lifetime = 0.9
	p.position = pumps[lane].pump.position + Vector3(0, 1.8, 0)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 70.0
	pm.initial_velocity_min = 2.5
	pm.initial_velocity_max = 5.0
	pm.gravity = Vector3(0, -6, 0)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	p.process_material = pm
	var star := QuadMesh.new()
	star.size = Vector2(0.18, 0.18)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	m.albedo_color = colour
	m.emission_enabled = true
	m.emission = colour
	m.emission_energy_multiplier = 3.0
	star.material = m
	p.draw_pass_1 = star
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


## A bad moment (Miss, drive-off, broken combo): the world shakes, the HUD does not (#26).
func shake(amount := 1.0) -> void:
	shake_amount = maxf(shake_amount, amount * shake_strength)


## Kept separate from _process so tests control time.
func tick_shake(delta: float) -> void:
	if shake_amount <= 0.0:
		return
	shake_amount = maxf(0.0, shake_amount - delta * 2.5)
	if shake_amount == 0.0:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		return
	camera.h_offset = randf_range(-1.0, 1.0) * shake_amount * 0.35
	camera.v_offset = randf_range(-1.0, 1.0) * shake_amount * 0.35


func _make_stream(at: Vector3) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = 70
	p.lifetime = 0.45
	p.position = at
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3(-0.3, 0.9, 1.0)  # up and over, toward the car
	pm.spread = 5.0
	pm.initial_velocity_min = 3.0
	pm.initial_velocity_max = 3.4
	pm.gravity = Vector3(0, -9.8, 0)
	p.process_material = pm
	var drop := SphereMesh.new()
	drop.radius = 0.08
	drop.height = 0.16
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # readable in any light
	m.albedo_color = Color(1.0, 0.78, 0.25)
	drop.material = m
	p.draw_pass_1 = drop
	p.emitting = false
	add_child(p)
	return p


func globe_energy(lane: int) -> float:
	return pumps[lane].globe.emission_energy_multiplier


# --- Cars --------------------------------------------------------------------------------------

## A customer pulled in at `lane`: a car in `colour` comes along the road from the top right, turns
## up the entry apron, and drives into its lane to the pump, where it parks (#26, #27).
func car_arrive(lane: int, colour: Color) -> void:
	car_depart(lane)
	var car: MeshInstance3D = _props.get_node("Car").duplicate()
	var body := _own_material(car, "CarBody")
	body.albedo_color = colour
	add_child(car)
	_drive(car, [Vector3(ROAD_FAR, 0.07, ROAD_Z), Vector3(APRON_IN_X, 0.07, ROAD_Z),
		Vector3(APRON_IN_X, 0.07, lane_z(lane)), Vector3(STOP_X, 0.07, lane_z(lane))], true)
	car.set_meta("lane", lane)
	_cars[lane] = car


## The customer is done (served, gone, or the day closed): the car leaves by the exit apron and the road.
func car_depart(lane: int) -> void:
	if not _cars.has(lane):
		return
	var car: Node3D = _cars[lane]
	_cars.erase(lane)
	var at := car.position
	_drive(car, [at, Vector3(APRON_OUT_X, 0.07, at.z), Vector3(APRON_OUT_X, 0.07, ROAD_Z),
		Vector3(-ROAD_FAR, 0.07, ROAD_Z)], false)
	_leaving.append(car)


func car_at(lane: int) -> Node3D:
	return _cars.get(lane)


func car_colour(lane: int) -> Color:
	var car: MeshInstance3D = _cars[lane]
	for i in car.mesh.get_surface_count():
		var m := car.get_surface_override_material(i)
		if m:
			return (m as StandardMaterial3D).albedo_color
	return Color.BLACK


## Gives `car` a smooth route through `points`: corners are rounded into curves, and the car slows
## into each corner and (if `park`) eases to a stop at the end.
func _drive(car: Node3D, points: Array, park: bool) -> void:
	var curve := Curve3D.new()
	curve.bake_interval = 0.2
	var corners: Array[Vector3] = []
	curve.add_point(points[0])
	for i in range(1, points.size() - 1):
		var a: Vector3 = points[i - 1]
		var b: Vector3 = points[i]
		var c: Vector3 = points[i + 1]
		var d_in := (b - a).normalized()
		var d_out := (c - b).normalized()
		var r := minf(CORNER_RADIUS, minf(a.distance_to(b), b.distance_to(c)) * 0.45)
		curve.add_point(b - d_in * r, Vector3.ZERO, d_in * r * 0.55)
		curve.add_point(b + d_out * r, -d_out * r * 0.55, Vector3.ZERO)
		corners.append(b)
	curve.add_point(points[-1])
	var corner_offsets: Array[float] = []
	for b in corners:
		corner_offsets.append(curve.get_closest_offset(b))
	car.set_meta("curve", curve)
	car.set_meta("offset", 0.0)
	car.set_meta("speed", car.get_meta("speed", 0.0) if not park else 6.0)
	car.set_meta("corners", corner_offsets)
	car.set_meta("park", park)
	car.position = points[0]
	_face(car, (points[1] as Vector3) - (points[0] as Vector3))


## Kept separate from _process so tests control time (stepped in small slices for smooth motion).
func tick_cars(delta: float) -> void:
	while delta > 0.0:
		var dt := minf(delta, 0.03)
		delta -= dt
		for car in _cars.values() + _leaving:
			_step_car(car, dt)
	for car in _leaving.duplicate():
		if car.get_meta("offset") >= (car.get_meta("curve") as Curve3D).get_baked_length() - 0.001:
			_leaving.erase(car)
			remove_child(car)
			car.queue_free()


func _step_car(car: Node3D, dt: float) -> void:
	var curve: Curve3D = car.get_meta("curve")
	var length := curve.get_baked_length()
	var offset: float = car.get_meta("offset")
	if offset >= length:
		return
	# The fastest speed that still lets the car brake for the next corner, and to a stop if parking.
	var allowed := CAR_SPEED
	for c in car.get_meta("corners"):
		if c > offset:
			allowed = minf(allowed, sqrt(CORNER_SPEED * CORNER_SPEED + 2.0 * CAR_BRAKE * (c - offset)))
	if car.get_meta("park"):
		allowed = minf(allowed, sqrt(2.0 * CAR_BRAKE * (length - offset)) + 0.4)
	var speed: float = minf(allowed, car.get_meta("speed") + CAR_ACCEL * dt)
	offset = minf(length, offset + speed * dt)
	car.set_meta("speed", speed)
	car.set_meta("offset", offset)
	var pos := curve.sample_baked(offset)
	var ahead := curve.sample_baked(minf(length, offset + 0.6))
	if ahead.distance_to(pos) > 0.05:
		_face(car, ahead - pos)
	car.position = pos
	if offset >= length and car.get_meta("park") and _cars.values().has(car):
		car.set_meta("speed", 0.0)
		_face(car, Vector3(-1, 0, 0))  # parked facing the way out
		car_parked.emit(car.get_meta("lane"))


## The car model's front points along -X; turn it to face `direction` (on the ground plane).
func _face(car: Node3D, direction: Vector3) -> void:
	if Vector2(direction.x, direction.z).length() < 0.001:
		return
	car.rotation.y = atan2(direction.z, -direction.x)


# --- Name ---------------------------------------------------------------------------------------

func set_station_name(text: String) -> void:
	name_label.text = text.to_upper()
	if billboard_label:
		billboard_label.text = "FILL UP AT\n%s" % text.to_upper()


func set_hours(open_hour: float, close_hour: float) -> void:
	hours_label.text = "OPEN %s – %s" % [_clock_text(open_hour), _clock_text(close_hour)]


static func _clock_text(h: float) -> String:
	var whole := int(h) % 24
	var shown := whole % 12
	return "%d %s" % [12 if shown == 0 else shown, "AM" if whole < 12 else "PM"]


func _build_name_label() -> void:
	name_label = _sign_label(scenery.get_node("NameAnchor"), 64, 0.0075, 560.0)  # wraps inside the 4.8 m board
	name_label.text = "GAS BAR BLUES"
	# Hangs under the name in the name's own text plane, so it reads like a second line on the board.
	hours_label = _sign_label(scenery.get_node("NameAnchor"), 34, 0.0075, 560.0)
	hours_label.reparent(name_label, false)
	hours_label.transform = Transform3D(Basis.IDENTITY, Vector3(0, -0.5, 0.01))
	set_hours(7.0, 11.0)


## Text painted on a sign at a Blender empty.
func _sign_label(anchor: Node3D, font_size: int, pixel: float, wrap_width: float) -> Label3D:
	var l := Label3D.new()
	l.font_size = font_size
	l.pixel_size = pixel
	l.width = wrap_width
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.modulate = Color(0.12, 0.11, 0.10)
	l.outline_size = 0
	l.double_sided = false
	# The Blender empty faces the camera along its local +Y once in Godot; Label3D faces local +Z.
	l.rotation = Vector3(-PI / 2, 0, 0)
	anchor.add_child(l)
	return l


# --- Look: camera, light, weather ---------------------------------------------------------------

func set_hour(h: float) -> void:
	day_light.hour = h
	weather.update_hour(h)
	_apply_look()


## Light from the clock first, then rain, then the pouring glow on top.
func _apply_look() -> void:
	if not day_light:
		return
	day_light.apply_hour(day_light.hour)
	var r := weather.intensity if weather else 0.0
	if r > 0.0:
		sun.light_energy *= 1.0 - 0.65 * r
		environment.background_color = environment.background_color.lerp(Color(0.32, 0.34, 0.38), 0.55 * r) * (1.0 - 0.25 * r)
		environment.ambient_light_energy *= 1.0 - 0.3 * r
	for m in _wet_materials:
		var dry: Array = _wet_materials[m]
		m.albedo_color = (dry[0] as Color).darkened(0.35 * r)
		m.roughness = lerpf(dry[1], 0.12, r)
	rain.emitting = r > 0.02
	rain.amount_ratio = maxf(r, 0.01)
	for lane in _pouring:
		if _pouring[lane] and lane < pumps.size():
			var g: StandardMaterial3D = pumps[lane].globe
			g.emission_energy_multiplier = maxf(g.emission_energy_multiplier, 2.0) * 3.0


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 23.6  # the Blender review frame (42 wide), measured on the height
	add_child(camera)
	camera.look_at_from_position(CAMERA_POS, CAMERA_TARGET)
	camera.current = true


func _build_environment() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	environment.glow_enabled = true  # pump globes and windows bloom at night
	environment.glow_intensity = 0.6
	environment.glow_bloom = 0.05
	var we := WorldEnvironment.new()
	we.environment = environment
	add_child(we)


func _build_lights() -> void:
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)
	day_light = DayLightComponent.new()
	day_light.name = "DayLight"
	day_light.sun = sun
	day_light.environment = environment
	add_child(day_light)
	# Warm light from the station windows, the pylon's bulbs, and a lamp washing the name board so the
	# player's name stays readable after dark (affordance check 3).
	for s in [[Vector3(2.0, 2.6, -9.8), 3.0, 11.0], [Vector3(16.0, 5.0, -2.3), 1.2, 7.0], [Vector3(14.6, 4.6, -0.9), 1.1, 3.5]]:
		var l := OmniLight3D.new()
		l.position = s[0]
		l.light_energy = s[1]
		l.omni_range = s[2]
		l.light_color = Color(1.0, 0.78, 0.5)
		add_child(l)
		day_light.glow_lights.append(l)
	# Own copies of emissive and ground materials so the imported kit stays untouched.
	for mesh in scenery.get_children():
		if not mesh is MeshInstance3D:
			continue
		for i in mesh.mesh.get_surface_count():
			var src: Material = mesh.mesh.surface_get_material(i)
			if not src is StandardMaterial3D:
				continue
			match src.resource_name:
				"WindowLight", "PumpGlobe", "SignBulb", "VendingGlow":
					var mat: StandardMaterial3D = src.duplicate()
					mat.emission_energy_multiplier = 2.5 if src.resource_name != "VendingGlow" else 1.0
					mesh.set_surface_override_material(i, mat)
					day_light.glow_materials.append(mat)
				"Asphalt", "Concrete", "ConcreteNew", "DryGrass", "Gravel":
					var wet: StandardMaterial3D = src.duplicate()
					_wet_materials[wet] = [wet.albedo_color, wet.roughness]
					mesh.set_surface_override_material(i, wet)


## Gives `mesh` its own copy of the surface material called `material_name` and returns it.
func _own_material(mesh: MeshInstance3D, material_name: String) -> StandardMaterial3D:
	for i in mesh.mesh.get_surface_count():
		var src: Material = mesh.mesh.surface_get_material(i)
		if src and src.resource_name == material_name:
			var mat: StandardMaterial3D = src.duplicate()
			mesh.set_surface_override_material(i, mat)
			return mat
	return StandardMaterial3D.new()


func _build_rain() -> void:
	rain = GPUParticles3D.new()
	rain.amount = 3200
	rain.lifetime = 1.0
	rain.position = Vector3(0, 16, -2)
	rain.visibility_aabb = AABB(Vector3(-45, -30, -45), Vector3(90, 50, 90))
	var p := ParticleProcessMaterial.new()
	p.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(32, 0.5, 30)
	p.direction = Vector3(0.12, -1, 0.08)
	p.spread = 2.0
	p.initial_velocity_min = 18.0
	p.initial_velocity_max = 22.0
	p.gravity = Vector3(0, -9.8, 0)
	rain.process_material = p
	var streak := QuadMesh.new()
	streak.size = Vector2(0.04, 0.9)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.albedo_color = Color(0.78, 0.82, 0.9, 0.45)
	streak.material = m
	rain.draw_pass_1 = streak
	rain.emitting = false
	add_child(rain)
