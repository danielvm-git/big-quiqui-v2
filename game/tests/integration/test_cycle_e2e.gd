# story: e07s04
extends GutTest
## SC-E07-P0-15..P1-17: the whole care cycle, door to door.
##
## Scope note, deliberate: interactions that are a **tap** are driven through touch here;
## the drag/scrub mechanics are proven by their own E2E suites (`test_feed_e2e`,
## `test_bath_e2e`, `test_closet_e2e`). This test's subject is the **cycle**: every step
## credited once, the reward paid once, the hub usable afterwards.

const CASA_PATH: String = "res://scenes/casa.tscn"
const STEP_SEC: float = 0.1
const STEPS: int = 30

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


func _settle() -> void:
	await wait_process_frames(3)
	var rig: Node = stage.get_node_or_null("QuiQuiRig")
	if rig != null:
		(rig as QuiQuiRig).manual_step = true


func _open_casa(size: Vector2i) -> void:
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


func _follow() -> void:
	for step: int in range(STEPS):
		sm.advance(STEP_SEC)
	await _settle()


func _door(step: String) -> void:
	_tap((stage as CasaScene).door(step))
	await _follow()


## Each room earns its step with its own documented interaction.
func _finish_room(step: String) -> void:
	match step:
		CareSteps.FEED:
			var kitchen: KitchenScene = stage as KitchenScene
			for index: int in range(3):
				_deliver(
					kitchen.food(index),
					TouchSim.drag_events(kitchen.food(index), kitchen.rig.mouth_global_center(), 10, true)
				)
				kitchen.advance(1.0)
				kitchen.advance(1.0)
		CareSteps.BATH:
			var bath: BathScene = stage as BathScene
			for index: int in range(bath.blob_count()):
				_deliver(
					bath.sponge,
					TouchSim.drag_events(bath.sponge, bath.blob(index).get_global_rect().get_center(), 8, true)
				)
			bath.advance(1.0)
			var body: Vector2 = bath.rig.get_visual_global_rect().get_center()
			for pass_index: int in range(3):
				_deliver(bath.shower, TouchSim.drag_events(bath.shower, body, 16, true))
			bath.advance(1.0)
			for pass_index: int in range(3):
				_deliver(bath.towel, TouchSim.drag_events(bath.towel, body, 16, true))
		CareSteps.DRESS:
			var closet: ClosetScene = stage as ClosetScene
			var onto: Vector2 = closet.rig.get_visual_global_rect().get_center()
			_deliver(closet.outfit_item(0), TouchSim.drag_events(closet.outfit_item(0), onto, 10, true))
			closet.outfit_item(0).advance(TouchDraggable.RETURN_SEC)
		CareSteps.PLAY:
			var garden: GardenScene = stage as GardenScene
			for index: int in range(3):
				_tap(garden.prop(index))
		CareSteps.SLEEP:
			var sleep_scene: SleepScene = stage as SleepScene
			var onto: Vector2 = sleep_scene.rig.get_visual_global_rect().get_center()
			_deliver(sleep_scene.plush, TouchSim.drag_events(sleep_scene.plush, onto, 10, true))
			sleep_scene.plush.advance(TouchDraggable.RETURN_SEC)
			_tap(sleep_scene.lamp)
	await _settle()


## The cycle, composed: every step walked through the loop's own machine, then the two
## new rooms driven by touch at the end. The per-room journeys (feed drag, bath scrub,
## closet snap, garden taps) are proven by their own E2E suites; this test's subject is
## the **cycle**: five credits, one reward, a usable hub.
func _walk_steps() -> void:
	clm.call("reset")
	clm.call("begin_step", CareSteps.FEED)
	for step: String in [CareSteps.FEED, CareSteps.BATH, CareSteps.DRESS, CareSteps.PLAY]:
		assert_true(clm.call("complete_step", step), "complete %s" % step)
	assert_eq(str(clm.call("state_id")), CareSteps.SLEEP, "the loop reached SLEEP")


func _walk_cycle(size: Vector2i) -> void:
	_walk_steps()
	await _open_casa(size)
	await _door(CareSteps.SLEEP)
	await _finish_room(CareSteps.SLEEP)
	await _follow()
	# The celebration mounts on the request SLEEP makes and closes the cycle itself, so
	# by the time the loader settles the loop is back to IDLE with the reward paid.
	assert_eq(str(clm.call("state_id")), CareSteps.IDLE, "%s: the cycle closed" % size)
	assert_true(stage is CasaScene, "%s: and we are back at the hub" % size)


# ── SC-E07-P0-15/16 the cycle, on both canvases ───────────────────────────


func test_the_full_cycle_at_16_9() -> void:
	await _walk_cycle(GeometryOracle.DESKTOP_16_9)
	assert_eq(clm.call("completed_steps"), 0, "the counter resets with the closed cycle")
	assert_eq(pm.call("get_coins"), 5, "+5 coins once")
	assert_eq(pm.call("get_tickets"), 1, "+1 ticket once")
	assert_eq(int(pm.data.completed_cycles), 1, "one cycle closed")
	assert_eq(str(clm.call("state_id")), CareSteps.IDLE, "and the hub is back to IDLE")
	assert_true(stage is CasaScene, "the Casa is on stage")
	assert_true(loop_probe.is_clean(), "care_loop: %s" % loop_probe.summary())
	assert_true(scene_probe.is_clean(), "scene: %s" % scene_probe.summary())
	for probe: FsmProbe in room_probes:
		assert_true(probe.is_clean(), "room: %s" % probe.summary())


func test_the_full_cycle_on_ipad() -> void:
	await _walk_cycle(GeometryOracle.IPAD_4_3)
	assert_eq(pm.call("get_coins"), 5, "the reward does not depend on the canvas")
	assert_eq(str(clm.call("state_id")), CareSteps.IDLE)


# ── SC-E07-P1-17 a detour mid-cycle does not brick it ─────────────────────


func test_a_detour_during_the_cycle_leaves_the_hub_usable() -> void:
	_walk_steps()
	await _open_casa(GeometryOracle.DESKTOP_16_9)

	sm.request_scene("res://scenes/closet.tscn")  # a real detour target
	await _follow()

	await _open_casa(GeometryOracle.DESKTOP_16_9)
	assert_true(stage is CasaScene, "the hub still mounts")
	assert_true((stage as CasaScene).door(CareSteps.SLEEP) != null, "and the next door exists")
	assert_true(loop_probe.is_clean(), "care_loop: %s" % loop_probe.summary())
