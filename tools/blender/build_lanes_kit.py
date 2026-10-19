"""Builds the Gas Bar Blues lanes kit: parallel lanes (cars enter top right, leave bottom left),
modular props for Godot to place per lane, the footprint expansion, and decor. Clean low-poly.

Run (headless):
    blender -b --factory-startup -P tools/blender/build_lanes_kit.py -- <project_root>

Writes:
    assets/art/source/lanes_kit.blend
    assets/art/export/station_scenery.glb  (ground, road, aprons, forecourt + expansion slab,
                                            lane strips 1-5, station, woods, sign, decor)
    assets/art/export/station_props.glb    (Pump, Island, Car: each at the origin, for instancing)
    docs/art/lanes_3.png, docs/art/lanes_5.png  (review renders)
Affordances: docs/art/AFFORDANCES.md. Refs #23

World layout (Blender axes, Z up): lanes run along X. Cars drive toward -X, which the isometric
camera (at -X,-Y) shows as top right -> bottom left. Lane i (0-based) is centred at y = LANE_Y0 - i * LANE_W.
"""
import math
import os
import random
import sys

import bpy

ROOT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.getcwd()
random.seed(1940)

LANE_W = 3.4
LANE_Y0 = 5.0
LANE_X = (-11.0, 11.0)   # lane strip extent along the direction of travel
BASE_LANES = 3
MAX_LANES = 5
ROAD_Y = LANE_Y0 - MAX_LANES * LANE_W - 2.6

# --- Palette: pumps are the only saturated red; everything else muted ---------------------------
RED = (0.55, 0.04, 0.03, 1)
WHITE = (0.86, 0.85, 0.80, 1)
ROOF = (0.16, 0.20, 0.18, 1)
WINDOW = (1.0, 0.78, 0.38, 1)
ASPHALT = (0.12, 0.12, 0.13, 1)
LANE_PAINT = (0.85, 0.84, 0.78, 1)
CONCRETE = (0.50, 0.49, 0.46, 1)
CONCRETE_NEW = (0.60, 0.59, 0.56, 1)
KERB = (0.62, 0.60, 0.55, 1)
GRASS = (0.50, 0.40, 0.17, 1)
GRASS_DARK = (0.36, 0.33, 0.14, 1)
WOODS = (0.06, 0.13, 0.09, 1)
TRUNK = (0.12, 0.08, 0.05, 1)
CAR = (0.33, 0.38, 0.45, 1)
GLASS = (0.20, 0.25, 0.30, 1)
TYRE = (0.04, 0.04, 0.04, 1)
RUST = (0.38, 0.22, 0.13, 1)
OLIVE = (0.30, 0.34, 0.22, 1)
TEAL = (0.20, 0.33, 0.33, 1)
WOOD = (0.36, 0.25, 0.16, 1)
STEEL = (0.45, 0.46, 0.47, 1)
SIGN = (0.80, 0.78, 0.72, 1)


def reset():
	bpy.ops.wm.read_factory_settings(use_empty=True)


def material(name, color, emission=0.0, roughness=0.8):
	m = bpy.data.materials.get(name) or bpy.data.materials.new(name)
	m.use_nodes = True
	bsdf = m.node_tree.nodes.get("Principled BSDF")
	bsdf.inputs["Base Color"].default_value = color
	bsdf.inputs["Roughness"].default_value = roughness
	if emission > 0:
		bsdf.inputs["Emission Color"].default_value = color
		bsdf.inputs["Emission Strength"].default_value = emission
	return m


M = {}


def mats():
	M.update({
		"red": material("PumpRed", RED, roughness=0.5),
		"white": material("StationWhite", WHITE),
		"roof": material("Roof", ROOF),
		"window": material("WindowLight", WINDOW, emission=2.0),
		"globe": material("PumpGlobe", (1.0, 0.95, 0.85, 1), emission=1.5, roughness=0.3),
		"display": material("PumpDisplay", (0.92, 0.92, 0.88, 1), emission=0.3),
		"asphalt": material("Asphalt", ASPHALT, roughness=0.9),
		"paint": material("LanePaint", LANE_PAINT),
		"concrete": material("Concrete", CONCRETE),
		"concrete_new": material("ConcreteNew", CONCRETE_NEW),
		"kerb": material("Kerb", KERB),
		"grass": material("DryGrass", GRASS),
		"grass_dark": material("GrassTufts", GRASS_DARK),
		"woods": material("Woods", WOODS),
		"trunk": material("Trunk", TRUNK),
		"car": material("CarBody", CAR, roughness=0.4),
		"glass": material("CarGlass", GLASS, roughness=0.2),
		"tyre": material("Tyre", TYRE),
		"rust": material("Rust", RUST, roughness=0.95),
		"olive": material("BarrelOlive", OLIVE),
		"teal": material("BarrelTeal", TEAL),
		"wood": material("Wood", WOOD),
		"steel": material("Steel", STEEL, roughness=0.5),
		"sign": material("Sign", SIGN),
		"rim": material("SignRim", (0.32, 0.10, 0.08, 1)),
		"vending": material("VendingGlow", (0.70, 0.78, 0.80, 1), emission=0.6),
	})


