class_name GasTankArt
extends RefCounted
## The station's gas tank as a gauge (round 8): the gold in its sight glass and the needle on its dial,
## drawn over the gas_tank sprite (assets/art/pixel/station.px.js) wherever it's shown: the night
## screen's GAS TANK panel and the delivery. Serves: tension (how much gas is left, at a glance).

const GLASS := Rect2(63, 11, 3, 27)  # inside the sight glass, PNG pixels
const DIAL := Vector2(13, 25)
const NEEDLE := 5.0


## `at` is the sprite's top-left on screen, `scale` its pixel size, `level` 0..1.
static func draw_level(ci: CanvasItem, at: Vector2, scale: float, level: float, t := 0.0) -> void:
	level = clampf(level, 0.0, 1.0)
	var glass := Rect2(at + GLASS.position * scale, GLASS.size * scale)
	var h := glass.size.y * level
	var low := level < 0.2
	var gas := GodPump.GAS if not low else GodPump.GAS.lerp(Color(1, 0.3, 0.2), 0.5 + 0.5 * sin(t * 6.0))
	ci.draw_rect(Rect2(glass.position.x, glass.end.y - h, glass.size.x, h), gas)
	if h > scale:
		ci.draw_rect(Rect2(glass.position.x, glass.end.y - h, glass.size.x, scale), Color(1, 0.95, 0.7))  # the surface
	ci.draw_rect(Rect2(glass.position.x, glass.position.y, scale, glass.size.y), Color(1, 1, 1, 0.18))  # the glass's glint
	# The dial: E on the left, F on the right, the needle swings with the level.
	var a := PI * (1.1 - 1.2 * level)
	var c := at + (DIAL + Vector2(0.5, 0.5)) * scale
	ci.draw_line(c, c + Vector2(cos(a), -sin(a)) * NEEDLE * scale, Color(0.75, 0.12, 0.1), maxf(scale * 0.7, 1.5))
	ci.draw_circle(c, scale * 0.8, Color(0.1, 0.1, 0.1))
