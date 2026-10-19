extends GutTest
## Good stops walk a chord progression; a broken chain falls apart (playtest 7). Refs #10


func test_given_chain_of_five_then_chords_are_c_g_am_f_c() -> void:
	var names := []
	for length in range(1, 6):
		names.append(SoundFeedback.CHORDS[SoundFeedback.chord_index(length)])
	assert_eq(names, ["C", "G", "Am", "F", "C"])
