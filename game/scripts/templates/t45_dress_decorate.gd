# story: e13s05
extends RefCounted
## Categories, slots and the bin come from the def. Invalid ids never reach the save.

var _ctx: TemplateContext = null
var _plays: int = 0


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	return 0.0


func categories() -> PackedStringArray:
	if _ctx == null or _ctx.step_def == null:
		return PackedStringArray()
	return _ctx.step_def.category_ids


func snap(item_id: String) -> bool:
	if not Ids.is_valid(item_id):
		return false
	var slot: String = _slot_for(item_id)
	if slot.is_empty():
		return false
	var sink: Node = _progress()
	if sink == null:
		return false
	return bool(sink.call("equip", slot, item_id))


func place(item_id: String, nx: float, ny: float) -> bool:
	if not Ids.is_valid(item_id):
		return false
	var sink: Node = _progress()
	if sink == null:
		return false
	return bool(sink.call("place_furniture", item_id, nx, ny))


func bin(item_id: String) -> bool:
	var slot: String = _slot_for(item_id)
	if not Ids.is_valid(slot):
		return false
	var sink: Node = _progress()
	if sink == null:
		return false
	_plays += 1
	return bool(sink.call("clear_slot", slot))


func play_count() -> int:
	return _plays


func _slot_for(item_id: String) -> String:
	if _ctx == null or _ctx.step_def == null:
		return ""
	var index: int = _ctx.step_def.item_ids.find(item_id)
	var slots: PackedStringArray = _ctx.step_def.slot_ids
	if index < 0 or index >= slots.size():
		return ""
	return slots[index]


func _progress() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("ProgressManager")
