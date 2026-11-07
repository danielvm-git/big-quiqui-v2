# story: e09s01
class_name StoreScene
extends Control
## The furniture store (e09s01): tap a piece, pay once from the HUD, keep it forever.
## Prices are tuning data (`EconomyData.furniture_prices`, FIX-05) and every piece is an
## id from `FurnitureCatalog`, so no tap can ever build a `res://` path out of text.

const CASA_PATH: String = "res://scenes/casa.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/tema_principal.ogg"
const VOICE_PATH: String = "res://assets/audio/voice/mercado_escolhe.ogg"
const BUY_SFX: String = "res://assets/audio/sfx/success.ogg"
const DENY_SFX: String = "res://assets/audio/sfx/erro_suave.ogg"

## One shelf per Lote-6 piece, in catalog order.
const SHELF_IDS: Array[String] = FurnitureCatalog.FURNITURE_IDS

const STATE_IDLE: String = "IDLE"
const STATE_PAYING: String = "PAYING"
const STATE_SOLD: String = "SOLD"
const LEGAL_EDGES: Dictionary = {
	STATE_IDLE: [STATE_PAYING],
	STATE_PAYING: [STATE_SOLD],
	STATE_SOLD: [STATE_IDLE],
}
const MAX_DWELL: Dictionary = {STATE_PAYING: 1.5, STATE_SOLD: 2.5}
const PAY_SEC: float = 0.25
const SOLD_HOLD_SEC: float = 0.6

@export var economy: EconomyData = null

var rig: QuiQuiRig = null
var hud: CoinTicketHud = null
var fsm: Fsm = null

var manual_step: bool = false
## Observable refusals: the child hears a soft no and nothing is charged.
var denials: int = 0

var _fsm_clock_sec: float = 0.0
var _state_age: float = 0.0


func _ready() -> void:
	rig = get_node_or_null("QuiQuiRig") as QuiQuiRig
	hud = get_node_or_null("CoinTicketHud") as CoinTicketHud
	close_celebrate_if_needed()
	if economy == null:
		economy = EconomyData.new()
	fsm = Fsm.new(STATE_IDLE, LEGAL_EDGES, MAX_DWELL, Callable(self, "_fsm_clock_ms"))
	_connect_inputs()
	_refresh_badges()
	_play_stream("play_voice", VOICE_PATH)
	_restore_music()
	_log("scene.ready", {"scene": "mercado"})


func _connect_inputs() -> void:
	for index: int in range(SHELF_IDS.size()):
		var shelf: TapButton = get_node_or_null("Shelf%d" % index) as TapButton
		if shelf != null:
			shelf.tapped.connect(try_buy.bind(SHELF_IDS[index]))
	var home: TapButton = get_node_or_null("HomeButton") as TapButton
	if home != null:
		home.tapped.connect(_on_home_tapped)
	if rig != null:
		rig.tapped.connect(_on_rig_tapped)
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress != null and progress.has_signal("progress_changed"):
		progress.progress_changed.connect(_refresh_badges)


func shelf_ids() -> Array[String]:
	var ids: Array[String] = []
	ids.assign(SHELF_IDS)
	return ids


## The one money path. Returns true only when the piece was paid for and is now owned.
func try_buy(id: String) -> bool:
	if fsm == null or fsm.state != STATE_IDLE:
		return false
	var price: int = _price_if_buyable(id)
	if price < 0:
		return false
	if not _charge(id, price):
		_deny()
		return false
	_on_paid(id, price)
	return true


## -1 means "do not charge": unknown id, already owned, or no ProgressManager (RAM-only
## purchases are worse than a refused tap).
func _price_if_buyable(id: String) -> int:
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress == null or FurnitureCatalog.get_item(id) == null:
		return -1
	if bool(progress.call("owns_furniture", id)):
		return -1
	return FurnitureCatalog.price_of(id, economy)


func _charge(id: String, price: int) -> bool:
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress == null:
		return false
	return bool(progress.call("buy_furniture", id, price))


func _on_paid(id: String, price: int) -> void:
	if not fsm.transition_to(STATE_PAYING):
		return
	_state_age = 0.0
	_fly_coin(id)
	_refresh_badges()
	_log("store.buy", {"id": id, "price": price})


func _deny() -> void:
	denials += 1
	_play_stream("play_sfx", DENY_SFX)
	if rig != null:
		rig.set_expression("carente")
	_log("store.denied", {"reason": "coins"})


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


func advance(delta: float) -> void:
	var step: float = maxf(delta, 0.0)
	_fsm_clock_sec += step
	_state_age += step
	match fsm.state:
		STATE_PAYING:
			_finish_payment_if_due()
		STATE_SOLD:
			_end_sale_if_due()


func _finish_payment_if_due() -> void:
	if _state_age < PAY_SEC:
		return
	if not fsm.transition_from(STATE_PAYING, STATE_SOLD):
		return
	_state_age = 0.0
	_play_stream("play_sfx", BUY_SFX)
	if rig != null:
		rig.set_expression("rindo")


func _end_sale_if_due() -> void:
	if _state_age < SOLD_HOLD_SEC:
		return
	if fsm.transition_from(STATE_SOLD, STATE_IDLE):
		_state_age = 0.0


## A sold badge marks what she already owns, so a second tap is visibly pointless and a
## fresh room still tells her what she has.
func _refresh_badges() -> void:
	var progress: Node = get_node_or_null("/root/ProgressManager")
	for index: int in range(SHELF_IDS.size()):
		var badge: Control = get_node_or_null("Shelf%d/SoldBadge%d" % [index, index]) as Control
		if badge == null:
			continue
		badge.visible = progress != null and bool(progress.call("owns_furniture", SHELF_IDS[index]))


func _fly_coin(id: String) -> void:
	if hud == null:
		return
	var shelf: Control = _shelf_of(id)
	if shelf != null:
		hud.fly_coin(shelf.get_global_rect().get_center())


func _shelf_of(id: String) -> Control:
	var index: int = SHELF_IDS.find(id)
	if index < 0:
		return null
	return get_node_or_null("Shelf%d" % index) as Control


func close_celebrate_if_needed() -> void:
	var manager: Node = get_node_or_null("/root/CareLoopManager")
	if manager != null and manager.has_method("close_celebrate_if_needed"):
		manager.call("close_celebrate_if_needed")


func _on_home_tapped() -> void:
	var manager: Node = get_node_or_null("/root/SceneManager")
	if manager != null:
		manager.call("request_scene", CASA_PATH)


func _on_rig_tapped() -> void:
	if rig != null:
		rig.set_expression("rindo")


func _fsm_clock_ms() -> int:
	return int(_fsm_clock_sec * 1000.0)


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
