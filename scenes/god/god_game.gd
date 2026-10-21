class_name GodGame
extends Node
## GOD PUMP from title to credits (docs/GOD_PUMP_PLAN.md). Runs the flow between screens and owns the
## run and the meta; the day itself is GodPump (the lot, the cars, the God Pump), which this node
## starts each morning and listens to each evening.
##   TITLE → (first time: INTRO → NAMING) → DAY → REPORT → NIGHT (shop, truck → CARDS) → DAY ...
##   → bankrupt: RUN_OVER → GARAGE → new run   ·   day 50: REPORT → ENDING → RUN_OVER → GARAGE
## Designer keys: F3 ends the day, F4 gives $100 (night), F6 gives 1000 XP (garage).

const DAY_SCENE := preload("res://scenes/prototype/god_pump.tscn")

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
var _last_report := {}


func _ready() -> void:
	meta = MetaState.load_from(meta_path)
	day = DAY_SCENE.instantiate()
	day.managed = true
	day.sound_on = sound_on
	add_child(day)
	day.day_over.connect(_on_day_over)
	day.round_over = true  # closed until a run opens
	day.set_station_name(meta.station_name)
	ui = CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	title = TitleScreen.new()
	cinematic = Cinematic.new()
	naming = NamingScreen.new()
	report_screen = DayReportScreen.new()
	night = NightScreen.new()
	cards = CardPickScreen.new()
	run_over = RunOverScreen.new()
	garage = GarageScreen.new()
	for s in [title, report_screen, night, cards, run_over, garage, naming, cinematic]:
		s.visible = false
		ui.add_child(s)
	title.play_pressed.connect(new_run)
	title.garage_pressed.connect(show_garage)
	title.intro_pressed.connect(func() -> void: _play_cinematic(Cinematic.INTRO, "title"))
	title.quit_pressed.connect(func() -> void: get_tree().quit())
	cinematic.finished.connect(_on_cinematic_finished)
	naming.named.connect(_on_named)
	report_screen.done.connect(_after_report)
	night.truck_called.connect(call_truck)
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
	for s in [title, report_screen, night, cards, run_over, garage, naming, cinematic]:
		s.visible = false


func _hud(on: bool) -> void:
	if day and day._overlay:
		day._overlay.visible = on


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


func call_truck() -> void:
	if run.call_truck():
		state = "cards"
		cards.show_offer(run)
		night.refresh()


func open_next_day() -> void:
	if run.tank < 1.0:
		return
	run.next_day()
	start_day()


func _show_run_over() -> void:
	state = "run_over"
	_hide_all()
	_hud(false)
	run_over.show_run(run, meta)


func _unhandled_input(e: InputEvent) -> void:
	if not (e is InputEventKey and e.pressed and not e.echo):
		return
	match e.physical_keycode:
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
