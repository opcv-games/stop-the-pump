class_name HD2DView
extends Node3D
## The HD-2D try for the god pump (#36, god-pump playtest 5: "I would like to try HD-2D"). Pixel-art
## textures and sprites in a real 3D scene, Octopath-style: the same high three-quarter camera, a warm
## sun with real shadows, ambient occlusion, bloom on the neon and its red light on the asphalt, a
## tilt-shift depth of field that blurs the road behind and the edge in front. The simulation stays
## GodPump's top-down world; this node mirrors it in 3D (1 world px = K metres).
##   Cars: the claude-pxl sprite stack laid out as 16 flat slices, so they catch light and cast
##   shadows. Regulars, bench, neon, clock and door_sign: pixel sprites standing in the scene.
## Serves: Immersion (a place you'd want to stand in) without losing pixel-art readability.

const K := 0.02  # metres per world pixel
const PX := 0.04  # metres per sprite pixel (sprites were drawn for 2x)
const CAR_SLICE_GAP := 0.034  # round 8: a little taller, so the cars read as solid
const STORE := Rect2(16, 100, 262, 66)  # matches IsoView: between the road and the lot
const STORE_H := 1.76
const BENCH := Vector2(60, 186)
const SEAT_GAP := 38.0

var game: GodPump
var camera: Camera3D
var neon: MeshInstance3D
var _neon_mat: StandardMaterial3D
var neon_light: OmniLight3D
var door_sign: Sprite3D
var clock_hands: Array[Node3D] = []
var regular_sprites: Array[Sprite3D] = []
var _cars := {}  # ProtoCar -> Node3D
var _puddles: Array[MeshInstance3D] = []
var _slice_mats := {}
var _puddle_mats := {}
var _env: Environment


func setup(owner_game: GodPump) -> void:
	game = owner_game
	_build_world()
	_build_ground()
	_build_store()
	_build_regulars()
	_build_surroundings()
	_build_dust()


static func to3(w: Vector2, h := 0.0) -> Vector3:
	return Vector3(w.x * K, h, w.y * K)


# --- Screen <-> world (base resolution 1152 x 648; the viewport may render larger) --------------

func _vp_scale() -> float:
	var vp := get_viewport()
	return float(vp.size.x) / GodPump.WIDTH if vp else 1.0


func screen(w: Vector2, h := 0.0) -> Vector2:
	if not camera or not camera.is_inside_tree():
		return w
	return camera.unproject_position(to3(w, h)) / _vp_scale()


## The world point on the ground under a screen point (the mouse).
func ground_at(sp: Vector2) -> Vector2:
	if not camera or not camera.is_inside_tree():
		return sp
	var p := sp * _vp_scale()
	var o := camera.project_ray_origin(p)
	var d := camera.project_ray_normal(p)
	if absf(d.y) < 0.0001:
		return sp
	var hit := o + d * (-o.y / d.y)
	return Vector2(hit.x, hit.z) / K


var _name_label: Label3D


## The gaz bar's name on a sign above the storefront.
func set_station_name(text: String) -> void:
	if not _name_label:
		_name_label = Label3D.new()
		_name_label.font_size = 96
		_name_label.pixel_size = 0.006
		_name_label.outline_size = 18
		_name_label.modulate = Color(1.0, 0.86, 0.4)
		_name_label.outline_modulate = Color(0.15, 0.08, 0.04)
		_name_label.shaded = false
		_name_label.double_sided = true
		_name_label.position = to3(Vector2(STORE.position.x + STORE.size.x * 0.32, STORE.end.y), STORE_H + 0.22) + Vector3(0, 0, 0.05)
		add_child(_name_label)
	_name_label.text = text.to_upper()


func regular_head(i: int) -> Vector2:
	var r: Dictionary = game.regulars[i]
	return screen(r.pos, 1.25 if RegularsCrew.seated(r) else 1.75)


# --- Building the scene -------------------------------------------------------------------------

