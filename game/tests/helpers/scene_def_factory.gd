# story: e12s02
class_name SceneDefFactory
extends RefCounted
## Pure in-memory defs for unit tests — no `res://data/scenes/*.tres` required.


static func valid() -> SceneDef:
	var step: StepDef = StepDef.new()
	step.template_id = "t_stub"
	step.param_int = 1
	var def: SceneDef = SceneDef.new()
	def.id = "dev_smoke"
	def.background_id = "bg_kitchen"
	def.music_id = "music_kitchen"
	def.intro_voice_key = "vo.kitchen.intro"
	var steps: Array[Resource] = []
	steps.append(step)
	def.steps = steps
	def.next_scene_id = "home"
	return def


static func broken(variant: String) -> SceneDef:
	var def: SceneDef = valid()
	match variant:
		"unknown_template":
			def.steps[0].template_id = "t99_missing"
		"missing_background":
			def.background_id = ""
		"empty_steps":
			def.steps = []
		"bad_next_scene":
			def.next_scene_id = "nowhere_at_all"
		"no_next_scene":
			def.next_scene_id = ""
		"bad_voice_key":
			def.intro_voice_key = "kitchen intro"
		_:
			push_error("SceneDefFactory: unknown variant %s" % variant)
	return def
