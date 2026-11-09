# story: e12s03
extends GutTest
## SC-e12s03-P1-02 / SC-e12s04-P1-01 — reactions are synchronous except wait.


func test_pose_and_sfx_share_a_frame() -> void:
	var rig: QuiQuiRig = QuiQuiRig.new()
	rig.size = Vector2(320.0, 480.0)
	add_child_autofree(rig)
	var recorder: ReactionRecorder = ReactionRecorder.new()
	var executor: ReactionExecutor = ReactionExecutor.new()
	executor.recorder = recorder
	executor.bind(self, rig)
	(
		executor
		. execute(
			[
				{"kind": ReactionExecutor.KIND_POSE, "id": "wink"},
				{"kind": ReactionExecutor.KIND_SFX, "id": "sfx_chomp"},
				{"kind": ReactionExecutor.KIND_WAIT, "sec": 0.5},
			]
		)
	)
	assert_true(recorder.same_frame(ReactionExecutor.KIND_POSE, ReactionExecutor.KIND_SFX))
	assert_gt(executor.pending_wait_sec(), 0.0)
