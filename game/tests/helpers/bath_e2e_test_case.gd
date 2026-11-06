# story: e04s04
class_name BathE2eTestCase
extends GutTest
## Shared fixture for the Casa -> Banheiro -> Casa journey: the real autoloads, the
## real scene loader, and every gesture delivered through `TouchSim.gui_event` so the
## local/global conversion is exercised rather than assumed.

const CASA_PATH: String = "res://scenes/casa.tscn"
const BANHEIRO_PATH: String = "res://scenes/banheiro.tscn"
const SCENE_STEP_SEC: float = 0.1
const SCENE_STEPS: int = 30
const GAP_SEC: float = 1.0
## One drag per patch: press on the sponge, sweep to the patch, release.
const DRAG_STEPS: int = 8
const BODY_SWEEP_STEPS: int = 16
## A child sweeps back and forth; one pass starts on the device, so only its last
## steps are on her body. Three passes is what a real rinse looks like.
const SWEEP_PASSES: int = 3

var clm: Node = null
var sm: Node = null
var am: Node = null
var diary: Node = null

var viewport: SubViewport = null
var stage: Control = null
var requested: Array[String] = []
var refused_requests: Array[String] = []
var loop_probe: FsmProbe = null
var scene_probe: FsmProbe = null
var bath_probes: Array[FsmProbe] = []


func before_all() -> void:
	clm = get_node("/root/CareLoopManager")
	sm = get_node("/root/SceneManager")
	am = get_node("/root/AudioManager")
	diary = get_node("/root/Log")
	sm.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))
	sm.transition_rejected.connect(func(path: String, _why: String) -> void: refused_requests.append(path))


func before_each() -> void:
	TestReset.reset_all()
	stage = null
	requested = []
	refused_requests = []
	bath_probes = []
	sm.manual_step = true
	sm.loader = _swap
	loop_probe = FsmProbe.new().attach(clm.fsm)
	scene_probe = FsmProbe.new().attach(sm.fsm)


func after_each() -> void:
	sm.loader = Callable()
	sm.manual_step = false
	am.reset()
	stage = null


func _swap(path: String) -> void:
	if stage != null:
		stage.free()
	stage = (load(path) as PackedScene).instantiate() as Control
	stage.set("manual_step", true)
	viewport.add_child(stage)
	if stage is BathScene:
		bath_probes.append(FsmProbe.new().attach((stage as BathScene).fsm))


# ── journey ─────────────────────────────────────────────────────────────────


## Walks the care loop to BATH the way a child would leave it: FEED done.
func _advance_loop_to_bath() -> void:
	clm.call("begin_step", CareSteps.FEED)
	clm.call("complete_step", CareSteps.FEED)
	clm.call("begin_step", CareSteps.BATH)


func _open_casa(size: Vector2i) -> void:
	viewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	_swap(CASA_PATH)
	await _settle()


func _enter_bath() -> void:
	var door: TapButton = (stage as CasaScene).door(CareSteps.BATH)
	_deliver(door, TouchSim.tap_events(door, true))
	for step: int in range(SCENE_STEPS):
		sm.advance(SCENE_STEP_SEC)
	await _settle()


func _settle() -> void:
	await wait_process_frames(3)
	if stage == null:
		return
	if stage is CasaScene:
		(stage.get_node("QuiQuiRig") as QuiQuiRig).manual_step = true
	if stage is BathScene:
		var bath: BathScene = stage as BathScene
		bath.rig.manual_step = true
		for device: TouchDraggable in [bath.sponge, bath.shower, bath.towel]:
			device.manual_step = true


func _bath() -> BathScene:
	return stage as BathScene


# ── gestures ────────────────────────────────────────────────────────────────


func _deliver(control: Control, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		control._gui_input(TouchSim.gui_event(control, event))


## Soaps one patch: press on the sponge, sweep the finger to the patch, release.
func _scrub_patch(index: int) -> void:
	var bath: BathScene = _bath()
	var target: Vector2 = bath.blob(index).get_global_rect().get_center()
	_deliver(bath.sponge, TouchSim.drag_events(bath.sponge, target, DRAG_STEPS, true))


func _sweep(device: TouchDraggable, steps: int) -> void:
	var body: Rect2 = _bath().rig.get_visual_global_rect()
	var centre: Vector2 = body.get_center()
	for pass_index: int in range(SWEEP_PASSES):
		# Alternate above and below the centre so the sweep covers her body, the way
		# a child rubs up and down rather than tapping one pixel.
		var offset: float = body.size.y * 0.18 * (1.0 if pass_index % 2 == 0 else -1.0)
		_deliver(device, TouchSim.drag_events(device, centre + Vector2(0.0, offset), steps, true))


func _soak_every_patch() -> void:
	for index: int in range(_bath().blob_count()):
		_scrub_patch(index)


func _rinse() -> void:
	_soak_every_patch()
	_bath().advance(GAP_SEC)
	_sweep(_bath().shower, BODY_SWEEP_STEPS)
	_bath().advance(GAP_SEC)


func _dry() -> void:
	_sweep(_bath().towel, BODY_SWEEP_STEPS)


# ── assertions ──────────────────────────────────────────────────────────────


func _assert_oracle_clean(size: Vector2i) -> void:
	var oracle: GeometryOracle = GeometryOracle.new()
	var findings: Array[String] = oracle.audit(stage, size, GeometryOracle.STEP_ROOM_SPEC)
	assert_true(findings.is_empty(), "%s: %s" % [size, oracle.summary()])


## The patches are on her body, and their art stays inside the painted character —
## the 4:3 failure this whole epic exists to prevent.
func _assert_patches_on_the_body(size: Vector2i) -> void:
	var bath: BathScene = _bath()
	var hull: PackedVector2Array = bath.rig.scrub_hull_global()
	var painted: Rect2 = bath.rig.get_visual_global_rect()
	for index: int in range(bath.blob_count()):
		var rect: Rect2 = bath.blob(index).get_global_rect()
		assert_true(
			Geometry2D.is_point_in_polygon(rect.get_center(), hull),
			"%s: patch %d centre must sit inside the hull" % [size, index],
		)
		assert_true(painted.intersects(rect), "%s: patch %d must overlap her body" % [size, index])
		assert_false(rect.encloses(painted), "%s: patch %d is not bigger than she is" % [size, index])


func _assert_probes_clean() -> void:
	assert_true(loop_probe.is_clean(), "care_loop: %s" % loop_probe.summary())
	assert_true(scene_probe.is_clean(), "scene: %s" % scene_probe.summary())
	assert_false(bath_probes.is_empty(), "the bath machine was watched")
	for probe: FsmProbe in bath_probes:
		assert_true(probe.is_clean(), "bath: %s" % probe.summary())