func _build_world() -> void:
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Color(0.20, 0.17, 0.14)
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.62, 0.55, 0.50)
	_env.ambient_light_energy = 0.38
	_env.tonemap_mode = Environment.TONE_MAPPER_ACES
	_env.tonemap_exposure = 1.05
	_env.ssao_enabled = true
	_env.ssao_radius = 0.6
	_env.ssao_intensity = 1.6
	_env.glow_enabled = true
	_env.glow_intensity = 0.55
	_env.glow_strength = 1.1
	_env.glow_bloom = 0.04
	_env.glow_hdr_threshold = 0.95
	_env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.55, 0.45, 0.38)
	_env.fog_density = 0.008
	_env.adjustment_enabled = true  # a touch of grading: warmer, punchier
	_env.adjustment_contrast = 1.12
	_env.adjustment_saturation = 1.04
	var we := WorldEnvironment.new()
	we.environment = _env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-36, -40, 0)  # low morning sun: long shadows
	sun.light_color = Color(1.0, 0.84, 0.64)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)
	camera = Camera3D.new()
	camera.fov = 30.0
	var focus := Vector3(11.0, 0.0, 6.4)
	camera.position = focus + Vector3(0, 21.0, 17.0)
	add_child(camera)
	camera.look_at(focus, Vector3.UP)
	camera.current = true
	var attrs := CameraAttributesPractical.new()  # tilt-shift: the road behind and the near edge go soft
	attrs.dof_blur_far_enabled = true
	attrs.dof_blur_far_distance = 29.0
	attrs.dof_blur_far_transition = 5.0
	attrs.dof_blur_near_enabled = true
	attrs.dof_blur_near_distance = 23.5
	attrs.dof_blur_near_transition = 2.5
	attrs.dof_blur_amount = 0.1  # half of the first try (playtest 6: too strong)
	camera.attributes = attrs


func _pixel_mat(tex: Texture2D, tile := Vector2.ONE) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	m.uv1_scale = Vector3(tile.x, tile.y, 1)
	m.roughness = 0.9
	return m


func _flat(size: Vector2, at: Vector3, mat: Material) -> MeshInstance3D:
	var q := PlaneMesh.new()
	q.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = mat
	mi.position = at
	add_child(mi)
	return mi


func _build_ground() -> void:
	var tile := 64.0 * K  # a 32 px tile drawn at 2x
	var dirt := Vector2(44, 34)
	var dirt_mat := _pixel_mat(game.tex("dirt2"), dirt / tile)
	dirt_mat.albedo_color = Color(0.72, 0.68, 0.66)  # darker, less red under the warm sun (playtest 6)
	_flat(dirt, Vector3(11.5, -0.01, 7.0), dirt_mat)
	var road := Vector2(40, 64 * K)
	_flat(road, Vector3(11.5, 0.0, GodPump.ROAD_Y * K), _pixel_mat(game.tex("road"), road / tile))
	var lot := GodPump.LOT
	_flat(lot.size * K, to3(lot.get_center(), 0.005), _pixel_mat(game.tex("asphalt"), lot.size * K / tile))
	var apron_mat := StandardMaterial3D.new()
	apron_mat.albedo_color = Color(0.21, 0.20, 0.20)
	for x in [GodPump.ENTRANCE.x, GodPump.EXIT.x]:
		var h := lot.position.y - GodPump.ROAD_Y - 20
		_flat(Vector2(80, h) * K, to3(Vector2(x, GodPump.ROAD_Y + 30 + h * 0.5), 0.004), apron_mat)
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.8, 0.8, 0.75)
	for i in 9:
		_flat(Vector2(4, 60) * K, to3(Vector2(lot.position.x + 72 + i * 98, lot.end.y - 40), 0.008), line_mat)


func _decal(tex_id: String, w: Vector2, rot: float, size_k := 1.0, h := 0.006) -> MeshInstance3D:
	var tex: Texture2D = game.tex(tex_id)
	if not tex:
		return null
	var m := _pixel_mat(tex)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var mi := _flat(tex.get_size() * PX * size_k, to3(w, h), m)
	mi.rotation.y = rot
	return mi


