class_name NamingScreen
extends Control
## Name your gaz bar (first run, and whenever you like from the title). It goes up on the sign.

signal named(text: String)

var input: LineEdit


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	input = LineEdit.new()
	input.max_length = 20
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	input.position = Vector2(326, 300)
	input.size = Vector2(500, 60)
	input.add_theme_font_size_override("font_size", 30)
	input.text_submitted.connect(func(t: String) -> void: named.emit(t.strip_edges() if t.strip_edges() != "" else "GAZ BAR"))
	add_child(input)


func show_naming(current: String) -> void:
	visible = true
	input.text = current
	if input.is_inside_tree():
		input.grab_focus()
		input.caret_column = input.text.length()


func _draw() -> void:
	GodUI.dim(self, size, 0.8)
	GodUI.text(self, Vector2(576, 230), tr("NAME YOUR GAZ BAR"), 40, GodUI.GOLD, true)
	GodUI.text(self, Vector2(576, 270), tr("It goes up on the sign."), 18, GodUI.CREAM, true)
	GodUI.text(self, Vector2(576, 400), tr("ENTER to open"), 17, Color(GodUI.CREAM, 0.6), true)
