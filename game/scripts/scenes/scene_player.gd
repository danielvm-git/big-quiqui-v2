# story: e12s02
extends Control
## Minimal data-scene host for e12s02: proves a def crosses the SceneManager hand-off.

var loaded_def: SceneDef = null


func _ready() -> void:
	boot_from_manager()


func boot_from_manager() -> void:
	var manager: Node = get_node_or_null("/root/SceneManager")
	if manager == null:
		return
	if not manager.has_method("consume_def"):
		return
	var def: SceneDef = manager.call("consume_def") as SceneDef
	if def == null:
		return
	loaded_def = SceneDefLoader.validate(def)
	if loaded_def != null:
		_apply_background(loaded_def.background_id)


func _apply_background(background_id: String) -> void:
	var path: String = SceneMedia.background_path(background_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var node: TextureRect = get_node_or_null("Background") as TextureRect
	if node == null:
		return
	node.texture = load(path) as Texture2D
