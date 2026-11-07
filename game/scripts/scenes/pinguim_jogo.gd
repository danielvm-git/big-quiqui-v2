# story: e10s03
class_name PenguinScene
extends Control
## Interactive ball/bubble catch minigame with Pinguim (e10s03).
## Continuous gesture: Pinguim slides across the ice lane via CONTINUOUS_SCRUB,
## catching falling balls and bubbles. All game logic is driven inside advance().

const FESTA_PATH: String = "res://scenes/festa.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/tema_principal.ogg"
const POP_SFX: String = "res://assets/audio/sfx/bolha.ogg"
const CONFETTI_SFX: String = "res://assets/audio/sfx/confete.ogg"

const FRIEND_ID: String = "pinguim"

const STATE_INTRO: String = "INTRO"
const STATE_RUNNING: String = "RUNNING"
const STATE_RESULT: String = "RESULT"
const STATE_REWARD: String = "REWARD"
const LEGAL_EDGES: Dictionary = {
	STATE_INTRO: [STATE_RUNNING],
	STATE_RUNNING: [STATE_RESULT],
	STATE_RESULT: [STATE_REWARD],
	STATE_REWARD: [STATE_INTRO],
}
const MAX_DWELL: Dictionary = {STATE_INTRO: 4.0, STATE_RUNNING: 60.0, STATE_RESULT: 10.0}

const INTRO_SEC: float = 1.0
const RESULT_SEC: float = 1.5
const ROUND_SEC: float = 20.0
const STAR_TARGET: int = 6

var fsm: Fsm = null
var manual_step: bool = false
var round_sec: float = 0.0

var lane: Control = null
var penguin: Control = null
var penguin_draggable: TouchDraggable = null
var items_container: Control = null
var hud: CoinTicketHud = null
var confetti: CPUParticles2D = null
var replay: Control = null

var _economy: EconomyData = EconomyData.new()
var _spawn_timer: float = 0.0
var _spawn_interval: float = 1.1
var _fall_speed: float = 260.0
var _seeded_spawns: Array[String] = []
var _items: Array[CatchItem] = []
var _catches: int = 0
var _state_t: float = 0.0
var _reward_paid: bool = false
var _fsm_clock_sec: float = 0.0


func _ready() -> void:
	lane = get_node_or_null("IceLane") as Control
	penguin = get_node_or_null("Penguin") as Control
	items_container = get_node_or_null("ItemsContainer") as Control
	hud = get_node_or_null("CoinTicketHud") as CoinTicketHud
	confetti = get_node_or_null("Confetti") as CPUParticles2D
	replay = get_node_or_null("ReplayButton") as Control
	fsm = Fsm.new(STATE_INTRO, LEGAL_EDGES, MAX_DWELL, Callable(self, "_fsm_clock_ms"))
	_setup_penguin_draggable()
	_connect_chrome()
	close_celebrate_if_needed()
	_enter_state(STATE_INTRO)
	_play_stream("play_voice", FriendCatalog.voice_path(FRIEND_ID))
	_restore_music()
	_log("scene.ready", {"scene": "pinguim_jogo"})


func _setup_penguin_draggable() -> void:
	if penguin != null and lane != null:
		penguin_draggable = penguin.get_node_or_null("Draggable") as TouchDraggable
		if penguin_draggable != null:
			penguin_draggable.mode = TouchDraggable.Mode.CONTINUOUS_SCRUB
			penguin_draggable.scrub_target = lane
			penguin_draggable.scrubbed.connect(_on_penguin_scrubbed)


func _connect_chrome() -> void:
	var home: Control = get_node_or_null("HomeButton") as Control
	if home != null:
		home.connect("tapped", _on_home_tapped)
	if replay != null:
		replay.connect("tapped", _on_replay_tapped)


func _process(delta: float) -> void:
	if not manual_step:
		advance(delta)


func advance(delta: float) -> void:
	if fsm == null:
		return
	_fsm_clock_sec += maxf(delta, 0.0)
	_state_t += maxf(delta, 0.0)
	match fsm.state:
		STATE_INTRO:
			if _state_t >= INTRO_SEC:
				_go(STATE_RUNNING)
		STATE_RUNNING:
			round_sec += delta
			_step_items(delta)
			_spawn_timer += delta
			if _spawn_timer >= _spawn_interval:
				_spawn_timer -= _spawn_interval
				_spawn_next_item()
			if round_sec >= ROUND_SEC:
				_go(STATE_RESULT)
		STATE_RESULT:
			if _state_t >= RESULT_SEC:
				_go(STATE_REWARD)


