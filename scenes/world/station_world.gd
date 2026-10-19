class_name StationWorld
extends Node3D
## The 3D station after Hopper's "Gas": the Blender kit seen through an orthographic isometric camera,
## lit by DayLightComponent (day clock) and dressed by WeatherComponent (rain). No gameplay here:
## the HUD on top owns the rules. Refs #22

const KIT := preload("res://assets/art/export/station_kit.glb")
## Matches the Blender look-test camera (Blender (-25,-25,25) is Godot (-25,25,25)).
const CAMERA_POS := Vector3(-25.0, 25.0, 25.0)
const CAMERA_TARGET := Vector3(0.5, 0.8, -1.0)

var kit: Node3D
var camera: Camera3D
var sun: DirectionalLight3D
var environment: Environment
var day_light: DayLightComponent
var weather: WeatherComponent
var rain: GPUParticles3D

var _wet_materials := {}  # material -> [dry albedo, dry roughness]


func _ready() -> void:
	kit = KIT.instantiate()
	add_child(kit)
	_build_camera()
	_build_environment()
	_build_lights()
	_build_rain()
	weather = WeatherComponent.new()
	weather.name = "Weather"
	add_child(weather)
	weather.intensity_changed.connect(func(_i: float) -> void: _apply_look())
	set_hour(7.0)


func set_hour(h: float) -> void:
	day_light.hour = h
	weather.update_hour(h)
	_apply_look()


## Light from the clock first, then rain darkens it and wets the ground.
func _apply_look() -> void:
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


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.5  # the Blender look test's 24-wide ortho frame, measured on the height
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
	sun.directional_shadow_max_distance = 70.0
	add_child(sun)
	day_light = DayLightComponent.new()
	day_light.name = "DayLight"
	day_light.sun = sun
	day_light.environment = environment
	add_child(day_light)
	# Warm pools of light under the windows and the pumps; they matter at night.
	var spots := [[Vector3(4.5, 2.6, -1.5), 3.0, 10.0]]
	for x in [-3.0, -0.4, 2.2]:
		spots.append([Vector3(x, 2.6, 1.7), 1.6, 6.0])
	for s in spots:
		var l := OmniLight3D.new()
		l.position = s[0]
		l.light_energy = s[1]
		l.omni_range = s[2]
		l.light_color = Color(1.0, 0.78, 0.5)
		add_child(l)
		day_light.glow_lights.append(l)
	# Own copies of the emissive and ground materials so the imported kit stays untouched.
	for mesh in kit.get_children():
		if not mesh is MeshInstance3D:
			continue
		for i in mesh.mesh.get_surface_count():
			var src: Material = mesh.mesh.surface_get_material(i)
			if not src is StandardMaterial3D:
				continue
			var mat: StandardMaterial3D
			match src.resource_name:
				"WindowLight", "PumpGlobe":
					mat = src.duplicate()
					mat.emission_energy_multiplier = 2.5
					day_light.glow_materials.append(mat)
				"Asphalt", "Concrete", "DryGrass":
					mat = src.duplicate()
					_wet_materials[mat] = [mat.albedo_color, mat.roughness]
			if mat:
				mesh.set_surface_override_material(i, mat)


func _build_rain() -> void:
	rain = GPUParticles3D.new()
	rain.amount = 2600
	rain.lifetime = 1.0
	rain.position = Vector3(0, 16, 0)
	rain.visibility_aabb = AABB(Vector3(-40, -30, -40), Vector3(80, 50, 80))
	var p := ParticleProcessMaterial.new()
	p.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(26, 0.5, 26)
	p.direction = Vector3(0.12, -1, 0.08)
	p.spread = 2.0
	p.initial_velocity_min = 18.0
	p.initial_velocity_max = 22.0
	p.gravity = Vector3(0, -9.8, 0)
	rain.process_material = p
	var streak := QuadMesh.new()
	streak.size = Vector2(0.035, 0.8)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	m.albedo_color = Color(0.78, 0.82, 0.9, 0.45)
	streak.material = m
	rain.draw_pass_1 = streak
	rain.emitting = false
	add_child(rain)
