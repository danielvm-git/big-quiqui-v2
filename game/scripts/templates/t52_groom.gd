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
var _phase_done: Dictionary = {STATE_COMB: false, STATE_DRY: false, STATE_TRIM: false}


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_bind_rub()


func teardown() -> void:
	_rub.teardown()


func advance(_delta: float) -> void:
	_rub.advance()
	_check_phase()


func progress() -> float:
	var done: int = 0
	for key: String in _phase_done.keys():
		done += 1 if _phase_done[key] else 0
	return clampf(float(done) / 3.0, 0.0, 1.0)


func begin_gesture() -> void:
	if _fsm.state == STATE_TRIM and not _phase_done[STATE_DRY]:
		return
	_rub.begin_gesture()


func end_gesture() -> void:
	_rub.end_gesture()


func note_rub(point: Vector2) -> bool:
	if _fsm.state == STATE_TRIM and not _phase_done[STATE_DRY]:
		return false
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
	if _rub.progress() < 0.99:
		return
	if _fsm.state == STATE_COMB and not _phase_done[STATE_COMB]:
		_phase_done[STATE_COMB] = true
		_fsm.transition_to(STATE_DRY)
		return
	if _fsm.state == STATE_DRY and not _phase_done[STATE_DRY]:
		_phase_done[STATE_DRY] = true
		_fsm.transition_to(STATE_TRIM)
		return
	if _fsm.state == STATE_TRIM:
		_phase_done[STATE_TRIM] = true
