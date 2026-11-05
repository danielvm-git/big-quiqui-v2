# story: e01s05
class_name SceneBuilder
extends RefCounted
## Shared scaffolding for the generated scenes.
##
## Hand-writing a `.tscn` is fragile (UIDs, sub-resources, layout flags); a tree
## the engine already built and packed yields a file Godot authored itself. Both
## builders also pin their nodes as ratios of the canvas (ADR-008), so the 16:9
## composition stays pixel-identical while the 4:3 expand canvas keeps its
## proportions instead of stranding the UI in a corner.


## anchors = (left, top, right, bottom); offsets = (left, top, right, bottom).
static func pin(node: Control, anchors: Vector4, offsets: Vector4) -> void:
	node.anchor_left = anchors.x
	node.anchor_top = anchors.y
	node.anchor_right = anchors.z
	node.anchor_bottom = anchors.w
	node.offset_left = offsets.x
	node.offset_top = offsets.y
	node.offset_right = offsets.z
	node.offset_bottom = offsets.w


static func pack_and_save(root: Control, scene_path: String, label: String) -> bool:
	_set_owner_recursive(root, root)
	var packed: PackedScene = PackedScene.new()
	var pack_error: int = packed.pack(root)
	if pack_error != OK:
		printerr("%s: pack failed (%s)" % [label, error_string(pack_error)])
		return false
	var save_error: int = ResourceSaver.save(packed, scene_path)
	if save_error != OK:
		printerr("%s: save failed (%s)" % [label, error_string(save_error)])
		return false
	print("%s: wrote %s (%d nodes)" % [label, scene_path, count_nodes(root)])
	return true


static func count_nodes(node: Node) -> int:
	var total: int = 1
	for child: Node in node.get_children():
		total += count_nodes(child)
	return total


## PackedScene only serialises nodes whose `owner` is the scene root; without
## this every child is silently dropped and the .tscn contains just the root.
static func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = owner_node
		_set_owner_recursive(child, owner_node)
