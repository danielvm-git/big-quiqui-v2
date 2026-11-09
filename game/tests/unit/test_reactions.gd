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


func test_invalid_voice_key_does_not_start_audio() -> void:
	var rig: QuiQuiRig = QuiQuiRig.new()
	rig.size = Vector2(320.0, 480.0)
	add_child_autofree(rig)
	var bad_key: String = "vo.../../../etc.intro"
	assert_eq(VoiceKeyResolver.path_for_key(bad_key), "")
	var am: Node = get_node("/root/AudioManager")
	am.call("reset")
	assert_false(bool(am.get("is_ducked")))
	var executor: ReactionExecutor = ReactionExecutor.new()
	executor.bind(self, rig)
	executor.execute([{"kind": ReactionExecutor.KIND_VOICE, "key": bad_key}])
	assert_false(bool(am.get("is_ducked")), "an invalid key must not duck music")
