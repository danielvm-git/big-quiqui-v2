# story: e04s02
class_name BathScene
extends Control
## The BATH room, stage 1 (SOAP): eight foam patches sit on QuiQui inside her scrub
## hull, and rubbing the sponge over them soaks them. When the last patch is gone the
## stage is done.
##
## Stage 2 (RINSE) is the showerhead dragged over her body; stage 3 (DRY) is the towel.
## Both report through the same hull, so the whole room has one interaction contract.
## The last dry pass credits BATH exactly once (T-E04-02) and goes home.
##
## Geometry of the blobs is solved from `QuiQuiRig.scrub_hull_global()` on every
## layout pass and on resize, so a patch can never end up on the wallpaper on 4:3
## (T-E04-01, T-E04-07).

const CASA_PATH: String = "res://scenes/casa.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/banho.ogg"
const VOICE_PATH: String = "res://assets/audio/voice/banho_hora_do_banho.ogg"

const BLOB_COUNT: int = 8
## A stage ends on effort, not on a timer: the child scrubs/rinses/dries her body.
const RINSE_POINTS: int = 10
const DRY_POINTS: int = 8
## Beat between stages so the change is visible instead of instant.
const STAGE_GAP_SEC: float = 0.8
## Soap tints, in child-friendly order: the first is the default.
const SOAP_TINTS: Array[Color] = [
	Color(0.92, 0.97, 1.0),
	Color(1.0, 0.85, 0.92),
	Color(0.85, 1.0, 0.88),
]
const SOAP_COUNT: int = 3

const STATE_SOAP: String = "SOAP"
const STATE_SOAP_DONE: String = "SOAP_DONE"
const STATE_RINSE: String = "RINSE"
const STATE_DRY: String = "DRY"
const STATE_FINISHED: String = "FINISHED"
const LEGAL_EDGES: Dictionary = {
	STATE_SOAP: [STATE_SOAP_DONE],
	STATE_SOAP_DONE: [STATE_RINSE],
	STATE_RINSE: [STATE_DRY],
	STATE_DRY: [STATE_FINISHED],
	STATE_FINISHED: [],
}
const MAX_DWELL_SEC: Dictionary = {}

@onready var rig: QuiQuiRig = $QuiQuiRig as QuiQuiRig
@onready var sponge: TouchDraggable = $Sponge as TouchDraggable
@onready var shower: TouchDraggable = $Shower as TouchDraggable
@onready var towel: TouchDraggable = $Towel as TouchDraggable
@onready var drops: CPUParticles2D = $Gota as CPUParticles2D
@onready var foams: CPUParticles2D = $Bolhas as CPUParticles2D
@onready var bubble: WishBubble = $WishBubble as WishBubble

var fsm: Fsm = null
var soaked: int = 0
var rinsed: int = 0
var dried: int = 0
## BATH is credited once per visit, whatever order the stages finish in (T-E04-02).
var credited: bool = false
## Test seam: when true, only `advance()` steps the machine.
var manual_step: bool = false

## Normalised placement, so a resize moves the patches with her instead of leaving
## them behind: (ring fraction, angle).
var _slots: Array[Vector2] = []
var _blobs: Array[FoamBlob] = []
var _tint: int = 0
var _clock_sec: float = 0.0
var _gap_sec: float = 0.0
var _casa_requested: bool = false


func _ready() -> void:
	fsm = Fsm.new(STATE_SOAP, LEGAL_EDGES, MAX_DWELL_SEC, _clock_ms)
	_wire_sponge()
	_wire_shower()
	_wire_towel()
	_wire_soaps()
	_set_device(sponge, true)
	_set_device(shower, false)
	_set_device(towel, false)
	($HomeButton as TapButton).tapped.connect(_on_home_tapped)
	_rebuild_blobs()
	_apply_tint()
	_play_stream("play_music", MUSIC_PATH)
	_play_stream("play_voice", VOICE_PATH)
	_log("scene.ready", {"scene": "banheiro"})


func _process(delta: float) -> void:
	if not manual_step:
		advance(delta)


func _advance(delta: float) -> void:
	_clock_sec += delta
	if fsm.state == STATE_SOAP_DONE or fsm.state == STATE_RINSE:
		_gap_sec += delta
		if fsm.state == STATE_SOAP_DONE and _gap_sec >= STAGE_GAP_SEC:
			_start_rinse()
		elif fsm.state == STATE_RINSE and rinsed >= RINSE_POINTS and _gap_sec >= STAGE_GAP_SEC:
			_start_dry()


## Public step for tests: SOAP -> SOAP_DONE happens on the last soak, not on a timer.
func advance(delta: float) -> void:
	_advance(maxf(delta, 0.0))


func blob(index: int) -> FoamBlob:
	return get_node_or_null("Foam%d" % index) as FoamBlob


func blob_count() -> int:
	return _blobs.size()


func soap(index: int) -> TapButton:
	return get_node_or_null("Soap%d" % index) as TapButton


