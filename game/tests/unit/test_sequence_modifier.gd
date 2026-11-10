# story: e15s02
extends GutTest


func test_only_the_active_id_advances() -> void:
	var mod: SequenceModifier = SequenceModifier.new()
	mod.reset(PackedStringArray(["ball", "pinwheel", "plush"]))
	assert_eq(mod.active_id(), "ball")
	assert_false(mod.note_correct("plush"))
	assert_eq(mod.progress(), 0.0)
	assert_true(mod.note_correct("ball"))
	assert_eq(mod.active_id(), "pinwheel")
	assert_true(mod.note_correct("pinwheel"))
	assert_true(mod.note_correct("plush"))
	assert_true(mod.is_done())
