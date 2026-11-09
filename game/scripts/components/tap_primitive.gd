# story: e13s02
class_name TapPrimitive
extends RefCounted
## Distinct-target taps. A repeat still counts as an answer and does not move progress.

var mode: String = "any"
var goal: int = 1

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
		return clampf(float(_seen.size()) / float(maxi(goal, 1)), 0.0, 1.0)
	return 0.0


func claims_completion() -> bool:
	return false


func reaction_count() -> int:
	return _reactions


func seen_count() -> int:
	return _seen.size()


func is_on(target_id: String) -> bool:
	return bool(_on.get(target_id, false))
