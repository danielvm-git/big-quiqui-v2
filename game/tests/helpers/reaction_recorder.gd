# story: e12s03
class_name ReactionRecorder
extends RefCounted
## Captures reaction kinds and the frame they ran on.

var entries: Array[Dictionary] = []


func record(kind: String, frame: int) -> void:
	entries.append({"kind": kind, "frame": frame})


func kinds() -> Array[String]:
	var out: Array[String] = []
	for row: Dictionary in entries:
		out.append(str(row.get("kind", "")))
	return out


func same_frame(a: String, b: String) -> bool:
	var frame_a: int = -1
	var frame_b: int = -1
	for row: Dictionary in entries:
		var kind: String = str(row.get("kind", ""))
		if kind == a:
			frame_a = int(row.get("frame", -1))
		if kind == b:
			frame_b = int(row.get("frame", -1))
	return frame_a >= 0 and frame_a == frame_b
