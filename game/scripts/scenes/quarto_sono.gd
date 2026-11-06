# story: e07s01
class_name SleepScene
extends Control
## The bedroom at night (SLEEP). Two interactions, in any order: dim the room with the
## lamp, tuck her in with the plush. When both are done the step is credited once and
## the celebration is requested.
##
## The night tint is applied to the **background only** — a dark character is a broken
## character, and the face is the only feedback a pre-reader has (T-E07-01).

const CELEBRACAO_PATH: String = "res://scenes/celebracao.tscn"
const CASA_PATH: String = "res://scenes/casa.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/tema_principal.ogg"
const VOICE_PATH: String = "res://assets/audio/voice/celebrate_parabens.ogg"

const NIGHT_TINT: Color = Color(0.42, 0.45, 0.72)
const LIT_TINT: Color = Color.WHITE

const STATE_SLEEPING: String = "SLEEPING"
const STATE_FINISHED: String = "FINISHED"
const LEGAL_EDGES: Dictionary = {STATE_SLEEPING: [STATE_FINISHED], STATE_FINISHED: []}

@onready var rig: QuiQuiRig = $QuiQuiRig as QuiQuiRig
@onready var background: TextureRect = $Background as TextureRect
@onready var plush: TouchDraggable = $Plush as TouchDraggable
@onready var lamp: TapButton = $LampButton as TapButton
@onready var zzz: CPUParticles2D = $Zzz as CPUParticles2D

var fsm: Fsm = null
var lamp_on: bool = true
var tucked: bool = false
var credited: bool = false
var manual_step: bool = false

var _clock_sec: float = 0.0
var _step_requested: bool = false


func _ready() -> void:
	fsm = Fsm.new(STATE_SLEEPING, LEGAL_EDGES, {}, _clock_ms)
	lamp.tapped.connect(toggle_lamp)
	($HomeButton as TapButton).tapped.connect(_on_home_tapped)
	plush.mode = TouchDraggable.Mode.SNAP_TO_SLOT
	plush.snap_target = rig
	plush.snap_margin = 40.0
	plush.payload_slot = "tuck"
	plush.payload_id = "plush"
	plush.snapped.connect(_on_snapped)
	_apply_lamp()
	_play_stream("play_music", MUSIC_PATH)
	_log("scene.ready", {"scene": "quarto_sono"})


func _process(delta: float) -> void:
	if not manual_step:
		advance(delta)


func advance(delta: float) -> void:
	_clock_sec += maxf(delta, 0.0)


## One tap: lit → dim. The tint lands on the background, never on the character.
## Inert once she is asleep: lighting the room back up behind the party transition is a
## glitch a child reads as a broken bedroom.
func toggle_lamp() -> bool:
	if fsm.state != STATE_SLEEPING:
		return false
	lamp_on = not lamp_on
	_apply_lamp()
	_log("sleep.lamp", {"on": lamp_on})
	_try_finish()
	return true


## The plush lands on her: she lies down, the zzz burst starts. Idempotent — a second
## tuck does not restart the particles (a restart reads as a glitch to a child).
func _on_snapped(_slot: String, _id: String) -> void:
	if tucked:
		return
	tucked = true
	rig.set_expression("sono")
	zzz.global_position = rig.get_visual_global_rect().get_center()
	zzz.restart()
	_log("sleep.tuck", {"tucked": true})
	_try_finish()


func _try_finish() -> void:
	if not lamp_on and tucked and fsm.state == STATE_SLEEPING:
		_finish()


func _finish() -> void:
	if not fsm.transition_from(STATE_SLEEPING, STATE_FINISHED):
		return
	_credit_sleep()
	_log("sleep.finished", {"lamp_on": lamp_on})
	# Only a credited SLEEP opens the party. Coming back after the step is free play, and
	# a celebration with no reward behind it is worse than going home (review B).
	_request(CELEBRACAO_PATH if credited else CASA_PATH)


func _credit_sleep() -> void:
	if credited:
		return
	if _care_state() != CareSteps.SLEEP:
		return
	credited = true
	_care_loop().call("complete_step", CareSteps.SLEEP)


func _apply_lamp() -> void:
	if background != null:
		background.modulate = LIT_TINT if lamp_on else NIGHT_TINT


func _on_home_tapped() -> void:
	zzz.emitting = false
	if _care_state() == CareSteps.SLEEP and not credited:
		_care_loop().call("abandon_step")
	_request(CASA_PATH)


func _request(path: String) -> void:
	if _step_requested:
		return
	_step_requested = true
	var manager: Node = get_node_or_null("/root/SceneManager")
	if manager != null:
		manager.call("request_scene", path)


func _care_state() -> String:
	var manager: Node = get_node_or_null("/root/CareLoopManager")
	return "" if manager == null else str(manager.call("state_id"))


func _care_loop() -> Node:
	return get_node_or_null("/root/CareLoopManager")


func _play_stream(method: String, path: String) -> bool:
	var stream: AudioStream = load(path) as AudioStream if ResourceLoader.exists(path) else null
	if stream == null:
		_log("audio.missing_art", {"track": path.get_file().get_basename()})
		return false
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio == null:
		return false
	audio.call(method, stream)
	return true


func _clock_ms() -> int:
	return int(_clock_sec * 1000.0)


func _log(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
