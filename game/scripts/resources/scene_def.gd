# story: e12s02
class_name SceneDef
extends Resource
## Typed scene description: backgrounds, music and steps are ids, never `res://` strings.

@export var id: String = ""
@export var background_id: String = ""
@export var music_id: String = ""
@export var intro_voice_key: String = ""
@export var steps: Array[Resource] = []
@export var next_scene_id: String = ""
@export var reward_coins: int = 0
