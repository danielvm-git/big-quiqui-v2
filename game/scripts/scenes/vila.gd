# story: e08s01
# story: e08s02
class_name VilaScene
extends Control
## Outdoor hub: six building taps, the same wish bubble semantics as the Casa,
## honest `scene.pending` for POIs without scenes, and the recycling drag (e08s02).

signal poi_requested(poi: String)

const CASA_PATH: String = "res://scenes/casa.tscn"
const RODA_PATH: String = "res://scenes/roda.tscn"
const SPARKLE_SFX: String = "res://assets/audio/sfx/confete.ogg"

const POI_SCENE_CASA: String = "CASA"
const POI_SCENE_RODA: String = "RODA"
const POI_RECYCLING: String = "RECYCLING"
const POI_MERCADO: String = "MERCADO"
const POI_CASINHA: String = "CASINHA"
const POI_FESTA: String = "FESTA"

const POI_SCENES: Dictionary = {
	POI_SCENE_CASA: CASA_PATH,
	POI_SCENE_RODA: RODA_PATH,
	POI_RECYCLING: "",
	POI_MERCADO: "",
	POI_CASINHA: "",
	POI_FESTA: "",
}

const WISH_ICONS: Dictionary = {
	CareSteps.FEED: "res://assets/art/items/cenoura.png",
	CareSteps.BATH: "res://assets/art/items/sabonete.png",
	CareSteps.DRESS: "res://assets/art/items/tiara_flores.png",
	CareSteps.PLAY: "res://assets/art/items/bola.png",
	CareSteps.SLEEP: "res://assets/art/efeitos/zzz.png",
}

const VOICE_PATH: String = "res://assets/audio/voice/vila_bem_vindo.ogg"
const MUSIC_PATH: String = "res://assets/audio/music/tema_principal.ogg"

const IDLE_WISH_SEC: float = 8.0
const ESCALATION_SEC: float = 6.0

const RECYCLE_READY: String = "READY"
const RECYCLE_PAY: String = "PAY"
const RECYCLE_LEGAL: Dictionary = {RECYCLE_READY: [RECYCLE_PAY], RECYCLE_PAY: [RECYCLE_READY]}

var rig: QuiQuiRig = null
var bubble: WishBubble = null
var hud: CoinTicketHud = null
var recycle_bag: TouchDraggable = null
var recycle_bin: Control = null
var hint_layer: Control = null
var hint_manager: Node = null
var drag_hint: Node = null
var sparkle: CPUParticles2D = null

var manual_step: bool = false
var voice_started: bool = false

var poi_taps: int = 0
var last_pending_slug: String = ""
var _idle_sec: float = 0.0
var _wish_shown_for_idle: bool = false

var recycle_fsm: Fsm = null
var recycle_earns: int = 0
var _recycle_hint_done: bool = false
var _recycle_awarded: bool = false


func _ready() -> void:
	rig = get_node_or_null("QuiQuiRig") as QuiQuiRig
	bubble = get_node_or_null("WishBubble") as WishBubble
	hud = get_node_or_null("CoinTicketHud") as CoinTicketHud
	recycle_bag = get_node_or_null("RecycleBag") as TouchDraggable
	recycle_bin = get_node_or_null("RecycleBin") as Control
	hint_layer = get_node_or_null("HintLayer") as Control
	hint_manager = get_node_or_null("HintManager")
	drag_hint = get_node_or_null("HintLayer/DragHint")
	sparkle = get_node_or_null("Sparkle") as CPUParticles2D
	close_celebrate_if_needed()
	recycle_fsm = Fsm.new(RECYCLE_READY, RECYCLE_LEGAL, {})
	_setup_recycle()
	_setup_hints()
	var home: TapButton = get_node_or_null("HomeButton") as TapButton
	if home != null:
		home.tapped.connect(_on_home_tapped)
	for key: String in POI_SCENES:
		var door: TapButton = poi(key)
		if door != null:
			door.tapped.connect(_on_poi_tapped.bind(key))
	if rig != null:
		rig.tapped.connect(_on_rig_tapped)
	_play_stream("play_voice", VOICE_PATH)
	_restore_music()
	_log("scene.ready", {"scene": "vila"})


func _setup_recycle() -> void:
	if recycle_bag != null:
		recycle_bag.mode = TouchDraggable.Mode.CONSUME_ON_DROP
		recycle_bag.drop_target = recycle_bin
		recycle_bag.drop_margin = 8.0
		recycle_bag.consumed.connect(_on_recycle_consumed)
		recycle_bag.drag_started.connect(_on_recycle_drag_started)
	if sparkle != null:
		sparkle.emitting = false


