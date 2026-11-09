# story: e13s04
extends RefCounted
## Clear a layer until the def threshold. Later rubbing cannot un-complete it.

var _clean: CleaningRub = CleaningRub.new()


func setup(ctx: TemplateContext) -> void:
	_clean.bind(ctx, "clear")


func teardown() -> void:
	_clean.teardown()


func advance(_delta: float) -> void:
	_clean.advance()


func progress() -> float:
	return _clean.progress()


func begin_gesture() -> void:
	_clean.begin_gesture()


func end_gesture() -> void:
	_clean.end_gesture()


func note_rub(point: Vector2) -> bool:
	return _clean.note_rub(point)


func completion_count() -> int:
	return _clean.completion_count()


func layer_alpha() -> float:
	return _clean.layer_alpha()


func tool() -> TouchDraggable:
	return _clean.tool()
