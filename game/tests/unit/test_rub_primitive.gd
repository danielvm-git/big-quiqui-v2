# story: e13s01
extends GutTest
## SC-e13s01-P0-01..04. The primitive reports a covered-area ratio and never completes itself.

const SCRIPT_PATH: String = "res://scripts/components/rub_primitive.gd"
const LOOP_PATH: String = "res://assets/audio/music/kitchen.ogg"


class HullStub:
	extends Control
	var hull: PackedVector2Array = PackedVector2Array()

	func scrub_hull_global() -> PackedVector2Array:
		return hull


func test_a_point_outside_the_hull_does_not_count() -> void:
	var rub: RefCounted = _new_rub()
	if rub == null:
		return
	_bind_square(rub)
	rub.call("begin", _host())
	assert_false(bool(rub.call("rub_at", Vector2(-40.0, -40.0))))
	assert_almost_eq(float(rub.call("progress")), 0.0, 0.001, "SC-e13s01-P0-01")


func test_progress_reaches_one_only_when_the_area_is_done() -> void:
	var rub: RefCounted = _new_rub()
	if rub == null:
		return
	_bind_square(rub)
	rub.call("begin", _host())
	for index: int in range(8):
		rub.call("rub_at", Vector2(50.0, 50.0))
	assert_lt(float(rub.call("progress")), 1.0, "one cell is not the whole area")
	_rub_grid(rub, 15)
	assert_lt(float(rub.call("progress")), 1.0, "SC-e13s01-P0-02 still short")
	_rub_grid(rub, 16)
	assert_almost_eq(float(rub.call("progress")), 1.0, 0.001, "SC-e13s01-P0-02")


func test_the_grid_edge_is_data_and_a_coarser_grid_covers_faster() -> void:
	var rub: RefCounted = _new_rub()
	if rub == null:
		return
	rub.set("edge", 2)
	_bind_square(rub)
	rub.call("begin", _host())
	rub.call("rub_at", Vector2(50.0, 50.0))
	assert_almost_eq(float(rub.call("progress")), 0.25, 0.001, "A9 one of four coarse cells")


func test_a_first_rub_reports_a_ratio_and_does_not_complete() -> void:
	var rub: RefCounted = _new_rub()
	if rub == null:
		return
	_bind_square(rub)
	rub.call("begin", _host())
	assert_true(bool(rub.call("rub_at", Vector2(50.0, 50.0))))
	var ratio: float = float(rub.call("progress"))
	assert_gt(ratio, 0.0)
	assert_lt(ratio, 1.0)


func test_corner_cells_of_an_oval_hull_do_not_fake_coverage() -> void:
	var rub: RefCounted = _new_rub()
	if rub == null:
		return
	var stub: HullStub = HullStub.new()
	stub.hull = _oval(Vector2(200.0, 200.0), 400.0)
	add_child_autofree(stub)
	rub.call("bind_target", stub)
	rub.call("begin", _host())
	for corner: Vector2 in [Vector2(70, 70), Vector2(330, 70), Vector2(70, 330), Vector2(330, 330)]:
		rub.call("rub_at", corner)
	assert_lt(float(rub.call("progress")), 0.2, "A1 corner cells sit outside the oval")
	for col: int in range(4):
		for row: int in range(4):
			rub.call("rub_at", Vector2(50.0 + 100.0 * float(col), 50.0 + 100.0 * float(row)))
	assert_almost_eq(float(rub.call("progress")), 1.0, 0.001, "the area cells alone reach 1.0")


func test_the_loop_waits_for_the_first_point_inside_the_hull() -> void:
	var rub: RefCounted = _new_rub()
	if rub == null:
		return
	_bind_square(rub)
	rub.call("set_loop", load(LOOP_PATH) as AudioStream)
	rub.call("begin", _host())
	assert_eq(int(rub.call("playing_channels")), 0, "B8 pressing is silent")
	rub.call("rub_at", Vector2(-40.0, -40.0))
	assert_eq(int(rub.call("playing_channels")), 0, "B8 a miss is silent")
	rub.call("rub_at", Vector2(50.0, 50.0))
	assert_eq(int(rub.call("playing_channels")), 1, "B8 the first valid rub starts it")
	rub.call("release_all")
	assert_eq(int(rub.call("playing_channels")), 0)


