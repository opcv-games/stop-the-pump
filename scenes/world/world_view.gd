class_name WorldView
extends Control
## Shows the 3D station behind the HUD, through the painterly shader. Two stages, both at the game's
## base resolution: the world renders in `viewport`, gets painted in `paint_viewport`, and the finished
## painting is scaled to the screen by `display`. Painting at base resolution keeps the shader cheap
## on large screens, and only the world is painted: the HUD on top stays crisp. Refs #22

const PAINTERLY := preload("res://shaders/painterly.gdshader")
const BASE := Vector2i(1152, 648)

var world: StationWorld
var viewport: SubViewport
var paint_viewport: SubViewport
## The canvas inside paint_viewport that carries the painterly material.
var paint: TextureRect
var display: TextureRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport = SubViewport.new()
	viewport.size = BASE
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	world = StationWorld.new()
	world.name = "StationWorld"
	viewport.add_child(world)

	paint_viewport = SubViewport.new()
	paint_viewport.size = BASE
	paint_viewport.disable_3d = true
	paint_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(paint_viewport)
	paint = TextureRect.new()
	paint.size = Vector2(BASE)
	paint.texture = viewport.get_texture()
	var mat := ShaderMaterial.new()
	mat.shader = PAINTERLY
	paint.material = mat
	paint_viewport.add_child(paint)

	display = TextureRect.new()
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_SCALE
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.texture = paint_viewport.get_texture()
	add_child(display)
