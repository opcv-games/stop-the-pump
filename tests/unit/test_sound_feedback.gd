extends GutTest
## Combo sound climbs one octave per step (playtest 6). Refs #9


func test_given_combo_x2_then_base_pitch() -> void:
	assert_almost_eq(SoundFeedback.combo_pitch(2), 1.0, 0.001)


func test_given_combo_x4_then_two_octaves_up() -> void:
	assert_almost_eq(SoundFeedback.combo_pitch(4), 4.0, 0.001)