def box(name, size, loc, mat, rot=(0, 0, 0)):
	bpy.ops.mesh.primitive_cube_add(size=1, location=loc, rotation=rot)
	o = bpy.context.active_object
	o.name = name
	o.scale = size
	bpy.ops.object.transform_apply(scale=True)
	o.data.materials.append(mat)
	return o


def cylinder(name, r, depth, loc, mat, rot=(0, 0, 0), verts=16):
	bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, rotation=rot, vertices=verts)
	o = bpy.context.active_object
	o.name = name
	o.data.materials.append(mat)
	return o


def sphere(name, r, loc, mat):
	bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=16, ring_count=8)
	o = bpy.context.active_object
	o.name = name
	o.data.materials.append(mat)
	return o


def torus(name, r, tube, loc, mat, rot=(0, 0, 0)):
	bpy.ops.mesh.primitive_torus_add(major_radius=r, minor_radius=tube, location=loc, rotation=rot,
	                                 major_segments=16, minor_segments=8)
	o = bpy.context.active_object
	o.name = name
	o.data.materials.append(mat)
	return o


def join(objs, name, collection):
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	bpy.context.view_layer.objects.active = objs[0]
	bpy.ops.object.join()
	o = objs[0]
	o.name = name
	for c in o.users_collection:
		c.objects.unlink(o)
	collection.objects.link(o)
	return o


def new_collection(name):
	c = bpy.data.collections.new(name)
	bpy.context.scene.collection.children.link(c)
	return c


def lane_y(i):
	return LANE_Y0 - i * LANE_W


# --- Props: built at the origin so Godot can place one per lane --------------------------------

def build_props(col):
	# Pump: tall, red, globe on top; display faces -Y (toward its lane and the camera).
	join([
		box("Body", (0.75, 0.55, 1.7), (0, 0, 0.85), M["red"]),
		box("Base", (0.95, 0.75, 0.15), (0, 0, 0.075), M["roof"]),
		box("Display", (0.55, 0.06, 0.4), (0, -0.29, 1.2), M["display"]),
		box("Hose", (0.08, 0.08, 0.9), (0.42, 0, 0.9), M["tyre"]),
		sphere("Globe", 0.27, (0, 0, 1.98), M["globe"]),
	], "Pump", col)
	# Island: low kerb the pump stands on, along the lane.
	join([box("Kerb", (4.2, 1.0, 0.22), (0, 0, 0.11), M["kerb"])], "Island", col)
	# Car: low and long, front toward -X (direction of travel).
	parts = [
		box("Body", (3.8, 1.7, 0.7), (0, 0, 0.55), M["car"]),
		box("Cabin", (2.0, 1.5, 0.55), (0.2, 0, 1.15), M["glass"]),
	]
	for dx in (-1.2, 1.2):
		for dy in (-0.85, 0.85):
			parts.append(cylinder("Wheel", 0.33, 0.3, (dx, dy, 0.33), M["tyre"], rot=(math.pi / 2, 0, 0)))
	join(parts, "Car", col)


# --- Scenery -----------------------------------------------------------------------------------

