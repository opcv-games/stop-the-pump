class_name Greybox
## Tiny helpers for flat-color greybox UI. Deleted in Phase 4.


static func label(parent: Node, text: String, font_size: int, pos: Vector2, box: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = box
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	parent.add_child(l)
	return l
