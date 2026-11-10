# story: e15s01
# story: e15s02
# story: e15s03
# story: e15s04
class_name ChildCanPlayWave2Flows
extends RefCounted


static func play_room(case: PlayerTestCase, player: ScenePlayer, scene_id: String) -> void:
	match scene_id:
		"find_toy":
			await _play_find(case, player)
		"coloring":
			await _play_coloring(case, player)
		"memory_match":
			await _play_memory(case, player)
		"peekaboo":
			await _play_peekaboo(case, player)
		_:
			case.assert_true(false, "unknown wave-2 room %s" % scene_id)


static func _play_find(case: PlayerTestCase, player: ScenePlayer) -> void:
	var tpl: RefCounted = player.get("_template") as RefCounted
	for _round: int in range(6):
		if tpl == null or not tpl.has_method("active_id"):
			break
		var target: String = str(tpl.call("active_id"))
		if target.is_empty():
			break
		if tpl.has_method("press"):
			tpl.call("press", target)
		else:
			for tap: TapButton in case.tray_taps(player):
				if tap.name == target:
					case.finger_tap(player, tap)
					break
		player.advance(0.1)
		if player.runner.template_progress() >= 1.0:
			return
	await case._settle(player)


static func _play_coloring(case: PlayerTestCase, player: ScenePlayer) -> void:
	for _phase: int in range(8):
		match player.runner.step_index:
			0:
				var tool: TouchDraggable = case.rub_tool(player)
				var canvas: Control = player.find_child("color_canvas", true, false) as Control
				if tool != null and canvas != null:
					case.rub_hull(tool, _canvas_hull(canvas))
			1:
				_fill_color_areas(case, player)
		for _tick: int in range(12):
			player.advance(0.2)
		if player.runner.fsm.state in [StepRunner.STATE_OUTRO, StepRunner.STATE_EXIT]:
			return
	await case._settle(player)


static func _canvas_hull(canvas: Control) -> PackedVector2Array:
	var box: Rect2 = canvas.get_global_rect()
	var hull: PackedVector2Array = PackedVector2Array()
	for index: int in range(12):
		var angle: float = TAU * float(index) / 12.0
		hull.append(box.get_center() + Vector2(cos(angle) * box.size.x * 0.42, sin(angle) * box.size.y * 0.42))
	return hull


static func _fill_color_areas(case: PlayerTestCase, player: ScenePlayer) -> void:
	var step: StepDef = player.loaded_def.steps[player.runner.step_index] as StepDef
	for index: int in range(step.item_ids.size()):
		var paint_id: String = step.item_ids[index]
		var area_id: String = step.slot_ids[index] if index < step.slot_ids.size() else ""
		if area_id.is_empty():
			continue
		var area: Control = player.find_child(area_id, true, false) as Control
		var chip: TouchDraggable = null
		for draggable: TouchDraggable in _tray_draggables(player):
			if draggable.payload_id == paint_id:
				chip = draggable
				break
		if chip == null or area == null:
			continue
		var to: Vector2 = area.get_global_rect().get_center()
		var from: Vector2 = chip.get_global_rect().get_center()
		case.send(chip, case.touch(from, true))
		case.send(chip, case.drag(to))
		case.send(chip, case.touch(to, false))


static func _play_memory(case: PlayerTestCase, player: ScenePlayer) -> void:
	var tpl: RefCounted = player.get("_template") as RefCounted
	for _round: int in range(24):
		if tpl == null or not tpl.has_method("press"):
			break
		var by_art: Dictionary = {}
		for button: TapButton in case.tray_taps(player):
			if not button.has_meta("art_id"):
				continue
			var art: String = str(button.get_meta("art_id"))
			var bucket: Array = by_art.get(art, []) as Array
			bucket.append(button.name)
			by_art[art] = bucket
		for art: String in by_art.keys():
			var ids: Array = by_art[art] as Array
			if ids.size() < 2:
				continue
			tpl.call("press", ids[0])
			tpl.call("press", ids[1])
			for _tick: int in range(10):
				player.advance(0.15)
		if player.runner.template_progress() >= 1.0:
			return
	await case._settle(player)


static func _play_peekaboo(case: PlayerTestCase, player: ScenePlayer) -> void:
	for _attempt: int in range(64):
		player.advance(0.45)
		for button: TapButton in _all_taps(player):
			case.finger_tap(player, button)
		if player.runner.template_progress() >= 1.0:
			return
	await case._settle(player)


static func _all_taps(player: ScenePlayer) -> Array[TapButton]:
	var found: Array[TapButton] = []
	_collect_taps(player, found)
	return found


static func _tray_draggables(player: ScenePlayer) -> Array[TouchDraggable]:
	var found: Array[TouchDraggable] = []
	var tray: Control = player.get_node_or_null("TrayZone") as Control
	if tray == null:
		return found
	for child: Node in tray.get_children():
		if child is TouchDraggable and not child.is_queued_for_deletion():
			found.append(child as TouchDraggable)
	return found


static func _collect_taps(node: Node, out: Array[TapButton]) -> void:
	for child: Node in node.get_children():
		if child is TapButton:
			out.append(child as TapButton)
		_collect_taps(child, out)
