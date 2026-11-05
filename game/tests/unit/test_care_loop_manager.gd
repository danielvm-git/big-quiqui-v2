# story: e02s01
extends GutTest
## SC-E02-P0-01..08 — the care cycle machine walks IDLE..CELEBRATE along its
## declared edges only, is idempotent under duplicate completes, pays the cycle
## reward exactly once per cycle id (detour guard), and never soft-locks the hub.

var clm: Node = null
var pm: Node = null
var loop_signals: Array[String] = []


func before_all() -> void:
	# Connect once: the autoload outlives the test, so per-test connections would
	# stack and every signal would be recorded N times.
	clm = get_node_or_null("/root/CareLoopManager")
	assert_not_null(clm, "CareLoopManager must be an autoload")
	clm.loop_state_changed.connect(
		func(from_state: String, to_state: String) -> void: loop_signals.append(from_state + "->" + to_state)
	)
	pm = get_node_or_null("/root/ProgressManager")
	assert_not_null(pm, "ProgressManager must be an autoload")


func before_each() -> void:
	TestReset.reset_all()
	loop_signals = []


func after_each() -> void:
	TestReset.reset_all()


func _walk_full_cycle() -> void:
	assert_true(clm.begin_step(clm.STATE_FEED), "IDLE -> FEED is the only way in")
	clm.complete_step(clm.STATE_FEED)
	clm.complete_step(clm.STATE_BATH)
	clm.complete_step(clm.STATE_DRESS)
	clm.complete_step(clm.STATE_PLAY)
	clm.complete_step(clm.STATE_SLEEP)


# SC-E02-P0-01
func test_starts_idle_with_zero_progress() -> void:
	assert_eq(clm.state_id(), "IDLE")
	assert_eq(clm.completed_steps(), 0)
	assert_eq(clm.next_step(), "FEED", "the first wish is always FEED")
	assert_eq(clm.cycle_id, 0)


# SC-E02-P0-02
func test_full_legal_walk_reaches_celebrate_and_returns_to_idle() -> void:
	var probe: FsmProbe = FsmProbe.new().attach(clm.fsm)

	_walk_full_cycle()
	assert_eq(clm.state_id(), "CELEBRATE")
	assert_eq(clm.completed_steps(), 5)
	assert_eq(clm.next_step(), "", "nothing left to wish while celebrating")

	assert_true(clm.complete_step(clm.STATE_CELEBRATE))
	assert_eq(clm.state_id(), "IDLE")

	assert_true(probe.is_clean(), "no illegal transition and no dwell timeout: %s" % probe.summary())
	assert_eq(
		loop_signals,
		[
			"IDLE->FEED",
			"FEED->BATH",
			"BATH->DRESS",
			"DRESS->PLAY",
			"PLAY->SLEEP",
			"SLEEP->CELEBRATE",
			"CELEBRATE->IDLE",
		]
	)
	probe.detach()


# SC-E02-P0-03
func test_illegal_begin_step_is_rejected() -> void:
	assert_false(clm.begin_step(clm.STATE_BATH), "IDLE -> BATH is not an edge")
	assert_eq(clm.state_id(), "IDLE", "a rejected begin must not move the machine")

	assert_false(clm.begin_step("IDLE"), "same-state begin is a silent no-op")
	assert_eq(clm.state_id(), "IDLE")


# SC-E02-P0-04
func test_duplicate_complete_step_is_stale_rejected() -> void:
	clm.begin_step(clm.STATE_FEED)
	assert_true(clm.complete_step(clm.STATE_FEED), "first complete: FEED -> BATH")
	assert_eq(clm.state_id(), "BATH")

	assert_false(clm.complete_step(clm.STATE_FEED), "second complete with the same expected state is stale")
	assert_eq(clm.state_id(), "BATH", "the stale complete must not advance again")


# SC-E02-P0-05
func test_skipping_a_step_is_rejected() -> void:
	clm.begin_step(clm.STATE_FEED)
	clm.complete_step(clm.STATE_FEED)

	assert_false(clm.complete_step(clm.STATE_DRESS), "BATH is the state, DRESS is stale")
	assert_eq(clm.state_id(), "BATH", "the machine refuses to skip BATH")


# SC-E02-P0-06
func test_abandon_returns_to_idle_from_any_step() -> void:
	assert_false(clm.abandon_step(), "abandon from IDLE is a no-op")

	clm.begin_step(clm.STATE_FEED)
	clm.complete_step(clm.STATE_FEED)
	assert_true(clm.abandon_step())
	assert_eq(clm.state_id(), "IDLE")
	assert_eq(clm.completed_steps(), 0, "an abandoned cycle shows no dots")
	assert_eq(clm.next_step(), "FEED", "and starts over from FEED")


# SC-E02-P0-07 — the detour guard: reward exactly once per cycle id
func test_celebrate_pays_exactly_once_per_cycle() -> void:
	_walk_full_cycle()
	assert_eq(pm.data.coins, 5, "entering CELEBRATE pays +5 coins immediately")
	assert_eq(pm.data.tickets, 1, "and +1 ticket")

	clm.complete_step(clm.STATE_CELEBRATE)
	assert_eq(pm.data.coins, 5, "leaving CELEBRATE never pays again")
	assert_eq(pm.data.tickets, 1)
	assert_eq(clm.cycle_id, 1, "closing the cycle bumps the id")

	_walk_full_cycle()
	assert_eq(pm.data.coins, 10, "a new cycle id may pay again")
	assert_eq(pm.data.tickets, 2)
	assert_eq(pm.data.completed_cycles, 2)


# SC-E02-P0-07b — detour from CELEBRATE keeps the reward and the id honest
func test_celebrate_detour_keeps_reward_and_closes_cycle() -> void:
	_walk_full_cycle()
	assert_true(clm.abandon_step(), "a detour leaves CELEBRATE through its IDLE edge")

	assert_eq(pm.data.coins, 5, "the reward granted at entry is not lost")
	assert_eq(clm.cycle_id, 1, "the detour closes the cycle like a normal exit")

	assert_true(clm.begin_step(clm.STATE_FEED), "no soft-lock: a fresh cycle can start")
	assert_false(clm.complete_step(clm.STATE_CELEBRATE), "the old celebration is gone")


# SC-E02-P0-08
func test_reset_restores_a_fresh_cycle() -> void:
	clm.begin_step(clm.STATE_FEED)
	clm.complete_step(clm.STATE_FEED)

	clm.reset()

	assert_eq(clm.state_id(), "IDLE")
	assert_eq(clm.cycle_id, 0)
	assert_eq(clm.completed_steps(), 0)


# SC-E02-P0-08b
func test_test_reset_reaches_care_loop_manager() -> void:
	clm.begin_step(clm.STATE_FEED)

	TestReset.reset_all()

	assert_eq(clm.state_id(), "IDLE", "TestReset must reset the 5th autoload too")
