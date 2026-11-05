# story: e01s05
class_name TituloScene
extends Control
## The first playable scene: a waving QuiQui on `bg_titulo`, the main theme, and
## one giant Play button. No text anywhere — a pre-reader must be able to start
## the game by tapping the only thing that glows.
##
## The Play target (`res://scenes/casa.tscn`) arrives with e02. Until then the tap
## still plays the spring and logs `scene.pending`, so the scene is honest rather
## than broken: it never pretends to navigate somewhere that does not exist.

signal play_requested

const CASA_PATH: String = "res://scenes/casa.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/tema_principal.ogg"

@onready var rig: QuiQuiRig = get_node_or_null("QuiQuiRig") as QuiQuiRig
@onready var play_button: TapButton = get_node_or_null("PlayButton") as TapButton

var play_presses: int = 0
var music_started: bool = false


func _ready() -> void:
	if play_button != null:
		play_button.tapped.connect(_on_play_tapped)
	if rig != null:
		rig.tapped.connect(_on_rig_tapped)
	_start_music()
	_log("scene.ready", {"scene": "titulo"})


func press_play() -> void:
	_on_play_tapped()


func _on_play_tapped() -> void:
	play_presses += 1
	play_requested.emit()
	if ResourceLoader.exists(CASA_PATH):
		var manager: Node = get_node_or_null("/root/SceneManager")
		if manager != null:
			manager.call("request_scene", CASA_PATH)
		return
	_log("scene.pending", {"target": "casa"})


func _on_rig_tapped() -> void:
	# A tap on QuiQui is affection, not navigation: she waves back.
	if rig != null:
		rig.set_expression("rindo")


func _start_music() -> void:
	if not ResourceLoader.exists(MUSIC_PATH):
		_log("audio.missing_art", {"track": "tema_principal"})
		return
	var manager: Node = get_node_or_null("/root/AudioManager")
	if manager == null:
		return
	var stream: AudioStream = load(MUSIC_PATH) as AudioStream
	if stream == null:
		return
	music_started = bool(manager.call("play_music", stream))
	_log("music.start", {"track": "tema_principal"})


func _log(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
