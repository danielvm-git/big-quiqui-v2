# story: e15s02
class_name SequenceModifier
extends RefCounted
## Ordered tap index on top of Tap — only the active id advances progress.

var _order: PackedStringArray = PackedStringArray()
var _index: int = 0
var _done: bool = false


func reset(order: PackedStringArray) -> void:
	_order = order
	_index = 0
	_done = order.is_empty()


func active_id() -> String:
	if _done or _index >= _order.size():
		return ""
	return _order[_index]


func note_correct(target_id: String) -> bool:
	if _done or _index >= _order.size():
		return false
	if target_id != _order[_index]:
		return false
	_index += 1
	_done = _index >= _order.size()
	return true


func progress() -> float:
	if _order.is_empty():
		return 1.0
	return clampf(float(_index) / float(_order.size()), 0.0, 1.0)


func is_done() -> bool:
	return _done
