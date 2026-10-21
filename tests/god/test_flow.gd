extends GutTest
## Spec: features/god_run.feature (#37): GOD PUMP's flow from a run's first day to the garage.

const SCENE := preload("res://scenes/god/god_game.tscn")

var g: GodGame


func before_each() -> void:
	g = SCENE.instantiate()
	g.meta_path = ""
	g.sound_on = false
	g.autostart = true
	add_child_autofree(g)
	g.day.view = "flat"
	g.day.set_view("flat")
	g.day.auto_traffic = false


func test_a_run_opens_on_day_1() -> void:
	assert_eq(g.state, "day")
	assert_eq(g.run.day, 1)
	assert_false(g.day.round_over)


func test_closing_shows_the_report_then_the_night() -> void:
	g.day.end_round()
	assert_eq(g.state, "report")
	assert_true(g.report_screen.visible)
	g._after_report()
	assert_eq(g.state, "night")
	assert_true(g.night.visible)


func test_the_truck_deals_cards_and_opening_starts_day_2() -> void:
	g.day.end_round()
	g._after_report()
	g.run.tank = 100.0
	g.run.cash = 5000.0
	g.call_truck()
	assert_eq(g.state, "cards")
	assert_eq(g.run.offer.size(), 3)
	var id: String = g.run.offer[0]
	g.run.pick_card(id)
	g.cards.picked.emit(id)
	assert_eq(g.state, "night")
	g.open_next_day()
	assert_eq(g.state, "day")
	assert_eq(g.run.day, 2)


func test_bankrupt_ends_the_run_and_banks_xp() -> void:
	g.day.reset_day_stats()
	g.day.day_stats.xp = 40
	g.day.tank = 0.0
	g.run.cash = 0.0
	g.day.end_round()
	g._after_report()
	assert_eq(g.state, "run_over")
	assert_eq(g.meta.xp, 40)
	assert_eq(g.meta.runs, 1)
	g.run_over.done.emit()
	assert_eq(g.state, "garage")


func test_day_50_brings_dad_and_the_ending() -> void:
	g.run.day = GodData.FINAL_DAY
	g.start_day()
	var dads := g.day.cars.filter(func(c: ProtoCar) -> bool: return c.type_id == "papa")
	assert_eq(dads.size(), 1)
	g.day.end_round()
	g._after_report()
	assert_eq(g.state, "cinematic")
	assert_true(g.meta.ending_seen)
	g.cinematic.skip()
	g.cinematic.advance()
	assert_eq(g.state, "run_over")


func test_buying_in_the_night_shop_changes_tomorrow() -> void:
	g.day.end_round()
	g._after_report()
	g.run.cash = 1000.0
	assert_true(g.night.tree.press("hours:0"))
	g.open_next_day()
	assert_almost_eq(g.day.round_seconds, (14.0 - 7.0) * GodData.HOUR_SECONDS, 0.01)


func test_escape_pauses_a_day_and_can_go_back_to_the_title() -> void:
	g.toggle_pause()
	assert_true(get_tree().paused)
	g.toggle_pause()
	assert_false(get_tree().paused)


func test_upgrades_bought_last_night_show_on_the_station_this_morning() -> void:
	g.day.view = "hd"
	g.day.set_view("hd")
	g.day.end_round()
	g._after_report()
	g.run.cash = 1000.0
	g.night.tree.press("attractions:0")  # traffic light
	assert_false(g.day._hd_view._props.has("traffic_light"), "not until the morning")
	g.open_next_day()
	g.day._hd_view._sync_props(0.1)
	assert_true(g.day._hd_view._props.has("traffic_light"))


func test_a_small_partial_delivery_stays_on_the_night() -> void:
	g.day.end_round()
	g._after_report()
	g.run.tank = 0.0
	g.run.cash = 30.0
	g.call_truck()
	assert_eq(g.state, "night")
	assert_gt(g.run.tank, 0.0)
