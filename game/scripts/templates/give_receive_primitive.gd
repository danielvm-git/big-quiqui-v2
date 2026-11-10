# story: e12s04
# story: e14s02
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
	if _is_recycle_step() and VillageRecycle.recycled_this_session:
		_successes = _goal
		return
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
	var id: String = _ctx.step_def.receiver_id
	var found: Control = _ctx.nodes.resolve(id)
	if found != null:
		return found
	if id == "recycle_bin" and _ctx.host != null:
		return _spawn_recycle_bin()
	return null


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
	var tex: Texture2D = data.texture() if data != null else ItemArt.texture(item_id)
	art.texture = tex
	food.add_child(art)
	return food


func _on_consumed() -> void:
	if _is_recycle_step() and VillageRecycle.recycled_this_session:
		return
	_successes += 1
	if _is_recycle_step():
		_pay_recycle_once()
	_play_hit_reactions()
	if _ctx != null and _ctx.runner != null:
		_ctx.runner.report_template_progress(progress())


func _on_drag_ended(item: TouchDraggable) -> void:
	if item.state_id() == TouchDraggableStates.STATE_CONSUMED:
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


func _is_recycle_step() -> bool:
	return _ctx != null and _ctx.step_def != null and _ctx.step_def.receiver_id == "recycle_bin"


func _pay_recycle_once() -> void:
	var progress: Node = (_ctx.host as Node).get_node_or_null("/root/ProgressManager") if _ctx.host != null else null
	if progress != null and progress.has_method("add_coins"):
		progress.call("add_coins", 1)
	VillageRecycle.recycled_this_session = true
	LogSink.emit_to_diary("vila.recycle_earn", {"coins": 1})


func _spawn_recycle_bin() -> Control:
	var host: Control = _ctx.host as Control
	if host == null or _ctx.nodes == null:
		return null
	var bin: Control = Control.new()
	bin.name = "RecycleBin"
	bin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bin.add_to_group("hit_target", true)
	bin.custom_minimum_size = TouchDraggable.MIN_HIT_SIZE
	bin.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bin.anchor_left = 0.72
	bin.anchor_right = 0.72
	bin.anchor_top = 0.78
	bin.anchor_bottom = 0.78
	bin.offset_left = -TouchDraggable.MIN_HIT_SIZE.x * 0.5
	bin.offset_right = TouchDraggable.MIN_HIT_SIZE.x * 0.5
	bin.offset_top = -TouchDraggable.MIN_HIT_SIZE.y * 0.5
	bin.offset_bottom = TouchDraggable.MIN_HIT_SIZE.y * 0.5
	host.add_child(bin)
	_ctx.nodes.register("recycle_bin", bin)
	return bin
