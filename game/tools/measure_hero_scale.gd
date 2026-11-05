extends SceneTree


# story: e02s03
# Headless measurement probe: box vs painted rect on both shipped scenes.
func _initialize() -> void:
	_go()


func _go() -> void:
	var root: Node = get_root()
	for scene_path: String in ["res://scenes/casa.tscn", "res://scenes/titulo.tscn"]:
		for vp: Vector2i in [Vector2i(1920, 1080), Vector2i(1920, 1440), Vector2i(2048, 1536)]:
			var holder: SubViewport = SubViewport.new()
			holder.size = vp
			holder.disable_3d = true
			holder.render_target_update_mode = SubViewport.UPDATE_DISABLED
			root.add_child(holder)
			var packed: PackedScene = load(scene_path) as PackedScene
			var inst: Control = packed.instantiate() as Control
			holder.add_child(inst)
			await process_frame
			await process_frame
			await process_frame
			var rig: Control = inst.get_node_or_null("QuiQuiRig") as Control
			var box: Rect2 = rig.get_global_rect()
			var painted: Rect2 = rig.call("get_visual_global_rect") as Rect2
			print(
				(
					"%s %dx%d box_h=%.3f box_feet=%.3f painted_h=%.3f painted_feet=%.3f"
					% [
						scene_path.get_file(),
						vp.x,
						vp.y,
						box.size.y / float(vp.y),
						box.end.y / float(vp.y),
						painted.size.y / float(vp.y),
						painted.end.y / float(vp.y),
					]
				)
			)
			holder.queue_free()
	quit(0)
