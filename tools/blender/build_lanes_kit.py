"""Builds the Gas Bar Blues lanes kit: parallel lanes (cars enter top right, leave bottom left),
modular props for Godot to place per lane, the footprint expansion, and decor. Clean low-poly,
and run-down to start: grime, a boarded window, faded paint, oil stains, cracks, weeds, potholes,
a shabby name pylon (Godot writes the player's station name at its NameAnchor), and a weedy vacant
lot with a LOT FOR SALE sign where the footprint expansion goes.

Run (headless):
    blender -b --factory-startup -P tools/blender/build_lanes_kit.py -- <project_root>

Writes:
    assets/art/source/lanes_kit.blend
    assets/art/export/station_scenery.glb  (ground, road, aprons, forecourt + expansion slab,
                                            lane strips 1-5, station, woods, sign, decor)
    assets/art/export/station_props.glb    (Pump, Island, Car: each at the origin, for instancing)
    assets/art/export/station_upgrades.glb (#28: one prop per upgrade, in place; per-pump props
                                            PumpCardReader/PumpSpeedBand/PumpDealSticker at the origin)
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
WHITE = (0.74, 0.72, 0.64, 1)  # dirty off-white: the station starts run-down
ROOF = (0.16, 0.20, 0.18, 1)
WINDOW = (1.0, 0.78, 0.38, 1)
ASPHALT = (0.12, 0.12, 0.13, 1)
LANE_PAINT = (0.62, 0.61, 0.56, 1)  # faded
CONCRETE = (0.50, 0.49, 0.46, 1)
CONCRETE_NEW = (0.60, 0.59, 0.56, 1)
KERB = (0.62, 0.60, 0.55, 1)
GRASS = (0.50, 0.40, 0.17, 1)
GRASS_DARK = (0.27, 0.33, 0.13, 1)
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
OIL = (0.05, 0.05, 0.06, 1)
CRACK = (0.24, 0.23, 0.21, 1)
GRAVEL = (0.44, 0.40, 0.31, 1)
GRIME = (0.42, 0.39, 0.33, 1)
PLANK = (0.40, 0.30, 0.20, 1)
BOARD = (0.70, 0.67, 0.58, 1)


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
		"oil": material("OilStain", OIL, roughness=0.3),
		"crack": material("Crack", CRACK),
		"gravel": material("Gravel", GRAVEL, roughness=1.0),
		"grime": material("Grime", GRIME),
		"plank": material("Plank", PLANK),
		"board": material("SignBoard", BOARD),
		"bulb": material("SignBulb", (1.0, 0.9, 0.6, 1), emission=1.2),
		"bulb_dead": material("DeadBulb", (0.20, 0.19, 0.17, 1)),
		"tank": material("TankWhite", (0.82, 0.82, 0.78, 1), roughness=0.5),
		"yellow": material("WorkYellow", (0.80, 0.62, 0.16, 1), roughness=0.6),
		"blue": material("CardBlue", (0.20, 0.36, 0.72, 1), roughness=0.5),
		"screen": material("CardScreen", (0.55, 0.80, 0.70, 1), emission=0.8),
		"jar": material("JarGlass", (0.70, 0.80, 0.78, 1), roughness=0.1),
		"coins": material("Coins", (0.75, 0.62, 0.30, 1), roughness=0.4),
		"jukebox": material("JukeboxGlow", (1.0, 0.55, 0.38, 1), emission=1.0),
		"poster": material("Poster", (0.78, 0.70, 0.52, 1)),
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
		# Run-down: the left window is boarded up, grime runs down the walls, a stain on the roof.
		box("PlankA", (1.9, 0.08, 0.22), (sx - 1.9, sy - 2.33, 1.95), M["plank"], rot=(0, math.radians(12), 0)),
		box("PlankB", (1.9, 0.08, 0.22), (sx - 1.9, sy - 2.33, 1.45), M["plank"], rot=(0, math.radians(-9), 0)),
		box("GrimeA", (0.5, 0.04, 1.0), (sx + 1.6, sy - 2.27, 0.55), M["grime"]),
		box("GrimeB", (0.3, 0.04, 0.8), (sx - 2.8, sy - 2.27, 0.45), M["grime"]),
		box("GrimeC", (0.25, 0.04, 1.6), (sx + 3.3, sy - 2.27, 2.0), M["grime"]),
		box("RoofStain", (2.2, 1.6, 0.02), (sx - 1.2, sy + 0.6, 3.53), M["grime"]),
	], "Station", col)

	build_name_pylon(col, LANE_X[1] + 5.0, back - 6.0)
	build_vacant_lot(col, base_front, front, w)
	build_dirt(col, back, base_front)

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


def tuft(x, y, h):
	"""A weed tuft: three thin blades leaning out, instead of a box."""
	blades = []
	for k in range(3):
		a = k * 2.1 + random.uniform(-0.3, 0.3)
		blades.append(box("Blade", (0.06, 0.06, h), (x + math.cos(a) * 0.06, y + math.sin(a) * 0.06, h / 2),
		                  M["grass_dark"], rot=(math.cos(a) * 0.35, math.sin(a) * 0.35, 0)))
	return blades


def build_name_pylon(col, px, py):
	"""Roadside pylon with the station's name board. Shabby to start: tilted, rusty posts, a missing
	panel and a dead bulb. Godot puts the player's chosen name on the NameAnchor empty."""
	face = -math.pi / 4  # boards face the isometric camera
	tilt = math.radians(4)
	parts = [
		cylinder("PostL", 0.12, 5.2, (px - 1.5, py + 1.5, 2.6), M["rust"], verts=8),
		cylinder("PostR", 0.12, 5.2, (px + 1.5, py - 1.5, 2.6), M["rust"], verts=8),
		box("Board", (4.8, 0.2, 1.5), (px, py, 4.4), M["board"], rot=(tilt, 0, face)),
		box("Frame", (5.1, 0.16, 1.8), (px + 0.07, py + 0.07, 4.4), M["roof"], rot=(tilt, 0, face)),
		box("MissingPanel", (0.9, 0.22, 0.55), (px + 1.2, py - 1.2, 3.95), M["roof"], rot=(tilt, 0, face)),
		box("GasTop", (1.6, 0.2, 0.7), (px - 0.7, py + 0.7, 5.6), M["rim"], rot=(0, 0, face)),
	]
	for k in range(6):
		t = -2.0 + k * 0.8
		parts.append(sphere("Bulb", 0.09, (px + t * 0.707, py - t * 0.707 - 0.2, 5.2), M["bulb_dead"] if k == 4 else M["bulb"]))
	join(parts, "NamePylon", col)
	anchor = bpy.data.objects.new("NameAnchor", None)
	anchor.location = (px - 0.12, py - 0.12, 4.45)  # just in front of the board
	anchor.rotation_euler = (math.pi / 2 + tilt, 0, face)
	col.objects.link(anchor)


