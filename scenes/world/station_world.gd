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

const LANE_W := 3.4
const LANE_Y0 := 5.0  # Blender y of lane 1
const MAX_LANES := 5
const STOP_X := -0.4   # where a car parks beside its pump
const ENTER_X := 26.0  # off screen, top right
const EXIT_X := -28.0  # off screen, bottom left
const CAR_SPEED := 9.0  # metres per second
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
var lane_count := 0
var expanded := false
## One entry per lane: {"pump": Node3D, "island": Node3D, "globe": StandardMaterial3D, "light": OmniLight3D}
var pumps: Array[Dictionary] = []

var _props: Node3D
var _cars := {}          # lane -> parked or arriving car (Node3D)
var _leaving: Array[Node3D] = []
var _pouring := {}       # lane -> true while the player pours
var _wet_materials := {}  # material -> [dry albedo, dry roughness]


func _ready() -> void:
	scenery = SCENERY.instantiate()
	add_child(scenery)
	_props = PROPS.instantiate()  # a library: Pump, Island and Car are copied from it
	_build_camera()
	_build_environment()
	_build_lights()
	_build_rain()
	_build_name_label()
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
		for key in ["pump", "island", "light"]:
			p[key].queue_free()
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
	pumps.append({"pump": pump, "island": island, "globe": globe, "light": light})


## Footprint expansion (#24): the vacant lot and its FOR SALE sign give way to new concrete.
func set_expanded(on: bool) -> void:
	expanded = on
	scenery.get_node("ForecourtExpansion").visible = on
	scenery.get_node("VacantLot").visible = not on
	scenery.get_node("LotForSaleSign").visible = not on


## The player is pouring this lane's pump: its globe glows brighter.
func set_pouring(lane: int, on: bool) -> void:
	_pouring[lane] = on
	_apply_look()


func globe_energy(lane: int) -> float:
	return pumps[lane].globe.emission_energy_multiplier


# --- Cars --------------------------------------------------------------------------------------

## A customer pulled in at `lane`: a car in `colour` drives in from the top right to the pump.
func car_arrive(lane: int, colour: Color) -> void:
	car_depart(lane)
	var car: MeshInstance3D = _props.get_node("Car").duplicate()
	car.position = Vector3(ENTER_X, 0.07, lane_z(lane))
	var body := _own_material(car, "CarBody")
	body.albedo_color = colour
	car.set_meta("target_x", STOP_X)
	add_child(car)
	_cars[lane] = car


## The customer is done (served, gone, or the day closed): the car drives off bottom left.
func car_depart(lane: int) -> void:
	if not _cars.has(lane):
		return
	var car: Node3D = _cars[lane]
	_cars.erase(lane)
	car.set_meta("target_x", EXIT_X)
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


## Kept separate from _process so tests control time.
func tick_cars(delta: float) -> void:
	for car in _cars.values() + _leaving:
		var target: float = car.get_meta("target_x")
		car.position.x = move_toward(car.position.x, target, CAR_SPEED * delta)
	for car in _leaving.duplicate():
		if is_equal_approx(car.position.x, EXIT_X):
			_leaving.erase(car)
			car.queue_free()
			remove_child(car)


# --- Name ---------------------------------------------------------------------------------------

func set_station_name(text: String) -> void:
	name_label.text = text.to_upper()


func _build_name_label() -> void:
	var anchor: Node3D = scenery.get_node("NameAnchor")
	name_label = Label3D.new()
	name_label.text = "GAS BAR BLUES"
	name_label.font_size = 64
	name_label.pixel_size = 0.0075
	name_label.width = 560.0  # wraps long names inside the 4.8 m board
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.modulate = Color(0.12, 0.11, 0.10)
	name_label.outline_size = 0
	name_label.double_sided = false
	# The Blender empty faces the camera along its local +Y once in Godot; Label3D faces local +Z.
	name_label.rotation = Vector3(-PI / 2, 0, 0)
	anchor.add_child(name_label)


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
