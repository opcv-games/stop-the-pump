extends GutTest
## Spec: features/station_tab.feature (#33): pumps are built and improved on the station itself.

const SCENE := preload("res://scenes/greybox/pump_station.tscn")

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.profile_file = ""
	station.cars_gate_service = false
	station.special_customer_chance = 0.0
	station.arrival_min = 60.0
	station.arrival_max = 60.0
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false
	station.wallet.add(5000.0)
	station.dev_end_day()
	station.continue_pressed()  # night shop


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func _view() -> StationShopView:
	return station.station_view


func test_the_night_shop_opens_on_the_tree() -> void:
	assert_eq(station.shop_tab, station.ShopTab.TREE)
	assert_true(station.tree_view.is_visible_in_tree())
	assert_false(_view().is_visible_in_tree())


func test_tab_switches_to_the_station() -> void:
	station.toggle_shop_tab()
	assert_eq(station.shop_tab, station.ShopTab.STATION)
	assert_false(station.tree_view.is_visible_in_tree())
	assert_true(_view().is_visible_in_tree())


func test_the_tree_has_no_pump_nodes() -> void:
	for n in UpgradeGraph.build(station):
		assert_ne(n.kind, "pump")
		if n.kind == "branch":
			assert_ne(Upgrades.BRANCHES[n.branch].id, "pumps")


func test_one_pump_then_its_upgrades_and_a_build_card() -> void:
	assert_eq(_view().keys(), ["pump:0:0", "pump:0:1", "pump:0:2", "build"])
	assert_string_contains(_view().tooltip_for("build"), "Pump 2")
	assert_string_contains(_view().tooltip_for("build"), "$100")


func test_clicking_build_builds_the_next_pump() -> void:
	assert_true(_view().press("build"))
	assert_eq(station.bays.size(), 2)
	assert_true("pump:1:0" in _view().keys())
	assert_string_contains(_view().tooltip_for("build"), "Pump 3")


func test_after_three_pumps_the_build_card_expands_the_lot() -> void:
	_view().press("build")
	_view().press("build")
	assert_string_contains(_view().tooltip_for("build"), "Expand")


func test_clicking_a_pump_upgrade_improves_that_pump() -> void:
	assert_true(_view().press("pump:0:0"))
	assert_eq(station.bays[0].pump_level, 1)
	assert_true(station.bays[0].self_service)


func test_a_pump_upgrade_further_along_cannot_be_bought_first() -> void:
	assert_false(_view().press("pump:0:1"))
	assert_eq(station.bays[0].pump_level, 0)


func test_each_pump_card_stands_on_its_pump() -> void:
	_view().press("build")
	for i in station.bays.size():
		assert_lt(_view().card_position(i).distance_to(station.anchor_position(i)), 80.0)


func test_the_day_hud_hides_at_night_and_returns_in_the_morning() -> void:
	assert_false(station.bays[0].is_visible_in_tree())
	station.continue_pressed()
	assert_true(station.bays[0].is_visible_in_tree())
