# story: e13s02
# story: e14s01
# story: e14s03
extends RefCounted
## Every object answers. No auto-end timer. The template knows no room.

const SPENT: Color = Color(0.7, 0.7, 0.7, 1.0)
const NIGHT_TINT: Color = Color(0.42, 0.45, 0.72)

var _tap: TapPrimitive = TapPrimitive.new()
var _ctx: TemplateContext = null
var _buttons: Dictionary = {}
var _plays: int = 0
var _rig_filter: int = -1
var _buy_shelf: bool = false
var _arcade: bool = false
var _last_open: String = ""

const PARTY_MIN_PLACED: int = 5


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_rig_filter = TemplateKit.quiet_rig(ctx)
	var mode: String = TemplateKit.mode_or(_ctx, "")
	_buy_shelf = mode == "buy"
	_arcade = mode == "arcade"
	if _buy_shelf:
		_tap.mode = "count_n"
		_tap.goal = _ctx.step_def.item_ids.size() if _ctx.step_def != null else 1
	else:
		_tap.mode = _mode()
		_tap.goal = _goal()
	_build_buttons()
	_tap.targets = _buttons.size()


func teardown() -> void:
	TemplateKit.restore_rig(_ctx, _rig_filter)
	_rig_filter = -1
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
	if _arcade:
		_try_arcade(target_id)
		return
	if _buy_shelf:
		_try_buy(target_id)
		return
	var fresh: bool = _tap.note_tap(target_id)
	_plays += 1
	_play_reaction(target_id)
	_mark(target_id)
	if target_id == "lamp" and fresh:
		_dim_room()


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


func last_open_id() -> String:
	return _last_open


func party_unlocked() -> bool:
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink == null or not sink.has_method("placed_count"):
		return false
	return int(sink.call("placed_count")) >= PARTY_MIN_PLACED


func _try_arcade(friend_id: String) -> void:
	var step: StepDef = _ctx.step_def if _ctx != null else null
	if step == null:
		return
	var scene_id: String = "playhouse"
	if party_unlocked():
		var index: int = step.item_ids.find(friend_id)
		if index < 0 or index >= step.destination_scenes.size():
			return
		scene_id = step.destination_scenes[index]
	_last_open = scene_id
	TemplateKit.play_hit(_ctx, "party.friend_game", {"friend": friend_id})
	SceneNav.open(TemplateKit.autoload("SceneManager"), scene_id)


func _try_buy(item_id: String) -> void:
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink == null:
		TemplateKit.play_miss(_ctx)
		return
	var economy: EconomyData = EconomyData.new()
	var price: int = FurnitureCatalog.price_of(item_id, economy)
	if price < 0 or bool(sink.call("owns_furniture", item_id)):
		TemplateKit.play_miss(_ctx)
		return
	if int(sink.call("get_coins")) < price:
		TemplateKit.play_miss(_ctx)
		return
	if not bool(sink.call("buy_furniture", item_id, price)):
		TemplateKit.play_miss(_ctx)
		return
	_tap.note_tap(item_id)
	_plays += 1
	_play_reaction(item_id)
	_mark(item_id)


func _dim_room() -> void:
	if _ctx == null or _ctx.host == null:
		return
	var bg: TextureRect = _ctx.host.get_node_or_null("Background") as TextureRect
	if bg != null:
		bg.modulate = NIGHT_TINT
