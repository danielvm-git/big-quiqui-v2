# story: e08s03
class_name WheelScene
extends Control
## Single-spin wheel: tickets in, coins out, seeded prize table (FIX-04/05).

const CASA_PATH: String = "res://scenes/casa.tscn"
const VOICE_PATH: String = "res://assets/audio/voice/roda_boa_sorte.ogg"
const BADGE_ART: String = "res://assets/art/ui/estrela.png"

const STATE_IDLE: String = "IDLE"
const STATE_SPINNING: String = "SPINNING"
const STATE_REWARD: String = "REWARD"
const LEGAL_EDGES: Dictionary = {
	STATE_IDLE: [STATE_SPINNING],
	STATE_SPINNING: [STATE_REWARD],
	STATE_REWARD: [STATE_IDLE],
}
const MAX_DWELL: Dictionary = {STATE_SPINNING: 3.0, STATE_REWARD: 3.0}

const SPIN_ANIM_SEC: float = 0.35
const REWARD_HOLD_SEC: float = 0.2

@export var economy: EconomyData = null

var rig: QuiQuiRig = null
var hud: CoinTicketHud = null
var spin: TapButton = null
var badge: Control = null

var manual_step: bool = false

var fsm: Fsm = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _fsm_clock_sec: float = 0.0
var _state_age: float = 0.0
var _pending_prize: String = ""
var _had_spin_success: bool = false


func _ready() -> void:
	rig = get_node_or_null("QuiQuiRig") as QuiQuiRig
	hud = get_node_or_null("CoinTicketHud") as CoinTicketHud
	spin = get_node_or_null("SpinButton") as TapButton
	badge = get_node_or_null("WheelBadge") as Control
	close_celebrate_if_needed()
	if economy == null:
		economy = EconomyData.new()
	_rng.randomize()
	fsm = Fsm.new(STATE_IDLE, LEGAL_EDGES, MAX_DWELL, Callable(self, "_fsm_clock_ms"))
	_connect_inputs()
	_play_voice()
	_refresh_badge()
	_log("scene.ready", {"scene": "roda"})


func _connect_inputs() -> void:
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress != null and progress.has_signal("progress_changed"):
		progress.progress_changed.connect(_refresh_badge)
	if spin != null:
		spin.tapped.connect(_on_spin_tapped)
	var home: TapButton = get_node_or_null("HomeButton") as TapButton
	if home != null:
		home.tapped.connect(_on_home)
	if rig != null:
		rig.tapped.connect(_on_rig_tapped)


## Test seam: a fixed seed replays the same prizes; production seeds from the clock once.
func seed_rng(value: int) -> void:
	_rng.seed = value


## Test seam: replace the prize table after mount.
func apply_economy(data: EconomyData) -> void:
	if data != null:
		economy = data
	_refresh_badge()


func _fsm_clock_ms() -> int:
	return int(_fsm_clock_sec * 1000.0)


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


func advance(delta: float) -> void:
	var step: float = maxf(delta, 0.0)
	_fsm_clock_sec += step
	_state_age += step
	match fsm.state:
		STATE_SPINNING:
			if _state_age >= SPIN_ANIM_SEC:
				_grant_reward()
		STATE_REWARD:
			if _state_age >= REWARD_HOLD_SEC:
				fsm.transition_from(STATE_REWARD, STATE_IDLE)
				_state_age = 0.0


func close_celebrate_if_needed() -> void:
	var manager: Node = get_node_or_null("/root/CareLoopManager")
	if manager != null and manager.has_method("close_celebrate_if_needed"):
		manager.call("close_celebrate_if_needed")


func _on_spin_tapped() -> void:
	if fsm.state != STATE_IDLE:
		return
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress == null or economy == null:
		return
	var cost: int = maxi(economy.wheel_spin_ticket_cost, 1)
	if int(progress.call("get_tickets")) < cost:
		return
	if not fsm.transition_to(STATE_SPINNING):
		return
	progress.call("add_tickets", -cost)
	_pending_prize = economy.pick_prize(_rng)
	_state_age = 0.0
	_log("wheel.spin_start", {"prize": _pending_prize})


func _grant_reward() -> void:
	if not fsm.transition_from(STATE_SPINNING, STATE_REWARD):
		return
	var coins: int = 0
	if not _pending_prize.is_empty():
		coins = maxi(int(economy.wheel_prize_coins.get(_pending_prize, 0)), 0)
	var progress: Node = get_node_or_null("/root/ProgressManager")
	if progress != null and coins > 0:
		progress.call("add_coins", coins)
	if hud != null and spin != null:
		hud.fly_coin(spin.get_global_rect().get_center())
	_log("wheel.prize", {"id": _pending_prize, "coins": coins})
	_had_spin_success = true
	_state_age = 0.0
	_refresh_badge()


func _refresh_badge() -> void:
	if badge == null:
		return
	var progress: Node = get_node_or_null("/root/ProgressManager")
	var tickets: int = 0 if progress == null else int(progress.call("get_tickets"))
	var show_badge: bool = tickets > 0 and not _had_spin_success
	var was_visible: bool = badge.visible
	badge.visible = show_badge
	if was_visible and not show_badge and _had_spin_success:
		_log("wheel.badge_hide", {"reason": "first_spin_done"})


func _on_home() -> void:
	if fsm.state != STATE_IDLE:
		return
	var manager: Node = get_node_or_null("/root/SceneManager")
	if manager != null:
		manager.call("request_scene", CASA_PATH)


func _on_rig_tapped() -> void:
	if rig != null:
		rig.set_expression("rindo")


func _play_voice() -> void:
	if not ResourceLoader.exists(VOICE_PATH):
		return
	var audio: Node = get_node_or_null("/root/AudioManager")
	var stream: AudioStream = load(VOICE_PATH) as AudioStream
	if audio != null and stream != null:
		audio.call("play_voice", stream)


func _log(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
