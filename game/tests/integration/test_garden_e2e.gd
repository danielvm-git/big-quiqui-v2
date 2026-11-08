# story: e06s03
extends GutTest
## SC-E06-P0-20..P1-23: the PLAY journey with the real autoloads — Casa door in, three
## distinct toys, credit once, Casa out — plus the sandbox's own promise: the same toy
## twice is still fun and still does not finish the step.

const CASA_PATH: String = "res://scenes/casa.tscn"
const JARDIM_PATH: String = "res://scenes/jardim.tscn"
const SCENE_STEP_SEC: float = 0.1
const SCENE_STEPS: int = 30

var clm: Node = null
var sm: Node = null
var viewport: SubViewport = null
var stage: Control = null
var requested: Array[String] = []
var loop_probe: FsmProbe = null


func before_all() -> void:
	clm = get_node("/root/CareLoopManager")
	sm = get_node("/root/SceneManager")
	sm.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))


func before_each() -> void:
	TestReset.reset_all()
	stage = null
	requested = []
	sm.manual_step = true
	sm.loader = _swap
	loop_probe = FsmProbe.new().attach(clm.fsm)


func after_each() -> void:
	sm.loader = Callable()
	sm.manual_step = false
	stage = null


func _swap(path: String) -> void:
	if stage != null:
		stage.free()
	stage = (load(path) as PackedScene).instantiate() as Control
	stage.set("manual_step", true)
	viewport.add_child(stage)


func _mount_hub(size: Vector2i) -> void:
	viewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	_swap(CASA_PATH)
	await _settle()


func _settle() -> void:
	await wait_process_frames(3)
	if stage != null and stage.get_node_or_null("QuiQuiRig") != null:
		(stage.get_node("QuiQuiRig") as QuiQuiRig).manual_step = true


func _walk_to_play() -> void:
	clm.call("reset")
	clm.call("begin_step", CareSteps.FEED)
	clm.call("complete_step", CareSteps.FEED)
	clm.call("begin_step", CareSteps.BATH)
	clm.call("complete_step", CareSteps.BATH)
	clm.call("begin_step", CareSteps.DRESS)
	clm.call("complete_step", CareSteps.DRESS)
	clm.call("begin_step", CareSteps.PLAY)


func _enter_garden() -> void:
	var door: TapButton = (stage as CasaScene).door(CareSteps.PLAY)
	_deliver(door, TouchSim.tap_events(door, true))
	for step: int in range(SCENE_STEPS):
		sm.advance(SCENE_STEP_SEC)
	await _settle()


func _garden() -> GardenScene:
	return stage as GardenScene


func _deliver(control: Control, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		control._gui_input(TouchSim.gui_event(control, event))


func _tap(control: Control) -> void:
	_deliver(control, TouchSim.tap_events(control, true))


func _assert_journey(size: Vector2i) -> void:
	_walk_to_play()
	await _mount_hub(size)
	await _enter_garden()
	assert_true(stage is GardenScene, "%s: the garden is on stage" % size)

	for index: int in range(3):
		_tap(_garden().prop(index))

	assert_eq(_garden().fsm.state, GardenScene.STATE_FINISHED, "%s: play finished" % size)
	assert_eq(_garden().rig.expression_id, "jumping", "%s: she jumps" % size)
	assert_true(_garden().credited, "%s: PLAY credited" % size)
	assert_eq(str(clm.call("state_id")), CareSteps.SLEEP, "%s: SLEEP is next" % size)
	assert_eq(requested, [JARDIM_PATH, CASA_PATH], "%s: the Casa is asked for once" % size)

	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, size, GeometryOracle.STEP_ROOM_SPEC)
	assert_true(findings.is_empty(), "%s: %s" % [size, oracle.summary()])
	assert_true(loop_probe.is_clean(), "%s: %s" % [size, loop_probe.summary()])


func test_the_play_journey_at_16_9() -> void:
	await _assert_journey(GeometryOracle.DESKTOP_16_9)


func test_the_play_journey_on_ipad() -> void:
	await _assert_journey(GeometryOracle.IPAD_4_3)


# ── SC-E06-P1-22 coming back is free play, not a second reward ─────────────


func test_replaying_the_garden_after_play_is_free_play() -> void:
	_walk_to_play()
	await _mount_hub(GeometryOracle.DESKTOP_16_9)
	await _enter_garden()
	for index: int in range(3):
		_tap(_garden().prop(index))
	assert_eq(str(clm.call("state_id")), CareSteps.SLEEP)

	stage.free()
	stage = null
	_swap(JARDIM_PATH)
	await _settle()
	for index: int in range(3):
		_tap(_garden().prop(index))

	assert_eq(_garden().fsm.state, GardenScene.STATE_FINISHED, "the room still finishes")
	assert_false(_garden().credited, "but nothing is credited twice")
	assert_eq(str(clm.call("state_id")), CareSteps.SLEEP, "and the loop stays put")


# ── SC-E06-P2-23 leaving leaves no toy spinning ────────────────────────────


func test_leaving_mid_play_leaves_every_toy_at_rest() -> void:
	_walk_to_play()
	await _mount_hub(GeometryOracle.DESKTOP_16_9)
	await _enter_garden()
	_tap(_garden().prop(1))

	_tap(_garden().get_node("HomeButton") as TapButton)

	for index: int in range(3):
		assert_true(_garden().prop(index).is_idle(), "toy %d stopped" % index)
	assert_eq(str(clm.call("state_id")), CareSteps.IDLE, "the step is abandoned")