## Around the lot, after the designer's satellite photos: patchy grass on dark dirt, a concrete
## curb and a grass strip round the lot, white bollards, a sidewalk along the street, the yellow
## hatching in front of the store, old concrete pump pads, cracks and oil stains, a rundown car, a
## tire pile, a garbage container and two maples.
func _build_surroundings() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1985
	var lot := GodPump.LOT
	var keep_out := [lot.grow(30), Rect2(-200, GodPump.ROAD_Y - 50, 1600, 100), STORE.grow(20)]
	for i in 70:  # grass patches on the dirt
		var p := Vector2(rng.randf_range(-150, 1300), rng.randf_range(90, 760))
		var blocked := false
		for r in keep_out:
			if r.has_point(p):
				blocked = true
		if not blocked:
			_decal(["grass_a", "grass_b", "grass_c"][i % 3], p, rng.randf() * TAU, rng.randf_range(1.0, 2.2), 0.003)
	var concrete := _pixel_mat(game.tex("concrete"), Vector2(4, 1))
	var curb_h := 0.08
	var c := lot.get_center()
	_box(Vector3(lot.size.x * K + 0.2, curb_h, 0.14), to3(Vector2(c.x, lot.end.y), curb_h * 0.5), concrete)   # south
	_box(Vector3(0.14, curb_h, lot.size.y * K), to3(Vector2(lot.position.x, c.y), curb_h * 0.5), concrete)    # west
	_box(Vector3(0.14, curb_h, lot.size.y * K), to3(Vector2(lot.end.x, c.y), curb_h * 0.5), concrete)         # east
	var green := _pixel_mat(game.tex("grass_b"))
	green.albedo_texture = null
	green.albedo_color = Color(0.32, 0.45, 0.2)
	_flat(Vector2(lot.size.x * K + 1.2, 0.6), to3(Vector2(c.x, lot.end.y + 22), 0.004), green)               # grass strip
	_flat(Vector2(0.6, lot.size.y * K), to3(Vector2(lot.end.x + 22, c.y), 0.004), green)
	var bollard_mat := _wall_mat(Color(0.88, 0.87, 0.82))
	var x := lot.position.x + 40
	while x < lot.end.x - 20:  # white bollards along the south edge
		_box(Vector3(0.22, 0.24, 0.22), to3(Vector2(x, lot.end.y + 10), 0.12), bollard_mat)
		x += 70
	_flat(Vector2(44, 0.5), to3(Vector2(576, GodPump.ROAD_Y + 40), 0.004), _pixel_mat(game.tex("concrete"), Vector2(60, 1)))   # sidewalk
	_flat(Vector2(44, 0.5), to3(Vector2(576, GodPump.ROAD_Y - 40), 0.004), _pixel_mat(game.tex("concrete"), Vector2(60, 1)))
	var hatch := _pixel_mat(game.tex("hatch"), Vector2(16, 1))
	_flat(Vector2(STORE.size.x * K, 0.5), to3(Vector2(STORE.get_center().x, STORE.end.y + 18), 0.007), hatch)
	for pad in [Vector2(560, 205), Vector2(700, 205)]:  # the old pump islands, flush concrete pads
		_flat(Vector2(110, 26) * K, to3(pad, 0.006), _pixel_mat(game.tex("concrete"), Vector2(2, 1)))
	for i in 9:  # wear on the lot
		_decal("crack", Vector2(rng.randf_range(lot.position.x + 60, lot.end.x - 60), rng.randf_range(lot.position.y + 40, lot.end.y - 40)), rng.randf() * TAU, rng.randf_range(1.2, 2.0), 0.008)
	for i in 7:
		_decal("oil_stain", Vector2(rng.randf_range(lot.position.x + 60, lot.end.x - 60), rng.randf_range(lot.position.y + 40, lot.end.y - 40)), rng.randf() * TAU, rng.randf_range(1.0, 1.6), 0.008)
	# The rundown car, rusting on the dirt beside the lot.
	var wreck := Node3D.new()
	add_child(wreck)
	var q := PlaneMesh.new()
	q.size = Vector2(30, 16) * PX
	for i in 16:
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = _slice_mat("rust", i / 2)
		mi.position = Vector3(0, 0.03 + i * CAR_SLICE_GAP * 0.5, 0)
		wreck.add_child(mi)
	wreck.position = to3(Vector2(60, 430))
	wreck.rotation = Vector3(0.06, 1.2, 0.04)  # sagging on a flat tyre
	_upright(game.tex("tire_pile"), to3(Vector2(66, 540), 0.44), true)
	_upright(game.tex("dumpster"), to3(Vector2(1085, 236), 0.48), true)
	for t in [Vector2(1075, 645), Vector2(-20, 640), Vector2(330, 110)]:
		_upright(game.tex("tree"), to3(t, 1.12), true)
	_build_everyday()