def build_vacant_lot(col, base_front, front, w):
	"""Weedy gravel where the footprint expansion goes, with a LOT FOR SALE sign. Godot hides it
	when the expansion is bought (and shows ForecourtExpansion instead)."""
	parts = [box("Gravel", (w, base_front - front, 0.03), (0, (base_front + front) / 2, 0.015), M["gravel"])]
	for k in range(45):
		parts += tuft(random.uniform(-w / 2 + 0.5, w / 2 - 0.5), random.uniform(front + 0.4, base_front - 0.4), random.uniform(0.3, 0.7))
	join(parts, "VacantLot", col)
	sy = (base_front + front) / 2
	join([
		box("Post", (0.12, 0.12, 1.6), (4.0, sy, 0.8), M["wood"]),
		box("Board", (1.6, 0.08, 0.8), (4.0, sy - 0.05, 1.5), M["sign"], rot=(0, 0, -math.pi / 4)),
		box("Stripe", (1.6, 0.09, 0.18), (4.0, sy - 0.06, 1.75), M["rim"], rot=(0, 0, -math.pi / 4)),
	], "LotForSaleSign", col)


def build_dirt(col, back, base_front):
	"""Oil stains, cracks and potholes on the starting forecourt (the expansion slab is new and clean)."""
	parts = []
	for i in range(BASE_LANES):
		y = lane_y(i) - 0.3
		bpy.ops.mesh.primitive_cylinder_add(radius=1.0, depth=0.01, location=(-0.4, y, 0.082), vertices=10)
		stain = bpy.context.active_object
		stain.scale = (random.uniform(1.0, 1.6), random.uniform(0.5, 0.8), 1)
		stain.data.materials.append(M["oil"])
		parts.append(stain)
	for k in range(14):
		x = random.uniform(LANE_X[0] + 1, LANE_X[1] - 1)
		y = random.uniform(base_front + 0.5, back - 0.5)
		parts.append(box("Crack", (random.uniform(0.8, 2.2), 0.06, 0.01), (x, y, 0.086), M["crack"],
		                 rot=(0, 0, random.uniform(0, math.pi))))
	# Potholes: dark dips with crumbs, in the lanes and on the aprons.
	spots = [(-6.5, lane_y(0) - 0.8), (5.5, lane_y(1) - 0.1), (-3.0, lane_y(2) - 0.9), (8.5, lane_y(2) + 0.2),
	         (LANE_X[1] + 2.2, lane_y(1)), (LANE_X[0] - 1.6, lane_y(2) - 1.5), (LANE_X[1] + 1.6, ROAD_Y + 4.0)]
	for (x, y) in spots:
		r = random.uniform(0.35, 0.6)
		bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=0.012, location=(x, y, 0.088), vertices=9)
		hole = bpy.context.active_object
		hole.scale = (1.0, random.uniform(0.6, 0.9), 1)
		hole.data.materials.append(M["oil"])
		parts.append(hole)
		for c in range(4):
			a = random.uniform(0, 2 * math.pi)
			parts.append(box("Crumb", (0.12, 0.12, 0.05), (x + math.cos(a) * (r + 0.15), y + math.sin(a) * (r + 0.1), 0.09), M["crack"]))
	# Weeds along the slab edges.
	for k in range(30):
		x = random.uniform(LANE_X[0], LANE_X[1])
		y = random.choice([back + 0.05, base_front - 0.05]) + random.uniform(-0.2, 0.2)
		parts += tuft(x, y, random.uniform(0.25, 0.5))
	join(parts, "Dirt", col)


