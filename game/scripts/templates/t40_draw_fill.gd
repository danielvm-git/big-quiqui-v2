# story: e13s04
extends RefCounted
## Paint until the def threshold. Residue is allowed and the step stays done.

var _clean: CleaningRub = CleaningRub.new()


func setup(ctx: TemplateContext) -> void:
	_clean.bind(ctx, "leave")


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


func raw_coverage() -> float:
	return _clean.raw_coverage()


func looks_clean() -> bool:
	return _clean.looks_clean()


func layer_alpha() -> float:
	return _clean.layer_alpha()


func tool() -> TouchDraggable:
	return _clean.tool()
