# story: e07s02
class_name CelebrationScene
extends Control
## Closing the care cycle: confetti, the family voice, and the cycle's reward paid
## exactly once — atomically with the cycle counter (T-E07-03, T-E07-04).
##
## Coming back after the celebration is free play: the loop is already IDLE, so no second payment
## is possible in the same session. The only thing that refuses a second payment is
## `CareLoopManager._rewarded_cycle_id` — an in-memory, per-session ledger. `ProgressManager` has no
## per-cycle guard of its own, and `close_cycle()`'s `credited_cycle` latch covers one mount only
## (ADR-009).

const CASA_PATH: String = "res://scenes/casa.tscn"
const MUSIC_PATH: String = "res://assets/audio/music/tema_principal.ogg"
const VOICE_PATH: String = "res://assets/audio/voice/celebrate_parabens.ogg"

## The party is the payoff of the whole cycle, so it is not a single fade: it holds long
## enough for a four-year-old to see the confetti settle and the reward arrive, then goes
## home by itself. `advance()` is the only clock (no timers), so tests drive it exactly.
const HOLD_SEC: float = 1.8
## The reveal waits for the voice to start, then pops in over `REVEAL_POP_SEC`.
const REVEAL_LEAD_SEC: float = 0.35
const REVEAL_POP_SEC: float = 0.5
const REVEAL_START_SCALE: float = 0.4

@onready var rig: QuiQuiRig = $QuiQuiRig as QuiQuiRig
@onready var confetti: CPUParticles2D = $Confetti as CPUParticles2D
@onready var coin: TextureRect = get_node_or_null("Coin") as TextureRect
@onready var ticket: TextureRect = get_node_or_null("Ticket") as TextureRect

var credited_cycle: int = -1
var paid_coins: int = 0
var paid_tickets: int = 0
var revealed: bool = false
var manual_step: bool = false

var _clock_sec: float = 0.0
var _casa_requested: bool = false


func _ready() -> void:
	($HomeButton as TapButton).tapped.connect(_leave)
	rig.set_expression("pulando")
	confetti.global_position = rig.get_visual_global_rect().get_center()
	confetti.restart()
	_play_music_once()
	_play_stream("play_voice", VOICE_PATH)
	_log("scene.ready", {"scene": "celebracao"})
	# Close if we can, then hold: every other room returns to the hub by itself, and a
	# celebration that only escapes through the corner button is a trap.
	close_cycle()
	_hide_reward()


func _process(delta: float) -> void:
	if manual_step:
		return
	advance(delta)


## The party's clock: reveals the reward, then goes home once `HOLD_SEC` has passed. Driven
## by `_process` in play and by tests through `manual_step`, so nobody waits on wall time.
func advance(delta: float) -> void:
	_clock_sec += maxf(delta, 0.0)
	_reveal_progress()
	if _clock_sec >= HOLD_SEC:
		_leave()


## What she earned, shown without a word: one coin and one ticket pop out of the burst.
## Nothing to read, nothing to tap (they ignore the mouse), and the hub's HUD still owns
## the exact totals.
func _reveal_progress() -> void:
	var elapsed: float = _clock_sec - REVEAL_LEAD_SEC
	if elapsed < 0.0:
		return
	if not revealed:
		revealed = true
		_log("celebrate.reveal", {"coins": paid_coins, "tickets": paid_tickets})
	var ratio: float = clampf(elapsed / REVEAL_POP_SEC, 0.0, 1.0)
	var eased: float = 1.0 - pow(1.0 - ratio, 3.0)
	for icon: TextureRect in [coin, ticket]:
		if icon == null:
			continue
		icon.visible = true
		icon.pivot_offset = icon.size * 0.5
		icon.modulate.a = clampf(ratio * 2.0, 0.0, 1.0)
		icon.scale = Vector2.ONE * lerpf(REVEAL_START_SCALE, 1.0, eased)


func _hide_reward() -> void:
	for icon: TextureRect in [coin, ticket]:
		if icon != null:
			icon.visible = false


## Closes the cycle: `CELEBRATE -> IDLE` through the loop's own machine, which is also
## what increments `cycle_id`.
##
## The scene does **not** pay. `CareLoopManager._grant_cycle_reward()` pays once when the
## loop *enters* `CELEBRATE` (guarded by `_rewarded_cycle_id`), so paying here as well
## doubled the reward — found by the first run of this story's tests. One owner for
## money: the manager.
func close_cycle() -> bool:
	var care: Node = _care_loop()
	if care == null:
		return false
	if str(care.call("state_id")) != CareSteps.CELEBRATE:
		return false
	var cycle: int = int(care.get("cycle_id"))
	if credited_cycle == cycle:
		return false
	if not bool(care.call("complete_step", CareSteps.CELEBRATE)):
		return false
	credited_cycle = cycle
	var progress: Node = _progress()
	if progress != null:
		paid_coins = int(progress.call("get_coins"))
		paid_tickets = int(progress.call("get_tickets"))
	_log("celebrate.closed", {"coins": paid_coins, "tickets": paid_tickets, "cycle": cycle})
	return true


func _leave() -> void:
	if _casa_requested:
		return
	_casa_requested = true
	var manager: Node = get_node_or_null("/root/SceneManager")
	if manager != null:
		manager.call("request_scene", CASA_PATH)


func _care_loop() -> Node:
	return get_node_or_null("/root/CareLoopManager")


func _progress() -> Node:
	return get_node_or_null("/root/ProgressManager")


## The party is louder than the room, not a different song: restarting the shared theme would
## put its first note under "parabéns" every cycle (threat model, kids row).
func _play_music_once() -> void:
	if not ResourceLoader.exists(MUSIC_PATH):
		_log("audio.missing_art", {"track": MUSIC_PATH.get_file().get_basename()})
		return
	var audio: Node = get_node_or_null("/root/AudioManager")
	var stream: AudioStream = load(MUSIC_PATH) as AudioStream
	if audio == null or stream == null or bool(audio.call("is_music_playing", stream)):
		return
	audio.call("play_music", stream)


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


func _log(ev: String, data: Dictionary) -> void:
	LogSink.emit_from(self, ev, data)
