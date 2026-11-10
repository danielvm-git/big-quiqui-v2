# story: e16s04
class_name ProgressHolderMount
extends RefCounted
## Draws t49 beside the active step. The holder is not the step, so its ratio is never reported.


static func mount(host: Control, runner: StepRunner, nodes: PlayerNodeTable) -> RefCounted:
	var holder: RefCounted = TemplateCatalog.instantiate("t49_progress_holder")
	if holder == null or not holder.has_method("setup"):
		return null
	var ctx: TemplateContext = TemplateContext.new()
	ctx.host = host
	ctx.runner = runner
	ctx.nodes = nodes
	holder.call("setup", ctx)
	return holder


static func tick(holder: RefCounted, delta: float) -> void:
	if holder != null and holder.has_method("advance"):
		holder.call("advance", delta)


static func clear(holder: RefCounted) -> void:
	if holder != null and holder.has_method("teardown"):
		holder.call("teardown")
