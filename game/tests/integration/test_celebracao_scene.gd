# story: e07s02
extends GutTest
## The celebration: one burst, one voice, and the cycle's reward paid exactly once —
## atomically with the cycle counter (T-E07-03, T-E07-04).

const SCENE_PATH: String = "res://scenes/celebracao.tscn"
const CASA_PATH: String = "res://scenes/casa.tscn"

var scene: CelebrationScene = null
var viewport: SubViewport = null
var requested: Array[String] = []


func before_all() -> void:
	var sm: Node = get_node("/root/SceneManager")
	sm.scene_requested.connect(func(path: String, _queued: bool) -> void: requested.append(path))


func before_each() -> void:
	TestReset.reset_all()
	requested = []
	var pm: Node = get_node("/root/ProgressManager")
	pm.set_test_mode(true)
	pm.reset()


func after_each() -> void:
	if scene != null and is_instance_valid(scene):
		scene.queue_free()
	scene = null


func _walk_to_celebrate() -> void:
	var clm: Node = get_node("/root/CareLoopManager")
	clm.call("reset")
	for step: String in [CareSteps.FEED, CareSteps.BATH, CareSteps.DRESS, CareSteps.PLAY, CareSteps.SLEEP]:
		clm.call("begin_step", step)
		clm.call("complete_step", step)
	clm.call("begin_step", CareSteps.CELEBRATE)


func _mount(size: Vector2i = GeometryOracle.DESKTOP_16_9) -> CelebrationScene:
	viewport = SubViewport.new()
	viewport.size = size
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child_autofree(viewport)
	scene = (load(SCENE_PATH) as PackedScene).instantiate() as CelebrationScene
	scene.manual_step = true
	viewport.add_child(scene)
	return scene


# ── SC-E07-P0-07 the reward is paid once, with the counter ─────────────────


func test_entering_pays_once_and_moves_the_loop_to_idle() -> void:
	_walk_to_celebrate()
	var clm: Node = get_node("/root/CareLoopManager")
	var pm: Node = get_node("/root/ProgressManager")
	# The reward is granted when the loop *enters* CELEBRATE, before this scene mounts:
	# CareLoopManager owns money, the scene only closes the cycle.
	assert_eq(pm.call("get_coins"), CelebrationScene.COINS, "the reward landed on entry")
	assert_eq(pm.call("get_tickets"), CelebrationScene.TICKETS)

	_mount()
	await wait_process_frames(3)

	assert_eq(pm.call("get_coins"), CelebrationScene.COINS, "still exactly one reward")
	assert_eq(pm.call("get_tickets"), CelebrationScene.TICKETS)
	assert_eq(int(pm.data.completed_cycles), 1, "the counter moved with the reward")
	assert_eq(str(clm.call("state_id")), CareSteps.IDLE, "the cycle closed")
	assert_eq(requested, [CASA_PATH], "the Casa is requested once")


# ── SC-E07-P0-08 re-entering the same cycle pays nothing ──────────────────


func test_re_entering_the_same_cycle_pays_nothing() -> void:
	_walk_to_celebrate()
	var pm: Node = get_node("/root/ProgressManager")
	_mount()
	await wait_process_frames(3)
	assert_eq(pm.call("get_coins"), CelebrationScene.COINS)

	scene.queue_free()
	scene = null
	_mount()
	await wait_process_frames(3)

	assert_eq(pm.call("get_coins"), CelebrationScene.COINS, "no second payment")
	assert_eq(int(pm.data.completed_cycles), 1, "and no second cycle")


# ── SC-E07-P1-10 the clamps hold (BUG-007) ────────────────────────────────


func test_the_reward_respects_the_counters_ceilings() -> void:
	# Pin the counters *before* the loop enters CELEBRATE, because that is when the
	# reward is granted — clamping happens on that call, not on mount.
	var pm: Node = get_node("/root/ProgressManager")
	pm.data.coins = SaveData.MAX_COINS - 2
	pm.data.tickets = SaveData.MAX_TICKETS
	_walk_to_celebrate()

	_mount()
	await wait_process_frames(3)

	assert_eq(pm.call("get_coins"), SaveData.MAX_COINS, "coins clamp at the ceiling")
	assert_eq(pm.call("get_tickets"), SaveData.MAX_TICKETS, "tickets cannot overflow")


# ── SC-E07-P2-11 house rules ──────────────────────────────────────────────


func test_the_celebration_passes_the_oracle_and_has_no_text() -> void:
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		viewport = SubViewport.new()
		viewport.size = size
		viewport.disable_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		add_child_autofree(viewport)
		var mounted: CelebrationScene = (load(SCENE_PATH) as PackedScene).instantiate() as CelebrationScene
		mounted.manual_step = true
		viewport.add_child(mounted)
		await wait_process_frames(3)

		var oracle: GeometryOracle = GeometryOracle.new()
		var findings: Array[String] = oracle.audit(mounted, size, GeometryOracle.STEP_ROOM_SPEC)
		assert_true(findings.is_empty(), "%s: %s" % [size, oracle.summary()])
		for node: Node in mounted.find_children("*", "Label", true, false):
			assert_true((node as Label).text.is_empty(), "%s carries text" % node.name)
		mounted.queue_free()


# e07 review B: the celebration always returns by itself, even when there is nothing to pay.
func test_the_celebration_leaves_even_when_the_cycle_was_not_open() -> void:
	_mount()
	await wait_process_frames(3)

	assert_eq(requested, [CASA_PATH], "the only exit is not a 120 px corner button")
