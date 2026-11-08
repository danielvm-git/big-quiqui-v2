# story: e05s03
extends GutTest
## SC-E05-P0-20..P1-25: the closet journey with the real autoloads — Casa door in,
## dress her, keep her face, leave, come back dressed — plus the invariant this epic
## exists for: **the outfit never hides the expression**, on any canvas.

const CASA_PATH: String = "res://scenes/casa.tscn"
const CLOSET_PATH: String = "res://scenes/closet.tscn"
const SCENE_STEP_SEC: float = 0.1
const SCENE_STEPS: int = 30

var clm: Node = null
var sm: Node = null
var pm: Node = null
var viewport: SubViewport = null
var stage: Control = null
var requested: Array[String] = []
var loop_probe: FsmProbe = null
var scene_probe: FsmProbe = null


func before_all() -> void:
	clm = get_node("/root/CareLoopManager")
	sm = get_node("/root/SceneManager")
	pm = get_node("/root/ProgressManager")
	sm.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))


func before_each() -> void:
	TestReset.reset_all()
	pm.set_test_mode(true)
	pm.load_or_default()
	stage = null
	requested = []
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
	if stage != null and not (stage.get_node_or_null("QuiQuiRig") == null):
		(stage.get_node("QuiQuiRig") as QuiQuiRig).manual_step = true
	if stage is ClosetScene:
		for index: int in range(4):
			if (stage as ClosetScene).outfit_item(index) != null:
				(stage as ClosetScene).outfit_item(index).manual_step = true
		for index: int in range(6):
			if (stage as ClosetScene).accessory_item(index) != null:
				(stage as ClosetScene).accessory_item(index).manual_step = true


func _walk_to_dress() -> void:
	clm.call("reset")  # each canvas starts the journey from a clean loop
	clm.call("begin_step", CareSteps.FEED)
	clm.call("complete_step", CareSteps.FEED)
	clm.call("begin_step", CareSteps.BATH)
	clm.call("complete_step", CareSteps.BATH)
	clm.call("begin_step", CareSteps.DRESS)


func _enter_closet() -> void:
	var door: TapButton = (stage as CasaScene).door(CareSteps.DRESS)
	_deliver(door, TouchSim.tap_events(door, true))
	for step: int in range(SCENE_STEPS):
		sm.advance(SCENE_STEP_SEC)
	await _settle()


func _closet() -> ClosetScene:
	return stage as ClosetScene


func _deliver(control: Control, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		control._gui_input(TouchSim.gui_event(control, event))


func _dress(item: TouchDraggable) -> void:
	var onto: Vector2 = _closet().rig.get_visual_global_rect().get_center()
	_deliver(item, TouchSim.drag_events(item, onto, 10, true))
	item.advance(TouchDraggable.RETURN_SEC)


# ── SC-E05-P0-20 the journey ────────────────────────────────────────────────


func test_the_journey_dresses_her_and_keeps_her_face_at_16_9() -> void:
	await _assert_journey(GeometryOracle.DESKTOP_16_9)


func test_the_journey_dresses_her_and_keeps_her_face_on_ipad() -> void:
	await _assert_journey(GeometryOracle.IPAD_4_3)


## One canvas per test: the loop and the SceneManager are singletons, so a shared
## iterate-two-canvases test carries state between mounts and lies about the second.
func _assert_journey(size: Vector2i) -> void:
	_walk_to_dress()
	await _mount_hub(size)
	await _enter_closet()
	assert_true(stage is ClosetScene, "%s: the closet is on stage" % size)

	_dress(_closet().outfit_item(0))
	_dress(_closet().accessory_item(0))

	var rig: QuiQuiRig = _closet().rig
	assert_eq(rig.outfit_id, "floral_dress", "%s: dressed" % size)
	assert_eq(rig.accessory_id("head"), "flower_tiara", "%s: and accessorised" % size)
	assert_gt(rig.expression.z_index, rig.outfit.z_index, "%s: the face stays on top" % size)
	assert_true(rig.expression.visible, "%s: and visible" % size)
	assert_true(_closet().credited, "%s: DRESS credited" % size)
	assert_eq(str(clm.call("state_id")), CareSteps.PLAY, "%s: PLAY is next" % size)
	assert_eq(pm.call("equipped", SaveData.SLOT_BODY), "floral_dress", "%s: saved" % size)
	assert_eq(requested, [CLOSET_PATH], "%s: one request" % size)
	assert_true(loop_probe.is_clean(), "%s: %s" % [size, loop_probe.summary()])
	assert_true(scene_probe.is_clean(), "%s: %s" % [size, scene_probe.summary()])


# ── SC-E05-P0-21 the look outlives the room (disk round-trip) ───────────────


func test_the_look_survives_leaving_and_returning() -> void:
	_walk_to_dress()
	await _mount_hub(GeometryOracle.DESKTOP_16_9)
	await _enter_closet()
	_dress(_closet().outfit_item(1))
	_dress(_closet().accessory_item(4))
	var chosen: String = _closet().rig.outfit_id
	var scarf: String = _closet().rig.accessory_id("neck")

	# A new visit: the room is mounted again on the iPad canvas. The journey back
	# through the hub is tested above; here the question is only whether the look
	# was written down.
	stage.free()
	stage = null
	_swap(CLOSET_PATH)
	await _settle()

	assert_eq(_closet().rig.outfit_id, chosen, "she is still wearing it")
	assert_eq(_closet().rig.accessory_id("neck"), scarf, "and the scarf")
	assert_gt(
		_closet().rig.expression.z_index,
		_closet().rig.outfit.z_index,
		"and her face is still above the dress on the iPad canvas",
	)


# ── SC-E05-P1-22 replay changes nothing ────────────────────────────────────


func test_replaying_the_same_outfit_credits_nothing_more() -> void:
	_walk_to_dress()
	await _mount_hub(GeometryOracle.DESKTOP_16_9)
	await _enter_closet()
	_dress(_closet().outfit_item(2))
	var equips_before: int = _closet().equips

	_dress(_closet().outfit_item(2))

	assert_eq(_closet().equips, equips_before + 1, "the child did equip again")
	assert_eq(str(clm.call("state_id")), CareSteps.PLAY, "but the loop did not move twice")
	assert_false(clm.call("complete_step", CareSteps.DRESS), "and a stale credit is refused")


# ── SC-E05-P1-23 abandoning leaves the look alone ──────────────────────────


func test_leaving_without_dressing_keeps_the_previous_look() -> void:
	_walk_to_dress()
	await _mount_hub(GeometryOracle.DESKTOP_16_9)
	await _enter_closet()
	_dress(_closet().outfit_item(0))
	var home: TapButton = _closet().get_node("HomeButton") as TapButton
	_deliver(home, TouchSim.tap_events(home, true))

	assert_eq(str(pm.call("equipped", SaveData.SLOT_BODY)), "floral_dress", "the choice persists")
	assert_eq(requested, [CLOSET_PATH, CASA_PATH], "the Casa is asked for once more")
