# story: e03s03
class_name KitchenScene
extends Control
## The FEED room: three foods on a tray, dragged to QuiQui's mouth. Each bite is
## one walk of the `kitchen_feed` machine (EXPLICIT_STATE_MACHINES §6). The third
## bite credits FEED, when FEED is the current step, and goes back to the Casa.
##
## Coming back after FEED is free play: she still eats and nothing is credited.

const BITES_TO_FINISH: int = 3
const CASA_PATH: String = "res://scenes/casa.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/cozinha.ogg"
const VOICE_PATH: String = "res://assets/audio/voice/feed_hora_de_comer.ogg"
const BITE_SFX_PATH: String = "res://assets/audio/sfx/nhami.ogg"

const DROP_MARGIN: float = 120.0
const IDLE_WISH_SEC: float = 8.0
const CHEW_SEC: float = 0.9
const PLEASURE_SEC: float = 0.9
## Foods that cannot be picked up look it, so a pre-reader sees they are not ready.
const DISABLED_FOOD_ALPHA: float = 0.5

const STATE_READY: String = "READY"
const STATE_CHEWING: String = "CHEWING"
const STATE_PLEASURE: String = "PLEASURE"
const STATE_FINISHED: String = "FINISHED"
const LEGAL_EDGES: Dictionary = {
	STATE_READY: [STATE_CHEWING],
	STATE_CHEWING: [STATE_PLEASURE],
	STATE_PLEASURE: [STATE_READY, STATE_FINISHED],
	STATE_FINISHED: [],
}
const MAX_DWELL_SEC: Dictionary = {STATE_CHEWING: 2.0, STATE_PLEASURE: 2.0}

@onready var rig: QuiQuiRig = $QuiQuiRig as QuiQuiRig
@onready var bubble: WishBubble = $WishBubble as WishBubble
@onready var crumbs: CPUParticles2D = $Crumbs as CPUParticles2D
@onready var hearts: CPUParticles2D = $Hearts as CPUParticles2D

var fsm: Fsm = null
var bites: int = 0
## Test seam: when true, `_process` does nothing and only `advance()` runs.
var manual_step: bool = false
## 0 varies the tray on every visit; tests set a fixed seed before entering the tree.
var seed_value: int = 0
var tray: Array[ItemData] = []

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _clock_sec: float = 0.0
var _idle_sec: float = 0.0
## One way out per visit, across FINISHED and HomeButton.
var _casa_requested: bool = false


func _ready() -> void:
	fsm = Fsm.new(STATE_READY, LEGAL_EDGES, MAX_DWELL_SEC, _clock_ms)
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value
	tray = FoodCatalog.pick_tray(_rng, BITES_TO_FINISH)
	_wire_foods()
	rig.tapped.connect(_reset_idle)
	($HomeButton as TapButton).tapped.connect(_on_home_tapped)
	if _care_state() == CareSteps.IDLE:
		_care_loop().call("begin_step", CareSteps.FEED)
	_play_stream("play_music", MUSIC_PATH)
	_play_stream("play_voice", VOICE_PATH)
	_log("scene.ready", {"scene": "cozinha"})


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


func advance(delta: float) -> void:
	var step: float = maxf(delta, 0.0)
	_clock_sec += step
	match fsm.state:
		STATE_READY:
			_advance_idle(step)
		STATE_CHEWING:
			if fsm.check_dwell() or fsm.elapsed_sec() >= CHEW_SEC:
				_start_pleasure()
		STATE_PLEASURE:
			if fsm.check_dwell() or fsm.elapsed_sec() >= PLEASURE_SEC:
				_end_bite()


func food(index: int) -> TouchDraggable:
	return get_node_or_null("Food%d" % index) as TouchDraggable


func _wire_foods() -> void:
	for index: int in range(BITES_TO_FINISH):
		var item: TouchDraggable = food(index)
		item.drop_target = rig.mouth_zone
		item.drop_margin = DROP_MARGIN
		item.drag_started.connect(_reset_idle)
		item.drag_moved.connect(rig.update_food_proximity)
		item.drag_ended.connect(_on_drag_ended.bind(item))
		item.consumed.connect(_on_food_consumed.bind(index))
		if index < tray.size():
			(item.get_node("Art") as TextureRect).texture = tray[index].texture()