def build_upgrades(col):
	"""One prop per upgrade (#28), placed where it sits on the station. Godot hides them all and pops
	each one in when its upgrade is bought. Per-pump props are built at the pump's origin."""
	back = lane_y(0) + LANE_W / 2 + 1.6
	sx, sy = 2.0, back + 4.2
	front_y = sy - 2.27

	# Marketing: sandwich board at the entrance, antenna on the roof, billboard across the road.
	join([
		box("SideA", (1.0, 0.06, 1.3), (13.6, -3.0, 0.6), M["wood"], rot=(math.radians(14), 0, -math.pi / 4)),
		box("SideB", (1.0, 0.06, 1.3), (13.75, -2.85, 0.6), M["wood"], rot=(math.radians(-14), 0, -math.pi / 4)),
		box("PosterA", (0.8, 0.02, 0.9), (13.55, -3.08, 0.68), M["poster"], rot=(math.radians(14), 0, -math.pi / 4)),
	], "UpFlyers", col)
	parts = [cylinder("Mast", 0.06, 3.4, (sx + 2.6, sy + 1.2, 3.5 + 1.7), M["steel"], verts=6)]
	for k, w in enumerate([1.4, 1.0, 0.6]):
		parts.append(box("Bar", (w, 0.05, 0.05), (sx + 2.6, sy + 1.2, 4.4 + k * 0.8), M["steel"], rot=(0, 0, -math.pi / 4)))
	parts.append(sphere("Tip", 0.08, (sx + 2.6, sy + 1.2, 6.95), M["rim"]))
	join(parts, "UpRadioAd", col)
	# Open sand right of the entrance, between apron and road: off the asphalt and clear of the HUD (playtest 20).
	bx, by, k = 21.3, -9.0, 0.72  # k: billboard scale
	join([
		cylinder("LegL", 0.15 * k, 4.2 * k, (bx - 2.0 * k, by + 2.0 * k, 2.1 * k), M["wood"], verts=6),
		cylinder("LegR", 0.15 * k, 4.2 * k, (bx + 2.0 * k, by - 2.0 * k, 2.1 * k), M["wood"], verts=6),
		box("Board", (6.5 * k, 0.25, 2.6 * k), (bx, by, 4.7 * k), M["board"], rot=(0, 0, -math.pi / 4)),
		box("Frame", (6.8 * k, 0.2, 2.9 * k), (bx + 0.08, by + 0.08, 4.7 * k), M["roof"], rot=(0, 0, -math.pi / 4)),
		box("Stripe", (6.5 * k, 0.27, 0.35 * k), (bx - 0.01, by - 0.01, 5.65 * k), M["rim"], rot=(0, 0, -math.pi / 4)),
	], "UpBillboard", col)
	anchor = bpy.data.objects.new("BillboardAnchor", None)  # Godot can write on the board here
	anchor.location = (bx - 0.16, by - 0.16, 4.5 * k)
	anchor.rotation_euler = (math.pi / 2, 0, -math.pi / 4)
	col.objects.link(anchor)

	# Tank: up to three white tanks on cradles beside the house (capacity at a glance).
	for k in range(3):
		tx = -7.6 - k * 2.4
		join([
			cylinder("Tank", 0.85, 3.2, (tx, sy + 0.5, 1.25), M["tank"], rot=(math.pi / 2, 0, 0), verts=16),
			box("CradleA", (1.4, 0.3, 0.5), (tx, sy - 0.6, 0.25), M["steel"]),
			box("CradleB", (1.4, 0.3, 0.5), (tx, sy + 1.6, 0.25), M["steel"]),
			box("Band", (1.75, 0.12, 0.12), (tx, sy + 0.5, 2.12), M["rim"]),
		], "UpTank_%d" % (k + 1), col)

	# Service: squeegee bucket at the first island, tip jar by the door, pressure washer at the exit.
	isl_y = lane_y(0) + 1.25
	join([
		cylinder("Bucket", 0.22, 0.4, (3.05, isl_y, 0.42), M["blue"], verts=10),
		box("Handle", (0.04, 0.04, 1.0), (3.05, isl_y + 0.05, 0.9), M["wood"], rot=(math.radians(18), 0, 0)),
		box("Blade", (0.45, 0.05, 0.1), (3.05, isl_y + 0.2, 1.38), M["tyre"]),
	], "UpSqueegee", col)
	join([
		box("Stand", (0.35, 0.35, 0.9), (sx + 1.0, front_y - 0.35, 0.45), M["wood"]),
		cylinder("Jar", 0.16, 0.36, (sx + 1.0, front_y - 0.35, 1.08), M["jar"], verts=12),
		cylinder("Coins", 0.14, 0.12, (sx + 1.0, front_y - 0.35, 0.96), M["coins"], verts=12),
	], "UpTipJar", col)
	wx, wy = LANE_X[0] - 1.6, back - 2.2
	join([
		box("Cart", (0.9, 0.6, 0.7), (wx, wy, 0.55), M["yellow"]),
		cylinder("WheelA", 0.2, 0.1, (wx - 0.3, wy - 0.33, 0.2), M["tyre"], rot=(math.pi / 2, 0, 0), verts=10),
		cylinder("WheelB", 0.2, 0.1, (wx + 0.3, wy - 0.33, 0.2), M["tyre"], rot=(math.pi / 2, 0, 0), verts=10),
		box("Lance", (0.05, 0.05, 1.1), (wx + 0.35, wy, 1.2), M["steel"], rot=(0, math.radians(20), 0)),
		torus("Hose", 0.3, 0.05, (wx, wy + 0.36, 0.6), M["tyre"], rot=(math.pi / 2, 0, 0)),
	], "UpPressureWasher", col)

	# Vibe: console radio by the bench, glowing jukebox on the porch.
	join([
		box("Cabinet", (0.8, 0.45, 1.0), (sx + 4.6, front_y - 0.4, 0.5), M["wood"]),
		box("Grille", (0.6, 0.02, 0.4), (sx + 4.6, front_y - 0.63, 0.55), M["roof"]),
		cylinder("Dial", 0.08, 0.02, (sx + 4.6, front_y - 0.63, 0.88), M["coins"], rot=(math.pi / 2, 0, 0), verts=10),
	], "UpRadio", col)
	jx = sx - 4.6
	join([
		box("Body", (0.95, 0.6, 1.5), (jx, front_y - 0.45, 0.75), M["wood"]),
		cylinder("Arch", 0.475, 0.6, (jx, front_y - 0.45, 1.5), M["wood"], rot=(math.pi / 2, 0, 0), verts=16),
		box("Glow", (0.7, 0.04, 0.9), (jx, front_y - 0.77, 0.9), M["jukebox"]),
		cylinder("GlowArch", 0.35, 0.04, (jx, front_y - 0.77, 1.5), M["jukebox"], rot=(math.pi / 2, 0, 0), verts=16),
	], "UpJukebox", col)

	# Per-pump props, at the pump's origin (pump body 0.75 x 0.55 x 1.7, display facing -Y).
	# The reader sits on the pump's -X side, which faces the camera (the +X side is hidden).
	join([
		box("Reader", (0.26, 0.34, 0.55), (-0.52, 0, 1.05), M["blue"]),
		box("Screen", (0.03, 0.22, 0.16), (-0.66, -0.02, 1.2), M["screen"]),
	], "PumpCardReader", col)
	join([box("Band", (0.8, 0.6, 0.22), (0, 0, 0.55), M["yellow"])], "PumpSpeedBand", col)
	join([box("Sticker", (0.02, 0.2, 0.14), (-0.665, -0.02, 0.92), M["sign"])], "PumpDealSticker", col)


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
		parts += tuft(random.uniform(-2, 2), random.choice([-1.1, 1.1]) + random.uniform(-0.2, 0.2), random.uniform(0.4, 0.7))
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
	expanded = lanes > BASE_LANES
	bpy.data.objects["ForecourtExpansion"].hide_render = not expanded
	bpy.data.objects["VacantLot"].hide_render = expanded
	bpy.data.objects["LotForSaleSign"].hide_render = expanded
	for i in range(MAX_LANES):
		bpy.data.objects["Lane_%d" % (i + 1)].hide_render = i >= lanes


