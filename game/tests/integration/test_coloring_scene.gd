# story: e15s01
extends PlayerTestCase


func test_coloring_def_loads_two_steps() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("coloring")
	assert_not_null(def)
	assert_eq(def.steps.size(), 2)
	assert_eq((def.steps[0] as StepDef).template_id, "t44_paint")
	assert_eq((def.steps[1] as StepDef).template_id, "t43_color_fill")


func test_coloring_mounts_at_both_aspects() -> void:
	for size: Vector2i in [GeometryOracle.DESKTOP_16_9, GeometryOracle.IPAD_4_3]:
		var player: ScenePlayer = await mount(def_or_load(), size)
		assert_not_null(player.loaded_def)
		player.queue_free()


func def_or_load() -> SceneDef:
	return SceneDefLoader.load_by_id("coloring")
