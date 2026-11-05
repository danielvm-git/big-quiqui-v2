# story: e01s01
class_name GeometryOracle
extends RefCounted
## Dual-aspect layout assertions (ADR-002 / ADR-008 / TEST_PLAN §1.4).
##
## The contract has three parts, and the oracle is only useful because each one
## is checked in *both* directions:
##   - the background `TextureRect` matches the viewport exactly (no bars, no
##     2x-oversized canvas that passes a `>=` test while zooming the art), and
##     uses `STRETCH_KEEP_ASPECT_COVERED`
##   - every node in the `hit_target` group is at least 120x120 px and inside the
##     viewport
##   - a scene that declares layout groups keeps them anchored: `rig` (height
##     ratio + feet line + horizontal centre), `ui_bottom`, `ui_top_right`
##
## The ratios are passed in by the caller (`CARE_ROOM_SPEC`/`TITLE_SPEC`), so the
## product requirement is written where it is asserted instead of being implied.
## The oracle never resizes the window: the caller puts the scene in a
## SubViewport of the target size, so the same code runs headless in CI.

const MIN_HIT_SIZE: Vector2 = Vector2(120.0, 120.0)
const HIT_GROUP: String = "hit_target"
const BACKGROUND_GROUP: String = "background"
const RIG_GROUP: String = "rig"
const BOTTOM_GROUP: String = "ui_bottom"
const TOP_RIGHT_GROUP: String = "ui_top_right"

const COVER_TOLERANCE: float = 1.0
const RATIO_TOLERANCE: float = 0.02
## A rig box that keeps more than this share of the canvas height above the art
## is a taller frame than the character (BUG-013).
const BOX_DEAD_SPACE_TOLERANCE: float = 0.03

const DESKTOP_16_9: Vector2i = Vector2i(1920, 1080)
const IPAD_4_3: Vector2i = Vector2i(2048, 1536)
const ASPECTS: Array[Vector2i] = [DESKTOP_16_9, IPAD_4_3]

## DESIGN.md §layout: care rooms put QuiQui at 55–65 % of the height with her
## feet on the 78 % line, the dots 36 px above the bottom, the HUD 36 px in.
const CARE_ROOM_SPEC: Dictionary = {
	"rig_feet_ratio": 0.78,
	"rig_height_min": 0.55,
	"rig_height_max": 0.65,
	"bottom_gap_max": 60.0,
	"top_right_gap_max": 60.0,
	"required_groups": [RIG_GROUP, BOTTOM_GROUP, TOP_RIGHT_GROUP],
}
## The title screen stands her lower, above the Play button, on the 92.6 % line.
const TITLE_SPEC: Dictionary = {
	"rig_feet_ratio": 0.926,
	"rig_height_min": 0.55,
	"rig_height_max": 0.65,
	"required_groups": [RIG_GROUP],
}

var findings: Array[String] = []


## The scene root itself must be the canvas: a packed `size` on a `FULL_RECT`
## root grows it to 2x and every child inherits the zoom (BUG-001).
func audit(root: Control, viewport_size: Vector2i, spec: Dictionary = {}) -> Array[String]:
	findings.clear()
	if root == null:
		findings.append("root is null")
		return findings
	var canvas: Rect2 = Rect2(Vector2.ZERO, Vector2(viewport_size))
	var root_rect: Rect2 = root.get_global_rect()
	if (
		absf(root_rect.size.x - canvas.size.x) > COVER_TOLERANCE
		or absf(root_rect.size.y - canvas.size.y) > COVER_TOLERANCE
	):
		findings.append(
			(
				"scene root %s is %s, viewport is %s (the root must be the canvas, not a packed size)"
				% [root.name, root_rect.size, canvas.size]
			)
		)
	_audit_background(root, canvas)
	_audit_hit_targets(root, canvas)
	_audit_rig(root, canvas, spec)
	_audit_required_groups(root, spec)
	_audit_edge_anchored(root, canvas, spec, BOTTOM_GROUP)
	_audit_edge_anchored(root, canvas, spec, TOP_RIGHT_GROUP)
	return findings


