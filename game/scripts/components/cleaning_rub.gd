# story: e13s04
class_name CleaningRub
extends RefCounted
## Shared measured rub for t23 and t40. The threshold is data. A finished step stays finished.
## Mode `leave` fills the layer as the ratio grows; `clear` fades it out. Both are data, not branches.

var _surface: RubSurface = RubSurface.new()
var _ctx: TemplateContext = null
var _latched: bool = false


## `default_mode` is `clear` or `leave`; a def that names one of them overrides the template.
func bind(ctx: TemplateContext, default_mode: String) -> void:
	_ctx = ctx
	_surface.bind(ctx, _on_scrubbed, default_mode)
	_show(0.0)


func teardown() -> void:
	_surface.teardown()


func begin_gesture() -> void:
	_surface.begin_gesture()


func end_gesture() -> void:
	_surface.end_gesture()


func note_rub(point: Vector2) -> bool:
	var hit: bool = _surface.note_rub(point)
	_consider()
	return hit


func advance() -> void:
	_surface.fit_layers()
	_consider()


func progress() -> float:
	_consider()
	if _latched:
		return 1.0
	return clampf(_surface.rub.progress() / _threshold(), 0.0, 1.0)


func raw_coverage() -> float:
	return _surface.rub.progress()


func latched() -> bool:
	return _latched


func completion_count() -> int:
	return 1 if _latched else 0


func looks_clean() -> bool:
	return _latched


func tool() -> TouchDraggable:
	return _surface.tool


func layer_alpha() -> float:
	return _surface.alpha(0)


func _on_scrubbed(point: Vector2) -> void:
	note_rub(point)


func _consider() -> void:
	if _latched:
		return
	_show(clampf(_surface.rub.progress() / _threshold(), 0.0, 1.0))
	if _surface.rub.progress() + 0.0001 < _threshold():
		return
	_latched = true
	_show(1.0)
	TemplateKit.play_hit(_ctx, "template.clean", {"done": 1})


func _show(ratio: float) -> void:
	_surface.set_alpha(0, ratio if _surface.mode == "leave" else 1.0 - ratio)


func _threshold() -> float:
	if _ctx == null or _ctx.step_def == null or _ctx.step_def.completion_threshold <= 0.0:
		return 0.9
	return _ctx.step_def.completion_threshold
