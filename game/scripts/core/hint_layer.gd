# story: e12s05
class_name HintLayer
extends RefCounted
## Idle clock + shared HintManager for one step at a time.

const DEFAULT_COOLDOWN_SEC: float = 3.0

var manager: HintManager = null
var drag_hint: DragHint = null
var step_def: StepDef = null
var nodes: PlayerNodeTable = null
var idle_sec: float = 0.0
var input_seen: bool = false
var _hint_played: bool = false


func bind(mgr: HintManager, hand: DragHint, table: PlayerNodeTable) -> void:
	manager = mgr
	drag_hint = hand
	nodes = table


func begin_step(def: StepDef) -> void:
	step_def = def
	idle_sec = 0.0
	input_seen = false
	_hint_played = false
	stop()


func note_input() -> void:
	input_seen = true
	idle_sec = 0.0
	_hint_played = false
	stop()
	if manager != null:
		manager.begin_cooldown(DEFAULT_COOLDOWN_SEC)


func advance(delta: float) -> void:
	if step_def == null or step_def.hint_delay_sec <= 0.0:
		return
	if input_seen:
		return
	if manager == null or drag_hint == null or nodes == null:
		return
	idle_sec += maxf(delta, 0.0)
	if idle_sec < step_def.hint_delay_sec:
		return
	if manager.try_show_next():
		return
	if _hint_played:
		return
	_show_hint()


func stop() -> void:
	if manager != null:
		manager.stop_current()


func hint_was_shown() -> bool:
	return _hint_played


func _show_hint() -> void:
	var from_id: String = step_def.hint_from_id
	var to_id: String = step_def.hint_to_id
	if from_id.is_empty() or to_id.is_empty():
		return
	var from_g: Vector2 = nodes.global_center(from_id)
	var to_g: Vector2 = nodes.global_center(to_id)
	var target: Control = nodes.resolve(to_id)
	drag_hint.play(from_g, to_g, target)
	manager.enqueue(drag_hint)
	manager.try_show_next()
	_hint_played = true
	if not step_def.hint_voice_key.is_empty() and drag_hint.get_parent() != null:
		VoicePlayback.play_key(drag_hint.get_parent(), step_def.hint_voice_key)
	LogSink.emit_to_diary("hint.shown", {"step": "active"})
