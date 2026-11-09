# story: e12s05
extends GutTest
## SC-e12s05-P1-01..P1-04, P2-01..02


func _layer() -> HintLayer:
	var layer: HintLayer = HintLayer.new()
	var table: PlayerNodeTable = PlayerNodeTable.new()
	var from: Control = Control.new()
	var to: Control = Control.new()
	from.size = Vector2(120.0, 120.0)
	to.size = Vector2(120.0, 120.0)
	var host: Node = Node.new()
	add_child_autofree(host)
	host.add_child(from)
	host.add_child(to)
	var mgr: HintManager = HintManager.new()
	var hand: DragHint = DragHint.new()
	host.add_child(mgr)
	host.add_child(hand)
	table.register("from", from)
	table.register("to", to)
	layer.bind(mgr, hand, table)
	return layer


func test_silence_shows_one_hint_after_threshold() -> void:
	var layer: HintLayer = _layer()
	var step: StepDef = StepDef.new()
	step.hint_delay_sec = 0.3
	step.hint_from_id = "from"
	step.hint_to_id = "to"
	layer.begin_step(step)
	layer.advance(0.35)
	assert_true(layer.hint_was_shown())


func test_input_cancels_and_starts_cooldown() -> void:
	var layer: HintLayer = _layer()
	var step: StepDef = StepDef.new()
	step.hint_delay_sec = 0.2
	step.hint_from_id = "from"
	step.hint_to_id = "to"
	layer.begin_step(step)
	layer.advance(0.25)
	assert_true(layer.hint_was_shown())
	layer.note_input()
	assert_true(layer.manager.cooling_down())


func test_step_without_hint_runs() -> void:
	var layer: HintLayer = _layer()
	var step: StepDef = StepDef.new()
	layer.begin_step(step)
	layer.advance(5.0)
	assert_false(layer.hint_was_shown())


func test_bad_node_id_is_rejected() -> void:
	var table: PlayerNodeTable = PlayerNodeTable.new()
	assert_null(table.resolve("../secret"))
	assert_null(table.resolve("../../root"))


func test_drag_hint_ignores_mouse() -> void:
	var hand: DragHint = DragHint.new()
	add_child_autofree(hand)
	await get_tree().process_frame
	assert_eq(hand.mouse_filter, Control.MOUSE_FILTER_IGNORE)
