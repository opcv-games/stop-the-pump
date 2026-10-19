extends GutTest
## Spec: features/customers.feature. Refs #5

const SCENE := preload("res://scenes/greybox/pump_station.tscn")

var station: Control


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.arrival_min = 60.0
	station.arrival_max = 60.0
	station.second_customer_offset = 0.0
	station.special_customer_chance = 0.0
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func test_given_twenty_guy_when_stopped_at_22_then_pays_20_and_2_comes_out_of_pocket() -> void:
	var bay: PumpBay = station.bays[0]
	bay.new_customer(20.0, "twenty_guy")
	var cash: float = station.wallet.cash
	bay.pump.finish_at(22.0)
	assert_almost_eq(station.wallet.cash - cash, 20.0 - 2.0, 0.001)
	assert_string_contains(bay.result_label.text, "out of your pocket")


func test_given_businessman_when_he_drives_off_then_combo_breaks_and_pump_waits_for_next_car() -> void:
	var bay: PumpBay = station.bays[0]
	station.combo.register(ScoreTiers.GOOD)
	station.combo.register(ScoreTiers.GOOD)
	bay.new_customer(40.0, "businessman")
	bay.customer.tick(10.0)
	assert_eq(station.combo.multiplier, 1)
	assert_string_contains(bay.result_label.text, "DROVE OFF")
	assert_true(bay.waiting)
	assert_false(bay.car_visible())


func test_given_grandpa_changes_his_order_then_the_pump_shows_the_new_order() -> void:
	var bay: PumpBay = station.bays[0]
	bay.new_customer(30.0, "grandpa")
	bay.pump.start_pour()
	bay.pump.tick(18.2 / bay.pump.flow_rate)
	assert_string_contains(bay.target_label.text, "$%.2f" % bay.pump.target)
	assert_string_contains(bay.target_label.text, "changed")


func test_given_customer_then_car_and_speech_bubble_show_and_go() -> void:
	var bay: PumpBay = station.bays[0]
	assert_true(bay.car_visible())
	assert_ne(bay.bubble_text(), "")
	bay.show_empty()
	assert_false(bay.car_visible())


func test_given_special_chance_1_then_self_service_pumps_still_get_regulars() -> void:
	station.special_customer_chance = 1.0
	station.wallet.add(5000.0)
	station.dev_end_day()
	station.continue_pressed()
	station.buy(1)
	station.toggle_shop_page()
	station.buy_pump(2)
	station.continue_pressed()
	assert_eq(station.bays[2].customer.type, "regular")


