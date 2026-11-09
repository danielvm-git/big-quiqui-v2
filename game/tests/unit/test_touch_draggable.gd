# story: e03s01
extends TouchDraggableTestCase
## The gesture (ADR-004): pick up, follow, consume once, or fly home, and what it
## writes to the diary (T-E03-06).

# ── contract ─────────────────────────────────────────────────────────────────


func test_a_fresh_food_rests_with_the_contract_defaults() -> void:
	var fresh: TouchDraggable = TouchDraggable.new()
	autofree(fresh)

	assert_eq(fresh.state_id(), "REST")
	assert_eq(fresh.fsm.max_dwell_sec.get("RETURNING"), 1.0)
	assert_eq(fresh.mode, TouchDraggable.Mode.CONSUME_ON_DROP)
	assert_null(fresh.drop_target)
	assert_eq(fresh.drop_margin, 0.0)
	assert_true(fresh.enabled)


func test_the_hit_box_is_enforced_on_ready() -> void:
	var small: TouchDraggable = TouchDraggable.new()
	small.size = Vector2(40.0, 40.0)
	add_child_autofree(small)

	assert_true(small.size.x >= 120.0 and small.size.y >= 120.0, "grew to the minimum")
	assert_eq(small.mouse_filter, Control.MOUSE_FILTER_STOP)
	assert_eq(food.size, FOOD_SIZE, "a larger box is left alone")


# ── SC-E03-P0-01 drag and consume once under echo ────────────────────────────


func test_drag_and_consume_fires_once_under_mouse_echo() -> void:
	_deliver(food, TouchSim.drag_events(food, ON_TARGET, 12, true))

	assert_eq(food.state_id(), "CONSUMED")
	assert_eq(consumed, 1, "one drop, one consumed")
	assert_eq(started, 1, "one press, one drag_started")
	assert_eq(ended, 1, "one release, one drag_ended")
	assert_eq(moved_points.size(), 12, "the echo adds no motion")
	assert_eq(probe.transitions, ["REST->DRAGGING", "DRAGGING->CONSUMED"] as Array[String])
	assert_true(probe.is_clean(), probe.summary())


func test_state_is_already_consumed_when_drag_ended_fires() -> void:
	var seen: Array[String] = []
	food.drag_ended.connect(func() -> void: seen.append(food.state_id()))

	_deliver(food, TouchSim.drag_events(food, ON_TARGET))

	assert_eq(seen, ["CONSUMED"] as Array[String], "a listener can tell a bite from a miss")


func test_consumed_is_terminal_when_the_gesture_is_replayed() -> void:
	var events: Array[InputEvent] = TouchSim.drag_events(food, ON_TARGET)
	_deliver(food, events)
	var parked: Vector2 = food.global_position

	_deliver(food, events)
	food.advance(1.0)

	assert_eq(food.state_id(), "CONSUMED")
	assert_eq(consumed, 1)
	assert_eq(started, 1)
	assert_eq(food.global_position, parked, "later events move nothing")
	assert_true(probe.is_clean(), probe.summary())


func test_the_drop_margin_grows_the_target_up_to_its_edge() -> void:
	food.drop_margin = 120.0
	var edge_x: float = TARGET_POS.x + TARGET_SIZE.x + 120.0

	_deliver(food, TouchSim.drag_events(food, Vector2(edge_x + 1.0, 500.0)))
	assert_eq(food.state_id(), "RETURNING", "just outside the margin misses")
	food.advance(TouchDraggable.RETURN_SEC)

	_deliver(food, TouchSim.drag_events(food, Vector2(edge_x - 1.0, 500.0)))
	assert_eq(food.state_id(), "CONSUMED", "just inside the margin hits")


# ── pick up and follow ───────────────────────────────────────────────────────


func test_a_press_starts_the_drag_without_moving_the_art() -> void:
	_send(food, _touch(HOME + Vector2(10.0, 20.0), true))

	assert_eq(food.state_id(), "DRAGGING")
	assert_eq(started, 1)
	assert_eq(food.global_position, HOME, "the art does not jump under the finger")


func test_each_move_keeps_the_grab_offset() -> void:
	var grab: Vector2 = Vector2(10.0, 20.0)
	_send(food, _touch(HOME + grab, true))

	for point: Vector2 in [Vector2(300.0, 300.0), Vector2(700.0, 150.0), Vector2(40.0, 900.0)]:
		_send(food, _drag(point))
		_assert_near(food.global_position, point - grab, "offset held")
		_assert_near(moved_points.back(), point, "drag_moved reports the finger")


# ── SC-E03-P0-03 miss returns home within the dwell ──────────────────────────


