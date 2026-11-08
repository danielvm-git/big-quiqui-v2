# story: e01s02
extends GutTest
## SC-E01-P1-03 — four buses, 8-player SFX pool, 0.4 s crossfade and −9 dB
## voice ducking that restores the exact previous level.

const MUSIC_DIR: String = "res://assets/audio/music/"
const MUSIC_TRACK_COUNT: int = 5

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


# Review M1: looping is an import setting, and AudioManager never sets it.
func test_every_music_track_is_imported_to_loop() -> void:
	var tracks: Array[String] = []
	for file_name: String in ResourceLoader.list_directory(MUSIC_DIR):
		if file_name.ends_with(".ogg"):
			tracks.append(file_name)
	assert_eq(tracks.size(), MUSIC_TRACK_COUNT, "the test must see every track")

	for file_name: String in tracks:
		var music: AudioStreamOggVorbis = load(MUSIC_DIR + file_name) as AudioStreamOggVorbis
		assert_not_null(music, file_name)
		assert_true(music.loop, "%s must loop" % file_name)


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


func test_is_music_playing_names_only_the_active_stream() -> void:
	var other: AudioStreamWAV = AudioStreamWAV.new()
	assert_false(am.is_music_playing(stream), "nothing plays yet")

	am.play_music(stream)

	assert_true(am.is_music_playing(stream))
	assert_false(am.is_music_playing(other))
	assert_false(am.is_music_playing(null))

	am.play_music(other)

	assert_false(am.is_music_playing(stream), "the outgoing track is not the music any more")
	assert_true(am.is_music_playing(other))


func test_is_music_playing_is_false_after_a_reset() -> void:
	am.play_music(stream)
	am.reset()

	assert_false(am.is_music_playing(stream))


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


# BUG-028: quitting with an Ogg playback live leaks four objects and two resources
# (`--quit-after 3` reported them on every run). Releasing the streams first is the fix.
func test_release_streams_stops_every_player_and_drops_its_stream() -> void:
	am.play_music(stream)
	am.play_voice(stream)
	am.play_sfx(stream)

	am.call("release_streams")

	for player: AudioStreamPlayer in am.call("_all_players"):
		assert_false(player.playing, "%s stopped" % player.name)
		assert_null(player.stream, "%s dropped its stream" % player.name)
	assert_false(am.is_music_playing(stream))


func test_exit_tree_is_safe_twice_and_without_players() -> void:
	am.play_music(stream)
	am.call("_exit_tree")
	am.call("_exit_tree")

	assert_false(am.is_music_playing(stream))


func test_voice_key_resolves_to_pt_br_stream() -> void:
	var path: String = AudioManager.voice_path_for_key("vo.kitchen.intro")
	assert_eq(path, "res://assets/audio/voice/pt_BR/kitchen_intro.ogg")
	assert_true(ResourceLoader.exists(path))
	assert_true(am.play_voice_key("vo.kitchen.intro"))


func test_an_unknown_voice_key_returns_false_and_logs_missing_key() -> void:
	assert_false(am.play_voice_key("vo.kitchen.does_not_exist"))
	assert_eq(_last_ev(), "audio.missing_key")


func test_an_invalid_voice_key_segment_is_rejected() -> void:
	assert_eq(AudioManager.voice_path_for_key("vo.Kitchen.intro"), "")
	assert_false(am.play_voice_key("vo.../../../etc.intro"))


func _last_ev() -> String:
	var diary: Node = get_node_or_null("/root/Log")
	if diary == null:
		return ""
	var lines: PackedStringArray = FileAccess.get_file_as_string(str(diary.log_path)).strip_edges().split("\n")
	if lines.is_empty():
		return ""
	var row: Dictionary = JSON.parse_string(lines[lines.size() - 1]) as Dictionary
	return str(row.get("ev", ""))
