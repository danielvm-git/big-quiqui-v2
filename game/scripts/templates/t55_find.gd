# story: e15s02
extends RefCounted
## Sequence on tap targets — wrong taps still answer.

var _seq: SequenceModifier = SequenceModifier.new()
var _tap: TapPrimitive = TapPrimitive.new()
var _ctx: TemplateContext = null
var _buttons: Dictionary = {}


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	var order: PackedStringArray = ctx.step_def.item_ids if ctx.step_def else PackedStringArray()
	_seq.reset(order)
	_tap.mode = "any"
	_tap.goal = 1
	_tap.targets = order.size()
	_build_buttons(order)
	_play_prompt()


func teardown() -> void:
	for button: TapButton in _buttons.values():
		if is_instance_valid(button):
			button.queue_free()
	_buttons.clear()


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	return _seq.progress()


func active_id() -> String:
	return _seq.active_id()


func press(target_id: String) -> void:
	var button: TapButton = _buttons.get(target_id) as TapButton
	if button != null:
		button.press()


func _build_buttons(order: PackedStringArray) -> void:
	if _ctx == null or _ctx.tray == null:
		return
	for index: int in range(order.size()):
		var target_id: String = order[index]
		var button: TapButton = TemplateKit.tap_button(target_id, Vector2(160.0 * float(index), 0.0))
		button.tapped.connect(_on_tapped.bind(target_id))
		_ctx.tray.add_child(button)
		_buttons[target_id] = button


func _on_tapped(target_id: String) -> void:
	_tap.note_tap(target_id)
	var index: int = _ctx.step_def.item_ids.find(target_id) if _ctx.step_def else -1
	TemplateKit.play_hit(_ctx, "template.tap", {"target": target_id}, index)
	if _seq.note_correct(target_id) and _ctx.runner != null:
		_ctx.runner.report_template_progress(progress())


func _play_prompt() -> void:
	if _ctx == null or _ctx.step_def == null or _ctx.reactions == null:
		return
	var key: String = _ctx.step_def.hint_voice_key
	if key.is_empty():
		return
	var path: String = VoiceKeyResolver.path_for_key(key)
	if path.is_empty():
		return
	_ctx.reactions.execute([{"kind": ReactionExecutor.KIND_VOICE, "key": key}])
