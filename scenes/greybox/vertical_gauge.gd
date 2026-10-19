class_name VerticalGauge
extends Control
## Flat greybox gauge: a solid fill plus an optional lighter "ghost" above it (e.g. cash you could
## still earn from the fuel left in the tank). Deleted or reskinned in Phase 4. Refs #8

var fill_color := Color(0.35, 0.9, 0.45)
var ghost_color := Color(0.35, 0.9, 0.45, 0.3)

var _back: ColorRect
var _ghost: ColorRect
var _fill: ColorRect
var value_label: Label


func setup(title: String, at: Vector2, bar_size: Vector2, fill: Color) -> void:
	position = at
	size = bar_size
	fill_color = fill
	ghost_color = Color(fill, 0.3)
	_back = _rect(Color(0.1, 0.1, 0.11))
	_ghost = _rect(ghost_color)
	_fill = _rect(fill_color)
	value_label = Greybox.label(self, "", 22, Vector2(-40, -36), Vector2(bar_size.x + 80, 32))
	Greybox.label(self, title, 18, Vector2(-40, bar_size.y + 6), Vector2(bar_size.x + 80, 28)).modulate = Color(1, 1, 1, 0.6)
	_back.size = bar_size


## fill and ghost are 0..1 shares of the bar height; ghost is measured from the bottom too.
func set_levels(fill: float, ghost := 0.0) -> void:
	fill = clampf(fill, 0.0, 1.0)
	ghost = clampf(maxf(ghost, fill), 0.0, 1.0)
	_place(_fill, fill)
	_place(_ghost, ghost)


func _place(r: ColorRect, share: float) -> void:
	r.size = Vector2(size.x, size.y * share)
	r.position = Vector2(0, size.y - r.size.y)


func _rect(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	add_child(r)
	return r
