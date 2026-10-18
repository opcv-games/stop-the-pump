extends GutTest
## Wiring check for the greybox: pump -> score -> combo -> screen. Refs #7

const SCENE := preload("res://scenes/greybox/pump_greybox.tscn")

var grey: Control


func before_each() -> void:
	grey = add_child_autofree(SCENE.instantiate())
	grey.sound.enabled = false
	grey.next_customer_delay = 60.0  # keep the result on screen for the assertions


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)


func _pour_exactly_to_target() -> void:
	grey.pump.start_pour()
	grey.pump.tick(grey.pump.target / grey.pump.flow_rate)
	grey.pump.stop_pour()


func test_given_new_customer_when_stopped_on_target_then_perfect_and_combo_grows() -> void:
	_pour_exactly_to_target()
	assert_eq(grey.combo.multiplier, 2)
	assert_string_contains(grey._result_label.text, "PERFECT")
	assert_string_contains(grey._combo_label.text, "x2")


func test_given_combo_when_badly_missed_then_screen_says_combo_lost() -> void:
	grey.combo.register(ScoreTiers.GOOD)
	grey.combo.register(ScoreTiers.GOOD)
	grey.pump.start_pour()
	grey.pump.tick(1.0)
	grey.pump.stop_pour()
	assert_string_contains(grey._result_label.text, "COMBO LOST  x3")
	assert_eq(grey.combo.multiplier, 1)
