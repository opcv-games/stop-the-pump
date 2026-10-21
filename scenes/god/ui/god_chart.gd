class_name GodChart
extends RefCounted
## Small charts for the newspaper, the menu screen and the run's last front page (round 8).
## One series per chart, one axis (two measures get two charts), thin marks, a hairline grid, the
## last point emphasised and labelled; the title says what it is. Text stays in ink, not the line's
## colour. A chart with fewer than two values draws just the number. Serves: Advancement (your run,
## read at a glance).


## A line over time: `values` in order, labelled with `fmt` (e.g. "$%.2f").
static func line(ci: CanvasItem, r: Rect2, values: Array, title: String, fmt: String, ink: Color, mark: Color, f: Font) -> void:
	ci.draw_string(f, r.position + Vector2(0, 12), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ink)
	var plot := Rect2(r.position + Vector2(4, 22), r.size - Vector2(8, 34))
	if values.size() < 2:  # one value isn't a chart
		var v := fmt % (values[0] if not values.is_empty() else 0.0)
		ci.draw_string(f, plot.position + Vector2(0, plot.size.y * 0.6), v, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, ink)
		return
	var lo: float = values.min()
	var hi: float = values.max()
	if hi - lo < 0.0001:
		hi = lo + 1.0
	lo -= (hi - lo) * 0.08
	for i in 3:  # hairline grid, solid
		var gy := plot.position.y + plot.size.y * i / 2.0
		ci.draw_line(Vector2(plot.position.x, gy), Vector2(plot.end.x, gy), Color(ink, 0.12), 1.0)
	var pts := PackedVector2Array()
	for i in values.size():
		var k := float(i) / (values.size() - 1)
		pts.append(Vector2(plot.position.x + plot.size.x * k, plot.end.y - plot.size.y * (float(values[i]) - lo) / (hi - lo)))
	ci.draw_polyline(pts, mark, 2.0, true)
	ci.draw_circle(pts[-1], 4.0, mark)
	ci.draw_circle(pts[-1], 1.6, Color(1, 1, 1, 0.9))
	var first := fmt % values[0]
	var last := fmt % values[-1]
	ci.draw_string(f, Vector2(plot.position.x, r.end.y - 1), first, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(ink, 0.7))
	var lw := f.get_string_size(last, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	ci.draw_string(f, Vector2(plot.end.x - lw, r.end.y - 1), last, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ink)


## Bars, one per value (runs, oldest first); `hi_index` is drawn in the mark colour, the rest muted.
static func bars(ci: CanvasItem, r: Rect2, values: Array, title: String, ink: Color, mark: Color, f: Font, cap := 0.0, hi_index := -1) -> void:
	ci.draw_string(f, r.position + Vector2(0, 12), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ink)
	var plot := Rect2(r.position + Vector2(0, 22), r.size - Vector2(0, 36))
	if values.size() < 2:
		var v := str(values[0]) if not values.is_empty() else "-"
		ci.draw_string(f, plot.position + Vector2(0, plot.size.y * 0.6), v, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, ink)
		return
	var hi: float = maxf(values.max(), cap)
	ci.draw_line(Vector2(plot.position.x, plot.end.y), Vector2(plot.end.x, plot.end.y), Color(ink, 0.3), 1.0)
	if cap > 0.0:  # a hairline at the goal (day 50)
		var gy := plot.end.y - plot.size.y * cap / hi
		ci.draw_line(Vector2(plot.position.x, gy), Vector2(plot.end.x, gy), Color(ink, 0.25), 1.0)
		ci.draw_string(f, Vector2(plot.end.x - 22, gy - 3), str(int(cap)), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(ink, 0.6))
	var n := values.size()
	var slot := plot.size.x / n
	var bw := maxf(slot - 2.0, 2.0)  # a 2px gap between bars
	for i in n:
		var h := plot.size.y * float(values[i]) / hi
		var col := mark if i == hi_index or (hi_index < 0 and i == n - 1) else Color(mark, 0.45)
		var bar := Rect2(plot.position.x + i * slot + 1.0, plot.end.y - h, bw, h)
		ci.draw_rect(bar, col)
	var last := str(values[-1])
	ci.draw_string(f, Vector2(plot.end.x - f.get_string_size(last, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x, r.end.y - 1), last, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ink)
