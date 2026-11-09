# story: e14s03
extends RefCounted
## Friend stars on cards — read-only, no photo capture.

var _ctx: TemplateContext = null
var _cards: Dictionary = {}
var _seen: Dictionary = {}
var _plays: int = 0


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_build_cards()


func teardown() -> void:
	for card: TapButton in _cards.values():
		if is_instance_valid(card):
			card.queue_free()
	_cards.clear()
	_seen.clear()


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	var need: int = maxi(_card_count(), 1)
	var got: int = 0
	for id: String in _seen.keys():
		if bool(_seen[id]):
			got += 1
	return clampf(float(got) / float(need), 0.0, 1.0)


func play_count() -> int:
	return _plays


func press(friend_id: String) -> void:
	_on_card(friend_id)


func stars_for(friend_id: String) -> int:
	var sink: Node = TemplateKit.autoload("ProgressManager")
	if sink == null:
		return 0
	return StarLedger.of(sink.data, friend_id)


func _card_count() -> int:
	return _cards.size() if not _cards.is_empty() else FriendCatalog.FRIEND_IDS.size()


func _build_cards() -> void:
	if _ctx == null or _ctx.tray == null:
		return
	var ids: PackedStringArray = FriendCatalog.FRIEND_IDS
	if _ctx.step_def != null and not _ctx.step_def.item_ids.is_empty():
		ids = _ctx.step_def.item_ids
	for index: int in range(ids.size()):
		var fid: String = ids[index]
		var card: TapButton = TemplateKit.tap_button(fid, Vector2(200.0 * float(index), 0.0))
		card.tapped.connect(_on_card.bind(fid))
		_ctx.tray.add_child(card)
		_cards[fid] = card
		_seen[fid] = false


func _on_card(friend_id: String) -> void:
	_plays += 1
	_seen[friend_id] = true
	TemplateKit.play_hit(_ctx, "template.album", {"friend": friend_id})
