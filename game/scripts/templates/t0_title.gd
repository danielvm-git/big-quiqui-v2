# story: e13s05
extends RefCounted
## One verb starts the game. Every other control on the host is decoration.

var _ctx: TemplateContext = null
var _started: bool = false
var _button: BaseButton = null


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_quiet_host()
	_add_verb()


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	return 1.0 if _started else 0.0


func press() -> void:
	_started = true


func interactive_count() -> int:
	if _ctx == null or not (_ctx.host is Control):
		return 1
	var count: int = 0
	for child: Node in (_ctx.host as Control).get_children():
		if child is Control and (child as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			count += 1
	return count


func _quiet_host() -> void:
	if _ctx == null or not (_ctx.host is Control):
		return
	for child: Node in (_ctx.host as Control).get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _add_verb() -> void:
	if _ctx == null or not (_ctx.host is Control):
		return
	var button: Button = Button.new()
	button.name = "start"
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.pressed.connect(press)
	(_ctx.host as Control).add_child(button)
	_button = button
