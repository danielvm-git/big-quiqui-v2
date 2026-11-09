# story: e12s03
extends GutTest
## SC-e12s03-P0-01 — undeclared step-runner edges stay rejected.


func test_step_runner_rejects_illegal_outro_from_intro() -> void:
	var runner: StepRunner = StepRunner.new()
	runner.manual_step = true
	runner.reset(1)
	runner.fsm.transition_to(StepRunner.STATE_INTRO)
	assert_eq(runner.fsm.state, StepRunner.STATE_INTRO)
	assert_false(runner.fsm.transition_to(StepRunner.STATE_OUTRO))
