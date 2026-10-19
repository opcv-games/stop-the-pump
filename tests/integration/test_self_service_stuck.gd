extends GutTest
## Regression (playtest 13): a self-service customer got stuck at $5.40. Refs #17

const SCENE := preload("res://scenes/greybox/pump_station.tscn")

var station: Control
var bay: PumpBay
var ss: SelfServiceComponent


func before_each() -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.arrival_min = 60.0
	station.arrival_max = 60.0
	station.second_customer_offset = 0.0
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false
	station.wallet.add(5000.0)
	station.dev_end_day()
	station.continue_pressed()
	station.buy(1)  # build pump 3
	station.buy_pump(2)  # pump 3: self-service
	station.continue_pressed()
	station.clock.running = false
	bay = station.bays[2]
	ss = bay.self_service_component
	while ss.phase != SelfServiceComponent.Phase.PUMPING:
		ss.tick(0.1)
	ss.tick(1.0)


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func _finish() -> void:
	for i in 400:
		ss.tick(0.1)


func test_given_self_service_pumping_when_player_presses_and_releases_its_key_then_customer_still_finishes_and_pays() -> void:
	watch_signals(ss)
	station.press(2)
	station.release(2)
	_finish()
	assert_signal_emitted(ss, "paid")
	assert_almost_eq(bay.pump.amount, bay.pump.target, 0.001)


func test_given_self_service_pumping_when_released_then_pump_keeps_pouring() -> void:
	var before := bay.pump.amount
	station.release(2)
	ss.tick(1.0)
	assert_gt(bay.pump.amount, before)
