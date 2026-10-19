class_name WorldView
extends Control
## Shows the 3D station behind the HUD. The world renders in its own SubViewport (sized to the window
## for crisp edges) so the HUD on top is never affected. Clean low-poly: the painterly filter tried in
## v0.20 was removed after review. Refs #22, #24

var world: StationWorld
var viewport: SubViewport
var display: TextureRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	add_child(viewport)
	world = StationWorld.new()
	world.name = "StationWorld"
	viewport.add_child(world)
	display = TextureRect.new()
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_SCALE
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.texture = viewport.get_texture()
	add_child(display)
	_fit_to_window()
	get_tree().root.size_changed.connect(_fit_to_window)


## Render at the window's real pixel size (not the 1152x648 layout size) so edges stay sharp.
func _fit_to_window() -> void:
	var s := get_tree().root.size
	viewport.size = Vector2i(maxi(s.x, 1152), maxi(s.y, 648))
