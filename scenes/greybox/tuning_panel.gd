class_name TuningPanel
extends CanvasLayer
## F2: sliders for every number in Tuning.PARAMS. Pauses the game while open; saves on every change.
## Greybox tool for the designer, not part of the shipped game. Refs #13

var _station: Node
var _defaults := {}
var _sliders := {}
var _values := {}
var _status: Label


func setup(station: Node) -> void:
	_station = station
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	# Defaults = the values the scene was built with, before any saved tuning.
	var fresh: Node = load("res://scenes/greybox/pump_station.tscn").instantiate()
	fresh.tuning_file = ""
	_defaults = _defaults_from(fresh)
	_build()


## The station is paused while the panel is open, so the panel listens for F2 itself.
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("toggle_tuning"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	visible = not visible
	get_tree().paused = visible
	if visible:
		_refresh()


func _defaults_from(fresh: Node) -> Dictionary:
	# Read the defaults without adding the scene to the tree: build the parts it needs by hand.
	var values := {}
	var economy := FuelEconomy.new()
	var tiers := ScoreTiers.new()
	var parts := {
		"station": fresh, "economy": economy, "tiers": tiers, "combo": ComboComponent.new(),
		"tank": TankComponent.new(), "clock": DayClock.new(), "sound": SoundFeedback.new(),
	}
	for p in Tuning.PARAMS:
		var bits: PackedStringArray = p.key.split("/")
		values[p.key] = parts[bits[0]].get(bits[1])
	for part in parts.values():
		if part is Node:
			part.free()
	return values


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.06, 0.07, 0.96)
	dim.size = Vector2(1152, 648)
	add_child(dim)

	Greybox.label(dim, "TUNING  (game paused, F2 to close, changes save automatically)", 20, Vector2(0, 8), Vector2(1152, 30))

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(76, 44)
	scroll.size = Vector2(1000, 520)
	dim.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 18)
	scroll.add_child(grid)
	for p in Tuning.PARAMS:
		var name := Label.new()
		name.text = p.label + ("  (new run)" if p.get("restart", false) else "")
		name.custom_minimum_size = Vector2(360, 26)
		name.add_theme_font_size_override("font_size", 16)
		grid.add_child(name)
		var slider := HSlider.new()
		slider.min_value = p.min
		slider.max_value = p.max
		slider.step = p.step
		slider.custom_minimum_size = Vector2(420, 26)
		grid.add_child(slider)
		var value := Label.new()
		value.custom_minimum_size = Vector2(120, 26)
		value.add_theme_font_size_override("font_size", 16)
		grid.add_child(value)
		_sliders[p.key] = slider
		_values[p.key] = value
		slider.value_changed.connect(_on_slider.bind(p.key))

	var buttons := HBoxContainer.new()
	buttons.position = Vector2(76, 580)
	buttons.add_theme_constant_override("separation", 16)
	dim.add_child(buttons)
	_button(buttons, "Restart run", _on_restart)
	_button(buttons, "Reset to defaults", _on_reset)
	_button(buttons, "Copy values", _on_copy)
	_button(buttons, "Close (F2)", toggle)
	_status = Label.new()
	_status.add_theme_font_size_override("font_size", 16)
	buttons.add_child(_status)


func _button(parent: Node, text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(action)
	parent.add_child(b)


func _refresh() -> void:
	for key in _sliders:
		var v: Variant = Tuning.get_value(_station, key)
		_sliders[key].set_value_no_signal(float(v))
		_values[key].text = _fmt(v)


func _on_slider(value: float, key: String) -> void:
	Tuning.set_value(_station, key, value)
	_values[key].text = _fmt(Tuning.get_value(_station, key))
	_save()


func _on_reset() -> void:
	Tuning.apply_snapshot(_station, _defaults)
	_refresh()
	_save()
	_status.text = "Defaults restored"


func _on_copy() -> void:
	DisplayServer.clipboard_set(Tuning.as_text(_station))
	_status.text = "Copied. Paste it to Claude."


func _on_restart() -> void:
	_save()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _save() -> void:
	if _station.tuning_file != "":
		Tuning.save(_station, _station.tuning_file)


func _fmt(v: Variant) -> String:
	if v is float:
		return "%.3f" % v if absf(v) < 1.0 and v != 0.0 else "%.2f" % v
	return str(v)
