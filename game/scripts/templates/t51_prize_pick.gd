# story: e13s09
extends RefCounted
## One tap picks one prize from the def. A second pick does nothing, and there is never an ad.
## Re-entering shows the saved prize lit; one tap on it carries on.

const STATE_OPEN: String = "OPEN"
const STATE_PICKED: String = "PICKED"
const STATE_DONE: String = "DONE"
## No state times out: the child picks whenever she is ready.
const MAX_DWELL_SEC: Dictionary = {}
const LEGAL_EDGES: Dictionary = {
	STATE_OPEN: [STATE_DONE],
	STATE_PICKED: [STATE_DONE],
}

var _ctx: TemplateContext = null
var _picked: String = ""
var _fsm: Fsm = Fsm.new(STATE_OPEN, LEGAL_EDGES, MAX_DWELL_SEC)
var _buttons: Dictionary = {}
var _rig_filter: int = -1


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_rig_filter = TemplateKit.quiet_rig(ctx)
	_adopt(_saved())
	_build_buttons()
	_light()


func teardown() -> void:
	TemplateKit.restore_rig(_ctx, _rig_filter)
	_rig_filter = -1
	for prize_id: String in _buttons.keys():
		var button: TapButton = _buttons[prize_id] as TapButton
		if is_instance_valid(button):
			button.queue_free()
	_buttons.clear()


func advance(_delta: float) -> void:
	pass


func pick(prize_id: String) -> bool:
	if _fsm.state != STATE_OPEN:
		_carry_on(prize_id)
		return false
	if not Ids.is_valid(prize_id) or not _prizes().has(prize_id):
		return false
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink == null or not bool(sink.call("pick_prize", prize_id)):
		return false
	_picked = prize_id
	_fsm.transition_to(STATE_DONE)
	_light()
	TemplateKit.play_hit(_ctx, "template.prize", {"picked": 1})
	return true


func picked() -> String:
	return _picked


func progress() -> float:
	return 1.0 if _fsm.state == STATE_DONE else 0.0


func button(prize_id: String) -> TapButton:
	return _buttons.get(prize_id) as TapButton


func _prizes() -> PackedStringArray:
	if _ctx == null or _ctx.step_def == null:
		return PackedStringArray()
	return _ctx.step_def.item_ids


## This cycle already holds a pick. A pick that is not in this def still lets one tap carry on.
func _adopt(saved: String) -> void:
	if saved.is_empty():
		return
	_picked = saved if _prizes().has(saved) else ""
	_fsm.reset(STATE_PICKED)


## A tap on the saved prize, or on any prize when the saved one is not in this def, carries on.
func _carry_on(prize_id: String) -> void:
	if _fsm.state == STATE_PICKED and (_picked.is_empty() or _picked == prize_id):
		_fsm.transition_to(STATE_DONE)


func _saved() -> String:
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink == null:
		return ""
	return str(sink.call("picked_prize"))


func _build_buttons() -> void:
	if _ctx == null or _ctx.tray == null:
		return
	for prize_id: String in _prizes():
		if _buttons.has(prize_id):
			continue
		var button: TapButton = TemplateKit.tap_button(prize_id, Vector2(160.0 * float(_buttons.size()), 0.0))
		button.tapped.connect(pick.bind(prize_id))
		_ctx.tray.add_child(button)
		_buttons[prize_id] = button


func _light() -> void:
	for prize_id: String in _buttons.keys():
		var lit: bool = _picked.is_empty() or _picked == prize_id
		(_buttons[prize_id] as TapButton).visual.modulate = Color(1, 1, 1, 1) if lit else Color(1, 1, 1, 0.4)
