# story: e10s01
class_name DuckDanceScene
extends Control
## The duck dance (e10s01): three rounds of follow-the-duck pose matching. The duck
## hops onto one of three pads — the pose, because no pose art exists — and she taps
## the pad he landed on. A miss replays the same pose; nothing is ever lost. The win
## pays the economy table once and grants one star.

const FESTA_PATH: String = "res://scenes/festa.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/tema_principal.ogg"
const SUCCESS_SFX: String = "res://assets/audio/sfx/success.ogg"
const MISS_SFX: String = "res://assets/audio/sfx/erro_suave.ogg"
const CONFETTI_SFX: String = "res://assets/audio/sfx/confete.ogg"

const FRIEND_ID: String = "pato"
const TOTAL_ROUNDS: int = 3
const PAD_IDS: Array[String] = ["left", "centre", "right"]

const STATE_INTRO: String = "INTRO"
const STATE_SHOWING: String = "SHOWING"
const STATE_WAITING: String = "WAITING"
const STATE_REWARD: String = "REWARD"
const LEGAL_EDGES: Dictionary = {
	STATE_INTRO: [STATE_SHOWING],
	STATE_SHOWING: [STATE_WAITING],
	STATE_WAITING: [STATE_SHOWING, STATE_REWARD],
	STATE_REWARD: [STATE_INTRO],
}
## The dwell watchdog is anti-wedge, never anti-child: WAITING may legally last a
## whole shy minute. REWARD is terminal until she chooses.
const MAX_DWELL: Dictionary = {STATE_INTRO: 4.0, STATE_SHOWING: 6.0, STATE_WAITING: 120.0}

const INTRO_SEC: float = 1.4
const HOP_SEC: float = 0.6
const HOP_HEIGHT_PX: float = 60.0

var fsm: Fsm = null
var manual_step: bool = false
var round_index: int = 0

var duck: Control = null
var hud: CoinTicketHud = null
var confetti: CPUParticles2D = null
var replay: Control = null

var _economy: EconomyData = EconomyData.new()
var _seeded: Array[String] = []
var _pose: String = ""
var _state_t: float = 0.0
var _hop_from_x: float = 0.0
var _reward_paid: bool = false
var _fsm_clock_sec: float = 0.0
var _pads: Dictionary = {}


func _ready() -> void:
	duck = get_node_or_null("Duck") as Control
	hud = get_node_or_null("CoinTicketHud") as CoinTicketHud
	confetti = get_node_or_null("Confetti") as CPUParticles2D
	replay = get_node_or_null("ReplayButton") as Control
	fsm = Fsm.new(STATE_INTRO, LEGAL_EDGES, MAX_DWELL, Callable(self, "_fsm_clock_ms"))
	_bind_pads()
	_connect_inputs()
	close_celebrate_if_needed()
	_enter_state(STATE_INTRO)
	_play_stream("play_voice", FriendCatalog.voice_path(FRIEND_ID))
	_restore_music()
	_log("scene.ready", {"scene": "pato_danca"})


func _bind_pads() -> void:
	for pad_id: String in PAD_IDS:
		var pad: Control = get_node_or_null("Pad" + _cap(pad_id)) as Control
		if pad != null:
			_pads[pad_id] = pad


func _connect_inputs() -> void:
	for pad_id: String in _pads.keys():
		(_pads[pad_id] as Control).connect("tapped", _on_pad_tapped.bind(pad_id))
	var home: Control = get_node_or_null("HomeButton") as Control
	if home != null:
		home.connect("tapped", _on_home_tapped)
	if replay != null:
		replay.connect("tapped", _on_replay_tapped)


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


func advance(delta: float) -> void:
	if fsm == null:
		return
	_fsm_clock_sec += maxf(delta, 0.0)
	_state_t += maxf(delta, 0.0)
	match fsm.state:
		STATE_INTRO:
			if _state_t >= INTRO_SEC:
				_go(STATE_SHOWING)
		STATE_SHOWING:
			_fly_duck()
			if _state_t >= HOP_SEC:
				_go(STATE_WAITING)
		STATE_WAITING:
			_pulse_pads()
		STATE_REWARD:
			pass


func apply_economy(data: EconomyData) -> void:
	_economy = data if data != null else EconomyData.new()


func seed_rounds(poses: Array[String]) -> void:
	_seeded = poses.duplicate()


# ── one input path ────────────────────────────────────────────────────────────


