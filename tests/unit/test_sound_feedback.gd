extends GutTest
## Good stops walk a chord progression; a broken chain falls apart (playtest 7). Refs #10, #11


func test_given_chain_of_13_then_chords_walk_a_12_bar_blues_and_loop() -> void:
	var names := []
	for length in range(1, 14):
		names.append(SoundFeedback.chord_for(length))
	assert_eq(names, ["A7", "A7", "A7", "A7", "D7", "D7", "A7", "A7", "E7", "D7", "A7", "E7", "A7"])
