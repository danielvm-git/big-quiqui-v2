# story: e06s03
extends GutTest
## The garden: three distinct toys complete PLAY (T-E06-05), replaying one does not
## count twice (T-E06-01), and leaving puts every toy back at rest (T-E06-06).

const SCENE_PATH: String = "res://scenes/jardim.tscn"

var scene: GardenScene = null
var viewport: SubViewport = null


func before_each() -> void:
	TestReset.reset_all()


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _mount(size: Vector2i = GeometryOracle.DESKTOP_16_9) -> GardenScene:
	viewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	assert_not_null(packed, "jardim.tscn must load")
	scene = packed.instantiate() as GardenScene
	scene.manual_step = true
	viewport.add_child(scene)
	return scene


func _deliver(control: Control, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		control._gui_input(TouchSim.gui_event(control, event))


func _tap(control: Control) -> void:
	_deliver(control, TouchSim.tap_events(control, true))


# ── SC-E06-P0-10 the garden is a garden ────────────────────────────────────


func test_the_garden_has_three_toys_a_tickle_zone_and_no_text() -> void:
	_mount()
	await wait_process_frames(3)

	for index: int in range(3):
		var prop: GardenProp = scene.prop(index)
		assert_not_null(prop, "toy %d" % index)
		assert_true(prop.is_idle(), "toy %d starts at rest" % index)
		assert_true(prop.size.x >= 120.0 and prop.size.y >= 120.0, "toy %d is a real target" % index)
	assert_not_null(scene.tickle, "the tickle zone exists")
	for node: Node in scene.find_children("*", "Label", true, false):
		assert_true((node as Label).text.is_empty(), "%s carries text" % node.name)

	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		viewport.size = size
		await wait_process_frames(2)
		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(scene, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_true(findings.is_empty(), "%s: %s" % [size, oracle.summary()])


# ── SC-E06-P0-11 three distinct toys finish play ───────────────────────────


func test_three_distinct_toys_finish_play_and_credit_once() -> void:
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("reset")
	clm.call("begin_step", CareSteps.FEED)
	clm.call("complete_step", CareSteps.FEED)
	clm.call("begin_step", CareSteps.BATH)
	clm.call("complete_step", CareSteps.BATH)
	clm.call("begin_step", CareSteps.DRESS)
	clm.call("complete_step", CareSteps.DRESS)
	clm.call("begin_step", CareSteps.PLAY)
	assert_eq(str(clm.call("state_id")), CareSteps.PLAY)

	_mount()
	await wait_process_frames(3)
	for index: int in range(3):
		_tap(scene.prop(index))

	assert_eq(scene.played.size(), 3)
	assert_eq(scene.fsm.state, GardenScene.STATE_FINISHED)
	assert_eq(scene.rig.expression_id, "pulando", "she jumps")
	assert_true(scene.credited, "PLAY credited")
	assert_eq(str(clm.call("state_id")), CareSteps.SLEEP, "SLEEP is next")
	assert_false(clm.call("complete_step", CareSteps.PLAY), "a second credit is refused")


# ── SC-E06-P0-12 the same toy thrice does not count (T-E06-01) ─────────────


func test_replaying_one_toy_never_finishes_play() -> void:
	_mount()
	await wait_process_frames(3)

	for repeat: int in range(4):
		_tap(scene.prop(0))
		scene.advance(GardenProp.BOUNCE_SEC + 0.1)

	assert_eq(scene.played.size(), 1, "one distinct toy, however often it is tapped")
	assert_eq(scene.fsm.state, GardenScene.STATE_PLAYING, "play is still open")
	assert_false(scene.credited)


# ── SC-E06-P1-13 tickle is play, not progress ──────────────────────────────


func test_tickling_is_repeatable_and_never_advances_the_step() -> void:
	_mount()
	await wait_process_frames(3)

	for repeat: int in range(5):
		_tap(scene.tickle)

	assert_eq(scene.tickles, 5, "every tickle counts as play")
	assert_eq(scene.played.size(), 0, "but none of them is a toy interaction")
	assert_eq(scene.fsm.state, GardenScene.STATE_PLAYING)


# ── SC-E06-P1-14 leaving leaves calm (T-E06-06) ────────────────────────────


func test_leaving_mid_play_stops_the_toys_and_abandons() -> void:
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("reset")
	clm.call("begin_step", CareSteps.FEED)
	clm.call("complete_step", CareSteps.FEED)
	clm.call("begin_step", CareSteps.BATH)
	clm.call("complete_step", CareSteps.BATH)
	clm.call("begin_step", CareSteps.DRESS)
	clm.call("complete_step", CareSteps.DRESS)
	clm.call("begin_step", CareSteps.PLAY)

	_mount()
	await wait_process_frames(3)
	_tap(scene.prop(0))
	assert_false(scene.prop(0).is_idle(), "the ball is moving")

	_tap(scene.get_node("HomeButton") as TapButton)

	for index: int in range(3):
		assert_true(scene.prop(index).is_idle(), "toy %d is at rest after leaving" % index)
	assert_eq(str(clm.call("state_id")), CareSteps.IDLE, "the step is abandoned")
	assert_false(scene.credited)


# ── SC-E06-P2-15 every toy settles on its own (T-E06-04) ───────────────────


func test_every_toy_settles_within_its_budget() -> void:
	_mount()
	await wait_process_frames(3)

	for index: int in range(3):
		_tap(scene.prop(index))
	scene.advance(2.0)

	for index: int in range(3):
		assert_true(scene.prop(index).is_idle(), "toy %d settled" % index)
