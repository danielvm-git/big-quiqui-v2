# story: e13s09
# story: e14s04
class_name StepParams
extends RefCounted
## Closed, template-specific checks on a step's parameters, run before the player mounts anything.
## A def that fails here is rejected with a reason id, so malformed data can never boot as a
## zero-position door, an open lock or a slot that is not there (threat model: the grammar perimeter).

const LANE_MAX: int = 6
const CADENCE_MAX: int = 30
const LIFETIME_MAX: int = 60
const COUNT_MAX: int = 99
## A tray row is 160 px a target from x 650, so eight fit the narrowest canvas we ship.
const TRAY_ITEMS_MAX: int = 8
## The dress strip scrolls, so it takes more than a row does.
const STRIP_ITEMS_MAX: int = 40
const WORLD_MAX: float = 20000.0
const T20_MODES: PackedStringArray = ["single", "pick_one", "slots"]
## `single` is the `StepDef` default, so a def that names no mode still loads and plays as `any`.
const T21_MODES: PackedStringArray = ["any", "count_n", "toggle", "single", "buy", "arcade"]
## Erase and draw take clear or leave, the reveal chain takes reveal. `single` is the unset default.
const RUB_MODES: Dictionary = {
	"t23_erase": ["clear", "leave", "single"],
	"t40_draw_fill": ["clear", "leave", "single"],
	"t34_rub_reveal": ["reveal", "single"],
}
const TOLERANCE_MAX: float = 200.0


## The first reason a step is malformed, or "" when it is sound.
static func problem(step: StepDef) -> String:
	if step == null:
		return "null_step"
	var reason: String = _shared(step)
	return reason if not reason.is_empty() else _by_template(step)


static func _by_template(step: StepDef) -> String:
	match step.template_id:
		"t20_drag_snap":
			return "bad_mode" if not T20_MODES.has(step.mode) else ""
		"t21_touch_each":
			if step.mode == "arcade":
				return _arcade(step)
			return _row(step) if T21_MODES.has(step.mode) else "bad_mode"
		"t23_erase", "t40_draw_fill", "t34_rub_reveal":
			return _rub(step)
		"t25_map":
			return _map(step)
		"t45_dress_decorate":
			return _dress(step)
		"t50_lanes":
			return _lanes(step)
		"t51_prize_pick":
			return _wheel_prizes(step) if step.mode == "wheel" else _row(step)
		"t_rhythm_pose", "t_album":
			return _needs_items(step)
	return ""


## A step with nothing to tap, show or catch could never finish, so it never loads.
static func _needs_items(step: StepDef) -> String:
	return "" if not step.item_ids.is_empty() else "no_items"


## A row of tap targets: at least one, and no more than the row can show.
static func _row(step: StepDef) -> String:
	var reason: String = _needs_items(step)
	if not reason.is_empty():
		return reason
	return "bad_count" if step.item_ids.size() > TRAY_ITEMS_MAX else ""


static func _rub(step: StepDef) -> String:
	if not (RUB_MODES[step.template_id] as Array).has(step.mode):
		return "bad_mode"
	## Every rub template needs a layer to rub; none could ever finish without one.
	if step.item_ids.is_empty():
		return "no_items"
	for layer_id: String in step.item_ids:
		if PlayerNodeTable.RESERVED.has(layer_id):
			return "bad_id"
	if step.param_int != 0 and (step.param_int < RubPrimitive.EDGE_MIN or step.param_int > RubPrimitive.EDGE_MAX):
		return "bad_count"
	return _threshold(step)


static func _shared(step: StepDef) -> String:
	for unique: PackedStringArray in [step.item_ids, step.destination_ids]:
		if not _clean_ids(unique, true):
			return "bad_id"
	## Slots, categories and scenes repeat on purpose: two neck items share a slot, two doors one room.
	for shared: PackedStringArray in [step.category_ids, step.destination_scenes]:
		if not _clean_ids(shared, false):
			return "bad_id"
	## An empty slot is a piece of furniture, placed free beside the worn items.
	if not _clean_ids(step.slot_ids, false, true):
		return "bad_id"
	if not _clean_optional(step):
		return "bad_id"
	var reason: String = _poses(step)
	if not reason.is_empty():
		return reason
	if step.repeat_count < 1 or step.repeat_count > COUNT_MAX or step.item_ids.size() > COUNT_MAX:
		return "bad_count"
	if not is_finite(step.hint_delay_sec) or step.hint_delay_sec < 0.0:
		return "bad_number"
	return ""


## Hit poses are optional, but when present there is one per item and each is a well formed id.
static func _poses(step: StepDef) -> String:
	if not step.hit_poses.is_empty() and step.hit_poses.size() != step.item_ids.size():
		return "mismatched_arrays"
	for pose: String in step.hit_poses:
		if not pose.is_empty() and not Ids.is_valid(pose):
			return "bad_id"
	return ""


