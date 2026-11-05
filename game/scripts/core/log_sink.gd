# story: e01s01
class_name LogSink
extends RefCounted
## The one bridge to the `Log` autoload (CONVENTIONS §4 graceful degradation).
##
## Every writer used to carry its own copy of this lookup; a missing autoload (a
## unit test, a manager built before `_ready`) must always be a silent no-op.

const LOG_NODE: String = "/root/Log"


## Emits from a node that may or may not be inside the tree yet.
static func emit_from(source: Node, ev: String, data: Dictionary) -> void:
	if source == null or not source.is_inside_tree():
		return
	var sink: Node = source.get_node_or_null(LOG_NODE)
	if sink != null and sink.has_method("event"):
		sink.call("event", ev, data)


## Emits from a `RefCounted` (an `Fsm`), which has no path of its own.
static func emit_to_diary(ev: String, data: Dictionary) -> void:
	if Engine.get_main_loop() is not SceneTree:
		return
	var root: Window = (Engine.get_main_loop() as SceneTree).root
	if root == null:
		return
	var sink: Node = root.get_node_or_null("Log")
	if sink != null and sink.has_method("event"):
		sink.call("event", ev, data)
