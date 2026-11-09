# story: e13s09
class_name StepParams
extends RefCounted
## Closed, template-specific checks on a step's parameters, run before the player mounts anything.
## A def that fails here is rejected with a reason id, so malformed data can never boot as a
## zero-position door, an open lock or a slot that is not there (threat model: the grammar perimeter).

## A lock names a care step in capitals, like `FEED`; empty means open.
const LOCK_PATTERN: String = "^[A-Z][A-Z_]{0,23}$"
const LANE_MAX: int = 6
const CADENCE_MAX: int = 30
const LIFETIME_MAX: int = 60
const COUNT_MAX: int = 99
const WORLD_MAX: float = 20000.0
const T20_MODES: PackedStringArray = ["single", "pick_one", "slots"]
const T21_MODES: PackedStringArray = ["any", "single", "toggle"]


## The first reason a step is malformed, or "" when it is sound.
static func problem(step: StepDef) -> String:
	if step == null:
		return "null_step"
	var reason: String = _shared(step)
	if not reason.is_empty():
		return reason
	match step.template_id:
		"t20_drag_snap":
			return "bad_mode" if not T20_MODES.has(step.mode) else ""
		"t21_touch_each":
			return "bad_mode" if not T21_MODES.has(step.mode) else ""
		"t23_erase", "t34_rub_reveal", "t40_draw_fill":
			return _threshold(step)
		"t25_map":
			return _map(step)
		"t45_dress_decorate":
			return _dress(step)
		"t50_lanes":
			return _lanes(step)
	return ""


static func _shared(step: StepDef) -> String:
	var lists: Array[PackedStringArray] = [
		step.item_ids, step.slot_ids, step.category_ids, step.destination_ids, step.destination_scenes
	]
	for ids: PackedStringArray in lists:
		if not _clean_ids(ids):
			return "bad_id"
	for icon: String in step.destination_icons:
		if not icon.is_empty() and not Ids.is_valid(icon):
			return "bad_id"
	for lock: String in step.destination_locks:
		if not lock.is_empty() and not RegEx.create_from_string(LOCK_PATTERN).search(lock):
			return "bad_id"
	for single: String in [step.receiver_id, step.tool_id, step.loop_sfx_id, step.on_hit_sfx_id, step.on_miss_sfx_id]:
		if not single.is_empty() and not Ids.is_valid(single):
			return "bad_id"
	if step.repeat_count < 1 or step.repeat_count > COUNT_MAX:
		return "bad_count"
	if not is_finite(step.hint_delay_sec) or step.hint_delay_sec < 0.0:
		return "bad_number"
	return ""


## Valid ids and no id twice, so a repeat can never leak a second target.
static func _clean_ids(ids: PackedStringArray) -> bool:
	var seen: Dictionary = {}
	for id: String in ids:
		if not Ids.is_valid(id) or seen.has(id):
			return false
		seen[id] = true
	return true


static func _threshold(step: StepDef) -> String:
	var value: float = step.completion_threshold
	return "" if is_finite(value) and value > 0.0 and value <= 1.0 else "bad_threshold"


static func _map(step: StepDef) -> String:
	var size: Vector2 = step.world_size
	if not size.is_finite() or size.x <= 0.0 or size.y <= 0.0 or size.x > WORLD_MAX or size.y > WORLD_MAX:
		return "bad_world"
	if not is_finite(step.pan_tolerance) or step.pan_tolerance < 0.0:
		return "bad_number"
	var count: int = step.destination_ids.size()
	if step.destination_scenes.size() != count or step.destination_positions.size() != count:
		return "mismatched_arrays"
	if step.destination_locks.size() != count:
		return "mismatched_arrays"
	if not step.destination_icons.is_empty() and step.destination_icons.size() != count:
		return "mismatched_arrays"
	for point: Vector2 in step.destination_positions:
		if not point.is_finite():
			return "bad_world"
	return ""


static func _dress(step: StepDef) -> String:
	if not step.slot_ids.is_empty() and step.slot_ids.size() != step.item_ids.size():
		return "mismatched_arrays"
	return ""


static func _lanes(step: StepDef) -> String:
	if step.lane_count < 1 or step.lane_count > LANE_MAX:
		return "bad_count"
	if step.spawn_cadence < 1 or step.spawn_cadence > CADENCE_MAX:
		return "bad_count"
	if step.spawn_lifetime < 1 or step.spawn_lifetime > LIFETIME_MAX:
		return "bad_count"
	if step.goal_count < 1 or step.goal_count > COUNT_MAX:
		return "bad_count"
	return ""