func _setup_hints() -> void:
	if hint_manager != null and drag_hint != null:
		hint_manager.call("enqueue", drag_hint)


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)
	if hint_manager != null and hint_manager.has_method("advance"):
		hint_manager.call("advance", delta)


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
			rig.set_expression("carente")
		if bubble != null:
			bubble.show_wish(WISH_ICONS[step])
		return
	if bubble != null and bubble.is_showing():
		var level: int = mini(WishBubble.MAX_URGENCY, floori((_idle_sec - IDLE_WISH_SEC) / ESCALATION_SEC))
		bubble.set_urgency(level)


func close_celebrate_if_needed() -> void:
	var manager: Node = get_node_or_null("/root/CareLoopManager")
	if manager != null and manager.has_method("close_celebrate_if_needed"):
		manager.call("close_celebrate_if_needed")


func poi(id: String) -> TapButton:
	return get_node_or_null("Poi" + id) as TapButton


func _maybe_start_recycle_hint() -> void:
	if _recycle_hint_done or hint_manager == null or drag_hint == null:
		return
	if recycle_bag == null or recycle_bin == null:
		return
	if not bool(hint_manager.call("try_show_next")):
		return
	var from_g: Vector2 = recycle_bag.get_global_rect().get_center()
	var to_g: Vector2 = recycle_bin.get_global_rect().get_center()
	var pulse_target: Control = recycle_bin.get_node_or_null("Visual") as Control
	drag_hint.call("play", from_g, to_g, pulse_target)


func _on_recycle_drag_started() -> void:
	if hint_manager != null:
		hint_manager.call("stop_current")
		hint_manager.call("begin_cooldown", 1.5)


func _on_recycle_consumed() -> void:
	if _recycle_awarded or recycle_fsm == null or recycle_fsm.state != RECYCLE_READY:
		return
	if not recycle_fsm.transition_to(RECYCLE_PAY):
		return
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress != null:
		progress.call("add_coins", 1)
	recycle_earns += 1
	_recycle_awarded = true
	_log("vila.recycle_earn", {"coins": 1})
	if hud != null and recycle_bin != null:
		hud.fly_coin(recycle_bin.get_global_rect().get_center())
	_play_sparkle()
	_recycle_finish_payment()


func _recycle_finish_payment() -> void:
	_recycle_hint_done = true
	if recycle_bag != null:
		recycle_bag.visible = false
		recycle_bag.enabled = false
	if recycle_fsm != null:
		recycle_fsm.transition_to(RECYCLE_READY)


func _play_sparkle() -> void:
	if sparkle == null or recycle_bin == null:
		return
	sparkle.global_position = recycle_bin.get_global_rect().get_center()
	sparkle.restart()
	_play_stream("play_sfx", SPARKLE_SFX)


func _on_poi_tapped(poi_id: String) -> void:
	poi_taps += 1
	poi_requested.emit(poi_id)
	var path: String = str(POI_SCENES.get(poi_id, ""))
	if not path.is_empty() and ResourceLoader.exists(path):
		_reset_idle()
		var manager: Node = get_node_or_null("/root/SceneManager")
		if manager != null:
			manager.call("request_scene", path)
		return
	var pending_slug: String = path.get_file().get_basename() if not path.is_empty() else poi_id.to_lower()
	last_pending_slug = pending_slug
	_reset_idle()
	_log("scene.pending", {"target": pending_slug})


func _on_rig_tapped() -> void:
	_reset_idle()
	if rig != null:
		rig.set_expression("rindo")


func _on_home_tapped() -> void:
	_reset_idle()
	var manager: Node = get_node_or_null("/root/SceneManager")
	if manager != null:
		manager.call("request_scene", CASA_PATH)


func _reset_idle() -> void:
	_idle_sec = 0.0
	_wish_shown_for_idle = false
	if bubble != null and bubble.is_showing():
		bubble.hide_wish()


func _care_next_step() -> String:
	var manager: Node = get_node_or_null("/root/CareLoopManager")
	if manager != null and manager.has_method("next_step"):
		return str(manager.call("next_step"))
	return CareSteps.FEED


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


func _play_stream(method: String, path: String) -> bool:
	var stream: AudioStream = load(path) as AudioStream if ResourceLoader.exists(path) else null
	if stream == null:
		_log("audio.missing_art", {"track": path.get_file().get_basename()})
		return false
	var audio: Node = get_node_or_null("/root/AudioManager")
	if audio == null:
		return false
	return bool(audio.call(method, stream))


func _log(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and visible:
		call_deferred("_maybe_start_recycle_hint")
