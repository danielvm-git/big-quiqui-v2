# story: e14s03
extends RefCounted
## Duck rhythm: three pads, a miss replays the pose, nothing is lost, one payout.

const STATE_SHOWING: String = "SHOWING"
const STATE_WAITING: String = "WAITING"
const STATE_DONE: String = "DONE"
const LEGAL: Dictionary = {
	STATE_SHOWING: [STATE_WAITING, STATE_DONE],
	STATE_WAITING: [STATE_SHOWING, STATE_DONE],
	STATE_DONE: [],
}
const ROUNDS: int = 3

var _ctx: TemplateContext = null
var _fsm: Fsm = null
var _pads: Dictionary = {}
var _round: int = 0
var _pose: String = ""
var _paid: bool = false
var _plays: int = 0


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_fsm = Fsm.new(STATE_SHOWING, LEGAL, {}, Callable(self, "_clock_ms"))
	_build_pads()
	_pick_pose()


func teardown() -> void:
	for pad: TapButton in _pads.values():
		if is_instance_valid(pad):
			pad.queue_free()
	_pads.clear()
	_fsm = null


func advance(delta: float) -> void:
	if _fsm != null:
		_fsm.advance(delta)


func progress() -> float:
	return 1.0 if _round >= ROUNDS or _fsm.state == STATE_DONE else float(_round) / float(ROUNDS)


func play_count() -> int:
	return _plays


func pose_id() -> String:
	return _pose


func press(pad_id: String) -> void:
	_on_pad(pad_id)


func _build_pads() -> void:
	if _ctx == null or _ctx.step_def == null or _ctx.tray == null:
		return
	for index: int in range(_ctx.step_def.item_ids.size()):
		var pad_id: String = _ctx.step_def.item_ids[index]
		var pad: TapButton = TemplateKit.tap_button(pad_id, Vector2(220.0 * float(index), 0.0))
		pad.tapped.connect(_on_pad.bind(pad_id))
		_ctx.tray.add_child(pad)
		_pads[pad_id] = pad


func _pick_pose() -> void:
	if _ctx == null or _ctx.step_def == null or _ctx.step_def.item_ids.is_empty():
		return
	var ids: PackedStringArray = _ctx.step_def.item_ids
	_pose = ids[(_round + _plays) % ids.size()]
	_highlight(_pose)


func _on_pad(pad_id: String) -> void:
	if _fsm == null or _fsm.state == STATE_DONE:
		return
	_plays += 1
	if pad_id == _pose:
		_round += 1
		if _round >= ROUNDS:
			_pay_once()
			_fsm.transition_to(STATE_DONE)
			return
		_fsm.transition_to(STATE_WAITING)
		_pick_pose()
	else:
		TemplateKit.play_miss(_ctx)
		_fsm.transition_to(STATE_SHOWING)
		_highlight(_pose)


func _pay_once() -> void:
	if _paid:
		return
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink == null:
		return
	var economy: EconomyData = EconomyData.new()
	var coins: int = FriendCatalog.coins_of("pato", economy)
	if coins > 0:
		sink.call("add_coins", coins)
	sink.call("add_star", "pato")
	_paid = true


func _highlight(pad_id: String) -> void:
	for id: String in _pads.keys():
		var pad: TapButton = _pads[id] as TapButton
		if pad != null and pad.visual != null:
			pad.visual.modulate = Color(1.0, 0.95, 0.5) if id == pad_id else Color.WHITE


func _clock_ms() -> int:
	return Time.get_ticks_msec()