func test_a_miss_flies_home_in_return_sec_then_rests() -> void:
	_deliver(food, TouchSim.drag_events(food, MISS))
	var dropped_at: Vector2 = food.position

	assert_eq(food.state_id(), "RETURNING")
	assert_eq(consumed, 0)

	food.advance(TouchDraggable.RETURN_SEC * 0.5)
	assert_eq(food.state_id(), "RETURNING")
	_assert_near(food.position, dropped_at.lerp(HOME, 0.5), "halfway home")

	food.advance(TouchDraggable.RETURN_SEC * 0.5)
	assert_eq(food.state_id(), "REST")
	assert_eq(food.position, HOME)
	assert_lt(TouchDraggable.RETURN_SEC, float(food.fsm.max_dwell_sec["RETURNING"]))
	assert_eq(probe.transitions, ["REST->DRAGGING", "DRAGGING->RETURNING", "RETURNING->REST"] as Array[String])
	assert_true(probe.is_clean(), probe.summary())


func test_process_drives_the_return_unless_manual_step_is_set() -> void:
	_deliver(food, TouchSim.drag_events(food, MISS))
	var dropped_at: Vector2 = food.position

	food._process(0.1)
	assert_eq(food.position, dropped_at, "manual_step: only advance() moves the machine")

	food.manual_step = false
	food._process(TouchDraggable.RETURN_SEC)
	assert_eq(food.state_id(), "REST")


func test_a_press_while_returning_grabs_it_and_keeps_the_original_home() -> void:
	_deliver(food, TouchSim.drag_events(food, MISS))
	food.advance(TouchDraggable.RETURN_SEC * 0.5)
	var midair: Vector2 = food.global_position

	_send(food, _touch(midair + Vector2(5.0, 5.0), true))
	assert_eq(food.state_id(), "DRAGGING")
	assert_eq(food.global_position, midair, "no jump on the regrab")

	_send(food, _drag(MISS))
	_send(food, _touch(MISS, false))
	food.advance(TouchDraggable.RETURN_SEC)

	assert_eq(food.state_id(), "REST")
	assert_eq(food.position, HOME, "home is not the midair point")
	assert_true(probe.is_clean(), probe.summary())


func test_the_dwell_watchdog_snaps_a_stuck_return_home() -> void:
	_deliver(food, TouchSim.drag_events(food, MISS))
	food.fsm.max_dwell_sec = {"RETURNING": 0.0}

	food.advance(0.001)

	assert_eq(probe.timeouts, ["RETURNING"] as Array[String])
	assert_eq(food.state_id(), "REST")
	assert_eq(food.position, HOME)


func test_without_a_target_a_drop_returns_home() -> void:
	food.drop_target = null
	_deliver(food, TouchSim.drag_events(food, ON_TARGET))

	assert_eq(food.state_id(), "RETURNING")
	assert_eq(consumed, 0)


func test_a_freed_target_is_a_miss_not_a_crash() -> void:
	target.free()
	_deliver(food, TouchSim.drag_events(food, ON_TARGET))

	assert_eq(food.state_id(), "RETURNING")
	assert_eq(consumed, 0)


## CONTINUOUS_SCRUB became live in e04s01, so only the two modes still unbuilt keep
## the e03 placeholder behaviour. The scrub's own gesture is covered in
## `test_touch_draggable_scrub.gd`.
func test_unbuilt_modes_return_home_even_on_the_target() -> void:
	for mode: TouchDraggable.Mode in [
		TouchDraggable.Mode.SNAP_TO_SLOT,
		TouchDraggable.Mode.FREE_PLACEMENT,
	]:
		food.mode = mode
		_deliver(food, TouchSim.drag_events(food, ON_TARGET))
		assert_eq(food.state_id(), "RETURNING", "mode %d" % mode)
		food.advance(TouchDraggable.RETURN_SEC)
	assert_eq(consumed, 0)


# ── T-E03-06 diary ───────────────────────────────────────────────────────────


func test_the_diary_gets_no_line_per_motion() -> void:
	_send(food, _touch(_center(food), true))
	var before: int = _diary().call("write_count")

	for step: int in range(30):
		_send(food, _drag(HOME + Vector2(float(step), float(step))))

	assert_eq(_diary().call("write_count"), before, "T-E03-06")


func test_a_press_writes_an_id_shaped_start() -> void:
	_send(food, _touch(_center(food), true))

	assert_eq(_last_line().get("ev"), "drag.start")
	assert_eq(_last_line().get("item"), "carrot")


func test_a_consume_writes_the_drop_and_the_consume() -> void:
	_deliver(food, TouchSim.drag_events(food, ON_TARGET))

	var lines: PackedStringArray = FileAccess.get_file_as_string(str(_diary().get("log_path"))).strip_edges().split(
		"\n"
	)
	var drop: Dictionary = JSON.parse_string(lines[lines.size() - 2]) as Dictionary
	var consume: Dictionary = JSON.parse_string(lines[lines.size() - 1]) as Dictionary
	assert_eq(drop.get("ev"), "drag.drop")
	assert_eq(drop.get("outcome"), "consumed")
	assert_eq(drop.get("item"), "carrot")
	assert_eq(consume.get("ev"), "drag.consume")
	assert_eq(consume.get("item"), "carrot")


func test_a_miss_writes_only_a_returned_drop() -> void:
	_deliver(food, TouchSim.drag_events(food, MISS))

	assert_eq(_last_line().get("ev"), "drag.drop")
	assert_eq(_last_line().get("outcome"), "returned")
