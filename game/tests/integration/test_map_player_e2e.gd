# story: e13s03
extends PlayerTestCase
## SC-e13s03-P0-02..05. The map is played through the player: pins, a pan, a locked door.

var _requested: Array[String] = []


func before_each() -> void:
	TestReset.reset_all()
	get_node("/root/CareLoopManager").call("reset")
	_requested.clear()


func _on_requested(path: String, _queued: bool) -> void:
	_requested.append(path)


func _manager() -> Node:
	var sm: Node = get_node("/root/SceneManager")
	sm.manual_step = true
	sm.reset()
	sm.set_test_mode(true)
	if not sm.scene_requested.is_connected(_on_requested):
		sm.scene_requested.connect(_on_requested)
	return sm


func after_each() -> void:
	var sm: Node = get_node("/root/SceneManager")
	if sm.scene_requested.is_connected(_on_requested):
		sm.scene_requested.disconnect(_on_requested)
	sm.reset()
	sm.manual_step = false


func _pad(player: ScenePlayer) -> TouchPad:
	return player.get_node("MapPad") as TouchPad


func _pin_point(player: ScenePlayer, dest: String) -> Vector2:
	var pin: Control = player.get_node("MapWorld/%s" % dest) as Control
	return pin.get_global_rect().get_center()


func test_the_def_builds_a_pad_and_one_pin_per_destination() -> void:
	_manager()
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("home_map"))
	assert_not_null(_pad(player), "A3 the map has a touch surface")
	assert_eq(player.get_node("MapWorld").get_child_count(), 3)
	var pin: Control = player.get_node("MapWorld/feed_door") as Control
	assert_eq(pin.size, TapButton.MIN_HIT_SIZE)
	assert_not_null(pin.texture if pin is TextureRect else null, "A3 the pin has its def icon")
	assert_lt(player.get_node("MapWorld/bath_door").modulate.a, 1.0, "the locked pin is dimmed")


func test_a_tap_on_an_open_pin_opens_its_catalogue_room() -> void:
	_manager()
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("home_map"))
	var at: Vector2 = _pin_point(player, "feed_door")
	send(_pad(player), touch(at, true))
	send(_pad(player), touch(at, false))
	assert_eq(_requested.size(), 1, "the room was requested once")
	assert_true(_requested[0].ends_with("scene_player.tscn"), "kitchen is a data scene")


func test_the_mouse_echo_does_not_open_a_door_twice() -> void:
	_manager()
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("home_map"))
	var at: Vector2 = _pin_point(player, "feed_door")
	send(_pad(player), touch(at, true))
	send(_pad(player), touch(at, true, 0, -1))
	send(_pad(player), touch(at, false))
	send(_pad(player), touch(at, false, 0, -1))
	assert_eq(_requested.size(), 1)


func test_a_locked_pin_refuses_softly_and_points_at_care() -> void:
	_manager()
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("home_map"))
	player.get_node("MapWorld").position = Vector2.ZERO
	var at: Vector2 = _pin_point(player, "bath_door")
	send(_pad(player), touch(at, true))
	send(_pad(player), touch(at, false))
	assert_eq(_requested.size(), 0, "a locked door never opens")
	var wish: WishBubble = player.get_node("MapWish") as WishBubble
	assert_true(wish.is_showing(), "the wish bubble points at the next care step")


func test_a_drag_from_empty_space_pans_and_opens_nothing() -> void:
	_manager()
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("home_map"))
	var start: Vector2 = Vector2(900.0, 900.0)
	send(_pad(player), touch(start, true))
	send(_pad(player), drag(start + Vector2(-300.0, 0.0)))
	send(_pad(player), touch(start + Vector2(-300.0, 0.0), false))
	assert_eq(_requested.size(), 0)
	assert_ne(player.get_node("MapWorld").position, Vector2.ZERO, "the world moved")


func test_a_drag_that_starts_on_a_pin_cancels_the_tap_and_does_not_pan() -> void:
	_manager()
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("home_map"))
	var at: Vector2 = _pin_point(player, "feed_door")
	var before: Vector2 = player.get_node("MapWorld").position
	send(_pad(player), touch(at, true))
	send(_pad(player), drag(at + Vector2(80.0, 0.0)))
	send(_pad(player), touch(at + Vector2(80.0, 0.0), false))
	assert_eq(_requested.size(), 0, "SC-e13s03-P0-02 a drag is not a tap")
	assert_eq(player.get_node("MapWorld").position, before, "and it did not pan")


func test_a_second_finger_cannot_open_a_door_under_the_first() -> void:
	_manager()
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("home_map"))
	var at: Vector2 = _pin_point(player, "feed_door")
	send(_pad(player), touch(Vector2(900.0, 900.0), true, 1))
	send(_pad(player), touch(at, true, 2))
	send(_pad(player), touch(at, false, 2))
	assert_eq(_requested.size(), 0, "B6 one finger owns the pan")


func test_teardown_removes_the_pad_the_world_and_the_wish() -> void:
	_manager()
	var player: ScenePlayer = await mount(SceneDefLoader.load_by_id("home_map"))
	player.runner.request_home()
	player.advance(0.2)
	await wait_process_frames(2)
	assert_null(player.get_node_or_null("MapPad"))
	assert_null(player.get_node_or_null("MapWorld"))
