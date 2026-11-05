# story: e03s01
extends TouchDraggableTestCase
## The input edges (ADR-004): second fingers, local coordinates, mouse echo and the
## static lock (T-E03-01).
const LAYER_OFFSET: Vector2 = Vector2(40.0, 30.0)
## The target's near corner on screen is (940, 430): this point is inside it only
## when the finger is read with the layer offset.
const LAYER_FINGER: Vector2 = Vector2(950.0, 440.0)

# ── SC-E03-P0-02 second finger ignored ───────────────────────────────────────


func test_a_second_finger_on_the_same_food_cannot_move_or_drop_it() -> void:
	_send(food, _touch(HOME + Vector2(10.0, 10.0), true, 0))
	_send(food, _drag(Vector2(300.0, 300.0), 0))
	var held_at: Vector2 = food.global_position

	_send(food, _touch(ON_TARGET, true, 1))
	_send(food, _drag(ON_TARGET, 1))
	_send(food, _touch(ON_TARGET, false, 1))

	assert_eq(food.state_id(), "DRAGGING", "finger 1 cannot drop it")
	assert_eq(food.global_position, held_at, "finger 1 cannot move it")
	assert_eq(consumed, 0)
	assert_eq(started, 1)

	_send(food, _drag(ON_TARGET, 0))
	_send(food, _touch(ON_TARGET, false, 0))
	assert_eq(food.state_id(), "CONSUMED", "finger 0 still owns it")
	assert_eq(consumed, 1)


func test_a_second_food_cannot_be_held_at_the_same_time() -> void:
	var other: TouchDraggable = _make_food(self, Vector2(400.0, 120.0), "Maca")
	var other_probe: FsmProbe = FsmProbe.new().attach(other.fsm)
	_send(food, _touch(_center(food), true, 0))

	_send(other, _touch(_center(other), true, 1))
	_send(other, _drag(ON_TARGET, 1))
	_send(other, _touch(ON_TARGET, false, 1))

	assert_eq(other.state_id(), "REST", "only one food in the game is held")
	assert_eq(other.position, Vector2(400.0, 120.0))
	assert_eq(food.state_id(), "DRAGGING", "the first food is untouched")
	assert_true(other_probe.is_clean(), other_probe.summary())


func test_the_lock_frees_on_a_drop_so_the_next_food_can_be_dragged() -> void:
	var other: TouchDraggable = _make_food(self, Vector2(400.0, 120.0), "Maca")

	_deliver(food, TouchSim.drag_events(food, MISS))
	_send(other, _touch(_center(other), true, 0))
	assert_eq(other.state_id(), "DRAGGING", "a returning food holds no lock")
	_send(other, _touch(ON_TARGET, false, 0))

	var third: TouchDraggable = _make_food(self, Vector2(700.0, 120.0), "Pera")
	_send(third, _touch(_center(third), true, 0))
	assert_eq(other.state_id(), "CONSUMED")
	assert_eq(third.state_id(), "DRAGGING", "a consumed food holds no lock")


# ── SC-E03-P0-04 local-coordinate conversion ─────────────────────────────────


func test_gui_event_returns_a_local_copy_and_leaves_the_original_alone() -> void:
	var event: InputEventScreenTouch = _touch(HOME + Vector2(7.0, 9.0), true, 3)

	var local: InputEventScreenTouch = TouchSim.gui_event(food, event) as InputEventScreenTouch

	assert_ne(local, event, "a copy")
	assert_eq(local.position, Vector2(7.0, 9.0))
	assert_eq(local.index, 3)
	assert_true(local.pressed)
	assert_eq(event.position, HOME + Vector2(7.0, 9.0))


func test_gui_event_keeps_the_mouse_device_so_the_echo_is_still_an_echo() -> void:
	var local: InputEvent = TouchSim.gui_event(food, _mouse(HOME, true, -1))

	assert_eq(local.device, -1)
	assert_eq((local as InputEventMouseButton).position, Vector2.ZERO)