func apply_economy(data: EconomyData) -> void:
	_economy = data if data != null else EconomyData.new()


func seed_spawns(types: Array[String]) -> void:
	_seeded_spawns.assign(types)


func catch_count() -> int:
	return _catches


func _on_penguin_scrubbed(global_point: Vector2) -> void:
	if lane != null and penguin != null:
		var lane_obj: IceLane = lane as IceLane
		if lane_obj != null:
			penguin.global_position.x = lane_obj.clamp_penguin_x(global_point.x, penguin.size.x)


func _step_items(delta: float) -> void:
	var fall_px: float = _fall_speed * delta
	var catch_rect: Rect2 = _penguin_catch_rect()
	var floor_y: float = _floor_y()
	var to_remove: Array[CatchItem] = []
	for item: CatchItem in _items:
		if item == null or not is_instance_valid(item):
			to_remove.append(item)
			continue
		item.step_down(fall_px)
		var item_rect: Rect2 = item.get_global_rect()
		if not item.popped and item_rect.intersects(catch_rect):
			_catch_item(item, to_remove)
		elif item_rect.position.y >= floor_y:
			_log("penguin.miss", {"item": item.kind})
			to_remove.append(item)
	_cleanup_items(to_remove)


func _catch_item(item: CatchItem, to_remove: Array[CatchItem]) -> void:
	item.popped = true
	_catches += 1
	item.visible = false
	to_remove.append(item)
	_play_stream("play_sfx", POP_SFX)
	_log("penguin.catch", {"item": item.kind, "total": _catches})


func _cleanup_items(to_remove: Array[CatchItem]) -> void:
	for item: CatchItem in to_remove:
		_items.erase(item)
		if item != null and is_instance_valid(item):
			item.queue_free()


func _spawn_next_item() -> void:
	if not _seeded_spawns.is_empty():
		spawn_item(_seeded_spawns.pop_front())
	else:
		spawn_item("bolha" if randf() > 0.5 else "bola")


func spawn_item(kind: String, at_x: float = -1.0) -> CatchItem:
	var item: CatchItem = CatchItem.create(kind, _calc_spawn_pos(at_x))
	_items.append(item)
	var parent_node: Node = items_container if items_container != null else self
	parent_node.add_child(item)
	return item


func _calc_spawn_pos(explicit_x: float) -> Vector2:
	if explicit_x >= 0.0:
		return Vector2(explicit_x, 60.0)
	if lane != null:
		var r: Rect2 = lane.get_global_rect()
		return Vector2(randf_range(r.position.x + 40.0, r.end.x - 40.0), 60.0)
	return Vector2(400.0, 60.0)


func _penguin_catch_rect() -> Rect2:
	return penguin.get_global_rect() if penguin != null else Rect2()


func _floor_y() -> float:
	return lane.get_global_rect().end.y + 40.0 if lane != null else 1000.0


func _go(next_state: String) -> void:
	if fsm.transition_from(fsm.state, next_state):
		_enter_state(next_state)


func _enter_state(state: String) -> void:
	_state_t = 0.0
	if replay != null:
		replay.visible = (state == STATE_REWARD)
	match state:
		STATE_INTRO:
			round_sec = 0.0
			_catches = 0
			_reward_paid = false
			_set_confetti(false)
			_clear_all_items()
		STATE_RESULT:
			_settle_reward()
		STATE_REWARD:
			_set_confetti(true)


func _clear_all_items() -> void:
	for item: CatchItem in _items:
		if item != null and is_instance_valid(item):
			item.queue_free()
	_items.clear()


func _settle_reward() -> void:
	if _reward_paid:
		return
	_reward_paid = true
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress == null:
		return
	var coins: int = _catches
	progress.call("add_coins", coins)
	var star: bool = _catches >= STAR_TARGET and bool(progress.call("add_star", FRIEND_ID))
	if hud != null and penguin != null:
		hud.fly_coin(penguin.get_global_rect().get_center())
	_play_stream("play_sfx", CONFETTI_SFX)
	_log("penguin.settle", {"catches": _catches, "coins": coins, "star": star})


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
