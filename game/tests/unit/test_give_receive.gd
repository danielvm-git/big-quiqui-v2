# story: e12s04
extends GutTest
## SC-e12s04-P0-01..03, P1-02 — Give→Receive primitive modes.

const FOOD_SCRIPT: String = "res://scripts/components/touch_draggable.gd"


func _ctx(mode: String, ids: PackedStringArray, repeat: int = 1) -> TemplateContext:
	var step: StepDef = StepDef.new()
	step.template_id = "t20_drag_snap"
	step.mode = mode
	step.item_ids = ids
	step.repeat_count = repeat
	step.receiver_id = "mouth"
	var tray: Control = Control.new()
	tray.size = Vector2(640.0, 200.0)
	add_child_autofree(tray)
	var mouth: Control = Control.new()
	mouth.size = Vector2(140.0, 140.0)
	mouth.position = Vector2(400.0, 80.0)
	tray.add_child(mouth)
	var nodes: PlayerNodeTable = PlayerNodeTable.new()
	nodes.register("mouth", mouth)
	var runner: StepRunner = StepRunner.new()
	runner.manual_step = true
	var ctx: TemplateContext = TemplateContext.new()
	ctx.tray = tray
	ctx.runner = runner
	ctx.nodes = nodes
	ctx.step_def = step
	ctx.reactions = ReactionExecutor.new()
	return ctx


func test_single_consumes_on_receiver() -> void:
	var ctx: TemplateContext = _ctx("single", PackedStringArray(["apple"]), 1)
	var prim: GiveReceivePrimitive = GiveReceivePrimitive.new()
	prim.setup(ctx)
	assert_eq(prim.active_draggables().size(), 1)
	var item: TouchDraggable = prim.active_draggables()[0]
	item.drop_target = ctx.nodes.resolve("mouth")
	item.global_position = ctx.nodes.resolve("mouth").global_position
	item.consumed.emit()
	assert_almost_eq(prim.progress(), 1.0, 0.001)


func test_miss_leaves_item_enabled() -> void:
	var ctx: TemplateContext = _ctx("single", PackedStringArray(["apple"]), 1)
	var prim: GiveReceivePrimitive = GiveReceivePrimitive.new()
	prim.setup(ctx)
	var item: TouchDraggable = prim.active_draggables()[0]
	item.drag_ended.emit()
	assert_true(item.enabled)
	assert_eq(item.state_id(), TouchDraggable.STATE_REST)


func test_slots_accepts_one_payload_per_slot() -> void:
	var ctx: TemplateContext = _ctx("slots", PackedStringArray(["apple", "carrot"]), 2)
	var prim: GiveReceivePrimitive = GiveReceivePrimitive.new()
	prim.setup(ctx)
	assert_eq(prim.active_draggables().size(), 2)


func test_exactly_one_draggable_holds_finger() -> void:
	TouchDraggable._holder = null
	var ctx: TemplateContext = _ctx("single", PackedStringArray(["apple"]), 1)
	var prim: GiveReceivePrimitive = GiveReceivePrimitive.new()
	prim.setup(ctx)
	var item: TouchDraggable = prim.active_draggables()[0]
	var events: Array[InputEvent] = TouchSim.drag_events(item, ctx.nodes.resolve("mouth").global_position, 4, false)
	item._gui_input(events[0])
	assert_eq(TouchDraggable._holder, item)
