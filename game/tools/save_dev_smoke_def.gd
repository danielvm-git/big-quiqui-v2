# story: e12s02
extends SceneTree

const STEP_DEF: Script = preload("res://scripts/resources/step_def.gd")
const SCENE_DEF: Script = preload("res://scripts/resources/scene_def.gd")


func _init() -> void:
	var step: Resource = STEP_DEF.new()
	step.template_id = "t_stub"
	step.param_int = 1
	var def: Resource = SCENE_DEF.new()
	def.id = "dev_smoke"
	def.background_id = "bg_kitchen"
	def.music_id = "music_kitchen"
	def.intro_voice_key = "vo.kitchen.intro"
	var steps: Array[Resource] = []
	steps.append(step)
	def.steps = steps
	def.next_scene_id = "home"
	var err: Error = ResourceSaver.save(def, "res://data/scenes/dev_smoke.tres")
	quit(0 if err == OK else 1)