def preview_name(col):
	"""Review renders only: an example name on the pylon. Not exported; Godot writes the real name."""
	anchor = bpy.data.objects["NameAnchor"]
	bpy.ops.object.text_add(location=anchor.location, rotation=anchor.rotation_euler)
	text = bpy.context.active_object
	text.data.body = "HANK'S GAS BAR"
	text.data.align_x = "CENTER"
	text.data.align_y = "CENTER"
	text.data.size = 0.55
	text.data.extrude = 0.01
	text.data.materials.append(M["roof"])
	for c in text.users_collection:
		c.objects.unlink(text)
	bpy.context.scene.collection.objects.link(text)


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
	upgrades = new_collection("Upgrades")
	build_props(props)
	build_scenery(scenery)
	build_upgrades(upgrades)

	src = os.path.join(ROOT, "assets", "art", "source")
	exp = os.path.join(ROOT, "assets", "art", "export")
	docs = os.path.join(ROOT, "docs", "art")
	for d in (src, exp, docs):
		os.makedirs(d, exist_ok=True)
	export(list(scenery.objects), os.path.join(exp, "station_scenery.glb"))
	export(list(props.objects), os.path.join(exp, "station_props.glb"))
	export(list(upgrades.objects), os.path.join(exp, "station_upgrades.glb"))

	preview_name(review)
	camera_and_light()
	for o in props.objects:
		o.hide_render = True  # the originals sit at the origin; the review layout uses copies
	per_pump = [bpy.data.objects[n] for n in ("PumpCardReader", "PumpSpeedBand", "PumpDealSticker")]
	for o in upgrades.objects:
		o.hide_render = True
	for lanes in (BASE_LANES, MAX_LANES):
		layout(review, lanes)
		bpy.context.scene.render.filepath = os.path.join(docs, "lanes_%d.png" % lanes)
		bpy.ops.render.render(write_still=True)
		print("RENDERED", lanes)
	# Fully upgraded station (#28): every station prop, and pumps 3-5 self-serve with all three per-pump props.
	layout(review, MAX_LANES)
	for o in upgrades.objects:
		o.hide_render = o in per_pump
	for i in range(2, MAX_LANES):
		for prop in per_pump:
			c = prop.copy()
			c.location = (0.6, lane_y(i) + 1.25, 0.22)
			c.hide_render = False
			review.objects.link(c)
	bpy.context.scene.render.filepath = os.path.join(docs, "upgrades_all.png")
	bpy.ops.render.render(write_still=True)
	print("RENDERED upgrades")
	bpy.ops.wm.save_as_mainfile(filepath=os.path.join(src, "lanes_kit.blend"))
	print("KIT_DONE")


main()
