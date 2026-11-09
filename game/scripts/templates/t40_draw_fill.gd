# story: e13s04
extends RefCounted
## Paint until the def threshold. Residue is allowed and the step stays done.

var _clean: CleaningRub = CleaningRub.new()


func setup(ctx: TemplateContext) -> void:
	_clean.bind(ctx, _mode(ctx, "leave"))


func teardown() -> void:
	_clean.end_gesture()


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	return _clean.progress()


func begin_gesture() -> void:
	_clean.begin_gesture()


func end_gesture() -> void:
	_clean.end_gesture()


func note_rub(point: Vector2) -> bool:
	return _clean.note_rub(point)


func note_tray(event: InputEvent) -> void:
	_clean.note_tray(event)


func raw_coverage() -> float:
	return _clean.raw_coverage()


func looks_clean() -> bool:
	return _clean.looks_clean()


func tray_taps() -> int:
	return _clean.tray_taps()


func claims_completion() -> bool:
	return false


func _mode(ctx: TemplateContext, fallback: String) -> String:
	if ctx == null or ctx.step_def == null or ctx.step_def.mode.is_empty():
		return fallback
	return ctx.step_def.mode
