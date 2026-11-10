# story: e16s02
extends RefCounted
## Stack food for one guest through Give slots.

var _give: GiveReceivePrimitive = GiveReceivePrimitive.new()


func setup(ctx: TemplateContext) -> void:
	_give.setup(ctx)


func teardown() -> void:
	_give.teardown()


func advance(delta: float) -> void:
	_give.advance(delta)


func progress() -> float:
	return _give.progress()
