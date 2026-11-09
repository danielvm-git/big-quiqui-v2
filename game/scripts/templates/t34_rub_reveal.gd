# story: e13s01
extends RefCounted
## Reveal layers in def order. The template knows no room.

var _rub: RubPrimitive = RubPrimitive.new()
var _ctx: TemplateContext = null
var _tool: TouchDraggable = null
var _layers: Array[Control] = []
var _owned: Array[Control] = []
var _gone: Array[bool] = []


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_rub.mode = _mode()
	_rub.bind_target(_hull_target())
	_bind_loop()
	_build_layers()
	_build_tool()


func teardown() -> void:
	_rub.release()
	if _tool != null and is_instance_valid(_tool):
		_tool.queue_free()
	for layer: Control in _owned:
		if is_instance_valid(layer):
			layer.queue_free()
	_owned.clear()


func advance(_delta: float) -> void:
	_reveal_due()


func progress() -> float:
	return _rub.progress()


func begin_gesture() -> void:
	if _ctx != null:
		_rub.begin(_ctx.host)


func end_gesture() -> void:
	_rub.release()


func note_rub(point: Vector2) -> bool:
	var counted: bool = _rub.rub_at(point)
	if counted:
		_reveal_due()
	return counted


func layer_alpha(index: int) -> float:
	if index < 0 or index >= _layers.size():
		return 1.0
	return _layers[index].modulate.a


func tool() -> TouchDraggable:
	return _tool


func _mode() -> String:
	if _ctx == null or _ctx.step_def == null or _ctx.step_def.mode.is_empty():
		return "reveal"
	return _ctx.step_def.mode


func _hull_target() -> Control:
	if _ctx != null and _ctx.nodes != null:
		var named: Control = _ctx.nodes.resolve("scrub_target")
		if named != null:
			return named
	if _ctx == null:
		return null
	return _ctx.rig


func _bind_loop() -> void:
	if _ctx == null or _ctx.step_def == null:
		return
	var path: String = SfxCatalog.path(_ctx.step_def.loop_sfx_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	_rub.set_loop(load(path) as AudioStream)


func _build_layers() -> void:
	if _ctx == null or _ctx.step_def == null:
		return
	for layer_id: String in _ctx.step_def.item_ids:
		var layer: Control = _claim_layer(layer_id)
		if layer == null:
			continue
		_layers.append(layer)
		_gone.append(false)


func _claim_layer(layer_id: String) -> Control:
	if _ctx.nodes != null:
		var existing: Control = _ctx.nodes.resolve(layer_id)
		if existing != null:
			return existing
	return _make_layer(layer_id)


func _make_layer(layer_id: String) -> Control:
	if _ctx.host == null:
		return null
	var layer: ColorRect = ColorRect.new()
	layer.name = layer_id
	layer.color = Color(1, 1, 1, 1)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ctx.host.add_child(layer)
	_owned.append(layer)
	return layer


func _build_tool() -> void:
	if _ctx == null or _ctx.tray == null:
		return
	var tool: TouchDraggable = TouchDraggable.new()
	tool.name = "RubTool"
	tool.custom_minimum_size = TouchDraggable.MIN_HIT_SIZE
	tool.size = TouchDraggable.MIN_HIT_SIZE
	tool.mode = TouchDraggable.Mode.CONTINUOUS_SCRUB
	tool.scrub_target = _hull_target()
	tool.scrubbed.connect(_on_scrubbed)
	tool.drag_started.connect(begin_gesture)
	tool.drag_ended.connect(end_gesture)
	_ctx.tray.add_child(tool)
	_tool = tool


func _on_scrubbed(point: Vector2) -> void:
	note_rub(point)


func _reveal_due() -> void:
	var count: int = _layers.size()
	if count == 0:
		return
	var ratio: float = _rub.progress()
	for index: int in range(count):
		if _gone[index]:
			continue
		if ratio + 0.0001 < float(index + 1) / float(count):
			continue
		_hide_layer(index)


func _hide_layer(index: int) -> void:
	_gone[index] = true
	_layers[index].modulate.a = 0.0
	_play_reveal(index)


func _play_reveal(index: int) -> void:
	if _ctx == null or _ctx.reactions == null or _ctx.step_def == null:
		return
	var batch: Array = []
	if not _ctx.step_def.on_hit_pose.is_empty():
		batch.append({"kind": ReactionExecutor.KIND_POSE, "id": _ctx.step_def.on_hit_pose})
	if not _ctx.step_def.on_hit_sfx_id.is_empty():
		batch.append({"kind": ReactionExecutor.KIND_SFX, "id": _ctx.step_def.on_hit_sfx_id})
	_ctx.reactions.execute(batch)
	LogSink.emit_to_diary("template.reveal", {"layer": index})