func test_conversion_holds_under_a_moved_and_scaled_parent() -> void:
	var parent: Control = Control.new()
	parent.position = Vector2(300.0, 200.0)
	parent.scale = Vector2(2.0, 2.0)
	add_child_autofree(parent)
	var nested: TouchDraggable = _make_food(parent, Vector2(50.0, 50.0), "Nested")
	var points: Array[Vector2] = []
	nested.drag_moved.connect(func(point: Vector2) -> void: points.append(point))

	_send(nested, _touch(Vector2(548.0, 448.0), true))
	_send(nested, _drag(Vector2(800.0, 600.0)))

	_assert_near(points[0], Vector2(800.0, 600.0), "the finger comes back global")
	_assert_near(_center(nested), Vector2(800.0, 600.0), "the art stays under the finger")

	_send(nested, _drag(ON_TARGET))
	_send(nested, _touch(ON_TARGET, false))
	assert_eq(nested.state_id(), "CONSUMED", "the drop is tested in global space")


func _make_layered_food() -> TouchDraggable:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.offset = LAYER_OFFSET
	add_child_autofree(layer)
	var layered: TouchDraggable = _make_food(layer, HOME, "Layered")
	layered.drop_target = _make_target(layer, TARGET_POS)
	return layered


func test_inside_a_canvas_layer_the_art_follows_the_finger_on_screen() -> void:
	var layered: TouchDraggable = _make_layered_food()
	var points: Array[Vector2] = []
	layered.drag_moved.connect(func(point: Vector2) -> void: points.append(point))

	_send(layered, _touch(HOME + LAYER_OFFSET + Vector2(10.0, 10.0), true))
	_send(layered, _drag(LAYER_FINGER))

	_assert_near(points[0], LAYER_FINGER, "the finger comes back in canvas space")
	var on_screen: Vector2 = layered.get_global_transform_with_canvas().origin
	_assert_near(on_screen, LAYER_FINGER - Vector2(10.0, 10.0), "follows on screen")


func test_inside_a_canvas_layer_finger_and_target_share_a_space() -> void:
	var layered: TouchDraggable = _make_layered_food()

	_send(layered, _touch(HOME + LAYER_OFFSET, true))
	_send(layered, _touch(LAYER_FINGER, false))

	assert_eq(layered.state_id(), "CONSUMED", "the point hits only with the layer offset")


# ── mouse echo ───────────────────────────────────────────────────────────────


func test_events_from_device_minus_one_are_ignored() -> void:
	var point: Vector2 = _center(food)
	_send(food, _mouse(point, true, -1))
	_send(food, _mouse_move(ON_TARGET, -1))
	_send(food, _mouse(ON_TARGET, false, -1))
	var emulated: InputEventScreenTouch = _touch(point, true)
	emulated.device = -1
	_send(food, emulated)

	assert_eq(food.state_id(), "REST")
	assert_eq(food.position, HOME)
	assert_eq(started, 0)


func test_a_real_mouse_drags_and_consumes() -> void:
	_send(food, _mouse(_center(food), true))
	assert_eq(food.state_id(), "DRAGGING")

	_send(food, _mouse_move(ON_TARGET))
	_assert_near(_center(food), ON_TARGET, "follows the mouse")

	_send(food, _mouse(ON_TARGET, false))
	assert_eq(food.state_id(), "CONSUMED")
	assert_eq(consumed, 1)


func test_a_right_click_does_not_pick_it_up() -> void:
	var event: InputEventMouseButton = _mouse(_center(food), true)
	event.button_index = MOUSE_BUTTON_RIGHT
	_send(food, event)

	assert_eq(food.state_id(), "REST")


func test_a_mouse_with_an_emulated_touch_is_one_gesture_mouse_first() -> void:
	var point: Vector2 = _center(food)
	_send(food, _mouse(point, true))
	_send(food, _touch(point, true))
	_send(food, _mouse_move(ON_TARGET))
	_send(food, _drag(ON_TARGET))
	_send(food, _mouse(ON_TARGET, false))
	_send(food, _touch(ON_TARGET, false))

	assert_eq(started, 1)
	assert_eq(consumed, 1)
	assert_eq(ended, 1)
	assert_eq(moved_points.size(), 1, "only the owner moves it")
	assert_true(probe.is_clean(), probe.summary())


