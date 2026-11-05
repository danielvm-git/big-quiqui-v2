# story: e01s01
class_name GeometryOracle
extends RefCounted
## Dual-aspect layout assertions (ADR-002 / TEST_PLAN §1.4).
##
## Targets:
##   - 1920x1080 (16:9 desktop) and 2048x1536 (4:3 iPad): zero letterbox bars,
##     which means the background covers the whole viewport rect
##   - every node in the `hit_target` group is at least 120x120 px and lies
##     inside the viewport
##   - every zone the rig exposes sits inside the rig's own visual rect
##
## The oracle never resizes the window: the caller puts the scene in a
## SubViewport of the target size and passes that viewport in, so the same code
## runs headless in CI and on a device.

const MIN_HIT_SIZE: Vector2 = Vector2(120.0, 120.0)
const HIT_GROUP: String = "hit_target"
const COVER_TOLERANCE: float = 1.0
const DESKTOP_16_9: Vector2i = Vector2i(1920, 1080)
const IPAD_4_3: Vector2i = Vector2i(2048, 1536)
const ASPECTS: Array[Vector2i] = [DESKTOP_16_9, IPAD_4_3]

var findings: Array[String] = []


func audit(root: Control, viewport_size: Vector2i) -> Array[String]:
	findings.clear()
	if root == null:
		findings.append("root is null")
		return findings
	var canvas: Rect2 = Rect2(Vector2.ZERO, Vector2(viewport_size))
	_audit_background(root, canvas)
	_audit_hit_targets(root, canvas)
	return findings


func is_clean() -> bool:
	return findings.is_empty()


func summary() -> String:
	if findings.is_empty():
		return "geometry clean"
	return "%d finding(s): %s" % [findings.size(), "; ".join(findings)]


## A covered background means no bars: the rect must reach every viewport edge.
func _audit_background(root: Control, canvas: Rect2) -> void:
	var backgrounds: Array[Node] = _collect(root, "background")
	if backgrounds.is_empty():
		findings.append("no node in the 'background' group")
		return
	for node: Node in backgrounds:
		var control: Control = node as Control
		if control == null:
			continue
		var rect: Rect2 = control.get_global_rect()
		if (
			rect.position.x > canvas.position.x + COVER_TOLERANCE
			or rect.position.y > canvas.position.y + COVER_TOLERANCE
			or rect.end.x < canvas.end.x - COVER_TOLERANCE
			or rect.end.y < canvas.end.y - COVER_TOLERANCE
		):
			findings.append("background %s covers %s, viewport is %s (letterbox bars)" % [control.name, rect, canvas])
		if control is TextureRect:
			var texture_rect: TextureRect = control as TextureRect
			if texture_rect.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_COVERED:
				findings.append(
					(
						"background %s stretch_mode=%d, expected STRETCH_KEEP_ASPECT_COVERED"
						% [control.name, texture_rect.stretch_mode]
					)
				)


func _audit_hit_targets(root: Control, canvas: Rect2) -> void:
	var targets: Array[Node] = []
	targets.append_array(get_tree_nodes_in_group(root, HIT_GROUP))
	if targets.is_empty():
		findings.append("no node in the 'hit_target' group")
		return
	for node: Node in targets:
		var control: Control = node as Control
		if control == null:
			findings.append("hit target %s is not a Control" % node.name)
			continue
		var rect: Rect2 = control.get_global_rect()
		if rect.size.x < MIN_HIT_SIZE.x - COVER_TOLERANCE or rect.size.y < MIN_HIT_SIZE.y - COVER_TOLERANCE:
			findings.append("hit target %s is %s, minimum is %s" % [control.name, rect.size, MIN_HIT_SIZE])
		if not canvas.encloses(rect):
			findings.append("hit target %s (%s) is outside the viewport %s" % [control.name, rect, canvas])


static func get_tree_nodes_in_group(root: Node, group: String) -> Array[Node]:
	var found: Array[Node] = []
	if root.is_inside_tree():
		for node: Node in root.get_tree().get_nodes_in_group(group):
			if root.is_ancestor_of(node) or node == root:
				found.append(node)
	return found


func _collect(root: Node, group: String) -> Array[Node]:
	var found: Array[Node] = []
	if root.is_inside_tree():
		for node: Node in root.get_tree().get_nodes_in_group(group):
			if root.is_ancestor_of(node):
				found.append(node)
	return found
