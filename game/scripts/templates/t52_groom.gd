# story: e16s03
extends RefCounted
## Comb, dry, then trim — trim locked until the first two report progress.

const STATE_COMB: String = "COMB"
const STATE_DRY: String = "DRY"
const STATE_TRIM: String = "TRIM"
const LEGAL: Dictionary = {
	STATE_COMB: [STATE_DRY],
	STATE_DRY: [STATE_TRIM],
	STATE_TRIM: [],
}

var _fsm: Fsm = Fsm.new(STATE_COMB, LEGAL, {})
var _rub: CleaningRub = CleaningRub.new()
var _ctx: TemplateContext = null


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_bind_rub()


func teardown() -> void:
	_rub.teardown()


func advance(_delta: float) -> void:
	_rub.advance()
	_check_phase()


func progress() -> float:
	var base: int = 0
	if _fsm.state == STATE_DRY:
		base = 1
	elif _fsm.state == STATE_TRIM:
		base = 2
	if _fsm.state == STATE_TRIM and _rub.progress() >= 0.99:
		return 1.0
	var slice: float = 1.0 if _rub.progress() >= 0.99 else 0.0
	return clampf((float(base) + slice) / 3.0, 0.0, 1.0)


func begin_gesture() -> void:
	_rub.begin_gesture()


func end_gesture() -> void:
	_rub.end_gesture()


func note_rub(point: Vector2) -> bool:
	return _rub.note_rub(point)


func _bind_rub() -> void:
	var step: StepDef = StepDef.new()
	step.item_ids = PackedStringArray(["hair_layer"])
	step.mode = "leave"
	step.completion_threshold = 0.6
	var rub_ctx: TemplateContext = TemplateContext.new()
	rub_ctx.step_def = step
	rub_ctx.host = _ctx.host
	rub_ctx.tray = _ctx.tray
	rub_ctx.nodes = _ctx.nodes
	rub_ctx.runner = _ctx.runner
	rub_ctx.reactions = _ctx.reactions
	rub_ctx.rig = _ctx.rig
	_rub.bind(rub_ctx, "leave")


func _check_phase() -> void:
	if _rub.progress() < 0.99 or _fsm.state == STATE_TRIM:
		return
	var nxt: String = STATE_DRY if _fsm.state == STATE_COMB else STATE_TRIM
	_fsm.transition_to(nxt)
	_rub.teardown()
	_bind_rub()
