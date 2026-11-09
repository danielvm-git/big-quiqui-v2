# story: e13s09
class_name HitProbe
extends RefCounted
## Which control a finger lands on, and what the child sees there. Godot's headless viewport does not
## dispatch GUI input or draw, so this walks the tree the way the engine does. Input: later siblings sit
## above earlier ones, children above their parent, a hidden node and anything outside a clipping parent
## is skipped, `IGNORE` is skipped. Because the engine's own rule for `z_index` on controls is easy to get
## wrong, a touch counts as answered only when BOTH the tree-order winner and the z-order winner are the
## target. Drawing: a node with a picture covers what is under it by `z_index` first and tree order second.

const SEEN_POINTS: Array[Vector2] = [
	Vector2(0.5, 0.5), Vector2(0.2, 0.2), Vector2(0.8, 0.2), Vector2(0.2, 0.8), Vector2(0.8, 0.8)
]


## The top-most control under `point` that takes touches by tree order, or null when nothing does.
static func top_at(root: Node, point: Vector2) -> Control:
	var found: Array[Dictionary] = _scan(root, point)
	return null if found.is_empty() else _last_by_tree(found)


## The same, but a higher `z_index` wins before tree order does.
static func top_at_z(root: Node, point: Vector2) -> Control:
	var found: Array[Dictionary] = _scan(root, point)
	return null if found.is_empty() else _last_by_z(found)


## True when the finger at `target`'s centre lands on the target or one of its descendants,
## by tree order and by z order.
static func answers(root: Node, target: Control) -> bool:
	var point: Vector2 = target.get_global_rect().get_center()
	return _owns(target, top_at(root, point)) and _owns(target, top_at_z(root, point))


## Names what covers `target`'s centre, or "" when nothing does. For a failure message.
static func coverer(root: Node, target: Control) -> String:
	if answers(root, target):
		return ""
	var top: Control = top_at_z(root, target.get_global_rect().get_center())
	return "nothing" if top == null else str(top.get_path())


## True when the picture on top at each of five points of `target` belongs to the target, so the child can
## see what the finger can reach. A target with no picture of its own is not judged.
static func seen(root: Node, target: Control) -> bool:
	return unseen_by(root, target) == ""


## Names the node drawn over `target`, or "" when it is seen, or has no picture to cover.
static func unseen_by(root: Node, target: Control) -> String:
	if _pictures_of(target).is_empty():
		return ""
	var rect: Rect2 = target.get_global_rect()
	for fraction: Vector2 in SEEN_POINTS:
		var top: Node = _top_picture(root, rect.position + rect.size * fraction)
		if top != null and top != target and not target.is_ancestor_of(top):
			return str(top.get_path())
	return ""


static func _owns(target: Control, top: Control) -> bool:
	return top != null and (top == target or target.is_ancestor_of(top))


## Every control that takes touches at `point`, in tree order, each with its effective z and order number.
static func _scan(root: Node, point: Vector2) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	_walk(root, point, 0, [0], found)
	return found


static func _walk(node: Node, point: Vector2, z_above: int, order: Array[int], into: Array[Dictionary]) -> void:
	if node.is_queued_for_deletion() or (node is CanvasItem and not (node as CanvasItem).visible):
		return
	var control: Control = node as Control
	if control != null and control.clip_contents and not control.get_global_rect().has_point(point):
		return
	var z_here: int = z_above + _own_z(node)
	order[0] += 1
	var self_order: int = order[0]
	for child: Node in node.get_children():
		_walk(child, point, z_here, order, into)
	if control != null and control.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		if control.get_global_rect().has_point(point):
			into.append({"node": control, "z": z_here, "order": self_order})


static func _own_z(node: Node) -> int:
	var item: CanvasItem = node as CanvasItem
	if item == null:
		return 0
	return item.z_index


static func _last_by_tree(found: Array[Dictionary]) -> Control:
	var best: Dictionary = found[0]
	for entry: Dictionary in found:
		if int(entry["order"]) > int(best["order"]):
			best = entry
	return best["node"] as Control


static func _last_by_z(found: Array[Dictionary]) -> Control:
	var best: Dictionary = found[0]
	for entry: Dictionary in found:
		var higher: bool = int(entry["z"]) > int(best["z"])
		if higher or (int(entry["z"]) == int(best["z"]) and int(entry["order"]) > int(best["order"])):
			best = entry
	return best["node"] as Control


## The picture drawn last at `point`: the highest effective z, then the latest in the tree.
static func _top_picture(root: Node, point: Vector2) -> Node:
	var drawn: Array[Dictionary] = []
	_collect_pictures(root, 0, [0], drawn)
	var best: Dictionary = {}
	for entry: Dictionary in drawn:
		if not (entry["rect"] as Rect2).has_point(point):
			continue
		var higher: bool = best.is_empty() or int(entry["z"]) > int(best["z"])
		if higher or (int(entry["z"]) == int(best["z"]) and int(entry["order"]) > int(best["order"])):
			best = entry
	return null if best.is_empty() else best["node"] as Node


static func _collect_pictures(node: Node, z_above: int, order: Array[int], into: Array[Dictionary]) -> void:
	if node.is_queued_for_deletion() or (node is CanvasItem and not (node as CanvasItem).visible):
		return
	var z_here: int = z_above + _own_z(node)
	order[0] += 1
	var rect: Rect2 = _picture_rect(node)
	if rect.has_area() and (node as CanvasItem).modulate.a > 0.05:
		into.append({"node": node, "z": z_here, "order": order[0], "rect": rect})
	for child: Node in node.get_children():
		_collect_pictures(child, z_here, order, into)


## The pixels a node draws, in global coordinates, or an empty rect when it draws no picture.
static func _picture_rect(node: Node) -> Rect2:
	if node is TextureRect and (node as TextureRect).texture != null:
		return (node as TextureRect).get_global_rect()
	if node is Sprite2D and (node as Sprite2D).texture != null:
		return _sprite_rect(node as Sprite2D)
	return Rect2()


static func _sprite_rect(sprite: Sprite2D) -> Rect2:
	var texture: Texture2D = sprite.texture
	var scale: Vector2 = sprite.global_scale.abs()
	var top_left: Vector2 = sprite.global_position - texture.get_size() * 0.5 * scale
	var rig: QuiQuiRig = _rig_of(sprite)
	if rig == null:
		return Rect2(top_left, texture.get_size() * scale)
	var used: Rect2 = rig.opaque_rect(texture)
	return Rect2(top_left + used.position * scale, used.size * scale) if used.has_area() else Rect2()


static func _rig_of(node: Node) -> QuiQuiRig:
	var parent: Node = node.get_parent()
	while parent != null:
		if parent is QuiQuiRig:
			return parent as QuiQuiRig
		parent = parent.get_parent()
	return null


static func _pictures_of(target: Control) -> Array[Node]:
	var found: Array[Node] = []
	var pending: Array[Node] = [target]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if _picture_rect(node).has_area():
			found.append(node)
		pending.append_array(node.get_children())
	return found
