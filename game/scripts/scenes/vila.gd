# story: e08s01
class_name VilaScene
extends Control
## Outdoor hub: six building taps, the same wish bubble semantics as the Casa,
## and honest `scene.pending` for doors whose scenes are not shipped yet.

signal poi_requested(poi: String)

const CASA_PATH: String = "res://scenes/casa.tscn"
## Set when e08s03 generates the wheel scene; until then the POI logs pending.
const RODA_PATH: String = "res://scenes/roda.tscn"

const POI_SCENE_CASA: String = "CASA"
const POI_SCENE_RODA: String = "RODA"
const POI_RECYCLING: String = "RECYCLING"
const POI_MERCADO: String = "MERCADO"
const POI_CASINHA: String = "CASINHA"
const POI_FESTA: String = "FESTA"

## Six POI ids -> scene path or "" when still under construction.
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

@onready var rig: QuiQuiRig = $QuiQuiRig as QuiQuiRig
@onready var bubble: WishBubble = $WishBubble as WishBubble
@onready var hud: CoinTicketHud = $CoinTicketHud as CoinTicketHud

var manual_step: bool = false
var voice_started: bool = false

var poi_taps: int = 0
## Test observable: last slug passed to `scene.pending` (empty if none this session).
var last_pending_slug: String = ""
var _idle_sec: float = 0.0
var _wish_shown_for_idle: bool = false


func _ready() -> void:
	close_celebrate_if_needed()
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


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


## Idle timer for wish + escalation (FIX-01), same constants as CasaScene.
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
	voice_started = bool(audio.call(method, stream))
	return voice_started


func _log(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