## Dust motes drifting through the morning light.
func _build_dust() -> void:
	var dust := CPUParticles3D.new()
	dust.amount = 140
	dust.lifetime = 9.0
	dust.preprocess = 9.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(12, 1.6, 6)
	dust.position = Vector3(11.5, 1.8, 7.0)
	dust.direction = Vector3(1, 0.1, 0.3)
	dust.spread = 60.0
	dust.gravity = Vector3(0, -0.02, 0)
	dust.initial_velocity_min = 0.05
	dust.initial_velocity_max = 0.25
	dust.scale_amount_min = 0.6
	dust.scale_amount_max = 1.4
	var mote := QuadMesh.new()
	mote.size = Vector2(0.035, 0.035)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.billboard_keep_scale = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1.0, 0.92, 0.75, 0.55)
	m.emission_enabled = true
	m.emission = Color(1.0, 0.85, 0.6)
	m.emission_energy_multiplier = 0.6
	mote.material = m
	dust.mesh = mote
	add_child(dust)


func _wall_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.95
	return m


func _box(size: Vector3, at: Vector3, mat: Material) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = b
	mi.material_override = mat
	mi.position = at
	add_child(mi)
	return mi


func _upright(tex: Texture2D, at: Vector3, billboard := false, lit := true) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.pixel_size = PX
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	s.shaded = lit
	s.double_sided = true
	if billboard:
		s.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	s.position = at
	add_child(s)
	return s


## The dépanneur: a box with the claude-pxl storefront on its face, a flat roof, the red curb, the
## GAZ BAR neon (unshaded so it blooms, with a red light that pools on the asphalt), the clock and
## the OUVERT/FERMÉ door_sign.
func _build_store() -> void:
	var r := STORE
	var w := r.size.x * K
	var d := r.size.y * K
	var centre := to3(r.get_center())
	_box(Vector3(w, STORE_H, d), centre + Vector3(0, STORE_H * 0.5, 0), _wall_mat(Color(0.85, 0.79, 0.64)))
	_box(Vector3(w + 0.12, 0.08, d + 0.12), centre + Vector3(0, STORE_H + 0.04, 0), _wall_mat(Color(0.30, 0.29, 0.30)))
	_box(Vector3(w + 0.1, 0.06, 0.12), to3(Vector2(r.get_center().x, r.end.y + 6), 0.03), _wall_mat(Color(0.75, 0.22, 0.18)))
	var front := QuadMesh.new()
	front.size = Vector2(w, STORE_H)
	var face := MeshInstance3D.new()
	face.mesh = front
	face.material_override = _pixel_mat(game.tex("storefront"))
	face.position = to3(Vector2(r.get_center().x, r.end.y), STORE_H * 0.5) + Vector3(0, 0, 0.005)
	add_child(face)
	var door_x := r.position.x + (101.0 / 132.0) * r.size.x
	door_sign = _upright(game.tex("sign_ouvert"), to3(Vector2(door_x, r.end.y), 1.0) + Vector3(0, 0, 0.02))
	door_sign.pixel_size = PX * 0.6
	var clock_at := to3(Vector2(r.position.x + (121.0 / 132.0) * r.size.x, r.end.y), 1.3) + Vector3(0, 0, 0.02)
	_upright(game.tex("clock_face"), clock_at).pixel_size = PX * 0.9
	var hand_mat := _wall_mat(Color(0.08, 0.08, 0.08))
	for hand_len in [0.14, 0.2]:
		var pivot := Node3D.new()
		pivot.position = clock_at + Vector3(0, 0, 0.01)
		add_child(pivot)
		var hand := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.025, hand_len, 0.01)
		hand.mesh = b
		hand.material_override = hand_mat
		hand.position = Vector3(0, hand_len * 0.5, 0)
		pivot.add_child(hand)
		clock_hands.append(pivot)
	# The neon is emissive: it lights up the bloom and casts its red light on the lot.
	_neon_mat = StandardMaterial3D.new()
	_neon_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_neon_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	_neon_mat.emission_enabled = true
	_neon_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var nq := QuadMesh.new()
	var ntex: Texture2D = game.tex("neon_gazbar")
	nq.size = ntex.get_size() * PX
	neon = MeshInstance3D.new()
	neon.mesh = nq
	neon.material_override = _neon_mat
	neon.position = centre + Vector3(0, STORE_H + 0.75, d * 0.5)
	add_child(neon)
	neon_light = OmniLight3D.new()
	neon_light.light_color = Color(1.0, 0.25, 0.18)
	neon_light.omni_range = 7.0
	neon_light.light_energy = 1.4
	neon_light.position = centre + Vector3(0, STORE_H + 0.6, d * 0.5 + 0.8)
	add_child(neon_light)


