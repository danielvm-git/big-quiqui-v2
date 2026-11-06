# story: e04s02
class_name BathScene
extends Control
## The BATH room, stage 1 (SOAP): eight foam patches sit on QuiQui inside her scrub
## hull, and rubbing the sponge over them soaks them. When the last patch is gone the
## stage is done.
##
## Stages 2 and 3 (RINSE, DRY) and the BATH credit arrive in e04s03; the machine here
## already declares them so the transition is never illegal, and this story stops at
## `SOAP_DONE`.
##
## Geometry of the blobs is solved from `QuiQuiRig.scrub_hull_global()` on every
## layout pass and on resize, so a patch can never end up on the wallpaper on 4:3
## (T-E04-01, T-E04-07).

const CASA_PATH: String = "res://scenes/casa.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/banho.ogg"
const VOICE_PATH: String = "res://assets/audio/voice/banho_hora_do_banho.ogg"

const BLOB_COUNT: int = 8
## Blob diameter as a share of the painted character height.
const BLOB_RATIO: float = 0.11
## Rings the blobs sit on, as a fraction of the hull radius. Two rings read as a
## pattern on her body instead of a grid on her face.
const RING_FRACTIONS: Array[float] = [0.55, 0.85]
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
@onready var bubble: WishBubble = $WishBubble as WishBubble

var fsm: Fsm = null
var soaked: int = 0
## Test seam: when true, only `advance()` steps the machine.
var manual_step: bool = false

## Normalised placement, so a resize moves the patches with her instead of leaving
## them behind: (ring fraction, angle).
var _slots: Array[Vector2] = []
var _blobs: Array[FoamBlob] = []
var _tint: int = 0


func _ready() -> void:
	fsm = Fsm.new(STATE_SOAP, LEGAL_EDGES, MAX_DWELL_SEC)
	_wire_sponge()
	_wire_soaps()
	($HomeButton as TapButton).tapped.connect(_on_home_tapped)
	_rebuild_blobs()
	_apply_tint()
	_play_stream("play_music", MUSIC_PATH)
	_play_stream("play_voice", VOICE_PATH)
	_log("scene.ready", {"scene": "banheiro"})


func _process(delta: float) -> void:
	if not manual_step:
		advance(delta)


func _advance(_delta: float) -> void:
	pass


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
	_log("bath.stage", {"stage": STATE_SOAP_DONE})


func _wire_sponge() -> void:
	sponge.mode = TouchDraggable.Mode.CONTINUOUS_SCRUB
	sponge.scrub_target = rig
	sponge.scrubbed.connect(_on_scrubbed)


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
	var colour: Color = SOAP_TINTS[_tint % SOAP_TINTS.size()]
	for blob_node: FoamBlob in _blobs:
		blob_node.self_modulate = colour


# ── blob geometry ────────────────────────────────────────────────────────────


## Rebuilds the eight slots in normalised hull space. Called once at ready; the
## projection runs again on every resize.
func _rebuild_blobs() -> void:
	_slots.clear()
	for index: int in range(BLOB_COUNT):
		var ring: float = RING_FRACTIONS[index % RING_FRACTIONS.size()]
		var angle: float = TAU * float(index) / float(BLOB_COUNT)
		_slots.append(Vector2(ring, angle))
	_blobs.clear()
	for index: int in range(BLOB_COUNT):
		var node: FoamBlob = get_node_or_null("Foam%d" % index) as FoamBlob
		if node == null:
			continue
		_blobs.append(node)
		(node.get_node("Art") as TextureRect).modulate = Color.WHITE
	project_blobs()


func project_blobs() -> void:
	var hull: PackedVector2Array = rig.scrub_hull_global()
	if hull.size() < 3 or _blobs.is_empty():
		return
	var box: Rect2 = Rect2(hull[0], Vector2.ZERO)
	for point: Vector2 in hull:
		box = box.expand(point)
	var centre: Vector2 = box.get_center()
	var radii: Vector2 = box.size * 0.5
	var diameter: float = maxf(rig.get_visual_global_rect().size.y * BLOB_RATIO, 24.0)
	for index: int in range(_blobs.size()):
		var slot: Vector2 = _slots[index]
		var point: Vector2 = centre + Vector2(cos(slot.y) * radii.x * slot.x, sin(slot.y) * radii.y * slot.x)
		var blob_node: FoamBlob = _blobs[index]
		blob_node.size = Vector2(diameter, diameter)
		blob_node.global_position = point - blob_node.size * 0.5


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and fsm != null:
		project_blobs()


func _on_home_tapped() -> void:
	if _care_state() == CareSteps.BATH:
		_care_loop().call("abandon_step")
	_request_casa()


func _request_casa() -> void:
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


func _log(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
