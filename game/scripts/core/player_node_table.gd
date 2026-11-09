# story: e12s05
class_name PlayerNodeTable
extends RefCounted
## Resolve declared node ids to controls; reject path-like ids (F-3).

const REJECT_EV: String = "player.node_rejected"

var _nodes: Dictionary = {}


func register(id: String, node: Control) -> void:
	if not _valid_id(id) or node == null:
		return
	_nodes[id] = node


func resolve(id: String) -> Control:
	if not _valid_id(id):
		_log_reject(id)
		return null
	var found: Variant = _nodes.get(id, null)
	return found as Control if found is Control else null


func global_center(id: String) -> Vector2:
	var node: Control = resolve(id)
	if node == null:
		return Vector2.ZERO
	return node.get_global_rect().get_center()


static func _valid_id(id: String) -> bool:
	if id.is_empty() or not Ids.is_valid(id):
		return false
	if id.contains("..") or id.contains("/"):
		return false
	return true


static func _log_reject(id: String) -> void:
	LogSink.emit_to_diary(REJECT_EV, {"node": id.substr(0, mini(id.length(), 32))})