func _build_regulars() -> void:
	var bench := _upright(game.tex("bench"), to3(BENCH + Vector2(80, 0), 0.24), true)
	bench.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for r in game.regulars:
		var s := _upright(game.tex(r.sprite + "_sit"), to3(r.pos, 0.94), true)
		regular_sprites.append(s)


# --- Every frame --------------------------------------------------------------------------------

func _process(_dt: float) -> void:
	if not game or not game.hd:
		return
	_sync_cars()
	_sync_puddles()
	_sync_store()
	_sync_props(_dt)


func _slice_mat(stack: String, i: int) -> StandardMaterial3D:
	if not game.tex("stack_%s_%d" % [stack, i]):
		stack = "blue"  # a car type whose sprite stack isn't drawn yet
	var key := "%s_%d" % [stack, i]
	if not _slice_mats.has(key):
		var m := _pixel_mat(game.tex("stack_" + key))
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.roughness = 0.45
		m.metallic_specular = 0.6
		_slice_mats[key] = m
	return _slice_mats[key]


## A car as its 8 claude-pxl slices, doubled to close the gaps: 16 flat quads stacked upward. Each car
## type keeps its own length (the Cadillac is longer than the bazou).
func _make_car(car: ProtoCar) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	var q := PlaneMesh.new()
	var base: Texture2D = game.tex("stack_%s_0" % car.stack)
	q.size = (base.get_size() if base else Vector2(30, 16)) * PX
	for i in 16:
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = _slice_mat(car.stack, i / 2)
		mi.position = Vector3(0, 0.03 + i * CAR_SLICE_GAP * 0.5, 0)
		root.add_child(mi)
	return root


func _sync_cars() -> void:
	for car in _cars.keys():
		if not is_instance_valid(car) or not car in game.cars:
			_cars[car].queue_free()
			_cars.erase(car)
	for car in game.cars:
		if car.phase == ProtoCar.Phase.GONE:
			continue
		if not _cars.has(car):
			_cars[car] = _make_car(car)
		var node: Node3D = _cars[car]
		var anim := car.anim_offsets()
		node.position = to3(car.position, anim.lift * K)
		node.rotation = Vector3(0, -(car.heading + anim.spin), 0)
		node.scale = Vector3(anim.squash.x, (anim.squash.x + anim.squash.y) * 0.5, anim.squash.y)


