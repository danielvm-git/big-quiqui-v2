# story: e10s02
class_name BearPuzzleScene
extends Control
## The magnetic jigsaw minigame (e10s02): Urso's portrait sliced into four quadrant
## pieces, shuffled into a tray, dragged onto ghost slots on the board. Dropping near
## the matching slot locks the piece in place; wrong drops fly home. Settle pays
## coins and a star.

const FESTA_PATH: String = "res://scenes/festa.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/tema_principal.ogg"
const SUCCESS_SFX: String = "res://assets/audio/sfx/success.ogg"
const CONFETTI_SFX: String = "res://assets/audio/sfx/confete.ogg"

const FRIEND_ID: String = "urso"
const PIECE_COUNT: int = 4

const STATE_INTRO: String = "INTRO"
const STATE_PLAYING: String = "PLAYING"
const STATE_REWARD: String = "REWARD"
const LEGAL_EDGES: Dictionary = {
	STATE_INTRO: [STATE_PLAYING],
	STATE_PLAYING: [STATE_REWARD],
	STATE_REWARD: [STATE_INTRO],
}
const MAX_DWELL: Dictionary = {STATE_INTRO: 4.0, STATE_PLAYING: 240.0}
const INTRO_SEC: float = 1.0

var fsm: Fsm = null
var manual_step: bool = false

var board: Control = null
var hud: CoinTicketHud = null
var confetti: CPUParticles2D = null
var replay: Control = null
var hint_manager: Node = null
var drag_hint: Node = null

var _economy: EconomyData = EconomyData.new()
var _pieces: Array[PuzzlePiece] = []
var _slots: Array[Control] = []
var _seeded_order: Array[int] = []
var _tray_order: Array[int] = [0, 1, 2, 3]
var _state_t: float = 0.0
var _reward_paid: bool = false
var _hint_done: bool = false
var _fsm_clock_sec: float = 0.0


func _ready() -> void:
	board = get_node_or_null("Board") as Control
	hud = get_node_or_null("CoinTicketHud") as CoinTicketHud
	confetti = get_node_or_null("Confetti") as CPUParticles2D
	replay = get_node_or_null("ReplayButton") as Control
	hint_manager = get_node_or_null("HintManager")
	drag_hint = get_node_or_null("HintLayer/DragHint")
	fsm = Fsm.new(STATE_INTRO, LEGAL_EDGES, MAX_DWELL, Callable(self, "_fsm_clock_ms"))
	_bind_slots_and_pieces()
	if hint_manager != null and drag_hint != null:
		hint_manager.call("enqueue", drag_hint)
	_connect_chrome()
	close_celebrate_if_needed()
	_enter_state(STATE_INTRO)
	_play_stream("play_voice", FriendCatalog.voice_path(FRIEND_ID))
	_restore_music()
	_log("scene.ready", {"scene": "urso_puzzle"})


func _bind_slots_and_pieces() -> void:
	_slots.clear()
	_pieces.clear()
	var art_path: String = FriendCatalog.art_path(FRIEND_ID)
	var art: Texture2D = load(art_path) as Texture2D if ResourceLoader.exists(art_path) else null
	var sz: Vector2 = art.get_size() if art != null else Vector2(1024.0, 1024.0)
	for i: int in range(PIECE_COUNT):
		var slot: Control = get_node_or_null("Board/Slot%d" % i) as Control
		if slot != null:
			_slots.append(slot)
		var piece: PuzzlePiece = get_node_or_null("Tray/Piece%d" % i) as PuzzlePiece
		if piece != null:
			piece.piece_id = i
			piece.setup_quadrant(art, PuzzlePiece.quadrant_region(i, sz), slot)
			piece.locked.connect(_on_piece_locked)
			if piece.draggable != null:
				piece.draggable.drag_started.connect(_stop_hint)
			_pieces.append(piece)


func _connect_chrome() -> void:
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
	for piece: PuzzlePiece in _pieces:
		if piece != null and piece.draggable != null:
			piece.draggable.advance(delta)
	if hint_manager != null and hint_manager.has_method("advance"):
		hint_manager.call("advance", maxf(delta, 0.0))
	if drag_hint != null and drag_hint.has_method("advance"):
		drag_hint.call("advance", maxf(delta, 0.0))
	match fsm.state:
		STATE_INTRO:
			if _state_t >= INTRO_SEC:
				_go(STATE_PLAYING)
		STATE_PLAYING:
			if locked_count() >= PIECE_COUNT:
				_go(STATE_REWARD)
		STATE_REWARD:
			pass


