# story: e01s01
extends GutTest
## SC-E01-P0-01..03 — the FSM only walks declared edges, is idempotent on the
## same state, refuses stale post-await transitions, and times out exactly once.

const EDGES: Dictionary = {
	"IDLE": ["FEED", "BATH"],
	"FEED": ["IDLE"],
	"BATH": ["IDLE"],
}
const DWELL: Dictionary = {"FEED": 2.0}


class FakeClock:
	var now_ms: int = 0

	func read_ms() -> int:
		return now_ms

	func advance(ms: int) -> void:
		now_ms += ms


func _make(clock: FakeClock = null) -> Fsm:
	var callable: Callable = Callable()
	if clock != null:
		callable = Callable(clock, "read_ms")
	return Fsm.new("IDLE", EDGES, DWELL, callable)


# SC-E01-P0-01
func test_declared_edge_transitions_and_probe_stays_clean() -> void:
	var fsm: Fsm = _make()
	var probe: FsmProbe = FsmProbe.new().attach(fsm)

	assert_true(fsm.transition_to("FEED"), "declared edge must be accepted")
	assert_eq(fsm.state, "FEED")
	assert_true(probe.is_clean(), probe.summary())
	assert_eq(probe.last_transition(), "IDLE->FEED")
	probe.detach()


# SC-E01-P0-01
func test_undeclared_edge_is_rejected_and_logged() -> void:
	var fsm: Fsm = _make()
	var probe: FsmProbe = FsmProbe.new().attach(fsm)

	assert_false(fsm.transition_to("SLEEP"), "undeclared edge must be refused")
	assert_eq(fsm.state, "IDLE", "state must not move")
	assert_eq(probe.rejections.size(), 1, probe.summary())
	assert_eq(probe.rejections[0]["reason"], Fsm.REASON_ILLEGAL)
	assert_eq(probe.transition_count(), 0)
	probe.detach()


# SC-E01-P0-02
func test_same_state_is_a_silent_noop() -> void:
	var fsm: Fsm = _make()
	var probe: FsmProbe = FsmProbe.new().attach(fsm)

	assert_false(fsm.transition_to("IDLE"), "same-state transition returns false")
	assert_eq(probe.transition_count(), 0, "no transition signal")
	assert_true(probe.is_clean(), "and it is not a rejection either")
	probe.detach()


# SC-E01-P0-01 (post-await safety)
func test_transition_from_refuses_a_stale_expectation() -> void:
	var fsm: Fsm = _make()
	var probe: FsmProbe = FsmProbe.new().attach(fsm)

	assert_true(fsm.transition_to("FEED"))
	assert_false(fsm.transition_from("IDLE", "BATH"), "expected state is stale")
	assert_eq(fsm.state, "FEED", "the stale attempt must not move the machine")
	assert_eq(probe.rejections.back()["reason"], Fsm.REASON_STALE)
	probe.detach()


# SC-E01-P0-03
func test_dwell_timeout_fires_exactly_once() -> void:
	var clock: FakeClock = FakeClock.new()
	var fsm: Fsm = _make(clock)
	var probe: FsmProbe = FsmProbe.new().attach(fsm)

	assert_true(fsm.transition_to("FEED"))
	clock.advance(500)
	assert_false(fsm.check_dwell(), "under the limit must not fire")

	clock.advance(1600)
	assert_true(fsm.check_dwell(), "past 2.0 s must fire")
	assert_false(fsm.check_dwell(), "and only once per visit")
	assert_eq(probe.timeouts.size(), 1)
	probe.detach()


# SC-E01-P0-03 (a new visit re-arms the watchdog)
func test_dwell_rearms_on_a_new_visit() -> void:
	var clock: FakeClock = FakeClock.new()
	var fsm: Fsm = _make(clock)
	var probe: FsmProbe = FsmProbe.new().attach(fsm)

	fsm.transition_to("FEED")
	clock.advance(2100)
	assert_true(fsm.check_dwell(), "first visit fires")
	fsm.transition_to("IDLE")
	fsm.transition_to("FEED")
	clock.advance(2100)
	assert_true(fsm.check_dwell(), "second visit fires again")
	assert_eq(probe.timeouts.size(), 2)
	probe.detach()


func test_probe_detach_stops_recording() -> void:
	var fsm: Fsm = _make()
	var probe: FsmProbe = FsmProbe.new().attach(fsm)
	probe.detach()

	fsm.transition_to("FEED")
	assert_eq(probe.transition_count(), 0, "detached probe records nothing")


# BUG-003: the diary payload is part of the contract, not decoration.
func test_dwell_timeout_logs_milliseconds_truthfully() -> void:
	var log: Node = get_node_or_null("/root/Log")
	assert_not_null(log, "the Log autoload must exist")
	var clock: FakeClock = FakeClock.new()
	var fsm: Fsm = _make(clock)

	fsm.transition_to("FEED")
	clock.advance(2100)
	assert_true(fsm.check_dwell())

	var line: Dictionary = log.get("last_line") as Dictionary
	assert_eq(line.get("ev"), "fsm.dwell_timeout")
	assert_eq(int(line.get("limit_ms", -1)), 2000, "2000 ms, not 2 ms and not a 'sec' key: %s" % line)
	assert_false(line.has("limit_sec"), "a key that lies about its unit must not ship: %s" % line)