## A scene can opt out of a layout check by forgetting `add_to_group`. When the
## spec names its groups, an empty one is a finding instead of a silent pass.
func _audit_required_groups(root: Control, spec: Dictionary) -> void:
	var required: Variant = spec.get("required_groups", null)
	if required == null or not required is Array:
		return
	for group_name: String in required as Array:
		if _collect(root, group_name).is_empty():
			findings.append("scene declares group '%s' in its layout spec but has no such node" % group_name)


func is_clean() -> bool:
	return findings.is_empty()


func summary() -> String:
	if findings.is_empty():
		return "geometry clean"
	return "%d finding(s): %s" % [findings.size(), "; ".join(findings)]


## A full-bleed background must *match* the canvas: smaller means letterbox bars,
## larger means the scene root grew past the viewport and the art is zoomed.
func _audit_background(root: Control, canvas: Rect2) -> void:
	var backgrounds: Array[Node] = _collect(root, BACKGROUND_GROUP)
	if backgrounds.is_empty():
		findings.append("no node in the '%s' group" % BACKGROUND_GROUP)
		return
	for node: Node in backgrounds:
		var control: Control = node as Control
		if control == null:
			continue
		var rect: Rect2 = control.get_global_rect()
		if _is_smaller(rect, canvas):
			findings.append("background %s covers %s, viewport is %s (letterbox bars)" % [control.name, rect, canvas])
		elif rect.size.x > canvas.size.x + COVER_TOLERANCE or rect.size.y > canvas.size.y + COVER_TOLERANCE:
			findings.append(
				(
					"background %s is %s, viewport is %s (oversized: the scene root grew past the canvas)"
					% [control.name, rect.size, canvas.size]
				)
			)
		var texture_rect: TextureRect = control as TextureRect
		if texture_rect == null:
			findings.append("background %s is not a TextureRect" % control.name)
			continue
		if texture_rect.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_COVERED:
			findings.append(
				(
					"background %s stretch_mode=%d, expected STRETCH_KEEP_ASPECT_COVERED"
					% [control.name, texture_rect.stretch_mode]
				)
			)


func _audit_hit_targets(root: Control, canvas: Rect2) -> void:
	var targets: Array[Node] = _collect(root, HIT_GROUP)
	if targets.is_empty():
		findings.append("no node in the '%s' group" % HIT_GROUP)
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


## QuiQui keeps her size and her floor line on every aspect (DESIGN §layout).
## The ratios are asserted on the **painted** rect: the box is empty space above
## her head once the canvas is taller than 16:9 (BUG-013).
func _audit_rig(root: Control, canvas: Rect2, spec: Dictionary) -> void:
	var rigs: Array[Node] = _collect(root, RIG_GROUP)
	if rigs.is_empty():
		return
	var expected_feet: float = float(spec.get("rig_feet_ratio", -1.0))
	var min_ratio: float = float(spec.get("rig_height_min", -1.0))
	var max_ratio: float = float(spec.get("rig_height_max", -1.0))
	for node: Node in rigs:
		var control: Control = node as Control
		if control == null:
			findings.append("rig node %s is not a Control: the layout contract cannot be measured" % node.name)
			continue
		var box: Rect2 = control.get_global_rect()
		var painted: Rect2 = _painted_rect(control)
		# Fail closed: "cannot measure" is a finding, never a silent fall back to
		# the box — that fallback is how BUG-013 shipped green.
		if not painted.has_area():
			findings.append("rig %s exposes no painted geometry: the height and feet checks cannot run" % control.name)
			continue
		var measured: Rect2 = painted
		_audit_rig_feet(control, measured, canvas, expected_feet)
		_audit_rig_height(control, measured, canvas, min_ratio, max_ratio)
		_audit_rig_box_is_the_character(control, box, painted, canvas)
		if absf(measured.get_center().x - canvas.get_center().x) > canvas.size.x * RATIO_TOLERANCE:
			findings.append(
				(
					"rig %s is not horizontally centred (x=%.0f, canvas centre %.0f)"
					% [control.name, measured.get_center().x, canvas.get_center().x]
				)
			)


## The observable that measures the art, not the layout box.
static func _painted_rect(control: Control) -> Rect2:
	if control == null or not control.has_method("get_visual_global_rect"):
		return Rect2()
	var painted: Variant = control.call("get_visual_global_rect")
	return painted if painted is Rect2 else Rect2()


