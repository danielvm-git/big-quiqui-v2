# story: e14s03
extends GutTest
## SC-e14s03-P0-04, P1-02 — miss replays, one payout, registry id.

const ROUNDS: int = 3


func before_each() -> void:
	TestReset.reset_all()


func test_the_template_id_is_in_the_closed_registry() -> void:
	assert_true(TemplateCatalog.is_known("t_rhythm_pose"), "SC-e14s03-P1-02")
	assert_false(TemplateCatalog.script_path("t_rhythm_pose").contains("res://scenes/"))


func test_a_miss_replays_and_three_hits_pay_once() -> void:
	var tpl: RefCounted = _mount()
	var progress: Node = get_node("/root/ProgressManager")
	assert_eq(int(progress.call("get_coins")), 0)
	tpl.call("press", "left")
	for _round: int in range(ROUNDS):
		var pose: String = str(tpl.call("pose_id"))
		tpl.call("press", pose)
	var coins: int = int(progress.call("get_coins"))
	assert_gt(coins, 0, "SC-e14s03-P0-04 one payout")
	assert_almost_eq(float(tpl.call("progress")), 1.0, 0.001)
	tpl.call("press", str(tpl.call("pose_id")))
	assert_eq(int(progress.call("get_coins")), coins, "no second payout")


func _mount() -> RefCounted:
	var step: StepDef = StepDef.new()
	step.template_id = "t_rhythm_pose"
	step.item_ids = PackedStringArray(["left", "centre", "right"])
	var tray: Control = Control.new()
	tray.size = Vector2(900.0, 160.0)
	add_child_autofree(tray)
	var tpl: RefCounted = TemplateCatalog.instantiate("t_rhythm_pose")
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.tray = tray
	tpl.call("setup", ctx)
	return tpl