## Icons, locks and the single ids may be empty, but an id that is there must be well formed.
static func _clean_optional(step: StepDef) -> bool:
	for icon: String in step.destination_icons:
		if not icon.is_empty() and not Ids.is_valid(icon):
			return false
	for lock: String in step.destination_locks:
		if not lock.is_empty() and not CareSteps.ORDER.has(lock):
			return false
	return _clean_singles(step)


static func _clean_singles(step: StepDef) -> bool:
	for single: String in [
		step.receiver_id,
		step.tool_id,
		step.loop_sfx_id,
		step.on_hit_sfx_id,
		step.on_miss_sfx_id,
		step.on_hit_pose,
		step.hint_from_id,
		step.hint_to_id,
	]:
		if not single.is_empty() and not Ids.is_valid(single):
			return false
	## The care step and the voice key have their own closed grammars, so the player never forwards a stray one.
	if not step.care_step_id.is_empty() and not CareSteps.ORDER.has(step.care_step_id):
		return false
	return step.hint_voice_key.is_empty() or not VoiceKeyResolver.path_for_key(step.hint_voice_key).is_empty()


## Valid ids, and no id twice when `unique`, so a repeat can never leak a second target.
static func _clean_ids(ids: PackedStringArray, unique: bool, allow_empty: bool = false) -> bool:
	var seen: Dictionary = {}
	for id: String in ids:
		if allow_empty and id.is_empty():
			continue
		if not Ids.is_valid(id) or (unique and seen.has(id)):
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
	var tolerance: float = step.pan_tolerance
	if not is_finite(tolerance) or tolerance < 0.0 or tolerance > TOLERANCE_MAX:
		return "bad_number"
	if step.destination_ids.is_empty():
		return "no_items"
	for scene: String in step.destination_scenes:
		if not SceneCatalog.is_shipped(scene):
			return "unknown_scene"
	if not MapDef.new(step).rows_match() or _bad_icons(step):
		return "mismatched_arrays"
	for point: Vector2 in step.destination_positions:
		if not _pin_fits(point, size):
			return "bad_world"
	return ""


## A pin is a whole 120 px target, so its corner stops one pin short of the world's far edge.
static func _pin_fits(point: Vector2, world: Vector2) -> bool:
	var limit: Vector2 = world - TapButton.MIN_HIT_SIZE
	return point.is_finite() and point.x >= 0.0 and point.y >= 0.0 and point.x <= limit.x and point.y <= limit.y


static func _bad_icons(step: StepDef) -> bool:
	return not step.destination_icons.is_empty() and step.destination_icons.size() != step.destination_ids.size()


static func _wheel_prizes(step: StepDef) -> String:
	var reason: String = _row(step)
	if not reason.is_empty():
		return reason
	var economy: EconomyData = EconomyData.new()
	for prize: String in step.item_ids:
		if not economy.wheel_prize_coins.has(prize):
			return "bad_id"
	return ""


static func _arcade(step: StepDef) -> String:
	if step.destination_scenes.is_empty() or step.destination_scenes.size() != step.item_ids.size():
		return "mismatched_arrays"
	for scene: String in step.destination_scenes:
		if not SceneCatalog.is_shipped(scene):
			return "unknown_scene"
	for friend: String in step.item_ids:
		if not FriendCatalog.is_friend(friend):
			return "bad_id"
	return ""


static func _dress(step: StepDef) -> String:
	if not step.slot_ids.is_empty() and step.slot_ids.size() != step.item_ids.size():
		return "mismatched_arrays"
	if not step.category_ids.is_empty() and step.category_ids.size() != step.item_ids.size():
		return "mismatched_arrays"
	if step.item_ids.size() > STRIP_ITEMS_MAX:
		return "bad_count"
	return _dress_items(step)


## A worn piece must be wearable in its slot and a free piece must be shipped furniture, so a def never
## offers a tap that the save is bound to refuse.
static func _dress_items(step: StepDef) -> String:
	if step.item_ids.is_empty():
		return "no_items"
	for index: int in range(step.item_ids.size()):
		var slot: String = step.slot_ids[index] if index < step.slot_ids.size() else ""
		var item: String = step.item_ids[index]
		if not _fits(slot, item):
			return "bad_id"
	return ""


static func _fits(slot: String, item: String) -> bool:
	if slot.is_empty():
		return FurnitureCatalog.FURNITURE_IDS.has(item)
	return OutfitCatalog.is_wearable(slot, item)


static func _lanes(step: StepDef) -> String:
	if step.item_ids.is_empty():
		return "no_items"
	if step.lane_count < 1 or step.lane_count > LANE_MAX:
		return "bad_count"
	if step.spawn_cadence < 1 or step.spawn_cadence > CADENCE_MAX:
		return "bad_count"
	if step.spawn_lifetime < 1 or step.spawn_lifetime > LIFETIME_MAX:
		return "bad_count"
	if step.goal_count < 1 or step.goal_count > COUNT_MAX:
		return "bad_count"
	return ""
