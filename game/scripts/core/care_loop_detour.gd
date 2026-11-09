# story: e01s02
# story: e12s02
class_name CareLoopDetour
extends RefCounted
## Close CELEBRATE when navigation leaves the hub or celebration legitimately.


static func close_unless(manager: Node, allowed: bool) -> void:
	if allowed:
		return
	var care: Node = manager.get_node_or_null("/root/CareLoopManager")
	if care != null and care.has_method("close_celebrate_if_needed"):
		care.call("close_celebrate_if_needed")
