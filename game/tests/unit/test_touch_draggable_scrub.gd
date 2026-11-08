# story: e04s01
extends TouchDraggableTestCase
## CONTINUOUS_SCRUB (ADR-004 mode 2): the gesture that produces no consume, only a
## stream of points while the finger is on the character.
##
## Threat findings closed here: T-E04-04 (an interrupted scrub must not wedge the
## shared finger owner), T-E04-03 (no diary line per motion), T-E04-05 (one channel,
## stopped on release).

const INSIDE: Vector2 = Vector2(1000.0, 500.0)
const INSIDE_2: Vector2 = Vector2(1040.0, 520.0)
const INSIDE_3: Vector2 = Vector2(1080.0, 540.0)
const HULL_POINTS: Array[Vector2] = [
	Vector2(800.0, 300.0),
	Vector2(1200.0, 300.0),
	Vector2(1200.0, 700.0),
	Vector2(800.0, 700.0),
]

var hull_stub: HullStub = null
var scrubbed: Array[Vector2] = []


## The component must not depend on `QuiQuiRig`'s type: any `Control` that can
## report a hull works, which is what makes this testable without a scene.
class HullStub:
	extends Control
	var hull: PackedVector2Array = PackedVector2Array()

	func scrub_hull_global() -> PackedVector2Array:
		return hull


func before_each() -> void:
	super.before_each()
	hull_stub = HullStub.new()
	hull_stub.hull = PackedVector2Array(HULL_POINTS)
	add_child_autofree(hull_stub)
	scrubbed = []
	food.mode = TouchDraggable.Mode.CONTINUOUS_SCRUB
	food.scrub_target = hull_stub
	food.scrubbed.connect(func(point: Vector2) -> void: scrubbed.append(point))


# ── SC-E04-P0-01 scrubbing emits, never consumes ──────────────────────────────


func test_a_scrub_inside_the_hull_emits_per_move_and_never_consumes() -> void:
	_send(food, _touch(INSIDE, true))
	_send(food, _scrub_drag(INSIDE_2))
	_send(food, _scrub_drag(INSIDE_3))
	_send(food, _touch(INSIDE_3, false))

	assert_eq(scrubbed.size(), 2, "one scrubbed per move inside the hull")
	assert_eq(food.state_id(), "REST", "the gesture ends at rest")
	assert_eq(consumed, 0, "a scrub never consumes")
	assert_eq(food.position, HOME, "the prop does not move: it is a scrub, not a drag")


# ── SC-E04-P0-02 outside the hull is silence, not an error ────────────────────


func test_a_move_outside_the_hull_emits_nothing_and_keeps_scrubbing() -> void:
	_send(food, _touch(INSIDE, true))
	_send(food, _scrub_drag(MISS))
	_send(food, _scrub_drag(INSIDE_2))
	_send(food, _touch(INSIDE_2, false))

	assert_eq(scrubbed.size(), 1, "only the inside move counts: %s" % [scrubbed])
	assert_eq(food.state_id(), "REST")


# ── SC-E04-P2-08 no target degrades quietly ──────────────────────────────────


func test_a_missing_scrub_target_emits_nothing() -> void:
	food.scrub_target = null
	_send(food, _touch(INSIDE, true))
	_send(food, _scrub_drag(INSIDE_2))
	_send(food, _touch(INSIDE_2, false))

	assert_eq(scrubbed.size(), 0, "no hull, no scrubs")
	assert_eq(food.state_id(), "REST")


# ── SC-E04-P0-04 an interrupted scrub must not wedge the owner ───────────────


func test_freeing_a_scrubbing_node_releases_the_owner() -> void:
	var second: TouchDraggable = _make_food(self, Vector2(300.0, 300.0), "Esponja")
	second.mode = TouchDraggable.Mode.CONTINUOUS_SCRUB
	second.scrub_target = hull_stub

	_send(food, _touch(INSIDE, true))
	assert_eq(food.state_id(), "SCRUBBING", "the first gesture is live")

	food.free()  # the scene changes mid-gesture

	_send(second, _touch(Vector2(400.0, 400.0), true))
	assert_eq(second.state_id(), "SCRUBBING", "the next control is still draggable")
	_send(second, _touch(Vector2(400.0, 400.0), false))
	assert_eq(second.state_id(), "REST")


# ── SC-E04-P0-05 the diary does not grow with the gesture ───────────────────


## T-E04-03 is about the *motion count*, not a magic total: a long scrub must write
## exactly as much as a short one. (The two `fsm.transition` lines come from the Fsm
## itself and are the same for both.)
func test_a_long_scrub_writes_as_much_as_a_short_one() -> void:
	var log_node: Node = get_node_or_null("/root/Log")
	assert_not_null(log_node, "the Log autoload is the writer under test")

	var short_delta: int = _scrub_and_count(log_node, 2)
	var long_delta: int = _scrub_and_count(log_node, 40)

	assert_eq(long_delta, short_delta, "40 motions must not write more than 2")
	assert_true(long_delta <= 4, "two scene events plus the Fsm's two transitions: %d" % long_delta)


func _scrub_and_count(log_node: Node, motions: int) -> int:
	var before: int = log_node.call("write_count") as int
	_send(food, _touch(INSIDE, true))
	for step: int in range(motions):
		_send(food, _scrub_drag(Vector2(1000.0 + float(step % 5), 500.0)))
	_send(food, _touch(INSIDE_3, false))
	return (log_node.call("write_count") as int) - before


# ── SC-E04-P1-06 one owned channel, stopped on release and on abort ─────────


func test_the_scrub_loop_is_one_player_and_stops_on_release() -> void:
	food.scrub_loop_stream = load("res://assets/audio/music/kitchen.ogg") as AudioStream
	assert_not_null(food.scrub_loop_stream)

	_send(food, _touch(INSIDE, true))
	assert_true(food.is_scrub_loop_playing(), "the loop runs with the gesture")

	_send(food, _touch(INSIDE, false))
	assert_false(food.is_scrub_loop_playing(), "and stops with it")

	_send(food, _touch(INSIDE, true))
	_send(food, _touch(INSIDE, false))
	assert_eq(food.scrub_loop_player_count(), 1, "one player, reused: no channel leak")


func test_abort_stops_the_loop_and_releases_the_owner() -> void:
	food.scrub_loop_stream = load("res://assets/audio/music/kitchen.ogg") as AudioStream
	_send(food, _touch(INSIDE, true))

	food.abort()

	assert_eq(food.state_id(), "REST", "abort returns to rest")
	assert_false(food.is_scrub_loop_playing(), "and stops the sound")
	_send(food, _touch(INSIDE, true))
	assert_eq(food.state_id(), "SCRUBBING", "the owner is free again")


# ── helpers ─────────────────────────────────────────────────────────────────


func _scrub_drag(point: Vector2) -> InputEventScreenDrag:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = 0
	event.position = point
	return event