func test_a_mouse_with_an_emulated_touch_is_one_gesture_touch_first() -> void:
	var point: Vector2 = _center(food)
	_send(food, _touch(point, true))
	_send(food, _mouse(point, true))
	_send(food, _drag(MISS))
	_send(food, _mouse_move(MISS))
	_send(food, _touch(MISS, false))
	_send(food, _mouse(MISS, false))

	assert_eq(started, 1)
	assert_eq(ended, 1)
	assert_eq(food.state_id(), "RETURNING")
	assert_true(probe.is_clean(), probe.summary())


# ── SC-E03-P1-05 disabled ────────────────────────────────────────────────────


func test_a_disabled_food_ignores_a_press() -> void:
	food.enabled = false
	_deliver(food, TouchSim.drag_events(food, ON_TARGET))

	assert_eq(food.state_id(), "REST")
	assert_eq(food.position, HOME)
	assert_eq(started, 0)


func test_disabling_a_held_food_still_ends_the_gesture_and_frees_the_lock() -> void:
	var other: TouchDraggable = _make_food(self, Vector2(400.0, 120.0), "Maca")
	_send(food, _touch(_center(food), true))
	food.enabled = false

	_send(food, _touch(MISS, false))
	assert_eq(food.state_id(), "RETURNING")

	_send(other, _touch(_center(other), true))
	assert_eq(other.state_id(), "DRAGGING", "no wedged owner (T-E03-01)")


# ── e03s03 cancelled touch ───────────────────────────────────────────────────


func test_a_cancelled_touch_on_the_target_returns_and_never_consumes() -> void:
	var other: TouchDraggable = _make_food(self, Vector2(400.0, 120.0), "Maca")
	_send(food, _touch(_center(food), true))
	_send(food, _drag(ON_TARGET))
	var cancelled: InputEventScreenTouch = _touch(ON_TARGET, false)
	cancelled.canceled = true

	_send(food, cancelled)

	assert_eq(food.state_id(), "RETURNING", "a system gesture is not a drop")
	assert_eq(consumed, 0)
	assert_eq(ended, 1)
	assert_true(probe.is_clean(), probe.summary())
	_send(other, _touch(_center(other), true))
	assert_eq(other.state_id(), "DRAGGING", "the lock is free")


# ── SC-E03-P1-06 owner released when the node leaves the tree ────────────────


func test_freeing_a_held_food_releases_the_owner() -> void:
	var other: TouchDraggable = _make_food(self, Vector2(400.0, 120.0), "Maca")
	_send(food, _touch(_center(food), true))
	probe.detach()

	food.free()

	_send(other, _touch(_center(other), true))
	assert_eq(other.state_id(), "DRAGGING", "T-E03-01: nothing is wedged")


func test_removing_a_held_food_cancels_the_drag_and_it_can_be_used_again() -> void:
	_send(food, _touch(_center(food), true))
	_send(food, _drag(MISS))

	remove_child(food)

	assert_eq(food.state_id(), "REST")
	assert_eq(food.position, HOME)
	assert_eq(ended, 1, "listeners get their drag_ended")
	assert_eq(consumed, 0)

	add_child(food)
	_deliver(food, TouchSim.drag_events(food, ON_TARGET))
	assert_eq(food.state_id(), "CONSUMED")
	assert_true(probe.is_clean(), probe.summary())


func test_removing_a_food_that_is_not_held_leaves_the_owner_alone() -> void:
	var other: TouchDraggable = _make_food(self, Vector2(400.0, 120.0), "Maca")
	_send(food, _touch(_center(food), true))

	remove_child(other)
	add_child(other)

	_send(other, _touch(_center(other), true, 1))
	assert_eq(other.state_id(), "REST", "the lock is still food's")
	assert_eq(food.state_id(), "DRAGGING")
