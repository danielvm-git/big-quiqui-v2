# story: e13s09
extends RefCounted
## One tap picks one prize from the def. A second tap does nothing.

var _ctx: TemplateContext = null
var _picked: String = ""


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	var saved: String = _saved()
	if _prizes().has(saved):
		_picked = saved


func advance(_delta: float) -> void:
	pass


func pick(prize_id: String) -> bool:
	if not _picked.is_empty() or not Ids.is_valid(prize_id):
		return false
	if not _prizes().has(prize_id):
		return false
	var sink: Node = _progress()
	if sink == null or not bool(sink.call("equip", "prize", prize_id)):
		return false
	_picked = prize_id
	return true


func picked() -> String:
	return _picked


func progress() -> float:
	return 1.0 if not _picked.is_empty() else 0.0


func claims_completion() -> bool:
	return false


func _prizes() -> PackedStringArray:
	if _ctx == null or _ctx.step_def == null:
		return PackedStringArray()
	return _ctx.step_def.item_ids


func _saved() -> String:
	var sink: Node = _progress()
	if sink == null:
		return ""
	return str(sink.call("equipped", "prize"))


func _progress() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("ProgressManager")
