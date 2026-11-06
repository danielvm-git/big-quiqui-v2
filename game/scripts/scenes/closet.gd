# story: e05s02
class_name ClosetScene
extends Control
## The DRESS room: a wardrobe of four outfits and six accessories, dragged onto QuiQui
## with the `SNAP_TO_SLOT` gesture. A drop on her body equips the item, saves the look
## and flies the hanger home; a drop anywhere else changes nothing.
##
## The room opens already dressed from the save, because the look is the child's, not
## the scene's (`ProgressManager.dress`).

const CASA_PATH: String = "res://scenes/casa.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/tema_principal.ogg"
const VOICE_PATH: String = "res://assets/audio/voice/dress_vamos_se_arrumar.ogg"
const POP_SFX_PATH: String = "res://assets/audio/sfx/pop_roupa.ogg"

const SNAP_MARGIN: float = 40.0
const IDLE_WISH_SEC: float = 8.0

## The catalogue: four outfits and six accessories, all shipped art.
const OUTFITS: Array[String] = ["vestido_florido", "vestido_vermelho", "macacao_verde", "pijama"]
const ACCESSORIES: Array[Dictionary] = [
	{"slot": "head", "id": "tiara_flores"},
	{"slot": "head", "id": "coroa"},
	{"slot": "head", "id": "chapeu_amarelo"},
	{"slot": "neck", "id": "cachecol_azul"},
	{"slot": "neck", "id": "laco_roxo"},
	{"slot": "eyes", "id": "oculos_coracao"},
]

const STATE_DRESSING: String = "DRESSING"
const STATE_FINISHED: String = "FINISHED"
const LEGAL_EDGES: Dictionary = {STATE_DRESSING: [STATE_FINISHED], STATE_FINISHED: []}

@onready var rig: QuiQuiRig = $QuiQuiRig as QuiQuiRig
@onready var bubble: WishBubble = $WishBubble as WishBubble

var fsm: Fsm = null
var manual_step: bool = false
## DRESS is credited once per visit (T-E05-02).
var credited: bool = false
var equips: int = 0

var _clock_sec: float = 0.0
var _idle_sec: float = 0.0
var _casa_requested: bool = false


func _ready() -> void:
	fsm = Fsm.new(STATE_DRESSING, LEGAL_EDGES, {}, _clock_ms)
	_wire_items()
	_apply_saved_look()
	($HomeButton as TapButton).tapped.connect(_on_home_tapped)
	_play_stream("play_music", MUSIC_PATH)
	_play_stream("play_voice", VOICE_PATH)
	_log("scene.ready", {"scene": "closet"})


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


func advance(delta: float) -> void:
	var step: float = maxf(delta, 0.0)
	_clock_sec += step
	if fsm.state != STATE_DRESSING or _is_holding():
		_idle_sec = 0.0
		return
	_idle_sec += step
	if _idle_sec >= IDLE_WISH_SEC:
		_idle_sec = 0.0
		if not bubble.is_showing():
			rig.set_expression("carente")
			bubble.show_wish("res://assets/art/items/tiara_flores.png")


func item(name: String) -> TouchDraggable:
	return get_node_or_null(name) as TouchDraggable


func outfit_item(index: int) -> TouchDraggable:
	return item("Outfit%d" % index)


func accessory_item(index: int) -> TouchDraggable:
	return item("Accessory%d" % index)


## A drop on her body equips. The payload is what the hanger carries, so the same
## handler serves outfits and accessories.
## Free play continues after DRESS is credited: the child may keep changing her
## clothes, and the step stays credited (the loop's machine has moved on).
func _on_snapped(slot: String, id: String) -> void:
	var applied: bool = false
	if slot == SaveData.SLOT_BODY:
		applied = rig.set_outfit(id)
	else:
		applied = rig.set_accessory(slot, id)
	if not applied:
		_play_stream("play_sfx", "res://assets/audio/sfx/erro_suave.ogg")
		return
	equips += 1
	rig.set_expression("rindo")
	_manager().call("equip", slot, id)
	_burst()
	_play_stream("play_sfx", POP_SFX_PATH)
	_credit_dress()
	_log("dress.equip", {"slot": slot, "item": id})
	_refresh_idle()


func _credit_dress() -> void:
	if credited:
		return
	if _care_state() != CareSteps.DRESS:
		return
	credited = true
	_care_loop().call("complete_step", CareSteps.DRESS)
	fsm.transition_to(STATE_FINISHED)


func _apply_saved_look() -> void:
	var manager: Node = _manager()
	if manager == null:
		return
	manager.call("dress", rig)


func _wire_items() -> void:
	for index: int in range(OUTFITS.size()):
		_wire(outfit_item(index), SaveData.SLOT_BODY, OUTFITS[index])
	for index: int in range(ACCESSORIES.size()):
		var entry: Dictionary = ACCESSORIES[index]
		_wire(accessory_item(index), str(entry["slot"]), str(entry["id"]))


func _wire(control: TouchDraggable, slot: String, id: String) -> void:
	if control == null:
		return
	control.mode = TouchDraggable.Mode.SNAP_TO_SLOT
	control.snap_target = rig
	control.snap_margin = SNAP_MARGIN
	control.payload_slot = slot
	control.payload_id = id
	control.snapped.connect(_on_snapped)
	control.drag_started.connect(_refresh_idle)


func _burst() -> void:
	var sparkles: CPUParticles2D = get_node_or_null("Sparkles") as CPUParticles2D
	if sparkles == null:
		return
	sparkles.global_position = rig.get_visual_global_rect().get_center()
	sparkles.restart()


func _is_holding() -> bool:
	for index: int in range(OUTFITS.size()):
		if outfit_item(index) != null and outfit_item(index).state_id() == TouchDraggable.STATE_DRAGGING:
			return true
	return false


func _refresh_idle() -> void:
	_idle_sec = 0.0
	if bubble.is_showing():
		bubble.hide_wish()
	if rig.expression_id == "carente":
		rig.set_expression(QuiQuiRig.NEUTRAL_EXPRESSION)


func _on_home_tapped() -> void:
	if _care_state() == CareSteps.DRESS and not credited:
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


func _manager() -> Node:
	return get_node_or_null("/root/ProgressManager")


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
