extends GutTest
## Specs: features/inheritance_intro.feature (#29), features/one_pump_start.feature (#30).

const SCENE := preload("res://scenes/greybox/pump_station.tscn")
const PUMPS := 1
const PROFILE := "user://test_first_minutes_profile.cfg"

var station: Control


func _make(pumps: int = -1, with_intro: bool = false) -> void:
	station = SCENE.instantiate()
	station.tuning_file = ""
	station.profile_file = PROFILE if with_intro else ""
	station.cars_gate_service = false
	station.special_customer_chance = 0.0
	station.arrival_min = 60.0
	station.arrival_max = 60.0
	if pumps > 0:
		station.pump_count = pumps
	add_child_autofree(station)
	station.sound.enabled = false
	station.clock.running = false


func after_each() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE))


# --- One pump (#30) ---------------------------------------------------------------------------

func test_given_a_new_run_then_the_station_has_one_pump() -> void:
	_make()
	assert_eq(station.bays.size(), 1)
	assert_eq(station.world_view.world.lane_count, 1)


func test_given_one_pump_then_the_first_pumps_upgrade_is_pump_2() -> void:
	_make()
	assert_eq(Upgrades.next_node(station, PUMPS).id, "pump_2")


func test_given_one_pump_when_pump_2_is_bought_then_the_station_has_two_pumps() -> void:
	_make()
	station.wallet.add(5000.0)
	station.dev_end_day()
	station.continue_pressed()
	station.buy(PUMPS)
	station.continue_pressed()
	assert_eq(station.bays.size(), 2)
	assert_eq(Upgrades.next_node(station, PUMPS).id, "pump_3")


func test_given_two_starting_pumps_then_the_first_pumps_upgrade_is_pump_3() -> void:
	_make(2)
	assert_eq(Upgrades.next_node(station, PUMPS).id, "pump_3")


func test_given_three_pumps_then_the_next_pumps_upgrade_is_the_expansion() -> void:
	_make(3)
	assert_eq(Upgrades.next_node(station, PUMPS).id, "expand")


func test_given_eviction_then_the_pumps_branch_restarts_at_pump_2() -> void:
	_make()
	station.wallet.add(5000.0)
	station.dev_end_day()
	station.continue_pressed()
	station.buy(PUMPS)
	station.start_run()
	assert_eq(station.bays.size(), 1)
	assert_eq(Upgrades.next_node(station, PUMPS).id, "pump_2")


func test_day_one_rent_fits_one_pump() -> void:
	_make()
	assert_almost_eq(station.economy.rent_for(1), 20.0, 0.01)  # 15-second days (#35)


# --- Story intro (#29) -------------------------------------------------------------------------

func test_given_a_new_game_then_the_intro_plays_before_naming() -> void:
	_make(-1, true)
	assert_eq(station.state, station.State.INTRO)
	assert_true(station.intro.visible)
	assert_string_contains(station.intro.card_text().to_lower(), "father")


func test_the_intro_tells_the_inheritance_and_ends_with_the_challenge() -> void:
	_make(-1, true)
	var all := ""
	for card in StoryIntro.CARDS:
		all += card + "\n"
	assert_string_contains(all, "Québec")
	assert_string_contains(all, "gas station")
	assert_eq(StoryIntro.CARDS[-1], "Are you up to the challenge?")


func test_given_the_intro_when_advanced_then_the_next_card_shows() -> void:
	_make(-1, true)
	station.intro.advance()
	assert_eq(station.intro.index, 1)


func test_given_the_intro_when_skipped_then_it_jumps_to_the_challenge() -> void:
	_make(-1, true)
	station.intro.skip()
	assert_true(station.intro.on_last_card())
	assert_eq(station.intro.card_text(), "Are you up to the challenge?")


func test_given_the_challenge_when_accepted_then_the_naming_screen_appears() -> void:
	_make(-1, true)
	station.intro.skip()
	station.intro.advance()  # Enter on the last card accepts
	assert_eq(station.state, station.State.NAMING)
	assert_false(station.intro.visible)


func test_given_a_second_run_then_naming_appears_without_the_intro() -> void:
	_make(-1, true)
	station.intro.skip()
	station.intro.advance()
	station.confirm_name("Test")
	station.start_run()
	assert_eq(station.state, station.State.NAMING)
	assert_false(station.intro.visible)
