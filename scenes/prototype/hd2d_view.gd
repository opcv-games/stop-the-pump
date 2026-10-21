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
const CAR_SLICE_GAP := 0.026
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


func regular_head(i: int) -> Vector2:
	return screen(BENCH + Vector2(18 + i * SEAT_GAP, 0), 1.25)


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
	_env.adjustment_saturation = 1.12
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
	attrs.dof_blur_far_distance = 27.5
	attrs.dof_blur_far_transition = 5.0
	attrs.dof_blur_near_enabled = true
	attrs.dof_blur_near_distance = 23.5
	attrs.dof_blur_near_transition = 2.5
	attrs.dof_blur_amount = 0.2
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
	var dirt := Vector2(40, 30)
	_flat(dirt, Vector3(11.5, -0.01, 7.0), _pixel_mat(game.tex("dirt"), dirt / tile))
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
		var s := _upright(game.tex(r.sprite), to3(BENCH + Vector2(18 + r.seat * SEAT_GAP, 2), 0.52), true)
		regular_sprites.append(s)


# --- Every frame --------------------------------------------------------------------------------

func _process(_dt: float) -> void:
	if not game or not game.hd:
		return
	_sync_cars()
	_sync_puddles()
	_sync_store()


func _slice_mat(stack: String, i: int) -> StandardMaterial3D:
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


## A car as its 8 claude-pxl slices, doubled to close the gaps: 16 flat quads stacked upward.
func _make_car(car: ProtoCar) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	var q := PlaneMesh.new()
	q.size = Vector2(30, 16) * PX
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
		regular_sprites[i].texture = game.tex(r.sprite + ("_cheer" if r.cheer > 0.0 else ""))
		var bob := 0.04 if sin(t * 1.3 + r.bob) > 0.85 else 0.0
		var hop := 0.12 * absf(sin(r.cheer * 12.0)) if r.cheer > 0.0 else 0.0
		regular_sprites[i].position.y = 0.52 + bob + hop
