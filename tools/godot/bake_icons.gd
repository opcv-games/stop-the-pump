extends SceneTree
## Bakes one icon per upgrade from the 3D kit (#31): each prop seen through the game's isometric
## angle on a transparent background, saved to assets/art/icons/<id>.png. The upgrade tree uses them
## so a node shows the very thing it adds to the station (affordance).
##
##     godot --path . -s tools/godot/bake_icons.gd        (needs a window: it renders)

const SIZE := 160
const OUT := "res://assets/art/icons/"
const KITS := {
	"props": "res://assets/art/export/station_props.glb",
	"upgrades": "res://assets/art/export/station_upgrades.glb",
	"scenery": "res://assets/art/export/station_scenery.glb",
}
## icon id: [kit, node, on a pump?]
const ICONS := {
	"station": ["scenery", "Station"],
	"pump": ["props", "Pump"],
	"expand": ["scenery", "LotForSaleSign"],
	"flyers": ["upgrades", "UpFlyers"],
	"radio_ad": ["upgrades", "UpRadioAd"],
	"billboard": ["upgrades", "UpBillboard"],
	"tank": ["upgrades", "UpTank_1"],
	"squeegee": ["upgrades", "UpSqueegee"],
	"tip_jar": ["upgrades", "UpTipJar"],
	"pressure_washer": ["upgrades", "UpPressureWasher"],
	"bluesy_radio": ["upgrades", "UpRadio"],
	"jukebox": ["upgrades", "UpJukebox"],
	# Per-pump props are shown on a pump, as in the game: alone they are just a box or a sticker.
	"self_service": ["upgrades", "PumpCardReader", true],
	"faster_self_serve": ["upgrades", "PumpSpeedBand", true],
	"card_deal": ["upgrades", "PumpDealSticker", true],
}
const VIEW_DIR := Vector3(-28.5, 30.0, 28.4)  # the game camera's direction (StationWorld.CAMERA_POS)

var _vp: SubViewport
var _cam: Camera3D
var _holder: Node3D
var _queue: Array = []
var _wait := 0
var _current := ""


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_vp = SubViewport.new()
	_vp.size = Vector2i(SIZE, SIZE)
	_vp.transparent_bg = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(_vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.85, 0.82, 0.78)
	env.environment.ambient_light_energy = 0.7
	_vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -35, 0)
	sun.light_energy = 1.3
	sun.light_color = Color(1.0, 0.92, 0.8)
	_vp.add_child(sun)
	_cam = Camera3D.new()
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_vp.add_child(_cam)
	_cam.current = true
	_queue = ICONS.keys()


func _process(_d: float) -> bool:
	if _wait > 0:
		_wait -= 1
		if _wait == 0:
			_vp.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + _current + ".png"))
			print("icon ", _current)
		return false
	if _holder:
		_holder.queue_free()
		_holder = null
	if _queue.is_empty():
		return true
	_current = _queue.pop_front()
	var spec: Array = ICONS[_current]
	var kit: Node3D = load(KITS[spec[0]]).instantiate()
	var src: Node3D = kit.get_node(spec[1])
	_holder = Node3D.new()
	_vp.add_child(_holder)
	var prop: Node3D = src.duplicate()
	prop.visible = true
	_holder.add_child(prop)
	kit.free()
	if spec.size() > 2 and spec[2]:
		var props: Node3D = load(KITS.props).instantiate()
		var pump: Node3D = props.get_node("Pump").duplicate()
		props.free()
		pump.position = Vector3.ZERO
		prop.position = Vector3.ZERO
		_holder.add_child(pump)
	var box := _bounds(_holder)
	var centre := box.get_center()
	var reach := box.size.length() * 0.5
	_cam.size = reach * 2.1
	_cam.look_at_from_position(centre + VIEW_DIR.normalized() * (reach + 20.0), centre)
	_wait = 4
	return false


func _bounds(n: Node) -> AABB:
	var box := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false) + ([n] if n is MeshInstance3D else []):
		var b: AABB = mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box
