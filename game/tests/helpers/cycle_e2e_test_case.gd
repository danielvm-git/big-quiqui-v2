# story: e07s04
class_name CycleE2eTestCase
extends GutTest
## Shared fixture for the five-step care cycle (e07s04 §3): the loader, the per-scene probes
## and the per-stage layout audit. The tests only describe the journey.
##
## Scope note, deliberate: interactions that are a **tap** are driven through touch here, and the
## bedroom — the room this epic delivers — is played by hand. The drag/scrub mechanics of the
## first four rooms are proven by their own E2E suites (`test_feed_e2e`, `test_bath_e2e`,
## `test_closet_e2e`, the garden journey). The subject here is the **cycle**: every step
## credited once, the reward paid once, the hub usable afterwards.

const CASA_PATH: String = "res://scenes/casa.tscn"
const ALBUM_PATH: String = "res://scenes/album.tscn"
const STEP_SEC: float = 0.1
const STEPS: int = 30
## The four rooms the cycle walks through the loop's own machine (guest rooms of earlier epics).
const WALKED_STEPS: Array[String] = [CareSteps.FEED, CareSteps.BATH, CareSteps.DRESS, CareSteps.PLAY]

var clm: Node = null
var sm: Node = null
var pm: Node = null
var viewport: SubViewport = null
var stage: Control = null
var requested: Array[String] = []
var loop_probe: FsmProbe = null
var scene_probe: FsmProbe = null
var room_probes: Array[FsmProbe] = []


func before_all() -> void:
	clm = get_node("/root/CareLoopManager")
	sm = get_node("/root/SceneManager")
	pm = get_node("/root/ProgressManager")
	sm.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))


func before_each() -> void:
	TestReset.reset_all()
	pm.set_test_mode(true)
	pm.reset()
	stage = null
	requested = []
	room_probes = []
	sm.manual_step = true
	sm.loader = _swap
	loop_probe = FsmProbe.new().attach(clm.fsm)
	scene_probe = FsmProbe.new().attach(sm.fsm)


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
	var machine: Variant = stage.get("fsm")
	if machine is Fsm:
		room_probes.append(FsmProbe.new().attach(machine as Fsm))


## Lets the frame settle, freezes the rig's idle timer, then audits the layout of the stage
## that just mounted (e07s04 AC4: every scene passes the oracle **during** the journey).
func _settle() -> void:
	await wait_process_frames(3)
	var rig: Node = stage.get_node_or_null("QuiQuiRig")
	if rig != null:
		(rig as QuiQuiRig).manual_step = true
	_audit_layout()


func _audit_layout() -> void:
	var spec: Dictionary = GeometryOracle.CARE_ROOM_SPEC if stage is CasaScene else GeometryOracle.STEP_ROOM_SPEC
	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, viewport.size, spec)
	assert_true(findings.is_empty(), "%s: %s" % [stage.name, oracle.summary()])


func _open_casa(size: Vector2i) -> void:
	if viewport == null:
		viewport = SubViewport.new()
		viewport.size = size
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child_autofree(viewport)
	_swap(CASA_PATH)
	await _settle()


func _deliver(control: Control, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		control._gui_input(TouchSim.gui_event(control, event))


func _tap(control: Control) -> void:
	_deliver(control, TouchSim.tap_events(control, true))


## Steps the transition machine **and** the mounted stage's own clock: every room in this
## project advances through `advance(delta)` (the celebration holds for HOLD_SEC before it
## goes home), so a manual-step test must drive both or the party never ends.
func _follow() -> void:
	for step: int in range(STEPS):
		sm.advance(STEP_SEC)
		if stage != null and stage.has_method("advance"):
			stage.call("advance", STEP_SEC)
	await _settle()


func _door(step: String) -> void:
	_tap((stage as CasaScene).door(step))
	await _follow()


## The bedroom earns its step the way a child plays it: tuck the plush, tap the lamp.
func _tuck_her_in() -> void:
	var sleep_scene: SleepScene = stage as SleepScene
	var onto: Vector2 = sleep_scene.rig.get_visual_global_rect().get_center()
	_deliver(sleep_scene.plush, TouchSim.drag_events(sleep_scene.plush, onto, 10, true))
	sleep_scene.plush.advance(TouchDraggable.RETURN_SEC)
	_tap(sleep_scene.lamp)


## Credits one step through the loop's own machine (a room of an earlier epic).
func _walk_step(step: String) -> void:
	assert_true(bool(clm.call("complete_step", step)), "credit %s" % step)
	_assert_step_credited(step)


func _assert_step_credited(step: String) -> void:
	var expected: int = CareSteps.ORDER.find(step) + 1
	assert_eq(int(clm.call("completed_steps")), expected, "%s is credited once" % step)


func _assert_probes_clean() -> void:
	assert_true(loop_probe.is_clean(), "care_loop: %s" % loop_probe.summary())
	assert_true(scene_probe.is_clean(), "scene: %s" % scene_probe.summary())
	for probe: FsmProbe in room_probes:
		assert_true(probe.is_clean(), "room: %s" % probe.summary())


## Walks the cycle to the celebration. With `party` false the celebration is not mounted, so the
## `CELEBRATE` state stays observable (the state a detour must survive).
func _walk_cycle(size: Vector2i, party: bool = true) -> void:
	clm.call("reset")
	clm.call("begin_step", CareSteps.FEED)
	for step: String in WALKED_STEPS:
		_walk_step(step)
	assert_eq(str(clm.call("state_id")), CareSteps.SLEEP, "the loop reached SLEEP")
	await _open_casa(size)
	await _door(CareSteps.SLEEP)
	if not party:
		sm.loader = func(_path: String) -> void: pass
	_tuck_her_in()
	await _follow()
