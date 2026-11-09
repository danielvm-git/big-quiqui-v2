# story: e13s05
extends RefCounted
## Collects through the cycle ledger. A second entry finds the star already lit.

var _ctx: TemplateContext = null
var _star: bool = false
var _collected: bool = false


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_star = _already_paid()


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	return 1.0 if _star else 0.0


func star_lit() -> bool:
	return _star


func collect() -> bool:
	if _collected or _already_paid():
		_star = true
		_collected = true
		return false
	var loop: Node = _care_loop()
	if loop == null or not loop.has_method("collect_reward"):
		return false
	var paid: bool = bool(loop.call("collect_reward"))
	_star = true
	_collected = true
	return paid


func gift_id() -> String:
	if _ctx == null or _ctx.step_def == null or _ctx.step_def.item_ids.is_empty():
		return ""
	return _ctx.step_def.item_ids[0]


func _already_paid() -> bool:
	var loop: Node = _care_loop()
	if loop == null or not loop.has_method("reward_paid"):
		return false
	return bool(loop.call("reward_paid"))


func _care_loop() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("CareLoopManager")
