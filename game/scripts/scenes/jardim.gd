# story: e06s02
class_name GardenScene
extends Control
## The PLAY room. There is no task here: three toys, and the step completes when the
## child has played with three *distinct* ones (T-E06-05). The tickle zone is
## repeatable on purpose — it is play, not a chore — and it never advances the step.

const CASA_PATH: String = "res://scenes/casa.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/jardim.ogg"
const VOICE_PATH: String = "res://assets/audio/voice/play_hora_de_brincar.ogg"
const TICKLE_SFX_PATH: String = "res://assets/audio/sfx/cocega_risada.ogg"
const CONFETTI_SFX_PATH: String = "res://assets/audio/sfx/confete.ogg"

const INTERACTIONS_TO_FINISH: int = 3
## The prop catalogue: kind and interaction id are wired at `_ready`, because a
## property set on a scripted node *before* it enters the tree is not serialised by
## `PackedScene.pack`. The scene file carries art and layout; the behaviour lives here.
const PROPS: Array[Dictionary] = [
	{"kind": 0, "id": "ball"},
	{"kind": 1, "id": "pinwheel"},
	{"kind": 2, "id": "plush"},
]
const IDLE_WISH_SEC: float = 8.0
const PROP_COUNT: int = 3

const STATE_PLAYING: String = "PLAYING"
const STATE_FINISHED: String = "FINISHED"
const LEGAL_EDGES: Dictionary = {STATE_PLAYING: [STATE_FINISHED], STATE_FINISHED: []}

@onready var rig: QuiQuiRig = $QuiQuiRig as QuiQuiRig
@onready var bubble: WishBubble = $WishBubble as WishBubble
@onready var tickle: TapButton = $TickleZone as TapButton
@onready var confetti: CPUParticles2D = $Confetti as CPUParticles2D

var fsm: Fsm = null
var manual_step: bool = false
## Distinct interaction ids already played with.
var played: Array[String] = []
var credited: bool = false
var tickles: int = 0

var _clock_sec: float = 0.0
var _idle_sec: float = 0.0
var _casa_requested: bool = false


func _ready() -> void:
	fsm = Fsm.new(STATE_PLAYING, LEGAL_EDGES, {}, _clock_ms)
	for index: int in range(PROP_COUNT):
		var prop: GardenProp = self.prop(index)
		if prop == null:
			continue
		if index < PROPS.size():
			prop.kind = int(PROPS[index]["kind"]) as GardenProp.Kind
			prop.interaction = str(PROPS[index]["id"])
		prop.interacted.connect(_on_interacted)
	if tickle != null:
		tickle.tapped.connect(_on_tickled)
	($HomeButton as TapButton).tapped.connect(_on_home_tapped)
	_play_stream("play_music", MUSIC_PATH)
	_play_stream("play_voice", VOICE_PATH)
	_log("scene.ready", {"scene": "jardim"})


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


func advance(delta: float) -> void:
	var step: float = maxf(delta, 0.0)
	_clock_sec += step
	for index: int in range(PROP_COUNT):
		var prop: GardenProp = self.prop(index)
		if prop != null:
			prop.advance(step)
	_advance_idle(step)


func prop(index: int) -> GardenProp:
	return get_node_or_null("Prop%d" % index) as GardenProp


## Three *distinct* toys complete the step. Replaying one is still fun and still
## moves the toy; it just does not count twice (T-E06-05).
func _on_interacted(interaction: String) -> void:
	rig.set_expression("rindo")
	_idle_sec = 0.0
	if played.has(interaction) or fsm.state != STATE_PLAYING:
		return
	played.append(interaction)
	_log("garden.play", {"interaction": interaction, "played": played.size()})
	if played.size() >= INTERACTIONS_TO_FINISH:
		_finish()


func _on_tickled() -> void:
	tickles += 1
	rig.set_expression("rindo")
	_idle_sec = 0.0
	_play_stream("play_sfx", TICKLE_SFX_PATH)
	_log("garden.tickle", {"tickles": tickles})


func _finish() -> void:
	if not fsm.transition_from(STATE_PLAYING, STATE_FINISHED):
		return
	rig.set_expression("pulando")
	confetti.global_position = rig.get_visual_global_rect().get_center()
	confetti.restart()
	_play_stream("play_sfx", CONFETTI_SFX_PATH)
	_credit_play()
	_log("garden.finished", {"interactions": played.size()})
	# One way out, the same as the bath's towel: the step is earned, the child goes home.
	_request_casa()


func _credit_play() -> void:
	if credited:
		return
	if _care_state() != CareSteps.PLAY:
		return
	credited = true
	_care_loop().call("complete_step", CareSteps.PLAY)


func _advance_idle(step: float) -> void:
	if fsm.state != STATE_PLAYING or _is_busy():
		_idle_sec = 0.0
		return
	_idle_sec += step
	if _idle_sec < IDLE_WISH_SEC:
		return
	_idle_sec = 0.0
	if not bubble.is_showing():
		rig.set_expression("carente")
		bubble.show_wish("res://assets/art/items/bola.png")


func _is_busy() -> bool:
	for index: int in range(PROP_COUNT):
		var prop: GardenProp = self.prop(index)
		if prop != null and not prop.is_idle():
			return true
	return false


## Leaving mid-play abandons an uncredited step and puts every toy back at rest, so
## the next scene opens calm (T-E06-06).
func _on_home_tapped() -> void:
	for index: int in range(PROP_COUNT):
		var prop: GardenProp = self.prop(index)
		if prop != null:
			prop.reset_prop()
	if _care_state() == CareSteps.PLAY and not credited:
		_care_loop().call("abandon_step")
	_request_casa()


func _request_casa() -> void:
	if _casa_requested:
		return
	_casa_requested = true
	var manager: Node = get_node_or_null("/root/SceneManager")
	if manager != null:
		manager.call("request_scene", CASA_PATH)


func _care_state() -> String:
	var manager: Node = _care_loop()
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
