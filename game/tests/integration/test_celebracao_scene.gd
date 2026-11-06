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


func _deliver(control: Control, events: Array[InputEvent]) -> void:
	for event: InputEvent in events:
		control._gui_input(TouchSim.gui_event(control, event))


func _tap(control: Control) -> void:
	_deliver(control, TouchSim.tap_events(control, true))


## The party holds for HOLD_SEC and then leaves by itself; in tests the scene's clock is
## stepped by hand (`manual_step`), so "the party is over" is an explicit call.
func _end_party() -> void:
	scene.advance(CelebrationScene.HOLD_SEC)


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
	assert_eq(pm.call("get_coins"), pm.CYCLE_COINS_REWARD, "the reward landed on entry")
	assert_eq(pm.call("get_tickets"), pm.CYCLE_TICKETS_REWARD)

	_mount()
	await wait_process_frames(3)

	assert_eq(pm.call("get_coins"), pm.CYCLE_COINS_REWARD, "still exactly one reward")
	assert_eq(pm.call("get_tickets"), pm.CYCLE_TICKETS_REWARD)
	assert_eq(int(pm.data.completed_cycles), 1, "the counter moved with the reward")
	assert_eq(str(clm.call("state_id")), CareSteps.IDLE, "the cycle closed")
	assert_eq(requested, [], "and the party is still on: the child gets to see it")

	_end_party()

	assert_eq(requested, [CASA_PATH], "then the Casa is requested once")


# ── SC-E07-P0-08 re-entering the same cycle pays nothing ──────────────────


func test_re_entering_the_same_cycle_pays_nothing() -> void:
	_walk_to_celebrate()
	var pm: Node = get_node("/root/ProgressManager")
	_mount()
	await wait_process_frames(3)
	assert_eq(pm.call("get_coins"), pm.CYCLE_COINS_REWARD)

	_end_party()
	scene.queue_free()
	scene = null
	requested = []
	_mount()
	await wait_process_frames(3)

	assert_eq(pm.call("get_coins"), pm.CYCLE_COINS_REWARD, "no second payment")
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
	assert_eq(requested, [], "the party holds first")

	_end_party()

	assert_eq(requested, [CASA_PATH], "the only exit is not a 120 px corner button")


## e07 post-epic (review B should-fix 5): the party plays a voice over the hub's theme.
## Restarting that theme puts the first note of the track under "parabéns".
func test_the_celebration_does_not_restart_the_theme_it_arrives_on() -> void:
	var audio: Node = get_node("/root/AudioManager")
	audio.call("play_music", load(CelebrationScene.MUSIC_PATH) as AudioStream)
	var active: AudioStreamPlayer = audio.get("_active_music")

	_mount()

	assert_eq(audio.get("_active_music"), active, "play_music swaps players: it was not called")
	assert_true(bool(audio.call("is_music_playing", load(CelebrationScene.MUSIC_PATH) as AudioStream)))


## e07s02 AC2: "the once-per-cycle guard is asserted from the scene, not assumed". The ledger
## lives in `CareLoopManager`; a second grant in the same cycle must pay nothing.
func test_a_second_grant_in_the_same_cycle_pays_nothing() -> void:
	_walk_to_celebrate()
	var clm: Node = get_node("/root/CareLoopManager")
	var pm: Node = get_node("/root/ProgressManager")
	var paid_cycle: int = int(clm.get("_rewarded_cycle_id"))
	assert_eq(paid_cycle, int(clm.get("cycle_id")), "the ledger names the cycle it paid")

	clm.call("_grant_cycle_reward")

	assert_eq(pm.call("get_coins"), pm.CYCLE_COINS_REWARD, "the ledger refuses a second payment")
	assert_eq(int(pm.data.completed_cycles), 1)


## e07s02 AC5: "HomeButton leaves early without paying twice". Nothing tapped it before.
func test_home_leaves_early_and_the_reward_is_already_paid() -> void:
	_walk_to_celebrate()
	var pm: Node = get_node("/root/ProgressManager")
	_mount()
	await wait_process_frames(3)

	_tap(scene.get_node("HomeButton") as TapButton)

	assert_eq(requested, [CASA_PATH], "the Casa is requested once, early or late")
	_end_party()
	assert_eq(requested, [CASA_PATH], "and the hold does not request it again")
	assert_eq(pm.call("get_coins"), pm.CYCLE_COINS_REWARD, "and nothing was paid twice")
	assert_eq(int(pm.data.completed_cycles), 1)


# ── SC-E07-P1-18 the reward is revealed, and the party holds (BUG-031) ────


func test_the_party_holds_then_shows_what_she_earned() -> void:
	_walk_to_celebrate()
	_mount()
	await wait_process_frames(3)

	assert_false(scene.revealed, "the burst lands first")
	assert_false(scene.coin.visible, "the coin is hidden at the start")
	assert_false(scene.ticket.visible)

	scene.advance(CelebrationScene.REVEAL_LEAD_SEC + CelebrationScene.REVEAL_POP_SEC)

	assert_true(scene.revealed, "then the reward arrives")
	assert_true(scene.coin.visible, "one coin")
	assert_true(scene.ticket.visible, "one ticket")
	assert_almost_eq(scene.coin.modulate.a, 1.0, 0.01, "at full opacity")
	assert_almost_eq(scene.coin.scale.x, 1.0, 0.01, "and full size")
	assert_eq(requested, [], "while the party is still on")


func test_the_reward_icons_are_art_not_buttons() -> void:
	_mount()
	await wait_process_frames(3)
	for icon: TextureRect in [scene.coin, scene.ticket]:
		assert_not_null(icon, "the generated scene declares it")
		assert_eq(icon.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s is not a target" % icon.name)
		assert_false(icon.is_in_group("hit_target"), "%s never joins the hit targets" % icon.name)


func test_the_party_leaves_by_itself_after_the_hold() -> void:
	_walk_to_celebrate()
	_mount()
	await wait_process_frames(3)
	var half: float = CelebrationScene.HOLD_SEC * 0.5

	scene.advance(half)
	assert_eq(requested, [], "halfway through: still on")

	scene.advance(half + 0.01)
	assert_eq(requested, [CASA_PATH], "and then home, once")
