# story: e15s01
extends RefCounted
## Palette color, then Rub leave deposits on the canvas layer.

var _clean: CleaningRub = CleaningRub.new()
var _ctx: TemplateContext = null
var _palette: PackedStringArray = PackedStringArray()
var _active: String = ""
var _chips: Dictionary = {}


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_palette = ctx.step_def.item_ids if ctx != null and ctx.step_def != null else PackedStringArray()
	_active = _palette[0] if not _palette.is_empty() else ""
	var rub_ctx: TemplateContext = _rub_context(ctx)
	_clean.bind(rub_ctx, "leave")
	_show_canvas()
	_build_palette()
	_apply_tint()


func teardown() -> void:
	_clean.teardown()
	for chip: TapButton in _chips.values():
		if is_instance_valid(chip):
			chip.queue_free()
	_chips.clear()


func advance(_delta: float) -> void:
	_clean.advance()
	_apply_tint()


func progress() -> float:
	return _clean.progress()


func begin_gesture() -> void:
	_clean.begin_gesture()


func end_gesture() -> void:
	_clean.end_gesture()


func note_rub(point: Vector2) -> bool:
	return _clean.note_rub(point)


func select_color(paint_id: String) -> void:
	if not PaintCatalog.is_paint(paint_id):
		return
	_active = paint_id
	_apply_tint()


func active_color() -> String:
	return _active


func _rub_context(ctx: TemplateContext) -> TemplateContext:
	var step: StepDef = StepDef.new()
	step.template_id = "t44_paint"
	step.mode = "leave"
	step.completion_threshold = ctx.step_def.completion_threshold if ctx.step_def else 0.9
	step.item_ids = PackedStringArray([_canvas_id()])
	step.tool_id = _brush_id()
	var rub_ctx: TemplateContext = TemplateContext.new()
	rub_ctx.step_def = step
	rub_ctx.host = ctx.host
	rub_ctx.tray = ctx.tray
	rub_ctx.nodes = ctx.nodes
	rub_ctx.runner = ctx.runner
	rub_ctx.reactions = ctx.reactions
	rub_ctx.rig = ctx.rig
	return rub_ctx


func _canvas_id() -> String:
	if _ctx != null and _ctx.step_def != null and not _ctx.step_def.slot_ids.is_empty():
		return _ctx.step_def.slot_ids[0]
	return "color_canvas"


func _brush_id() -> String:
	if _ctx != null and _ctx.step_def != null and not _ctx.step_def.tool_id.is_empty():
		return _ctx.step_def.tool_id
	return "sponge"


func _build_palette() -> void:
	if _ctx == null or _ctx.tray == null:
		return
	for index: int in range(_palette.size()):
		var paint_id: String = _palette[index]
		var chip: TapButton = TemplateKit.tap_button(paint_id, Vector2(140.0 * float(index), 80.0))
		chip.tapped.connect(_on_chip.bind(paint_id))
		var swatch: ColorRect = ColorRect.new()
		swatch.color = PaintCatalog.color_of(paint_id)
		swatch.set_anchors_preset(Control.PRESET_FULL_RECT)
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(swatch)
		_ctx.tray.add_child(chip)
		_chips[paint_id] = chip


func _on_chip(paint_id: String) -> void:
	select_color(paint_id)
	TemplateKit.play_hit(_ctx, "template.paint_chip", {"color": paint_id})


func _apply_tint() -> void:
	var layer: Control = _canvas()
	if layer == null or _active.is_empty():
		return
	var tint: Color = PaintCatalog.color_of(_active)
	tint.a = maxf(_clean.layer_alpha(), 0.35)
	layer.modulate = tint


func _show_canvas() -> void:
	var layer: Control = _canvas()
	if layer == null:
		return
	layer.custom_minimum_size = Vector2(520.0, 400.0)
	layer.size = Vector2(520.0, 400.0)
	layer.position = Vector2(200.0, 180.0)
	layer.z_index = TemplateKit.LAYER_Z


func _canvas() -> Control:
	if _ctx == null or _ctx.host == null:
		return null
	var layer_id: String = _canvas_id()
	var found: Node = (_ctx.host as Node).find_child(layer_id, true, false)
	if found is Control and _ctx.nodes != null:
		_ctx.nodes.register(layer_id, found as Control)
	return found as Control
