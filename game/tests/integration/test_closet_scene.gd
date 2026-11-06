# story: e05s02
extends GutTest
## The closet: drag an item onto her and she wears it. A drop elsewhere changes
## nothing, the look is saved, and DRESS is credited once (T-E05-02).

const SCENE_PATH: String = "res://scenes/closet.tscn"

var scene: ClosetScene = null
var viewport: SubViewport = null


func before_each() -> void:
	TestReset.reset_all()
	var pm: Node = get_node("/root/ProgressManager")
	pm.set_test_mode(true)
	pm.load_or_default()


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _mount(size: Vector2i = GeometryOracle.DESKTOP_16_9) -> ClosetScene:
	viewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	var packed: PackedScene = load(SCENE_PATH) as PackedScene
	assert_not_null(packed, "closet.tscn must load")
	scene = packed.instantiate() as ClosetScene
	scene.manual_step = true
	viewport.add_child(scene)
	return scene


func _deliver(control: Control, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		control._gui_input(TouchSim.gui_event(control, event))


## Drops item onto the character, the way a finger would.
func _drop_on_her(item: TouchDraggable) -> void:
	var onto: Vector2 = scene.rig.get_visual_global_rect().get_center()
	_deliver(item, TouchSim.drag_events(item, onto, 10, true))
	item.advance(TouchDraggable.RETURN_SEC)


func _drop_on_the_floor(item: TouchDraggable) -> void:
	_deliver(item, TouchSim.drag_events(item, Vector2(6.0, 6.0), 10, true))
	item.advance(TouchDraggable.RETURN_SEC)


# ── SC-E05-P0-10 the wardrobe exists and is reachable ───────────────────────


func test_the_closet_has_four_outfits_and_six_accessories() -> void:
	_mount()
	await wait_process_frames(3)

	for index: int in range(4):
		assert_not_null(scene.outfit_item(index), "outfit %d" % index)
	for index: int in range(6):
		assert_not_null(scene.accessory_item(index), "accessory %d" % index)
	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(scene, GeometryOracle.DESKTOP_16_9, GeometryOracle.STEP_ROOM_SPEC)
	assert_true(findings.is_empty(), oracle.summary())


# ── SC-E05-P0-11 dropping on her equips and saves ───────────────────────────


func test_dropping_an_outfit_on_her_equips_and_saves_it() -> void:
	_mount()
	await wait_process_frames(3)
	var pm: Node = get_node("/root/ProgressManager")

	_drop_on_her(scene.outfit_item(1))

	assert_eq(scene.rig.outfit_id, "vestido_vermelho", "she is wearing what was dropped")
	assert_eq(str(pm.call("equipped", SaveData.SLOT_BODY)), "vestido_vermelho", "and it is saved")
	assert_eq(scene.equips, 1)
	assert_eq(scene.outfit_item(1).state_id(), "REST", "the hanger flew home")


func test_dropping_an_accessory_equips_that_slot_only() -> void:
	_mount()
	await wait_process_frames(3)

	_drop_on_her(scene.accessory_item(0))

	assert_eq(scene.rig.accessory_id("head"), "tiara_flores")
	assert_eq(scene.rig.accessory_id("eyes"), "", "other slots stay empty")


# ── SC-E05-P1-12 a miss changes nothing ─────────────────────────────────────


func test_a_drop_off_the_character_changes_nothing() -> void:
	_mount()
	await wait_process_frames(3)
	var pm: Node = get_node("/root/ProgressManager")

	_drop_on_the_floor(scene.outfit_item(0))

	assert_eq(scene.rig.outfit_id, "", "nothing equipped")
	assert_eq(scene.equips, 0)
	assert_eq(str(pm.call("equipped", SaveData.SLOT_BODY)), "", "and nothing saved")


# ── SC-E05-P0-13 the look survives a new room ──────────────────────────────


func test_the_next_visit_opens_already_dressed() -> void:
	_mount()
	await wait_process_frames(3)
	_drop_on_her(scene.outfit_item(2))
	_drop_on_her(scene.accessory_item(3))
	scene.queue_free()
	scene = null

	_mount(Vector2i(2048, 1536))
	await wait_process_frames(3)

	assert_eq(scene.rig.outfit_id, "macacao_verde", "the dress came back from disk")
	assert_eq(scene.rig.accessory_id("neck"), "cachecol_azul", "and so did the scarf")
	# The face must still be above the dress on the iPad canvas (T-E05-03).
	assert_gt(scene.rig.expression.z_index, scene.rig.outfit.z_index)


# ── SC-E05-P0-14 DRESS is credited once (T-E05-02) ─────────────────────────


func test_equipping_credits_dress_once_and_moves_on() -> void:
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("begin_step", CareSteps.FEED)
	clm.call("complete_step", CareSteps.FEED)
	clm.call("begin_step", CareSteps.BATH)
	clm.call("complete_step", CareSteps.BATH)
	clm.call("begin_step", CareSteps.DRESS)
	assert_eq(str(clm.call("state_id")), CareSteps.DRESS)

	_mount()
	await wait_process_frames(3)
	_drop_on_her(scene.outfit_item(0))
	_drop_on_her(scene.accessory_item(1))
	_drop_on_her(scene.accessory_item(2))

	assert_true(scene.credited, "DRESS is credited")
	assert_eq(str(clm.call("state_id")), CareSteps.PLAY, "the loop moved to PLAY")
	assert_false(clm.call("complete_step", CareSteps.DRESS), "and refuses a second credit")


func test_equipping_when_dress_is_not_the_step_credits_nothing() -> void:
	_mount()
	await wait_process_frames(3)

	_drop_on_her(scene.outfit_item(0))

	assert_false(scene.credited)
	assert_eq(scene.equips, 1, "the child still dressed her, it just is not this step")


# ── house rules ────────────────────────────────────────────────────────────


func test_the_closet_has_no_text() -> void:
	_mount()
	await wait_process_frames(3)

	for node: Node in scene.find_children("*", "Label", true, false):
		assert_true((node as Label).text.is_empty(), "%s carries text" % node.name)


func test_leaving_before_dressing_abandons_the_step() -> void:
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("begin_step", CareSteps.FEED)
	clm.call("complete_step", CareSteps.FEED)
	clm.call("begin_step", CareSteps.BATH)
	clm.call("complete_step", CareSteps.BATH)
	clm.call("begin_step", CareSteps.DRESS)

	_mount()
	await wait_process_frames(3)
	var home: TapButton = scene.get_node("HomeButton") as TapButton
	_deliver(home, TouchSim.tap_events(home, true))

	assert_eq(str(clm.call("state_id")), CareSteps.IDLE, "the step is abandoned")
	assert_false(scene.credited)
