extends GutTest
## Spec: features/super_perfect_and_sound.feature. Plain SFX + background music (playtest 12). Refs #16


func test_given_every_tier_then_it_has_a_sound_effect_file() -> void:
	for tier in [ScoreTiers.SUPER_PERFECT, ScoreTiers.PERFECT, ScoreTiers.GOOD, ScoreTiers.OK, ScoreTiers.MISS]:
		assert_true(SoundFeedback.TIER_SFX.has(tier), tier)
		assert_true(ResourceLoader.exists(SoundFeedback.DIR + SoundFeedback.TIER_SFX[tier] + ".wav"), tier)


func test_given_combo_break_then_it_has_a_sound_effect_file() -> void:
	assert_true(ResourceLoader.exists(SoundFeedback.DIR + "sfx_combo_break.wav"))


func test_given_background_music_then_roadside_at_two_is_used() -> void:
	assert_eq(SoundFeedback.MUSIC, "res://assets/audio/music/roadside_at_two.wav")
	assert_true(ResourceLoader.exists(SoundFeedback.MUSIC))
