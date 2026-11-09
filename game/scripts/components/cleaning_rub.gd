# story: e13s04
class_name CleaningRub
extends RefCounted
## Shared measured rub. The threshold is data. A finished step stays finished.

var _rub: RubPrimitive = RubPrimitive.new()
var _ctx: TemplateContext = null
var _latched: bool = false
var _completions: int = 0
var _holding: bool = false
var _tray_taps: int = 0


func bind(ctx: TemplateContext, mode: String) -> void:
	_ctx = ctx
	_rub.mode = mode
	_rub.bind_target(_target())


func begin_gesture() -> void:
	_holding = true
	if _ctx != null and _ctx.host != null:
		_rub.begin(_ctx.host)


func end_gesture() -> void:
	_holding = false
	_rub.release()


func note_rub(point: Vector2) -> bool:
	var hit: bool = _rub.rub_at(point)
	_consider()
	return hit


func progress() -> float:
	_consider()
	if _latched:
		return 1.0
	return clampf(_rub.progress() / _threshold(), 0.0, 1.0)


func raw_coverage() -> float:
	return _rub.progress()


func latched() -> bool:
	return _latched


func completion_count() -> int:
	return _completions


func looks_clean() -> bool:
	return _latched


func tray_accepts() -> bool:
	return not _holding


func tray_taps() -> int:
	return _tray_taps


func note_tray(event: InputEvent) -> void:
	if event is InputEventMouse and event.device == -1:
		return
	if not tray_accepts():
		return
	if event is InputEventScreenTouch and event.pressed:
		_tray_taps += 1


func claims_completion() -> bool:
	return false


func _consider() -> void:
	if _latched:
		return
	if _rub.progress() + 0.0001 < _threshold():
		return
	_latched = true
	_completions = 1


func _threshold() -> float:
	if _ctx == null or _ctx.step_def == null:
		return 0.9
	if _ctx.step_def.completion_threshold <= 0.0:
		return 0.9
	return _ctx.step_def.completion_threshold


func _target() -> Control:
	if _ctx != null and _ctx.nodes != null:
		var named: Control = _ctx.nodes.resolve("scrub_target")
		if named != null:
			return named
	if _ctx == null:
		return null
	return _ctx.rig