## A box much larger than the art is dead space: the child sees a smaller or
## narrower character than the box claims, and empty space around her is exposed.
func _audit_rig_box_is_the_character(control: Control, box: Rect2, painted: Rect2, canvas: Rect2) -> void:
	var dead_y: float = maxf(box.size.y - painted.size.y, 0.0) / canvas.size.y
	if dead_y > BOX_DEAD_SPACE_TOLERANCE:
		findings.append(
			(
				"rig %s box is %.2f of the canvas but the character is only %.2f (%.2f of empty space above her head)"
				% [control.name, box.size.y / canvas.size.y, painted.size.y / canvas.size.y, dead_y]
			)
		)
	var dead_x: float = maxf(box.size.x - painted.size.x, 0.0) / canvas.size.x
	if dead_x > BOX_DEAD_SPACE_TOLERANCE:
		findings.append(
			(
				"rig %s box width is %.2f of the canvas but the character is only %.2f (%.2f of empty horizontal space)"
				% [control.name, box.size.x / canvas.size.x, painted.size.x / canvas.size.x, dead_x]
			)
		)


func _audit_rig_feet(control: Control, rect: Rect2, canvas: Rect2, expected_feet: float) -> void:
	if expected_feet < 0.0:
		return
	var feet_ratio: float = (rect.end.y - canvas.position.y) / canvas.size.y
	if absf(feet_ratio - expected_feet) > RATIO_TOLERANCE:
		findings.append(
			(
				"rig %s feet at %.3f of the canvas, expected %.3f (DESIGN layout)"
				% [control.name, feet_ratio, expected_feet]
			)
		)


func _audit_rig_height(control: Control, rect: Rect2, canvas: Rect2, min_ratio: float, max_ratio: float) -> void:
	if min_ratio < 0.0 or max_ratio < 0.0:
		return
	var height_ratio: float = rect.size.y / canvas.size.y
	if height_ratio < min_ratio or height_ratio > max_ratio:
		findings.append(
			(
				"rig %s is %.2f of the canvas height, expected %.2f-%.2f (painted character)"
				% [control.name, height_ratio, min_ratio, max_ratio]
			)
		)


## A UI strip that claims an edge must actually sit within the inset of it.
func _audit_edge_anchored(root: Control, canvas: Rect2, spec: Dictionary, group: String) -> void:
	var nodes: Array[Node] = _collect(root, group)
	if nodes.is_empty():
		return
	var bottom_gap_max: float = float(spec.get("bottom_gap_max", -1.0))
	var top_right_gap_max: float = float(spec.get("top_right_gap_max", -1.0))
	for node: Node in nodes:
		var control: Control = node as Control
		if control == null:
			continue
		var rect: Rect2 = control.get_global_rect()
		if group == BOTTOM_GROUP and bottom_gap_max >= 0.0:
			var bottom_gap: float = canvas.end.y - rect.end.y
			if bottom_gap < 0.0 or bottom_gap > bottom_gap_max:
				findings.append(
					"%s floats %.0f px above the bottom edge (max %.0f)" % [control.name, bottom_gap, bottom_gap_max]
				)
		if group == TOP_RIGHT_GROUP and top_right_gap_max >= 0.0:
			var right_gap: float = canvas.end.x - rect.end.x
			var top_gap: float = rect.position.y - canvas.position.y
			if right_gap < 0.0 or right_gap > top_right_gap_max:
				findings.append(
					"%s floats %.0f px from the right edge (max %.0f)" % [control.name, right_gap, top_right_gap_max]
				)
			if top_gap < 0.0 or top_gap > top_right_gap_max:
				findings.append(
					"%s floats %.0f px from the top edge (max %.0f)" % [control.name, top_gap, top_right_gap_max]
				)


func _is_smaller(rect: Rect2, canvas: Rect2) -> bool:
	return (
		rect.position.x > canvas.position.x + COVER_TOLERANCE
		or rect.position.y > canvas.position.y + COVER_TOLERANCE
		or rect.end.x < canvas.end.x - COVER_TOLERANCE
		or rect.end.y < canvas.end.y - COVER_TOLERANCE
	)


static func _collect(root: Node, group: String) -> Array[Node]:
	var found: Array[Node] = []
	if not root.is_inside_tree():
		return found
	for node: Node in root.get_tree().get_nodes_in_group(group):
		if root.is_ancestor_of(node) or node == root:
			found.append(node)
	return found