def build_scenery(col):
	front = lane_y(MAX_LANES - 1) - LANE_W / 2 - 0.6
	base_front = lane_y(BASE_LANES - 1) - LANE_W / 2 - 0.6
	back = lane_y(0) + LANE_W / 2 + 1.6
	join([box("Ground", (90, 90, 0.1), (0, 0, -0.05), M["grass"])], "Ground", col)

	# Road along the bottom; aprons lead in at the top right (+X) and out at the bottom left (-X).
	join([box("Road", (90, 6, 0.04), (0, ROAD_Y, 0.02), M["asphalt"])], "Road", col)
	join([
		box("ApronIn", (4.0, back - ROAD_Y, 0.05), (LANE_X[1] + 2.0, (back + ROAD_Y) / 2, 0.025), M["asphalt"]),
		box("ApronOut", (4.0, back - ROAD_Y, 0.05), (LANE_X[0] - 2.0, (back + ROAD_Y) / 2, 0.025), M["asphalt"]),
	], "Aprons", col)

	# Forecourt: the starting slab (3 lanes) and the expansion slab (lanes 4-5), shown by Godot when bought.
	w = LANE_X[1] - LANE_X[0]
	join([box("Slab", (w, back - base_front, 0.06), (0, (back + base_front) / 2, 0.03), M["concrete"])], "Forecourt", col)
	join([box("SlabNew", (w, base_front - front, 0.06), (0, (base_front + front) / 2, 0.03), M["concrete_new"])],
	     "ForecourtExpansion", col)

	# Lane strips with arrows pointing the way cars go (-X). One object per lane so Godot can hide unused ones.
	for i in range(MAX_LANES):
		y = lane_y(i)
		parts = [box("Strip", (w, 2.3, 0.02), (0, y - 0.3, 0.07), M["asphalt"])]
		for ax in (-6.0, 6.0):
			parts.append(box("ArrowShaft", (1.6, 0.18, 0.01), (ax + 0.3, y - 0.3, 0.085), M["paint"]))
			bpy.ops.mesh.primitive_cone_add(vertices=3, radius1=0.45, depth=0.01, location=(ax - 0.75, y - 0.3, 0.085),
			                                rotation=(0, 0, math.pi))
			head = bpy.context.active_object
			head.data.materials.append(M["paint"])
			parts.append(head)
		join(parts, "Lane_%d" % (i + 1), col)

	# Station behind the lanes (top left on screen), windows facing the forecourt.
	sx, sy = 2.0, back + 4.2
	join([
		box("Walls", (7.0, 4.5, 3.2), (sx, sy, 1.6), M["white"]),
		box("RoofSlab", (7.8, 5.3, 0.35), (sx, sy, 3.35), M["roof"]),
		box("Window_L", (1.6, 0.06, 1.1), (sx - 1.9, sy - 2.27, 1.7), M["window"]),
		box("Window_R", (1.6, 0.06, 1.1), (sx + 1.9, sy - 2.27, 1.7), M["window"]),
		box("Door", (0.9, 0.06, 2.0), (sx, sy - 2.27, 1.0), M["roof"]),
		sphere("PorchLamp", 0.18, (sx, sy - 2.45, 2.6), M["globe"]),
	], "Station", col)

	# Sign pole at the entrance (top right), facing the camera.
	join([
		cylinder("Pole", 0.09, 4.4, (LANE_X[1] + 4.5, back - 2.0, 2.2), M["roof"]),
		cylinder("Disc", 0.9, 0.14, (LANE_X[1] + 4.44, back - 2.06, 4.4), M["sign"], rot=(math.pi / 2, 0, -math.pi / 4), verts=32),
		cylinder("Rim", 1.0, 0.1, (LANE_X[1] + 4.52, back - 1.98, 4.4), M["rim"], rot=(math.pi / 2, 0, -math.pi / 4), verts=32),
	], "SignPole", col)

	build_decor(col, sx, sy, back)

	# Woods: rounded dark masses behind and around, kept clear of lanes, road and house.
	trees = []
	for _ in range(220):
		x = random.uniform(-40, 40)
		y = random.uniform(back + 2, 42) if random.random() < 0.7 else random.uniform(ROAD_Y - 22, 42)
		near_station = -22 < x < 24 and y < back + 10.5  # lanes, aprons, house and decor stay clear
		near_road = abs(y - ROAD_Y) < 6
		if near_station or near_road:
			continue
		h = random.uniform(4.5, 9.0)
		for k in range(random.randint(2, 3)):
			bpy.ops.mesh.primitive_ico_sphere_add(radius=random.uniform(1.4, 2.3), subdivisions=1,
			                                      location=(x + random.uniform(-1, 1), y + random.uniform(-1, 1), h - k * 1.6))
			blob = bpy.context.active_object
			blob.scale = (1.0, 1.0, random.uniform(1.1, 1.5))
			blob.data.materials.append(M["woods"])
			trees.append(blob)
		trees.append(cylinder("Trunk", 0.2, h - 2.0, (x, y, (h - 2.0) / 2), M["trunk"], verts=6))
	join(trees, "Woods", col)


