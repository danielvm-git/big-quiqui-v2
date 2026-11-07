# story: e09s04
class_name PlacementOracle
extends RefCounted
## The epic's own claim, as a test (e09s04): a piece she placed must sit at the same
## ratio of the room on any canvas. Measures the *painted* rect centre, like
## `GeometryOracle` does after BUG-013 — never the anchor box.

const RATIO_TOLERANCE: float = 0.02
const DEFAULT_AREA: String = "PlacementArea"

var findings: Array[String] = []


## Audits a save against a mounted room: `saved` comes from `ProgressManager.placed()`,
## `first` is the canvas it was captured on (for the message), `second` the one on screen.
func audit_normalized(
	first: Vector2i,
	second: Vector2i,
	saved: Array[Dictionary],
	mounted: Control,
	area_name: String = DEFAULT_AREA,
) -> Array[String]:
	findings.clear()
	if mounted == null:
		findings.append("%s: nothing is mounted" % second)
		return findings
	var area: Control = mounted.get_node_or_null(area_name) as Control
	if area == null:
		findings.append("%s: no '%s' node, the ratio cannot be measured" % [second, area_name])
		return findings
	if saved.is_empty():
		findings.append("%s: the save holds no placement, so the round trip proves nothing" % second)
		return findings
	for entry: Dictionary in saved:
		_audit_entry(first, second, entry, mounted, area)
	return findings


func _audit_entry(first: Vector2i, second: Vector2i, entry: Dictionary, mounted: Control, area: Control) -> void:
	var id: String = str(entry.get("id", ""))
	var ratio: Vector2 = Vector2(float(entry.get("x", 0.5)), float(entry.get("y", 0.5)))
	if not _inside(ratio):
		findings.append("%s: saved ratio %s for %s is outside the room" % [second, ratio, id])
	var prop: Control = mounted.get_node_or_null("Prop_" + id) as Control
	if prop == null:
		findings.append("%s: placed piece %s is not in the scene" % [second, id])
		return
	var measured: Vector2 = normalized_center_of(prop, area)
	if measured.distance_to(ratio) > RATIO_TOLERANCE:
		findings.append("%s (placed on %s): %s sits at %s of the room, saved %s" % [second, first, id, measured, ratio])


func normalized_center_of(control: Control, area: Control) -> Vector2:
	var rect: Rect2 = area.get_global_rect()
	if control == null or rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return Vector2(-1.0, -1.0)
	return (control.get_global_rect().get_center() - rect.position) / rect.size


func is_clean() -> bool:
	return findings.is_empty()


func summary() -> String:
	if findings.is_empty():
		return "placements clean"
	return "%d finding(s): %s" % [findings.size(), "; ".join(findings)]


static func _inside(ratio: Vector2) -> bool:
	return ratio.x >= 0.0 and ratio.x <= 1.0 and ratio.y >= 0.0 and ratio.y <= 1.0
