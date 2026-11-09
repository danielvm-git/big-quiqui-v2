# story: e13s09
extends RefCounted
## One tap picks one prize from the def. A second pick does nothing, and there is never an ad.
## Re-entering shows the saved prize lit; one tap on it carries on.

var _ctx: TemplateContext = null
var _picked: String = ""
var _continued: bool = false
var _buttons: Dictionary = {}


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	var saved: String = _saved()
	if _prizes().has(saved):
		_picked = saved
	_build_buttons()
	_light()


func teardown() -> void:
	for prize_id: String in _buttons.keys():
		var button: TapButton = _buttons[prize_id] as TapButton
		if is_instance_valid(button):
			button.queue_free()
	_buttons.clear()


func advance(_delta: float) -> void:
	pass


func pick(prize_id: String) -> bool:
	if not _picked.is_empty():
		_continued = _picked == prize_id or _continued
		return false
	if not Ids.is_valid(prize_id) or not _prizes().has(prize_id):
		return false
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink == null or not bool(sink.call("pick_prize", prize_id)):
		return false
	_picked = prize_id
	_continued = true
	_light()
	TemplateKit.play_hit(_ctx, "template.prize", {"picked": 1})
	return true


func picked() -> String:
	return _picked


func progress() -> float:
	return 1.0 if _continued else 0.0


func button(prize_id: String) -> TapButton:
	return _buttons.get(prize_id) as TapButton


func _prizes() -> PackedStringArray:
	if _ctx == null or _ctx.step_def == null:
		return PackedStringArray()
	return _ctx.step_def.item_ids


func _saved() -> String:
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink == null:
		return ""
	return str(sink.call("picked_prize"))


func _build_buttons() -> void:
	if _ctx == null or _ctx.tray == null:
		return
	for prize_id: String in _prizes():
		if _buttons.has(prize_id):
			continue
		var button: TapButton = TemplateKit.tap_button(prize_id, Vector2(160.0 * float(_buttons.size()), 0.0))
		button.tapped.connect(pick.bind(prize_id))
		_ctx.tray.add_child(button)
		_buttons[prize_id] = button


func _light() -> void:
	for prize_id: String in _buttons.keys():
		var lit: bool = _picked.is_empty() or _picked == prize_id
		(_buttons[prize_id] as TapButton).visual.modulate = Color(1, 1, 1, 1) if lit else Color(1, 1, 1, 0.4)
