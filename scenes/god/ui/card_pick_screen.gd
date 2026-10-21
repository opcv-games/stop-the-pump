class_name CardPickScreen
extends Control
## "CHOOSE ONE" after a fuel delivery (designer's Bills reference): 3 cards (4 with the perk), framed
## by rarity, with an icon and what they do; click one. A reroll if the perk allows. Serves: Advancement.

signal picked(id: String)

var run: RunState
var _hover := -1
var _t := 0.0
var _reroll: Button


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_reroll = GodUI.button("REROLL", Vector2(200, 42), 17)
	_reroll.position = Vector2(476, 580)
	_reroll.pressed.connect(func() -> void:
		if run and run.reroll():
			_refresh())
	add_child(_reroll)


func show_offer(the_run: RunState) -> void:
	run = the_run
	visible = true
	_t = 0.0
	_refresh()


func _refresh() -> void:
	_reroll.visible = run.rerolls_left > 0
	_reroll.text = tr("REROLL (%d)") % run.rerolls_left
	queue_redraw()


func card_rect(i: int) -> Rect2:
	var n := run.offer.size()
	var w := 300.0 if n <= 3 else 250.0
	var gap := 30.0
	var x0 := 576.0 - (n * w + (n - 1) * gap) * 0.5
	return Rect2(x0 + i * (w + gap), 150, w, 400)


func _gui_input(e: InputEvent) -> void:
	if not run or run.offer.is_empty():
		return
	if e is InputEventMouseMotion:
		_hover = -1
		for i in run.offer.size():
			if card_rect(i).has_point(e.position):
				_hover = i
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and _hover >= 0:
		var id: String = run.offer[_hover]
		if run.pick_card(id):
			_hover = -1
			picked.emit(id)


func _process(dt: float) -> void:
	if visible:
		_t += dt
		queue_redraw()


func _draw() -> void:
	if not run or run.offer.is_empty():
		return
	GodUI.dim(self, size, 0.82)
	var band := Rect2(0, 44, size.x, 74)
	draw_rect(band, Color(0.02, 0.015, 0.01, 0.8))
	GodUI.text(self, Vector2(576, 102), tr("CHOOSE ONE"), 50, GodUI.GOLD, true)
	for i in run.offer.size():
		var c := GodData.card(run.offer[i])
		var r := card_rect(i)
		var rise := -10.0 if i == _hover else 0.0
		r.position.y += rise + sin(_t * 2.0 + i) * 2.0
		GodUI.card(self, r, c.name, tr(c.helps), GodUI.icon(c.id), GodUI.RARITY[c.rarity], i == _hover,
			tr(c.rarity))
