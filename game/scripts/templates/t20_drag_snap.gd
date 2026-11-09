# story: e12s06
extends RefCounted
## Drag-to-receiver with repeat — no room nouns; reads only StepDef.

var _primitive: GiveReceivePrimitive = GiveReceivePrimitive.new()


func setup(ctx: TemplateContext) -> void:
	_primitive.setup(ctx)


func teardown() -> void:
	_primitive.teardown()


func advance(delta: float) -> void:
	_primitive.advance(delta)


func progress() -> float:
	return _primitive.progress()


func active_draggables() -> Array[TouchDraggable]:
	return _primitive.active_draggables()
