# story: e13s05
extends RefCounted
## One verb starts the game. Every other control on the host is decoration, except Home.

const VERB_ART: String = "play_button"
const VERB_SIZE: Vector2 = Vector2(240.0, 240.0)

var _ctx: TemplateContext = null
var _started: bool = false
var _button: TapButton = null
var _quieted: Dictionary = {}


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_quiet_host()
	_add_verb()


func teardown() -> void:
	for node: Control in _quieted.keys():
		if is_instance_valid(node):
			node.mouse_filter = int(_quieted[node]) as Control.MouseFilter
	_quieted.clear()
	if _button != null and is_instance_valid(_button):
		_button.queue_free()
	_button = null


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	return 1.0 if _started else 0.0


func press() -> void:
	if _button != null and is_instance_valid(_button):
		_button.press()
	else:
		_started = true


func button() -> TapButton:
	return _button


func interactive_count() -> int:
	if _ctx == null or not (_ctx.host is Control):
		return 1
	var count: int = 0
	for child: Node in (_ctx.host as Control).get_children():
		if child is Control and (child as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			count += 1
	return count


func _home() -> Node:
	if _ctx == null or _ctx.nodes == null:
		return null
	return _ctx.nodes.resolve("home")


func _quiet_host() -> void:
	if _ctx == null or not (_ctx.host is Control):
		return
	for child: Node in (_ctx.host as Control).get_children():
		if child is Control and child != _home():
			_quieted[child] = (child as Control).mouse_filter
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _add_verb() -> void:
	if _ctx == null or not (_ctx.host is Control):
		return
	var host: Control = _ctx.host as Control
	_button = TemplateKit.tap_button(VERB_ART, Vector2.ZERO)
	_button.size = VERB_SIZE
	_button.custom_minimum_size = VERB_SIZE
	_button.position = (host.size - VERB_SIZE) * 0.5 + Vector2(0.0, host.size.y * 0.2)
	_button.tapped.connect(_on_tapped)
	host.add_child(_button)


func _on_tapped() -> void:
	_started = true
