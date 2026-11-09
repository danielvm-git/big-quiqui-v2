# story: e13s01
# story: e13s04
class_name RubSurface
extends RefCounted
## What a rub template shares: the measured rub, the tool in the tray, the layers over the
## target and the quiet tray. It knows no room: ids and sounds come from the def.

var rub: RubPrimitive = RubPrimitive.new()
var tool: TouchDraggable = null
var layers: Array[Control] = []
var holding: bool = false

var _ctx: TemplateContext = null
var _owned: Array[Control] = []
var _claimed_alpha: Dictionary = {}


func bind(ctx: TemplateContext, on_scrubbed: Callable) -> void:
	_ctx = ctx
	rub.bind_target(TemplateKit.hull_target(ctx))
	_bind_loop()
	_claim_layers()
	_build_tool(on_scrubbed)


func begin_gesture() -> void:
	holding = true
	TemplateKit.hold_tray(_tray(), tool)
	if _ctx != null:
		rub.begin(_ctx.host)


func end_gesture() -> void:
	holding = false
	TemplateKit.release_tray(_tray())
	rub.release()


func note_rub(point: Vector2) -> bool:
	return rub.rub_at(point)


func fit_layers() -> void:
	var target: Control = TemplateKit.hull_target(_ctx)
	if target == null or not target.is_inside_tree():
		return
	for layer: Control in _owned:
		if is_instance_valid(layer):
			layer.global_position = target.global_position
			layer.size = target.size


func set_alpha(index: int, alpha: float) -> void:
	if index >= 0 and index < layers.size():
		layers[index].modulate.a = alpha


func alpha(index: int) -> float:
	if index < 0 or index >= layers.size():
		return 1.0
	return layers[index].modulate.a


func teardown() -> void:
	end_gesture()
	rub.release_all()
	if tool != null and is_instance_valid(tool):
		tool.queue_free()
	for layer: Control in layers:
		if _claimed_alpha.has(layer) and is_instance_valid(layer):
			layer.modulate.a = float(_claimed_alpha[layer])
	for layer: Control in _owned:
		if is_instance_valid(layer):
			layer.queue_free()
	layers.clear()
	_owned.clear()


func _tray() -> Control:
	return null if _ctx == null else _ctx.tray


func _bind_loop() -> void:
	if _ctx == null or _ctx.step_def == null:
		return
	var path: String = SfxCatalog.path(_ctx.step_def.loop_sfx_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	rub.set_loop(load(path) as AudioStream)


func _claim_layers() -> void:
	if _ctx == null or _ctx.step_def == null:
		return
	for layer_id: String in _ctx.step_def.item_ids:
		var layer: Control = _existing(layer_id)
		if layer == null:
			layer = _make_layer(layer_id)
		if layer != null:
			layers.append(layer)


func _existing(layer_id: String) -> Control:
	if _ctx.nodes == null:
		return null
	var found: Control = _ctx.nodes.resolve(layer_id)
	if found != null:
		_claimed_alpha[found] = found.modulate.a
	return found


func _make_layer(layer_id: String) -> Control:
	if _ctx.host == null:
		return null
	var layer: Control = _layer_node(layer_id)
	layer.name = layer_id
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_ctx.host.add_child(layer)
	if _ctx.rig != null and _ctx.rig.get_parent() == _ctx.host:
		_ctx.host.move_child(layer, _ctx.rig.get_index() + 1)
	_owned.append(layer)
	return layer


func _layer_node(layer_id: String) -> Control:
	if not ItemArt.has_art(layer_id):
		var wash: ColorRect = ColorRect.new()
		wash.color = Color(1.0, 1.0, 1.0, 0.8)
		return wash
	var art: TextureRect = ItemArt.icon(layer_id, 120.0)
	art.stretch_mode = TextureRect.STRETCH_SCALE
	return art


func _build_tool(on_scrubbed: Callable) -> void:
	if _ctx == null or _ctx.tray == null:
		return
	tool = TouchDraggable.new()
	tool.name = "RubTool"
	tool.custom_minimum_size = TouchDraggable.MIN_HIT_SIZE
	tool.size = TouchDraggable.MIN_HIT_SIZE
	tool.mode = TouchDraggable.Mode.CONTINUOUS_SCRUB
	tool.scrub_target = TemplateKit.hull_target(_ctx)
	tool.scrubbed.connect(on_scrubbed)
	tool.drag_started.connect(begin_gesture)
	tool.drag_ended.connect(end_gesture)
	tool.add_child(ItemArt.icon(_ctx.step_def.tool_id, TouchDraggable.MIN_HIT_SIZE.x))
	_ctx.tray.add_child(tool)
