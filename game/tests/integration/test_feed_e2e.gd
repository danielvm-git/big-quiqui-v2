# story: e03s04
extends FeedE2eTestCase
## SC-E03-P0-22..P1-26: the whole FEED journey from the Casa door and back, with the
## real autoloads.


func test_full_journey_at_16_9() -> void:
	await _assert_full_journey(GeometryOracle.DESKTOP_16_9)


func test_full_journey_at_4_3() -> void:
	await _assert_full_journey(GeometryOracle.IPAD_4_3)


func test_full_journey_at_the_real_4_3_canvas() -> void:
	await _assert_full_journey(GeometryOracle.CANVAS_4_3)


func _assert_full_journey(size: Vector2i) -> void:
	await _open_casa(size)
	var door: TapButton = (stage as CasaScene).door(CareSteps.FEED)
	_deliver(door, TouchSim.tap_events(door, true))
	assert_eq(door.taps, 1, "one tap on the door")
	assert_eq(requested, [COZINHA_PATH], "the door asks for the kitchen")

	await _follow_the_request()
	assert_true(stage is KitchenScene, "the kitchen is on stage")
	assert_eq(clm.state_id(), "FEED", "entering from IDLE begins the step")
	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, size, GeometryOracle.STEP_ROOM_SPEC)
	assert_true(findings.is_empty(), "%s: %s" % [size, oracle.summary()])

	for index: int in range(FOOD_COUNT):
		_feed(index)
		assert_eq(_kitchen().bites, index + 1, "%s: one drag, one bite" % size)
		_finish_reactions()

	assert_eq(clm.state_id(), "BATH", "BATH is next")
	assert_eq(clm.completed_steps(), 1, "the first dot fills")
	assert_eq(requested, [COZINHA_PATH, CASA_PATH], "the Casa is requested exactly once")
	assert_eq(refused_requests, [], "nothing asked twice")

	await _follow_the_request()
	assert_true(stage is CasaScene, "back at the Casa")
	assert_eq(clm.next_step(), "BATH", "the hub now asks for the bath")
	assert_eq(sm.current_scene, CASA_PATH)
	assert_false(sm.is_busy())
	assert_eq(sm.production_swap_path, "", "T-E03-04")
	_assert_probes_clean()


func test_replaying_a_drag_on_a_consumed_food_changes_nothing() -> void:
	await _open_casa()
	await _enter_kitchen()
	var sfx_before: int = am.sfx_cursor()
	var gesture: Array[InputEvent] = _feed(0)
	_replay(0, gesture)

	assert_eq(_kitchen().bites, 1, "while she chews")
	assert_eq(_kitchen().fsm.state, "CHEWING")
	_finish_reactions()
	_replay(0, gesture)

	assert_eq(_kitchen().bites, 1, "and once she is ready again")
	assert_eq(_kitchen().fsm.state, "READY")
	assert_false(_kitchen().food(0).visible, "the eaten food stays gone")
	assert_eq(am.sfx_cursor(), sfx_before + 1, "one nhami")
	assert_eq(_diary_count("kitchen.bite"), 1)
	_assert_probes_clean()


func test_replaying_the_last_bite_credits_feed_once() -> void:
	await _open_casa()
	await _enter_kitchen()
	var sfx_before: int = am.sfx_cursor()
	_feed(0)
	_finish_reactions()
	_feed(1)
	_finish_reactions()
	var gesture: Array[InputEvent] = _feed(2)
	_replay(2, gesture)
	_finish_reactions()
	_replay(2, gesture)
	_finish_reactions()

	assert_eq(_kitchen().bites, 3)
	assert_eq(am.sfx_cursor(), sfx_before + 3, "one nhami per bite")
	assert_eq(_diary_count("care.complete"), 1, "one care.complete")
	assert_eq(loop_probe.transitions, ["IDLE->FEED", "FEED->BATH"])
	assert_eq(requested, [COZINHA_PATH, CASA_PATH])
	assert_eq(refused_requests, [])
	_assert_probes_clean()


