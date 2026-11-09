# story: e12s02
# story: e12s03
extends RefCounted
## Placeholder template: completes when param_int ticks to zero.

var _ctx: TemplateContext = null
var _left: int = 0


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_left = maxi(ctx.step_def.param_int, 1)


func teardown() -> void:
	_ctx = null


func advance(_delta: float) -> void:
	if _left <= 0:
		return
	_left -= 1
	if _left <= 0 and _ctx != null and _ctx.runner != null:
		_ctx.runner.report_template_progress(1.0)


func progress() -> float:
	return 1.0 if _left <= 0 else 0.0
