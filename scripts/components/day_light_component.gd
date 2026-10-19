class_name DayLightComponent
extends Node
## The day clock drives the light (art direction, DESIGN.md 9b): low warm sun at 7am, high white
## light in the afternoon, a gold then blue dusk, and at night the light comes from the windows,
## porch lamp and pump globes. Keyframes are blended hour by hour. Serves: Immersion, readability. Refs #22

## hour, sun elevation and azimuth (degrees; azimuth 0 = east, 90 = toward the camera side, 180 = west),
## sun colour, sun energy, sky colour, ambient energy, night glow multiplier.
const KEYS := [
	[7.0, 6.0, 10.0, Color(1.0, 0.70, 0.48), 1.1, Color(0.78, 0.60, 0.46), 0.45, 0.6],
	[10.0, 32.0, 40.0, Color(1.0, 0.88, 0.74), 1.5, Color(0.76, 0.72, 0.64), 0.55, 0.2],
	[14.0, 68.0, 95.0, Color(1.0, 0.97, 0.92), 1.9, Color(0.72, 0.77, 0.82), 0.65, 0.15],
	[17.5, 22.0, 150.0, Color(1.0, 0.72, 0.45), 1.3, Color(0.86, 0.62, 0.42), 0.5, 0.5],
	[19.5, 2.0, 170.0, Color(0.95, 0.45, 0.30), 0.35, Color(0.38, 0.26, 0.30), 0.3, 1.6],
	[21.0, 40.0, 250.0, Color(0.55, 0.62, 1.0), 0.15, Color(0.06, 0.07, 0.13), 0.12, 3.2],
	[23.0, 50.0, 270.0, Color(0.50, 0.58, 1.0), 0.12, Color(0.02, 0.025, 0.06), 0.08, 3.6],
]

@export var sun: DirectionalLight3D
@export var environment: Environment
## Point lights near the windows and pumps; their energy scales with the night glow.
@export var glow_lights: Array[OmniLight3D] = []
## Emissive materials (windows, globes); their emission scales with the night glow.
@export var glow_materials: Array[StandardMaterial3D] = []

var hour := 7.0
var _glow_base := {}


static func sample(h: float) -> Dictionary:
	h = clampf(h, KEYS[0][0], KEYS[-1][0])
	var i := 0
	while i < KEYS.size() - 2 and h > KEYS[i + 1][0]:
		i += 1
	var a: Array = KEYS[i]
	var b: Array = KEYS[i + 1]
	var t := 0.0 if b[0] == a[0] else clampf((h - a[0]) / (b[0] - a[0]), 0.0, 1.0)
	return {
		"elevation": lerpf(a[1], b[1], t),
		"azimuth": lerpf(a[2], b[2], t),
		"sun_color": (a[3] as Color).lerp(b[3], t),
		"sun_energy": lerpf(a[4], b[4], t),
		"sky": (a[5] as Color).lerp(b[5], t),
		"ambient": lerpf(a[6], b[6], t),
		"glow": lerpf(a[7], b[7], t),
	}


func apply_hour(h: float) -> void:
	hour = h
	var s := sample(h)
	if sun:
		var el := deg_to_rad(s.elevation)
		var az := deg_to_rad(s.azimuth)
		var toward_sun := Vector3(cos(el) * cos(az), sin(el), cos(el) * sin(az))
		sun.transform = Transform3D(Basis.looking_at(-toward_sun), toward_sun * 30.0)
		sun.light_color = s.sun_color
		sun.light_energy = s.sun_energy
	if environment:
		environment.background_color = s.sky
		environment.ambient_light_color = s.sky.lerp(Color.WHITE, 0.25)
		environment.ambient_light_energy = s.ambient
	for l in glow_lights:
		if not _glow_base.has(l):
			_glow_base[l] = l.light_energy
		l.light_energy = _glow_base[l] * s.glow
	for m in glow_materials:
		if not _glow_base.has(m):
			_glow_base[m] = m.emission_energy_multiplier
		m.emission_energy_multiplier = _glow_base[m] * s.glow
