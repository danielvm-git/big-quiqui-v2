# story: e11s01
class_name MbtWalk
extends RefCounted
## Seeded random mount of every shipped scene for the 500-step MBT gate.

const STEP_COUNT: int = 500
const WALK_SEED: int = 1107

var visited: Dictionary = {}
var steps_done: int = 0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func reset() -> void:
	visited.clear()
	steps_done = 0
	_rng.seed = WALK_SEED


func next_scene_path() -> String:
	var index: int = _rng.randi_range(0, SceneCatalog.ALL_PATHS.size() - 1)
	return SceneCatalog.ALL_PATHS[index]


func record_visit(path: String) -> void:
	visited[path] = true
	steps_done += 1


func all_scenes_visited() -> bool:
	return visited.size() >= SceneCatalog.SCENE_COUNT


func assert_economy_invariants(progress: Node) -> Array[String]:
	var faults: Array[String] = []
	if progress == null:
		faults.append("no_progress")
		return faults
	var coins: int = int(progress.call("get_coins"))
	if coins < 0 or coins > SaveData.MAX_COINS:
		faults.append("coins_out_of_range")
	var data: SaveData = progress.get("data") as SaveData
	if data == null:
		return faults
	if data.tickets < 0 or data.tickets > SaveData.MAX_TICKETS:
		faults.append("tickets_out_of_range")
	for key: Variant in data.friend_stars.keys():
		var stars: int = int(data.friend_stars[key])
		if stars < 0 or stars > SaveData.MAX_STARS:
			faults.append("stars_out_of_range")
	return faults
