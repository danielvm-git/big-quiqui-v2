# story: e02s02
extends GutTest
## SC-E02-P1-01..06 — the wish bubble is a two-state Fsm-driven overlay: it shows
## the icon of what QuiQui wants, pulses only while shown, never eats touches,
## and degrades gracefully when art is missing.

const FRAME_PATH: String = "res://assets/art/ui/balao_desejo.png"


func _mounted() -> WishBubble:
	var bubble: WishBubble = WishBubble.new()
	bubble.size = Vector2(220.0, 220.0)
	add_child_autofree(bubble)
	return bubble


func test_starts_hidden_and_transparent_to_touch() -> void:
	var bubble: WishBubble = _mounted()

	assert_false(bubble.is_showing())
	assert_false(bubble.visible)
	assert_eq(bubble.mouse_filter, Control.MOUSE_FILTER_IGNORE, "the bubble must never eat a tap")
	assert_eq(bubble.wish_id(), "")


func test_show_wish_reveals_the_bubble_with_the_asked_icon() -> void:
	var bubble: WishBubble = _mounted()

	assert_true(bubble.show_wish("res://assets/art/items/cenoura.png"))

	assert_true(bubble.is_showing())
	assert_true(bubble.visible)
	assert_eq(bubble.wish_id(), "cenoura")
	assert_not_null(bubble.icon_texture(), "cenoura.png must load")


func test_showing_a_new_wish_swaps_the_icon_without_hiding() -> void:
	var bubble: WishBubble = _mounted()
	bubble.show_wish("res://assets/art/items/cenoura.png")

	assert_true(bubble.show_wish("res://assets/art/items/bola.png"))

	assert_true(bubble.is_showing(), "the bubble stays up between wishes")
	assert_eq(bubble.wish_id(), "bola")


func test_hide_closes_the_bubble() -> void:
	var bubble: WishBubble = _mounted()
	bubble.show_wish("res://assets/art/items/cenoura.png")

	assert_true(bubble.hide_wish())

	assert_false(bubble.is_showing())
	assert_false(bubble.visible)
	assert_eq(bubble.wish_id(), "")


func test_missing_art_keeps_the_bubble_hidden() -> void:
	var bubble: WishBubble = _mounted()

	assert_false(bubble.show_wish("res://assets/art/items/arquivo_que_nao_existe.png"))

	assert_false(bubble.is_showing(), "a missing icon must not show an empty bubble")


func test_pulse_only_moves_while_shown_and_is_deterministic() -> void:
	var bubble: WishBubble = _mounted()
	bubble.manual_step = true

	bubble.advance(0.5)
	assert_almost_eq(bubble.pulse_scale(), 1.0, 0.0001, "hidden means no pulse")

	bubble.show_wish("res://assets/art/items/cenoura.png")
	bubble.advance(0.5)
	var first_pass: float = bubble.pulse_scale()
	assert_gt(first_pass, 0.95, "the pulse is a subtle breathing swell")
	assert_lt(first_pass, 1.05)

	# Determinism: replaying the same timeline must reproduce the same values.
	var replay: WishBubble = _mounted()
	replay.manual_step = true
	replay.show_wish("res://assets/art/items/cenoura.png")
	replay.advance(0.5)
	assert_almost_eq(replay.pulse_scale(), first_pass, 0.0001, "same deltas, same pulse")


func test_the_machine_never_rejects_or_times_out() -> void:
	var bubble: WishBubble = _mounted()
	var probe: FsmProbe = FsmProbe.new().attach(bubble.fsm)

	for index: int in range(3):
		bubble.show_wish("res://assets/art/items/cenoura.png")
		bubble.show_wish("res://assets/art/items/bola.png")
		bubble.hide_wish()

	assert_true(probe.is_clean(), "show/hide cycles are all legal edges: %s" % probe.summary())
	assert_eq(probe.transition_count(), 6, "three show->show-swap stays put, three hides")
	probe.detach()


# BUG-005: hidden means rest, in the transform as well as in the getter.
func test_hiding_mid_pulse_returns_the_visual_to_rest() -> void:
	var bubble: WishBubble = _mounted()
	bubble.manual_step = true
	bubble.show_wish("res://assets/art/items/cenoura.png")
	bubble.advance(0.3)
	assert_ne(bubble.get_node("Visual").scale, Vector2.ONE, "the pulse must actually move the art")

	bubble.hide_wish()
	bubble.advance(0.1)

	assert_almost_eq(bubble.pulse_scale(), 1.0, 0.0001)
	assert_eq(bubble.get_node("Visual").scale, Vector2.ONE, "hidden art is exactly 1.0")


# BUG-012: prefix and suffix are not a path validation.
func test_a_traversal_path_is_refused() -> void:
	var bubble: WishBubble = _mounted()

	assert_false(bubble.show_wish("res://assets/art/../../secret.png"), "no '..' may escape the art root")
	assert_false(bubble.show_wish("res://assets/art/items/CENOURA.png"), "ids are lowercase")
	assert_false(bubble.show_wish("https://example.com/x.png"))


# BUG-005/013: `reset()` must leave the getter and the transform agreeing.
func test_reset_mid_pulse_returns_the_visual_to_rest() -> void:
	var bubble: WishBubble = _mounted()
	bubble.manual_step = true
	bubble.show_wish("res://assets/art/items/cenoura.png")
	bubble.advance(0.3)
	assert_ne(bubble.get_node("Visual").scale, Vector2.ONE, "the pulse must actually move the art")

	bubble.reset()

	assert_almost_eq(bubble.pulse_scale(), 1.0, 0.0001, "reset clears the pulse")
	assert_eq(bubble.get_node("Visual").scale, Vector2.ONE, "and the transform agrees with the getter")


# BUG-014 / round-2 must-fix 3: the same `\A…\z` rule as `Ids`, pinned.
func test_a_newline_suffixed_path_is_refused() -> void:
	var bubble: WishBubble = _mounted()

	# `ResourceLoader.exists` would also refuse it, so assert the *pattern* itself:
	# reverting `\A…\z` to `^…$` must fail this line (round 3, review A).
	assert_false(bubble.call("_is_valid_art_path", "res://assets/art/items/cenoura.png\n") as bool, "PCRE `$`")
	assert_false(bubble.call("_is_valid_art_path", "res://assets/art/items/cenoura.png\r\n") as bool)
	assert_true(bubble.call("_is_valid_art_path", "res://assets/art/items/cenoura.png") as bool)
	assert_false(bubble.show_wish("res://assets/art/items/cenoura.png\n"))
	assert_false(bubble.is_showing(), "and the bubble stays hidden")
