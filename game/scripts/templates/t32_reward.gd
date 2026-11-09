# story: e13s05
extends RefCounted
## The reward is a star to tap. Paying belongs to the cycle ledger and the amount to the services.
## Re-entering after the tap finds the star already lit; one more tap carries on. Never an ad.

var _ctx: TemplateContext = null
var _button: TapButton = null
var _star: bool = false
var _continued: bool = false


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_star = _collected()
	_build_button()
	_light()


func teardown() -> void:
	if _button != null and is_instance_valid(_button):
		_button.queue_free()
	_button = null


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	return 1.0 if _continued else 0.0


func star_lit() -> bool:
	return _star


func button() -> TapButton:
	return _button


## The child's tap. First tap of the cycle collects (and pays when nothing paid yet); a tap on a
## lit star only carries on. True when this tap collected.
func collect() -> bool:
	var collected: bool = false
	if not _star:
		collected = _collect_now()
	_star = true
	_continued = true
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
		_button.visual.modulate = Color(1, 1, 1, 1) if _star else Color(1, 1, 1, 0.55)
