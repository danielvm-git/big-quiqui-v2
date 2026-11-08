# story: e10s02
extends GutTest
## SC-E10-P0-08, SC-E10-P0-09, SC-E10-P1-13 — PuzzlePiece unit tests: quadrant
## regions, SNAP_TO_SLOT to own slot, wrong-slot fly-home, and idempotent locking.

const URSO_ART: String = "res://assets/art/friends/bear.png"

var root: Control = null
var slot: Control = null
var wrong_slot: Control = null
var piece: PuzzlePiece = null
var texture: Texture2D = null


func before_each() -> void:
	TestReset.reset_all()
	texture = load(URSO_ART) as Texture2D
	root = Control.new()
	root.size = Vector2(1920.0, 1080.0)
	add_child_autofree(root)

	slot = Control.new()
	slot.name = "Slot_0"
	slot.position = Vector2(600.0, 300.0)
	slot.size = Vector2(180.0, 180.0)
	root.add_child(slot)

	wrong_slot = Control.new()
	wrong_slot.name = "Slot_1"
	wrong_slot.position = Vector2(800.0, 300.0)
	wrong_slot.size = Vector2(180.0, 180.0)
	root.add_child(wrong_slot)

	piece = PuzzlePiece.new()
	piece.piece_id = 0
	piece.position = Vector2(200.0, 700.0)
	piece.size = Vector2(180.0, 180.0)
	root.add_child(piece)
	var region: Rect2 = PuzzlePiece.quadrant_region(0, texture.get_size())
	piece.setup_quadrant(texture, region, slot)


func after_each() -> void:
	TestReset.delete_test_save()


func test_quadrant_regions_are_exact_quarters_of_texture() -> void:
	var size: Vector2 = Vector2(1024.0, 1024.0)
	var r0: Rect2 = PuzzlePiece.quadrant_region(0, size)
	var r1: Rect2 = PuzzlePiece.quadrant_region(1, size)
	var r2: Rect2 = PuzzlePiece.quadrant_region(2, size)
	var r3: Rect2 = PuzzlePiece.quadrant_region(3, size)

	assert_eq(r0, Rect2(0.0, 0.0, 512.0, 512.0), "top-left")
	assert_eq(r1, Rect2(512.0, 0.0, 512.0, 512.0), "top-right")
	assert_eq(r2, Rect2(0.0, 512.0, 512.0, 512.0), "bottom-left")
	assert_eq(r3, Rect2(512.0, 512.0, 512.0, 512.0), "bottom-right")

	# Area of four quarters equals whole texture
	var total_area: float = r0.get_area() + r1.get_area() + r2.get_area() + r3.get_area()
	assert_eq(total_area, size.x * size.y, "exact coverage")


func _deliver(control: Control, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		control._gui_input(TouchSim.gui_event(control, event))


func test_snap_to_own_slot_locks_and_parks() -> void:
	assert_false(piece.is_locked(), "starts unlocked")
	watch_signals(piece)

	# Drag to own slot center
	var to_pos: Vector2 = slot.get_global_rect().get_center()
	_deliver(piece.draggable, TouchSim.drag_events(piece.draggable, to_pos))

	assert_true(piece.is_locked(), "locks on drop inside own slot")
	assert_signal_emitted_with_parameters(piece, "locked", [0])
	assert_eq(piece.draggable.global_position, slot.global_position, "parks in slot")


func test_drop_on_wrong_slot_or_floor_flies_home_and_does_not_lock() -> void:
	watch_signals(piece)

	# Drag to wrong slot
	var wrong_pos: Vector2 = wrong_slot.get_global_rect().get_center()
	_deliver(piece.draggable, TouchSim.drag_events(piece.draggable, wrong_pos))

	assert_false(piece.is_locked(), "wrong slot does not lock")
	assert_signal_not_emitted(piece, "locked")

	# Drag to empty floor
	_deliver(piece.draggable, TouchSim.drag_events(piece.draggable, Vector2(100.0, 100.0)))
	assert_false(piece.is_locked(), "floor does not lock")
	assert_signal_not_emitted(piece, "locked")


func test_lock_is_idempotent_and_inert_afterwards() -> void:
	piece.lock_in()
	assert_true(piece.is_locked())
	assert_false(piece.draggable.enabled, "draggable disabled on lock")

	watch_signals(piece)
	# Second lock_in call changes nothing
	piece.lock_in()
	assert_signal_not_emitted(piece, "locked")

	# Attempting to drag disabled piece changes nothing
	_deliver(piece.draggable, TouchSim.drag_events(piece.draggable, Vector2(1000.0, 500.0)))
	assert_eq(piece.draggable.global_position, slot.global_position, "still parked")


func test_unlock_reenables_piece_and_resets_position() -> void:
	piece.lock_in()
	assert_true(piece.is_locked())
	piece.unlock()
	assert_false(piece.is_locked(), "unlocked")
	assert_true(piece.draggable.enabled, "draggable re-enabled")
	assert_eq(piece.draggable.position, Vector2.ZERO, "position reset to piece origin")