func test_a_miss_returns_the_food_and_the_same_food_can_then_be_eaten() -> void:
	await _open_casa()
	await _enter_kitchen()
	var food: TouchDraggable = _kitchen().food(0)
	var rest_position: Vector2 = food.position
	_deliver(food, TouchSim.drag_events(food, AWAY_FROM_MOUTH))

	assert_eq(food.state_id(), "RETURNING")
	assert_eq(_kitchen().bites, 0, "no bite")
	assert_eq(_kitchen().fsm.state, "READY")
	assert_eq(clm.state_id(), "FEED", "no care transition")
	food.advance(TouchDraggable.RETURN_SEC)
	assert_eq(food.state_id(), "REST")
	assert_true(food.position.is_equal_approx(rest_position), "back in its place")

	_feed(0)
	assert_eq(_kitchen().bites, 1)
	assert_eq(food.state_id(), "CONSUMED")
	assert_eq(loop_probe.transitions, ["IDLE->FEED"])
	_assert_probes_clean()


func test_a_second_finger_on_another_food_during_a_drag_moves_nothing() -> void:
	await _open_casa()
	await _enter_kitchen()
	var mouth: Vector2 = _kitchen().rig.mouth_global_center()
	var held: TouchDraggable = _kitchen().food(0)
	var other: TouchDraggable = _kitchen().food(1)
	var other_at: Vector2 = other.global_position
	var gesture: Array[InputEvent] = TouchSim.drag_events(held, mouth)
	var halfway: int = gesture.size() / 2

	_deliver(held, gesture.slice(0, halfway))
	var held_at: Vector2 = held.global_position
	_deliver(other, _as_finger(TouchSim.drag_events(other, mouth), SECOND_FINGER))

	assert_eq(other.state_id(), "REST", "the second finger picks up nothing")
	assert_eq(other.global_position, other_at)
	assert_eq(held.state_id(), "DRAGGING", "the first finger still holds its food")
	assert_eq(held.global_position, held_at)
	assert_eq(_kitchen().bites, 0)

	_deliver(held, gesture.slice(halfway))
	assert_eq(held.state_id(), "CONSUMED", "the first finger finishes its drag")
	assert_eq(other.state_id(), "REST")
	assert_eq(_kitchen().bites, 1)
	_assert_probes_clean()


func test_feeding_again_after_feed_keeps_the_loop_in_bath() -> void:
	await _open_casa()
	await _enter_kitchen()
	_feed_all()
	await _follow_the_request()
	var transitions_after_first_visit: Array[String] = loop_probe.transitions.duplicate()

	await _enter_kitchen()
	assert_true(stage is KitchenScene, "the door stays open after FEED")
	assert_eq(clm.state_id(), "BATH", "entering credits nothing")
	_feed_all()
	assert_eq(_kitchen().bites, 3, "she still eats")
	assert_eq(clm.state_id(), "BATH")
	assert_eq(clm.completed_steps(), 1)

	await _follow_the_request()
	assert_true(stage is CasaScene)
	assert_eq(loop_probe.transitions, transitions_after_first_visit, "the second visit walks nothing")
	assert_eq(requested, [COZINHA_PATH, CASA_PATH, COZINHA_PATH, CASA_PATH])
	assert_eq(refused_requests, [])
	assert_eq(kitchen_probes.size(), 2, "two visits, two machines")
	_assert_probes_clean()


func test_the_journey_leaves_a_clean_diary() -> void:
	await _open_casa()
	await _enter_kitchen()
	_feed_all()
	await _follow_the_request()
	await _enter_kitchen()
	_feed_all()
	await _follow_the_request()

	assert_eq(_diary_count("kitchen.bite"), 6, "the diary saw both visits")
	assert_eq(_diary_count("fsm.illegal_transition"), 0)
	assert_eq(_diary_count("fsm.stale_transition"), 0)
	assert_eq(_diary_count("fsm.dwell_timeout"), 0)
	_assert_probes_clean()
	var lines: PackedStringArray = _diary_lines()
	assert_eq(_audit_exit_code(lines), 0, "logs.sh audit passes every line")
	lines.append(BAD_DIARY_LINE)
	assert_ne(_audit_exit_code(lines), 0, "the same audit fails a bad line")
