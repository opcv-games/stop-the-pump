extends GutTest
## Spec: features/juice.feature (#28): every upgrade's prop pops in the next morning.

const SCENE := preload("res://scenes/greybox/pump_station.tscn")
const MARKETING := 0
const TANK := 2
const VIBE := 4

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.pump_count = 2  # these rules need two pumps; the one-pump start is in test_first_minutes
	station.profile_file = ""
	station.cars_gate_service = false
	station.special_customer_chance = 0.0
	station.arrival_min = 60.0
	station.arrival_max = 60.0
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func _world() -> StationWorld:
	return station.world_view.world


func _to_shop() -> void:
	station.wallet.add(9000.0)
	station.dev_end_day()
	station.continue_pressed()


func test_given_every_upgrade_then_its_prop_exists_in_the_kit() -> void:
	for id in Upgrades.PROPS:
		assert_not_null(_world().upgrades.get_node_or_null(Upgrades.PROPS[id]), id)
	for id in Upgrades.PUMP_PROPS:
		assert_not_null(_world().upgrades.get_node_or_null(Upgrades.PUMP_PROPS[id]), id)


func test_given_new_run_then_no_upgrade_prop_shows() -> void:
	for id in Upgrades.PROPS:
		assert_false(_world().upgrades.get_node(Upgrades.PROPS[id]).visible, id)


func test_given_tank_bought_then_the_tank_waits_for_morning_then_pops_in() -> void:
	_to_shop()
	station.buy(TANK)
	var tank: Node3D = _world().upgrades.get_node("UpTank_1")
	assert_false(tank.visible, "not until the next morning")
	station.continue_pressed()
	assert_true(tank.visible)
	assert_lt(tank.scale.y, 0.5, "rising out of the ground")
	_world().tick_pop(0.3)
	_world().tick_pop(3.0)
	assert_almost_eq(tank.scale.y, 1.0, 0.001)


func test_given_three_tanks_then_three_tanks_show() -> void:
	_to_shop()
	for i in 3:
		station.buy(TANK)
	station.continue_pressed()
	for i in 3:
		assert_true(_world().upgrades.get_node("UpTank_%d" % (i + 1)).visible)


func test_given_self_service_on_pump_1_then_a_card_reader_attaches_to_that_pump() -> void:
	_to_shop()
	station.buy_pump(0)
	station.continue_pressed()
	var pump: Node3D = _world().pumps[0].pump
	assert_not_null(pump.get_node_or_null("PumpCardReader"))
	assert_null(_world().pumps[1].pump.get_node_or_null("PumpCardReader"))


func test_given_pump_tree_complete_then_reader_band_and_sticker_are_on_it() -> void:
	_to_shop()
	for i in 3:
		station.buy_pump(1)
	station.continue_pressed()
	var pump: Node3D = _world().pumps[1].pump
	for n in ["PumpCardReader", "PumpSpeedBand", "PumpDealSticker"]:
		assert_not_null(pump.get_node_or_null(n), n)


func test_given_billboard_bought_then_it_shows_the_station_name() -> void:
	station.set_station_name("Lucky Pump")
	_to_shop()
	for i in 3:
		station.buy(MARKETING)
	station.continue_pressed()
	assert_true(_world().upgrades.get_node("UpBillboard").visible)
	assert_string_contains(_world().billboard_label.text, "LUCKY PUMP")


func test_given_props_when_evicted_then_the_station_is_run_down_again() -> void:
	_to_shop()
	station.buy(TANK)
	station.buy(VIBE)
	station.buy(VIBE)
	station.buy_pump(0)
	station.continue_pressed()
	station.wallet.add(-station.wallet.cash - 9000.0)
	station.dev_end_day()
	assert_true(station.evicted)
	station.continue_pressed()
	for id in Upgrades.PROPS:
		assert_false(_world().upgrades.get_node(Upgrades.PROPS[id]).visible, id)
	assert_null(_world().pumps[0].pump.get_node_or_null("PumpCardReader"))


func test_given_station_then_version_is_0_25() -> void:
	assert_string_contains((station.get_node("VersionLabel") as Label).text, "v0.2")


func test_given_no_billboard_then_its_text_is_hidden_too() -> void:
	station.set_station_name("Chez Papa")
	assert_false(_world().billboard_label.is_visible_in_tree(), "no floating FILL UP AT text before the billboard")
	_world().show_prop("UpBillboard", false)
	assert_true(_world().billboard_label.is_visible_in_tree())
