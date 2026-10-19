"""Builds the Gas Bar Blues station kit after Hopper's "Gas" (1940) and renders isometric look tests.

Run (headless):
    blender -b --factory-startup -P tools/blender/build_station_kit.py -- <project_root>

Writes:
    assets/art/source/station_kit.blend   (source)
    assets/art/export/station_kit.glb     (meshes + materials for Godot; no lights or camera)
    docs/art/look_test_{morning,afternoon,night}.png
Affordances: docs/art/AFFORDANCES.md. Refs #21
"""
import math
import os
import random
import sys

import bpy
from mathutils import Vector

ROOT = sys.argv[sys.argv.index("--") + 1] if "--" in sys.argv else os.getcwd()
random.seed(1940)

# --- Palette (Hopper's Gas): pumps are the only saturated red; the world is muted -------------
RED = (0.55, 0.04, 0.03, 1)
WHITE = (0.86, 0.85, 0.80, 1)
ROOF = (0.16, 0.20, 0.18, 1)
WINDOW = (1.0, 0.78, 0.38, 1)
ASPHALT = (0.11, 0.11, 0.12, 1)
CONCRETE = (0.48, 0.47, 0.44, 1)
GRASS = (0.50, 0.40, 0.17, 1)
WOODS = (0.04, 0.10, 0.07, 1)
TRUNK = (0.10, 0.07, 0.05, 1)
CAR = (0.33, 0.38, 0.45, 1)
TYRE = (0.03, 0.03, 0.03, 1)
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


