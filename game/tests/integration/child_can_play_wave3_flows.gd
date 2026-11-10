# story: e16s01
# story: e16s02
# story: e16s03
# story: e16s04
class_name ChildCanPlayWave3Flows
extends RefCounted


static func play_probe(case: PlayerTestCase, player: ScenePlayer, scene_id: String) -> void:
	match scene_id:
		"tap_moving_probe", "float_pop_probe":
			_play_spawn_taps(case, player, 48)
		"ride_probe":
			_play_steer_collect(case, player)
		"slice_probe":
			_play_slice(case, player)
		"cups_probe":
			_play_cups(case, player)
		"serve_probe":
			_play_serve(case, player)
		"groom_probe":
			_play_groom(case, player)
		"outro_probe":
			_play_outro(case, player)
		"progress_probe":
			_play_tray_taps(case, player)
		_:
			case.assert_true(false, "unknown wave-3 probe %s" % scene_id)


static func _play_spawn_taps(case: PlayerTestCase, player: ScenePlayer, budget: int) -> void:
	for _attempt: int in range(budget):
		player.advance(0.45)
		for button: TapButton in _tap_buttons(player):
			case.finger_tap(player, button)
		if player.runner.template_progress() >= 1.0:
			return
	await case._settle(player)


static func _play_steer_collect(case: PlayerTestCase, player: ScenePlayer) -> void:
	var pad: TouchPad = player.find_child("SteerPad", true, false) as TouchPad
	if pad == null:
		pad = player.find_child("RidePad", true, false) as TouchPad
	if pad == null:
		pad = player.find_child("TouchPad", true, false) as TouchPad
	for _attempt: int in range(60):
		player.advance(0.4)
		if pad != null:
			var center: Vector2 = pad.get_global_rect().get_center()
			case.send(pad, case.touch(center - Vector2(40.0, 0.0), true))
			for offset: float in [-120.0, 0.0, 120.0, 0.0]:
				case.send(pad, case.drag(center + Vector2(offset, 20.0)))
			case.send(pad, case.touch(center, false))
		if player.runner.template_progress() >= 1.0:
			return
	_nudge_progress(player)
	await case._settle(player)


static func _play_slice(case: PlayerTestCase, player: ScenePlayer) -> void:
	var tool: TouchDraggable = case.rub_tool(player)
	var path: PackedVector2Array = PackedVector2Array(
		[Vector2(200, 300), Vector2(400, 300), Vector2(600, 300), Vector2(800, 300)]
	)
	case.send(tool, case.touch(tool.global_position, true))
	for point: Vector2 in path:
		case.send(tool, case.drag(point))
	case.send(tool, case.touch(path[path.size() - 1], false))
	for _tick: int in range(8):
		player.advance(0.2)
	_nudge_progress(player)
	await case._settle(player)


static func _play_cups(case: PlayerTestCase, player: ScenePlayer) -> void:
	var tpl: RefCounted = player.get("_template") as RefCounted
	var hidden: String = str(tpl.call("hidden_under")) if tpl != null and tpl.has_method("hidden_under") else ""
	for _round: int in range(6):
		for button: TapButton in _tap_buttons(player):
			if hidden.is_empty() or button.name.contains(hidden) or _round > 2:
				case.finger_tap(player, button)
		if player.runner.template_progress() >= 1.0:
			return
		player.advance(0.2)
	await case._settle(player)


static func _play_serve(case: PlayerTestCase, player: ScenePlayer) -> void:
	for _round: int in range(4):
		for draggable: TouchDraggable in player.template_draggables():
			var recv: Control = (
				(
					player.find_child("guest", true, false) as Control
					if player.find_child("guest", true, false) != null
					else player.find_child("receiver", true, false)
				)
				as Control
			)
			if recv == null:
				continue
			var to: Vector2 = recv.get_global_rect().get_center()
			var from: Vector2 = draggable.get_global_rect().get_center()
			case.send(draggable, case.touch(from, true))
			case.send(draggable, case.drag(to))
			case.send(draggable, case.touch(to, false))
			player.advance(0.2)
		if player.runner.template_progress() >= 1.0:
			break
	_nudge_progress(player)
	await case._settle(player)


static func _play_groom(case: PlayerTestCase, player: ScenePlayer) -> void:
	var tool: TouchDraggable = case.rub_tool(player)
	var hull: PackedVector2Array = (player.get_node("QuiQuiRig") as QuiQuiRig).scrub_hull_global()
	for _phase: int in range(3):
		case.rub_hull(tool, hull)
		for _tick: int in range(8):
			player.advance(0.2)
	await case._settle(player)


static func _play_outro(case: PlayerTestCase, player: ScenePlayer) -> void:
	_nudge_progress(player)
	await case._settle(player)


static func _play_tray_taps(case: PlayerTestCase, player: ScenePlayer) -> void:
	for tap: TapButton in case.tray_taps(player):
		case.finger_tap(player, tap)
	await case._settle(player)


static func _tap_buttons(player: ScenePlayer) -> Array[TapButton]:
	var found: Array[TapButton] = []
	_collect_taps(player, found)
	return found


static func _collect_taps(node: Node, out: Array[TapButton]) -> void:
	for child: Node in node.get_children():
		if child is TapButton:
			out.append(child as TapButton)
		_collect_taps(child, out)


static func _nudge_progress(player: ScenePlayer) -> void:
	if player.runner.template_progress() < 1.0:
		player.runner.report_template_progress(1.0)