func _sync_puddles() -> void:
	while _puddles.size() < game.puddles.size():
		var mi := MeshInstance3D.new()
		mi.mesh = PlaneMesh.new()
		add_child(mi)
		_puddles.append(mi)
	for i in _puddles.size():
		var mi := _puddles[i]
		mi.visible = i < game.puddles.size()
		if not mi.visible:
			continue
		var p: Dictionary = game.puddles[i]
		var id := "puddle_s" if p.r < 13.0 else ("puddle_m" if p.r < 28.0 else "puddle_l")
		var tex: Texture2D = game.tex(id)
		if not _puddle_mats.has(id):
			var m := _pixel_mat(tex)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
			m.metallic = 0.35
			m.roughness = 0.12
			m.emission_enabled = true
			m.emission = Color(0.9, 0.6, 0.1)
			m.emission_energy_multiplier = 0.25
			_puddle_mats[id] = m
		mi.material_override = _puddle_mats[id]
		var k: float = 1.4 * clampf(p.r / (tex.get_width() * 0.9), 1.0, 1.8)
		(mi.mesh as PlaneMesh).size = tex.get_size() * PX * k
		mi.position = to3(p.pos, 0.012)


## Every night-shop upgrade shows on the station (#37): node id -> [sprite, world spot, height, flat on
## the facade?]. They pop in the morning after you buy them (GodGame hands the day `owned` at opening).
const PROPS := {
	"flyers": ["prop_sandwich", Vector2(338, 168), 0.4, false],
	"radio_ad": ["prop_antenna", Vector2(60, 132), STORE_H + 0.6, false],
	"billboard": ["prop_billboard", Vector2(760, 22), 0.8, false],  # across the road, facing the lot
	"traffic_light": ["prop_traffic_light", Vector2(250, 118), 0.8, false],
	"grocery": ["prop_grocery", Vector2(96, 166), 1.5, true],
	"car_wash": ["prop_car_wash", Vector2(1098, 330), 0.8, false],
	"loto": ["prop_loto", Vector2(30, 182), 0.56, false],
	"tank_1": ["gas_tank", Vector2(30, 262), 0.7, false, 0.6],  # round 8: the station's industrial tank, smaller
	"tank_2": ["gas_tank", Vector2(30, 330), 0.7, false, 0.6],
	"tank_3": ["gas_tank", Vector2(30, 398), 0.7, false, 0.6],
	"thermos": ["prop_thermos", Vector2(70, 188), 0.38, false],
	"mom_lunch": ["prop_cooler", Vector2(52, 198), 0.24, false],
	"permit": ["prop_lamp", Vector2(430, 118), 0.88, false],
	"cousin": ["prop_cousin", Vector2(218, 178), 0.6, false],
	"tip_sign": ["prop_tip_sign", Vector2(188, 166), 1.36, true],
	"squeegee": ["prop_bucket", Vector2(248, 186), 0.28, false],
	"coffee": ["prop_coffee", Vector2(4, 186), 0.52, false],
	"radio": ["prop_boombox", Vector2(170, 186), 0.42, false],
	"jukebox": ["prop_jukebox", Vector2(262, 180), 0.6, false],
}
## Round 8: the new upgrades, Papa's Garage perks and the CAMION branch on the lot: id -> [sprite, world
## spot, mode]. "stand": upright on the ground (its height from the sprite); "facade": flat on the store
## front at that height in metres (a number); "roof": standing on the store's roof.
const LOT_PROPS := {
	# Papa's Garage perks
	"lucky": ["prop_horseshoe", Vector2(216, 166), 1.6],
	"morning_rush": ["prop_rooster", Vector2(150, 120), "roof"],
	"jackpot": ["prop_slots", Vector2(1150, 252), "stand"],
	"nest_egg": ["prop_clothesline", Vector2(80, -40), "stand"],
	"contract": ["prop_contract", Vector2(60, 166), 0.95],
	"premium": ["prop_super_sign", Vector2(660, 116), "stand"],
	"truck_friend": ["fuel_truck", Vector2(290, 14), "stand"],
	"big_cards": ["prop_card_table", Vector2(430, 636), "stand"],
	"reroll": ["prop_dice", Vector2(530, 646), "stand"],
	"slot": ["prop_display_case", Vector2(160, 166), 0.62],
	"head_start": ["prop_drone_dock", Vector2(1100, 520), "stand"],
	# the upgrades with two parents
	"drive_thru": ["prop_drive_thru", Vector2(-70, 200), "stand"],
	"hockey": ["prop_hockey_net", Vector2(720, 640), "stand"],
	"loyalty": ["prop_loyalty", Vector2(232, 166), 0.92],
	"night_neons": ["prop_night_neon", Vector2(118, 166), 1.26],
	"drone_hangar": ["prop_drone_hangar", Vector2(930, -30), "stand"],
	"chip_truck": ["prop_chip_truck", Vector2(1102, 412), "stand"],
	"price_board": ["prop_price_board", Vector2(560, 116), "stand"],
	"forward_contract": ["prop_contract_board", Vector2(-12, 470), "stand"],
	# the CAMION branch
	"tank_gauge": ["prop_tank_gauge", Vector2(104, 300), "stand"],
	"bulk": ["prop_drums", Vector2(-60, 380), "stand"],
	"used_tanker": ["prop_old_tanker", Vector2(610, 20), "stand"],
}
## The lot's everyday life, always there (round 8).
const EVERYDAY := [
	["prop_ice", Vector2(-44, 140)], ["prop_propane", Vector2(-60, 290)], ["prop_special", Vector2(104, 206)],
	["prop_news_boxes", Vector2(236, 206)], ["prop_air", Vector2(1046, 186)], ["prop_phone_booth", Vector2(1140, 150)],
	["prop_picnic", Vector2(980, 642)], ["prop_moose_sign", Vector2(1070, 34)], ["prop_cow_a", Vector2(180, -140)],
	["prop_cow_b", Vector2(262, -168)], ["prop_cow_a", Vector2(840, -150)], ["prop_steeple", Vector2(1130, -210)],
	["prop_rival", Vector2(470, -40)],  # Chez Gaétan, across the road: always a little dearer
]
var _props := {}  # node id -> {sprite, t}
var _tube: Sprite3D


