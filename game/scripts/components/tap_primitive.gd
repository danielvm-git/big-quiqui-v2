# story: e13s02
class_name TapPrimitive
extends RefCounted
## Distinct-target taps. A repeat still counts as an answer and does not move progress.

var mode: String = "any"
var goal: int = 1
## How many distinct targets the step has. `count_n` never asks for more, and `toggle` is done
## when every one is on. Zero means unknown, so the goal stands as given.
var targets: int = 0

var _seen: Dictionary = {}
var _on: Dictionary = {}
var _reactions: int = 0


func note_tap(target_id: String) -> bool:
	_reactions += 1
	if mode == "toggle":
		_on[target_id] = not bool(_on.get(target_id, false))
		return true
	if _seen.has(target_id):
		return false
	_seen[target_id] = true
	return true


func progress() -> float:
	if mode == "any":
		return 1.0 if _seen.size() > 0 else 0.0
	if mode == "count_n":
		return clampf(float(_seen.size()) / float(_goal()), 0.0, 1.0)
	if mode == "toggle":
		return clampf(float(_on_count()) / float(maxi(targets, 1)), 0.0, 1.0)
	return 0.0


func _goal() -> int:
	if targets > 0:
		return clampi(goal, 1, targets)
	return maxi(goal, 1)


func _on_count() -> int:
	var count: int = 0
	for target_id: String in _on.keys():
		if bool(_on[target_id]):
			count += 1
	return count


func claims_completion() -> bool:
	return false


func reaction_count() -> int:
	return _reactions


func seen_count() -> int:
	return _seen.size()


func is_on(target_id: String) -> bool:
	return bool(_on.get(target_id, false))
