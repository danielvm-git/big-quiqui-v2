# story: e02s03
class_name CasaScene
extends Control
## The hub of the game: QuiQui in her sala, five room doors plus the Vila door,
## the cycle dots and the economy HUD. The child decides where to go by tapping
## a door — no text anywhere.
##
## Doors to scenes that do not exist yet (each care room arrives with its own
## epic) log `scene.pending` instead of navigating, exactly like the e01 Play
## button did: the hub is honest, never broken.

signal door_requested(step: String)

const DOOR_SCENES: Dictionary = {
	"FEED": "res://scenes/cozinha.tscn",
	"BATH": "res://scenes/banheiro.tscn",
	"DRESS": "res://scenes/closet.tscn",
	"PLAY": "res://scenes/jardim.tscn",
	"SLEEP": "res://scenes/quarto_sono.tscn",
	"VILA": "res://scenes/vila.tscn",
}

## What QuiQui asks for in each step (DESIGN.md: the wish bubble carries the
## prompt, not words).
const WISH_ICONS: Dictionary = {
	"FEED": "res://assets/art/items/cenoura.png",
	"BATH": "res://assets/art/items/sabonete.png",
	"DRESS": "res://assets/art/items/tiara_flores.png",
	"PLAY": "res://assets/art/items/bola.png",
	"SLEEP": "res://assets/art/efeitos/zzz.png",
}

const VOICE_PATH: String = "res://assets/audio/voice/hub_bem_vindo.ogg"
const IDLE_WISH_SEC: float = 8.0
const DOOR_DIM_ALPHA: float = 0.72

@onready var rig: QuiQuiRig = get_node_or_null("QuiQuiRig") as QuiQuiRig
@onready var bubble: WishBubble = get_node_or_null("WishBubble") as WishBubble
@onready var dots: CareDotsBar = get_node_or_null("CareDotsBar") as CareDotsBar
@onready var hud: CoinTicketHud = get_node_or_null("CoinTicketHud") as CoinTicketHud

## Test seam: when true, `_process` does nothing and only `advance()` steps the
## idle timer, so a test's timeline is the only timeline.
var manual_step: bool = false

var door_taps: int = 0
var voice_started: bool = false

var _idle_sec: float = 0.0
var _wish_shown_for_idle: bool = false


func _ready() -> void:
	for step: String in DOOR_SCENES:
		var door: TapButton = door(step)
		if door != null:
			door.tapped.connect(_on_door_tapped.bind(step))
	if rig != null:
		rig.tapped.connect(_on_rig_tapped)
	_connect_care_loop()
	_play_voice()
	_refresh_from_care_loop()
	_log("scene.ready", {"scene": "casa"})


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


## Steps the idle timer. After IDLE_WISH_SEC without a touch, QuiQui shows the
## carente face and asks for the next step of the cycle (DESIGN.md §4.3).
func advance(delta: float) -> void:
	_idle_sec += maxf(delta, 0.0)
	if _idle_sec < IDLE_WISH_SEC or _wish_shown_for_idle:
		return
	var step: String = _care_next_step()
	if step.is_empty() or not WISH_ICONS.has(step):
		return
	_wish_shown_for_idle = true
	if rig != null:
		rig.set_expression("carente")
	if bubble != null:
		bubble.show_wish(WISH_ICONS[step])


func door(step: String) -> TapButton:
	return get_node_or_null("Door" + step) as TapButton


func _on_door_tapped(step: String) -> void:
	door_taps += 1
	door_requested.emit(step)
	_reset_idle()
	var path: String = DOOR_SCENES.get(step, "")
	if ResourceLoader.exists(path):
		var manager: Node = get_node_or_null("/root/SceneManager")
		if manager != null:
			manager.call("request_scene", path)
		return
	_log("scene.pending", {"target": path.get_file().get_basename()})


func _on_rig_tapped() -> void:
	# A tap on QuiQui is affection, not navigation: she laughs back.
	_reset_idle()
	if rig != null:
		rig.set_expression("rindo")


func _reset_idle() -> void:
	_idle_sec = 0.0
	_wish_shown_for_idle = false
	if bubble != null and bubble.is_showing():
		bubble.hide_wish()


func _connect_care_loop() -> void:
	var manager: Node = get_node_or_null("/root/CareLoopManager")
	if manager != null and manager.has_signal("loop_state_changed"):
		manager.loop_state_changed.connect(_on_loop_changed)


func _on_loop_changed(_from_state: String, _to_state: String) -> void:
	_reset_idle()
	_refresh_from_care_loop()


func _refresh_from_care_loop() -> void:
	var completed: int = _care_completed_steps()
	if dots != null:
		dots.set_completed_steps(completed)
	var next: String = _care_next_step()
	for step: String in DOOR_SCENES:
		var door_node: TapButton = door(step)
		if door_node == null:
			continue
		door_node.modulate = Color(1.0, 1.0, 1.0, 1.0 if step == next else DOOR_DIM_ALPHA)


func _care_completed_steps() -> int:
	var manager: Node = get_node_or_null("/root/CareLoopManager")
	if manager != null and manager.has_method("completed_steps"):
		return int(manager.call("completed_steps"))
	return 0


func _care_next_step() -> String:
	var manager: Node = get_node_or_null("/root/CareLoopManager")
	if manager != null and manager.has_method("next_step"):
		return str(manager.call("next_step"))
	return "FEED"


func _play_voice() -> void:
	if not ResourceLoader.exists(VOICE_PATH):
		_log("audio.missing_art", {"track": "hub_bem_vindo"})
		return
	var manager: Node = get_node_or_null("/root/AudioManager")
	if manager == null:
		return
	var stream: AudioStream = load(VOICE_PATH) as AudioStream
	if stream == null:
		return
	voice_started = bool(manager.call("play_voice", stream))
	_log("voice.start", {"track": "hub_bem_vindo"})


func _log(ev: String, data: Dictionary) -> void:
	var sink: Node = get_node_or_null("/root/Log")
	if sink != null and sink.has_method("event"):
		sink.call("event", ev, data)