## `drag_ended` fires before `consumed`: a consumed food leaves the face to the bite.
func _on_drag_ended(item: TouchDraggable) -> void:
	if item.state_id() != TouchDraggable.STATE_CONSUMED:
		rig.clear_food_proximity()


func _on_food_consumed(index: int) -> void:
	if not fsm.transition_from(STATE_READY, STATE_CHEWING):
		return
	bites += 1
	_set_foods_enabled(false)
	food(index).visible = false
	# In this order: clearing first would flash the base face.
	rig.set_expression("mastigando")
	rig.clear_food_proximity()
	_burst(crumbs)
	_play_stream("play_sfx", BITE_SFX_PATH)
	_log("kitchen.bite", {"bites": bites, "item": tray[index].id if index < tray.size() else "unknown"})


func _start_pleasure() -> void:
	fsm.transition_from(STATE_CHEWING, STATE_PLEASURE)
	rig.set_expression("prazer")
	_burst(hearts)


func _end_bite() -> void:
	if bites < BITES_TO_FINISH:
		fsm.transition_from(STATE_PLEASURE, STATE_READY)
		rig.set_expression(QuiQuiRig.NEUTRAL_EXPRESSION)
		_set_foods_enabled(true)
		_idle_sec = 0.0
		return
	fsm.transition_from(STATE_PLEASURE, STATE_FINISHED)
	if _care_state() == CareSteps.FEED:
		_care_loop().call("complete_step", CareSteps.FEED)
	_request_casa()


## In FINISHED this does nothing: FEED is already credited and the Casa requested.
## During the last bite every food is eaten, so the step is earned, not abandoned.
func _on_home_tapped() -> void:
	if _care_state() == CareSteps.FEED:
		if bites >= BITES_TO_FINISH:
			_care_loop().call("complete_step", CareSteps.FEED)
		else:
			_care_loop().call("abandon_step")
	_request_casa()


func _request_casa() -> void:
	if _casa_requested:
		return
	_casa_requested = true
	var manager: Node = get_node_or_null("/root/SceneManager")
	if manager != null:
		manager.call("request_scene", CASA_PATH)


func _advance_idle(step: float) -> void:
	if _is_holding_food():
		_idle_sec = 0.0
		return
	_idle_sec += step
	if _idle_sec < IDLE_WISH_SEC:
		return
	_idle_sec = 0.0
	if not bubble.is_showing():
		rig.set_expression("carente")
		bubble.show_wish(_next_wish_art())


## The first food still on the tray: she only asks for what the child can give her.
func _next_wish_art() -> String:
	for index: int in range(tray.size()):
		if food(index).state_id() != TouchDraggable.STATE_CONSUMED:
			return tray[index].art_path
	return ""


func _reset_idle() -> void:
	_idle_sec = 0.0
	if bubble.is_showing():
		bubble.hide_wish()
	if rig.expression_id == "carente":
		rig.set_expression(QuiQuiRig.NEUTRAL_EXPRESSION)


func _is_holding_food() -> bool:
	for index: int in range(BITES_TO_FINISH):
		if food(index).state_id() == TouchDraggable.STATE_DRAGGING:
			return true
	return false


func _set_foods_enabled(value: bool) -> void:
	for index: int in range(BITES_TO_FINISH):
		food(index).enabled = value
		food(index).modulate.a = 1.0 if value else DISABLED_FOOD_ALPHA


func _burst(particles: CPUParticles2D) -> void:
	particles.global_position = rig.mouth_global_center()
	particles.restart()


## Callers check this first: a call from a state without the edge would log
## `fsm.illegal_transition`. "" (no manager) matches no step, so nothing is called.
func _care_state() -> String:
	var manager: Node = _care_loop()
	return "" if manager == null else str(manager.call("state_id"))


func _care_loop() -> Node:
	return get_node_or_null("/root/CareLoopManager")


## `method` is an AudioManager play call. A missing stream logs and the scene goes on.
func _play_stream(method: String, path: String) -> bool:
	var stream: AudioStream = load(path) as AudioStream if ResourceLoader.exists(path) else null
	if stream == null:
		_log("audio.missing_art", {"track": path.get_file().get_basename()})
		return false
	var manager: Node = get_node_or_null("/root/AudioManager")
	if manager == null:
		return false
	manager.call(method, stream)
	return true


func _clock_ms() -> int:
	return int(_clock_sec * 1000.0)


func _log(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
