# story: e15s03
extends GutTest


func test_seeded_shuffle_is_stable() -> void:
	var a: RefCounted = _tpl(42)
	var b: RefCounted = _tpl(42)
	a.call("setup", _ctx(42))
	b.call("setup", _ctx(42))
	assert_eq(a.call("_shuffled"), b.call("_shuffled"))


func test_odd_card_count_rejects_at_load() -> void:
	var step: StepDef = StepDef.new()
	step.template_id = "t27_memory"
	step.item_ids = PackedStringArray(["ball", "ball", "plush"])
	assert_eq(StepParams.problem(step), "bad_count")


func _tpl(seed: int) -> RefCounted:
	return TemplateCatalog.instantiate("t27_memory")


func _ctx(seed: int) -> TemplateContext:
	var step: StepDef = StepDef.new()
	step.template_id = "t27_memory"
	step.spawn_seed = seed
	step.item_ids = PackedStringArray(["ball", "ball", "plush", "plush"])
	var ctx: TemplateContext = TemplateContext.new()
	ctx.step_def = step
	ctx.tray = Control.new()
	add_child_autofree(ctx.tray)
	return ctx
