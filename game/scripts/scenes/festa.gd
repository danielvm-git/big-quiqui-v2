# story: e09s03
# story: e10s01
class_name HousePartyScene
extends Control
## The house party (e09s03): five placed pieces open it, four close it, and three friends
## dance while QuiQui celebrates. A locked party never scolds — it points at the casinha.
## e10s01: while the party dances, each friend is a door to their minigame.

const CASA_PATH: String = "res://scenes/casa.tscn"
const CASINHA_PATH: String = "res://scenes/casinha.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/main_theme.ogg"
const VOICE_KEY: String = "vo.party.congrats"
const CONFETTI_SFX: String = "res://assets/audio/sfx/confetti.ogg"

## The one threshold: the Vila badge and this scene both read it (e09s03 AC6).
const PARTY_MIN_PLACED: int = 5

const STATE_LOCKED: String = "LOCKED"
const STATE_DANCING: String = "DANCING"
const LEGAL_EDGES: Dictionary = {STATE_LOCKED: [STATE_DANCING], STATE_DANCING: [STATE_LOCKED]}

const BOB_PERIOD_SEC: float = 0.9
const BOB_HEIGHT_PX: float = 18.0
## Each friend is a third of a cycle behind the last, so the row ripples.
const PHASE_STEP_SEC: float = 0.3

var rig: QuiQuiRig = null
var hud: CoinTicketHud = null
var lock_badge: Control = null
var confetti: CPUParticles2D = null

var fsm: Fsm = null
var manual_step: bool = false

var _phase: float = 0.0
var _friend_base: Dictionary = {}


func _ready() -> void:
	rig = get_node_or_null("QuiQuiRig") as QuiQuiRig
	hud = get_node_or_null("CoinTicketHud") as CoinTicketHud
	lock_badge = get_node_or_null("LockBadge") as Control
	confetti = get_node_or_null("Confetti") as CPUParticles2D
	fsm = Fsm.new(STATE_LOCKED, LEGAL_EDGES, {})
	_remember_friend_bases()
	_connect_inputs()
	close_celebrate_if_needed()
	if party_unlocked():
		fsm.transition_to(STATE_DANCING)
	_apply_state()
	_restore_music()
	_log("scene.ready", {"scene": "festa"})


func _remember_friend_bases() -> void:
	for id: String in FriendCatalog.FRIEND_IDS:
		var friend: Control = get_node_or_null("Friend_" + id) as Control
		if friend != null:
			_friend_base[id] = friend.position.y


func _connect_inputs() -> void:
	var home: TapButton = get_node_or_null("HomeButton") as TapButton
	if home != null:
		home.tapped.connect(_on_home_tapped)
	var casinha: TapButton = get_node_or_null("CasinhaButton") as TapButton
	if casinha != null:
		casinha.tapped.connect(_on_casinha_tapped)
	if rig != null:
		rig.tapped.connect(_on_rig_tapped)
	for id: String in FriendCatalog.FRIEND_IDS:
		var friend: Control = get_node_or_null("Friend_" + id) as Control
		if friend != null:
			friend.connect("tapped", _on_friend_tapped.bind(id))
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress != null and progress.has_signal("progress_changed"):
		progress.progress_changed.connect(refresh_unlock)


func party_unlocked() -> bool:
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress == null or not progress.has_method("placed_count"):
		return false
	return int(progress.call("placed_count")) >= PARTY_MIN_PLACED


## Mount and every `progress_changed` land here. A repeat of the same state is a no-op,
## so the party announces one `party.dance` per opening, never one per coin.
func refresh_unlock() -> void:
	if fsm == null:
		return
	var want: String = STATE_DANCING if party_unlocked() else STATE_LOCKED
	if fsm.state == want or not fsm.transition_to(want):
		return
	_apply_state()


func _apply_state() -> void:
	var dancing: bool = fsm.state == STATE_DANCING
	if lock_badge != null:
		lock_badge.visible = not dancing
	if confetti != null:
		confetti.emitting = dancing
		if dancing:
			confetti.restart()
	_show_friends(dancing)
	_phase = 0.0
	_apply_bob()
	if dancing:
		VoicePlayback.play_key(self, VOICE_KEY)
		_play_stream("play_sfx", CONFETTI_SFX)
		rig_celebrate()
		_log("party.dance", {"placed": _placed_count()})
		return
	_log("party.locked", {"placed": _placed_count(), "needed": PARTY_MIN_PLACED})


func _show_friends(visible_now: bool) -> void:
	for id: String in FriendCatalog.FRIEND_IDS:
		var friend: Control = get_node_or_null("Friend_" + id) as Control
		if friend != null:
			friend.visible = visible_now


func rig_celebrate() -> void:
	if rig != null:
		rig.set_expression("jumping")


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


func advance(delta: float) -> void:
	if fsm == null or fsm.state != STATE_DANCING:
		return
	_phase += maxf(delta, 0.0)
	_apply_bob()


## Where each friend is in the bob, in pixels above her place. Pure: a function of the
## accumulated phase only, so `manual_step` replays the dance exactly.
func friend_offsets() -> Dictionary:
	var offsets: Dictionary = {}
	for index: int in range(FriendCatalog.FRIEND_IDS.size()):
		var local: float = _phase + float(index) * PHASE_STEP_SEC
		offsets[FriendCatalog.FRIEND_IDS[index]] = absf(sin(local * TAU / BOB_PERIOD_SEC)) * BOB_HEIGHT_PX
	return offsets


func _apply_bob() -> void:
	var offsets: Dictionary = friend_offsets()
	for id: String in FriendCatalog.FRIEND_IDS:
		var friend: Control = get_node_or_null("Friend_" + id) as Control
		if friend == null:
			continue
		var base: float = float(_friend_base.get(id, friend.position.y))
		friend.position.y = base - float(offsets[id])


func _placed_count() -> int:
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress == null or not progress.has_method("placed_count"):
		return 0
	return int(progress.call("placed_count"))


# ── scene glue ───────────────────────────────────────────────────────────────


func close_celebrate_if_needed() -> void:
	var manager: Node = get_node_or_null("/root/CareLoopManager")
	if manager != null and manager.has_method("close_celebrate_if_needed"):
		manager.call("close_celebrate_if_needed")


func _on_home_tapped() -> void:
	_exit_party(CASA_PATH)


## e10s01: the friends are the arcade. Only a dancing party opens games — the
## friends are hidden while locked, and this guard holds even for a forced tap.
func _on_friend_tapped(id: String) -> void:
	if fsm == null or fsm.state != STATE_DANCING:
		return
	_log("party.friend_game", {"friend": id})
	_request(FriendCatalog.scene_path(id))


func _on_casinha_tapped() -> void:
	_exit_party(CASINHA_PATH)


func _exit_party(path: String) -> void:
	if fsm != null and fsm.state == STATE_DANCING:
		fsm.transition_to(STATE_LOCKED)
	_request(path)


func _request(path: String) -> void:
	var manager: Node = get_node_or_null("/root/SceneManager")
	if manager != null:
		manager.call("request_scene", path)


func _on_rig_tapped() -> void:
	if rig != null:
		rig.set_expression("laughing")


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


func _log(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