func answer(pad: String) -> void:
	if fsm == null or fsm.state != STATE_WAITING or not _pads.has(pad):
		return
	if pad == _pose:
		round_index += 1
		_play_stream("play_sfx", SUCCESS_SFX)
		_log("duck.match", {"round": round_index, "pad": pad})
		if round_index >= TOTAL_ROUNDS:
			_pose = ""
			_go(STATE_REWARD)
		else:
			_pose = _next_pose()
			_go(STATE_SHOWING)
		return
	_play_stream("play_sfx", MISS_SFX)
	_log("duck.miss", {"round": round_index, "pad": pad})
	_go(STATE_SHOWING)


func _on_pad_tapped(pad_id: String) -> void:
	answer(pad_id)


# ── state glue ────────────────────────────────────────────────────────────────


func _go(next_state: String) -> void:
	if not fsm.transition_from(fsm.state, next_state):
		return
	_enter_state(next_state)


func _enter_state(state: String) -> void:
	_state_t = 0.0
	match state:
		STATE_INTRO:
			round_index = 0
			_pose = ""
			_reward_paid = false
			_set_confetti(false)
			if replay != null:
				replay.visible = false
		STATE_SHOWING:
			if _pose.is_empty():
				_pose = _next_pose()
			_hop_from_x = duck.position.x if duck != null else 0.0
			if replay != null:
				replay.visible = false
		STATE_WAITING:
			_log("duck.pose", {"round": round_index + 1, "pad": _pose})
		STATE_REWARD:
			_set_confetti(true)
			if replay != null:
				replay.visible = true
			_settle_reward()


func _settle_reward() -> void:
	if _reward_paid:
		return
	_reward_paid = true
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress == null:
		return
	var coins: int = FriendCatalog.coins_of(FRIEND_ID, _economy)
	progress.call("add_coins", coins)
	var star: bool = bool(progress.call("add_star", FRIEND_ID))
	if hud != null and duck != null:
		hud.fly_coin(duck.get_global_rect().get_center())
	_play_stream("play_sfx", CONFETTI_SFX)
	_log("duck.win", {"rounds": TOTAL_ROUNDS, "coins": coins, "star": star})


func _next_pose() -> String:
	if not _seeded.is_empty():
		return _seeded.pop_front()
	var roll: Array[String] = PAD_IDS.duplicate()
	roll.shuffle()
	return roll[0]


# ── motion ────────────────────────────────────────────────────────────────────


func _fly_duck() -> void:
	if duck == null or not _pads.has(_pose):
		return
	var target_x: float = (_pads[_pose] as Control).get_global_rect().get_center().x
	var ratio: float = clampf(_state_t / HOP_SEC, 0.0, 1.0)
	duck.global_position.x = lerpf(_hop_from_x, target_x, ratio)


func _pulse_pads() -> void:
	var glow: float = 0.5 + 0.5 * absf(sin(_state_t * TAU * 0.8))
	for pad_id: String in _pads.keys():
		var pad: Control = _pads[pad_id] as Control
		pad.modulate.a = 1.0 if pad_id == _pose else 0.9 - 0.2 * glow


# ── scene glue ────────────────────────────────────────────────────────────────


func _on_home_tapped() -> void:
	_request(FESTA_PATH)


func _on_replay_tapped() -> void:
	_go(STATE_INTRO)


func _request(path: String) -> void:
	var manager: Node = get_node_or_null("/root/SceneManager")
	if manager != null:
		manager.call("request_scene", path)


func close_celebrate_if_needed() -> void:
	var manager: Node = get_node_or_null("/root/CareLoopManager")
	if manager != null and manager.has_method("close_celebrate_if_needed"):
		manager.call("close_celebrate_if_needed")


func _restore_music() -> void:
	if not ResourceLoader.exists(MUSIC_PATH):
		_log("audio.missing_art", {"track": "tema_principal"})
		return
	var manager: Node = get_node_or_null("/root/AudioManager")
	var stream: AudioStream = load(MUSIC_PATH) as AudioStream
	if manager == null or stream == null or bool(manager.call("is_music_playing", stream)):
		return
	manager.call("play_music", stream)
	_log("music.start", {"track": "tema_principal"})


func _play_stream(method: String, path: String) -> bool:
	var stream: AudioStream = load(path) as AudioStream if ResourceLoader.exists(path) else null
	if stream == null:
		_log("audio.missing_art", {"track": path.get_file().get_basename()})
		return false
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio == null:
		return false
	return bool(audio.call(method, stream))


func _set_confetti(on: bool) -> void:
	if confetti == null:
		return
	confetti.emitting = on
	if on:
		confetti.restart()


func _fsm_clock_ms() -> int:
	return int(_fsm_clock_sec * 1000.0)


func _cap(value: String) -> String:
	return value[0].to_upper() + value.substr(1)


func _log(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
