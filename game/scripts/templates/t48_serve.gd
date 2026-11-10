# story: e16s02
extends RefCounted
## Stack food for one guest through Give slots.

var _give: GiveReceivePrimitive = GiveReceivePrimitive.new()


func setup(ctx: TemplateContext) -> void:
	_place_guest(ctx)
	_give.setup(ctx)


func teardown() -> void:
	_give.teardown()


func advance(delta: float) -> void:
	_give.advance(delta)


func progress() -> float:
	return _give.progress()


func active_draggables() -> Array[TouchDraggable]:
	return _give.active_draggables()


func _place_guest(ctx: TemplateContext) -> void:
	if ctx == null or ctx.host == null or ctx.step_def == null or ctx.nodes == null:
		return
	var id: String = ctx.step_def.receiver_id
	if id.is_empty() or ctx.nodes.resolve(id) != null:
		return
	var guest: Control = Control.new()
	guest.name = id
	guest.z_index = TemplateKit.SURFACE_Z
	guest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	guest.custom_minimum_size = Vector2(160.0, 160.0)
	guest.size = Vector2(160.0, 160.0)
	guest.position = Vector2(720.0, 420.0)
	guest.add_child(ItemArt.icon("teddy", 160.0))
	(ctx.host as Control).add_child(guest)
	ctx.nodes.register(id, guest)