func apply_economy(data: EconomyData) -> void:
	_economy = data if data != null else EconomyData.new()


func seed_shuffle(order: Array[int]) -> void:
	_seeded_order.assign(order)
	_apply_tray_order(_seeded_order)


func tray_order() -> Array[int]:
	var result: Array[int] = []
	result.assign(_tray_order)
	return result


func locked_count() -> int:
	var count: int = 0
	for piece: PuzzlePiece in _pieces:
		if piece != null and piece.is_locked():
			count += 1
	return count


func _on_piece_locked(id: int) -> void:
	_stop_hint()
	_play_stream("play_sfx", SUCCESS_SFX)
	_log("puzzle.lock", {"piece": id, "locked": locked_count()})
	if locked_count() >= PIECE_COUNT and fsm.state == STATE_PLAYING:
		_go(STATE_REWARD)


func _go(next_state: String) -> void:
	if fsm.transition_from(fsm.state, next_state):
		_enter_state(next_state)


func _enter_state(state: String) -> void:
	_state_t = 0.0
	match state:
		STATE_INTRO:
			_reward_paid = false
			_set_confetti(false)
			if replay != null:
				replay.visible = false
			for piece: PuzzlePiece in _pieces:
				if piece != null:
					piece.unlock()
			_shuffle_tray()
		STATE_PLAYING:
			if replay != null:
				replay.visible = false
			_hint_done = false
			call_deferred("_maybe_start_hint")
		STATE_REWARD:
			_stop_hint()
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
	if hud != null and board != null:
		hud.fly_coin(board.get_global_rect().get_center())
	_play_stream("play_sfx", CONFETTI_SFX)
	_log("puzzle.win", {"pieces": PIECE_COUNT, "coins": coins, "star": star})


func _shuffle_tray() -> void:
	var order: Array[int] = []
	if not _seeded_order.is_empty():
		order.assign(_seeded_order)
	else:
		order = [0, 1, 2, 3]
		order.shuffle()
	_apply_tray_order(order)


func _apply_tray_order(order: Array[int]) -> void:
	_tray_order.clear()
	_tray_order.assign(order)
	PuzzlePiece.apply_tray_layout(_pieces, order)


func _maybe_start_hint() -> void:
	if _hint_done or hint_manager == null or drag_hint == null:
		return
	if not bool(hint_manager.call("try_show_next")):
		return
	var first: PuzzlePiece = _first_unlocked_piece()
	if first == null or first.piece_id >= _slots.size():
		return
	var target_slot: Control = _slots[first.piece_id]
	drag_hint.call(
		"play", first.get_global_rect().get_center(), target_slot.get_global_rect().get_center(), target_slot
	)


func _first_unlocked_piece() -> PuzzlePiece:
	for piece: PuzzlePiece in _pieces:
		if piece != null and not piece.is_locked():
			return piece
	return null


func _stop_hint() -> void:
	_hint_done = true
	if hint_manager != null and hint_manager.has_method("stop_current"):
		hint_manager.call("stop_current")
		hint_manager.call("begin_cooldown", 2.0)
	if drag_hint != null and drag_hint.has_method("stop"):
		drag_hint.call("stop")


func _on_home_tapped() -> void:
	var manager: Node = get_node_or_null("/root/SceneManager")
	if manager != null:
		manager.call("request_scene", FESTA_PATH)


func _on_replay_tapped() -> void:
	_go(STATE_INTRO)


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
	if manager != null and stream != null and not bool(manager.call("is_music_playing", stream)):
		manager.call("play_music", stream)
		_log("music.start", {"track": "tema_principal"})


func _play_stream(method: String, path: String) -> bool:
	var stream: AudioStream = load(path) as AudioStream if ResourceLoader.exists(path) else null
	if stream == null:
		_log("audio.missing_art", {"track": path.get_file().get_basename()})
		return false
	var audio: Node = get_node_or_null("/root/AudioManager")
	return bool(audio.call(method, stream)) if audio != null else false


func _set_confetti(on: bool) -> void:
	if confetti != null:
		confetti.emitting = on
		if on:
			confetti.restart()


func _fsm_clock_ms() -> int:
	return int(_fsm_clock_sec * 1000.0)


func _log(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
