# story: e16s04
extends RefCounted
## Shows runner progress; does not complete the step alone.

var _ctx: TemplateContext = null
var _bar: ProgressBar = null


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_bar = ProgressBar.new()
	_bar.name = "ProgressHolder"
	_bar.custom_minimum_size = Vector2(400.0, 40.0)
	_bar.position = Vector2(260.0, 80.0)
	_bar.show_percentage = false
	if ctx.host != null:
		(ctx.host as Control).add_child(_bar)


func teardown() -> void:
	if _bar != null and is_instance_valid(_bar):
		_bar.queue_free()
	_bar = null


func advance(_delta: float) -> void:
	_sync()


func progress() -> float:
	if _ctx != null and _ctx.runner != null:
		return _ctx.runner.template_progress()
	return 0.0


func _sync() -> void:
	if _bar == null or _ctx == null or _ctx.runner == null:
		return
	_bar.value = _ctx.runner.template_progress() * 100.0
