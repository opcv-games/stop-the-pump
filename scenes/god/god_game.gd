class_name GodGame
extends Node
## GOD PUMP from title to credits (docs/GOD_PUMP_PLAN.md). Runs the flow between screens and owns the
## run and the meta; the day itself is GodPump (the lot, the cars, the God Pump), which this node
## starts each morning and listens to each evening.
##   TITLE → (first time: INTRO → NAMING) → DAY → REPORT → NIGHT (shop, truck → TRUCK → CARDS) → DAY ...
##   → bankrupt: RUN_OVER → GARAGE → new run   ·   day 50: REPORT → ENDING → RUN_OVER → GARAGE
## Designer keys: F1 opens the dev configurator (DevPanel), F3 ends the day, F4 gives $100, F6 gives
## 1000 XP.

const DAY_SCENE := preload("res://scenes/god/day/god_pump.tscn")

@export var meta_path := MetaState.DEFAULT_PATH
@export var sound_on := true
## Tests start straight into a run without the title.
@export var autostart := false

var meta: MetaState
var run: RunState
var day: GodPump
var state := "title"
var ui: CanvasLayer
var title: TitleScreen
var cinematic: Cinematic
var naming: NamingScreen
var report_screen: DayReportScreen
var night: NightScreen
var cards: CardPickScreen
var run_over: RunOverScreen
var garage: GarageScreen
var truck_scene: TruckScene
var paper: NewspaperScreen
var _last_report := {}


func _ready() -> void:
	meta = MetaState.load_from(meta_path)
	_apply_volume()
	day = DAY_SCENE.instantiate()
	day.managed = true
	day.sound_on = sound_on
	add_child(day)
	day.day_over.connect(_on_day_over)
	day.round_over = true  # closed until a run opens
	day.set_station_name(meta.station_name)
	ui = CanvasLayer.new()
	ui.layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS  # the pause menu keeps working
	day.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(ui)
	title = TitleScreen.new()
	cinematic = Cinematic.new()
	naming = NamingScreen.new()
	report_screen = DayReportScreen.new()
	night = NightScreen.new()
	cards = CardPickScreen.new()
	run_over = RunOverScreen.new()
	garage = GarageScreen.new()
	truck_scene = TruckScene.new()
	truck_scene.sound_on = sound_on
	paper = NewspaperScreen.new()
	for s in [title, report_screen, night, cards, run_over, garage, naming, cinematic, truck_scene, paper]:
		s.visible = false
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # crisp pixel icons
		ui.add_child(s)
	title.play_pressed.connect(new_run)
	title.garage_pressed.connect(show_garage)
	title.intro_pressed.connect(func() -> void: _play_cinematic(Cinematic.INTRO, "title"))
	title.quit_pressed.connect(func() -> void: get_tree().quit())
	cinematic.finished.connect(_on_cinematic_finished)
	naming.named.connect(_on_named)
	report_screen.done.connect(_after_report)
	night.truck_called.connect(call_truck)
	truck_scene.finished.connect(_after_truck)
	paper.done.connect(func() -> void: if state == "paper": start_day())
	night.open_pressed.connect(open_next_day)
	cards.picked.connect(func(_id: String) -> void: _show_night())
	run_over.done.connect(show_garage)
	garage.play_pressed.connect(new_run)
	garage.menu_pressed.connect(show_title)
	if autostart:
		new_run()
	else:
		show_title()


func _hide_all() -> void:
	for s in [title, report_screen, night, cards, run_over, garage, naming, cinematic, truck_scene, paper]:
		s.visible = false


func _hud(on: bool) -> void:
	if day and day._overlay:
		day._overlay.visible = on
	if sound_on:  # in a day the nozzle is the cursor; menus need the mouse
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN if on else Input.MOUSE_MODE_VISIBLE


func show_title() -> void:
	state = "title"
	_hide_all()
	_hud(false)
	title.show_title(meta)


func show_garage() -> void:
	state = "garage"
	_hide_all()
	_hud(false)
	garage.show_garage(meta)


