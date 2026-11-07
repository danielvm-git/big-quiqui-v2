# story: e09s02
extends TouchDraggableTestCase
## SC-E09-P0-01/02/03/07 — FREE_PLACEMENT: what she drops stays where she dropped it,
## which is a ratio of the room and never a pixel.

const ROOM_POS: Vector2 = Vector2(600.0, 300.0)
const ROOM_SIZE: Vector2 = Vector2(400.0, 400.0)
const ROOM_CENTER: Vector2 = Vector2(800.0, 500.0)
const OUTSIDE: Vector2 = Vector2(1400.0, 900.0)

var room: Control = null
var placed_points: Array[Vector2] = []


func before_each() -> void:
	super.before_each()
	room = _make_target(self, ROOM_POS)
	room.size = ROOM_SIZE
	food.mode = TouchDraggable.Mode.FREE_PLACEMENT
	food.placement_area = room
	placed_points = []
	food.placed.connect(func(point: Vector2) -> void: placed_points.append(point))


func test_a_drop_inside_the_room_keeps_the_piece_there() -> void:
	_deliver(food, TouchSim.drag_events(food, ROOM_CENTER))

	assert_eq(food.state_id(), "REST", "a placed piece is at rest, not flying home")
	assert_eq(placed_points.size(), 1, "one drop, one placement")
	assert_false(food.position.is_equal_approx(HOME), "it did not fly back to the tray")
	var centre: Vector2 = food.get_global_rect().get_center()
	var expected: Vector2 = (centre - ROOM_POS) / ROOM_SIZE
	assert_true(placed_points[0].is_equal_approx(expected), "placed %s, want %s" % [placed_points[0], expected])
	assert_true(probe.is_clean(), probe.summary())


func test_advance_does_not_move_a_placed_piece() -> void:
	_deliver(food, TouchSim.drag_events(food, ROOM_CENTER))
	var settled: Vector2 = food.position

	food.advance(1.0)

	assert_true(food.position.is_equal_approx(settled), "no return spring on a placed piece")


func test_a_drop_outside_the_room_flies_home_and_places_nothing() -> void:
	_deliver(food, TouchSim.drag_events(food, OUTSIDE))

	assert_eq(food.state_id(), "RETURNING")
	assert_eq(placed_points.size(), 0, "no placement outside the room")
	food.advance(TouchDraggable.RETURN_SEC + 0.01)
	assert_true(food.position.is_equal_approx(HOME), "back in the tray")


func test_normalized_of_is_a_ratio_and_clamps_at_the_edges() -> void:
	var inside_centre: Vector2 = food.normalized_of(ROOM_CENTER)
	assert_true(inside_centre.is_equal_approx(Vector2(0.5, 0.5)), str(inside_centre))
	assert_true(food.normalized_of(ROOM_POS - Vector2(500.0, 500.0)).is_equal_approx(Vector2.ZERO))
	assert_true(food.normalized_of(ROOM_POS + ROOM_SIZE + Vector2(500.0, 500.0)).is_equal_approx(Vector2.ONE))


func test_normalized_of_without_a_room_is_the_origin() -> void:
	food.placement_area = null

	assert_true(food.normalized_of(ROOM_CENTER).is_equal_approx(Vector2.ZERO))


func test_other_modes_never_place() -> void:
	food.mode = TouchDraggable.Mode.CONSUME_ON_DROP

	_deliver(food, TouchSim.drag_events(food, ROOM_CENTER))

	assert_eq(placed_points.size(), 0)
	assert_eq(food.state_id(), "RETURNING", "a drop with no target is still a return")


func test_a_disabled_piece_never_starts_a_placement() -> void:
	food.enabled = false

	_deliver(food, TouchSim.drag_events(food, ROOM_CENTER))

	assert_eq(started, 0)
	assert_eq(placed_points.size(), 0)
	assert_eq(food.state_id(), "REST")
