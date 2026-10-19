class_name DayGauge
extends Control
## One bar for the day: the tank's fuel shown in dollars (orange) turns into cash earned today (green)
## as the player pours. A white line marks the morning's fuel value, so tips lift the bar above it
## and wasted fuel drops it below. Makes the cost of overshooting visible (Mastery). Refs #9

const CASH_COLOR := Color(0.35, 0.9, 0.45)
const FUEL_COLOR := Color(1.0, 0.65, 0.15)

## The bar's full height is the morning's fuel value plus this much headroom for tips.
@export var headroom := 0.25

var scale_value := 1.0
var green_share := 0.0
var top_share := 0.0
var line_share := 0.0

var earned_label: Label
var fuel_label: Label

var _back: ColorRect
var _green: ColorRect
var _orange: ColorRect
var _line: ColorRect


func setup(at: Vector2, bar_size: Vector2) -> void:
	position = at
	size = bar_size
	_back = _rect(Color(0.1, 0.1, 0.11))
	_back.size = bar_size
	_orange = _rect(FUEL_COLOR)
	_green = _rect(CASH_COLOR)
	_line = _rect(Color.WHITE)
	earned_label = Greybox.label(self, "", 22, Vector2(-60, -70), Vector2(bar_size.x + 120, 32))
	earned_label.add_theme_color_override("font_color", CASH_COLOR)
	fuel_label = Greybox.label(self, "", 20, Vector2(-60, -38), Vector2(bar_size.x + 120, 30))
	fuel_label.add_theme_color_override("font_color", FUEL_COLOR)
	Greybox.label(self, "TODAY", 18, Vector2(-60, bar_size.y + 6), Vector2(bar_size.x + 120, 28)).modulate = Color(1, 1, 1, 0.6)


## earned_today: cash earned since opening. fuel_value: fuel left, in pump dollars.
## start_value: the fuel value at opening (where the white line sits).
func set_values(earned_today: float, fuel_value: float, start_value: float) -> void:
	scale_value = maxf(start_value * (1.0 + headroom), earned_today + fuel_value)
	scale_value = maxf(scale_value, 1.0)
	green_share = clampf(earned_today / scale_value, 0.0, 1.0)
	top_share = clampf((earned_today + fuel_value) / scale_value, 0.0, 1.0)
	line_share = clampf(start_value / scale_value, 0.0, 1.0)
	_place(_green, 0.0, green_share)
	_place(_orange, green_share, top_share)
	_line.size = Vector2(size.x + 16, 3)
	_line.position = Vector2(-8, size.y * (1.0 - line_share) - 1)
	earned_label.text = "+$%.0f" % earned_today
	fuel_label.text = "$%.0f fuel" % fuel_value


func _place(r: ColorRect, from_share: float, to_share: float) -> void:
	r.size = Vector2(size.x, size.y * maxf(0.0, to_share - from_share))
	r.position = Vector2(0, size.y * (1.0 - to_share))


func _rect(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	add_child(r)
	return r
