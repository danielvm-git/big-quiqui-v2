# story: e01s02
extends GutTest
## SC-E01-P1-03 — four buses, 8-player SFX pool, 0.4 s crossfade and −9 dB
## voice ducking that restores the exact previous level.

var am: Node = null
var stream: AudioStreamWAV = null


func before_each() -> void:
	TestReset.reset_all()
	am = get_node_or_null("/root/AudioManager")
	assert_not_null(am, "AudioManager must be an autoload")
	am.manual_step = true
	am.reset()
	stream = AudioStreamWAV.new()


func after_each() -> void:
	am.reset()
	am.manual_step = false


func test_the_four_buses_exist_and_feed_master() -> void:
	for bus_name: String in ["Master", "Music", "SFX", "Voice"]:
		assert_ne(am.bus_index(bus_name), -1, "missing bus %s" % bus_name)
	for bus_name: String in ["Music", "SFX", "Voice"]:
		var index: int = am.bus_index(bus_name)
		assert_eq(AudioServer.get_bus_send(index), "Master", "%s must send to Master" % bus_name)


func test_sfx_pool_round_robins_across_eight_players() -> void:
	assert_eq(am.sfx_pool_size(), 8)

	var slots: Array[int] = []
	for play: int in range(9):
		slots.append(am.play_sfx(stream))

	assert_eq(slots.size(), 9)
	assert_eq(slots.slice(0, 8), [0, 1, 2, 3, 4, 5, 6, 7], "eight distinct players")
	assert_eq(slots[8], 0, "the ninth play reuses the first player")


func test_duck_lowers_music_and_sfx_by_nine_db_only() -> void:
	var music_before: float = am.bus_volume_db("Music")
	var sfx_before: float = am.bus_volume_db("SFX")
	var voice_before: float = am.bus_volume_db("Voice")

	am.apply_duck(true)

	assert_almost_eq(am.bus_volume_db("Music"), music_before + am.DUCK_DB, 0.01)
	assert_almost_eq(am.bus_volume_db("SFX"), sfx_before + am.DUCK_DB, 0.01)
	assert_almost_eq(am.bus_volume_db("Voice"), voice_before, 0.01, "voice is never ducked itself")
	assert_true(am.is_ducked)


func test_duck_restores_the_exact_previous_volume() -> void:
	var music_before: float = am.bus_volume_db("Music")
	var sfx_before: float = am.bus_volume_db("SFX")

	am.apply_duck(true)
	am.apply_duck(true)  # idempotent: must not duck twice
	assert_almost_eq(am.bus_volume_db("Music"), music_before + am.DUCK_DB, 0.01, "double duck")

	am.apply_duck(false)
	assert_almost_eq(am.bus_volume_db("Music"), music_before, 0.01)
	assert_almost_eq(am.bus_volume_db("SFX"), sfx_before, 0.01)
	assert_false(am.is_ducked)


func test_voice_play_ducks_and_completion_restores() -> void:
	var music_before: float = am.bus_volume_db("Music")

	assert_true(am.play_voice(stream), "a non-null stream plays")
	assert_true(am.is_ducked)

	am._on_voice_finished()

	assert_false(am.is_ducked)
	assert_almost_eq(am.bus_volume_db("Music"), music_before, 0.01)


func test_missing_streams_degrade_without_crashing() -> void:
	assert_false(am.play_music(null))
	assert_false(am.play_voice(null))
	assert_eq(am.play_sfx(null), -1)
	assert_false(am.is_ducked)


func test_music_crossfade_completes_in_four_tenths_of_a_second() -> void:
	assert_true(am.play_music(stream))
	assert_true(am.play_music(stream), "a second track starts a crossfade")
	assert_true(am.is_crossfading())

	am.advance(0.2)
	assert_true(am.is_crossfading(), "still fading at half time")

	am.advance(0.25)
	assert_false(am.is_crossfading(), "0.4 s ends the crossfade")
	assert_almost_eq(am._active_music.volume_db, am.music_db, 0.01)


func test_reset_clears_duck_and_cursor() -> void:
	am.apply_duck(true)
	am.play_sfx(stream)
	am.reset()

	assert_false(am.is_ducked)
	assert_eq(am.sfx_cursor(), 0)
	assert_almost_eq(am.bus_volume_db("Music"), am.music_db, 0.01)


# BUG-012: calls before _ready degrade like every other autoload.
func test_calls_before_ready_degrade() -> void:
	var fresh: Node = load("res://scripts/autoloads/audio_manager.gd").new()

	assert_false(bool(fresh.call("play_music", stream)), "no players yet, no crash")
	assert_false(bool(fresh.call("play_voice", stream)))
	assert_eq(int(fresh.call("play_sfx", stream)), -1)
	fresh.call("apply_duck", true)
	fresh.call("apply_duck", false)
	fresh.call("reset")
	fresh.free()
