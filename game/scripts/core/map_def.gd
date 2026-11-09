# story: e13s03
class_name MapDef
extends RefCounted
## What the map template reads from its step: destination rows, world size and the care-loop locks.
## Every read is bounds-checked, so a short array is a closed door and never a crash.

const DEFAULT_WORLD: Vector2 = Vector2(1920.0, 1080.0)
const DEFAULT_TOLERANCE: float = 24.0

var step: StepDef = null


func _init(step_def: StepDef = null) -> void:
	step = step_def


func world_size() -> Vector2:
	return DEFAULT_WORLD if step == null else step.world_size


func tolerance() -> float:
	return DEFAULT_TOLERANCE if step == null else step.pan_tolerance


func count() -> int:
	return 0 if step == null else step.destination_ids.size()


func index_of(dest_id: String) -> int:
	return -1 if step == null else step.destination_ids.find(dest_id)


func scene_at(index: int) -> String:
	return _at(step.destination_scenes if step != null else PackedStringArray(), index)


func lock_at(index: int) -> String:
	return _at(step.destination_locks if step != null else PackedStringArray(), index)


func icon_at(index: int) -> String:
	return _at(step.destination_icons if step != null else PackedStringArray(), index)


func position_at(index: int) -> Vector2:
	if step == null or index < 0 or index >= step.destination_positions.size():
		return Vector2.ZERO
	return step.destination_positions[index]


## Scenes, locks and positions must pair one-to-one with ids, or the whole map is closed.
func rows_match() -> bool:
	if step == null:
		return false
	var count: int = step.destination_ids.size()
	if step.destination_scenes.size() != count or step.destination_locks.size() != count:
		return false
	return step.destination_positions.size() == count


## A lock names a care step. Open when it is empty or the care loop already finished it.
func is_locked(index: int, open_steps: PackedStringArray) -> bool:
	if not rows_match():
		return true
	var rule: String = lock_at(index)
	return not rule.is_empty() and not open_steps.has(rule)


static func open_steps_now() -> PackedStringArray:
	var open: PackedStringArray = PackedStringArray()
	var loop: Node = TemplateKit.autoload("CareLoopManager")
	if loop == null or not loop.has_method("completed_steps"):
		return open
	for index: int in range(mini(int(loop.call("completed_steps")), CareSteps.ORDER.size())):
		open.append(CareSteps.ORDER[index])
	return open


static func next_care(open_steps: PackedStringArray) -> String:
	for step_id: String in CareSteps.ORDER:
		if not open_steps.has(step_id):
			return step_id
	return ""


func _at(items: PackedStringArray, index: int) -> String:
	return items[index] if index >= 0 and index < items.size() else ""
