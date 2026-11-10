# story: e15s01
# story: e15s02
# story: e15s03
# story: e16s01
# story: e16s02
class_name StepParamsWave
extends RefCounted


static func paint(step: StepDef) -> String:
	if step.item_ids.is_empty():
		return "no_items"
	for paint_id: String in step.item_ids:
		if not PaintCatalog.is_paint(paint_id):
			return "bad_id"
	return _threshold(step)


static func color_fill(step: StepDef) -> String:
	if step.slot_ids.is_empty():
		return "no_items"
	if step.category_ids.size() != step.slot_ids.size():
		return "mismatched_arrays"
	if step.item_ids.is_empty():
		return "no_items"
	for paint_id: String in step.category_ids:
		if not PaintCatalog.is_paint(paint_id):
			return "bad_id"
	return ""


static func memory(step: StepDef) -> String:
	var count: int = step.item_ids.size()
	if count != 4 and count != 6:
		return "bad_count"
	var seen: Dictionary = {}
	for art_id: String in step.item_ids:
		if not Ids.is_valid(art_id):
			return "bad_id"
		seen[art_id] = int(seen.get(art_id, 0)) + 1
	for art_id: String in seen.keys():
		if int(seen[art_id]) != 2:
			return "bad_count"
	return ""


static func spawn_goal(step: StepDef) -> String:
	if step.item_ids.is_empty():
		return "no_items"
	if step.goal_count < 1:
		return "bad_count"
	return ""


static func slice(step: StepDef) -> String:
	if step.destination_positions.size() < 2:
		return "no_items"
	return _threshold(step)


static func cups(step: StepDef) -> String:
	if step.item_ids.size() < 2:
		return "bad_count"
	if step.item_ids.size() > 8:
		return "bad_count"
	return ""


static func _threshold(step: StepDef) -> String:
	var value: float = step.completion_threshold
	return "" if is_finite(value) and value > 0.0 and value <= 1.0 else "bad_threshold"
