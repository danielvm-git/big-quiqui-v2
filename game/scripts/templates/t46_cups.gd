# story: e16s02
extends RefCounted
## Shell game: tap the cup hiding the prize.

var _ctx: TemplateContext = null
var _cups: Dictionary = {}
var _hidden: String = ""
var _found: bool = false


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_hidden = _pick_hidden()
	_build_cups()


func teardown() -> void:
	for cup: TapButton in _cups.values():
		if is_instance_valid(cup):
			cup.queue_free()
	_cups.clear()


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	return 1.0 if _found else 0.0


func hidden_under() -> String:
	return _hidden


func _pick_hidden() -> String:
	var ids: PackedStringArray = (
		_ctx.step_def.item_ids if _ctx.step_def else PackedStringArray(["cup_a", "cup_b", "cup_c"])
	)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = maxi(_ctx.step_def.spawn_seed, 1)
	return ids[rng.randi() % ids.size()]


func _build_cups() -> void:
	var ids: PackedStringArray = _ctx.step_def.item_ids if _ctx.step_def else PackedStringArray()
	for index: int in range(ids.size()):
		var cup_id: String = ids[index]
		var cup: TapButton = TemplateKit.tap_button(cup_id, Vector2(200.0 * float(index), 400.0))
		cup.tapped.connect(_on_cup.bind(cup_id))
		if _ctx.host != null:
			(_ctx.host as Control).add_child(cup)
		_cups[cup_id] = cup


func _on_cup(cup_id: String) -> void:
	TemplateKit.play_hit(_ctx, "template.tap", {"target": cup_id})
	if cup_id == _hidden:
		_found = true
		if _ctx.runner != null:
			_ctx.runner.report_template_progress(1.0)
	else:
		TemplateKit.play_miss(_ctx)