## A fresh run. The first time ever: the intro, then name the gaz bar.
func new_run() -> void:
	run = RunState.new(meta)
	run.rng.randomize()
	if not meta.intro_seen and not autostart:
		_play_cinematic(Cinematic.INTRO, "naming")
		return
	start_day()


var _after_cinematic := ""


func _play_cinematic(which: Array, then: String) -> void:
	state = "cinematic"
	_after_cinematic = then
	_hide_all()
	_hud(false)
	cinematic.play(which)


func _on_cinematic_finished() -> void:
	match _after_cinematic:
		"naming":
			meta.intro_seen = true
			meta.save()
			state = "naming"
			_hide_all()
			naming.show_naming(meta.station_name)
		"run_over":
			_show_run_over()
		_:
			show_title()


func _on_named(text: String) -> void:
	meta.station_name = text.to_upper()
	meta.save()
	day.set_station_name(meta.station_name)
	start_day()


## Opens today: the run's numbers, the tank, the unlocked car types. Day 50: Dad drives in first.
func start_day() -> void:
	state = "day"
	_hide_all()
	_hud(true)
	day.owned = run.owned.duplicate()  # upgrades bought last night pop in this morning
	day.links = run.links.duplicate()
	day.perks = meta.perk_tiers.duplicate()  # Garage perks stand on the lot every day
	day.bling = meta.equipped_bling.duplicate()  # and the bling hangs off the nozzle
	day.bling_owned = meta.owned_bling.duplicate()  # every piece owned: a ring on the handle
	day.start_day(run.mods(), run.tank, run.day, meta.unlocked_cars())
	if run.day >= GodData.FINAL_DAY:
		var dad := day.park_customer(30.0, Vector2(GodPump.ENTRANCE.x + 60, GodPump.LOT.position.y + 70))
		dad.set_type("papa", day.rng)
		dad.stack = "orange"
		dad.patience = 9999.0


func _on_day_over(report: Dictionary) -> void:
	if state != "day":
		return
	_last_report = report
	run.end_day(report)
	state = "report"
	report_screen.show_report(report, run, meta)


func _after_report() -> void:
	report_screen.visible = false
	if run.won:
		run.finish()
		_play_cinematic(Cinematic.ENDING, "run_over")
		return
	if run.bankrupt():
		run.finish()
		_show_run_over()
		return
	_show_night()


func _show_night() -> void:
	state = "night"
	_hide_all()
	_hud(false)
	night.show_night(run)


## The truck comes: the delivery plays over the night screen, then the cards (none for a small one).
func call_truck() -> void:
	var before := {"tank_from": run.tank, "price_from": run.price, "cash": run.cash}
	if run.call_truck():
		state = "truck"
		night.refresh()
		truck_scene.play({"tank_from": before.tank_from, "tank_to": run.tank, "capacity": run.tank_capacity(),
			"cost": before.cash - run.cash, "price_from": before.price_from, "price_to": run.price,
			"cards": not run.offer.is_empty()})


func _after_truck() -> void:
	if state != "truck":
		return
	if run.offer.is_empty():  # a small partial delivery deals no cards
		state = "night"
		night.refresh()
		return
	state = "cards"
	cards.show_offer(run)


## OPEN: the next morning starts with L'Écho de Saint-Clin-Clin, about yesterday (round 8).
func open_next_day() -> void:
	if run.tank < 1.0:
		return
	run.next_day()
	show_paper()


func show_paper() -> void:
	var ed := Newspaper.edition(run, meta, _last_report)
	meta.clip(ed.headline, ed.postcard.get("day", 0))
	state = "paper"
	_hide_all()
	_hud(false)
	paper.show_paper(ed)


func _show_run_over() -> void:
	state = "run_over"
	_hide_all()
	_hud(false)
	run_over.show_run(run, meta)


var _pause: Control


