extends GutTest
## A backing band plays the 12-bar blues; stops add melody notes that fit the bar. Refs #12


func test_given_backing_at_start_then_bar_1_is_a7() -> void:
	assert_eq(SoundFeedback.chord_at(0.0), "A7")


func test_given_backing_in_bar_5_then_chord_is_d7() -> void:
	assert_eq(SoundFeedback.chord_at(SoundFeedback.bar_seconds() * 4.5), "D7")


func test_given_backing_past_one_chorus_then_it_loops_to_bar_1() -> void:
	assert_eq(SoundFeedback.chord_at(SoundFeedback.bar_seconds() * 12.2), "A7")


func test_given_tiers_then_note_counts_are_3_2_1_0() -> void:
	assert_eq(SoundFeedback.note_count(ScoreTiers.SUPER_PERFECT), 3)
	assert_eq(SoundFeedback.note_count(ScoreTiers.PERFECT), 2)
	assert_eq(SoundFeedback.note_count(ScoreTiers.GOOD), 1)
	assert_eq(SoundFeedback.note_count(ScoreTiers.OK), 0)


func test_given_swing_then_eighth_notes_fall_on_the_beat_and_two_thirds_through() -> void:
	var beat := 60.0 / SoundFeedback.BPM
	assert_eq(SoundFeedback.eighth_index(0.0), 0)
	assert_eq(SoundFeedback.eighth_index(beat * 0.5), 0)
	assert_eq(SoundFeedback.eighth_index(beat * 0.7), 1)
	assert_eq(SoundFeedback.eighth_index(beat * 1.01), 2)


func test_given_roadside_track_then_every_bar_uses_the_safe_note_set() -> void:
	assert_eq(SoundFeedback.chord_at(0.0, 1), "Roadside")
	assert_eq(SoundFeedback.chord_at(77.0, 1), "Roadside")


func test_given_roadside_track_then_tempo_is_92() -> void:
	assert_eq(SoundFeedback.TRACKS[1].bpm, 92.0)
