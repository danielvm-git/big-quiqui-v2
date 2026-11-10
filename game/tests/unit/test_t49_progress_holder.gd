# story: e16s04
extends GutTest


func test_holder_reads_runner_progress() -> void:
	var tpl: RefCounted = TemplateCatalog.instantiate("t49_progress_holder")
	var runner: StepRunner = StepRunner.new()
	runner.manual_step = true
	runner.reset(1)
	while runner.fsm.state != StepRunner.STATE_STEP:
		runner.advance(0.06)
	runner.report_template_progress(0.5)
	assert_almost_eq(runner.template_progress(), 0.5, 0.01)
	var host: Control = Control.new()
	add_child_autofree(host)
	var ctx: TemplateContext = TemplateContext.new()
	ctx.host = host
	ctx.runner = runner
	tpl.call("setup", ctx)
	tpl.call("advance", 0.1)
	assert_almost_eq(float(tpl.call("progress")), 0.5, 0.01)
