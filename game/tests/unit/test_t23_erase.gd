# story: e13s04
extends GutTest
## SC-e13s04-P0-02, P0-03, P1-01. Erase completes once and the tray yields to the finger.


class HullStub:
	extends Control
	var hull: PackedVector2Array = PackedVector2Array()

	func scrub_hull_global() -> PackedVector2Array:
		return hull


var _recorder: ReactionRecorder = null
var _stub: HullStub = null


func test_erase_completes_once_and_stays_done() -> void:
	var tpl: RefCounted = _mount()
	_rub_cells(tpl, 15)
	assert_eq(int(tpl.call("completion_count")), 1, "SC-e13s04-P0-02")
	assert_almost_eq(float(tpl.call("progress")), 1.0, 0.001)
	_rub_cells(tpl, 16)
	assert_eq(int(tpl.call("completion_count")), 1, "SC-e13s04-P0-03")
	assert_almost_eq(float(tpl.call("progress")), 1.0, 0.001)


func test_the_finish_reaction_plays_exactly_once_over_two_full_passes() -> void:
	var tpl: RefCounted = _mount()
	_rub_cells(tpl, 16)
	_rub_cells(tpl, 16)
	assert_eq(_recorder.kinds(), ["pose", "sfx"], "B8 SC-e13s04-P0-02 one pose and one sound, never a second batch")


func test_a_finished_erase_stays_finished_when_the_target_moves() -> void:
	var tpl: RefCounted = _mount()
	_rub_cells(tpl, 15)
	_stub.hull = PackedVector2Array([Vector2(900, 900), Vector2(1300, 900), Vector2(1300, 1300), Vector2(900, 1300)])
	tpl.call("advance", 0.1)
	assert_almost_eq(
		float(tpl.call("progress")), 1.0, 0.001, "B8 SC-e13s04-P0-03 more time or a new hull never undoes it"
	)
	assert_eq(_recorder.kinds().size(), 2, "and the finish does not replay")


func _mount() -> RefCounted:
	var step: StepDef = StepDef.new()
	step.template_id = "t23_erase"
	step.mode = "clear"
	step.completion_threshold = 0.9
	step.on_hit_pose = "pleased"
	step.on_hit_sfx_id = "sfx_heart"
	var tpl: RefCounted = TemplateCatalog.instantiate("t23_erase")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.host = Node.new()
	add_child_autofree(ctx.host)
	_recorder = ReactionRecorder.new()
	ctx.reactions = ReactionExecutor.new()
	ctx.reactions.recorder = _recorder
	_stub = HullStub.new()
	_stub.hull = PackedVector2Array([Vector2(0, 0), Vector2(400, 0), Vector2(400, 400), Vector2(0, 400)])
	add_child_autofree(_stub)
	var nodes: PlayerNodeTable = PlayerNodeTable.new()
	nodes.register("scrub_target", _stub)
	ctx.nodes = nodes
	tpl.call("setup", ctx)
	tpl.call("begin_gesture")
	return tpl


func _rub_cells(tpl: RefCounted, limit: int) -> void:
	var filled: int = 0
	for col: int in range(4):
		for row: int in range(4):
			if filled >= limit:
				return
			tpl.call("note_rub", Vector2(50.0 + 100.0 * float(col), 50.0 + 100.0 * float(row)))
			filled += 1