## Scrubbed points arrive only inside the hull; the blob decides the rest.
func _on_scrubbed(point: Vector2) -> void:
	for blob_node: FoamBlob in _blobs:
		if not blob_node.contains_global_point(point):
			continue
		if blob_node.soak():
			soaked += 1
			_log("bath.soak", {"soaked": soaked, "total": BLOB_COUNT})
			if soaked >= BLOB_COUNT:
				_finish_stage()
		return


func _finish_stage() -> void:
	if not fsm.transition_from(STATE_SOAP, STATE_SOAP_DONE):
		return
	_gap_sec = 0.0
	_log("bath.stage", {"stage": STATE_SOAP_DONE})


func _start_rinse() -> void:
	if not fsm.transition_from(STATE_SOAP_DONE, STATE_RINSE):
		return
	_gap_sec = 0.0
	_set_device(sponge, false)
	_set_device(shower, true)
	rig.set_expression("molhada")
	_log("bath.stage", {"stage": STATE_RINSE})


func _on_rinsed(point: Vector2) -> void:
	if fsm.state != STATE_RINSE:
		return
	if not _inside_hull(point):
		return
	rinsed += 1
	drops.global_position = point
	drops.restart()
	if rinsed >= RINSE_POINTS:
		_log("bath.rinse_done", {"points": rinsed})


func _start_dry() -> void:
	if not fsm.transition_from(STATE_RINSE, STATE_DRY):
		return
	_gap_sec = 0.0
	_set_device(shower, false)
	_set_device(towel, true)
	_log("bath.stage", {"stage": STATE_DRY})


func _on_dried(point: Vector2) -> void:
	if fsm.state != STATE_DRY:
		return
	if not _inside_hull(point):
		return
	dried += 1
	foams.global_position = point
	foams.restart()
	if dried >= DRY_POINTS:
		_finish_stage_dry()


## The last dry pass: shiny face, BATH credited once, then home (T-E04-02).
func _finish_stage_dry() -> void:
	if not fsm.transition_from(STATE_DRY, STATE_FINISHED):
		return
	_gap_sec = 0.0
	_set_device(towel, false)
	rig.set_expression("brilhando")
	_credit_bath()
	_log("bath.stage", {"stage": STATE_FINISHED})
	_request_casa()


## Credited once per visit, and only when BATH is the step the loop is actually in:
## coming back later must be free play, not a second reward.
func _credit_bath() -> void:
	if credited:
		return
	if _care_state() != CareSteps.BATH:
		return
	credited = true
	_care_loop().call("complete_step", CareSteps.BATH)


func _inside_hull(point: Vector2) -> bool:
	return BathRoomView.contains(rig.scrub_hull_global(), point)


func _set_device(device: TouchDraggable, active: bool) -> void:
	BathRoomView.set_device(device, active)


func _wire_sponge() -> void:
	sponge.mode = TouchDraggable.Mode.CONTINUOUS_SCRUB
	sponge.scrub_target = rig
	sponge.scrubbed.connect(_on_scrubbed)


func _wire_shower() -> void:
	shower.mode = TouchDraggable.Mode.CONTINUOUS_SCRUB
	shower.scrub_target = rig
	shower.scrubbed.connect(_on_rinsed)


func _wire_towel() -> void:
	towel.mode = TouchDraggable.Mode.CONTINUOUS_SCRUB
	towel.scrub_target = rig
	towel.scrubbed.connect(_on_dried)


func _wire_soaps() -> void:
	for index: int in range(SOAP_COUNT):
		var button: TapButton = soap(index)
		if button == null:
			continue
		button.tapped.connect(_on_soap_tapped.bind(index))


## A soap sets the foam colour: the "scented" affordance works without art swaps,
## and it never changes the geometry the hull contract asserts.
func _on_soap_tapped(index: int) -> void:
	_tint = index
	_apply_tint()
	_log("bath.soap", {"soap": index})


func _apply_tint() -> void:
	BathRoomView.tint(_blobs, SOAP_TINTS[_tint % SOAP_TINTS.size()])


# ── blob geometry ────────────────────────────────────────────────────────────


## Rebuilds the eight slots in normalised hull space. Called once at ready; the
## projection runs again on every resize.
func _rebuild_blobs() -> void:
	_slots = BathRoomView.slots(BLOB_COUNT)
	_blobs.clear()
	for index: int in range(BLOB_COUNT):
		var node: FoamBlob = get_node_or_null("Foam%d" % index) as FoamBlob
		if node != null:
			_blobs.append(node)
	project_blobs()


func project_blobs() -> void:
	BathRoomView.project_blobs(rig, _blobs, _slots)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and fsm != null:
		project_blobs()


## Leaving mid-stage abandons the step and aborts every device, so no gesture is left
## latched and no loop is left playing (T-E04-06).
func _on_home_tapped() -> void:
	for device: TouchDraggable in [sponge, shower, towel]:
		if device != null:
			device.abort()
	if _care_state() == CareSteps.BATH and not credited:
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
	var manager: Node = get_node_or_null("/root/AudioManager")
	if manager == null:
		return false
	manager.call(method, stream)
	return true


func _clock_ms() -> int:
	return int(_clock_sec * 1000.0)


func _log(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