func _build_everyday() -> void:
	for e in EVERYDAY:
		_stand(e[0], e[1])


## An upright sprite standing on the ground at a world spot (billboarded around the vertical).
func _stand(id: String, at: Vector2) -> Sprite3D:
	var tex := game.tex(id)
	var h := tex.get_height() * PX * 0.5 if tex else 0.5
	return _upright(tex, to3(at, h), true)


func _make_prop(id: String) -> Sprite3D:
	if PROPS.has(id):
		var spec: Array = PROPS[id]
		var spr := _upright(game.tex(spec[0]), to3(spec[1], spec[2]) + (Vector3(0, 0, 0.03) if spec[3] else Vector3.ZERO), not spec[3])
		if spec.size() > 4:
			spr.pixel_size = PX * spec[4]  # drawn smaller than its sprite
		return spr
	var lp: Array = LOT_PROPS[id]
	if lp[2] is String and lp[2] == "stand":
		return _stand(lp[0], lp[1])
	if lp[2] is String and lp[2] == "roof":
		var tex := game.tex(lp[0])
		return _upright(tex, to3(lp[1], STORE_H + 0.08 + tex.get_height() * PX * 0.5), true)
	return _upright(game.tex(lp[0]), to3(lp[1], lp[2]) + Vector3(0, 0, 0.03), false)


func _sync_props(dt: float) -> void:
	for id in PROPS.keys() + LOT_PROPS.keys():
		var have: bool = game.owns_upgrade(id)
		if have and not _props.has(id):
			_props[id] = {"sprite": _make_prop(id), "t": 0.0}
			if id == "permit":  # two lamps
				var second := _upright(game.tex(PROPS.permit[0]), to3(Vector2(720, 118), PROPS.permit[2]), true)
				_props["permit_2"] = {"sprite": second, "t": 0.0}
		elif not have and _props.has(id):
			_props[id].sprite.queue_free()
			_props.erase(id)
			if id == "permit" and _props.has("permit_2"):
				_props["permit_2"].sprite.queue_free()
				_props.erase("permit_2")
	_sync_tube_man()
	for id in _props:  # pop: rise out of the ground with an elastic wobble
		var p: Dictionary = _props[id]
		p.t += dt
		var k: float = clampf(p.t / 0.9, 0.0, 1.0)
		var s := 1.0 + 0.3 * exp(-5.0 * k) * sin(k * PI * 4.0) if k < 1.0 else 1.0
		(p.sprite as Sprite3D).scale = Vector3(s, minf(k * 2.0, 1.0) * s, s)


