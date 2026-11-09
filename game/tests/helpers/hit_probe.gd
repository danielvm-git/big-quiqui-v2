# story: e13s09
class_name HitProbe
extends RefCounted
## Which control a finger lands on. Godot's headless viewport does not dispatch GUI input, so this
## walks the tree the way GUI dispatch does: later siblings sit above earlier ones, children above
## their parent, a hidden node and anything outside a clipping parent is skipped, and `IGNORE` is
## skipped. The first control left is the one that answers the touch.


## The top-most control under `point` that takes touches, or null when nothing does.
static func top_at(root: Node, point: Vector2) -> Control:
	if root is CanvasItem and not (root as CanvasItem).visible:
		return null
	var control: Control = root as Control
	if control != null and control.clip_contents and not control.get_global_rect().has_point(point):
		return null
	var children: Array[Node] = root.get_children()
	children.reverse()
	for child: Node in children:
		if child.is_queued_for_deletion():
			continue
		var found: Control = top_at(child, point)
		if found != null:
			return found
	if control != null and control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		if control.get_global_rect().has_point(point):
			return control
	return null


## True when the finger at `target`'s centre lands on the target or one of its own descendants.
static func answers(root: Node, target: Control) -> bool:
	var top: Control = top_at(root, target.get_global_rect().get_center())
	return top != null and (top == target or target.is_ancestor_of(top))


## Names what covers `target`'s centre, or "" when nothing does. For a failure message.
static func coverer(root: Node, target: Control) -> String:
	if answers(root, target):
		return ""
	var top: Control = top_at(root, target.get_global_rect().get_center())
	return "nothing" if top == null else str(top.get_path())
