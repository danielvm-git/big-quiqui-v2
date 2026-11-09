# story: e14s02
extends GutTest
## SC-e14s02-P0-01 — one verb on title, it opens home.


func test_title_def_has_one_verb_that_requests_home() -> void:
	var def: SceneDef = SceneDefLoader.load_by_id("title")
	assert_not_null(def)
	assert_eq(def.steps.size(), 1)
	assert_eq((def.steps[0] as StepDef).template_id, "t0_title")
	assert_eq(def.next_scene_id, "home")
	assert_true(def.intro_voice_key.is_empty())
