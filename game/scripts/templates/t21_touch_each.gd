# story: e13s02
extends RefCounted
## Every object answers. No auto-end timer. The template knows no room.

var _tap: TapPrimitive = TapPrimitive.new()
var _ctx: TemplateContext = null
var _buttons: Dictionary = {}
var _plays: int = 0


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_tap.mode = _mode()
	_tap.goal = _goal()
	_build_buttons()


func teardown() -> void:
	for target_id: String in _buttons.keys():
		var button: TapButton = _buttons[target_id] as TapButton
		if is_instance_valid(button):
			button.queue_free()
	_buttons.clear()


func progress() -> float:
	return _tap.progress()


func play_count() -> int:
	return _plays


func press(target_id: String) -> void:
	var button: TapButton = _buttons.get(target_id) as TapButton
	if button == null:
		return
	button.press()


func button_size(target_id: String) -> Vector2:
	var button: TapButton = _buttons.get(target_id) as TapButton
	if button == null:
		return Vector2.ZERO
	return button.size


func advance(_delta: float) -> void:
	pass


func _mode() -> String:
	if _ctx == null or _ctx.step_def == null or _ctx.step_def.mode.is_empty():
		return "any"
	return _ctx.step_def.mode


func _goal() -> int:
	if _ctx == null or _ctx.step_def == null:
		return 1
	return maxi(_ctx.step_def.repeat_count, 1)


func _build_buttons() -> void:
	if _ctx == null or _ctx.step_def == null or _ctx.tray == null:
		return
	var index: int = 0
	for target_id: String in _ctx.step_def.item_ids:
		_buttons[target_id] = _make_button(target_id, index)
		index += 1


func _make_button(target_id: String, index: int) -> TapButton:
	var button: TapButton = TapButton.new()
	button.name = target_id
	button.manual_step = true
	button.size = TapButton.MIN_HIT_SIZE
	button.position = Vector2(160.0 * float(index), 0.0)
	button.add_to_group("hit_target", true)
	button.tapped.connect(_on_tapped.bind(target_id))
	_ctx.tray.add_child(button)
	return button


func _on_tapped(target_id: String) -> void:
	_tap.note_tap(target_id)
	_plays += 1
	_play_reaction(target_id)


func _play_reaction(target_id: String) -> void:
	if _ctx == null or _ctx.reactions == null or _ctx.step_def == null:
		return
	var batch: Array = []
	if not _ctx.step_def.on_hit_pose.is_empty():
		batch.append({"kind": ReactionExecutor.KIND_POSE, "id": _ctx.step_def.on_hit_pose})
	if not _ctx.step_def.on_hit_sfx_id.is_empty():
		batch.append({"kind": ReactionExecutor.KIND_SFX, "id": _ctx.step_def.on_hit_sfx_id})
	_ctx.reactions.execute(batch)
	LogSink.emit_to_diary("template.tap", {"target": target_id})
