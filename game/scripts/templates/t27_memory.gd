# story: e15s03
extends RefCounted
## Four or six cards; seeded shuffle; match stays face up.

const STATE_IDLE: String = "IDLE"
const STATE_ONE_UP: String = "ONE_UP"
const STATE_RESOLVING: String = "RESOLVING"
const STATE_DONE: String = "DONE"
const LEGAL: Dictionary = {
	STATE_IDLE: [STATE_ONE_UP, STATE_DONE],
	STATE_ONE_UP: [STATE_RESOLVING, STATE_IDLE],
	STATE_RESOLVING: [STATE_IDLE, STATE_DONE],
	STATE_DONE: [],
}
const DWELL: Dictionary = {STATE_RESOLVING: 0.6}

var _fsm: Fsm = null
var _ctx: TemplateContext = null
var _cards: Dictionary = {}
var _order: PackedStringArray = PackedStringArray()
var _first_card: String = ""
var _first_art: String = ""
var _matched: Dictionary = {}
var _resolve_at: int = 0
var _clock: int = 0


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_clock = 0
	_matched.clear()
	_first_card = ""
	_first_art = ""
	_fsm = Fsm.new(STATE_IDLE, LEGAL, DWELL, Callable(self, "_clock_ms"))
	_order = _shuffled()
	_build_cards()


func teardown() -> void:
	for card: TapButton in _cards.values():
		if is_instance_valid(card):
			card.queue_free()
	_cards.clear()


func advance(delta: float) -> void:
	_clock += int(maxf(delta, 0.0) * 1000.0)
	if _fsm.state == STATE_RESOLVING and _fsm.check_dwell():
		_flip_back()
		_fsm.transition_to(STATE_IDLE)


func progress() -> float:
	var pairs: int = maxi(_pair_count(), 1)
	return clampf(float(_matched.size()) / float(pairs), 0.0, 1.0)


func press(card_id: String) -> void:
	var button: TapButton = _cards.get(card_id) as TapButton
	if button != null:
		button.press()


func _pair_count() -> int:
	return _order.size() / 2


func _shuffled() -> PackedStringArray:
	var ids: PackedStringArray = _ctx.step_def.item_ids.duplicate() if _ctx.step_def else PackedStringArray()
	var seed: int = _ctx.step_def.spawn_seed if _ctx.step_def else 1
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed
	for index: int in range(ids.size() - 1, 0, -1):
		var swap: int = rng.randi() % (index + 1)
		var temp: String = ids[index]
		ids[index] = ids[swap]
		ids[swap] = temp
	return ids


func _build_cards() -> void:
	if _ctx == null or _ctx.tray == null:
		return
	for index: int in range(_order.size()):
		var card_id: String = "card_%d" % index
		var art_id: String = _order[index]
		var button: TapButton = TemplateKit.tap_button(
			card_id, Vector2(140.0 * float(index % 4), 140.0 * float(index / 4))
		)
		button.set_meta("art_id", art_id)
		button.tapped.connect(_on_card.bind(card_id, art_id))
		_set_face(button, false)
		_ctx.tray.add_child(button)
		_cards[card_id] = button


func _on_card(card_id: String, art_id: String) -> void:
	if _blocked(art_id):
		TemplateKit.play_hit(_ctx, "template.tap", {"target": card_id})
		return
	var button: TapButton = _cards.get(card_id) as TapButton
	if button == null:
		return
	_set_face(button, true)
	if _fsm.state == STATE_IDLE:
		_open(card_id, art_id)
	else:
		_second(card_id, art_id)
	TemplateKit.play_hit(_ctx, "template.tap", {"target": card_id})


func _blocked(art_id: String) -> bool:
	return _fsm.state == STATE_DONE or _fsm.state == STATE_RESOLVING or _matched.has(art_id)


func _open(card_id: String, art_id: String) -> void:
	_first_card = card_id
	_first_art = art_id
	_fsm.transition_to(STATE_ONE_UP)


func _second(card_id: String, art_id: String) -> void:
	if card_id == _first_card:
		return
	if art_id != _first_art:
		_resolve_at = _clock
		_fsm.transition_to(STATE_RESOLVING)
		return
	_matched[art_id] = true
	_first_card = ""
	_first_art = ""
	var done: bool = _matched.size() >= _pair_count()
	_fsm.transition_to(STATE_DONE if done else STATE_IDLE)
	if _ctx.runner != null:
		_ctx.runner.report_template_progress(progress())


func _flip_back() -> void:
	for card_id: String in _cards.keys():
		var button: TapButton = _cards[card_id] as TapButton
		var art_id: String = str(button.get_meta("art_id"))
		if not _matched.has(art_id):
			_set_face(button, false)
	_first_card = ""
	_first_art = ""
	TemplateKit.play_miss(_ctx)


func _clock_ms() -> int:
	return _clock


func _set_face(button: TapButton, face_up: bool) -> void:
	if button.visual == null:
		return
	for child: Node in button.visual.get_children():
		child.queue_free()
	var art_id: String = str(button.get_meta("art_id")) if face_up else "star"
	button.visual.add_child(ItemArt.icon(art_id, TapButton.MIN_HIT_SIZE.x))
