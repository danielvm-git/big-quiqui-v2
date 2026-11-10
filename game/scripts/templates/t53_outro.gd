# story: e16s03
extends RefCounted
## One tap goes home through SceneNav.

var _ctx: TemplateContext = null
var _button: TapButton = null
var _done: bool = false


func setup(ctx: TemplateContext) -> void:
	_ctx = ctx
	_button = TemplateKit.tap_button("home_button", Vector2(360.0, 420.0))
	_button.tapped.connect(_go_home)
	if ctx.host != null:
		(ctx.host as Control).add_child(_button)


func teardown() -> void:
	if _button != null and is_instance_valid(_button):
		_button.queue_free()
	_button = null


func advance(_delta: float) -> void:
	pass


func progress() -> float:
	return 1.0 if _done else 0.0


func _go_home() -> void:
	_done = true
	TemplateKit.play_hit(_ctx, "template.outro", {"scene": "home"})
	SceneNav.open(TemplateKit.autoload("SceneManager"), "home")
	if _ctx.runner != null:
		_ctx.runner.report_template_progress(1.0)
