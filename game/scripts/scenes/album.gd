# story: e10s04
class_name AlbumScene
extends Control
## Sticker & star collection album (e10s04). Displays friend cards with lit star badges
## earned across the minigames. Returns to the Vila.

const VILA_PATH: String = "res://scenes/vila.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/tema_principal.ogg"
const TAP_SFX: String = "res://assets/audio/sfx/tap.ogg"

const STAR_LIT_COLOR: Color = Color(1.0, 0.95, 0.3, 1.0)
const STAR_UNLIT_COLOR: Color = Color(0.25, 0.25, 0.25, 0.45)
const CARD_LIT_COLOR: Color = Color(1.0, 1.0, 1.0, 1.0)
const CARD_UNLIT_COLOR: Color = Color(0.3, 0.3, 0.3, 0.6)
const BOUNCE_SEC: float = 0.4

var manual_step: bool = false

var _cards: Dictionary = {}
var _bouncing_card: Control = null
var _bounce_t: float = 0.0


func _ready() -> void:
	_bind_cards()
	_connect_home()
	_connect_progress()
	close_celebrate_if_needed()
	_restore_music()
	refresh_all()
	_log("scene.ready", {"scene": "album"})


func _bind_cards() -> void:
	for id: String in FriendCatalog.FRIEND_IDS:
		var card: Control = get_node_or_null("Cards/Card_" + id) as Control
		if card != null:
			_cards[id] = card
			card.connect("tapped", _on_card_tapped.bind(id))


func _connect_home() -> void:
	var home: Control = get_node_or_null("HomeButton") as Control
	if home != null:
		home.connect("tapped", _on_home_tapped)


func _connect_progress() -> void:
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress != null and progress.has_signal("progress_changed"):
		progress.progress_changed.connect(refresh_all)


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


func advance(delta: float) -> void:
	if _bouncing_card == null:
		return
	_bounce_t += maxf(delta, 0.0)
	if _bounce_t >= BOUNCE_SEC:
		_bouncing_card.scale = Vector2.ONE
		_bouncing_card = null
		_bounce_t = 0.0
		return
	var wave: float = sin((_bounce_t / BOUNCE_SEC) * PI)
	_bouncing_card.scale = Vector2.ONE * (1.0 + 0.12 * wave)


func total_stars() -> int:
	var sum: int = 0
	for id: String in FriendCatalog.FRIEND_IDS:
		sum += lit_stars(id)
	return sum


func lit_stars(id: String) -> int:
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress == null or not progress.has_method("stars_of"):
		return 0
	return clampi(int(progress.call("stars_of", id)), 0, SaveData.MAX_STARS)


func refresh_all() -> void:
	for id: String in FriendCatalog.FRIEND_IDS:
		_refresh_card(id)


func _refresh_card(id: String) -> void:
	var card: Control = _cards.get(id) as Control
	if card == null:
		return
	var count: int = lit_stars(id)
	var art: TextureRect = card.get_node_or_null("Art") as TextureRect
	if art != null:
		art.modulate = CARD_LIT_COLOR if count > 0 else CARD_UNLIT_COLOR
	for star_idx: int in range(SaveData.MAX_STARS):
		var star: TextureRect = card.get_node_or_null("Stars/Star%d" % star_idx) as TextureRect
		if star != null:
			star.modulate = STAR_LIT_COLOR if star_idx < count else STAR_UNLIT_COLOR


func _on_card_tapped(id: String) -> void:
	_play_stream("play_voice", FriendCatalog.voice_path(id))
	_play_stream("play_sfx", TAP_SFX)
	var card: Control = _cards.get(id) as Control
	if card != null:
		_bounce_card(card)
	_log("album.card_tap", {"friend": id, "stars": lit_stars(id)})


func _bounce_card(card: Control) -> void:
	if _bouncing_card != null:
		_bouncing_card.scale = Vector2.ONE
	_bouncing_card = card
	_bounce_t = 0.0


func _on_home_tapped() -> void:
	close_celebrate_if_needed()
	_request(VILA_PATH)


func _request(path: String) -> void:
	var manager: Node = get_node_or_null("/root/SceneManager")
	if manager != null:
		manager.call("request_scene", path)


func close_celebrate_if_needed() -> void:
	var manager: Node = get_node_or_null("/root/CareLoopManager")
	if manager != null and manager.has_method("close_celebrate_if_needed"):
		manager.call("close_celebrate_if_needed")


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
