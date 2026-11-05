# story: e01s02
extends Node
## Four-bus audio with deterministic control: Music, SFX, Voice under Master,
## 0.4 s music crossfade, 8-player SFX round-robin and −9 dB ducking of
## music+SFX while a voice line plays.
##
## Everything degrades instead of crashing (CONVENTIONS §4): a missing stream
## logs and returns false, a missing bus is created, and ducking restores the
## exact previous volume rather than assuming 0 dB.

const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"
const BUS_VOICE: String = "Voice"

const DEFAULT_BUSES: Array[String] = [BUS_MUSIC, BUS_SFX, BUS_VOICE]
const SFX_POOL_SIZE: int = 8
const CROSSFADE_SEC: float = 0.4
const DUCK_DB: float = -9.0

var music_db: float = -6.0
var sfx_db: float = -3.0
var voice_db: float = 0.0

var is_ducked: bool = false
## Test seam: when true, `_process` does nothing and only `advance()` runs.
var manual_step: bool = false

var _music_a: AudioStreamPlayer = null
var _music_b: AudioStreamPlayer = null
var _active_music: AudioStreamPlayer = null
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_cursor: int = 0
var _voice: AudioStreamPlayer = null

var _ducked_buses: Dictionary = {}
var _crossfade_elapsed: float = 0.0
var _crossfading: bool = false


func _ready() -> void:
	_ensure_buses()
	_build_players()
	_apply_bus_volumes()


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


# ── buses ────────────────────────────────────────────────────────────────────


func _ensure_buses() -> void:
	for bus_name: String in DEFAULT_BUSES:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		var index: int = AudioServer.bus_count
		AudioServer.add_bus(index)
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, BUS_MASTER)


func bus_index(bus_name: String) -> int:
	return AudioServer.get_bus_index(bus_name)


func bus_volume_db(bus_name: String) -> float:
	var index: int = bus_index(bus_name)
	if index == -1:
		return 0.0
	return AudioServer.get_bus_volume_db(index)


func _apply_bus_volumes() -> void:
	_set_bus_db(BUS_MUSIC, music_db)
	_set_bus_db(BUS_SFX, sfx_db)
	_set_bus_db(BUS_VOICE, voice_db)


func _set_bus_db(bus_name: String, db: float) -> void:
	var index: int = bus_index(bus_name)
	if index != -1:
		AudioServer.set_bus_volume_db(index, db)


# ── players ──────────────────────────────────────────────────────────────────


func _build_players() -> void:
	_music_a = _make_player("MusicA", BUS_MUSIC)
	_music_b = _make_player("MusicB", BUS_MUSIC)
	_active_music = _music_a
	for slot: int in range(SFX_POOL_SIZE):
		_sfx_pool.append(_make_player("Sfx%d" % slot, BUS_SFX))
	_voice = _make_player("Voice", BUS_VOICE)
	_voice.finished.connect(_on_voice_finished)


func _make_player(player_name: String, bus_name: String) -> AudioStreamPlayer:
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus_name
	add_child(player)
	return player


# ── music ────────────────────────────────────────────────────────────────────


## Crossfades to `stream`. Returns false (and logs) when there is nothing to play.
func play_music(stream: AudioStream) -> bool:
	if stream == null:
		_emit("audio.missing_stream", {"bus": "music"})
		return false
	var outgoing: AudioStreamPlayer = _active_music
	var incoming: AudioStreamPlayer = _music_b if _active_music == _music_a else _music_a
	incoming.stream = stream
	incoming.volume_db = music_db - 40.0
	incoming.play()
	_active_music = incoming
	_crossfade_elapsed = 0.0
	_crossfading = true
	if outgoing != null and outgoing.playing:
		outgoing.volume_db = music_db
	_emit("audio.music_start", {"bus": "music"})
	return true


func advance(delta: float) -> void:
	if not _crossfading:
		return
	_crossfade_elapsed += maxf(delta, 0.0)
	var span: float = CROSSFADE_SEC if CROSSFADE_SEC > 0.0 else 0.0001
	var ratio: float = clampf(_crossfade_elapsed / span, 0.0, 1.0)
	var target: AudioStreamPlayer = _active_music
	var other: AudioStreamPlayer = _music_b if target == _music_a else _music_a
	target.volume_db = lerpf(music_db - 40.0, music_db, ratio)
	other.volume_db = lerpf(music_db, music_db - 40.0, ratio)
	if ratio >= 1.0:
		_crossfading = false
		other.stop()


func is_crossfading() -> bool:
	return _crossfading


# ── sfx ──────────────────────────────────────────────────────────────────────


## Plays on the next pool player (round-robin). Returns the slot, or -1.
func play_sfx(stream: AudioStream) -> int:
	if stream == null:
		_emit("audio.missing_stream", {"bus": "sfx"})
		return -1
	if _sfx_pool.is_empty():
		return -1
	var slot: int = _sfx_cursor
	_sfx_cursor = (_sfx_cursor + 1) % _sfx_pool.size()
	var player: AudioStreamPlayer = _sfx_pool[slot]
	player.stream = stream
	player.play()
	_emit("audio.sfx", {"bus": "sfx", "slot": slot})
	return slot


func sfx_pool_size() -> int:
	return _sfx_pool.size()


func sfx_cursor() -> int:
	return _sfx_cursor


# ── voice + ducking ──────────────────────────────────────────────────────────


func play_voice(stream: AudioStream) -> bool:
	if stream == null:
		_emit("audio.missing_stream", {"bus": "voice"})
		return false
	_voice.stream = stream
	_voice.play()
	apply_duck(true)
	_emit("audio.voice_start", {"bus": "voice"})
	return true


func apply_duck(active: bool) -> void:
	if active == is_ducked:
		return
	if active:
		_ducked_buses = {
			BUS_MUSIC: bus_volume_db(BUS_MUSIC),
			BUS_SFX: bus_volume_db(BUS_SFX),
		}
		_set_bus_db(BUS_MUSIC, float(_ducked_buses[BUS_MUSIC]) + DUCK_DB)
		_set_bus_db(BUS_SFX, float(_ducked_buses[BUS_SFX]) + DUCK_DB)
	else:
		for bus_name: String in _ducked_buses.keys():
			_set_bus_db(bus_name, float(_ducked_buses[bus_name]))
		_ducked_buses.clear()
	is_ducked = active
	_emit("audio.duck", {"bus": "music", "on": active})


func _on_voice_finished() -> void:
	apply_duck(false)
	_emit("audio.voice_end", {"bus": "voice"})


# ── lifecycle ────────────────────────────────────────────────────────────────


func reset() -> void:
	for player: AudioStreamPlayer in _all_players():
		player.stop()
		player.stream = null
		player.volume_db = 0.0
	_active_music = _music_a
	_sfx_cursor = 0
	_crossfading = false
	_crossfade_elapsed = 0.0
	if is_ducked:
		apply_duck(false)
	_ducked_buses.clear()
	_apply_bus_volumes()


func _all_players() -> Array[AudioStreamPlayer]:
	var players: Array[AudioStreamPlayer] = [_music_a, _music_b, _voice]
	players.append_array(_sfx_pool)
	return players


func _emit(ev: String, data: Dictionary) -> void:
	var sink: Node = get_node_or_null("/root/Log")
	if sink != null and sink.has_method("event"):
		sink.call("event", ev, data)
