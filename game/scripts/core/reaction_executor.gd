# story: e12s03
class_name ReactionExecutor
extends RefCounted
## Closed vocabulary: pose, sfx, voice, fx, swap, coins, wait — synchronous except wait.

const KIND_POSE: String = "pose"
const KIND_SFX: String = "sfx"
const KIND_VOICE: String = "voice"
const KIND_FX: String = "fx"
const KIND_SWAP: String = "swap"
const KIND_COINS: String = "coins"
const KIND_WAIT: String = "wait"

var recorder: Object = null
var _rig: QuiQuiRig = null
var _host: Node = null
var _pending_wait_sec: float = 0.0


func bind(host: Node, rig: QuiQuiRig) -> void:
	_host = host
	_rig = rig


func execute(reactions: Array) -> void:
	_pending_wait_sec = 0.0
	var frame: int = Engine.get_process_frames()
	for entry: Variant in reactions:
		if entry is not Dictionary:
			continue
		var kind: String = str((entry as Dictionary).get("kind", ""))
		if kind == KIND_WAIT:
			_pending_wait_sec += float((entry as Dictionary).get("sec", 0.0))
			_record(kind, frame)
			continue
		_apply(kind, entry as Dictionary)
		_record(kind, frame)


func pending_wait_sec() -> float:
	return _pending_wait_sec


func _apply(kind: String, data: Dictionary) -> void:
	match kind:
		KIND_POSE:
			_apply_pose(data)
		KIND_SFX:
			_apply_sfx(data)
		KIND_VOICE:
			_apply_voice(data)
		KIND_COINS:
			_apply_coins(data)
		KIND_FX, KIND_SWAP:
			pass
		_:
			pass


func _apply_pose(data: Dictionary) -> void:
	if _rig == null:
		return
	var pose_id: String = str(data.get("id", ""))
	if not pose_id.is_empty():
		_rig.set_expression(pose_id)


func _apply_sfx(data: Dictionary) -> void:
	var sfx_id: String = str(data.get("id", ""))
	if sfx_id.is_empty():
		return
	var path: String = SfxCatalog.path(sfx_id)
	if path.is_empty():
		return
	var player: Node = _audio()
	if player != null and player.has_method("play_sfx"):
		player.call("play_sfx", load(path) as AudioStream)


func _apply_voice(data: Dictionary) -> void:
	var key: String = str(data.get("key", ""))
	if key.is_empty():
		return
	if _host != null:
		VoicePlayback.play_key(_host, key)


func _apply_coins(data: Dictionary) -> void:
	var amount: int = int(data.get("amount", 1))
	if amount > 0:
		var pm: Node = _progress()
		if pm != null and pm.has_method("add_coins"):
			pm.call("add_coins", amount)


func _audio() -> Node:
	if _host == null:
		return null
	return _host.get_node_or_null("/root/AudioManager")


func _progress() -> Node:
	if _host == null:
		return null
	return _host.get_node_or_null("/root/ProgressManager")


func _record(kind: String, frame: int) -> void:
	if recorder == null:
		return
	if recorder.has_method("record"):
		recorder.call("record", kind, frame)
