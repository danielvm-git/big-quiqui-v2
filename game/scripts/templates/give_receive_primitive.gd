# story: e12s04
class_name GiveReceivePrimitive
extends RefCounted
## Give→Receive over TouchDraggable modes — no second drag surface (ADR-004).

const MODE_SINGLE: String = "single"
const MODE_PICK_ONE: String = "pick_one"
const MODE_SLOTS: String = "slots"

var _ctx: TemplateContext = null
var _items: Array[TouchDraggable] = []
var _successes: int = 0
var _goal: int = 1
var _receiver: Control = null


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_successes = 0
	_goal = maxi(ctx.step_def.repeat_count, 1)
	_receiver = _resolve_receiver()
	_spawn_items()


func teardown() -> void:
	for item: TouchDraggable in _items:
		if is_instance_valid(item):
			item.queue_free()
	_items.clear()


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	if _goal <= 0:
		return 1.0
	return clampf(float(_successes) / float(_goal), 0.0, 1.0)


func active_draggables() -> Array[TouchDraggable]:
	return _items


func _resolve_receiver() -> Control:
	if _ctx == null or _ctx.nodes == null:
		return null
	return _ctx.nodes.resolve(_ctx.step_def.receiver_id)


func _spawn_items() -> void:
	if _ctx == null or _ctx.tray == null:
		return
	var ids: PackedStringArray = _ctx.step_def.item_ids
	var count: int = ids.size()
	if count == 0:
		return
	for index: int in range(count):
		var item: TouchDraggable = _make_item(index, ids[index])
		_ctx.tray.add_child(item)
		_items.append(item)


func _make_item(index: int, item_id: String) -> TouchDraggable:
	var data: ItemData = FoodCatalog.get_item(item_id)
	var food: TouchDraggable = TouchDraggable.new()
	food.name = "Item%d" % index
	food.custom_minimum_size = TouchDraggable.MIN_HIT_SIZE
	food.add_to_group("hit_target", true)
	food.position = Vector2(180.0 * index, 0.0)
	food.size = TouchDraggable.MIN_HIT_SIZE
	food.mode = TouchDraggable.Mode.CONSUME_ON_DROP
	food.drop_target = _receiver
	food.drop_margin = 120.0
	food.consumed.connect(_on_consumed)
	food.drag_ended.connect(_on_drag_ended.bind(food))
	var art: TextureRect = TextureRect.new()
	art.name = "Art"
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if data != null:
		art.texture = data.texture()
	food.add_child(art)
	return food


func _on_consumed() -> void:
	_successes += 1
	_play_hit_reactions()
	if _ctx != null and _ctx.runner != null:
		_ctx.runner.report_template_progress(progress())


func _on_drag_ended(item: TouchDraggable) -> void:
	if item.state_id() == TouchDraggable.STATE_CONSUMED:
		return
	_play_miss_reactions()


func _play_hit_reactions() -> void:
	if _ctx == null or _ctx.reactions == null or _ctx.step_def == null:
		return
	var batch: Array = []
	if not _ctx.step_def.on_hit_pose.is_empty():
		batch.append({"kind": ReactionExecutor.KIND_POSE, "id": _ctx.step_def.on_hit_pose})
	if not _ctx.step_def.on_hit_sfx_id.is_empty():
		batch.append({"kind": ReactionExecutor.KIND_SFX, "id": _ctx.step_def.on_hit_sfx_id})
	_ctx.reactions.execute(batch)
	LogSink.emit_to_diary("template.give", {"mode": _ctx.step_def.mode})


func _play_miss_reactions() -> void:
	if _ctx == null or _ctx.reactions == null or _ctx.step_def == null:
		return
	var sfx: String = _ctx.step_def.on_miss_sfx_id
	if sfx.is_empty():
		return
	_ctx.reactions.execute([{"kind": ReactionExecutor.KIND_SFX, "id": sfx}])
