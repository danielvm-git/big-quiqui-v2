# story: e12s03
extends GutTest
## SC-e12s03-P0-01..03 — the step machine is table-driven and never times out a step.


class FakeClock:
	var now_ms: int = 0

	func read_ms() -> int:
		return now_ms

	func advance_ms(ms: int) -> void:
		now_ms += ms


func _runner(clock: FakeClock = null) -> StepRunner:
	var callable: Callable = Callable()
	if clock != null:
		callable = Callable(clock, "read_ms")
	var runner: StepRunner = StepRunner.new(callable)
	runner.manual_step = true
	runner.reset(2)
	return runner


func test_rejects_undeclared_edges() -> void:
	var runner: StepRunner = _runner()
	runner.fsm.transition_to(StepRunner.STATE_INTRO)
	runner.finish_intro()
	assert_eq(runner.fsm.state, StepRunner.STATE_STEP)
	assert_false(runner.fsm.transition_to(StepRunner.STATE_OUTRO), "STEP cannot skip to OUTRO")


func test_same_state_transition_is_no_op() -> void:
	var runner: StepRunner = _runner()
	assert_false(runner.fsm.transition_to(StepRunner.STATE_LOAD))
	assert_eq(runner.fsm.state, StepRunner.STATE_LOAD)


func test_step_completes_only_at_progress_one() -> void:
	var runner: StepRunner = _runner()
	runner.fsm.transition_to(StepRunner.STATE_INTRO)
	runner.finish_intro()
	assert_eq(runner.fsm.state, StepRunner.STATE_STEP)
	runner.report_template_progress(0.5)
	assert_eq(runner.fsm.state, StepRunner.STATE_STEP)
	runner.report_template_progress(1.0)
	assert_eq(runner.fsm.state, StepRunner.STATE_STEP_DONE)


func test_step_state_has_no_dwell_deadline() -> void:
	assert_false(StepRunner.MAX_DWELL_SEC.has(StepRunner.STATE_STEP))


func test_home_exits_from_every_state_without_penalty() -> void:
	var states: Array[String] = [
		StepRunner.STATE_LOAD,
		StepRunner.STATE_INTRO,
		StepRunner.STATE_STEP,
		StepRunner.STATE_STEP_DONE,
		StepRunner.STATE_OUTRO,
	]
	for state: String in states:
		var runner: StepRunner = _runner()
		runner.fsm.reset(state)
		assert_true(runner.request_home())
		assert_eq(runner.fsm.state, StepRunner.STATE_EXIT)
		assert_false(runner.home_penalty())
		var probe: FsmProbe = FsmProbe.new().attach(runner.fsm)
		assert_true(probe.is_clean(), probe.summary())
		probe.detach()
