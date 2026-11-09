# story: e13s02
extends RefCounted
## Every object answers. No auto-end timer. The template knows no room.

const SPENT: Color = Color(0.7, 0.7, 0.7, 1.0)

var _tap: TapPrimitive = TapPrimitive.new()
var _ctx: TemplateContext = null
var _buttons: Dictionary = {}
var _plays: int = 0


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_tap.mode = _mode()
	_tap.goal = _goal()
	_build_buttons()
	_tap.targets = _buttons.size()


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


## Test seam: a tap without a finger.
func press(target_id: String) -> void:
	var button: TapButton = _buttons.get(target_id) as TapButton
	if button == null:
		return
	button.press()


## Test seam: read the hit rect size.
func button_size(target_id: String) -> Vector2:
	var button: TapButton = _buttons.get(target_id) as TapButton
	if button == null:
		return Vector2.ZERO
	return button.size


func advance(_delta: float) -> void:
	pass


## `count_n` and `toggle` are the named modes. A def that names none (`StepDef` defaults to "single") is `any`.
func _mode() -> String:
	var named: String = TemplateKit.mode_or(_ctx, "any")
	return named if named in ["count_n", "toggle"] else "any"


func _goal() -> int:
	if _ctx == null or _ctx.step_def == null:
		return 1
	return maxi(_ctx.step_def.repeat_count, 1)


func _build_buttons() -> void:
	if _ctx == null or _ctx.step_def == null or _ctx.tray == null:
		return
	for target_id: String in _ctx.step_def.item_ids:
		if _buttons.has(target_id):
			continue
		_buttons[target_id] = _make_button(target_id, _buttons.size())


func _make_button(target_id: String, index: int) -> TapButton:
	var button: TapButton = TemplateKit.tap_button(target_id, Vector2(160.0 * float(index), 0.0))
	button.tapped.connect(_on_tapped.bind(target_id))
	_ctx.tray.add_child(button)
	return button


func _on_tapped(target_id: String) -> void:
	_tap.note_tap(target_id)
	_plays += 1
	_play_reaction(target_id)
	_mark(target_id)


func _play_reaction(target_id: String) -> void:
	var index: int = _ctx.step_def.item_ids.find(target_id)
	TemplateKit.play_hit(_ctx, "template.tap", {"target": target_id}, index)


## A spent target dims, so the child sees what is done. Toggle dims only while it is on.
func _mark(target_id: String) -> void:
	var button: TapButton = _buttons.get(target_id) as TapButton
	if button == null or button.visual == null:
		return
	var spent: bool = _tap.is_on(target_id) if _tap.mode == "toggle" else true
	button.visual.modulate = SPENT if spent else Color.WHITE