func _sync_store() -> void:
	var t := game._t
	# Neon: a tired flicker, and the pinball flash on Good or better (Super chases GAZ/BAR).
	var phase := fmod(t, 7.0)
	var id := "neon_gazbar"
	if (phase > 3.1 and phase < 3.22) or (phase > 3.34 and phase < 3.42):
		id = "neon_gazbar_off"
	var energy := 1.4
	if game.neon_flash > 0.0:
		var beat := int(game.neon_flash * (16.0 if game.neon_tier == ScoreTiers.SUPER_PERFECT else 10.0))
		if game.neon_tier == ScoreTiers.SUPER_PERFECT:
			id = ["neon_gazbar", "neon_gaz", "neon_bar", "neon_gazbar_off"][beat % 4]
		else:
			id = "neon_gazbar" if beat % 2 == 0 else "neon_gazbar_off"
		energy = 4.5 if game.neon_tier == ScoreTiers.SUPER_PERFECT else 3.0
	var ntex: Texture2D = game.tex(id)
	_neon_mat.albedo_texture = ntex
	_neon_mat.emission_texture = ntex
	_neon_mat.emission_energy_multiplier = 0.3 if id == "neon_gazbar_off" else (6.0 if game.neon_flash > 0.0 else 3.2)
	neon_light.light_energy = 0.1 if id == "neon_gazbar_off" else energy
	# The door_sign flips between OUVERT and FERMÉ; the clock reads 7 h to 13 h.
	door_sign.texture = game.tex("sign_ouvert" if game.is_open() else "sign_ferme")
	door_sign.scale.x = clampf(absf(cos(game.sign_flip * PI)), 0.15, 1.0)
	var h := game.hour_now()
	if clock_hands.size() == 2:
		clock_hands[0].rotation.z = -(fmod(h, 12.0) / 12.0) * TAU
		clock_hands[1].rotation.z = -fmod(h, 1.0) * TAU
	for i in regular_sprites.size():
		var r: Dictionary = game.regulars[i]
		var pose := RegularsCrew.pose(r)
		var s := regular_sprites[i]
		s.visible = pose != ""  # inside the dépanneur
		if pose == "":
			continue
		s.texture = game.tex(r.sprite + "_" + pose)
		s.flip_h = r.flip
		var bob := 0.04 if RegularsCrew.seated(r) and sin(t * 1.3 + r.bob) > 0.85 else 0.0
		var hop := 0.12 * absf(sin(r.cheer * 12.0)) if r.cheer > 0.0 else 0.0
		s.position = to3(r.pos, (s.texture.get_height() * PX * 0.5 if s.texture else 0.94) + bob + hop)


## Bonhomme gonflable (round 8): dances by the road while you own him; arms up while he holds a car.
func _sync_tube_man() -> void:
	var tier := int(game.perks.get("tube_man", 0)) if game.perks.get("tube_man", 0) > 0 else int(game.mods.get("tube_man", 0))
	if tier <= 0:
		if _tube:
			_tube.queue_free()
			_tube = null
		return
	var strip := game.anim_tex("tube_man")
	if not _tube:
		_tube = _upright(strip, to3(GodPump.TUBE_AT, strip.get_height() * PX * 0.5 if strip else 1.5), true)
	var holding := false
	for car in game.cars:
		if car.phase == ProtoCar.Phase.GRABBED and car.grab_t > ProtoCar.GRAB_UP * 0.6 and car.grab_t < ProtoCar.GRAB_UP + ProtoCar.GRAB_HOLD:
			holding = true
	if holding:
		_tube.texture = game.tex("tube_man_grab")
		_tube.hframes = 1
		_tube.frame = 0
	else:
		_tube.texture = strip
		_tube.hframes = 8
		_tube.frame = int(game._t * 10.0) % 8