def box(name, size, loc, mat, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(mat)
    if parent:
        o.parent = parent
    return o


def cylinder(name, r, depth, loc, mat, rot=(0, 0, 0), verts=24):
    bpy.ops.mesh.primitive_cylinder_add(radius=r, depth=depth, location=loc, rotation=rot, vertices=verts)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(mat)
    return o


def sphere(name, r, loc, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r, location=loc, segments=24, ring_count=12)
    o = bpy.context.active_object
    o.name = name
    o.data.materials.append(mat)
    bpy.ops.object.shade_smooth()
    return o


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    objs[0].name = name
    return objs[0]


def build_kit():
    m = {
        "red": material("PumpRed", RED, roughness=0.5),
        "white": material("StationWhite", WHITE),
        "roof": material("Roof", ROOF),
        "window": material("WindowLight", WINDOW, emission=2.0),
        "globe": material("PumpGlobe", (1.0, 0.95, 0.85, 1), emission=1.5, roughness=0.3),
        "display": material("PumpDisplay", (0.92, 0.92, 0.88, 1), emission=0.3),
        "asphalt": material("Asphalt", ASPHALT, roughness=0.9),
        "concrete": material("Concrete", CONCRETE),
        "grass": material("DryGrass", GRASS),
        "woods": material("Woods", WOODS),
        "trunk": material("Trunk", TRUNK),
        "car": material("CarBody", CAR, roughness=0.4),
        "tyre": material("Tyre", TYRE),
        "sign": material("Sign", SIGN),
        "rim": material("SignRim", (0.32, 0.10, 0.08, 1)),
    }

    # Ground, road (cars come from the left), forecourt.
    box("Ground", (60, 60, 0.1), (0, 0, -0.05), m["grass"])
    box("Road", (60, 6, 0.04), (0, -6.5, 0.02), m["asphalt"])
    box("Forecourt", (16, 7, 0.06), (0, -0.5, 0.03), m["concrete"])

    # Station: small white box, dark roof, warm windows and a porch lamp.
    station = [
        box("Walls", (6, 4, 3.2), (4.5, 5.0, 1.6), m["white"]),
        box("RoofSlab", (6.8, 4.8, 0.35), (4.5, 5.0, 3.35), m["roof"]),
        box("Window_L", (1.4, 0.06, 1.1), (3.0, 2.97, 1.7), m["window"]),
        box("Window_R", (1.4, 0.06, 1.1), (6.0, 2.97, 1.7), m["window"]),
        box("Door", (0.9, 0.06, 2.0), (4.5, 2.97, 1.0), m["roof"]),
        sphere("PorchLamp", 0.18, (4.5, 2.8, 2.6), m["globe"]),
    ]
    join(station, "Station")

    # Pumps: tall, red, globe on top, display facing the camera. Instanced in Godot per bay.
    for i, x in enumerate([-3.0, -0.4, 2.2]):
        parts = [
            box("Body", (0.75, 0.55, 1.7), (x, -1.0, 0.85), m["red"]),
            box("Base", (0.95, 0.75, 0.15), (x, -1.0, 0.075), m["roof"]),
            box("Display", (0.55, 0.06, 0.4), (x, -1.29, 1.2), m["display"]),
            box("Hose", (0.08, 0.08, 0.9), (x + 0.42, -1.0, 0.9), m["tyre"]),
            sphere("Globe", 0.27, (x, -1.0, 1.98), m["globe"]),
        ]
        join(parts, "Pump_%d" % (i + 1))

    # A car waiting at pump 2: low and long (the pumps are tall and upright).
    car = [
        box("Body", (1.8, 3.8, 0.7), (-0.4, -3.4, 0.55), m["car"]),
        box("Cabin", (1.5, 2.0, 0.55), (-0.4, -3.6, 1.15), m["car"]),
    ]
    for dx in (-0.85, 0.85):
        for dy in (-1.2, 1.2):
            car.append(cylinder("Wheel", 0.33, 0.3, (-0.4 + dx, -3.4 + dy, 0.33), m["tyre"], rot=(0, math.pi / 2, 0)))
    join(car, "Car")

    # Sign pole with a round sign, framing the left like Hopper's Mobilgas sign.
    sign = [
        cylinder("Pole", 0.09, 6.0, (-7.0, 1.5, 3.0), m["roof"]),
        # Face the isometric camera (which looks from -X,-Y): disc axis along (-1,-1,0).
        # Off-white face with a thin muted rim: it must never outshine the pumps (affordance check 2).
        cylinder("Disc", 0.9, 0.14, (-7.06, 1.44, 6.0), m["sign"], rot=(math.pi / 2, 0, -math.pi / 4), verts=32),
        cylinder("Rim", 1.0, 0.1, (-6.98, 1.52, 6.0), m["rim"], rot=(math.pi / 2, 0, -math.pi / 4), verts=32),
    ]
    join(sign, "SignPole")

    # Woods: dense, rounded dark masses behind the station, Hopper-style (deepest values in the scene).
    # Kept out of the foreground so nothing hides the pumps or the road.
    trees = []
    for _ in range(170):
        x = random.uniform(-30, 30)
        y = random.uniform(-4, 30)
        in_front = y < 8 and -14 < x < 16
        if in_front or y < -3 + (x + 30) * 0.05:
            continue
        h = random.uniform(4.5, 9.0)
        for k in range(random.randint(2, 3)):
            r = random.uniform(1.4, 2.3)
            bpy.ops.mesh.primitive_ico_sphere_add(radius=r, subdivisions=2,
                location=(x + random.uniform(-1, 1), y + random.uniform(-1, 1), h - k * 1.6))
            blob = bpy.context.active_object
            blob.scale = (1.0, 1.0, random.uniform(1.1, 1.5))
            blob.data.materials.append(m["woods"])
            trees.append(blob)
        trees.append(cylinder("Trunk", 0.2, h - 2.0, (x, y, (h - 2.0) / 2), m["trunk"], verts=6))
    join(trees, "Woods")


def camera():
    target = bpy.data.objects.new("CameraTarget", None)
    target.location = (0.5, 1.0, 0.8)
    bpy.context.collection.objects.link(target)
    cam_data = bpy.data.cameras.new("IsoCamera")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = 24
    cam = bpy.data.objects.new("IsoCamera", cam_data)
    cam.location = (-25.0, -25.0, 25.0)  # true isometric: 45° around, ~35° down
    bpy.context.collection.objects.link(cam)
    track = cam.constraints.new("TRACK_TO")
    track.target = target
    track.track_axis = "TRACK_NEGATIVE_Z"
    track.up_axis = "UP_Y"
    bpy.context.scene.camera = cam


TIMES = {
    # sun position (tracked to the origin), sun colour, sun strength, sky colour, emission multiplier
    "morning": ((30, 4, 7), (1.0, 0.80, 0.58), 3.5, (0.80, 0.66, 0.52), 0.6),
    "afternoon": ((6, -8, 40), (1.0, 0.97, 0.90), 4.5, (0.72, 0.78, 0.84), 0.4),
    "night": ((-10, 20, 30), (0.45, 0.55, 1.0), 0.12, (0.01, 0.015, 0.04), 6.0),
}


def light_for(time_name):
    for o in [o for o in bpy.data.objects if o.type == "LIGHT" or o.name == "SunTarget"]:
        bpy.data.objects.remove(o, do_unlink=True)
    pos, color, strength, sky, glow = TIMES[time_name]
    sun_target = bpy.data.objects.new("SunTarget", None)
    bpy.context.collection.objects.link(sun_target)
    sun_data = bpy.data.lights.new("Sun", "SUN")
    sun_data.color = color
    sun_data.energy = strength
    sun_data.angle = math.radians(3)
    sun = bpy.data.objects.new("Sun", sun_data)
    sun.location = pos
    bpy.context.collection.objects.link(sun)
    c = sun.constraints.new("TRACK_TO")
    c.target = sun_target
    c.track_axis = "TRACK_NEGATIVE_Z"
    c.up_axis = "UP_Y"
    world = bpy.context.scene.world or bpy.data.worlds.new("World")
    bpy.context.scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes.get("Background")
    bg.inputs["Color"].default_value = (*sky, 1)
    bg.inputs["Strength"].default_value = 0.6 if time_name != "night" else 0.3
    for name, base in (("WindowLight", 2.0), ("PumpGlobe", 1.5)):
        mat = bpy.data.materials[name]
        mat.node_tree.nodes["Principled BSDF"].inputs["Emission Strength"].default_value = base * glow
    if time_name == "night":
        # Light that spills onto the forecourt: windows and pump globes.
        for i, loc in enumerate([(4.5, 1.5, 2.6), (-3.0, -1.6, 2.6), (-0.4, -1.6, 2.6), (2.2, -1.6, 2.6)]):
            ld = bpy.data.lights.new("Glow%d" % i, "POINT")
            ld.color = (1.0, 0.8, 0.5)
            ld.energy = 450 if i == 0 else 160
            lo = bpy.data.objects.new("Glow%d" % i, ld)
            lo.location = loc
            bpy.context.collection.objects.link(lo)


def render_settings():
    scene = bpy.context.scene
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            scene.render.engine = engine
            break
        except TypeError:
            continue
    scene.render.resolution_x = 1152
    scene.render.resolution_y = 648
    scene.render.film_transparent = False
    try:
        scene.eevee.taa_render_samples = 32
    except AttributeError:
        pass
    scene.view_settings.view_transform = "AgX" if "AgX" in [i.name for i in type(scene.view_settings).bl_rna.properties["view_transform"].enum_items] else "Filmic"


def main():
    reset()
    build_kit()
    camera()
    render_settings()

    src = os.path.join(ROOT, "assets", "art", "source")
    exp = os.path.join(ROOT, "assets", "art", "export")
    docs = os.path.join(ROOT, "docs", "art")
    for d in (src, exp, docs):
        os.makedirs(d, exist_ok=True)

    # Export the meshes only: Godot owns the camera and the light (day clock).
    bpy.ops.object.select_all(action="DESELECT")
    for o in bpy.data.objects:
        if o.type == "MESH":
            o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(exp, "station_kit.glb"), export_format="GLB",
                              use_selection=True, export_lights=False, export_cameras=False)

    for t in ("morning", "afternoon", "night"):
        light_for(t)
        bpy.context.scene.render.filepath = os.path.join(docs, "look_test_%s.png" % t)
        bpy.ops.render.render(write_still=True)
        print("RENDERED", t)

    light_for("morning")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(src, "station_kit.blend"))
    print("KIT_DONE")


main()