def build_decor(col, sx, sy, back):
	# Broken-down car beside the house: on blocks, flat tyre, missing door, rust, grass. Never a customer.
	bx, by = sx + 6.6, back + 2.6  # front corner of the house: visible, but off the forecourt
	rot = math.radians(24)
	parts = [
		box("Body", (3.6, 1.6, 0.65), (0, 0, 0.75), M["rust"]),
		box("Cabin", (1.8, 1.45, 0.5), (0.3, 0, 1.3), M["rust"]),
		box("Hood", (1.0, 1.5, 0.06), (-1.6, 0, 1.45), M["rust"], rot=(0, math.radians(-55), 0)),
		box("BlockA", (0.5, 0.5, 0.45), (-1.1, -0.6, 0.22), M["concrete"]),
		box("BlockB", (0.5, 0.5, 0.45), (1.1, 0.6, 0.22), M["concrete"]),
		cylinder("FlatTyre", 0.33, 0.3, (1.1, -0.85, 0.2), M["tyre"], rot=(math.pi / 2, 0, 0)),
	]
	for k in range(9):
		parts.append(box("Tuft", (0.25, 0.25, random.uniform(0.3, 0.6)),
		                 (random.uniform(-2, 2), random.choice([-1.1, 1.1]) + random.uniform(-0.2, 0.2), 0.2), M["grass_dark"]))
	car = join(parts, "BrokenCar", col)
	car.rotation_euler = (0, 0, rot)
	car.location = (bx, by, 0)

	# Tyre pile by the other corner of the house.
	tyres = []
	for k, (dx, dy, dz) in enumerate([(0, 0, 0.15), (0.7, 0.1, 0.15), (0.35, 0.05, 0.45), (0.35, 0.7, 0.15), (0.3, 0.6, 0.45), (0.4, 0.3, 0.75)]):
		tyres.append(torus("Tyre", 0.36, 0.14, (sx - 6.0 + dx, sy - 0.5 + dy, dz), M["tyre"]))
	join(tyres, "TirePile", col)

	# Oil barrels.
	join([
		cylinder("Barrel1", 0.33, 0.95, (sx - 4.6, sy + 1.4, 0.48), M["olive"]),
		cylinder("Barrel2", 0.33, 0.95, (sx - 3.9, sy + 1.7, 0.48), M["teal"]),
		cylinder("Barrel3", 0.33, 0.95, (sx - 4.3, sy + 2.3, 0.48), M["olive"]),
	], "Barrels", col)

	# Bench and vending machine against the house front.
	join([
		box("Seat", (1.8, 0.5, 0.08), (sx + 3.2, sy - 2.65, 0.5), M["wood"]),
		box("Back", (1.8, 0.08, 0.5), (sx + 3.2, sy - 2.45, 0.85), M["wood"]),
		box("LegL", (0.08, 0.45, 0.5), (sx + 2.4, sy - 2.65, 0.25), M["steel"]),
		box("LegR", (0.08, 0.45, 0.5), (sx + 4.0, sy - 2.65, 0.25), M["steel"]),
	], "Bench", col)
	join([
		box("Cabinet", (0.9, 0.7, 1.9), (sx - 3.0, sy - 2.65, 0.95), M["teal"]),
		box("Front", (0.6, 0.04, 1.2), (sx - 3.0, sy - 3.02, 1.15), M["vending"]),
	], "VendingMachine", col)

	# Air pump post by the entrance, phone booth by the exit.
	join([
		box("Post", (0.35, 0.35, 1.3), (LANE_X[1] + 1.2, back + 0.4, 0.65), M["steel"]),
		box("Gauge", (0.3, 0.06, 0.3), (LANE_X[1] + 1.2, back + 0.2, 1.05), M["sign"]),
		torus("Hose", 0.25, 0.04, (LANE_X[1] + 1.2, back + 0.15, 0.7), M["tyre"], rot=(math.pi / 2, 0, 0)),
	], "AirPump", col)
	join([
		box("Booth", (1.0, 1.0, 2.3), (LANE_X[0] - 0.8, back + 0.8, 1.15), M["steel"]),
		box("Roof", (1.15, 1.15, 0.15), (LANE_X[0] - 0.8, back + 0.8, 2.37), M["roof"]),
		box("Panel", (0.7, 0.05, 1.4), (LANE_X[0] - 0.8, back + 0.28, 1.3), M["glass"]),
	], "PhoneBooth", col)