func test_one_loop_channel_and_silence_after_release() -> void:
	var rub: RefCounted = _new_rub()
	if rub == null:
		return
	_bind_square(rub)
	var stream: AudioStream = load(LOOP_PATH) as AudioStream
	assert_not_null(stream)
	rub.call("set_loop", stream)
	var host: Node = _host()
	rub.call("begin", host)
	rub.call("rub_at", Vector2(50.0, 50.0))
	assert_eq(int(rub.call("playing_channels")), 1, "SC-e13s01-P0-03 the loop starts")
	rub.call("release")
	assert_eq(int(rub.call("playing_channels")), 0, "SC-e13s01-P0-03 silence on release")
	rub.call("begin", host)
	rub.call("release")
	assert_eq(int(rub.call("owned_channels")), 1, "one player, reused")


func test_the_hull_is_read_at_call_time() -> void:
	var rub: RefCounted = _new_rub()
	if rub == null:
		return
	var stub: HullStub = _bind_square(rub)
	rub.call("begin", _host())
	assert_true(bool(rub.call("rub_at", Vector2(50.0, 50.0))))
	var before: float = float(rub.call("progress"))
	stub.hull = _box(2000.0)
	assert_false(bool(rub.call("rub_at", Vector2(50.0, 50.0))))
	assert_almost_eq(float(rub.call("progress")), before, 0.001, "SC-e13s01-P0-04 stale point")
	assert_true(bool(rub.call("rub_at", Vector2(2050.0, 2050.0))), "SC-e13s01-P0-04 moved hull")


func test_the_same_centre_counts_at_both_aspects() -> void:
	for canvas: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		var rub: RefCounted = _new_rub()
		if rub == null:
			return
		var stub: HullStub = HullStub.new()
		stub.position = Vector2.ZERO
		stub.size = Vector2(canvas)
		add_child_autofree(stub)
		stub.hull = _rect_hull(stub.get_global_rect())
		rub.call("bind_target", stub)
		rub.call("begin", _host())
		var centre: Vector2 = stub.get_global_rect().get_center()
		assert_true(bool(rub.call("rub_at", centre)), "SC-e13s01-P1-02 %s" % canvas)
		var outside: Vector2 = stub.get_global_rect().position - Vector2(30.0, 30.0)
		assert_false(bool(rub.call("rub_at", outside)), "outside %s" % canvas)


func test_a_missing_target_is_zero_progress_and_not_an_error() -> void:
	var rub: RefCounted = _new_rub()
	if rub == null:
		return
	rub.call("bind_target", null)
	rub.call("begin", _host())
	assert_false(bool(rub.call("rub_at", Vector2(50.0, 50.0))))
	assert_almost_eq(float(rub.call("progress")), 0.0, 0.001)


func _new_rub() -> RefCounted:
	if not ResourceLoader.exists(SCRIPT_PATH):
		fail_test("missing %s" % SCRIPT_PATH)
		return null
	var script: Script = load(SCRIPT_PATH) as Script
	if script == null:
		fail_test("missing %s" % SCRIPT_PATH)
		return null
	return script.new() as RefCounted


func _host() -> Node:
	var host: Node = Node.new()
	add_child_autofree(host)
	return host


func _bind_square(rub: RefCounted) -> HullStub:
	var stub: HullStub = HullStub.new()
	stub.hull = _box(0.0)
	add_child_autofree(stub)
	rub.call("bind_target", stub)
	return stub


func _rect_hull(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array(
		[
			rect.position,
			rect.position + Vector2(rect.size.x, 0.0),
			rect.position + rect.size,
			rect.position + Vector2(0.0, rect.size.y),
		]
	)


func _oval(centre: Vector2, edge: float) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for step: int in range(12):
		var angle: float = TAU * float(step) / 12.0
		points.append(centre + Vector2(cos(angle), sin(angle)) * edge * 0.5)
	return points


func _box(origin: float) -> PackedVector2Array:
	return PackedVector2Array(
		[
			Vector2(origin, origin),
			Vector2(origin + 400.0, origin),
			Vector2(origin + 400.0, origin + 400.0),
			Vector2(origin, origin + 400.0),
		]
	)


func _rub_grid(rub: RefCounted, limit: int) -> void:
	var filled: int = 0
	for col: int in range(4):
		for row: int in range(4):
			if filled >= limit:
				return
			var point: Vector2 = Vector2(50.0 + 100.0 * float(col), 50.0 + 100.0 * float(row))
			rub.call("rub_at", point)
			filled += 1