## ESC pauses a day: resume, or back to the title (the run is abandoned, its XP still banked).
func toggle_pause() -> void:
	if not _pause:
		_pause = Control.new()
		_pause.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_pause.process_mode = Node.PROCESS_MODE_ALWAYS
		_pause.draw.connect(func() -> void:
			GodUI.dim(_pause, _pause.size, 0.7)
			GodUI.text(_pause, Vector2(576, 250), "PAUSE", 56, GodUI.GOLD, true, 8))
		var resume := GodUI.button("RESUME  (ESC)", Vector2(300, 48))
		resume.position = Vector2(426, 300)
		resume.pressed.connect(toggle_pause)
		_pause.add_child(resume)
		var quit := GodUI.button("BACK TO THE TITLE", Vector2(300, 48))
		quit.position = Vector2(426, 360)
		quit.pressed.connect(func() -> void:
			toggle_pause()
			if run and not run.over:
				run.finish()
			day.round_over = true
			show_title())
		_pause.add_child(quit)
		var vol := HSlider.new()
		vol.min_value = 0.0
		vol.max_value = 1.0
		vol.step = 0.05
		vol.value = meta.volume
		vol.position = Vector2(476, 440)
		vol.size = Vector2(200, 24)
		vol.focus_mode = Control.FOCUS_NONE
		vol.value_changed.connect(func(v: float) -> void:
			meta.volume = v
			_apply_volume()
			meta.save())
		_pause.add_child(vol)
		var vol_label := Label.new()
		vol_label.text = "VOLUME"
		vol_label.position = Vector2(400, 440)
		vol_label.add_theme_color_override("font_color", GodUI.GOLD)
		_pause.add_child(vol_label)
		ui.add_child(_pause)
		_pause.visible = false
	_pause.visible = not _pause.visible
	get_tree().paused = _pause.visible
	if sound_on:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _pause.visible else Input.MOUSE_MODE_HIDDEN
	_pause.queue_redraw()


var dev: DevPanel


## F1: the designer's configurator. It pauses a day while it's open.
func toggle_dev() -> void:
	if not dev:
		dev = DevPanel.new()
		dev.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ui.add_child(dev)
		dev.build(self)
		dev.visible = false
	dev.visible = not dev.visible
	var paused_by_menu := _pause != null and _pause.visible
	get_tree().paused = dev.visible or paused_by_menu
	if sound_on:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if dev.visible or state != "day" else Input.MOUSE_MODE_HIDDEN


func dev_refresh() -> void:
	if state == "night":
		night.refresh()
	elif state == "garage":
		garage.show_garage(meta)


func dev_end_day() -> void:
	if state == "day":
		_close_dev()
		day.end_round()


## Skips ahead to the next night: closes today if a day is on, or plays tomorrow as an empty day.
func dev_next_night() -> void:
	if not run or run.over:
		return
	_close_dev()
	match state:
		"day":
			day.end_round()
			_after_report()
		"report":
			_after_report()
		"night", "cards", "truck":
			truck_scene.visible = false
			run.offer = []
			run.next_day()
			run.end_day({"tank_left": run.tank})
			_after_report()


func dev_reset_save() -> void:
	_close_dev()
	if run and not run.over:
		run.over = true
	meta = MetaState.new()
	meta.path = meta_path
	meta.save()
	day.round_over = true
	day.set_station_name(meta.station_name)
	show_title()


func _close_dev() -> void:
	if dev and dev.visible:
		toggle_dev()


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(meta.volume, 0.001)))
	AudioServer.set_bus_mute(bus, meta.volume <= 0.01)


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	if e.physical_keycode == KEY_ESCAPE and (state == "day" or (_pause and _pause.visible)):
		toggle_pause()
		return
	match e.physical_keycode:
		KEY_F1:
			toggle_dev()
		KEY_F3:
			if state == "day":
				day.end_round()
		KEY_F4:
			if run and state in ["night", "day"]:
				run.cash += 100.0
				night.refresh()
		KEY_F6:
			meta.xp += 1000
			meta.save()
