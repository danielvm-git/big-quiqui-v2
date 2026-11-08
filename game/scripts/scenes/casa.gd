# story: e02s03
# story: e08s01
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

const VILA: String = "VILA"

## Door ids come from the shared vocabulary (`CareSteps`); only the paths are
## local. VILA is a destination, not a care step: it never carries the
## "waiting" dim.
const DOOR_SCENES: Dictionary = {
	CareSteps.FEED: "res://scenes/cozinha.tscn",
	CareSteps.BATH: "res://scenes/banheiro.tscn",
	CareSteps.DRESS: "res://scenes/closet.tscn",
	CareSteps.PLAY: "res://scenes/jardim.tscn",
	CareSteps.SLEEP: "res://scenes/quarto_sono.tscn",
	VILA: "res://scenes/vila.tscn",
}

## What QuiQui asks for in each step (DESIGN.md: the wish bubble carries the
## prompt, not words).
const WISH_ICONS: Dictionary = {
	CareSteps.FEED: "res://assets/art/items/carrot.png",
	CareSteps.BATH: "res://assets/art/items/soap.png",
	CareSteps.DRESS: "res://assets/art/items/flower_tiara.png",
	CareSteps.PLAY: "res://assets/art/items/ball.png",
	CareSteps.SLEEP: "res://assets/art/effects/zzz.png",
}

const VOICE_KEY: String = "vo.home.welcome"
const MUSIC_PATH: String = "res://assets/audio/music/main_theme.ogg"
const IDLE_WISH_SEC: float = 8.0
const ESCALATION_SEC: float = 6.0
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
	close_celebrate_if_needed()
	for step: String in DOOR_SCENES:
		var door: TapButton = door(step)
		if door != null:
			door.tapped.connect(_on_door_tapped.bind(step))
	if rig != null:
		rig.tapped.connect(_on_rig_tapped)
	_connect_care_loop()
	_restore_music()
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
	if _idle_sec < IDLE_WISH_SEC:
		return
	var step: String = _care_next_step()
	if step.is_empty() or not WISH_ICONS.has(step):
		return
	if not _wish_shown_for_idle:
		_wish_shown_for_idle = true
		if rig != null:
			rig.set_expression("needy")
		if bubble != null:
			bubble.show_wish(WISH_ICONS[step])
		return
	if bubble != null and bubble.is_showing():
		var level: int = mini(
			WishBubble.MAX_URGENCY,
			floori((_idle_sec - IDLE_WISH_SEC) / ESCALATION_SEC),
		)
		bubble.set_urgency(level)


## The hub is a whitelisted target of `SceneManager`'s detour guard, so it must close a
## CELEBRATE cycle itself: arriving from anywhere (a parked request, the album, a test) while
## the loop is mid-celebration otherwise shows six doors that all refuse (T-E07-05).
func close_celebrate_if_needed() -> void:
	var manager: Node = get_node_or_null("/root/CareLoopManager")
	if manager != null and manager.has_method("close_celebrate_if_needed"):
		manager.call("close_celebrate_if_needed")


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
		rig.set_expression("laughing")


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
	# Only the five care steps express "not your turn yet". Dimming VILA would
	# tell a child that a tappable door is disabled.
	for step: String in CareSteps.ORDER:
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
	return CareSteps.FEED


## A room's theme stops at the hub; arriving from the title keeps the theme running.
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


func _play_voice() -> void:
	voice_started = AudioManager.play_voice_key(VOICE_KEY)
	if voice_started:
		_log("voice.start", {"track": "home_welcome"})


func _log(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