# --- Review layout: place props per lane, like Godot will --------------------------------------

def layout(col, lanes):
	for o in list(col.objects):
		bpy.data.objects.remove(o, do_unlink=True)
	pump = bpy.data.objects["Pump"]
	island = bpy.data.objects["Island"]
	car = bpy.data.objects["Car"]
	for i in range(lanes):
		y = lane_y(i)
		for src, loc in ((island, (0.6, y + 1.25, 0)), (pump, (0.6, y + 1.25, 0.22))):
			o = src.copy()
			o.location = loc
			o.hide_render = False  # the hidden originals pass their flag to copies
			col.objects.link(o)
		if i in (0, 2, 3):
			c = car.copy()
			c.location = (-0.4 + (i % 2) * 0.4, y - 0.3, 0.07)
			c.hide_render = False
			col.objects.link(c)
	bpy.data.objects["ForecourtExpansion"].hide_render = lanes <= BASE_LANES
	for i in range(MAX_LANES):
		bpy.data.objects["Lane_%d" % (i + 1)].hide_render = i >= lanes


def camera_and_light():
	scene = bpy.context.scene
	target = bpy.data.objects.new("CameraTarget", None)
	target.location = (1.5, lane_y(1), 0.8)
	scene.collection.objects.link(target)
	cam_data = bpy.data.cameras.new("IsoCamera")
	cam_data.type = "ORTHO"
	cam_data.ortho_scale = 42
	cam = bpy.data.objects.new("IsoCamera", cam_data)
	cam.location = (target.location.x - 30, target.location.y - 30, 30.0)
	scene.collection.objects.link(cam)
	t = cam.constraints.new("TRACK_TO")
	t.target = target
	t.track_axis = "TRACK_NEGATIVE_Z"
	t.up_axis = "UP_Y"
	scene.camera = cam

	sun_target = bpy.data.objects.new("SunTarget", None)
	scene.collection.objects.link(sun_target)
	sun_data = bpy.data.lights.new("Sun", "SUN")
	sun_data.energy = 4.0
	sun_data.color = (1.0, 0.95, 0.88)
	sun = bpy.data.objects.new("Sun", sun_data)
	sun.location = (12, -6, 30)
	scene.collection.objects.link(sun)
	c = sun.constraints.new("TRACK_TO")
	c.target = sun_target
	c.track_axis = "TRACK_NEGATIVE_Z"
	c.up_axis = "UP_Y"
	world = bpy.data.worlds.new("World")
	scene.world = world
	world.use_nodes = True
	world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.72, 0.76, 0.80, 1)
	world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6

	for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
		try:
			scene.render.engine = engine
			break
		except TypeError:
			continue
	scene.render.resolution_x = 1152
	scene.render.resolution_y = 648


def export(objs, path):
	bpy.ops.object.select_all(action="DESELECT")
	for o in objs:
		o.select_set(True)
	bpy.ops.export_scene.gltf(filepath=path, export_format="GLB", use_selection=True,
	                          export_lights=False, export_cameras=False)


def main():
	reset()
	mats()
	props = new_collection("Props")
	scenery = new_collection("Scenery")
	review = new_collection("ReviewLayout")
	build_props(props)
	build_scenery(scenery)

	src = os.path.join(ROOT, "assets", "art", "source")
	exp = os.path.join(ROOT, "assets", "art", "export")
	docs = os.path.join(ROOT, "docs", "art")
	for d in (src, exp, docs):
		os.makedirs(d, exist_ok=True)
	export(list(scenery.objects), os.path.join(exp, "station_scenery.glb"))
	export(list(props.objects), os.path.join(exp, "station_props.glb"))

	camera_and_light()
	for o in props.objects:
		o.hide_render = True  # the originals sit at the origin; the review layout uses copies
	for lanes in (BASE_LANES, MAX_LANES):
		layout(review, lanes)
		bpy.context.scene.render.filepath = os.path.join(docs, "lanes_%d.png" % lanes)
		bpy.ops.render.render(write_still=True)
		print("RENDERED", lanes)
	bpy.ops.wm.save_as_mainfile(filepath=os.path.join(src, "lanes_kit.blend"))
	print("KIT_DONE")


main()
