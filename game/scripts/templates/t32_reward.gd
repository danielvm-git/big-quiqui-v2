# story: e13s05
extends RefCounted
## The reward is a star to tap. Paying belongs to the cycle ledger and the amount to the services.
## Re-entering after the tap finds the star already lit; one more tap carries on. Never an ad.

const STATE_UNLIT: String = "UNLIT"
const STATE_LIT: String = "LIT"
const STATE_DONE: String = "DONE"
## No state times out: the star waits for the child's finger as long as it takes.
const MAX_DWELL_SEC: Dictionary = {}
const LEGAL_EDGES: Dictionary = {
	STATE_UNLIT: [STATE_LIT],
	STATE_LIT: [STATE_DONE],
}

var _ctx: TemplateContext = null
var _button: TapButton = null
var _rig_filter: int = -1
var _fsm: Fsm = Fsm.new(STATE_UNLIT, LEGAL_EDGES, MAX_DWELL_SEC)


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_rig_filter = TemplateKit.quiet_rig(ctx)
	if _collected():
		_fsm.reset(STATE_LIT)
	_build_button()
	_light()


func teardown() -> void:
	TemplateKit.restore_rig(_ctx, _rig_filter)
	_rig_filter = -1
	if _button != null and is_instance_valid(_button):
		_button.queue_free()
	_button = null


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	return 1.0 if _fsm.state == STATE_DONE else 0.0


func star_lit() -> bool:
	return _fsm.state != STATE_UNLIT


func button() -> TapButton:
	return _button


## The child's tap. First tap of the cycle collects (and pays when nothing paid yet); a tap on a
## lit star only carries on. True when this tap collected.
func collect() -> bool:
	var collected: bool = false
	if _fsm.state == STATE_UNLIT:
		collected = _collect_now()
		_fsm.transition_to(STATE_LIT)
	_fsm.transition_to(STATE_DONE)
	_light()
	return collected


func gift_id() -> String:
	if _ctx == null or _ctx.step_def == null or _ctx.step_def.item_ids.is_empty():
		return ""
	return _ctx.step_def.item_ids[0]


func _collect_now() -> bool:
	var loop: Node = TemplateKit.autoload("CareLoopManager")
	if loop == null or not loop.has_method("collect_reward"):
		return false
	var collected: bool = bool(loop.call("collect_reward"))
	if collected:
		_give_gift()
		_fly_coin()
	return collected


func _give_gift() -> void:
	var gift: String = gift_id()
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink != null and FurnitureCatalog.FURNITURE_IDS.has(gift):
		sink.call("buy_furniture", gift, 0)


func _fly_coin() -> void:
	if _ctx == null or not (_ctx.host is Control) or _button == null:
		return
	var hud: Node = (_ctx.host as Control).get_node_or_null("CoinHud")
	if hud != null and hud.has_method("fly_coin"):
		hud.call("fly_coin", _button.global_position + _button.size * 0.5)


func _collected() -> bool:
	var loop: Node = TemplateKit.autoload("CareLoopManager")
	if loop == null or not loop.has_method("reward_collected"):
		return false
	return bool(loop.call("reward_collected"))


func _build_button() -> void:
	if _ctx == null or _ctx.tray == null:
		return
	_button = TemplateKit.tap_button("star", Vector2(0.0, 0.0))
	_button.tapped.connect(collect)
	_ctx.tray.add_child(_button)


func _light() -> void:
	if _button != null and is_instance_valid(_button) and _button.visual != null:
		_button.visual.modulate = Color(1, 1, 1, 1) if star_lit() else Color(1, 1, 1, 0.55)
