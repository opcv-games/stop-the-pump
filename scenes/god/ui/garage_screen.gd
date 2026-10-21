class_name GarageScreen
extends Control
## Papa's Garage (GOD PUMP plan): XP from every run buys nozzles (equip one), bling (equip in slots)
## and perks (tiers). Click to buy; click an owned item to equip it. Serves: Advancement across runs.

signal play_pressed
signal menu_pressed

const TABS := ["NOZZLES", "BLING", "PERKS"]

var meta: MetaState
var tab := 0
var _hover := -1
var _t := 0.0
var _flash := {}


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var play := GodUI.button("NEW RUN  →", Vector2(260, 48))
	play.position = Vector2(868, 584)
	play.pressed.connect(func() -> void: play_pressed.emit())
	add_child(play)
	var menu := GodUI.button("MENU", Vector2(140, 44), 17)
	menu.position = Vector2(24, 588)
	menu.pressed.connect(func() -> void: menu_pressed.emit())
	add_child(menu)


func show_garage(the_meta: MetaState) -> void:
	meta = the_meta
	visible = true


func items() -> Array:
	return [GodData.NOZZLES, GodData.BLING, GodData.PERKS][tab]


func item_rect(i: int) -> Rect2:
	var cols := 5 if items().size() <= 10 else 6  # 11 perks: six to a row
	var w := (1068.0 - (cols - 1) * 10.0) / cols
	var h := 200.0
	return Rect2(42 + (i % cols) * (w + 10), 150 + (i / cols) * (h + 12), w, h)


func tab_rect(i: int) -> Rect2:
	return Rect2(330 + i * 170, 96, 160, 38)


func state(it: Dictionary) -> String:
	match tab:
		0:
			return "equipped" if meta.nozzle == it.id else ("owned" if it.id in meta.owned_nozzles else "shop")
		1:
			return "equipped" if it.id in meta.equipped_bling else ("owned" if it.id in meta.owned_bling else "shop")
	var tier: int = meta.perk_tiers.get(it.id, 0)
	return "maxed" if tier >= it.tiers else ("owned" if tier > 0 else "shop")


func price(it: Dictionary) -> int:
	return meta.perk_price(it.id) if tab == 2 else it.price


func click(i: int) -> bool:
	var it: Dictionary = items()[i]
	var ok := false
	match tab:
		0:
			ok = meta.equip_nozzle(it.id) if it.id in meta.owned_nozzles else meta.buy_nozzle(it.id)
		1:
			ok = meta.toggle_bling(it.id) if it.id in meta.owned_bling else meta.buy_bling(it.id)
		2:
			ok = meta.buy_perk(it.id)
	if ok:
		_flash[i] = 0.0
	return ok


func _gui_input(e: InputEvent) -> void:
	if not meta:
		return
	if e is InputEventMouseMotion:
		_hover = -1
		for i in items().size():
			if item_rect(i).has_point(e.position):
				_hover = i
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		for i in TABS.size():
			if tab_rect(i).has_point(e.position):
				tab = i
				_hover = -1
				return
		if _hover >= 0:
			click(_hover)


func _process(dt: float) -> void:
	if visible:
		_t += dt
		for k in _flash.keys():
			_flash[k] += dt
			if _flash[k] > 0.6:
				_flash.erase(k)
		queue_redraw()


func _draw() -> void:
	if not meta:
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.045, 0.035, 0.96))
	GodUI.text(self, Vector2(576, 56), "PAPA'S GARAGE", 38, GodUI.GOLD, true)
	GodUI.text(self, Vector2(1120 - GodUI.font().get_string_size("XP %d" % meta.xp, HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x, 56), "XP %d" % meta.xp, 26, GodUI.GOLD)
	GodUI.text(self, Vector2(32, 56), "Runs: %d   ·   Best day: %d" % [meta.runs, meta.best_day], 15, Color(GodUI.CREAM, 0.7))
	for i in TABS.size():
		var r := tab_rect(i)
		draw_style_box(GodUI.panel_box(GodUI.GOLD if i == tab else GodUI.GOLD_DIM, Color(0.2, 0.15, 0.09) if i == tab else Color(0.1, 0.08, 0.06), 8), r)
		GodUI.text(self, r.get_center() + Vector2(0, 6), TABS[i], 16, GodUI.GOLD if i == tab else Color(GodUI.GOLD, 0.6), true)
	if tab == 1:
		GodUI.text(self, Vector2(576, 146), "Slots: %d / %d" % [meta.equipped_bling.size(), meta.bling_slots()], 14, Color(GodUI.CREAM, 0.7), true)
	var list := items()
	for i in list.size():
		var it: Dictionary = list[i]
		var r := item_rect(i)
		var st := state(it)
		var p := price(it)
		var col := GodUI.GREEN if st == "equipped" else (GodUI.GOLD if st in ["owned", "maxed"] else (GodUI.GOLD_DIM if meta.xp >= p else Color(0.35, 0.3, 0.25)))
		var box := GodUI.panel_box(col.lightened(0.2) if i == _hover else col, Color(0.09, 0.075, 0.06, 0.97), 10)
		if _flash.has(i):
			box.shadow_color = Color(GodUI.GOLD, 0.8 - _flash[i])
			box.shadow_size = 22
		draw_style_box(box, r)
		var tex := GodUI.icon(it.id)
		if tex:
			draw_texture_rect(tex, Rect2(Vector2(r.get_center().x - 32, r.position.y + 12), Vector2(64, 64)), false, Color.WHITE if st != "shop" or meta.xp >= p else Color(0.55, 0.55, 0.55))
		GodUI.text(self, Vector2(r.get_center().x, r.position.y + 98), it.name, 16 if r.size.x > 200.0 else 14, GodUI.GOLD, true)
		GodUI.para(self, Vector2(r.get_center().x, r.position.y + 122), it.helps, 13, r.size.x - 20)
		var foot := ""
		match st:
			"equipped":
				foot = "EQUIPPED"
			"owned":
				foot = "click to equip" if tab < 2 else "tier %d · next %d XP" % [meta.perk_tiers.get(it.id, 0), p]
			"maxed":
				foot = "MAX"
			_:
				foot = "%d XP" % p if p > 0 else "free"
		if tab == 2 and st == "shop":
			foot = "%d XP  (×%d)" % [p, it.tiers]
		GodUI.text(self, Vector2(r.get_center().x, r.end.y - 14), foot, 15, col.lightened(0.2), true)
